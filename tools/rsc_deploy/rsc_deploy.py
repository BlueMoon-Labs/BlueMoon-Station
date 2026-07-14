#!/usr/bin/env python3
"""Prepare and atomically publish a content-addressed BYOND resource archive for TGS."""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile


MANIFEST_NAME = ".rsc-deploy.json"
GENERATED_DEFINES_NAME = ".rsc-deployment.dm"
SAFE_NAME = re.compile(r"^[A-Za-z0-9._-]+$")
ASSET_CONFIG_BEGIN = "# BEGIN MANAGED EXTERNAL BROWSER ASSETS"
ASSET_CONFIG_END = "# END MANAGED EXTERNAL BROWSER ASSETS"
LOBBY_IMAGE_EXTENSIONS = {".gif", ".jpeg", ".jpg", ".png", ".webp"}
LOBBY_AUDIO_EXTENSIONS = {".flac", ".mp3", ".ogg", ".wav"}
RESOURCE_REFERENCE_SOURCE_EXTENSIONS = {".dm", ".dme", ".dmf", ".dmm"}
RESOURCE_LITERAL = re.compile(rb"'([^'\r\n]+)'")
BUILD_CONFIGURATION_DIRECTIVE = re.compile(rb"^\s*#\s*(?:define|undef)\b", re.IGNORECASE)
RESOURCE_BUILD_INPUTS = (".tgs.yml",)
FINGERPRINT_CACHE_NAME = ".rsc-input-cache.json"
RESOURCE_SCAN_IGNORED_DIRS = {
	".cache",
	".git",
	"bot",
	"config",
	"data",
	"node_modules",
	"SQL",
	"tgstation-server",
	"tmp",
	"tools",
}


class DeployError(RuntimeError):
	pass


def log(message):
	print("[rsc-deploy] {}".format(message), flush=True)


def atomic_write(path, content):
	path = Path(path)
	path.parent.mkdir(parents=True, exist_ok=True)
	fd, temporary_name = tempfile.mkstemp(prefix=".{}-".format(path.name), dir=str(path.parent))
	try:
		with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as output:
			output.write(content)
			output.flush()
			os.fsync(output.fileno())
		os.replace(temporary_name, str(path))
	except Exception:
		try:
			os.unlink(temporary_name)
		except OSError:
			pass
		raise


def atomic_copy(source, destination):
	source = Path(source)
	destination = Path(destination)
	destination.parent.mkdir(parents=True, exist_ok=True)
	if destination.is_file() and destination.stat().st_size == source.stat().st_size:
		return
	fd, temporary_name = tempfile.mkstemp(prefix=".{}-".format(destination.name), dir=str(destination.parent))
	try:
		with source.open("rb") as input_file, os.fdopen(fd, "wb") as output_file:
			shutil.copyfileobj(input_file, output_file, length=1024 * 1024)
			output_file.flush()
			os.fsync(output_file.fileno())
		os.chmod(temporary_name, 0o644)
		os.replace(temporary_name, str(destination))
	except Exception:
		try:
			os.unlink(temporary_name)
		except OSError:
			pass
		raise


def parse_bool(value, setting_name):
	normalized = str(value).strip().lower()
	if normalized in ("1", "true", "yes", "on"):
		return True
	if normalized in ("0", "false", "no", "off"):
		return False
	raise DeployError("{} must be 0/1, true/false, yes/no or on/off".format(setting_name))


def load_settings(game_dir, configured_path=None):
	config_path = Path(configured_path) if configured_path else Path(game_dir) / "config" / "rsc_deploy.env"
	config_path = config_path.resolve()
	if not config_path.is_file():
		log("{} is absent; external RSC publishing is disabled".format(config_path))
		return None

	settings = {}
	for line_number, raw_line in enumerate(config_path.read_text(encoding="utf-8-sig").splitlines(), 1):
		line = raw_line.strip()
		if not line or line.startswith("#"):
			continue
		if line.startswith("export "):
			line = line[7:].lstrip()
		if "=" not in line:
			raise DeployError("{}:{} must be KEY=VALUE".format(config_path, line_number))
		key, value = line.split("=", 1)
		key = key.strip()
		value = value.strip()
		if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
			value = value[1:-1]
		settings[key] = value

	for required in ("RSC_PUBLIC_BASE_URL", "RSC_PUBLISH_DIR"):
		if not settings.get(required):
			raise DeployError("{} is required in {}".format(required, config_path))

	base_url = settings["RSC_PUBLIC_BASE_URL"].rstrip("/")
	if not base_url.startswith(("http://", "https://")):
		raise DeployError("RSC_PUBLIC_BASE_URL must start with http:// or https://")
	settings["RSC_PUBLIC_BASE_URL"] = base_url
	public_base_urls = [base_url]
	configured_mirrors = settings.get("RSC_PUBLIC_MIRROR_BASE_URLS", "").strip()
	if configured_mirrors:
		for mirror_number, configured_mirror in enumerate(configured_mirrors.split(";"), 1):
			mirror_url = configured_mirror.strip().rstrip("/")
			if not mirror_url:
				continue
			if not mirror_url.startswith(("http://", "https://")):
				raise DeployError(
					"RSC_PUBLIC_MIRROR_BASE_URLS entry {} must start with http:// or https://".format(
						mirror_number
					)
				)
			if mirror_url not in public_base_urls:
				public_base_urls.append(mirror_url)
	settings["RSC_PUBLIC_BASE_URLS"] = public_base_urls

	prefix = settings.get("RSC_ARCHIVE_PREFIX", "Moon-Blue")
	if not SAFE_NAME.fullmatch(prefix):
		raise DeployError("RSC_ARCHIVE_PREFIX may only contain letters, digits, dot, dash and underscore")
	settings["RSC_ARCHIVE_PREFIX"] = prefix
	deployment_namespace = settings.get("RSC_DEPLOYMENT_NAMESPACE", "").strip()
	if deployment_namespace and not SAFE_NAME.fullmatch(deployment_namespace):
		raise DeployError("RSC_DEPLOYMENT_NAMESPACE may only contain letters, digits, dot, dash and underscore")
	settings["RSC_DEPLOYMENT_NAMESPACE"] = deployment_namespace
	settings["_CONFIG_PATH"] = config_path

	for setting_name, default in (
		("RSC_LOBBY_MEDIA_SUBDIR", "lobby-media"),
		("RSC_ASSET_WEBROOT_SUBDIR", "browser-assets"),
	):
		value = settings.get(setting_name, default).strip("/\\")
		if not SAFE_NAME.fullmatch(value):
			raise DeployError("{} must be one safe directory name".format(setting_name))
		settings[setting_name] = value
	settings["RSC_PUBLISH_LOBBY_MEDIA"] = parse_bool(settings.get("RSC_PUBLISH_LOBBY_MEDIA", "1"), "RSC_PUBLISH_LOBBY_MEDIA")
	settings["RSC_ENABLE_ASSET_WEBROOT"] = parse_bool(settings.get("RSC_ENABLE_ASSET_WEBROOT", "1"), "RSC_ENABLE_ASSET_WEBROOT")
	settings["RSC_PRUNE_ENABLED"] = parse_bool(settings.get("RSC_PRUNE_ENABLED", "1"), "RSC_PRUNE_ENABLED")

	try:
		settings["RSC_COMPRESSION_LEVEL"] = int(settings.get("RSC_COMPRESSION_LEVEL", "6"))
		settings["RSC_MIN_FREE_BYTES"] = int(settings.get("RSC_MIN_FREE_BYTES", str(512 * 1024 * 1024)))
		settings["RSC_KEEP_UNREFERENCED"] = int(settings.get("RSC_KEEP_UNREFERENCED", "2"))
		settings["RSC_PRUNE_GRACE_HOURS"] = int(settings.get("RSC_PRUNE_GRACE_HOURS", "24"))
	except ValueError as error:
		raise DeployError(
			"RSC_COMPRESSION_LEVEL, RSC_MIN_FREE_BYTES, RSC_KEEP_UNREFERENCED and "
			"RSC_PRUNE_GRACE_HOURS must be integers"
		) from error
	if not 0 <= settings["RSC_COMPRESSION_LEVEL"] <= 9:
		raise DeployError("RSC_COMPRESSION_LEVEL must be between 0 and 9")
	if settings["RSC_MIN_FREE_BYTES"] < 0:
		raise DeployError("RSC_MIN_FREE_BYTES must not be negative")
	if settings["RSC_KEEP_UNREFERENCED"] < 0:
		raise DeployError("RSC_KEEP_UNREFERENCED must not be negative")
	if settings["RSC_PRUNE_GRACE_HOURS"] < 0:
		raise DeployError("RSC_PRUNE_GRACE_HOURS must not be negative")

	configured_roots = settings.get("RSC_DEPLOYMENT_ROOTS", "").strip()
	if configured_roots:
		deployment_roots = []
		for configured_root in configured_roots.split(";"):
			configured_root = configured_root.strip()
			if not configured_root:
				continue
			root = Path(configured_root).expanduser()
			if not root.is_absolute():
				raise DeployError("every RSC_DEPLOYMENT_ROOTS entry must be an absolute path")
			deployment_roots.append(root.resolve())
		if not deployment_roots:
			raise DeployError("RSC_DEPLOYMENT_ROOTS does not contain any paths")
		settings["RSC_DEPLOYMENT_ROOTS"] = deployment_roots
	else:
		settings["RSC_DEPLOYMENT_ROOTS"] = None
	return settings


def git_revision(game_dir, supplied_revision):
	try:
		result = subprocess.run(
			["git", "-C", str(game_dir), "rev-parse", "HEAD"],
			check=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.DEVNULL,
			text=True,
		)
		revision = result.stdout.strip()
	except (OSError, subprocess.CalledProcessError):
		revision = supplied_revision.strip()
	if not revision:
		revision = "unknown"
	revision = re.sub(r"[^A-Za-z0-9._-]", "-", revision)
	return revision[:12]


def dm_string(value):
	return '"{}"'.format(value.replace("\\", "\\\\").replace('"', '\\"'))


def dm_list(values):
	return "list({})".format(", ".join(dm_string(value) for value in values))


def archive_inputs_sha256(resource_input_hash, settings):
	"""Refine a resource fingerprint with a stable per-instance namespace."""
	digest = hashlib.sha256()
	_hash_record(digest, "version", "rsc-archive-inputs-v1")
	_hash_record(digest, "resources-and-build", resource_input_hash)
	namespace = settings["RSC_DEPLOYMENT_NAMESPACE"]
	if not namespace:
		# Separate TGS instances normally have distinct persistent config paths.
		# Hash rather than expose the host path in a public archive name.
		namespace = os.path.normcase(str(Path(settings["_CONFIG_PATH"]).resolve()))
	_hash_record(digest, "deployment-namespace", namespace)
	return digest.hexdigest()


def _hash_record(digest, record_type, name, payload=None):
	digest.update(record_type.encode("ascii"))
	digest.update(b"\0")
	digest.update(name.encode("utf-8", errors="surrogateescape"))
	digest.update(b"\0")
	if payload is not None:
		digest.update(str(len(payload)).encode("ascii"))
		digest.update(b"\0")
		digest.update(payload)
	digest.update(b"\0")


def _git_file_identities(game_dir):
	"""Return clean index blob IDs without reading every tracked file."""
	try:
		index_result = subprocess.run(
			["git", "-C", str(game_dir), "ls-files", "--stage", "-z"],
			check=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.DEVNULL,
		)
		dirty_result = subprocess.run(
			["git", "-C", str(game_dir), "status", "--porcelain=v1", "-z", "--untracked-files=no"],
			check=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.DEVNULL,
		)
	except (OSError, subprocess.CalledProcessError):
		return {}, set()

	identities = {}
	for record in index_result.stdout.split(b"\0"):
		if not record or b"\t" not in record:
			continue
		metadata, raw_name = record.split(b"\t", 1)
		parts = metadata.split()
		if len(parts) != 3 or parts[2] != b"0":
			continue
		name = raw_name.decode("utf-8", errors="surrogateescape").replace("\\", "/")
		identities[name] = "git:{}".format(parts[1].decode("ascii"))

	dirty = set()
	records = dirty_result.stdout.split(b"\0")
	index = 0
	while index < len(records):
		record = records[index]
		index += 1
		if len(record) < 4:
			continue
		status = record[:2]
		name = record[3:].decode("utf-8", errors="surrogateescape").replace("\\", "/")
		dirty.add(name)
		# Rename/copy porcelain records carry the second path as another NUL item.
		if b"R" in status or b"C" in status:
			if index < len(records):
				dirty.add(records[index].decode("utf-8", errors="surrogateescape").replace("\\", "/"))
				index += 1
	return identities, dirty


def _load_fingerprint_cache(cache_path):
	if not cache_path:
		return {"sources": {}, "files": {}}
	try:
		payload = json.loads(Path(cache_path).read_text(encoding="utf-8"))
		if payload.get("version") != 1:
			return {"sources": {}, "files": {}}
		return {
			"sources": payload.get("sources", {}),
			"files": payload.get("files", {}),
		}
	except (OSError, ValueError, json.JSONDecodeError):
		return {"sources": {}, "files": {}}


def _scan_resource_source(path):
	try:
		payload = Path(path).read_bytes()
	except OSError as error:
		raise DeployError("could not read resource-reference source {}: {}".format(path, error)) from error
	references = [
		match.group(1).decode("utf-8", errors="surrogateescape").replace("\\", "/")
		for match in RESOURCE_LITERAL.finditer(payload)
	]
	directives = []
	lines = payload.splitlines(keepends=True)
	line_number = 0
	while line_number < len(lines):
		line = lines[line_number]
		line_number += 1
		if not BUILD_CONFIGURATION_DIRECTIVE.match(line):
			continue
		directive = bytearray(line)
		while directive.rstrip(b"\r\n").endswith(b"\\") and line_number < len(lines):
			directive.extend(lines[line_number])
			line_number += 1
		directives.append(bytes(directive).decode("utf-8", errors="replace"))
	return references, directives


def resource_inputs_sha256(game_dir, cache_path=None):
	"""Hash statically referenced resource files deterministically.

	The source scan catches code changes which add or remove an already-existing
	resource. Unreferenced media is deliberately excluded: browser bundles and
	other repository assets which DreamMaker does not embed must not invalidate
	the entire RSC cache. Compiler define/undef directives are included so two
	build variants cannot accidentally select the same archive. A persistent
	per-instance cache avoids reparsing unchanged maps and rehashing unchanged
	resources on every TGS deployment.
	"""
	game_dir = Path(game_dir)
	resource_files = {}
	references = set()
	build_directives = []
	git_identities, dirty_files = _git_file_identities(game_dir)
	cache = _load_fingerprint_cache(cache_path)
	used_source_cache = {}
	used_file_cache = {}
	for relative_name in RESOURCE_BUILD_INPUTS:
		path = game_dir / relative_name
		if path.is_file():
			resource_files[relative_name] = path

	for current_root, directories, filenames in os.walk(game_dir):
		current_root = Path(current_root)
		directories[:] = sorted(
			directory for directory in directories if directory not in RESOURCE_SCAN_IGNORED_DIRS
		)
		for filename in sorted(filenames):
			path = current_root / filename
			try:
				relative_path = path.relative_to(game_dir)
			except ValueError:
				continue
			relative_name = relative_path.as_posix()
			if relative_name in (MANIFEST_NAME, GENERATED_DEFINES_NAME):
				continue
			suffix = path.suffix.lower()
			if suffix not in RESOURCE_REFERENCE_SOURCE_EXTENSIONS:
				continue
			identity = git_identities.get(relative_name) if relative_name not in dirty_files else None
			cached_source = cache["sources"].get(identity) if identity else None
			if isinstance(cached_source, dict):
				literals = cached_source.get("references", [])
				directives = cached_source.get("directives", [])
			else:
				literals, directives = _scan_resource_source(path)
			if identity:
				used_source_cache[identity] = {"references": literals, "directives": directives}
			for literal in literals:
				while literal.startswith("./"):
					literal = literal[2:]
				literal_path = Path(literal)
				if literal_path.is_absolute() or ".." in literal_path.parts:
					continue
				referenced_path = game_dir / literal_path
				if referenced_path.is_file():
					references.add(literal)
					resource_files[literal_path.as_posix()] = referenced_path
			for directive_number, directive in enumerate(directives):
				build_directives.append((relative_name, directive_number, directive))

	digest = hashlib.sha256()
	_hash_record(digest, "version", "rsc-resource-inputs-v3")
	for literal in sorted(references):
		_hash_record(digest, "reference", literal)
	for relative_name, directive_number, directive in sorted(build_directives):
		_hash_record(
			digest,
			"build-directive",
			"{}:{}".format(relative_name, directive_number),
			directive.encode("utf-8"),
		)
	for relative_name in sorted(resource_files):
		path = resource_files[relative_name]
		try:
			identity = git_identities.get(relative_name) if relative_name not in dirty_files else None
			file_hash = cache["files"].get(identity) if identity else None
			if not isinstance(file_hash, str) or not re.fullmatch(r"[0-9a-f]{64}", file_hash):
				file_hash = sha256_file(path)
			if identity:
				used_file_cache[identity] = file_hash
			_hash_record(digest, "file-sha256", relative_name, file_hash.encode("ascii"))
		except OSError as error:
			raise DeployError("could not read resource input {}: {}".format(path, error)) from error
	if cache_path:
		try:
			atomic_write(
				cache_path,
				json.dumps(
					{"version": 1, "sources": used_source_cache, "files": used_file_cache},
					ensure_ascii=True,
					sort_keys=True,
				) + "\n",
			)
		except OSError as error:
			log("warning: could not update resource fingerprint cache {}: {}".format(cache_path, error))
	return digest.hexdigest()


def prepare(args):
	game_dir = Path(args.game_dir).resolve()
	settings = load_settings(game_dir, args.config)
	if settings is None:
		# _compile_options.dm includes this file for every TGS build. Keep the
		# include valid even when external publishing is intentionally disabled.
		atomic_write(game_dir / GENERATED_DEFINES_NAME, "// External RSC publishing is disabled.\n")
		return

	revision = git_revision(game_dir, args.revision or "")
	stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
	cache_path = settings["_CONFIG_PATH"].parent / FINGERPRINT_CACHE_NAME
	input_hash = resource_inputs_sha256(game_dir, cache_path=cache_path)
	archive_input_hash = archive_inputs_sha256(input_hash, settings)
	archive_name = "{}-{}.zip".format(settings["RSC_ARCHIVE_PREFIX"], archive_input_hash)
	public_urls = ["{}/{}".format(base_url, archive_name) for base_url in settings["RSC_PUBLIC_BASE_URLS"]]
	public_url = public_urls[0]
	asset_manifest_name = None
	if settings["RSC_ENABLE_ASSET_WEBROOT"]:
		asset_manifest_name = "{}-{}-{}.txt".format(
			settings["RSC_ARCHIVE_PREFIX"], revision, archive_input_hash[:16]
		)

	generated_defines = "// Generated by tools/rsc_deploy; do not commit.\n"
	generated_defines += "#ifdef DEPLOYMENT_RSC_URLS\n#undef DEPLOYMENT_RSC_URLS\n#endif\n"
	generated_defines += "#define DEPLOYMENT_RSC_URLS {}\n".format(dm_list(public_urls))
	generated_defines += "#ifdef DEPLOYMENT_ASSET_MANIFEST_NAME\n#undef DEPLOYMENT_ASSET_MANIFEST_NAME\n#endif\n"
	generated_defines += "#define DEPLOYMENT_ASSET_MANIFEST_NAME {}\n".format(
		dm_string(asset_manifest_name) if asset_manifest_name else "null"
	)
	atomic_write(game_dir / GENERATED_DEFINES_NAME, generated_defines)

	manifest = {
		"archive_name": archive_name,
		"public_url": public_url,
		"public_urls": public_urls,
		"revision": revision,
		"resource_inputs_sha256": input_hash,
		"archive_inputs_sha256": archive_input_hash,
		"browser_asset_manifest": asset_manifest_name,
		"browser_asset_webroot_enabled": settings["RSC_ENABLE_ASSET_WEBROOT"],
		"lobby_media_enabled": settings["RSC_PUBLISH_LOBBY_MEDIA"],
		"created_utc": stamp,
	}
	atomic_write(game_dir / MANIFEST_NAME, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
	log("prepared {} RSC URL(s) for this compilation: {}".format(len(public_urls), ", ".join(public_urls)))


def sha256_file(path):
	digest = hashlib.sha256()
	with Path(path).open("rb") as source:
		for chunk in iter(lambda: source.read(1024 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def validate_archive(path, expected_rsc_size, expected_rsc_hash=None, size_mismatch_hint=None):
	path = Path(path)
	with zipfile.ZipFile(path, "r") as archive:
		entries = archive.infolist()
		if len(entries) != 1 or entries[0].filename != "tgstation.rsc":
			raise DeployError("{} has an unexpected layout".format(path))
		if entries[0].file_size != expected_rsc_size:
			message = "{} contains a different resource size: {}, expected {}".format(
				path, entries[0].file_size, expected_rsc_size
			)
			if size_mismatch_hint:
				message += "; {}".format(size_mismatch_hint)
			raise DeployError(
				message
			)
		digest = hashlib.sha256()
		with archive.open(entries[0], "r") as resource:
			for chunk in iter(lambda: resource.read(1024 * 1024), b""):
				digest.update(chunk)
		archive_hash = digest.hexdigest()
	if expected_rsc_hash is not None and archive_hash != expected_rsc_hash:
		raise DeployError(
			"archive {} contains rsc sha256 {}, expected {}".format(
				path, archive_hash, expected_rsc_hash
			)
		)
	return archive_hash


def validate_writable_directory(path, minimum_free_bytes, additional_required_bytes=0):
	path = Path(path)
	path.mkdir(parents=True, exist_ok=True)
	fd = None
	probe_name = None
	try:
		fd, probe_name = tempfile.mkstemp(prefix=".rsc-write-test-", dir=str(path))
		with os.fdopen(fd, "wb") as probe:
			fd = None
			probe.write(b"rsc-deploy write test\n")
			probe.flush()
			os.fsync(probe.fileno())
	except OSError as error:
		raise DeployError("{} is not writable: {}".format(path, error)) from error
	finally:
		if fd is not None:
			os.close(fd)
		if probe_name:
			try:
				os.unlink(probe_name)
			except OSError:
				pass

	free_bytes = shutil.disk_usage(path).free
	required_bytes = minimum_free_bytes + additional_required_bytes
	if free_bytes < required_bytes:
		raise DeployError(
			"{} has {} free bytes, but {} are required (including the configured reserve)".format(
				path, free_bytes, required_bytes
			)
		)
	return free_bytes


def _path_is_within(path, root):
	try:
		Path(path).resolve().relative_to(Path(root).resolve())
		return True
	except ValueError:
		return False


def deployment_roots(settings):
	configured_roots = settings["RSC_DEPLOYMENT_ROOTS"]
	if configured_roots:
		return configured_roots

	config_path = Path(settings["_CONFIG_PATH"])
	for parent in config_path.parents:
		if parent.name.lower() == "configuration":
			return [(parent.parent / "Game").resolve()]
	return []


def _read_deployment_manifest(manifest_path):
	try:
		manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
	except (OSError, json.JSONDecodeError) as error:
		raise DeployError("cannot read deployment manifest {}: {}".format(manifest_path, error)) from error
	archive_name = manifest.get("archive_name")
	if not isinstance(archive_name, str) or Path(archive_name).name != archive_name or not SAFE_NAME.fullmatch(archive_name):
		raise DeployError("deployment manifest {} has an unsafe archive_name".format(manifest_path))
	return manifest


def inventory_deployment_archives(root, max_depth=3):
	"""Inventory manifests referenced by deployable DMB directories below a TGS Game root."""
	root = Path(root).resolve()
	try:
		if not root.is_dir():
			raise DeployError("TGS deployment root does not exist: {}".format(root))
	except OSError as error:
		raise DeployError("cannot inspect TGS deployment root {}: {}".format(root, error)) from error

	protected = set()
	deployments = []
	dmb_count = 0
	stack = [(root, 0)]
	while stack:
		current, depth = stack.pop()
		try:
			entries = list(os.scandir(current))
		except OSError as error:
			raise DeployError("cannot list TGS deployment directory {}: {}".format(current, error)) from error

		manifest_path = None
		dmb_entries = []
		directories = []
		for entry in entries:
			try:
				if entry.name == MANIFEST_NAME and entry.is_file(follow_symlinks=True):
					manifest_path = Path(entry.path)
				elif entry.name.lower().endswith(".dmb") and entry.is_file(follow_symlinks=True):
					dmb_entries.append(entry.name)
				elif depth < max_depth and entry.is_dir(follow_symlinks=False):
					directories.append(Path(entry.path))
			except OSError as error:
				raise DeployError("cannot inspect TGS deployment entry {}: {}".format(entry.path, error)) from error

		if dmb_entries:
			dmb_count += len(dmb_entries)
			if manifest_path is None:
				raise DeployError(
					"DMB without {} found in {}; refusing to prune".format(MANIFEST_NAME, current)
				)
			manifest = _read_deployment_manifest(manifest_path)
			protected.add(manifest["archive_name"])
			deployments.append((manifest_path.resolve(), manifest))
			continue
		if manifest_path is not None:
			# A failed deployment may leave a manifest before TGS removes its
			# directory. Protecting it temporarily is safer than guessing.
			manifest = _read_deployment_manifest(manifest_path)
			protected.add(manifest["archive_name"])
			deployments.append((manifest_path.resolve(), manifest))
			continue
		for directory in sorted(directories, reverse=True):
			stack.append((directory, depth + 1))

	return protected, dmb_count, deployments


def prune_archives(game_dir, settings, current_archive_name):
	if not settings["RSC_PRUNE_ENABLED"]:
		return 0

	roots = deployment_roots(settings)
	if not roots:
		log("warning: archive cleanup skipped: could not infer the TGS Game directory")
		return 0
	game_dir = Path(game_dir).resolve()
	if not any(_path_is_within(game_dir, root) for root in roots):
		log("warning: archive cleanup skipped: current game directory is outside RSC_DEPLOYMENT_ROOTS")
		return 0

	try:
		protected = {current_archive_name}
		dmb_count = 0
		for root in roots:
			root_protected, root_dmb_count, _ = inventory_deployment_archives(root)
			protected.update(root_protected)
			dmb_count += root_dmb_count
		if not dmb_count:
			raise DeployError("no deployable DMBs were found below RSC_DEPLOYMENT_ROOTS")
	except DeployError as error:
		log("warning: archive cleanup skipped: {}".format(error))
		return 0

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	if not publish_dir.is_dir():
		return 0
	try:
		archives = sorted(
			publish_dir.glob("{}-*.zip".format(settings["RSC_ARCHIVE_PREFIX"])),
			key=lambda path: path.stat().st_mtime,
			reverse=True,
		)
	except OSError as error:
		log("warning: archive cleanup skipped: cannot inventory published archives: {}".format(error))
		return 0
	unreferenced = [archive for archive in archives if archive.name not in protected]
	keep_count = settings["RSC_KEEP_UNREFERENCED"]
	grace_seconds = settings["RSC_PRUNE_GRACE_HOURS"] * 60 * 60
	cutoff = dt.datetime.now(dt.timezone.utc).timestamp() - grace_seconds
	removed = 0
	for archive in unreferenced[keep_count:]:
		try:
			if archive.is_symlink() or not archive.is_file():
				log("warning: archive cleanup ignored non-regular path {}".format(archive))
				continue
			if archive.stat().st_mtime > cutoff:
				continue
			archive.unlink()
			removed += 1
			log("removed unreferenced archive {}".format(archive.name))
		except OSError as error:
			log("warning: could not remove unreferenced archive {}: {}".format(archive, error))
	log(
		"archive cleanup protected {} names from {} DMBs, kept {} newest unreferenced, removed {}".format(
			len(protected), dmb_count, min(keep_count, len(unreferenced)), removed
		)
	)
	return removed


def _safe_relative_content_path(value, setting_name):
	if not isinstance(value, str):
		raise DeployError("{} contains a non-string path".format(setting_name))
	normalized = value.replace("\\", "/").strip("/")
	path = Path(normalized)
	if not normalized or path.is_absolute() or ".." in path.parts:
		raise DeployError("{} contains an unsafe path: {}".format(setting_name, value))
	return Path(*path.parts)


def _deployment_content_inventories(game_dir, settings):
	roots = deployment_roots(settings)
	if not roots:
		raise DeployError("could not infer the TGS Game directory")
	game_dir = Path(game_dir).resolve()
	if not any(_path_is_within(game_dir, root) for root in roots):
		raise DeployError("current game directory is outside RSC_DEPLOYMENT_ROOTS")
	deployments = []
	dmb_count = 0
	for root in roots:
		_, root_dmb_count, root_deployments = inventory_deployment_archives(root)
		deployments.extend(root_deployments)
		dmb_count += root_dmb_count
	if not dmb_count:
		raise DeployError("no deployable DMBs were found below RSC_DEPLOYMENT_ROOTS")
	return deployments, dmb_count


def _read_browser_asset_inventory(path):
	assets = set()
	try:
		lines = Path(path).read_text(encoding="utf-8-sig").splitlines()
	except OSError as error:
		raise DeployError("cannot read browser asset inventory {}: {}".format(path, error)) from error
	for raw_line in lines:
		line = raw_line.strip()
		if not line or line.startswith("#"):
			continue
		assets.add(_safe_relative_content_path(line, "browser asset inventory"))
	return assets


def _prune_content_tree(root, protected_relative_paths, cutoff, ignored_top_level=None):
	root = Path(root)
	if not root.is_dir():
		return 0
	ignored_top_level = set(ignored_top_level or ())
	protected = {Path(path).as_posix() for path in protected_relative_paths}
	removed = 0
	try:
		files = sorted(root.rglob("*"), key=lambda path: len(path.parts), reverse=True)
	except OSError as error:
		raise DeployError("cannot inventory content store {}: {}".format(root, error)) from error
	for path in files:
		try:
			relative = path.relative_to(root)
			if relative.parts and relative.parts[0] in ignored_top_level:
				continue
			if path.is_symlink():
				continue
			if path.is_file():
				if relative.as_posix() in protected or path.stat().st_mtime > cutoff:
					continue
				path.unlink()
				removed += 1
			elif path.is_dir():
				try:
					path.rmdir()
				except OSError:
					pass
		except OSError as error:
			log("warning: could not prune content path {}: {}".format(path, error))
	return removed


def prune_content_stores(game_dir, settings, current_manifest_path, current_lobby_files):
	"""Prune only files unused by every deployable DMB, after a grace period."""
	if not settings["RSC_PRUNE_ENABLED"]:
		return 0
	try:
		deployments, dmb_count = _deployment_content_inventories(game_dir, settings)
	except DeployError as error:
		log("warning: content cleanup skipped: {}".format(error))
		return 0

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	lobby_subdir = settings["RSC_LOBBY_MEDIA_SUBDIR"]
	asset_subdir = settings["RSC_ASSET_WEBROOT_SUBDIR"]
	lobby_root = publish_dir / lobby_subdir
	asset_root = publish_dir / asset_subdir
	asset_manifest_root = asset_root / ".manifests"
	current_manifest_path = Path(current_manifest_path).resolve()
	protected_lobby = {
		_safe_relative_content_path(path, "current lobby media") for path in current_lobby_files
	}
	protected_assets = set()
	protected_asset_manifests = set()
	legacy_lobby_inventory = False
	legacy_asset_inventory = False

	for manifest_path, manifest in deployments:
		is_current = manifest_path == current_manifest_path
		if "lobby_media_enabled" not in manifest:
			if not is_current:
				legacy_lobby_inventory = True
		elif manifest["lobby_media_enabled"]:
			files = manifest.get("lobby_media_files")
			if files is None:
				if not is_current:
					legacy_lobby_inventory = True
			else:
				for path in files:
					protected_lobby.add(_safe_relative_content_path(path, "lobby_media_files"))

		if "browser_asset_webroot_enabled" not in manifest:
			if not is_current:
				legacy_asset_inventory = True
		elif manifest["browser_asset_webroot_enabled"]:
			manifest_name = manifest.get("browser_asset_manifest")
			if not isinstance(manifest_name, str) or Path(manifest_name).name != manifest_name or not SAFE_NAME.fullmatch(manifest_name):
				if not is_current:
					legacy_asset_inventory = True
				continue
			protected_asset_manifests.add(Path(manifest_name))
			inventory_path = asset_manifest_root / manifest_name
			if inventory_path.is_file():
				for relative_path in _read_browser_asset_inventory(inventory_path):
					protected_assets.add(relative_path)
					protected_assets.add(Path(relative_path.as_posix() + ".gz"))

	grace_seconds = settings["RSC_PRUNE_GRACE_HOURS"] * 60 * 60
	cutoff = dt.datetime.now(dt.timezone.utc).timestamp() - grace_seconds
	removed = 0
	if legacy_lobby_inventory:
		log("warning: lobby-media cleanup skipped while a deployable DMB has no content inventory")
	else:
		removed += _prune_content_tree(lobby_root, protected_lobby, cutoff)
	if legacy_asset_inventory:
		log("warning: browser-assets cleanup skipped while a deployable DMB has no content inventory")
	else:
		removed += _prune_content_tree(asset_root, protected_assets, cutoff, ignored_top_level={".manifests"})
		removed += _prune_content_tree(asset_manifest_root, protected_asset_manifests, cutoff)
	log("content cleanup protected assets from {} DMBs and removed {} stale files".format(dmb_count, removed))
	return removed


def collect_lobby_media(game_dir, config_root):
	media = {}

	def add_tree(relative_root, extensions):
		root = config_root / relative_root
		if not root.is_dir():
			return
		for source in sorted(root.rglob("*")):
			if source.is_file() and source.suffix.lower() in extensions:
				key = (Path("config") / source.relative_to(config_root)).as_posix()
				media[key] = source

	add_tree(Path("title_screens"), LOBBY_IMAGE_EXTENSIONS)
	add_tree(Path("title_music") / "sounds", LOBBY_AUDIO_EXTENSIONS)

	round_music_list = game_dir / "strings" / "round_start_sounds.txt"
	if round_music_list.is_file():
		for raw_line in round_music_list.read_text(encoding="utf-8-sig").splitlines():
			relative_path = raw_line.strip().replace("\\", "/")
			if not relative_path or relative_path.startswith("#"):
				continue
			source = game_dir / relative_path
			if source.is_file() and source.suffix.lower() in LOBBY_AUDIO_EXTENSIONS:
				media[relative_path] = source
	return media


def plan_lobby_media(game_dir, settings):
	if not settings["RSC_PUBLISH_LOBBY_MEDIA"]:
		return {}
	config_root = settings["_CONFIG_PATH"].parent
	plan = {}
	for source_key, source in collect_lobby_media(game_dir, config_root).items():
		file_hash = sha256_file(source)
		extension = source.suffix.lower()
		relative_target = Path(file_hash[:2]) / "asset.{}{}".format(file_hash, extension)
		plan[source_key] = (source, relative_target, file_hash)
	return plan


def publish_lobby_media(game_dir, settings, media_plan=None):
	config_root = settings["_CONFIG_PATH"].parent
	manifest_path = config_root / "lobby_media.json"
	if not settings["RSC_PUBLISH_LOBBY_MEDIA"]:
		try:
			manifest_path.unlink()
		except FileNotFoundError:
			pass
		log("disabled external lobby media manifest")
		return 0, 0, []

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	media_subdir = settings["RSC_LOBBY_MEDIA_SUBDIR"]
	media_root = publish_dir / media_subdir
	public_root = "{}/{}".format(settings["RSC_PUBLIC_BASE_URL"], media_subdir)
	mappings = {}
	total_size = 0
	published_hashes = set()
	if media_plan is None:
		media_plan = plan_lobby_media(game_dir, settings)
	for source_key, (source, relative_target, file_hash) in media_plan.items():
		atomic_copy(source, media_root / relative_target)
		mappings[source_key] = "{}/{}".format(public_root, relative_target.as_posix())
		if file_hash not in published_hashes:
			total_size += source.stat().st_size
			published_hashes.add(file_hash)

	payload = {
		"assets": mappings,
		"generated_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
		"version": 1,
	}
	atomic_write(manifest_path, json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
	os.chmod(manifest_path, 0o644)
	log("published {} lobby media mappings ({} unique bytes)".format(len(mappings), total_size))
	return len(mappings), total_size, sorted(path.as_posix() for _, path, _ in media_plan.values())


def remove_managed_asset_config(text):
	start = text.find(ASSET_CONFIG_BEGIN)
	if start >= 0:
		end = text.find(ASSET_CONFIG_END, start)
		if end < 0:
			raise DeployError("managed browser asset block is incomplete in resources.txt")
		end += len(ASSET_CONFIG_END)
		text = text[:start].rstrip() + "\n" + text[end:].lstrip()
	return text.rstrip() + "\n"


def configure_asset_webroot(settings):
	resources_path = settings["_CONFIG_PATH"].parent / "entries" / "resources.txt"
	if not resources_path.is_file():
		if settings["RSC_ENABLE_ASSET_WEBROOT"]:
			raise DeployError("{} is missing; cannot configure webroot asset transport".format(resources_path))
		return
	original_text = resources_path.read_text(encoding="utf-8-sig")
	# Managed values are appended and therefore take precedence while enabled.
	# Keep the operator's original ASSET_* lines intact so removing our block
	# restores their configuration exactly.
	text = remove_managed_asset_config(original_text)
	if not settings["RSC_ENABLE_ASSET_WEBROOT"]:
		if text != original_text:
			atomic_write(resources_path, text)
			log("disabled managed browser asset webroot configuration")
		return

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	asset_subdir = settings["RSC_ASSET_WEBROOT_SUBDIR"]
	asset_webroot = publish_dir / asset_subdir
	free_bytes = validate_writable_directory(asset_webroot, settings["RSC_MIN_FREE_BYTES"])
	(asset_webroot / ".manifests").mkdir(parents=True, exist_ok=True)
	webroot_value = asset_webroot.as_posix().rstrip("/") + "/"
	url_value = "{}/{}/".format(settings["RSC_PUBLIC_BASE_URL"], asset_subdir)
	text += "\n{}\n".format(ASSET_CONFIG_BEGIN)
	text += "ASSET_TRANSPORT webroot\n"
	text += "ASSET_CDN_WEBROOT {}\n".format(webroot_value)
	text += "ASSET_CDN_URL {}\n".format(url_value)
	text += "{}\n".format(ASSET_CONFIG_END)
	atomic_write(resources_path, text)
	log("configured writable browser assets at {} ({} free bytes)".format(url_value, free_bytes))


def publish(args):
	game_dir = Path(args.game_dir).resolve()
	settings = load_settings(game_dir, args.config)
	if settings is None:
		return

	manifest_path = game_dir / MANIFEST_NAME
	if not manifest_path.is_file():
		raise DeployError("{} is missing; PreCompile did not prepare this build".format(manifest_path))
	manifest = _read_deployment_manifest(manifest_path)
	rsc_path = game_dir / "tgstation.rsc"
	if not rsc_path.is_file():
		raise DeployError("DreamMaker did not create {}".format(rsc_path))
	rsc_hash = sha256_file(rsc_path)
	rsc_size = rsc_path.stat().st_size

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	if not publish_dir.is_absolute():
		raise DeployError("RSC_PUBLISH_DIR must be an absolute path")
	final_path = publish_dir / manifest["archive_name"]
	media_plan = plan_lobby_media(game_dir, settings)
	current_lobby_files = sorted(path.as_posix() for _, path, _ in media_plan.values())
	# Prune before checking free space so old, unreferenced archives cannot
	# or content-addressed browser/lobby files cannot deadlock a deployment by
	# consuming the room needed for their replacement.
	prune_archives(game_dir, settings, manifest["archive_name"])
	prune_content_stores(game_dir, settings, manifest_path, current_lobby_files)
	missing_lobby_bytes = 0
	seen_lobby_targets = set()
	for source, relative_target, _ in media_plan.values():
		if relative_target in seen_lobby_targets:
			continue
		seen_lobby_targets.add(relative_target)
		if not (publish_dir / settings["RSC_LOBBY_MEDIA_SUBDIR"] / relative_target).is_file():
			missing_lobby_bytes += source.stat().st_size
	validate_writable_directory(
		publish_dir,
		settings["RSC_MIN_FREE_BYTES"],
		additional_required_bytes=(0 if final_path.exists() else rsc_size) + missing_lobby_bytes,
	)
	archive_reused = False
	archive_rsc_hash = rsc_hash
	if final_path.exists():
		# DreamMaker writes compilation timestamps into tgstation.rsc, so two
		# builds from identical inputs are not byte-for-byte reproducible. The
		# content-addressed input fingerprint selects the archive; size still
		# catches resources being added or removed by conditional compilation.
		archive_rsc_hash = validate_archive(
			final_path,
			expected_rsc_size=rsc_size,
			size_mismatch_hint=(
				"the resource input fingerprint is stale or conditional compilation "
				"changed the embedded resource set"
			),
		)
		archive_reused = True
		log(
			"immutable archive {} has the expected RSC size; reusing it "
			"(archive sha256 {}, compiled sha256 {})".format(final_path, archive_rsc_hash, rsc_hash)
		)
	else:
		fd, temporary_name = tempfile.mkstemp(prefix=".{}-".format(final_path.name), suffix=".tmp", dir=str(publish_dir))
		os.close(fd)
		temporary_path = Path(temporary_name)
		try:
			compression = zipfile.ZIP_STORED if settings["RSC_COMPRESSION_LEVEL"] == 0 else zipfile.ZIP_DEFLATED
			with zipfile.ZipFile(
				temporary_path,
				"w",
				compression=compression,
				compresslevel=settings["RSC_COMPRESSION_LEVEL"] if compression == zipfile.ZIP_DEFLATED else None,
				allowZip64=True,
			) as archive:
				archive.write(rsc_path, arcname="tgstation.rsc")
			archive_rsc_hash = validate_archive(
				temporary_path,
				expected_rsc_size=rsc_size,
				expected_rsc_hash=rsc_hash,
			)
			with temporary_path.open("rb+") as archive_file:
				os.fsync(archive_file.fileno())
			os.chmod(temporary_path, 0o644)
			os.replace(str(temporary_path), str(final_path))
		except Exception:
			try:
				temporary_path.unlink()
			except OSError:
				pass
			raise

	manifest.update(
		{
			"archive_reused": archive_reused,
			"archive_rsc_sha256": archive_rsc_hash,
			"rsc_sha256": rsc_hash,
			"rsc_size": rsc_size,
			"zip_size": final_path.stat().st_size,
		}
	)
	media_count, media_size, lobby_media_files = publish_lobby_media(game_dir, settings, media_plan=media_plan)
	manifest["lobby_media_count"] = media_count
	manifest["lobby_media_size"] = media_size
	manifest["lobby_media_files"] = lobby_media_files
	configure_asset_webroot(settings)
	# This copy travels with the DMB. Future cleanup uses it (plus the runtime
	# browser inventory) to protect every file needed by deployable versions.
	atomic_write(manifest_path, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
	latest_manifest = publish_dir / "{}-latest.json".format(settings["RSC_ARCHIVE_PREFIX"])
	atomic_write(latest_manifest, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
	os.chmod(latest_manifest, 0o644)

	log(
		"published {} ({} bytes, archive rsc sha256 {}, compiled rsc sha256 {})".format(
			final_path,
			final_path.stat().st_size,
			manifest["archive_rsc_sha256"],
			manifest["rsc_sha256"],
		)
	)


def main():
	parser = argparse.ArgumentParser(description=__doc__)
	subparsers = parser.add_subparsers(dest="command", required=True)

	prepare_parser = subparsers.add_parser("prepare", help="embed a unique URL before DreamMaker runs")
	prepare_parser.add_argument("--game-dir", required=True)
	prepare_parser.add_argument("--revision", default="")
	prepare_parser.add_argument("--config", help="host settings file; defaults to GAME_DIR/config/rsc_deploy.env")
	prepare_parser.set_defaults(handler=prepare)

	publish_parser = subparsers.add_parser("publish", help="publish the matching archive after compilation")
	publish_parser.add_argument("--game-dir", required=True)
	publish_parser.add_argument("--config", help="host settings file; defaults to GAME_DIR/config/rsc_deploy.env")
	publish_parser.set_defaults(handler=publish)

	args = parser.parse_args()
	try:
		args.handler(args)
	except (DeployError, OSError, ValueError, zipfile.BadZipFile, json.JSONDecodeError) as error:
		log("ERROR: {}".format(error))
		return 1
	return 0


if __name__ == "__main__":
	sys.exit(main())

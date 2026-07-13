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
RESOURCE_EXTENSIONS = {
	".css",
	".dmi",
	".dmf",
	".flac",
	".gif",
	".htm",
	".html",
	".ico",
	".jpeg",
	".jpg",
	".js",
	".json",
	".mid",
	".midi",
	".mp3",
	".ogg",
	".otf",
	".png",
	".svg",
	".ttf",
	".wav",
	".webp",
	".woff",
	".woff2",
}
RESOURCE_REFERENCE_SOURCE_EXTENSIONS = {".dm", ".dme", ".dmm"}
RESOURCE_LITERAL = re.compile(rb"'([^'\r\n]+)'")
RESOURCE_BUILD_INPUTS = (".tgs.yml",)
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

	prefix = settings.get("RSC_ARCHIVE_PREFIX", "Moon-Blue")
	if not SAFE_NAME.fullmatch(prefix):
		raise DeployError("RSC_ARCHIVE_PREFIX may only contain letters, digits, dot, dash and underscore")
	settings["RSC_ARCHIVE_PREFIX"] = prefix
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

	try:
		settings["RSC_COMPRESSION_LEVEL"] = int(settings.get("RSC_COMPRESSION_LEVEL", "6"))
		settings["RSC_MIN_FREE_BYTES"] = int(settings.get("RSC_MIN_FREE_BYTES", str(512 * 1024 * 1024)))
	except ValueError as error:
		raise DeployError("RSC_COMPRESSION_LEVEL and RSC_MIN_FREE_BYTES must be integers") from error
	if not 0 <= settings["RSC_COMPRESSION_LEVEL"] <= 9:
		raise DeployError("RSC_COMPRESSION_LEVEL must be between 0 and 9")
	if settings["RSC_MIN_FREE_BYTES"] < 0:
		raise DeployError("RSC_MIN_FREE_BYTES must not be negative")
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


def _hash_file_record(digest, name, path):
	path = Path(path)
	digest.update(b"file\0")
	digest.update(name.encode("utf-8", errors="surrogateescape"))
	digest.update(b"\0")
	digest.update(str(path.stat().st_size).encode("ascii"))
	digest.update(b"\0")
	with path.open("rb") as source:
		for chunk in iter(lambda: source.read(1024 * 1024), b""):
			digest.update(chunk)
	digest.update(b"\0")


def resource_inputs_sha256(game_dir):
	"""Hash resource files and static DM resource references deterministically.

	Hashing static references as well as the files catches code changes which add
	or remove an already-existing resource. The actual compiled RSC hash is still
	checked during publish so an incomplete fingerprint can never overwrite or
	reuse an incompatible immutable archive.
	"""
	game_dir = Path(game_dir)
	resource_files = {}
	references = set()
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
			if relative_path.parts[0].lower() in ("icons", "sound") or suffix in RESOURCE_EXTENSIONS:
				resource_files[relative_name] = path
			if suffix not in RESOURCE_REFERENCE_SOURCE_EXTENSIONS:
				continue
			try:
				source_lines = path.open("rb")
			except OSError as error:
				raise DeployError("could not read resource-reference source {}: {}".format(path, error)) from error
			with source_lines:
				for source_line in source_lines:
					for match in RESOURCE_LITERAL.finditer(source_line):
						literal = match.group(1).decode("utf-8", errors="surrogateescape").replace("\\", "/")
						while literal.startswith("./"):
							literal = literal[2:]
						literal_path = Path(literal)
						if literal_path.is_absolute() or ".." in literal_path.parts:
							continue
						referenced_path = game_dir / literal_path
						if referenced_path.is_file():
							references.add(literal)
							resource_files[literal_path.as_posix()] = referenced_path

	digest = hashlib.sha256()
	_hash_record(digest, "version", "rsc-resource-inputs-v1")
	for literal in sorted(references):
		_hash_record(digest, "reference", literal)
	for relative_name in sorted(resource_files):
		path = resource_files[relative_name]
		try:
			_hash_file_record(digest, relative_name, path)
		except OSError as error:
			raise DeployError("could not read resource input {}: {}".format(path, error)) from error
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
	input_hash = resource_inputs_sha256(game_dir)
	archive_name = "{}-{}.zip".format(settings["RSC_ARCHIVE_PREFIX"], input_hash)
	public_url = "{}/{}".format(settings["RSC_PUBLIC_BASE_URL"], archive_name)

	generated_defines = "// Generated by tools/rsc_deploy; do not commit.\n"
	generated_defines += "#ifdef DEPLOYMENT_RSC_URL\n#undef DEPLOYMENT_RSC_URL\n#endif\n"
	generated_defines += "#define DEPLOYMENT_RSC_URL {}\n".format(dm_string(public_url))
	atomic_write(game_dir / GENERATED_DEFINES_NAME, generated_defines)

	manifest = {
		"archive_name": archive_name,
		"public_url": public_url,
		"revision": revision,
		"resource_inputs_sha256": input_hash,
		"created_utc": stamp,
	}
	atomic_write(game_dir / MANIFEST_NAME, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
	log("prepared {} for this compilation".format(public_url))


def sha256_file(path):
	digest = hashlib.sha256()
	with Path(path).open("rb") as source:
		for chunk in iter(lambda: source.read(1024 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def validate_archive(path, expected_rsc_hash, expected_rsc_size):
	path = Path(path)
	with zipfile.ZipFile(path, "r") as archive:
		entries = archive.infolist()
		if len(entries) != 1 or entries[0].filename != "tgstation.rsc":
			raise DeployError("{} has an unexpected layout".format(path))
		if entries[0].file_size != expected_rsc_size:
			raise DeployError("{} contains a different resource size".format(path))
		digest = hashlib.sha256()
		with archive.open(entries[0], "r") as resource:
			for chunk in iter(lambda: resource.read(1024 * 1024), b""):
				digest.update(chunk)
		archive_hash = digest.hexdigest()
	if archive_hash != expected_rsc_hash:
		raise DeployError(
			"immutable archive {} already exists with rsc sha256 {}, expected {}".format(
				path, archive_hash, expected_rsc_hash
			)
		)


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


def publish_lobby_media(game_dir, settings):
	if not settings["RSC_PUBLISH_LOBBY_MEDIA"]:
		return 0, 0

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	config_root = settings["_CONFIG_PATH"].parent
	media_subdir = settings["RSC_LOBBY_MEDIA_SUBDIR"]
	media_root = publish_dir / media_subdir
	public_root = "{}/{}".format(settings["RSC_PUBLIC_BASE_URL"], media_subdir)
	mappings = {}
	total_size = 0
	published_hashes = set()
	for source_key, source in collect_lobby_media(game_dir, config_root).items():
		file_hash = sha256_file(source)
		extension = source.suffix.lower()
		relative_target = Path(file_hash[:2]) / "asset.{}{}".format(file_hash, extension)
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
	manifest_path = config_root / "lobby_media.json"
	atomic_write(manifest_path, json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
	os.chmod(manifest_path, 0o644)
	log("published {} lobby media mappings ({} unique bytes)".format(len(mappings), total_size))
	return len(mappings), total_size


def remove_managed_asset_config(text):
	start = text.find(ASSET_CONFIG_BEGIN)
	if start >= 0:
		end = text.find(ASSET_CONFIG_END, start)
		if end < 0:
			raise DeployError("managed browser asset block is incomplete in resources.txt")
		end += len(ASSET_CONFIG_END)
		text = text[:start].rstrip() + "\n" + text[end:].lstrip()
	active_setting = re.compile(r"^\s*(ASSET_TRANSPORT|ASSET_CDN_WEBROOT|ASSET_CDN_URL)\s+", re.IGNORECASE)
	return "\n".join(line for line in text.splitlines() if not active_setting.match(line)).rstrip() + "\n"


def configure_asset_webroot(settings):
	if not settings["RSC_ENABLE_ASSET_WEBROOT"]:
		return

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	asset_subdir = settings["RSC_ASSET_WEBROOT_SUBDIR"]
	asset_webroot = publish_dir / asset_subdir
	free_bytes = validate_writable_directory(asset_webroot, settings["RSC_MIN_FREE_BYTES"])
	resources_path = settings["_CONFIG_PATH"].parent / "entries" / "resources.txt"
	if not resources_path.is_file():
		raise DeployError("{} is missing; cannot configure webroot asset transport".format(resources_path))
	text = remove_managed_asset_config(resources_path.read_text(encoding="utf-8-sig"))
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
	manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
	rsc_path = game_dir / "tgstation.rsc"
	if not rsc_path.is_file():
		raise DeployError("DreamMaker did not create {}".format(rsc_path))
	rsc_hash = sha256_file(rsc_path)
	rsc_size = rsc_path.stat().st_size

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	if not publish_dir.is_absolute():
		raise DeployError("RSC_PUBLISH_DIR must be an absolute path")
	final_path = publish_dir / manifest["archive_name"]
	validate_writable_directory(
		publish_dir,
		settings["RSC_MIN_FREE_BYTES"],
		additional_required_bytes=0 if final_path.exists() else rsc_size,
	)
	archive_reused = False
	if final_path.exists():
		validate_archive(final_path, rsc_hash, rsc_size)
		archive_reused = True
		log("immutable archive {} already contains the same RSC; reusing it".format(final_path))
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
			validate_archive(temporary_path, rsc_hash, rsc_size)
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
			"rsc_sha256": rsc_hash,
			"rsc_size": rsc_size,
			"zip_size": final_path.stat().st_size,
		}
	)
	media_count, media_size = publish_lobby_media(game_dir, settings)
	manifest["lobby_media_count"] = media_count
	manifest["lobby_media_size"] = media_size
	configure_asset_webroot(settings)
	latest_manifest = publish_dir / "{}-latest.json".format(settings["RSC_ARCHIVE_PREFIX"])
	atomic_write(latest_manifest, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
	os.chmod(latest_manifest, 0o644)

	log("published {} ({} bytes, rsc sha256 {})".format(final_path, final_path.stat().st_size, manifest["rsc_sha256"]))


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

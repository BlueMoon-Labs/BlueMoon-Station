#!/usr/bin/env python3
"""Prepare and atomically publish a versioned BYOND resource archive for TGS."""

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import zipfile


MANIFEST_NAME = ".rsc-deploy.json"
BEGIN_MARKER = "// BEGIN GENERATED RSC DEPLOYMENT URL"
END_MARKER = "// END GENERATED RSC DEPLOYMENT URL"
SAFE_NAME = re.compile(r"^[A-Za-z0-9._-]+$")


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

	try:
		settings["RSC_KEEP_VERSIONS"] = max(2, int(settings.get("RSC_KEEP_VERSIONS", "5")))
		settings["RSC_COMPRESSION_LEVEL"] = int(settings.get("RSC_COMPRESSION_LEVEL", "6"))
	except ValueError as error:
		raise DeployError("RSC_KEEP_VERSIONS and RSC_COMPRESSION_LEVEL must be integers") from error
	if not 0 <= settings["RSC_COMPRESSION_LEVEL"] <= 9:
		raise DeployError("RSC_COMPRESSION_LEVEL must be between 0 and 9")
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


def remove_generated_block(text):
	start = text.find(BEGIN_MARKER)
	if start < 0:
		return text.rstrip() + "\n"
	end = text.find(END_MARKER, start)
	if end < 0:
		raise DeployError("generated RSC marker is incomplete in code/_compile_options.dm")
	end += len(END_MARKER)
	return (text[:start].rstrip() + "\n" + text[end:].lstrip()).rstrip() + "\n"


def dm_string(value):
	return '"{}"'.format(value.replace("\\", "\\\\").replace('"', '\\"'))


def prepare(args):
	game_dir = Path(args.game_dir).resolve()
	settings = load_settings(game_dir, args.config)
	if settings is None:
		return

	revision = git_revision(game_dir, args.revision or "")
	stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
	archive_name = "{}-{}-{}.zip".format(settings["RSC_ARCHIVE_PREFIX"], revision, stamp)
	public_url = "{}/{}".format(settings["RSC_PUBLIC_BASE_URL"], archive_name)

	compile_options = game_dir / "code" / "_compile_options.dm"
	text = remove_generated_block(compile_options.read_text(encoding="utf-8"))
	text += "\n{}\n#ifdef DEPLOYMENT_RSC_URL\n#undef DEPLOYMENT_RSC_URL\n#endif\n".format(BEGIN_MARKER)
	text += "#define DEPLOYMENT_RSC_URL {}\n{}\n".format(dm_string(public_url), END_MARKER)
	atomic_write(compile_options, text)

	manifest = {
		"archive_name": archive_name,
		"public_url": public_url,
		"revision": revision,
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

	publish_dir = Path(settings["RSC_PUBLISH_DIR"]).expanduser()
	if not publish_dir.is_absolute():
		raise DeployError("RSC_PUBLISH_DIR must be an absolute path")
	publish_dir.mkdir(parents=True, exist_ok=True)
	final_path = publish_dir / manifest["archive_name"]
	if final_path.exists():
		raise DeployError("refusing to overwrite immutable archive {}".format(final_path))

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
		with zipfile.ZipFile(temporary_path, "r") as archive:
			entries = archive.infolist()
			if len(entries) != 1 or entries[0].filename != "tgstation.rsc":
				raise DeployError("created archive has an unexpected layout")
			if entries[0].file_size != rsc_path.stat().st_size:
				raise DeployError("created archive has an unexpected resource size")
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
			"rsc_sha256": sha256_file(rsc_path),
			"rsc_size": rsc_path.stat().st_size,
			"zip_size": final_path.stat().st_size,
		}
	)
	latest_manifest = publish_dir / "{}-latest.json".format(settings["RSC_ARCHIVE_PREFIX"])
	atomic_write(latest_manifest, json.dumps(manifest, indent=2, sort_keys=True) + "\n")
	os.chmod(latest_manifest, 0o644)

	archives = sorted(
		publish_dir.glob("{}-*.zip".format(settings["RSC_ARCHIVE_PREFIX"])),
		key=lambda path: path.stat().st_mtime,
		reverse=True,
	)
	for old_archive in archives[settings["RSC_KEEP_VERSIONS"] :]:
		try:
			old_archive.unlink()
			log("removed old rollback archive {}".format(old_archive.name))
		except OSError as error:
			log("warning: could not remove {}: {}".format(old_archive, error))

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

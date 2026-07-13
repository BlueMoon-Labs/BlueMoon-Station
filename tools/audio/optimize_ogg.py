#!/usr/bin/env python3
"""Find oversized/mislabeled .ogg files and re-encode them as Ogg Vorbis."""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


DEFAULT_ROOTS = ("sound", "modular_bluemoon", "modular_citadel", "modular_sand", "modular_splurt")
MIN_MISLABELED_SIZE = 256 * 1024
MIN_HIGH_BITRATE_SIZE = 1024 * 1024
HIGH_BITRATE = 256_000


def probe(path):
	command = [
		"ffprobe",
		"-v",
		"error",
		"-select_streams",
		"a:0",
		"-show_entries",
		"stream=codec_name:format=duration,bit_rate",
		"-of",
		"json",
		str(path),
	]
	result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
	if result.returncode:
		return None
	payload = json.loads(result.stdout)
	if not payload.get("streams"):
		return None
	stream = payload["streams"][0]
	container = payload.get("format", {})
	return {
		"codec": stream.get("codec_name", ""),
		"duration": float(container.get("duration") or 0),
		"bitrate": int(container.get("bit_rate") or 0),
	}


def needs_optimization(path, metadata):
	size = path.stat().st_size
	return (
		(metadata["codec"] != "vorbis" and size >= MIN_MISLABELED_SIZE)
		or (metadata["bitrate"] >= HIGH_BITRATE and size >= MIN_HIGH_BITRATE_SIZE)
	)


def optimize(path, metadata, quality):
	old_size = path.stat().st_size
	fd, temporary_name = tempfile.mkstemp(prefix=".{}-".format(path.stem), suffix=".ogg", dir=str(path.parent))
	os.close(fd)
	temporary_path = Path(temporary_name)
	try:
		command = [
			"ffmpeg",
			"-v",
			"error",
			"-y",
			"-i",
			str(path),
			"-map_metadata",
			"0",
			"-vn",
			"-c:a",
			"libvorbis",
			"-q:a",
			str(quality),
			str(temporary_path),
		]
		result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
		if result.returncode:
			raise RuntimeError(result.stderr.strip() or "ffmpeg failed")

		new_metadata = probe(temporary_path)
		if not new_metadata or new_metadata["codec"] != "vorbis":
			raise RuntimeError("ffmpeg output is not Ogg Vorbis")
		allowed_duration_delta = max(0.25, metadata["duration"] * 0.002)
		if abs(new_metadata["duration"] - metadata["duration"]) > allowed_duration_delta:
			raise RuntimeError(
				"duration changed from {:.3f}s to {:.3f}s".format(metadata["duration"], new_metadata["duration"])
			)
		new_size = temporary_path.stat().st_size
		if new_size >= old_size:
			raise RuntimeError("re-encoded file is not smaller")

		os.replace(str(temporary_path), str(path))
		return old_size, new_size
	finally:
		try:
			temporary_path.unlink()
		except OSError:
			pass


def main():
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--apply", action="store_true", help="replace selected files; default is an audit only")
	parser.add_argument("--quality", type=float, default=4, help="libvorbis VBR quality (default: 4)")
	parser.add_argument("--workers", type=int, default=min(8, os.cpu_count() or 1))
	parser.add_argument("roots", nargs="*", default=list(DEFAULT_ROOTS))
	args = parser.parse_args()

	for tool in ("ffprobe", "ffmpeg"):
		if shutil.which(tool) is None:
			parser.error("{} is required".format(tool))

	paths = []
	for root_name in args.roots:
		root = Path(root_name)
		if root.is_file() and root.suffix.lower() == ".ogg":
			paths.append(root)
		elif root.is_dir():
			paths.extend(root.rglob("*.ogg"))
	paths = sorted(set(path.resolve() for path in paths))

	selected = []
	with ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
		futures = {executor.submit(probe, path): path for path in paths}
		for future in as_completed(futures):
			path = futures[future]
			metadata = future.result()
			if metadata and needs_optimization(path, metadata):
				selected.append((path, metadata))
	selected.sort(key=lambda item: item[0].as_posix().lower())

	old_total = sum(path.stat().st_size for path, _ in selected)
	print("Selected {} files ({:.1f} MiB)".format(len(selected), old_total / 1024 / 1024))
	for path, metadata in selected:
		print(
			"{:.2f} MiB {:>9} {:>4} kbps {}".format(
				path.stat().st_size / 1024 / 1024,
				metadata["codec"],
				round(metadata["bitrate"] / 1000),
				path,
			)
		)

	if not args.apply:
		return 0

	results = []
	errors = []
	with ThreadPoolExecutor(max_workers=max(1, args.workers)) as executor:
		futures = {executor.submit(optimize, path, metadata, args.quality): path for path, metadata in selected}
		for future in as_completed(futures):
			path = futures[future]
			try:
				results.append(future.result())
			except Exception as error:
				errors.append((path, error))
				print("ERROR {}: {}".format(path, error), file=sys.stderr)

	new_total = sum(new_size for _, new_size in results)
	processed_old_total = sum(old_size for old_size, _ in results)
	print(
		"Optimized {} files: {:.1f} MiB -> {:.1f} MiB (saved {:.1f} MiB)".format(
			len(results),
			processed_old_total / 1024 / 1024,
			new_total / 1024 / 1024,
			(processed_old_total - new_total) / 1024 / 1024,
		)
	)
	return 1 if errors else 0


if __name__ == "__main__":
	sys.exit(main())

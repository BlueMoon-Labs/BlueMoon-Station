#!/usr/bin/env python3

import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


SCRIPT = Path(__file__).with_name("rsc_deploy.py")
sys.path.insert(0, str(SCRIPT.parent))
import rsc_deploy  # noqa: E402


def dreammaker_rsc_fixture(compilation_timestamp):
	"""Model DreamMaker resource records with build-time and source mtimes."""
	entries = (
		(b"icons/test.dmi", 1_720_000_001, b"DMI resource contents"),
		(b"sound/test.ogg", 1_720_000_002, b"OggS resource contents"),
	)
	result = bytearray(b"RSC fixture\0")
	for name, source_mtime, payload in entries:
		result.extend(struct.pack("<II", compilation_timestamp, source_mtime))
		result.extend(struct.pack("<II", len(name), len(payload)))
		result.extend(name)
		result.extend(payload)
	return bytes(result)


class RscDeployIntegrationTest(unittest.TestCase):
	def test_archive_media_and_webroot_are_published_together(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			root = Path(temporary_directory)
			game_dir = root / "Game" / "current" / "A"
			config_root = root / "Configuration" / "GameStaticFiles" / "config"
			publish_dir = root / "nginx" / "byond_rsc"
			settings_path = config_root / "rsc_deploy.env"

			(game_dir / "code").mkdir(parents=True)
			(game_dir / "strings").mkdir(parents=True)
			(game_dir / "sound" / "ambience").mkdir(parents=True)
			(config_root / "entries").mkdir(parents=True)
			(config_root / "title_screens").mkdir(parents=True)
			(config_root / "title_music" / "sounds").mkdir(parents=True)

			(game_dir / "code" / "_compile_options.dm").write_text(
				"#define DEPLOYMENT_RSC_URLS null\n", encoding="utf-8"
			)
			compiled_rsc = dreammaker_rsc_fixture(1_720_000_100)
			(game_dir / "tgstation.rsc").write_bytes(compiled_rsc)
			(game_dir / "tgstation.dmb").write_bytes(b"compiled game")
			(game_dir / "strings" / "round_start_sounds.txt").write_text(
				"sound/ambience/title1.ogg\n", encoding="utf-8"
			)
			round_music = b"round music"
			lobby_music = b"custom lobby music"
			lobby_image = b"GIF89a lobby background"
			(game_dir / "sound" / "ambience" / "title1.ogg").write_bytes(round_music)
			(config_root / "title_music" / "sounds" / "custom.ogg").write_bytes(lobby_music)
			(config_root / "title_screens" / "cyberpunk.gif").write_bytes(lobby_image)
			(config_root / "title_screens" / "cyberpunk-copy.gif").write_bytes(lobby_image)
			(config_root / "entries" / "resources.txt").write_text(
				"# Browser assets\n"
				"#ASSET_TRANSPORT webroot\n"
				"#ASSET_CDN_WEBROOT data/asset-store/\n"
				"ASSET_TRANSPORT simple\n"
				"ASSET_CDN_WEBROOT old-assets/\n"
				"ASSET_CDN_URL http://old.example.test/\n",
				encoding="utf-8",
			)
			settings_path.write_text(
				"RSC_PUBLIC_BASE_URL=http://download.example.test/byond_rsc\n"
				"RSC_PUBLIC_MIRROR_BASE_URLS=https://mirror-one.example.test/rsc/;"
				"https://mirror-two.example.test/byond_rsc\n"
				"RSC_PUBLISH_DIR={}\n"
				"RSC_ARCHIVE_PREFIX=Moon-Test\n"
				"RSC_COMPRESSION_LEVEL=0\n"
				"RSC_MIN_FREE_BYTES=0\n"
				"RSC_KEEP_UNREFERENCED=0\n"
				"RSC_PRUNE_GRACE_HOURS=0\n"
				"RSC_PUBLISH_LOBBY_MEDIA=1\n"
				"RSC_ENABLE_ASSET_WEBROOT=1\n".format(publish_dir.as_posix()),
				encoding="utf-8",
			)

			common = ["--game-dir", str(game_dir), "--config", str(settings_path)]
			original_compile_options = (game_dir / "code" / "_compile_options.dm").read_text(encoding="utf-8")
			subprocess.run(
				[sys.executable, str(SCRIPT), "prepare", *common, "--revision", "abcdef0123456789"],
				check=True,
			)
			build_manifest = json.loads((game_dir / ".rsc-deploy.json").read_text(encoding="utf-8"))
			self.assertEqual(
				(game_dir / "code" / "_compile_options.dm").read_text(encoding="utf-8"),
				original_compile_options,
			)
			self.assertIn(
				build_manifest["public_url"],
				(game_dir / ".rsc-deployment.dm").read_text(encoding="utf-8"),
			)
			expected_public_urls = [
				"http://download.example.test/byond_rsc/{}".format(build_manifest["archive_name"]),
				"https://mirror-one.example.test/rsc/{}".format(build_manifest["archive_name"]),
				"https://mirror-two.example.test/byond_rsc/{}".format(build_manifest["archive_name"]),
			]
			self.assertEqual(build_manifest["public_urls"], expected_public_urls)
			generated_defines = (game_dir / ".rsc-deployment.dm").read_text(encoding="utf-8")
			self.assertIn("#define DEPLOYMENT_RSC_URLS list(", generated_defines)
			self.assertIn("#define DEPLOYMENT_ASSET_MANIFEST_NAME \"Moon-Test-", generated_defines)
			for public_url in expected_public_urls:
				self.assertIn(public_url, generated_defines)
			self.assertEqual(
				build_manifest["archive_name"],
				"Moon-Test-{}.zip".format(build_manifest["archive_inputs_sha256"]),
			)

			# A pure logic change must retain the resource URL.
			(game_dir / "code" / "code_only.dm").write_text("/proc/code_only_change()\n\treturn 42\n", encoding="utf-8")
			subprocess.run(
				[sys.executable, str(SCRIPT), "prepare", *common, "--revision", "different-revision"],
				check=True,
			)
			code_only_manifest = json.loads((game_dir / ".rsc-deploy.json").read_text(encoding="utf-8"))
			self.assertEqual(code_only_manifest["archive_name"], build_manifest["archive_name"])

			old_game_dir = root / "Game" / "old" / "A"
			old_game_dir.mkdir(parents=True)
			(old_game_dir / "tgstation.dmb").write_bytes(b"active old game")
			protected_archive = publish_dir / "Moon-Test-protected.zip"
			stale_archive = publish_dir / "Moon-Test-stale.zip"
			publish_dir.mkdir(parents=True)
			protected_archive.write_bytes(b"referenced by active DMB")
			stale_archive.write_bytes(b"unreferenced")
			(old_game_dir / ".rsc-deploy.json").write_text(
				json.dumps({"archive_name": protected_archive.name}), encoding="utf-8"
			)

			subprocess.run([sys.executable, str(SCRIPT), "publish", *common], check=True)
			# Publishing the same content-addressed RSC again is an idempotent success.
			subprocess.run([sys.executable, str(SCRIPT), "publish", *common], check=True)
			self.assertFalse(stale_archive.exists())
			self.assertEqual(protected_archive.read_bytes(), b"referenced by active DMB")
			# Reconfiguring an existing instance must not duplicate the managed
			# block or retain stale active CDN settings.
			loaded_settings = rsc_deploy.load_settings(game_dir, settings_path)
			rsc_deploy.configure_asset_webroot(loaded_settings)
			rsc_deploy.configure_asset_webroot(loaded_settings)
			archive_path = publish_dir / build_manifest["archive_name"]
			with zipfile.ZipFile(archive_path) as archive:
				self.assertEqual(archive.namelist(), ["tgstation.rsc"])
				self.assertEqual(archive.read("tgstation.rsc"), (game_dir / "tgstation.rsc").read_bytes())

			media_manifest = json.loads((config_root / "lobby_media.json").read_text(encoding="utf-8"))
			expected = {
				"config/title_music/sounds/custom.ogg": lobby_music,
				"config/title_screens/cyberpunk-copy.gif": lobby_image,
				"config/title_screens/cyberpunk.gif": lobby_image,
				"sound/ambience/title1.ogg": round_music,
			}
			self.assertEqual(set(media_manifest["assets"]), set(expected))
			for source_name, source_payload in expected.items():
				url = media_manifest["assets"][source_name]
				self.assertTrue(url.startswith("http://download.example.test/byond_rsc/lobby-media/"))
				relative_path = url.split("/lobby-media/", 1)[1]
				self.assertEqual((publish_dir / "lobby-media" / relative_path).read_bytes(), source_payload)
			self.assertEqual(
				media_manifest["assets"]["config/title_screens/cyberpunk.gif"],
				media_manifest["assets"]["config/title_screens/cyberpunk-copy.gif"],
			)

			resources = (config_root / "entries" / "resources.txt").read_text(encoding="utf-8")
			self.assertEqual(resources.count("# BEGIN MANAGED EXTERNAL BROWSER ASSETS"), 1)
			self.assertEqual(resources.count("\nASSET_TRANSPORT webroot\n"), 1)
			self.assertIn("ASSET_CDN_WEBROOT {}/browser-assets/".format(publish_dir.as_posix()), resources)
			self.assertIn("ASSET_CDN_URL http://download.example.test/byond_rsc/browser-assets/", resources)
			# Operator values remain below the managed override and become active
			# again when external webroot management is disabled.
			self.assertIn("ASSET_TRANSPORT simple", resources)
			self.assertIn("ASSET_CDN_WEBROOT old-assets/", resources)
			self.assertIn("ASSET_CDN_URL http://old.example.test/", resources)
			self.assertTrue((publish_dir / "browser-assets").is_dir())
			self.assertTrue((publish_dir / "browser-assets" / ".manifests").is_dir())

			latest = json.loads((publish_dir / "Moon-Test-latest.json").read_text(encoding="utf-8"))
			self.assertTrue(latest["archive_reused"])
			self.assertEqual(latest["archive_rsc_sha256"], latest["rsc_sha256"])
			self.assertEqual(latest["lobby_media_count"], 4)
			self.assertEqual(latest["lobby_media_size"], sum(map(len, set(expected.values()))))

			# DreamMaker timestamps make repeated RSC builds bytewise different.
			# Rebuild the same resource records with another compilation time: the
			# size and source mtimes stay fixed, while the compiled bytes differ.
			original_archive = archive_path.read_bytes()
			timestamp_variant = dreammaker_rsc_fixture(1_720_000_207)
			self.assertEqual(len(timestamp_variant), len(compiled_rsc))
			self.assertNotEqual(timestamp_variant, compiled_rsc)
			(game_dir / "tgstation.rsc").write_bytes(timestamp_variant)
			result = subprocess.run(
				[sys.executable, str(SCRIPT), "publish", *common],
				check=True,
				capture_output=True,
				text=True,
			)
			self.assertIn("has the expected RSC size; reusing it", result.stdout)
			self.assertEqual(archive_path.read_bytes(), original_archive)
			latest = json.loads((publish_dir / "Moon-Test-latest.json").read_text(encoding="utf-8"))
			self.assertNotEqual(latest["archive_rsc_sha256"], latest["rsc_sha256"])

			# A changed resource set normally changes the RSC size and must not
			# reuse an archive selected by a stale pre-compile fingerprint.
			(game_dir / "tgstation.rsc").write_bytes(b"different size")
			result = subprocess.run(
				[sys.executable, str(SCRIPT), "publish", *common],
				check=False,
				capture_output=True,
				text=True,
			)
			self.assertNotEqual(result.returncode, 0)
			self.assertIn("contains a different resource size", result.stdout)
			self.assertIn("resource input fingerprint is stale", result.stdout)
			self.assertEqual(archive_path.read_bytes(), original_archive)

			# Disabling the feature must remove settings written by an earlier
			# enabled deployment instead of leaving webroot transport active.
			loaded_settings["RSC_ENABLE_ASSET_WEBROOT"] = False
			rsc_deploy.configure_asset_webroot(loaded_settings)
			resources = (config_root / "entries" / "resources.txt").read_text(encoding="utf-8")
			self.assertNotIn("# BEGIN MANAGED EXTERNAL BROWSER ASSETS", resources)
			self.assertIn("ASSET_TRANSPORT simple", resources)
			self.assertIn("ASSET_CDN_WEBROOT old-assets/", resources)
			self.assertIn("ASSET_CDN_URL http://old.example.test/", resources)

			# Disabling lobby publication must remove the runtime switch, otherwise
			# the next server keeps emitting HTTP URLs for files no longer managed.
			loaded_settings["RSC_PUBLISH_LOBBY_MEDIA"] = False
			rsc_deploy.publish_lobby_media(game_dir, loaded_settings)
			self.assertFalse((config_root / "lobby_media.json").exists())

	def test_resource_fingerprint_tracks_files_and_static_references(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			game_dir = Path(temporary_directory)
			(game_dir / "code").mkdir()
			(game_dir / "icons").mkdir()
			(game_dir / "tgui" / "public").mkdir(parents=True)
			resource = game_dir / "icons" / "existing.dmi"
			resource.write_bytes(b"first icon")
			browser_bundle = game_dir / "tgui" / "public" / "bundle.js"
			browser_bundle.write_bytes(b"first browser bundle")
			source = game_dir / "code" / "feature.dm"
			source.write_text("/proc/example()\n\treturn 1\n", encoding="utf-8")

			initial = rsc_deploy.resource_inputs_sha256(game_dir)
			source.write_text("/proc/example()\n\treturn 2\n", encoding="utf-8")
			self.assertEqual(rsc_deploy.resource_inputs_sha256(game_dir), initial)
			resource.write_bytes(b"unreferenced icon change")
			browser_bundle.write_bytes(b"second browser bundle")
			self.assertEqual(rsc_deploy.resource_inputs_sha256(game_dir), initial)

			source.write_text("/obj/example\n\ticon = 'icons/existing.dmi'\n", encoding="utf-8")
			with_reference = rsc_deploy.resource_inputs_sha256(game_dir)
			self.assertNotEqual(with_reference, initial)

			# Compile-time variants must never collide even when they mention the
			# same resource literals and files.
			source.write_text(
				"#define ALTERNATE_RESOURCE_SET\n/obj/example\n\ticon = 'icons/existing.dmi'\n",
				encoding="utf-8",
			)
			with_build_define = rsc_deploy.resource_inputs_sha256(game_dir)
			self.assertNotEqual(with_build_define, with_reference)

			resource.write_bytes(b"changed icon")
			with_changed_resource = rsc_deploy.resource_inputs_sha256(game_dir)
			self.assertNotEqual(with_changed_resource, with_build_define)

			# The interface file is compiled too, so its static resource literals
			# must participate even though unrelated browser JS does not.
			(game_dir / "interface").mkdir()
			interface_resource = game_dir / "icons" / "interface.dmi"
			interface_resource.write_bytes(b"interface icon")
			(game_dir / "interface" / "skin.dmf").write_text(
				"icon = 'icons/interface.dmi'\n", encoding="utf-8"
			)
			with_interface_reference = rsc_deploy.resource_inputs_sha256(game_dir)
			self.assertNotEqual(with_interface_reference, with_changed_resource)
			interface_resource.write_bytes(b"changed interface icon")
			self.assertNotEqual(rsc_deploy.resource_inputs_sha256(game_dir), with_interface_reference)

	def test_resource_fingerprint_cache_reuses_clean_git_blobs(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			game_dir = Path(temporary_directory)
			(game_dir / "code").mkdir()
			(game_dir / "icons").mkdir()
			(game_dir / "code" / "feature.dm").write_text(
				"/obj/example\n\ticon = 'icons/example.dmi'\n", encoding="utf-8"
			)
			(game_dir / "icons" / "example.dmi").write_bytes(b"icon")
			subprocess.run(["git", "init", "-q", str(game_dir)], check=True)
			subprocess.run(["git", "-C", str(game_dir), "config", "user.email", "test@example.test"], check=True)
			subprocess.run(["git", "-C", str(game_dir), "config", "user.name", "RSC Test"], check=True)
			subprocess.run(["git", "-C", str(game_dir), "add", "."], check=True)
			subprocess.run(["git", "-C", str(game_dir), "commit", "-qm", "fixture"], check=True)
			cache_path = game_dir / ".rsc-cache.json"
			first = rsc_deploy.resource_inputs_sha256(game_dir, cache_path=cache_path)
			self.assertTrue(cache_path.is_file())
			with mock.patch.object(rsc_deploy, "_scan_resource_source", side_effect=AssertionError("cache miss")):
				with mock.patch.object(rsc_deploy, "sha256_file", side_effect=AssertionError("cache miss")):
					second = rsc_deploy.resource_inputs_sha256(game_dir, cache_path=cache_path)
			self.assertEqual(second, first)

	def test_windows_hooks_use_repository_python_bootstrap(self):
		hooks_dir = SCRIPT.parent.parent / "tgs4_scripts"
		for hook_name in ("PreCompile.bat", "PostCompile.bat"):
			hook = (hooks_dir / hook_name).read_text(encoding="utf-8")
			self.assertIn("bootstrap\\python.bat", hook)

	def test_content_cleanup_protects_every_deployable_dmb_inventory(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			root = Path(temporary_directory)
			game_root = root / "Game"
			current_dir = game_root / "current" / "A"
			old_dir = game_root / "old" / "A"
			publish_dir = root / "publish"
			lobby_root = publish_dir / "lobby-media"
			asset_root = publish_dir / "browser-assets"
			inventory_root = asset_root / ".manifests"
			for directory in (current_dir, old_dir, lobby_root / "aa", asset_root / "bb", inventory_root):
				directory.mkdir(parents=True, exist_ok=True)

			(current_dir / "tgstation.dmb").write_bytes(b"current")
			(old_dir / "tgstation.dmb").write_bytes(b"old")
			current_manifest = {
				"archive_name": "Moon-Test-current.zip",
				"lobby_media_enabled": True,
				"browser_asset_webroot_enabled": True,
				"browser_asset_manifest": "current.txt",
			}
			old_manifest = {
				"archive_name": "Moon-Test-old.zip",
				"lobby_media_enabled": True,
				"lobby_media_files": ["aa/old.ogg"],
				"browser_asset_webroot_enabled": True,
				"browser_asset_manifest": "old.txt",
			}
			(current_dir / ".rsc-deploy.json").write_text(json.dumps(current_manifest), encoding="utf-8")
			(old_dir / ".rsc-deploy.json").write_text(json.dumps(old_manifest), encoding="utf-8")
			(inventory_root / "current.txt").write_text("bb/current.js\n", encoding="utf-8")
			(inventory_root / "old.txt").write_text("bb/old.js\n", encoding="utf-8")
			(inventory_root / "stale.txt").write_text("bb/stale.js\n", encoding="utf-8")

			protected_files = (
				lobby_root / "aa" / "current.ogg",
				lobby_root / "aa" / "old.ogg",
				asset_root / "bb" / "current.js",
				asset_root / "bb" / "old.js",
			)
			stale_files = (lobby_root / "aa" / "stale.ogg", asset_root / "bb" / "stale.js")
			for path in protected_files + stale_files:
				path.write_bytes(path.name.encode("ascii"))
			for path in protected_files + stale_files + tuple(inventory_root.glob("*.txt")):
				os.utime(path, (1, 1))

			settings = {
				"RSC_PRUNE_ENABLED": True,
				"RSC_DEPLOYMENT_ROOTS": [game_root],
				"RSC_PUBLISH_DIR": str(publish_dir),
				"RSC_LOBBY_MEDIA_SUBDIR": "lobby-media",
				"RSC_ASSET_WEBROOT_SUBDIR": "browser-assets",
				"RSC_PRUNE_GRACE_HOURS": 0,
			}
			removed = rsc_deploy.prune_content_stores(
				current_dir,
				settings,
				current_dir / ".rsc-deploy.json",
				["aa/current.ogg"],
			)
			self.assertEqual(removed, 3)
			for path in protected_files:
				self.assertTrue(path.is_file())
			for path in stale_files:
				self.assertFalse(path.exists())
			self.assertTrue((inventory_root / "current.txt").is_file())
			self.assertTrue((inventory_root / "old.txt").is_file())
			self.assertFalse((inventory_root / "stale.txt").exists())

	def test_invalid_rsc_mirror_url_is_rejected(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			root = Path(temporary_directory)
			settings_path = root / "rsc_deploy.env"
			settings_path.write_text(
				"RSC_PUBLIC_BASE_URL=https://download.example.test/rsc\n"
				"RSC_PUBLIC_MIRROR_BASE_URLS=ftp://mirror.example.test/rsc\n"
				"RSC_PUBLISH_DIR={}\n".format((root / "publish").as_posix()),
				encoding="utf-8",
			)
			with self.assertRaisesRegex(rsc_deploy.DeployError, "entry 1 must start"):
				rsc_deploy.load_settings(root, settings_path)

	def test_archive_names_are_namespaced_per_tgs_instance(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			root = Path(temporary_directory)
			settings = []
			for instance_name in ("main", "test"):
				config_path = root / instance_name / "Configuration" / "GameStaticFiles" / "config" / "rsc_deploy.env"
				config_path.parent.mkdir(parents=True)
				config_path.write_text(
					"RSC_PUBLIC_BASE_URL=https://download.example.test/rsc\n"
					"RSC_PUBLISH_DIR={}\n".format((root / "publish").as_posix()),
					encoding="utf-8",
				)
				settings.append(rsc_deploy.load_settings(root, config_path))
			resource_hash = "a" * 64
			self.assertNotEqual(
				rsc_deploy.archive_inputs_sha256(resource_hash, settings[0]),
				rsc_deploy.archive_inputs_sha256(resource_hash, settings[1]),
			)

	def test_pruning_fails_closed_when_a_dmb_has_no_manifest(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			root = Path(temporary_directory)
			game_root = root / "Game"
			current_dir = game_root / "current" / "A"
			unknown_dir = game_root / "unknown" / "A"
			publish_dir = root / "publish"
			current_dir.mkdir(parents=True)
			unknown_dir.mkdir(parents=True)
			publish_dir.mkdir()
			(current_dir / "tgstation.dmb").write_bytes(b"current")
			(current_dir / ".rsc-deploy.json").write_text(
				json.dumps({"archive_name": "Moon-Test-current.zip"}), encoding="utf-8"
			)
			(unknown_dir / "unknown.dmb").write_bytes(b"unknown")
			candidate = publish_dir / "Moon-Test-unreferenced.zip"
			candidate.write_bytes(b"keep me")

			settings = {
				"RSC_PRUNE_ENABLED": True,
				"RSC_DEPLOYMENT_ROOTS": [game_root],
				"RSC_PUBLISH_DIR": str(publish_dir),
				"RSC_ARCHIVE_PREFIX": "Moon-Test",
				"RSC_KEEP_UNREFERENCED": 0,
				"RSC_PRUNE_GRACE_HOURS": 0,
			}
			removed = rsc_deploy.prune_archives(current_dir, settings, "Moon-Test-current.zip")
			self.assertEqual(removed, 0)
			self.assertEqual(candidate.read_bytes(), b"keep me")


if __name__ == "__main__":
	unittest.main()

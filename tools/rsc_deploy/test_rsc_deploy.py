#!/usr/bin/env python3

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).with_name("rsc_deploy.py")
sys.path.insert(0, str(SCRIPT.parent))
import rsc_deploy  # noqa: E402


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
				"#define DEPLOYMENT_RSC_URL null\n", encoding="utf-8"
			)
			compiled_rsc = b"resource payload\n" * 4096
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
			self.assertEqual(
				build_manifest["archive_name"],
				"Moon-Test-{}.zip".format(build_manifest["resource_inputs_sha256"]),
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
			self.assertNotIn("old-assets", resources)
			self.assertNotIn("old.example.test", resources)
			self.assertTrue((publish_dir / "browser-assets").is_dir())

			latest = json.loads((publish_dir / "Moon-Test-latest.json").read_text(encoding="utf-8"))
			self.assertTrue(latest["archive_reused"])
			self.assertEqual(latest["lobby_media_count"], 4)
			self.assertEqual(latest["lobby_media_size"], sum(map(len, set(expected.values()))))

			# A fingerprint collision must fail closed and keep the immutable archive.
			original_archive = archive_path.read_bytes()
			(game_dir / "tgstation.rsc").write_bytes(b"x" * len(compiled_rsc))
			result = subprocess.run(
				[sys.executable, str(SCRIPT), "publish", *common],
				check=False,
				capture_output=True,
				text=True,
			)
			self.assertNotEqual(result.returncode, 0)
			self.assertIn("already exists with rsc sha256", result.stdout)
			self.assertEqual(archive_path.read_bytes(), original_archive)

	def test_resource_fingerprint_tracks_files_and_static_references(self):
		with tempfile.TemporaryDirectory() as temporary_directory:
			game_dir = Path(temporary_directory)
			(game_dir / "code").mkdir()
			(game_dir / "icons").mkdir()
			resource = game_dir / "icons" / "existing.dmi"
			resource.write_bytes(b"first icon")
			source = game_dir / "code" / "feature.dm"
			source.write_text("/proc/example()\n\treturn 1\n", encoding="utf-8")

			initial = rsc_deploy.resource_inputs_sha256(game_dir)
			source.write_text("/proc/example()\n\treturn 2\n", encoding="utf-8")
			self.assertEqual(rsc_deploy.resource_inputs_sha256(game_dir), initial)

			source.write_text("/obj/example\n\ticon = 'icons/existing.dmi'\n", encoding="utf-8")
			with_reference = rsc_deploy.resource_inputs_sha256(game_dir)
			self.assertNotEqual(with_reference, initial)

			resource.write_bytes(b"changed icon")
			self.assertNotEqual(rsc_deploy.resource_inputs_sha256(game_dir), with_reference)

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

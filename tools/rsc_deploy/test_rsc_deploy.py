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
			game_dir = root / "compile-output"
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
			(game_dir / "tgstation.rsc").write_bytes(b"resource payload\n" * 4096)
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
				"RSC_KEEP_VERSIONS=2\n"
				"RSC_COMPRESSION_LEVEL=0\n"
				"RSC_PUBLISH_LOBBY_MEDIA=1\n"
				"RSC_ENABLE_ASSET_WEBROOT=1\n".format(publish_dir.as_posix()),
				encoding="utf-8",
			)

			common = ["--game-dir", str(game_dir), "--config", str(settings_path)]
			subprocess.run(
				[sys.executable, str(SCRIPT), "prepare", *common, "--revision", "abcdef0123456789"],
				check=True,
			)
			build_manifest = json.loads((game_dir / ".rsc-deploy.json").read_text(encoding="utf-8"))
			self.assertIn(build_manifest["public_url"], (game_dir / "code" / "_compile_options.dm").read_text(encoding="utf-8"))

			subprocess.run([sys.executable, str(SCRIPT), "publish", *common], check=True)
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
			self.assertEqual(latest["lobby_media_count"], 4)
			self.assertEqual(latest["lobby_media_size"], sum(map(len, set(expected.values()))))


if __name__ == "__main__":
	unittest.main()

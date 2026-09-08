"""Проверка переноса настоящих сейвов без запуска станции и изменения оригиналов."""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tempfile


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def archive_tar(archive):
    if archive.suffix.lower() != ".7z":
        return "tar"
    for name in ("bsdtar", "tar"):
        executable = shutil.which(name)
        if executable:
            version = subprocess.check_output([executable, "--version"], text=True)
            if "bsdtar" in version.lower():
                return executable
    raise RuntimeError("Для архивов .7z нужен bsdtar (libarchive) с поддержкой 7z в PATH; GNU tar не подходит")


def run():
    parser = argparse.ArgumentParser(description=__doc__)
    sources = parser.add_mutually_exclusive_group(required=True)
    sources.add_argument("--archive", type=Path)
    sources.add_argument("--source-dir", type=Path)
    parser.add_argument("--work-dir", type=Path)
    parser.add_argument("--byond-bin", type=Path)
    parser.add_argument("--limit", type=int, help="Ограничить выборку для быстрой проверки")
    parser.add_argument("--export-legacy", action="store_true", help="Экспортировать JSON обратно в .sav в рабочем каталоге")
    parser.add_argument("--storage-roundtrip", action="store_true", help="Проверить также запись разделов JSON и повторное открытие")
    parser.add_argument("--benchmark", action="store_true", help="Замерить чтение и запись на отдельных рабочих копиях")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[2]
    work = args.work_dir.resolve() if args.work_dir else Path(tempfile.mkdtemp(prefix="player-save-audit-"))
    work.mkdir(parents=True, exist_ok=True)
    archive_hash = None
    if args.archive:
        archive = args.archive.resolve(strict=True)
        archive_hash = digest(archive)
        tar = archive_tar(archive)
        names = subprocess.check_output([tar, "-tf", str(archive)], text=True).splitlines()
        for name in names:
            member = PurePosixPath(name.replace("\\", "/"))
            if member.is_absolute() or ".." in member.parts or ":" in name:
                raise ValueError("Архив содержит путь вне каталога распаковки")
        source = work / "archive"
        source.mkdir(exist_ok=True)
        subprocess.run([tar, "-xf", str(archive), "-C", str(source)], check=True)
    else:
        source = args.source_dir.resolve(strict=True)
    if args.export_legacy:
        json_files = [p for p in source.rglob("*") if p.is_file()
                      and not any(part.endswith(".json.d") for part in p.relative_to(source).parts)
                      and (p.name.endswith(".sav.json") or p.name.endswith(".sav.json.recovery"))]
        files = sorted({Path(str(p).removesuffix(".recovery").removesuffix(".json")) for p in json_files})
    else:
        files = sorted(p for p in source.rglob("*") if p.is_file() and p.suffix in (".sav", ".updatebac"))
    if args.limit is not None:
        if args.limit < 1:
            parser.error("--limit должен быть положительным")
        files = files[:args.limit]
    if not files:
        parser.error("Сейвы .sav и .updatebac не найдены")
    checked_files = [p for p in source.rglob("*") if p.is_file()] if args.export_legacy else files
    hashes = [digest(path) for path in checked_files]
    manifest = {"work_directory": work.as_posix(), "files": [p.as_posix() for p in files]}
    manifest["storage_roundtrip"] = args.storage_roundtrip
    manifest["benchmark"] = args.benchmark
    if args.export_legacy:
        manifest["mode"] = "export"
        manifest["outputs"] = [(work / "legacy" / p.relative_to(source)).as_posix() for p in files]
    manifest_path = work / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False), encoding="utf-8")
    if args.byond_bin:
        compiler = args.byond_bin / ("dm.exe" if os.name == "nt" else "DreamMaker")
    else:
        compiler = Path(subprocess.check_output([
            "node", "--input-type=module", "-e",
            "import {getDmPath} from './tools/build/lib/byond.js'; console.log(await getDmPath())",
        ], cwd=repo, text=True).strip())
    daemon = compiler.parent / ("dd.exe" if os.name == "nt" else "DreamDaemon")
    artifact = repo / f"tgstation.test.saveaudit.{os.getpid()}"
    dme = Path(f"{artifact}.dme")
    dme.write_text(
        "#define CBT\n#define LOWMEMORYMODE\n"
        + (repo / "tgstation.dme").read_text(encoding="utf-8-sig")
        + '\n#include "tools\\player_saves\\audit.dm"\n', encoding="utf-8",
    )
    try:
        subprocess.run([str(compiler), str(dme)], cwd=repo, check=True)
        subprocess.run([
            str(daemon), f"{artifact}.dmb", "-trusted", "-close", "-invisible",
            "-params", f"save-audit-manifest={manifest_path.as_posix()}",
        ], cwd=repo, check=True)
    finally:
        for extension in (".dme", ".dmb", ".rsc"):
            Path(f"{artifact}{extension}").unlink(missing_ok=True)
    report_path = work / "report.json"
    report = json.loads(report_path.read_text(encoding="utf-8-sig"))
    report["source_files_unchanged"] = all(digest(path) == old for path, old in zip(checked_files, hashes))
    report["archive_sha256"] = archive_hash
    report["archive_unchanged"] = archive_hash is None or digest(archive) == archive_hash
    report["limited"] = args.limit is not None
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Report: {report_path}")
    print(f"Passed: {report['passed']}; failed: {report['failed']}; repaired by BYOND: {len(report['repaired'])}")
    if report["failed"] or report["repaired"] or report["missing_version"] or not report["source_files_unchanged"] or not report["archive_unchanged"]:
        raise SystemExit(1)


if __name__ == "__main__":
    run()

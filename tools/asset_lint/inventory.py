"""Список ассетов репозитория и поиск дубликатов."""

import hashlib
import os
import subprocess
import zlib

from .references import is_asset_path

# Каталоги, файлы из которых не проверяются: сборка tgui, инструменты, конфиги сервера
# (их подкладывают на проде, ссылки на них живут в конфигурации, а не в коде).
EXCLUDED_PREFIXES = (
    '.github/',
    'config/',
    'data/',
    'tgui/',
    'tools/',
)

PNG_MAGIC = b'\x89PNG\r\n\x1a\n'


def repository_files():
    """Файлы под git плюс новые неигнорируемые, чтобы локальный прогон видел их до git add."""
    try:
        output = subprocess.run(
            ['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard'],
            capture_output=True, check=True,
        ).stdout
        files = [path.decode('utf-8') for path in output.split(b'\0') if path]
        return [path for path in files if os.path.isfile(path)]
    except (OSError, subprocess.CalledProcessError):
        files = []
        for dirpath, dirnames, filenames in os.walk('.'):
            for skipped in ('.git', 'node_modules'):
                if skipped in dirnames:
                    dirnames.remove(skipped)
            for filename in filenames:
                files.append(os.path.relpath(os.path.join(dirpath, filename)).replace(os.sep, '/'))
        return files


def is_checked_asset(path):
    return is_asset_path(path) and not path.startswith(EXCLUDED_PREFIXES)


def directories_of(files):
    directories = set()
    for path in files:
        parent = os.path.dirname(path)
        while parent and parent not in directories:
            directories.add(parent)
            parent = os.path.dirname(parent)
    return directories


def file_digest(path):
    digest = hashlib.sha1()
    with open(path, 'rb') as handle:
        for block in iter(lambda: handle.read(1 << 20), b''):
            digest.update(block)
    return digest.hexdigest()


def _png_signature(path):
    """Размер холста и метадата DMI без распаковки картинки."""
    with open(path, 'rb') as handle:
        if handle.read(8) != PNG_MAGIC:
            return None
        size = None
        description = b''
        while True:
            header = handle.read(8)
            if len(header) < 8:
                break
            length = int.from_bytes(header[:4], 'big')
            chunk_type = header[4:]
            if chunk_type == b'IDAT' or chunk_type == b'IEND':
                break
            body = handle.read(length)
            handle.seek(4, os.SEEK_CUR)
            if chunk_type == b'IHDR':
                size = body[:8]
            elif chunk_type in (b'zTXt', b'tEXt') and body.split(b'\0', 1)[0] == b'Description':
                payload = body.split(b'\0', 1)[1]
                description = zlib.decompress(payload[1:]) if chunk_type == b'zTXt' else payload
        return size, description


def _pixel_digest(path):
    from PIL import Image
    with Image.open(path) as image:
        rgba = image.convert('RGBA')
        return hashlib.sha1(rgba.tobytes()).hexdigest()


def duplicate_groups(assets):
    """Группы одинаковых файлов: побайтно, а для PNG/DMI - по пикселям и метадате.

    Пиксели распаковываются только у файлов, совпавших по размеру холста и метадате.
    """
    by_bytes = {}
    for path in assets:
        by_bytes.setdefault((os.path.getsize(path), file_digest(path)), []).append(path)

    groups = [sorted(paths) for paths in by_bytes.values() if len(paths) > 1]
    representatives = [paths[0] for paths in by_bytes.values()]

    by_signature = {}
    for path in representatives:
        if not path.lower().endswith(('.dmi', '.png')):
            continue
        signature = _png_signature(path)
        if signature and signature[0]:
            by_signature.setdefault(signature, []).append(path)

    merged = {path: group for group in groups for path in group}
    for candidates in by_signature.values():
        if len(candidates) < 2:
            continue
        by_pixels = {}
        for path in candidates:
            try:
                by_pixels.setdefault(_pixel_digest(path), []).append(path)
            except Exception:
                continue
        for same in by_pixels.values():
            if len(same) < 2:
                continue
            combined = set()
            for path in same:
                combined.update(merged.get(path, [path]))
            combined = sorted(combined)
            for path in combined:
                merged[path] = combined

    unique = {tuple(group) for group in merged.values()}
    return sorted(list(group) for group in unique)

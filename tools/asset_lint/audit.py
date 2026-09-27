"""Какие ассеты используются, какие нет, и какие ссылки ведут в пустоту."""

import re

from . import inventory, references
from .references import HOLE

DATA_EXTENSIONS = ('.json', '.txt', '.html', '.htm', '.css', '.js', '.toml')
# Лицензии и атрибуции упоминают файлы, но не используют их.
NOT_DATA = re.compile(r'licen[cs]e|attri?t?bution|credit|readme|copying|sources', re.I)
NOT_DATA_PREFIXES = ('.github/', '.vscode/', 'data/', 'html/changelogs/', 'tgui/', 'tools/')

# Короткие подстановки вроде номера варианта или ноты принимаются без проверки.
SHORT_HOLE_LENGTH = 3


def _template_regex(template):
    return re.compile('(.*?)'.join(re.escape(part) for part in template.lower().split(HOLE)))


def holes_are_known(match, strings):
    """Подстановка в шаблон должна быть известной строкой из кода, числом или короткой."""
    for value in match.groups():
        if len(value) > SHORT_HOLE_LENGTH and not value.isdigit() and value.lower() not in strings:
            return False
    return True


class Audit:
    def __init__(self, dme='tgstation.dme'):
        self.dme = dme
        self.files = inventory.repository_files()
        self.assets = sorted(path for path in self.files if inventory.is_checked_asset(path))
        self.references = references.References()
        self.used_by = {}
        self.broken = {}

    def run(self):
        known_files = set(self.files)
        known_directories = inventory.directories_of(self.files)
        self.sources = [path for path in self.files if path.endswith(('.dm', '.dme'))]
        references.scan_dm_sources(self.references, self.sources, known_files, known_directories)
        maps = [path for path in self.files if path.endswith(('.dmm', '.dmf'))]
        references.scan_maps(self.references, maps, known_files, known_directories)
        data_files = [
            path for path in self.files
            if path.lower().endswith(DATA_EXTENSIONS)
            and not path.startswith(NOT_DATA_PREFIXES)
            and not NOT_DATA.search(path.rsplit('/', 1)[-1])
        ]
        references.scan_data_files(self.references, data_files, known_files)
        self._resolve()
        self._find_broken(known_files)
        return self

    def _resolve(self):
        exact = {path.lower(): origin for path, origin in self.references.embedded.items()}
        exact.update((path.lower(), min(origins)) for path, origins in self.references.exact.items())
        directories = [(path.lower() + '/', origin) for path, origin in self.references.directories.items()]
        patterns = [(_template_regex(template), origin) for template, origin in self.references.patterns.items()]
        strings = {value.lower() for value in self.references.strings}
        for asset in self.assets:
            key = asset.lower()
            origin = exact.get(key)
            if origin is None:
                origin = next((source for prefix, source in directories if key.startswith(prefix)), None)
            if origin is None:
                for regex, pattern_origin in patterns:
                    match = regex.fullmatch(key)
                    if match and holes_are_known(match, strings):
                        origin = pattern_origin
                        break
            if origin is not None:
                self.used_by[asset] = origin

    def _find_broken(self, known_files):
        """Компилируемый код или карта ссылается на путь в каталоге ассетов, а файла нет.

        Неподключённые в .dme модули сюда не попадают: их ссылки ничего не ломают.
        """
        known = {path.lower() for path in known_files}
        roots = {asset.split('/', 1)[0] for asset in self.assets if '/' in asset}
        compiled = references.included_sources(self.dme)
        for path, origins in self.references.exact.items():
            if path.lower() in known or path.lstrip('/').split('/', 1)[0] not in roots:
                continue
            live = sorted(origin for origin in origins if origin in compiled or origin.endswith(('.dmm', '.dmf')))
            if live:
                self.broken[path] = live[0]

    @property
    def unused(self):
        return [asset for asset in self.assets if asset not in self.used_by]

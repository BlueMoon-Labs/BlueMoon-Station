"""Отчёт по стейтам DMI, имён которых нет ни в коде, ни на картах.

Это эвристика, а не проверка: имя стейта часто собирается на лету ("[base]_open"), и такие
шаблоны засчитываются, только если подстановка - известная строка из кода. Остаются и ложные
находки (имя из json, из типа, из пользовательского ввода), поэтому перед удалением стейт
надо проверить глазами.
"""

import re
import zlib

from .audit import holes_are_known
from .references import HOLE, read_text

_STATE_TEMPLATE = re.compile(r'[\w\-+.# ]*')
_MAP_ICON_STATE = re.compile(r'\bicon_state = "((?:[^"\\\n]|\\.)*)"')
_STATE_LINE = re.compile(r'^state = "(.*)"$')
_VALUE_LINE = re.compile(r'^\t(\w+) = (.+)$')

PNG_MAGIC = b'\x89PNG\r\n\x1a\n'


def read_states(path):
    """[(имя, байт в распакованном виде)] из метадаты DMI; None, если метадаты нет."""
    with open(path, 'rb') as handle:
        if handle.read(8) != PNG_MAGIC:
            return None
        width = height = None
        description = None
        while True:
            header = handle.read(8)
            if len(header) < 8:
                break
            length = int.from_bytes(header[:4], 'big')
            chunk_type = header[4:]
            if chunk_type in (b'IDAT', b'IEND'):
                break
            body = handle.read(length)
            handle.seek(4, 1)
            if chunk_type in (b'zTXt', b'tEXt') and body.split(b'\0', 1)[0] == b'Description':
                payload = body.split(b'\0', 1)[1]
                description = (zlib.decompress(payload[1:]) if chunk_type == b'zTXt' else payload).decode('utf-8', 'replace')
    if description is None:
        return None

    states = []
    current = None
    for line in description.splitlines():
        if line.startswith('\twidth = ') and current is None:
            width = int(line.split('=')[1])
        elif line.startswith('\theight = ') and current is None:
            height = int(line.split('=')[1])
        match = _STATE_LINE.match(line)
        if match:
            current = {'name': match.group(1), 'dirs': 1, 'frames': 1}
            states.append(current)
            continue
        match = _VALUE_LINE.match(line)
        if match and current is not None and match.group(1) in ('dirs', 'frames'):
            current[match.group(1)] = int(match.group(2))
    cell = (width or 32) * (height or 32) * 4
    return [(state['name'], cell * state['dirs'] * state['frames']) for state in states]


class StateMatcher:
    def __init__(self, strings, templates):
        self.strings = strings
        self.lowered = {value.lower() for value in strings}
        self.by_prefix = {}
        self.by_suffix = {}
        self.floating = []
        for template in templates:
            parts = template.split(HOLE)
            regex = re.compile('(.*?)'.join(re.escape(part) for part in parts))
            entry = (parts[0], parts[-1], regex)
            if parts[0]:
                self.by_prefix.setdefault(parts[0], []).append(entry)
            elif parts[-1]:
                self.by_suffix.setdefault(parts[-1], []).append(entry)
            else:
                self.floating.append(entry)

    def _candidates(self, name):
        for end in range(1, len(name) + 1):
            yield from self.by_prefix.get(name[:end], ())
        for start in range(len(name)):
            yield from self.by_suffix.get(name[start:], ())
        yield from self.floating

    def is_referenced(self, name):
        if name == '' or name in self.strings:
            return True
        for _prefix, suffix, regex in self._candidates(name):
            if not name.endswith(suffix):
                continue
            match = regex.fullmatch(name)
            if match and holes_are_known(match, self.lowered):
                return True
        return False


def _collect(audit):
    strings = set(audit.references.strings)
    templates = set()
    for template in audit.references.state_templates:
        if len(template) < 64 and _STATE_TEMPLATE.fullmatch(template.replace(HOLE, '')) and template.replace(HOLE, ''):
            templates.add(template)
    for path in audit.files:
        if path.endswith('.dmm'):
            for value in _MAP_ICON_STATE.findall(read_text(path)):
                strings.add(value)
    return strings, templates


def report(audit):
    strings, templates = _collect(audit)
    matcher = StateMatcher(strings, templates)
    results = []
    for asset in audit.assets:
        if not asset.endswith('.dmi') or asset not in audit.used_by:
            continue
        states = read_states(asset)
        if not states:
            continue
        missing = [(name, size) for name, size in states if not matcher.is_referenced(name)]
        if missing:
            results.append((sum(size for _, size in missing), asset, len(states), missing))

    total_states = total_bytes = 0
    for wasted, asset, count, missing in sorted(results, reverse=True):
        total_states += len(missing)
        total_bytes += wasted
        print(f'{asset}: {len(missing)} из {count} стейтов, {wasted / 1024:.0f} КБ у клиента')
        for name, _ in missing:
            print(f'    "{name}"')
    print(f'Итого {total_states} стейтов в {len(results)} файлах, {total_bytes / 1024 / 1024:.1f} МБ распакованными')
    return 0

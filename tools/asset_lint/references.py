"""Сбор ссылок на ассеты из DM-кода, карт, интерфейса и конфигов."""

import os
import re

ASSET_EXTENSIONS = ('.dmi', '.png', '.gif', '.jpg', '.jpeg', '.bmp', '.ogg', '.wav', '.mid', '.midi', '.mp3', '.ttf', '.otf')

# Плейсхолдер на месте [выражения] внутри строки.
HOLE = '\0'

_TOP_LEVEL = re.compile(r'//|/\*|\{"|"|\'|@|^[ \t]*#[ \t]*(?:warn|error)\b', re.M)
_BLOCK_COMMENT = re.compile(r'/\*|\*/')
_STRING_PLAIN = re.compile(r'\\|\[|"')
_STRING_MULTILINE = re.compile(r'\\|\[|"\}')
_EXPRESSION = re.compile(r'\[|\]|\{"|"|\'|@"')

_ESCAPES = {'n': '\n', 't': '\t', '"': '"', '\\': '\\', '[': '[', ']': ']', "'": "'"}


class DMLexer:
    """Вытаскивает из исходника DM ресурсные литералы и строки, пропуская комментарии.

    Строка отдаётся шаблоном: литеральный текст, а на месте каждого [выражения] - HOLE.
    Строки внутри выражений собираются тоже.
    """

    def __init__(self, text):
        self.text = text
        self.resources = []
        self.strings = []

    def run(self):
        text = self.text
        pos = 0
        while True:
            match = _TOP_LEVEL.search(text, pos)
            if not match:
                return self
            token = match.group(0)
            start = match.start()
            if token == '//':
                pos = self._line_end(start)
            elif token == '/*':
                pos = self._skip_block_comment(start + 2)
            elif token == '{"':
                pos = self._read_string(start + 2, multiline=True)
            elif token == '"':
                pos = self._read_string(start + 1, multiline=False)
            elif token == "'":
                pos = self._read_resource(start + 1)
            elif token == '@':
                pos = self._read_raw_string(start + 1)
            else:
                pos = self._line_end(start)

    def _line_end(self, pos):
        end = self.text.find('\n', pos)
        return len(self.text) if end < 0 else end + 1

    def _skip_block_comment(self, pos):
        depth = 1
        while depth:
            match = _BLOCK_COMMENT.search(self.text, pos)
            if not match:
                return len(self.text)
            depth += 1 if match.group(0) == '/*' else -1
            pos = match.end()
        return pos

    def _read_resource(self, pos):
        end = self.text.find("'", pos)
        newline = self.text.find('\n', pos)
        if end < 0 or (0 <= newline < end):
            return pos
        self.resources.append(self.text[pos:end])
        return end + 1

    def _read_raw_string(self, pos):
        text = self.text
        if text.startswith('{"', pos):
            end = text.find('"}', pos + 2)
            body_start, skip = pos + 2, 2
        elif text.startswith('(', pos):
            close = text.find(')', pos)
            if close < 0:
                return pos
            delimiter = text[pos + 1:close]
            end = text.find(delimiter, close + 1)
            body_start, skip = close + 1, len(delimiter)
        elif pos < len(text):
            end = text.find(text[pos], pos + 1)
            body_start, skip = pos + 1, 1
        else:
            return pos
        if end < 0:
            return len(text)
        self.strings.append(text[body_start:end])
        return end + skip

    def _read_string(self, pos, multiline):
        text = self.text
        pattern = _STRING_MULTILINE if multiline else _STRING_PLAIN
        parts = []
        while True:
            match = pattern.search(text, pos)
            if not match:
                self.strings.append(''.join(parts))
                return len(text)
            parts.append(text[pos:match.start()])
            token = match.group(0)
            if token == '\\':
                escaped = text[match.end():match.end() + 1]
                parts.append(_ESCAPES.get(escaped, ''))
                pos = match.end() + 1
            elif token == '[':
                parts.append(HOLE)
                pos = self._read_expression(match.end())
            else:
                self.strings.append(''.join(parts))
                return match.end()

    def _read_expression(self, pos):
        text = self.text
        depth = 1
        while True:
            match = _EXPRESSION.search(text, pos)
            if not match:
                return len(text)
            token = match.group(0)
            if token == '[':
                depth += 1
                pos = match.end()
            elif token == ']':
                depth -= 1
                pos = match.end()
                if not depth:
                    return pos
            elif token == '{"':
                pos = self._read_string(match.end(), multiline=True)
            elif token == '"':
                pos = self._read_string(match.end(), multiline=False)
            elif token == '@"':
                pos = self._read_raw_string(match.start() + 1)
            else:
                pos = self._read_resource(match.end())


def normalize(path):
    path = path.replace('\\', '/')
    path = os.path.normpath(path).replace('\\', '/')
    return '' if path == '.' else path


_INCLUDE = re.compile(r'^[ \t]*#[ \t]*include[ \t]+"([^"]+)"', re.M)


def included_sources(dme):
    """Файлы, которые реально компилируются: обход #include от .dme."""
    visited = set()
    stack = [normalize(dme)]
    while stack:
        source = stack.pop()
        if source in visited or not os.path.isfile(source):
            continue
        visited.add(source)
        for include in _INCLUDE.findall(read_text(source)):
            target = resolve_relative(source, include, os.path.isfile)
            if target.endswith(('.dm', '.dme')):
                stack.append(target)
    return visited


def resolve_relative(source, reference, exists):
    """Как DreamMaker ищет файл: сначала от каталога исходника, потом от FILE_DIR (корня)."""
    local = normalize(os.path.join(os.path.dirname(source), reference.replace('\\', '/')))
    if exists(local):
        return local
    return normalize(reference)


def read_text(path):
    with open(path, 'rb') as handle:
        data = handle.read()
    return data.decode('utf-8', errors='replace')


def is_asset_path(path):
    return path.lower().endswith(ASSET_EXTENSIONS)


class References:
    """Все найденные ссылки: точные пути, шаблоны путей и каталоги целиком."""

    def __init__(self):
        self.exact = {}
        self.patterns = {}
        self.directories = {}
        self.embedded = {}
        self.strings = set()
        self.state_templates = set()

    def add_exact(self, path, origin):
        self.exact.setdefault(path, set()).add(origin)

    def add_pattern(self, template, origin):
        self.patterns.setdefault(template, origin)

    def add_directory(self, path, origin):
        self.directories.setdefault(path.rstrip('/'), origin)


_DATA_PATH = re.compile(r'[\w./\\-]+\.(?:' + '|'.join(ext[1:] for ext in ASSET_EXTENSIONS) + r')\b', re.I)
_EMBEDDED_PATH = re.compile(r'[\w./-]+/[\w.-]+\.(?:' + '|'.join(ext[1:] for ext in ASSET_EXTENSIONS) + r')\b', re.I)
_MAP_RESOURCE = re.compile(r"'([^'\n]+)'")
_MAP_STRING = re.compile(r'"((?:[^"\\\n]|\\.)*)"')


_PATH_TEMPLATE = re.compile(r'[^\s<>"\'=;,(){}]+')


def _is_path_template(template):
    """Шаблон с [выражением] - путь, если он похож на путь и до первой дыры есть каталог.

    Иначе "[path].ogg" совпал бы со всеми звуками разом.
    """
    if not _PATH_TEMPLATE.fullmatch(template):
        return False
    prefix = template.split(HOLE, 1)[0]
    return '/' in prefix.strip('/')


def collect_from_string(references, value, origin, known_directories):
    value = value.replace('\\', '/')
    if HOLE in value:
        references.state_templates.add(value)
        if _is_path_template(value):
            references.add_pattern(value, origin)
    else:
        references.strings.add(value)
        if is_asset_path(value):
            references.add_exact(normalize(value), origin)
            return
        if value.endswith('/') and '/' in value.strip('/') and normalize(value) in known_directories:
            references.add_directory(normalize(value), origin)
    # Путь внутри HTML или команды: "<img src='icons/x.png'>", "-icon %CD%\icons\x.png".
    for part in value.split(HOLE):
        for token in _EMBEDDED_PATH.findall(part):
            references.embedded.setdefault(normalize(token.lstrip('/')), origin)


def scan_dm_sources(references, sources, known_files, known_directories):
    exists = lambda path: path in known_files or os.path.isfile(path)
    for source in sources:
        lexer = DMLexer(read_text(source)).run()
        for resource in lexer.resources:
            if not resource.strip():
                continue
            path = resolve_relative(source, resource, exists)
            references.add_exact(path, source)
        for value in lexer.strings:
            collect_from_string(references, value, source, known_directories)


def scan_maps(references, maps, known_files, known_directories):
    exists = lambda path: path in known_files or os.path.isfile(path)
    for map_file in maps:
        text = read_text(map_file)
        for resource in _MAP_RESOURCE.findall(text):
            if is_asset_path(resource):
                references.add_exact(resolve_relative(map_file, resource, exists), map_file)
        for value in _MAP_STRING.findall(text):
            if '/' in value:
                collect_from_string(references, value.replace('\\"', '"'), map_file, known_directories)


def scan_data_files(references, data_files, known_files):
    """Конфиги, json и html: ищем любые токены, похожие на путь к ассету."""
    exists = lambda path: path in known_files
    for data_file in data_files:
        text = read_text(data_file)
        for token in _DATA_PATH.findall(text):
            references.add_exact(resolve_relative(data_file, token, exists), data_file)

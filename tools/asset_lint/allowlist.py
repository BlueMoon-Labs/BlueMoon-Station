"""Белый список: ассеты, которые проверка считает лишними, но удалять их нельзя."""

import fnmatch
import os

ALLOWLIST_PATH = os.path.join(os.path.dirname(__file__), 'allowlist.txt')
KINDS = ('unused', 'duplicate')


class Entry:
    def __init__(self, kind, pattern, line):
        self.kind = kind
        self.pattern = pattern
        self.line = line
        self.matched = False

    def matches(self, path):
        if fnmatch.fnmatchcase(path, self.pattern):
            self.matched = True
            return True
        return False


class Allowlist:
    def __init__(self, entries, errors):
        self.entries = entries
        self.errors = errors

    @classmethod
    def load(cls, path=ALLOWLIST_PATH):
        entries, errors = [], []
        if not os.path.isfile(path):
            return cls(entries, errors)
        with open(path, encoding='utf-8') as handle:
            for number, raw in enumerate(handle, 1):
                line = raw.split('#', 1)[0].strip()
                if not line:
                    continue
                parts = line.split(None, 1)
                if len(parts) != 2 or parts[0] not in KINDS:
                    errors.append(f'allowlist.txt:{number}: ожидается "unused <путь>" или "duplicate <путь>"')
                    continue
                entries.append(Entry(parts[0], parts[1].strip(), number))
        return cls(entries, errors)

    def allows(self, kind, path):
        return any(entry.matches(path) for entry in self.entries if entry.kind == kind)

    def allows_group(self, group):
        return all([self.allows('duplicate', path) for path in group])

    def stale(self):
        return [entry for entry in self.entries if not entry.matched]

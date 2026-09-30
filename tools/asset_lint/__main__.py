"""Проверка ассетов: неиспользуемые файлы, дубликаты и ссылки на несуществующие файлы.

    tools/bootstrap/python -m asset_lint                проверка, как в CI
    tools/bootstrap/python -m asset_lint --unused       все неиспользуемые файлы с размерами
    tools/bootstrap/python -m asset_lint --duplicates   все группы одинаковых файлов
    tools/bootstrap/python -m asset_lint --why PATH     кто ссылается на файл
    tools/bootstrap/python -m asset_lint --states       стейты DMI, чьих имён нет в коде (эвристика)

Файл считается используемым, если на него ссылается DM-код (комментарии не в счёт),
карта, интерфейс .dmf или конфиг. Строки вида "sound/voice/[name].ogg" засчитываются,
если подстановка - известная строка из кода.
Исключения - в tools/asset_lint/allowlist.txt.
"""

import argparse
import os
import sys

from . import inventory
from .allowlist import Allowlist
from .audit import Audit

MIB = 1024 * 1024


def _annotate(path, message):
    if os.environ.get('GITHUB_ACTIONS'):
        print(f'::error file={path}::{message}')


def _size(paths):
    return sum(os.path.getsize(path) for path in paths) / MIB


def check(audit, allowlist):
    errors = list(allowlist.errors)

    for asset in audit.unused:
        if not allowlist.allows('unused', asset):
            errors.append(f'{asset}: на файл никто не ссылается. Удалите его или впишите в allowlist.txt с причиной.')
            _annotate(asset, 'На ассет никто не ссылается')

    for group in inventory.duplicate_groups(audit.assets):
        if not allowlist.allows_group(group):
            errors.append('одинаковые файлы: ' + ', '.join(group) + '. Оставьте один и переведите ссылки на него.')
            _annotate(group[-1], 'Дубликат ' + group[0])

    for path, origin in sorted(audit.broken.items()):
        errors.append(f'{origin}: ссылка на несуществующий файл {path}')
        _annotate(origin, f'Ссылка на несуществующий файл {path}')

    for entry in allowlist.stale():
        errors.append(f'allowlist.txt:{entry.line}: "{entry.kind} {entry.pattern}" больше ничего не прикрывает, удалите запись')

    used = len(audit.assets) - len(audit.unused)
    print(f'asset_lint: {len(audit.assets)} ассетов, используются {used}, исходников DM {len(audit.sources)}')
    if errors:
        print()
        for error in errors:
            print('ОШИБКА:', error)
        return 1
    return 0


def list_unused(audit):
    unused = audit.unused
    for asset in unused:
        print(f'{os.path.getsize(asset):>10}  {asset}')
    print(f'{len(unused)} файлов, {_size(unused):.1f} МБ')


def list_duplicates(audit):
    groups = inventory.duplicate_groups(audit.assets)
    for group in groups:
        print('  '.join(('' if path in audit.used_by else '-') + path for path in group))
    print(f'{len(groups)} групп, лишних копий {sum(len(group) - 1 for group in groups)}')


def why(audit, path):
    path = path.replace('\\', '/')
    if path not in audit.assets:
        print(f'{path}: не ассет или не отслеживается git')
        return 1
    origin = audit.used_by.get(path)
    print(f'{path}: {origin}' if origin else f'{path}: не используется')
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog='asset_lint', description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--unused', action='store_true')
    mode.add_argument('--duplicates', action='store_true')
    mode.add_argument('--why', metavar='PATH')
    mode.add_argument('--states', action='store_true')
    args = parser.parse_args(argv)

    audit = Audit().run()
    if args.unused:
        return list_unused(audit)
    if args.duplicates:
        return list_duplicates(audit)
    if args.why:
        return why(audit, args.why)
    if args.states:
        from .states import report
        return report(audit)
    return check(audit, Allowlist.load())


if __name__ == '__main__':
    sys.exit(main())

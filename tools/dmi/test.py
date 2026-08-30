import os
import struct
import sys
from dmi import *


# Клиент BYOND - 32-битный процесс, и распакованный DMI живёт у него в адресном
# пространстве целиком: спрайт-лист разворачивается в RGBA по четыре байта на пиксель.
# На диске дерево иконок весит около 120 МБ, распакованными - около 2.4 ГБ, то есть
# примерно столько же, сколько Dream Seeker вообще способен занять. Клиент декодирует
# файл, когда впервые из него рисует, поэтому цена приходит ступенями по ходу смены:
# взорвалась станция - плюс сотня мегабайт, кого-то накрыло наркотиками - ещё сотня.
# Кончилось адресное пространство - клиент рисует чужие спрайты вместо штатных и чёрные
# квадраты вместо тайлов, а потом падает.
#
# Отсюда потолок на ОДИН файл. Он не про размер картинки на диске: PNG с прозрачным фоном
# жмётся в сотню килобайт и разворачивается в шестьдесят мегабайт (legacy_tg.dmi:
# 0.1 МБ на диске, 56 МБ в клиенте). Считается только площадь листа.
DECODED_BUDGET_BYTES = 32 * 1024 * 1024

# И потолок на ВСЁ дерево. Отдельный файл может быть скромным, а сумма - нет: клиент
# декодирует ровно те листы, которые ему показали, и дерево на 2.3 ГБ при потолке процесса
# около 3 ГБ означает, что достаточно активный раунд упирается в стену без единого
# нарушителя пофайлового потолка. Число - храповик: опускать по мере разноса листов,
# поднимать только сознательно и с объяснением, почему клиенту это по карману.
TREE_DECODED_BUDGET_BYTES = 2350 * 1024 * 1024

# Файлы, которые уже были над потолком, когда его завели. Значение - ТЕКУЩИЙ размер листа
# в байтах, то есть персональный потолок: уменьшать эти иконки можно свободно, увеличивать -
# только осознанно, поправив цифру здесь. Смысл списка не в том, чтобы простить долг, а в
# том, чтобы он был виден и нумерован.
#
# Замер 28.08.2026, после разноса полноэкранных и параллаксных листов.
# Шесть файлов держат 421 МБ из 2329 МБ всего дерева.
GRANDFATHERED_DECODED_BYTES = {
    'icons/effects/station_explosion.dmi': 150994944,  # 6144x6144, 144 МБ
    'modular_bluemoon/icons/screen/heroin_fullscreen.dmi': 111513600,  # 5280x5280, 106 МБ
    'icons/effects/parallax/legacy_tg.dmi': 58982400,  # 3840x3840, 56 МБ
    'modular_bluemoon/icons/obj/barsigns.dmi': 42614784,  # 3264x3264, 41 МБ
    'modular_splurt/icons/mob/widerobot.dmi': 38936576,  # 3136x3104, 37 МБ
    'modular_bluemoon/icons/screen/drug_fullscreen.dmi': 38707200,  # 3360x2880, 37 МБ
}

PNG_MAGIC = b'\x89PNG\r\n\x1a\n'
MIB = 1024 * 1024


def _decoded_bytes(fullpath):
    """Во сколько байт развернётся спрайт-лист у клиента.

    Читается заголовок IHDR, а не картинка: ширина и высота лежат в первых 24 байтах
    файла, и разворачивать двадцать мегапикселей ради двух чисел незачем. Возвращает
    None, если файл не PNG - такой случай поймает разбор ниже, а не эта проверка.
    """
    with open(fullpath, 'rb') as handle:
        head = handle.read(24)
    if len(head) < 24 or head[:8] != PNG_MAGIC or head[12:16] != b'IHDR':
        return None
    width, height = struct.unpack('>II', head[16:24])
    return width * height * 4


def _self_test():
    # test: can we load every DMI in the tree
    count = 0
    total_decoded = 0
    measured = []
    for dirpath, dirnames, filenames in os.walk('.'):
        for skipped in ('.git', '.claude', 'node_modules'):
            if skipped in dirnames:
                dirnames.remove(skipped)
        for filename in filenames:
            if filename.endswith('.dmi'):
                fullpath = os.path.join(dirpath, filename)
                try:
                    Dmi.from_file(fullpath)
                except Exception:
                    print('Failed on:', fullpath)
                    raise
                count += 1
                decoded = _decoded_bytes(fullpath)
                if decoded is not None:
                    total_decoded += decoded
                    measured.append((decoded, os.path.relpath(fullpath).replace(os.sep, '/')))

    print(f"{os.path.relpath(__file__)}: successfully parsed {count} .dmi files")
    print(f"{os.path.relpath(__file__)}: распакованными у клиента это {total_decoded / MIB:.0f} МБ")

    failures = []
    for decoded, relpath in sorted(measured, reverse=True):
        if decoded <= DECODED_BUDGET_BYTES:
            break
        allowed = GRANDFATHERED_DECODED_BYTES.get(relpath)
        if allowed is None:
            failures.append(
                f"{relpath}: лист разворачивается в {decoded / MIB:.0f} МБ памяти клиента "
                f"при потолке {DECODED_BUDGET_BYTES / MIB:.0f} МБ. Клиент 32-битный, и такой "
                f"файл он держит целиком с первой же отрисовки. Уменьшите холст или число "
                f"кадров - либо, если цена осознана, впишите файл в GRANDFATHERED_DECODED_BYTES."
            )
        elif decoded > allowed:
            failures.append(
                f"{relpath}: лист вырос до {decoded / MIB:.0f} МБ памяти клиента "
                f"с прежних {allowed / MIB:.0f} МБ. Файл и так над потолком; расти ему нельзя."
            )

    if total_decoded > TREE_DECODED_BUDGET_BYTES:
        failures.append(
            f"дерево иконок разворачивается в {total_decoded / MIB:.0f} МБ при потолке "
            f"{TREE_DECODED_BUDGET_BYTES / MIB:.0f} МБ. Это сумма, а не один файл: "
            f"клиенту столько показать нечем. Разнесите крупный лист по стейтам или "
            f"снесите неиспользуемый - и только осознанно поднимайте TREE_DECODED_BUDGET_BYTES."
        )

    if failures:
        print()
        for failure in failures:
            print('ОШИБКА:', failure)
        exit(1)


def _usage():
    print(f"Usage:")
    print(f"    tools{os.sep}bootstrap{os.sep}python -m {__spec__.name}")
    exit(1)


def _main():
    if len(sys.argv) == 1:
        return _self_test()

    return _usage()


if __name__ == '__main__':
    _main()

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

# И потолок на ВСЁ дерево: каждый файл может быть скромным, а сумма - нет. Клиент держит
# 3 ГБ распакованных листов без заметных просадок, поэтому потолок 3000 МБ, а не впритык к
# текущему размеру. Поднимать его в каждом ПР с новыми спрайтами не нужно - на этом ПР и
# конфликтуют между собой. Когда запас станет меньше TREE_WARN_HEADROOM_BYTES, проверка
# предупредит заранее, и разносить крупные листы можно будет без спешки.
TREE_DECODED_BUDGET_BYTES = 3000 * 1024 * 1024
TREE_WARN_HEADROOM_BYTES = 100 * 1024 * 1024
TREE_REPORT_TOP = 10

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


def _description_chunk_type(fullpath):
    """Каким PNG-чанком записана метадата DMI.

    DreamMaker пишет Description в zTXt, и только его читает rust-g при сборке
    спрайтшитов: файл с tEXt-описанием (сторонние редакторы) BYOND открывает молча,
    а rust-g не видит вовсе - лист теряет спрайты и пересобирается каждый раунд.
    Возвращает 'zTXt', 'tEXt', 'iTXt' или None, если описания нет.
    """
    with open(fullpath, 'rb') as handle:
        if handle.read(8) != PNG_MAGIC:
            return None
        while True:
            header = handle.read(8)
            if len(header) < 8:
                return None
            length, chunk_type = struct.unpack('>I4s', header)
            if chunk_type == b'IEND':
                return None
            if chunk_type in (b'zTXt', b'tEXt', b'iTXt'):
                if handle.read(length).split(b'\0', 1)[0] == b'Description':
                    return chunk_type.decode('ascii')
                handle.seek(4, os.SEEK_CUR)
            else:
                handle.seek(length + 4, os.SEEK_CUR)


def _warn(message):
    # В Actions строка с ::warning:: становится аннотацией на странице прогона.
    if os.environ.get('GITHUB_ACTIONS') == 'true':
        print(f"::warning title=Дерево иконок::{message}")
    else:
        print('ПРЕДУПРЕЖДЕНИЕ:', message)


def _self_test():
    # test: can we load every DMI in the tree
    count = 0
    total_decoded = 0
    measured = []
    failures = []
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
                chunk_type = _description_chunk_type(fullpath)
                if chunk_type not in (None, 'zTXt'):
                    failures.append(
                        f"{os.path.relpath(fullpath).replace(os.sep, '/')}: метадата DMI лежит в чанке "
                        f"{chunk_type}, а не zTXt. rust-g такой файл не читает, и спрайтшиты теряют его "
                        f"спрайты. Пересохраните файл в DreamMaker или через tools/dmi."
                    )
                decoded = _decoded_bytes(fullpath)
                if decoded is not None:
                    total_decoded += decoded
                    measured.append((decoded, os.path.relpath(fullpath).replace(os.sep, '/')))

    print(f"{os.path.relpath(__file__)}: successfully parsed {count} .dmi files")
    print(
        f"{os.path.relpath(__file__)}: распакованными у клиента это {total_decoded / MIB:.0f} МБ "
        f"из {TREE_DECODED_BUDGET_BYTES / MIB:.0f}, запас {(TREE_DECODED_BUDGET_BYTES - total_decoded) / MIB:.0f} МБ"
    )

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

    headroom = TREE_DECODED_BUDGET_BYTES - total_decoded
    if headroom < 0:
        failures.append(
            f"дерево иконок разворачивается в {total_decoded / MIB:.0f} МБ при потолке "
            f"{TREE_DECODED_BUDGET_BYTES / MIB:.0f} МБ. Это сумма, а не один файл: "
            f"клиенту столько показать нечем. Разнесите крупный лист по стейтам или "
            f"снесите неиспользуемый - и только осознанно поднимайте TREE_DECODED_BUDGET_BYTES."
        )
    elif headroom < TREE_WARN_HEADROOM_BYTES:
        _warn(
            f"до потолка дерева иконок осталось {headroom / MIB:.0f} МБ "
            f"({total_decoded / MIB:.0f} из {TREE_DECODED_BUDGET_BYTES / MIB:.0f}). "
            f"Пора разносить крупные листы, пока проверка не покраснела."
        )
    if headroom < TREE_WARN_HEADROOM_BYTES:
        print(f"\nКрупнейшие листы, МБ в клиенте:")
        for decoded, relpath in sorted(measured, reverse=True)[:TREE_REPORT_TOP]:
            print(f"    {decoded / MIB:6.1f}  {relpath}")

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
    # Консоль Windows по умолчанию не в UTF-8, и русские сообщения выходят кракозябрами.
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
    if len(sys.argv) == 1:
        return _self_test()

    return _usage()


if __name__ == '__main__':
    _main()

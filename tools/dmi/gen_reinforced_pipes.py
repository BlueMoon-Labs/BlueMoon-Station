#!/usr/bin/env python3
"""Генерация спрайтов усиленной трубы и маркеров повреждения.

Готового арта под усиленную трубу нет ни в одной соседней кодбазе: в линии
Baystation она нарисована в чужой школе (icons/obj/atmospherics/red_pipe.dmi,
стейт "intact"), а в линии tg такой трубы нет вовсе. Поэтому спрайт выводится
из нашего же: штрих трубы расширяется на пиксель с каждой стороны, а исходные
пиксели притемняются. Получается "толще стенка", что заодно ровно иллюстрирует
механику - у усиленной трубы меньше просвет и меньше объём.

Маркеры повреждения рисуются по явной сетке, без псевдослучайности: результат
обязан быть воспроизводимым и читаемым построчно в ревью. Оба маркера
центрируются в тайле, потому что через центр проходят все восемь направлений
трубы - значит один стейт закрывает весь набор вместо восьми.

Скрипт идемпотентен: повторный запуск даёт тот же результат и не плодит дублей
стейтов.

Запуск из корня репозитория:
    python tools/dmi/gen_reinforced_pipes.py
"""

import pathlib
import sys

from PIL import Image

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from dmi import Dmi  # noqa: E402

ICONS = pathlib.Path("icons/obj/atmospherics/pipes")

# Насколько притемняются исходные пиксели. Труба рендерится с умножением на
# pipe_color, поэтому притемнение обязано быть мягким: иначе покрашенная труба
# уходит в грязь.
CORE_DARKEN = 0.88

BREACH_PALETTE = {
    "#": (0x2B, 0x2B, 0x2B, 255),
    "o": (0x7A, 0x7A, 0x7A, 255),
    "*": (0xE8, 0xE8, 0xE8, 255),
    ".": (0, 0, 0, 0),
}

# Размеры подобраны по отрисовке: 5 пикселей в 32-пиксельном тайле на игровом
# зуме теряются, 7 и 9 читаются. Свищ обязан быть заметно мельче разрыва -
# разница стадий должна быть видна с одного взгляда, без осмотра.
BREACH_LEAK = [
    ". . # # # . .",
    ". # o * o # .",
    "# o * # * o #",
    "# * # # # * #",
    "# o * # * o #",
    ". # o * o # .",
    ". . # # # . .",
]

BREACH_RUPTURE = [
    ". . # # # # # . .",
    ". # o * o * o # .",
    "# o * # # # * o #",
    "# * # . . . # * #",
    "# o # . . . # o #",
    "# * # . . . # * #",
    "# o * # # # * o #",
    ". # o * o * o # .",
    ". . # # # # # . .",
]


def luminance(pixel):
    red, green, blue, _alpha = pixel
    return 0.299 * red + 0.587 * green + 0.114 * blue


def thicken(frame):
    """Расширяет штрих на пиксель с каждой стороны, сохраняя контур снаружи."""
    source = frame.convert("RGBA")
    width, height = source.size
    src = source.load()

    opaque = [
        (x, y)
        for y in range(height)
        for x in range(width)
        if src[x, y][3] > 0
    ]
    if not opaque:
        return source.copy()

    # Самый тёмный непрозрачный цвет кадра - это контур трубы, им и обводим.
    outline = min((src[x, y] for x, y in opaque), key=luminance)

    result = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    out = result.load()

    # Сначала кольцо новых пикселей контуром. Оно ложится только туда, где
    # источник прозрачен, поэтому со вторым проходом не конфликтует.
    for x, y in opaque:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height and src[nx, ny][3] == 0:
                    out[nx, ny] = outline

    # Потом поверх - исходные пиксели, притемнённые.
    for x, y in opaque:
        red, green, blue, alpha = src[x, y]
        out[x, y] = (
            int(red * CORE_DARKEN),
            int(green * CORE_DARKEN),
            int(blue * CORE_DARKEN),
            alpha,
        )

    return result


def copy_state(target, source, name, transform):
    """Переносит стейт со всей метадатой, прогоняя кадры через transform."""
    state = target.state(
        name,
        dirs=source.dirs,
        loop=source.loop,
        rewind=source.rewind,
        movement=source.movement,
    )
    for index, frame in enumerate(source.frames):
        delay = source.delays[index] if index < len(source.delays) else 1
        state.frame(transform(frame), delay=delay)
    if source.hotspots:
        state.hotspots = list(source.hotspots)
    return state


def derive_sheet(source_path, target_path):
    source = Dmi.from_file(source_path)
    target = Dmi(source.width, source.height)
    for state in source.states:
        copy_state(target, state, state.name, thicken)
    target.to_file(target_path)
    print(f"{target_path}: {len(target.states)} стейтов из {source_path}")


def add_item_states(path, pairs):
    """Дописывает предметные стейты для RPD прямо в pipe_item.dmi."""
    sheet = Dmi.from_file(path)
    existing = {state.name: state for state in sheet.states}
    for source_name, new_name in pairs:
        if source_name not in existing:
            raise SystemExit(f"{path}: нет исходного стейта {source_name!r}")
        # Идемпотентность: повторный запуск заменяет, а не добавляет второй.
        sheet.states = [state for state in sheet.states if state.name != new_name]
        copy_state(sheet, existing[source_name], new_name, thicken)
    sheet.to_file(path)
    print(f"{path}: предметные стейты {[pair[1] for pair in pairs]}")


def draw_grid(grid):
    frame = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    pixels = frame.load()
    rows = [row.split() for row in grid]
    height = len(rows)
    width = len(rows[0])
    if any(len(row) != width for row in rows):
        raise SystemExit("сетка маркера должна быть прямоугольной")
    left = (32 - width) // 2
    top = (32 - height) // 2
    for y, row in enumerate(rows):
        for x, cell in enumerate(row):
            colour = BREACH_PALETTE[cell]
            if colour[3]:
                pixels[left + x, top + y] = colour
    return frame


def build_damage_sheet(path):
    sheet = Dmi(32, 32)
    sheet.state("breach_leak").frame(draw_grid(BREACH_LEAK))
    sheet.state("breach_rupture").frame(draw_grid(BREACH_RUPTURE))
    sheet.to_file(path)
    print(f"{path}: breach_leak, breach_rupture")


def main():
    if not ICONS.is_dir():
        raise SystemExit("запускать из корня репозитория")
    derive_sheet(ICONS / "simple.dmi", ICONS / "reinforced.dmi")
    derive_sheet(ICONS / "manifold.dmi", ICONS / "reinforced_manifold.dmi")
    add_item_states(
        ICONS / "pipe_item.dmi",
        [
            ("simple", "reinforced_simple"),
            ("manifold", "reinforced_manifold"),
            ("manifold4w", "reinforced_manifold4w"),
        ],
    )
    build_damage_sheet(ICONS / "pipe_damage.dmi")


if __name__ == "__main__":
    main()

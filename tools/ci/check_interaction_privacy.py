import re
import sys
from pathlib import Path


INTERACTION_ENTRY_POINTS = {"do_action", "display_interaction", "post_interaction", "special_check"}
OUTPUT_RANGES = {
    "visible_message": ("vision_distance", 3),
    "audible_message": ("hearing_distance", 2),
    "playsound": ("extrarange", 4),
    "playlewdinteractionsound": ("extrarange", 4),
}
REACTIONS = {
    "apply_effect", "audio_effects", "buckle_mob", "clear_cuffs", "clothing_burst",
    "cum", "do_climax", "handle_post_sex", "moan", "mob_climax", "play_interaction_sound",
    "post_reaction", "target_reaction", "try_apply_knot", "try_moan",
    "try_play_interaction_effect", "user_lust_grant", "partner_lust_grant",
}
PROCEDURE = re.compile(r"^(/[\w/]+)\(([^)\n]*)\)")
TOP_LEVEL = re.compile(r"(?m)^(?=/(?![/*]))")
CALL = re.compile(r"\b(" + "|".join(sorted(OUTPUT_RANGES.keys() | REACTIONS | INTERACTION_ENTRY_POINTS)) + r")\(")
NON_CODE = re.compile(r"""//|/\*|["']""")
HIDDEN_FLAG = r"(?:is_hidden|knot_is_hidden)"
HIDDEN = re.compile(rf"\b{HIDDEN_FLAG}\b")
TEXT_RANGE = re.compile(rf"HIDDEN_INTERACTION_RANGE|INTERACTION_MESSAGE_RANGE\({HIDDEN_FLAG}\)|{HIDDEN_FLAG}\s*\?\s*(?:1|HIDDEN_INTERACTION_RANGE)\s*:\s*\w+")
SOUND_RANGE = re.compile(rf"(?:DEFAULT_)?INTERACTION_SOUND_EXTRARANGE\({HIDDEN_FLAG}(?:\s*,\s*-?\d+)?\)")


def end_of_group(source, start, closing):
    # В интерполяции DM могут встречаться вложенные строки и скобки.
    cursor = start
    while cursor < len(source):
        char = source[cursor]
        cursor += 1
        if char == closing:
            return cursor
        if closing in ('"', "'"):
            if char == "\\":
                cursor += 1
            elif char == "[" and closing == '"':
                cursor = end_of_group(source, cursor, "]")
        elif char in ('"', "'", "(", "["):
            cursor = end_of_group(source, cursor, {"(": ")", "[": "]"}.get(char, char))
    return len(source)


def mask_non_code(source):
    # Сохраняем переносы строк для диагностики CI.
    parts = []
    cursor = 0
    while match := NON_CODE.search(source, cursor):
        parts.append(source[cursor:match.start()])
        marker = match.group()
        if marker in ('"', "'"):
            end = end_of_group(source, match.end(), marker)
        elif marker == "//":
            end = source.find("\n", match.end())
            end = len(source) if end < 0 else end
        else:
            end = source.find("*/", match.end())
            end = len(source) if end < 0 else end + 2
        parts.append(re.sub(r"[^\n]", " ", source[match.start():end]))
        cursor = end
    parts.append(source[cursor:])
    return "".join(parts)


def split_arguments(source):
    start = cursor = 0
    while cursor < len(source):
        char = source[cursor]
        cursor += 1
        if char == ",":
            yield source[start:cursor - 1].strip()
            start = cursor
        elif char in "([":
            cursor = end_of_group(source, cursor, {"(": ")", "[": "]"}[char])
    yield source[start:].strip()


def limits_range(expression, before_call, is_sound):
    pattern = SOUND_RANGE if is_sound else TEXT_RANGE
    if pattern.fullmatch(expression):
        return True
    if not re.fullmatch(r"\w+", expression):
        return False
    alias = re.escape(expression)
    assignments = re.findall(rf"(?m)^\s*(?:var/)?{alias}\s*=\s*([^\n]+)", before_call)
    if assignments and pattern.fullmatch(assignments[-1].strip()):
        return True
    return not is_sound and bool(re.search(rf"if\({HIDDEN_FLAG}\)[ \t]*\n[ \t]+{alias}\s*=\s*1\b", before_call))


def check_file(path, source):
    code = mask_non_code(source)
    entry_points = checked_calls = 0
    errors = []
    line = 1
    for block in TOP_LEVEL.split(code):
        start_line = line
        line += block.count("\n")
        declaration = PROCEDURE.match(block)
        if not declaration:
            continue
        proc, arguments = declaration.groups()
        is_interaction = proc.startswith("/datum/interaction/")
        entry_point = is_interaction and proc.rsplit("/", 1)[-1] in INTERACTION_ENTRY_POINTS
        if entry_point:
            entry_points += 1
            if not HIDDEN.search(arguments):
                errors.append(f"{path}:{start_line}: {proc} не принимает is_hidden")
        if not (is_interaction or HIDDEN.search(arguments) or "knot_is_hidden" in block):
            continue

        for call in CALL.finditer(block, declaration.end()):
            name = call.group(1)
            end = end_of_group(block, call.end(), ")")
            passed = re.sub(r"\\[ \t]*\n", "\n", block[call.end():end - 1])
            before_call = block[:call.start()]
            checked_calls += 1
            location = f"{path}:{start_line + before_call.count(chr(10))}"
            if name in OUTPUT_RANGES:
                args = list(split_arguments(passed))
                named = dict(match.groups() for arg in args if (match := re.fullmatch(r"(\w+)\s*=\s*(.*)", arg, re.DOTALL)))
                flag, expected = ("visible_message_flags", rf"INTERACTION_MESSAGE_FLAGS\({HIDDEN_FLAG}\)") if name == "visible_message" else ("local_only", HIDDEN_FLAG)
                if not re.fullmatch(expected, named.get(flag, "")):
                    errors.append(f"{location}: {proc} вызывает {name} без передачи скрытого режима через {flag}")
                range_name, index = OUTPUT_RANGES[name]
                distance = named.get(range_name, args[index] if index < len(args) else "")
                if not limits_range(distance, before_call, range_name == "extrarange"):
                    errors.append(f"{location}: {proc} вызывает {name} без ограничения радиуса в скрытом режиме")
            elif not HIDDEN.search(passed):
                if name == "moan" and passed.strip() == "TRUE" and re.search(rf"if\({HIDDEN_FLAG}\)\s*\n[^\n]*$", before_call):
                    continue
                errors.append(f"{location}: {proc} вызывает {name} без передачи is_hidden")
    return entry_points, checked_calls, errors


def main():
    # Проверяем файлы, которые входят в сборку, включая модульные каталоги.
    dme = Path("tgstation.dme").read_text(encoding="utf-8")
    paths = re.findall(r'(?m)^#include "([^"]+\.dm)"', dme)
    entry_points = checked_calls = 0
    errors = []
    for filename in paths:
        path = Path(filename.replace("\\", "/"))
        if not path.is_file() or "unit_tests" in path.parts:
            continue
        source = path.read_text(encoding="utf-8", errors="replace")
        if "/datum/interaction/" not in source and not HIDDEN.search(source):
            continue
        found_entries, found_calls, found_errors = check_file(path, source)
        entry_points += found_entries
        checked_calls += found_calls
        errors.extend(found_errors)

    for error in errors:
        print(error, file=sys.stderr)
    print(f"Проверено обработчиков интеракций: {entry_points}, вызовов: {checked_calls}.")
    return int(bool(errors) or not entry_points or not checked_calls)


if __name__ == "__main__":
    sys.exit(main())

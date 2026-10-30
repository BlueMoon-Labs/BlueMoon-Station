"""
Checks the changelog in a PR description the way generate_cl.py will read it after the merge.
generate_cl.py silently drops lines with an unknown tag, lines left from the PR template and
lines that do not match its pattern; this script turns each of them into a warning beforehand.
It never fails: a PR without a changelog is allowed.

Expected environment variables:
PR_BODY: the description of the pull request
GITHUB_STEP_SUMMARY: where the summary goes, optional
"""
import os
import re
from pathlib import Path

import yaml

# The same patterns as in generate_cl.py.
CL_BODY = re.compile(r":cl:([^\r\n]+)?\r?\n((.|\n|\r)+?)\r?\n\/:cl:", re.MULTILINE)
CL_SPLIT = re.compile(r"(^\w+):\s+(\w.+)", re.MULTILINE)
# What generate_cl.py takes from the rest of the :cl: line as the author.
AUTHOR = re.compile(r"[\w .-]{1,40}")


def check(body, tags):
    """Returns (number of lines that make it into the changelog, warnings)."""
    cl = CL_BODY.search(body or "")
    if not cl:
        return 0, []
    warnings = []
    author = (cl.group(1) or "").strip()
    if author and not AUTHOR.fullmatch(author):
        warnings.append(f'Автором записи станет "{author[:80]}": первое :cl: в описании открывает блок, даже упомянутое в тексте.')
    kept = 0
    defaults = set(tags["defaults"].values())
    for line in cl.group(2).splitlines():
        if not line.strip():
            continue
        # No strip: generate_cl.py drops a line with a leading space as well.
        entry = CL_SPLIT.match(line)
        if not entry:
            warnings.append(f'Строка не по формату "тег: текст", в чейнджлог не попадёт: {line}')
        elif entry.group(1) not in tags["tags"]:
            known = ", ".join(sorted(tags["tags"]))
            warnings.append(f'Неизвестный тег "{entry.group(1)}", строка пропадёт. Теги: {known}')
        elif entry.group(2).rstrip() in defaults:
            warnings.append(f"Строка осталась из шаблона и будет выброшена: {line}")
        else:
            kept += 1
    if kept == 0:
        warnings.append("В блоке :cl: не осталось ни одной строки, чейнджлог для этого PR не появится.")
    return kept, warnings


def main():
    tags = yaml.safe_load(Path(__file__).with_name("tags.yml").read_text(encoding="utf-8"))
    body = os.getenv("PR_BODY", "")
    kept, warnings = check(body, tags)
    if not CL_BODY.search(body):
        message = "В описании нет блока :cl: ... /:cl:, этот PR не попадёт в чейнджлог."
        print(f"::notice title=Чейнджлог::{message}")
        summary = message
    else:
        for warning in warnings:
            print(f"::warning title=Чейнджлог::{warning}")
        summary = f"Строк в чейнджлоге: {kept}." + "".join(f"\n- {warning}" for warning in warnings)
    print(summary)
    summary_file = os.getenv("GITHUB_STEP_SUMMARY")
    if summary_file:
        with open(summary_file, "a", encoding="utf-8") as file:
            file.write(f"## Чейнджлог\n\n{summary}\n")


if __name__ == "__main__":
    main()

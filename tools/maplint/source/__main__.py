import argparse
import glob
from collections import Counter
import pathlib
import traceback
import yaml

from . import baseline, dmm, lint
from .error import MaplintError

def green(text):
    return "\033[32m" + str(text) + "\033[0m"

def red(text):
    return "\033[31m" + str(text) + "\033[0m"

def process_dmm(map_filename, lints: dict[str, lint.Lint]) -> list[MaplintError]:
    problems: list[MaplintError] = []

    with open(map_filename, "r", encoding = "utf-8") as file:
        try:
            map_data = dmm.parse_dmm(file)
        except MaplintError as error:
            problems.append(error)
            # No structured data to lint.
            return problems

        for lint_name, lint in lints.items():
            try:
                lint_problems = lint.run(map_data)
            except KeyboardInterrupt:
                raise
            except Exception:
                lint_problems = [MaplintError(
                    f"An exception occurred, this is either a bug in maplint or a bug in a lint. \n{traceback.format_exc()}",
                    map_filename,
                )]

            for problem in lint_problems:
                problem.lint_name = lint_name
            problems.extend(lint_problems)

    return problems

def print_error(message: str, filename: str, line_number: int, github_error_style: bool):
    if github_error_style:
        print(f"::error file={filename},line={line_number},title=DMM Linter::{message}")
    else:
        print(red(f"- Error parsing {filename} (line {line_number}): {message}"))

def print_maplint_error(error: MaplintError, github_error_style: bool):
    print_error(
        f"{f'(in pop {error.pop_id}) ' if error.pop_id else ''}{f'(at {error.coordinates}) ' if error.coordinates else ''}{error}" + (f"\n  {error.help}" if error.help is not None else ""),
        error.file_name,
        error.line_number,
        github_error_style,
    )

def print_baseline_entry(text: str, baseline_path: pathlib.Path, github_error_style: bool):
    if github_error_style:
        print(f"::error file={baseline.normalize_map_path(baseline_path)},line=1,title=DMM Linter baseline::{text}")
    else:
        print(red(f"- {text}"))

def main(args):
    lints_failed = False
    github_error_style = args.github

    lints: dict[str, lint.Lint] = {}

    lint_base = pathlib.Path(__file__).parent.parent / "lints"
    lint_filenames = []
    if args.lints is None:
        lint_filenames = sorted(lint_base.glob("*.yml"))
    else:
        lint_filenames = [lint_base / f"{lint_name}.yml" for lint_name in args.lints]

    for lint_filename in lint_filenames:
        try:
            lints[lint_filename.stem] = lint.Lint(yaml.safe_load(lint_filename.read_text(encoding = "utf-8")))
        except MaplintError as error:
            print_maplint_error(error, github_error_style)
            lints_failed = True
        except Exception:
            print_error("Error loading lint file.", lint_filename, 1, github_error_style)
            traceback.print_exc()
            lints_failed = True

    any_failed = lints_failed

    baseline_path = pathlib.Path(args.baseline) if args.baseline else None
    previous = baseline.load(baseline_path) if baseline_path is not None else {}
    known = {} if args.update_baseline else previous

    map_filenames = [baseline.normalize_map_path(map_filename) for map_filename in (args.maps or sorted(glob.glob("_maps/**/*.dmm", recursive = True)))]
    found: Counter = Counter()

    for map_filename in map_filenames:
        print(map_filename, end = " ")

        all_failures: list[MaplintError] = []

        try:
            all_failures.extend(process_dmm(map_filename, lints))
        except KeyboardInterrupt:
            raise
        except Exception:
            all_failures.append(MaplintError(
                f"An exception occurred, this is either a bug in maplint or a bug in a lint.' {traceback.format_exc()}",
                map_filename,
            ))

        map_found = baseline.count_errors(all_failures)
        found.update(map_found)

        over_keys = {key for key, count in map_found.items() if count > known.get(key, 0)}
        new_failures = [failure for failure in all_failures if baseline.key_for(failure) in over_keys]

        if len(new_failures) == 0:
            print(green("OK"))
        else:
            print(red("X"))
            any_failed = True

        for failure in new_failures:
            print_maplint_error(failure, github_error_style)

        for key in sorted(over_keys):
            if known.get(key, 0) > 0:
                print_error(f"{key[1]} on {key[2]}: {map_found[key]} found, the baseline allows {known[key]}. The errors above include the old ones, fix the new ones.", map_filename, 1, github_error_style)

    if baseline_path is None:
        exit(1 if any_failed else 0)

    checked_maps = set(map_filenames)
    checked_lints = set(lints.keys())

    # A full run also owns entries of deleted maps and lints, so they go stale instead of lingering
    if not args.maps:
        checked_maps.update(key[0] for key in previous)
    if args.lints is None:
        checked_lints.update(key[1] for key in previous)

    if args.update_baseline:
        updated = baseline.merge(previous, found, checked_maps, checked_lints)
        baseline.save(baseline_path, updated)
        print(f"Baseline written to {baseline_path}: {sum(updated.values())} violations in {len(updated)} entries.")
        if lints_failed:
            exit(1)
        return

    comparison = baseline.compare(found, known, checked_maps, checked_lints)
    for (map_file, lint_name, typepath), (count, allowed) in sorted(comparison.stale.items()):
        print_baseline_entry(f"Baseline allows {allowed} of {lint_name} on {typepath or 'the whole map'} in {map_file}, only {count} left. Regenerate it with --update-baseline.", baseline_path, github_error_style)
        any_failed = True

    if any_failed:
        exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog = "maplint",
        description = "Checks for common errors in maps.",
    )

    parser.add_argument("maps", nargs = "*")
    parser.add_argument("--lints", nargs = "*")
    parser.add_argument("--github", action='store_true')
    parser.add_argument("--baseline", help = "JSON file of known violations, only violations beyond it fail")
    parser.add_argument("--update-baseline", action = "store_true", help = "Rewrite --baseline with the violations found in the checked maps and lints")

    args = parser.parse_args()

    if args.update_baseline and not args.baseline:
        parser.error("--update-baseline needs --baseline")

    main(args)

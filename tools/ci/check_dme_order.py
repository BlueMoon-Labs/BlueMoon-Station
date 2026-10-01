"""Checks that .dme includes are sorted the way DreamMaker sorts them.

Usage: python3 tools/ci/check_dme_order.py tgstation.dme [--fix]
"""
import sys

BEGIN = "// BEGIN_INCLUDE"
END = "// END_INCLUDE"


def sort_key(line):
	parts = line[len('#include "'):-1].lower().split("\\")
	name = parts[-1]
	# DreamMaker puts files before subfolders, and .dm before .dmf/.dmm.
	return [(1, folder) for folder in parts[:-1]] + [(0, not name.endswith(".dm"), name)]


def main():
	args = [arg for arg in sys.argv[1:] if arg != "--fix"]
	fix = "--fix" in sys.argv[1:]
	if len(args) != 1:
		print(__doc__)
		return 2
	path = args[0]
	with open(path, encoding="utf-8", newline="") as dme:
		text = dme.read()
	newline = "\r\n" if "\r\n" in text else "\n"
	lines = text.split(newline)
	start = lines.index(BEGIN) + 1
	end = lines.index(END)
	includes = lines[start:end]
	expected = sorted(includes, key=sort_key)
	if includes == expected:
		return 0
	if fix:
		lines[start:end] = expected
		with open(path, "w", encoding="utf-8", newline="") as dme:
			dme.write(newline.join(lines))
		print(f"{path}: includes sorted")
		return 0
	for index, (actual, wanted) in enumerate(zip(includes, expected)):
		if actual != wanted:
			print(f"ERROR: {path}:{start + index + 1}: expected {wanted}, found {actual}")
			break
	print("Includes must stay in DreamMaker order so that file order never matters. Shared #defines go to code/__DEFINES or code/__BLUEMOONCODE/_DEFINES.")
	print(f"To fix: python3 tools/ci/check_dme_order.py {path} --fix")
	return 1


if __name__ == "__main__":
	sys.exit(main())

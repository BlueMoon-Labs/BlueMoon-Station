import copy
import io
import pathlib
import tempfile
import unittest
from collections import Counter

from . import baseline, dmm, lint
from .error import MaplintError

HEADER = "//MAP CONVERTED BY dmm2tgm.py THIS HEADER COMMENT PREVENTS RECONVERSION, DO NOT REMOVE\n"

REAGENTS_LINT = {
    "*": {
        "banned_variables": ["reagents"],
    },
}

def make_map(pops: dict[str, str], columns: list[list[str]]) -> str:
    text = HEADER
    for key, contents in pops.items():
        text += f'"{key}" = (\n{contents})\n'
    text += "\n"
    for x, column in enumerate(columns, start = 1):
        text += f'({x},1,1) = {{"\n' + "\n".join(column) + '\n"}\n'
    return text

def lint_map(text: str, map_name = "_maps/test.dmm") -> list[MaplintError]:
    reader = io.StringIO(text)
    reader.name = map_name
    map_data = dmm.parse_dmm(reader)
    errors = lint.Lint(copy.deepcopy(REAGENTS_LINT)).run(map_data)
    for error in errors:
        error.lint_name = "reagents_varedits"
    return errors

BOTTLE = "/obj/item/reagent_containers/glass/bottle{\n\treagents = /datum/reagent/water\n\t},\n"
FLOOR = "/turf/open/floor/plating,\n/area/space"

def error(map_file = "_maps/a.dmm", lint_name = "multiple_tables", typepath = "/obj/structure/table", instances = 1, pop_id = "a") -> MaplintError:
    result = MaplintError("test", map_file)
    result.lint_name = lint_name
    result.typepath = typepath
    result.instances = instances
    result.pop_id = pop_id
    return result

class TestKeys(unittest.TestCase):
    def test_key_ignores_pop_and_coordinates(self):
        first = error(pop_id = "a")
        first.coordinates = "(1, 1, 1)"
        second = error(pop_id = "b", instances = 2)
        second.coordinates = "(5, 5, 1)"

        self.assertEqual(baseline.key_for(first), baseline.key_for(second))
        self.assertEqual(baseline.count_errors([first, second]), Counter({("_maps/a.dmm", "multiple_tables", "/obj/structure/table"): 3}))

    def test_windows_paths_are_normalized(self):
        self.assertEqual(baseline.key_for(error(map_file = "_maps\\a.dmm"))[0], "_maps/a.dmm")

    def test_parse_errors_have_their_own_lint(self):
        parse_error = MaplintError("Pop content didn't lead to a path", "_maps/a.dmm", 3)
        self.assertEqual(baseline.key_for(parse_error), ("_maps/a.dmm", baseline.PARSE_LINT, ""))

class TestCompare(unittest.TestCase):
    key = ("_maps/a.dmm", "multiple_tables", "/obj/structure/table")
    other_map_key = ("_maps/b.dmm", "multiple_tables", "/obj/structure/table")

    def compare(self, found, known, maps = ("_maps/a.dmm",), lints = ("multiple_tables",)):
        return baseline.compare(Counter(found), known, set(maps), set(lints))

    def test_within_baseline_passes(self):
        comparison = self.compare({self.key: 2}, {self.key: 2})
        self.assertEqual(comparison.over, {})
        self.assertEqual(comparison.stale, {})

    def test_more_than_baseline_fails(self):
        comparison = self.compare({self.key: 3}, {self.key: 2})
        self.assertEqual(comparison.over, {self.key: (3, 2)})

    def test_new_key_fails(self):
        comparison = self.compare({self.key: 1}, {})
        self.assertEqual(comparison.over, {self.key: (1, 0)})

    def test_fixed_violations_make_the_entry_stale(self):
        comparison = self.compare({self.key: 1}, {self.key: 2})
        self.assertEqual(comparison.over, {})
        self.assertEqual(comparison.stale, {self.key: (1, 2)})

        comparison = self.compare({}, {self.key: 2})
        self.assertEqual(comparison.stale, {self.key: (0, 2)})

    def test_unchecked_maps_and_lints_are_not_stale(self):
        known = {self.key: 2, self.other_map_key: 1}
        self.assertEqual(self.compare({self.key: 2}, known).stale, {})
        self.assertEqual(self.compare({}, {self.key: 2}, lints = ("area_noop",)).stale, {})

class TestMerge(unittest.TestCase):
    def test_merge_replaces_only_checked_entries(self):
        kept = ("_maps/b.dmm", "multiple_tables", "/obj/structure/table")
        other_lint = ("_maps/a.dmm", "area_noop", "/area/template_noop")
        fixed = ("_maps/a.dmm", "multiple_tables", "/obj/structure/table")
        raised = ("_maps/a.dmm", "multiple_tables", "/obj/structure/table/wood")
        parse = ("_maps/a.dmm", baseline.PARSE_LINT, "")

        merged = baseline.merge(
            {kept: 4, other_lint: 1, fixed: 2, parse: 1},
            Counter({raised: 3}),
            {"_maps/a.dmm"},
            {"multiple_tables"},
        )

        self.assertEqual(merged, {kept: 4, other_lint: 1, raised: 3})

    def test_file_round_trip(self):
        known = {
            ("_maps/a.dmm", "multiple_tables", "/obj/structure/table"): 2,
            ("_maps/a.dmm", baseline.PARSE_LINT, ""): 1,
        }

        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "baseline.json"
            baseline.save(path, known)
            self.assertEqual(baseline.load(path), known)
            self.assertTrue(path.read_bytes().endswith(b"}\n"))
            self.assertNotIn(b"\r\n", path.read_bytes())

        self.assertEqual(baseline.load(pathlib.Path("does/not/exist.json")), {})

class TestMapCounts(unittest.TestCase):
    def count(self, text):
        return baseline.count_errors(lint_map(text))

    def test_moving_a_violation_keeps_the_key_and_count(self):
        original = make_map({"a": FLOOR, "b": BOTTLE + FLOOR}, [["a", "b"], ["a", "a"]])
        # Same content under another pop key, placed on another turf
        moved = make_map({"a": FLOOR, "q": BOTTLE + FLOOR}, [["a", "a"], ["a", "q"]])

        expected = Counter({("_maps/test.dmm", "reagents_varedits", "/obj/item/reagent_containers/glass/bottle"): 1})
        self.assertEqual(self.count(original), expected)
        self.assertEqual(self.count(moved), expected)

    def test_copying_a_violating_pop_raises_the_count(self):
        copied = make_map({"a": FLOOR, "b": BOTTLE + FLOOR}, [["a", "b"], ["b", "a"]])
        self.assertEqual(sum(self.count(copied).values()), 2)

    def test_list_reagents_is_allowed(self):
        allowed = make_map({"a": "/obj/item/reagent_containers/glass/bottle{\n\tlist_reagents = list(/datum/reagent/water = 30)\n\t},\n" + FLOOR}, [["a"]])
        self.assertEqual(self.count(allowed), Counter())

    def test_newlist_var_edits_parse(self):
        newlist = make_map({"a": "/obj/structure/closet{\n\tcontents = newlist(/obj/item/toy)\n\t},\n" + FLOOR}, [["a"]])
        self.assertEqual(self.count(newlist), Counter())

if __name__ == "__main__":
    unittest.main()

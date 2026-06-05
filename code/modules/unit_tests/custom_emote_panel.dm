/// Verifies that ASCII control characters can no longer corrupt custom emote
/// panel names. Such characters survive html_encode() but cannot round-trip
/// through the DM<->TGUI json/topic bridge, which used to leave a button that
/// could not be executed, renamed, or deleted.
/// See modular_bluemoon/code/modules/tgui_panel/tgui_emote_panel.dm.
/datum/unit_test/custom_emote_panel_control_chars

/datum/unit_test/custom_emote_panel_control_chars/Run()
	// 0x0E and 0x1F are control bytes from the reported breaking range; they must
	// be removed while the surrounding text is preserved.
	var/dirty = "test[ascii2text(14)][ascii2text(31)]name"
	TEST_ASSERT_EQUAL(strip_control_chars(dirty), "testname", "control characters were not stripped from a name")

	// Multi-byte Unicode (Cyrillic) must survive untouched.
	TEST_ASSERT_EQUAL(strip_control_chars("вздох"), "вздох", "Unicode text was corrupted by strip_control_chars")

	// Tab/newline/carriage-return have proper JSON escapes and round-trip fine, so
	// they are deliberately kept (e.g. a multi-line *me message must stay intact).
	var/whitespace = "a[ascii2text(9)]b[ascii2text(10)]c[ascii2text(13)]d"
	TEST_ASSERT_EQUAL(strip_control_chars(whitespace), whitespace, "tab/newline/carriage-return must be preserved")

	// A string made entirely of control characters cleans to empty.
	TEST_ASSERT_EQUAL(strip_control_chars("[ascii2text(14)][ascii2text(20)]"), "", "an all-control string should clean to empty")

	// DEL (0x7F) is also handled by the ascii == 127 branch and must be stripped.
	TEST_ASSERT_EQUAL(strip_control_chars(ascii2text(127)), "", "DEL (0x7F) should be stripped")

	// Recovery: a panel whose key carries a control character is rebuilt with a
	// clean, matchable key, and the stored message is cleaned too.
	var/broken_name = "wave[ascii2text(15)]"
	var/list/panel = list()
	panel[broken_name] = list("type" = TGUI_PANEL_EMOTE_TYPE_ME, "message" = "machine[ascii2text(16)] hums")
	var/list/repaired = sanitize_custom_emote_panel(panel)
	TEST_ASSERT(isnull(repaired[broken_name]), "the broken control-character key should not survive sanitization")
	TEST_ASSERT_NOTNULL(repaired["wave"], "the cleaned emote name should be present and matchable")
	var/list/repaired_emote = repaired["wave"]
	TEST_ASSERT_EQUAL(repaired_emote["message"], "machine hums", "the stored message should also be stripped of control characters")

	// An emote whose entire name is control characters is unrecoverable and dropped.
	var/list/garbage_panel = list()
	garbage_panel["[ascii2text(14)]"] = list("type" = TGUI_PANEL_EMOTE_TYPE_DEFAULT, "key" = "sigh")
	TEST_ASSERT_EQUAL(length(sanitize_custom_emote_panel(garbage_panel)), 0, "an all-control-character emote name should be dropped")

	// Collision: two names that clean to the same key keep only the first.
	var/list/collision_panel = list()
	collision_panel["hi[ascii2text(14)]"] = list("type" = TGUI_PANEL_EMOTE_TYPE_DEFAULT, "key" = "first")
	collision_panel["hi[ascii2text(15)]"] = list("type" = TGUI_PANEL_EMOTE_TYPE_DEFAULT, "key" = "second")
	var/list/deduped = sanitize_custom_emote_panel(collision_panel)
	TEST_ASSERT_EQUAL(length(deduped), 1, "colliding cleaned names should be deduplicated")
	var/list/kept = deduped["hi"]
	TEST_ASSERT_EQUAL(kept["key"], "first", "the first cleaned emote should win a name collision")

	// sanitize_assoc_keys (the generic helper behind colormate/jukebox recovery) cleans
	// text keys, drops empty/colliding ones, and leaves non-text keys (typepaths) alone.
	var/list/assoc = list()
	assoc["good[ascii2text(14)]"] = "a"
	assoc["[ascii2text(31)]"] = "b" // all-control -> dropped
	assoc[/obj/item] = "typepath-key-stays"
	var/list/assoc_clean = sanitize_assoc_keys(assoc)
	TEST_ASSERT_EQUAL(assoc_clean["good"], "a", "sanitize_assoc_keys should clean a control-character text key")
	TEST_ASSERT(isnull(assoc_clean["good[ascii2text(14)]"]), "the original dirty key must not survive")
	TEST_ASSERT_EQUAL(assoc_clean[/obj/item], "typepath-key-stays", "non-text keys must pass through untouched")
	TEST_ASSERT_EQUAL(length(assoc_clean), 2, "the all-control-character key should have been dropped")

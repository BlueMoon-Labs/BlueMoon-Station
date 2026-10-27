/// Значки BYOND-членства для OOC/AOOC лежат в чат-листе и размером со строку чата.
/datum/unit_test/chat_member_badges

/datum/unit_test/chat_member_badges/Run()
	var/datum/asset/spritesheet_batched/chat/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
	TEST_ASSERT(sheet.fully_generated, "чат-лист не собран")
	for(var/sprite_name in list("member-ooc", "member-aooc"))
		TEST_ASSERT_EQUAL(sheet.icon_tag(sprite_name), "<span class=\"chat16x16 [sprite_name]\"></span>", "значок [sprite_name] не в листе или не 16x16")

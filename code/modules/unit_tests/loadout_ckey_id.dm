/// Reversible IDs preserve spelling and normalize only during access checks.

/datum/unit_test/loadout_ckey_id
	var/saved_secret

/datum/unit_test/loadout_ckey_id/Run()
	saved_secret = CONFIG_GET(string/loadout_ckey_secret)
	CONFIG_SET(string/loadout_ckey_secret, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	var/id = gear_ckey_id("AA-BB-ab...")
	TEST_ASSERT(id && findtextEx(id, "enc1:", 1, 6), "IDs must use reversible enc1 format")
	TEST_ASSERT_EQUAL(gear_ckey_from_id(id), "AA-BB-ab...", "IDs must preserve original spelling")
	TEST_ASSERT_NOTEQUAL(gear_ckey_id("AABBAB"), id, "Different exact keys must receive different randomized IDs")
	TEST_ASSERT_NULL(gear_ckey_id(null), "Missing keys must not receive an ID")
	TEST_ASSERT_NULL(gear_ckey_id("..."), "Keys that normalize to an empty string must not receive an ID")

/datum/unit_test/loadout_ckey_id/Destroy()
	if(!isnull(saved_secret))
		CONFIG_SET(string/loadout_ckey_secret, saved_secret)
	return ..()

/// Mixed whitelists must preserve legacy access and still require donor group membership.
/datum/unit_test/loadout_ckey_whitelist
	var/list/original_donator_groups
	var/saved_secret

/datum/unit_test/loadout_ckey_whitelist/Run()
	saved_secret = CONFIG_GET(string/loadout_ckey_secret)
	CONFIG_SET(string/loadout_ckey_secret, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	var/datum/gear/gear = allocate(/datum/gear)
	TEST_ASSERT(gear.donator_ckey_check("stranger"), "A null whitelist must remain unrestricted")
	gear.ckeywhitelist = list()
	TEST_ASSERT(gear.donator_ckey_check("stranger"), "An empty whitelist must remain unrestricted")
	gear.ckeywhitelist = list("aabbab")
	TEST_ASSERT(gear.donator_ckey_check("AA-BB-ab..."), "Legacy whitelist checks must normalize display keys")
	TEST_ASSERT(!gear.donator_ckey_check("stranger"), "Legacy whitelists must reject other accounts")
	gear.ckeywhitelist = list("AA-BB-ab...")
	TEST_ASSERT(gear.donator_ckey_check("AA-BB-ab..."), "Display-key entries must authorize their account")
	TEST_ASSERT(gear.donator_ckey_check("aabbab"), "Display-key entries must also accept normalized input")
	TEST_ASSERT(gear.donator_ckey_check("Aa.Bb-Ab"), "Plaintext spellings of the same account must compare after normalization")
	TEST_ASSERT(!gear.donator_ckey_check("stranger"), "Display-key entries must reject other accounts")
	var/id = gear_ckey_id("AA-BB-ab...")
	gear.ckeywhitelist = list(id, "legacyaccount")
	TEST_ASSERT(gear.donator_ckey_check("Legacy-Account"), "Mixed whitelists must accept legacy entries")
	TEST_ASSERT(gear.donator_ckey_check("aabbab"), "Mixed whitelists must accept encrypted entries")
	TEST_ASSERT(!gear.donator_ckey_check("stranger"), "Mixed whitelists must reject other accounts")
	TEST_ASSERT(!gear.donator_ckey_check(null), "Missing account keys must not match a restricted item")
	TEST_ASSERT(!gear.donator_ckey_check("..."), "Empty normalized keys must not match a restricted item")
	gear.ckeywhitelist = list("Display-Account", "normalizedaccount", id)
	TEST_ASSERT(gear.donator_ckey_check("displayaccount"), "Mixed plaintext and encrypted entries must accept display names")
	TEST_ASSERT(gear.donator_ckey_check("Normalized-Account"), "Mixed plaintext and encrypted entries must accept ckeys")
	TEST_ASSERT(gear.donator_ckey_check("aabbab"), "Mixed plaintext and encrypted entries must accept encrypted IDs")
	TEST_ASSERT(!gear.donator_ckey_check("stranger"), "Mixed entries must reject other accounts")

	original_donator_groups = GLOB.donators_by_group
	GLOB.donators_by_group = list("loadout_test_group" = list("aabbab", "stranger"))
	gear.donator_group_id = "loadout_test_group"
	for(var/entry in list("AA-BB-ab...", "aabbab", id))
		gear.ckeywhitelist = list(entry, "legacyaccount")
		TEST_ASSERT(gear.donator_ckey_check("AA-BB-ab..."), "Group membership and any of the four whitelist formats must allow access")
		TEST_ASSERT(!gear.donator_ckey_check("legacyaccount"), "Whitelist membership must not bypass the donor group")
		TEST_ASSERT(!gear.donator_ckey_check("stranger"), "Group membership must not bypass the whitelist")

/datum/unit_test/loadout_ckey_whitelist/Destroy()
	if(!isnull(saved_secret))
		CONFIG_SET(string/loadout_ckey_secret, saved_secret)
	if(!isnull(original_donator_groups))
		GLOB.donators_by_group = original_donator_groups
		original_donator_groups = null
	return ..()

/// Real helper integration, including cache invalidation, legacy coexistence and fail-closed behavior.
/datum/unit_test/loadout_ckey_encryption
	var/saved_secret
	var/list/saved_donator_groups

/datum/unit_test/loadout_ckey_encryption/Run()
	saved_secret = CONFIG_GET(string/loadout_ckey_secret)
	CONFIG_SET(string/loadout_ckey_secret, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	var/fixture = "enc1:AAECAwQFBgcICQoLBkP7WYfIo3mjb7lYYwet3PW22BiBfjL-G3kJ"
	var/other_fixture = "enc1:AAECAwQFBgcICQoLBkP7WYfIo3mjb7lYYwet3PW22BiBfjL-G3kA"
	var/list/diagnostics = list("error" = "previous_error")
	TEST_ASSERT_EQUAL(gear_crypto("decrypt", fixture, FALSE, diagnostics), "AA-BB-ab...", "Uncached diagnostic requests must preserve existing IDs")
	TEST_ASSERT_NULL(diagnostics["error"], "Successful requests must clear previous diagnostics")
	TEST_ASSERT(diagnostics["node_version"], "Diagnostics must identify the running Node version")
	TEST_ASSERT_NULL(gear_crypto("decrypt", other_fixture, FALSE, diagnostics), "Diagnostics must not bypass authentication")
	TEST_ASSERT_EQUAL(diagnostics["error"], "authentication_failed", "Authentication errors must be distinguishable from process failures")
	TEST_ASSERT_NOTNULL(diagnostics["error_detail"], "DM diagnostic flags must request helper error details")
	gear_crypto("decrypt", list(fixture, other_fixture))
	TEST_ASSERT_EQUAL(gear_ckey_from_id(fixture), "AA-BB-ab...", "Batch decryption must accept an independent AES-GCM fixture")
	TEST_ASSERT_NULL(gear_ckey_from_id(other_fixture), "An altered authentication tag must fail")
	var/id = gear_ckey_id("AA-BB-ab...")
	TEST_ASSERT(id && findtextEx(id, "enc1:", 1, 6), "SHOW must issue a reversible ID")
	TEST_ASSERT_EQUAL(gear_ckey_from_id(id), "AA-BB-ab...", "Decryption must preserve original spelling")
	TEST_ASSERT_EQUAL(gear_ckey_id("AA-BB-ab..."), id, "Repeated SHOW requests must use the cache")
	TEST_ASSERT_NULL(gear_ckey_id(null), "An empty account must not be encrypted")
	var/datum/gear/gear = allocate(/datum/gear)
	gear.ckeywhitelist = list(id)
	TEST_ASSERT(gear.donator_ckey_check("aabbab"), "Encrypted entries must match normalized identity")
	TEST_ASSERT(gear.donator_ckey_check("Aa.Bb-Ab"), "Spelling changes must not invalidate an encrypted identity")
	TEST_ASSERT(!gear.donator_ckey_check("stranger"), "Encrypted entries must reject strangers")
	TEST_ASSERT(!gear.donator_ckey_check(id), "An encrypted ID is not a plaintext account name")
	saved_donator_groups = GLOB.donators_by_group
	GLOB.donators_by_group = list("crypto_test_group" = list("stranger"))
	gear.donator_group_id = "crypto_test_group"
	TEST_ASSERT(!gear.donator_ckey_check("aabbab"), "An encrypted whitelist entry must not bypass a donor group")
	TEST_ASSERT(!gear.donator_ckey_check("stranger"), "A donor group must not bypass an encrypted whitelist")
	gear.donator_group_id = null
	gear.ckeywhitelist = list("enc2:invalid", other_fixture, id, "legacyaccount")
	TEST_ASSERT(gear.donator_ckey_check("Legacy-Account"), "Plain entries must coexist with encrypted IDs")
	TEST_ASSERT(gear.donator_ckey_check("aabbab"), "Encrypted entries must coexist with old formats")
	TEST_ASSERT(!gear.donator_ckey_check("enc2invalid"), "Unknown encoded formats must not become plaintext entries")
	CONFIG_SET(string/loadout_ckey_secret, "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
	TEST_ASSERT_NULL(gear_ckey_from_id(id), "Changing the secret must invalidate cached decrypted IDs")
	var/new_id = gear_ckey_id("AA-BB-ab...")
	TEST_ASSERT(new_id && new_id != id, "Changing the secret must invalidate cached issued IDs")
	TEST_ASSERT_EQUAL(gear_ckey_from_id(new_id), "AA-BB-ab...", "The new secret must work for newly issued IDs")
	TEST_ASSERT(!gear.donator_ckey_check("aabbab"), "Wrong keys must deny encrypted whitelist access")
	CONFIG_SET(string/loadout_ckey_secret, "")
	TEST_ASSERT_NULL(gear_crypto("encrypt", "PRIVATE_TEXT", FALSE, diagnostics), "Missing secrets must fail diagnostic requests")
	TEST_ASSERT_EQUAL(diagnostics["error"], "secret_missing", "Missing config must be diagnosable in-round")
	TEST_ASSERT_EQUAL(length(diagnostics), 1, "Early failures must clear stale process diagnostics")
	TEST_ASSERT_NULL(gear_ckey_id("AA-BB-ab..."), "Missing secret must not silently fall back to SHA or plaintext")
	TEST_ASSERT_NULL(gear_ckey_from_id(new_id), "Missing secret must not use cached plaintext")
	TEST_ASSERT(!gear.donator_ckey_check("aabbab"), "Missing secret must deny encrypted whitelist access")
	TEST_ASSERT(gear.donator_ckey_check("legacyaccount"), "Missing secret must not break plain whitelists")

/datum/unit_test/loadout_ckey_encryption/Destroy()
	if(!isnull(saved_secret))
		CONFIG_SET(string/loadout_ckey_secret, saved_secret)
	if(!isnull(saved_donator_groups))
		GLOB.donators_by_group = saved_donator_groups
	return ..()

/// Sprite selection must use the same identity and authentication rules as the loadout.
/datum/unit_test/sprite_accessory_ckey_whitelist
	var/saved_secret

/datum/unit_test/sprite_accessory_ckey_whitelist/Run()
	saved_secret = CONFIG_GET(string/loadout_ckey_secret)
	CONFIG_SET(string/loadout_ckey_secret, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	var/datum/sprite_accessory/accessory = allocate(/datum/sprite_accessory)
	TEST_ASSERT(accessory.is_allowed_for(null), "A null accessory whitelist must be unrestricted")
	accessory.ckeys_allowed = list()
	TEST_ASSERT(accessory.is_allowed_for("stranger"), "An empty accessory whitelist must be unrestricted")
	var/original_id = "enc1:AAECAwQFBgcICQoLBkP7WYfIo3mjb7lYYwet3PW22BiBfjL-G3kJ"
	var/normalized_id = gear_ckey_id("aabbab")
	TEST_ASSERT(normalized_id, "The normalized-name encryption fixture must be available")
	for(var/entry in list("AA-BB-ab...", "aabbab", original_id, normalized_id))
		accessory.ckeys_allowed = list(entry)
		for(var/account in list("AA-BB-ab...", "aabbab", "Aa.Bb-Ab"))
			TEST_ASSERT(accessory.is_allowed_for(account), "All four whitelist formats must match the same accessory owner")
		TEST_ASSERT(!accessory.is_allowed_for("stranger"), "A restricted accessory must reject other accounts")
		TEST_ASSERT(!accessory.is_allowed_for(null), "A restricted accessory must reject a missing account")
		TEST_ASSERT(!accessory.is_allowed_for("..."), "A restricted accessory must reject an empty normalized account")
		TEST_ASSERT(!accessory.is_allowed_for(original_id), "A ciphertext is not a player account")
	var/tampered_id = "enc1:AAECAwQFBgcICQoLBkP7WYfIo3mjb7lYYwet3PW22BiBfjL-G3kA"
	accessory.ckeys_allowed = list(null, 123, "...", "enc2:invalid", tampered_id, original_id, "Legacy-Account")
	TEST_ASSERT(accessory.is_allowed_for("aabbab"), "Valid IDs must work beside malformed entries")
	TEST_ASSERT(accessory.is_allowed_for("legacyaccount"), "Plain entries must work beside encrypted entries")
	TEST_ASSERT(!accessory.is_allowed_for("enc2invalid"), "An unknown encrypted version must not become a plaintext key")
	TEST_ASSERT(!accessory.is_allowed_for("stranger"), "Mixed accessory whitelists must reject strangers")
	CONFIG_SET(string/loadout_ckey_secret, "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")
	TEST_ASSERT(!accessory.is_allowed_for("aabbab"), "Changing the secret must invalidate cached accessory access")
	TEST_ASSERT(accessory.is_allowed_for("Legacy-Account"), "Changing the secret must not break plaintext accessory access")
	CONFIG_SET(string/loadout_ckey_secret, "")
	TEST_ASSERT(!accessory.is_allowed_for("aabbab"), "A missing secret must deny encrypted accessory access")
	TEST_ASSERT(accessory.is_allowed_for("legacyaccount"), "A missing secret must not break plaintext accessory access")

/datum/unit_test/sprite_accessory_ckey_whitelist/Destroy()
	if(!isnull(saved_secret))
		CONFIG_SET(string/loadout_ckey_secret, saved_secret)
	return ..()

/// Other private content shares the four whitelist formats but keeps its own empty-list and group rules.
/datum/unit_test/additional_ckey_whitelists
	var/saved_secret
	var/list/saved_donator_groups
	var/list/saved_hotel_templates

/datum/unit_test/additional_ckey_whitelists/Run()
	saved_secret = CONFIG_GET(string/loadout_ckey_secret)
	CONFIG_SET(string/loadout_ckey_secret, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	var/datum/bark/bark = allocate(/datum/bark)
	var/datum/ai_donator_screen/screen = allocate(/datum/ai_donator_screen)
	var/datum/borg_donator_skin/skin = allocate(/datum/borg_donator_skin)
	var/datum/map_template/hilbertshotel/room = new()
	allocated += room
	TEST_ASSERT(bark.is_allowed_for("stranger"), "A null bark whitelist must remain public")
	bark.ckeys_allowed = list()
	TEST_ASSERT(!bark.is_allowed_for("stranger"), "An explicit empty bark whitelist must still deny everyone")
	TEST_ASSERT(!screen.is_allowed_for("stranger"), "An empty private AI screen whitelist must deny everyone")
	TEST_ASSERT(!skin.is_allowed_for("stranger"), "A borg skin without a whitelist or donor group must deny everyone")
	TEST_ASSERT(!skin.can_use(null), "Borg skin selection must require a client")
	TEST_ASSERT(room.is_allowed_for("stranger"), "An empty hotel whitelist must remain public")
	var/original_id = "enc1:AAECAwQFBgcICQoLBkP7WYfIo3mjb7lYYwet3PW22BiBfjL-G3kJ"
	var/normalized_id = gear_ckey_id("aabbab")
	TEST_ASSERT(normalized_id, "The normalized-name encryption fixture must be available")
	for(var/entry in list("AA-BB-ab...", "aabbab", original_id, normalized_id))
		bark.ckeys_allowed = list(entry)
		screen.ckey_whitelist = list(entry)
		skin.ckey_whitelist = list(entry)
		room.ckeywhitelist = list(entry)
		for(var/account in list("AA-BB-ab...", "aabbab", "Aa.Bb-Ab"))
			TEST_ASSERT(bark.is_allowed_for(account), "Barks must accept all four whitelist formats")
			TEST_ASSERT(screen.is_allowed_for(account), "AI screens must accept all four whitelist formats")
			TEST_ASSERT(skin.is_allowed_for(account), "Borg skins must accept all four whitelist formats")
			TEST_ASSERT(room.is_allowed_for(account), "Hotel templates must accept all four whitelist formats")
		TEST_ASSERT(!bark.is_allowed_for("stranger"), "Private barks must reject strangers")
		TEST_ASSERT(!screen.is_allowed_for("stranger"), "Private AI screens must reject strangers")
		TEST_ASSERT(!skin.is_allowed_for("stranger"), "Private borg skins must reject strangers")
		TEST_ASSERT(!room.is_allowed_for("stranger"), "Private hotel templates must reject strangers")
		TEST_ASSERT(!skin.is_allowed_for(null), "Borg skin access must reject missing account names")
	var/list/mixed_whitelist = list("enc2:invalid", "enc1:bad", original_id, "Legacy-Account")
	bark.ckeys_allowed = mixed_whitelist
	screen.ckey_whitelist = mixed_whitelist
	skin.ckey_whitelist = mixed_whitelist
	room.ckeywhitelist = mixed_whitelist
	for(var/account in list("aabbab", "legacyaccount"))
		TEST_ASSERT(bark.is_allowed_for(account), "Mixed bark whitelists must accept their owners")
		TEST_ASSERT(screen.is_allowed_for(account), "Mixed screen whitelists must accept their owners")
		TEST_ASSERT(skin.is_allowed_for(account), "Mixed skin whitelists must accept their owners")
		TEST_ASSERT(room.is_allowed_for(account), "Mixed hotel whitelists must accept their owners")
	TEST_ASSERT(!screen.is_allowed_for("enc2invalid"), "Unknown encrypted versions must not become plaintext keys")
	saved_donator_groups = GLOB.donators_by_group
	GLOB.donators_by_group = list("skin_whitelist_test" = list("groupmember"))
	skin.donator_group = "skin_whitelist_test"
	TEST_ASSERT(skin.is_allowed_for("Group-Member"), "A donor group must independently grant borg skin access")
	TEST_ASSERT(skin.is_allowed_for("AA-BB-ab..."), "A borg whitelist must independently grant access beside a donor group")
	TEST_ASSERT(!skin.is_allowed_for("stranger"), "A stranger must not pass either borg access route")
	skin.ckey_whitelist = list()
	TEST_ASSERT(skin.is_allowed_for("Group-Member"), "An empty borg whitelist must not disable its donor group")
	CONFIG_SET(string/loadout_ckey_secret, "")
	TEST_ASSERT(!bark.is_allowed_for("aabbab"), "A missing secret must deny encrypted bark access")
	TEST_ASSERT(!screen.is_allowed_for("aabbab"), "A missing secret must deny encrypted AI screen access")
	TEST_ASSERT(!room.is_allowed_for("aabbab"), "A missing secret must deny encrypted hotel access")
	TEST_ASSERT(bark.is_allowed_for("legacyaccount"), "Plaintext barks must work without a crypto secret")
	TEST_ASSERT(screen.is_allowed_for("legacyaccount"), "Plaintext screens must work without a crypto secret")
	TEST_ASSERT(room.is_allowed_for("legacyaccount"), "Plaintext hotel templates must work without a crypto secret")

	// UI data carries the server's decision, never the whitelist itself.
	saved_hotel_templates = SShilbertshotel.hotel_map_list
	var/datum/map_template/hilbertshotel/public_room = new()
	allocated += public_room
	SShilbertshotel.hotel_map_list = list("private" = room, "public" = public_room)
	var/obj/item/hilbertshotel/hotel = allocate(/obj/item/hilbertshotel)
	var/mob/user = allocate(/mob)
	var/list/ui_data = hotel.ui_static_data(user)
	var/list/room_choices = ui_data["hotel_map_list"]
	TEST_ASSERT_EQUAL(length(room_choices), 2, "Both hotel templates must be described to the UI")
	var/list/private_choice = room_choices[1]
	var/list/public_choice = room_choices[2]
	TEST_ASSERT(!private_choice["available"], "An anonymous user must not select a private hotel template")
	TEST_ASSERT(public_choice["available"], "An anonymous user may select a public hotel template")
	TEST_ASSERT(!("ckeywhitelist" in private_choice), "Private hotel whitelists must not be sent to clients")
	TEST_ASSERT(!("ckeywhitelist" in public_choice), "Public hotel whitelists must not be sent to clients")

/datum/unit_test/additional_ckey_whitelists/Destroy()
	if(!isnull(saved_secret))
		CONFIG_SET(string/loadout_ckey_secret, saved_secret)
	if(!isnull(saved_donator_groups))
		GLOB.donators_by_group = saved_donator_groups
	if(!isnull(saved_hotel_templates))
		SShilbertshotel.hotel_map_list = saved_hotel_templates
	return ..()

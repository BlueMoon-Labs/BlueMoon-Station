/// Reversible IDs preserve spelling and normalize only during access checks.
/datum/unit_test/loadout_ckey_id/Run()
	var/saved_secret = CONFIG_GET(string/loadout_ckey_secret)
	CONFIG_SET(string/loadout_ckey_secret, "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
	var/id = gear_ckey_id("AA-BB-ab...")
	TEST_ASSERT(id && findtextEx(id, "enc1:", 1, 6), "IDs must use reversible enc1 format")
	TEST_ASSERT_EQUAL(gear_ckey_from_id(id), "AA-BB-ab...", "IDs must preserve original spelling")
	TEST_ASSERT_NOTEQUAL(gear_ckey_id("AABBAB"), id, "Different exact keys must receive different randomized IDs")
	TEST_ASSERT_NULL(gear_ckey_id(null), "Missing keys must not receive an ID")
	TEST_ASSERT_NULL(gear_ckey_id("..."), "Keys that normalize to an empty string must not receive an ID")
	CONFIG_SET(string/loadout_ckey_secret, saved_secret)

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
	gear_crypto("decrypt_many", list(fixture, other_fixture))
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

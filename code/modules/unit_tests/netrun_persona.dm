/// Presentation is validated independently of node permissions and program inventory.
/datum/unit_test/netrun_persona_validation/Run()
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	var/datum/netrun_console/console = entity.console
	console.operator = entity
	var/datum/netrun_persona/profile = entity.get_persona()
	TEST_ASSERT_EQUAL(profile.avatar, "cipher", "A new process must have a curated default avatar")
	TEST_ASSERT(console.update_persona(list("avatar" = "ghost", "accent" = "violet", "tagline" = "Silent signal", "name" = "Echo 7"), entity), "A valid presentation patch must be applied")
	TEST_ASSERT_EQUAL(profile.avatar, "ghost", "The selected avatar must be retained")
	TEST_ASSERT_EQUAL(profile.accent, "violet", "The selected accent must be retained")
	TEST_ASSERT_EQUAL(profile.tagline, "Silent signal", "The personal tagline must be retained")
	TEST_ASSERT_EQUAL(entity.real_name, "Echo 7", "Editing the profile name must update the real process and messenger identity")
	TEST_ASSERT(!console.update_persona(list("avatar" = "https://example.invalid/avatar.png", "accent" = "mint"), entity), "Remote images cannot become avatar assets")
	TEST_ASSERT_EQUAL(profile.accent, "violet", "An invalid avatar must reject the entire patch before changing its valid accent")
	TEST_ASSERT(!console.update_persona(list("accent" = "#ff0000"), entity), "Arbitrary CSS values must not enter the presentation contract")
	TEST_ASSERT(!console.update_persona(list("tagline" = 123), entity), "Taglines must be text")
	var/too_long = ""
	for(var/i in 1 to 81)
		too_long += "я"
	TEST_ASSERT(!console.update_persona(list("tagline" = too_long), entity), "The server must enforce the Unicode character limit")
	TEST_ASSERT(console.update_persona(list("tagline" = "<b>Echo</b>\nvalue"), entity), "Plain-text content may be extracted from a submitted tagline")
	TEST_ASSERT_EQUAL(profile.tagline, "Echo value", "The profile must not retain HTML or multiline layout controls")
	var/list/contact = entity.get_netrun_combatant().ui_entry()
	var/list/contact_persona = contact["persona"]
	TEST_ASSERT_EQUAL(contact_persona["avatar"], "ghost", "Other process cards must receive the same chosen avatar")
	TEST_ASSERT_NULL(contact_persona["options"], "Public contact cards must not repeat the full editor option catalog")

/datum/unit_test/netrun_persona_owner_admission/Run()
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	var/mob/camera/netrun_entity/other = allocate(/mob/camera/netrun_entity)
	entity.console.operator = entity
	TEST_ASSERT(!entity.console.update_persona(list("avatar" = "eye"), other), "Another process must not edit this identity")
	TEST_ASSERT(!entity.console.set_ui_theme("amber", other), "Another process must not change this client's theme")
	entity.console.operator = other
	TEST_ASSERT(!entity.console.update_persona(list("avatar" = "eye"), other), "Replacing the last operator must not make a foreign entity its owner")
	TEST_ASSERT(!entity.console.set_ui_theme("amber", other), "The actual entity host remains authoritative for cosmetic actions")
	TEST_ASSERT_EQUAL(entity.get_persona().avatar, "cipher", "Rejected customization must preserve the original avatar")

/// Themes follow a real character across devices; mindless clients keep isolated fallbacks.
/datum/unit_test/netrun_theme_character_scope/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	var/obj/item/first_host = allocate(/obj/item)
	var/obj/item/second_host = allocate(/obj/item)
	var/datum/netrun_console/first = allocate(/datum/netrun_console, first_host)
	var/datum/netrun_console/second = allocate(/datum/netrun_console, second_host)
	first.operator = user
	second.operator = user
	TEST_ASSERT(first.set_ui_theme("phosphor", user), "A valid theme must be accepted for the current operator")
	TEST_ASSERT_EQUAL(second.theme_id(user), "phosphor", "The same character must retain its theme when opening a different physical client")
	TEST_ASSERT(!first.set_ui_theme("url(javascript:bad)", user), "A theme is a known identifier, never arbitrary style text")
	TEST_ASSERT_EQUAL(first.theme_id(user), "phosphor", "Rejected themes must not change a stored preference")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	other.mind_initialize()
	TEST_ASSERT_EQUAL(second.theme_id(other), "ion", "A different character must not inherit another user's device fallback")
	var/mob/camera/netrun_entity/mindless = allocate(/mob/camera/netrun_entity)
	mindless.console.operator = mindless
	TEST_ASSERT(mindless.console.set_ui_theme("synthwave", mindless), "A resident without a mind may still style its own client")
	TEST_ASSERT_EQUAL(mindless.console.theme_id(), "synthwave", "Mindless residents retain their own profile theme")
	TEST_ASSERT_EQUAL(first.theme_id(user), "phosphor", "An unrelated process must not change the character's theme")

/// The same profile survives the real implant's mind transfer and a second dive.
/datum/unit_test/netrun_persona_dive_roundtrip/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The test must enter through the real neural implant")
	var/mob/camera/netrun_entity/first = scene.implant.console.dive_ref?.resolve()
	first.console.operator = first
	TEST_ASSERT(first.console.update_persona(list("avatar" = "moth", "accent" = "rose", "tagline" = "Between the relays", "name" = "Lumen"), first), "The diving character must be able to create a persona")
	TEST_ASSERT(first.console.set_ui_theme("amber", first), "The diving character must be able to choose its interface theme")
	var/datum/netrun_persona/profile = first.get_persona()
	first.return_to_body()
	TEST_ASSERT(QDELETED(first), "Returning must end the temporary resident process")
	TEST_ASSERT(!QDELETED(profile), "The returning character's mind must retain its presentation")
	TEST_ASSERT_EQUAL(scene.user.mind.netrun_persona, profile, "The profile must belong to the same mind rather than the temporary entity")
	TEST_ASSERT_EQUAL(scene.implant.console.theme_id(scene.user), "amber", "Returning to the implant UI must retain the chosen theme")
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "A later dive must create another real resident")
	var/mob/camera/netrun_entity/second = scene.implant.console.dive_ref?.resolve()
	TEST_ASSERT_EQUAL(second.get_persona(), profile, "The second dive must reuse the existing identity profile")
	TEST_ASSERT_EQUAL(second.real_name, "Lumen", "The chosen alias must survive a second dive")
	TEST_ASSERT_EQUAL(second.get_persona().avatar, "moth", "The chosen avatar must survive a second dive")
	TEST_ASSERT_EQUAL(second.console.theme_id(), "amber", "The resident UI must keep the same theme")

/// An abandoned process cannot mutate the profile that left with its former player.
/datum/unit_test/netrun_persona_identity_lifecycle/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	var/datum/mind/identity = body.mind
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	var/datum/netrun_persona/temporary = entity.get_persona()
	identity.transfer_to(entity)
	var/datum/netrun_persona/persistent = entity.get_persona()
	TEST_ASSERT_EQUAL(persistent, temporary, "The first mind assignment should adopt the resident's existing profile")
	entity.console.operator = entity
	TEST_ASSERT(entity.console.update_persona(list("avatar" = "eye"), entity), "The controlling identity must be able to style its process")
	identity.transfer_to(body)
	var/datum/netrun_persona/abandoned = entity.get_persona()
	TEST_ASSERT(abandoned != persistent, "A process left behind by a mind must have an independent appearance snapshot")
	TEST_ASSERT_EQUAL(abandoned.avatar, "eye", "The abandoned process may retain its last visible appearance")
	abandoned.avatar = "orb"
	TEST_ASSERT_EQUAL(persistent.avatar, "eye", "The abandoned process must not retain write access to the departed identity")
	qdel(entity)
	TEST_ASSERT(QDELETED(abandoned), "Deleting a mindless process must delete its owned profile")
	TEST_ASSERT(!QDELETED(persistent), "Deleting the abandoned process must not delete a profile owned by its former mind")
	qdel(identity)
	TEST_ASSERT(QDELETED(persistent), "Deleting the identity must release its persistent presentation profile")

/// Native consecutive transfers have no UI read between the old mind leaving and the new one entering.
/datum/unit_test/netrun_persona_consecutive_minds/Run()
	var/mob/living/carbon/human/first_body = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second_body = allocate(/mob/living/carbon/human)
	first_body.mind_initialize()
	second_body.mind_initialize()
	var/datum/mind/first_mind = first_body.mind
	var/datum/mind/second_mind = second_body.mind
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	first_mind.transfer_to(entity)
	entity.console.operator = entity
	TEST_ASSERT(entity.console.update_persona(list("avatar" = "ghost", "accent" = "rose", "name" = "First Echo"), entity), "The first mind must create its own profile")
	var/datum/netrun_persona/first_profile = first_mind.netrun_persona
	first_mind.transfer_to(first_body)
	// Intentionally do not call entity.get_persona() here: only native transfer signals may intervene.
	second_mind.transfer_to(entity)
	var/datum/netrun_persona/second_profile = second_mind.netrun_persona
	TEST_ASSERT_NOTNULL(second_profile, "The next mind must receive a profile from the native mind-change signal")
	TEST_ASSERT(second_profile != first_profile, "Consecutive occupants must not share a mutable presentation profile")
	TEST_ASSERT_EQUAL(first_mind.netrun_persona, first_profile, "The departed mind must keep its original profile reference")
	TEST_ASSERT_EQUAL(first_profile.identity_ref?.resolve(), first_mind, "The departed profile must remain owned by its original mind")
	TEST_ASSERT_EQUAL(second_profile.identity_ref?.resolve(), second_mind, "The arriving mind must own only its independent profile")
	TEST_ASSERT(entity.console.update_persona(list("avatar" = "orb", "accent" = "mint", "name" = "Second Echo"), entity), "The new occupant must be able to edit its own appearance")
	TEST_ASSERT_EQUAL(first_profile.avatar, "ghost", "The arriving mind's edits must not mutate the departed player's avatar")
	TEST_ASSERT_EQUAL(first_profile.alias, "First Echo", "The arriving mind's edits must not rename the departed identity")
	qdel(second_mind)
	TEST_ASSERT(QDELETED(second_profile), "Deleting the second mind must release its own profile")
	TEST_ASSERT(!QDELETED(first_profile), "Deleting the second identity must preserve the first identity's profile")
	qdel(first_mind)
	TEST_ASSERT(QDELETED(first_profile), "The departed profile must still follow its own mind's lifetime")

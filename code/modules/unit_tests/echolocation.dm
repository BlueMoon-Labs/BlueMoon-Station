/// Regression coverage for the echolocation quirk's blindness, action, and echo boundaries.
/datum/unit_test/echolocation_saved_name_migration

/datum/unit_test/echolocation_saved_name_migration/Run()
	var/datum/preferences/prefs = new
	allocated += prefs
	var/savefile/character_save = new
	var/localized_name = /datum/quirk/echolocation::name
	var/other_quirk = /datum/quirk/blindness::name
	prefs.all_quirks = list(other_quirk, "Echolocation")
	prefs.update_character(82, character_save)
	TEST_ASSERT(localized_name in prefs.all_quirks, "Renaming echolocation must preserve an existing selection")
	TEST_ASSERT(other_quirk in prefs.all_quirks, "Renaming echolocation must preserve unrelated selections")
	TEST_ASSERT(!("Echolocation" in prefs.all_quirks), "The obsolete English name must not remain in saved selections")
	TEST_ASSERT_EQUAL(length(prefs.all_quirks), 2, "Renaming a quirk must not change the number of selected quirks")
	TEST_ASSERT_EQUAL(SSquirks.quirks[localized_name], /datum/quirk/echolocation, "The migrated selection must resolve through the real quirk registry")

	prefs.all_quirks += "Echolocation"
	prefs.update_character(82, character_save)
	TEST_ASSERT_EQUAL(length(prefs.all_quirks), 2, "A save containing both names must not produce duplicate selections")
	prefs.update_character(82, character_save)
	TEST_ASSERT_EQUAL(length(prefs.all_quirks), 2, "Repeating the migration must be harmless")

	prefs.all_quirks = list(other_quirk)
	prefs.update_character(82, character_save)
	TEST_ASSERT_EQUAL(length(prefs.all_quirks), 1, "Migration must not grant echolocation to a character who never selected it")
	TEST_ASSERT(other_quirk in prefs.all_quirks, "An unrelated selection must survive migration unchanged")
	prefs.all_quirks = null
	prefs.update_character(82, character_save)
	TEST_ASSERT_NULL(prefs.all_quirks, "A missing quirk list must remain safe for the normal savefile sanitizer")

/datum/unit_test/echolocation_value

/datum/unit_test/echolocation_value/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	TEST_ASSERT_EQUAL(sense.value, abs(/datum/quirk/blindness::value) - 2, "Echolocation must offset the blindness quirk by two points")

/datum/unit_test/echolocation_actions_and_blindness

/datum/unit_test/echolocation_actions_and_blindness/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	holder.become_blind("unit_test_initial_blindness")
	sense.sync_actions()
	TEST_ASSERT_EQUAL(sense.snap_action.owner, holder, "A holder who starts blind must receive the snap action")
	TEST_ASSERT(!sense.eye_action.owner, "A holder who starts blind must not receive the eye action")
	holder.cure_blind("unit_test_initial_blindness")
	sense.sync_actions()
	TEST_ASSERT_EQUAL(sense.eye_action.owner, holder, "A sighted holder must receive the eye action")
	TEST_ASSERT(!sense.snap_action.owner, "A sighted holder must not receive the snap action")

	sense.toggle_eyes()
	TEST_ASSERT(sense.eyes_closed, "Closing eyes must update the quirk state")
	TEST_ASSERT(HAS_TRAIT(holder, TRAIT_BLIND), "Closing eyes must apply blindness")
	TEST_ASSERT_EQUAL(sense.snap_action.owner, holder, "Closing eyes must grant the snap action")

	holder.become_blind("unit_test_independent_blindness")
	sense.toggle_eyes()
	TEST_ASSERT(!sense.eyes_closed, "Opening eyes must update the quirk state")
	TEST_ASSERT(HAS_TRAIT(holder, TRAIT_BLIND), "Opening eyes must preserve unrelated blindness")
	TEST_ASSERT_EQUAL(sense.snap_action.owner, holder, "An independently blind holder must retain the snap action")
	TEST_ASSERT(!sense.eye_action.owner, "A blind holder with open eyes must not receive the eye action")

	holder.cure_blind("unit_test_independent_blindness")
	sense.sync_actions()
	TEST_ASSERT_EQUAL(sense.eye_action.owner, holder, "Curing independent blindness must restore the eye action")
	TEST_ASSERT(!sense.snap_action.owner, "Curing independent blindness must remove the snap action")

/datum/unit_test/echolocation_can_snap_gates

/datum/unit_test/echolocation_can_snap_gates/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	sense.toggle_eyes()
	TEST_ASSERT(sense.can_snap(), "A conscious listener with an open working hand must be able to snap")

	holder.held_items[1] = allocate(/obj/item)
	holder.held_items[2] = allocate(/obj/item)
	TEST_ASSERT(!sense.can_snap(), "A listener with no free hand must not be able to snap")
	holder.held_items[1] = null
	holder.held_items[2] = null

	for(var/obj/item/bodypart/hand in holder.hand_bodyparts)
		hand.disabled = TRUE
	TEST_ASSERT_EQUAL(sense.click_method(), "tongueclick", "Disabled hands must fall back to a tongue click")
	TEST_ASSERT(sense.can_snap(), "A tongue click must work when all hands are disabled")
	for(var/obj/item/bodypart/hand in holder.hand_bodyparts)
		hand.disabled = FALSE

	ADD_TRAIT(holder, TRAIT_DEAF, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(!sense.can_snap(), "A deaf listener must not be able to snap")
	REMOVE_TRAIT(holder, TRAIT_DEAF, TRAIT_SOURCE_UNIT_TESTS)

	holder.set_stat(UNCONSCIOUS)
	TEST_ASSERT(!sense.can_snap(), "An unconscious listener must not be able to snap")

/datum/unit_test/echolocation_restrained_action_fallbacks

/datum/unit_test/echolocation_restrained_action_fallbacks/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	var/atom/movable/screen/movable/action_button/button = allocate(/atom/movable/screen/movable/action_button)
	sense.toggle_eyes()
	TEST_ASSERT_EQUAL(sense.snap_action.current_method, "snap", "An unrestrained holder must initially use a finger snap")

	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	holder.handcuffed = cuffs
	cuffs.forceMove(holder)
	holder.update_handcuffed()
	TEST_ASSERT(holder.restrained(), "Handcuffs must restrain the action fallback test holder")
	sense.process()
	TEST_ASSERT_EQUAL(sense.snap_action.current_method, "tongueclick", "Fast processing must refresh a cuffed holder to tongue clicking")
	TEST_ASSERT_EQUAL(sense.snap_action.name, "Щёлкнуть языком", "A cuffed holder's action must show the tongue-click label")
	TEST_ASSERT_EQUAL(sense.snap_action.icon_icon, 'icons/mob/actions/click_tongue.png', "A cuffed holder's action must show the tongue-click icon")
	sense.next_echo = 0
	holder.nextsoundemote = -1
	sense.snap_action.UpdateButton(button)
	var/mutable_appearance/icon_overlay = button.overlays[1]
	TEST_ASSERT_EQUAL(icon_overlay.icon, 'icons/mob/actions/click_tongue.png', "The rendered cuffed action button must use the tongue-click icon")
	// BYOND normalizes an opaque white tint to null.
	TEST_ASSERT_NULL(button.color, "The rendered cuffed tongue-click button must have no unavailable tint")
	TEST_ASSERT(sense.snap_action.IsAvailable(), "A cuffed holder with a working tongue must have an available echolocation action")
	TEST_ASSERT(sense.snap_action.Trigger(), "A cuffed holder's tongue-click action must trigger")
	TEST_ASSERT(sense.next_echo > world.time, "A cuffed holder's tongue-click action must start an echo")

	var/obj/item/organ/tongue/tongue = holder.getorganslot(ORGAN_SLOT_TONGUE)
	tongue.organ_flags |= ORGAN_FAILING
	sense.next_echo = 0
	holder.nextsoundemote = -1
	sense.process()
	TEST_ASSERT_EQUAL(sense.snap_action.current_method, "jawclick", "A cuffed holder with a failing tongue must fall back to jaw clicking")
	TEST_ASSERT_EQUAL(sense.snap_action.name, "Щёлкнуть челюстью", "A cuffed holder without a working tongue must show the jaw-click label")
	TEST_ASSERT_EQUAL(sense.snap_action.icon_icon, 'icons/mob/actions/click_jaw.png', "A cuffed holder without a working tongue must show the jaw-click icon")
	sense.snap_action.UpdateButton(button)
	icon_overlay = button.overlays[1]
	TEST_ASSERT_EQUAL(icon_overlay.icon, 'icons/mob/actions/click_jaw.png', "The rendered cuffed action button must use the jaw-click icon")
	TEST_ASSERT_NULL(button.color, "The rendered cuffed jaw-click button must have no unavailable tint")
	TEST_ASSERT(sense.snap_action.IsAvailable(), "A cuffed holder with a usable jaw must have an available echolocation action")
	TEST_ASSERT(sense.snap_action.Trigger(), "A cuffed holder's jaw-click action must trigger")
	TEST_ASSERT(sense.next_echo > world.time, "A cuffed holder's jaw-click action must start an echo")

	tongue.organ_flags &= ~ORGAN_FAILING
	tongue.Remove(TRUE)
	sense.process()
	TEST_ASSERT_EQUAL(sense.snap_action.current_method, "jawclick", "A cuffed holder without a tongue must fall back to jaw clicking")
	tongue.Insert(holder, TRUE)
	holder.handcuffed = null
	holder.update_handcuffed()
	sense.next_echo = 0
	holder.nextsoundemote = -1
	sense.process()
	TEST_ASSERT_EQUAL(sense.snap_action.current_method, "snap", "Removing handcuffs must restore finger snapping")
	TEST_ASSERT_EQUAL(sense.snap_action.name, "Щёлкнуть пальцами", "Removing handcuffs must restore the finger-snap label")
	TEST_ASSERT_EQUAL(sense.snap_action.icon_icon, 'icons/mob/actions/snap_fingers.png', "Removing handcuffs must restore the finger-snap icon")
	TEST_ASSERT(sense.snap_action.IsAvailable(), "Removing handcuffs must restore the available finger-snap action")
	TEST_ASSERT(sense.snap_action.Trigger(), "The restored finger-snap action must trigger after uncuffing")
	TEST_ASSERT(sense.next_echo > world.time, "The restored finger-snap action must start an echo")

	ADD_TRAIT(holder, TRAIT_RESTRAINED, TRAIT_SOURCE_UNIT_TESTS)
	sense.process()
	TEST_ASSERT_EQUAL(sense.snap_action.current_method, "tongueclick", "The generic restrained trait must also select tongue clicking")
	REMOVE_TRAIT(holder, TRAIT_RESTRAINED, TRAIT_SOURCE_UNIT_TESTS)

/datum/unit_test/echolocation_mouth_fallbacks_and_hearing

/datum/unit_test/echolocation_mouth_fallbacks_and_hearing/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	sense.toggle_eyes()
	for(var/obj/item/bodypart/hand in holder.hand_bodyparts.Copy())
		hand.drop_limb(TRUE)
		qdel(hand)
	TEST_ASSERT_EQUAL(sense.click_method(), "tongueclick", "Removing both hands must select tongue clicking")
	TEST_ASSERT(sense.can_snap(), "A tongued, handless holder must be able to echolocate")

	sense.next_echo = 0
	holder.nextsoundemote = -1
	holder.emote("tongueclick", intentional = TRUE)
	TEST_ASSERT(sense.next_echo > world.time, "Tongue clicking must trigger echolocation through the emote signal")
	sense.next_echo = 0

	var/obj/item/organ/tongue/tongue = holder.getorganslot(ORGAN_SLOT_TONGUE)
	tongue.Remove(TRUE)
	TEST_ASSERT_EQUAL(sense.click_method(), "jawclick", "Removing the tongue must select jaw clicking")
	TEST_ASSERT(sense.can_snap(), "A headed, unmuzzled holder must be able to jaw click")
	sense.next_echo = 0
	holder.nextsoundemote = -1
	holder.emote("jawclick", intentional = TRUE)
	TEST_ASSERT(sense.next_echo > world.time, "Jaw clicking must trigger echolocation through the emote signal")
	sense.next_echo = 0

	tongue.Insert(holder, TRUE)
	TEST_ASSERT_EQUAL(sense.click_method(), "tongueclick", "Reinserting the tongue must restore tongue clicking")

	var/obj/item/clothing/mask/muzzle/muzzle = allocate(/obj/item/clothing/mask/muzzle)
	TEST_ASSERT(holder.equip_to_slot_or_del(muzzle, ITEM_SLOT_MASK), "The fallback test muzzle must equip")
	TEST_ASSERT(!sense.can_snap(), "A muzzle must prevent mouth-click echolocation")
	holder.dropItemToGround(muzzle, TRUE)
	TEST_ASSERT(sense.can_snap(), "Removing the muzzle must restore mouth-click echolocation")

	var/obj/item/organ/ears/ears = holder.getorganslot(ORGAN_SLOT_EARS)
	ears.damage = 70
	TEST_ASSERT(sense.can_listen(), "Ear damage exactly at the threshold must still permit echolocation")
	ears.damage = 71
	TEST_ASSERT(!sense.can_listen(), "Ear damage above the threshold must disable passive echolocation")
	TEST_ASSERT(!sense.can_snap(), "Ear damage above the threshold must disable active echolocation")
	ears.damage = 0
	TEST_ASSERT(sense.can_listen() && sense.can_snap(), "Healing ears must restore echolocation")

	holder.SetStun(1 SECONDS)
	TEST_ASSERT(!sense.can_listen(), "Stunning the holder must disable passive echolocation")
	TEST_ASSERT(!sense.can_snap(), "Stunning the holder must disable active echolocation")
	holder.SetStun(0)
	TEST_ASSERT(sense.can_listen() && sense.can_snap(), "Recovering from a stun must restore echolocation")

/datum/unit_test/echolocation_manual_mouth_emotes

/datum/unit_test/echolocation_manual_mouth_emotes/Run()
	for(var/hand_state in list("free", "occupied", "restrained", "absent"))
		for(var/tongue_state in list("present", "absent", "failing"))
			var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
			var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
			sense.toggle_eyes()

			switch(hand_state)
				if("occupied")
					holder.held_items[1] = allocate(/obj/item)
					holder.held_items[2] = allocate(/obj/item)
				if("restrained")
					var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
					holder.handcuffed = cuffs
					cuffs.forceMove(holder)
					TEST_ASSERT(holder.restrained(), "Handcuffs must actually restrain the manual mouth-emote test holder")
				if("absent")
					for(var/obj/item/bodypart/hand in holder.hand_bodyparts.Copy())
						hand.drop_limb(TRUE)
						qdel(hand)

			var/obj/item/organ/tongue/tongue = holder.getorganslot(ORGAN_SLOT_TONGUE)
			switch(tongue_state)
				if("absent")
					tongue.Remove(TRUE)
					qdel(tongue)
				if("failing")
					tongue.organ_flags |= ORGAN_FAILING

			for(var/emote_key in list("tongueclick", "jawclick"))
				var/expected_tongue_click = tongue_state == "present"
				var/expected_echo = emote_key == "jawclick" || expected_tongue_click
				sense.next_echo = 0
				holder.nextsoundemote = -1
				TEST_ASSERT_EQUAL(sense.can_snap(emote_key), expected_echo, "[emote_key] echolocation availability must match [hand_state] hands and a [tongue_state] tongue")
				var/emote_ran = holder.emote(emote_key, intentional = TRUE)
				TEST_ASSERT_EQUAL(!!emote_ran, expected_echo, "[emote_key] must only run with [hand_state] hands and a [tongue_state] tongue when its anatomy permits it")
				if(expected_echo)
					TEST_ASSERT(sense.next_echo > world.time, "[emote_key] must echolocate with [hand_state] hands and a [tongue_state] tongue")
				else
					TEST_ASSERT_EQUAL(sense.next_echo, 0, "[emote_key] must not echolocate with [hand_state] hands and a [tongue_state] tongue")
			if(hand_state != "free")
				for(var/emote_key in list("snap", "snap2", "snap3"))
					sense.next_echo = 0
					holder.nextsoundemote = -1
					holder.emote(emote_key, intentional = TRUE)
					TEST_ASSERT_EQUAL(sense.next_echo, 0, "[emote_key] must still require a free working hand when hands are [hand_state]")

	var/mob/living/carbon/human/no_quirk_holder = allocate(/mob/living/carbon/human)
	var/obj/item/organ/tongue/no_quirk_tongue = no_quirk_holder.getorganslot(ORGAN_SLOT_TONGUE)
	no_quirk_tongue.Remove(TRUE)
	qdel(no_quirk_tongue)
	TEST_ASSERT(!no_quirk_holder.emote("tongueclick", intentional = TRUE), "Tongue clicking must reject a holder without a tongue even without echolocation")

	var/mob/living/carbon/human/cooldown_holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/cooldown_sense = allocate(/datum/quirk/echolocation, cooldown_holder)
	cooldown_sense.toggle_eyes()
	cooldown_sense.next_echo = 0
	cooldown_holder.nextsoundemote = -1
	cooldown_holder.emote("tongueclick", intentional = TRUE)
	var/tongue_deadline = cooldown_sense.next_echo
	TEST_ASSERT(tongue_deadline > world.time, "A tongue click must start the shared echolocation cooldown")
	// Distinguish preserving the cooldown from incorrectly restarting it in the same tick.
	tongue_deadline -= 1
	cooldown_sense.next_echo = tongue_deadline
	cooldown_holder.nextsoundemote = -1
	cooldown_holder.emote("snap", intentional = TRUE)
	TEST_ASSERT_EQUAL(cooldown_sense.next_echo, tongue_deadline, "A finger snap must share the tongue-click echolocation cooldown")

	cooldown_sense.next_echo = 0
	cooldown_holder.nextsoundemote = -1
	cooldown_holder.emote("snap", intentional = TRUE)
	var/snap_deadline = cooldown_sense.next_echo
	TEST_ASSERT(snap_deadline > world.time, "A finger snap must start the shared echolocation cooldown")
	snap_deadline -= 1
	cooldown_sense.next_echo = snap_deadline
	cooldown_holder.nextsoundemote = -1
	cooldown_holder.emote("jawclick", intentional = TRUE)
	TEST_ASSERT_EQUAL(cooldown_sense.next_echo, snap_deadline, "A jaw click must share the finger-snap echolocation cooldown")

/datum/unit_test/echolocation_remove_and_transfer

/datum/unit_test/echolocation_remove_and_transfer/Run()
	var/mob/living/carbon/human/old_holder = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/new_holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, old_holder)
	sense.toggle_eyes()
	sense.transfer_mob(new_holder)
	TEST_ASSERT(!old_holder.is_blind(), "Transferring must clear blindness applied to the old holder")
	TEST_ASSERT_EQUAL(sense.quirk_holder, new_holder, "Transferring must attach the quirk to the new holder")
	TEST_ASSERT_EQUAL(sense.eye_action.owner, new_holder, "The new sighted holder must receive the eye action")
	TEST_ASSERT(!sense.snap_action.owner, "The new sighted holder must not inherit the snap action")

	sense.toggle_eyes()
	var/datum/action/echolocation_eyes/eye_action = sense.eye_action
	var/datum/action/echolocation_snap/snap_action = sense.snap_action
	qdel(sense)
	TEST_ASSERT(!HAS_TRAIT(new_holder, TRAIT_BLIND), "Removing the quirk must clear its closed-eyes blindness")
	TEST_ASSERT(QDELETED(eye_action) && QDELETED(snap_action), "Removing the quirk must delete both actions")

/datum/unit_test/echolocation_emote_signal

/datum/unit_test/echolocation_emote_signal/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	sense.toggle_eyes()

	for(var/emote_key in list("snap", "snap2", "snap3"))
		sense.next_echo = 0
		holder.nextsoundemote = -1
		holder.emote(emote_key, intentional = TRUE)
		TEST_ASSERT(sense.next_echo > world.time, "[emote_key] must trigger an echolocation pulse through the emote signal")

	sense.next_echo = 0
	holder.nextsoundemote = -1
	holder.emote("shrug", intentional = TRUE)
	TEST_ASSERT_EQUAL(sense.next_echo, 0, "A non-snap emote must not trigger echolocation")

	sense.toggle_eyes()
	holder.nextsoundemote = -1
	holder.emote("snap", intentional = TRUE)
	TEST_ASSERT_EQUAL(sense.next_echo, 0, "A sighted holder's snap must not trigger echolocation")

	sense.toggle_eyes()
	holder.nextsoundemote = -1
	holder.emote("snap", intentional = TRUE)
	var/first_deadline = sense.next_echo
	holder.nextsoundemote = -1
	holder.emote("snap", intentional = TRUE)
	TEST_ASSERT_EQUAL(sense.next_echo, first_deadline, "Snapping during the echolocation cooldown must not extend its deadline")

/datum/unit_test/echolocation_generated_icons

/datum/unit_test/echolocation_generated_icons/Run()
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	var/icon/wave = sense.wave_icon()
	TEST_ASSERT_EQUAL(wave.Width(), 128, "The generated echo wave must be 128 pixels wide")
	TEST_ASSERT_EQUAL(wave.Height(), 128, "The generated echo wave must be 128 pixels high")
	TEST_ASSERT(!wave.GetPixel(65, 65), "The center of the generated echo wave must remain transparent")
	TEST_ASSERT(wave.GetPixel(125, 65), "The generated echo wave must contain its outer ring")

	var/icon/floor = sense.floor_icon()
	TEST_ASSERT_EQUAL(floor.Width(), 32, "The generated floor grid must be 32 pixels wide")
	TEST_ASSERT_EQUAL(floor.Height(), 32, "The generated floor grid must be 32 pixels high")
	TEST_ASSERT(floor.GetPixel(1, 16), "The generated floor grid must retain its left edge")
	TEST_ASSERT(floor.GetPixel(16, 1), "The generated floor grid must retain its top edge")

	var/icon/chasm = sense.hazard_icon("chasm")
	var/icon/lava = sense.hazard_icon("lava")
	var/icon/plasma = sense.hazard_icon("plasma")
	TEST_ASSERT_EQUAL(chasm.Width(), 32, "Generated chasm contours must remain tile-sized")
	TEST_ASSERT_EQUAL(lava.Height(), 32, "Generated lava contours must remain tile-sized")
	TEST_ASSERT_EQUAL(plasma.Width(), 32, "Generated plasma contours must remain tile-sized")
	TEST_ASSERT_NOTEQUAL(chasm.GetPixel(10, 13), lava.GetPixel(10, 13), "Chasm and lava must use distinct monochrome textures")
	TEST_ASSERT_NOTEQUAL(lava.GetPixel(10, 7), plasma.GetPixel(10, 7), "Lava and plasma must use distinct monochrome textures")
	var/all_edges = NORTH | SOUTH | EAST | WEST
	fcopy(sense.hazard_icon("chasm", all_edges), "data/echolocation_check/hazard_chasm.png")
	fcopy(sense.hazard_icon("lava", all_edges), "data/echolocation_check/hazard_lava.png")
	fcopy(sense.hazard_icon("plasma", all_edges), "data/echolocation_check/hazard_plasma.png")

/datum/unit_test/echolocation_hazard_surfaces

/datum/unit_test/echolocation_hazard_surfaces/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/north = get_step(origin, NORTH)
	var/turf/east = get_step(origin, EAST)
	var/turf/south = get_step(origin, SOUTH)
	var/turf/west = get_step(origin, WEST)
	var/turf/north_beyond = get_step(north, NORTH)
	var/north_type = north.type
	var/east_type = east.type
	var/south_type = south.type
	var/west_type = west.type
	var/north_beyond_type = north_beyond.type
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, origin)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)

	north = north.ChangeTurf(/turf/open/chasm, flags = CHANGETURF_INHERIT_AIR)
	east = east.ChangeTurf(/turf/open/lava/smooth, flags = CHANGETURF_INHERIT_AIR)
	south = south.ChangeTurf(/turf/open/lava/plasma/ice_moon, flags = CHANGETURF_INHERIT_AIR)
	west = west.ChangeTurf(/turf/open/water, flags = CHANGETURF_INHERIT_AIR)
	north_beyond = north_beyond.ChangeTurf(/turf/open/floor/fakepit, flags = CHANGETURF_INHERIT_AIR)

	TEST_ASSERT_EQUAL(sense.surface_hazard(north), "chasm", "Real chasms must render as chasms")
	TEST_ASSERT_EQUAL(sense.surface_hazard(east), "lava", "Smooth lava must render as lava")
	TEST_ASSERT_EQUAL(sense.surface_hazard(south), "plasma", "Ice moon plasma must render as plasma")
	TEST_ASSERT_NULL(sense.surface_hazard(west), "Water over a chasm baseturf must remain an ordinary surface")
	TEST_ASSERT_NULL(sense.surface_hazard(north_beyond), "A fake pit must remain an ordinary floor surface")
	TEST_ASSERT(sense.carries_sound(north), "An air-filled hazard turf must carry an echo")
	TEST_ASSERT(north in sense.collect_echo_turfs(origin, 5, 5), "An air-filled hazard turf must be collected by an echo")

	east = east.PlaceOnTop(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
	TEST_ASSERT_NULL(sense.surface_hazard(east), "A constructed floor placed over lava must not retain the old hazard classification")
	north = north.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)
	TEST_ASSERT_NULL(sense.surface_hazard(north), "A turf changed from chasm to floor must not retain the old hazard classification")

	north.ChangeTurf(north_type, flags = CHANGETURF_INHERIT_AIR)
	east.ChangeTurf(east_type, flags = CHANGETURF_INHERIT_AIR)
	south.ChangeTurf(south_type, flags = CHANGETURF_INHERIT_AIR)
	west.ChangeTurf(west_type, flags = CHANGETURF_INHERIT_AIR)
	north_beyond.ChangeTurf(north_beyond_type, flags = CHANGETURF_INHERIT_AIR)

/datum/unit_test/echolocation_hazard_contours

/datum/unit_test/echolocation_hazard_contours/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/north = get_step(origin, NORTH)
	var/turf/east = get_step(origin, EAST)
	var/turf/south = get_step(origin, SOUTH)
	var/turf/west = get_step(origin, WEST)
	var/origin_type = origin.type
	var/north_type = north.type
	var/east_type = east.type
	var/south_type = south.type
	var/west_type = west.type
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, get_step(origin, SOUTH))
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)

	origin = origin.ChangeTurf(/turf/open/lava, flags = CHANGETURF_INHERIT_AIR)
	east = east.ChangeTurf(/turf/open/lava/smooth, flags = CHANGETURF_INHERIT_AIR)
	TEST_ASSERT_EQUAL(sense.hazard_edges(origin, "lava"), NORTH | SOUTH | WEST, "Adjacent lava must suppress only its shared contour seam")
	east = east.ChangeTurf(/turf/open/lava/plasma, flags = CHANGETURF_INHERIT_AIR)
	TEST_ASSERT_EQUAL(sense.hazard_edges(origin, "lava"), NORTH | SOUTH | EAST | WEST, "A different hazard kind must retain a contour seam")

	var/atom/movable/screen/echolocation_echo/hazard_echo = allocate(/atom/movable/screen/echolocation_echo)
	TEST_ASSERT_EQUAL(hazard_echo.set_surface(origin, sense), 180, "Hazard surfaces must use hazard brightness")
	var/atom/movable/screen/echolocation_echo/floor_echo = allocate(/atom/movable/screen/echolocation_echo)
	TEST_ASSERT_EQUAL(floor_echo.set_surface(south, sense), 45, "Ordinary floor surfaces must retain floor brightness")
	TEST_ASSERT_EQUAL(hazard_echo.layer, floor_echo.layer, "Hazard surfaces must remain on the floor layer")
	var/icon/hazard_texture = icon(hazard_echo.icon)
	var/icon/floor_texture = sense.floor_icon()
	TEST_ASSERT_NOTEQUAL(hazard_texture.GetPixel(8, 16), floor_texture.GetPixel(8, 16), "set_surface() must render a hazard texture instead of the ordinary floor grid")

	north = north.ChangeTurf(/turf/closed/wall, flags = CHANGETURF_INHERIT_AIR)
	var/atom/movable/screen/echolocation_echo/wall_echo = allocate(/atom/movable/screen/echolocation_echo)
	TEST_ASSERT_EQUAL(wall_echo.set_surface(north, sense), 165, "Closed surfaces must retain wall brightness")
	TEST_ASSERT(length(wall_echo.overlays), "set_surface() must use a wall shape for closed turfs")

	origin.ChangeTurf(origin_type, flags = CHANGETURF_INHERIT_AIR)
	north.ChangeTurf(north_type, flags = CHANGETURF_INHERIT_AIR)
	east.ChangeTurf(east_type, flags = CHANGETURF_INHERIT_AIR)
	south.ChangeTurf(south_type, flags = CHANGETURF_INHERIT_AIR)
	west.ChangeTurf(west_type, flags = CHANGETURF_INHERIT_AIR)

/datum/unit_test/echolocation_echo_boundaries

/datum/unit_test/echolocation_echo_boundaries/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/north = get_step(origin, NORTH)
	var/turf/north_beyond = get_step(north, NORTH)
	var/turf/east = get_step(origin, EAST)
	var/turf/east_beyond = get_step(east, EAST)
	var/turf/south = get_step(origin, SOUTH)
	var/turf/south_beyond = get_step(south, SOUTH)
	var/turf/west = get_step(origin, WEST)
	var/turf/west_beyond = get_step(west, WEST)
	var/north_type = north.type
	var/datum/gas_mixture/saved_west_air = new
	saved_west_air.copy_from(west.return_air())
	north = north.ChangeTurf(/turf/closed/wall)
	allocate(/obj/machinery/door/airlock, east)
	allocate(/obj/structure/window/fulltile, south)
	west.return_air().clear()

	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, origin)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	var/list/reached = sense.collect_echo_turfs(origin, 7, 7)
	var/north_reached = (north in reached)
	var/east_reached = (east in reached)
	var/south_reached = (south in reached)
	var/west_reached = (west in reached)
	var/north_beyond_reached = (north_beyond in reached)
	var/east_beyond_reached = (east_beyond in reached)
	var/south_beyond_reached = (south_beyond in reached)
	var/west_beyond_reached = (west_beyond in reached)
	north = north.ChangeTurf(north_type)
	west.return_air().copy_from(saved_west_air)
	qdel(saved_west_air)

	TEST_ASSERT(north_reached && east_reached && south_reached && west_reached, "Reflecting barriers and vacuum boundaries must be included")
	TEST_ASSERT(!north_beyond_reached, "A wall must stop echo propagation")
	TEST_ASSERT(!east_beyond_reached, "A closed door must stop echo propagation")
	TEST_ASSERT(!south_beyond_reached, "A fulltile window must stop echo propagation")
	TEST_ASSERT(!west_beyond_reached, "Vacuum must stop echo propagation")
	TEST_ASSERT(length(reached) <= 49, "Echo collection must remain bounded by the supplied screen dimensions")

/datum/unit_test/echolocation_snapshot_is_static

/datum/unit_test/echolocation_snapshot_is_static/Run()
	var/obj/item/stack/rods/observed = allocate(/obj/item/stack/rods)
	var/atom/movable/screen/echolocation_echo/echo = allocate(/atom/movable/screen/echolocation_echo)
	echo.set_shape(observed)
	var/mutable_appearance/shape = echo.overlays[1]
	var/original_icon = shape.icon
	var/original_icon_state = shape.icon_state
	observed.icon_state = "echolocation_test_changed_source"
	qdel(observed)
	TEST_ASSERT(shape != observed, "An echo shape must be a copied appearance, not the source atom")
	TEST_ASSERT(!isnull(original_icon), "A full icon snapshot must retain the observed icon")
	TEST_ASSERT_EQUAL(shape.icon, original_icon, "Deleting the source atom must not remove the snapshot icon")
	TEST_ASSERT_EQUAL(shape.icon_state, original_icon_state, "Changing the source atom must not change the snapshot")
	TEST_ASSERT(!length(echo.vis_contents), "An echo snapshot must not track the source through vis_contents")

	var/mob/living/carbon/human/typing_holder = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	typing_holder.display_typing_indicator(isSay = TRUE)
	TEST_ASSERT(typing_holder.typing_indicator_current, "Test premise: the observed mob must have a normal typing indicator")
	var/atom/movable/screen/echolocation_echo/typing_echo = allocate(/atom/movable/screen/echolocation_echo)
	typing_echo.set_shape(typing_holder)
	var/mutable_appearance/typing_shape = typing_echo.overlays[1]
	TEST_ASSERT(!typing_shape.overlays || !(typing_holder.typing_indicator_current in typing_shape.overlays), "An echo shape must not retain the observed mob's normal typing indicator")
	typing_holder.clear_typing_indicator()

/datum/unit_test/echolocation_directional_shape_snapshots

/datum/unit_test/echolocation_directional_shape_snapshots/Run()
	var/obj/structure/chair/observed = allocate(/obj/structure/chair)
	var/obj/structure/window/window = allocate(/obj/structure/window)
	observed.pixel_x = 4
	observed.pixel_y = -3
	observed.transform = matrix(1.2, 0, 3, 0, 0.8, -2)
	for(var/direction in GLOB.cardinals)
		observed.setDir(direction)
		var/atom/movable/screen/echolocation_echo/echo = allocate(/atom/movable/screen/echolocation_echo)
		echo.set_shape(observed)
		var/mutable_appearance/shape = echo.overlays[1]
		TEST_ASSERT_EQUAL(echo.dir, direction, "An echo host must face the directional chair it snapshots ([dir2text(direction)])")
		// BYOND may normalize mutable overlay directions to 0, inheriting their host.
		TEST_ASSERT_EQUAL(shape.dir || echo.dir, direction, "A grouped echo shape must render in the chair's direction ([dir2text(direction)])")
		TEST_ASSERT_EQUAL(shape.pixel_x, observed.pixel_x, "A directional snapshot must retain the chair's horizontal pixel offset")
		TEST_ASSERT_EQUAL(shape.pixel_y, observed.pixel_y, "A directional snapshot must retain the chair's vertical pixel offset")
		TEST_ASSERT_EQUAL(shape.transform.a, observed.transform.a, "A directional snapshot must retain the chair's horizontal transform scale")
		TEST_ASSERT_EQUAL(shape.transform.e, observed.transform.e, "A directional snapshot must retain the chair's vertical transform scale")
		TEST_ASSERT_EQUAL(shape.transform.c, observed.transform.c, "A directional snapshot must retain the chair's horizontal transform translation")
		TEST_ASSERT_EQUAL(shape.transform.f, observed.transform.f, "A directional snapshot must retain the chair's vertical transform translation")

		var/rotated_direction = turn(direction, 90)
		observed.setDir(rotated_direction)
		TEST_ASSERT_EQUAL(echo.dir, direction, "Rotating a chair after an echo must not rotate the old echo host")
		TEST_ASSERT_EQUAL(shape.dir || echo.dir, direction, "Rotating a chair after an echo must not rotate the old grouped shape")
		var/atom/movable/screen/echolocation_echo/rotated_echo = allocate(/atom/movable/screen/echolocation_echo)
		rotated_echo.set_shape(observed)
		var/mutable_appearance/rotated_shape = rotated_echo.overlays[1]
		TEST_ASSERT_EQUAL(rotated_echo.dir, rotated_direction, "A later echo must use the chair's current direction")
		TEST_ASSERT_EQUAL(rotated_shape.dir || rotated_echo.dir, rotated_direction, "A later grouped shape must use the chair's current direction")

		window.setDir(direction)
		var/atom/movable/screen/echolocation_echo/window_echo = allocate(/atom/movable/screen/echolocation_echo)
		window_echo.set_shape(window)
		var/mutable_appearance/window_shape = window_echo.overlays[1]
		TEST_ASSERT_EQUAL(window_echo.dir, direction, "An echo host must retain a directional window's edge orientation")
		TEST_ASSERT_EQUAL(window_shape.dir || window_echo.dir, direction, "A grouped window shape must remain on the source window's edge")

	var/obj/structure/chair/e_chair/electric_chair = allocate(/obj/structure/chair/e_chair)
	electric_chair.setDir(EAST)
	var/mutable_appearance/original_overlay = electric_chair.overlays[1]
	var/original_overlay_direction = original_overlay.dir
	var/atom/movable/screen/echolocation_echo/electric_echo = allocate(/atom/movable/screen/echolocation_echo)
	electric_echo.set_shape(electric_chair)
	var/mutable_appearance/electric_shape = electric_echo.overlays[1]
	var/mutable_appearance/inherited_overlay = electric_shape.overlays[1]
	TEST_ASSERT(inherited_overlay, "Test premise: an electric chair must retain its nested directional overlay in an echo snapshot")
	TEST_ASSERT_EQUAL(electric_echo.dir, EAST, "An echo host must supply direction to nested mutable overlays")
	TEST_ASSERT_EQUAL(electric_shape.dir || electric_echo.dir, EAST, "A grouped electric-chair shape must direct its nested overlay")
	// A copied inherited direction can normalize from SOUTH to 0 while still following its host.
	TEST_ASSERT_EQUAL(inherited_overlay.dir || electric_shape.dir || electric_echo.dir, EAST, "A nested mutable overlay must render in the electric chair's direction")
	var/mutable_appearance/current_overlay = electric_chair.overlays[1]
	TEST_ASSERT_EQUAL(current_overlay.dir, original_overlay_direction, "An echo must not change the source chair overlay's direction")

/datum/unit_test/echolocation_monochrome_shape_grouping

/datum/unit_test/echolocation_monochrome_shape_grouping/Run()
	for(var/obj/structure/chair/observed as anything in list(allocate(/obj/structure/chair/comfy/brown), allocate(/obj/structure/chair/sofa/middle/maroon)))
		observed.setDir(NORTH)
		var/source_color = observed.color
		observed.filters = list(filter(type = "blur", size = 1))
		var/image/directed_overlay = image(observed.icon, icon_state = observed.icon_state, dir = EAST)
		directed_overlay.plane = FOV_VISUAL_PLANE
		directed_overlay.appearance_flags |= KEEP_APART | RESET_COLOR
		var/image/nested_overlay = image(observed.icon, icon_state = observed.icon_state, dir = SOUTH)
		nested_overlay.plane = FOV_VISUAL_PLANE
		nested_overlay.appearance_flags |= KEEP_APART
		directed_overlay.overlays += nested_overlay
		var/image/directed_underlay = image(observed.icon, icon_state = observed.icon_state, dir = WEST)
		directed_underlay.plane = FOV_VISUAL_PLANE
		directed_underlay.appearance_flags |= KEEP_APART | RESET_COLOR
		observed.overlays += directed_overlay
		observed.underlays += directed_underlay

		var/atom/movable/screen/echolocation_echo/echo = allocate(/atom/movable/screen/echolocation_echo)
		echo.set_shape(observed)
		var/image/shape = echo.overlays[1]
		var/image/copied_overlay = shape.overlays[length(shape.overlays)]
		var/image/copied_nested_overlay = copied_overlay.overlays[1]
		var/image/copied_underlay = shape.underlays[length(shape.underlays)]
		TEST_ASSERT_NULL(echo.color, "A monochrome echo host must remain neutral after copying [observed.name]")
		TEST_ASSERT_EQUAL(length(echo.filters), 2, "A monochrome echo host must retain its gray silhouette and white outline filters")
		TEST_ASSERT_EQUAL(observed.color, source_color, "Copying [observed.name] must not alter its source color")
		TEST_ASSERT_EQUAL(shape.color, source_color, "The copied [observed.name] shape must retain its source color before host filtering")
		TEST_ASSERT_EQUAL(length(observed.filters), 1, "Copying [observed.name] must not alter its source filters")
		TEST_ASSERT_EQUAL(length(shape.filters), 0, "The copied [observed.name] root shape must not retain source filters")
		TEST_ASSERT(shape.appearance_flags & KEEP_TOGETHER, "The copied [observed.name] root shape must group its colored layers")
		TEST_ASSERT_EQUAL(copied_overlay.dir, EAST, "An explicitly directed overlay on [observed.name] must retain its direction")
		TEST_ASSERT_EQUAL(copied_nested_overlay.dir, SOUTH, "A nested explicitly directed overlay on [observed.name] must retain its direction")
		TEST_ASSERT_EQUAL(copied_underlay.dir, WEST, "An explicitly directed underlay on [observed.name] must retain its direction")
		assert_floated_shape(shape, observed.name)

/datum/unit_test/echolocation_monochrome_shape_grouping/proc/assert_floated_shape(image/appearance, source_name)
	TEST_ASSERT_EQUAL(appearance.plane, FLOAT_PLANE, "Every copied [source_name] layer must render on the floating plane")
	TEST_ASSERT(!(appearance.appearance_flags & KEEP_APART), "No copied [source_name] layer may escape its monochrome group")
	for(var/image/child as anything in appearance.overlays)
		assert_floated_shape(child, source_name)
	for(var/image/child as anything in appearance.underlays)
		assert_floated_shape(child, source_name)

/datum/unit_test/echolocation_lighting_shape_filtering

/datum/unit_test/echolocation_lighting_shape_filtering/Run()
	var/obj/machinery/light/small/lamp = allocate(/obj/machinery/light/small)
	lamp.on = TRUE
	lamp.status = LIGHT_OK
	lamp.setDir(EAST)
	var/list/fixture_overlays = lamp.update_overlays()
	var/image/physical_fixture_overlay
	var/image/emissive_fixture_overlay
	for(var/image/fixture_overlay as anything in fixture_overlays)
		if(fixture_overlay.icon != 'icons/obj/lighting_overlay.dmi' || fixture_overlay.icon_state != lamp.base_state)
			continue
		if(fixture_overlay.plane == EMISSIVE_PLANE)
			emissive_fixture_overlay = fixture_overlay
		else
			physical_fixture_overlay = fixture_overlay
	TEST_ASSERT(physical_fixture_overlay, "A working small light must generate its ordinary fixture overlay")
	TEST_ASSERT(emissive_fixture_overlay, "A working small light must generate its emissive fixture overlay")
	TEST_ASSERT_EQUAL(physical_fixture_overlay.dir, EAST, "A fixture's ordinary overlay must retain the lamp direction")
	TEST_ASSERT_EQUAL(emissive_fixture_overlay.dir, EAST, "A fixture's emissive overlay must retain the lamp direction")

	var/atom/movable/screen/echolocation_echo/echo = allocate(/atom/movable/screen/echolocation_echo)
	var/image/source_root = image(physical_fixture_overlay)
	source_root.overlays += emissive_fixture_overlay
	var/image/physical_child = image('icons/obj/lighting_overlay.dmi', icon_state = lamp.base_state, dir = EAST)
	physical_child.plane = ABOVE_LIGHTING_PLANE
	var/list/lighting_planes = list(FLOOR_LIGHTING_LAMPS_PLANE, FLOOR_LIGHTING_LAMPS_SELFGLOW, FLOOR_LIGHTING_LAMPS_GLARE, LIGHTING_LAMPS_PLANE, LIGHTING_LAMPS_SELFGLOW, LIGHTING_EXPOSURE_PLANE, LIGHTING_LAMPS_GLARE, EMISSIVE_PLANE, EMISSIVE_BLOCKER_PLANE, O_LIGHTING_VISUAL_PLANE)
	for(var/plane in lighting_planes)
		var/image/light_shape = image('icons/obj/lamps.dmi', icon_state = "bulb", dir = EAST)
		light_shape.plane = plane
		physical_child.overlays += light_shape
		var/image/light_underlay = image('icons/effects/exposures.dmi', icon_state = "circle", dir = EAST)
		light_underlay.plane = plane
		physical_child.underlays += light_underlay
	// BYOND snapshots an image when adding it: attach only after populating its children.
	source_root.overlays += physical_child
	var/image/attached_physical_child = source_root.overlays[2]
	TEST_ASSERT_EQUAL(length(attached_physical_child.overlays), length(lighting_planes), "Test premise: nested lighting overlays must exist in the source snapshot")
	TEST_ASSERT_EQUAL(length(attached_physical_child.underlays), length(lighting_planes), "Test premise: nested lighting underlays must exist in the source snapshot")

	var/image/copied_root = echo.copy_shape_appearance(source_root, base_shape = TRUE)
	TEST_ASSERT(copied_root, "The physical fixture appearance must survive filtering")
	TEST_ASSERT_EQUAL(copied_root.icon, 'icons/obj/lighting_overlay.dmi', "The copied root must retain the fixture's physical icon")
	TEST_ASSERT_EQUAL(copied_root.icon_state, lamp.base_state, "The copied root must retain the fixture's physical icon state")
	TEST_ASSERT_EQUAL(copied_root.dir, EAST, "The copied root must retain the fixture direction")
	TEST_ASSERT_EQUAL(length(copied_root.overlays), 1, "A physical child on the aliased lighting plane must survive")
	var/image/copied_physical_child = copied_root.overlays[1]
	TEST_ASSERT_EQUAL(copied_physical_child.plane, FLOAT_PLANE, "The preserved physical child must be rehomed into the echo group")
	TEST_ASSERT_EQUAL(copied_physical_child.dir, EAST, "The preserved physical child must retain its direction")
	TEST_ASSERT(!length(copied_physical_child.overlays) && !length(copied_physical_child.underlays), "Nested glow, exposure, emissive, and overlay-lighting shapes must be removed")
	TEST_ASSERT_EQUAL(length(source_root.overlays), 2, "Copying must remove the small light's real emissive overlay without changing its source appearance")
	TEST_ASSERT_EQUAL(length(physical_child.overlays), length(lighting_planes), "Copying must not remove lighting overlays from the source appearance")
	TEST_ASSERT_EQUAL(length(physical_child.underlays), length(lighting_planes), "Copying must not remove lighting underlays from the source appearance")
	for(var/image/source_light_shape as anything in physical_child.overlays)
		TEST_ASSERT(source_light_shape.plane in lighting_planes, "Synthetic lamp glow shapes must remain unchanged on the source appearance")
	for(var/image/source_light_shape as anything in physical_child.underlays)
		TEST_ASSERT(source_light_shape.plane in lighting_planes, "Synthetic lamp exposure shapes must remain unchanged on the source appearance")

	var/image/emissive_root = image('icons/obj/lighting_overlay.dmi', icon_state = lamp.base_state, dir = EAST)
	emissive_root.plane = EMISSIVE_PLANE
	var/image/copied_emissive_root = echo.copy_shape_appearance(emissive_root, base_shape = TRUE)
	TEST_ASSERT(copied_emissive_root, "The base-shape call must retain a physical root regardless of its source plane")
	TEST_ASSERT_EQUAL(copied_emissive_root.icon, 'icons/obj/lighting_overlay.dmi', "A preserved physical root must retain its fixture icon")
	TEST_ASSERT_EQUAL(copied_emissive_root.plane, FLOAT_PLANE, "A preserved physical root must be rehomed into the echo group")

/datum/unit_test/echolocation_lit_fixtures

/datum/unit_test/echolocation_lit_fixtures/Run()
	for(var/fixture_type in list(/obj/machinery/light, /obj/machinery/light/small))
		var/obj/machinery/light/lamp = allocate(fixture_type, run_loc_floor_bottom_left)
		lamp.on = TRUE
		lamp.status = LIGHT_OK
		lamp.setDir(EAST)
		lamp.update_appearance()
		lamp.set_light(l_range = 3, l_power = 1, l_on = TRUE)
		lamp.update_bloom()
		TEST_ASSERT(lamp.glow_overlay && lamp.exposure_overlay, "Test premise: the working lamp must have real glow and exposure images")
		TEST_ASSERT(lamp.glow_overlay.appearance in lamp.overlays, "Test premise: the real lamp glow must be attached")
		TEST_ASSERT(lamp.exposure_overlay.appearance in lamp.overlays, "Test premise: the real cone or circle exposure must be attached")
		var/source_overlay_count = length(lamp.overlays)
		var/atom/movable/screen/echolocation_echo/lamp_echo = allocate(/atom/movable/screen/echolocation_echo)
		lamp_echo.set_shape(lamp)
		var/image/lamp_shape = lamp_echo.overlays[1]
		TEST_ASSERT_EQUAL(lamp_shape.icon, lamp.icon, "The lit lamp's physical casing must remain in its echo")
		TEST_ASSERT_EQUAL(lamp_shape.icon_state, lamp.icon_state, "The lit lamp's casing state must remain in its echo")
		TEST_ASSERT_EQUAL(length(lamp_shape.overlays), 1, "The lit lamp must retain only its physical bulb overlay, without emissive, glow, or exposure masks")
		var/image/bulb_shape = lamp_shape.overlays[1]
		TEST_ASSERT_EQUAL(bulb_shape.icon, lamp.overlayicon, "The lamp's physical bulb must remain visible")
		TEST_ASSERT_EQUAL(bulb_shape.icon_state, lamp.base_state, "Both tube and small fixtures must retain their own bulb shape")
		TEST_ASSERT_EQUAL(length(lamp.overlays), source_overlay_count, "Echolocation must leave the lamp's normal lighting untouched")

	var/obj/item/flashlight/flashlight = allocate(/obj/item/flashlight, run_loc_floor_bottom_left)
	flashlight.on = TRUE
	flashlight.update_brightness()
	var/light_underlay_count = 0
	for(var/image/underlay as anything in flashlight.underlays)
		if(underlay.plane == O_LIGHTING_VISUAL_PLANE)
			light_underlay_count++
	TEST_ASSERT(light_underlay_count, "Test premise: a lit flashlight must have real overlay-lighting underlays")
	var/source_underlay_count = length(flashlight.underlays)
	var/atom/movable/screen/echolocation_echo/flashlight_echo = allocate(/atom/movable/screen/echolocation_echo)
	flashlight_echo.set_shape(flashlight)
	var/image/flashlight_shape = flashlight_echo.overlays[1]
	TEST_ASSERT_EQUAL(flashlight_shape.icon_state, flashlight.icon_state, "A flashlight's physical shape must remain in its echo")
	TEST_ASSERT_EQUAL(length(flashlight_shape.underlays), source_underlay_count - light_underlay_count, "A flashlight's light mask and cone must not enter its echo")
	TEST_ASSERT_EQUAL(length(flashlight.underlays), source_underlay_count, "Echolocation must leave the flashlight's original light underlays untouched")

/datum/unit_test/echolocation_item_echo_visibility

/datum/unit_test/echolocation_item_echo_visibility/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, test_turf)
	var/datum/quirk/echolocation/sense = allocate(/datum/quirk/echolocation, holder)
	var/obj/item/stack/rods/rods = allocate(/obj/item/stack/rods, test_turf)
	var/obj/item/storage/backpack/backpack = allocate(/obj/item/storage/backpack, test_turf)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, get_step(test_turf, NORTH))

	TEST_ASSERT(sense.can_echo_atom(rods), "Rods on a turf must produce an echo shape")
	TEST_ASSERT(holder.put_in_hands(rods), "Test premise: the rods must fit in the holder's hand")
	TEST_ASSERT(!sense.can_echo_atom(rods), "Held rods must not produce an echo shape")
	TEST_ASSERT(holder.dropItemToGround(rods, TRUE), "Test premise: the rods must drop to the turf")
	TEST_ASSERT(sense.can_echo_atom(rods), "Dropped rods must again produce an echo shape")
	rods.forceMove(backpack)
	TEST_ASSERT(!sense.can_echo_atom(rods), "Rods inside a backpack must not produce an echo shape")
	rods.forceMove(test_turf)

	rods.invisibility = 1
	TEST_ASSERT(!sense.can_echo_atom(rods), "Invisible rods must not produce an echo shape")
	rods.invisibility = 0
	rods.alpha = 0
	TEST_ASSERT(!sense.can_echo_atom(rods), "Fully transparent rods must not produce an echo shape")
	rods.alpha = initial(rods.alpha)

	TEST_ASSERT(!sense.can_echo_atom(rods, TRUE), "Items on a reflecting boundary must not produce a duplicate echo shape")
	TEST_ASSERT(sense.can_echo_atom(door, TRUE), "A door on a reflecting boundary must produce its boundary echo shape")

/datum/unit_test/echolocation_typing_echo_lifecycle

/datum/unit_test/echolocation_typing_echo_lifecycle/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/moved_turf = get_step(origin, EAST)
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, origin)
	var/atom/movable/screen/echolocation_echo/marker = allocate(/atom/movable/screen/echolocation_echo)

	holder.display_typing_indicator(isSay = TRUE)
	TEST_ASSERT(holder.typing_indicator_current, "Test premise: displaying a say typing indicator must create an indicator")
	marker.set_typist(holder)
	TEST_ASSERT_EQUAL(marker.refresh_typing(), holder, "A marker must follow its self-typing source")
	TEST_ASSERT_EQUAL(marker.world_x, origin.x, "A typing marker must use the source's initial X coordinate")
	TEST_ASSERT_EQUAL(marker.world_y, origin.y, "A typing marker must use the source's initial Y coordinate")

	holder.forceMove(moved_turf)
	TEST_ASSERT_EQUAL(marker.refresh_typing(), holder, "A typing marker must remain valid after its source moves across turfs")
	TEST_ASSERT_EQUAL(marker.world_x, moved_turf.x, "A typing marker must update its X coordinate when its source moves")
	TEST_ASSERT_EQUAL(marker.world_y, moved_turf.y, "A typing marker must update its Y coordinate when its source moves")

	holder.clear_typing_indicator()
	TEST_ASSERT_NULL(marker.refresh_typing(), "Cancelling typing must clear the echolocation typing marker")

	holder.display_typing_indicator(isSay = TRUE)
	var/obj/item/storage/backpack/backpack = allocate(/obj/item/storage/backpack, moved_turf)
	holder.forceMove(backpack)
	TEST_ASSERT_NULL(marker.refresh_typing(), "A typing source inside a container must not retain an echo marker")
	holder.forceMove(moved_turf)
	holder.clear_typing_indicator()

	var/mob/living/carbon/human/deleted_source = allocate(/mob/living/carbon/human, origin)
	var/atom/movable/screen/echolocation_echo/deleted_marker = allocate(/atom/movable/screen/echolocation_echo)
	deleted_source.display_typing_indicator(isSay = TRUE)
	TEST_ASSERT(deleted_source.typing_indicator_current, "Test premise: the deleted source must have a typing indicator")
	deleted_marker.set_typist(deleted_source)
	qdel(deleted_source)
	TEST_ASSERT_NULL(deleted_marker.refresh_typing(), "Deleting a typing source must safely clear its weakref-backed marker")

/datum/component/pregnancy

	dupe_mode = COMPONENT_DUPE_UNIQUE
	//can_transfer = TRUE

	/// type of baby the mother will plop out - needs to be subtype of /mob/living
	var/baby_type = /mob/living/carbon/human

	var/obj/item/organ/container
	var/mob/living/carrier
	var/datum/pregnancy_coordinator/coordinator

	var/datum/dna/father_dna
	var/datum/dna/mother_dna

	var/list/mother_features
	var/list/father_features

	var/mother_name

	var/egg_name

	var/stage = 0
	var/max_stage = PREGNANCY_STAGES
	COOLDOWN_DECLARE(stage_time)
	COOLDOWN_DECLARE(hatch_request_cooldown)
	/// Prevent multiple hatch() calls during the ghost poll/name dialog.
	var/hatch_in_progress = FALSE
	/// Active only while an egg has no living carrier; cancelled on insertion.
	var/tmp/external_stage_timer

	var/added_size = 0
	/// this boolean is for identifying whether this preg is in the egg state or not
	var/oviposition = TRUE
	/// this boolean is for saving whether or not we should inflate the belly if appropriate
	var/pregnancy_inflation = TRUE
	/// breast growth
	var/pregnancy_breast_growth = TRUE
	/// whether the pregnancy is revealed or not, scanners will reveal this no matter what
	var/revealed = FALSE

/datum/component/pregnancy/Initialize(mob/living/_mother, mob/living/_father, _baby_type = /mob/living/carbon/human)
	if(!isobj(parent))
		return COMPONENT_INCOMPATIBLE

	var/obj/item/thing = parent

	if(!isorgan(thing.loc))
		return COMPONENT_INCOMPATIBLE

	if(ispath(_baby_type, /mob/living))
		baby_type = _baby_type
	else
		stack_trace("Invalid baby_type given to pregnancy component!")
		return COMPONENT_INCOMPATIBLE

	container = thing.loc

	var/obj/item/organ/nads = thing.loc

	if(nads.owner)
		carrier = nads.owner

	if(iscarbon(_father))
		var/mob/living/carbon/cardad = _father
		father_dna = new
		cardad.dna.copy_dna(father_dna)

	if(iscarbon(_mother))
		var/mob/living/carbon/carmom = _mother
		mother_dna = new
		carmom.dna.copy_dna(mother_dna)

	mother_name = _mother.real_name

	if(ishuman(_father))
		var/mob/living/carbon/human/cardad = _father
		LAZYINITLIST(father_features)
		father_features["skin_tone"] = cardad.skin_tone
		father_features["hair_color"] = cardad.hair_color
		father_features["facial_hair_color"] = cardad.facial_hair_color
		father_features["left_eye_color"] = cardad.left_eye_color
		father_features["right_eye_color"] = cardad.right_eye_color

	if(ishuman(_mother))
		var/mob/living/carbon/human/carmom = _mother
		LAZYINITLIST(mother_features)
		mother_features["skin_tone"] = carmom.skin_tone
		mother_features["hair_color"] = carmom.hair_color
		mother_features["facial_hair_color"] = carmom.facial_hair_color
		mother_features["left_eye_color"] = carmom.left_eye_color
		mother_features["right_eye_color"] = carmom.right_eye_color

	pregnancy_inflation = carrier?.client?.prefs?.pregnancy_inflation

	pregnancy_breast_growth = carrier?.client?.prefs?.pregnancy_breast_growth


/datum/component/pregnancy/RegisterWithParent()
	if(carrier)
		register_carrier()

	if(container && !QDELETED(container))
		register_container()
	if(!carrier)
		schedule_external_incubation()
	RegisterSignal(parent, COMSIG_ATOM_ENTERING, PROC_REF(on_entering))
	RegisterSignal(parent, COMSIG_OBJ_BREAK, PROC_REF(on_obj_break))
	RegisterSignal(parent, COMSIG_OBJ_WRITTEN_ON, PROC_REF(name_egg))
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(handle_hatch))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(eg_status))

/datum/component/pregnancy/UnregisterFromParent()
	if(carrier)
		unregister_carrier()
	if(container)
		unregister_container()
	cancel_external_incubation()
	UnregisterSignal(parent, COMSIG_ATOM_ENTERING)
	UnregisterSignal(parent, COMSIG_OBJ_BREAK)
	UnregisterSignal(parent, COMSIG_OBJ_WRITTEN_ON)
	UnregisterSignal(parent, COMSIG_PARENT_ATTACKBY)
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/datum/component/pregnancy/proc/register_carrier()
	if(!carrier || QDELETED(carrier))
		return
	if(coordinator && !QDELETED(coordinator) && coordinator.carrier == carrier)
		return
	var/datum/pregnancy_coordinator/M = carrier.pregnancy_coordinator
	if(!M || QDELETED(M))
		M = new(carrier)
	coordinator = M
	M.add_pregnancy(src)

/datum/component/pregnancy/proc/unregister_carrier()
	if(coordinator && !QDELETED(coordinator))
		coordinator.remove_pregnancy(src)
	coordinator = null

/// Egg tracking follows the *organ*, not just its former owner.
/// No periodic polling: the organ already emits insertion/removal signals.
/datum/component/pregnancy/proc/register_container()
	if(!container || QDELETED(container))
		return
	RegisterSignal(container, COMSIG_ORGAN_INSERTED, PROC_REF(on_container_inserted))
	RegisterSignal(container, COMSIG_ORGAN_REMOVED, PROC_REF(on_container_removed))

/datum/component/pregnancy/proc/unregister_container()
	if(container && !QDELETED(container))
		UnregisterSignal(container, list(COMSIG_ORGAN_INSERTED, COMSIG_ORGAN_REMOVED))

/datum/component/pregnancy/proc/on_container_inserted(datum/source)
	SIGNAL_HANDLER
	if(source != container || QDELETED(container))
		return
	var/mob/living/new_carrier = container.owner
	if(carrier == new_carrier)
		return
	if(carrier)
		unregister_carrier()
	carrier = new_carrier
	if(carrier)
		cancel_external_incubation()
		pregnancy_inflation = carrier.client?.prefs?.pregnancy_inflation
		pregnancy_breast_growth = carrier.client?.prefs?.pregnancy_breast_growth
		register_carrier()

/datum/component/pregnancy/proc/on_container_removed(datum/source)
	SIGNAL_HANDLER
	if(source != container)
		return
	if(carrier)
		unregister_carrier()
	carrier = null
	schedule_external_incubation()

/datum/component/pregnancy/Destroy()
	cancel_external_incubation()
	unregister_carrier()
	return ..()

/datum/component/pregnancy/proc/name_egg(datum/source, name)
	SIGNAL_HANDLER

	egg_name = name

/datum/component/pregnancy/proc/on_climax(datum/source, datum/reagents/senders_cum, atom/target, obj/item/organ/genital/sender, obj/item/organ/genital/receiver, spill)
	SIGNAL_HANDLER

	if(isgenital(container))
		var/obj/item/organ/genital/stuff = container
		if(stuff != sender && stuff.linked_organ != sender)
			return FALSE

	if(stage < 2)
		return FALSE

	//receiver приходит не только гениталией: оральный контакт передаёт сюда желудок,
	//у которого нет genital_flags - откладываем на пол, как и в остальных случаях
	if(isgenital(receiver) && isliving(target))
		if(CHECK_BITFIELD(receiver.genital_flags, GENITAL_CAN_STUFF))
			return lay_eg(receiver, senders_cum)
	return lay_eg(get_turf(carrier), senders_cum)

/datum/component/pregnancy/proc/on_obj_break(datum/source, damage_flag)
	SIGNAL_HANDLER

	qdel(src)

/datum/component/pregnancy/proc/on_entering(datum/source, atom/destination, atom/oldLoc)
	SIGNAL_HANDLER
	var/obj/item/organ/new_container = istype(destination, /obj/item/organ) ? destination : null
	if(new_container == container)
		return

	var/mob/living/new_carrier = new_container?.owner
	if(container)
		unregister_container()
	if(carrier && carrier != new_carrier)
		unregister_carrier()

	container = new_container
	carrier = new_carrier
	if(container)
		register_container()
	if(carrier)
		cancel_external_incubation()
		pregnancy_inflation = carrier.client?.prefs?.pregnancy_inflation
		pregnancy_breast_growth = carrier.client?.prefs?.pregnancy_breast_growth
		register_carrier()
	else
		schedule_external_incubation()

/// Laid eggs and eggs in detached organs still mature without a carrier.
/// Only one stoppable timer per egg is active, and it ends at max_stage.
/datum/component/pregnancy/proc/schedule_external_incubation()
	if(carrier || QDELETED(parent) || stage >= max_stage || external_stage_timer)
		return
	external_stage_timer = addtimer(CALLBACK(src, PROC_REF(advance_external_stage)), max(1, COOLDOWN_TIMELEFT(src, stage_time)), TIMER_STOPPABLE)

/datum/component/pregnancy/proc/cancel_external_incubation()
	if(external_stage_timer)
		deltimer(external_stage_timer)
		external_stage_timer = null

/datum/component/pregnancy/proc/advance_external_stage()
	external_stage_timer = null
	if(carrier || QDELETED(parent) || stage >= max_stage)
		return
	if(COOLDOWN_FINISHED(src, stage_time))
		stage = min(stage + 1, max_stage)
		COOLDOWN_START(src, stage_time, PREGNANCY_STAGE_DURATION)
	schedule_external_incubation()

/datum/component/pregnancy/proc/handle_life(seconds)
	SIGNAL_HANDLER

	var/mob/living/active_carrier = carrier
	if(!active_carrier || QDELETED(active_carrier))
		return

	if(!HAS_TRAIT(active_carrier, TRAIT_COMMON_PREGNANCY)) //For normal pregnancy - Gardelin0
		if(oviposition)
			handle_ovi_preg()
		else
			handle_incubation()

	if((stage >= 2) && !revealed)
		revealed = TRUE
		// Shared statuses are applied once by pregnancy_coordinator.


	if(COOLDOWN_FINISHED(src, stage_time))
		stage += 1
		stage = min(stage, max_stage)
		if(ishuman(active_carrier) && stage >= 2)
			inflate_organs(active_carrier)
		COOLDOWN_START(src, stage_time, PREGNANCY_STAGE_DURATION)

/datum/component/pregnancy/proc/inflate_organs(mob/living/carbon/human/gregnant)
	//var/obj/item/organ/genital/belly/belly = gregnant.getorganslot(ORGAN_SLOT_BELLY)
	if(added_size < 4)
		added_size += 1
	else
		return
	parent.AddComponent(/datum/component/organ_inflation, 1)
	//if(pregnancy_inflation)
	//	belly?.modify_size(1)
	// Shared breast growth is applied by coordinator using the MAX egg stage.

/datum/component/pregnancy/proc/handle_incubation()
	if(carrier && (stage < max_stage) && prob(2))
		to_chat(carrier, span_warning("You feel \The [parent] moving a bit inside you!"))
	if(carrier && (stage == max_stage) && prob(2))
		to_chat(carrier, span_warning("\The [parent] moves, it's probably ready to hatch!"))

/datum/component/pregnancy/proc/handle_hatch(datum/source, obj/item/I, mob/user, params)
	SIGNAL_HANDLER

	if(stage < max_stage)
		return

	var/obj/item/egg = parent
	egg.balloon_alert(user, "Вы пытаетесь вылупить яйцо!")
	INVOKE_ASYNC(src, PROC_REF(hatch), source, I, user, params)

/datum/component/pregnancy/proc/hatch(datum/source, obj/item/I, mob/user, params)
	if(hatch_in_progress || !COOLDOWN_FINISHED(src, hatch_request_cooldown))
		return
	hatch_in_progress = TRUE
	COOLDOWN_START(src, hatch_request_cooldown, 30 SECONDS)

	var/poll_message = "Do you want to play as [mother_name]'s offspring?[egg_name ? " Your name will be [egg_name]" : ""]"
	var/list/mob/candidates = pollGhostCandidates(poll_message, ROLE_RESPAWN, null, FALSE, 30 SECONDS, POLL_IGNORE_EGG, priority_check = FALSE)

	if(QDELETED(src) || QDELETED(parent))
		return
	// If no ghosts volunteer, delivery still completes with an unoccupied mob.
	// This is especially important for the Common Pregnancy birth verb.
	var/mob/player = LAZYLEN(candidates) ? pick(candidates) : null
	var/turf/birth_turf = get_turf(parent)
	if(!birth_turf && carrier && !QDELETED(carrier))
		birth_turf = get_turf(carrier)
	if(!birth_turf)
		hatch_in_progress = FALSE
		if(user && !QDELETED(user))
			to_chat(user, span_warning("Роды не удалось завершить: отсутствует безопасная позиция для ребёнка."))
		return
	if(!player && user && !QDELETED(user))
		to_chat(user, span_notice("Никто не откликнулся на роль ребёнка. Роды завершатся без игрока."))

	playsound(parent, 'sound/effects/splat.ogg', 70, TRUE)
	var/mob/living/babby = new baby_type(birth_turf)

	if(ishuman(babby))
		var/mob/living/carbon/human/babby_human = babby
		determine_baby_features(babby_human)
		determine_baby_dna(babby_human)
		babby_human.updateappearance(mutcolor_update=1)
		babby_human.domutcheck()

	if(player)
		player.transfer_ckey(babby, TRUE)

	to_chat(babby, "You are the son (or daughter) of [mother_name ? mother_name : "someone"]!")

	var/name
	if(egg_name)
		name = egg_name
	else if(user && !QDELETED(user))
		name = input(user, "What will be your baby's name?", "Name the baby") as null|text
	else if(babby.client)
		name = input(babby, "What will be your name?", "Name yourself") as null|text

	if(!name)
		babby.real_name = random_unique_name(babby.gender)
		babby.update_name()
	else
		babby.real_name = name
		babby.update_name()

	if(mother_name)
		babby?.mind?.store_memory("[mother_name] is your mother!")

	var/obj/item = parent
	item.forceMove(birth_turf)
	item.obj_break(MELEE)
	qdel(src)

/datum/component/pregnancy/proc/eg_status(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(stage >= max_stage)
		examine_list += span_notice("\The [parent] seems ready to hatch! You can tap it with something to hatch it")

/datum/component/pregnancy/proc/handle_ovi_preg()
	if(stage <= 2)
		if(stage == 2 && prob(2))
			to_chat(carrier, span_notice("You feel something pressing lightly inside"))
		return
	if(prob(10))
		if(prob(50))
			to_chat(carrier, span_warning("Something presses hard against your anus! It's probably your egg!"))
		else
			to_chat(carrier, span_warning("You REALLY need to get this egg out!"))
		carrier.emote("scream")
		carrier.adjustStaminaLoss(15)

	lay_eg(get_turf(carrier))

/datum/component/pregnancy/proc/lay_eg(atom/location, datum/reagents/senders_cum)
	if(HAS_TRAIT(carrier, TRAIT_COMMON_PREGNANCY)) //For normal pregnancy - Gardelin0
		return

	to_chat(carrier, span_userlove("You feel your egg sliding slowly inside!"))

	if(prob(60))
		return FALSE
	if(isorgan(location))
		var/obj/item/organ/recv = location

		if(!recv.owner)
			return FALSE

	if(container && isgenital(container))
		var/obj/item/organ/genital/gen = container
		if(!(gen.is_exposed() || gen.linked_organ?.is_exposed()))
			return FALSE

	var/obj/item/oviposition_egg/eggo = parent

	eggo.icon_state = carrier.client?.prefs?.egg_shell ? ("egg_" + carrier.client.prefs.egg_shell) : "egg_chicken"
	eggo.update_appearance()

	if(isorgan(location))
		var/obj/item/organ/recv = location
		var/datum/component/genital_equipment/equipment = eggo.GetComponent(/datum/component/genital_equipment)
		equipment.holder_genital = recv
		carrier.visible_message(span_userlove("[carrier] laid an egg!"), \
			span_userlove("You laid an egg inside [recv.owner]'s [recv]"))
	else
		carrier.visible_message(span_notice("[carrier] laid an egg!"), \
			span_nicegreen("The egg came out!"))

	if(senders_cum?.total_volume > 5)
		senders_cum.reaction(location, TOUCH, 1, 0)

	playsound(carrier, 'sound/effects/splat.ogg', 70, TRUE)
	carrier.Knockdown(200, TRUE, TRUE)
	carrier.Stun(200, TRUE, TRUE)
	carrier.adjustStaminaLoss(200)
	SEND_SIGNAL(carrier, COMSIG_ADD_MOOD_EVENT, "pregnancy_end", /datum/mood_event/pregnant_positive)

	oviposition = FALSE
	eggo.forceMove(location)

	return TRUE

// Inherit appearance and DNA from stored parents, never from the hatch initiator.
/datum/component/pregnancy/proc/determine_baby_dna(mob/living/carbon/human/babby)
	if(mother_dna && father_dna)
		mother_dna.transfer_identity_random(father_dna, babby)
	else if(mother_dna && !father_dna)
		mother_dna.transfer_identity_random(babby.dna, babby)
	else if(!mother_dna && father_dna)
		father_dna.transfer_identity_random(babby.dna, babby)

/datum/component/pregnancy/proc/determine_baby_features(mob/living/carbon/human/babby)
	var/list/final_features = list()
	transfer_randomized_list(final_features, mother_features, father_features)
	if(final_features["skin_tone"])
		babby.skin_tone = final_features["skin_tone"]
	if(final_features["hair_color"])
		babby.hair_color = final_features["hair_color"]
	if(final_features["facial_hair_color"])
		babby.facial_hair_color = final_features["facial_hair_color"]
	if(final_features["left_eye_color"])
		babby.left_eye_color = final_features["left_eye_color"]
	if(final_features["right_eye_color"])
		babby.right_eye_color = final_features["right_eye_color"]
	babby.hair_style = pick("Bedhead", "Bedhead 2", "Bedhead 3")
	babby.facial_hair_style = "Shaved"
	babby.underwear = "Nude"
	babby.undershirt = "Nude"
	babby.socks = "Nude"

/datum/component/pregnancy/proc/generic_pragency_start()
	if(revealed)
		carrier.apply_status_effect(/datum/status_effect/pregnancy)
	if(ishuman(carrier))
		human_pragency_start(carrier)
	ADD_TRAIT(carrier, TRAIT_PREGNANT, PREGNANCY_TRAIT)

	// === BLUEMOON ADD ===
	if(HAS_TRAIT(carrier, TRAIT_ESTROUS_ACTIVE))
		SEND_SIGNAL(carrier, COMSIG_PREGNANCY_STARTED)

/datum/component/pregnancy/proc/generic_pragency_end()
	REMOVE_TRAIT(carrier, TRAIT_PREGNANT, PREGNANCY_TRAIT)
	carrier.remove_status_effect(/datum/status_effect/pregnancy)
	if(ishuman(carrier))
		human_pragency_end(carrier)

	// BLUEMOON ADD
	SEND_SIGNAL(carrier, COMSIG_PREGNANCY_ENDED)

/datum/component/pregnancy/proc/human_pragency_start(mob/living/carbon/human/gregnant)
	if(pregnancy_breast_growth)
		var/obj/item/organ/genital/breasts/boob = gregnant.getorganslot(ORGAN_SLOT_BREASTS)
		if(!boob)
			boob = gregnant.give_genital(/obj/item/organ/genital/breasts)
	return TRUE

/datum/component/pregnancy/proc/human_pragency_end(mob/living/carbon/human/gregnant)
	SEND_SIGNAL(gregnant, COMSIG_CLEAR_MOOD_EVENT, "pregnancy")

/datum/component/pregnancy/proc/fetus_mortus()
	SIGNAL_HANDLER

	if(!carrier || QDELETED(carrier))
		qdel(src)
		return
	if(get_turf(carrier) && stage >= 2)
		if(!oviposition)
			new /obj/effect/gibspawner/generic(get_turf(carrier))
		else
			new /obj/effect/decal/cleanable/egg_smudge(get_turf(carrier))
	carrier.Knockdown(200, TRUE, TRUE)
	carrier.Stun(200, TRUE, TRUE)
	carrier.adjustStaminaLoss(200)
	carrier.visible_message(span_danger("[carrier] has a miscarriage!"), \
						span_userdanger("Oh no! My baby is dead!"))
	qdel(src)

/datum/component/pregnancy/proc/on_scan(datum/source, mob/user)
	SIGNAL_HANDLER
	to_chat(user, span_notice("<b>Pregnancy detected!</b>"))

//drop kicked
/datum/component/pregnancy/proc/handle_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

	if(def_zone == BODY_ZONE_PRECISE_GROIN && damagetype == BRUTE && damage > 5 && prob(40))
		fetus_mortus()

/datum/surgery/advanced/revival
	name = "Revival"
	desc = "Экспериментальная хирургическая процедура, которая включает в себя реконструкцию и реактивацию мозга пациента даже спустя долгое время после смерти. Организм должен оставаться в состоянии поддерживать жизнедеятельность. Обеспечивает минимальное функционирование всем органам пораженным некрозом."
	steps = list(/datum/surgery_step/incise,
				/datum/surgery_step/retract_skin,
				/datum/surgery_step/saw,
				/datum/surgery_step/clamp_bleeders,
				/datum/surgery_step/incise,
				/datum/surgery_step/revive,
				/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = 0
	icon = 'icons/obj/defibrillators.dmi'
	icon_state = "defibpaddles0"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY

/datum/surgery/advanced/revival/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(!..())
		return FALSE
	if(target.stat != DEAD)
		return FALSE
	if(target.suiciding || HAS_TRAIT(target, TRAIT_NOCLONE) || target.hellbound)
		return FALSE
	var/obj/item/organ/brain/B = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(!B)
		return FALSE
	return TRUE

/datum/surgery_step/revive
	name = "Провести Электрическую Стимуляцию Мозга"
	implements = list(/obj/item/shockpaddles = 100, /obj/item/abductor/gizmo = 100, /obj/item/rod_of_asclepius = 100, /obj/item/melee/baton = 75, /obj/item/organ/cyberimp/arm/baton = 75, /obj/item/organ/cyberimp/arm/gun/taser = 60, /obj/item/gun/energy/e_gun/advtaser = 60, /obj/item/gun/energy/taser = 60)
	time = 120
	success_sound = 'sound/magic/lightningbolt.ogg'
	failure_sound = 'sound/magic/lightningbolt.ogg'

/datum/surgery_step/revive/tool_check(mob/user, obj/item/tool)
	. = TRUE
	if(istype(tool, /obj/item/shockpaddles))
		var/obj/item/shockpaddles/S = tool
		if((S.req_defib && !S.defib.powered) || !S.wielded || S.cooldown || S.busy)
			to_chat(user, "<span class='warning'>You need to wield both paddles, and [S.defib] must be powered!</span>")
			return FALSE
	if(istype(tool, /obj/item/melee/baton))
		var/obj/item/melee/baton/B = tool
		if(!B.turned_on)
			to_chat(user, "<span class='warning'>[B] needs to be active!</span>")
			return FALSE
	if(istype(tool, /obj/item/gun/energy))
		var/obj/item/gun/energy/E = tool
		if(E.chambered && istype(E.chambered, /obj/item/ammo_casing/energy/electrode))
			return TRUE
		else
			to_chat(user, "<span class='warning'>You need an electrode for this!</span>")
			return FALSE

/datum/surgery_step/revive/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You prepare to give [target]'s brain the spark of life with [tool].</span>",
		"[user] prepares to shock [target]'s brain with [tool].",
		"[user] prepares to shock [target]'s brain with [tool].")
	target.notify_ghost_cloning("Someone is trying to zap your brain. Re-enter your corpse if you want to be revived!", source = target)

/datum/surgery_step/revive/play_preop_sound(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(istype(tool, /obj/item/shockpaddles))
		playsound(tool, 'sound/machines/defib_charge.ogg', 75, 0)
	else
		..()

/datum/surgery_step/revive/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>You successfully shock [target]'s brain with [tool]...</span>",
		"[user] send a powerful shock to [target]'s brain with [tool]...",
		"[user] send a powerful shock to [target]'s brain with [tool]...")
	target.adjustOxyLoss(-50, 0)
	target.updatehealth()
	if(target.revive())
		user.visible_message("...[target] wakes up, alive and aware!", "<span class='notice'><b>IT'S ALIVE!</b></span>")
		target.visible_message("...[target] wakes up, alive and aware!")
		target.emote("gasp")
		target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 50, 199) //MAD SCIENCE
		for(var/obj/item/organ/O in target.internal_organs)//zap those buggers back to life!
			if(O.organ_flags & ORGAN_FAILING)
				O.applyOrganDamage(-5)
		// BLUEMOON EDIT START - изменение памяти после смерти
		target.mind?.revival_handle_memory("surgical revival")
		// BLUEMOON EDIT END
		return TRUE
	else
		user.visible_message("...[target.ru_who()] convulses, then lies still.")
		target.visible_message("...[target.ru_who()] convulses, then lies still.")
		return FALSE

/datum/surgery_step/revive/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	display_results(user, target, "<span class='notice'>You shock [target]'s brain with [tool], but [target.ru_who()] doesn't react.</span>",
		"[user] send a powerful shock to [target]'s brain with [tool], but [target.ru_who()] doesn't react.",
		"[user] send a powerful shock to [target]'s brain with [tool], but [target.ru_who()] doesn't react.")
	target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 15, 199)

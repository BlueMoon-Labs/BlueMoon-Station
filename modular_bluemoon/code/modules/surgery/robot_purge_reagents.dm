/***
 * Убирает все реагенты из ((крови)) синтетика, что может очень помочь, например, в передозировке систем клинером / синтанолом
***/

/datum/surgery/robot_purge_reagents
	name = "Emergency Reagents Disposal"
	desc = "Операция по удалению всех реагентов в системе робота на случай загрязнения инородными субстанциями."
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(
			/datum/surgery_step/mechanic_open,
			/datum/surgery_step/open_hatch,
			/datum/surgery_step/mechanic_unwrench,
			/datum/surgery_step/prepare_electronics,
			/datum/surgery_step/override_safeties,
			/datum/surgery_step/unscrew_liver_hatch,
			/datum/surgery_step/eject_reagents,
			/datum/surgery_step/mechanic_wrench,
			/datum/surgery_step/mechanic_close)
	possible_locs = list(BODY_ZONE_CHEST)
	target_mobtypes = list(/mob/living/carbon/human)
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "multitool_yellow"
	radial_priority = SURGERY_RADIAL_PRIORITY_HEAL_ADDITIONAL

/datum/surgery/robot_purge_reagents/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	. = ..()
	if(!.)
		return
	var/obj/item/organ/liver/liver = target.getorganslot(ORGAN_SLOT_LIVER)
	if(isrobotic(target) && liver && IS_ROBOTIC_ORGAN(liver))
		return TRUE
	return FALSE


/datum/surgery_step/unscrew_liver_hatch
	name = "Открутить клапан процессора реагентов"
	implements = list(TOOL_SCREWDRIVER = 95, TOOL_HEMOSTAT = 35, TOOL_WIRECUTTER = 30, /obj/item/pen = 15)
	time = 25
	preop_sound = 'sound/items/screwdriver.ogg'
	success_sound = 'sound/items/screwdriver2.ogg'

/datum/surgery_step/unscrew_liver_hatch/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>Вы начинаете откручивать клапан системы обработки реагентов [target]...</span>",
		"[user] откручивает клапан на одной из трубок в груди [target].",
		"[user] begins to perform surgery on [target].")

/datum/surgery_step/unscrew_liver_hatch/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/liver/liver = target.getorganslot(ORGAN_SLOT_LIVER)
	if(!liver || !isrobotic(target))
		user.visible_message("<span class='warning'>[user] не находит систему обработки реагентов в груди [target]...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] отсутствует.</span>")
		return FALSE
	if(!IS_ROBOTIC_ORGAN(liver))
		user.visible_message("<span class='warning'>[user] обнаруживает несовместимость обработчика реагентов [target] с известными методиками очистки...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] не подходит для очистки.</span>")
		return FALSE
	display_results(user, target, "<span class='notice'>Вы успешно откручиваете клапан резервуара с реагентами [target]...</span>",
		"[user] успешно откручивает клапан в груди [target].",
		"[user] completes the surgery on [target].")
	return TRUE

/datum/surgery_step/unscrew_liver_hatch/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/liver/liver = target.getorganslot(ORGAN_SLOT_LIVER)
	if(!liver || !isrobotic(target))
		user.visible_message("<span class='warning'>[user] не находит систему обработки реагентов в груди [target]...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] отсутствует.</span>")
		return FALSE
	if(!IS_ROBOTIC_ORGAN(liver))
		user.visible_message("<span class='warning'>[user] обнаруживает несовместимость обработчика реагентов [target] с известными методиками очистки...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] не подходит для очистки.</span>")
		return FALSE
	. = ..()
	display_results(user, target, "<span class='warning'>Ваша отвёртка срывается и [target] вздрагивает всем корпусом, когда в [target.ru_na()] обработчике реагентов появляется новая пробоина...</span>",
	"[user] неудачно отсверливает клапан у обработчика реагентов [target], повреждая [target.ru_na()] систему.",
	"[user] completes the surgery on [target].")
	target.adjustOrganLoss(ORGAN_SLOT_LIVER, 20)
	playsound(target, 'modular_bluemoon/krashly/sound/items/watersplash.ogg', 40, 1)


/datum/surgery_step/eject_reagents
	name = "Открыть люк сброса реагентов"
	implements = list(TOOL_MULTITOOL = 95, TOOL_HEMOSTAT = 25, TOOL_CROWBAR = 25)
	time = 40
	preop_sound = 'sound/machines/doorclick.ogg'

/datum/surgery_step/eject_reagents/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, "<span class='notice'>Вы начинаете открывать люк на резервуаре с реагентами в груди [target]...</span>",
		"[user] начинает открывать люк сброса реагентов у [target].",
		"[user] begins to perform surgery on [target].")

/datum/surgery_step/eject_reagents/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/liver/liver = target.getorganslot(ORGAN_SLOT_LIVER)
	if(!liver || !isrobotic(target))
		user.visible_message("<span class='warning'>[user] не находит систему обработки реагентов в груди [target]...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] отсутствует.</span>")
		return FALSE
	if(!IS_ROBOTIC_ORGAN(liver))
		user.visible_message("<span class='warning'>[user] обнаруживает несовместимость обработчика реагентов [target] с известными методиками очистки...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] не подходит для очистки.</span>")
		return FALSE
	display_results(user, target, "<span class='notice'>Вы успешно открываете люк сброса реагентов у [target], высвобождая хранящиеся там реагенты...</span>",
		"[user] успешно открывает люк в груди [target], выплёскивая оттуда реагенты.",
		"[user] completes the surgery on [target].")
	playsound(target, 'sound/effects/splash.ogg', 70, TRUE, 1)
	if(target.reagents)
		target.reagents.clear_reagents()
	new /obj/effect/decal/cleanable/oil/streak(get_turf(target))
	return TRUE

/datum/surgery_step/eject_reagents/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/liver/liver = target.getorganslot(ORGAN_SLOT_LIVER)
	if(!liver || !isrobotic(target))
		user.visible_message("<span class='warning'>[user] не находит систему обработки реагентов в груди [target]...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] отсутствует.</span>")
		return FALSE
	if(!IS_ROBOTIC_ORGAN(liver))
		user.visible_message("<span class='warning'>[user] обнаруживает несовместимость обработчика реагентов [target] с известными методиками очистки...", "<span class='warning'>Вы понимаете, что система обработки реагентов [target] не подходит для очистки.</span>")
		return FALSE
	. = ..()
	display_results(user, target, "<span class='warning'>Вы слишком сильно нажимаете ломом и крышка процессора реагентов [target] отламывается, а часть жидкости, вылившаяся на [target.ru_na()] микросхемы вызывает короткое замыкание!</span>",
	"<span class='warning'>[user] случайно ломает люк резервуара с реагентами в груди [target], вызывая короткое замыкание от вылившихся реагентов.",
	"[user] completes the surgery on [target].")
	target.adjustOrganLoss(ORGAN_SLOT_LIVER, 35)
	playsound(target, 'sound/effects/bang.ogg', 50, 1)
	playsound(target, 'sound/effects/splat.ogg', 10, TRUE)
	do_sparks(10, 5, target)
	target.adjustFireLoss(20)
	target.jitteriness += 10

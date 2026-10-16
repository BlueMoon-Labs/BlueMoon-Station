#define HK47_DISGUISE_GREET_COOLDOWN (20 SECONDS)

/// Маскировка HK под протокольного дроида: имя, голос и корпус HK-50, пока дроид не стреляет и не бьёт.
/datum/component/hk47_disguise
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/active = FALSE
	var/datum/action/innate/hk47_disguise/button
	/// Карта из слота ID на время маскировки лежит в корпусе: по ней дроида узнали бы СБ-HUD и осмотр.
	var/obj/item/stowed_id
	COOLDOWN_DECLARE(reenable_cooldown)
	COOLDOWN_DECLARE(greet_cooldown)

/datum/component/hk47_disguise/Initialize()
	if(!is_species(parent, /datum/species/ipc/hk))
		return COMPONENT_INCOMPATIBLE

/datum/component/hk47_disguise/RegisterWithParent()
	button = new(src)
	button.Grant(parent)
	RegisterSignals(parent, list(COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_SET_AS_ATTACKER), PROC_REF(on_hostile_act))
	RegisterSignal(parent, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/component/hk47_disguise/UnregisterFromParent()
	drop(silent = TRUE)
	UnregisterSignal(parent, list(COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_PARENT_EXAMINE, COMSIG_LIVING_DEATH))
	QDEL_NULL(button)

/datum/component/hk47_disguise/proc/toggle()
	if(active)
		return drop()
	return enable()

/datum/component/hk47_disguise/proc/enable()
	var/mob/living/carbon/human/droid = parent
	if(active)
		return FALSE
	if(droid.stat != CONSCIOUS)
		return FALSE
	if(!COOLDOWN_FINISHED(src, reenable_cooldown))
		to_chat(droid, span_warning("Утверждение: маскировочные протоколы перезапускаются, ещё [DisplayTimeText(COOLDOWN_TIMELEFT(src, reenable_cooldown))]."))
		return FALSE
	active = TRUE
	ADD_TRAIT(droid, TRAIT_HK47_DISGUISED, REF(src))
	ADD_TRAIT(droid, TRAIT_DISFIGURED, REF(src))
	stow_id(droid)
	droid.name_override = HK47_DISGUISE_NAME
	droid.SetSpecialVoice(HK47_DISGUISE_NAME)
	droid.name = droid.get_visible_name()
	set_chassis_model(HK_MODEL_50)
	droid.sec_hud_set_ID()
	hk47_upgrade_voice(droid, "hk47_stealth")
	to_chat(droid, span_notice("Утверждение: маскировка включена. Для окружающих вы - [HK47_DISGUISE_NAME], карта ID убрана в корпус, СБ-HUD вас не узнаёт. Выстрел или атака сорвут маскировку."))
	return TRUE

/// broken - сорвана выстрелом или атакой: повтор только после паузы.
/datum/component/hk47_disguise/proc/drop(broken = FALSE, silent = FALSE)
	if(!active)
		return FALSE
	var/mob/living/carbon/human/droid = parent
	active = FALSE
	REMOVE_TRAIT(droid, TRAIT_HK47_DISGUISED, REF(src))
	REMOVE_TRAIT(droid, TRAIT_DISFIGURED, REF(src))
	if(droid.name_override == HK47_DISGUISE_NAME)
		droid.name_override = null
	if(droid.GetSpecialVoice() == HK47_DISGUISE_NAME)
		droid.UnsetSpecialVoice()
	INVOKE_ASYNC(src, PROC_REF(restore_id), droid)
	if(QDELETED(droid))
		return TRUE
	droid.name = droid.get_visible_name()
	droid.sec_hud_set_ID()
	set_chassis_model(null)
	if(broken)
		COOLDOWN_START(src, reenable_cooldown, HK47_DISGUISE_COOLDOWN)
	if(silent)
		return TRUE
	if(broken)
		droid.visible_message(span_danger("Протокольный дроид сбрасывает маскировку: это [droid]!"), span_warning("Утверждение: маскировка сорвана. Повтор - через [DisplayTimeText(HK47_DISGUISE_COOLDOWN)]."))
	else
		to_chat(droid, span_notice("Утверждение: маскировка снята."))
	return TRUE

/datum/component/hk47_disguise/proc/stow_id(mob/living/carbon/human/droid)
	var/obj/item/card = droid.wear_id
	if(!card || !droid.temporarilyRemoveItemFromInventory(card, idrop = FALSE))
		return
	card.moveToNullspace()
	stowed_id = card
	RegisterSignal(card, COMSIG_PARENT_QDELETING, PROC_REF(on_stowed_id_deleted))

/datum/component/hk47_disguise/proc/restore_id(mob/living/carbon/human/droid)
	var/obj/item/card = stowed_id
	if(!card)
		return
	UnregisterSignal(card, COMSIG_PARENT_QDELETING)
	stowed_id = null
	if(QDELETED(droid))
		var/turf/drop_turf = get_turf(droid)
		if(drop_turf)
			card.forceMove(drop_turf)
		else
			qdel(card)
		return
	if(!droid.equip_to_slot_if_possible(card, ITEM_SLOT_ID, disable_warning = TRUE) && !droid.put_in_hands(card))
		card.forceMove(droid.drop_location())
	droid.sec_hud_set_ID()

/datum/component/hk47_disguise/proc/on_stowed_id_deleted(datum/source)
	SIGNAL_HANDLER
	stowed_id = null

/// null - вернуть родную модель шасси.
/datum/component/hk47_disguise/proc/set_chassis_model(model)
	var/mob/living/carbon/human/droid = parent
	var/datum/species/ipc/hk/chassis = droid.dna?.species
	if(!istype(chassis))
		return
	var/new_model = model || initial(chassis.hk_model)
	chassis.hk_model = new_model
	chassis.limbs_id = new_model
	chassis.mutant_bodyparts["limbs_id"] = new_model
	droid.update_body_parts()
	droid.update_body()

/// Выстрел, удар предметом или нападение: у всех трёх сигналов второй аргумент - жертва.
/datum/component/hk47_disguise/proc/on_hostile_act(datum/source, atom/victim)
	SIGNAL_HANDLER
	if(victim != parent)
		drop(broken = TRUE)

/datum/component/hk47_disguise/proc/on_unarmed_attack(mob/living/carbon/human/source, atom/target)
	SIGNAL_HANDLER
	if(source.a_intent == INTENT_HARM && (isliving(target) || isobj(target)))
		drop(broken = TRUE)

/datum/component/hk47_disguise/proc/on_death(datum/source)
	SIGNAL_HANDLER
	drop(silent = TRUE)

/datum/component/hk47_disguise/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!active || user == parent || get_dist(user, parent) > HK47_DISGUISE_GREET_RANGE)
		return
	if(!COOLDOWN_FINISHED(src, greet_cooldown))
		examine_list += span_notice("Протокольный дроид учтиво склоняет голову.")
		return
	COOLDOWN_START(src, greet_cooldown, HK47_DISGUISE_GREET_COOLDOWN)
	examine_list += span_notice("Протокольный дроид учтиво склоняет голову: «Приветствие: здравствуйте, потенциальный покупатель. Чем этот скромный дроид может вам служить?»")
	hk47_upgrade_voice(parent, "hk47_prospective")

/datum/action/innate/hk47_disguise
	name = "Protocol Droid Disguise"
	desc = "Включить или снять маскировку под протокольного дроида: другое имя и голос, корпус HK-50, карта ID убрана в корпус, пеленгатор и СБ-HUD вас не узнают. Выстрел или атака срывают её, после этого - пауза."
	icon_icon = 'modular_bluemoon/icons/mob/hk_droids/hk50.dmi'
	button_icon_state = "hk50"
	background_icon_state = "bg_tech"

/datum/action/innate/hk47_disguise/Activate()
	var/datum/component/hk47_disguise/disguise = target
	disguise.toggle()

#undef HK47_DISGUISE_GREET_COOLDOWN

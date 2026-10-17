/datum/species/ipc/hk
	name = "HK Droid"
	id = SPECIES_HK
	blacklisted = TRUE
	say_mod = "states"
	armor = HK_ARMOR
	punchdamagelow = 10
	punchdamagehigh = 19
	punchstunthreshold = 14
	species_traits = list(NOEYES, NOTRANSSTING, HAS_FLESH, HAS_BONE, ROBOTIC_LIMBS, NOGENITALS, NOAROUSAL)
	mutant_bodyparts = list()
	nojumpsuit = TRUE
	no_equip = list(ITEM_SLOT_ICLOTHING, ITEM_SLOT_OCLOTHING, ITEM_SLOT_HEAD)
	mutanteyes = /obj/item/organ/eyes/ipc/hk
	mutanttongue = /obj/item/organ/tongue/robot/ipc/hk
	limbs_id = "ipc"
	var/hk_model
	COOLDOWN_DECLARE(emp_stun_cooldown)

/datum/species/ipc/hk/New()
	. = ..()
	inherent_traits -= TRAIT_EASYDISMEMBER
	inherent_traits |= list(TRAIT_NODISMEMBER, TRAIT_LOWPRESSURECOOLING)

/datum/species/ipc/hk/on_species_gain(mob/living/carbon/human/droid, datum/species/old_species, pref_load)
	. = ..()
	QDEL_NULL(screen)
	QDEL_NULL(designation)
	RegisterSignal(droid, COMSIG_MOB_SAY, PROC_REF(on_say))
	RegisterSignal(droid, COMSIG_LIVING_SEND_SPEECH, PROC_REF(on_send_speech))
	RegisterSignal(droid, COMSIG_HK_MASTER_CHANGED, PROC_REF(on_master_changed))
	RegisterSignal(droid, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	if(hk_model)
		var/obj/effect/dummy/lighting_obj/moblight/hk_eyes/glow = new(droid)
		glow.set_light_on(eyes_lit(droid))

/datum/species/ipc/hk/on_species_loss(mob/living/carbon/human/droid, datum/species/new_species, pref_load)
	UnregisterSignal(droid, list(COMSIG_MOB_SAY, COMSIG_LIVING_SEND_SPEECH, COMSIG_HK_MASTER_CHANGED, COMSIG_PARENT_EXAMINE))
	qdel(locate(/obj/effect/dummy/lighting_obj/moblight/hk_eyes) in droid)
	return ..()

/datum/species/ipc/hk/spec_emp_act(mob/living/carbon/human/droid, severity)
	if(droid.stat == DEAD || !COOLDOWN_FINISHED(src, emp_stun_cooldown))
		return
	COOLDOWN_START(src, emp_stun_cooldown, HK_EMP_STUN_COOLDOWN)
	var/stun_time = severity >= HK_EMP_HEAVY_SEVERITY ? HK_EMP_HEAVY_STUN : HK_EMP_LIGHT_STUN
	droid.Paralyze(stun_time)
	emp_blackout = TRUE
	refresh_eyes(droid)
	addtimer(CALLBACK(src, PROC_REF(end_emp_blackout), WEAKREF(droid)), stun_time, TIMER_UNIQUE | TIMER_OVERRIDE)
	droid.visible_message(span_warning("[droid] искрит, фотоприёмники гаснут: ЭМИ отключил шасси."), span_userdanger("ЭМИ отключил приводы шасси!"))

/datum/species/ipc/hk/proc/end_emp_blackout(datum/weakref/droid_ref)
	emp_blackout = FALSE
	var/mob/living/carbon/human/droid = droid_ref.resolve()
	if(droid?.dna?.species == src)
		refresh_eyes(droid)

/datum/species/ipc/hk/proc/on_master_changed(mob/living/carbon/human/source, datum/mind/new_master, datum/mind/old_master)
	SIGNAL_HANDLER
	if(!new_master || !recolor_on_reprogram || eyes_reprogrammed)
		return
	eyes_reprogrammed = TRUE
	source.update_body()

/datum/species/ipc/hk/proc/on_examine(mob/living/carbon/human/droid, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(HAS_TRAIT(droid, TRAIT_HK47_DISGUISED))
		return
	if(eyes_reprogrammed && eyes_lit(droid))
		examine_list += span_notice("Фотоприёмники светятся голубым: блок лояльности перепрошит.")
	if(user != droid && is_hk_droid_disabled(droid))
		examine_list += span_notice("Дроид обездвижен, сервисная панель блока лояльности доступна: его можно перепрошить операцией на голове (нужен мультитул) или чипом лояльности с фабрики HK.")
	if(hk_can_read_loyalty(user))
		var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
		var/datum/mind/master = loyalty?.get_master()
		examine_list += span_notice("Блок лояльности: [master ? "хозяин - [master.name]" : "хозяин не задан"].")

/// Блок лояльности читают робототехники и все, кто видит диагностический HUD.
/proc/hk_can_read_loyalty(mob/user)
	if(user.mind?.assigned_role in HK_LOYALTY_READER_JOBS)
		return TRUE
	for(var/hud_type in list(DATA_HUD_DIAGNOSTIC_BASIC, DATA_HUD_DIAGNOSTIC_ADVANCED))
		var/datum/atom_hud/diagnostic = GLOB.huds[hud_type]
		if(diagnostic.hudusers[user])
			return TRUE
	return FALSE

/datum/species/ipc/hk/proc/on_say(mob/living/carbon/human/source, list/speech_args)
	SIGNAL_HANDLER
	speech_args[SPEECH_MESSAGE] = hk_speech_prefix(speech_args[SPEECH_MESSAGE])

/datum/species/ipc/hk/proc/hk_speech_prefix(message)
	if(!length(message))
		return message
	for(var/prefix in list(HK_PREFIX_STATEMENT, HK_PREFIX_QUERY, HK_PREFIX_EXCLAMATION, HK_PREFIX_ANALYSIS))
		if(findtext(message, prefix) == 1)
			return message
	var/last_char = copytext_char(message, -1)
	var/prefix = HK_PREFIX_STATEMENT
	if(last_char == "?")
		prefix = HK_PREFIX_QUERY
	else if(last_char == "!")
		prefix = HK_PREFIX_EXCLAMATION
	return "[prefix] [message]"

/datum/species/ipc/hk/hk47
	name = "HK-47"
	id = SPECIES_HK47
	hk_model = HK_MODEL_47
	limbs_id = HK_MODEL_47
	override_bp_icon = 'modular_bluemoon/icons/mob/human/hk_droid.dmi'

/datum/species/ipc/hk/hk47/on_species_gain(mob/living/carbon/human/droid, datum/species/old_species, pref_load)
	. = ..()
	if(droid.physiology)
		droid.physiology.stamina_mod *= HK47_STAMINA_MOD

/datum/species/ipc/hk/hk47/on_species_loss(mob/living/carbon/human/droid, datum/species/new_species, pref_load)
	if(droid.physiology)
		droid.physiology.stamina_mod /= HK47_STAMINA_MOD
	return ..()

/datum/species/ipc/hk/hk50
	name = "HK-50"
	id = SPECIES_HK50
	armor = HK50_ARMOR
	hk_model = HK_MODEL_50
	limbs_id = HK_MODEL_50
	override_bp_icon = 'modular_bluemoon/icons/mob/human/hk_droid.dmi'

/datum/species/ipc/hk/hk51
	name = "HK-51"
	id = SPECIES_HK51
	punchstunthreshold = HK51_PUNCH_STUN_THRESHOLD
	recolor_on_reprogram = FALSE
	hk_model = HK_MODEL_51
	limbs_id = HK_MODEL_51
	override_bp_icon = 'modular_bluemoon/icons/mob/human/hk_droid.dmi'

/obj/item/organ/eyes/ipc/hk
	name = "HK photoreceptors"
	desc = "Оптика дроида серии HK со встроенным светофильтром: вспышки её не слепят. Пока дроид работает, фотоприёмники светятся и видны даже в темноте; ЭМИ гасит их, пока шасси отключено, а у перепрошитых HK-47 и HK-50 они светятся голубым."
	flash_protect = 1

/obj/item/organ/tongue/robot/ipc/hk
	name = "HK vocabulator"
	desc = "Вокабулятор дроида серии HK: сухой металлический голос без капли интонации."
	say_mod = "states"
	say_mod_ru = "констатирует"

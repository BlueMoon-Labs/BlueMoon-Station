#define HERETIC_STARTER_ESSENCE_VOLUME 10

/datum/antagonist/heretic
	var/starter_essence_given = FALSE

/datum/antagonist/heretic/proc/give_starter_essence(mob/living/carbon/user)
	if(starter_essence_given || role_removed || QDELETED(user) || owner?.current != user)
		return
	starter_essence_given = TRUE
	var/obj/item/reagent_containers/hypospray/medipen/eldritch/injector = new(get_turf(user))
	var/where = user.equip_in_one_of_slots(injector, list("рюкзак" = ITEM_SLOT_BACKPACK, "левый карман" = ITEM_SLOT_LPOCKET, "правый карман" = ITEM_SLOT_RPOCKET), qdel_on_fail = FALSE)
	if(!where)
		where = user.put_in_hands(injector) ? "в руках" : "на полу под вами"
	to_chat(user, span_notice("Стартовый инъектор эссенции ([HERETIC_STARTER_ESSENCE_VOLUME]u): [where]. Примените его на себя перед боем: он лечит повреждения, восстанавливает выносливость и сокращает оглушение, но не защищает от новых попаданий. Работает и у синтетиков. Обычную эссенцию можно изготовить через «Ритуал священника» в кодексе; она предназначена для органического тела. Пустой инъектор выдаёт еретика: не выбрасывайте его там, где его найдут."))
	log_game("[key_name(user)] получает стартовый инъектор эссенции ([HERETIC_STARTER_ESSENCE_VOLUME]u), место: [where].")

/obj/item/reagent_containers/hypospray/medipen/eldritch
	name = "eldritch essence autoinjector"
	desc = "Одноразовый инъектор с 10 единицами стабилизированной эссенции. Примените на себя перед боем: при каждом усвоении эссенция лечит по 6 ушибов, ожогов, токсинов и удушья, восстанавливает 30 выносливости и сокращает обездвиживание на 8 секунд. Работает у органических и синтетических еретиков, даже через одежду. Не защищает от новых попаданий; для непосвящённых это яд. Обычная ритуальная эссенция не удваивает лечение и подходит только органическому телу. Пустой инъектор с чужим знаком выдаёт владельца: экипаж узнаёт его и снимает с него волокна, так что не бросайте его где попало."
	icon = 'modular_bluemoon/icons/obj/heretic_relics.dmi'
	icon_state = "eldritchpen"
	item_state = "syndipen"
	volume = HERETIC_STARTER_ESSENCE_VOLUME
	amount_per_transfer_from_this = HERETIC_STARTER_ESSENCE_VOLUME
	list_reagents = list(/datum/reagent/eldritch/stabilized = HERETIC_STARTER_ESSENCE_VOLUME)

/obj/item/reagent_containers/hypospray/medipen/eldritch/cyborg_recharge(mob/living/silicon/robot/user)
	return

/datum/reagent/eldritch/stabilized
	name = "Stabilized Eldritch Essence"
	description = "Стабилизированная эссенция для органических и синтетических еретиков."
	chemical_flags = REAGENT_ALL_PROCESS
	self_consuming = TRUE
	can_synth = FALSE

/datum/mind
	var/heretic_escape_ready_at = 0

/datum/action/item_action/heretic_escape
	name = "Разбить клинок и отступить"
	desc = "Разбейте клинок в руке, чтобы перенестись в случайное безопасное место. Клинок будет потерян. Применяйте до оглушения или потери сознания. Между побегами проходит не меньше 10 секунд; запрет телепортации, наручники, смирительная рубашка и щит разума мешают побегу."
	check_flags = AB_CHECK_RESTRAINED|AB_CHECK_STUN|AB_CHECK_CONSCIOUS

/datum/action/item_action/heretic_escape/Grant(mob/user)
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return ..()
	Remove(owner)

/datum/action/item_action/heretic_escape/Trigger(trigger_flags)
	if(!IsAvailable(TRUE))
		var/obj/item/melee/sickly_blade/blade = target
		if(!QDELETED(owner) && !QDELETED(blade))
			blade.escape_failure(owner, (blade in owner.held_items) ? "Сейчас вы не можете разбить клинок." : "Возьмите клинок в руку.")
		return FALSE
	return ..()

/datum/action/item_action/heretic_escape/IsAvailable(silent = FALSE)
	if(!..())
		return FALSE
	var/obj/item/melee/sickly_blade/blade = target
	return !QDELETED(blade) && (blade in owner.held_items) && !blade.escape_in_progress && !owner.incapacitated() && (IS_HERETIC(owner) || IS_HERETIC_MONSTER(owner))

/obj/item/melee/sickly_blade
	COOLDOWN_DECLARE(escape_failure_log_cooldown)

/obj/item/melee/sickly_blade/proc/escape_failure(mob/user, reason)
	to_chat(user, span_warning("[reason] Клинок остаётся целым."))
	if(COOLDOWN_FINISHED(src, escape_failure_log_cooldown))
		log_game("HERETIC ESCAPE: [key_name(user)] failed with [src] at [AREACOORD(user)]: [reason]")
		COOLDOWN_START(src, escape_failure_log_cooldown, 5 SECONDS)

#undef HERETIC_STARTER_ESSENCE_VOLUME

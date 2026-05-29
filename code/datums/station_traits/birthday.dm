// С днем рождения милли коч!!
/datum/station_trait/birthday
	name = "День Рождения Сотрудника"
	trait_type = STATION_TRAIT_NEUTRAL
	weight = 2
	show_in_report = TRUE
	report_message = "Пакт поздравляет Сотрудника с днём рождения"
	trait_to_give = STATION_TRAIT_BIRTHDAY
	blacklist = list(/datum/station_trait/announcement_intern, /datum/station_trait/announcement_medbot) //Переопределение диктора скрывает имя именинника в сообщении.
	/// Ссылка на именинника
	var/mob/living/carbon/human/birthday_person
	/// Имя именинника на момент выбора
	var/birthday_person_name = ""
	/// Оверрайд именника для админов.
	var/birthday_override_ckey

/datum/station_trait/birthday/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_after_spawn))

/datum/station_trait/birthday/revert()
	return ..()

/datum/station_trait/birthday/on_round_start()
	. = ..()
	if(birthday_override_ckey)
		if(!check_valid_override())
			message_admins("Попытка назначить [birthday_override_ckey] именинником провалилась: игрок не является действительным членом экипажа. Будет выбран случайный именинник.")

	if(!birthday_person)
		var/list/birthday_options = list()
		for(var/mob/living/carbon/human/human in GLOB.human_list)
			if(human.mind && human.job)
				birthday_options += human
		if(length(birthday_options))
			birthday_person = pick(birthday_options)
			birthday_person_name = birthday_person.real_name
			ADD_TRAIT(birthday_person, TRAIT_BIRTHDAY_BOY, REF(src))
	addtimer(CALLBACK(src, PROC_REF(announce_birthday)), 10 SECONDS)

/datum/station_trait/birthday/proc/check_valid_override()
	var/mob/living/carbon/human/birthday_override_mob = get_mob_by_ckey(birthday_override_ckey)

	if(isnull(birthday_override_mob))
		return FALSE

	if(birthday_override_mob.mind && birthday_override_mob.job)
		birthday_person = birthday_override_mob
		birthday_person_name = birthday_person.real_name
		return TRUE
	else
		return FALSE

/datum/station_trait/birthday/proc/announce_birthday()
	report_message = "Пакт поздравляет [birthday_person ? birthday_person_name : "Сотрудника"] с днём рождения!"
	priority_announce("С днём рождения, [birthday_person ? birthday_person_name : "Сотрудник"]! Пакт желает тебе счастливого [birthday_person ? thtotext(birthday_person.age + 1) : "255-го"] дня рождения.")
	if(birthday_person)
		playsound(birthday_person, 'sound/items/party_horn.ogg', 80)
		SEND_SIGNAL(birthday_person, COMSIG_ADD_MOOD_EVENT, "birthday", /datum/mood_event/birthday)
		birthday_person = null

/// Переназначить именинника в любой момент раунда.
/datum/station_trait/birthday/proc/reassign_birthday(mob/living/carbon/human/new_person)
	ADD_TRAIT(SSstation, STATION_TRAIT_BIRTHDAY, STATION_TRAIT)

	// Снимаем трейт со старого именинника
	if(birthday_person && HAS_TRAIT(birthday_person, TRAIT_BIRTHDAY_BOY))
		REMOVE_TRAIT(birthday_person, TRAIT_BIRTHDAY_BOY, REF(src))

	birthday_person = new_person
	birthday_person_name = new_person.real_name
	ADD_TRAIT(birthday_person, TRAIT_BIRTHDAY_BOY, REF(src))

	announce_birthday()

/datum/station_trait/birthday/proc/on_job_after_spawn(datum/source, datum/job/job, mob/living/spawned_mob, client/player_client)
	SIGNAL_HANDLER

	if(!ishuman(spawned_mob))
		return

	// Шляпки
	var/hat_type = prob(75) ? /obj/item/clothing/head/festive : /obj/item/clothing/head/christmashat
	var/obj/item/hat = new hat_type(spawned_mob)
	if(!spawned_mob.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD, disable_warning = TRUE))
		hat.forceMove(get_turf(spawned_mob))

	// Игрушечки
	var/toy_type = pick(/obj/item/toy/balloon, /obj/item/sparkler)
	var/obj/item/toy = new toy_type(spawned_mob)
	if(!spawned_mob.equip_to_slot_if_possible(toy, ITEM_SLOT_HANDS, disable_warning = TRUE))
		toy.forceMove(get_turf(spawned_mob))

	// Приглашение
	if(birthday_person_name)
		var/obj/item/birthday_invite/invite = new(spawned_mob)
		invite.setup_card(birthday_person_name)
		if(!spawned_mob.equip_to_slot_if_possible(invite, ITEM_SLOT_HANDS, disable_warning = TRUE))
			invite.forceMove(get_turf(spawned_mob))

// Пригласительная открытка на день рождения
/obj/item/birthday_invite
	name = "Пригласительная открытка"
	desc = "Открытка, сообщающая что сегодня у кого-то день рождения."
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_TINY
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paperbiscuit_paper"

/obj/item/birthday_invite/proc/setup_card(birthday_name)
	desc = "Открытка, сообщающая что сегодня день рождения у [birthday_name]."

/// Админ-верб
/client/proc/cmd_admin_set_birthday_person()
	set category = "Admin.Events"
	set name = "Set Birthday Person"

	if(!check_rights(R_ADMIN))
		return

	var/datum/station_trait/birthday/birthday_trait
	for(var/datum/station_trait/birthday/trait in SSstation.station_traits)
		birthday_trait = trait
		break

	if(!birthday_trait)
		SSstation.setup_trait(/datum/station_trait/birthday)
		for(var/datum/station_trait/birthday/trait in SSstation.station_traits)
			birthday_trait = trait
			break
		if(!birthday_trait)
			to_chat(usr, span_warning("Не удалось создать трейт 'День Рождения'."))
			return

	var/list/crew_options = list()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(!H.mind || !H.job || !H.client)
			continue
		var/label = "[H.real_name] ([H.mind.key]) — [H.job]"
		crew_options[label] = H

	if(!length(crew_options))
		to_chat(usr, span_warning("Нет живых членов экипажа с игроком."))
		return

	var/chosen_label = tgui_input_list(usr, "Выберите именинника:", "Назначить именинника", crew_options)
	if(isnull(chosen_label))
		return

	var/mob/living/carbon/human/chosen = crew_options[chosen_label]
	if(!chosen || !chosen.client)
		to_chat(usr, span_warning("Игрок уже недоступен."))
		return

	birthday_trait.birthday_override_ckey = chosen.mind.key
	birthday_trait.reassign_birthday(chosen)

	to_chat(usr, span_notice("Именинником назначен: [chosen.real_name] ([chosen.mind.key])."))

	var/msg = "[key_name(usr)] назначил(а) именинником: [chosen.real_name] ([chosen.mind.key])"
	log_admin(msg)
	message_admins(msg)

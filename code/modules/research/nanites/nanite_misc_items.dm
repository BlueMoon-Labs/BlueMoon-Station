/obj/item/nanite_injector
	name = "nanite injector (FOR TESTING)"
	desc = "Injects nanites into the user."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_remote"

/obj/item/nanite_injector/attack_self(mob/user)
	user.AddComponent(/datum/component/nanites, 150)

#define NANITE_PUMP_SYNC_DELAY 15 SECONDS

/obj/item/implant/nanite_pump
	name = "nanite pump"
	desc = "This device looks like a pump with an input and output and functions as a small nanomachine factory, a filter for spent nanomachines, and a similar reprogrammer that restores damaged programs. However, without constant updates and reprocessing, these programs are short-lived."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "pumpextreme"
	var/datum/component/nanites/nanite_pump/pump_nanites = null
	var/set_program_cloud = 0
	var/next_sync

/obj/item/implant/nanite_pump/Initialize(mapload)
	. = ..()
	pump_nanites = AddComponent(/datum/component/nanites/nanite_pump)

/obj/item/implant/nanite_pump/implant(mob/living/target, mob/user, silent, force)
	. = ..()
	if(!.)
		return FALSE

	var/volume = 0
	if(SEND_SIGNAL(target, COMSIG_HAS_NANITES))
		volume = SEND_SIGNAL(target, COMSIG_NANITE_GET_VOLUME)
		SEND_SIGNAL(target, COMSIG_NANITE_DELETE)

	if(target.AddComponent(/datum/component/nanites/nanite_pump, volume) == COMPONENT_INCOMPATIBLE)
		return FALSE

	START_PROCESSING(SSobj, src)
	next_sync = world.time + NANITE_PUMP_SYNC_DELAY
	sync_nanites()
	return TRUE

/obj/item/implant/nanite_pump/removed(mob/living/source, silent, special)
	. = ..()
	STOP_PROCESSING(SSobj, src)
	var/volume = SEND_SIGNAL(source, COMSIG_NANITE_GET_VOLUME)
	SEND_SIGNAL(source, COMSIG_NANITE_DELETE)
	if(source.AddComponent(/datum/component/nanites, volume) != COMPONENT_INCOMPATIBLE)
		SEND_SIGNAL(source, COMSIG_NANITE_SYNC, pump_nanites)
		SEND_SIGNAL(source, COMSIG_NANITE_SET_REGEN, -50)

/obj/item/implant/nanite_pump/activate()
	. = ..()
	var/cloud_id = tgui_input_number(imp_in, "Установите облако с которого будут скачены программы в имплант. Это можно сделать ОДИН РАЗ", "ID облака", set_program_cloud, 100, 0)
	if(!isnum(cloud_id))
		return
	set_programs_pump(cloud_id, imp_in)
	sync_nanites()

/obj/item/implant/nanite_pump/examine(mob/user)
	. = ..()
	if(set_program_cloud)
		. += "<BR><b>CLOUD ID:</b> [set_program_cloud]"

/obj/item/implant/nanite_pump/get_data()
	var/programs = ""
	for(var/X in pump_nanites.programs)
		var/datum/nanite_program/NP = X
		programs += "<b>[NP.name]</b> | [NP.activated ? "Active" : "Inactive"]<BR>"

	var/dat = {"<b>Технические характеристики Импланта:</b><BR>
				<b>Название:</b> Нанитная помпа<BR>
				<b>Время Износа:</b> Неизвестно.<BR>
				<b>Дополнительные Сведения:</b> Загружены программы из облака: [set_program_cloud].<BR>
				[programs]
				<HR>
				<b>Дополнительная информация по импланту:</b><BR>
				<b>Функционал:</b>  Внедряет в тело носителя наномашины и является небольшим заводом по их репликации, фильтрации, синхронизации с эталонными инструкциями. <BR>
				<b>Дополнительные Функции:</b> Не обнаружено.<BR>
				<b>Целостность:</b> Передатчик уязвим к электромагнитным импульсам разрушая эталонные программы, что соответственно приводит к порче наномашин носителя, стремительно убивая его."}
	return dat

/obj/item/implant/nanite_pump/can_be_implanted_in(mob/living/target)
	if(HAS_TRAIT(target, TRAIT_NANITES_IMMUNITY))
		return FALSE
	if(target.mob_biotypes & (MOB_ORGANIC | MOB_UNDEAD) || HAS_TRAIT(target, TRAIT_COMPATIBLE_WITH_NANITES))
		return TRUE
	return FALSE

/obj/item/implant/nanite_pump/process(delta_time)
	if(world.time < next_sync)
		return

	next_sync = world.time + NANITE_PUMP_SYNC_DELAY
	if(!check_nanites())
		to_chat(imp_in, "<span class='warning'>Нанитная помпа внутри вашего тела растворяется из за вашей несовместимости с нанитами</span>")
		qdel(src)
		return
	sync_nanites()

/obj/item/implant/nanite_pump/proc/sync_nanites()
	SEND_SIGNAL(imp_in, COMSIG_NANITE_SET_CLOUD, 0)
	SEND_SIGNAL(imp_in, COMSIG_NANITE_SYNC, pump_nanites)

/obj/item/implant/nanite_pump/proc/check_nanites()
    if(SEND_SIGNAL(imp_in, COMSIG_HAS_NANITES))
        return TRUE
    return imp_in.AddComponent(/datum/component/nanites/nanite_pump, 1) != COMPONENT_INCOMPATIBLE

/obj/item/implant/nanite_pump/proc/set_programs_pump(cloud_id, mob/user, force = FALSE)
	if(cloud_id)
		var/datum/nanite_cloud_backup/backup = SSnanites.get_cloud_backup(cloud_id)
		if(!backup)
			to_chat(user, "<span class='warning'>Сервер не отвечает на запрос, попробуйте позже</span>")
			return
		set_program_cloud = cloud_id
		SEND_SIGNAL(src, COMSIG_NANITE_SYNC, backup.nanites)

		if(user == imp_in)
			for(var/X in actions)
				var/datum/action/A = X
				A.Remove(imp_in)

		if(!force)
			activated = FALSE

#undef NANITE_PUMP_SYNC_DELAY

/obj/item/implant/nanite_pump/attack_self(mob/user)
	. = ..()
	if(set_program_cloud)
		to_chat(user, "<span class='warning'>Невозможно установить новое программное обеспечение</span>")

	var/cloud_id = tgui_input_number(user, "Установите облако с которого будут скачены программы в имплант. Это можно сделать ОДИН РАЗ (При внедрении в тело при таком раскладе остается возможность перевыбора)", "ID облака", 0, 100, 0)
	if(!isnum(cloud_id))
		return
	set_programs_pump(cloud_id, user, TRUE)

/obj/item/implantcase/nanite_pump
	name = "implant case - 'Nanite Pump'"
	desc = "A glass case containing an nanite pump implant."
	imp_type = /obj/item/implant/nanite_pump


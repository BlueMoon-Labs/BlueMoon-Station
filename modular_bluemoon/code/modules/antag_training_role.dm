GLOBAL_LIST_EMPTY(antag_training_roles)

/// Отделы в порядке раздевалки: флаги и подписи по одному индексу.
GLOBAL_LIST_INIT(antag_training_role_department_flags, list(DEPARTMENT_BITFLAG_COMMAND, DEPARTMENT_BITFLAG_SECURITY, DEPARTMENT_BITFLAG_MEDICAL, DEPARTMENT_BITFLAG_ENGINEERING, DEPARTMENT_BITFLAG_SCIENCE, DEPARTMENT_BITFLAG_SUPPLY, DEPARTMENT_BITFLAG_SERVICE))
GLOBAL_LIST_INIT(antag_training_role_department_names, list("Командование", "Служба безопасности", "Медицина", "Инженерия", "Наука", "Снабжение", "Сервис"))
/// Предметы власти над станцией, которые снаряжение должности на полигоне не выдаёт.
GLOBAL_LIST_INIT(antag_training_role_station_items, typecacheof(list(/obj/item/station_charter, /obj/item/syndicate_uplink/station, /obj/item/card/id/departmental_budget)))

/// Код для записки полигона: того же вида, что код золотого сейфа станции, но не он.
/proc/antag_training_fake_safe_code(real_code)
	var/obj/structure/safe/spare_id/safe_type = /obj/structure/safe/spare_id
	var/list/tumblers = list()
	do
		tumblers.Cut()
		for(var/index in 1 to initial(safe_type.number_of_tumblers))
			tumblers += rand(0, 99)
	while(jointext(tumblers, "-") == real_code)
	return jointext(tumblers, "-")

/proc/antag_training_roles()
	if(!length(GLOB.antag_training_roles))
		var/datum/antag_training_role/default_role = new
		GLOB.antag_training_roles[default_role.id] = default_role
		for(var/datum/job/job as anything in SSjob.occupations)
			if(!job.outfit || (job.departments & DEPARTMENT_BITFLAG_SILICON))
				continue
			var/datum/antag_training_role/crew/role = new(job)
			GLOB.antag_training_roles[role.id] = role
		for(var/role_type in list(/datum/antag_training_role/silicon/ai, /datum/antag_training_role/silicon/cyborg))
			var/datum/antag_training_role/silicon_role = new role_type
			GLOB.antag_training_roles[silicon_role.id] = silicon_role
	return GLOB.antag_training_roles

/proc/antag_training_role(id)
	return antag_training_roles()[id]

/// Программа принимает роль: программы без должностей (существа, команды извне) принимают любую и её игнорируют.
/proc/antag_training_role_compatible(program_type, datum/antag_training_role/role)
	var/datum/antag_training_program/program = program_type
	var/allowed = initial(program.allowed_roles)
	return !allowed || !role || !!(allowed & role.kind)

/proc/antag_training_role_entries()
	var/list/entries = list()
	var/list/roles = antag_training_roles()
	for(var/id in roles)
		var/datum/antag_training_role/role = roles[id]
		entries += list(role.ui_entry())
	return entries

/datum/antag_training_role
	var/id = ANTAG_TRAINING_ROLE_DEFAULT
	var/name = "Учебное тело"
	var/department = "Полигон"
	var/order = 0
	var/kind = ANTAG_TRAINING_ROLES_HUMAN

/// Снаряжает тело роли. FALSE - роль не применилась, сессия не начинается.
/datum/antag_training_role/proc/apply(datum/antag_training_session/session, mob/living/carbon/human/body)
	return TRUE

/datum/antag_training_role/proc/ui_entry()
	return list("id" = id, "name" = name, "department" = department, "order" = order, "kind" = kind)

/// Должность станции без записи в манифест, банк, слоты и assigned_role.
/datum/antag_training_role/crew
	var/job_title

/datum/antag_training_role/crew/New(datum/job/job)
	job_title = job.title
	id = "crew:[job.title]"
	name = job.title
	order = job.display_order
	for(var/index in 1 to length(GLOB.antag_training_role_department_flags))
		if(job.departments & GLOB.antag_training_role_department_flags[index])
			department = GLOB.antag_training_role_department_names[index]
			break

/datum/antag_training_role/crew/apply(datum/antag_training_session/session, mob/living/carbon/human/body)
	var/datum/job/job = SSjob.GetJob(job_title)
	if(!job?.outfit)
		return FALSE
	body.delete_equipment()
	for(var/obj/item/implant/implant as anything in body.implants)
		qdel(implant)
	// Как SSjob: скафандр и баллон вида, потом форма должности.
	body.dna.species.before_equip_job(job, body)
	body.equipOutfit(job.outfit)
	body.dna.species.after_equip_job(job, body)
	for(var/obj/item/station_item in body.GetAllContents())
		if(is_type_in_typecache(station_item, GLOB.antag_training_role_station_items))
			qdel(station_item)
	// Доступ ставится здесь: outfit/job/post_equip завязан на банковский счёт, которого у участника нет.
	var/obj/item/card/id/card = body.get_idcard()
	if(card)
		card.access = job.get_access()
		card.assignment = job.title
		card.registered_name = body.real_name
		card.update_label()
	for(var/trait in job.mind_traits)
		ADD_TRAIT(body.mind, trait, ANTAG_TRAINING_ROLE_TRAIT)
	body.regenerate_icons()
	return TRUE

/// Синтетик: не снаряжает человека, а меняет тело на учебного ИИ или киборга.
/datum/antag_training_role/silicon
	kind = ANTAG_TRAINING_ROLES_SILICON
	department = "Синтетики"
	var/mob_type

/datum/antag_training_role/silicon/proc/spawn_turf(datum/antag_training_session/session)
	return session.arena.entry_turf

/// Новое тело с разумом сеанса; null - не вышло.
/datum/antag_training_role/silicon/proc/build_body(datum/antag_training_session/session)
	var/turf/where = spawn_turf(session)
	var/datum/mind/soul = session.avatar_mind
	if(!where || QDELETED(soul))
		return null
	var/mob/living/silicon/body = new mob_type(where)
	body.register_training_atom()
	if(body.training_origin?.resolve() != session.arena)
		qdel(body)
		return null
	var/mob/old_body = soul.current
	soul.transfer_to(body)
	if(soul.current != body)
		qdel(body)
		return null
	if(old_body?.ckey && !body.ckey)
		old_body.transfer_ckey(body, FALSE)
	after_build(session, body)
	return body

/datum/antag_training_role/silicon/proc/after_build(datum/antag_training_session/session, mob/living/silicon/body)
	return

/datum/antag_training_role/silicon/ai
	id = "silicon:ai"
	name = "ИИ"
	order = 1
	mob_type = /mob/living/silicon/ai/training

/// ИИ встаёт в ядро мини-станции хаба, без хаба - в ядро станционного макета: там камеры сети training.
/datum/antag_training_role/silicon/ai/spawn_turf(datum/antag_training_session/session)
	var/datum/antag_training_hub/hub = session.arena.hub
	if(hub?.load_station())
		return hub.landmark_turf("hub_ai_core")
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	if(!station?.load())
		return null
	return station.landmark_turf("ai_core")

/datum/antag_training_role/silicon/cyborg
	id = "silicon:cyborg"
	name = "Киборг"
	order = 2
	mob_type = /mob/living/silicon/robot/training

/// Киборг подключается к первому живому учебному ИИ другого участника арены.
/datum/antag_training_role/silicon/cyborg/after_build(datum/antag_training_session/session, mob/living/silicon/robot/training/body)
	for(var/datum/antag_training_session/member as anything in session.arena.members)
		var/mob/living/silicon/ai/training/core = member.current_body
		if(member != session && istype(core) && core.stat != DEAD)
			body.TryConnectToAI(core)
			return

/// Приём и раздача радио на z полигона: станционные приёмники сигналы этого z не берут.
/obj/machinery/telecomms/allinone/antag_training
	name = "training relay"
	desc = "Учебный ретранслятор: связывает гарнитуры участников полигона и не выходит за его пределы."
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	flags_1 = NODECONSTRUCT_1

// Программы, которые работают поверх должности участника; остальные её игнорируют.
/datum/antag_training_program/free
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN | ANTAG_TRAINING_ROLES_SILICON

/datum/antag_training_program/heretic
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/traitor
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/blood_brother
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/changeling
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/bloodsucker
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/gang
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/revolution
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/cult
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/clockcult
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/devil
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/hatred
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

/datum/antag_training_program/antag/zombie
	allowed_roles = ANTAG_TRAINING_ROLES_HUMAN

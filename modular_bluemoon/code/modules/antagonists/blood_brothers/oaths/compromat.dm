/// Отделы станции по зонам
GLOBAL_LIST_INIT(brother_department_areas, list(
	"командование" = list(/area/command, /area/ai_monitored/command, /area/ai_monitored/turret_protected),
	"СБ" = list(/area/security, /area/ai_monitored/security),
	"наука" = list(/area/science),
	"медицина" = list(/area/medical),
	"инженерия" = list(/area/engineering, /area/tcommsat),
	"снабжение" = list(/area/cargo),
	"сервис" = list(
		/area/service/kitchen,
		/area/service/hydroponics,
		/area/service/janitor,
		/area/service/lawoffice,
		/area/service/chapel/office,
		/area/service/theater/clown,
		/area/service/theater/mime,
	),
))

/// Зоны внутри отделов, куда ходит кто угодно, и заброшенные отсеки
GLOBAL_LIST_INIT(brother_department_open_areas, list(
	/area/medical/medbay/lobby,
	/area/medical/abandoned,
	/area/science/research/lobby,
	/area/science/research/abandoned,
	/area/engineering/lobby,
	/area/service/hydroponics/lobby,
	/area/service/hydroponics/garden,
	/area/security/courtroom,
	/area/cargo/miningdock/abandoned,
))

/// Кабинет главы, куда подбрасывают компромат на работника отдела
GLOBAL_LIST_INIT(brother_head_offices, list(
	"командование" = list("area" = /area/command/heads_quarters/captain, "name" = "кабинет капитана", "where" = "кабинете капитана"),
	"СБ" = list("area" = /area/command/heads_quarters/hos, "name" = "кабинет главы службы безопасности", "where" = "кабинете главы службы безопасности"),
	"наука" = list("area" = /area/command/heads_quarters/rd, "name" = "кабинет научного руководителя", "where" = "кабинете научного руководителя"),
	"медицина" = list("area" = /area/command/heads_quarters/cmo, "name" = "кабинет главного врача", "where" = "кабинете главного врача"),
	"инженерия" = list("area" = /area/command/heads_quarters/ce, "name" = "кабинет старшего инженера", "where" = "кабинете старшего инженера"),
	"снабжение" = list("area" = /area/cargo/qm, "name" = "кабинет квартирмейстера", "where" = "кабинете квартирмейстера"),
	"сервис" = list("area" = /area/command/heads_quarters/hop, "name" = "кабинет главы персонала", "where" = "кабинете главы персонала"),
))

/proc/brother_area_department(area/place)
	if(!place || is_type_in_list(place, GLOB.brother_department_open_areas))
		return null
	for(var/department in GLOB.brother_department_areas)
		if(is_type_in_list(place, GLOB.brother_department_areas[department]))
			return department
	return null

/// Отделы должности, главный первым; у ассистента, заключённого и безбилетника отдела нет
/proc/brother_job_departments(job_title)
	var/static/list/no_department = list("Assistant", "Prisoner", "Stowaway")
	. = list()
	if(!job_title || (job_title in no_department))
		return
	if(job_title in GLOB.command_positions)
		. += "командование"
	if(job_title in GLOB.security_positions)
		. += "СБ"
	if(job_title in GLOB.science_positions)
		. += "наука"
	if(job_title in GLOB.medical_positions)
		. += "медицина"
	if(job_title in GLOB.engineering_positions)
		. += "инженерия"
	if(job_title in GLOB.supply_positions)
		. += "снабжение"
	if((job_title in GLOB.civilian_positions) || (job_title in GLOB.law_positions))
		. += "сервис"

/// У должности без отдела чужих отделов нет
/proc/brother_area_is_foreign(area/place, job_title)
	var/department = brother_area_department(place)
	if(!department)
		return FALSE
	var/list/own_departments = brother_job_departments(job_title)
	return (length(own_departments) && !(department in own_departments)) ? TRUE : FALSE

/// Кабинет начальника должности list("area", "name"); за главу и за кабинет, которого нет на карте, отвечает капитан
/proc/brother_head_office(job_title)
	var/list/departments = brother_job_departments(job_title)
	var/list/office = GLOB.brother_head_offices[length(departments) ? departments[1] : "сервис"]
	if(brother_area_type_exists(office["area"]))
		return office
	office = GLOB.brother_head_offices["командование"]
	return brother_area_type_exists(office["area"]) ? office : null

/proc/brother_area_type_exists(area_type)
	for(var/area/candidate as anything in GLOB.all_areas)
		if(istype(candidate, area_type))
			return TRUE
	return FALSE

/// Кто из разумных попал в кадр и в каком виде: WEAKREF(mind) -> флаги
/proc/photo_subjects_seen(list/mobs)
	var/list/subjects
	for(var/mob/living/subject in mobs)
		if(!subject.mind)
			continue
		LAZYSET(subjects, WEAKREF(subject.mind), list(
			"restrained" = subject.restrained(TRUE) ? TRUE : FALSE,
			"unconscious" = (subject.stat != CONSCIOUS || subject.IsSleeping()) ? TRUE : FALSE,
			"foreign_area" = brother_area_is_foreign(get_area(subject), subject.mind.assigned_role),
		))
	return subjects

/proc/brother_photo_compromises(obj/item/photo/photo, datum/mind/target)
	var/list/subjects = photo?.picture?.subjects_seen
	if(!target || !length(subjects))
		return FALSE
	var/list/state = subjects[WEAKREF(target)]
	return state && (state["restrained"] || state["unconscious"] || state["foreign_area"])

/datum/blood_oath/compromat
	name = "Компромат"
	key = "compromat"
	summary = "собрать компромат на человека и подбросить его начальству"
	weight = 6
	capstone_type = /datum/action/cooldown/blood_bond/capstone/mark
	kit_items = list(/obj/item/camera, /obj/item/restraints/handcuffs/cable/zipties, /obj/item/clothing/mask/balaclava)
	var/office_type
	/// Кабинет в винительном падеже: «подбросьте в кабинет капитана»
	var/office_name
	/// Кабинет в предложном падеже: «на столе в кабинете капитана»
	var/office_where

/datum/blood_oath/compromat/prepare(datum/team/brother_team/for_team)
	. = ..()
	target_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	var/datum/mind/found = find_target(for_team)
	if(!found || !set_target(found))
		return FALSE
	add_step(new /datum/blood_oath_step/compromat_photo)
	add_step(new /datum/blood_oath_step/compromat_papers)
	add_step(new /datum/blood_oath_step/compromat_plant)
	update_story()
	return TRUE

/// Охрана и капитан компромата не боятся, заключённый и так под стражей
/datum/blood_oath/compromat/find_target(datum/team/brother_team/for_team)
	return brother_pick_target(for_team, target_opt_in_level, GLOB.security_positions + "Captain" + get_prisoner_role_titles(), src)

/datum/blood_oath/compromat/target_allowed(datum/mind/candidate)
	return !isnull(brother_head_office(candidate?.assigned_role))

/datum/blood_oath/compromat/set_target(datum/mind/new_target)
	var/list/office = brother_head_office(new_target?.assigned_role)
	if(!office)
		return FALSE
	. = ..()
	office_type = office["area"]
	office_name = office["name"]
	office_where = office["where"]

/datum/blood_oath/compromat/update_story()
	story = "[target_mind.name] слишком много о вас знает. Соберите компромат и подбросьте его в [office_name]: пусть начальство само разберётся, кому теперь верить."

/datum/blood_oath_step/compromat_photo
	name = "Снимок"

/datum/blood_oath_step/compromat_photo/describe()
	var/mob/living/target_body = oath.target_mind.current
	name = "Снимок: [oath.target_mind.name]"
	desc = "Фото, где [oath.target_mind.name] в наручниках, без сознания или спит, или там, где [target_body ? target_body.ru_emu() : "ей"] не место: в чужом отделе. Фото у любого из братьев."

/datum/blood_oath_step/compromat_photo/can_seal(mob/living/sealer)
	for(var/obj/item/photo/photo as anything in brother_team_items(oath.team, /obj/item/photo))
		if(brother_photo_compromises(photo, oath.target_mind))
			return TRUE
	return "на брате нет снимка, где [oath.target_mind?.name] выглядит плохо"

/datum/blood_oath_step/compromat_photo/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/compromat_papers
	name = "Документы"

/datum/blood_oath_step/compromat_papers/describe()
	name = "Документы: [oath.target_mind.name]"
	desc = "ID-карта или КПК на имя [oath.target_mind.name] у любого из братьев. Документы на прежнее имя цели тоже годятся."

/datum/blood_oath_step/compromat_papers/can_seal(mob/living/sealer)
	for(var/obj/item/card/id/card as anything in brother_team_items(oath.team, /obj/item/card/id))
		if(oath.target_known_name(card.registered_name))
			return TRUE
	for(var/obj/item/modular_computer/pda/pda as anything in brother_team_items(oath.team, /obj/item/modular_computer/pda))
		if(oath.target_known_name(pda.saved_identification))
			return TRUE
	return "на брате нет ни ID-карты, ни КПК на имя [oath.target_mind?.name]"

/datum/blood_oath_step/compromat_papers/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/compromat_plant
	name = "Подбросить"

/datum/blood_oath_step/compromat_plant/describe()
	var/datum/blood_oath/compromat/compromat_oath = oath
	name = "Подбросить в [compromat_oath.office_name]"
	desc = "Положите снимок с компроматом на [oath.target_mind.name] на пол или на стол в [compromat_oath.office_where] и скрепите, стоя не дальше [BROTHER_COMPROMAT_PLANT_RANGE] клеток от него."

/datum/blood_oath_step/compromat_plant/can_seal(mob/living/sealer)
	if(find_planted(sealer))
		return TRUE
	var/datum/blood_oath/compromat/compromat_oath = oath
	return "в [compromat_oath.office_where] рядом нет подброшенного снимка"

/datum/blood_oath_step/compromat_plant/condition_text(mob/living/viewer, sealable)
	return "снимок подброшен рядом: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/compromat_plant/proc/find_planted(mob/living/sealer)
	var/datum/blood_oath/compromat/compromat_oath = oath
	var/turf/sealer_turf = get_turf(sealer)
	if(!sealer_turf || !istype(compromat_oath))
		return null
	for(var/obj/item/photo/photo in range(BROTHER_COMPROMAT_PLANT_RANGE, sealer_turf))
		if(isturf(photo.loc) && istype(get_area(photo), compromat_oath.office_type) && brother_photo_compromises(photo, oath.target_mind))
			return photo
	return null

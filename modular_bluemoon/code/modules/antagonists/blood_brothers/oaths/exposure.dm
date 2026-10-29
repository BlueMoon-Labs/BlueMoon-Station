/datum/blood_oath/exposure
	name = "Разоблачение"
	key = "exposure"
	summary = "добыть секретные документы, снять копию и выложить её на виду"
	weight = 6
	capstone_type = /datum/action/cooldown/blood_bond/capstone/stash
	kit_items = list(BROTHER_KIT_BREAKIN)

/// Подлинные документы станции; копии не в счёт
GLOBAL_LIST_EMPTY(brother_station_papers)

/obj/item/documents/Initialize(mapload)
	. = ..()
	if(!istype(src, /obj/item/documents/photocopy) && brother_exposure_papers(src))
		GLOB.brother_station_papers += src

/obj/item/documents/Destroy()
	GLOB.brother_station_papers -= src
	return ..()

/// Без документов на станции первый шаг не скрепить; полигон выдаёт их сам
/datum/blood_oath/exposure/available(datum/team/brother_team/for_team)
	if(!..())
		return FALSE
	if(for_team.training)
		return TRUE
	for(var/obj/item/documents/papers as anything in GLOB.brother_station_papers)
		var/turf/papers_turf = get_turf(papers)
		if(papers_turf && is_station_level(papers_turf.z))
			return TRUE
	return FALSE

/datum/blood_oath/exposure/prepare(datum/team/brother_team/for_team)
	. = ..()
	add_step(new /datum/blood_oath_step/exposure_papers)
	add_step(new /datum/blood_oath_step/exposure_copy)
	add_step(new /datum/blood_oath_step/exposure_public)
	story = "Вы видели, что корпорация прячет в своих сейфах, и знаете, где лежат бумаги. Клянётесь: станция узнает правду."
	return TRUE

/// Документы, которые разоблачают станцию: не вражеские; у копии считается тип оригинала
/proc/brother_exposure_papers(obj/item/documents/papers)
	var/static/list/foreign_papers = typecacheof(list(/obj/item/documents/syndicate, /obj/item/documents/inteq))
	var/paper_type = papers.type
	if(istype(papers, /obj/item/documents/photocopy))
		var/obj/item/documents/photocopy/copy = papers
		paper_type = copy.copy_type
	return ispath(paper_type, /obj/item/documents) && !ispath(paper_type, /obj/item/documents/photocopy) && !foreign_papers[paper_type]

/datum/blood_oath_step/exposure_papers
	name = "Добыть секретные документы"
	desc = "Добудьте секретные документы станции и держите при себе. Бумаги Синдиката и InteQ не подойдут."

/datum/blood_oath_step/exposure_papers/can_seal(mob/living/sealer)
	for(var/obj/item/documents/papers as anything in brother_team_items(oath.team, /obj/item/documents))
		if(!istype(papers, /obj/item/documents/photocopy) && brother_exposure_papers(papers))
			return TRUE
	return "на брате нет секретных документов станции"

/datum/blood_oath_step/exposure_papers/condition_text(mob/living/viewer, sealable)
	return "на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/exposure_copy
	name = "Снять копию"
	desc = "Снимите с этих документов копию на любом фотокопире и держите при себе. Копия с копии тоже считается."

/datum/blood_oath_step/exposure_copy/can_seal(mob/living/sealer)
	for(var/obj/item/documents/photocopy/copy as anything in brother_team_items(oath.team, /obj/item/documents/photocopy))
		if(brother_exposure_papers(copy))
			return TRUE
	return "на брате нет копии документов"

/datum/blood_oath_step/exposure_copy/condition_text(mob/living/viewer, sealable)
	return "копия на брате: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/datum/blood_oath_step/exposure_public
	name = "Выложить на виду"

/datum/blood_oath_step/exposure_public/describe()
	desc = "Оставьте копию на полу или на столе в баре, кафетерии, главном коридоре или у прибытия и скрепите, стоя не дальше [BROTHER_EXPOSURE_RANGE] клеток от неё."

/datum/blood_oath_step/exposure_public/can_seal(mob/living/sealer)
	var/turf/sealer_turf = get_turf(sealer)
	if(!sealer_turf)
		return "копию некому выложить"
	for(var/obj/item/documents/photocopy/copy in range(BROTHER_EXPOSURE_RANGE, sealer_turf))
		if(isturf(copy.loc) && brother_exposure_papers(copy) && brother_area_is(copy, GLOB.brother_public_areas))
			return TRUE
	return "рядом нет копии на виду в людном месте"

/datum/blood_oath_step/exposure_public/condition_text(mob/living/viewer, sealable)
	return "копия на виду рядом: [sealable_now(viewer, sealable) ? "да" : "нет"]"

/// Потолок ожидания чужого кадра и слота съёмки.
#define RECORD_PHOTO_INFLIGHT_TIMEOUT (10 SECONDS)
#define RECORD_PHOTO_MAX_IN_FLIGHT 2

/// Сколько кадров записей строится прямо сейчас.
GLOBAL_VAR_INIT(record_photos_in_flight, 0)

//TODO: someone please get rid of this shit
/datum/datacore
	var/list/medical = list()
	var/medicalPrintCount = 0
	var/list/general = list()
	var/list/security = list()
	var/securityPrintCount = 0
	var/securityCrimeCounter = 0
	///This list tracks characters spawned in the world and cannot be modified in-game. Currently referenced by respawn_character().
	var/list/locked = list()
	/// Name-indexed lookups for O(1) record access by character name
	var/list/medical_by_name = list()
	var/list/security_by_name = list()
	var/list/general_by_name = list()
	/// ID-indexed lookups for O(1) record access by hex ID
	var/list/medical_by_id = list()
	var/list/security_by_id = list()
	var/list/general_by_id = list()
	var/list/locked_by_id = list()

/// Ленивый источник фотографии записи: в манифесте лежит только снапшот внешности,
/// кадр строится при первом обращении и кэшируется. Один на general- и locked-запись.
/datum/record_photo_source
	/// Снапшот внешности; сам моб тут держать нельзя, запись живёт весь раунд.
	var/frozen_appearance
	/// Роль для запасного пути через манекен, если снапшота нет.
	var/assigned_role
	var/datum/weakref/prefs_ref
	var/icon/cached_icon
	/// Взводится перед съёмкой: неудачный кадр кэшируется наравне с удачным.
	var/generated = FALSE
	/// TRUE, пока съёмка идёт. Отдельный флаг от generated нужен потому, что съёмка спит
	/// гарантированно, и читатель в этом окне иначе прочёл бы пустой кэш как готовый.
	var/generating = FALSE
	/// Потолок ожидания чужого кадра и слота съёмки; переменная, чтобы тест мог её укоротить.
	var/inflight_timeout = RECORD_PHOTO_INFLIGHT_TIMEOUT

/datum/record_photo_source/New(mob/living/carbon/human/subject, assigned_role, datum/preferences/prefs)
	. = ..()
	src.assigned_role = assigned_role
	if(prefs)
		prefs_ref = WEAKREF(prefs)
	snapshot_appearance(subject)

/// Снимает снапшот внешности, пока кадр ещё не строился; латеджойн зовёт повторно.
/datum/record_photo_source/proc/snapshot_appearance(mob/living/carbon/human/subject)
	if(generated || QDELETED(subject))
		return FALSE
	if(subject.body_position != STANDING_UP || subject.alpha < 255)
		return FALSE
	frozen_appearance = subject.appearance
	return TRUE

/// Первый вызов снимает кадр, последующие отдают кэш. Проверка generating идёт перед
/// generated: флаги взводятся вместе, и читатель в окне съёмки иначе уходит с null.
/datum/record_photo_source/proc/get_photo_icon()
	if(generating)
		var/wait_deadline = world.time + inflight_timeout
		UNTIL(!generating || world.time > wait_deadline)
		if(generating)
			generating = FALSE
			log_world("## DATACORE: съёмка кадра записи не завершилась за [inflight_timeout / (1 SECONDS)] с, флаг снят принудительно")
		return cached_icon
	if(generated)
		return cached_icon
	generated = TRUE
	generating = TRUE
	var/slot_deadline = world.time + inflight_timeout
	UNTIL(GLOB.record_photos_in_flight < RECORD_PHOTO_MAX_IN_FLIGHT || world.time > slot_deadline)
	if(GLOB.record_photos_in_flight >= RECORD_PHOTO_MAX_IN_FLIGHT)
		log_world("## DATACORE: счётчик съёмок записей завис на [GLOB.record_photos_in_flight], сброшен")
		GLOB.record_photos_in_flight = 0
	GLOB.record_photos_in_flight++
	try
		cached_icon = build_photo_icon()
	catch(var/exception/photo_error)
		cached_icon = null
		stack_trace("record_photo_source: съёмка кадра сорвалась ([photo_error])")
	GLOB.record_photos_in_flight = max(GLOB.record_photos_in_flight - 1, 0)
	frozen_appearance = null
	generating = FALSE
	return cached_icon

/// Собственно съёмка; вынесена отдельным проком, чтобы тест считал реальные генерации.
/datum/record_photo_source/proc/build_photo_icon()
	var/static/list/show_directions = list(SOUTH, WEST)
	// no_anim: фотография в записи статична, а без флага getFlatIcon тянет все кадры
	// анимации каждого оверлея - это самая дорогая часть съёмки.
	if(frozen_appearance)
		return build_flat_multidir_icon(null, show_directions, no_anim = TRUE, snapshot_appearance = frozen_appearance)
	var/datum/preferences/prefs = prefs_ref?.resolve()
	if(!assigned_role && !prefs)
		return icon('icons/effects/effects.dmi', "nothing")
	var/datum/job/photo_job = assigned_role ? SSjob.GetJob(assigned_role) : null
	return get_flat_human_icon(null, photo_job, prefs, DUMMY_HUMAN_SLOT_MANIFEST, show_directions, no_anim = TRUE)

/// Обновляет снапшот внешности в записи после того, как моба дообули на латеджойне.
/datum/datacore/proc/refresh_manifest_photo_source(mob/living/carbon/human/subject)
	if(QDELETED(subject))
		return FALSE
	var/datum/data/record/general_record = general_by_name[subject.real_name]
	var/datum/record_photo_source/source = general_record?.photo_source
	if(!source)
		return FALSE
	return source.snapshot_appearance(subject)

/// Registers a record in the appropriate index lists. Call after adding to medical/security/general lists.
/datum/datacore/proc/register_record(datum/data/record/R, record_type)
	var/rname = R.fields["name"]
	var/rid = R.fields["id"]
	switch(record_type)
		if("general")
			if(rname)
				general_by_name[rname] = R
			if(rid)
				general_by_id[rid] = R
		if("medical")
			if(rname)
				medical_by_name[rname] = R
			if(rid)
				medical_by_id[rid] = R
		if("security")
			if(rname)
				security_by_name[rname] = R
			if(rid)
				security_by_id[rid] = R

/// Reindexes a record after name or id change. Call with old values before the change.
/datum/datacore/proc/reindex_record(datum/data/record/R, old_name, old_id)
	// Remove old keys
	if(old_name)
		if(general_by_name[old_name] == R)
			general_by_name -= old_name
		if(medical_by_name[old_name] == R)
			medical_by_name -= old_name
		if(security_by_name[old_name] == R)
			security_by_name -= old_name
	if(old_id)
		if(general_by_id[old_id] == R)
			general_by_id -= old_id
		if(medical_by_id[old_id] == R)
			medical_by_id -= old_id
		if(security_by_id[old_id] == R)
			security_by_id -= old_id
	// Insert new keys
	var/new_name = R.fields["name"]
	var/new_id = R.fields["id"]
	if(new_name)
		if(R in general)
			general_by_name[new_name] = R
		if(R in medical)
			medical_by_name[new_name] = R
		if(R in security)
			security_by_name[new_name] = R
	if(new_id)
		if(R in general)
			general_by_id[new_id] = R
		if(R in medical)
			medical_by_id[new_id] = R
		if(R in security)
			security_by_id[new_id] = R

/// Removes all records (medical, security, general, locked) for a given name. Returns the rank from general record if found.
/datum/datacore/proc/remove_records_by_name(target_name)
	var/announce_rank = null
	var/datum/data/record/gen = general_by_name[target_name]
	if(gen)
		announce_rank = gen.fields["rank"]
		qdel(gen)
	var/datum/data/record/med = medical_by_name[target_name]
	if(med)
		qdel(med)
	var/datum/data/record/sec = security_by_name[target_name]
	if(sec)
		qdel(sec)
	// Locked-записи индексируются по id, не по имени - ищем перебором.
	// Без этого GLOB.data_core.locked бесконечно копит записи ушедших в крио,
	// а каждая держит mind (скиллы, антаг-датумы, флэт-иконку).
	for(var/datum/data/record/locked_record as anything in locked.Copy())
		if(locked_record.fields["name"] == target_name)
			qdel(locked_record)
	return announce_rank

/datum/data
	var/name = "data"

/datum/data/record
	name = "record"
	var/list/fields = list()
	/// Ленивый источник фотографии, общий у general- и locked-записи; пуст у записей с консоли.
	var/datum/record_photo_source/photo_source

/// Единственная дверь к полям photo_front/photo_side: первое обращение снимает кадр и
/// раскладывает по обоим полям. generate = FALSE - только заглянуть, для списков в ui_data.
/datum/data/record/proc/get_record_photo(photo_field = "photo_front", generate = TRUE)
	var/obj/item/photo/existing = fields[photo_field]
	if(istype(existing))
		return existing
	// В поле бывает сырая /icon (запись с консоли, последствия ЭМИ) - её вызывающий читает сам.
	if(!generate || !photo_source || isicon(fields[photo_field]))
		return null
	var/icon/photo_icon = photo_source.get_photo_icon()
	if(!photo_icon)
		return null
	// Съёмка спит: за это окно запись могли стереть с консоли.
	if(QDELETED(src))
		return null
	// На том же сне поле мог заполнить другой читатель этой записи.
	existing = fields[photo_field]
	if(istype(existing))
		return existing
	try
		apply_record_photo_icon(photo_icon)
	catch(var/exception/photo_apply_error)
		stack_trace("get_record_photo: раскладка кадра по записи сорвалась ([photo_apply_error])")
		return null
	existing = fields[photo_field]
	return istype(existing) ? existing : null

/// base64 фотографии записи для ui_data консолей: только чтение готового. Съёмки здесь
/// нет намеренно - ui_data гоняет SStgui, усыплять его нельзя.
/datum/data/record/proc/get_record_photo_base64(photo_field = "photo_front")
	var/obj/item/photo/photo = get_record_photo(photo_field, generate = FALSE)
	if(photo)
		return photo.picture?.get_base64()
	var/existing = fields[photo_field]
	if(isicon(existing))
		return icon2base64(existing)
	return null

/// Раскладывает снятый кадр по полям general-записи: анфас - юг, профиль - запад.
/datum/data/record/proc/apply_record_photo_icon(icon/photo_icon)
	var/record_name = fields["name"] || "Unknown"
	var/datum/picture/picture_front = new
	picture_front.picture_name = record_name
	picture_front.picture_desc = "This is [record_name]."
	picture_front.picture_image = icon(photo_icon, dir = SOUTH)
	var/datum/picture/picture_side = new
	picture_side.picture_name = record_name
	picture_side.picture_desc = "This is [record_name]."
	picture_side.picture_image = icon(photo_icon, dir = WEST)
	// Чужое значение не перетираем: его мог положить upd_photo за время сна съёмки.
	if(isnull(fields["photo_front"]))
		fields["photo_front"] = new /obj/item/photo(null, picture_front)
	if(isnull(fields["photo_side"]))
		fields["photo_side"] = new /obj/item/photo(null, picture_side)

/// То же самое для locked-записи, где фото лежит сырой иконкой (голограмма ИИ).
/datum/data/record/proc/get_record_image(generate = TRUE)
	var/icon/existing = fields["image"]
	if(isicon(existing))
		return existing
	if(!generate || !photo_source || !isnull(existing))
		return null
	var/icon/photo_icon = photo_source.get_photo_icon()
	if(!photo_icon)
		return null
	if(QDELETED(src))
		return null
	existing = fields["image"]
	if(isicon(existing))
		return existing
	// Копия, а не общий cached_icon: правка на месте (Blend, Scale) видна всем читателям.
	photo_icon = icon(photo_icon)
	fields["image"] = photo_icon
	return photo_icon

/datum/data/record/Destroy()
	// Консоли кэшируют выбранную запись в active1/active2 и обнуляют их только в
	// собственном Destroy - удалённая запись иначе висит на консоли вечно.
	for(var/obj/machinery/computer/secure_data/sec_console in GLOB.machines)
		if(sec_console.active1 == src)
			sec_console.active1 = null
		if(sec_console.active2 == src)
			sec_console.active2 = null
	for(var/obj/machinery/computer/med_data/med_console in GLOB.machines)
		if(med_console.active1 == src)
			med_console.active1 = null
		if(med_console.active2 == src)
			med_console.active2 = null
	// Только general-запись владеет фотографиями. Security-запись после EMP
	// может ссылаться на те же объекты и не должна удалять их из-под владельца.
	if(src in GLOB.data_core.general)
		var/obj/item/photo/photo_front = fields["photo_front"]
		if(istype(photo_front))
			qdel(photo_front)
		var/obj/item/photo/photo_side = fields["photo_side"]
		if(istype(photo_side))
			qdel(photo_side)
	var/record_name = fields["name"]
	var/record_id = fields["id"]
	if(record_name)
		if(GLOB.data_core.medical_by_name[record_name] == src)
			GLOB.data_core.medical_by_name -= record_name
		if(GLOB.data_core.security_by_name[record_name] == src)
			GLOB.data_core.security_by_name -= record_name
		if(GLOB.data_core.general_by_name[record_name] == src)
			GLOB.data_core.general_by_name -= record_name
	if(record_id)
		if(GLOB.data_core.medical_by_id[record_id] == src)
			GLOB.data_core.medical_by_id -= record_id
		if(GLOB.data_core.security_by_id[record_id] == src)
			GLOB.data_core.security_by_id -= record_id
		if(GLOB.data_core.general_by_id[record_id] == src)
			GLOB.data_core.general_by_id -= record_id
		if(GLOB.data_core.locked_by_id[record_id] == src)
			GLOB.data_core.locked_by_id -= record_id
	GLOB.data_core.medical -= src
	GLOB.data_core.security -= src
	GLOB.data_core.general -= src
	GLOB.data_core.locked -= src
	// Источник общий с парной записью: обнуляем только свою ссылку.
	photo_source = null
	. = ..()

/datum/data/crime
	name = "crime"
	var/crimeName = ""
	var/crimeDetails = ""
	var/author = ""
	var/time = ""
	var/dataId = 0
	// BLUEMOON ADD START - авторизация ЦК и возможность пометить правонарушение как уже обработанное
	var/centcom_enforced = FALSE // Создана ли данная запись сотрудниками ЦК
	var/penalties_incurred = FALSE // Понёс ли субъект наказание за свои преступления
	// BLUEMOON ADD END

/datum/datacore/proc/createCrimeEntry(cname = "", cdetails = "", author = "", time = "", centcom_enforced = FALSE) // BLUEMOON EDIT - авторизация ЦК
	var/datum/data/crime/c = new /datum/data/crime
	c.crimeName = cname
	c.crimeDetails = cdetails
	c.author = author
	c.time = time
	c.dataId = ++securityCrimeCounter
	c.centcom_enforced = centcom_enforced // BLUEMOON EDIT - авторизация ЦК
	return c

/datum/datacore/proc/addMinorCrime(id = "", datum/data/crime/crime)
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/list/crimes = R.fields["mi_crim"]
			crimes |= crime
			return

/datum/datacore/proc/removeMinorCrime(id, cDataId, centcom_authority = FALSE) // BLUEMOON EDIT - авторизация ЦК
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/list/crimes = R.fields["mi_crim"]
			for(var/datum/data/crime/crime in crimes)
				if(crime.dataId == text2num(cDataId))
					if(crime.centcom_enforced && !centcom_authority) // BLUEMOON EDIT - авторизация ЦК
						return
					crimes -= crime
					return

/datum/datacore/proc/removeMajorCrime(id, cDataId, centcom_authority = FALSE) // BLUEMOON EDIT - авторизация ЦК
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/list/crimes = R.fields["ma_crim"]
			for(var/datum/data/crime/crime in crimes)
				if(crime.dataId == text2num(cDataId))
					if(crime.centcom_enforced && !centcom_authority) // BLUEMOON EDIT - авторизация ЦК
						return
					crimes -= crime
					return

/datum/datacore/proc/addMajorCrime(id = "", datum/data/crime/crime)
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/list/crimes = R.fields["ma_crim"]
			crimes |= crime
			return

// BLUEMOON ADD START - возможность пометить правонарушение как обработанное | Логи
/datum/datacore/proc/switch_incur(id, cDataId)
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/list/crimes = R.fields["mi_crim"] + R.fields["ma_crim"]
			for(var/datum/data/crime/crime in crimes)
				if(crime.dataId == text2num(cDataId))
					crime.penalties_incurred = !crime.penalties_incurred
					return

/datum/datacore/proc/get_actions_logs(id)
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/list/logs = R.fields["actions_logs"]
			return logs

/datum/datacore/proc/append_sec_logs(id, log, auth_name, auth_rank)
	for(var/datum/data/record/R in security)
		if(R.fields["id"] == id)
			var/timestamp = "\[[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]\]"
			var/log_text = "<b>[timestamp]</b> [log]"
			log_text = replacetext(log_text, "%%RANK%%", "<u>[auth_rank]</u>")
			log_text = replacetext(log_text, "%%AUTH%%", "<u>[auth_name]</u>")
			log_text = replacetext(log_text, "%%GEN_AUTH%%", "<u>[auth_name] ([auth_rank])</u>")
			R.fields["actions_logs"] += log_text

// отдельная запись квирков когда они реально записаны
/datum/datacore/proc/notes_traits_modify(mob/living/carbon/human/H)
	var/datum/data/record/foundrecord = GLOB.data_core.medical_by_name[H.real_name]
	if(foundrecord)
		var/traits_dat = H.get_trait_string(TRUE)
		if(!traits_dat)
			return
		else
			foundrecord.fields["notes"] += "\n информация о чертах на начало смены: [traits_dat]"
// BLUEMOON ADD END

/datum/datacore/proc/manifest()
	// Обход списка идёт по снапшоту, снятому на входе в цикл, а CHECK_TICK усыпляет
	// прок: к следующей итерации игрок мог отключиться, а его моб - уйти в qdel.
	// Поэтому валидность проверяется заново на каждой итерации, иначе рантайм на
	// N.client.prefs роняет манифест всем, кто стоит в списке дальше.
	for(var/mob/dead/new_player/N in GLOB.player_list)
		CHECK_TICK
		if(QDELETED(N) || !N.client)
			continue
		var/mob/living/character = N.new_character
		if(QDELETED(character))
			continue
		log_manifest(N.ckey, character.mind, character)
		if(ishuman(character) && N.client.prefs)
			manifest_inject(character, N.client, N.client.prefs)

/datum/datacore/proc/manifest_modify(name, assignment, real_rank)
	if(!name || !assignment && !real_rank)
		return
	var/datum/data/record/foundrecord = GLOB.data_core.general_by_name[name]
	if(foundrecord)
		if(assignment)
			foundrecord.fields["rank"] = assignment
		if(real_rank)
			foundrecord.fields["real_rank"] = real_rank

/datum/datacore/proc/get_manifest()
	var/list/manifest_out = list()
	var/list/departments = list(
		"Command" = GLOB.command_positions,
		"Security" = GLOB.security_positions,
		"Engineering" = GLOB.engineering_positions,
		"Medical" = GLOB.medical_positions,
		"Science" = GLOB.science_positions,
		"Supply" = GLOB.supply_positions,
		"Service" = GLOB.civilian_positions,
		"Law" = GLOB.law_positions,
		"Silicon" = GLOB.nonhuman_positions
	)
	for(var/datum/data/record/t in GLOB.data_core.general)
		var/name = t.fields["name"]
		var/rank = t.fields["rank"]
		var/department_check = GetJobName(t.fields["real_rank"])
		var/has_department = FALSE
		for(var/department in departments)
			var/list/jobs = departments[department]
			if(department_check in jobs)
				if(!manifest_out[department])
					manifest_out[department] = list()
				// Append to beginning of list if captain or department head
				if (department_check == "Captain" || (department != "Command" && (rank in GLOB.command_positions)))
					manifest_out[department] = list(list(
						"name" = name,
						"rank" = rank,
						"department_check" = department_check
					)) + manifest_out[department]
				else
					manifest_out[department] += list(list(
						"name" = name,
						"rank" = rank,
						"department_check" = department_check
					))
				has_department = TRUE
		if(!has_department)
			if(!manifest_out["Misc"])
				manifest_out["Misc"] = list()
			manifest_out["Misc"] += list(list(
				"name" = name,
				"rank" = rank,
				"department_check" = department_check
			))
	return manifest_out

/datum/datacore/proc/get_manifest_bm(monochrome, OOC)
	var/list/heads = list()
	var/list/sec = list()
	var/list/eng = list()
	var/list/med = list()
	var/list/sci = list()
	var/list/sup = list()
	var/list/civ = list()
	var/list/law = list()
	var/list/bot = list()
	var/list/misc = list()
	var/dat = {"
	<head><style>
		.manifest {border-collapse:collapse;}
		.manifest td, th {border:1px solid [monochrome?"black":"#DEF; background-color:white; color:black"]; padding:.25em}
		.manifest th {height: 2em; [monochrome?"border-top-width: 3px":"background-color: #48C; color:white"]}
		.manifest tr.head th { [monochrome?"border-top-width: 1px":"background-color: #488;"] }
		.manifest td:first-child {text-align:right}
		.manifest tr.alt td {[monochrome?"border-top-width: 2px":"background-color: #DEF"]}
	</style></head>
	<table class="manifest" width='350px'>
	<tr class='head'><th>Имя</th><th>Должность</th></tr>
	"}
	var/even = 0
	// sort mobs
	for(var/datum/data/record/t in GLOB.data_core.general)
		var/name = t.fields["name"]
		var/rank = t.fields["rank"]
		var/department_check = GetJobName(t.fields["real_rank"])
		var/department = 0
		if(department_check in GLOB.command_positions)
			heads[name] = rank
			department = 1
		if(department_check in GLOB.security_positions)
			sec[name] = rank
			department = 1
		if(department_check in GLOB.engineering_positions)
			eng[name] = rank
			department = 1
		if(department_check in GLOB.medical_positions)
			med[name] = rank
			department = 1
		if(department_check in GLOB.science_positions)
			sci[name] = rank
			department = 1
		if(department_check in GLOB.supply_positions)
			sup[name] = rank
			department = 1
		if(department_check in GLOB.civilian_positions)
			civ[name] = rank
			department = 1
		if(department_check in GLOB.law_positions)
			law[name] = rank
			department = 1
		if(department_check in GLOB.nonhuman_positions)
			bot[name] = rank
			department = 1
		if(!department && !(name in heads))
			misc[name] = rank
	if(heads.len > 0)
		dat += "<tr><th colspan=3>Heads</th></tr>"
		for(var/name in heads)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[heads[name]]</td></tr>"
			even = !even
	if(sec.len > 0)
		dat += "<tr><th colspan=3>Security</th></tr>"
		for(var/name in sec)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[sec[name]]</td></tr>"
			even = !even
	if(eng.len > 0)
		dat += "<tr><th colspan=3>Engineering</th></tr>"
		for(var/name in eng)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[eng[name]]</td></tr>"
			even = !even
	if(med.len > 0)
		dat += "<tr><th colspan=3>Medical</th></tr>"
		for(var/name in med)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[med[name]]</td></tr>"
			even = !even
	if(sci.len > 0)
		dat += "<tr><th colspan=3>Science</th></tr>"
		for(var/name in sci)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[sci[name]]</td></tr>"
			even = !even
	if(sup.len > 0)
		dat += "<tr><th colspan=3>Supply</th></tr>"
		for(var/name in sup)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[sup[name]]</td></tr>"
			even = !even
	if(law.len > 0)
		dat += "<tr><th colspan=3>Law</th></tr>"
		for(var/name in law)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[law[name]]</td></tr>"
			even = !even
	if(civ.len > 0)
		dat += "<tr><th colspan=3>Civilian</th></tr>"
		for(var/name in civ)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[civ[name]]</td></tr>"
			even = !even
	// in case somebody is insane and added them to the manifest, why not
	if(bot.len > 0)
		dat += "<tr><th colspan=3>Silicon</th></tr>"
		for(var/name in bot)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[bot[name]]</td></tr>"
			even = !even
	// misc guys
	if(misc.len > 0)
		dat += "<tr><th colspan=3>Miscellaneous</th></tr>"
		for(var/name in misc)
			dat += "<tr[even ? " class='alt'" : ""]><td>[name]</td><td>[misc[name]]</td></tr>"
			even = !even

	dat += "</table>"
	dat = replacetext(dat, "\n", "")
	dat = replacetext(dat, "\t", "")
	return dat

/datum/datacore/proc/manifest_inject(mob/living/carbon/human/H, client/C, datum/preferences/prefs)
	set waitfor = FALSE
	if(H.mind && (H.mind.assigned_role != H.mind.special_role)  && (H.mind.assigned_role != "Stowaway"))
		var/assignment
		var/real_rank
		if(H.mind.assigned_role)
			real_rank = H.mind.assigned_role
		else if(H.job)
			real_rank = H.job
		else
			real_rank = "Unassigned"

		// Берем название роли из карточки, с учетом наклеек и альт. названия
		if(H.wear_id)
			var/obj/item/card/id/id_card = H.wear_id.GetID()
			if(istype(id_card))
				assignment = id_card.get_assignment_name()
		if(!assignment)
			// Если не удалось, пробуем получить из префов
			if(C && C.prefs && C.prefs.alt_titles_preferences[assignment])
				assignment = C.prefs.alt_titles_preferences[assignment]
			// Иначе берем стандартное название
			else
				assignment = real_rank

		var/static/record_id_num = 1001
		var/id = num2hex(record_id_num++,6)
		if(!C)
			C = H.client
		var/datum/record_photo_source/photo_source = new(H, H.mind.assigned_role, C?.prefs || prefs)

		//These records should ~really~ be merged or something
		//General Record
		var/datum/data/record/G = new()
		G.fields["id"]			= id
		G.fields["name"]		= H.real_name
		G.fields["rank"]		= assignment
		G.fields["real_rank"]	= GetJobName(real_rank)
		G.fields["age"]			= H.age
		G.fields["species"]		= H.dna.species.name
		G.fields["fingerprint"]	= md5(H.dna.uni_identity)
		G.fields["p_stat"]		= "Active"
		G.fields["m_stat"]		= "Stable"
		if(H.gender == MALE)
			G.fields["gender"]  = "Male"
		else if(H.gender == FEMALE)
			G.fields["gender"]  = "Female"
		else
			G.fields["gender"]  = "Other"
		G.photo_source			= photo_source
		general += G
		general_by_name[H.real_name] = G
		general_by_id[id] = G

		//Medical Record
		var/datum/data/record/M = new()
		M.fields["id"]			= id
		M.fields["name"]		= H.real_name
		M.fields["blood_type"]	= H.dna.blood_type
		M.fields["b_dna"]		= H.dna.unique_enzymes
		M.fields["mi_dis"]		= "None"
		M.fields["mi_dis_d"]	= "No minor disabilities have been declared."
		M.fields["ma_dis"]		= "None"
		M.fields["ma_dis_d"]	= "No major disabilities have been diagnosed."
		M.fields["alg"]			= "None"
		M.fields["alg_d"]		= "No allergies have been detected in this patient."
		M.fields["cdi"]			= "None"
		M.fields["cdi_d"]		= "No diseases have been diagnosed at the moment."
		M.fields["notes"]		= "[prefs.medical_records]"
		medical += M
		medical_by_name[H.real_name] = M
		medical_by_id[id] = M

		//Security Record
		var/datum/data/record/S = new()
		S.fields["id"]			= id
		S.fields["name"]		= H.real_name
		// BLUEMOON CHANGE START - Установление статуса заключенного
		if(real_rank == "Prisoner")
			S.fields["criminal"]	= SEC_RECORD_STATUS_INCARCERATED
		else
			S.fields["criminal"]	= SEC_RECORD_STATUS_NONE
		// BLUEMOON CHANGE END
		S.fields["mi_crim"]		= list()
		S.fields["mi_crim_d"]	= list()
		S.fields["ma_crim"]		= list()
		S.fields["ma_crim_d"]	= "No major crime convictions."
		S.fields["notes"]		= prefs.security_records || "No notes."
		// BLUEMOON ADD START - логи
		S.fields["actions_logs"] = list(
			"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [H.real_name] | [assignment] | [id];</u><br>"
			)
		// BLUEMOON ADD END
		LAZYINITLIST(S.fields["comments"])
		security += S
		security_by_name[H.real_name] = S
		security_by_id[id] = S
		// BLUEMOON ADD START - Установление статуса заключенного
		if(real_rank == "Prisoner")
			H.sec_hud_set_security_status()
		// BLUEMOON ADD END

		//Locked Record
		var/datum/data/record/L = new()
		L.fields["id"]			= md5("[H.real_name][H.mind.assigned_role]")	//surely this should just be id, like the others?
		L.fields["name"]		= H.real_name
		L.fields["rank"] 		= assignment
		L.fields["real_rank"]	= GetJobName(real_rank)
		L.fields["age"]			= H.age
		if(H.gender == MALE)
			G.fields["gender"]  = "Male"
		else if(H.gender == FEMALE)
			G.fields["gender"]  = "Female"
		else
			G.fields["gender"]  = "Other"
		L.fields["blood_type"]	= H.dna.blood_type
		L.fields["b_dna"]		= H.dna.unique_enzymes
		L.fields["identity"]	= H.dna.uni_identity
		L.fields["species"]		= H.dna.species.type
		L.fields["features"]	= H.dna.features
		L.fields["mindref"]		= H.mind
		L.photo_source			= photo_source
		locked += L
		locked_by_id[L.fields["id"]] = L
	return

#undef RECORD_PHOTO_INFLIGHT_TIMEOUT
#undef RECORD_PHOTO_MAX_IN_FLIGHT

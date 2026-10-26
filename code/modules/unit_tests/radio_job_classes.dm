/// Тег должности в рации: класс отдела общий для альт-названий и фракций, главы помечены, инлайн-цвета нет.
/datum/unit_test/radio_job_classes
	var/mob/living/carbon/human/speaker
	var/mob/living/carbon/human/listener
	var/obj/item/card/id/card
	var/obj/item/radio/radio
	var/last_line
	var/last_legacy

/datum/unit_test/radio_job_classes/Run()
	speaker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	listener = allocate(/mob/living/carbon/human, get_step(speaker, EAST))
	radio = allocate(/obj/item/radio, get_step(speaker, NORTH))
	card = allocate(/obj/item/card/id)
	speaker.equip_to_slot(card, ITEM_SLOT_ID)

	var/datum/asset/spritesheet_batched/chat/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
	TEST_ASSERT_EQUAL(sheet.icon_class_name("job-captain"), "chat16x16 job-captain", "Значки профессий в чат-листе размером со строку")

	var/list/doctor = tag_classes("Medical Doctor")
	TEST_ASSERT_EQUAL(doctor[1], "radiojob-med", "Врач в медицинском отделе: [last_line]")
	TEST_ASSERT(!("radiojob-head" in doctor), "Рядовой врач не помечен главой: [last_line]")
	TEST_ASSERT_EQUAL(last_legacy, "med", "Класс старого вывода первым в теге: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-medicaldoctor", "Значок врача перед тегом: [last_line]")

	var/list/nurse = tag_classes("Medical Doctor", "Nurse")
	TEST_ASSERT_EQUAL(nurse[1], doctor[1], "Альт-название в цвет отдела профессии: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-medicaldoctor", "Альт-название со значком своей профессии: [last_line]")

	var/obj/item/card_sticker/syndicate/sticker = allocate(/obj/item/card_sticker/syndicate)
	TEST_ASSERT(sticker.wrap(card, null, silent = TRUE, force = TRUE), "Наклейка Синдиката клеится на карту")
	var/list/syndicate_doctor = tag_classes("Medical Doctor")
	TEST_ASSERT(findtext(last_line, "\[Syndicate Medical Doctor\]"), "Наклейка меняет должность в теге: [last_line]")
	TEST_ASSERT_EQUAL(syndicate_doctor[1], doctor[1], "Фракционный вариант в цвет отдела профессии: [last_line]")
	TEST_ASSERT("radiojob-f-synd" in syndicate_doctor, "Фракция остаётся модификатором: [last_line]")
	TEST_ASSERT_EQUAL(last_legacy, "synd", "Прежняя раскраска сохраняется классом: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-medicaldoctor", "Наклейка фракции не меняет значок профессии: [last_line]")
	sticker.unwrap(card, null, silent = TRUE, force = TRUE)

	var/list/cmo = tag_classes("Chief Medical Officer")
	TEST_ASSERT_EQUAL(cmo[1], doctor[1], "Глава в цвет своего отдела: [last_line]")
	TEST_ASSERT("radiojob-head" in cmo, "Главврач помечен главой: [last_line]")

	var/list/captain = tag_classes("Captain")
	TEST_ASSERT_EQUAL(captain[1], "radiojob-cmd", "Капитан в командовании: [last_line]")
	TEST_ASSERT("radiojob-head" in captain, "Капитан помечен главой: [last_line]")

	var/list/blueshield = tag_classes("Blueshield")
	TEST_ASSERT_EQUAL(blueshield[1], "radiojob-cmd", "Блюшилд в командовании: [last_line]")
	TEST_ASSERT(!("radiojob-head" in blueshield), "Блюшилд никем не руководит: [last_line]")

	var/list/psychologist = tag_classes("Psychologist")
	TEST_ASSERT_EQUAL(psychologist[1], doctor[1], "Профессия без битов отдела берёт отдел начальника: [last_line]")

	var/list/admiral = tag_classes("Syndicate Admiral")
	TEST_ASSERT_EQUAL(admiral[1], "radiojob-synd", "Роль вне станции красится фракцией: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-syndicate", "Роль вне станции со значком фракции: [last_line]")

	var/list/renamed_captain = tag_classes("Captain", "Assistant")
	TEST_ASSERT(findtext(last_line, "\[Assistant\]"), "Карта показывает новое название: [last_line]")
	TEST_ASSERT_EQUAL(renamed_captain[1], "radiojob-asst", "Цвет следует за показанной должностью: [last_line]")
	TEST_ASSERT(!("radiojob-head" in renamed_captain), "Переименованная карта капитана не выдаёт главу: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-assistant", "Значок следует за показанной должностью: [last_line]")
	TEST_ASSERT(sticker.wrap(card, null, silent = TRUE, force = TRUE), "Наклейка клеится повторно")
	var/list/stickered_captain = tag_classes("Captain", "Assistant")
	TEST_ASSERT(findtext(last_line, "\[Syndicate Assistant\]"), "Наклейка добавляет префикс к новому названию: [last_line]")
	TEST_ASSERT(!("radiojob-head" in stickered_captain), "Префикс наклейки не открывает главу под новым названием: [last_line]")
	sticker.unwrap(card, null, silent = TRUE, force = TRUE)

	var/list/free_title = tag_classes("Medical Doctor", "Senior Surgeon")
	TEST_ASSERT_EQUAL(free_title[1], doctor[1], "Свободное название остаётся в отделе профессии карты: [last_line]")
	TEST_ASSERT(!findtext(last_line, "radiojob-icon"), "Свободное название не выдаёт профессию карты значком: [last_line]")

	var/list/admiral_captain = tag_classes("Captain", "Admiral")
	TEST_ASSERT_EQUAL(admiral_captain[1], "radiojob-cmd", "Альт-название капитана, совпадающее с должностью ЦК, остаётся капитанским: [last_line]")
	TEST_ASSERT("radiojob-head" in admiral_captain, "Капитан под альт-названием остаётся главой: [last_line]")
	var/list/custodian = tag_classes("Janitor", "Custodian")
	TEST_ASSERT_EQUAL(custodian[1], "radiojob-srv", "Уборщик-Custodian в сервисе, не в ЦК: [last_line]")
	var/list/iron_ce = tag_classes("Chief Engineer", "Big Iron")
	TEST_ASSERT_EQUAL(iron_ce[1], "radiojob-eng", "Общее альт-название берёт профессию карты СИ: [last_line]")
	TEST_ASSERT("radiojob-head" in iron_ce, "СИ под общим альт-названием глава: [last_line]")
	var/list/iron_hos = tag_classes("Head of Security", "Big Iron")
	TEST_ASSERT_EQUAL(iron_hos[1], "radiojob-sec", "Общее альт-название берёт профессию карты ГСБ: [last_line]")
	TEST_ASSERT("radiojob-head" in iron_hos, "ГСБ под общим альт-названием глава: [last_line]")
	var/list/mechanic_engineer = tag_classes("Station Engineer", "Mechanic")
	TEST_ASSERT_EQUAL(mechanic_engineer[1], "radiojob-eng", "Механик-инженер в инженерии: [last_line]")
	var/list/mechanic_roboticist = tag_classes("Roboticist", "Mechanic")
	TEST_ASSERT_EQUAL(mechanic_roboticist[1], "radiojob-sci", "Механик-робототехник в науке: [last_line]")
	var/list/bob_captain = tag_classes("Captain", "Bob")
	TEST_ASSERT_EQUAL(bob_captain[1], "radiojob-cmd", "Свободное название капитана в цвет командования: [last_line]")
	TEST_ASSERT(!("radiojob-head" in bob_captain), "Свободное название не выдаёт главу: [last_line]")
	TEST_ASSERT(!findtext(last_line, "radiojob-icon"), "Свободное название на карте капитана без значка капитана: [last_line]")
	var/list/mechanic_captain = tag_classes("Captain", "Mechanic")
	TEST_ASSERT_EQUAL(mechanic_captain[1], "radiojob-cmd", "Чужое неоднозначное альт-название красится профессией карты: [last_line]")
	TEST_ASSERT(!("radiojob-head" in mechanic_captain), "Чужое неоднозначное альт-название не выдаёт главу: [last_line]")
	var/list/forged_iron = tag_classes("Big Iron")
	TEST_ASSERT_EQUAL(forged_iron[1], "radiojob-unk", "Поддельная должность с неоднозначным альт-названием не берёт чужой отдел: [last_line]")
	TEST_ASSERT(!("radiojob-head" in forged_iron), "Поддельная должность с неоднозначным альт-названием не глава: [last_line]")
	var/list/centcom_admiral = tag_classes("Admiral")
	TEST_ASSERT_EQUAL(centcom_admiral[1], "radiojob-centcom", "Карта адмирала ЦК остаётся в ЦК: [last_line]")
	TEST_ASSERT(!("radiojob-head" in centcom_admiral), "Адмирал ЦК не капитан станции: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-centcom", "Карта ЦК со значком ЦК: [last_line]")

	var/list/prisoner = tag_classes("Prisoner")
	TEST_ASSERT_EQUAL(prisoner[1], "radiojob-unk", "Заключённый не выглядит как СБ: [last_line]")

	tag_classes("Medical Doctor")
	TEST_ASSERT(!findtext(last_line, "style="), "Цвет тега не задаётся инлайном: [last_line]")
	var/list/doctor_name = name_classes()
	TEST_ASSERT_EQUAL(jointext(doctor_name, " "), "[jointext(doctor, " ")] radiojob-name-legacy-med", "Имя говорящего несёт классы тега и свой класс прежней раскраски: [last_line]")
	TEST_ASSERT(!findtext(last_line, "radiojob-name radiojob-legacy-") && !findtext(jointext(doctor_name, " "), " radiojob-legacy-"), "Старый вывод не красит имя: [last_line]")

	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot, get_step(speaker, WEST))
	var/atom/movable/virtualspeaker/borg_voice = new(null, borg, radio)
	last_line = listener.compose_message(borg_voice, /datum/language/common, "Проверка связи.", FREQ_COMMON, list())
	qdel(borg_voice)
	var/list/borg_tag = parse_tag()
	TEST_ASSERT_EQUAL(borg_tag[1], "radiojob-silicon", "Киборг в синтетиках: [last_line]")
	TEST_ASSERT_EQUAL(last_legacy, "silicon", "Тег синтетика окрашен и в старом выводе: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-cyborg", "Значок киборга: [last_line]")

	speaker.temporarilyRemoveItemFromInventory(card, force = TRUE)
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	pda.ownjob = "Syndicate Medical Doctor"
	speaker.equip_to_slot(pda, ITEM_SLOT_ID)
	var/atom/movable/virtualspeaker/pda_voice = new(null, speaker, radio)
	last_line = listener.compose_message(pda_voice, /datum/language/common, "Проверка связи.", FREQ_COMMON, list())
	qdel(pda_voice)
	TEST_ASSERT(findtext(last_line, "<span class='radiojob-legacy-synd radiojob [jointext(syndicate_doctor, " ")]'>"), "КПК без карты с префиксом наклейки даёт те же классы, что карта: [last_line]")
	TEST_ASSERT_EQUAL(icon_sprite(), "job-medicaldoctor", "КПК с наклейкой со значком профессии: [last_line]")
	pda.ownjob = "Syndicate Admiral"
	pda_voice = new(null, speaker, radio)
	last_line = listener.compose_message(pda_voice, /datum/language/common, "Проверка связи.", FREQ_COMMON, list())
	qdel(pda_voice)
	TEST_ASSERT(findtext(last_line, "<span class='radiojob-legacy-synd radiojob radiojob-synd "), "Должность Синдиката на КПК не становится альт-названием капитана: [last_line]")
	TEST_ASSERT(!findtext(last_line, "radiojob-head"), "Должность Синдиката на КПК не глава станции: [last_line]")

	var/obj/item/clothing/mask/infiltrator/mask = allocate(/obj/item/clothing/mask/infiltrator)
	speaker.equip_to_slot(mask, ITEM_SLOT_MASK)
	tag_classes("Medical Doctor")
	TEST_ASSERT(findtext(last_line, "Unknown"), "Маска скрывает голос: [last_line]")
	TEST_ASSERT(!findtext(last_line, "radiojob"), "Скрытый голос без тега, значка и класса имени: [last_line]")

/datum/unit_test/radio_job_classes/proc/tag_classes(assignment, custom_job = "")
	card.assignment = assignment
	card.custom_job = custom_job
	var/atom/movable/virtualspeaker/virt = new(null, speaker, radio)
	last_line = listener.compose_message(virt, /datum/language/common, "Проверка связи.", FREQ_COMMON, list())
	qdel(virt)
	return parse_tag()

/// Классы тега после класса старого вывода, который обязан стоять первым.
/datum/unit_test/radio_job_classes/proc/parse_tag()
	last_legacy = null
	var/regex/tag = regex("<span class='radiojob-legacy-(\[a-z\]+) radiojob (\[^'\]+)'>")
	if(!tag.Find(last_line))
		return list("")
	last_legacy = tag.group[1]
	return splittext(tag.group[2], " ")

/datum/unit_test/radio_job_classes/proc/name_classes()
	var/regex/name_span = regex("<span class='radiojob-name (\[^'\]+)'>")
	if(!name_span.Find(last_line))
		return list()
	return splittext(name_span.group[1], " ")

/// Спрайт значка, стоящего вплотную перед тегом.
/datum/unit_test/radio_job_classes/proc/icon_sprite()
	var/regex/icon = regex("<span class='radiojob-icon chat16x16 (job-\[a-z0-9\]+)'></span><span class='radiojob-legacy-")
	if(!icon.Find(last_line))
		return null
	return icon.group[1]

/datum/unit_test/radio_job_classes/Destroy()
	speaker = null
	listener = null
	card = null
	radio = null
	return ..()

/// Старый интерфейс чата (Fix chat -> old ui) красит тег должности стилями client/script: инлайн-цвета у тега больше нет.
/datum/unit_test/radio_job_legacy_stylesheet

/datum/unit_test/radio_job_legacy_stylesheet/Run()
	// /client/script без клиента не прочитать: берём исходник таблицы.
	var/stylesheet = file2text("interface/stylesheet.dm")
	TEST_ASSERT(length(stylesheet), "Таблица стилей старого вывода найдена")
	var/list/legacy_ids = list("cmd", "sec", "eng", "med", "sci", "cargo", "srv", "law", "asst", "silicon", "unk", "centcom", "clown", "synd", "inteq", "tarkon", "pirate", "sol", "nri", "hotel")
	for(var/id in legacy_ids)
		TEST_ASSERT(findtext(stylesheet, ".radiojob-legacy-[id]"), "Старый вывод красит тег radiojob-legacy-[id]")
	// До разделения по отделам имя в старом выводе было цвета канала.
	TEST_ASSERT(!findtext(stylesheet, "radiojob-name"), "Старый вывод не красит имя говорящего")

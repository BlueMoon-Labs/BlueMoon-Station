#define MANIFEST_TEST_PREFIX "Manifest Test "

/// Главы в списке экипажа: флаг главы по должности записи как в рации, глава первой строкой отдела, звёздочка в печати и у pAI.
/datum/unit_test/crew_manifest_heads

/datum/unit_test/crew_manifest_heads/Run()
	add_record("Doctor", "Medical Doctor")
	add_record("Director", "Chief Medical Officer")
	add_record("Freetext", "Chief Medical Officer")
	add_record("Bartender", "Bartender")
	add_record("Personnel", "Head of Personnel")
	add_record("Bridge", "Bridge Officer")
	add_record("Fake", "Assistant")
	add_record("Security", "Head of Security")
	add_record("Captain", "Captain")
	add_record("Renamed", "Captain")
	add_record("Stickered", "Chief Medical Officer")

	issue_card("Director", "Chief Medical Officer", "Medical Director")
	issue_card("Freetext", "Chief Medical Officer", "Bob")
	issue_card("Fake", "Assistant", "Syndicate Captain")
	issue_card("Renamed", "Captain", "Assistant")
	var/obj/item/card/id/stickered_card = issue_card("Stickered", "Chief Medical Officer")
	var/obj/item/card_sticker/syndicate/sticker = allocate(/obj/item/card_sticker/syndicate)
	TEST_ASSERT(sticker.wrap(stickered_card, null, silent = TRUE, force = TRUE), "Наклейка Синдиката клеится на карту")
	stickered_card.update_manifest()

	var/datum/crew_manifest/window = allocate(/datum/crew_manifest)
	var/list/manifest = window.ui_data(null)["manifest"]
	TEST_ASSERT_EQUAL(window.ui_static_data(null)["department_names"][DEPARTMENT_MEDICAL], "Медицинский отдел", "Окно получает русское название отдела с сервера")

	var/list/medical = test_entries(manifest, DEPARTMENT_MEDICAL)
	TEST_ASSERT_EQUAL(entry_names(medical), "Director, Freetext, Stickered, Doctor", "Главы медотдела первыми, рядовые в прежнем порядке")
	TEST_ASSERT(medical["Director"]["head"], "Главврач под альт-названием помечен главой")
	TEST_ASSERT(!medical["Doctor"]["head"], "Рядовой врач не глава")
	TEST_ASSERT(medical["Freetext"]["head"], "Свободное название на карте главврача остаётся главой, как и в рации")
	TEST_ASSERT_EQUAL(medical["Stickered"]["rank"], "Syndicate Chief Medical Officer", "Наклейка видна в должности записи")
	TEST_ASSERT(medical["Stickered"]["head"], "Префикс наклейки не снимает метку главы")

	var/list/service = test_entries(manifest, DEPARTMENT_SERVICE)
	TEST_ASSERT_EQUAL(entry_names(service), "Personnel, Bartender, Bridge, Fake", "Глава сервиса первым, бриг-офицер не глава")
	TEST_ASSERT_EQUAL(service["Fake"]["rank"], "Syndicate Captain", "Своё название карты видно в должности")
	TEST_ASSERT(!service["Fake"]["head"], "Вписанное руками \"Syndicate Captain\" на карте ассистента не глава, как и в рации")
	TEST_ASSERT(!("department_check" in service["Personnel"]), "Профессия записи не уходит в данные окна")
	TEST_ASSERT(service["Personnel"]["head"], "ГП - глава сервиса")
	TEST_ASSERT(!service["Bridge"]["head"], "Бриг-офицер никем не руководит")

	var/list/command = test_entries(manifest, DEPARTMENT_COMMAND)
	TEST_ASSERT_EQUAL(entry_names(command), "Captain, Director, Freetext, Personnel, Security, Stickered, Bridge, Renamed", "Капитан первым, затем главы, затем остальные")
	TEST_ASSERT_EQUAL(command["Renamed"]["rank"], "Assistant", "Переименованная карта меняет должность записи")
	TEST_ASSERT(!command["Renamed"]["head"], "Карта капитана под названием ассистента не выдаёт главу")

	var/cache_key = "Chief Medical Officer|Medical Director|Medical Director"
	TEST_ASSERT_EQUAL(GLOB.manifest_head_cache[cache_key], TRUE, "Ответ по главе лежит в кэше")
	GLOB.manifest_head_cache[cache_key] = FALSE
	var/from_cache = is_manifest_record_head("Chief Medical Officer", "Medical Director", "Medical Director")
	GLOB.manifest_head_cache[cache_key] = TRUE
	TEST_ASSERT_EQUAL(from_cache, FALSE, "Повторный вызов берёт ответ из кэша, а не считает класс рации заново")
	TEST_ASSERT_EQUAL(is_manifest_record_head("Chief Medical Officer", "Medical Director", "Medical Director"), TRUE, "Из кэша тот же ответ")
	TEST_ASSERT(!("Chief Medical Officer|Bob|Bob" in GLOB.manifest_head_cache), "Свободное название карты не растит кэш")

	var/obj/item/modular_computer/laptop/preset/civilian/laptop = allocate(/obj/item/modular_computer/laptop/preset/civilian, run_loc_floor_bottom_left)
	laptop.install_component(new /obj/item/computer_hardware/printer/mini)
	TEST_ASSERT_NOTNULL(laptop.all_components[MC_PRINT], "В ноутбук ставится принтер")
	var/datum/computer_file/program/crew_manifest/program = new
	var/obj/item/computer_hardware/hard_drive/drive = laptop.all_components[MC_HDD]
	TEST_ASSERT(drive.store_file(program), "Список экипажа записывается на диск")
	program.computer = laptop
	var/list/ntos_command = test_entries(program.ui_data(null)["manifest"], DEPARTMENT_COMMAND)
	TEST_ASSERT(ntos_command["Captain"]["head"], "Список экипажа в NTOS получает метку главы")
	TEST_ASSERT_EQUAL(program.ui_static_data(null)["department_names"][DEPARTMENT_COMMAND], "Командование", "NTOS получает русское название отдела")

	var/mob/living/carbon/human/reader = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/tgui/program_ui = allocate(/datum/tgui, reader, program, "NtosCrewManifest")
	program_ui.status = UI_INTERACTIVE
	usr = reader
	program.ui_act("PRG_print", list(), program_ui)
	usr = null
	var/obj/item/paper/printout = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(printout, "Печать списка экипажа выдаёт лист")
	allocated += printout
	var/datum/paper_input/printed = printout.raw_text_inputs[1]
	TEST_ASSERT(!findtext(printed.raw_text, "/list"), "Печать содержит таблицу, а не тип списка: [printed.raw_text]")
	TEST_ASSERT(findtext(printed.raw_text, "<b>★ Captain</b>"), "Глава в печати со звёздочкой и жирным: [printed.raw_text]")
	TEST_ASSERT(findtext(printed.raw_text, "<td>Medical Doctor</td>"), "Рядовой в печати без метки: [printed.raw_text]")
	TEST_ASSERT(findtext(printed.raw_text, "<th colspan=2>Медицинский отдел</th>"), "Печать берёт те же названия отделов: [printed.raw_text]")

	var/mob/living/silicon/pai/pai = allocate(/mob/living/silicon/pai, run_loc_floor_bottom_left)
	allocated += pai.card
	var/list/pai_heads = list()
	for(var/list/entry as anything in pai.ui_data(pai)["crew_manifest"])
		pai_heads[entry["name"]] = entry["head"]
	TEST_ASSERT(pai_heads[MANIFEST_TEST_PREFIX + "Director"], "pAI видит главу под альт-названием")
	TEST_ASSERT(!pai_heads[MANIFEST_TEST_PREFIX + "Doctor"], "pAI не помечает рядового")

/// Запись из manifest_inject берёт своё название с надетой карты, правка должности в консоли СБ его сбрасывает.
/datum/unit_test/crew_manifest_heads/inject

/datum/unit_test/crew_manifest_heads/inject/Run()
	var/mob/living/carbon/human/director = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/full_name = MANIFEST_TEST_PREFIX + "Injected"
	director.real_name = full_name
	director.mind_initialize()
	director.mind.assigned_role = "Chief Medical Officer"
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.assignment = "Chief Medical Officer"
	card.custom_job = "Medical Director"
	director.equip_to_slot(card, ITEM_SLOT_ID)
	var/datum/preferences/prefs = new
	allocated += prefs
	GLOB.data_core.manifest_inject(director, null, prefs)
	var/datum/data/record/general = GLOB.data_core.general_by_name[full_name]
	TEST_ASSERT_NOTNULL(general, "manifest_inject создаёт запись")
	allocated += general
	allocated += GLOB.data_core.medical_by_name[full_name]
	allocated += GLOB.data_core.security_by_name[full_name]
	allocated += GLOB.data_core.locked_by_id[md5("[full_name]Chief Medical Officer")]
	TEST_ASSERT_EQUAL(general.fields["custom_job"], "Medical Director", "Своё название карты записано при создании записи")

	var/datum/crew_manifest/window = allocate(/datum/crew_manifest)
	var/list/medical = test_entries(window.ui_data(null)["manifest"], DEPARTMENT_MEDICAL)
	TEST_ASSERT(medical["Injected"]["head"], "Главврач из manifest_inject под альт-названием глава")

	var/mob/living/carbon/human/clerk = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/computer/secure_data/console = allocate(/obj/machinery/computer/secure_data)
	console.machine_stat = NONE
	var/datum/ui_login/login = console.ui_login_get()
	login.logged_in = TRUE
	login.access = list(ACCESS_HOP)
	console.active1 = general
	var/datum/tgui/console_ui = allocate(/datum/tgui, clerk, console, "SecurityRecords")
	console_ui.status = UI_INTERACTIVE
	usr = clerk
	console.ui_act("edit_field", list("field" = "rank", "value" = "Medical Doctor"), console_ui)
	usr = null
	console.ui_login_logout(login)
	TEST_ASSERT_EQUAL(general.fields["rank"], "Medical Doctor", "Консоль СБ меняет должность записи")
	TEST_ASSERT_NULL(general.fields["custom_job"], "Правка должности сбрасывает своё название карты")
	medical = test_entries(window.ui_data(null)["manifest"], DEPARTMENT_MEDICAL)
	TEST_ASSERT(!medical["Injected"]["head"], "Разжалованный в врачи не глава по старому названию карты")

/datum/unit_test/crew_manifest_heads/proc/add_record(short_name, real_rank)
	var/datum/data/record/record = allocate(/datum/data/record)
	var/full_name = MANIFEST_TEST_PREFIX + short_name
	record.fields["name"] = full_name
	record.fields["rank"] = real_rank
	record.fields["real_rank"] = real_rank
	GLOB.data_core.general += record
	GLOB.data_core.general_by_name[full_name] = record

/// Карта на имя записи, переписывает её через update_manifest(), как консоль ГП.
/datum/unit_test/crew_manifest_heads/proc/issue_card(short_name, assignment, custom_job = "")
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_name = MANIFEST_TEST_PREFIX + short_name
	card.assignment = assignment
	card.custom_job = custom_job
	card.update_manifest()
	return card

/// Записи теста в отделе: короткое имя -> запись, в порядке манифеста.
/datum/unit_test/crew_manifest_heads/proc/test_entries(list/manifest, department)
	. = list()
	for(var/list/entry as anything in manifest[department])
		var/name = entry["name"]
		if(findtext(name, MANIFEST_TEST_PREFIX) == 1)
			.[copytext(name, length(MANIFEST_TEST_PREFIX) + 1)] = entry

/datum/unit_test/crew_manifest_heads/proc/entry_names(list/entries)
	return jointext(entries, ", ")

#undef MANIFEST_TEST_PREFIX

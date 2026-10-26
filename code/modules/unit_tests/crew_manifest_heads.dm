#define MANIFEST_TEST_PREFIX "Manifest Test "

/// Главы в списке экипажа: флаг главы по должности записи как в рации, глава первой строкой отдела, звёздочка в печати и у pAI.
/datum/unit_test/crew_manifest_heads

/datum/unit_test/crew_manifest_heads/Run()
	add_record("Doctor", "Medical Doctor", "Medical Doctor")
	add_record("Director", "Medical Director", "Chief Medical Officer")
	add_record("Freetext", "Bob", "Chief Medical Officer")
	add_record("Bartender", "Bartender", "Bartender")
	add_record("Personnel", "Head of Personnel", "Head of Personnel")
	add_record("Bridge", "Bridge Officer", "Bridge Officer")
	add_record("Security", "Head of Security", "Head of Security")
	add_record("Captain", "Captain", "Captain")
	add_record("Renamed", "Captain", "Captain")
	add_record("Stickered", "Chief Medical Officer", "Chief Medical Officer")

	var/obj/item/card/id/renamed_card = allocate(/obj/item/card/id)
	renamed_card.registered_name = MANIFEST_TEST_PREFIX + "Renamed"
	renamed_card.assignment = "Captain"
	renamed_card.custom_job = "Assistant"
	renamed_card.update_manifest()

	var/obj/item/card/id/stickered_card = allocate(/obj/item/card/id)
	stickered_card.registered_name = MANIFEST_TEST_PREFIX + "Stickered"
	stickered_card.assignment = "Chief Medical Officer"
	var/obj/item/card_sticker/syndicate/sticker = allocate(/obj/item/card_sticker/syndicate)
	TEST_ASSERT(sticker.wrap(stickered_card, null, silent = TRUE, force = TRUE), "Наклейка Синдиката клеится на карту")
	stickered_card.update_manifest()

	var/datum/crew_manifest/window = allocate(/datum/crew_manifest)
	var/list/manifest = window.ui_data(null)["manifest"]

	var/list/medical = test_entries(manifest, DEPARTMENT_MEDICAL)
	TEST_ASSERT_EQUAL(entry_names(medical), "Director, Stickered, Doctor, Freetext", "Главы медотдела первыми, рядовые в прежнем порядке")
	TEST_ASSERT(medical["Director"]["head"], "Главврач под альт-названием помечен главой")
	TEST_ASSERT(!medical["Doctor"]["head"], "Рядовой врач не глава")
	TEST_ASSERT(!medical["Freetext"]["head"], "Свободное название на карте главврача не выдаёт главу, как и в рации")
	TEST_ASSERT_EQUAL(medical["Stickered"]["rank"], "Syndicate Chief Medical Officer", "Наклейка видна в должности записи")
	TEST_ASSERT(medical["Stickered"]["head"], "Префикс наклейки не снимает метку главы")

	var/list/service = test_entries(manifest, DEPARTMENT_SERVICE)
	TEST_ASSERT_EQUAL(entry_names(service), "Personnel, Bartender, Bridge", "Глава сервиса первым, бриг-офицер не глава")
	TEST_ASSERT(service["Personnel"]["head"], "ГП - глава сервиса")
	TEST_ASSERT(!service["Bridge"]["head"], "Бриг-офицер никем не руководит")

	var/list/command = test_entries(manifest, DEPARTMENT_COMMAND)
	TEST_ASSERT_EQUAL(entry_names(command), "Captain, Director, Personnel, Security, Stickered, Freetext, Bridge, Renamed", "Капитан первым, затем главы, затем остальные")
	TEST_ASSERT_EQUAL(command["Renamed"]["rank"], "Assistant", "Переименованная карта меняет должность записи")
	TEST_ASSERT(!command["Renamed"]["head"], "Карта капитана под названием ассистента не выдаёт главу")

	var/obj/item/modular_computer/laptop/preset/civilian/laptop = allocate(/obj/item/modular_computer/laptop/preset/civilian, run_loc_floor_bottom_left)
	laptop.install_component(new /obj/item/computer_hardware/printer/mini)
	TEST_ASSERT_NOTNULL(laptop.all_components[MC_PRINT], "В ноутбук ставится принтер")
	var/datum/computer_file/program/crew_manifest/program = new
	var/obj/item/computer_hardware/hard_drive/drive = laptop.all_components[MC_HDD]
	TEST_ASSERT(drive.store_file(program), "Список экипажа записывается на диск")
	program.computer = laptop
	var/list/ntos_command = test_entries(program.ui_data(null)["manifest"], DEPARTMENT_COMMAND)
	TEST_ASSERT(ntos_command["Captain"]["head"], "Список экипажа в NTOS получает метку главы")

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

	var/mob/living/silicon/pai/pai = allocate(/mob/living/silicon/pai, run_loc_floor_bottom_left)
	allocated += pai.card
	var/list/pai_heads = list()
	for(var/list/entry as anything in pai.ui_data(pai)["crew_manifest"])
		pai_heads[entry["name"]] = entry["head"]
	TEST_ASSERT(pai_heads[MANIFEST_TEST_PREFIX + "Director"], "pAI видит главу под альт-названием")
	TEST_ASSERT(!pai_heads[MANIFEST_TEST_PREFIX + "Doctor"], "pAI не помечает рядового")

/datum/unit_test/crew_manifest_heads/proc/add_record(short_name, rank, real_rank)
	var/datum/data/record/record = allocate(/datum/data/record)
	var/full_name = MANIFEST_TEST_PREFIX + short_name
	record.fields["name"] = full_name
	record.fields["rank"] = rank
	record.fields["real_rank"] = real_rank
	GLOB.data_core.general += record
	GLOB.data_core.general_by_name[full_name] = record

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

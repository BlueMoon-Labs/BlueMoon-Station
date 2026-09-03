/// Радио после Destroy не остаётся ни в одном списке частот, хотя снимается только со своих.
/datum/unit_test/radio_destroy_leaves_frequency_lists/Run()
	var/obj/item/radio/headset/headset_sec/radio = allocate(/obj/item/radio/headset/headset_sec)
	TEST_ASSERT(radio in GLOB.all_radios["[radio.frequency]"], "предпосылка: гарнитура не встала на общую частоту")
	TEST_ASSERT(length(radio.secure_radio_connections), "предпосылка: у гарнитуры СБ нет защищённых каналов")
	for(var/ch_name in radio.secure_radio_connections)
		var/freq = radio.secure_radio_connections[ch_name]
		TEST_ASSERT(radio in GLOB.all_radios["[freq]"], "предпосылка: гарнитура не встала на канал [ch_name]")

	qdel(radio)

	for(var/freq in GLOB.all_radios)
		TEST_ASSERT(!(radio in GLOB.all_radios[freq]), "уничтоженная гарнитура осталась на частоте [freq]")

/// Эмодзи, рингтоны и список мессенджеров не уезжают в ui_data каждую секунду.
/datum/unit_test/messenger_static_payload_stays_static/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/modular_computer/pda/first_pda = allocate(/obj/item/modular_computer/pda)
	var/obj/item/modular_computer/pda/second_pda = allocate(/obj/item/modular_computer/pda)
	first_pda.saved_identification = "Первый"
	second_pda.saved_identification = "Второй"
	var/datum/computer_file/program/messenger/first = locate(/datum/computer_file/program/messenger) in first_pda.get_all_files()
	var/datum/computer_file/program/messenger/second = locate(/datum/computer_file/program/messenger) in second_pda.get_all_files()
	TEST_ASSERT_NOTNULL(first, "предпосылка: в ПДА нет мессенджера")
	TEST_ASSERT_NOTNULL(second, "предпосылка: во втором ПДА нет мессенджера")

	var/list/dynamic = first.ui_data(user)
	var/list/static_data = first.ui_static_data(user)
	for(var/key in list("emoji_base64", "emoji_list", "ringtone_list"))
		TEST_ASSERT(!(key in dynamic), "[key] всё ещё уходит в ui_data")
		TEST_ASSERT(key in static_data, "[key] пропал из ui_static_data")

	var/list/first_sees = first.get_messengers()
	var/list/second_sees = second.get_messengers()
	TEST_ASSERT(REF(second) in first_sees, "первый мессенджер не видит второй")
	TEST_ASSERT(!(REF(first) in first_sees), "мессенджер видит сам себя")
	TEST_ASSERT(REF(first) in second_sees, "второй мессенджер не видит первый")
	TEST_ASSERT(!(REF(second) in second_sees), "второй мессенджер видит сам себя")

/// VV не пропускает загруженную картинку не в .dmi: анимированный GIF в appearance роняет DreamDaemon.
/datum/unit_test/vv_icon_upload_guard/Run()
	TEST_ASSERT(vv_upload_is_dmi("icons/mob/mob.dmi"), ".dmi обязан проходить")
	TEST_ASSERT(vv_upload_is_dmi("Pat-pat.DMI"), "регистр расширения не должен мешать")
	TEST_ASSERT(!vv_upload_is_dmi("Ricardo32.gif"), "GIF обязан отсекаться")
	TEST_ASSERT(!vv_upload_is_dmi("Prop.png"), "PNG обязан отсекаться")
	TEST_ASSERT(!vv_upload_is_dmi("dmi.gif"), "суффикс, а не вхождение")
	TEST_ASSERT(vv_upload_is_image("Ricardo32.gif"), "GIF это картинка")
	TEST_ASSERT(vv_upload_is_image("photo.jpeg"), "JPEG это картинка")
	TEST_ASSERT(!vv_upload_is_image("track.ogg"), "звук картинкой не считается")

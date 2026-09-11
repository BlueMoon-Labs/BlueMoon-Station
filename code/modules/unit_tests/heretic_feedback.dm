/// Индикатор появляется после выбора любого пути и берёт данные из его реального запаса.
/datum/unit_test/heretic_resource_hud_paths/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/body = heretic.owner.current
		heretic.selected_path = path_id
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		heretic.gain_knowledge(path.knowledge[1])
		var/datum/eldritch_knowledge/knowledge = heretic.get_knowledge(path.knowledge[1])
		var/list/resource = knowledge.get_combat_resource_data()
		var/atom/movable/screen/alert/heretic_resource/indicator = body.alerts["heretic_path_resource"]
		TEST_ASSERT(indicator, "У пути [path_id] должен появляться постоянный индикатор.")
		TEST_ASSERT_EQUAL(indicator.displayed_value, resource["value"], "HUD и кодекс должны показывать один запас [path_id].")
		TEST_ASSERT_EQUAL(indicator.displayed_max, resource["max"], "HUD должен знать текущий предел [path_id].")
		TEST_ASSERT(indicator.icon_state in icon_states(indicator.icon), "У индикатора [path_id] должно быть существующее изображение.")
		TEST_ASSERT_EQUAL(indicator.icon, 'modular_bluemoon/icons/obj/heretic_alerts.dmi', "HUD использует отдельный лист значков.")
		TEST_ASSERT_EQUAL(indicator.icon_state, "sigil_[lowertext(path_id)]", "HUD показывает знак выбранного пути.")
		TEST_ASSERT(knowledge.grasp_visual && knowledge.grasp_sound, "Каждому пути нужны собственные визуал и звук хватки.")
		qdel(heretic)
		TEST_ASSERT_NULL(body.alerts["heretic_path_resource"], "Удалённая роль не оставляет индикатор.")

/// Получение, расход и отказ от расхода обновляют HUD в тот же вызов, без ожидания обработки мира.
/datum/unit_test/heretic_resource_hud_changes/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/body = heretic.owner.current
	for(var/index in 1 to 5)
		body.throw_alert("earlier_alert_[index]", /atom/movable/screen/alert)
	heretic.selected_path = PATH_BLADE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blade)
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/atom/movable/screen/alert/heretic_resource/indicator = body.alerts["heretic_path_resource"]
	TEST_ASSERT(indicator, "Индикатор Темпа должен появиться при изучении пути.")
	TEST_ASSERT_EQUAL(body.alerts[1], "earlier_alert_1", "Запас пути не вытесняет более ранние предупреждения о состоянии тела.")
	TEST_ASSERT_EQUAL(body.alerts[6], "heretic_path_resource", "Индикатор запаса сохраняет обычный порядок предупреждений.")
	TEST_ASSERT_EQUAL(length(body.alerts), 6, "Индикатор не должен удалять предыдущие предупреждения.")
	TEST_ASSERT_EQUAL(indicator.displayed_value, initial(knowledge.combat_resource), "HUD показывает начальный Темп.")
	TEST_ASSERT(knowledge.spend_combat_resource(knowledge.combat_resource), "Начальный Темп можно потратить.")
	TEST_ASSERT_EQUAL(indicator.displayed_value, 0, "Индикатор сохраняется и показывает опустевший запас.")
	knowledge.gain_combat_resource(2)
	TEST_ASSERT_EQUAL(indicator.displayed_value, 2, "Получение Темпа немедленно видно на HUD.")
	TEST_ASSERT(!knowledge.spend_combat_resource(3), "Нельзя потратить больше накопленного Темпа.")
	TEST_ASSERT_EQUAL(indicator.displayed_value, 2, "Неудачный расход не меняет индикатор.")
	TEST_ASSERT(knowledge.spend_combat_resource(), "Накопленный Темп можно потратить.")
	TEST_ASSERT_EQUAL(indicator.displayed_value, 1, "Расход немедленно виден на HUD.")
	knowledge.gain_combat_resource(100)
	TEST_ASSERT_EQUAL(indicator.displayed_value, knowledge.combat_resource_max, "HUD показывает ограниченный запас, а не запрошенное начисление.")
	TEST_ASSERT_EQUAL(body.alerts["heretic_path_resource"], indicator, "Обновления должны сохранять один экземпляр индикатора.")
	TEST_ASSERT_EQUAL(indicator.owner, body, "Обновлённый индикатор сохраняет владельца.")

/// При переселении индикатор следует за разумом, а снятая роль больше не может его создать.
/datum/unit_test/heretic_resource_hud_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/old_body = heretic.owner.current
	heretic.selected_path = PATH_ASH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	heretic.apply_innate_effects(old_body)
	var/datum/eldritch_knowledge/base_ash/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	knowledge.gain_combat_resource(2)
	var/atom/movable/screen/alert/heretic_resource/old_indicator = old_body.alerts["heretic_path_resource"]
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_NULL(old_body.alerts["heretic_path_resource"], "Покинутое тело не должно видеть ресурс роли.")
	TEST_ASSERT(QDELETED(old_indicator), "Индикатор прежнего тела должен удаляться.")
	var/atom/movable/screen/alert/heretic_resource/new_indicator = new_body.alerts["heretic_path_resource"]
	TEST_ASSERT(new_indicator, "Новое тело получает индикатор без повторного исследования.")
	TEST_ASSERT_EQUAL(new_indicator.displayed_value, initial(knowledge.combat_resource) + 2, "Смена тела сохраняет накопленные угольки.")
	heretic.clear_heretic()
	TEST_ASSERT_NULL(new_body.alerts["heretic_path_resource"], "Снятие роли убирает индикатор нового тела.")
	knowledge.gain_combat_resource()
	TEST_ASSERT_NULL(new_body.alerts["heretic_path_resource"], "Запоздавшее начисление не возвращает индикатор снятой роли.")

/// HUD объектов реагирует на создание, разрушение и исследование увеличенного предела.
/datum/unit_test/heretic_resource_hud_objects/Run()
	var/datum/antagonist/heretic/moon_heretic = allocate_heretic()
	var/mob/living/moon_body = moon_heretic.owner.current
	moon_heretic.selected_path = PATH_MOON
	moon_heretic.gain_knowledge(/datum/eldritch_knowledge/base_moon)
	var/datum/eldritch_knowledge/base_moon/moon = moon_heretic.get_knowledge(/datum/eldritch_knowledge/base_moon)
	var/atom/movable/screen/alert/heretic_resource/moon_indicator = moon_body.alerts["heretic_path_resource"]
	TEST_ASSERT(moon_indicator, "HUD Луны должен появляться до создания первого отражения.")
	var/mob/living/simple_animal/hostile/illusion/heretic_moon/reflection = moon.create_reflection(moon_body, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(reflection, "Свободный пол должен принять отражение.")
	TEST_ASSERT_EQUAL(moon_indicator.displayed_value, 1, "Создание отражения немедленно видно на HUD.")
	qdel(reflection)
	TEST_ASSERT_EQUAL(moon_indicator.displayed_value, 0, "Разбитое отражение немедленно исчезает из счётчика.")
	moon_heretic.gain_knowledge(/datum/eldritch_knowledge/moon_upgrade)
	TEST_ASSERT_EQUAL(moon_indicator.displayed_max, moon.reflection_limit(), "Изучение дополнительного отражения обновляет предел HUD.")
	var/datum/antagonist/heretic/cosmic_heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/cosmic_body = cosmic_heretic.owner.current
	cosmic_heretic.selected_path = PATH_COSMIC
	cosmic_heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = cosmic_heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/atom/movable/screen/alert/heretic_resource/cosmic_indicator = cosmic_body.alerts["heretic_path_resource"]
	TEST_ASSERT(cosmic_indicator, "HUD Космоса должен появляться до первой звезды.")
	TEST_ASSERT(cosmic.add_star(get_turf(cosmic_body), cosmic_body), "Свободный пол должен принять звезду.")
	TEST_ASSERT_EQUAL(cosmic_indicator.displayed_value, 1, "Зажжённая звезда немедленно появляется на HUD.")
	cosmic_heretic.gain_knowledge(/datum/eldritch_knowledge/cosmic_expansion)
	TEST_ASSERT_EQUAL(cosmic_indicator.displayed_max, cosmic.star_limit(), "Расширение созвездия обновляет предел HUD.")
	cosmic.clear_stars()
	TEST_ASSERT_EQUAL(cosmic_indicator.displayed_value, 0, "Погашенное созвездие немедленно исчезает из счётчика.")

/// Износ корпуса не вызывает обработчики урона компьютера и не добивает диск с файлами.
/datum/unit_test/heretic_rust_preserves_computer_files
	var/computer_damage_events = 0

/datum/unit_test/heretic_rust_preserves_computer_files/proc/on_computer_damage(datum/source)
	SIGNAL_HANDLER
	computer_damage_events++

/datum/unit_test/heretic_rust_preserves_computer_files/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/modular_computer/tablet/preset/cheap/computer = allocate(/obj/item/modular_computer/tablet/preset/cheap, victim)
	TEST_ASSERT(victim.put_in_hands(computer), "Планшет должен находиться в руке носителя метки.")
	var/obj/item/computer_hardware/hard_drive/drive = computer.all_components[MC_HDD]
	TEST_ASSERT(drive, "Настоящий планшет должен содержать установленный диск.")
	var/datum/computer_file/data/document = allocate(/datum/computer_file/data)
	document.filename = "field_notes"
	document.stored_data = "Журнал экспедиции: образцы доставлены в лабораторию."
	TEST_ASSERT(drive.store_file(document), "Документ должен записаться на диск до повреждения.")
	var/list/files_before = drive.stored_files.Copy()
	drive.obj_integrity = 1
	var/integrity_before = computer.obj_integrity
	RegisterSignal(computer, COMSIG_ATOM_TAKE_DAMAGE, PROC_REF(on_computer_damage))
	var/datum/status_effect/eldritch/rust/mark = victim.apply_status_effect(/datum/status_effect/eldritch/rust)
	mark.on_effect()
	TEST_ASSERT(computer.obj_integrity < integrity_before, "Метка должна изнашивать корпус планшета.")
	// Сигнал проверяется отдельно: обычный урон задевает HDD случайно, что сделало бы тест нестабильным.
	TEST_ASSERT_EQUAL(computer_damage_events, 0, "Поверхностная ржавчина не должна запускать цепочку обычного урона.")
	TEST_ASSERT(!QDELETED(drive), "Метка не должна добивать повреждённый диск внутри устройства.")
	TEST_ASSERT_EQUAL(drive.obj_integrity, 1, "Прочность внутреннего диска должна остаться прежней.")
	TEST_ASSERT_EQUAL(computer.all_components[MC_HDD], drive, "Диск должен оставаться установленным в планшете.")
	TEST_ASSERT_EQUAL(length(drive.stored_files), length(files_before), "Метка не должна удалять файлы с диска.")
	for(var/datum/computer_file/file as anything in files_before)
		TEST_ASSERT(!QDELETED(file) && (file in drive.stored_files), "Все исходные файлы должны сохраниться на диске.")
	TEST_ASSERT_EQUAL(document.stored_data, "Журнал экспедиции: образцы доставлены в лабораторию.", "Содержимое документа должно остаться неизменным.")


/// Публичный API владеет порядком предупреждений, включая замену типа и очистку.
/datum/unit_test/heretic_resource_alert_order_api/Run()
	var/mob/living/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/atom/movable/screen/alert/older = body.throw_alert("older", /atom/movable/screen/alert)
	var/atom/movable/screen/alert/newer = body.throw_alert("newer", /atom/movable/screen/alert)
	TEST_ASSERT_EQUAL(body.alerts[1], "older", "Обычные предупреждения сохраняют порядок создания.")
	var/atom/movable/screen/alert/resource = body.throw_alert("resource", /atom/movable/screen/alert/heretic_resource, place_first = TRUE)
	TEST_ASSERT_EQUAL(body.alerts[1], "resource", "Запрошенный первый слот назначает throw_alert.")
	TEST_ASSERT_EQUAL(body.alerts[2], "older", "Приоритетное предупреждение сохраняет порядок остальных.")
	TEST_ASSERT_EQUAL(body.alerts[3], "newer", "Последнее обычное предупреждение остаётся последним.")
	TEST_ASSERT_EQUAL(body.throw_alert("resource", /atom/movable/screen/alert/heretic_resource, place_first = TRUE), resource, "Обновление возвращает тот же объект.")
	var/atom/movable/screen/alert/replacement = body.throw_alert("resource", /atom/movable/screen/alert, place_first = TRUE)
	TEST_ASSERT(QDELETED(resource), "Смена типа удаляет предыдущий объект.")
	TEST_ASSERT_EQUAL(body.alerts[1], "resource", "Смена типа сохраняет запрошенный первый слот.")
	TEST_ASSERT_EQUAL(body.alerts["resource"], replacement, "После замены категория связана с новым объектом.")
	body.clear_alert("resource")
	TEST_ASSERT(QDELETED(replacement), "Обычная очистка удаляет заменённый объект.")
	TEST_ASSERT_EQUAL(body.alerts["older"], older, "Очистка сохраняет первое независимое предупреждение.")
	TEST_ASSERT_EQUAL(body.alerts["newer"], newer, "Очистка сохраняет второе независимое предупреждение.")

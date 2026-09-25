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
		var/obj/effect/proc_holder/spell/power = indicator.power_ref?.resolve()
		TEST_ASSERT(power && (power in body.mind.spell_list), "Индикатор [path_id] должен вызывать выданную владельцу силу.")
		TEST_ASSERT(findtext(indicator.desc, power.name), "Подсказка [path_id] должна называть доступную силу.")
		TEST_ASSERT(indicator.icon_state in icon_states(indicator.icon), "У индикатора [path_id] должно быть существующее изображение.")
		TEST_ASSERT_EQUAL(indicator.icon, 'modular_bluemoon/icons/obj/heretic_alerts.dmi', "HUD использует отдельный лист значков.")
		TEST_ASSERT_EQUAL(indicator.icon_state, "sigil_[lowertext(path_id)]", "HUD показывает знак выбранного пути.")
		TEST_ASSERT(knowledge.grasp_visual && knowledge.grasp_sound, "Каждому пути нужны собственные визуал и звук хватки.")
		qdel(heretic)
		TEST_ASSERT_NULL(body.alerts["heretic_path_resource"], "Удалённая роль не оставляет индикатор.")

/// Нажатие индикатора применяет настоящую силу и соблюдает её ограничения.
/datum/unit_test/heretic_resource_hud_activation/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/body = heretic.owner.current
	var/datum/eldritch_knowledge/base_ash/ash = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/atom/movable/screen/alert/heretic_resource/indicator = body.alerts["heretic_path_resource"]
	var/mob/living/outsider = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	TEST_ASSERT(!indicator.activate_power(outsider), "Чужой персонаж не может нажать индикатор владельца.")
	body.adjustBruteLoss(30)
	body.adjustFireLoss(30)
	var/resource_before = ash.combat_resource
	TEST_ASSERT(indicator.activate_power(body), "Индикатор применяет доступное Угасание.")
	TEST_ASSERT_EQUAL(body.getBruteLoss(), 20, "Угасание лечит ушибы владельца.")
	TEST_ASSERT_EQUAL(body.getFireLoss(), 15, "Угасание лечит ожоги владельца.")
	TEST_ASSERT_EQUAL(ash.combat_resource, resource_before - 1, "Применение расходует уголёк.")
	TEST_ASSERT(!indicator.activate_power(body), "Повторное нажатие не обходит перезарядку.")
	TEST_ASSERT_EQUAL(ash.combat_resource, resource_before - 1, "Перезарядка не расходует второй уголёк.")
	ash.combat_power.charge_counter = ash.combat_power.charge_max
	body.Paralyze(10 SECONDS)
	TEST_ASSERT(!indicator.activate_power(body), "Нельзя применить силу в параличе.")
	body.SetParalyzed(0)
	ash.combat_resource = 0
	TEST_ASSERT(!indicator.activate_power(body), "Недостаток силы не обходится нажатием индикатора.")
	qdel(ash.combat_power)
	TEST_ASSERT(!indicator.activate_power(body), "Удалённая сила не остаётся доступной через индикатор.")

/// HUD адресных сил сохраняет заряд до выбора цели и отменяет подготовленную силу.
/datum/unit_test/heretic_resource_hud_pointed/Run()
	for(var/path_id in list(PATH_MOON, PATH_COSMIC, PATH_LOCK, PATH_SPIRIT, PATH_BLOOD, PATH_GLASS))
		var/datum/antagonist/heretic/heretic = allocate_deed_heretic(path_id)
		var/mob/living/body = heretic.owner.current
		var/atom/movable/screen/alert/heretic_resource/indicator = body.alerts["heretic_path_resource"]
		TEST_ASSERT(indicator, "Путь [path_id] должен выдать индикатор силы.")
		var/obj/effect/proc_holder/spell/pointed/power = indicator.power_ref?.resolve()
		TEST_ASSERT(istype(power), "У [path_id] должна быть адресная сила.")
		TEST_ASSERT(indicator.activate_power(body), "Готовая сила [path_id] доступна через HUD.")
		TEST_ASSERT_EQUAL(power.charge_counter, power.charge_max, "Выбор цели [path_id] не расходует заряд и не оставляет вечную перезарядку.")
		// У тестового тела нет клиента: подключаем подготовленный прицел для проверки отмены.
		power.active = TRUE
		power.ranged_ability_user = body
		body.ranged_ability = power
		body.click_intercept = power
		TEST_ASSERT(indicator.activate_power(body), "Повторное нажатие [path_id] отменяет прицел.")
		TEST_ASSERT(!power.active, "Подготовленная сила [path_id] должна отключиться.")
		TEST_ASSERT_NULL(body.ranged_ability, "Отмена [path_id] освобождает адресную способность.")
		TEST_ASSERT_NULL(body.click_intercept, "Отмена [path_id] освобождает перехват кликов.")
		TEST_ASSERT_EQUAL(power.charge_counter, power.charge_max, "Отмена [path_id] сохраняет заряд.")
		qdel(heretic)

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
	moon_heretic.gain_knowledge(/datum/eldritch_knowledge/moon_shroud)
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

/// Пока кодекс ни разу не призван, на экране висит подсказка; первый призыв её убирает насовсем.
/datum/unit_test/heretic_codex_alert/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/body = heretic.owner.current
	heretic.equip_cultist()
	heretic.apply_innate_effects(body)
	var/atom/movable/screen/alert/indicator = body.alerts["heretic_codex"]
	TEST_ASSERT(indicator, "До первого призыва кодекса еретик видит подсказку.")
	TEST_ASSERT(indicator.icon_state in icon_states(indicator.icon), "У подсказки должно быть существующее изображение.")
	var/obj/effect/proc_holder/spell/self/heretic_summon/book/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_summon/book)
	spell.cast(list(body), body)
	TEST_ASSERT(locate(/obj/item/forbidden_book) in body.held_items, "Призыв кладёт кодекс в руку.")
	TEST_ASSERT_NULL(body.alerts["heretic_codex"], "После призыва подсказка исчезает.")
	spell.cast(list(body), body)
	TEST_ASSERT_NULL(locate(/obj/item/forbidden_book) in body.held_items, "Повторный призыв прячет кодекс.")
	heretic.remove_innate_effects(body)
	heretic.apply_innate_effects(body)
	TEST_ASSERT_NULL(body.alerts["heretic_codex"], "Спрятанный после призыва кодекс подсказку не возвращает.")

/// Снятие роли убирает подсказку о кодексе вместе с остальными индикаторами.
/datum/unit_test/heretic_codex_alert_removal/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/body = heretic.owner.current
	heretic.equip_cultist()
	heretic.apply_innate_effects(body)
	TEST_ASSERT(body.alerts["heretic_codex"], "Подсказка появляется вместе с ролью.")
	qdel(heretic)
	TEST_ASSERT_NULL(body.alerts["heretic_codex"], "Удалённая роль не оставляет подсказку.")

/// Кнопки заклинаний путей и новых действий берутся из существующих стейтов, внутри пути нет двух одинаковых кнопок.
/datum/unit_test/heretic_action_buttons/Run()
	var/list/path_tokens = list(
		PATH_BLADE = list("heretic_blade", "heretic_lunge", "heretic_feint"),
		PATH_MOON = list("heretic_moon"),
		PATH_COSMIC = list("/spell/self/cosmic/"),
		PATH_LOCK = list("heretic_lock"),
		PATH_TIDE = list("heretic_tide"),
		PATH_GLASS = list("heretic_glass"),
		PATH_BLOOD = list("heretic_blood"),
		PATH_ECHO = list("heretic_echo"),
		PATH_SAND = list("heretic_sand"),
		PATH_WAX = list("heretic_wax"),
		PATH_SPIRIT = list("heretic_spirit"),
	)
	var/list/states_by_icon = list()
	var/list/seen = list()
	var/checked = 0
	for(var/spell_type in subtypesof(/obj/effect/proc_holder/spell))
		var/obj/effect/proc_holder/spell/spell = spell_type
		var/obj/effect/proc_holder/spell/parent = type2parent(spell_type)
		if(initial(spell.name) == initial(parent.name))
			continue
		var/type_text = "[spell_type]"
		var/path_id
		for(var/candidate in path_tokens)
			for(var/token in path_tokens[candidate])
				if(findtext(type_text, token))
					path_id = candidate
		if(!path_id)
			continue
		var/icon_key = "[initial(spell.action_icon)]"
		if(!states_by_icon[icon_key])
			states_by_icon[icon_key] = icon_states(initial(spell.action_icon))
		var/state = initial(spell.action_icon_state)
		TEST_ASSERT(state in states_by_icon[icon_key], "Кнопка [spell_type] ([state]) есть в [icon_key].")
		var/button_key = "[path_id]:[icon_key]:[state]"
		TEST_ASSERT(!seen[button_key], "[spell_type] и [seen[button_key]] пути [path_id] показывают одну кнопку [state].")
		seen[button_key] = spell_type
		checked++
	TEST_ASSERT(checked >= 70, "Проверены кнопки всех путей: [checked].")
	var/list/action_states = icon_states('modular_bluemoon/icons/obj/heretic_actions.dmi')
	for(var/action_type in list(/datum/action/innate/heretic_pocket_leave, /datum/action/innate/heretic_blade_surrender))
		var/datum/action/action = action_type
		TEST_ASSERT_EQUAL(initial(action.icon_icon), 'modular_bluemoon/icons/obj/heretic_actions.dmi', "[action_type] берёт кнопку из листа способностей еретика.")
		TEST_ASSERT(initial(action.button_icon_state) in action_states, "Кнопка [action_type] существует.")
	var/atom/movable/screen/alert/heretic_moon_door/door = /atom/movable/screen/alert/heretic_moon_door
	TEST_ASSERT_EQUAL(initial(door.icon_state), "moon_door", "Кнопка «Увести в отражение» отличается от знака Луны.")
	TEST_ASSERT(initial(door.icon_state) in icon_states(initial(door.icon)), "Стейт двери Луны существует.")

/// Алерты состояний рисуются своими стейтами: внутри пути нет двух одинаковых, и ни один не повторяет знак пути.
/datum/unit_test/heretic_status_alert_icons/Run()
	var/list/groups = list(
		PATH_BLADE = list(/atom/movable/screen/alert/status_effect/heretic_parry, /atom/movable/screen/alert/status_effect/heretic_blade_oath, /atom/movable/screen/alert/status_effect/heretic_blade_brand, /atom/movable/screen/alert/status_effect/heretic_blade_throat),
		PATH_MOON = list(/atom/movable/screen/alert/status_effect/heretic_lunatic, /atom/movable/screen/alert/status_effect/heretic_moon_daze, /atom/movable/screen/alert/status_effect/heretic_moon_sleepwalk, /atom/movable/screen/alert/heretic_moon_door),
		PATH_ECHO = list(/atom/movable/screen/alert/status_effect/heretic_echo_ringing, /atom/movable/screen/alert/status_effect/heretic_echo_dissonance, /atom/movable/screen/alert/status_effect/heretic_echo_lullaby, /atom/movable/screen/alert/status_effect/heretic_echo_hush),
		PATH_BLOOD = list(/atom/movable/screen/alert/status_effect/heretic_blood_clot, /atom/movable/screen/alert/status_effect/heretic_blood_slip, /atom/movable/screen/alert/status_effect/heretic_blood_exsanguinated, /atom/movable/screen/alert/status_effect/heretic_blood_drain, /atom/movable/screen/alert/status_effect/heretic_blood_trail),
		PATH_SPIRIT = list(/atom/movable/screen/alert/status_effect/heretic_spirit_hold, /atom/movable/screen/alert/status_effect/heretic_spirit_incorporeal),
		PATH_WAX = list(/atom/movable/screen/alert/status_effect/heretic_wax_seal, /atom/movable/screen/alert/status_effect/heretic_wax_clinging, /atom/movable/screen/alert/status_effect/heretic_wax_effigy, /atom/movable/screen/alert/status_effect/heretic_wax_melting, /atom/movable/screen/alert/status_effect/heretic_wax_leak),
		PATH_RUST = list(/atom/movable/screen/alert/heretic_rust_healing),
		PATH_VOID = list(/atom/movable/screen/alert/status_effect/heretic_domain, /atom/movable/screen/alert/status_effect/heretic_void_chill),
		PATH_COSMIC = list(/atom/movable/screen/alert/status_effect/heretic_cosmic_orbit),
		PATH_TIDE = list(/atom/movable/screen/alert/status_effect/heretic_drenched, /atom/movable/screen/alert/status_effect/heretic_tide_drowning),
		PATH_GLASS = list(/atom/movable/screen/alert/status_effect/heretic_glass_fracture),
		PATH_SAND = list(/atom/movable/screen/alert/status_effect/heretic_sand_recall, /atom/movable/screen/alert/status_effect/heretic_sand_stasis, /atom/movable/screen/alert/status_effect/heretic_sand_rewind, /atom/movable/screen/alert/status_effect/heretic_sand_drought),
	)
	for(var/path_id in groups)
		var/list/seen = list()
		for(var/alert_type in groups[path_id])
			var/atom/movable/screen/alert/alert = alert_type
			var/state = initial(alert.icon_state)
			TEST_ASSERT(state in icon_states(initial(alert.icon)), "[alert_type]: стейт [state] есть в листе.")
			TEST_ASSERT_NOTEQUAL(state, "sigil_[lowertext(path_id)]", "[alert_type] не повторяет знак пути.")
			TEST_ASSERT(!seen[state], "[alert_type] и [seen[state]] показывают один значок [state].")
			seen[state] = alert_type
	var/list/alert_states = icon_states('modular_bluemoon/icons/obj/heretic_alerts.dmi')
	for(var/distance in list("close", "medium", "far", "direct", "null"))
		TEST_ASSERT("blood_trail_[distance]" in alert_states, "Стейт следа крови [distance] есть в листе.")

/// Кромка разрыва изнанки красится чернилами пути владельца.
/datum/unit_test/heretic_pocket_rift_tint/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_MOON
	var/datum/heretic_pocket/pocket = new(heretic)
	allocated += pocket
	var/obj/effect/heretic_pocket_rift/rift = new(run_loc_floor_bottom_left, pocket)
	allocated += rift
	var/glow_color
	for(var/mutable_appearance/glow as anything in rift.overlays)
		if(glow.icon_state == "[rift.icon_state]_glow" && glow.plane != EMISSIVE_PLANE)
			glow_color = lowertext(glow.color)
	TEST_ASSERT_EQUAL(glow_color, lowertext(heretic_path_ink(PATH_MOON)), "Кромка разрыва Луны окрашена её чернилами.")

/obj/item/radio/headset/click_probe
	var/clicks = 0

/obj/item/radio/headset/click_probe/transmit_click(mob/living/speaker)
	clicks++

/datum/unit_test/heretic_radio_jam_click/proc/jam(atom/movable/source, obj/item/radio/radio)
	SIGNAL_HANDLER
	return COMPONENT_CANNOT_USE_RADIO

/// Заглушённая рация не щёлкает гарнитурой: щелчок звучит, только когда передача и правда уходит.
/datum/unit_test/heretic_radio_jam_click/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/radio/headset/click_probe/headset = allocate(/obj/item/radio/headset/click_probe, run_loc_floor_bottom_left)
	headset.on = TRUE
	RegisterSignal(speaker, COMSIG_MOVABLE_USING_RADIO, PROC_REF(jam))
	headset.talk_into(speaker, "Проверка связи.", null)
	TEST_ASSERT_EQUAL(headset.clicks, 0, "Заглушённый говорящий не щёлкает гарнитурой.")
	UnregisterSignal(speaker, COMSIG_MOVABLE_USING_RADIO)
	headset.talk_into(speaker, "Проверка связи.", null)
	TEST_ASSERT_EQUAL(headset.clicks, 1, "Без глушения гарнитура щёлкает.")

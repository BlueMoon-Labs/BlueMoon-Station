/// Начальные цвета вещей лоадаута без альфы: восьмизначный цвет рвал выдачу лоадаута на старте раунда.
/datum/unit_test/loadout_initial_colors_are_rgb/Run()
	var/static/regex/rgb_color = regex(@"^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$")
	var/checked = 0
	for(var/category in GLOB.loadout_items)
		for(var/subcategory in GLOB.loadout_items[category])
			for(var/gear_name in GLOB.loadout_items[category][subcategory])
				var/datum/gear/gear = GLOB.loadout_items[category][subcategory][gear_name]
				for(var/color in gear.loadout_initial_colors)
					checked++
					TEST_ASSERT(istext(color) && rgb_color.Find(color), "[gear.type]: начальный цвет [color] не в формате RGB/RRGGBB")
	TEST_ASSERT(checked, "Санити: в лоадауте не нашлось ни одного начального цвета")

/// Полихромный цвет добивается начальными цветами, если в слоте сохранено меньше цветов, чем слоёв.
/datum/unit_test/loadout_polychromic_colors_padded/Run()
	var/datum/gear/gear = new
	gear.loadout_initial_colors = list("#111111", "#222222", "#333333")
	var/list/user_gear = list()
	user_gear[LOADOUT_COLOR] = list("#FFFFFF")

	gear.pad_polychromic_colors(user_gear)
	var/list/colors = user_gear[LOADOUT_COLOR]
	TEST_ASSERT_EQUAL(length(colors), 3, "Цветов должно стать столько же, сколько слоёв")
	TEST_ASSERT_EQUAL(colors[1], "#FFFFFF", "Сохранённый цвет не должен перезаписываться")
	TEST_ASSERT_EQUAL(colors[3], "#333333", "Недостающий цвет берётся из начальных")

	var/list/empty_gear = list()
	gear.pad_polychromic_colors(empty_gear)
	TEST_ASSERT_EQUAL(length(empty_gear[LOADOUT_COLOR]), 3, "Без сохранённых цветов берутся все начальные")
	qdel(gear)

/// Рука касательного заклинания, удалённая посреди удара, не роняет проверку зарядов.
/datum/unit_test/touch_hand_deleted_mid_attack/Run()
	var/obj/effect/proc_holder/spell/targeted/touch/disintegrate/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/disintegrate)
	var/obj/item/melee/touch_attack/disintegrate/hand = allocate(/obj/item/melee/touch_attack/disintegrate)
	spell.attached_hand = hand
	hand.attached_spell = spell
	hand.charges = 0

	qdel(hand)
	hand.charges_check()
	TEST_ASSERT_NULL(spell.attached_hand, "Удалённая рука должна отвязаться от заклинания")

/// Руна возврата забывает удалённые вещи и не телепортирует удалённого призванного.
/datum/unit_test/summon_return_rune_forgets_deleted/Run()
	var/mob/living/carbon/human/returner = allocate(/mob/living/carbon/human)
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	returner.put_in_hands(pen)
	var/obj/effect/summon_rune/old_rune = allocate(/obj/effect/summon_rune)
	var/obj/effect/summon_rune/return_rune/rune = allocate(/obj/effect/summon_rune/return_rune, run_loc_floor_bottom_left, returner, run_loc_floor_top_right, old_rune)
	TEST_ASSERT(pen in rune.listed_items, "Санити: вещь из рук призванного должна попасть в список руны")

	qdel(pen)
	TEST_ASSERT(!(pen in rune.listed_items), "Удалённая вещь должна уйти из списка руны")

	qdel(returner)
	rune.process()
	TEST_ASSERT(QDELETED(rune), "Руна без живого призванного должна удалиться")

/// Удалённый извне сегмент света глаз уходит из списков органа и пересобирается.
/datum/unit_test/glow_eyes_forget_deleted_segment/Run()
	var/obj/item/organ/eyes/robotic/toggled/glow/eyes = allocate(/obj/item/organ/eyes/robotic/toggled/glow)
	eyes.set_distance(3)
	TEST_ASSERT_EQUAL(length(eyes.eye_lighting), 3, "Санити: сегментов столько же, сколько дальность")

	var/obj/effect/abstract/eye_lighting/segment = eyes.eye_lighting[2]
	qdel(segment)
	TEST_ASSERT(!(segment in eyes.eye_lighting), "Удалённый сегмент должен уйти из списка органа")
	qdel(eyes.on_mob)
	TEST_ASSERT_NULL(eyes.on_mob, "Удалённый свет на мобе должен отвязаться от органа")

	eyes.set_distance(2)
	TEST_ASSERT_EQUAL(length(eyes.eye_lighting), 2, "После пересборки сегментов столько же, сколько дальность")

/// Адаптер этажей отпускает удалённого соседа, даже если связь была односторонней.
/datum/unit_test/deck_relay_drops_deleted_partner/Run()
	var/obj/machinery/power/deck_relay/lower = allocate(/obj/machinery/power/deck_relay)
	var/obj/machinery/power/deck_relay/upper = allocate(/obj/machinery/power/deck_relay, run_loc_floor_top_right)
	var/obj/machinery/power/deck_relay/top = allocate(/obj/machinery/power/deck_relay, run_loc_floor_top_right)
	upper.below = lower
	upper.above = top

	qdel(lower)
	upper.process()
	TEST_ASSERT_NULL(upper.below, "Удалённый адаптер снизу должен забываться")

/// В отчёт ЦК попадают только режимы со своим текстом, без заглушки.
/datum/unit_test/command_report_modes_have_text/Run()
	TEST_ASSERT(length(config.mode_false_report_weight), "Санити: режимы для ложных отчётов не загружены")
	for(var/mode_tag in config.mode_false_report_weight)
		var/report = config.mode_reports[mode_tag]
		TEST_ASSERT(istext(report) && length(report), "Режим [mode_tag] может попасть в отчёт ЦК без текста")
		TEST_ASSERT(!findtext(report, "Contact a coder"), "Режим [mode_tag] попадает в отчёт ЦК с заглушкой")

/// Боеголовка взрывается на каждом этаже связки в той же точке.
/datum/unit_test/station_explosion_covers_stack/Run()
	var/list/single = station_explosion_epicenters(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(length(single), length(SSmapping.get_connected_levels(run_loc_floor_bottom_left)), "Эпицентров должно быть по одному на этаж")
	TEST_ASSERT(run_loc_floor_bottom_left in single, "Этаж бомбы должен взрываться")

	if(!SSmapping.max_plane_offset)
		return
	var/turf/lower = multiz_test_lower_turf()
	TEST_ASSERT_NOTNULL(lower, "В мире со стопкой не нашлось этажа со смещением")
	var/list/epicenters = station_explosion_epicenters(lower)
	TEST_ASSERT_EQUAL(length(epicenters), length(SSmapping.get_connected_levels(lower)), "Взрыв должен идти на каждом этаже связки")
	for(var/turf/epicenter as anything in epicenters)
		TEST_ASSERT(epicenter.x == lower.x && epicenter.y == lower.y, "Эпицентр на другом этаже сместился")

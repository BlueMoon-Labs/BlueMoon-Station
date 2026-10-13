/// У двух способностей одного пути и у способности пути с общей разные кнопки; каждая кнопка есть в своём листе еретика.
/datum/unit_test/heretic_fin_action_icons

/datum/unit_test/heretic_fin_action_icons/Run()
	var/list/spells_by_path = path_spells()
	var/list/side_buttons = list()
	for(var/spell_type in spells_by_path[PATH_SIDE])
		side_buttons[button_of(spell_type)] = spell_type
	var/checked = 0
	for(var/path_id in spells_by_path)
		var/list/seen = list()
		for(var/spell_type in spells_by_path[path_id])
			var/obj/effect/proc_holder/spell/spell = spell_type
			var/sheet = initial(spell.action_icon)
			var/state = initial(spell.action_icon_state)
			TEST_ASSERT(findtext("[sheet]", "heretic"), "[spell_type] берёт кнопку [state] из листа еретика, а не из общего [sheet].")
			TEST_ASSERT(state in icon_states(sheet), "Кнопка [spell_type] ([state]) есть в [sheet].")
			var/button = button_of(spell_type)
			TEST_ASSERT(!seen[button], "[path_id]: [spell_type] и [seen[button]] показывают одну кнопку [state].")
			seen[button] = spell_type
			if(path_id != PATH_SIDE)
				TEST_ASSERT(!side_buttons[button], "[path_id]: [spell_type] повторяет кнопку общей способности [side_buttons[button]].")
			checked++
	TEST_ASSERT(checked >= 120, "Проверены кнопки всех путей: [checked].")

/datum/unit_test/heretic_fin_action_icons/proc/button_of(spell_type)
	var/obj/effect/proc_holder/spell/spell = spell_type
	return "[initial(spell.action_icon)]:[initial(spell.action_icon_state)]"

/// Способности путей: всё, что выдают знания, плюс выданное стартом, вознесением, боевым ресурсом и слугами.
/datum/unit_test/heretic_fin_action_icons/proc/path_spells()
	var/list/spells_by_path = list(
		PATH_SIDE = list(),
		PATH_ASH = list(
			/obj/effect/proc_holder/spell/aoe_turf/fire_cascade,
			/obj/effect/proc_holder/spell/targeted/fire_sworn,
			/obj/effect/proc_holder/spell/self/heretic_power/ash,
		),
		PATH_RUST = list(
			/obj/effect/proc_holder/spell/self/rust_corrosive_wave,
			/obj/effect/proc_holder/spell/self/heretic_power/rust,
		),
		PATH_FLESH = list(
			/obj/effect/proc_holder/spell/self/heretic_power/flesh,
			/obj/effect/proc_holder/spell/targeted/shed_human_form,
			/obj/effect/proc_holder/spell/targeted/worm_contract,
			/obj/effect/proc_holder/spell/targeted/emplosion/eldritch,
			/obj/effect/proc_holder/spell/targeted/shapeshift/eldritch,
			/obj/effect/proc_holder/spell/pointed/trigger/blind/eldritch,
			/obj/effect/proc_holder/spell/targeted/telepathy/eldritch,
			/obj/effect/proc_holder/spell/pointed/manse_link,
			/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh/long,
		),
		PATH_VOID = list(
			/obj/effect/proc_holder/spell/self/heretic_power/void,
			/obj/effect/proc_holder/spell/self/heretic_last_waltz,
		),
		PATH_BLADE = list(
			/obj/effect/proc_holder/spell/self/heretic_blade/parry,
			/obj/effect/proc_holder/spell/self/heretic_blade/storm,
			/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge,
		),
		PATH_MOON = list(
			/obj/effect/proc_holder/spell/pointed/heretic_moon/create,
			/obj/effect/proc_holder/spell/self/heretic_moon/masquerade,
			/obj/effect/proc_holder/spell/self/heretic_moon/return_post,
			/obj/effect/proc_holder/spell/self/heretic_moon/post_voice,
			/obj/effect/proc_holder/spell/pointed/heretic_moon/shatter,
			/obj/effect/proc_holder/spell/pointed/heretic_moon/wisp,
		),
		PATH_COSMIC = list(
			/obj/effect/proc_holder/spell/self/cosmic/manifest,
			/obj/effect/proc_holder/spell/self/cosmic/stargazer,
			/obj/effect/proc_holder/spell/self/cosmic/command,
		),
		PATH_LOCK = list(
			/obj/effect/proc_holder/spell/pointed/heretic_lock/seal,
			/obj/effect/proc_holder/spell/self/heretic_lock/house,
			/obj/effect/proc_holder/spell/self/heretic_lock/keeper,
		),
		PATH_TIDE = list(
			/obj/effect/proc_holder/spell/self/heretic_tide/release,
			/obj/effect/proc_holder/spell/self/heretic_tide/leviathan,
			/obj/effect/proc_holder/spell/self/heretic_tide/dive,
		),
		PATH_GLASS = list(
			/obj/effect/proc_holder/spell/pointed/heretic_glass/release,
			/obj/effect/proc_holder/spell/self/heretic_glass/crown,
			/obj/effect/proc_holder/spell/pointed/heretic_glass/passage,
		),
		PATH_BLOOD = list(
			/obj/effect/proc_holder/spell/pointed/heretic_blood/release,
			/obj/effect/proc_holder/spell/pointed/heretic_blood/coronation,
		),
		PATH_ECHO = list(
			/obj/effect/proc_holder/spell/self/heretic_echo/release,
			/obj/effect/proc_holder/spell/self/heretic_echo/final,
			/obj/effect/proc_holder/spell/self/heretic_echo/listen,
		),
		PATH_SAND = list(
			/obj/effect/proc_holder/spell/self/heretic_sand/release,
			/obj/effect/proc_holder/spell/pointed/heretic_sand/final,
		),
		PATH_WAX = list(
			/obj/effect/proc_holder/spell/self/heretic_wax/release,
			/obj/effect/proc_holder/spell/self/heretic_wax/crown,
		),
		PATH_SPIRIT = list(
			/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever,
			/obj/effect/proc_holder/spell/self/heretic_spirit/crown,
		),
		PATH_DANCE = list(
			/obj/effect/proc_holder/spell/self/heretic_dance/style,
			/obj/effect/proc_holder/spell/self/heretic_dance/great_horovod,
		),
	)
	for(var/knowledge_type in subtypesof(/datum/eldritch_knowledge/spell))
		var/datum/eldritch_knowledge/spell/knowledge = knowledge_type
		var/spell_type = initial(knowledge.spell_to_add)
		if(!spell_type)
			continue
		var/route = initial(knowledge.route)
		if(route == "Start")
			route = PATH_SIDE
		var/list/route_spells = spells_by_path[route]
		if(route_spells)
			route_spells |= spell_type
	return spells_by_path

/// Каждая кнопка в листе способностей еретика и каждое действие с него ссылаются на существующий стейт.
/datum/unit_test/heretic_fin_action_sheet_states/Run()
	var/sheet = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	var/list/states = icon_states(sheet)
	var/obj/effect/proc_holder/spell/root = /obj/effect/proc_holder/spell
	var/obj/effect/proc_holder/spell/pointed/pointed_root = /obj/effect/proc_holder/spell/pointed
	var/list/abstract_names = list(initial(root.name), initial(pointed_root.name))
	var/checked = 0
	for(var/spell_type in subtypesof(/obj/effect/proc_holder/spell))
		var/obj/effect/proc_holder/spell/spell = spell_type
		if(initial(spell.action_icon) != sheet || (initial(spell.name) in abstract_names))
			continue
		TEST_ASSERT(initial(spell.action_icon_state) in states, "Кнопка [spell_type] ([initial(spell.action_icon_state)]) есть в листе способностей еретика.")
		checked++
	for(var/action_type in subtypesof(/datum/action))
		var/datum/action/action = action_type
		if(initial(action.icon_icon) != sheet)
			continue
		TEST_ASSERT(initial(action.button_icon_state) in states, "Кнопка [action_type] ([initial(action.button_icon_state)]) есть в листе способностей еретика.")
		checked++
	TEST_ASSERT(checked >= 120, "Проверены кнопки листа способностей еретика: [checked].")
	for(var/style_id in list("waltz", "tango", "tarantella", "cancan", "macabre"))
		TEST_ASSERT("dance_style_[style_id]" in states, "Значок стиля Пляски [style_id] есть в листе.")

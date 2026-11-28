/// Кнопки, которые раньше показывали спрайт предмета или эффекта, рисуются своими значками из листа способностей.
/datum/unit_test/heretic_action_own_buttons/Run()
	var/sheet = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	var/list/states = icon_states(sheet)
	var/list/buttons = list(
		/obj/effect/proc_holder/spell/self/heretic_summon/book = "heretic_codex",
		/obj/effect/proc_holder/spell/self/heretic_lock/keeper = "lock_keeper",
		/obj/effect/proc_holder/spell/aoe_turf/domain_expansion = "void_domain_expand",
		/obj/effect/proc_holder/spell/targeted/touch/grasp_of_decay = "rust_grasp_chain",
		/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch = "flesh_tendon",
		/obj/effect/proc_holder/spell/pointed/heretic_moon/shatter = "moon_shatter",
	)
	for(var/spell_type in buttons)
		var/obj/effect/proc_holder/spell/spell = spell_type
		TEST_ASSERT_EQUAL(initial(spell.action_icon), sheet, "[spell_type] берёт кнопку из листа способностей еретика.")
		TEST_ASSERT_EQUAL(initial(spell.action_icon_state), buttons[spell_type], "[spell_type] показывает свой значок.")
		TEST_ASSERT(buttons[spell_type] in states, "Значок [buttons[spell_type]] нарисован.")

/// Фон кнопок еретика свой и берётся только у способностей с фоном bg_ecult; чужие кнопки остаются на фонах tg.
/datum/unit_test/heretic_action_background/Run()
	var/heretic_backgrounds = 'modular_bluemoon/icons/mob/actions/heretic_backgrounds.dmi'
	TEST_ASSERT("bg_ecult" in icon_states(heretic_backgrounds), "Фон кнопок еретика нарисован.")
	var/obj/effect/proc_holder/spell/heretic_spell = allocate(/obj/effect/proc_holder/spell/self/heretic_summon/book)
	TEST_ASSERT_EQUAL(heretic_spell.action.background_icon_state, "bg_ecult", "Способность еретика несёт фон еретика.")
	TEST_ASSERT_EQUAL(heretic_spell.action.background_icon_file(), heretic_backgrounds, "Фон способности еретика берётся из его листа.")
	var/obj/effect/proc_holder/spell/other_spell = allocate(/obj/effect/proc_holder/spell/targeted/ethereal_jaunt)
	TEST_ASSERT_NOTEQUAL(other_spell.action.background_icon_file(), heretic_backgrounds, "Способность мага не получает фон еретика.")
	TEST_ASSERT_EQUAL(other_spell.action.background_icon_file(), other_spell.action.button_icon, "Чужая способность берёт фон из своего файла.")

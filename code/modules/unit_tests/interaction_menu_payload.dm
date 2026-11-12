/// Меню взаимодействий: описания уровней согласия на цели антагов едут в static_data, в обновлении остаётся только выбор.
/datum/unit_test/interaction_menu_opt_in_static

/datum/unit_test/interaction_menu_opt_in_static/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/component/interaction_menu_granter/granter = user.AddComponent(/datum/component/interaction_menu_granter/opt_in_test)
	var/list/static_data = granter.ui_static_data(user)
	var/list/catalog = static_data["antag_opt_in_levels"]
	TEST_ASSERT_NOTNULL(catalog, "Описания уровней не попали в static_data")
	TEST_ASSERT_EQUAL(length(catalog["levels"]), ANTAG_OPT_IN_ROUND_REMOVE - ANTAG_OPT_IN_NOT_TARGET + 1, "В static_data не все уровни")
	TEST_ASSERT_EQUAL(catalog["disclaimer"], GLOB.antag_opt_in_disclaimer, "Предупреждение не дошло до меню")
	TEST_ASSERT(length(catalog["thresholds"]), "Пороги уровней пустые")
	var/list/state = granter.antag_opt_in_ui_data(user)
	TEST_ASSERT_EQUAL(state["level"], antag_opt_in_default_level(), "Выбор без разума и настроек не по умолчанию")
	TEST_ASSERT_EQUAL(state["effective"], state["level"], "Итоговый уровень без разума не равен выбранному")
	TEST_ASSERT_NULL(state["levels"], "Описания уровней снова едут в каждом обновлении")
	qdel(granter)

/datum/component/interaction_menu_granter/opt_in_test/Initialize(...)
	return

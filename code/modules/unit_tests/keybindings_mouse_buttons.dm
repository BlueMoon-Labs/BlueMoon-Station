/// Боковые кнопки мыши приходят с карты в MouseDown/MouseUp/Click: так их шлёт Dream Seeker 516.1688
/datum/unit_test/keybindings_mouse_buttons/Run()
	TEST_ASSERT_EQUAL(mouse_event_side_button_key("icon-x=1;icon-y=32;xbutton1=1;button=xbutton1;screen-loc=6:1,5:32"), MOUSE_SIDE_BUTTON_BACK, "кнопка назад не стала клавишей Mouse4")
	TEST_ASSERT_EQUAL(mouse_event_side_button_key("icon-x=1;icon-y=32;xbutton2=1;button=xbutton2;screen-loc=6:1,5:32"), MOUSE_SIDE_BUTTON_FORWARD, "кнопка вперёд не стала клавишей Mouse5")
	TEST_ASSERT_EQUAL(mouse_event_side_button_key("xbutton1=1;shift=1;button=xbutton1"), MOUSE_SIDE_BUTTON_BACK, "Shift с боковой кнопкой потерял кнопку")
	TEST_ASSERT_NULL(mouse_event_side_button_key("icon-x=1;icon-y=32;left=1;button=left;screen-loc=6:1,5:32"), "ЛКМ принят за боковую кнопку")
	TEST_ASSERT_NULL(mouse_event_side_button_key("right=1;button=right"), "ПКМ принят за боковую кнопку")
	TEST_ASSERT_NULL(mouse_event_side_button_key("middle=1;button=middle"), "СКМ принят за боковую кнопку")
	TEST_ASSERT_NULL(mouse_event_side_button_key("left=1;xbutton1=1;button=left"), "ЛКМ при зажатой боковой кнопке перестал быть ЛКМ")
	TEST_ASSERT_NULL(mouse_event_side_button_key(null), "пустые параметры дали кнопку")

	TEST_ASSERT(keybind_is_mouse_button("Mouse4"), "Mouse4 не узнан как кнопка мыши")
	TEST_ASSERT(keybind_is_mouse_button("ShiftMouse5"), "Shift+Mouse5 не узнан как кнопка мыши")
	TEST_ASSERT(keybind_is_mouse_button("AltCtrlMouse4"), "Alt+Ctrl+Mouse4 не узнан как кнопка мыши")
	for(var/key in list("M", "CtrlM", "Numpad4", "F5", "Northeast", "Space"))
		TEST_ASSERT(!keybind_is_mouse_button(key), "клавиша [key] принята за кнопку мыши")

	// мышь не шлёт повторов, как клавиатура: зажатая боковая кнопка движения не должна отпускаться по истечении аренды
	var/list/movement = list("W" = NORTH, MOUSE_SIDE_BUTTON_FORWARD = EAST)
	var/list/held = list(MOUSE_SIDE_BUTTON_FORWARD = 10)
	TEST_ASSERT(!length(keybindings_expired_movement_keys(held, movement, 10, 10 + MOVEMENT_KEY_REPEAT_TIMEOUT * 4)), "зажатая боковая кнопка движения отпущена без повтора")
	held = list(MOUSE_SIDE_BUTTON_FORWARD = 10, "W" = 10)
	var/list/expired = keybindings_expired_movement_keys(held, movement, 10, 10 + MOVEMENT_KEY_REPEAT_TIMEOUT)
	TEST_ASSERT_EQUAL(length(expired), 1, "аренда должна отпустить только клавишу W")
	TEST_ASSERT("W" in expired, "клавиша W без повтора не отпущена")

	// у кнопок мыши нет макросов клиента: ни повтора, ни отпускания
	var/list/macros = list("Any" = "any")
	keybindings_add_movement_repeat_macros(macros, list("W" = NORTH, MOUSE_SIDE_BUTTON_FORWARD = EAST), TRUE)
	TEST_ASSERT(macros["W+REP"], "клавиша W потеряла макрос повтора")
	TEST_ASSERT(!macros["[MOUSE_SIDE_BUTTON_FORWARD]+REP"], "кнопка мыши получила макрос повтора")
	TEST_ASSERT(!macros["[MOUSE_SIDE_BUTTON_FORWARD]+UP"], "кнопка мыши получила макрос отпускания")

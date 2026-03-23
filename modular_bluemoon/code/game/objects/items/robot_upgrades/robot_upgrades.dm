/obj/item/borg/upgrade/advmed_tools
	name = "cyborg advanced surgical tools"
	desc = "A replacement for the medical module's standard surgical equipment. Provides the cyborg with brand-new advanced tools."
	icon_state = "cyborg_upgrade"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/medical)
	module_flags = BORG_MODULE_MEDICAL
	/// Инструменты, которые лучше предыдущих, на замену
	var/list/adv_tools = list(/obj/item/scalpel/advanced/cyborg,
		/obj/item/retractor/advanced/cyborg,
		/obj/item/surgicaldrill/advanced/cyborg
	)
	/// Базовые инструменты, что мы заменяем или возвращаем
	var/list/basic_tools = list(/obj/item/retractor, /obj/item/hemostat, /obj/item/cautery, /obj/item/surgicaldrill, /obj/item/scalpel, /obj/item/circular_saw)

/obj/item/borg/upgrade/advmed_tools/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for (var/i in adv_tools)
		var/obj/item/tool = locate(i) in R.module.modules // Ищем в инвентаре борга инструменты списка
		if(tool)
			to_chat(user, "<span class='warning'>This unit is already equipped with advanced surgical tools.</span>")
			return FALSE

	var/list/old_tools = list()
	for (var/i = 1, i <= R.module.modules.len, i++) // Этот алгоритм формирует список предметов на
		var/obj/item/I = R.module.modules[i] // замену новыми инструментами. Можно было бы чётко
		if(I && (I.type in basic_tools)) // существующие типа именно "скальпель", но это универсальнее.
			old_tools += I

	var/tool_to_replace = min(adv_tools.len, old_tools.len)

	for (var/n = 1, n <= tool_to_replace, n++) // Для каждого инструмента, что будем менять
		var/obj/item/old = old_tools[n]
		var/newtype = adv_tools[n] // Включая замену на продвинутые, на месте.
		var/obj/item/newtool = new newtype(R.module)
		R.module.basic_modules += newtool

		R.module.add_module(newtool, FALSE, TRUE)

		var/old_idx = R.module.modules.Find(old)
		var/new_idx = R.module.modules.Find(newtool)
		if(old_idx && new_idx)
		// ВАЖНО: мы меняем местами в ОБОИХ списках
			R.module.modules.Swap(old_idx, new_idx)
			R.module.basic_modules.Swap(old_idx, new_idx)

		R.module.remove_module(old, TRUE)

	if(old_tools.len > tool_to_replace)
		for (var/m = tool_to_replace + 1, m <= old_tools.len, m++)
			var/obj/item/excess = old_tools[m] // Мы заменили три инструмента на три адванседа. Убираем лишний остаток.
			if(excess && (excess in R.module.modules))
				R.module.remove_module(excess, TRUE)

/obj/item/borg/upgrade/advmed_tools/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

/// Не вышло сделать замену зеркально добавлению, чтобы 3 инструмента заменились на 6 старых. Новые добавляются в конец инвентаря.
	// Удаление продвинутых инструментов.
	for (var/i = R.module.modules.len, i > 0, i--)
		var/obj/item/I = R.module.modules[i]
		if(I && (I.type in adv_tools))
			R.module.remove_module(I, TRUE)

	// Возвращение старых хирургических инструментов.
	for (var/newtype in basic_tools)
		if(!(locate(newtype) in R.module.modules))
			var/obj/item/basic = new newtype(R.module)
			R.module.basic_modules += basic
			R.module.add_module(basic, FALSE, TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/borg/upgrade/rcdsyndi
	name = "cyborg industrial RCD"
	desc = "A replacement for the basic RCD module with energy efficient Syndicate-grade version."
	icon_state = "cyborg_upgrade2"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING
	/// Старый РЦД
	var/obj/item/construction/rcd/borg/RCD
	/// Новый РЦД
	var/obj/item/construction/rcd/borg/syndicate/IRCD

/obj/item/borg/upgrade/rcdsyndi/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for(IRCD in R.module.modules)
		if(IRCD)
			to_chat(user, "<span class='warning'>This unit is already equipped with an industrial RCD module.</span>")
			return FALSE

	var/RCD_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Начинаем искать индекс старого РЦД
		RCD = R.module.modules[i]
		if(istype(RCD, /obj/item/construction/rcd/borg))
			RCD_index = i
			break // Находим - прекращаем, не обрабатываем for'ом весь список.

	IRCD = new(R.module)
	R.module.basic_modules += IRCD
	R.module.add_module(IRCD, FALSE, TRUE)
	var/IRCD_index = R.module.modules.Find(IRCD)
	for(IRCD in R.module) // Можно оформить и для старого РЦД, здесь сделано для нового, без разницы.
		R.module.modules.Swap(RCD_index, IRCD_index) // Swap в обоих листах важно настолько же
		R.module.basic_modules.Swap(RCD_index, IRCD_index) // как и `basic_modules +=` и `add.module` выше
	R.module.remove_module(RCD, TRUE) // Замена произошла - избавляемся от старого РЦД

/obj/item/borg/upgrade/rcdsyndi/deactivate(mob/living/silicon/robot/R, user)
	. = ..()
	if(!.)
		return

	var/IRCD_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Этот алгоритм зеркален тому, что для добавления
		IRCD = R.module.modules[i]
		if(istype(IRCD, /obj/item/construction/rcd/borg/syndicate))
			IRCD_index = i
			break

	RCD = new(R.module)
	R.module.basic_modules += RCD
	R.module.add_module(RCD, FALSE, TRUE)
	var/RCD_index = R.module.modules.Find(RCD)
	for(RCD in R.module)
		R.module.modules.Swap(IRCD_index, RCD_index)
		R.module.basic_modules.Swap(IRCD_index, RCD_index)
		R.module.remove_module(IRCD, TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/borg/upgrade/broomer
	name = "cyborg experimental broom"
	desc = "При активации позволяет толкать предметы перед собой в большой куче."
	icon_state = "cyborg_upgrade3"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/butler)
	module_flags = BORG_MODULE_JANITOR

/obj/item/borg/upgrade/broomer/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/obj/item/broom/cyborg/BR = locate() in R.module.modules
	if (BR)
		to_chat(user, span_warning("Этот киборг уже оснащен экспериментальным толкателем!"))
		return FALSE

	BR = new(R.module)
	R.module.basic_modules += BR
	R.module.add_module(BR, FALSE, TRUE)

/obj/item/borg/upgrade/broomer/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/obj/item/broom/cyborg/BR = locate() in R.module.modules
	if (BR)
		R.module.remove_module(BR, TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/borg/upgrade/extinguisher_adv
	name = "cyborg advanced fire extinguisher"
	desc = "Atmospheric Technician-grade extinguisher for the most dangerous flames."
	icon_state = "cyborg_upgrade3"
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING

/obj/item/borg/upgrade/extinguisher_adv/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/obj/item/extinguisher/advanced/cyborg/EA = locate() in R.module.modules
	if (EA)
		to_chat(user, "<span class='warning'>This unit is already equipped with an advanced fire extinguisher module.</span>")
		return FALSE

	EA = new(R.module)
	R.module.basic_modules += EA
	R.module.add_module(EA, FALSE, TRUE)

/obj/item/borg/upgrade/extinguisher_adv/deactivate(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if (!.)
		return

	var/obj/item/extinguisher/advanced/cyborg/EA = locate() in R.module.modules
	if (EA)
		R.module.remove_module(EA, TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////////

/obj/item/borg/upgrade/gasanalyzer_advanced
	name = "cyborg long ranged gas analyzer"
	desc = "Atmospheric Technician-grade gas analyzer for scanning gas properties from the distance."
	require_module = TRUE
	module_type = list(/obj/item/robot_module/engineering)
	module_flags = BORG_MODULE_ENGINEERING
	/// Старый анализатор
	var/obj/item/analyzer/analyzer
	/// Новый
	var/obj/item/analyzer/ranged/cyborg/analyzer_adv

/obj/item/borg/upgrade/gasanalyzer_advanced/action(mob/living/silicon/robot/R, user = usr)
	. = ..()
	if(!.)
		return

	for(analyzer_adv in R.module.modules)
		if(analyzer_adv)
			to_chat(user, "<span class='warning'>This unit is already equipped with an advanced analyzer module.</span>")
			return FALSE

	var/analyzer_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Начинаем искать индекс старого анализатора
		analyzer = R.module.modules[i]
		if(istype(analyzer, /obj/item/analyzer))
			analyzer_index = i
			break // Находим - прекращаем, не обрабатываем for'ом весь список.

	analyzer_adv = new(R.module)
	R.module.basic_modules += analyzer_adv
	R.module.add_module(analyzer_adv, FALSE, TRUE)
	var/analyzer_adv_index = R.module.modules.Find(analyzer_adv)
	for(analyzer_adv in R.module) // Можно оформить и для старого анализатора, здесь сделано для нового, без разницы.
		R.module.modules.Swap(analyzer_index, analyzer_adv_index) // Swap в обоих листах важно настолько же
		R.module.basic_modules.Swap(analyzer_index, analyzer_adv_index) // как и `basic_modules +=` и `add.module` выше
	R.module.remove_module(analyzer, TRUE) // Замена произошла - избавляемся от старого

/obj/item/borg/upgrade/gasanalyzer_advanced/deactivate(mob/living/silicon/robot/R, user)
	. = ..()
	if(!.)
		return

	var/analyzer_adv_index = 0
	for(var/i = 1, i <= R.module.modules.len, i++) // Этот алгоритм зеркален тому, что для добавления
		analyzer_adv = R.module.modules[i]
		if(istype(analyzer_adv, /obj/item/analyzer/ranged/cyborg))
			analyzer_adv_index = i
			break

	analyzer = new(R.module)
	R.module.basic_modules += analyzer
	R.module.add_module(analyzer, FALSE, TRUE)
	var/analyzer_index = R.module.modules.Find(analyzer)
	for(analyzer in R.module)
		R.module.modules.Swap(analyzer_adv_index, analyzer_index)
		R.module.basic_modules.Swap(analyzer_adv_index, analyzer_index)
		R.module.remove_module(analyzer_adv, TRUE)

///////////////////////////////////////////////////////////////////////////////////////////////////

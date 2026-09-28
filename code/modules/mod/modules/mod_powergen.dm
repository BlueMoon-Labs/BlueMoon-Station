/obj/item/mod/module/power
	name = "Basic powergen module"
	desc = "Незамысловатый модуль небольшого размера, приспособленный генерировать энергию из топлива"
	module_type = MODULE_TOGGLE //можно включить/выключить в радиалочке
	incompatible_modules = list(/obj/item/mod/module/power)
	var/obj/item/stock_parts/cell/mod_cell
	var/generation_rate = MOD_FUELGEN_RATE_GENERIC //это число умножается на generation_amount для расчета того, насколько зарядит
	var/generation_amount = 500 //сколько генерирует за заход. Учитываем, что типичная батарейка имеет около 10к заряда и до 60к
	var/use_fuel = TRUE //юзает ли топливо. Ставим TRUE вместе с нижним параметром
	var/have_tesla_relay = FALSE //если включено, то генерирует ТОЛЬКО от энергии зоны.
	var/max_fuel_amount = 50 //макс кол-во топливав
	var/current_fuel_amount = 0 //текущее кол-во топлива
	var/use_fuel_by_step = 1 //сколько жрёт за одну генерацию
	var/use_sparks = TRUE //поджигаем плазму))
	var/upper_charge_percent = MOD_CHARGE_MAX_DEFAULT //потолок зарядки
	var/broken = FALSE //нельзя включить, если сломан. Только замена.
	var/fuel_type = /obj/item/stack/sheet/mineral/plasma
	COOLDOWN_DECLARE(power_generation_cooldown)
	var/powergen_cooldown_time = 5 SECONDS

//MARK: Базовые проки
/obj/item/mod/module/power/examine(mob/user)
	. = ..()
	if(use_fuel)
		. += span_danger("Чтобы модуль работал, нужно вставить в него топливо, нажав на МОД Ctrl+Shift и левая кнопка мыши, держа нужный тип топлива в руках!")
	return .

/obj/item/mod/module/power/on_install()
	. = ..()
	if(!mod)
		return
	mod_cell = mod.get_cell()
	RegisterSignal(mod, COMSIG_CLICK_CTRL_SHIFT, PROC_REF(try_insert_fuel))

/obj/item/mod/module/power/on_uninstall(deleting, user)
	. = ..()
	mod_cell = null
	UnregisterSignal(mod, COMSIG_CLICK_CTRL_SHIFT)

/obj/item/mod/module/power/emp_act(severity)
	. = ..()
	if(severity < MOD_EMP_SEVERITY_MAX || broken)
		return
	go_destroy()
	on_deactivation()

/obj/item/mod/module/power/on_activation()
	. = ..()
	if(!mod.wearer)
		return
	to_chat(mod.wearer, span_notice("[name] активен!"))

/obj/item/mod/module/power/on_deactivation()
	. = ..()
	if(!mod.wearer)
		return
	to_chat(mod.wearer, span_notice("[name] был отключён!"))

/obj/item/mod/module/power/on_select(atom/target)
	if(broken)
		return FALSE
	if(!current_fuel_amount)
		to_chat(mod.wearer, span_warning("[name] не имеет топлива!"))
	if(have_tesla_relay || current_fuel_amount)
		return . = ..()

/obj/item/mod/module/power/crowbar_act(mob/living/user, obj/item/tool)
	. = ..()
	if(!current_fuel_amount || !use_fuel)
		return
	var/obj/item/stack/sheet/sheet_on_the_floor =  new fuel_type(drop_location())
	tool.play_tool_sound(src, 50)
	var/amount_of_sheets = current_fuel_amount

	if(current_fuel_amount >= sheet_on_the_floor.max_amount)
		amount_of_sheets = sheet_on_the_floor.max_amount

	current_fuel_amount -= amount_of_sheets
	sheet_on_the_floor.amount = amount_of_sheets

/obj/item/mod/module/power/screwdriver_act(mob/living/user, obj/item/tool)
	. = ..()
	switch(upper_charge_percent)
		if(MOD_CHARGE_MAX_DEFAULT)
			upper_charge_percent = MOD_CHARGE_ADJUSTED_MEDIUM
		if(MOD_CHARGE_ADJUSTED_MEDIUM)
			upper_charge_percent = MOD_CHARGE_ADJUSTED_MAX
		if(MOD_CHARGE_ADJUSTED_MAX)
			upper_charge_percent = MOD_CHARGE_MAX_DEFAULT

	tool.play_tool_sound(src, 50)
	to_chat(user, span_notice("Вы изменили верхний предел зарядки для [name], теперь он составляет [upper_charge_percent]%"))

/obj/item/mod/module/power/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(istype(I, fuel_type))
		insert_fuel(I, user)
	if(istype(I, /obj/item/stack/cable_coil))
		repair_after_emp(I, user)

//MARK: Специфика
/obj/item/mod/module/power/proc/repair_after_emp(obj/item/stack/cable_coil/cable, mob/living/user)
	if(!broken)
		return

	if(cable.amount < 5)
		to_chat(user, span_danger("Вам нужно 5 кусочков кабеля. чтобы починить перегоревшие провода внутри [name]"))
		return

	if(do_after(user, 5 SECONDS, src))
		cable.use(5)
		to_chat(user, span_nicegreen("Вы успешно заменяете сгоревшие провода внутри [name], модуль положительно пищит, сигнализируя о готовности к работе"))
		playsound(src, 'sound/machines/twobeep.ogg', 50, TRUE)
		broken = FALSE

/obj/item/mod/module/power/proc/go_destroy()
	if(active)
		to_chat(mod.wearer, span_big_warning("От попадания ЕМП ваш модуль [name] ломается!"))
		broken = TRUE

/obj/item/mod/module/power/proc/try_insert_fuel(datum/source, mob/living/user)
	SIGNAL_HANDLER
	if(!iscarbon(user) || source != mod)
		return

	var/obj/item/item_in_active_hand = user.get_active_held_item()
	if(!item_in_active_hand || !istype(item_in_active_hand, fuel_type))
		return

	insert_fuel(item_in_active_hand, user)

/obj/item/mod/module/power/proc/insert_fuel(obj/item/stack/sheet/mineral/fuel, user)
	if(current_fuel_amount == max_fuel_amount)
		can_generate_power()
		return
	var/amount_fuel_can_be_used = max_fuel_amount

	if(fuel.amount > max_fuel_amount || (fuel.amount - max_fuel_amount) <= 0)
		amount_fuel_can_be_used = fuel.amount

	fuel.use(amount_fuel_can_be_used)
	current_fuel_amount = amount_fuel_can_be_used

	can_generate_power()

/obj/item/mod/module/power/proc/can_generate_power()
	//пробуем найти батарейку, если она вдруг пропала(замена, вставка модуля в мод без батарейки)
	if(!mod_cell)
		mod_cell = mod.get_cell()
	if(!COOLDOWN_FINISHED(src, power_generation_cooldown) || !mod || !mod.wearer || !mod_cell || QDELETED(mod))
		return FALSE

	if(have_tesla_relay)
		return TRUE

	if(current_fuel_amount)
		return TRUE

/obj/item/mod/module/power/proc/charge_from_neaby_apc()
	var/area/A = get_area(mod.wearer)

	if(A && A.powered(EQUIP) && mod_cell.give(generation_amount))
		A.use_power((generation_amount * generation_rate), EQUIP)

/obj/item/mod/module/power/proc/generate()
	var/amount_to_recharge = generation_amount * generation_rate
	if(have_tesla_relay)
		charge_from_neaby_apc()
		return TRUE

	mod_cell.give(amount_to_recharge)
	current_fuel_amount -= use_fuel_by_step

	if(current_fuel_amount <= 0)
		current_fuel_amount = 0
	return TRUE

/obj/item/mod/module/power/proc/notify_user()
	//playsound
	if(!mod.wearer || !mod_cell)
		return
	if(use_sparks)
		do_sparks(rand(1,2), FALSE,  mod.drop_location())

	to_chat(mod.wearer, span_nicegreen("Модуль [name] перезарядил батарею в [mod.name], её новый заряд составляет: [mod_cell.percent()]%"))

	if(!current_fuel_amount && use_fuel)
		//playsound
		to_chat(mod.wearer, span_alertwarning("Модуль [name] с тихим жужжанием отключился, из-за недостатка топлива."))
		on_deactivation()

//MARK: Процессинг тут
/obj/item/mod/module/power/on_process(delta_time)
	. = ..()
	if(!can_generate_power() || !active || (mod_cell.percent() > upper_charge_percent))
		return
	if(generate())
		COOLDOWN_START(src, power_generation_cooldown, powergen_cooldown_time)
		notify_user()

//MARK: Разновидности тут

/obj/item/mod/module/power/plasma
	name = "Plasma PowerGen Module"
	desc = "Младший брат ПАКМАНа, но в виде модуля. Не имеет встроенных защит и довольно массивен для МОДа. \
	Очень чувствителен к ЕМП, безысходно ломаясь после него, требуя полной замены. Потреблет 5 единиц плазмы на одну \
	генерацию энергии, выдаввая 2,5 МДж каждые 20 секунд. И да, его надо включить."
	icon_state = "plasma_gen"
	use_fuel_by_step = 3
	powergen_cooldown_time = 20 SECONDS
	generation_amount = 2500
	complexity = 3
	fuel_type = /obj/item/stack/sheet/mineral/plasma

/obj/item/mod/module/power/plasma/go_destroy()
	. = ..()
	if(current_fuel_amount && mod.wearer && prob(MOD_PLASMAGEN_EMP_BURN_CHANCE))
		to_chat(mod.wearer, span_big_warning("[name] перегревается от сильного импульса, поджигая часть плазмы вместе с костюмом!"))
		mod.wearer.adjust_fire_stacks(current_fuel_amount)
		mod.wearer.IgniteMob()
		mod.wearer.emote("scream")

/obj/item/mod/module/power/uranium
	name = "Nuclear PowerGen Module"
	desc = "Ваш личный атомный энергоблок на обогощенном уране за спиной. Мало того, он ещё и никак не экранирован. \
	Отлично фонит и модно светится, пока включен. Третья рука в комплект входит? \
	Генерирует 4 МДж каждые 20 секунд."
	icon_state = "uranium_gen"
	max_fuel_amount = 100
	use_fuel_by_step = 2
	powergen_cooldown_time = 20 SECONDS
	generation_amount = 4000
	complexity = 2
	fuel_type = /obj/item/stack/sheet/mineral/uranium

/obj/item/mod/module/power/uranium/on_activation()
	. = ..()
	mod.AddComponent(/datum/component/radioactive, 0, src, 0)
	var/datum/component/radioactive/Comp = mod.GetComponent(/datum/component/radioactive)
	Comp.set_strength(round(use_fuel_by_step*10)) //20, у реакторки 14,5

/obj/item/mod/module/power/uranium/on_deactivation()
	. = ..()
	var/datum/component/radioactive/Comp = mod.GetComponent(/datum/component/radioactive)
	qdel(Comp)

/obj/item/mod/module/power/diamond
	name = "Diamond PowerGen Module"
	desc = "Встроенный, экологически чистый генератор на алмазах. Дорого-богато.\
	Генерирует 6,5 МДж каждые 20 секунд."
	icon_state = "diamond_gen"
	max_fuel_amount = 100
	use_fuel_by_step = 1
	powergen_cooldown_time = 20 SECONDS
	generation_amount = 6500
	complexity = 2
	fuel_type = /obj/item/stack/sheet/mineral/diamond

/obj/item/mod/module/power/bananium
	name = "Bananium Honk PowerGen Module"
	desc = "Бананиумный генератор! Хонк-хонк. Никто не знает как им пользоваться. Лишь истинные сыны и дочеры \
	хонкоматери могут приручить этот безумный аппарат. Генерирует безумные 4.5 МДж каждые 20 секунд и даже не искрит"
	icon_state = "bananium_gen"
	use_fuel_by_step = 5
	use_sparks = FALSE
	powergen_cooldown_time = 20 SECONDS
	generation_amount = 4500
	complexity = 2
	fuel_type = /obj/item/stack/sheet/mineral/bananium

/obj/item/mod/module/power/bananium/generate()
	. = ..()
	playsound(mod.wearer.loc, 'sound/items/bikehorn.ogg', 50, 1)

/obj/item/mod/module/power/bananium/on_select()
	if(!isclownjob(mod.wearer))
		to_chat(mod.wearer, span_alertwarning("Что? Где тут кнопка включения? Наверное сломано..."))
		return FALSE
	. = ..()

/obj/item/mod/module/power/tesla
	name = "Tesla PowerGen Module"
	desc = "Особый встроенный генератор энергии для МОД костюмов, способный брать электричество напрямую из\
	электричества текущего помещения, если оно запитано. Работает раз в 30 секунд, заряжает батарею на 2 МДж"
	icon_state = "tesla_gen"
	powergen_cooldown_time = 30 SECONDS
	generation_amount = 2000
	have_tesla_relay = TRUE
	complexity = 4
	use_fuel = FALSE

/obj/item/mod/module/power/tesla/go_destroy()
	. = ..()
	if(!mod.wearer)
		return
	do_sparks(5, TRUE, mod.drop_location())
	electrocute_mob(mod.wearer, mod_cell, src, 1, FALSE)

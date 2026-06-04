//Medical modules for MODsuits

#define HEALTH_SCAN "Health"
#define WOUND_SCAN "Wound"
#define CHEM_SCAN "Chemical"

///Health Analyzer - Gives the user a ranged health analyzer and their health status in the panel.
/obj/item/mod/module/health_analyzer
	name = "MOD health analyzer module"
	desc = "Модуль, установленный в перчатку костюма. Это высокотехнологичный биологический сканер, \
		позволяющий пользователю получать подробную информацию о жизненно важных показателях и травмах других даже на расстоянии, \
		всего лишь взмахом руки. Данные отображаются в удобном формате на дисплее шлема, \
		но что с ними делать — зависит от вас."
	icon_state = "health"
	module_type = MODULE_ACTIVE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/health_analyzer)
	cooldown_time = 0.5 SECONDS
	tgui_id = "health_analyzer"
	/// Scanning mode, changes how we scan something.
	var/mode = HEALTH_SCAN
	/// List of all scanning modes.
	var/static/list/modes = list(HEALTH_SCAN, WOUND_SCAN, CHEM_SCAN)
	mod_module_flags = MOD_MODULE_MEDICAL // BLUEMOON ADD

/obj/item/mod/module/health_analyzer/add_ui_data()
	. = ..()
	.["userhealth"] = mod.wearer?.health || 0
	.["usermaxhealth"] = mod.wearer?.getMaxHealth() || 0
	.["userbrute"] = mod.wearer?.getBruteLoss() || 0
	.["userburn"] = mod.wearer?.getFireLoss() || 0
	.["usertoxin"] = mod.wearer?.getToxLoss() || 0
	.["useroxy"] = mod.wearer?.getOxyLoss() || 0

/obj/item/mod/module/health_analyzer/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(!isliving(target) || !mod.wearer.can_read(src))
		return
	switch(mode)
		if(HEALTH_SCAN)
			healthscan(mod.wearer, target)
		if(WOUND_SCAN)
			woundscan(mod.wearer, target)
		if(CHEM_SCAN)
			chemscan(mod.wearer, target)
	drain_power(use_power_cost)

/obj/item/mod/module/health_analyzer/get_configuration()
	. = ..()
	.["mode"] = add_ui_configuration("Scan Mode", "list", mode, modes)

/obj/item/mod/module/health_analyzer/configure_edit(key, value)
	switch(key)
		if("mode")
			mode = value

#undef HEALTH_SCAN
#undef WOUND_SCAN
#undef CHEM_SCAN

///Quick Carry - Lets the user carry bodies quicker.
/obj/item/mod/module/quick_carry
	name = "MOD quick carry module"
	desc = "Набор продвинутых сервоприводов, перенаправляющих энергию из рук костюма для помощи в переноске раненых; \
		или просто для развлечения. Однако Nanotrasen заблокировал способность модуля помогать в рукопашном бою."
	icon_state = "carry"
	complexity = 1
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	incompatible_modules = list(/obj/item/mod/module/quick_carry, /obj/item/mod/module/constructor)
	mod_module_flags = MOD_MODULE_MEDICAL // BLUEMOON ADD

/obj/item/mod/module/quick_carry/on_suit_activation()
	ADD_TRAIT(mod.wearer, TRAIT_QUICKER_CARRY, MOD_TRAIT)

/obj/item/mod/module/quick_carry/on_suit_deactivation(deleting = FALSE)
	REMOVE_TRAIT(mod.wearer, TRAIT_QUICKER_CARRY, MOD_TRAIT)

/obj/item/mod/module/quick_carry/advanced
	name = "MOD advanced quick carry module"
	removable = FALSE
	complexity = 0

///Injector - No piercing syringes, replace another time

///Organ Thrower

///Patrient Transport

///Defibrillator - Gives the suit an extendable pair of shock paddles.
/obj/item/mod/module/defibrillator
	name = "MOD defibrillator module"
	desc = "Модуль, встроенный в рукавицы костюма; широко известный среди медицинских работников как 'Целительные Руки'. \
		Пользователь размещает ладони над пациентом. Бортовые компьютеры костюма рассчитывают необходимое напряжение, \
		а модифицированный наведённый компьютер определяет лучшую позицию для нажатия. \
		К коже пациента прикладывается сила в двадцать пять фунтов. Импульсы проходят из перчаток костюма \
		через стандартные грудные электроды в сердце, и носитель возвращается в Медблок героем. \
		Даже не думайте использовать это как оружие; нормы производства и программные блокировки прямо запрещают это."
	icon_state = "defibrillator"
	module_type = MODULE_ACTIVE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 25
	device = /obj/item/shockpaddles/mod
	overlay_state_inactive = "module_defibrillator"
	overlay_state_active = "module_defibrillator_active"
	incompatible_modules = list(/obj/item/mod/module/defibrillator)
	cooldown_time = 0.5 SECONDS
	var/defib_cooldown = 5 SECONDS
	mod_module_flags = MOD_MODULE_MEDICAL // BLUEMOON ADD

/obj/item/mod/module/defibrillator/Initialize(mapload)
	. = ..()
	RegisterSignal(device, COMSIG_DEFIBRILLATOR_SUCCESS, PROC_REF(on_defib_success))

/obj/item/mod/module/defibrillator/Destroy()
	UnregisterSignal(device, COMSIG_DEFIBRILLATOR_SUCCESS)
	. = ..()

/obj/item/mod/module/defibrillator/proc/on_defib_success(obj/item/shockpaddles/source)
	drain_power(use_power_cost)
	source.recharge(defib_cooldown)
	return COMPONENT_DEFIB_STOP

/obj/item/shockpaddles/mod
	name = "MOD defibrillator gauntlets"
	req_defib = FALSE
	icon_state = "defibgauntlets0"
	item_state = "defibgauntlets0"
	base_icon_state = "defibgauntlets"

/obj/item/mod/module/defibrillator/combat
	name = "MOD combat defibrillator module"
	desc = "Модуль, встроенный в рукавицы костюма; широко известный среди медицинских работников как 'Целительные Руки'. \
		Пользователь размещает ладони над пациентом. Бортовые компьютеры костюма рассчитывают необходимое напряжение, \
		а модифицированный наведённый компьютер определяет лучшую позицию для нажатия. \
		К коже пациента прикладывается сила в двадцать пять фунтов. Импульсы проходят из перчаток костюма \
		и контр-шокируют сердце, и носитель возвращается в Медблок героем. \
		Interdyne Pharmaceutics продвигала бытовую версию Целительных Рук как надёжную и непригодную в качестве оружия. \
		Но когда пришло время снабдить своих оперативников пригодным медицинским оборудованием, они не стали колебаться, убрав \
		встроенные системы безопасности. Оперативники в поле могут воспользоваться тем, что они называют 'Оглушающие Перчатки', способные подавать импульсы \
		прямо в сердце жертвы для обездвиживания, или даже полностью остановить сердце при достаточной мощности."
	complexity = 1
	module_type = MODULE_ACTIVE
	overlay_state_inactive = "module_defibrillator_combat"
	overlay_state_active = "module_defibrillator_combat_active"
	device = /obj/item/shockpaddles/syndicate/mod
	defib_cooldown = 2.5 SECONDS

/obj/item/shockpaddles/syndicate/mod
	name = "MOD combat defibrillator gauntlets"
	req_defib = FALSE
	icon_state = "syndiegauntlets0"
	item_state = "syndiegauntlets0"
	base_icon_state = "syndiegauntlets"

///Thread Ripper

///Surgical Processor - Lets you do advanced surgeries portably.
/obj/item/mod/module/surgical_processor
	name = "MOD surgical processor module"
	desc = "Модуль с бортовым хирургическим компьютером, который можно подключить к другим компьютерам для загрузки и \
		выполнения продвинутых операций на ходу."
	icon_state = "surgical_processor"
	module_type = MODULE_ACTIVE
	complexity = 2
	active_power_cost = DEFAULT_CHARGE_DRAIN
	device = /obj/item/surgical_processor/mod
	incompatible_modules = list(/obj/item/mod/module/surgical_processor)
	cooldown_time = 0.5 SECONDS
	mod_module_flags = MOD_MODULE_MEDICAL // BLUEMOON ADD

/obj/item/surgical_processor/mod
	name = "MOD surgical processor"

/obj/item/mod/module/surgical_processor/preloaded
	desc = "Модуль с бортовым хирургическим компьютером, который можно подключить к другим компьютерам для загрузки и \
		выполнения продвинутых операций на ходу. Этот экземпляр предзагружен некоторыми продвинутыми операциями."
	device = /obj/item/surgical_processor/mod/preloaded

/obj/item/surgical_processor/mod/preloaded
	advanced_surgeries = list(
		/datum/surgery/advanced/pacify,
		/datum/surgery/healing/combo/upgraded/femto,
		/datum/surgery/advanced/brainwashing,
		/datum/surgery/advanced/bioware/nerve_splicing,
		/datum/surgery/advanced/bioware/nerve_grounding,
		/datum/surgery/advanced/bioware/vein_threading,
		/datum/surgery/advanced/bioware/muscled_veins,
		/datum/surgery/advanced/bioware/ligament_hook,
		/datum/surgery/advanced/bioware/ligament_reinforcement
	)

//Supply modules for MODsuits

///Internal GPS - Extends a GPS you can use.
/obj/item/mod/module/gps
	name = "MOD internal GPS module"
	desc = "Этот модуль использует обычную технологию Nanotrasen для вычисления положения пользователя в любом месте космоса \
		с точностью до координат. Эта информация передаётся в центральную базу данных, доступную с самого устройства, \
		хотя использовать её для помощи людям — решать вам."
	icon_state = "gps"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	incompatible_modules = list(/obj/item/mod/module/gps)
	cooldown_time = 0.5 SECONDS
	allowed_inactive = TRUE
	mod_module_flags = MOD_MODULE_SUPPLY // BLUEMOON ADD

/obj/item/gps/mod
	name = "MOD internal GPS"
	icon_state = "gps-trac"
	desc = "Выдвижной экран GPS, который является образцом самого обычного \
			модуля позиционирования, разработанного в Nanotrasen. Стоит \
			осознавать, что вашу позицию будет видно всем остальным владельцам такого устройства."

/obj/item/mod/module/gps/on_install()
	. = ..()
	var/obj/item/item_to_snap = new /obj/item/gps/mod(src)
	my_retract_component = AddComponent(/datum/component/mod_retractable, device = item_to_snap, modsuit = mod, retract_sound = my_retract_sound)

/obj/item/mod/module/gps/on_uninstall()
	. = ..()
	my_retract_component.RemoveComponent()
	qdel(my_retract_component)

/obj/item/mod/module/gps/on_use()
	. = ..()
	SEND_SIGNAL(my_retract_component, COMSIG_MODULE_ON_USE, src, mod.wearer)

///Hydraulic Clamp - Lets you pick up and drop crates.
/obj/item/mod/module/clamp
	name = "MOD hydraulic clamp module"
	desc = "Ряд актуаторов, установленных в обе руки костюма, с грузоподъёмностью почти в тонну. \
		Однако эта конструкция была заблокирована Nanotrasen для использования преимущественно для подъёма различных контейнеров. Также может использоваться для перемещения особенно тяжёлых членов экипажа. \
		Многие скажут, что погрузка грузов — скучная работа, но вы не могли бы с этим сильнее не согласиться."
	icon_state = "clamp"
	module_type = MODULE_ACTIVE
	complexity = 3
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/clamp)
	cooldown_time = 0.5 SECONDS
	overlay_state_inactive = "module_clamp"
	overlay_state_active = "module_clamp_on"
	/// Time it takes to load a crate.
	var/load_time = 3 SECONDS
	/// The max amount of crates you can carry.
	var/max_crates = 3
	/// The crates stored in the module.
	var/list/stored_crates = list()
	mod_module_flags = MOD_MODULE_SUPPLY // BLUEMOON ADD
	removable = TRUE

/obj/item/mod/module/clamp/on_select_use(atom/target)
	. = ..()
	if(!.)
		return
	if(!mod.wearer.Adjacent(target))
		return
	if(istype(target, /obj/structure/closet) || istype(target, /obj/structure/big_delivery) || istype(target, /obj/structure/ore_box))
		var/atom/movable/picked_crate = target
		if(!check_crate_pickup(picked_crate))
			return
		playsound(mod, 'sound/mecha/hydraulic.ogg', 25, TRUE)
		if(!do_after(mod.wearer, load_time, target = target))
			mod.balloon_alert(mod.wearer, "прервано!")
			return
		if(!check_crate_pickup(picked_crate))
			return
		stored_crates += picked_crate
		picked_crate.forceMove(src)
		mod.balloon_alert(mod.wearer, "picked up [picked_crate]")
		drain_power(use_power_cost)
	else if(length(stored_crates))
		var/turf/target_turf = get_turf(target)
		if(is_blocked_turf(target_turf))
			return
		playsound(mod, 'sound/mecha/hydraulic.ogg', 25, TRUE)
		if(!do_after(mod.wearer, load_time, target = target))
			mod.balloon_alert(mod.wearer, "прервано!")
			return
		if(is_blocked_turf(target_turf))
			return
		var/atom/movable/dropped_crate = pop(stored_crates)
		dropped_crate.forceMove(target_turf)
		mod.balloon_alert(mod.wearer, "dropped [dropped_crate]")
		drain_power(use_power_cost)
	else
		mod.balloon_alert(mod.wearer, "invalid target!")

/obj/item/mod/module/clamp/on_suit_deactivation(deleting = FALSE)
	if(deleting)
		return
	for(var/atom/movable/crate as anything in stored_crates)
		crate.forceMove(drop_location())
		stored_crates -= crate

/obj/item/mod/module/clamp/proc/check_crate_pickup(atom/movable/target)
	if(length(stored_crates) >= max_crates)
		mod.balloon_alert(mod.wearer, "too many crates!")
		return FALSE
	for(var/mob/living/mob in target.GetAllContents())
		if(mob.mob_size < MOB_SIZE_HUMAN)
			continue
		mod.balloon_alert(mod.wearer, "crate too heavy!")
		return FALSE
	return TRUE

/obj/item/mod/module/clamp/loader
	name = "MOD loader hydraulic clamp module"
	icon_state = "clamp_loader"
	complexity = 2
	overlay_state_inactive = null
	overlay_state_active = "module_clamp_loader"
	load_time = 1 SECONDS
	max_crates = 5
	use_mod_colors = TRUE
	mod_module_flags = MOD_MODULE_SUPPLY // BLUEMOON ADD

///Drill - Lets you dig through rock and basalt.
/obj/item/mod/module/drill // TODO: Would be cooler with a built-in drill, but meh
	name = "MOD pickaxe/drill storage module"
	desc = "Предоставляет удобное отделение для хранения кирок и дрелей."
	icon_state = "drill"
	complexity = 2
	incompatible_modules = list(/obj/item/mod/module/drill)
	cooldown_time = 0.5 SECONDS
	allowed_inactive = TRUE
	module_type = MODULE_USABLE
	/// Pickaxe we have stored.
	var/obj/item/pickaxe/stored
	mod_module_flags = MOD_MODULE_SUPPLY // BLUEMOON ADD

/obj/item/mod/module/drill/on_use()
	. = ..()
	if(!.)
		return
	if(!stored)
		var/obj/item/pickaxe/holding = mod.wearer.get_active_held_item()
		if(!holding)
			mod.balloon_alert(mod.wearer, "нечего хранить!")
			return
		if(!istype(holding))
			mod.balloon_alert(mod.wearer, "не подходит!")
			return
		if(mod.wearer.transferItemToLoc(holding, src, force = FALSE, silent = TRUE))
			stored = holding
			mod.balloon_alert(mod.wearer, "шахтёрский инструмент вставлен")
			playsound(mod, 'sound/weapons/revolverempty.ogg', 100, TRUE)
	else if(mod.wearer.put_in_active_hand(stored, forced = FALSE, ignore_animation = TRUE))
		mod.balloon_alert(mod.wearer, "шахтёрский инструмент возвращён")
		playsound(mod, 'sound/weapons/revolverempty.ogg', 100, TRUE)
	else
		mod.balloon_alert(mod.wearer, "в модуле уже что-то есть!")

/obj/item/mod/module/drill/on_uninstall(deleting = FALSE)
	if(stored)
		stored.forceMove(drop_location())

/obj/item/mod/module/drill/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == stored)
		stored = null

/obj/item/mod/module/drill/Destroy()
	QDEL_NULL(stored)
	return ..()

/obj/item/mod/module/orebag // TODO
	name = "MOD mining satchel storage module"
	desc = "Предоставляет удобное отделение для хранения шахтёрской сумки."
	icon_state = "ore"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.2
	incompatible_modules = list(/obj/item/mod/module/orebag)
	cooldown_time = 0.5 SECONDS
	allowed_inactive = TRUE
	/// Pickaxe we have stored.
	var/obj/item/storage/bag/ore/stored
	mod_module_flags = MOD_MODULE_SUPPLY // BLUEMOON ADD

/obj/item/mod/module/orebag/on_use()
	. = ..()
	if(!.)
		return
	if(!stored)
		var/obj/item/storage/bag/ore/holding = mod.wearer.get_active_held_item()
		if(!holding)
			mod.balloon_alert(mod.wearer, "нечего хранить!")
			return
		if(!istype(holding))
			mod.balloon_alert(mod.wearer, "это не подходит!")
			return
		if(mod.wearer.transferItemToLoc(holding, src, force = FALSE, silent = TRUE))
			stored = holding
			mod.balloon_alert(mod.wearer, "сумка для руды успешно помещена")
			playsound(mod, 'sound/weapons/revolverempty.ogg', 100, TRUE)
			RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(Pickup_ores))
	else if(mod.wearer.put_in_active_hand(stored, forced = FALSE, ignore_animation = TRUE))
		UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
		mod.balloon_alert(mod.wearer, "сумка для руды возвращена")
		playsound(mod, 'sound/weapons/revolverempty.ogg', 100, TRUE)
	else
		mod.balloon_alert(mod.wearer, "сумка для руды переполнена!")

/obj/item/mod/module/orebag/on_uninstall(deleting = FALSE)
	if(stored)
		UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
		stored.forceMove(drop_location())

/obj/item/mod/module/orebag/on_equip()
	if(stored)
		RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(Pickup_ores))

/obj/item/mod/module/orebag/on_unequip()
	if(stored)
		UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)

/obj/item/mod/module/orebag/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == stored)
		UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
		stored = null

/obj/item/mod/module/orebag/Destroy()
	if(stored)
		UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
	QDEL_NULL(stored)
	return ..()

/obj/item/mod/module/orebag/proc/Pickup_ores()
	if(stored)
		stored.Pickup_ores(mod.wearer)

// Ash accretion looks cool, but can't be arsed to implement
// Same with sphere transformation

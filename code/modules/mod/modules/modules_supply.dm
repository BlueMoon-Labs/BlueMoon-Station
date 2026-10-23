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
	var/datum/component/gps/item/internal_gps

/obj/item/mod/module/gps/on_install()
	. = ..()
	internal_gps = mod.AddComponent(/datum/component/gps/item/modsuit, "MODsuit GPS", FALSE, TRUE, null, null, TRUE)

/obj/item/mod/module/gps/on_uninstall(deleting, user)
	qdel(internal_gps)
	internal_gps = null
	. = ..()

/obj/item/mod/module/gps/on_use()
	. = ..()
	if(!.)
		return
	if(SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SELF, mod.wearer))
		return
	internal_gps.interact(mod, mod.wearer)//source, user


/obj/item/mod/module/gps/vanguard
	complexity = 0
	removable = FALSE

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
	have_shortcut_activation = TRUE
	required_modpart_index = MOD_PART_GLOVES
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
	if(!..() || !mod.wearer.Adjacent(target))
		return FALSE
	if(istype(target, /obj/structure/closet) || istype(target, /obj/structure/big_delivery) || istype(target, /obj/structure/ore_box))
		return load_crate(target)
	return unload_crate(get_turf(target))

/obj/item/mod/module/clamp/proc/load_crate(atom/movable/crate)
	if(!check_crate_pickup(crate))
		return FALSE
	var/mob/living/carbon/human/user = mod.wearer
	playsound(mod, 'sound/mecha/hydraulic.ogg', MOD_SUPPORT_VOLUME, TRUE)
	if(!do_after(user, load_time, target = crate) || !can_handle_cargo(user, crate) || !check_crate_pickup(crate))
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	stored_crates += crate
	RegisterSignal(crate, COMSIG_PARENT_QDELETING, PROC_REF(on_crate_deleted))
	crate.forceMove(src)
	mod.balloon_alert(user, "picked up [crate]")
	return TRUE

/obj/item/mod/module/clamp/proc/unload_crate(turf/target)
	if(!length(stored_crates) || !target || is_blocked_turf(target))
		return FALSE
	var/mob/living/carbon/human/user = mod.wearer
	playsound(mod, 'sound/mecha/hydraulic.ogg', MOD_SUPPORT_VOLUME, TRUE)
	if(!do_after(user, load_time, target) || !can_handle_cargo(user, target) || is_blocked_turf(target) || !length(stored_crates))
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	var/atom/movable/crate = stored_crates[length(stored_crates)]
	crate.forceMove(target)
	mod.balloon_alert(user, "dropped [crate]")
	return TRUE

/obj/item/mod/module/clamp/proc/can_handle_cargo(mob/living/carbon/human/user, atom/target)
	return !QDELETED(target) && active && mod?.wearer == user && !mod.is_activating() && check_required_modpart() && user.Adjacent(target)

/obj/item/mod/module/clamp/proc/check_crate_pickup(atom/movable/target)
	if(QDELETED(target) || !isturf(target.loc) || target.anchored || target.move_resist >= MOVE_FORCE_OVERPOWERING)
		return FALSE
	if(length(stored_crates) >= max_crates)
		mod.balloon_alert(mod.wearer, "too many crates!")
		return FALSE
	for(var/mob/living/mob in target.GetAllContents())
		if(mob.mob_size < MOB_SIZE_HUMAN)
			continue
		mod.balloon_alert(mod.wearer, "crate too heavy!")
		return FALSE
	return TRUE

/obj/item/mod/module/clamp/Exited(atom/movable/gone, direction)
	. = ..()
	forget_crate(gone)

/obj/item/mod/module/clamp/proc/on_crate_deleted(atom/movable/crate)
	SIGNAL_HANDLER
	forget_crate(crate)

/obj/item/mod/module/clamp/proc/forget_crate(atom/movable/crate)
	if(!(crate in stored_crates))
		return
	UnregisterSignal(crate, COMSIG_PARENT_QDELETING)
	stored_crates -= crate

/obj/item/mod/module/clamp/proc/release_crates()
	var/atom/destination = mod ? mod.drop_location() : drop_location()
	for(var/atom/movable/crate in stored_crates.Copy())
		forget_crate(crate)
		if(!QDELETED(crate))
			crate.forceMove(destination)

/obj/item/mod/module/clamp/on_suit_deactivation(deleting = FALSE)
	release_crates()

/obj/item/mod/module/clamp/on_uninstall(deleting = FALSE, user)
	release_crates()
	return ..()

/obj/item/mod/module/clamp/Destroy()
	release_crates()
	return ..()

/obj/item/mod/module/clamp/loader
	name = "MOD loader hydraulic clamp module"
	icon_state = "clamp_loader"
	complexity = 0
	overlay_state_inactive = null
	overlay_state_active = "module_clamp_loader"
	load_time = 1 SECONDS
	max_crates = 5
	use_mod_colors = TRUE
	mod_module_flags = MOD_MODULE_SUPPLY // BLUEMOON ADD

/obj/item/mod/module/drill
	name = "MOD drill module"
	desc = "Выдвижной бур на перчатке. Копает породу и грунт по Alt+клику, а породу — ещё и при столкновении. В форме сферы копает мгновенно и потребляет вдвое меньше энергии."
	icon_state = "drill"
	complexity = 1
	module_type = MODULE_ACTIVE
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/drill)
	cooldown_time = 0.2 SECONDS
	required_modpart_index = MOD_PART_GLOVES
	have_shortcut_activation = TRUE
	overlay_state_active = "module_drill"
	toolspeed = 0.25
	usesound = 'sound/weapons/drill.ogg'
	mod_module_flags = MOD_MODULE_SUPPLY
	var/sphere_mode = FALSE
	var/last_bump_tick = -1
	var/digrange = 0
	var/mob/living/carbon/human/drill_user
	COOLDOWN_DECLARE(gibtonite_warning_cd)

/obj/item/mod/module/drill/on_activation()
	if(sphere_mode)
		balloon_alert(mod?.wearer, "сначала отключите сферу")
		return FALSE
	if(!..())
		return FALSE
	refresh_drill()
	return TRUE

/obj/item/mod/module/drill/on_deactivation()
	. = ..()
	refresh_drill()

/obj/item/mod/module/drill/on_uninstall(deleting = FALSE, user)
	sphere_mode = FALSE
	clear_drill()
	return ..()

/obj/item/mod/module/drill/on_suit_deactivation()
	sphere_mode = FALSE
	clear_drill()

/obj/item/mod/module/drill/on_unequip()
	sphere_mode = FALSE
	clear_drill()

/obj/item/mod/module/drill/Destroy()
	sphere_mode = FALSE
	clear_drill()
	return ..()

/obj/item/mod/module/drill/proc/set_sphere_mode(enabled)
	sphere_mode = enabled && mod?.is_active() && mod.all_parts_deployed()
	refresh_drill()

/obj/item/mod/module/drill/proc/refresh_drill()
	clear_drill()
	toolspeed = sphere_mode ? 0 : initial(toolspeed)
	if(!(active || sphere_mode) || !mod?.is_active() || !check_required_modpart())
		return
	drill_user = mod.wearer
	tool_behaviour = TOOL_MINING
	RegisterSignal(drill_user, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))

/obj/item/mod/module/drill/proc/clear_drill()
	UnregisterSignal(drill_user, COMSIG_MOVABLE_BUMP)
	drill_user = null
	tool_behaviour = NONE
	toolspeed = initial(toolspeed)
	last_bump_tick = -1

/obj/item/mod/module/drill/on_select_use(atom/target)
	if(!mod?.wearer?.Adjacent(target) || !(ismineralturf(target) || istype(target, /turf/open/floor/plating/asteroid)))
		return FALSE
	if(!..() || !drain_power(use_power_cost))
		return FALSE
	INVOKE_ASYNC(target, TYPE_PROC_REF(/atom, attackby), src, mod.wearer)
	return TRUE

/obj/item/mod/module/drill/proc/on_bump(mob/source, atom/target)
	SIGNAL_HANDLER
	bump_mine(target)

/obj/item/mod/module/drill/proc/bump_mine(turf/closed/mineral/rock)
	if(!istype(rock) || !drill_user || !tool_behaviour || !check_required_modpart() || world.time == last_bump_tick)
		return FALSE
	last_bump_tick = world.time
	var/turf/closed/mineral/gibtonite/gibtonite = rock
	if(istype(gibtonite) && gibtonite.stage == GIBTONITE_UNSTRUCK)
		if(COOLDOWN_FINISHED(src, gibtonite_warning_cd))
			COOLDOWN_START(src, gibtonite_warning_cd, MOD_DRILL_WARNING_COOLDOWN)
			balloon_alert(drill_user, "в породе нетронутый гибтонит!")
			playsound(drill_user, 'sound/machines/scanbuzz.ogg', MOD_DRILL_VOLUME, TRUE)
		return FALSE
	var/power_cost = sphere_mode ? use_power_cost * MOD_DRILL_SPHERE_POWER : use_power_cost
	if(!drain_power(power_cost))
		return FALSE
	INVOKE_ASYNC(rock, TYPE_PROC_REF(/atom, attackby), src, drill_user)
	return TRUE

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

/obj/item/mod/module/sphere_transform
	name = "MOD sphere transform module"
	desc = "Превращает полностью развёрнутый MOD в быструю бронированную сферу. Alt+клик запускает шахтёрскую бомбу при низком давлении. Два куска кожи желчного червя дают защиту от лавы."
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	icon_state = "sphere"
	module_type = MODULE_ACTIVE
	removable = FALSE
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	cooldown_time = 1 SECONDS
	incompatible_modules = list(/obj/item/mod/module/sphere_transform)
	need_full_deploy = TRUE
	have_shortcut_activation = TRUE
	hands_free_use = TRUE
	mod_module_flags = MOD_MODULE_SUPPLY
	overlay_icon_file = 'icons/mob/clothing/modsuit/mod_modules_whitemoon.dmi'
	var/hide_upgrade = FALSE
	var/mob/living/carbon/human/sphere_user
	var/list/armored_parts
	var/matrix/old_transform
	var/old_gravity_inverted
	var/steps = 0
	var/static/list/user_traits = list(TRAIT_FORCED_STANDING, TRAIT_HANDS_BLOCKED, TRAIT_NOSLIPALL, TRAIT_SILENT_STEP)

/obj/item/mod/module/sphere_transform/on_install()
	. = ..()
	RegisterSignal(mod, COMSIG_PARENT_ATTACKBY, PROC_REF(on_upgrade))

/obj/item/mod/module/sphere_transform/on_uninstall(deleting = FALSE, user)
	clear_sphere()
	UnregisterSignal(mod, COMSIG_PARENT_ATTACKBY)
	return ..()

/obj/item/mod/module/sphere_transform/Destroy()
	clear_sphere()
	return ..()

/obj/item/mod/module/sphere_transform/on_unequip()
	if(sphere_user)
		on_deactivation()

/obj/item/mod/module/sphere_transform/proc/on_upgrade(datum/source, obj/item/item, mob/user)
	SIGNAL_HANDLER
	return reinforce(item, user) ? COMPONENT_NO_AFTERATTACK : NONE

/obj/item/mod/module/sphere_transform/attackby(obj/item/item, mob/user, params)
	if(!reinforce(item, user))
		return ..()

/obj/item/mod/module/sphere_transform/proc/reinforce(obj/item/item, mob/user)
	if(!istype(item, /obj/item/stack/sheet/animalhide/bileworm))
		return FALSE
	if(hide_upgrade)
		balloon_alert(user, "сфера уже усилена")
		return TRUE
	var/obj/item/stack/sheet/animalhide/bileworm/hide = item
	if(!hide.use(MOD_SPHERE_HIDE_AMOUNT))
		balloon_alert(user, "нужно два куска кожи")
		return TRUE
	hide_upgrade = TRUE
	overlay_state_inactive = "module_bileworm_bracing"
	if(sphere_user)
		ADD_TRAIT(sphere_user, TRAIT_LAVA_IMMUNE, REF(src))
	mod?.update_control_overlay()
	balloon_alert(user, "защита от лавы установлена")
	return TRUE

/obj/item/mod/module/sphere_transform/on_activation()
	if(active || !mod?.wearer || !mod.wearer.has_gravity())
		balloon_alert(mod?.wearer, "нужна гравитация")
		return FALSE
	if(!..())
		return FALSE
	sphere_user = mod.wearer
	for(var/trait in user_traits)
		ADD_TRAIT(sphere_user, trait, REF(src))
	if(hide_upgrade)
		ADD_TRAIT(sphere_user, TRAIT_LAVA_IMMUNE, REF(src))
	sphere_user.add_movespeed_mod_immunities(REF(src), /datum/movespeed_modifier/damage_slowdown)
	sphere_user.add_movespeed_modifier(/datum/movespeed_modifier/mod_sphere)
	sphere_user.update_mobility()
	apply_visuals()
	RegisterSignal(sphere_user, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	RegisterSignal(sphere_user, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))
	RegisterSignal(sphere_user, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_part_removed))
	RegisterSignal(sphere_user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	armored_parts = mod.get_mod_parts(include_cell = FALSE, include_mod = TRUE)
	change_armor(MOD_SPHERE_ARMOR)
	var/obj/item/mod/module/drill/drill = locate() in mod.modules
	drill?.set_sphere_mode(TRUE)
	playsound(mod, 'sound/items/modsuit/ballin.ogg', MOD_SPHERE_VOLUME, TRUE)
	return TRUE

/obj/item/mod/module/sphere_transform/proc/apply_visuals()
	old_transform = matrix(sphere_user.transform)
	old_gravity_inverted = sphere_user.gravity_inverted
	sphere_user.add_filter("mod_ball", 1, alpha_mask_filter(icon = icon(overlay_icon_file, "ball_mask"), flags = MASK_INVERSE))
	sphere_user.add_filter("mod_blur", 2, angular_blur_filter(size = MOD_SPHERE_BLUR))
	sphere_user.add_filter("mod_outline", 3, outline_filter(color = "#000000AA"))
	sphere_user.pixel_y += MOD_SPHERE_OFFSET

/obj/item/mod/module/sphere_transform/on_deactivation()
	clear_sphere()
	return ..()

/obj/item/mod/module/sphere_transform/proc/clear_sphere()
	if(!sphere_user)
		return
	var/obj/item/mod/module/drill/drill = locate() in mod.modules
	drill?.set_sphere_mode(FALSE)
	change_armor(-MOD_SPHERE_ARMOR)
	armored_parts = null
	UnregisterSignal(sphere_user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_STATCHANGE, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_PARENT_QDELETING))
	sphere_user.remove_filter(list("mod_ball", "mod_blur", "mod_outline"))
	sphere_user.pixel_y -= MOD_SPHERE_OFFSET
	var/matrix/restored = matrix(old_transform)
	if(old_gravity_inverted != sphere_user.gravity_inverted)
		restored.Scale(1, -1)
	animate(sphere_user, transform = restored, time = 0, flags = ANIMATION_END_NOW, tag = "mod_sphere")
	for(var/trait in user_traits)
		REMOVE_TRAIT(sphere_user, trait, REF(src))
	REMOVE_TRAIT(sphere_user, TRAIT_LAVA_IMMUNE, REF(src))
	sphere_user.remove_movespeed_mod_immunities(REF(src), /datum/movespeed_modifier/damage_slowdown)
	sphere_user.remove_movespeed_modifier(/datum/movespeed_modifier/mod_sphere)
	sphere_user.update_mobility()
	sphere_user = null
	old_transform = null
	old_gravity_inverted = null
	steps = 0

/obj/item/mod/module/sphere_transform/proc/change_armor(amount)
	for(var/obj/item/part as anything in armored_parts)
		if(!QDELETED(part))
			part.set_armor(part.get_armor().modifyRating(melee = amount, bomb = amount))

/obj/item/mod/module/sphere_transform/on_active_process(delta_time)
	if(!sphere_user?.has_gravity() || sphere_user.stat || !mod.all_parts_deployed())
		on_deactivation()

/obj/item/mod/module/sphere_transform/proc/on_move(datum/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	if(!sphere_user.has_gravity())
		on_deactivation()
		return
	sphere_user.SpinAnimation(MOD_SPHERE_SPIN, loops = 1, tag = "mod_sphere")
	if(forced || HAS_TRAIT_NOT_FROM(sphere_user, TRAIT_SILENT_STEP, REF(src)))
		return
	steps++
	if(!(steps % MOD_SPHERE_STEPS))
		playsound(sphere_user, FOOTSTEP_SOUND_OBJ_ROBOT, MOD_SPHERE_STEP_VOLUME, TRUE)

/obj/item/mod/module/sphere_transform/proc/on_stat_change()
	SIGNAL_HANDLER
	if(sphere_user?.stat)
		on_deactivation()

/obj/item/mod/module/sphere_transform/proc/on_part_removed(mob/source, obj/item/item)
	SIGNAL_HANDLER
	if(mod.is_mod_part(item))
		on_deactivation()

/obj/item/mod/module/sphere_transform/proc/on_user_deleted()
	SIGNAL_HANDLER
	if(sphere_user)
		on_deactivation()

/obj/item/mod/module/sphere_transform/on_select_use(atom/target)
	if(!active || !mod?.wearer || !get_turf(target))
		return FALSE
	if(!lavaland_equipment_pressure_check(get_turf(mod)))
		balloon_alert(mod?.wearer, "слишком высокое давление")
		return FALSE
	if(!..() || !drain_power(use_power_cost))
		return FALSE
	var/obj/item/projectile/mod_mining_bomb/bomb = new(get_turf(mod.wearer))
	bomb.firer = mod.wearer
	bomb.preparePixelProjectile(target, mod.wearer)
	playsound(mod, 'sound/weapons/grenadelaunch.ogg', MOD_SPHERE_VOLUME, TRUE)
	INVOKE_ASYNC(bomb, TYPE_PROC_REF(/obj/item/projectile, fire))
	return TRUE

/datum/movespeed_modifier/mod_sphere
	multiplicative_slowdown = -0.5

/obj/item/stack/sheet/animalhide/bileworm
	name = "bileworm skin"
	desc = "Влажная блестящая кожа желчного червя. Подходит для защиты шахтёрской сферы от лавы."
	singular_name = "bileworm skin piece"
	icon = 'icons/obj/clothing/modsuit/bileworm.dmi'
	icon_state = "sheet-bileworm"
	item_state = null
	merge_type = /obj/item/stack/sheet/animalhide/bileworm

/obj/item/projectile/mod_mining_bomb
	name = "mining bomb"
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	icon_state = "mine_bomb"
	damage = 0
	range = 6
	suppressed = SUPPRESSED_VERY
	flag = BOMB
	var/dropped_bomb = FALSE

/obj/item/projectile/mod_mining_bomb/on_hit(atom/target, blocked = FALSE, pierce_hit)
	drop_bomb()
	return ..()

/obj/item/projectile/mod_mining_bomb/on_range()
	drop_bomb()
	return ..()

/obj/item/projectile/mod_mining_bomb/proc/drop_bomb()
	if(dropped_bomb || !get_turf(src))
		return FALSE
	dropped_bomb = TRUE
	var/obj/structure/mod_mining_bomb/bomb = new(get_turf(src))
	addtimer(CALLBACK(bomb, TYPE_PROC_REF(/obj/structure/mod_mining_bomb, prime), firer), MOD_SPHERE_BOMB_PRIME_TIME)
	return TRUE

/obj/structure/mod_mining_bomb
	name = "mining bomb"
	desc = "Небольшой направленный заряд для разрушения породы."
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	icon_state = "mine_bomb"
	anchored = TRUE
	density = FALSE
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	light_system = OVERLAY_LIGHT
	light_range = 1
	light_power = 1
	light_color = COLOR_LIGHT_ORANGE
	var/primed = FALSE

/obj/structure/mod_mining_bomb/proc/prime(mob/firer)
	if(primed)
		return
	primed = TRUE
	new /obj/effect/temp_visual/mod_mining_explosion(get_turf(src))
	addtimer(CALLBACK(src, PROC_REF(boom), firer), MOD_SPHERE_BOMB_DELAY)

/obj/structure/mod_mining_bomb/proc/boom(mob/firer)
	playsound(src, 'sound/magic/magic_missile.ogg', MOD_SPHERE_VOLUME, TRUE)
	for(var/turf/closed/mineral/rock in circlerangeturfs(src, MOD_SPHERE_BLAST_RANGE))
		rock.gets_drilled()
	for(var/mob/living/victim in range(MOD_SPHERE_BLAST_RANGE, src))
		if(HAS_TRAIT(victim, TRAIT_MINING_AOE_IMMUNE))
			continue
		var/damage = MOD_SPHERE_BOMB_DAMAGE
		if(istype(victim, /mob/living/simple_animal/hostile/asteroid))
			damage *= MOD_SPHERE_FAUNA_MULTIPLIER
		victim.apply_damage(damage, BRUTE, spread_damage = TRUE)
		to_chat(victim, span_userdanger("Вас задел взрыв шахтёрской бомбы!"))
		if(firer && ishostile(victim))
			var/mob/living/simple_animal/hostile/hostile = victim
			hostile.GiveTarget(firer)
	for(var/obj/object in range(MOD_SPHERE_BLAST_RANGE, src))
		if(object != src)
			object.take_damage(MOD_SPHERE_BOMB_DAMAGE, BRUTE, BOMB)
	qdel(src)

/obj/effect/temp_visual/mod_mining_explosion
	icon = 'icons/effects/96x96.dmi'
	icon_state = "judicial_explosion"
	pixel_x = -32
	pixel_y = -32
	layer = ABOVE_MOB_LAYER
	duration = 1.35 SECONDS

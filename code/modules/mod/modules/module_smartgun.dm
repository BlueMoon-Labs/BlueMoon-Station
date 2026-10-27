/obj/item/mod/module/smartgun
	name = "MOD smartgun module"
	desc = "Кобура с тяжёлым M63A4: автоматический огонь, распознавание союзников и питание от MOD."
	icon = 'icons/obj/clothing/modsuit/mod_smartgun_whitemoon.dmi'
	icon_state = "smartgun"
	overlay_icon_file = 'icons/mob/clothing/modsuit/mod_smartgun_whitemoon.dmi'
	overlay_state_inactive = "module_smartgun_off"
	overlay_state_active = "module_smartgun_on"
	module_type = MODULE_ACTIVE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	device = /obj/item/gun/ballistic/automatic/smart_machine_gun
	required_modpart_index = MOD_PART_GLOVES
	incompatible_modules = list(/obj/item/mod/module/smartgun)
	cooldown_time = 0.5 SECONDS

/obj/item/mod/module/smartgun/on_install()
	. = ..()
	var/obj/item/gun/ballistic/automatic/smart_machine_gun/gun = device
	gun.power_module = src

/obj/item/mod/module/smartgun/on_uninstall(deleting = FALSE, user)
	var/obj/item/gun/ballistic/automatic/smart_machine_gun/gun = device
	if(gun)
		gun.power_module = null
	return ..()

/obj/item/mod/module/smartgun/Destroy()
	var/obj/item/gun/ballistic/automatic/smart_machine_gun/gun = device
	if(gun)
		gun.power_module = null
	return ..()

/obj/item/mod/module/smartgun/marines
	removable = FALSE

/obj/item/gun/ballistic/automatic/smart_machine_gun
	name = "M63A4 Smartgun"
	desc = "Тяжёлый пулемёт, предназначенный для крепления к MOD. Пули обходят членов ERT."
	icon = 'icons/obj/clothing/modsuit/smartgun_whitemoon.dmi'
	icon_state = "smartgun"
	item_state = "smartgun"
	lefthand_file = 'icons/mob/inhands/mod_smartgun_left_whitemoon.dmi'
	righthand_file = 'icons/mob/inhands/mod_smartgun_right_whitemoon.dmi'
	fire_sound = 'modular_bluemoon/fluffs/sound/weapon/at41_fire.ogg'
	weapon_weight = WEAPON_HEAVY
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	spread = 18
	mag_type = /obj/item/ammo_box/magazine/smartgun_drum
	can_suppress = FALSE
	fire_delay = 0.15
	burst_size = 1
	actions_types = list()
	pin = /obj/item/firing_pin/implant/mindshield
	automatic_burst_overlay = FALSE
	tactical_reload = FALSE
	casing_ejector = FALSE
	var/cover_open = FALSE
	var/list/iff_factions = list("ert")
	var/obj/item/mod/module/smartgun/power_module

/obj/item/gun/ballistic/automatic/smart_machine_gun/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, fire_delay)

/obj/item/gun/ballistic/automatic/smart_machine_gun/Destroy()
	power_module = null
	return ..()

/obj/item/gun/ballistic/automatic/smart_machine_gun/update_icon_state()
	icon_state = initial(icon_state)

/obj/item/gun/ballistic/automatic/smart_machine_gun/update_overlays()
	. = ..()
	if(cover_open)
		. += "smartgun_door_open"

/obj/item/gun/ballistic/automatic/smart_machine_gun/examine(mob/user)
	. = ..()
	. += span_notice("Используйте оружие в руке, чтобы открыть или закрыть крышку магазина.")
	if(cover_open && magazine)
		. += span_notice("Нажмите пустой рукой, чтобы извлечь магазин.")

/obj/item/gun/ballistic/automatic/smart_machine_gun/attack_self(mob/user)
	cover_open = !cover_open
	balloon_alert(user, cover_open ? "крышка открыта" : "крышка закрыта")
	playsound(src, 'sound/items/weapons/gun/l6/l6_door.ogg', MOD_SMARTGUN_COVER_VOLUME, TRUE)
	update_icon()

/obj/item/gun/ballistic/automatic/smart_machine_gun/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(!cover_open || !magazine || loc != user)
		return ..()
	var/obj/item/ammo_box/magazine/old_mag = magazine
	magazine = null
	if(!user.put_in_hands(old_mag))
		old_mag.forceMove(get_turf(user))
	update_icon()
	balloon_alert(user, "магазин извлечён")
	return TRUE

/obj/item/gun/ballistic/automatic/smart_machine_gun/attackby(obj/item/item, mob/user, params)
	if(!cover_open && istype(item, mag_type))
		balloon_alert(user, "откройте крышку")
		return FALSE
	return ..()

/obj/item/gun/ballistic/automatic/smart_machine_gun/can_shoot()
	if(cover_open || !power_module || QDELETED(power_module))
		return FALSE
	if(!power_module.active || !power_module.check_power(MOD_SMARTGUN_SHOT_POWER))
		return FALSE
	return ..()

/obj/item/gun/ballistic/automatic/smart_machine_gun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(!power_module || QDELETED(power_module) || user != power_module.mod?.wearer || !can_shoot())
		balloon_alert(user, "нет питания")
		return FALSE
	. = ..()
	if(.)
		power_module.drain_power(MOD_SMARTGUN_SHOT_POWER)

/obj/item/gun/ballistic/automatic/smart_machine_gun/process_chamber(mob/living/user, empty_chamber = 1)
	var/obj/item/ammo_casing/old_round = chambered
	. = ..()
	if(old_round && old_round != chambered)
		qdel(old_round)

/obj/item/gun/ballistic/automatic/smart_machine_gun/unrestricted
	pin = /obj/item/firing_pin

/obj/item/ammo_box/magazine/smartgun_drum
	name = "smartgun drum (10x28mm caseless)"
	icon = 'icons/obj/clothing/modsuit/smartgun_ammo_whitemoon.dmi'
	icon_state = "smartgun_drum"
	ammo_type = /obj/item/ammo_casing/smart/a10x28
	caliber = "a10x28"
	max_ammo = 500
	multiple_sprites = 0
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/ammo_box/magazine/smartgun_drum/update_icon_state()
	icon_state = "smartgun_drum-[length(stored_ammo) ? "full" : "empty"]"

/obj/item/ammo_casing/smart
	firing_effect_type = null

/obj/item/ammo_casing/smart/ready_proj(atom/target, mob/living/user, quiet, zone_override = "", fired_from)
	if(istype(fired_from, /obj/item/gun/ballistic/automatic/smart_machine_gun) && istype(BB, /obj/item/projectile/bullet/smart))
		var/obj/item/gun/ballistic/automatic/smart_machine_gun/gun = fired_from
		var/obj/item/projectile/bullet/smart/bullet = BB
		bullet.ignored_factions = gun.iff_factions.Copy()
	return ..()

/obj/item/ammo_casing/smart/a10x28
	name = "10x28mm caseless bullet"
	icon_state = "762-casing"
	caliber = "a10x28"
	projectile_type = /obj/item/projectile/bullet/smart/a10x28

/obj/item/projectile/bullet/smart
	var/list/ignored_factions

/obj/item/projectile/bullet/smart/prehit_pierce(atom/target)
	if(isliving(target) && length(ignored_factions))
		var/mob/living/living_target = target
		if(length(living_target.faction & ignored_factions))
			return PROJECTILE_PIERCE_PHASE
	return ..()

/obj/item/projectile/bullet/smart/a10x28
	name = "10x28mm bullet"
	damage = 9
	wound_bonus = -5
	wound_falloff_tile = -1

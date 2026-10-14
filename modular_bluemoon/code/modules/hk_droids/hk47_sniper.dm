/obj/item/projectile/beam/hk_bolt/sniper
	name = "HK sniper bolt"
	damage = HK47_SNIPER_DAMAGE
	armour_penetration = HK47_SNIPER_ARMOUR_PENETRATION

/obj/item/ammo_casing/energy/hk_bolt/sniper
	projectile_type = /obj/item/projectile/beam/hk_bolt/sniper
	e_cost = HK_RIFLE_SHOT_COST * HK47_SNIPER_SHOT_CHARGES
	select_name = "sniper"
	fire_sound = 'sound/weapons/beam_sniper.ogg'

/obj/item/gun/energy/hk_rifle
	var/aiming = FALSE
	/// Выстрел после прицеливания: process_fire пропускает его без нового прицела.
	var/sniper_shot_armed = FALSE
	COOLDOWN_DECLARE(sniper_cooldown)

/obj/item/gun/energy/hk_rifle/proc/unlock_sniper()
	if(sniper_unlocked)
		return FALSE
	sniper_unlocked = TRUE
	var/obj/item/ammo_casing/energy/hk_bolt/sniper/casing = new(src)
	ammo_type += casing
	ammo_type[casing] = TRUE
	return TRUE

/obj/item/gun/energy/hk_rifle/proc/sniper_selected()
	return istype(ammo_type[current_firemode_index], /obj/item/ammo_casing/energy/hk_bolt/sniper)

/obj/item/gun/energy/hk_rifle/select_fire(mob/living/user)
	if(!sniper_unlocked)
		return
	set_firemode_index(current_firemode_index + 1)
	if(sniper_selected())
		to_chat(user, span_notice("Снайперский режим: прицеливание [HK47_SNIPER_AIM_TIME / (1 SECONDS)] с, выстрел стоит [HK47_SNIPER_SHOT_CHARGES] заряда."))
	else
		to_chat(user, span_notice("Обычный режим: одиночные выстрелы."))

/obj/item/gun/energy/hk_rifle/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(!sniper_selected() || sniper_shot_armed)
		return ..()
	if(!user || aiming)
		return FALSE
	if(!COOLDOWN_FINISHED(src, sniper_cooldown))
		to_chat(user, span_warning("Утверждение: снайперский режим перезаряжается, ещё [DisplayTimeText(COOLDOWN_TIMELEFT(src, sniper_cooldown))]."))
		return FALSE
	INVOKE_ASYNC(src, PROC_REF(sniper_aim), target, user, params, zone_override)
	return FALSE

/// Телеграф выстрела: луч прицела видят все, цель успевает уйти с линии.
/obj/item/gun/energy/hk_rifle/proc/sniper_aim(atom/target, mob/living/user, params, zone_override)
	aiming = TRUE
	var/datum/beam/beam = aim_beam(user, target)
	user.visible_message(span_danger("[user] вскидывает [src], и красный луч прицела ложится на [target]!"), span_notice("Прицеливание: не двигайтесь и держите цель в поле зрения."))
	playsound(user, 'sound/effects/seedling_chargeup.ogg', 40, FALSE)
	hk47_upgrade_voice(user, "hk47_target_acquired")
	var/aimed = do_after(user, HK47_SNIPER_AIM_TIME, target, IGNORE_TARGET_LOC_CHANGE, extra_checks = CALLBACK(src, PROC_REF(sniper_aim_holds), user, target))
	QDEL_NULL(beam)
	aiming = FALSE
	if(!aimed || QDELETED(src) || QDELETED(target))
		to_chat(user, span_warning("Утверждение: прицел сбит."))
		return FALSE
	return sniper_fire(target, user, params, zone_override)

/// Луч дотягивается до края дальности прицела: у Beam по умолчанию только 10 клеток.
/obj/item/gun/energy/hk_rifle/proc/aim_beam(mob/living/user, atom/target)
	return user.Beam(target, icon_state = "r_beam", time = HK47_SNIPER_AIM_TIME * 2, maxdistance = HK47_SNIPER_AIM_RANGE + 1)

/obj/item/gun/energy/hk_rifle/proc/sniper_aim_holds(mob/living/user, atom/target)
	if(QDELETED(target) || loc != user || !sniper_selected())
		return FALSE
	var/turf/user_turf = get_turf(user)
	var/turf/target_turf = get_turf(target)
	if(!user_turf || !target_turf || user_turf.z != target_turf.z || get_dist(user_turf, target_turf) > HK47_SNIPER_AIM_RANGE)
		return FALSE
	return can_see(user_turf, target_turf, HK47_SNIPER_AIM_RANGE)

/obj/item/gun/energy/hk_rifle/proc/sniper_fire(atom/target, mob/living/user, params, zone_override)
	sniper_shot_armed = TRUE
	. = process_fire(target, user, TRUE, params, zone_override)
	sniper_shot_armed = FALSE
	if(.)
		COOLDOWN_START(src, sniper_cooldown, HK47_SNIPER_COOLDOWN)

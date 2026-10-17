/obj/item/projectile/beam/hk_bolt/stun
	name = "HK stun bolt"
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk47_gear.dmi'
	icon_state = "hk47_stun_bolt"
	damage = HK47_STUN_BOLT_STAMINA
	damage_type = STAMINA
	armour_penetration = 0
	hitsound = 'sound/weapons/tap.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/hk47_stun
	light_color = LIGHT_COLOR_ORANGE

#define HK47_STUN_NOTE_MEMORY (30 SECONDS)

/datum/antagonist/hk47
	/// WEAKREF(цель) -> world.time, когда HK уже отметил её обездвиженной.
	var/list/stun_noted

/// Цель свалилась от заряда HK-47: он видит, что её можно брать.
/obj/item/projectile/beam/hk_bolt/stun/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/mob/living/victim = target
	var/mob/living/shooter = firer
	if(!istype(victim) || !istype(shooter) || victim.stat == DEAD || !IS_STAMCRIT(victim))
		return
	var/datum/antagonist/hk47/hunter = shooter.mind?.has_antag_datum(/datum/antagonist/hk47)
	if(!hunter || hk47_recalls(hunter.stun_noted, victim, HK47_STUN_NOTE_MEMORY))
		return
	hunter.stun_noted = hk47_remember(hunter.stun_noted, victim, HK47_STUN_NOTE_MEMORY)
	victim.balloon_alert(shooter, "обездвижен")
	hk47_quip(shooter, "stun_down")

#undef HK47_STUN_NOTE_MEMORY

/obj/effect/temp_visual/impact_effect/hk47_stun
	icon_state = "impact_laser"
	color = "#ffd27f"
	duration = 4

/obj/item/ammo_casing/energy/hk_bolt/stun
	projectile_type = /obj/item/projectile/beam/hk_bolt/stun
	e_cost = HK_RIFLE_SHOT_COST
	select_name = "stun"
	fire_sound = 'modular_bluemoon/sound/hk_droids/hk47_stun_shot.ogg'

/obj/item/gun/energy/hk_rifle
	var/stun_unlocked = FALSE

/obj/item/gun/energy/hk_rifle/proc/unlock_stun()
	if(stun_unlocked)
		return FALSE
	stun_unlocked = TRUE
	var/obj/item/ammo_casing/energy/hk_bolt/stun/casing = new(src)
	ammo_type += casing
	ammo_type[casing] = TRUE
	return TRUE

/obj/item/gun/energy/hk_rifle/proc/stun_selected()
	return istype(ammo_type[current_firemode_index], /obj/item/ammo_casing/energy/hk_bolt/stun)

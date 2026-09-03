/**
 * TG-style melee blood effects (ported from /tg/station attack_effects).
 * Called after apply_damage from [/mob/living/carbon/attacked_by] and [/mob/living/attacked_by].
 */

/// Temporary blood spray away from the attacker (direction of the hit).
/proc/play_melee_bloodsplatter_visual(mob/living/victim, mob/living/attacker, hit_zone)
	var/turf/T = get_turf(victim)
	if(!T)
		return
	var/splatter_dir = attacker ? get_dir(attacker, victim) : victim.dir
	if(!iscarbon(victim))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, splatter_dir)
		return
	var/mob/living/carbon/C = victim
	var/obj/item/bodypart/B = C.get_bodypart(hit_zone)
	if(!B)
		B = C.bodyparts[1]
	if(B?.is_robotic_limb())
		return
	if(isalien(C))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter/xenosplatter(T, splatter_dir)
		return
	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, splatter_dir, H.dna.species.exotic_blood_color)
	else
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, splatter_dir)

/// Stain specific human attacker clothing based on damage (TG thresholds).
/proc/melee_blood_stain_attacker(mob/living/carbon/human/attacker, mob/living/victim, damage_done)
	if(!attacker || !victim)
		return
	var/obj/item/gloves = attacker.get_item_by_slot(ITEM_SLOT_GLOVES)
	if(gloves)
		gloves.add_mob_blood(victim)
	if(damage_done >= 20 || (damage_done >= 15 && prob(25)))
		var/obj/item/inner = attacker.get_item_by_slot(ITEM_SLOT_ICLOTHING)
		var/obj/item/outer = attacker.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(inner)
			inner.add_mob_blood(victim)
		if(outer)
			outer.add_mob_blood(victim)
	if(prob(33) && damage_done >= 10)
		var/obj/item/feet = attacker.get_item_by_slot(ITEM_SLOT_FEET)
		if(feet)
			feet.add_mob_blood(victim)
	if(prob(33) && damage_done >= 24)
		var/obj/item/mask = attacker.get_item_by_slot(ITEM_SLOT_MASK)
		if(mask)
			mask.add_mob_blood(victim)
	if(prob(33) && damage_done >= 30)
		var/obj/item/head_item = attacker.get_item_by_slot(ITEM_SLOT_HEAD)
		if(head_item)
			head_item.add_mob_blood(victim)

/**
 * Called when we take melee item damage — blood splatter, decals, staining.
 * Return TRUE if an effect was applied (TG compatibility).
 */
/mob/living/proc/attack_effects(damage_done, hit_zone, obj/item/attacking_item, mob/living/attacker)
	if(damage_done <= 0 || attacking_item.damtype != BRUTE)
		return FALSE
	if(!prob(min(100, 25 + damage_done * 2)))
		return FALSE
	if(!get_blood_dna_list())
		return FALSE
	attacking_item.add_mob_blood(src)
	play_melee_bloodsplatter_visual(src, attacker, hit_zone)
	var/splatter_dir = attacker ? get_dir(attacker, src) : dir
	var/splatter_strength = clamp(2 + round(damage_done / 12), 2, 7)
	spray_blood(splatter_dir, splatter_strength)
	if(!attacker || get_dist(attacker, src) > 1)
		return TRUE
	if(!ishuman(attacker))
		attacker.add_mob_blood(src)
		return TRUE
	melee_blood_stain_attacker(attacker, src, damage_done)
	return TRUE

/mob/living/carbon/attack_effects(damage_done, hit_zone, obj/item/attacking_item, mob/living/attacker)
	var/obj/item/bodypart/affecting = hit_zone ? get_bodypart(hit_zone) : null
	if(!affecting)
		affecting = bodyparts[1]
	if(affecting.is_robotic_limb())
		if(attacking_item.damtype == BRUTE && damage_done > 0)
			do_sparks(2, FALSE, get_turf(src))
			if(prob(25))
				new /obj/effect/decal/cleanable/oil(get_turf(src))
		return TRUE
	if(!affecting.is_organic_limb(FALSE))
		return FALSE
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		if((NOBLOOD in H.dna.species.species_traits) || !H.blood_volume)
			return FALSE
	return ..()

/mob/living/carbon/human/attack_effects(damage_done, hit_zone, obj/item/attacking_item, mob/living/attacker)
	. = ..()
	if(!. || !hit_zone)
		return
	if(hit_zone == BODY_ZONE_HEAD)
		var/bc = min(100, damage_done * 3)
		if(wear_mask && prob(bc))
			wear_mask.add_mob_blood(src)
			update_inv_wear_mask()
		if(wear_neck && prob(bc))
			wear_neck.add_mob_blood(src)
			update_inv_neck()
		if(head && prob(bc))
			head.add_mob_blood(src)
			update_inv_head()

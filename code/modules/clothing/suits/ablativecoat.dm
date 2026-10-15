/obj/item/clothing/head/hooded/ablative
    name = "ablative hood"
    desc = "Hood hopefully belonging to an ablative trenchcoat. Includes a visor for cool-o-vision."
    icon_state = "ablativehood"
    flags_inv = HIDEHAIR|HIDEEARS
    strip_delay = 30
    var/hit_reflect_chance = 60
    armor_type = /datum/armor/ablative

/obj/item/clothing/head/hooded/ablative/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
    if(def_zone == BODY_ZONE_HEAD)
        if(prob(hit_reflect_chance) && is_energy_reflectable_projectile(object) && (attack_type & ATTACK_TYPE_PROJECTILE))
            block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
            return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
    return ..()

/obj/item/clothing/suit/hooded/ablative
    name = "ablative trenchcoat"
    desc = "Experimental trenchcoat specially crafted to reflect and absorb laser and disabler shots. Don't expect it to do all that much against an axe or a shotgun, however."
    icon_state = "ablativecoat"
    body_parts_covered = CHEST|GROIN|LEGS|ARMS
    armor_type = /datum/armor/ablative
    hoodtype = /obj/item/clothing/head/hooded/ablative
    strip_delay = 30
    equip_delay_other = 40
    var/hit_reflect_chance = 60
    mutantrace_variation = STYLE_ALL_TAURIC

/obj/item/clothing/suit/hooded/ablative/Initialize(mapload)
    . = ..()
    allowed = GLOB.security_vest_allowed

/obj/item/clothing/suit/hooded/ablative/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
    if(def_zone in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)) //If not shot where ablative is covering you, you don't get the reflection bonus!
        if (prob(hit_reflect_chance) && is_energy_reflectable_projectile(object) && (attack_type & ATTACK_TYPE_PROJECTILE))
            block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_RETURN_TO_SENDER
            return BLOCK_SHOULD_REDIRECT | BLOCK_REDIRECTED | BLOCK_SUCCESS | BLOCK_PHYSICAL_INTERNAL
    return ..()

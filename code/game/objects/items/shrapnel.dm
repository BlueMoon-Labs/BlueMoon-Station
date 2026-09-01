/obj/item/shrapnel // frag grenades
	name = "shrapnel shard"
	embedding = list(embed_chance=70, ignore_throwspeed_threshold=TRUE, fall_chance=4, embed_chance_turf_mod=-100)
	custom_materials = list(/datum/material/iron=50)
	armour_penetration = -20
	icon = 'icons/obj/shards.dmi'
	icon_state = "large"
	w_class = WEIGHT_CLASS_TINY
	item_flags = DROPDEL
	sharpness = SHARP_EDGED

/obj/item/shrapnel/stingball // stingbang grenades
	name = "stingball"
	embedding = list(embed_chance=90, fall_chance=3, jostle_chance=7, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.7, pain_mult=5, jostle_pain_mult=6, rip_time=15, embed_chance_turf_mod=-100)
	icon_state = "tiny"
	sharpness = SHARP_NONE

/obj/item/shrapnel/bullet // bullets
	name = "bullet"
	icon = 'icons/obj/ammo.dmi'
	icon_state = "s-casing"
	item_flags = NONE

/obj/item/shrapnel/bullet/c38 // .38 round
	name = "\improper .38 bullet"

/obj/item/shrapnel/bullet/c38/dumdum // .38 DumDum round
	name = "\improper .38 DumDum bullet"
	embedding = list(embed_chance=70, fall_chance=7, jostle_chance=7, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10, embed_chance_turf_mod=-100)

/obj/item/projectile/bullet/shrapnel
	name = "flying shrapnel shard"
	damage = 14
	range = 20
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было -30 → BR1(10). Шрапнель от гранаты
	                                   // должна хоть немного пробивать лёгкую броню.
	dismemberment = 5
	ricochets_max = 2
	ricochet_chance = 70
	shrapnel_type = /obj/item/shrapnel
	ricochet_incidence_leeway = 60
	sharpness = SHARP_EDGED
	wound_bonus = 40
	hit_prone_targets = TRUE

// mega — наследует BR1 от родителя, без изменений

/obj/item/projectile/bullet/shrapnel/mega
	name = "flying shrapnel hunk"
	range = 45
	dismemberment = 15
	ricochets_max = 6
	ricochet_chance = 130
	ricochet_incidence_leeway = 0
	ricochet_decay_chance = 0.9

/obj/item/projectile/bullet/pellet/stingball
	name = "stingball pellet"
	armour_penetration = BULLET_BR0
	damage = 3
	stamina = 8
	ricochets_max = 4
	ricochet_chance = 66
	ricochet_decay_chance = 1
	ricochet_decay_damage = 0.9
	ricochet_auto_aim_angle = 10
	ricochet_auto_aim_range = 2
	ricochet_incidence_leeway = 0
	shrapnel_type = /obj/item/shrapnel/stingball

/obj/item/projectile/bullet/pellet/stingball/mega
	name = "megastingball pellet"
	ricochets_max = 6
	ricochet_chance = 110

/obj/item/projectile/bullet/pellet/stingball/breaker
	name = "breakbang pellet"
	armour_penetration = BULLET_BR0
	damage = 10
	wound_bonus = 40
	sharpness = SHARP_NONE

/obj/item/projectile/bullet/pellet/stingball/shred
	name = "shredbang pellet"
	armour_penetration = BULLET_BR0
	damage = 10
	wound_bonus = 30
	sharpness = SHARP_EDGED

// 9mm (Stechkin APS)

/obj/item/projectile/bullet/c9mm
	name = "9mm bullet"
	damage = 22
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было 10 → BR1(10), без изменений
	embedding = list(embed_chance=15, fall_chance=3, jostle_chance=4, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)

/obj/item/projectile/bullet/c9mm_ap
	name = "9mm armor-piercing bullet"
	damage = 17
	armour_penetration = BULLET_BR3   // BLUEMOON EDIT: было 10 → BR3(35). FiveseveN-style — маленький но злой, форма пули даёт отличное пробитие.
	embedding = null

/obj/item/projectile/bullet/incendiary/c9mm
	name = "9mm incendiary bullet"
	damage = 10
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было 10 → BR1(10), без изменений
	fire_stacks = 1

// 10mm (Stechkin)

/obj/item/projectile/bullet/c10mm
	name = "10mm bullet"
	damage = 30
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было 10 → BR1(10)

/obj/item/projectile/bullet/c10mm_ap
	name = "10mm armor-piercing bullet"
	damage = 27
	armour_penetration = BULLET_BR3   // BLUEMOON EDIT: было 40 → BR3(35)

/obj/item/projectile/bullet/c10mm_hp
	name = "10mm hollow-point bullet"
	damage = 50
	armour_penetration = BULLET_BR0 - 25  // -25 (HP)

/obj/item/projectile/bullet/incendiary/c10mm
	name = "10mm incendiary bullet"
	damage = 15
	armour_penetration = BULLET_BR1
	fire_stacks = 2

/obj/item/projectile/bullet/c10mm/soporific
	name = "10mm soporific bullet"
	nodamage = TRUE
	stamina = 30
	armour_penetration = BULLET_BR0   // усыпляющие не про пробитие

/obj/item/projectile/bullet/c10mm/soporific/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if((blocked != 100) && isliving(target))
		var/mob/living/L = target
		L.blur_eyes(6)
		if(L.getStaminaLoss() >= 80)
			L.Sleeping(300)


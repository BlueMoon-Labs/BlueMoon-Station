/obj/item/projectile/bullet/dnainjector
	name = "\improper DNA injector"
	icon_state = "syringeproj"
	var/obj/item/dnainjector/injector
	armour_penetration = 10
	damage = 1
	hitsound_wall = "shatter"
	var/armor_ignore = 5
	var/max_armor = 100

/obj/item/projectile/bullet/dnainjector/on_hit(atom/target, blocked = FALSE)
	if(blocked != 100 && iscarbon(target))
		var/mob/living/carbon/M = target
		var/armor = M.run_armor_check(def_zone, flag, null, null, armour_penetration, null)
		if(prob(max(armor_ignore, ((max_armor - (armor * 2))))))
			if(injector.inject(M, firer))
				QDEL_NULL(injector)
				return BULLET_ACT_HIT
		else
			target.visible_message("<span class='danger'>[src] отскочил!</span>", \
								   "<span class='userdanger'>Вы были защищены от [src]!</span>")
			blocked = 100
	return ..()

/obj/item/projectile/bullet/dnainjector/Destroy()
	QDEL_NULL(injector)
	return ..()

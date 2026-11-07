/obj/vehicle/sealed/mecha/combat/neovgre
	name = "Neovgre, the Anima Bulwark"
	desc = "Самое мощное творение Nezbere, могучая боевая машина несравненной мощи, о которой говорят, что она заканчивала войны за одну ночь. Вооружена тяжёлым лазером и генератором тесла-сфер. Требует пилота и стрелка."
	icon = 'icons/mecha/neovgre.dmi'
	icon_state = "neovgre"
	pixel_x = -16
	layer = ABOVE_MOB_LAYER
	max_integrity = 500
	deflect_chance = 40
	armor_type = /datum/armor/neovgre
	max_temperature = 60000
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	force = 50 //SMASHY SMASHY!!
	movedelay = 4
	internal_damage_threshold = 25
	internals_req_access = list()
	wreckage = /obj/structure/mecha_wreckage/durand/neovgre
	stepsound = 'sound/mecha/neostep2.ogg'
	turnsound = 'sound/mecha/powerloader_step.ogg'
	max_occupants = 2
	mecha_type = MECHA_TYPE_COMBAT | MECHA_TYPE_NEOVGRE
	var/breach_time = 100 //ten seconds till all goes to shit
	var/recharge_rate = 100

//override this proc if you need to split up mecha control between multiple people (see savannah_ivanov.dm)
/obj/vehicle/sealed/mecha/combat/neovgre/auto_assign_occupant_flags(mob/M)
	if(driver_amount() < max_drivers)
		add_control_flags(M, VEHICLE_CONTROL_DRIVE|VEHICLE_CONTROL_SETTINGS|VEHICLE_CONTROL_MELEE)
	else
		add_control_flags(M, VEHICLE_CONTROL_MELEE|VEHICLE_CONTROL_EQUIPMENT)

/obj/vehicle/sealed/mecha/combat/neovgre/mob_exit(mob/M, silent, randomstep, forced)
	if(forced)
		..()

/obj/vehicle/sealed/mecha/combat/neovgre/MouseDrop_T(mob/M, mob/user)
	if(!is_servant_of_ratvar(user))
		to_chat(user, span_neovgre("ПРОЧЬ, НЕВЕРНЫЙ!"))
		return
	else
		..()

/obj/vehicle/sealed/mecha/combat/neovgre/moved_inside(mob/living/carbon/human/H)
	var/list/Itemlist = H.get_contents()
	for(var/obj/item/clockwork/slab/W in Itemlist)
		to_chat(H, span_brass("Вы убираете [W] в [src]."))
		qdel(W)
	. = ..()

/obj/vehicle/sealed/mecha/combat/neovgre/obj_destruction()
	for(var/mob/M in src)
		to_chat(M, span_brass("Вас поглощает пламя, бушующее внутри Neovgre..."))
		M.dust()
	playsound(src, 'sound/effects/neovgre_exploding.ogg', 100, 0)
	src.visible_message(span_userdanger("Реактор в критическом состоянии! Сейчас рванёт!"))
	addtimer(CALLBACK(src,PROC_REF(go_critical)),breach_time)

/obj/vehicle/sealed/mecha/combat/neovgre/proc/go_critical()
	explosion(get_turf(loc), 6, 10, 20, 40, 60)
	if(!QDELETED(src))
		qdel(src)

/obj/vehicle/sealed/mecha/combat/neovgre/container_resist(mob/living/user)
	to_chat(user, span_brass("Neovgre требует пожизненной преданности, друг. Пути назад нет!"))
	return

/obj/vehicle/sealed/mecha/combat/neovgre/process()
	..()
	if(!obj_integrity) //Integrity is zero but we would heal out of that state if we went into this before it recognises it being zero
		return
	if(GLOB.ratvar_awakens) // At this point only timley intervention by lord singulo could hope to stop the superweapon
		cell.charge = INFINITY
		max_integrity = INFINITY
		obj_integrity = max_integrity
	else
		if(cell.charge < cell.maxcharge)
			for(var/obj/effect/clockwork/sigil/transmission/T in range(SIGIL_ACCESS_RANGE, src))
				var/delta = min(recharge_rate, cell.maxcharge - cell.charge)
				if (get_clockwork_power() >= delta)
					cell.charge += delta
					adjust_clockwork_power(-delta)
		if(obj_integrity < max_integrity && istype(loc, /turf/open/floor/clockwork))
			obj_integrity += min(max_integrity - obj_integrity, max_integrity / 100)

/obj/vehicle/sealed/mecha/combat/neovgre/Initialize(mapload)
	.=..()
	GLOB.neovgre_exists ++
	var/obj/item/mecha_parts/mecha_equipment/ME
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/anticcw_armor_booster(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	var/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy/neovgre/N = new
	N.attach(src)
	var/obj/item/mecha_parts/mecha_equipment/weapon/energy/tesla/shocking = new
	shocking.attach(src)

/obj/structure/mecha_wreckage/durand/neovgre
	name = "\improper Neovgre wreckage?"
	desc = "При ближайшем рассмотрении это выглядит как обломки Durand с примотанным картоном, разрисованным баллончиком!"

/obj/item/mecha_parts/mecha_equipment/weapon/energy/laser/heavy/neovgre
	name = "Arbiter Laser Cannon"
	desc = "Пожалуйста, прикрепите это обратно к Neovgre и перестаньте спрашивать, почему оно выглядит как обычный лазерный пулемёт Solaris выпуска Nanotrasen — Nezbere"
	equip_cooldown = 8 //Rapid fire heavy laser cannon, simple yet elegant
	energy_drain = 30
	fire_sound = 'sound/weapons/neovgre_laser.ogg'
	compatible_mecha_types = MECHA_TYPE_NEOVGRE

/obj/machinery/porta_turret/inteq

	installation = null
	always_up = 1
	use_power = NO_POWER_USE
	has_cover = 0
	scan_range = 9
	req_access = list(ACCESS_INTEQ)
	mode = TURRET_LETHAL
	stun_projectile = /obj/item/projectile/bullet
	lethal_projectile = /obj/item/projectile/bullet
	lethal_projectile_sound = 'sound/weapons/gunshot.ogg'
	stun_projectile_sound = 'sound/weapons/gunshot.ogg'
	icon_state = "syndie_off"
	base_icon_state = "syndie"
	faction = list(ROLE_INTEQ)
	desc = "A ballistic machine gun auto-turret."

/obj/machinery/porta_turret/inteq/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_SELF | EMP_PROTECT_WIRES)

/obj/machinery/porta_turret/inteq/setup()
	return

/obj/machinery/porta_turret/Inteq/assess_perp(mob/living/carbon/human/perp)
	var/obj/item/card/id/target_card = perp.get_idcard(FALSE)
	if(target_card && (ACCESS_INTEQ in target_card?.access) && istype(target_card, /obj/item/card/id/inteq))
		if(istype(target_card, /obj/item/card/id/syndicate) || istype(target_card, /obj/item/card/id/syndicate/anyone) || istype(target_card, /obj/item/card/id/syndicate/nuke_leader))
			return 10	//no Syndicate allowed!
		else
			return 0
	else
		return 10 //Syndicate turrets shoot everything not in their faction

/obj/machinery/porta_turret/inteq/energy
	icon_state = "standard_stun"
	base_icon_state = "standard"
	stun_projectile = /obj/item/projectile/energy/electrode
	stun_projectile_sound = 'sound/weapons/taser.ogg'
	nonlethal_projectile = /obj/item/projectile/beam/disabler
	nonlethal_projectile_sound = 'sound/weapons/taser2.ogg'
	lethal_projectile = /obj/item/projectile/beam/laser
	lethal_projectile_sound = 'sound/weapons/laser.ogg'
	desc = "An energy blaster auto-turret."

/obj/machinery/porta_turret/inteq/energy/heavy
	icon_state = "standard_stun"
	base_icon_state = "standard"
	stun_projectile = /obj/item/projectile/energy/electrode
	stun_projectile_sound = 'sound/weapons/taser.ogg'
	nonlethal_projectile = /obj/item/projectile/beam/disabler
	nonlethal_projectile_sound = 'sound/weapons/taser2.ogg'
	lethal_projectile = /obj/item/projectile/beam/laser/heavylaser
	lethal_projectile_sound = 'sound/weapons/lasercannonfire.ogg'
	desc = "An energy blaster auto-turret."

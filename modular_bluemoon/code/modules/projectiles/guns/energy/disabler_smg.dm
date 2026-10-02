/obj/item/gun/energy/disabler/smg
	name = "disabler smg"
	desc = "An automatic disabler variant, as opposed to the conventional model, boasts a higher ammunition capacity at the cost of slightly reduced beam effectiveness."
	icon = 'modular_bluemoon/icons/obj/guns/disabler_smg.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/disabler_smg_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/disabler_smg_righthand.dmi'
	icon_state = "disabler_smg"
	ammo_type = list(/obj/item/ammo_casing/energy/disabler/smg)
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_FULLY_AUTOMATIC)
	fire_delay = 1.5
	shaded_charge = 1

/obj/item/ammo_casing/energy/disabler/smg
	projectile_type = /obj/item/projectile/beam/disabler/weak/smg
	e_cost = 18
	fire_sound = 'modular_bluemoon/sound/weapons/taser3.ogg'

/obj/item/projectile/beam/disabler/weak/smg
	damage = 12

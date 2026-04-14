/obj/item/organ/cyberimp/arm/mantis_blade //Ported from skyrat
	name = "arm blade implant"
	desc = "An integrated blade implant designed to be installed into a persons arm. Stylish and deadly; Although, being caught with this without proper permits is sure to draw unwanted attention."
	contents = newlist(/obj/item/melee/implantarmblade)
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis_blade"

/obj/item/organ/cyberimp/arm/mantis_blade/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/mantis_blade/emag_act()//Emag function - it will give an energy-alike blade, but less deadly.
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s energy blade!</span>")
	add_item(new /obj/item/melee/implantarmblade/energy)
	return TRUE

/obj/item/melee/implantarmblade
	name = "implanted arm blade"
	desc = "A long, sharp, mantis-like blade implanted into someones arm. Cleaves through flesh like its particularly strong butter."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/implanted_blade_righthand.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/implanted_blade_lefthand.dmi'
	icon_state = "mantis_blade"
	force = 25
	armour_penetration = 20
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_POINTY
	attack_verb = list("slashed", "cut")
	item_flags = NEEDS_PERMIT //Beepers gets angry if you get caught with this.
	hitsound = 'sound/weapons/bladeslice.ogg'

/obj/item/melee/implantarmblade/energy
	name = "energy arm blade"
	desc = "A long mantis-like blade made entirely of blazing-hot energy. Stylish and EXTRA deadly!"
	icon_state = "energy_mantis_blade"
	force = 30
	armour_penetration = 10 //Energy isn't as good at going through armor as it is through flesh alone.
	hitsound = 'sound/weapons/blade1.ogg'

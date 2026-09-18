/obj/item/organ/cyberimp/arm/mantis_blade
	name = "Mantis blade implant"
	desc = "An integrated blade implant designed to be installed into a persons arm. Stylish and deadly; Although, being caught with this without proper permits is sure to draw unwanted attention."
	contents = newlist(/obj/item/melee/implantarmblade)
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "mantis"

/obj/item/organ/cyberimp/arm/mantis_blade/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/mantis_blade/sec_level
	name = "Corporate Mantis blade implant"
	icon_state = "mantis_corpo"
	contents = newlist(/obj/item/melee/implantarmblade/corpo)
	active_security_level = MANTIS_IMPLANT_SEC_LEVEL

/obj/item/organ/cyberimp/arm/mantis_blade/sec_level/l
	zone = BODY_ZONE_L_ARM

/obj/item/organ/cyberimp/arm/mantis_blade/syndie
	name = "Gorlex Mantis blade implant"
	icon_state = "mantis_syndie"
	contents = newlist(/obj/item/melee/implantarmblade/syndie)

/obj/item/organ/cyberimp/arm/mantis_blade/syndie/l
	zone = BODY_ZONE_L_ARM

/obj/item/melee/implantarmblade
	name = "Mantis blade"
	desc = "A blade designed to be hidden just beneath the skin. The brain is directly linked to this bad boy, allowing it to spring into action."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	icon_state = "mantis"
	force = 20
	armour_penetration = 20
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_POINTY
	total_mass = TOTAL_MASS_HAND_REPLACEMENT
	attack_verb = list("slashed", "cut")
	item_flags = NEEDS_PERMIT //Beepers gets angry if you get caught with this.
	hitsound = 'sound/weapons/bladeslice.ogg'
	tool_behaviour = TOOL_CROWBAR
	can_force_powered = TRUE
	usesound = 'sound/items/jaws_pry.ogg'

/obj/item/melee/implantarmblade/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/ambidextria_attack, /obj/item/melee/implantarmblade)

/obj/item/melee/implantarmblade/corpo
	name = "Corporate Mantis blade"
	icon_state = "mantis_corpo"

/obj/item/melee/implantarmblade/syndie
	name = "Gorlex mantis blade"
	icon_state = "mantis_syndie"
	force = 30
	armour_penetration = 40

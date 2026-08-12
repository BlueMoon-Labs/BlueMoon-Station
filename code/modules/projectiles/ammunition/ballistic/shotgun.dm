// Shotgun

/obj/item/ammo_casing/shotgun
	caliber = "shotgun"
	icon = 'icons/obj/ammo_reheated.dmi'
	shell_bounce_sounds = list(
		'sound/weapons/Shotguns_reheated/shared/casings/12g_fall1.ogg',
		'sound/weapons/Shotguns_reheated/shared/casings/12g_fall2.ogg',
		'sound/weapons/Shotguns_reheated/shared/casings/12g_fall3.ogg',
		'sound/weapons/Shotguns_reheated/shared/casings/12g_fall4.ogg'
	)

/obj/item/ammo_casing/shotgun/slug
	name = "shotgun slug"
	desc = "A 12 gauge lead slug."
	icon_state = "whiteshell"
	projectile_type = /obj/item/projectile/bullet/shotgun_slug
	custom_materials = list(/datum/material/iron = 4000)
	stress_added = 15
	recoil_added = 1.2

/obj/item/ammo_casing/shotgun/breacher
	name = "breacher slug"
	desc = "A 12 gauge copper slug meant for destroying every airlock on it's way."
	icon_state = "breachshell"
	caliber = "shotgun"
	projectile_type = /obj/item/projectile/bullet/breach_slug
	custom_materials = list(/datum/material/iron=4000)
	can_be_printed = FALSE
	pellets = 2
	variance = 1
	stress_added = 25
	recoil_added = 1.8

/obj/item/ammo_casing/shotgun/executioner
	name = "executioner slug"
	desc = "A 12 gauge lead slug purpose built to annihilate flesh on impact."
	icon_state = "specialshell"
	projectile_type = /obj/item/projectile/bullet/shotgun_slug/executioner
	stress_added = 28
	recoil_added = 2.0

/obj/item/ammo_casing/shotgun/pulverizer
	name = "pulverizer slug"
	desc = "A 12 gauge lead slug purpose built to annihilate bones on impact."
	icon_state = "specialshell"
	projectile_type = /obj/item/projectile/bullet/shotgun_slug/pulverizer
	stress_added = 28
	recoil_added = 2.0

/obj/item/ammo_casing/shotgun/beanbag
	name = "beanbag slug"
	desc = "A weak beanbag slug for riot control."
	icon_state = "greenshell"
	projectile_type = /obj/item/projectile/bullet/shotgun_beanbag
	custom_materials = list(/datum/material/iron=250)
	stress_added = 5
	recoil_added = 0.5

/obj/item/ammo_casing/shotgun/incendiary
	name = "incendiary slug"
	desc = "An incendiary-coated shotgun slug."
	icon_state = "orangeshell"
	projectile_type = /obj/item/projectile/bullet/incendiary/shotgun
	stress_added = 18
	recoil_added = 1.3

/obj/item/ammo_casing/shotgun/dragonsbreath
	name = "dragonsbreath shell"
	desc = "A shotgun shell which fires a spread of incendiary pellets."
	icon_state = "fireshell"
	projectile_type = /obj/item/projectile/bullet/incendiary/shotgun/dragonsbreath
	pellets = 4
	variance = 35
	stress_added = 20
	recoil_added = 1.5

/obj/item/ammo_casing/shotgun/stunslug
	name = "taser slug"
	desc = "A stunning taser slug."
	icon_state = "tazershell"
	projectile_type = /obj/item/projectile/bullet/shotgun_stunslug
	custom_materials = list(/datum/material/iron=250)
	stress_added = 12
	recoil_added = 0.9

/obj/item/ammo_casing/shotgun/meteorslug
	name = "meteorslug shell"
	desc = "A shotgun shell rigged with CMC technology, which launches a massive slug when fired."
	icon_state = "blackshell"
	projectile_type = /obj/item/projectile/bullet/shotgun_meteorslug
	stress_added = 30
	recoil_added = 2.2

/obj/item/ammo_casing/shotgun/pulseslug
	name = "pulse slug"
	desc = "A delicate device which can be loaded into a shotgun. The primer acts as a button which triggers the gain medium and fires a powerful \
	energy blast. While the heat and power drain limit it to one use, it can still allow an operator to engage targets that ballistic ammunition \
	would have difficulty with."
	icon_state = "kineticshell"
	projectile_type = /obj/item/projectile/beam/pulse/shotgun
	stress_added = 22
	recoil_added = 1.6

/obj/item/ammo_casing/shotgun/frag12
	name = "FRAG-12 slug"
	desc = "A high explosive breaching round for a 12 gauge shotgun."
	icon_state = "blueshell"
	projectile_type = /obj/item/projectile/bullet/shotgun_frag12
	stress_added = 26
	recoil_added = 1.7

/obj/item/ammo_casing/shotgun/buckshot
	name = "buckshot shell"
	desc = "A 12 gauge buckshot shell."
	icon_state = "redshell"
	projectile_type = /obj/item/projectile/bullet/pellet/shotgun_buckshot
	pellets = 6
	variance = 25
	stress_added = 16
	recoil_added = 1.1

/obj/item/ammo_casing/shotgun/rubbershot
	name = "rubber shot"
	desc = "A shotgun casing filled with densely-packed rubber balls, used to incapacitate crowds from a distance."
	icon_state = "blueshell"
	projectile_type = /obj/item/projectile/bullet/pellet/shotgun_rubbershot
	pellets = 6
	variance = 25
	custom_materials = list(/datum/material/iron=4000)
	stress_added = 6
	recoil_added = 0.5

/obj/item/ammo_casing/shotgun/improvised
	name = "improvised shell"
	desc = "An extremely weak shotgun shell with multiple small pellets made out of metal shards."
	icon_state = "dirtyshell"
	projectile_type = /obj/item/projectile/bullet/pellet/shotgun_improvised
	custom_materials = list(/datum/material/iron=250)
	pellets = 10
	variance = 25
	stress_added = 4
	recoil_added = 0.3

/obj/item/ammo_casing/shotgun/ion
	name = "ion shell"
	desc = "An advanced shotgun shell which uses a subspace ansible crystal to produce an effect similar to a standard ion rifle. \
	The unique properties of the crystal split the pulse into a spread of individually weaker bolts."
	icon_state = "ionshell"
	projectile_type = /obj/item/projectile/ion/weak
	pellets = 4
	variance = 35
	stress_added = 14
	recoil_added = 1.0

/obj/item/ammo_casing/shotgun/laserslug
	name = "scatter laser shell"
	desc = "An advanced shotgun shell that uses a micro laser to replicate the effects of a scatter laser weapon in a ballistic package."
	icon_state = "lasershell"
	projectile_type = /obj/item/projectile/beam/scatter
	pellets = 6
	variance = 35
	stress_added = 15
	recoil_added = 1.2

/obj/item/ammo_casing/shotgun/techshell
	name = "unloaded technological shell"
	desc = "A high-tech shotgun shell which can be loaded with materials to produce unique effects."
	icon_state = "purpleshell"
	projectile_type = null

/obj/item/ammo_casing/shotgun/dart
	name = "shotgun dart"
	desc = "A dart for use in shotguns. Can be injected with up to 30 units of any chemical."
	icon_state = "kineticshell"
	projectile_type = /obj/item/projectile/bullet/dart
	var/reagent_amount = 30

/obj/item/ammo_casing/shotgun/dart/Initialize(mapload)
	. = ..()
	create_reagents(reagent_amount, OPENCONTAINER)

/obj/item/ammo_casing/shotgun/dart/attackby()
	return

/obj/item/ammo_casing/shotgun/dart/noreact
	name = "cryostasis shotgun dart"
	desc = "A dart for use in shotguns. Uses technology similar to cryostasis beakers to keep internal reagents from reacting. Can be injected with up to 10 units of any chemical."
	icon_state = "kineticshell"
	reagent_amount = 10
	recoil_added = 0.3

/obj/item/ammo_casing/shotgun/dart/noreact/Initialize(mapload)
	. = ..()
	reagents.reagents_holder_flags |= NO_REACT

/obj/item/ammo_casing/shotgun/dart/bioterror
	desc = "A shotgun dart filled with an obscene amount of lethal reagents. God help whoever is shot with this."
	projectile_type = /obj/item/projectile/bullet/dart/piercing
	reagent_amount = 50
	recoil_added = 0.3

/obj/item/ammo_casing/shotgun/dart/bioterror/Initialize(mapload)
	. = ..()
	reagents.add_reagent(/datum/reagent/toxin/amanitin, 12) //for a nasty surprise after you get shot and somehow escape and don't think to quickly purge, and even shock those who are loaded up on purging agents
	reagents.add_reagent(/datum/reagent/toxin/chloralhydrate, 6)
	reagents.add_reagent(/datum/reagent/toxin/mutetoxin, 6) //;HELPIES OPS IN MAINT
	reagents.add_reagent(/datum/reagent/impedrezene, 6)
	reagents.add_reagent(/datum/reagent/toxin/acid/fluacid, 5) //this and the acid equal about 25ish burn, not counting the minute toxin damage dealt by their metabolism, this makes each dart about as lethal as a stechkin shot in upfront damage
	reagents.add_reagent(/datum/reagent/toxin/acid, 5)
	reagents.add_reagent(/datum/reagent/consumable/frostoil, 10) //tempgun slowdown goes both ways and adds to the burn

/obj/item/ammo_casing/shotgun/incapacitate
	name = "custom incapacitating shot"
	desc = "A shotgun casing filled with... something. used to incapacitate targets."
	icon_state = "specialshell"
	projectile_type = /obj/item/projectile/bullet/pellet/shotgun_incapacitate
	pellets = 12//double the pellets, but half the stun power of each, which makes this best for just dumping right in someone's face.
	variance = 25
	custom_materials = list(/datum/material/iron=4000)
	stress_added = 14
	recoil_added = 1.0

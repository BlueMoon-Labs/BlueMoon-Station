/obj/item/ammo_casing/rebar
	name = "sharpened iron rod"
	desc = "A sharpened iron rod. It's pointy!"
	caliber = "rebar"
	icon = 'modular_bluemoon/icons/obj/guns/crossbowbolts.dmi'
	icon_state = "Sharpenedironrod"
	projectile_type = /obj/item/projectile/bullet/rebar
	newtonian_force = 1.5
	heavy_metal = FALSE
	custom_materials = list(/datum/material/iron = 1000)

/obj/item/ammo_casing/rebar/update_icon_state()
	icon_state = initial(icon_state)

/obj/item/ammo_casing/rebar/syndie
	name = "jagged iron rod"
	desc = "An iron rod, with notches cut into it. You really don't want this stuck in you."
	icon_state = "Jagged iron rod"
	projectile_type = /obj/item/projectile/bullet/rebar/syndie

/obj/item/ammo_casing/rebar/zaukerite
	name = "zaukerite sliver"
	desc = "A sliver of a zaukerite crystal. Due to its irregular, jagged edges, removal of an embedded zaukerite sliver should only be done by trained surgeons."
	icon_state = "Zaukerite sliver"
	projectile_type = /obj/item/projectile/bullet/rebar/zaukerite

/obj/item/ammo_casing/rebar/hydrogen
	name = "metallic hydrogen bolt"
	desc = "An ultra-sharp rod made from pure metallic hydrogen. Armor may as well not exist."
	icon_state = "Metallic hydrogen bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/hydrogen

/obj/item/ammo_casing/rebar/healium
	name = "healium crystal bolt"
	desc = "Who needs a syringe gun, anyway?"
	icon_state = "Healium crystal bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/healium
	custom_materials = null

/obj/item/ammo_casing/rebar/n2o
	name = "N2O crystal bolt"
	desc = "A rod tipped with crystallized nitrous oxide. One good hit and they'll be seeing stars."
	icon_state = "N2O crystal bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/n2o
	custom_materials = null

/obj/item/ammo_casing/rebar/hypernoblium
	name = "hypernoblium crystal bolt"
	desc = "A rod fused with hypernoblium crystal. Injects protective gas on impact."
	icon_state = "Hypernoblium crystal bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/hypernoblium
	custom_materials = null

/obj/item/ammo_casing/rebar/nitrium
	name = "nitrium crystal bolt"
	desc = "A rod tipped with nitrium crystal. Delivers a sharp stimulant payload on hit."
	icon_state = "Nitrium crystal bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/nitrium
	custom_materials = null

/obj/item/ammo_casing/rebar/proto_nitrate
	name = "proto nitrate crystal bolt"
	desc = "A rod laced with proto nitrate crystal. Highly radioactive on impact."
	icon_state = "Proto nitrate crystal bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/proto_nitrate
	custom_materials = null

/obj/item/ammo_casing/rebar/supermatter
	name = "supermatter bolt"
	desc = "Wait, how is the bow capable of firing this without dusting?"
	icon_state = "Supermatter bolt"
	projectile_type = /obj/item/projectile/bullet/rebar/supermatter

/obj/item/ammo_casing/rebar/paperball
	name = "paper ball"
	desc = "Doink!"
	icon_state = "paperball"
	projectile_type = /obj/item/projectile/bullet/paperball
	newtonian_force = 0.5
	custom_materials = list(/datum/material/paper = 250)

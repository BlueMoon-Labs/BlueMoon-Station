/datum/supply_pack/costumes_toys/randomised/toys/New()
	var/list/extra_contains = list(
		/obj/item/toy/prize/savannahivanov
	)
	LAZYADD(contains, extra_contains)
	. = ..()

/datum/supply_pack/costumes_toys/wedding/New()
	. = ..()
	var/list/extra_contains = list(
		/obj/item/bouquet,
		/obj/item/bouquet/sunflower,
		/obj/item/bouquet/poppy
	)
	LAZYADD(contains, extra_contains)

/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_vr
	name = "Teshari cloaks"
	desc = "Три случайных плаща, скроенных под тешари: цветные с серым, белый, оранжевый или радужный."
	crate_name = "teshari cloaks crate"
	contains = list(
			/obj/item/clothing/neck/cloak/teshari/standard/white,
			/obj/item/clothing/neck/cloak/teshari/standard/white_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/red_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/orange_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/yellow_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/green_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/blue_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/purple_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/pink_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/brown_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/rainbow,
			/obj/item/clothing/neck/cloak/teshari/standard/orange
			)
	cost = 700

/datum/supply_pack/costumes_toys/randomised/tesh_cloaks_b_vr
	name = "Teshari cloaks (black)"
	desc = "Три случайных чёрных плаща под тешари с цветной отделкой - может попасться и светящийся."
	crate_name = "teshari black cloaks crate"
	contains = list(
			/obj/item/clothing/neck/cloak/teshari,
			/obj/item/clothing/neck/cloak/teshari/standard/black_red,
			/obj/item/clothing/neck/cloak/teshari/standard/black_orange,
			/obj/item/clothing/neck/cloak/teshari/standard/black_yellow,
			/obj/item/clothing/neck/cloak/teshari/standard/black_green,
			/obj/item/clothing/neck/cloak/teshari/standard/black_blue,
			/obj/item/clothing/neck/cloak/teshari/standard/black_purple,
			/obj/item/clothing/neck/cloak/teshari/standard/black_pink,
			/obj/item/clothing/neck/cloak/teshari/standard/black_brown,
			/obj/item/clothing/neck/cloak/teshari/standard/black_grey,
			/obj/item/clothing/neck/cloak/teshari/standard/black_white,
			/obj/item/clothing/neck/cloak/teshari/standard/black_glow,
			/obj/item/clothing/neck/cloak/teshari/standard/dark_retrowave
			)
	cost = 700

/datum/supply_pack/costumes_toys/randomised/tesh_beltcloaks_vr
	name = "Teshari cloaks (belted)"
	desc = "Три случайных плаща с поясом под тешари: цветные с серым, оранжевый или радужный."
	crate_name = "teshari belted cloaks crate"
	contains = list(
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/orange_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/rainbow,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/lightgrey_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/white_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/red_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/orange,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/yellow_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/green_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/blue_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/purple_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/pink_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/brown_grey
			)
	cost = 700

/datum/supply_pack/costumes_toys/randomised/tesh_beltcloaks_b_vr
	name = "Teshari cloaks (belted, black)"
	desc = "Три случайных чёрных плаща с поясом под тешари, с цветной отделкой."
	crate_name = "teshari black belted cloaks crate"
	contains = list(
			/obj/item/clothing/suit/hooded/teshari/beltcloak,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_orange,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_grey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_midgrey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_lightgrey,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_white,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_red,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_yellow,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_green,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_blue,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_purple,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_pink,
			/obj/item/clothing/suit/hooded/teshari/beltcloak/standard/black_brown
			)
	cost = 700

/datum/supply_pack/costumes_toys/randomised/tesh_hoodcloaks_vr
	name = "Teshari cloaks (hooded)"
	desc = "Три случайных плаща с капюшоном под тешари: цветные с серым или оранжевый."
	crate_name = "teshari hooded cloaks crate"
	contains = list(
			/obj/item/clothing/suit/hooded/teshari/standard/orange_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/lightgrey_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/white_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/red_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/orange,
			/obj/item/clothing/suit/hooded/teshari/standard/yellow_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/green_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/blue_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/purple_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/pink_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/brown_grey
			)
	cost = 700

/datum/supply_pack/costumes_toys/randomised/tesh_hoodcloaks_b_vr
	name = "Teshari cloaks (hooded, black)"
	desc = "Три случайных чёрных плаща с капюшоном под тешари, с цветной отделкой."
	crate_name = "teshari black hooded cloaks crate"
	contains = list(
			/obj/item/clothing/suit/hooded/teshari,
			/obj/item/clothing/suit/hooded/teshari/standard/black_orange,
			/obj/item/clothing/suit/hooded/teshari/standard/black_grey,
			/obj/item/clothing/suit/hooded/teshari/standard/black_midgrey,
			/obj/item/clothing/suit/hooded/teshari/standard/black_lightgrey,
			/obj/item/clothing/suit/hooded/teshari/standard/black_white,
			/obj/item/clothing/suit/hooded/teshari/standard/black_red,
			/obj/item/clothing/suit/hooded/teshari/standard/black,
			/obj/item/clothing/suit/hooded/teshari/standard/black_yellow,
			/obj/item/clothing/suit/hooded/teshari/standard/black_green,
			/obj/item/clothing/suit/hooded/teshari/standard/black_blue,
			/obj/item/clothing/suit/hooded/teshari/standard/black_purple,
			/obj/item/clothing/suit/hooded/teshari/standard/black_pink,
			/obj/item/clothing/suit/hooded/teshari/standard/black_brown
			)
	cost = 700

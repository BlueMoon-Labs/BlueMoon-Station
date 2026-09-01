/obj/item/reagent_containers/glass/beaker/ultimate
	name = "ultimate beaker"
	desc = "Ультиматичная мензурка, созданная экстраполяцией блюспейс-технологии \
		через тёмную материю. Может держать до \
		900 u! Также способна держать вещества экстремальных значений pH, \
		\nМечта любого химика."
	icon = 'modular_sand/icons/obj/chemical.dmi'
	icon_state = "beakerultimate"
	custom_materials = list(/datum/material/glass = 5000, /datum/material/plasma = 3000, /datum/material/diamond = 1000, /datum/material/bluespace = 1000)
	volume = 900
	possible_transfer_amounts = list(5,10,15,20,25,30,50,100,300,450,600,900)
	container_flags = APTFT_ALTCLICK|APTFT_VERB
	container_HP = 10

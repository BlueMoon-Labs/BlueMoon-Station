// Hyper stuff

/datum/gear/backpack/condom
	name = "Condom"
	path = /obj/item/genital_equipment/condom

/datum/gear/backpack/condom_box
	name = "Box of Condoms"
	description = "Большая коллекция презервативов — для самых безопасных шлюх!"
	path = /obj/item/storage/box/bulk_condoms

/datum/gear/backpack/sounding
	name = "Уретральный стержень"
	path = /obj/item/genital_equipment/sounding

/datum/gear/backpack/urethral_plug
	name = "Уретральная пробка"
	path = /obj/item/genital_equipment/urethral_plug

//Lipstick
/datum/gear/backpack/lipstick
	name = "Lipstick"
	description = "Помада неизвестной марки."
	path = /obj/item/lipstick/loadout
	loadout_initial_colors = list("#FF0000")

/datum/gear/backpack/lipstick/crocin
	name = "Crocin Lipstick"
	path = /obj/item/lipstick/crocin

/datum/gear/backpack/lipstick/honk
	name = "Honk Lipstick"
	path = /obj/item/lipstick/honk
	restricted_roles = list("Clown")

/datum/gear/backpack/lipstick/mime
	name = "Mime Lipstick"
	path = /obj/item/lipstick/mime
	restricted_roles = list("Mime")

/datum/gear/donator/backpack/lipstick/dragqueen
	name = "Drag Queen Lipstick"
	path = /obj/item/lipstick/dragqueen

//Nail polish
/datum/gear/backpack/nailpolish_red
	name = "Red Nail Polish"
	path = /obj/item/nailpolish/red

/datum/gear/backpack/nailpolish_blue
	name = "Blue Nail Polish"
	path = /obj/item/nailpolish/blue

/datum/gear/backpack/nailpolish_aqua
	name = "Cyan Nail Polish"
	path = /obj/item/nailpolish/aqua

/datum/gear/backpack/nailpolish_black
	name = "Black Nail Polish"
	path = /obj/item/nailpolish/black

/datum/gear/backpack/nailpolish_white
	name = "White Nail Polish"
	path = /obj/item/nailpolish/white

/datum/gear/backpack/nailpolish_navy
	name = "Navy Nail Polish"
	path = /obj/item/nailpolish/navy

/datum/gear/backpack/nailpolish_yellow
	name = "Yellow Nail Polish"
	path = /obj/item/nailpolish/yellow

/datum/gear/backpack/nailpolish_purple
	name = "Purple Nail Polish"
	path = /obj/item/nailpolish/purple

/datum/gear/backpack/secbadge
	name = "Security Badge"
	description = "Значок, показывающий, что владелец — сотрудник безопасности."
	path = /obj/item/clothing/accessory/badge
	restricted_roles = list("Security Officer", "Warden", "Detective", "Head of Security")

/datum/gear/backpack/holobadge
	name = "Security Holo Badge"
	description = "Более футуристичный значок на твёрдом свете."
	path = /obj/item/clothing/accessory/badge/holo
	restricted_roles = list("Security Officer", "Warden", "Detective", "Head of Security")

/datum/gear/backpack/towel
	name = "Towel"
	description = "Мягкое хлопковое полотенце."
	path = /obj/item/reagent_containers/rag/towel
	cost = 2

/datum/gear/backpack/towel_red
	name = "Red Towel"
	description = "Истинное оружие массового поражения."
	path = /obj/item/reagent_containers/rag/towel/syndicate
	cost = 4

/datum/gear/backpack/hugbox
	name = "Box of Hugs"
	description = "Особая коробка для чувствительных людей."
	path = /obj/item/storage/box/hug

/datum/gear/backpack/shockcollar
	name = "Shock Collar Kit"
	description = "Silver Love Co. не несёт ответственности за ошейники, застрявшие на владельце."
	path = /obj/item/storage/box/shockcollar
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 3

/datum/gear/backpack/standard_chastity_box
	name = "Chastity Box"
	description = "Содержит ключ и клетку для пениса."
	path = /obj/item/storage/box/chastity_cage

/datum/gear/backpack/metal_chastity_box
	name = "Metal Chastity Box"
	description = "Содержит ключ и клетку для пениса."
	path = /obj/item/storage/box/chastity_cage/metal

/datum/gear/backpack/belt_chastity_box
	name = "Chastity Belt Box"
	description = "Содержит ключ и клетку для пениса."
	path = /obj/item/storage/box/chastity_cage/belt

/datum/gear/backpack/estim_chastity_box
	name = "E-Stim Chastity Box"
	description = "Содержит ключ и клетку для пениса."
	path = /obj/item/storage/box/chastity_cage/estim

/datum/gear/backpack/chastity_hypno/magazine
	name = "Hypnotic Chastity Magazine"
	description = "Захватывающий журнал, полный завораживающих узоров и статей об искусстве гипнотического целомудрия..."
	path = /obj/item/chastity_hypno/magazine

/datum/gear/backpack/chastity_hypno/watch
	name = "Hypnotic Chastity Watch"
	path = /obj/item/chastity_hypno/watch

//MODIFIED COSTS - MODULAR SPLURT
/datum/gear/backpack/tennis/tri
description = "Полихромный теннисный мяч. На полуоторванной бирке написано: «ВНИМАНИ-», ну, конечно, это ничего не значит. Верно?"
	cost = 1

/datum/gear/backpack/tennis/tri/squeak
description = "Трёхцветный полихромный теннисный мяч. Утроенная неожиданность!"
	cost = 1

/datum/gear/backpack/bone/squeak
description = "Полихромная кость для жевания. Ничто не сравнится с хорошей костью, которую можно пожевать."
	cost = 1

/datum/gear/backpack/toykatana
	cost = 1

/datum/gear/backpack/modular_tablet
	cost = 3

/datum/gear/backpack/modular_laptop
	cost = 3

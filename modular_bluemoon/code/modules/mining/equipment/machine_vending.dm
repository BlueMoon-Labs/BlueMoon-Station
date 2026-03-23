/obj/machinery/mineral/equipment_vendor/Initialize(mapload)
	. = ..()
	prize_list += list(//General suggestion to anybody that will use this: keep the lines somewhat same with tabs, not spaces. THANK YOU.
			new /datum/data/mining_equipment("Pill Shelter",						/obj/item/survivalcapsule/luxury/pill,			400, 	"Capsules"), //The smallest of them all! Same as usual capsule to prevent abusing them
			new /datum/data/mining_equipment("Arena Shelter",						/obj/item/survivalcapsule/luxury/arena,			10000,	"Capsules"), //What do you expect in the first place?
			new /datum/data/mining_equipment("Supreme Shelter",						/obj/item/survivalcapsule/luxury/greatest,		100000,	"Capsules"), //https://youtu.be/97lKspTB3u0?si=bsdh-3VRzvV7wkIG | Yes it will cost a lot, but look at the design!(it sucks lmao)
			new /datum/data/mining_equipment("Nanotrasen MRE Ration Kit Menu 1",	/obj/item/storage/box/mre/menu1,				999,	"Recreational"), //On other forks miners at least can buy themselves some food, at affordable price.
			new /datum/data/mining_equipment("Nanotrasen MRE Ration Kit Menu 2",	/obj/item/storage/box/mre/menu2,				999,	"Recreational"),
			new /datum/data/mining_equipment("Nanotrasen MRE Ration Kit Menu 3",	/obj/item/storage/box/mre/menu3,				999,	"Recreational"),
			new /datum/data/mining_equipment("Nanotrasen MRE Ration Kit Menu 4",	/obj/item/storage/box/mre/menu4,				999,	"Recreational"),
			new /datum/data/mining_equipment("Sonic Jackhammer",					/obj/item/pickaxe/drill/jackhammer,				4000,	"Mining Tools"),
			new /datum/data/mining_equipment("KinkMate Refill Stock",				/obj/item/vending_refill/kink,					1200,	"Recreational"), //Kinkmate restock for ghostroles/lone miners. Circuit can be found in circuit printer.
			new /datum/data/mining_equipment("5000 Point Transfer Card",			/obj/item/card/mining_point_card/fivethousand,	5000),
			)
	build_inventory() // Фикс нужен для корректного отображения иконок

/obj/item/card/mining_point_card/fivethousand
	points = 5000

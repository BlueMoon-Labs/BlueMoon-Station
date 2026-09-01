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
			new /datum/data/mining_equipment("1 Metadollar",				/obj/item/stack/metadollar,						50000,	"Miscellanous"),
			)
	build_inventory() // Фикс нужен для корректного отображения иконок

/obj/machinery/mineral/equipment_vendor/RefreshParts()
	. = ..()
	for(var/datum/data/mining_equipment/prize in prize_list)
		if(ispath(prize.equipment_path, /obj/item/stack/metadollar))
			prize.cost = prize.base_cost

/obj/machinery/mineral/equipment_vendor/ui_act(action, params)
	if(action == "purchase")
		var/datum/data/mining_equipment/prize = locate(params["ref"]) in prize_list
		if(prize && ispath(prize.equipment_path, /obj/item/stack/metadollar))
			if(!bm_mining_vendor_can_buy_metadollar(usr))
				flick(icon_deny, src)
				return TRUE
	return ..()

/proc/bm_mining_vendor_can_buy_metadollar(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Нужна гуманоидная форма."))
		return FALSE
	var/mob/living/carbon/human/H = user
	if(!H.mind?.assigned_role)
		to_chat(H, span_warning("Нужна зарегистрированная профессия."))
		return FALSE
	var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
	if(!istype(J, /datum/job/mining))
		to_chat(H, span_warning("Этот товар заказать могут только сотрудники смены с профессией шахтёра."))
		return FALSE
	return TRUE

/obj/item/card/mining_point_card/fivethousand
	points = 5000

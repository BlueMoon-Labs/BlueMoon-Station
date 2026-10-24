//наборы оружия
/obj/item/storage/secure/briefcase/vanguard/lasgun
	name = "\improper Energy gun kit"
	desc = "Кейс для хранения энергопистолета Авангарда. Да будет лазер-шоу!"

/obj/item/storage/secure/briefcase/vanguard/lasgun/PopulateContents()
	new /obj/item/gun/ballistic/automatic/laser/vanguard(src)
	new /obj/item/ammo_box/magazine/recharge/vanguard(src)
	new /obj/item/ammo_box/magazine/recharge/vanguard(src)
	new /obj/item/ammo_box/magazine/recharge/vanguard(src)

/obj/item/storage/secure/briefcase/vanguard/p320
	name = "\improper P320 gun kit"
	desc = "Кейс для хранения табельного пистолета Авангарда P320. Подходите по одному!"

/obj/item/storage/secure/briefcase/vanguard/p320/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/sigsauer(src)
	new /obj/item/ammo_box/magazine/sig(src)
	new /obj/item/ammo_box/magazine/sig(src)
	new /obj/item/ammo_box/magazine/sig(src)
	new /obj/item/gun/ballistic/automatic/pistol/sigsauer(src)
	new /obj/item/ammo_box/magazine/sig(src)
	new /obj/item/ammo_box/magazine/sig(src)
	new /obj/item/ammo_box/magazine/sig(src)

//наборы экипировки классов
/obj/item/storage/box/demolition
	name = "Breaching & Reinforcment"
	desc = "Всё что нужно, чтобы куда-нибудь вломиться!"
	icon_state = "satchel_demolition"
	item_state = "satchel"

/obj/item/storage/box/demolition/PopulateContents()
	new /obj/item/grenade/exploration(src)
	new /obj/item/grenade/exploration(src)
	new /obj/item/grenade/exploration(src)
	new /obj/item/grenade/exploration(src)
	new /obj/item/grenade/exploration(src)
	new /obj/item/exploration_detonator(src)
	new /obj/item/paper/thermite_istruction(src)

/obj/item/paper/thermite_istruction
	name = "Как оказатся в любом месте за 30 секунд!"
	default_raw_text = "<b>*Свяжите заряд с детонатором. Установите заряд на стену. Отойдите на безопасную дистанцию. Подорвите заряд. НЕ РАБОТАЕТ НА ТЕРИТОРИИ СТАНЦИИ*</b>"

/obj/item/storage/firstaid/vanguard
	name = "Frontier surgion kit"
	desc = "Господи, дай мне спасти еще одного."
	icon_state = "frontier"
	item_state = "frontier"

/obj/item/storage/firstaid/vanguard/PopulateContents()
	new /obj/item/reagent_containers/glass/bottle/morphine(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)
	new /obj/item/bonesetter(src)
	new /obj/item/stack/medical/bone_gel(src)
	new /obj/item/reagent_containers/hypospray/medipen/blood_loss(src)
	new /obj/item/reagent_containers/hypospray/medipen/blood_loss(src)

//пояса с эквипом
/obj/item/storage/belt/military/assault/demolition/PopulateContents()
	new /obj/item/wrench/caravan(src)
	new /obj/item/screwdriver/caravan(src)
	new /obj/item/wirecutters/caravan(src)
	new /obj/item/crowbar/red/caravan(src)
	new /obj/item/weldingtool/hugetank(src)
	new /obj/item/multitool(src)

/obj/item/storage/firstaid/frontier
	name = "Field surgery suply"
	desc = "Для тех, кто в нужде."
	icon_state = "medkit_surgery"
	item_state = "medkit-surgical"

/obj/item/storage/firstaid/frontier/PopulateContents()
	new /obj/item/scalpel/upgraded_t2(src)
	new /obj/item/circular_saw/upgraded_t2(src)
	new /obj/item/retractor/upgraded_t2(src)
	new /obj/item/hemostat/upgraded_t2(src)
	new /obj/item/cautery/upgraded_t2(src)
	new /obj/item/surgical_drapes(src)

/obj/item/storage/bag/marksman
	name = "marksman's knife pouch"
	desc = "Кармашек для метательных ножей, позволяет удобно доставать их для быстрой шинковки."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "ammopouch"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/marksman/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = INFINITY
	STR.max_items = 5
	STR.display_numerical_stacking = TRUE
	STR.can_hold = typecacheof(list(/obj/item/kitchen/knife/combat))

/obj/item/storage/bag/marksman/PopulateContents() //can kill most basic enemies with 5 knives, though marksmen shouldn't be soloing enemies anyways
	new /obj/item/kitchen/knife/combat/marksman(src)
	new /obj/item/kitchen/knife/combat/marksman(src)
	new /obj/item/kitchen/knife/combat/marksman(src)
	new /obj/item/kitchen/knife/combat/marksman(src)
	new /obj/item/kitchen/knife/combat/marksman(src)

/obj/item/storage/bag/medpen
	name = "Medipen pouch"
	desc = "Паритетно к патронному варианту - этот может держать всевозможные автоинъекторы."
	icon = 'icons/obj/storage.dmi'
	icon_state = "firstaid_pouch"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/medpen/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = INFINITY
	STR.max_items = 12
	STR.display_numerical_stacking = TRUE
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/hypospray/medipen))

/obj/item/storage/bag/medpen/combatant
	name = "Stay alive pouch"
	desc = "Мешочек для хранения всевозможных автоинъекторов, для решения самых нерешаемых ситуаций."
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/medpen/combatant/PopulateContents()
	new /obj/item/reagent_containers/hypospray/medipen/survival(src)
	new /obj/item/reagent_containers/hypospray/medipen/salacid(src)
	new /obj/item/reagent_containers/hypospray/medipen/salacid(src)
	new /obj/item/reagent_containers/hypospray/medipen/oxandrolone(src)
	new /obj/item/reagent_containers/hypospray/medipen/oxandrolone(src)
	new /obj/item/reagent_containers/hypospray/medipen/blood_loss(src)

/obj/item/storage/firstaid/tactical/vanguard //бомжатская версия для авангардцев
	name = "Budget tactical first-aid kit"
	icon_state = "medkit_tactical_lite"

/obj/item/storage/firstaid/tactical/vanguard/PopulateContents()
	if(empty)
		return
	new /obj/item/healthanalyzer/advanced(src)
	new /obj/item/bonesetter(src)
	new /obj/item/stack/medical/suture/medicated(src)
	new /obj/item/clothing/glasses/hud/health/sunglasses/aviators(src)
	new /obj/item/stack/medical/mesh/advanced(src)
	new /obj/item/stack/medical/gauze/adv(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)


/obj/item/storage/bag/marksman/empty

/obj/item/storage/bag/marksman/empty/PopulateContents()
	return

/obj/item/storage/bag/medpen/combatant/empty

/obj/item/storage/bag/medpen/combatant/empty/PopulateContents()
	return

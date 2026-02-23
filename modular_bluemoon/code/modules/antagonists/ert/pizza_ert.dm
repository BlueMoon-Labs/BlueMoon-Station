/datum/ert/pizza
	roles = list(/datum/antagonist/ert/pizza_ert)
	leader_role = /datum/antagonist/ert/pizza_ert/leader
	rename_team = "Pizza Team Squad"
	code = "Green"
	mission = "Обслуживайте станцию с улыбкой, не забывайте получать чаевые!!"
	polldesc = "a Little Group of Trained Pizza Delivery Employees"

/datum/antagonist/ert/pizza_ert
	name = "Pizza Delivery Employee"
	outfit = /datum/outfit/ert/pizza_ert
	role = "Доставщик"
	greentext_reward = 15

/datum/antagonist/ert/pizza_ert/leader
	name = "Dogginos Regional Manager"
	outfit = /datum/outfit/ert/pizza_ert/leader
	leader = TRUE
	role = "Менеджер"
	greentext_reward = 20

/obj/item/card/id/ert/pizza_ert

/obj/item/card/id/ert/pizza_ert/Initialize(mapload)
	. = ..()

	access = list(ACCESS_CENT_GENERAL, ACCESS_CENT_LIVING, ACCESS_MAINT_TUNNELS, ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_MINERAL_STOREROOM)

/obj/item/card/id/ert/pizza_ert

/obj/item/card/id/ert/pizza_ert/leader/Initialize(mapload)
	. = ..()

	access = list(ACCESS_CENT_GENERAL, ACCESS_CENT_LIVING, ACCESS_HEADS, ACCESS_MAINT_TUNNELS, ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_MINERAL_STOREROOM)

/obj/item/clothing/suit/toggle/jacket/hoodie
	name = "Red Hoodie"
	icon_state = "red_hoodie"

/obj/item/clothing/suit/toggle/jacket/hoodie/pizza
	name = "Dogginos Hoodie"
	desc = "A hoodie often worn by the delivery boys of this intergalactically known brand of pizza."

/obj/item/clothing/under/pizza
	name = "Dogginos Employee Uniform"
	desc = "The standard issue for the famous dog-founded pizza brand, Dogginos."
	icon_state = "dominos"

/obj/item/clothing/head/pizza
	name = "Dogginos Manager Hat"
	desc = "Looks like something a Sol general would wear."
	icon_state = "dominosleader"

/datum/outfit/ert/pizza_ert //da pizza for you and me
	name = "Pizza Delivery Boy"
	id = /obj/item/card/id/ert/pizza_ert
	suit = /obj/item/clothing/suit/det_suit/forensicsred/long
	glasses = /obj/item/clothing/glasses/regular/modern
	head = /obj/item/clothing/head/soft/red
	mask = /obj/item/clothing/mask/fakemoustache/italian
	uniform = /obj/item/clothing/under/pizza
	ears = /obj/item/radio/headset/headset_cent/alt
	back = /obj/item/storage/backpack
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/kitchen/knife,\
		/obj/item/storage/box/ingredients/italian,\
		/obj/item/pizzabox/margherita = 2,
		/obj/item/pizzabox/mushroom = 2,
		/obj/item/pizzabox/meat = 2,
		/obj/item/pizzabox/pineapple = 2,
		)

	implants = list(/obj/item/implant/mindshield, /obj/item/implant/deathrattle/centcom)

/datum/outfit/ert/pizza_ert/leader //da pizza for you and me
	name = "Pizza Delivery Manager"
	id = /obj/item/card/id/ert/pizza_ert/leader
	suit = /obj/item/clothing/suit/det_suit/forensicsred/long
	uniform = /obj/item/clothing/under/pizza
	mask = /obj/item/clothing/mask/fakemoustache/italian
	head = /obj/item/clothing/head/pizza
	ears = /obj/item/radio/headset/headset_cent/alt
	back = /obj/item/storage/backpack
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/kitchen/knife,\
		/obj/item/storage/box/ingredients/italian,\
		/obj/item/pizzabox/margherita = 2,
		/obj/item/pizzabox/mushroom = 2,
		/obj/item/pizzabox/meat = 2,
		/obj/item/pizzabox/pineapple = 2,
		)

	implants = list(/obj/item/implant/mindshield, /obj/item/implant/deathrattle/centcom)

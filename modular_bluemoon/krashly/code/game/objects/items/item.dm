/obj/item/hand_mirror
	name = "hand mirror"
	desc = "Красивое зеркальце. Самое то чтобы поправить свою прическу после какого бы то ни было инцедента."
	icon = 'modular_bluemoon/krashly/icons/obj/hand_mirror.dmi'
	icon_state = "mirror"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/hand_mirror/attack_self(mob/user) // Функция зеркала
	if(ishuman(user))
		var/mob/living/carbon/human/H = user

		if(H.gender != FEMALE)
			var/new_style = input(user, "Select a facial hair style", "Grooming")  as null|anything in GLOB.facial_hair_styles_list
			if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
				return
			if(new_style)
				H.facial_hair_style = new_style
		else
			H.facial_hair_style = "Shaved"

		var/new_style = input(user, "Select a hair style", "Grooming")  as null|anything in GLOB.hair_styles_list
		if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
			return
		if(new_style)
			H.hair_style = new_style

		H.update_mutant_bodyparts()
		H.update_hair()

/obj/item/icona_madonna
	name = "Madonna icon"
	desc = "Икона великой Мадонны."
	icon =  'modular_bluemoon/krashly/icons/obj/structures.dmi'
	icon_state = "madonna"

/obj/item/sign/flag
	var/can_lock_coffin = FALSE

// Прок для закрытия гробов флагами. У нас в DMI еще куча гробов с флагами, кто захочет, поменяйте им стейты в DMI или сделайте отдельную переменную для этого
/obj/item/sign/flag/proc/lock_coffin(obj/structure/closet/crate/coffin/grob)
	if(grob?.type != /obj/structure/closet/crate/coffin || !can_lock_coffin || !ispath(sign_path))
		return
	var/icon_state_name = sign_path:icon_state
	if(!icon_state_name)
		return
	grob.icon = icon
	grob.icon_state = "grob_"+icon_state_name
	grob.locked = TRUE
	qdel(src)

	return TRUE

/obj/structure/sign/flag/skull
	name = "flag of PMC Skull"
	desc = "Черный флаг с Черепом по центру. Флаг пахнет кровью."
	icon = 'modular_bluemoon/krashly/icons/obj/skull_flag.dmi'
	icon_state = "full"
	item_flag = /obj/item/sign/flag/skull

/obj/item/sign/flag/skull
	name = "folded flag of the PMC Skull"
	desc = "Сложенный флаг ЧВК 'Череп'."
	icon = 'modular_bluemoon/krashly/icons/obj/skull_flag.dmi'
	icon_state = "mini"
	can_lock_coffin = TRUE
	sign_path = /obj/structure/sign/flag/skull

/datum/gear/donator/bm/skull_flag
	name = "PMC Skull flag"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/sign/flag/skull
	ckeywhitelist = list("krashly", "stgs", "hazzi", "dolbajob", "vulpshiro", "sodastrike", "lonofera", "mihana964", "hellsinggc")
	subcategory = LOADOUT_SUBCATEGORIES_DON01

//InteQ

/obj/structure/sign/flag/fake_inteq
	name = "Flag of PMC InteQ"
	desc = "Коричнево-Оранжевый флаг с щитом по центру. Флаг пахнет кровью."
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_flag.dmi'
	icon_state = "full"
	item_flag = /obj/item/sign/flag/fake_inteq

/obj/item/sign/flag/fake_inteq
	name = "Folded Flag of the PMC InteQ"
	desc = "Сложенный флаг ЧВК 'InteQ'."
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_flag.dmi'
	icon_state = "mini"
	can_lock_coffin = TRUE
	sign_path = /obj/structure/sign/flag/fake_inteq

/obj/structure/sign/flag/inteq
	name = "flag of PMC InteQ"
	desc = "Коричнево-Оранжевый флаг с щитом по центру. Флаг пахнет кровью."
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_flag.dmi'
	icon_state = "full"
	item_flag = /obj/item/sign/flag/inteq
	var/datum/proximity_monitor/advanced/demoraliser/demotivator

/obj/structure/sign/flag/inteq/Initialize(mapload)
	demotivator = new(src, 7, TRUE)
	START_PROCESSING(SSobj,src)
	return ..()

/obj/structure/sign/flag/inteq/process()
	if(world.time < demotivator.next_scare)
		return
	var/scared_someone = FALSE
	for(var/mob/living/viewer in view(5, src))
		demotivator.pugach(viewer)
		scared_someone = TRUE
	if(scared_someone)
		demotivator.next_scare = world.time + 120


/obj/structure/sign/flag/inteq/Destroy()
	QDEL_NULL(demotivator)
	return ..()

/obj/item/sign/flag/inteq
	name = "folded flag of the PMC InteQ"
	desc = "Сложенный флаг ЧВК 'InteQ'."
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_flag.dmi'
	icon_state = "mini"
	can_lock_coffin = TRUE
	sign_path = /obj/structure/sign/flag/inteq

/obj/item/sign/flag/inteq/afterattack(atom/target, mob/user, proximity)
	if(!iswallturf(target) || !proximity)
		return ..()
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/placer = user
	if(!IS_INTEQ(placer) && !placer.mind?.antag_datums)
		to_chat(placer, span_warning("Вы разворачиваете флаг, и тут замечаете, что это пропаганда InteQ! Ну его, от греха подальше!"))
		placer.drop_all_held_items()
		return
	. = ..()

/obj/item/storage/box/inteq_box/posters
	name = "InteQ Posters Box"
	desc = "Каробочка. Крутая."

/obj/item/storage/box/inteq_box/posters/PopulateContents()
	new	/obj/item/poster/random_inteq(src)
	new	/obj/item/poster/random_inteq(src)
	new	/obj/item/poster/random_inteq(src)
	new	/obj/item/poster/random_inteq(src)
	new	/obj/item/poster/random_inteq(src)
	new	/obj/item/poster/random_inteq(src)
	new	/obj/item/poster/random_inteq(src)

/obj/item/storage/box/inteq_box
	name = "brown box"
	desc = "В неё определенно нет ничего опасного."
	icon = 'modular_bluemoon/krashly/icons/obj/box.dmi'
	icon_state = "inteqbox"

/obj/item/storage/box/inteq_box/inteq_clothes
	name = "clothes kit"

/obj/item/storage/box/inteq_box/inteq_clothes/PopulateContents()
	new /obj/item/clothing/under/inteq(src)
	new /obj/item/clothing/suit/armor/inteq(src)
	new /obj/item/clothing/gloves/combat(src)
	new /obj/item/clothing/shoes/combat(src)
	new /obj/item/storage/belt/military/inteq(src)
	new /obj/item/clothing/glasses/hud/security/sunglasses/inteq(src)
	new /obj/item/clothing/head/helmet/swat/inteq(src)
	new /obj/item/clothing/mask/gas/inteq(src)
	new /obj/item/storage/backpack/security/inteq(src)

/obj/item/soap/inteq
	desc = "Жёлтое мыло с крайне мощными химическими агентами, которые отмывают кровь быстрее."
	icon_state = "soapinteq"
	cleanspeed = 10
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_soap.dmi'
	lefthand_file = 'modular_bluemoon/krashly/icons/mob/inhands/obj/lefthand.dmi'
	righthand_file = 'modular_bluemoon/krashly/icons/mob/inhands/obj/righthand.dmi'

/obj/item/reagent_containers/food/snacks/intecookies
	name = "InteCookies"
	desc = "Песочное печенье, каждое из которых в форме маленьких щитов."
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_snacks.dmi'
	icon_state = "inteqcookies"
	trash = /obj/item/trash/intecookies
	bitesize = 3
	list_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/cooking_oil = 2, /datum/reagent/consumable/sodiumchloride = 3)
	filling_color = "#cfa156"
	tastes = list("shortbread cookies" = 1)
	foodtype = JUNKFOOD | FRIED
	dunkable = TRUE

/obj/item/trash/intecookies
	name = "intecookies bag"
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_snacks.dmi'
	icon_state = "inteqcookies_trash"
	grind_results = list(/datum/reagent/aluminium = 1)

/obj/item/storage/fancy/cigarettes/cigpack_inteq
	name = "cigarette packet"
	desc = "Пачка сигарет от известной ЧВК."
	icon = 'modular_bluemoon/krashly/icons/obj/inteq_cigarettes.dmi'
	icon_state = "inteq"
	spawn_type = /obj/item/clothing/mask/cigarette/inteq

/obj/item/clothing/mask/cigarette/inteq
	desc = "Сигарета от известной ЧВК."
	list_reagents = list(/datum/reagent/drug/nicotine = 15, /datum/reagent/medicine/omnizine = 15)

/obj/item/toy/mecha/hermes
	name = "toy Hermes"
	icon = 'modular_bluemoon/krashly/icons/obj/toys.dmi'
	icon_state = "toy_hermes"
	max_combat_health = 6 //300 integrity

/obj/item/toy/mecha/ares
	name = "toy Ares"
	icon = 'modular_bluemoon/krashly/icons/obj/toys.dmi'
	icon_state = "toy_ares"
	max_combat_health = 7 //350 integrity

/// Лодаут
/datum/gear/accessory/hand_mirror
	name = "A hand mirror"
	path = /obj/item/hand_mirror
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/////// Заказ Алхимика. ///////
// Рескин шмоток:

/obj/item/paper/book_alch
	name = "Alchemist's Book"
	desc = "Покрылась пылью и кажется заполнена странными рунами."
	icon = 'modular_bluemoon/krashly/icons/obj/alchemist.dmi'

/obj/item/paper/book_alch/AltClick(mob/living/user, obj/item/I)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(istype(src, /obj/item/paper/carbon))
		var/obj/item/paper/carbon/Carbon = src
		if(!Carbon.copied)
			to_chat(user, span_notice("Take off the carbon copy first."))
			return
	//Origami Master
	var/datum/action/innate/origami/origami_action = locate() in user.actions
	if(origami_action?.active)
		make_plane(user, I, /obj/item/paperplane/syndicate)
	else
		make_plane(user, I, /obj/item/paperplane/book_alch)

/obj/item/paperplane/book_alch
	name = "Alchemist's Book"
	desc = "Покрылась пылью и кажется заполнена странными рунами."
	icon = 'modular_bluemoon/krashly/icons/obj/alchemist.dmi'
	throw_range = 1
	throw_speed = 1
	throwforce = 2

/obj/item/storage/wallet/cat_alch
	name = "Neko Wallet"
	desc = "Этот кот просит денег."
	icon = 'modular_bluemoon/krashly/icons/obj/alchemist.dmi'
	icon_state = "wallet"

// Шмотки в конкретный лодаут по Кею.

/datum/gear/donator/bm/vape
	name = "Vape"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/clothing/mask/vape
	ckeywhitelist = list("trollandrew")
	subcategory = LOADOUT_SUBCATEGORIES_DON03
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/datum/gear/donator/bm/electropack
	name = "Electropack"
	slot = ITEM_SLOT_HANDS
	path = /obj/item/electropack
	ckeywhitelist = list("trollandrew")
	subcategory = LOADOUT_SUBCATEGORIES_DON03
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/datum/gear/donator/bm/straight_jacket
	name = "Straight Jacket"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/straight_jacket
	ckeywhitelist = list("trollandrew")
	subcategory = LOADOUT_SUBCATEGORIES_DON03
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/datum/gear/donator/bm/boxing
	name = "Boxing Gloves"
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/boxing
	ckeywhitelist = list("trollandrew")
	subcategory = LOADOUT_SUBCATEGORIES_DON03
	loadout_flags = LOADOUT_CAN_NAME | LOADOUT_CAN_DESCRIPTION

/datum/gear/donator/bm/coconut_bong
	name = "Coconut Bong"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/bong/coconut

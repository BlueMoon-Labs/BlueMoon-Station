/obj/item/storage/box/deviant_kit/lust
	name = "Sex Worker kit"
	desc = "Kit with ID and permit for employee of Silver Love Co."
	illustration = "id"

/obj/item/storage/box/deviant_kit/lust/PopulateContents()
	new /obj/item/card_sticker/lust(src)
	new /obj/item/clothing/accessory/permit/special/deviant/lust(src)

/obj/item/storage/box/deviant_kit/heresy
	name = "Occult kit"
	desc = "Вещественное одобрение на проведение оккультной деятельности"
	illustration = "id"

/obj/item/storage/box/deviant_kit/heresy/PopulateContents()
	new /obj/item/card_sticker/heresy(src)
	new /obj/item/clothing/accessory/permit/special/deviant/heresey(src)

/obj/item/storage/box/deviant_kit/agony
	name = "Ravenheart Resident kit"
	desc = "Kit with ID and permit for research related to extreme activities whose nature of agony is strictly prohibited by scientific evidence."
	illustration = "id"

/obj/item/storage/box/deviant_kit/agony/PopulateContents()
	new /obj/item/card_sticker/agony(src)
	new /obj/item/clothing/accessory/permit/special/deviant/agony(src)


/obj/item/storage/box/raven_box
	name = "dark red box"
	desc = "Тёмно-красная коробка."
	icon = 'modular_bluemoon/icons/obj/storage.dmi'
	icon_state = "ravenbox"

/obj/item/storage/box/raven_box/posters
	name = "ravenheart posters box"
	desc = "Тёмно-красная коробка."

/obj/item/storage/box/raven_box/posters/PopulateContents()
	new	/obj/item/poster/random_ravenheart(src)
	new	/obj/item/poster/random_ravenheart(src)
	new	/obj/item/poster/random_ravenheart(src)
	new	/obj/item/poster/random_ravenheart(src)
	new	/obj/item/poster/random_ravenheart(src)
	new	/obj/item/poster/random_ravenheart(src)
	new	/obj/item/poster/random_ravenheart(src)

/obj/item/storage/box/deviants
	name = "box of deviant permits"
	desc = "Has so many different deviant permits."
	illustration = "id"

/obj/item/storage/box/deviants/PopulateContents()

	new	/obj/item/clothing/accessory/permit/deviant/heresey(src)
	new	/obj/item/clothing/accessory/permit/deviant/heresey(src)
	new	/obj/item/clothing/accessory/permit/deviant/lust(src)
	new	/obj/item/clothing/accessory/permit/deviant/lust(src)
	new	/obj/item/clothing/accessory/permit/deviant/agony(src)
	new	/obj/item/clothing/accessory/permit/deviant/agony(src)
	new	/obj/item/clothing/accessory/permit/deviant/lust(src)

/obj/item/storage/box/service_permits
	name = "box of service permits"
	desc = "Has permits for new service employees."
	illustration = "id"

/obj/item/storage/box/service_permits/PopulateContents()
	new	/obj/item/clothing/accessory/permit/special/bartender(src)
	new	/obj/item/clothing/accessory/permit/special/bartender(src)
	new	/obj/item/clothing/accessory/permit/special/bartender(src)
	new	/obj/item/clothing/accessory/permit/special/bartender(src)
	new	/obj/item/clothing/accessory/permit/special/bouncer(src)
	new	/obj/item/clothing/accessory/permit/special/bouncer(src)
	new	/obj/item/clothing/accessory/permit/special/bouncer(src)

/obj/item/storage/box/metashop/holoparasite_kit
	name = "holoparasite kit"
	desc = "Коробка с инжектором голопаразита и разрешением на его ношение."
	illustration = "syringe"

/obj/item/storage/box/metashop/holoparasite_kit/PopulateContents()
	new /obj/item/guardiancreator/tech/choose/traitor(src)
	new /obj/item/clothing/accessory/permit/special/holoparasite(src)

///////////////////////////////// SHRIMP /////////////////////////////////////
// Упаковка креветок с ЦК: лоток на 8 креветок, запаянный в пищевую плёнку.
#define SHRIMP_PACK_CAPACITY 8

/obj/item/storage/box/shrimp_pack
	name = "vacuum-packed shrimp"
	desc = "Небольшой лоток с креветками, плотно завернутыми в пищевую пленку. Разверните пленку, держа ее в руке."
	icon = 'modular_bluemoon/icons/obj/food/shrimp_pack.dmi'
	icon_state = "shrimp_pack"
	foldable = null
	illustration = null
	appearance_flags = KEEP_TOGETHER
	var/wrapped = TRUE
	var/static/list/shrimp_offsets = list(
		list(0, 3),  list(5, 1), list(10, 3), list(15, 1),
		list(0, -4), list(5, -6), list(10, -4), list(15, -6),
	)

/obj/item/storage/box/shrimp_pack/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = SHRIMP_PACK_CAPACITY
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/food/snacks/meat/rawshrimp))
	STR.locked = TRUE

/obj/item/storage/box/shrimp_pack/PopulateContents()
	for(var/i in 1 to SHRIMP_PACK_CAPACITY)
		new /obj/item/reagent_containers/food/snacks/meat/rawshrimp(src)
	update_icon()

/obj/item/storage/box/shrimp_pack/attack_self(mob/user)
	if(!wrapped)
		return ..()

	var/unwrap_time = 5 SECONDS
	if(user.mind && (user.mind.assigned_role == "Cook"))
		unwrap_time = 1 SECONDS

	balloon_alert(user, "распаковка...")
	if(!do_after(user, unwrap_time, src))
		return
	if(!wrapped)
		return

	wrapped = FALSE
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.locked = FALSE
	playsound(loc, 'sound/items/poster_ripped.ogg', vol = 50, vary = TRUE)
	user.visible_message(span_notice("[user] распаковывает [src]."), span_notice("Вы распаковали [src]."))
	update_icon()

/obj/item/storage/box/shrimp_pack/update_icon_state()
	if(wrapped)
		icon_state = "shrimp_pack"
	else
		icon_state = "shrimpbox_top"

/obj/item/storage/box/shrimp_pack/update_overlays()
	. = ..()

	if(wrapped)
		return

	var/index = 1
	for(var/obj/item/reagent_containers/food/snacks/meat/rawshrimp/shrimp in contents)
		if(index > SHRIMP_PACK_CAPACITY)
			break
		if(!istype(shrimp))
			continue
		var/list/offset = shrimp_offsets[index]
		. += image(icon = initial(icon), icon_state = "shrimp_inbox", pixel_x = offset[1], pixel_y = offset[2])
		index++

	. += image(icon = initial(icon), icon_state = "shrimpbox_inner")

#undef SHRIMP_PACK_CAPACITY

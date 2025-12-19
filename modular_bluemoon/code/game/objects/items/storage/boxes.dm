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

/obj/item/storage/box/deviant_kit/muck
	name = "Muck activity kit"
	desc = "Жрать гавно."
	illustration = "id"

/obj/item/storage/box/deviant_kit/muck/PopulateContents()
	new /obj/item/card_sticker/muck(src)
	new /obj/item/clothing/accessory/permit/special/deviant/muck(src)

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
	new	/obj/item/clothing/accessory/permit/deviant/muck(src)

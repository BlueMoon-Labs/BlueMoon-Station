/obj/item/storage/toolbox/infiltrator/alliance
	name = "Alliance Assasin Case"
	desc = "Элегантный кейс с отделкой из кожи и с эмблемой Вселенского Союза. Содержит внутри костюм, разработанный для понижения заметности пользователя в условиях тесных пространств замкнутых помещений. Сам кейс же отлично подходит для переноса всего того арсенала оружия, что ты взял с собой на 'тихую' миссию."
	icon_state = "infiltrator_case_alliance"
	item_state = "infiltrator_case_alliance"
	icon = 'modular_bluemoon/icons/obj/assasin/assasin_case.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/case_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/case_righthand.dmi'

/obj/item/storage/toolbox/infiltrator/alliance/PopulateContents()
	new /obj/item/clothing/head/helmet/infiltrator/alliance(src)
	new /obj/item/clothing/suit/armor/vest/infiltrator/alliance(src)
	new /obj/item/clothing/under/alliance/tactical_gorka(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated/infiltrator/alliance(src)
	new /obj/item/clothing/shoes/combat/sneakboots/alliance(src)

/obj/item/clothing/head/helmet/infiltrator/alliance
	name = "Alliance Assasin Helmet"
	desc = "Лёгкий шлем с панорамным визором. Покрыт защитной плёнкой, спасающей владельца от ярких вспышек, а армированный визор сможет выдержать не одну пулю во время твоей 'скрытной' миссии."
	icon_state = "infiltrator_h"
	item_state = "infiltrator_h"
	icon = 'modular_bluemoon/icons/mob/assasin.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/assasin.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/assasin_digi.dmi'
	alternate_screams = ALLIANCE_SCREAMS

/obj/item/clothing/mask/balaclava/breath/alliance
	name = "Alliance Breathaclava"
	clothing_flags = ALLOWINTERNALS
	alternate_screams = ALLIANCE_SCREAMS

/obj/item/clothing/suit/armor/vest/infiltrator/alliance
	name = "Alliance Assasin Combat Vest"
	desc = "Качественный бронежилет с бронепластиной из многослойной пластали. Совмещает в себе лёгкость и прочность, имеет буферный подкладки и идеально прилегает к телу, не издавая лишних звуков при ношении."
	icon_state = "infiltrator_a"
	item_state = "infiltrator_a"
	icon = 'modular_bluemoon/icons/mob/assasin.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/assasin.dmi'

/obj/item/clothing/suit/armor/vest/infiltrator/alliance/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!(user.gender == FEMALE))
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "uncomfortably", /datum/mood_event/uncomfortably)

/obj/item/clothing/under/alliance/tactical_gorka
	name = "Alliance Assasin Combat Suit"
	desc = "Костюм данной модели выполнен на основе неизвестного костюма. Изготавливается из особо прочной ткани Альянсиума с водоотталкивающей пропиткой и высоким содержанием хлопка, и полиэфирных нитей. Идеально подогнан под пропорции клиента и прекрасно подходит для грязной работы."
	icon_state = "infiltrator_u"
	item_state = "infiltrator_u"
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 100, ACID = 100, WOUND = 10)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	can_adjust = FALSE
	icon = 'modular_bluemoon/icons/mob/assasin.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/assasin.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/assasin_digi.dmi'

/obj/item/clothing/under/alliance/tactical_gorka/equipped(mob/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!(user.gender == FEMALE))
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "uncomfortably", /datum/mood_event/uncomfortably)

/obj/item/clothing/gloves/tackler/combat/insulated/infiltrator/alliance
	name = "Alliance Assasin Guerrilla Gloves"
	desc = "Боевые перчатки предназначенные для усиления навыков владельца. Встроенные наночипы напрямую посылают сигналы в нервные окончания рук, доводя движения владельца до идеала, что позволяет укладывать жертв на землю и перетаскивать их с максимальной эффективностью."
	icon_state = "infiltrator_g"
	item_state = "infiltrator_g"
	icon = 'modular_bluemoon/icons/obj/assasin/assasin_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/assasin.dmi'

/obj/item/clothing/shoes/combat/sneakboots/alliance
	name = "Alliance Assasin Sneakboots"
	desc = "Пара ботинок с высоким берцем. Подошва покрыта звукопоглощающим слоем, почти полностью сводя шум шагов на нет."
	icon_state = "sneakboots"
	item_state = "sneakboots"
	icon = 'modular_bluemoon/icons/obj/assasin/assasin_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/assasin.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/assasin_digi.dmi'
	clothing_flags = NONE

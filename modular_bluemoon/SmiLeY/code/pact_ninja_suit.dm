/obj/item/storage/toolbox/infiltrator/pact_ninja
	name = "Pact Ninja Case"
	desc = "Элегантный кейс с отделкой из кожи и с эмблемой Nanotrasen и Синдиката. Содержит внутри костюм, разработанный для понижения заметности пользователя в условиях тесных пространств замкнутых помещений. Сам кейс же отлично подходит для переноса всего того арсенала оружия, что ты взял с собой на 'тихую' миссию."
	icon_state = "infiltrator_case_command"
	item_state = "infiltrator_case_command"
	icon = 'modular_sand/icons/obj/storage.dmi'

/obj/item/storage/toolbox/infiltrator/pact_ninja/PopulateContents()
	new /obj/item/clothing/head/helmet/infiltrator/pact_ninja(src)
	new /obj/item/clothing/suit/armor/vest/infiltrator/pact_ninja(src)
	new /obj/item/clothing/under/pact_ninja/tactical_gorka(src)
	new /obj/item/clothing/gloves/tackler/combat/insulated/infiltrator/pact_ninja(src)
	new /obj/item/clothing/shoes/combat/sneakboots/pact_ninja(src)
	new /obj/item/melee/transforming/energy/sword/pirate/pact_ninja(src)
	new /obj/item/tank/internals/oxygen/black(src)

/obj/item/tank/internals/oxygen/black
	desc = "Баллон кислорода чёрного цвета."
	icon = 'modular_bluemoon/SmiLeY/icons/obj/obj.dmi'
	icon_state = "oxygen_black"
	dog_fashion = null

/obj/item/melee/transforming/energy/sword/pirate/pact_ninja
	name = "Pact Ninja Energy Cutlass"
	desc = "Рар, мяу."
	icon_state = "spear0"
	icon_state_on = "spear1"
	icon = 'modular_bluemoon/SmiLeY/icons/obj/obj.dmi'
	lefthand_file = 'modular_bluemoon/SmiLeY/icons/obj/items_left.dmi'
	righthand_file = 'modular_bluemoon/SmiLeY/icons/obj/items_right.dmi'

/obj/item/clothing/head/helmet/infiltrator/pact_ninja
	name = "Pact Ninja Helmet"
	desc = "Лёгкий шлем с панорамным визором. Покрыт защитной плёнкой, спасающей владельца от ярких вспышек, а армированный визор сможет выдержать не одну пулю во время твоей 'скрытной' миссии."
	icon_state = "infiltrator_h"
	item_state = "infiltrator_h"
	icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	mob_overlay_icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja_digi.dmi'
	alternate_screams = ALLIANCE_SCREAMS

/obj/item/clothing/mask/balaclava/breath/pact_ninja
	name = "Pact Ninja Breathaclava"
	icon_state = "infiltrator_m"
	item_state = "infiltrator_m"
	icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	mob_overlay_icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja_digi.dmi'
	alternate_screams = ALLIANCE_SCREAMS

/obj/item/clothing/suit/armor/vest/infiltrator/pact_ninja
	name = "Pact Ninja Combat Vest"
	desc = "Качественный бронежилет с бронепластиной из многослойной пластали. Совмещает в себе лёгкость и прочность, имеет буферный подкладки и идеально прилегает к телу, не издавая лишних звуков при ношении."
	icon_state = "infiltrator_a"
	item_state = "infiltrator_a"
	icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	mob_overlay_icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja_digi.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS

/obj/item/clothing/under/pact_ninja/tactical_gorka
	name = "Pact Ninja Combat Suit"
	desc = "Костюм данной модели выполнен на основе неизвестного костюма. Изготавливается из особо прочной ткани Альянсиума с водоотталкивающей пропиткой и высоким содержанием хлопка, и полиэфирных нитей. Идеально подогнан под пропорции клиента и прекрасно подходит для грязной работы."
	icon_state = "infiltrator_u"
	item_state = "infiltrator_u"
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 100, ACID = 100, WOUND = 10)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	can_adjust = FALSE
	icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	mob_overlay_icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja_digi.dmi'

/obj/item/clothing/gloves/tackler/combat/insulated/infiltrator/pact_ninja
	name = "Pact Ninja Guerrilla Gloves"
	desc = "Боевые перчатки предназначенные для усиления навыков владельца. Встроенные наночипы напрямую посылают сигналы в нервные окончания рук, доводя движения владельца до идеала, что позволяет укладывать жертв на землю и перетаскивать их с максимальной эффективностью."
	icon_state = "infiltrator_g"
	item_state = "infiltrator_g"
	icon = 'modular_bluemoon/SmiLeY/icons/obj/obj.dmi'
	mob_overlay_icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'

/obj/item/clothing/shoes/combat/sneakboots/pact_ninja
	name = "Pact Ninja Sneakboots"
	desc = "Пара ботинок с высоким берцем. Подошва покрыта звукопоглощающим слоем, почти полностью сводя шум шагов на нет."
	icon_state = "sneakboots"
	item_state = "sneakboots"
	icon = 'modular_bluemoon/SmiLeY/icons/obj/assasin/assasin_clothing.dmi'
	mob_overlay_icon = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/SmiLeY/icons/mob/pact_ninja_digi.dmi'
	clothing_flags = NONE

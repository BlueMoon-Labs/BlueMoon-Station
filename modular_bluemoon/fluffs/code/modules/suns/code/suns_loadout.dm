// Personal SUNS loadout for noterravija & dagran.
// Only non-gameplay skins are granted directly; anything functional
// (suits, hardsuits, gloves, eye masks, visors, hoods) is served via
// the SUNS conversion kit box instead.

/datum/gear/donator/bm/suns
	description = "Золото? Ясно — сделано из банания! Хонк!"
	ckeywhitelist = list("noterravija", "dagran")

// uniforms

/datum/gear/donator/bm/suns/formal_suit
	name = "SUNS formal suit"
	description = "Нарядный сшитый на заказ костюм с фиолетовыми брюками. Обычно его носят студенты первой половины учёбы."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns

/datum/gear/donator/bm/suns/senior_suit
	name = "SUNS senior formal suit"
	description = "Форма, которую обычно носят студенты старших курсов."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/uniform2

/datum/gear/donator/bm/suns/graduate_suit
	name = "SUNS graduate suit"
	description = "Костюм, который носят выпускники SUNS и преподаватели SUNS. Ты прошёл долгий путь, друг."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/uniform3

/datum/gear/donator/bm/suns/peacekeeper_uniform
	name = "SUNS peacekeeper uniform"
	description = "Форма, созданная для удобства движений — и в аудитории, и на границе."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/pkuniform

/datum/gear/donator/bm/suns/work_jumpsuit
	name = "SUNS work jumpsuit"
	description = "Повседневная форма, которую носят студенты и сотрудники, чтобы не пачкаться на черновой работе."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/workerjumpsuit

/datum/gear/donator/bm/suns/captain_suit
	name = "SUNS captain suit"
	description = "Вычурная форма, чтобы выделить старших сотрудников академии среди остальных."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/captain

/datum/gear/donator/bm/suns/academic_suit
	name = "SUNS academic suit"
	description = "Стиль костюма, который обычно носят преподаватели."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/xo

/datum/gear/donator/bm/suns/lab_jumpsuit
	name = "SUNS lab jumpsuit"
	description = "Удобный костюм, созданный для защиты человека от воздействия вредных предметов."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/sciencejumpsuit

/datum/gear/donator/bm/suns/medical_scrubs
	name = "SUNS medical scrubs"
	description = "Рабочие медицинские халаты для профессионалов и стажёров."
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/syndicate/suns/doctorscrubs

// headwear

/datum/gear/donator/bm/suns/staff_beret
	name = "SUNS academic staff beret"
	description = "Мягкий берет с выцветшим пером-чернильницей. Если бы только он снова мог держать чернила."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/suns/staffberet

/datum/gear/donator/bm/suns/worker_helmet
	name = "SUNS worker helmet"
	description = "Головной убор, используемый в опасных рабочих условиях для защиты головы."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/suns/workerhelmet

/datum/gear/donator/bm/suns/peacekeeper_cap
	name = "SUNS peacekeeper cap"
	description = "Чёрная фуражка, которую носят эксцентричные миротворцы."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/suns/pkcap

/datum/gear/donator/bm/suns/surgery_cap
	name = "SUNS surgery cap"
	description = "Хирургическая шапочка, которую носят и студенты академии, и профессионалы."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/suns/surgerycap

/datum/gear/donator/bm/suns/captain_bicorne
	name = "SUNS bicorne hat"
	description = "Уникальная двууголка, которую дают капитанам SUNS, чтобы показать академическое старшинство."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/suns/captainbicorne

/datum/gear/donator/bm/suns/doctor_hat
	name = "SUNS medical instructor hat"
	description = "Шляпа, которую носят эксцентричные медицинские сотрудники."
	slot = ITEM_SLOT_HEAD
	path = /obj/item/clothing/head/suns/doctorhat

// masks

/datum/gear/donator/bm/suns/black_gas_mask
	name = "SUNS black gas mask"
	description = "Чёрное покрытие лица, позволяющее подключиться к личному источнику газа. Удивительно плохо предотвращает вдыхание газа."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/suns

/datum/gear/donator/bm/suns/sterile_mask
	name = "SUNS purple sterile mask"
	description = "Стерильная маска, помогающая предотвратить распространение болезней. Теперь и фиолетовая! Красиво!"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/surgical/suns

/datum/gear/donator/bm/suns/half_face_mask
	name = "SUNS half face mask"
	description = "Плотно прилегающая маска, прикрывающая ровно настолько, чтобы подключить источник воздуха."
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/breath/suns

// cloaks

/datum/gear/donator/bm/suns/short_cloak
	name = "SUNS short cloak"
	description = "Носят и молодые, и старые. Почти чувствуешь академическую гордость."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/suns

/datum/gear/donator/bm/suns/staff_cloak
	name = "SUNS academic staff cloak"
	description = "Носят сотрудники SUNS — почти можно учуять все двойки, которые этот плащ повидал."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/suns/xo

/datum/gear/donator/bm/suns/captain_cloak
	name = "SUNS captain's cloak"
	description = "Носят капитаны SUNS. У этого плаща очень внушительная аура."
	slot = ITEM_SLOT_NECK
	path = /obj/item/clothing/neck/cloak/suns/cap

// shoes

/datum/gear/donator/bm/suns/white_clogs
	name = "SUNS white clogs"
	description = "Удобные деревянные башмаки для повседневного использования."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/sneakers/suns/doctorclogs

/datum/gear/donator/bm/suns/combat_boots
	name = "SUNS fancy combat boots"
	description = "Боевые ботинки с приличным сцеплением, которые носят старшие академические сотрудники."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/combat/suns

/datum/gear/donator/bm/suns/work_jackboots
	name = "SUNS work safe jackboots"
	description = "Академические ботинки со стальным носком. Для тех, у кого физически тяжёлая специализация."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/jackboots/suns

/datum/gear/donator/bm/suns/longboots
	name = "SUNS peacekeeper longboots"
	description = "Высокие сапоги, которые носят академические охранники и стажёры."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/jackboots/suns/long

/datum/gear/donator/bm/suns/laceup_shoes
	name = "SUNS academy laceup shoes"
	description = "Стандартные шнурованные ботинки от академии, что при Синдикате."
	slot = ITEM_SLOT_FEET
	path = /obj/item/clothing/shoes/laceup/suns

// accessories

/datum/gear/donator/bm/suns/waistcoat
	name = "SUNS waistcoat"
	description = "Обычный академический жилет."
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/waistcoat/suns

/datum/gear/donator/bm/suns/ribbon
	name = "SUNS ribbon"
	description = "Академический бант — для тех случаев, когда хочется выглядеть мило."
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/waistcoat/suns/ribbon

/datum/gear/donator/bm/suns/gembow
	name = "SUNS gem bow"
	description = "Академический бант — для тех случаев, когда хочется выглядеть ОЧЕНЬ мило."
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/waistcoat/suns/gembow

/datum/gear/donator/bm/suns/chest_poof
	name = "SUNS chest poof"
	description = "Академический бант — для тех случаев, когда хочется выглядеть изысканно."
	slot = ITEM_SLOT_ACCESSORY
	path = /obj/item/clothing/accessory/waistcoat/suns/poof

// conversion kit box

/datum/gear/donator/bm/suns/kit
	name = "SUNS kit"
	description = "Военный ящик с полным набором конверсионных наборов SUNS."
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/suns_kit

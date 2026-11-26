/datum/gear/glasses/security/sunglasses/aviators
	name = "Security HUD Aviators"
	description = "Авиаторы с охранным HUD."
	path = /obj/item/clothing/glasses/hud/security/sunglasses/aviators
	restricted_roles = list("Peacekeeper", "Security Officer", "Warden", "Head of Security", "NanoTrasen Representative", "Captain", "Blueshield")

/datum/gear/glasses/security/sunglasses/securitygoggles
	name = "Security HUD Goggles"
	path = /obj/item/clothing/glasses/hud/security/securitygoggles
	restricted_roles = list("Peacekeeper", "Security Officer", "Warden", "Head of Security", "NanoTrasen Representative", "Captain", "Blueshield")

/datum/gear/glasses/security/sunglasses/aviators/prescription
	name = "Prescription Security HUD Aviators"
	description = "Авиаторы с охранным HUD и диоптрийными линзами."
	path = /obj/item/clothing/glasses/hud/security/sunglasses/aviators/prescription
	restricted_roles = list("Peacekeeper", "Security Officer", "Warden", "Head of Security", "NanoTrasen Representative", "Captain", "Blueshield")

/datum/gear/glasses/security/sunglasses/holo
	name = "Holo Secuirity HUD Glasses"
	description = "Солнцезащитные очки с охранным HUD. Почти не видны, когда надеты."
	path = /obj/item/clothing/glasses/hud/security/sunglasses/holo
	restricted_roles = list("Peacekeeper", "Security Officer", "Warden", "Head of Security", "NanoTrasen Representative", "Captain", "Blueshield") // Add by KiJoking

/datum/gear/glasses/security/sunglasses/holo/prescription
	name = "Prescription Holo Secuirity HUD Glasses"
	description = "Солнцезащитные очки с охранным HUD. Почти не видны, когда надеты. С диоптрийными линзами."
	path = /obj/item/clothing/glasses/hud/security/sunglasses/holo/prescription
	restricted_roles = list("Peacekeeper", "Security Officer", "Warden", "Head of Security", "NanoTrasen Representative", "Captain", "Blueshield") // Add by KiJoking

/datum/gear/glasses/health/sunglasses/aviators
	name = "Medical HUD Aviators"
	description = "Авиаторы с медицинским HUD."
	path = /obj/item/clothing/glasses/hud/health/sunglasses/aviators
	restricted_roles = list("Chief Medical Officer", "Brig Physician") // BLUEMOON CHANGE balance issues with flash_protection

/datum/gear/glasses/health/sunglasses/aviators/prescription
	name = "Prescription Medical HUD Aviators"
	description = "Авиаторы с медицинским HUD. С диоптрийными линзами."
	path = /obj/item/clothing/glasses/hud/health/sunglasses/aviators/prescription
	restricted_roles = list("Chief Medical Officer", "Brig Physician") // BLUEMOON CHANGE balance issues with flash_protection

/datum/gear/glasses/blueshield/aviators
	name = "Blueshield HUD Aviators"
	description = "HUD с множеством функций. Более стильный."
	path = /obj/item/clothing/glasses/hud/blueshield/aviators
	restricted_roles = list("Blueshield")

/datum/gear/glasses/blueshield/prescription
	name = "Prescription Blueshield HUD"
	description = "HUD с множеством функций. С диоптрийными линзами."
	path = /obj/item/clothing/glasses/hud/blueshield/prescription
	restricted_roles = list("Blueshield")

/datum/gear/glasses/blueshield/aviators/prescription
	name = "Prescription Blueshield HUD Aviators"
	description = "HUD с множеством функций. Более стильный. С диоптрийными линзами."
	path = /obj/item/clothing/glasses/hud/blueshield/aviators/prescription
	restricted_roles = list("Blueshield")

/datum/gear/glasses/blueshield/holo
	name = "Holo Blueshield HUD Glasses"
	description = "HUD с множеством функций. Почти не виден, когда надет. Всё равно защищает от вспышек."
	path = /obj/item/clothing/glasses/hud/blueshield/holo
	restricted_roles = list("Blueshield")

/datum/gear/glasses/blueshield/holo/prescription
	name = "Prescription Holo Blueshield HUD Glasses"
	description = "HUD с множеством функций. Почти не виден, когда надет. С диоптрийными линзами."
	path = /obj/item/clothing/glasses/hud/blueshield/holo/prescription
	restricted_roles = list("Blueshield")

//NON-RESTRICTED

/datum/gear/glasses/contact
	name = "Contact Lenses"
	description = "Контактные линзы с диоптриями — чудо науки."
	path = /obj/item/clothing/glasses/contact

/datum/gear/glasses/tac_veil
	name = "Veil (adaptive)"
	description = "Компания Furui привезла это из дальних краёв, переняв культуру Jingdai."
	path = /obj/item/clothing/glasses/cover/tac_veil

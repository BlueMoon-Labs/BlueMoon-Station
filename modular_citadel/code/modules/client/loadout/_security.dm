/datum/gear/uniform/navyblueuniformhos
 	name = "Head of Security navyblue uniform"
	description = "Эмблема на этой форме говорит, что она принадлежит Начальнику безопасности."
 	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
 	path = /obj/item/clothing/under/rank/security/head_of_security/formal
 	restricted_roles = list("Head of Security")

/datum/gear/head/navybluehosberet
	name = "Head of security's navyblue beret"
	description = "Особый берет с эмблемой Начальника безопасности. Символ превосходства, знак храбрости, метка исключительности."
	path = /obj/item/clothing/head/beret/sec/navyhos
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Head of Security")

/datum/gear/suit/navybluejackethos
	name = "head of security's navyblue jacket"
	description = "Эта одежда была специально создана для подчёркивания превосходной власти."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	path = /obj/item/clothing/suit/armor/hos/navyblue
	restricted_roles = list("Head of Security")

/datum/gear/suit/navybluejacketofficer
	name = "security officer's navyblue jacket"
	description = "Эта куртка — для тех особых случаев, когда охраннику не требуется броня."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	path = /obj/item/clothing/suit/armor/navyblue
	restricted_roles = list("Security Officer")

/datum/gear/head/empire_head
	name = "Katzen Steel Helmet"
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	path = /obj/item/clothing/head/helmet/sec/empire_head
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#2A2A2A","#e4b829")
	restricted_roles = list("Security Officer", "Head of Security", "Warden")

/datum/gear/head/navyblueofficerberet
	name = "Security officer's Navyblue beret"
	description = "Особый берет с эмблемой службы безопасности. Для офицеров с классом."
	path = /obj/item/clothing/head/beret/sec/navyofficer
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Security Officer")

/datum/gear/uniform/navyblueuniformofficer
 	name = "Security officer navyblue uniform"
	description = "Последний пир модной охранной формы."
 	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
 	path = /obj/item/clothing/under/rank/security/officer/formal
 	restricted_roles = list("Security Officer")

/datum/gear/suit/navybluejacketwarden
	name = "warden navyblue jacket"
	description = "Идеально для надзирателя, который хочет произвести впечатление стилем на посетителей брига."
	subcategory = LOADOUT_SUBCATEGORY_SUIT_JOBS
	path = /obj/item/clothing/suit/armor/vest/warden/navyblue
	restricted_roles = list("Warden")

/datum/gear/head/navybluewardenberet
	name = "Warden's navyblue beret"
	description = "Особый берет с эмблемой надзирателя. Для надзирателей с классом."
	path = /obj/item/clothing/head/beret/sec/navywarden
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Warden")

/datum/gear/uniform/navyblueuniformwarden
 	name = "Warden navyblue uniform"
	description = "Эмблема на этой форме говорит, что она принадлежит надзирателю."
 	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
 	path = /obj/item/clothing/under/rank/security/warden/formal
 	restricted_roles = list("Warden")

/datum/gear/uniform/secskirt
	name = "Security skirt"
	description = "«Тактический» комбинезон охранника, у которого вместо штанин юбка."
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	path = /obj/item/clothing/under/rank/security/officer/skirt
	restricted_roles = list("Security Officer", "Warden", "Head of Security")

/datum/gear/uniform/hosskirt
	name = "Head of security's skirt"
	description = "Комбинезон-юбка охранника, украшенный для тех немногих, кто вот столько лет как достиг должности Начальника безопасности."
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	path = /obj/item/clothing/under/rank/security/head_of_security/skirt
	restricted_roles = list("Head of Security")

/datum/gear/glasses/sechud
	name = "Security Hud"
	path = /obj/item/clothing/glasses/hud/security
	restricted_roles = list("Peacekeeper", "Security Officer", "Warden", "Head of Security")

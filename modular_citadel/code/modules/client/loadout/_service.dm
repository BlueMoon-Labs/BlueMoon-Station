/datum/gear/uniform/greytidestationwide
	name = "Staff Assistant's jumpsuit"
	description = "Обычный серый комбинезон. Впрочем, помощники примерно столько и стоят."
	path = /obj/item/clothing/under/misc/staffassistant
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_roles = list("Assistant", "Stowaway")

/datum/gear/suit/neetsuit
	name = "D.A.B. suit"
	description = "Дешёвая копия старой брони SWAT. На спине написано: «<i>Desperate Assistance Battleforce</i>»."
	path = /obj/item/clothing/suit/assu_suit
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_roles = list("Assistant", "Stowaway")
	cost = 2

/datum/gear/head/neethelm
	name = "D.A.B. helmet"
	description = "Дешёвая копия старого шлема для подавления беспорядков без забрала. Спереди написано «D.A.B.»."
	path = /obj/item/clothing/head/assu_helmet
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Assistant", "Stowaway")
	cost = 2

/datum/gear/backpack/plushvar
	name = "Ratvar Plushie"
	description = "Очаровательный плюшевый сам часового магистрата с новой и улучшенной пружинной рукой."
	path = /obj/item/toy/plush/plushvar
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 5
	restricted_roles = list("Chaplain")

/datum/gear/backpack/narplush
	name = "Narsie Plushie"
	description = "Маленькая мягкая кукла старшей богини Nar'Sie. Кто решил, что это хорошая детская игрушка?"
	path = /obj/item/toy/plush/narplush
	subcategory = LOADOUT_SUBCATEGORY_BACKPACK_TOYS
	cost = 5
	restricted_roles = list("Chaplain")

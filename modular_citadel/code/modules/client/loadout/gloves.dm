/datum/gear/gloves
	category = LOADOUT_CATEGORY_GLOVES
	slot = ITEM_SLOT_GLOVES

/datum/gear/gloves/fingerless
	name = "Fingerless Gloves"
	description = "Простые чёрные перчатки без пальцев для тех, кто много работает."
	path = /obj/item/clothing/gloves/fingerless

/datum/gear/gloves/color
	name = "Black Gloves"
	description = "Эти перчатки огнеустойчивы."
	path = /obj/item/clothing/gloves/color/black

/datum/gear/gloves/evening
	name = "Evening gloves"
	description = "Тонкие красивые перчатки для королевского женского наряда. Бирка на краю гласит, что они «сделаны» в Космическом Китае — скорее всего, их предназначали для какого-то фетиша на горничных."
	path = /obj/item/clothing/gloves/evening

/datum/gear/gloves/midnight
	name = "Midnight gloves"
	description = "Тонкие красивые перчатки для сексуального женского наряда. Бирка на краю гласит, что они отлично сочетаются с чёрными чулками."
	path = /obj/item/clothing/gloves/evening/black

/datum/gear/gloves/maidpoly // WHAT DO YOU EVEN CALL THEM
	name = "Polychromic maid gloves"
	path = /obj/item/clothing/gloves/polymaid
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#333333", "#FFFFFF")

/datum/gear/gloves/north_star
	name = "Hugs of the North Star"
	description = "Нарукавные повязки скромного друга. Теперь вам очень хочется рассказать всем, как вы его цените!"
	path = /obj/item/clothing/gloves/fingerless/pugilist/hug

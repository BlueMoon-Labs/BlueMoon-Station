//ASH WEAPON
/obj/item/melee/macahuitl
	name = "ash macahuitl"
	desc = "Оружие, которое, судя по всему, оставляет очень сильные следы."
	icon = 'modular_bluemoon/code/modules/ashwalkers/icons/ashwalker_clothing.dmi'
	icon_state = "macahuitl"

	force = 25
	wound_bonus = 15

/datum/crafting_recipe/ash_recipe/macahuitl
	name = "Ash Macahuitl"
	result = /obj/item/melee/macahuitl
	reqs = list(
		/obj/item/stack/sheet/bone = 2,
		/obj/item/stack/sheet/sinew = 2,
		/obj/item/stack/sheet/animalhide/goliath_hide = 2,
	)
	category = CAT_PRIMAL

/obj/item/kinetic_crusher/cursed
	name = "cursed ash carver"
	desc = "Ужасное, похожее на живое оружие, которое время от времени пульсирует. Тендрил создал это чудовище, чтобы подражать и соперничать с теми, кто вторгается на эту землю."
	icon = 'modular_bluemoon/code/modules/ashwalkers/icons/ashwalker_tools.dmi'

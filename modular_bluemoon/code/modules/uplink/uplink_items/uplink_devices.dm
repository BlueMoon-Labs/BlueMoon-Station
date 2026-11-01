/datum/uplink_item/inteq/shieldbelt
	name = "Shieldbelt"
	desc = "Лучшие умы ЧВК додумались использовать портативные генераторы щита не только в скафандрах."
	item = /obj/item/shieldbelt
	cost = 6
	purchasable_from = (UPLINK_TRAITORS)

/datum/uplink_item/mod/shield_module
	name = "Shield MOD Module"
	desc = "Украденный у Синдиката незавершенный модуль щита, доработанный уже в лабораториях ЧВК. Всё ещё достаточно сильный,\
	однако не способен выдерживать столько же много попаданий, как старшая версия."
	item = /obj/item/mod/module/energy_shield/syndie/inteq
	cost = 4
	purchasable_from = (UPLINK_TRAITORS)

/datum/uplink_item/device_tools/vortex_cell
	name = "Vortex power cell"
	desc = "Невероятно технологичная самозарядная батарея."
	item = /obj/item/stock_parts/cell/vortex
	cost = 2
	purchasable_from = (UPLINK_TRAITORS | UPLINK_SYNDICATE | UPLINK_SYNDICATE_PACT_CREW)

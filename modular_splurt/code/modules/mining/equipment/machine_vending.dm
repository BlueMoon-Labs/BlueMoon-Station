/obj/machinery/mineral/equipment_vendor/Initialize(mapload)
	. = ..()
	prize_list += list(
			new /datum/data/mining_equipment("Explorer Stripper Outfit", /obj/item/clothing/under/rank/cargo/miner/lavaland/stripper, 50,	"Mining Gear")
			)
	build_inventory() // Фикс нужен для корректного отображения иконок

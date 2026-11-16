/obj/item/vending_refill/fishing
	machine_name = "Angler's Friend"
	icon_state = "refill_snack"

/obj/item/circuitboard/machine/vendor/fishing
	name = "Angler's Friend Vendor (Machine Board)"
	build_path = /obj/machinery/vending/fishing
	req_components = list(/obj/item/vending_refill/fishing = 1)

/datum/supply_pack/service/fishing_kit
	name = "Fishing Kit"
	desc = "Ящик с базовой удочкой, леской, крючком, приманками, каталогом рыб, портальным набором и парой ящиков для улова."
	cost = 800
	contains = list(
		/obj/item/fishing_rod,
		/obj/item/fishing_line,
		/obj/item/fishing_hook,
		/obj/item/bait_can/worm,
		/obj/item/fishing_lure/minnow,
		/obj/item/bait/doughball,
		/obj/item/fish_catalog,
		/obj/item/fishing_portal_kit,
		/obj/item/stock_parts/cell/lead,
		/obj/item/storage/fish_case,
		/obj/item/storage/fish_case/random,
	)
	crate_name = "fishing kit"

/datum/supply_pack/vending/fishing
	name = "Angler's Friend Refill Crate"
	desc = "Заправка для автомата Angler's Friend. Возвращает на полки удочки, снасти, приманки и рыбацкую одежду."
	cost = 700
	contains = list(/obj/item/vending_refill/fishing)
	crate_name = "fishing vendor refill crate"

/obj/item/circuitboard/machine/pdapainter
	name = "PDA painter (Machine Board)"
	icon_state = "service"
	build_path = /obj/machinery/pdapainter
	req_components = list(
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stack/cable_coil = 2,
		/obj/item/stack/sheet/glass = 2)
	needs_anchored = FALSE

/obj/item/circuitboard/machine/aug_manipulator
	name = "Augment manipulator (Machine Board)"
	icon_state = "science"
	build_path = /obj/machinery/aug_manipulator
	req_components = list(
		/obj/item/stock_parts/micro_laser = 1,
		/obj/item/stack/cable_coil = 2,
		/obj/item/stack/sheet/glass = 2)
	needs_anchored = FALSE

// Плата для генератора полезных для робототехника жидкостей
/obj/item/circuitboard/machine/robo_liquid_generator
	name = "RoboLiquid Generator (Machine Board)"
	icon_state = "science"
	build_path = /obj/machinery/robo_liquid_generator
	desc = "Звучит достаточно инновационно?"
	req_components = list(
		/obj/item/stock_parts/manipulator = 3,
		/obj/item/stock_parts/matter_bin = 2,
		/obj/item/stock_parts/capacitor = 2,
		/obj/item/stack/sheet/glass = 1)
	needs_anchored = FALSE

// This item must not be used in the game. It's needed for correct stock_parts work.
/obj/item/circuitboard/machine/pedalgen
	name = "Pedal Generator (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/power/dynamo
	req_components = list(
		/obj/item/stock_parts/capacitor = 2)
	needs_anchored = FALSE


// ============================================
// CIRCUIT BOARDS ДЛЯ СИСТЕМЫ VANGUARD
// ============================================

// Платформа обмена контрабанды
/obj/item/circuitboard/machine/contrabandpad
	name = "Contraband Exchange Pad (Machine Board)"
	icon_state = "generic"
	build_path = /obj/machinery/vanguard/contraband
	desc = "The circuit board for a contraband exchange pad."
	req_components = list(
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/manipulator = 1
	)

// Консоль управления платформой
/obj/item/circuitboard/computer/contrabandpad
	name = "Contraband Exchange Terminal (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/vanguard_control/contraband
	desc = "The circuit board for a contraband exchange terminal."

// BountyVend терминал
/obj/item/circuitboard/machine/bountyvend
	name = "BountyVend (Machine Board)"
	icon_state = "generic"
	build_path = /obj/machinery/bountyvend
	desc = "The circuit board for a BountyVend terminal."
	req_components = list(
		/obj/item/stock_parts/matter_bin = 3
	)

/obj/item/circuitboard/machine/bountyvend/plus
	name = "BountyVend Expert (Machine Board)"
	build_path = /obj/machinery/bountyvend/plus

/obj/item/circuitboard/machine/big_manipulator
	name = "Big Manipulator (Machine Board)"
	icon_state = "engineering"
	build_path = /obj/machinery/big_manipulator
	req_components = list(
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stack/sheet/glass = 1)
	needs_anchored = FALSE


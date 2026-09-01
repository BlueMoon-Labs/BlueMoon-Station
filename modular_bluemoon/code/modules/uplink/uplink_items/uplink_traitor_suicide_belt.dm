
/datum/uplink_item/explosives/traitor_suicide_belt
	name = "Suicide Bomber Belt"
	desc = "Пояс с зарядами, связанными на один общий таймер. После включения звучит громкая запись с пояса, затем идёт мощнейший взрыв."
	item = /obj/item/suicide_belt
	cost = 10
	surplus = 0
	cant_discount = TRUE
	hijack_only = TRUE
	purchasable_from = UPLINK_TRAITORS | UPLINK_NUKE_OPS

/datum/uplink_item/device_tools/traitor_dna_laser_eyes
	name = "DNA injector (laser eyes)"
	desc = "Штамп, вводящий мутацию «Laser Eyes»."
	item = /obj/item/dnainjector/lasereyesmut
	cost = 16
	surplus = 0
	purchasable_from = UPLINK_TRAITORS | UPLINK_SYNDICATE

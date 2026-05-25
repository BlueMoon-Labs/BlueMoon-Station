
/datum/uplink_item/explosives/traitor_suicide_belt
	name = "Suicide bomber belt"
	desc = "Пояс с зарядами, связанными на один общий таймер. После включения громкая запись звучит с пояса ~5 секунд, затем мощнейший разрыв. В каталог попадаешь только имея задачу на угон шаттла через консоль управления или на героическую (мартирскую) гибель; тот же фильтр действует у оперативников ядерной команды."
	item = /obj/item/suicide_belt
	cost = 10
	surplus = 0
	cant_discount = TRUE
	hijack_only = TRUE
	purchasable_from = UPLINK_TRAITORS | UPLINK_SYNDICATE | UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS

/datum/uplink_item/device_tools/traitor_dna_laser_eyes
	name = "DNA injector (laser eyes)"
	desc = "Штамп InteQ, вводящий мутацию «Laser Eyes». Мутация «замкнута»: не выпадает из стандартного генетического набора блоков станции."
	item = /obj/item/dnainjector/lasereyesmut
	cost = 16
	surplus = 0
	purchasable_from = UPLINK_TRAITORS | UPLINK_SYNDICATE

/obj/item/integrated_circuit/power/
	category_text = "Энергия - Активная"

/obj/item/integrated_circuit/power/transmitter
	name = "power transmission circuit"
	desc = "Это позволяет беспроводным способом передавать электроэнергию от аккумулятора корпуса к расположенному поблизости устройству."
	icon_state = "power_transmitter"
	extended_desc = "Эта схема передает 5 кДж электроэнергии при каждом импульсе на пине активатора. Пин входа должен быть \
    ссылкой на устройство, на которое передается электроэнергия. Это может быть батарея или любое устройство, содержащее батарейку. Устройство может находиться \
    внутри корпуса или рядом с ним. Питание подается от батарейки корпуса. Если цель находится за пределами корпуса, \
    часть энергии теряется из-за потерь при передаче."
	w_class = WEIGHT_CLASS_SMALL
	complexity = 16
	inputs = list("цель" = IC_PINTYPE_REF)
	outputs = list(
		"заряд батареи цели" = IC_PINTYPE_NUMBER,
		"максимальный заряд батареи цели" = IC_PINTYPE_NUMBER,
		"процент заряда батареи цели" = IC_PINTYPE_NUMBER
		)
	activators = list("передать" = IC_PINTYPE_PULSE_IN, "при передаче" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 500 // Inefficency has to come from somewhere.
	var/amount_to_move = 5000

/obj/item/integrated_circuit/power/transmitter/large
	name = "large power transmission circuit"
	desc = "Это устройство позволяет беспроводным способом передавать значительный объем электроэнергии от аккумулятора корпуса к расположенному поблизости устройству. <b>Предупреждение:</b> Не используйте в среде, подверженной возгоранию."
	extended_desc = "Эта схема передает 20 кДж электроэнергии при каждом импульсе на пине активатора. Пин входа должен быть \
    ссылкой на устройство, которому предназначается электроэнергия. Это может быть батарея или любое устройство, содержащее батарею. Устройство может находиться \
	внутри корпуса или рядом с ним. Питание поступает от батарейки корпуса. Если цель находится за пределами корпуса, \
    часть энергии теряется из-за неэффективности. Внимание! Не устанавливайте более 1 передатчика энергии, так как это снижает эффективность всех остальных \
    схем передачи энергии в данном корпусе и соседних корпусах."
	w_class = WEIGHT_CLASS_BULKY
	complexity = 32
	power_draw_per_use = 2000
	amount_to_move = 20000

/obj/item/integrated_circuit/power/transmitter/do_work()

	var/atom/movable/AM = get_pin_data_as_type(IC_INPUT, 1, /atom/movable)
	if(!AM)
		return FALSE
	if(istype(AM, /obj/item/gun/energy))
		return FALSE
	if(!assembly)
		return FALSE // Pointless to do everything else if there's no battery to draw from.
	var/obj/item/stock_parts/cell/cell = AM.get_cell()
	if(cell)
		var/transfer_amount = amount_to_move
		var/turf/A = get_turf(src)
		var/turf/B = get_turf(AM)
		if(A.Adjacent(B))
			if(AM.loc != assembly)
				transfer_amount *= 0.8 // Losses due to distance.
			var/list/U=A.GetAllContents(/obj/item/integrated_circuit/power/transmitter)
			transfer_amount *= 1 / U.len
			set_pin_data(IC_OUTPUT, 1, cell.charge)
			set_pin_data(IC_OUTPUT, 2, cell.maxcharge)
			set_pin_data(IC_OUTPUT, 3, cell.percent())
			activate_pin(2)
			push_data()
			if(cell.charge == cell.maxcharge)
				return FALSE
			if(transfer_amount && assembly.draw_power(amount_to_move)) // CELLRATE is already handled in draw_power()
				cell.give(transfer_amount * GLOB.CELLRATE)
				if(istype(AM, /obj/item))
					var/obj/item/I = AM
					I.update_icon()
				return TRUE
	else
		set_pin_data(IC_OUTPUT, 1, null)
		set_pin_data(IC_OUTPUT, 2, null)
		set_pin_data(IC_OUTPUT, 3, null)
		activate_pin(2)
		push_data()
		return FALSE

/obj/item/integrated_circuit/power/transmitter/large/do_work()
	if(..()) // If the above code succeeds, do this below.
		var/atom/movable/acting_object = get_object()
		if(prob(20))
			var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
			s.set_up(12, 1, src)
			s.start()
			acting_object.visible_message("<span class='warning'>\The [acting_object] создаёт искры!</span>")
		return TRUE

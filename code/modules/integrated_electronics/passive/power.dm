
/obj/item/integrated_circuit/passive/power
	name = "power thingy"
	desc = "Связано с энергией."
	complexity = 5
	category_text = "Энергия - Пассивная"

/obj/item/integrated_circuit/passive/power/proc/make_energy()
	return

// For calculators.
/obj/item/integrated_circuit/passive/power/solar_cell
	name = "tiny photovoltaic cell"
	desc = "Это очень маленькая солнечная батарея, которую обычно используют в калькуляторах."
	extended_desc = "Эта батарея генерирует 1 Вт энергии при оптимальных условиях освещения. При меньшей освещённости количество вырабатываемой энергии уменьшится."
	icon_state = "solar_cell"
	complexity = 8
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/max_power = 30

/obj/item/integrated_circuit/passive/power/solar_cell/make_energy()
	var/turf/T = get_turf(src)
	var/light_amount = T ? T.get_lumcount() : 0
	var/adjusted_power = max(max_power * light_amount, 0)
	adjusted_power = round(adjusted_power, 0.1)
	if(adjusted_power)
		if(assembly)
			assembly.give_power(adjusted_power)

/obj/item/integrated_circuit/passive/power/starter
	name = "starter"
	desc = "Эта миниатюрная схема будет генерировать импульс сразу после включения устройства или при восстановлении питания."
	icon_state = "led"
	complexity = 1
	activators = list("pulse out" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/is_charge = FALSE

/obj/item/integrated_circuit/passive/power/starter/make_energy()
	if(assembly.battery)
		if(assembly.battery.charge)
			if(!is_charge)
				activate_pin(1)
			is_charge = TRUE
		else
			is_charge = FALSE
	else
		is_charge=FALSE
	return FALSE

// For fat machines that need fat power, like drones.
/obj/item/integrated_circuit/passive/power/relay
	name = "tesla power relay"
	desc = "На первый взгляд загадочное устройство, которое подключается к ближайшим устройствам APC по беспроводной сети и получает от них питание."
	w_class = WEIGHT_CLASS_SMALL
	extended_desc = "Сифон поглощает 50 Вт энергии от блока APC, расположенного в том же помещении, пока в нем остаётся заряд. Он всегда будет потреблять энергию \
    из канала питания оборудования."
	icon_state = "power_relay"
	complexity = 7
	spawn_flags = IC_SPAWN_RESEARCH
	var/power_amount = 50


/obj/item/integrated_circuit/passive/power/relay/make_energy()
	if(!assembly)
		return
	var/area/A = get_area(src)
	if(A && A.powered(EQUIP) && assembly.give_power(power_amount))
		A.use_power((power_amount + (power_amount/1.5)), EQUIP)
		// give_power() handles CELLRATE on its own.


// For really fat machines.
/obj/item/integrated_circuit/passive/power/relay/large
	name = "large tesla power relay"
	desc = "На первый взгляд загадочное устройство, которое подключается к ближайшим точкам доступа по беспроводной сети и получает от них питание, теперь доступно в промышленном размере!"
	w_class = WEIGHT_CLASS_BULKY
	extended_desc = "Сифон поглощает 2 кВт энергии от устройства APC, расположенного в том же помещении, пока в нем остаётся заряд. Он всегда будет потреблять энергию \
    из канала питания оборудования."
	icon_state = "power_relay"
	complexity = 15
	spawn_flags = IC_SPAWN_RESEARCH
	power_amount = 1000


//fuel cell
/obj/item/integrated_circuit/passive/power/chemical_cell
	name = "fuel cell"
	desc = "Производит электроэнергию из химических веществ."
	icon_state = "chemical_cell"
	extended_desc = "По сути, это внутренний реактор. Он потребляет и вырабатывает энергию из плазмы, слизистого желе, сварочного топлива, углерода, \
    этанола, питательных веществ и крови в порядке убывания эффективности. Топливо потребляется только в том случае, если аккумулятор способен принять дополнительную энергию. Однако ни одно топливо не может сравниться с кровью живого человека."
	complexity = 4
	inputs = list()
	outputs = list("volume used" = IC_PINTYPE_NUMBER, "self reference" = IC_PINTYPE_SELFREF)
	activators = list("push ref" = IC_PINTYPE_PULSE_IN)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/volume = 60
	var/list/fuel = list(/datum/reagent/toxin/plasma = 50000, /datum/reagent/fuel = 15000, /datum/reagent/carbon = 10000,
						/datum/reagent/consumable/ethanol = 10000, /datum/reagent/consumable/nutriment = 8000)
	var/multi = 1
	var/lfwb =TRUE

/obj/item/integrated_circuit/passive/power/chemical_cell/Initialize(mapload)
	. = ..()
	create_reagents(volume, OPENCONTAINER)

/obj/item/integrated_circuit/passive/power/chemical_cell/interact(mob/user)
	set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
	push_data()
	..()

/obj/item/integrated_circuit/passive/power/chemical_cell/on_reagent_change(changetype)
	set_pin_data(IC_OUTPUT, 1, reagents.total_volume)
	push_data()

/obj/item/integrated_circuit/passive/power/chemical_cell/make_energy()
	if(assembly)
		if(assembly.battery)
			var/bp = 5000
			if(reagents.get_reagent_amount(/datum/reagent/blood)) //only blood is powerful enough to power the station(c)
				var/datum/reagent/blood/B = locate() in reagents.reagent_list
				if(lfwb)
					if(B && B.data["cloneable"])
						var/datum/weakref/donor_ref = B.data["donor"]
						var/mob/donor = donor_ref.resolve()
						if(donor && (donor.stat != DEAD) && (donor.client))
							bp = 500000
				if((assembly.battery.maxcharge-assembly.battery.charge) / GLOB.CELLRATE > bp)
					if(reagents.remove_reagent(/datum/reagent/blood, 1))
						assembly.give_power(bp)
			for(var/I in fuel)
				if((assembly.battery.maxcharge-assembly.battery.charge) / GLOB.CELLRATE > fuel[I])
					if(reagents.remove_reagent(I, 1))
						assembly.give_power(fuel[I]*multi)

/obj/item/integrated_circuit/passive/power/chemical_cell/do_work()
	set_pin_data(IC_OUTPUT, 2, WEAKREF(src))
	push_data()

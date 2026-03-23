/obj/item/integrated_circuit/manipulation/activator
	name = "activator"
	desc = "Circuit which can activate things remotely!"
	icon_state = "pull_claw"
	extended_desc = "This circuit needs a reference to a thing to activate, it also needs to know who is activating said item."
	w_class = WEIGHT_CLASS_SMALL
	size = 3
	cooldown_per_use = 1
	complexity = 10
	inputs = list("target" = IC_PINTYPE_REF, "person" = IC_PINTYPE_REF)
	activators = list("pulse in" = IC_PINTYPE_PULSE_IN,"pulse out" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 50
	ext_cooldown = 1

/obj/item/integrated_circuit/manipulation/activator/do_work(ord)
	var/obj/acting_object = get_pin_data_as_type(IC_INPUT, 1, /obj/)
	var/mob/person = get_pin_data_as_type(IC_INPUT, 2, /mob/)
	acting_object.interact(person)
	activate_pin(1)


/obj/item/integrated_circuit/manipulation/advactivator
	name = "advactivator"
	desc = "Circuit which can UI elements remotely! Works with most machines."
	icon_state = "pull_claw"
	extended_desc = "This circuit needs a reference to activate, as well as action and sometimes params to pass: key - value."
	w_class = WEIGHT_CLASS_SMALL
	size = 3
	cooldown_per_use = 1
	complexity = 10

	inputs = list("target" = IC_PINTYPE_REF, "action" = IC_PINTYPE_STRING, "param_key_1" = IC_PINTYPE_STRING, "param_value_1" = IC_PINTYPE_ANY, "param_key_2" = IC_PINTYPE_STRING, "param_value_2" = IC_PINTYPE_ANY, "param_key_3" = IC_PINTYPE_STRING, "param_value_3" = IC_PINTYPE_ANY, "passkey" = IC_PINTYPE_STRING)
	activators = list(
		"pulse in" = IC_PINTYPE_PULSE_IN,
		"pulse out" = IC_PINTYPE_PULSE_OUT
		)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 50
	ext_cooldown = 1
	var/max_grab = GRAB_PASSIVE
	var/datum/component/ntnet_interface/net

/obj/item/integrated_circuit/manipulation/advactivator/Initialize(mapload)
	. = ..()
	net = LoadComponent(/datum/component/ntnet_interface)
	var/address = net.hardware_id
	net.differentiate_broadcast = FALSE
	desc += "<br>This circuit's NTNet hardware address is: [address]"

/obj/item/integrated_circuit/manipulation/advactivator/do_work(ord)
	var/obj/acting_object = get_pin_data_as_type(IC_INPUT, 1, /obj/)
	var/action = get_pin_data(IC_INPUT, 2)
	var/passkey = get_pin_data(IC_INPUT, 9)
	//var/key = get_pin_data(IC_INPUT, 3)
	//var/value = get_pin_data(IC_INPUT, 4)
	var/params = list(
		"ic_advactivator" = TRUE,
		//"[key]" = value,
	)
	for(var/i=3, i<=7, i+=2)
		var/key = get_pin_data(IC_INPUT, i)
		var/value = get_pin_data(IC_INPUT, i+1)
		if(key && value)
			params["[key]"] = value
	if(acting_object)
		var/datum/ntnet/my_ntnet = SSnetworks.station_network
		var/user = assembly.loc
		var/mob/living/carbon/human/realuser = user //Интегралка может лежать на полу, но если она все же в руках игрока, то это позволит определить кто это
		if(my_ntnet.check_relay_operation(acting_object.z) & my_ntnet.check_relay_operation(assembly.z) & !net.blocked)//Если на станции отключен NTnet то и гост-рольки не смогут тыкать адвактиватором. Увы. Логичное объяснение - NTnet один с сервером на станции. Практическое объяснение - гострольки не должны через камеры бесоебить шлюзы на станции
			if(acting_object.GetComponent(/datum/component/ntnet_interface)) //Шлюзы и стеклянные панели имеют NTnet интерфейс
				if(!passkey) //Если пасскей не введен вовсе и взаимодействие происходит с шлюзом, то ничего не произойдет. Адвактиватор не отработает
					return
				var/obj/machinery/door/target_airlock = acting_object
				if(target_airlock.check_access_list(assembly.access_card.access))
					acting_object.ui_act(action, params) //позволяем  трогать шлюз, если есть доступ
				else
					return
			if(ishuman(user))
				user = realuser.real_name //Станция должна знать своих героев(в данный момент сломана кодировка имени в отправке \u041c\u0430\u0440)
			var/datum/netdata/message = new
			var/location = "[realuser.x], [realuser.y], [realuser.z]"
			message.data = list("message" = "[acting_object] has been activated by [realuser] in [location]")

			if(!acting_object.GetComponent(/datum/component/ntnet_interface))//Проверка istype() на тип шлюза не работает почему-то. Зато на компонент работает.
				acting_object.ui_act(action, params)
			ntnet_send(message)//Используется только в целях логгирования в консоль РД, т.к все отправки записываются в Wirecamp
			activate_pin(2)

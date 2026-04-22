#define IC_MAX_SIZE_BASE		25
#define IC_COMPLEXITY_BASE		75

/obj/item/electronic_assembly
	name = "electronic assembly"
	obj_flags = CAN_BE_HIT | UNIQUE_RENAME
	desc = "Это корпус для сборки небольших электронных устройств."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/assemblies/electronic_setups.dmi'
	icon_state = "setup_small"
	item_flags = NOBLUDGEON
	custom_materials = null		// To be filled later
	datum_flags = DF_USE_TAG
	var/list/assembly_components = list()
	var/list/ckeys_allowed_to_scan = list() // Players who built the circuit can scan it as a ghost.
	var/max_components = IC_MAX_SIZE_BASE
	var/max_complexity = IC_COMPLEXITY_BASE
	var/opened = TRUE
	var/obj/item/stock_parts/cell/battery // Internal cell which most circuits need to work.
	var/cell_type = /obj/item/stock_parts/cell
	var/can_charge = TRUE //Can it be charged in a recharger?
	var/can_fire_equipped = FALSE //Can it fire/throw weapons when the assembly is being held?
	var/charge_sections = 4
	var/charge_tick = FALSE
	var/charge_delay = 4
	var/use_cyborg_cell = TRUE
	var/ext_next_use = 0
	var/atom/collw
	var/obj/item/card/id/access_card
	var/allowed_circuit_action_flags = IC_ACTION_COMBAT | IC_ACTION_LONG_RANGE //which circuit flags are allowed
	var/combat_circuits = 0 //number of combat cicuits in the assembly, used for diagnostic hud
	var/long_range_circuits = 0 //number of long range cicuits in the assembly, used for diagnostic hud
	var/prefered_hud_icon = "hudstat"		// Used by the AR circuit to change the hud icon.
	var/creator // circuit creator if any
	var/static/next_assembly_id = 0
	var/sealed = FALSE

	/// TGUI IntegratedCircuit canvas pan
	var/ie_tgui_screen_x = 0
	var/ie_tgui_screen_y = 0
	var/datum/weakref/ie_gui_examined_circuit
	var/ie_gui_examined_x = 0
	var/ie_gui_examined_y = 0
	/// TGUI: подсветка связи при передаче данных по проводу
	var/ie_tgui_pulse_until = 0
	var/ie_tgui_pulse_output_ref = null
	var/ie_tgui_pulse_input_ref = null
	var/datum/weakref/ie_tgui_pulse_chip_weak

	hud_possible = list(DIAG_STAT_HUD, DIAG_BATT_HUD, DIAG_TRACK_HUD, DIAG_CIRCUIT_HUD) //diagnostic hud overlays
	max_integrity = 50
	pass_flags = 0
	armor = list(MELEE = 50, BULLET = 70, LASER = 70, ENERGY = 100, BOMB = 10, BIO = 100, RAD = 100, FIRE = 0, ACID = 0)
	anchored = FALSE
	var/can_anchor = TRUE
	var/detail_color = COLOR_ASSEMBLY_BLACK
	var/list/color_whitelist = list( //This is just for checking that hacked colors aren't in the save data.
		COLOR_ASSEMBLY_BLACK,
		COLOR_FLOORTILE_GRAY,
		COLOR_ASSEMBLY_BGRAY,
		COLOR_ASSEMBLY_WHITE,
		COLOR_ASSEMBLY_RED,
		COLOR_ASSEMBLY_ORANGE,
		COLOR_ASSEMBLY_BEIGE,
		COLOR_ASSEMBLY_BROWN,
		COLOR_ASSEMBLY_GOLD,
		COLOR_ASSEMBLY_YELLOW,
		COLOR_ASSEMBLY_GURKHA,
		COLOR_ASSEMBLY_LGREEN,
		COLOR_ASSEMBLY_GREEN,
		COLOR_ASSEMBLY_LBLUE,
		COLOR_ASSEMBLY_BLUE,
		COLOR_ASSEMBLY_PURPLE
		)

/obj/item/electronic_assembly/New()
	..()
	src.max_components = round(max_components)
	src.max_complexity = round(max_complexity)

/obj/item/electronic_assembly/GenerateTag()
    tag = "assembly_[next_assembly_id++]"

/obj/item/electronic_assembly/examine(mob/user)
	. = ..()
	if(can_anchor)
		. += "<span class='notice'>Крепежные болты [anchored? "": "могут быть"] <b>затянуты</b> на месте, а панель доступа [opened? "может быть": ""] <b>завинчена</b> на месте.</span>"
	else
		. += "<span class='notice'>Панель доступа [opened? "может быть": ""] <b>завинчена</b> на месте.</span>"

	if((isobserver(user) && ckeys_allowed_to_scan[user.ckey]) || IsAdminGhost(user))
		. += "Вы можете <a href='?src=[REF(src)];ghostscan=1'>просканировать</a> данную схему."

	for(var/obj/item/integrated_circuit/I in assembly_components)
		var/examine_data = I.external_examine(user)
		if(examine_data)
			. += examine_data
	if(opened)
		interact(user)

/obj/item/electronic_assembly/proc/check_interactivity(mob/user)
	if(!istype(user, /mob))
		return
	return user.canUseTopic(src, BE_CLOSE)

/obj/item/electronic_assembly/Bump(atom/AM)
	collw = AM
	.=..()
	if((istype(collw, /obj/machinery/door/airlock) ||  istype(collw, /obj/machinery/door/window)) && (!isnull(access_card)))
		var/obj/machinery/door/D = collw
		if(D.check_access(access_card))
			D.open()

/obj/item/electronic_assembly/Initialize(mapload)
	LAZYSET(custom_materials, /datum/material/iron, round((max_complexity + max_components) * 0.25) * SScircuit.cost_multiplier)
	.=..()
	START_PROCESSING(SScircuit, src)

	//sets up diagnostic hud view
	prepare_huds()
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.all_huds)
		diag_hud.add_to_hud(src)
	diag_hud_set_circuithealth()
	diag_hud_set_circuitcell()
	diag_hud_set_circuitstat()
	diag_hud_set_circuittracking()

	access_card = new /obj/item/card/id(src)

/obj/item/electronic_assembly/Destroy()
	STOP_PROCESSING(SScircuit, src)
	for(var/datum/atom_hud/data/diagnostic/diag_hud in GLOB.all_huds)
		diag_hud.remove_from_hud(src)
	QDEL_NULL(access_card)
	return ..()

/obj/item/electronic_assembly/process()
	handle_idle_power()
	check_pulling()

	//updates diagnostic hud
	diag_hud_set_circuithealth()
	diag_hud_set_circuitcell()

/obj/item/electronic_assembly/proc/handle_idle_power()

	// First we generate power.
	for(var/obj/item/integrated_circuit/passive/power/P in assembly_components)
		P.make_energy()

	// Now spend it.
	for(var/obj/item/integrated_circuit/I in assembly_components)
		if(I.power_draw_idle)
			if(!draw_power(I.power_draw_idle))
				I.power_fail()

/obj/item/electronic_assembly/interact(mob/user, circuit)
	if(user?.client?.prefs?.ie_classic_circuit_ui)
		ie_legacy_ui_interact(user, circuit)
		return
	ui_interact(user, circuit)

/obj/item/electronic_assembly/Topic(href, href_list)
	if(..())
		return TRUE

	if(href_list["ghostscan"])
		if((isobserver(usr) && ckeys_allowed_to_scan[usr.ckey]) || IsAdminGhost(usr))
			if(assembly_components.len)
				var/saved = "На принтерах схем, на которых включена функция клонирования, вы можете использовать приведенный ниже код для клонирования схемы:<br><br><code>[SScircuit.save_electronic_assembly(src)]</code>"
				var/datum/browser/popup = new(usr, "circuit_scan", "Circuit Scan", 500, 600)
				popup.set_content(saved)
				popup.open()
			else
				to_chat(usr, "<span class='warning'>Схема пуста!</span>")
		return

	if(!check_interactivity(usr))
		return

	if(href_list["ie_ui_mode"] == "tgui")
		if(usr.client?.prefs)
			usr.client.prefs.ie_classic_circuit_ui = FALSE
		SStgui.close_uis(src)
		ui_interact(usr, null)
		return

	if(href_list["rename"])
		rename(usr)

	if(href_list["remove_cell"])
		if(!battery)
			to_chat(usr, "<span class='warning'>Здесь нет батарейки, которую нужно извлечь из [src].</span>")
		else
			battery.forceMove(drop_location())
			playsound(src, 'sound/items/Crowbar.ogg', 50, 1)
			to_chat(usr, "<span class='notice'>Вы извлекаете [battery] из источника питания [src].</span>")
			battery = null
			diag_hud_set_circuitstat() //update diagnostic hud

	var/obj/item/integrated_circuit/component

	if(href_list["component"])
		component = locate(href_list["component"]) in assembly_components

		if(!component)
			return


		if(href_list["scan"])
			var/obj/held_item = usr.get_active_held_item()
			if(istype(held_item, /obj/item/integrated_electronics/debugger))
				var/obj/item/integrated_electronics/debugger/D = held_item
				if(D.accepting_refs)
					D.afterattack(component, usr, TRUE)
				else
					to_chat(usr, "<span class='warning'>Сканер ссылок отладчика должен быть включен.</span>")
			else
				to_chat(usr, "<span class='warning'>Для этого вам понадобится отладчик, настроенный в режим ссылок.</span>")

		// Builtin components are not supposed to be removed or rearranged
		if(!component.removable)
			return

		add_allowed_scanner(usr.ckey)

		// Find the position of a first removable component
		var/first_removable_pos = 0
		for(var/i in assembly_components)
			first_removable_pos++
			var/obj/item/integrated_circuit/temp_component = i
			if(temp_component.removable)
				break

		if(href_list["remove"])
			if(try_remove_component(component, usr))
				component = null

		if(href_list["rename_component"])
			component.rename_component(usr)
			if(component.assembly)
				component.assembly.add_allowed_scanner(usr.ckey)

		if(href_list["interact"])
			var/obj/item/I = usr.get_active_held_item()
			if(istype(I))
				I.melee_attack_chain(usr, component)
			else
				component.attack_self(usr)

		// Adjust the position
		if(href_list["change_pos"])
			var/new_pos = max(input(usr,"Введите новое число","Новая позиция") as num,1)

			if(new_pos > assembly_components.len)
				new_pos = assembly_components.len

			if(new_pos < first_removable_pos)
				new_pos = first_removable_pos

			assembly_components.Remove(component)
			assembly_components.Insert(new_pos, component)

	interact(usr, component) // To refresh the UI.

/obj/item/electronic_assembly/pickup(mob/living/user)
	. = ..()
	//update diagnostic hud when picked up, true is used to force the hud to be hidden
	diag_hud_set_circuithealth(TRUE)
	diag_hud_set_circuitcell(TRUE)
	diag_hud_set_circuitstat(TRUE)
	diag_hud_set_circuittracking(TRUE)

/obj/item/electronic_assembly/dropped(mob/user)
	. = ..()
	//update diagnostic hud when dropped
	diag_hud_set_circuithealth()
	diag_hud_set_circuitcell()
	diag_hud_set_circuitstat()
	diag_hud_set_circuittracking()

/obj/item/electronic_assembly/proc/rename()
	var/mob/M = usr
	if(!check_interactivity(M))
		return

	var/input = reject_bad_name(input("Как вы хотите это назвать?", "Переименовать", src.name) as null|text, TRUE)
	if(!check_interactivity(M))
		return
	if(src && input)
		to_chat(M, "<span class='notice'>На корпусе теперь есть наклейка с надписью '[input]'.</span>")
		name = input

/obj/item/electronic_assembly/proc/add_allowed_scanner(ckey)
	ckeys_allowed_to_scan[ckey] = TRUE

/obj/item/electronic_assembly/proc/can_move()
	return FALSE

/obj/item/electronic_assembly/update_icon()
	if(opened)
		icon_state = initial(icon_state) + "-open"
	else
		icon_state = initial(icon_state)
	cut_overlays()
	if(detail_color == COLOR_ASSEMBLY_BLACK) //Black colored overlay looks almost but not exactly like the base sprite, so just cut the overlay and avoid it looking kinda off.
		return
	var/mutable_appearance/detail_overlay = mutable_appearance('icons/obj/assemblies/electronic_setups.dmi', "[icon_state]-color")
	detail_overlay.color = detail_color
	add_overlay(detail_overlay)

/obj/item/electronic_assembly/proc/return_total_complexity()
	var/returnvalue = 0
	for(var/obj/item/integrated_circuit/part in assembly_components)
		returnvalue += part.complexity
	return(returnvalue)

/obj/item/electronic_assembly/proc/return_total_size()
	var/returnvalue = 0
	for(var/obj/item/integrated_circuit/part in assembly_components)
		returnvalue += part.size
	return(returnvalue)

// Returns true if the circuit made it inside.
/obj/item/electronic_assembly/proc/try_add_component(obj/item/integrated_circuit/IC, mob/user)
	if(!opened)
		to_chat(user, "<span class='warning'>Крышка [src] закрыта, внутрь ничего не поместишь.</span>")
		return FALSE

	if(IC.w_class > w_class)
		to_chat(user, "<span class='warning'>[IC] слишком велик, чтобы поместиться в [src].</span>")
		return FALSE
	if(istype(IC, /obj/item/integrated_circuit/manipulation/interacter) && locate(/obj/item/integrated_circuit/manipulation/interacter) in src.assembly_components)
		to_chat(user, "<span class='warning'>Вы не можете вставить две этих детали в один корпус.</span>")
		return FALSE
	var/total_part_size = return_total_size()
	var/total_complexity = return_total_complexity()

	if((total_part_size + IC.size) > max_components)
		to_chat(user, "<span class='warning'>Похоже, вы не можете добавить '[IC]', так как не хватает места.</span>")
		return FALSE
	if((total_complexity + IC.complexity) > max_complexity)
		to_chat(user, "<span class='warning'>Похоже, вы не можете добавить '[IC]', так как эта плата слишком сложна для данного корпуса.</span>")
		return FALSE
	if((allowed_circuit_action_flags & IC.action_flags) != IC.action_flags)
		to_chat(user, "<span class='warning'>Похоже, вы не можете добавить '[IC]', так как данный корпус не подходит под данную плату.</span>")
		return FALSE

	if(!user.transferItemToLoc(IC, src))
		return FALSE

	to_chat(user, "<span class='notice'>Вы вставляете [IC] внутрь [src].</span>")
	playsound(src, 'sound/items/Deconstruct.ogg', 50, 1)
	add_allowed_scanner(user.ckey)
	investigate_log("had [IC]([IC.type]) inserted by [key_name(user)].", INVESTIGATE_CIRCUIT)

	add_component(IC)
	return TRUE


// Actually puts the circuit inside, doesn't perform any checks.
/obj/item/electronic_assembly/proc/add_component(obj/item/integrated_circuit/component)
	component.assembly = src
	component.forceMove(get_object())
	assembly_components |= component

	//increment numbers for diagnostic hud
	if(component.action_flags & IC_ACTION_COMBAT)
		combat_circuits += 1;
	if(component.action_flags & IC_ACTION_LONG_RANGE)
		long_range_circuits += 1;

	//diagnostic hud update
	diag_hud_set_circuitstat()
	diag_hud_set_circuittracking()
	SStgui.update_uis(src)

/obj/item/electronic_assembly/proc/try_remove_component(obj/item/integrated_circuit/IC, mob/user, silent)
	if(!opened)
		if(!silent)
			to_chat(user, "<span class='warning'>Крышка [src] закрыта, поэтому вы не можете повозиться с внутренними компонентами.</span>")
		return FALSE

	if(!IC.removable)
		if(!silent)
			to_chat(user, "<span class='warning'>[src] намертво прикреплен к корпусу.</span>")
		return FALSE

	remove_component(IC)
	if(!silent)
		to_chat(user, "<span class='notice'>Вы достаёте [IC] из корпуса и отсоединяете его.</span>")
		playsound(src, 'sound/items/crowbar.ogg', 50, 1)
		user.put_in_hands(IC)
	add_allowed_scanner(user.ckey)
	investigate_log("had [IC]([IC.type]) removed by [key_name(user)].", INVESTIGATE_CIRCUIT)

	return TRUE

// Actually removes the component, doesn't perform any checks.
/obj/item/electronic_assembly/proc/remove_component(obj/item/integrated_circuit/component)
	component.disconnect_all()
	component.forceMove(drop_location())
	component.assembly = null

	assembly_components -= component

	//decrement numbers for diagnostic hud
	if(component.action_flags & IC_ACTION_COMBAT)
		combat_circuits -= 1;
	if(component.action_flags & IC_ACTION_LONG_RANGE)
		long_range_circuits -= 1;

	//diagnostic hud update
	diag_hud_set_circuitstat()
	diag_hud_set_circuittracking()
	SStgui.update_uis(src)

/obj/item/electronic_assembly/afterattack(atom/target, mob/user, proximity)
	. = ..()
	for(var/obj/item/integrated_circuit/input/S in assembly_components)
		if(S.sense(target,user,proximity))
			visible_message("<span class='notice'> [user] проводит [src] около [target].</span>")


/obj/item/electronic_assembly/screwdriver_act(mob/living/user, obj/item/I)
	if(sealed)
		to_chat(user,"<span class='notice'>Корпус герметичен. Любая попытка вскрыть его силой приведет к его повреждению.</span>")
		return FALSE
	if(..())
		return TRUE
	I.play_tool_sound(src)
	opened = !opened
	to_chat(user, "<span class='notice'>Вы [opened ? "открыли" : "закрыли"] крышку [src].</span>")
	update_icon()
	return TRUE

/obj/item/electronic_assembly/welder_act(mob/living/user, obj/item/I)
	var/type_to_use

	if(!sealed)
		type_to_use = input("Чтобы вы хотели сделать?","[src] type setting") as null|anything in list("починить", "заварить")
	else
		type_to_use = input("Чтобы вы хотели сделать?","[src] type setting") as null|anything in list("починить", "вскрыть")

	switch(type_to_use)
		if("починить")
			if(obj_integrity < max_integrity)
				obj_integrity = min(obj_integrity + 20,max_integrity)
				to_chat(user,"<span class='notice'>Вы устраняете вмятины и царапины на корпусе.</span>")
				to_chat(user, "<span class='notice'>Прочность: [obj_integrity] / [max_integrity]</span>")
				return TRUE

			else
				to_chat(user,"<span class='notice'>Корпус уже находится в идеальном состоянии.</span>")
				return FALSE

		if("заварить")
			if(!opened)
				if(I.use_tool(src, user, 50, volume=100, amount=3))
					to_chat(user,"<span class='notice'>Вы завариваете корпус, делая его невозможным для вскрытия.</span>")
					sealed = TRUE
					return TRUE

			else
				to_chat(user,"<span class='notice'>Прежде чем заварить корпус, его нужно закрыть!</span>")
				return FALSE

		if("вскрыть")
			to_chat(user,"<span class='notice'>Вы начинаете осторожно вскрывать корпус...</span>")
			if(I.use_tool(src, user, 50, volume=250, amount=3))
				for(var/obj/item/integrated_circuit/IC in assembly_components)
					if(prob(50))
						IC.disconnect_all()

				to_chat(user,"<span class='notice'>Вы вскрыли корпус.</span>")
				sealed = FALSE
				return TRUE

/obj/item/electronic_assembly/attackby(obj/item/I, mob/living/user)
	if(can_anchor && default_unfasten_wrench(user, I, 20))
		return

	if(istype(I, /obj/item/integrated_circuit))
		if(!user.canUnEquip(I))
			return FALSE
		if(try_add_component(I, user))
			return TRUE
		else
			for(var/obj/item/integrated_circuit/input/S in assembly_components)
				S.attackby_react(I,user,user.a_intent)
			return ..()
	else if(I.tool_behaviour == TOOL_MULTITOOL || istype(I, /obj/item/integrated_electronics/wirer) || istype(I, /obj/item/integrated_electronics/debugger))
		if(opened)
			interact(user)
			return TRUE
		else
			to_chat(user, "<span class='warning'>Крышка [src] закрыта, поэтому вы не можете повозиться с внутренними компонентами.</span>")
			for(var/obj/item/integrated_circuit/input/S in assembly_components)
				S.attackby_react(I,user,user.a_intent)
			return ..()

	else if(istype(I, /obj/item/stock_parts/cell))
		if(!opened)
			to_chat(user, "<span class='warning'>Люк [src] закрыт, поэтому вы не можете получить доступ к источнику питания [src].</span>")
			for(var/obj/item/integrated_circuit/input/S in assembly_components)
				S.attackby_react(I,user,user.a_intent)
			return ..()
		if(battery)
			to_chat(user, "<span class='warning'>[src] уже имеет установленную [battery]. Сначала извлеките её, если хотите заменить.</span>")
			for(var/obj/item/integrated_circuit/input/S in assembly_components)
				S.attackby_react(I,user,user.a_intent)
			return ..()
		I.forceMove(src)
		battery = I
		diag_hud_set_circuitstat() //update diagnostic hud
		playsound(get_turf(src), 'sound/items/Deconstruct.ogg', 50, 1)
		to_chat(user, "<span class='notice'>Вы вставляете [I] в разъем питания [src].</span>")
		to_chat(user, "<span class='info'>Питание не считается «компонентом» схемы: в окне редактора в счётчике — только напечатанные на интегральном принтере микросхемы.</span>")
		SStgui.update_uis(src)
		return TRUE

	else if(istype(I, /obj/item/integrated_electronics/detailer))
		var/obj/item/integrated_electronics/detailer/D = I
		detail_color = D.detail_color
		update_icon()

	else
		if(user.a_intent != INTENT_HELP)
			return ..()
		var/list/input_selection = list()
		//Check all the components asking for an input
		for(var/obj/item/integrated_circuit/input in assembly_components)
			if((input.demands_object_input && opened) || (input.demands_object_input && input.can_input_object_when_closed))
				var/i = 0
				//Check if there is another component with the same name and append a number for identification
				for(var/s in input_selection)
					var/obj/item/integrated_circuit/s_circuit = input_selection[s] //The for-loop iterates the keys of the associative list.
					if(s_circuit.name == input.name && s_circuit.displayed_name == input.displayed_name && s_circuit != input)
						i++
				var/disp_name= "[input.displayed_name] \[[input]\]"
				if(i)
					disp_name += " ([i+1])"
				//Associative lists prevent me from needing another list and using a Find proc
				input_selection[disp_name] = input

		var/obj/item/integrated_circuit/choice
		if(input_selection)
			if(input_selection.len == 1)
				choice = input_selection[input_selection[1]]
			else
				var/selection = input(user, "Куда вы хотите вставить этот элемент?", "Взаимодействие") as null|anything in input_selection
				if(!check_interactivity(user))
					return ..()
				if(selection)
					choice = input_selection[selection]
			if(choice)
				choice.additem(I, user)
		for(var/obj/item/integrated_circuit/input/S in assembly_components)
			S.attackby_react(I,user,user.a_intent)
		return ..()


/obj/item/electronic_assembly/attack_self(mob/user)
	set waitfor = FALSE
	if(!check_interactivity(user))
		return
	if(opened)
		interact(user)

	var/list/input_selection = list()
	//Check all the components asking for an input
	for(var/obj/item/integrated_circuit/input/input in assembly_components)
		if(input.can_be_asked_input)
			var/i = 0
			//Check if there is another component with the same name and append a number for identification
			for(var/s in input_selection)
				var/obj/item/integrated_circuit/s_circuit = input_selection[s] //The for-loop iterates the keys of an associative list.
				if(s_circuit.name == input.name && s_circuit.displayed_name == input.displayed_name && s_circuit != input)
					i++
			var/disp_name= "[input.displayed_name] \[[input]\]"
			if(i)
				disp_name += " ([i+1])"
			//Associative lists prevent me from needing another list and using a Find proc
			input_selection[disp_name] = input

	var/obj/item/integrated_circuit/input/choice


	if(input_selection)
		if(input_selection.len ==1)
			choice = input_selection[input_selection[1]]
		else
			var/selection = input(user, "С чем вы хотите взаимодействовать?", "Взаимодействие") as null|anything in input_selection
			if(!check_interactivity(user))
				return
			if(selection)
				choice = input_selection[selection]

	if(choice)
		choice.ask_for_input(user)

/obj/item/electronic_assembly/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/I in src)
		var/atom/movable/AM = I
		AM.emp_act(severity)

// Returns true if power was successfully drawn.
/obj/item/electronic_assembly/proc/draw_power(amount)
	if(battery && battery.use(amount * GLOB.CELLRATE))
		return TRUE
	return FALSE

// Ditto for giving.
/obj/item/electronic_assembly/proc/give_power(amount)
	if(battery && battery.give(amount * GLOB.CELLRATE))
		return TRUE
	return FALSE

/obj/item/electronic_assembly/Moved(oldLoc, dir)
	. = ..()
	for(var/I in assembly_components)
		var/obj/item/integrated_circuit/IC = I
		IC.ext_moved(oldLoc, dir)
	if(light) //Update lighting objects (From light circuits).
		update_light()

/obj/item/electronic_assembly/stop_pulling()
	for(var/I in assembly_components)
		var/obj/item/integrated_circuit/IC = I
		IC.stop_pulling()
	..()


// Returns the object that is supposed to be used in attack messages, location checks, etc.
// Override in children for special behavior.
/obj/item/electronic_assembly/proc/get_object()
	return src

// Returns the location to be used for dropping items.
// Same as the regular drop_location(), but with checks being run on acting_object if necessary.
/obj/item/integrated_circuit/drop_location()
	var/atom/movable/acting_object = get_object()

	// plz no infinite loops
	if(acting_object == src)
		return ..()

	return acting_object.drop_location()

/obj/item/electronic_assembly/attack_tk(mob/user)
	if(anchored)
		return
	..()

/obj/item/electronic_assembly/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(anchored)
		attack_self(user)
		return
	..()

/obj/item/electronic_assembly/default //The /default electronic_assemblys are to allow the introduction of the new naming scheme without breaking old saves.
	name = "type-a electronic assembly"

/obj/item/electronic_assembly/calc
	name = "type-b electronic assembly"
	icon_state = "setup_small_calc"
	desc = "Это корпус для сборки небольших электронных устройств. Он напоминает карманный калькулятор."

/obj/item/electronic_assembly/clam
	name = "type-c electronic assembly"
	icon_state = "setup_small_clam"
	desc = "Это корпус для сборки небольших электронных устройств. Данная модель имеет конструкцию в виде раскладушки."

/obj/item/electronic_assembly/simple
	name = "type-d electronic assembly"
	icon_state = "setup_small_simple"
	desc = "Это корпус для сборки небольших электронных устройств. У него простая конструкция."

/obj/item/electronic_assembly/hook
	name = "type-e electronic assembly"
	icon_state = "setup_small_hook"
	desc = "Это чехол для сборки небольших электронных устройств. Похоже, что у него есть зажим для ремня, но он носит чисто декоративный характер."

/obj/item/electronic_assembly/pda
	name = "type-f electronic assembly"
	icon_state = "setup_small_pda"
	desc = "Это корпус для сборки небольших электронных устройств. Он напоминает ПДА."
	slot_flags = ITEM_SLOT_ID | ITEM_SLOT_BELT

/obj/item/electronic_assembly/dildo
	name = "type-g electronic assembly"
	icon_state = "setup_dildo_medium"
	desc = "Это корпус для сборки небольших электронных устройств. У этого корпуса фаллическая форма."

/obj/item/electronic_assembly/small
	name = "electronic device"
	icon_state = "setup_device"
	desc = "Это корпус для сборки миниатюрных электронных устройств."
	w_class = WEIGHT_CLASS_TINY
	max_components = IC_MAX_SIZE_BASE / 2
	max_complexity = IC_COMPLEXITY_BASE / 2

/obj/item/electronic_assembly/small/default
	name = "type-a electronic device"

/obj/item/electronic_assembly/small/cylinder
	name = "type-b electronic device"
	icon_state = "setup_device_cylinder"
	desc = "Это корпус для сборки миниатюрных электронных устройств. Данная модель имеет цилиндрическую форму."

/obj/item/electronic_assembly/small/scanner
	name = "type-c electronic device"
	icon_state = "setup_device_scanner"
	desc = "Это корпус для сборки миниатюрных электронных устройств. У него дизайн, напоминающий сканер."

/obj/item/electronic_assembly/small/hook
	name = "type-d electronic device"
	icon_state = "setup_device_hook"
	desc = "Это корпус для сборки миниатюрных электронных устройств. Похоже, что у него есть зажим для ремня, но он носит чисто декоративный характер."

/obj/item/electronic_assembly/small/box
	name = "type-e electronic device"
	icon_state = "setup_device_box"
	desc = "Это корпус для сборки миниатюрных электронных устройств. У него прямоугольная форма."

/obj/item/electronic_assembly/small/dildo
	name = "type-f electronic device"
	icon_state = "setup_dildo_small"
	desc = "Это корпус для сборки миниатюрных электронных устройств. У этого корпуса фаллическая форма."

/obj/item/electronic_assembly/medium
	name = "electronic mechanism"
	icon_state = "setup_medium"
	desc = "Это корпус для сборки электроники средних размеров."
	w_class = WEIGHT_CLASS_NORMAL
	max_components = IC_MAX_SIZE_BASE * 2
	max_complexity = IC_COMPLEXITY_BASE * 2

/obj/item/electronic_assembly/medium/default
	name = "type-a electronic mechanism"

/obj/item/electronic_assembly/medium/box
	name = "type-b electronic mechanism"
	icon_state = "setup_medium_box"
	desc = "Это корпус для сборки электроники средних размеров. У него прямоугольная форма."

/obj/item/electronic_assembly/medium/clam
	name = "type-c electronic mechanism"
	icon_state = "setup_medium_clam"
	desc = "Это корпус для сборки электроники средних размеров. Данная модель имеет конструкцию в виде раскладушки."

/obj/item/electronic_assembly/medium/medical
	name = "type-d electronic mechanism"
	icon_state = "setup_medium_med"
	desc = "Это корпус для сборки электронных устройств средних размеров. Он напоминает какой-то медицинский прибор."

/obj/item/electronic_assembly/medium/gun
	name = "type-e electronic mechanism"
	icon_state = "setup_medium_gun"
	item_state = "circuitgun"
	desc = "Это корпус для сборки электронных устройств средних размеров. Он напоминает пистолет или, если смотреть на вещи с оптимизмом, какой-то инструмент. Пока пользователь держит его в руках, он может стрелять и бросать предметы."
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	can_fire_equipped = TRUE

/obj/item/electronic_assembly/medium/radio
	name = "type-f electronic mechanism"
	icon_state = "setup_medium_radio"
	desc = "Это корпус для сборки электроники средних размеров. Он напоминает старое радио."

/obj/item/electronic_assembly/medium/dildo
	name = "type-g electronic mechanism"
	icon_state = "setup_dildo_large"
	desc = "Это корпус для сборки электроники средних размеров. У этого корпуса фаллическая форма."


/obj/item/electronic_assembly/large
	name = "electronic machine"
	icon_state = "setup_large"
	desc = "Это корпус для сборки крупных электронных устройств."
	w_class = WEIGHT_CLASS_BULKY
	max_components = IC_MAX_SIZE_BASE * 4
	max_complexity = IC_COMPLEXITY_BASE * 4

/obj/item/electronic_assembly/large/default
	name = "type-a electronic machine"

/obj/item/electronic_assembly/large/scope
	name = "type-b electronic machine"
	icon_state = "setup_large_scope"
	desc = "Это корпус для сборки крупных электронных устройств. Он напоминает осциллограф."

/obj/item/electronic_assembly/large/terminal
	name = "type-c electronic machine"
	icon_state = "setup_large_terminal"
	desc = "Это корпус для сборки крупных электронных устройств. Он напоминает компьютерный терминал."

/obj/item/electronic_assembly/large/arm
	name = "type-d electronic machine"
	icon_state = "setup_large_arm"
	desc = "Это корпус для сборки крупных электронных устройств. Он напоминает манипулятор."

/obj/item/electronic_assembly/large/tall
	name = "type-e electronic machine"
	icon_state = "setup_large_tall"
	desc = "Это корпус для сборки крупных электронных устройств. У этой модели высокая конструкция."

/obj/item/electronic_assembly/large/industrial
	name = "type-f electronic machine"
	icon_state = "setup_large_industrial"
	desc = "Это корпус для сборки крупных электронных устройств. Он напоминает какое-то промышленное оборудование."

/obj/item/electronic_assembly/drone
	name = "electronic drone"
	icon_state = "setup_drone"
	desc = "Это корпус для сборки мобильной электроники."
	w_class = WEIGHT_CLASS_NORMAL
	max_components = IC_MAX_SIZE_BASE * 3
	max_complexity = IC_COMPLEXITY_BASE * 3
	allowed_circuit_action_flags = IC_ACTION_MOVEMENT | IC_ACTION_COMBAT | IC_ACTION_LONG_RANGE
	can_anchor = FALSE

/obj/item/electronic_assembly/drone/can_move()
	return TRUE

/obj/item/electronic_assembly/drone/default
	name = "type-a electronic drone"

/obj/item/electronic_assembly/drone/arms
	name = "type-b electronic drone"
	icon_state = "setup_drone_arms"
	desc = "Это корпус для сборки мобильной электроники. Этот корпус вооружён и опасен."

/obj/item/electronic_assembly/drone/secbot
	name = "type-c electronic drone"
	icon_state = "setup_drone_secbot"
	desc = "Это корпус для сборки мобильной электроники. Он похож на Бипски."

/obj/item/electronic_assembly/drone/medbot
	name = "type-d electronic drone"
	icon_state = "setup_drone_medbot"
	desc = "Это корпус для сборки мобильной электроники. Он похож на Medibot."

/obj/item/electronic_assembly/drone/genbot
	name = "type-e electronic drone"
	icon_state = "setup_drone_genbot"
	desc = "Это корпус для сборки мобильной электроники. У него универсальный дизайн в виде робота."

/obj/item/electronic_assembly/drone/android
	name = "type-f electronic drone"
	icon_state = "setup_drone_android"
	desc = "Это корпус для мобильной электроники. У этого корпуса дизайн в виде гуманоида."

/obj/item/electronic_assembly/wallmount
	name = "wall-mounted electronic assembly"
	icon_state = "setup_wallmount_medium"
	desc = "Это корпус для сборки электронных устройств средних размеров. Он имеет магнитную заднюю панель, благодаря которой его можно прикрепить к стене, но для надежной фиксации все равно потребуется затянуть крепежные болты."
	w_class = WEIGHT_CLASS_NORMAL
	max_components = IC_MAX_SIZE_BASE * 2
	max_complexity = IC_COMPLEXITY_BASE * 2

/obj/item/electronic_assembly/wallmount/heavy
	name = "heavy wall-mounted electronic assembly"
	icon_state = "setup_wallmount_large"
	desc = "Это корпус для установки крупных электронных устройств. Он имеет магнитную заднюю панель, благодаря которой его можно прикрепить к стене, но для надежной фиксации все равно потребуется затянуть крепежные болты."
	w_class = WEIGHT_CLASS_BULKY
	max_components = IC_MAX_SIZE_BASE * 4
	max_complexity = IC_COMPLEXITY_BASE * 4

/obj/item/electronic_assembly/wallmount/light
	name = "light wall-mounted electronic assembly"
	icon_state = "setup_wallmount_small"
	desc = "Это корпус для сборки небольших электронных устройств. Он имеет магнитную заднюю панель, благодаря которой его можно прикрепить к стене, но для надежной фиксации все равно потребуется затянуть крепежные болты."
	w_class = WEIGHT_CLASS_SMALL
	max_components = IC_MAX_SIZE_BASE
	max_complexity = IC_COMPLEXITY_BASE

/obj/item/electronic_assembly/wallmount/tiny
	name = "tiny wall-mounted electronic assembly"
	icon_state = "setup_wallmount_tiny"
	desc = "Это корпус для сборки миниатюрных электронных устройств. Он имеет магнитную заднюю панель, благодаря которой его можно прикрепить к стене, но для надежной фиксации все равно потребуется закрутить крепежные болты."
	w_class = WEIGHT_CLASS_TINY
	max_components = IC_MAX_SIZE_BASE / 2
	max_complexity = IC_COMPLEXITY_BASE / 2

/obj/item/electronic_assembly/wallmount/proc/mount_assembly(turf/on_wall, mob/user) //Yeah, this is admittedly just an abridged and kitbashed version of the wallframe attach procs.
	if(get_dist(on_wall,user)>1)
		return
	var/ndir = get_dir(on_wall, user)
	if(!(ndir in GLOB.cardinals))
		return
	var/turf/T = get_turf(user)
	if(!isfloorturf(T))
		to_chat(user, "<span class='warning'>Вы не можете разместить [src] в этом месте!</span>")
		return
	if(gotwallitem(T, ndir))
		to_chat(user, "<span class='warning'>На этой стене уже висит что-то!</span>")
		return
	playsound(src.loc, 'sound/machines/click.ogg', 75, 1)
	user.visible_message("[user.name] прикрепляет [src] к стене.",
		"<span class='notice'>Вы прикрепляете [src] к стене.</span>",
		"<span class='italics'>Вы слышите щёлчок.</span>")
	user.dropItemToGround(src)
	switch(ndir)
		if(NORTH)
			pixel_y = -31
		if(SOUTH)
			pixel_y = 31
		if(EAST)
			pixel_x = -31
		if(WEST)
			pixel_x = 31
	plane = ABOVE_WALL_PLANE

/obj/item/electronic_assembly/wallmount/Moved(atom/OldLoc, Dir, Forced = FALSE) //reset the plane if moved off the wall.
	. = ..()
	plane = GAME_PLANE

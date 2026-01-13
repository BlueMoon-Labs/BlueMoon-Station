/obj/machinery/rnd/production/circuit_imprinter
	name = "circuit imprinter"
	desc = "Производит электронные платы для сбора машинерии."
	icon_state = "circuit_imprinter"
	circuit = /obj/item/circuitboard/machine/circuit_imprinter
	categories = list(
								"AI Modules",
								"Computer Boards",
								"Teleportation Machinery",
								"Medical Machinery",
								"Engineering Machinery",
								"Exosuit Modules",
								"Hydroponics Machinery",
								"Subspace Telecomms",
								"Research Machinery",
								"Misc. Machinery",
								"Computer Parts"
								)
	production_animation = "circuit_imprinter_ani"
	allowed_buildtypes = IMPRINTER

/obj/machinery/rnd/production/circuit_imprinter/disconnect_console()
	linked_console.linked_imprinter = null
	..()

/obj/machinery/rnd/production/circuit_imprinter/AfterMaterialInsert() //doesnt use have an animation like lathes do
	return

/////// BLUEMOON ADD хакнутый принтер для печатки вещей, требующих код, в любом месте.
/obj/machinery/rnd/production/circuit_imprinter/hacked
	name = "hacked imprinter"
	desc = "Производит электронные платы для сбора машинерии. Конкретно этот тип принтеров запрещён к использованию во многих корпорациях с делением власти между множеством отделов.."
	circuit = /obj/item/circuitboard/machine/circuit_imprinter/hacked
	requires_console = 0

/obj/machinery/rnd/production/circuit_imprinter/hacked/design_menu_entry(datum/design/D, coeff) // Это необходимо для обхода ограничения по коду у обычных production машин
	if(!istype(D))
		return
	if(!coeff)
		coeff = print_cost_coeff
	if(!efficient_with(D.build_path))
		coeff = 1
	var/list/l = list()
	var/temp_material
	var/c = 50
	var/t
	var/all_materials = D.materials + D.reagents_list
	for(var/M in all_materials)
		t = check_mat(D, M)
		temp_material += " | "
		if (t < 1)
			temp_material += "<span class='bad'>[all_materials[M] * coeff] [CallMaterialName_RuGenitive(M)]</span>"
		else
			temp_material += " [all_materials[M] * coeff] [CallMaterialName_RuGenitive(M)]"
		c = min(c,t)

	var/clearance = !(obj_flags & EMAGGED) && (offstation_security_levels || is_station_level(z))
	var/sec_text = ""
	if(clearance && (D.min_security_level > SEC_LEVEL_GREEN || D.max_security_level < SEC_LEVEL_DELTA))
		sec_text = " (При уровнях тревоги: "
		for(var/n in D.min_security_level to D.max_security_level)
			sec_text += NUM2SECLEVEL(n)
			if(n + 1 <= D.max_security_level)
				sec_text += ", "
		sec_text += ")"

	clearance = !clearance || ISINRANGE(GLOB.security_level, D.min_security_level, D.max_security_level)
	if (c >= 1 && clearance)
		l += "<A href='?src=[REF(src)];build=[D.id];amount=1'>[D.name]</A>[RDSCREEN_NOBREAK]"
		if(c >= 5)
			l += "<A href='?src=[REF(src)];build=[D.id];amount=5'>x5</A>[RDSCREEN_NOBREAK]"
		if(c >= 10)
			l += "<A href='?src=[REF(src)];build=[D.id];amount=10'>x10</A>[RDSCREEN_NOBREAK]"
		//SPLURT EDIT: Print x30 stock parts at once
		if(c >= 30 && selected_category == "Stock Parts")
			l += "<A href='?src=[REF(src)];build=[D.id];amount=30'>x30</A>[RDSCREEN_NOBREAK]"
		l += "[temp_material][sec_text][RDSCREEN_NOBREAK]"
	else
		l += "<span class='linkOff'>[D.name]</span>[temp_material][sec_text][RDSCREEN_NOBREAK]"
	l += ""
	return l

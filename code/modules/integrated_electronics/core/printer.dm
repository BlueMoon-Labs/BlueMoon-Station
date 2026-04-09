#define MAX_CIRCUIT_CLONE_TIME 3 MINUTES //circuit slow-clones can only take up this amount of time to complete

/obj/item/integrated_circuit_printer
	name = "integrated circuit printer"
	desc = "Устройство, которое можно назвать \"почти\" портативным, предназначенное для печати крошечных модульных схем из металла."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "circuit_printer"
	w_class = WEIGHT_CLASS_BULKY
	var/upgraded = FALSE		// When hit with an upgrade disk, will turn true, allowing it to print the higher tier circuits.
	var/can_clone = TRUE		// Allows the printer to clone circuits, either instantly or over time depending on upgrade. Set to FALSE to disable entirely.
	var/fast_clone = FALSE		// If this is false, then cloning will take an amount of deciseconds equal to the metal cost divided by 100.
	var/debug = FALSE			// If it's upgraded and can clone, even without config settings.
	var/current_category = null
	var/cloning = FALSE			// If the printer is currently creating a circuit
	var/recycling = FALSE		// If an assembly is being emptied into this printer
	var/list/program			// Currently loaded save, in form of list

/obj/item/integrated_circuit_printer/proc/check_interactivity(mob/user)
	return user.canUseTopic(src, BE_CLOSE)

/obj/item/integrated_circuit_printer/upgraded
	upgraded = TRUE
	can_clone = TRUE
	fast_clone = TRUE

/obj/item/integrated_circuit_printer/debug //translation: "integrated_circuit_printer/local_server"
	name = "debug circuit printer"
	debug = TRUE
	upgraded = TRUE
	can_clone = TRUE
	fast_clone = TRUE
	w_class = WEIGHT_CLASS_TINY

/obj/item/integrated_circuit_printer/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/material_container, list(/datum/material/iron), MINERAL_MATERIAL_AMOUNT * 25, TRUE, list(/obj/item/stack, /obj/item/integrated_circuit, /obj/item/electronic_assembly))

/obj/item/integrated_circuit_printer/proc/print_program(mob/user)
	if(!cloning)
		return

	visible_message("<span class='notice'>[src] завершил печать корпуса.</span>")
	playsound(src, 'sound/items/poster_being_created.ogg', 50, TRUE)
	var/obj/item/electronic_assembly/assembly = SScircuit.load_electronic_assembly(get_turf(src), program)
	log_admin("INTEGRAL BITCH [user.ckey] завершил печать программы на [src]. Созданная сборка: [assembly], Программа: [program]")
	assembly.creator = key_name(user)
	assembly.investigate_log("was printed by [assembly.creator].", INVESTIGATE_CIRCUIT)
	cloning = FALSE

/obj/item/integrated_circuit_printer/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/disk/integrated_circuit/upgrade/advanced))
		if(upgraded)
			to_chat(user, "<span class='warning'>[src] уже имеет данное улучшение. </span>")
			return TRUE
		to_chat(user, "<span class='notice'>Вы вставляете [O] в [src]. </span>")
		upgraded = TRUE
		return TRUE

	if(istype(O, /obj/item/disk/integrated_circuit/upgrade/clone))
		if(fast_clone)
			to_chat(user, "<span class='warning'>[src] уже имеет данное улучшение. </span>")
			return TRUE
		to_chat(user, "<span class='notice'>Вы вставляете [O] в [src]. Теперь клонирование схем будет происходить мгновенно. </span>")
		fast_clone = TRUE
		return TRUE

	if(istype(O, /obj/item/electronic_assembly))
		var/obj/item/electronic_assembly/EA = O //microtransactions not included
		if(EA.assembly_components.len)
			if(recycling)
				return
			if(!EA.opened)
				to_chat(user, "<span class='warning'>Вы не можете достать до компонентов [EA], чтобы достать их!</span>")
				return
			if(EA.battery)
				to_chat(user, "<span class='warning'>Достаньте батарейку [EA] сначала!</span>")
				return
			for(var/V in EA.assembly_components)
				var/obj/item/integrated_circuit/IC = V
				if(!IC.removable)
					to_chat(user, "<span class='warning'>В корпусе [EA] имеются неизвлекаемые компоненты, что не позволяет его опорожнить.</span>")
					return
			to_chat(user, "<span class='notice'>Вы начинаете перерабатывать компоненты [EA]...</span>")
			playsound(src, 'sound/items/electronic_assembly_emptying.ogg', 50, TRUE)
			if(!do_after(user, 30, target = src) || recycling) //short channel so you don't accidentally start emptying out a complex assembly
				return
			recycling = TRUE
			var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
			for(var/V in EA.assembly_components)
				var/obj/item/integrated_circuit/IC = V
				if(!mats.has_space(mats.get_item_material_amount(IC)))
					to_chat(user, "<span class='notice'>[src] не может хранить больше материалов!</span>")
					break
				if(!do_after(user, 5, target = user))
					recycling = FALSE
					return
				playsound(src, 'sound/items/crowbar.ogg', 50, TRUE)
				if(EA.try_remove_component(IC, user, TRUE))
					mats.user_insert(IC, user)
			to_chat(user, "<span class='notice'>Вы переработали все компоненты[EA.assembly_components.len ? ", которые могли " : " "]из [EA]!</span>")
			playsound(src, 'sound/items/electronic_assembly_empty.ogg', 50, TRUE)
			recycling = FALSE
			return TRUE

	return ..()

/obj/item/integrated_circuit_printer/attack_self(mob/living/carbon/human/user)
	var/user_job = user.mind.assigned_role
	message_admins("INTEGRAL BITCH [user.ckey] взаимодействует с [src].")
	log_admin("INTEGRAL BITCH [user.ckey] взаимодействует с [src].")
	if(upgraded)
		if(user_job == "Roboticist" || user_job == "Research Director" || user_job == "Scientist" || user_job == "Expeditor" || user.mind?.has_antag_datum(/datum/antagonist))
			interact(user)
			return
		else
			to_chat(user, "<span class='warning'>Улучшения сделали этот принтер сложным и непонятным для вас!")
			return
	interact(user)

/obj/item/integrated_circuit_printer/interact(mob/user)
	if(!(in_range(src, user) || issilicon(user)))
		return

	var/client/client = user.client
	if (CONFIG_GET(flag/use_exp_tracking) && client && client.get_exp_living(TRUE) < 60 HOURS) // Player with less than 60 hours playtime is using this machine.
		if(client.next_circuit_grief_warning < world.time)
			var/turf/T = get_turf(src)
			client.next_circuit_grief_warning = world.time + 15 MINUTES // Wait 15 minutes before alerting admins again
			message_antigrif("New player [ADMIN_LOOKUPFLW(user)] has touched \a [src] at [ADMIN_VERBOSEJMP(T)].")
			client.touched_circuit = TRUE

	if(isnull(current_category))
		current_category = SScircuit.circuit_fabricator_recipe_list[1]

	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

	//Preparing the browser
	var/datum/browser/popup = new(user, "printernew", "Integrated Circuit Printer", 800, 630) // Set up the popup browser window

	var/HTML = "<center><h2>Принтер для печати интегральных схем</h2></center><br>"
	if(debug)
		HTML += "<center><h3>DEBUG PRINTER -- Бесконечные материалы. Клонирование доступно.</h3></center>"
	else
		HTML += "Металл: [materials.total_amount]/[materials.max_amount].<br><br>"

	if(CONFIG_GET(flag/ic_printing) || debug)
		HTML += "Клонирование сборок: [can_clone ? (fast_clone ? "Мгновенно" : "Доступно") : "Недоступно"].<br>"

	HTML += "Доступные платы: [upgraded || debug ? "Продвинутые":"Обычные"]."
	if(!upgraded)
		HTML += "<br>Зачеркнутые схемы означают, что принтер не имеет достаточных улучшений для создания данной схемы."

	HTML += "<hr>"
	if((can_clone && CONFIG_GET(flag/ic_printing)) || debug)
		HTML += "Здесь вы можете загрузить код вашей сборки.<br>"
		if(!cloning)
			HTML += " <A href='?src=[REF(src)];print=load'>Загрузить программу</a> "
		else
			HTML += "Загрузить программу"
		if(!program)
			HTML += " [fast_clone ? "Распечатать сборку" : "Начать печать сборки"]"
		else if(cloning)
			HTML += " <A href='?src=[REF(src)];print=cancel'>Отменить печать</a>"
		else
			HTML += " <A href='?src=[REF(src)];print=print'>[fast_clone ? "Распечатать сборку" : "Начать печать сборки"]</a>"

		HTML += "<br><hr>"
	HTML += "Categories:"
	for(var/category in SScircuit.circuit_fabricator_recipe_list)
		if(category != current_category)
			HTML += " <a href='?src=[REF(src)];category=[category]'>[category]</a> "
		else // Bold the button if it's already selected.
			HTML += " <b>[category]</b> "
	HTML += "<hr>"
	HTML += "<center><h4>[current_category]</h4></center>"

	var/list/current_list = SScircuit.circuit_fabricator_recipe_list[current_category]
	for(var/path in current_list)
		var/obj/O = path
		var/can_build = TRUE
		if(ispath(path, /obj/item/integrated_circuit))
			var/obj/item/integrated_circuit/IC = path
			if((initial(IC.spawn_flags) & IC_SPAWN_RESEARCH) && (!(initial(IC.spawn_flags) & IC_SPAWN_DEFAULT)) && !upgraded)
				can_build = FALSE
		if(can_build)
			HTML += "<a href='?src=[REF(src)];build=[path]'>[initial(O.name)]</a>: [initial(O.desc)]<br>"
		else
			HTML += "<s>[initial(O.name)]</s>: [initial(O.desc)]<br>"

	popup.set_content(HTML)
	popup.open()

/obj/item/integrated_circuit_printer/Topic(href, href_list)
	if(!check_interactivity(usr))
		return
	if(..())
		return TRUE
	add_fingerprint(usr)

	if(href_list["category"])
		current_category = href_list["category"]

	if(href_list["build"])
		var/build_type = text2path(href_list["build"])
		if(!build_type || !ispath(build_type))
			return TRUE

		var/cost = 400
		if(ispath(build_type, /obj/item/electronic_assembly))
			var/obj/item/electronic_assembly/E = SScircuit.cached_assemblies[build_type]
			cost = E.custom_materials[SSmaterials.GetMaterialRef(/datum/material/iron)]
		else if(ispath(build_type, /obj/item/integrated_circuit))
			var/obj/item/integrated_circuit/IC = SScircuit.cached_components[build_type]
			cost = IC.custom_materials[SSmaterials.GetMaterialRef(/datum/material/iron)]
		else if(!(build_type in SScircuit.circuit_fabricator_recipe_list["Tools"]))
			return

		var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

		if(!debug && !materials.use_amount_mat(cost, /datum/material/iron))
			to_chat(usr, "<span class='warning'>Вам нужно [cost] металла, чтобы создать это!</span>")
			return TRUE

		var/obj/item/built = new build_type(drop_location())
		usr.put_in_hands(built)

		if(istype(built, /obj/item/electronic_assembly))
			var/obj/item/electronic_assembly/E = built
			E.creator = key_name(usr)
			E.opened = TRUE
			E.update_icon()
			//reupdate diagnostic hud because it was put_in_hands() and not pickup()'ed
			E.diag_hud_set_circuithealth()
			E.diag_hud_set_circuitcell()
			E.diag_hud_set_circuitstat()
			E.diag_hud_set_circuittracking()
			E.investigate_log("was printed by [E.creator].", INVESTIGATE_CIRCUIT)

		to_chat(usr, "<span class='notice'>[capitalize(built.name)] распечатана.</span>")
		playsound(src, 'sound/items/jaws_pry.ogg', 50, TRUE)

	if(href_list["print"])
		if(!CONFIG_GET(flag/ic_printing) && !debug)
			to_chat(usr, "<span class='warning'>Центральное Командование приостановило печать пользовательских схем в связи с недавними обвинениями в нарушении авторских прав.</span>")
			return
		if(!can_clone) // Copying and printing ICs is cloning
			to_chat(usr, "<span class='warning'>В этом принтере отсутствует обновление для клонирования.</span>")
			return
		switch(href_list["print"])
			if("load")
				if(cloning)
					return
				var/input = input("Вставьте свой код сюда:", "загрузка", null, null) as message | null
				if(!check_interactivity(usr) || cloning)
					return
				if(!input)
					program = null
					return

				log_admin("INTEGRAL BITCH [usr.ckey] загрузил программу: [input] в [src]")
				var/validation = SScircuit.validate_electronic_assembly(input)

				// Validation error codes are returned as text.
				if(istext(validation))
					to_chat(usr, "<span class='warning'>Error: [validation]</span>")
					return
				else if(islist(validation))
					program = validation
					to_chat(usr, "<span class='notice'>Это допустимая программа для [program["assembly"]["type"]].</span>")
					if(program["requires_upgrades"])
						if(upgraded)
							to_chat(usr, "<span class='notice'>В нём используются продвинутые компоненты.</span>")
						else
							to_chat(usr, "<span class='warning'>В нём используются неизвестные компоненты. Для продолжения необходимо улучшить принтер.</span>")
					if(program["unsupported_circuit"])
						to_chat(usr, "<span class='warning'>Эта программа использует компоненты, которые не поддерживаются указанным корпусом. Измените тип корпуса в файле сохранения на поддерживаемый.</span>")
					to_chat(usr, "<span class='notice'>Использованное место: [program["used_space"]]/[program["max_space"]].</span>")
					to_chat(usr, "<span class='notice'>Сложность: [program["complexity"]]/[program["max_complexity"]].</span>")
					to_chat(usr, "<span class='notice'>Потраченный металл: [program["metal_cost"]].</span>")

			if("print")
				if(!program || cloning)
					return
				log_admin("INTEGRAL BITCH [usr.ckey] начал печать программы на [src]. Программа: [program]")

				if(program["requires_upgrades"] && !upgraded && !debug)
					to_chat(usr, "<span class='warning'>В этой программе используются неизвестные компоненты. Для продолжения необходимо улучшить принтер.</span>")
					return
				if(program["unsupported_circuit"] && !debug)
					to_chat(usr, "<span class='warning'>Эта программа использует компоненты, которые не поддерживаются указанным корпусом. Измените тип корпуса в файле сохранения на поддерживаемый.</span>")
					return
				else if(fast_clone)
					var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
					if(debug || materials.use_amount_mat(program["metal_cost"], /datum/material/iron))
						cloning = TRUE
						print_program(usr)
					else
						to_chat(usr, "<span class='warning'>Вам нужно [program["metal_cost"]] металла, чтобы создать это!</span>")
				else
					var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
					if(!materials.use_amount_mat(program["metal_cost"], /datum/material/iron))
						to_chat(usr, "<span class='warning'>Вам нужно [program["metal_cost"]] металла, чтобы создать это!</span>")
						return
					var/cloning_time = round(program["metal_cost"] / 15)
					cloning_time = min(cloning_time, MAX_CIRCUIT_CLONE_TIME)
					cloning = TRUE
					to_chat(usr, "<span class='notice'>Вы начинаете печать пользовательской сборки. Это займет примерно [DisplayTimeText(cloning_time)]. В это время вы по-прежнему можете распечатывать \
					обычные детали.</span>")
					playsound(src, 'sound/items/poster_being_created.ogg', 50, TRUE)
					addtimer(CALLBACK(src, PROC_REF(print_program), usr), cloning_time)

			if("cancel")
				if(!cloning || !program)
					return

				to_chat(usr, "<span class='notice'>Клонирование отменено. Стоимость металла возвращена.</span>")
				cloning = FALSE
				var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
				materials.use_amount_mat(-program["metal_cost"], /datum/material/iron) //use negative amount to regain the cost


	interact(usr)


// FUKKEN UPGRADE DISKS
/obj/item/disk/integrated_circuit/upgrade
	name = "integrated circuit printer upgrade disk"
	desc = "Установите это в ваш принтер интегральных схем, чтобы улучшить его работу."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "upgrade_disk"
	item_state = "card-id"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/disk/integrated_circuit/upgrade/advanced
	name = "integrated circuit printer upgrade disk - advanced designs"
	desc = "Установите это в свой принтер с интегральной схемой, чтобы улучшить его работу.  Этот диск добавляет в принтер новые усовершенствованные дизайны."

/obj/item/disk/integrated_circuit/upgrade/clone
	name = "integrated circuit printer upgrade disk - instant cloner"
	desc = "Установите это в свой принтер с интегральной схемой, чтобы улучшить его работу.  Этот диск позволяет принтеру мгновенно копировать сборки."
	icon_state = "upgrade_disk_clone"

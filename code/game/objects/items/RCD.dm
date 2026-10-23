#define GLOW_MODE 3
#define LIGHT_MODE 2
#define REMOVE_MODE 1

/*
CONTAINS:
RCD
ARCD
RLD
*/

/obj/item/construction
	name = "not for ingame use"
	desc = "Устройство для быстрого строительства и демонтажа. Заправляется металлом, пласталью, стеклом или картриджами со сжатой материей."
	opacity = 0
	density = FALSE
	anchored = FALSE
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	force = 0
	throwforce = 10
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron=100000)
	req_access_txt = "11"
	armor_type = /datum/armor/weapons_and_construction_tools
	resistance_flags = FIRE_PROOF
	var/datum/effect_system/spark_spread/spark_system
	var/matter = 0
	var/max_matter = 100
	var/sheetmultiplier	= 4 //Controls the amount of matter added for each glass/metal sheet, triple for plasteel
	var/plasteelmultiplier = 3 //Plasteel is worth 3 times more than glass or metal
	var/plasmarglassmultiplier = 2 //50% less plasma than in plasteel
	var/rglassmultiplier = 1.5 //One metal sheet, half a glass sheet
	var/no_ammo_message = span_warning("Индикатор нехватки материи на устройстве мигает жёлтым.")
	var/has_ammobar = FALSE	//controls whether or not does update_icon apply ammo indicator overlays
	var/ammo_sections = 10	//amount of divisions in the ammo indicator overlay/number of ammo indicator states
	var/custom_range = 7
	var/upgrade = FALSE

/obj/item/construction/Initialize(mapload)
	. = ..()
	spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/item/construction/examine(mob/user)
	. = ..()
	. += "Запас материи: [matter]/[max_matter] ед."
	if(upgrade & RCD_UPGRADE_FRAMES)
		. += "Содержит чертежи каркасов машин и компьютеров, а также программу демонтажа."
	if(upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS)
		. += span_notice("Содержит чертежи плат воздушной и пожарной сигнализации, контроллеров питания и простых аккумуляторов.")

/obj/item/construction/Destroy()
	QDEL_NULL(spark_system)
	. = ..()

/obj/item/construction/attackby(obj/item/W, mob/user, params)
	if(iscyborg(user))
		return
	var/loaded = 0
	if(istype(W, /obj/item/rcd_ammo))
		var/obj/item/rcd_ammo/R = W
		var/load = min(R.ammoamt, max_matter - matter)
		if(load <= 0)
			to_chat(user, span_warning("Хранилище материи [src] заполнено!"))
			return
		R.ammoamt -= load
		if(R.ammoamt <= 0)
			qdel(R)
		matter += load
		playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
		loaded = 1
	else if(istype(W, /obj/item/stack/sheet/metal) || istype(W, /obj/item/stack/sheet/glass))
		loaded = loadwithsheets(W, sheetmultiplier, user)
	else if(istype(W, /obj/item/stack/sheet/plasteel))
		loaded = loadwithsheets(W, plasteelmultiplier*sheetmultiplier, user) //12 matter for 1 plasteel sheet
	else if(istype(W, /obj/item/stack/sheet/plasmarglass))
		loaded = loadwithsheets(W, plasmarglassmultiplier*sheetmultiplier, user) //8 matter for one plasma rglass sheet
	else if(istype(W, /obj/item/stack/sheet/rglass))
		loaded = loadwithsheets(W, rglassmultiplier*sheetmultiplier, user) //6 matter for one rglass sheet
	else if(istype(W, /obj/item/stack/rods))
		loaded = loadwithsheets(W, sheetmultiplier * 0.5, user) // 2 matter for 1 rod, as 2 rods are produced from 1 metal
	else if(istype(W, /obj/item/stack/tile/plasteel))
		loaded = loadwithsheets(W, sheetmultiplier * 0.25, user) // 1 matter for 1 floortile, as 4 tiles are produced from 1 metal
	if(loaded)
		to_chat(user, span_notice("Запас материи [src]: [matter]/[max_matter] ед."))
	else if(istype(W, /obj/item/rcd_upgrade))
		to_chat(user, span_notice("Вы улучшаете РЦД с помощью [W]!"))
		var/obj/item/rcd_upgrade/rcd_up = W
		if(!(upgrade & rcd_up.upgrade))
			upgrade |= rcd_up.upgrade
			playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
			qdel(W)
	else
		return ..()
	update_icon()	//ensures that ammo counters (if present) get updated

/obj/item/construction/proc/loadwithsheets(obj/item/stack/sheet/S, value, mob/user)
	var/maxsheets = round((max_matter-matter)/value)    //calculate the max number of sheets that will fit in RCD
	if(maxsheets > 0)
		var/amount_to_use = min(S.amount, maxsheets)
		S.use(amount_to_use)
		matter += value*amount_to_use
		playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
		to_chat(user, span_notice("Вы загружаете в [src] [amount_to_use] ед. [S.name]."))
		return TRUE
	to_chat(user, span_warning("В [src] больше не помещается [S.name]!"))
	return FALSE

/obj/item/construction/proc/activate()
	playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)

/obj/item/construction/attack_self(mob/user)
	playsound(src.loc, 'sound/effects/pop.ogg', 50, 0)
	if(prob(20))
		spark_system.start()

/obj/item/construction/proc/useResource(amount, mob/user)
	if(matter < amount)
		if(user)
			to_chat(user, no_ammo_message)
		return FALSE
	matter -= amount
	update_icon()
	return TRUE

/obj/item/construction/proc/checkResource(amount, mob/user)
	. = matter >= amount
	if(!. && user)
		to_chat(user, no_ammo_message)
		if(has_ammobar)
			flick("[icon_state]_empty", src)	//somewhat hacky thing to make RCDs with ammo counters actually have a blinking yellow light
	return .


/obj/item/construction/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/construction/proc/range_check(atom/A, mob/user)
	if(!(A in range(custom_range, get_turf(user))))
		to_chat(user, span_warning("Индикатор превышения дальности на [src] мигает красным."))
		return FALSE
	var/view_range = user.client ? user.client.view : world.view
	//if user can't be seen from A (only checks surroundings' opaqueness) and can't see A.
	//jarring, but it should stop people from targetting atoms they can't see...
	//excluding darkness, to allow RLD to be used to light pitch black dark areas.
	if(!((user in view(view_range, A)) || (user in fov_viewers(view_range, A))))
		to_chat(user, span_warning("Вы направляете [src] на цель за пределами видимости, но ничего не происходит."))
		return FALSE
	return TRUE

/obj/item/construction/rcd
	name = "rapid-construction-device (RCD)"
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcd"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_price = PRICE_ABOVE_EXPENSIVE
	custom_premium_price = PRICE_ALMOST_ONE_GRAND
	max_matter = 160
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON
	has_ammobar = TRUE
	var/mode = 1
	var/ranged = FALSE
	var/computer_dir = 1
	var/airlock_type = /obj/machinery/door/airlock
	var/airlock_glass = FALSE // So the floor's rcd_act knows how much ammo to use
	var/window_type = /obj/structure/window/fulltile
	var/advanced_airlock_setting = 1 //Set to 1 if you want more paintjobs available
	var/list/conf_access = null
	var/use_one_access = 0 //If the airlock should require ALL or only ONE of the listed accesses.
	var/delay_mod = 1
	var/canRturf = FALSE //Variable for R walls to deconstruct them

/obj/item/construction/rcd/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] переключает РЦД в режим строительства стен и направляет его себе в горло! Похоже, это попытка самоубийства!"))
	return (BRUTELOSS)

/obj/item/construction/rcd/verb/toggle_window_type_verb()
	set name = "РЦД: материал окон"
	set category = "Object"
	set src in view(1)

	if(!usr.canUseTopic(src, BE_CLOSE))
		return

	toggle_window_type(usr)

/obj/item/construction/rcd/proc/toggle_window_type(mob/user)
	var/window_type_name
	if (window_type == /obj/structure/window/fulltile)
		window_type = /obj/structure/window/reinforced/fulltile
		window_type_name = "Армированное окно"
	else
		window_type = /obj/structure/window/fulltile
		window_type_name = "Обычное окно"

	to_chat(user, span_notice("Вы выбираете материал окон: [window_type_name]."))

/obj/item/construction/rcd/verb/change_airlock_access(mob/user)
	set name = "РЦД: доступ к шлюзам"

	if(!can_configure_access(user))
		return

	var/t1 = ""


	if(use_one_access)
		t1 += "Условие доступа: <a href='?src=[REF(src)];access=one'>Достаточно одного из выбранных доступов</a><br>"
	else
		t1 += "Условие доступа: <a href='?src=[REF(src)];access=one'>Нужны все выбранные доступы</a><br>"

	t1 += "<a href='?src=[REF(src)];access=all'>Сбросить ограничения</a><br>"

	var/accesses = ""
	accesses += "<div align='center'><b>Доступ</b></div>"
	accesses += "<table style='width:100%'>"
	accesses += "<tr>"
	for(var/i = 1; i <= 7; i++)
		accesses += "<td style='width:14%'><b>[get_region_accesses_name(i)]:</b></td>"
	accesses += "</tr><tr>"
	for(var/i = 1; i <= 7; i++)
		accesses += "<td style='width:14%' valign='top'>"
		for(var/A in get_region_accesses(i))
			if(A in conf_access)
				accesses += "<a href='?src=[REF(src)];access=[A]'><font color=\"red\">[replacetext(get_access_desc(A), " ", "&nbsp")]</font></a> "
			else
				accesses += "<a href='?src=[REF(src)];access=[A]'>[replacetext(get_access_desc(A), " ", "&nbsp")]</a> "
			accesses += "<br>"
		accesses += "</td>"
	accesses += "</tr></table>"
	t1 += "<tt>[accesses]</tt>"

	t1 += "<p><a href='?src=[REF(src)];close=1'>Закрыть</a></p>\n"

	var/datum/browser/popup = new(user, "rcd_access", "Настройка доступа", 900, 500, src)
	popup.set_content(t1)
	popup.open()

/obj/item/construction/rcd/Topic(href, href_list)
	..()
	if(usr.stat || usr.restrained() || !can_configure_access(usr))
		return
	if (href_list["close"])
		usr << browse(null, "window=rcd_access")
		return

	if (href_list["access"])
		toggle_access(href_list["access"])
		change_airlock_access(usr)

/obj/item/construction/rcd/proc/can_configure_access(mob/user)
	return user && (ishuman(user) || user.silicon_privileges) && user.is_holding(src)

/obj/item/construction/rcd/proc/toggle_access(acc)
	if (acc == "all")
		conf_access = null
	else if(acc == "one")
		use_one_access = !use_one_access
	else
		var/req = text2num(acc)

		if (conf_access == null)
			conf_access = list()

		if (!(req in conf_access))
			conf_access += req
		else
			conf_access -= req
			if (!conf_access.len)
				conf_access = null

/obj/item/construction/rcd/proc/get_airlock_image(airlock_type)
	var/obj/machinery/door/airlock/proto = airlock_type
	var/ic = initial(proto.icon)
	var/mutable_appearance/MA = mutable_appearance(ic, "closed")
	if(!initial(proto.glass))
		MA.overlays += "fill_closed"
	//Not scaling these down to button size because they look horrible then, instead just bumping up radius.
	return MA

/obj/item/construction/rcd/proc/change_computer_dir(mob/user)
	if(!user)
		return
	var/list/computer_dirs = list(
		"Север" = image(icon = 'icons/mob/radial.dmi', icon_state = "cnorth"),
		"Восток" = image(icon = 'icons/mob/radial.dmi', icon_state = "ceast"),
		"Юг" = image(icon = 'icons/mob/radial.dmi', icon_state = "csouth"),
		"Запад" = image(icon = 'icons/mob/radial.dmi', icon_state = "cwest")
		)
	var/computerdirs = show_radial_menu(user, get_atom_on_turf(src), computer_dirs, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(computerdirs)
		if("Север")
			computer_dir = 1
		if("Восток")
			computer_dir = 4
		if("Юг")
			computer_dir = 2
		if("Запад")
			computer_dir = 8

/obj/item/construction/rcd/proc/change_airlock_setting(mob/user)
	if(!user)
		return

	var/list/solid_or_glass_choices = list(
		"Цельный" = get_airlock_image(/obj/machinery/door/airlock),
		"Стеклянный" = get_airlock_image(/obj/machinery/door/airlock/glass)
	)

	var/list/solid_choices = list(
		"Стандартный" = get_airlock_image(/obj/machinery/door/airlock),
		"Общий" = get_airlock_image(/obj/machinery/door/airlock/public),
		"Инженерный" = get_airlock_image(/obj/machinery/door/airlock/engineering),
		"Атмосферный" = get_airlock_image(/obj/machinery/door/airlock/atmos),
		"Служба безопасности" = get_airlock_image(/obj/machinery/door/airlock/security),
		"Командование" = get_airlock_image(/obj/machinery/door/airlock/command),
		"Медицинский" = get_airlock_image(/obj/machinery/door/airlock/medical),
		"Исследовательский" = get_airlock_image(/obj/machinery/door/airlock/research),
		"Морозильник" = get_airlock_image(/obj/machinery/door/airlock/freezer),
		"Научный" = get_airlock_image(/obj/machinery/door/airlock/science),
		"Вирусология" = get_airlock_image(/obj/machinery/door/airlock/virology),
		"Шахтёрский" = get_airlock_image(/obj/machinery/door/airlock/mining),
		"Технический" = get_airlock_image(/obj/machinery/door/airlock/maintenance),
		"Внешний" = get_airlock_image(/obj/machinery/door/airlock/external),
		"Внешний технический" = get_airlock_image(/obj/machinery/door/airlock/maintenance/external),
		"Герметичный люк" = get_airlock_image(/obj/machinery/door/airlock/hatch),
		"Технический люк" = get_airlock_image(/obj/machinery/door/airlock/maintenance_hatch)
	)

	var/list/glass_choices = list(
		"Стандартный" = get_airlock_image(/obj/machinery/door/airlock/glass),
		"Общий" = get_airlock_image(/obj/machinery/door/airlock/public/glass),
		"Инженерный" = get_airlock_image(/obj/machinery/door/airlock/engineering/glass),
		"Атмосферный" = get_airlock_image(/obj/machinery/door/airlock/atmos/glass),
		"Служба безопасности" = get_airlock_image(/obj/machinery/door/airlock/security/glass),
		"Командование" = get_airlock_image(/obj/machinery/door/airlock/command/glass),
		"Медицинский" = get_airlock_image(/obj/machinery/door/airlock/medical/glass),
		"Исследовательский" = get_airlock_image(/obj/machinery/door/airlock/research/glass),
		"Научный" = get_airlock_image(/obj/machinery/door/airlock/science/glass),
		"Вирусология" = get_airlock_image(/obj/machinery/door/airlock/virology/glass),
		"Шахтёрский" = get_airlock_image(/obj/machinery/door/airlock/mining/glass),
		"Технический" = get_airlock_image(/obj/machinery/door/airlock/maintenance/glass),
		"Внешний" = get_airlock_image(/obj/machinery/door/airlock/external/glass),
		"Внешний технический" = get_airlock_image(/obj/machinery/door/airlock/maintenance/external/glass)
	)

	var/airlockcat = show_radial_menu(user, get_atom_on_turf(src), solid_or_glass_choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE)
	if(!check_menu(user))
		return
	switch(airlockcat)
		if("Цельный")
			if(advanced_airlock_setting == 1)
				var/airlockpaint = show_radial_menu(user, get_atom_on_turf(src), solid_choices, radius = 42, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE)
				if(!check_menu(user))
					return
				switch(airlockpaint)
					if("Стандартный")
						airlock_type = /obj/machinery/door/airlock
					if("Общий")
						airlock_type = /obj/machinery/door/airlock/public
					if("Инженерный")
						airlock_type = /obj/machinery/door/airlock/engineering
					if("Атмосферный")
						airlock_type = /obj/machinery/door/airlock/atmos
					if("Служба безопасности")
						airlock_type = /obj/machinery/door/airlock/security
					if("Командование")
						airlock_type = /obj/machinery/door/airlock/command
					if("Медицинский")
						airlock_type = /obj/machinery/door/airlock/medical
					if("Исследовательский")
						airlock_type = /obj/machinery/door/airlock/research
					if("Морозильник")
						airlock_type = /obj/machinery/door/airlock/freezer
					if("Научный")
						airlock_type = /obj/machinery/door/airlock/science
					if("Вирусология")
						airlock_type = /obj/machinery/door/airlock/virology
					if("Шахтёрский")
						airlock_type = /obj/machinery/door/airlock/mining
					if("Технический")
						airlock_type = /obj/machinery/door/airlock/maintenance
					if("Внешний")
						airlock_type = /obj/machinery/door/airlock/external
					if("Внешний технический")
						airlock_type = /obj/machinery/door/airlock/maintenance/external
					if("Герметичный люк")
						airlock_type = /obj/machinery/door/airlock/hatch
					if("Технический люк")
						airlock_type = /obj/machinery/door/airlock/maintenance_hatch
				airlock_glass = FALSE
			else
				airlock_type = /obj/machinery/door/airlock
				airlock_glass = FALSE

		if("Стеклянный")
			if(advanced_airlock_setting == 1)
				var/airlockpaint = show_radial_menu(user, get_atom_on_turf(src), glass_choices, radius = 42, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE)
				if(!check_menu(user))
					return
				switch(airlockpaint)
					if("Стандартный")
						airlock_type = /obj/machinery/door/airlock/glass
					if("Общий")
						airlock_type = /obj/machinery/door/airlock/public/glass
					if("Инженерный")
						airlock_type = /obj/machinery/door/airlock/engineering/glass
					if("Атмосферный")
						airlock_type = /obj/machinery/door/airlock/atmos/glass
					if("Служба безопасности")
						airlock_type = /obj/machinery/door/airlock/security/glass
					if("Командование")
						airlock_type = /obj/machinery/door/airlock/command/glass
					if("Медицинский")
						airlock_type = /obj/machinery/door/airlock/medical/glass
					if("Исследовательский")
						airlock_type = /obj/machinery/door/airlock/research/glass
					if("Научный")
						airlock_type = /obj/machinery/door/airlock/science/glass
					if("Вирусология")
						airlock_type = /obj/machinery/door/airlock/virology/glass
					if("Шахтёрский")
						airlock_type = /obj/machinery/door/airlock/mining/glass
					if("Технический")
						airlock_type = /obj/machinery/door/airlock/maintenance/glass
					if("Внешний")
						airlock_type = /obj/machinery/door/airlock/external/glass
					if("Внешний технический")
						airlock_type = /obj/machinery/door/airlock/maintenance/external/glass
				airlock_glass = TRUE
			else
				airlock_type = /obj/machinery/door/airlock/glass
				airlock_glass = TRUE
		else
			airlock_type = /obj/machinery/door/airlock
			airlock_glass = FALSE


/obj/item/construction/rcd/proc/change_firelock_setting(mob/user)
	var/obj/machinery/door/firedoor/firelock_preview = /obj/machinery/door/firedoor
	var/obj/machinery/door/firedoor/window/window_firelock_preview = /obj/machinery/door/firedoor/window
	var/list/choices = list(
		"Стеклянный фаерлок" = image(icon = initial(firelock_preview.icon), icon_state = "door_closed"),
		"Оконный фаерлок" = image(icon = initial(window_firelock_preview.icon), icon_state = "door_closed")
	)
	var/choice = show_radial_menu(user, get_atom_on_turf(src), choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(choice)
		if("Стеклянный фаерлок")
			set_mode(RCD_FIRELOCK)
		if("Оконный фаерлок")
			set_mode(RCD_WINDOW_FIRELOCK)
		else
			return
	playsound(src, 'sound/effects/pop.ogg', 50, FALSE)
	to_chat(user, span_notice("Вы переключаете РЦД в режим «[choice]»."))

/obj/item/construction/rcd/proc/rcd_create(atom/A, mob/user, datum/callback/extra_checks)
	var/list/rcd_results = A.rcd_vals(user, src)
	if(!rcd_results)
		return FALSE
	var/resource_cost = get_resource_cost(rcd_results)
	if(!checkResource(resource_cost, user))
		return FALSE
	var/delay = rcd_results["delay"] * delay_mod
	var/obj/effect/constructing_effect/rcd_effect = new(get_turf(A), delay, src.mode)
	var/turf/the_turf = get_turf(A)
	var/turf_coords = "[COORD(the_turf)]"
	investigate_log("[user] is attempting to use [src] on [A] (loc [turf_coords] at [the_turf]) with cost [rcd_results["cost"]], delay [rcd_results["delay"]], mode [rcd_results["mode"]].", INVESTIGATE_RCD)
	if(do_after(user, delay, target = A, extra_checks = extra_checks) && !QDELETED(src) && checkResource(resource_cost, user) && (!extra_checks || extra_checks.Invoke()))
		var/atom/cached = A
		if(A.rcd_act(user, src, rcd_results["mode"]))
			rcd_effect.end_animation()
			useResource(resource_cost, user)
			if(rcd_results["mode"] == RCD_WINDOWGRILLE && istype(cached, /obj/structure/grille))
				recycle_window_debris(the_turf, user)
			activate()
			investigate_log("[user] used [src] on [cached] (loc [turf_coords] at [the_turf]) with cost [rcd_results["cost"]], delay [rcd_results["delay"]], mode [rcd_results["mode"]].", INVESTIGATE_RCD)
			playsound(src, 'sound/machines/click.ogg', 50, 1)
			return TRUE
	qdel(rcd_effect)

/obj/item/construction/rcd/proc/get_resource_cost(list/rcd_results)
	return rcd_results["cost"]

// Собираем только мусор на самом тайле; оплата окна уже освободила место в ёмкости.
/obj/item/construction/rcd/proc/recycle_window_debris(turf/build_turf, mob/user)
	var/recovered_matter = 0
	for(var/obj/item/shard/shard in build_turf)
		recovered_matter += sheetmultiplier
		qdel(shard)
	for(var/obj/item/stack/rods/rods in build_turf)
		if(rods.is_cyborg)
			continue
		recovered_matter += rods.get_amount() * sheetmultiplier * 0.5
		qdel(rods)
	if(recovered_matter)
		recover_matter(recovered_matter, user)

// Мусор убирается целиком, но излишек не превышает вместимость РЦД.
/obj/item/construction/rcd/proc/recover_matter(amount, mob/user)
	. = min(amount, max(0, max_matter - matter))
	matter += .
	update_icon()

/obj/item/construction/rcd/Initialize(mapload)
	. = ..()
	GLOB.rcd_list += src

/obj/item/construction/rcd/Destroy()
	GLOB.rcd_list -= src
	. = ..()

/obj/item/construction/rcd/builds_over_openspace()
	return TRUE

/obj/item/construction/rcd/attack_self(mob/user)
	if(!check_menu(user))
		return
	..()
	var/list/choices = list(
		"Шлюзы" = image(icon = 'icons/mob/radial.dmi', icon_state = "airlock"),
		"Решётки и окна" = image(icon = 'icons/mob/radial.dmi', icon_state = "grillewindow"),
		"Стены и пол" = image(icon = 'icons/mob/radial.dmi', icon_state = "wallfloor"),
		"Фаерлоки" = image(icon = 'icons/mob/radial.dmi', icon_state = "firedoor")
	)
	if(upgrade & RCD_UPGRADE_FRAMES)
		choices += list(
		"Демонтаж" = image(icon= 'icons/mob/radial.dmi', icon_state = "delete"),
		"Каркасы машин" = image(icon = 'icons/mob/radial.dmi', icon_state = "machine"),
		"Каркасы компьютеров" = image(icon = 'icons/mob/radial.dmi', icon_state = "computer_dir"),
		)
	if(mode == RCD_AIRLOCK)
		choices += list(
		"Настроить доступ" = image(icon = 'icons/mob/radial.dmi', icon_state = "access"),
		"Тип шлюза" = image(icon = 'icons/mob/radial.dmi', icon_state = "airlocktype")
		)
	else if(mode == RCD_WINDOWGRILLE)
		choices += list(
			"Материал окон" = image(icon = 'icons/mob/radial.dmi', icon_state = "windowtype")
		)
	var/choice = show_radial_menu(user, get_atom_on_turf(src), choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(choice)
		if("Стены и пол")
			set_mode(RCD_FLOORWALL)
		if("Шлюзы")
			set_mode(RCD_AIRLOCK)
		if("Фаерлоки")
			change_firelock_setting(user)
			return
		if("Демонтаж")
			set_mode(RCD_DECONSTRUCT)
		if("Решётки и окна")
			set_mode(RCD_WINDOWGRILLE)
		if("Каркасы машин")
			set_mode(RCD_MACHINE)
		if("Каркасы компьютеров")
			set_mode(RCD_COMPUTER)
			change_computer_dir(user)
			return
		if("Настроить доступ")
			change_airlock_access(user)
			return
		if("Тип шлюза")
			change_airlock_setting(user)
			return
		if("Материал окон")
			toggle_window_type(user)
			return
		else
			return
	playsound(src, 'sound/effects/pop.ogg', 50, 0)
	to_chat(user, span_notice("Вы переключаете РЦД в режим «[choice]»."))

/obj/item/construction/rcd/proc/set_mode(new_mode)
	mode = new_mode

/obj/item/construction/rcd/proc/target_check(atom/A, mob/user) // only returns true for stuff the device can actually work with
	if(mode == RCD_DECONSTRUCT && istype(A, /obj/machinery/door/firedoor))
		return TRUE
	if((isturf(A) && A.density && mode==RCD_DECONSTRUCT) || (isturf(A) && !A.density) || (istype(A, /obj/machinery/door/airlock) && mode==RCD_DECONSTRUCT) || istype(A, /obj/structure/grille) || (istype(A, /obj/structure/window) && mode==RCD_DECONSTRUCT) || istype(A, /obj/structure/girder))
		return TRUE
	else
		return FALSE

/obj/item/construction/rcd/proc/resolve_construction_target(atom/A)
	// Конструкции на тайле не должны перекрывать выбор опоры под фаерлок.
	if(mode == RCD_FIRELOCK || mode == RCD_WINDOW_FIRELOCK)
		if(istype(A, /obj/structure/window) || istype(A, /obj/structure/grille) || istype(A, /obj/machinery/door) || istype(A, /obj/structure/inflatable/airbag) || istype(A, /obj/item/airbag_module))
			return get_turf(A)
	// Аирбаг и обломки скрывают решётку, на которую нужно поставить постоянное окно.
	if(mode == RCD_WINDOWGRILLE && (isturf(A) || istype(A, /obj/structure/inflatable/airbag) || istype(A, /obj/item/airbag_module) || istype(A, /obj/item/shard) || istype(A, /obj/item/stack/rods)))
		var/turf/build_turf = get_turf(A)
		if(!build_turf)
			return null
		var/obj/structure/grille/grille = locate() in build_turf
		return grille || build_turf
	return A

/obj/item/construction/rcd/afterattack(atom/A, mob/user, proximity)
	. = ..()
	A = resolve_construction_target(A)
	if(!A)
		return
	if(!proximity)
		if(!ranged || !range_check(A,user)) //early return not-in-range sanity.
			return
		if(target_check(A,user))
			user.Beam(A,icon_state="rped_upgrade",time=30)
		rcd_create(A,user)
		return
	rcd_create(A, user)

/obj/item/construction/rcd/proc/detonate_pulse()
	audible_message(span_danger("<b>[src] начинает вибрировать и громко гудеть!</b>"), span_danger("<b>[src] начинает сильно вибрировать!</b>"))
	// До взрыва остаётся пять секунд.
	addtimer(CALLBACK(src, PROC_REF(detonate_pulse_explode)), 50)

/obj/item/construction/rcd/proc/detonate_pulse_explode()
	explosion(src, 0, 0, 3, 1, flame_range = 1)
	qdel(src)

/obj/item/construction/rcd/update_overlays()
	. = ..()
	if(has_ammobar)
		var/ratio = CEILING((matter / max_matter) * ammo_sections, 1)
		if(ratio)
			. += "[icon_state]_charge[ratio]"

/obj/item/construction/rcd/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/construction/rcd/borg
	desc = "Устройство для быстрого строительства стен и полов."
	no_ammo_message = span_warning("Недостаточно заряда.")
	canRturf = TRUE
	upgrade = TRUE
	var/energyfactor = 72


/obj/item/construction/rcd/borg/useResource(amount, mob/user)
	if(!iscyborg(user))
		return FALSE
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		if(user)
			to_chat(user, no_ammo_message)
		return FALSE
	. = borgy.cell.use(amount * energyfactor) //borgs get 1.3x the use of their RCDs
	if(!. && user)
		to_chat(user, no_ammo_message)
	return .

/obj/item/construction/rcd/borg/checkResource(amount, mob/user)
	if(!iscyborg(user))
		return FALSE
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		if(user)
			to_chat(user, no_ammo_message)
		return FALSE
	. = borgy.cell.charge >= (amount * energyfactor)
	if(!. && user)
		to_chat(user, no_ammo_message)
	return .

// Борговый РЦД тратит заряд вместо материи; возвращаем эквивалент в его батарею.
/obj/item/construction/rcd/borg/recover_matter(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borg = user
	return borg.cell?.give(amount * energyfactor) / energyfactor

/obj/item/construction/rcd/borg/syndicate
	icon_state = "ircd"
	item_state = "ircd"
	energyfactor = 66
	delay_mod = 0.8 // Улучшил. Это теперь также улучшение при изучении нелегалов.

/obj/item/construction/rcd/loaded
	custom_materials = list(/datum/material/iron = 48000, /datum/material/glass = 32000)
	matter = 160

/obj/item/construction/rcd/loaded/upgraded
	upgrade = TRUE

/obj/item/construction/rcd/combat
	name = "combat RCD"
	desc = "Устройство для быстрого строительства и демонтажа. Заправляется металлом, пласталью, стеклом или картриджами со сжатой материей."
	icon_state = "ircd"
	item_state = "ircd"
	max_matter = 500
	matter = 500
	canRturf = TRUE
	upgrade = TRUE

/obj/item/construction/rcd/combat/examine(mob/user)
	. = ..()
	. += "В [name] установлен волновой пробойник, позволяющий разбирать укреплённые стены."

/obj/item/construction/rcd/industrial
	name = "industrial RCD"
	icon_state = "ircd"
	item_state = "ircd"
	max_matter = 500
	matter = 500
	delay_mod = 0.6
	sheetmultiplier	= 8
	upgrade = TRUE

// Встроенный промышленный РЦД использует питание и разрешения модуля меха.
/obj/item/construction/rcd/mecha
	name = "exosuit RCD"
	desc = "Встроенный промышленный РЦД экзокостюма. Работает от батареи меха."
	icon_state = "ircd"
	item_state = "ircd"
	max_matter = 500
	matter = 500
	delay_mod = 0.35
	sheetmultiplier = 8
	upgrade = TRUE
	mode = RCD_DECONSTRUCT
	canRturf = TRUE
	has_ammobar = FALSE
	custom_range = 3

/obj/item/construction/rcd/mecha/check_menu(mob/living/user)
	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc
	return istype(module) && module.equip_ready && module.can_operate(user)

/obj/item/construction/rcd/mecha/can_configure_access(mob/user)
	return check_menu(user)

/obj/item/construction/rcd/mecha/set_mode(new_mode)
	..()
	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc
	if(istype(module))
		module.energy_drain = mode == RCD_DECONSTRUCT ? module.energy_drain_deconstruct : initial(module.energy_drain)
		module.update_equip_info()

/obj/item/construction/rcd/mecha/get_resource_cost(list/rcd_results)
	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc
	return module.energy_drain

/obj/item/construction/rcd/mecha/checkResource(amount, mob/user)
	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc
	. = istype(module) && module.can_operate(user) && module.chassis.has_charge(amount)
	if(!. && user)
		to_chat(user, span_warning("Недостаточно энергии либо модуль РЦД недоступен."))

/obj/item/construction/rcd/mecha/useResource(amount, mob/user)
	if(!checkResource(amount, user))
		return FALSE
	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc
	return module.chassis.use_power(amount)

// Сбор обломков не заряжает батарею: модуль оплачивает целую операцию, а не единицы материи.
/obj/item/construction/rcd/mecha/recover_matter(amount, mob/user)
	return 0

/obj/item/construction/rcd/mecha/detonate_pulse_explode()
	var/obj/item/mecha_parts/mecha_equipment/rcd/module = loc
	..()
	if(istype(module))
		qdel(module)

/obj/item/rcd_ammo
	name = "compressed matter cartridge"
	desc = "Сильно сжатая материя для РЦД."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "rcd"
	item_state = "rcdammo"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_materials = list(/datum/material/iron=24000, /datum/material/glass=16000)
	var/ammoamt = 80

/obj/item/rcd_ammo/large
	name = "large compressed matter cartridge"
	desc = "Сильно сжатая материя для РЦД. В том же объёме помещается вчетверо больше материи, чем в обычном картридже."
	custom_materials = list(/datum/material/iron=96000, /datum/material/glass=64000)
	ammoamt = 320


/obj/item/construction/rcd/combat/admin
	name = "admin RCD"
	max_matter = INFINITY
	matter = INFINITY
	upgrade = TRUE
	ranged = TRUE

// Ranged RCD


/obj/item/construction/rcd/arcd
	name = "advanced rapid-construction-device (ARCD)"
	desc = "Прототип РЦД с увеличенным запасом материи и возможностью работы на расстоянии. Заправляется металлом, пласталью, стеклом или картриджами со сжатой материей."
	max_matter = 300
	matter = 300
	delay_mod = 0.6
	ranged = TRUE
	icon_state = "arcd"
	item_state = "oldrcd"
	has_ammobar = FALSE
	upgrade = TRUE


// RAPID LIGHTING DEVICE


/obj/item/construction/rld
	name = "rapid-light-device (RLD)"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with metal, plasteel, glass or compressed matter cartridges."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rld"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	matter = 200
	max_matter = 200
	sheetmultiplier = 5
	var/mode = LIGHT_MODE
	actions_types = list(/datum/action/item_action/pick_color)
	ammo_sections = 5
	has_ammobar = TRUE

	var/wallcost = 20
	var/floorcost = 25
	var/launchcost = 10
	var/deconcost = 20

	var/walldelay = 10
	var/floordelay = 10
	var/decondelay = 10

	var/color_choice = null


/obj/item/construction/rld/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/construction/rld/ui_action_click(mob/user, var/datum/action/A)
	if(istype(A, /datum/action/item_action/pick_color))
		color_choice = input(user,"","Choose Color",color_choice) as color
	else
		..()

/obj/item/construction/rld/update_overlays()
	. = ..()
	var/ratio = CEILING((matter / max_matter) * ammo_sections, 1)
	. += "rld_light[ratio]"

/obj/item/construction/rld/attack_self(mob/user)
	..()
	switch(mode)
		if(REMOVE_MODE)
			mode = LIGHT_MODE
			to_chat(user, "<span class='notice'>You change RLD's mode to 'Permanent Light Construction'.</span>")
		if(LIGHT_MODE)
			mode = GLOW_MODE
			to_chat(user, "<span class='notice'>You change RLD's mode to 'Light Launcher'.</span>")
		if(GLOW_MODE)
			mode = REMOVE_MODE
			to_chat(user, "<span class='notice'>You change RLD's mode to 'Deconstruct'.</span>")


/obj/item/construction/rld/proc/checkdupes(var/target)
	. = list()
	var/turf/checking = get_turf(target)
	for(var/obj/machinery/light/dupe in checking)
		if(istype(dupe, /obj/machinery/light))
			. |= dupe


/obj/item/construction/rld/afterattack(atom/A, mob/user)
	. = ..()
	if(!range_check(A,user))
		return
	var/turf/start = get_turf(src)
	switch(mode)
		if(REMOVE_MODE)
			if(istype(A, /obj/machinery/light/))
				if(checkResource(deconcost, user))
					to_chat(user, "<span class='notice'>You start deconstructing [A]...</span>")
					user.Beam(A,icon_state="light_beam",time=15)
					playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
					if(do_after(user, decondelay, target = A))
						if(!useResource(deconcost, user))
							return FALSE
						activate()
						qdel(A)
						return TRUE
				return FALSE
		if(LIGHT_MODE)
			if(iswallturf(A))
				var/turf/closed/wall/W = A
				if(checkResource(floorcost, user))
					to_chat(user, "<span class='notice'>You start building a wall light...</span>")
					user.Beam(A,icon_state="light_beam",time=15)
					playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
					playsound(src.loc, 'sound/effects/light_flicker.ogg', 50, 0)
					if(do_after(user, floordelay, target = A))
						if(!istype(W))
							return FALSE
						var/list/candidates = list()
						var/turf/open/winner = null
						var/winning_dist = null
						for(var/direction in GLOB.cardinals)
							var/turf/C = get_step(W, direction)
							var/list/dupes = checkdupes(C)
							if(start.CanAtmosPass(C) && !dupes.len)
								candidates += C
						if(!candidates.len)
							to_chat(user, "<span class='warning'>Valid target not found...</span>")
							playsound(src.loc, 'sound/misc/compiler-failure.ogg', 30, 1)
							return FALSE
						for(var/turf/open/O in candidates)
							if(istype(O))
								var/x0 = O.x
								var/y0 = O.y
								var/contender = cheap_hypotenuse(start.x, start.y, x0, y0)
								if(!winner)
									winner = O
									winning_dist = contender
								else
									if(contender < winning_dist) // lower is better
										winner = O
										winning_dist = contender
						activate()
						if(!useResource(wallcost, user))
							return FALSE
						var/light = get_turf(winner)
						var/align = get_dir(winner, A)
						var/obj/machinery/light/L = new /obj/machinery/light(light)
						L.setDir(align)
						L.color = color_choice
						L.light_color = L.color
						return TRUE
				return FALSE

			if(isfloorturf(A))
				var/turf/open/floor/F = A
				if(checkResource(floorcost, user))
					to_chat(user, "<span class='notice'>You start building a floor light...</span>")
					user.Beam(A,icon_state="light_beam",time=15)
					playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
					playsound(src.loc, 'sound/effects/light_flicker.ogg', 50, 1)
					if(do_after(user, floordelay, target = A))
						if(!istype(F))
							return FALSE
						if(!useResource(floorcost, user))
							return FALSE
						activate()
						var/destination = get_turf(A)
						var/obj/machinery/light/floor/FL = new /obj/machinery/light/floor(destination)
						FL.color = color_choice
						FL.light_color = FL.color
						return TRUE
				return FALSE

		if(GLOW_MODE)
			if(useResource(launchcost, user))
				activate()
				to_chat(user, "<span class='notice'>You fire a glowstick!</span>")
				var/obj/item/flashlight/glowstick/G  = new /obj/item/flashlight/glowstick(start)
				G.color = color_choice
				G.light_color = G.color
				G.throw_at(A, 9, 3, user)
				G.on = TRUE
				G.update_brightness()
				return TRUE
			return FALSE

/obj/item/construction/rld/mini
	name = "mini-rapid-light-device (MRLD)"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with metal, plasteel, glass or compressed matter cartridges."
	matter = 100
	max_matter = 100
	w_class = WEIGHT_CLASS_SMALL

/obj/item/rcd_upgrade
	name = "RCD advanced design disk"
	desc = "It seems to be empty."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"
	var/upgrade

/obj/item/rcd_upgrade/frames
	desc = "It contains the design for machine frames, computer frames and deconstruction."
	upgrade = RCD_UPGRADE_FRAMES

/obj/item/rcd_upgrade/simple_circuits
	desc = "Содержит чертежи плат воздушной и пожарной сигнализации, контроллеров питания и простых аккумуляторов."
	upgrade = RCD_UPGRADE_SIMPLE_CIRCUITS

/obj/item/construction/plumbing
	name = "Plumbing Constructor"
	desc = "An expertly modified RCD outfitted to construct plumbing machinery. Reload with compressed matter cartridges."
	icon = 'icons/obj/tools.dmi'
	icon_state = "arcd"
	item_state = "oldrcd"
	has_ammobar = FALSE
	matter = 200
	max_matter = 200
	custom_price = PRICE_ABOVE_EXPENSIVE*1.5
	custom_premium_price = PRICE_ABOVE_EXPENSIVE*3

	///type of the plumbing machine
	var/blueprint = null
	///index, used in the attack self to get the type. stored here since it doesnt change
	var/list/choices = list()
	///index, used in the attack self to get the type. stored here since it doesnt change
	var/list/name_to_type = list()
	///
	var/list/machinery_data = list("cost" = list(), "delay" = list())

/obj/item/construction/plumbing/attack_self(mob/user)
	..()
	if(!choices.len)
		for(var/A in subtypesof(/obj/machinery/plumbing))
			var/obj/machinery/plumbing/M = A
			if(initial(M.rcd_constructable))
				choices += list(initial(M.name) = image(icon = initial(M.icon), icon_state = initial(M.icon_state)))
				name_to_type[initial(M.name)] = M
				machinery_data["cost"][A] = initial(M.rcd_cost)
				machinery_data["delay"][A] = initial(M.rcd_delay)

	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return

	blueprint = name_to_type[choice]
	playsound(src, 'sound/effects/pop.ogg', 50, FALSE)
	to_chat(user, "<span class='notice'>You change [name]s blueprint to '[choice]'.</span>")

///pretty much rcd_create, but named differently to make myself feel less bad for copypasting from a sibling-type
/obj/item/construction/plumbing/proc/create_machine(atom/A, mob/user)
	if(!machinery_data || !isopenturf(A))
		return FALSE

	if(checkResource(machinery_data["cost"][blueprint], user) && blueprint)
		if(do_after(user, machinery_data["delay"][blueprint], target = A))
			if(checkResource(machinery_data["cost"][blueprint], user) && canPlace(A))
				useResource(machinery_data["cost"][blueprint], user)
				activate()
				playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
				new blueprint (A, FALSE, FALSE)
				return TRUE

/obj/item/construction/plumbing/proc/canPlace(turf/T)
	if(!isopenturf(T))
		return FALSE
	. = TRUE
	for(var/obj/O in T.contents)
		if(O.density) //let's not built ontop of dense stuff, like big machines and other obstacles, it kills my immershion
			return FALSE

/obj/item/construction/plumbing/afterattack(atom/A, mob/user)
	. = ..()
	if(!range_check(A, user))
		return
	if(istype(A, /obj/machinery/plumbing))
		var/obj/machinery/plumbing/P = A
		if(P.anchored)
			to_chat(user, "<span class='warning'>The [P.name] needs to be unanchored!</span>")
			return
		if(do_after(user, 20, target = P))
			P.deconstruct() //Let's not substract matter
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, TRUE) //this is just such a great sound effect
	else
		create_machine(A, user)


#undef GLOW_MODE
#undef LIGHT_MODE
#undef REMOVE_MODE

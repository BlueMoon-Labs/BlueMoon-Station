GLOBAL_LIST(labor_sheet_values)

/**********************Prisoners' Console**************************/

/obj/machinery/mineral/labor_claim_console
	name = "point claim console"
	desc = "Консоль с электромагнитным записывающим устройством для отслеживания руды, добытой заключенными."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = FALSE
	/// Connected stacking machine
	var/obj/machinery/mineral/stacking_machine/laborstacker/stacking_machine = null
	/// Direction of the stacking machine
	var/machinedir = SOUTH
	/// Needed to send messages to sec radio
	var/obj/item/radio/Radio

/obj/machinery/mineral/labor_claim_console/Initialize(mapload)
	. = ..()
	Radio = new/obj/item/radio(src)
	Radio.listening = FALSE
	locate_stacking_machine()

	if(!GLOB.labor_sheet_values)
		var/sheet_list = list()
		for(var/sheet_type in subtypesof(/obj/item/stack/sheet))
			var/obj/item/stack/sheet/sheet = sheet_type
			if(!initial(sheet.point_value) || (initial(sheet.merge_type) && initial(sheet.merge_type) != sheet_type)) //ignore no-value sheets and x/fifty subtypes
				continue
			sheet_list += list(list("ore" = initial(sheet.name), "value" = initial(sheet.point_value)))
		GLOB.labor_sheet_values = sort_list(sheet_list, GLOBAL_PROC_REF(cmp_sheet_list))

/proc/cmp_sheet_list(list/a, list/b)
	return a["value"] - b["value"]

/obj/machinery/mineral/labor_claim_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LaborClaimConsole", name)
		ui.open()

/obj/machinery/mineral/labor_claim_console/ui_static_data(mob/user)
	var/list/data = list()
	data["ores"] = GLOB.labor_sheet_values
	return data

/obj/machinery/mineral/labor_claim_console/ui_data(mob/user)
	var/list/data = list()
	var/can_go_home = FALSE

	data["emagged"] = FALSE
	if(obj_flags & EMAGGED)
		data["emagged"] = TRUE
		can_go_home = TRUE

	var/obj/item/card/id/I
	if(isliving(user))
		var/mob/living/L = user
		I = L.get_idcard(TRUE)

	if(istype(I, /obj/item/card/id/prisoner))
		var/obj/item/card/id/prisoner/P = I
		data["id_points"] = P.points
		if(P.points >= P.goal)
			can_go_home = TRUE
			data["status_info"] = "Цель достигнута!"
		else
			data["status_info"] = "Вам осталось набрать [(P.goal - P.points)] очков."
	else
		data["status_info"] = "ID-карта заключенного не обнаружена."
		data["id_points"] = 0

	if(stacking_machine)
		data["unclaimed_points"] = stacking_machine.points
	else
		data["unclaimed_points"] = 0

	data["can_go_home"] = can_go_home
	return data

/obj/machinery/mineral/labor_claim_console/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/M = usr
	switch(action)
		if("claim_points")
			if(!stacking_machine)
				to_chat(M, "<span class='alert'>Ошибка: Устройство для сдачи руды не найдено.</span>")
				return

			var/obj/item/card/id/I
			if(isliving(M))
				var/mob/living/L = M
				I = L.get_idcard(TRUE)

			if(istype(I, /obj/item/card/id/prisoner))
				var/obj/item/card/id/prisoner/P = I
				P.points += stacking_machine.points
				stacking_machine.points = 0
				to_chat(M, "<span class='notice'>Очки успешно переведены на ID-карту.</span>")
				return TRUE
			else
				to_chat(M, "<span class='alert'>Не обнаружена действительная ID-карта для перевода очков.</span>")

		if("move_shuttle")
			if(!alone_in_area(get_area(src), M))
				to_chat(M, "<span class='alert'>Заключенным разрешено вызывать шаттл только находясь в одиночестве.</span>")
				return

			switch(SSshuttle.moveShuttle("laborcamp", "laborcamp_home", TRUE))
				if(1)
					to_chat(M, "<span class='alert'>Шаттл не найден.</span>")
				if(2)
					to_chat(M, "<span class='alert'>Шаттл уже находится на станции.</span>")
				if(3)
					to_chat(M, "<span class='alert'>Не удалось получить разрешение на стыковку.</span>")
				else

					if(!(obj_flags & EMAGGED))
						Radio.set_frequency(FREQ_SECURITY)
						var/loud_msg = "<b><span class='alert'>ВНИМАНИЕ! Заключенный возвращается на станцию! Минералы и ID-карта готовы к изъятию!</span></b>"
						Radio.talk_into(src, loud_msg, FREQ_SECURITY)

					if(ishuman(M))
						var/mob/living/carbon/human/H = M
						if(!isnull(GLOB.data_core.security))
							for(var/r in GLOB.data_core.security)
								var/datum/data/record/R = r
								if(R.fields["name"] == H.real_name)
									R.set_security_status(SEC_RECORD_STATUS_RELEASED)
									break

					to_chat(M, "<span class='notice'>Сообщение получено. Шаттл будет отправлен в ближайшее время.</span>")
					return TRUE

/obj/machinery/mineral/labor_claim_console/proc/locate_stacking_machine()
	for (var/obj/machinery/mineral/stacking_machine/laborstacker/SM in orange(2, src))
		stacking_machine = SM
		break
	if(stacking_machine)
		stacking_machine.CONSOLE = src

/obj/machinery/mineral/labor_claim_console/emag_act(mob/user)
	. = ..()
	if(!(obj_flags & EMAGGED))
		obj_flags |= EMAGGED
		to_chat(user, "<span class='warning'>ПЗЗЗТ-ТФФФФТ!</span>")
		log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	return TRUE

/**********************Prisoner Collection Unit**************************/

/obj/machinery/mineral/stacking_machine/laborstacker
	force_connect = TRUE
	var/points = 0


/obj/machinery/mineral/stacking_machine/laborstacker/process_sheet(obj/item/stack/sheet/inp)
	points += inp.point_value * inp.amount
	..()

/obj/machinery/mineral/stacking_machine/laborstacker/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/stack/ore))
		to_chat(user, "<span class='warning'>[src] не принимает необработанную руду! Сначала переплавьте её.</span>")
		return

	if(istype(I, /obj/item/stack/sheet) && user.canUnEquip(I) && user.a_intent == INTENT_HELP)
		var/obj/item/stack/sheet/inp = I
		var/added_points = inp.point_value * inp.amount

		if(added_points <= 0)
			to_chat(user, "<span class='warning'>[src] не принимает эти материалы.</span>")
			return

		points += added_points
		to_chat(user, "<span class='notice'>Вы загрузили [inp.name] в машину. Начислено очков: [added_points].</span>")
		inp.use(inp.amount)

		return

	return ..()


/obj/item/detective_scanner
	name = "Forensic Scanner"
	desc = "Анализатор, способный выдать отчет по человеку, исходя из имени, ДНК или отпечатков пальцев."
	icon = 'icons/obj/device.dmi'
	icon_state = "forensicnew"
	w_class = WEIGHT_CLASS_SMALL
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	actions_types = list(/datum/action/item_action/displayDetectiveScanResults)

	var/scanning = FALSE
	var/scan_progress = 0
	var/has_scan = FALSE
	var/target_name = ""
	var/target_icon_b64 = null
	var/scan_timestamp = ""
	var/scan_location = ""
	var/list/scan_fingerprints = list()
	var/list/scan_blood = list()
	var/list/scan_fibers = list()
	var/list/scan_reagents = list()
	var/range = 1
	var/view_check = TRUE
	var/forensicPrintCount = 0

/datum/action/item_action/displayDetectiveScanResults
	name = "Display Forensic Scanner Results"

/datum/action/item_action/displayDetectiveScanResults/Trigger()
	var/obj/item/detective_scanner/scanner = target
	if(istype(scanner))
		scanner.ui_interact(usr)

/obj/item/detective_scanner/attack_self(mob/user)
	ui_interact(user)
	return

/obj/item/detective_scanner/attack(mob/living/M, mob/user)
	return

/obj/item/detective_scanner/examine(mob/user)
	. = ..()
	. += span_notice("Нажмите в руке чтобы открыть интерфейс сканера.")
	if(has_scan && !scanning)
		. += span_notice("В памяти сохранён отчёт по <b>[target_name]</b> - откройте интерфейс для печати.")
	if(scanning)
		. += span_warning("Идёт анализ... [scan_progress]%")

/obj/item/detective_scanner/AltClick(mob/living/user)
	. = ..()
	if(!user.canUseTopic(src, be_close=TRUE))
		return
	. = TRUE
	ui_interact(user)

/obj/item/detective_scanner/afterattack(atom/A, mob/user, params)
	. = ..()
	scan(A, user)
	return FALSE

/obj/item/detective_scanner/proc/can_scan(atom/A, mob/user)
	if(scanning)
		return FALSE
	if((get_dist(A, user) > range) || (!(A in view(range, user)) && view_check) || (loc != user))
		return FALSE
	if(ismob(A) && A == user)
		return FALSE
	return TRUE

/obj/item/detective_scanner/proc/scan(atom/A, mob/user)
	set waitfor = 0
	if(!can_scan(A, user))
		return

	scanning = TRUE
	has_scan = FALSE
	scan_progress = 0
	target_name = A.name
	target_icon_b64 = null
	scan_fingerprints = list()
	scan_blood = list()
	scan_fibers = list()
	scan_reagents = list()
	scan_timestamp = "[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
	var/area/area_name = get_area(A)
	scan_location = area_name ? area_name.name : "Unknown"

	var/icon/flat = getFlatIcon(A, no_anim = TRUE)
	if(flat)
		target_icon_b64 = icon2base64(flat)

	SStgui.update_uis(src)
	user.visible_message(span_notice("\The [user] наводит [src.name] на \the [A] - слышен тихий писк анализатора."), span_notice("Начинаем сканирование \the [A]..."))
	playsound(src, 'sound/machines/terminal_success.ogg', 25, FALSE)

	var/list/fingerprints = list()
	var/list/blood = list()
	var/list/fibers = list()
	var/list/reagents = list()

	if(A.blood_DNA && length(A.blood_DNA))
		for(var/dna in A.blood_DNA)
			if(dna == "color")
				continue
			blood += list(list("dna" = dna, "type" = A.blood_DNA[dna]))

	if(A.suit_fibers && length(A.suit_fibers))
		fibers = A.suit_fibers.Copy()

	if(ishuman(A))
		var/mob/living/carbon/human/H = A
		if(!H.gloves)
			fingerprints += md5(H.dna.uni_identity)
	else if(!ismob(A))
		if(A.fingerprints && length(A.fingerprints))
			for(var/fp in A.fingerprints)
				fingerprints += A.fingerprints[fp]
		if(A.reagents && length(A.reagents.reagent_list))
			for(var/datum/reagent/R in A.reagents.reagent_list)
				reagents += list(list("name" = R.name, "volume" = round(R.volume, 0.1)))
				if(istype(R, /datum/reagent/blood))
					if(R.data["blood_DNA"] && R.data["blood_type"])
						var/blood_DNA = R.data["blood_DNA"]
						var/blood_type = R.data["blood_type"]
						var/found = FALSE
						for(var/list/entry in blood)
							if(entry["dna"] == blood_DNA)
								found = TRUE
								break
						if(!found)
							blood += list(list("dna" = blood_DNA, "type" = blood_type))

	var/list/stages = list(25, 50, 75, 100)
	for(var/stage in stages)
		sleep(0.9 SECONDS)
		if(QDELETED(src))
			return
		scan_progress = stage
		SStgui.update_uis(src)
		playsound(src, 'sound/machines/terminal_processing.ogg', 12, FALSE)

	scan_fingerprints = fingerprints
	scan_blood = blood
	scan_fibers = fibers
	scan_reagents = reagents

	scanning = FALSE
	has_scan = TRUE
	scan_progress = 100

	var/found_something = length(fingerprints) || length(blood) || length(fibers) || length(reagents)

	if(!found_something)
		playsound(src, 'sound/machines/buzz-two.ogg', 40, FALSE)
		balloon_alert(user, "следов не найдено")
	else
		playsound(src, 'sound/machines/chime.ogg', 40, FALSE)
		balloon_alert(user, "анализ завершён")

	SStgui.update_uis(src)
	if(ismob(loc))
		ui_interact(loc)

/obj/item/detective_scanner/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DetectiveScanner", name)
		ui.open()

/obj/item/detective_scanner/ui_status(mob/user, datum/ui_state/state)
	if(scanning && user != loc)
		return UI_INTERACTIVE
	return ..()

/obj/item/detective_scanner/ui_data(mob/user)
	var/list/data = list()
	data["scanning"] = scanning
	data["scan_progress"] = scan_progress
	data["has_scan"] = has_scan
	data["target_name"] = target_name
	data["target_icon"] = target_icon_b64
	data["timestamp"] = scan_timestamp
	data["location"] = scan_location
	data["fingerprints"] = scan_fingerprints
	data["blood"] = scan_blood
	data["fibers"] = scan_fibers
	data["reagents"] = scan_reagents
	data["print_count"] = forensicPrintCount
	data["can_print"] = has_scan && !scanning
	return data

/obj/item/detective_scanner/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("print_report")
			if(scanning || !has_scan)
				return
			print_report(usr)
			return TRUE
		if("clear_scan")
			if(scanning)
				return
			clear_scan(usr)
			return TRUE
		if("close")
			return TRUE

/obj/item/detective_scanner/proc/clear_scan(mob/user)
	if(scanning)
		balloon_alert(user, "занят анализом!")
		return
	if(!has_scan)
		balloon_alert(user, "память пуста")
		return
	has_scan = FALSE
	scan_progress = 0
	target_name = ""
	target_icon_b64 = null
	scan_timestamp = ""
	scan_location = ""
	scan_fingerprints = list()
	scan_blood = list()
	scan_fibers = list()
	scan_reagents = list()
	balloon_alert(user, "память очищена")
	playsound(src, 'sound/machines/beep.ogg', 30, FALSE)
	SStgui.update_uis(src)

/obj/item/detective_scanner/proc/print_report(mob/user)
	if(scanning || !has_scan)
		return
	forensicPrintCount++
	var/frNum = forensicPrintCount

	var/obj/item/paper/report_paper = new(get_turf(src))
	report_paper.name = "FR-[frNum] '[target_name]' - Forensic Report"
	report_paper.color = "#fdf6e3"

	var/report_text = {"
<h1 style='text-align:center; font-family:monospace; letter-spacing:2px; border:1px solid #333; padding:6px; font-size:14px;'>NANOTRASEN FORENSIC BUREAU</h1>
<p style='text-align:center; font-size:8px; color:#666; letter-spacing:1px;'>CASE FILE - FR-[frNum] | CONFIDENTIAL | EYES ONLY</p>
<hr>
<table style='width:100%; font-size:12px;'>
<tr><td><b>Объект анализа:</b> [target_name]</td><td style='text-align:right;'><b>Время:</b> [scan_timestamp]</td></tr>
<tr><td><b>Оператор:</b> [user ? user.real_name : "Unknown"]</td><td style='text-align:right;'><b>ID:</b> FR-[frNum]</td></tr>
<tr><td colspan='2'><b>Сканер:</b> NT-Forensic Scanner v2.1</td></tr>
</table>
<hr>
"}

	report_text += "<h3>Отпечатки пальцев</h3>"
	if(length(scan_fingerprints))
		report_text += "<table style='width:100%; font-family:monospace; font-size:11px; border-collapse:collapse;'>"
		report_text += "<tr style='background:#222; color:#fff;'><th style='padding:4px; text-align:left;'>#</th><th style='padding:4px; text-align:left;'>MD5 Hash</th></tr>"
		var/i = 1
		for(var/fp in scan_fingerprints)
			var/bg = (i % 2 == 0) ? "#f0e6d3" : "#fff8dc"
			report_text += "<tr style='background:[bg];'><td style='padding:3px;'>[i]</td><td style='padding:3px;'>[fp]</td></tr>"
			i++
		report_text += "</table>"
	else
		report_text += "<p style='color:#888; font-style:italic;'>- Следов отпечатков не обнаружено -</p>"

	report_text += "<h3>Кровь / ДНК</h3>"
	if(length(scan_blood))
		report_text += "<table style='width:100%; font-family:monospace; font-size:11px; border-collapse:collapse;'>"
		report_text += "<tr style='background:#4a0a0a; color:#fff;'><th style='padding:4px;'>#</th><th style='padding:4px;'>Группа крови</th><th style='padding:4px;'>ДНК</th></tr>"
		var/i = 1
		for(var/list/entry in scan_blood)
			var/bg = (i % 2 == 0) ? "#fde8e8" : "#fff0f0"
			report_text += "<tr style='background:[bg];'><td style='padding:3px; text-align:center;'>[i]</td><td style='padding:3px; text-align:center; color:#b00; font-weight:bold;'>[entry["type"]]</td><td style='padding:3px;'>[entry["dna"]]</td></tr>"
			i++
		report_text += "</table>"
	else
		report_text += "<p style='color:#888; font-style:italic;'>- Крови/ДНК не обнаружено -</p>"

	report_text += "<h3>Волокна / Материалы</h3>"
	if(length(scan_fibers))
		report_text += "<ul style='font-size:11px;'>"
		for(var/f in scan_fibers)
			report_text += "<li>[f]</li>"
		report_text += "</ul>"
	else
		report_text += "<p style='color:#888; font-style:italic;'>- Волокон не обнаружено -</p>"

	report_text += "<h3>Реагенты</h3>"
	if(length(scan_reagents))
		report_text += "<table style='width:100%; font-family:monospace; font-size:11px; border-collapse:collapse;'>"
		report_text += "<tr style='background:#0a2a4a; color:#fff;'><th style='padding:4px;'>Реагент</th><th style='padding:4px; text-align:right;'>Объём (u)</th></tr>"
		var/i = 1
		for(var/list/entry in scan_reagents)
			var/bg = (i % 2 == 0) ? "#e8f0fd" : "#f0f6ff"
			report_text += "<tr style='background:[bg];'><td style='padding:3px;'>[entry["name"]]</td><td style='padding:3px; text-align:right;'>[entry["volume"]]</td></tr>"
			i++
		report_text += "</table>"
	else
		report_text += "<p style='color:#888; font-style:italic;'>- Реагентов не обнаружено -</p>"

	report_text += {"
<hr>
<p style='font-size:10px; color:#555;'><b>Примечания:</b> <span style='border-bottom:1px dotted #999;'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span></p>
<p style='font-size:9px; color:#999; text-align:center;'>Документ сгенерирован автоматически. Требуется подпись криминалиста для юридической силы. NT-FB-FR. Копирование без санкции СБ запрещено.</p>
"}

	report_paper.add_raw_text(report_text)
	report_paper.update_appearance()

	if(ismob(loc))
		var/mob/printer = loc
		printer.put_in_hands(report_paper)
		balloon_alert(printer, "отчёт FR-[frNum] напечатан")
	else
		report_paper.forceMove(get_turf(src))

	playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 50, FALSE)

/proc/get_timestamp()
	return time2text(world.time + 432000, ":ss")

/obj/machinery/computer/secure_data//TODO:SANITY
	name = "security records console"
	desc = "Used to view and edit personnel's security records."
	icon_screen = "security"
	icon_keyboard = "security_key"
	req_one_access = list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS)
	circuit = /obj/item/circuitboard/computer/secure_data
	var/rank = null
	var/screen = null
	var/datum/data/record/active1 = null
	var/datum/data/record/active2 = null
	var/temp = null
	var/printing = null
	var/can_change_id = 0
	var/list/Perp
	var/tempname = null
	//Sorting Variables
	var/sortBy = "name"
	var/order = 1 // -1 = Descending - 1 = Ascending

	var/list/logged_access

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/secure_data/syndie
	icon_keyboard = "syndie_key"

/obj/machinery/computer/secure_data/laptop
	name = "security laptop"
	desc = "A cheap Nanotrasen security laptop, it functions as a security records console. It's bolted to the table."
	icon_state = "laptop"
	icon_screen = "seclaptop"
	icon_keyboard = "laptop_key"
	clockwork = TRUE //it'd look weird
	pass_flags = PASSTABLE

//Someone needs to break down the dat += into chunks instead of long ass lines.
/obj/machinery/computer/secure_data/ui_interact(mob/user)
	. = ..()
	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	if(is_away_level(z))
		to_chat(user, "<span class='boldannounce'>Unable to establish a connection</span>: \black You're too far away from the station!")
		return
	var/dat

	if(temp)
		dat = "<TT>[temp]</TT><BR><BR><A href='?src=[REF(src)];choice=Clear Screen'>Clear Screen</A>"
	else
		dat = ""
		if(authenticated)
			switch(screen)
				if(1)

					//body tag start + onload and onkeypress (onkeyup) javascript event calls
					dat += "<body onload='selectTextField(); updateSearch();' onkeyup='updateSearch();'>"
					//search bar javascript
					dat += {"

		<head>
			<script src="jquery.min.js"></script>
			<script type='text/javascript'>

				function updateSearch(){
					var filter_text = document.getElementById('filter');
					var filter = filter_text.value.toLowerCase();

					if(complete_list != null && complete_list != ""){
						var mtbl = document.getElementById("maintable_data_archive");
						mtbl.innerHTML = complete_list;
					}

					if(filter.value == ""){
						return;
					}else{
						$("#maintable_data").children("tbody").children("tr").children("td").children("input").filter(function(index)
						{
							return $(this)\[0\].value.toLowerCase().indexOf(filter) == -1
						}).parent("td").parent("tr").hide()
					}
				}

				function selectTextField(){
					var filter_text = document.getElementById('filter');
					filter_text.focus();
					filter_text.select();
				}

			</script>
		</head>


	"}
					dat += {"
<p style='text-align:center;'>"}
					dat += "<A href='?src=[REF(src)];choice=New Record (General)'>New Record</A><BR>"
					//search bar
					dat += {"
						<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable'>
							<tr id='search_tr'>
								<td align='center'>
									<b>Search:</b> <input type='text' id='filter' value='' style='width:300px;'>
								</td>
							</tr>
						</table>
					"}
					dat += {"
</p>
<table style="text-align:center;" cellspacing="0" width="100%">
<tr>
<th>Records:</th>
</tr>
</table>

<span id='maintable_data_archive'>
<table id='maintable_data' style="text-align:center;" border="1" cellspacing="0" width="100%">
<tr>
<th><A href='?src=[REF(src)];choice=Sorting;sort=name'>Name</A></th>
<th><A href='?src=[REF(src)];choice=Sorting;sort=id'>ID</A></th>
<th><A href='?src=[REF(src)];choice=Sorting;sort=rank'>Rank</A></th>
<th><A href='?src=[REF(src)];choice=Sorting;sort=fingerprint'>Fingerprints</A></th>
<th>Criminal Status</th>
</tr>"}
					if(!isnull(GLOB.data_core.general))
						for(var/datum/data/record/R in sortRecord(GLOB.data_core.general, sortBy, order))
							var/crimstat = ""
							for(var/datum/data/record/E in GLOB.data_core.security)
								if((E.fields["name"] == R.fields["name"]) && (E.fields["id"] == R.fields["id"]))
									crimstat = E.fields["criminal"]
							var/background
							switch(crimstat)
								if(SEC_RECORD_STATUS_ARREST)
									background = "'background-color:#990000;'"
								if(SEC_RECORD_STATUS_EXECUTE)
									background = "'background-color:#990000;'"
								if(SEC_RECORD_STATUS_INCARCERATED)
									background = "'background-color:#990000;'"
								if(SEC_RECORD_STATUS_RELEASED)
									background = "'background-color:#4F7529;'"
								if(SEC_RECORD_STATUS_PAROLLED)
									background = "'background-color:#4F7529;'"
								if(SEC_RECORD_STATUS_DEMOTE)
									background = "'background-color:#CD6500;'"
								if(SEC_RECORD_STATUS_SEARCH)
									background = "'background-color:#CD6500;'"
								if(SEC_RECORD_STATUS_MONITOR)
									background = "'background-color:#006699;'"
								if(SEC_RECORD_STATUS_DISCHARGED)
									background = "'background-color:#4F7529;'"
								if("")
									background = "''" //"'background-color:#FFFFFF;'"
									crimstat = "No Record."
							dat += "<tr style=[background]>"
							dat += text("<td><input type='hidden' value='[] [] [] []'></input><A href='?src=[REF(src)];choice=Browse Record;d_rec=[REF(R)]'>[]</a></td>", R.fields["name"], R.fields["id"], R.fields["rank"], R.fields["fingerprint"], R.fields["name"])
							dat += text("<td>[]</td>", R.fields["id"])
							dat += text("<td>[]</td>", R.fields["rank"])
							dat += text("<td>[]</td>", R.fields["fingerprint"])
							dat += text("<td>[]</td></tr>", crimstat)
						dat += {"
						</table></span>
						<script type='text/javascript'>
							var maintable = document.getElementById("maintable_data_archive");
							var complete_list = maintable.innerHTML;
						</script>
						<hr width='75%' />"}
					dat += "<A href='?src=[REF(src)];choice=Record Maintenance'>Record Maintenance</A><br><br>"
					dat += "<A href='?src=[REF(src)];choice=Log Out'>{Log Out}</A>"
				if(2)
					dat += "<B>Records Maintenance</B><HR>"
					dat += "<BR><A href='?src=[REF(src)];choice=Delete All Records'>Delete All Records</A><BR><BR><A href='?src=[REF(src)];choice=Return'>Back</A>"
				if(3)
					dat += "<font size='4'><b>Security Record</b></font><br>"
					if(istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1))
						if(istype(active1.fields["photo_front"], /obj/item/photo))
							var/obj/item/photo/P1 = active1.fields["photo_front"]
							user << browse_rsc(P1.picture.picture_image, "photo_front")
						if(istype(active1.fields["photo_side"], /obj/item/photo))
							var/obj/item/photo/P2 = active1.fields["photo_side"]
							user << browse_rsc(P2.picture.picture_image, "photo_side")
						dat += {"<table><tr><td><table>
						<tr><td>Name:</td><td><A href='?src=[REF(src)];choice=Edit Field;field=name'>&nbsp;[active1.fields["name"]]&nbsp;</A></td></tr>
						<tr><td>ID:</td><td><A href='?src=[REF(src)];choice=Edit Field;field=id'>&nbsp;[active1.fields["id"]]&nbsp;</A></td></tr>
						<tr><td>Gender:</td><td><A href='?src=[REF(src)];choice=Edit Field;field=gender'>&nbsp;[active1.fields["gender"]]&nbsp;</A></td></tr>
						<tr><td>Age:</td><td><A href='?src=[REF(src)];choice=Edit Field;field=age'>&nbsp;[active1.fields["age"]]&nbsp;</A></td></tr>"}
						dat += "<tr><td>Species:</td><td><A href ='?src=[REF(src)];choice=Edit Field;field=species'>&nbsp;[active1.fields["species"]]&nbsp;</A></td></tr>"
						var/record_rank = GetJobName(active1.fields["rank"])
						var/datum/job/job_datum = SSjob.name_occupations[record_rank]
						var/how_many_alts = job_datum ? length(job_datum.alt_titles) : null
						dat += {"<tr><td>Rank:</td><td><A href='?src=[REF(src)];choice=Edit Field;field=rank'>&nbsp;[active1.fields["rank"]]&nbsp;</A>
						<br />
						<a href='?src=[REF(src)];choice=Edit Field;field=alt_title;rank=[record_rank]'>Change title<span style='color:#BBBBBB; font-style: italic;'> ([how_many_alts + 1] options)</span></a></td></tr>
						<tr><td>Fingerprint:</td><td><A href='?src=[REF(src)];choice=Edit Field;field=fingerprint'>&nbsp;[active1.fields["fingerprint"]]&nbsp;</A></td></tr>
						<tr><td>Physical Status:</td><td>&nbsp;[active1.fields["p_stat"]]&nbsp;</td></tr>
						<tr><td>Mental Status:</td><td>&nbsp;[active1.fields["m_stat"]]&nbsp;</td></tr>
						</table></td>
						<td><table><td align = center><a href='?src=[REF(src)];choice=Edit Field;field=show_photo_front'><img src=photo_front height=80 width=80 border=4></a><br>
						<a href='?src=[REF(src)];choice=Edit Field;field=print_photo_front'>Print photo</a><br>
						<a href='?src=[REF(src)];choice=Edit Field;field=upd_photo_front'>Update front photo</a></td>
						<td align = center><a href='?src=[REF(src)];choice=Edit Field;field=show_photo_side'><img src=photo_side height=80 width=80 border=4></a><br>
						<a href='?src=[REF(src)];choice=Edit Field;field=print_photo_side'>Print photo</a><br>
						<a href='?src=[REF(src)];choice=Edit Field;field=upd_photo_side'>Update side photo</a></td></table>
						</td></tr></table></td></tr></table>"}
					else
						dat += "<br>General Record Lost!<br>"
					if((istype(active2, /datum/data/record) && GLOB.data_core.security.Find(active2)))
						dat += "<font size='4'><b>Security Data</b></font>"
						dat += "<br>Criminal Status: <A href='?src=[REF(src)];choice=Edit Field;field=criminal'>[active2.fields["criminal"]]</A>"
						dat += "<br><br>Minor Crimes: <A href='?src=[REF(src)];choice=Edit Field;field=mi_crim_add'>Add New</A>"

						// BLUEMOON EDIT START - возможность пометить правонарушение как обработанное и от имени ЦК | Логи у рекордса
						dat +={"<table style="text-align:center;" border="1" cellspacing="0" width="100%">
						<tr>
						<th>Crime</th>
						<th>Details</th>
						<th>Author</th>
						<th>Time Added</th>
						<th>Penalty Incurred</th>
						<th>Del</th>
						</tr>"}
						for(var/datum/data/crime/c in active2.fields["mi_crim"])
							dat += "<tr><td>[c.crimeName]</td>"
							dat += "<td>[c.crimeDetails][c.centcom_enforced ? "<br><b style='color:green'>АВТОРИЗОВАНО ЦЕНТРАЛЬНЫМ КОМАНДОВАНИЕМ</b>" : ""]</td>"
							dat += "<td>[c.author]</td>"
							dat += "<td>[c.time]</td>"
							dat += "<td>[c.penalties_incurred ? "<b style='color:green'>ДА</b>" : "<b style='color:red'>НЕТ</b>"]<BR><A href='?src=[REF(src)];choice=Edit Field;field=crim_incur_switch;cdataid=[c.dataId]'>\[Switch\]</A></td>"
							dat += "<td><A href='?src=[REF(src)];choice=Edit Field;field=mi_crim_delete;cdataid=[c.dataId]'>\[X\]</A></td>"
							dat += "</tr>"
						dat += "</table>"


						dat += "<br>Major Crimes: <A href='?src=[REF(src)];choice=Edit Field;field=ma_crim_add'>Add New</A>"

						dat +={"<table style="text-align:center;" border="1" cellspacing="0" width="100%">
						<tr>
						<th>Crime</th>
						<th>Details</th>
						<th>Author</th>
						<th>Time Added</th>
						<th>Penalty Incurred</th>
						<th>Del</th>
						</tr>"}
						for(var/datum/data/crime/c in active2.fields["ma_crim"])
							dat += "<tr><td>[c.crimeName]</td>"
							dat += "<td>[c.crimeDetails][c.centcom_enforced ? "<br><b>[span_green("АВТОРИЗОВАНО ЦЕНТРАЛЬНЫМ КОМАНДОВАНИЕМ")]</b>" : ""]</td>"
							dat += "<td>[c.author]</td>"
							dat += "<td>[c.time]</td>"
							dat += "<td>[c.penalties_incurred ? "<b style='color:green'>ДА</b>" : "<b style='color:red'>НЕТ</b>"]<BR><A href='?src=[REF(src)];choice=Edit Field;field=crim_incur_switch;cdataid=[c.dataId]'>\[Switch\]</A></td>"
							dat += "<td><A href='?src=[REF(src)];choice=Edit Field;field=ma_crim_delete;cdataid=[c.dataId]'>\[X\]</A></td>"
							dat += "</tr>"
						dat += "</table>"

						dat += "<br>\nImportant Notes:<br>\n\t<A href='?src=[REF(src)];choice=Edit Field;field=notes'>&nbsp;[active2.fields["notes"]]&nbsp;</A>"
						dat += "<br><br><font size='4'><b>Comments/Log</b></font><br>"
						var/list/logs = active2.fields["actions_logs"]
						var/log_string = logs.Join("<br>")
						dat += "<br>\n<b>Actions Logs</b>:<br>[log_string]\n\t"
						dat += "<br><A href='?src=[REF(src)];choice=Print Logs;'>Print Logs</A>"
						dat += "<A href='?src=[REF(src)];choice=Delete Logs;'>Delete Logs</A>"
						dat += "<br><br><b>Comments</b><br>"
						// BLUEMOON EDIT END
						var/counter = 1
						while(active2.fields[text("com_[]", counter)])
							dat += (active2.fields[text("com_[]", counter)] + "<BR>")
							if(active2.fields[text("com_[]", counter)] != "<B>Deleted</B>")
								dat += text("<A href='?src=[REF(src)];choice=Delete Entry;del_c=[]'>Delete Entry</A><BR><BR>", counter)
							counter++
						dat += "<A href='?src=[REF(src)];choice=Add Entry'>Add Entry</A><br><br>"
						dat += "<A href='?src=[REF(src)];choice=Delete Record (Security)'>Delete Record (Security Only)</A><br>"
					else
						dat += "Security Record Lost!<br>"
						dat += "<A href='?src=[REF(src)];choice=New Record (Security)'>New Security Record</A><br><br>"
					dat += "<A href='?src=[REF(src)];choice=Delete Record (ALL)'>Delete Record (ALL)</A><br><A href='?src=[REF(src)];choice=Print Record'>Print Record</A><BR><A href='?src=[REF(src)];choice=Print Poster'>Print Wanted Poster</A><BR><A href='?src=[REF(src)];choice=Generate Arrest Warrant'>Generate Arrest Warrant</A><BR><A href='?src=[REF(src)];choice=Return'>Back</A><BR><BR>"
					dat += "<A href='?src=[REF(src)];choice=Log Out'>{Log Out}</A>"
				else
		else
			dat += "<A href='?src=[REF(src)];choice=Log In'>{Log In}</A>"
	var/datum/browser/popup = new(user, "secure_rec", "Security Records Console", 600, 400)
	popup.set_content(dat)
	popup.open()
	return

/*Revised /N
I can't be bothered to look more of the actual code outside of switch but that probably needs revising too.
What a mess.*/
// BLUEMOON EDIT START - (((нанорефактор))) этого говна, когда-то понадобится реальный рефактор, но мне за это не платят.
/obj/machinery/computer/secure_data/Topic(href, href_list)
	. = ..()
	if(.)
		return .
	if(!( GLOB.data_core.general.Find(active1) ))
		active1 = null
	if(!( GLOB.data_core.security.Find(active2) ))
		active2 = null
	if(!authenticated && href_list["choice"] != "Log In") // logging in is the only action you can do if not logged in
		return
	if(!(usr.contents.Find(src) || (in_range(src, usr) && isturf(loc)) || hasSiliconAccessInArea(usr) || IsAdminGhost(usr)))
		to_chat(usr, span_warning("Вы не можете взаимодействовать с [src]!"))
		return
	if(printing)
		to_chat(usr, span_warning("Вы не можете взаимодействовать с [src], пока устройство занято печатью."))
		return
	usr.set_machine(src)
	switch(href_list["choice"])
		// SORTING!
		if("Sorting")
			// Reverse the order if clicked twice
			if(sortBy == href_list["sort"])
				if(order == 1)
					order = -1
				else
					order = 1
			else
			// New sorting order!
				sortBy = href_list["sort"]
				order = initial(order)
		//BASIC FUNCTIONS
		if("Clear Screen")
			temp = null

		if("Return")
			screen = 1
			active1 = null
			active2 = null

		if("Log Out")
			authenticated = null
			screen = null
			active1 = null
			active2 = null

			logged_access = null

			playsound(src, 'sound/machines/terminal_off.ogg', 50, FALSE)

		if("Log In")
			var/mob/M = usr
			var/obj/item/card/id/I = M.get_idcard(TRUE)
			if(hasSiliconAccessInArea(M))
				var/mob/living/silicon/borg = M
				active1 = null
				active2 = null
				authenticated = borg.name
				rank = "AI"
				screen = 1

				logged_access = get_all_accesses()

			else if(IsAdminGhost(M))
				active1 = null
				active2 = null
				authenticated = M.client.holder.admin_signature
				rank = "Central Command"
				screen = 1

				logged_access = get_centcom_access("CentCom Commander")

			else if(I && check_access(I))
				active1 = null
				active2 = null
				authenticated = I.registered_name
				rank = I.get_assignment_name()
				screen = 1

				logged_access = I.access

			else
				to_chat(usr, "<span class='danger'>Unauthorized Access.</span>")
			playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)

		//RECORD FUNCTIONS
		if("Record Maintenance")
			screen = 2
			active1 = null
			active2 = null

		if("Browse Record")
			var/datum/data/record/R = locate(href_list["d_rec"]) in GLOB.data_core.general
			if(!R)
				temp = "Record Not Found!"
			else
				active1 = active2 = R
				for(var/datum/data/record/E in GLOB.data_core.security)
					if((E.fields["name"] == R.fields["name"] || E.fields["id"] == R.fields["id"]))
						active2 = E
				screen = 3


		if("Print Record")
			if(!( printing ))
				printing = 1
				GLOB.data_core.securityPrintCount++
				playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
				sleep(30)
				var/obj/item/paper/P = new /obj/item/paper( loc )
				var/report_text = "<CENTER><B>Security Record - (SR-[GLOB.data_core.securityPrintCount])</B></CENTER><BR>"
				if((istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1)))
					report_text += text("Name: [] ID: []<BR>\nGender: []<BR>\nAge: []<BR>", active1.fields["name"], active1.fields["id"], active1.fields["gender"], active1.fields["age"])
					report_text += "\nSpecies: [active1.fields["species"]]<BR>"
					report_text += text("\nFingerprint: []<BR>\nPhysical Status: []<BR>\nMental Status: []<BR>", active1.fields["fingerprint"], active1.fields["p_stat"], active1.fields["m_stat"])
				else
					report_text += "<B>General Record Lost!</B><BR>"
				if((istype(active2, /datum/data/record) && GLOB.data_core.security.Find(active2)))
					report_text += text("<BR>\n<CENTER><B>Security Data</B></CENTER><BR>\nCriminal Status: []", active2.fields["criminal"])

					report_text += "<BR>\n<BR>\nMinor Crimes:<BR>\n"
					report_text +={"<table style="text-align:center;" border="1" cellspacing="0" width="100%">
<tr>
<th>Crime</th>
<th>Details</th>
<th>Author</th>
<th>Time Added</th>
</tr>"}
					for(var/datum/data/crime/c in active2.fields["mi_crim"])
						report_text += "<tr><td>[c.crimeName]</td>"
						report_text += "<td>[c.crimeDetails]</td>"
						report_text += "<td>[c.author]</td>"
						report_text += "<td>[c.time]</td>"
						report_text += "</tr>"
					report_text += "</table>"

					report_text += "<BR>\nMajor Crimes: <BR>\n"
					report_text +={"<table style="text-align:center;" border="1" cellspacing="0" width="100%">
<tr>
<th>Crime</th>
<th>Details</th>
<th>Author</th>
<th>Time Added</th>
</tr>"}
					for(var/datum/data/crime/c in active2.fields["ma_crim"])
						report_text += "<tr><td>[c.crimeName]</td>"
						report_text += "<td>[c.crimeDetails]</td>"
						report_text += "<td>[c.author]</td>"
						report_text += "<td>[c.time]</td>"
						report_text += "</tr>"
					report_text += "</table>"


					report_text += text("<BR>\nImportant Notes:<BR>\n\t[]<BR>\n<BR>\n<CENTER><B>Comments/Log</B></CENTER><BR>", active2.fields["notes"])
					var/counter = 1
					while(active2.fields[text("com_[]", counter)])
						report_text += text("[]<BR>", active2.fields[text("com_[]", counter)])
						counter++
					P.name = text("SR-[] '[]'", GLOB.data_core.securityPrintCount, active1.fields["name"])
				else
					report_text += "<B>Security Record Lost!</B><BR>"
					P.name = text("SR-[] '[]'", GLOB.data_core.securityPrintCount, "Record Lost")
				report_text += "</TT>"
				P.add_raw_text(report_text)
				P.update_appearance()
				P.update_icon()
				printing = null
		// BLUEMOON ADD START - возможность распечатать автоматически сгенерированный ордер
		if("Generate Arrest Warrant")
			if(printing)
				return
			if(!canUseSecurityRecordsConsole(usr, "print", active1, active2))
				return
			if(!(istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1)) || !(istype(active2, /datum/data/record) && GLOB.data_core.security.Find(active2)))
				say("Данные повреждены!")
				return
			var/list/crimes = active2.fields["ma_crim"] + active2.fields["mi_crim"]
			if(!crimes.len) // Можно было ещё по c.penalties_incurred отфильтровать, но чёрт с ним
				say("Правонарушения отсутствуют!")
				return
			printing = 1
			GLOB.data_core.securityPrintCount++
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
			sleep(30)
			var/obj/item/paper/P = new /obj/item/paper( loc )
			var/report_text = ""
			report_text += {"
				<h1><div align=\"center\">Ордер на арест №[GLOB.data_core.securityPrintCount]</div></h1>
				<p><strong>Задерживаемый субъект:</strong>  [active1.fields["name"]]</p>
				<p><strong>Причина задержания:</strong></p>
				<p>Разыскивается службой безопасности [GLOB.station_name] в связи с нарушением статей Космического Закона::</p>"}
			for(var/datum/data/crime/c in crimes)
				if(c.penalties_incurred)
					continue
				var/crime_text = "<p>"
				crime_text += "<b>" + c.crimeName + "</b> - " + c.crimeDetails
				if(c.centcom_enforced)
					crime_text += " <i>\[Центкомм\]</i>"
				crime_text += "</p>"
				report_text += crime_text
			report_text += {"
				<p><strong><div align=\"center\">Подписи и печати</strong></div></p>
				<p><strong>Подпись составителя:</strong></p>
				<p>\[________________________________________________________________\]</p>
				<p><strong>Должность составителя:</strong></p>
				<p>[rank]</p>
				<p><strong>Дата:</strong></p>
				<p>Время: [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]</p>
				<p>Дата: [time2text(world.realtime, "MMM DD")] [GLOB.year_integer]</p>
				<p><strong>Место для печатей</strong></p>
				<hr/>
				<br>
				<br>
				<br>
				<hr/>
				<font color=\"grey\"><div align=\"justify\">Основная часть документа сгенерирована автоматически.</div></font></p>
				<font color=\"grey\"><div align=\"justify\">Данный документ считается действительным только при наличии подписи и печати, если таковая имеется.</div></font></p>
				<font color=\"grey\"><div align=\"justify\">Данный документ имеет юридическую силу, только если составлен уполномоченным лицом.</div></font></p>"}
			P.add_raw_text(report_text)
			P.name = "Ордер на арест - [active1.fields["name"]]"
			P.update_appearance()
			P.update_icon()
			printing = null
		// BLUEMOON ADD END
		if("Print Poster")
			if(!( printing ))
				var/wanted_name = stripped_input(usr, "Please enter an alias for the criminal:", "Print Wanted Poster", active1.fields["name"])
				if(wanted_name)
					var/default_description = "A poster declaring [wanted_name] to be a dangerous individual, wanted by Nanotrasen. Report any sightings to security immediately."
					var/list/major_crimes = active2.fields["ma_crim"]
					var/list/minor_crimes = active2.fields["mi_crim"]
					if(major_crimes.len + minor_crimes.len)
						default_description += "\n[wanted_name] is wanted for the following crimes:\n"
					if(minor_crimes.len)
						default_description += "\nMinor Crimes:"
						for(var/datum/data/crime/c in active2.fields["mi_crim"])
							default_description += "\n[c.crimeName]\n"
							default_description += "[c.crimeDetails]\n"
					if(major_crimes.len)
						default_description += "\nMajor Crimes:"
						for(var/datum/data/crime/c in active2.fields["ma_crim"])
							default_description += "\n[c.crimeName]\n"
							default_description += "[c.crimeDetails]\n"

					var/info = stripped_multiline_input(usr, "Please input a description for the poster:", "Print Wanted Poster", default_description, null)
					if(info)
						playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
						printing = 1
						sleep(30)
						if((istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1)))//make sure the record still exists.
							var/obj/item/photo/photo = active1.fields["photo_front"]
							new /obj/item/poster/wanted(loc, photo.picture.picture_image, wanted_name, info)
						printing = 0

		//RECORD DELETE
		if("Delete All Records")
			temp = ""
			temp += "Are you sure you wish to delete all Security records?<br>"
			temp += "<a href='?src=[REF(src)];choice=Purge All Records'>Yes</a><br>"
			temp += "<a href='?src=[REF(src)];choice=Clear Screen'>No</a>"

		if("Purge All Records")
			investigate_log("[key_name(usr)] has purged all the security records.", INVESTIGATE_RECORDS)
			for(var/datum/data/record/R in GLOB.data_core.security)
				qdel(R)
			GLOB.data_core.security.Cut()
			temp = "All Security records deleted."

		if("Add Entry")
			if(!( istype(active2, /datum/data/record) ))
				return
			var/a2 = active2
			var/t1 = stripped_multiline_input("Add Comment:", "Secure. records", null, null)
			if(!canUseSecurityRecordsConsole(usr, t1, null, a2))
				return
			var/counter = 1
			while(active2.fields[text("com_[]", counter)])
				counter++
			active2.fields[text("com_[]", counter)] = text("Made by [] ([]) on [] [], []<BR>[]", src.authenticated, src.rank, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), time2text(world.realtime, "MMM DD"), GLOB.year_integer, t1)

		if("Delete Record (ALL)")
			if(active1)
				temp = "<h5>Are you sure you wish to delete the record (ALL)?</h5>"
				temp += "<a href='?src=[REF(src)];choice=Delete Record (ALL) Execute'>Yes</a><br>"
				temp += "<a href='?src=[REF(src)];choice=Clear Screen'>No</a>"

		if("Delete Record (Security)")
			if(active2)
				temp = "<h5>Are you sure you wish to delete the record (Security Portion Only)?</h5>"
				temp += "<a href='?src=[REF(src)];choice=Delete Record (Security) Execute'>Yes</a><br>"
				temp += "<a href='?src=[REF(src)];choice=Clear Screen'>No</a>"

		if("Delete Entry")
			if((istype(active2, /datum/data/record) && active2.fields[text("com_[]", href_list["del_c"])]))
				active2.fields[text("com_[]", href_list["del_c"])] = "<B>Deleted</B>"
		//RECORD CREATE
		if("New Record (Security)")
			if((istype(active1, /datum/data/record) && !( istype(active2, /datum/data/record) )))
				var/datum/data/record/R = new /datum/data/record()
				R.fields["name"] = active1.fields["name"]
				R.fields["id"] = active1.fields["id"]
				R.name = text("Security Record #[]", R.fields["id"])
				R.fields["criminal"] = SEC_RECORD_STATUS_NONE
				R.fields["mi_crim"] = list()
				R.fields["ma_crim"] = list()
				R.fields["notes"] = "No notes."
				GLOB.data_core.security += R
				active2 = R
				screen = 3

		if("New Record (General)")
			//General Record
			var/datum/data/record/G = new /datum/data/record()
			G.fields["name"] = "New Record"
			G.fields["id"] = "[num2hex(rand(1, 1.6777215E7), 6)]"
			G.fields["rank"] = "Unassigned"
			G.fields["gender"] = "Male"
			G.fields["age"] = "Unknown"
			G.fields["species"] = "Human"
			G.fields["photo_front"] = new /icon()
			G.fields["photo_side"] = new /icon()
			G.fields["fingerprint"] = "?????"
			G.fields["p_stat"] = "Active"
			G.fields["m_stat"] = "Stable"
			GLOB.data_core.general += G
			active1 = G

			//Security Record
			var/datum/data/record/R = new /datum/data/record()
			R.fields["name"] = active1.fields["name"]
			R.fields["id"] = active1.fields["id"]
			R.name = text("Security Record #[]", R.fields["id"])
			R.fields["criminal"] = SEC_RECORD_STATUS_NONE
			R.fields["mi_crim"] = list()
			R.fields["ma_crim"] = list()
			R.fields["notes"] = "No notes."
			R.fields["actions_logs"] = list(
				"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [active1.fields["name"]] | N/A | [active1.fields["id"]] -- ИНИЦИАТОР: [authenticated] ([rank]);</u><br>"
				)
			GLOB.data_core.security += R
			active2 = R

			//Medical Record
			var/datum/data/record/M = new /datum/data/record()
			M.fields["id"]			= active1.fields["id"]
			M.fields["name"]		= active1.fields["name"]
			M.fields["blood_type"]	= "?"
			M.fields["b_dna"]		= "?????"
			M.fields["mi_dis"]		= "None"
			M.fields["mi_dis_d"]	= "No minor disabilities have been declared."
			M.fields["ma_dis"]		= "None"
			M.fields["ma_dis_d"]	= "No major disabilities have been diagnosed."
			M.fields["alg"]			= "None"
			M.fields["alg_d"]		= "No allergies have been detected in this patient."
			M.fields["cdi"]			= "None"
			M.fields["cdi_d"]		= "No diseases have been diagnosed at the moment."
			M.fields["notes"]		= "No notes."
			GLOB.data_core.medical += M


		// Возможность распечатать логи
		if("Print Logs")
			if(!istype(active2, /datum/data/record))
				return
			if(printing)
				return
			if(!canUseSecurityRecordsConsole(usr, "print", active1, active2))
				return
			if(!(istype(active1, /datum/data/record) && GLOB.data_core.general.Find(active1)) || !(istype(active2, /datum/data/record) && GLOB.data_core.security.Find(active2)))
				say("Данные повреждены!")
				return
			var/list/logs = active2.fields["actions_logs"]
			printing = 1
			GLOB.data_core.securityPrintCount++
			playsound(loc, 'sound/items/poster_being_created.ogg', 100, 1)
			sleep(30)
			var/obj/item/paper/P = new /obj/item/paper( loc )
			var/log_text = ""
			log_text += {"
				<h1><div align=\"center\">ЛОГИ ЗАПИСЕЙ | СЛУЖБА БЕЗОПАСНОСТИ</div></h1>
				<p><strong>ОБЪЕКТ:</strong>  [GLOB.station_name]</p>
				<p><strong>ДАТА ЗАПРОСА:</strong>  [GLOB.current_date_string]</p>
				<p><strong>ВРЕМЯ ЗАПРОСА:</strong>  [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]</p>
				<p><strong>ЗАПИСЬ:</strong>  [active1.fields["id"]]</p>
				<p><strong>ИМЯ СУБЪЕКТА:</strong> [active1.fields["name"]]</p>
				<hr><br><center><div align=\"center\"><b>НАЧАЛО ЗАПИСИ</b></center></div>
				"}
			for(var/log in logs)
				log_text += "<br>[log]"
			log_text += "<br><br><div align=\"center\"><b>КОНЕЦ ЗАПИСИ</b></div><hr><br>"
			P.add_raw_text(log_text)
			P.name = "Database Logs - [active1.fields["name"]] - [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
			var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
			P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 50, 1, "stamp-machine")
			P.update_appearance()
			P.update_icon()
			printing = null

		if("Delete Logs")
			if(!istype(active2, /datum/data/record))
				return
			if(!(ACCESS_HOS in logged_access))
				to_chat(usr, span_warning("У вас нет полномочий для данного действия: необходим доступ не ниже Главы Службы Безопасности."))
				return
			active2.fields["actions_logs"] = list(
				"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЛОГИ ОЧИЩЕНЫ УПРАВЛЯЮЩИМ [authenticated] | [rank];</u><br>"
			)

		//FIELD FUNCTIONS
		if("Edit Field")
			var/a1 = active1
			var/a2 = active2

			switch(href_list["field"])
				if("name")
					if(istype(active1, /datum/data/record) || istype(active2, /datum/data/record))
						var/t1 = stripped_input(usr, "Please input name:", "Secure. records", active1.fields["name"], MAX_MESSAGE_LEN)
						if(!canUseSecurityRecordsConsole(usr, t1, a1))
							return
						if(istype(active1, /datum/data/record))
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% сменил поле \"имя\" с [active1.fields["name"]] на [t1] | ОБЩИЕ ЗАПИСИ",
								authenticated,
								rank
							)
							active1.fields["name"] = t1
						if(istype(active2, /datum/data/record))
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% сменил поле \"имя\" с [active2.fields["name"]] на [t1] | ЗАПИСИ БЕЗОПАСНОСТИ",
								authenticated,
								rank
							)
							active2.fields["name"] = t1
				if("id")
					if(istype(active2, /datum/data/record) || istype(active1, /datum/data/record))
						var/t1 = stripped_input(usr, "Please input id:", "Secure. records", active1.fields["id"], null)
						if(!canUseSecurityRecordsConsole(usr, t1, a1))
							return
						if(istype(active1, /datum/data/record))
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% сменил поле \"ID\" с [active1.fields["id"]] на [t1] | ОБЩИЕ ЗАПИСИ",
								authenticated,
								rank
							)
							active1.fields["id"] = t1
						if(istype(active2, /datum/data/record))
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% сменил поле \"ID\" с [active2.fields["id"]] на [t1] | ЗАПИСИ БЕЗОПАСНОСТИ",
								authenticated,
								rank
							)
							active2.fields["id"] = t1
				if("fingerprint")
					if(istype(active1, /datum/data/record))
						var/t1 = stripped_input(usr, "Please input fingerprint hash:", "Secure. records", active1.fields["fingerprint"], null)
						if(!canUseSecurityRecordsConsole(usr, t1, a1))
							return
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% сменил поле \"отпечаток\" с [active1.fields["fingerprint"]] на [t1]",
							authenticated,
							rank
						)
						active1.fields["fingerprint"] = t1
				if("gender")
					if(istype(active1, /datum/data/record))
						var/old_gender = active1.fields["gender"]
						if(active1.fields["gender"] == "Male")
							active1.fields["gender"] = "Female"
						else if(active1.fields["gender"] == "Female")
							active1.fields["gender"] = "Other"
						else
							active1.fields["gender"] = "Male"
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% сменил поле \"гендер\" с [old_gender] на [active1.fields["gender"]]",
							authenticated,
							rank
						)
				if("age")
					if(istype(active1, /datum/data/record))
						var/t1 = input("Please input age:", "Secure. records", active1.fields["age"], null) as num
						if(!canUseSecurityRecordsConsole(usr, "age", a1))
							return
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% сменил поле \"возраст\" с [active1.fields["age"]] на [t1]",
							authenticated,
							rank
						)
						active1.fields["age"] = t1
				if("species")
					if(istype(active1, /datum/data/record))
						var/t1 = stripped_input("Please input species name", "Sec. records", active1.fields["species"], null)
						if(!canUseSecurityRecordsConsole(usr, t1, a1))
							return
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% сменил поле \"вид\" с [active1.fields["species"]] на [t1]",
							authenticated,
							rank
						)
						active1.fields["species"] = t1
				if("show_photo_front")
					if(active1.fields["photo_front"])
						if(istype(active1.fields["photo_front"], /obj/item/photo))
							var/obj/item/photo/P = active1.fields["photo_front"]
							P.show(usr)
				if("upd_photo_front")
					var/obj/item/photo/photo = get_photo(usr)
					if(photo)
						qdel(active1.fields["photo_front"])
						//Lets center it to a 32x32.
						var/icon/I = photo.picture.picture_image
						var/w = I.Width()
						var/h = I.Height()
						var/dw = w - 32
						var/dh = w - 32
						I.Crop(dw/2, dh/2, w - dw/2, h - dh/2)
						active1.fields["photo_front"] = photo
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% отредактировал фотографию №1",
							authenticated,
							rank
						)
				if("print_photo_front")
					if(active1.fields["photo_front"])
						if(istype(active1.fields["photo_front"], /obj/item/photo))
							var/obj/item/photo/P = active1.fields["photo_front"]
							print_photo(P.picture.picture_image, active1.fields["name"])
				if("show_photo_side")
					if(active1.fields["photo_side"])
						if(istype(active1.fields["photo_side"], /obj/item/photo))
							var/obj/item/photo/P = active1.fields["photo_side"]
							P.show(usr)
				if("upd_photo_side")
					var/obj/item/photo/photo = get_photo(usr)
					if(photo)
						qdel(active1.fields["photo_side"])
						//Lets center it to a 32x32.
						var/icon/I = photo.picture.picture_image
						var/w = I.Width()
						var/h = I.Height()
						var/dw = w - 32
						var/dh = w - 32
						I.Crop(dw/2, dh/2, w - dw/2, h - dh/2)
						active1.fields["photo_side"] = photo
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% отредактировал фотографию №2",
							authenticated,
							rank
						)
				if("print_photo_side")
					if(active1.fields["photo_side"])
						if(istype(active1.fields["photo_side"], /obj/item/photo))
							var/obj/item/photo/P = active1.fields["photo_side"]
							print_photo(P.picture.picture_image, active1.fields["name"])

				if("mi_crim_add")
					if(istype(active1, /datum/data/record))
						var/t1 = stripped_input(usr, "Please input minor crime names:", "Secure. records", "", null)
						var/t2 = stripped_input(usr, "Please input minor crime details:", "Secure. records", "", null)
						if(!canUseSecurityRecordsConsole(usr, t1, null, a2))
							return
						var/centcom_authority = (ACCESS_CENT_CAPTAIN in logged_access) // BLUEMOON EDIT - авторизация ЦК
						var/crime = GLOB.data_core.createCrimeEntry(t1, t2, authenticated, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), centcom_authority)
						GLOB.data_core.addMinorCrime(active1.fields["id"], crime)
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% записал некрупное преступление: <b>[t1]</b>, [t2]",
							authenticated,
							rank
						)
						investigate_log("New Minor Crime: <strong>[t1]</strong>: [t2] | Added to [active1.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
				if("mi_crim_delete")
					if(istype(active1, /datum/data/record))
						if(href_list["cdataid"])
							if(!canUseSecurityRecordsConsole(usr, "delete", null, a2))
								return
							var/centcom_authority = (ACCESS_CENT_CAPTAIN in logged_access) // BLUEMOON EDIT - авторизация ЦК
							GLOB.data_core.removeMinorCrime(active1.fields["id"], href_list["cdataid"], centcom_authority)
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% удалил некрупное преступление №[href_list["cdataid"]]",
								authenticated,
								rank
							)
				if("ma_crim_add")
					if(istype(active1, /datum/data/record))
						var/t1 = stripped_input(usr, "Please input major crime names:", "Secure. records", "", null)
						var/t2 = stripped_input(usr, "Please input major crime details:", "Secure. records", "", null)
						if(!canUseSecurityRecordsConsole(usr, t1, null, a2))
							return
						var/centcom_authority = (ACCESS_CENT_CAPTAIN in logged_access) // BLUEMOON EDIT - авторизация ЦК
						var/crime = GLOB.data_core.createCrimeEntry(t1, t2, authenticated, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time), centcom_authority)
						GLOB.data_core.addMajorCrime(active1.fields["id"], crime)
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% записал крупное преступление: <b>[t1]</b>, [t2]",
							authenticated,
							rank
						)
						investigate_log("New Major Crime: <strong>[t1]</strong>: [t2] | Added to [active1.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
				if("ma_crim_delete")
					if(istype(active1, /datum/data/record))
						if(href_list["cdataid"])
							if(!canUseSecurityRecordsConsole(usr, "delete", null, a2))
								return
							var/centcom_authority = (ACCESS_CENT_CAPTAIN in logged_access) // BLUEMOON EDIT - авторизация ЦК
							GLOB.data_core.removeMajorCrime(active1.fields["id"], href_list["cdataid"], centcom_authority)
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% удалил крупное преступление №[href_list["cdataid"]]",
								authenticated,
								rank
							)
				// BLUEMOON ADD START - возможность пометить правонарушение как обработанное
				if("crim_incur_switch")
					if(istype(active1, /datum/data/record))
						if(href_list["cdataid"])
							if(!canUseSecurityRecordsConsole(usr, "incur", null, a2))
								return
							GLOB.data_core.switch_incur(active1.fields["id"], href_list["cdataid"])
							GLOB.data_core.append_sec_logs(
								active1.fields["id"],
								"%%GEN_AUTH%% изменил пометку \"НАКАЗАНИЕ ПОНЕСЕНО\" у преступления №[href_list["cdataid"]]",
								authenticated,
								rank
							)
				// BLUEMOON ADD END
				if("notes")
					if(istype(active2, /datum/data/record))
						var/t1 = stripped_multiline_input(usr, "Please summarize notes:", "Secure records", active2.fields["notes"], 8192)
						if(!canUseSecurityRecordsConsole(usr, t1, null, a2))
							return
						active2.fields["notes"] = t1
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% изменил служебные заметки субъекта",
							authenticated,
							rank
						)
				if("criminal")
					if(istype(active2, /datum/data/record))
						temp = "<h5>Criminal Status:</h5>"
						temp += "<ul>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=none'>Ничего</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=arrest'>*Арестовать*</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=execute'>*Уничтожить*</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=incarcerated'>Отбывает Срок</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=released'>Выпустили</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=parolled'>УДО</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=demote'>Уволить</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=search'>Искать</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=monitor'>Наблюдать</a></li>"
						temp += "<li><a href='?src=[REF(src)];choice=Change Criminal Status;criminal2=discharged'>Сняты Обвинения</a></li>"
						temp += "</ul>"
				if("rank")
					if(istype(active1, /datum/data/record) && ((ACCESS_CAPTAIN in logged_access) || (ACCESS_HOP in logged_access) || (ACCESS_CENT_GENERAL in logged_access)))
						temp = "<h5>Rank:</h5>"
						temp += "<ul>"
						for(var/rank in get_all_jobs())
							temp += "<li><a href='?src=[REF(src)];choice=Change Rank;rank=[rank]'>[rank]</a>"
							var/datum/job/job_datum = SSjob.name_occupations[rank]
							if(job_datum && length(job_datum.alt_titles))
								var/how_many_alts = length(job_datum.alt_titles)
								temp += "<a href='?src=[REF(src)];choice=Edit Field;field=alt_title;rank=[rank]'>Use Title<span style='color:#BBBBBB; font-style: italic;'> ([how_many_alts + 1] options)</span></a>"
							temp += "</li>"
						temp += "</ul>"
					else
						alert(usr, "You do not have the required rank to do this!")
				if("alt_title")
					if(istype(active1, /datum/data/record) && ((ACCESS_CAPTAIN in logged_access) || (ACCESS_HOP in logged_access) || (ACCESS_CENT_GENERAL in logged_access)))
						temp = "<h5>Rank Title:</h5>"
						temp += "<ul>"
						var/chosen_rank = href_list["rank"]
						temp += "<li><a href='?src=[REF(src)];choice=Change Rank;rank=[chosen_rank]'>[chosen_rank]</a></li><br />"
						var/datum/job/job_datum = SSjob.name_occupations[chosen_rank]
						if(job_datum && length(job_datum.alt_titles))
							for(var/rank in job_datum.alt_titles)
								temp += "<li><a href='?src=[REF(src)];choice=Change Rank;rank=[rank]'>[rank]</a></li>"
						else
							temp += "<li><b>We're very sorry, there was an internal error fetching titles. Report to centcom error: </b>null_job_or_no_titles</li>"
						temp += "</ul>"
					else
						alert(usr, "You do not have the required rank to do this!")

		//TEMPORARY MENU FUNCTIONS
		else//To properly clear as per clear screen.
			temp=null
			switch(href_list["choice"])
				if("Change Rank")
					if(active1)
						if(GetJobName(href_list["rank"]) != "Unknown" && GetJobName(href_list["rank"]) != "Centcom") // hi hello you looking, stop trying to exploit html
							active1.fields["rank"] = href_list["rank"]
							active1.fields["real_rank"] = GetJobName(href_list["rank"])

				if("Change Criminal Status")
					if(active2)
						var/old_field = active2.fields["criminal"]
						switch(href_list["criminal2"])
							if("none")
								active2.fields["criminal"] = SEC_RECORD_STATUS_NONE
							if("arrest")
								active2.fields["criminal"] = SEC_RECORD_STATUS_ARREST
							if("execute")
								active2.fields["criminal"] = SEC_RECORD_STATUS_EXECUTE
							if("incarcerated")
								active2.fields["criminal"] = SEC_RECORD_STATUS_INCARCERATED
							if("released")
								active2.fields["criminal"] = SEC_RECORD_STATUS_RELEASED
							if("parolled")
								active2.fields["criminal"] = SEC_RECORD_STATUS_PAROLLED
							if("demote")
								active2.fields["criminal"] = SEC_RECORD_STATUS_DEMOTE
							if("search")
								active2.fields["criminal"] = SEC_RECORD_STATUS_SEARCH
							if("monitor")
								active2.fields["criminal"] = SEC_RECORD_STATUS_MONITOR
							if("discharged")
								active2.fields["criminal"] = SEC_RECORD_STATUS_DISCHARGED

						investigate_log("[active1.fields["name"]] has been set from [old_field] to [active2.fields["criminal"]] by [key_name(usr)].", INVESTIGATE_RECORDS)
						for(var/mob/living/carbon/human/H in GLOB.carbon_list)
							H.sec_hud_set_security_status()
						GLOB.data_core.append_sec_logs(
							active1.fields["id"],
							"%%GEN_AUTH%% изменил статус с <b>[old_field]</b> на <b>[active2.fields["criminal"]]</b>.",
							authenticated,
							rank
						)
				if("Delete Record (Security) Execute")
					investigate_log("[key_name(usr)] has deleted the security records for [active1.fields["name"]].", INVESTIGATE_RECORDS)
					if(active2)
						qdel(active2)
						active2 = null

				if("Delete Record (ALL) Execute")
					if(active1)
						investigate_log("[key_name(usr)] has deleted all records for [active1.fields["name"]].", INVESTIGATE_RECORDS)
						for(var/datum/data/record/R in GLOB.data_core.medical)
							if((R.fields["name"] == active1.fields["name"] || R.fields["id"] == active1.fields["id"]))
								qdel(R)
								break
						qdel(active1)
						active1 = null

					if(active2)
						qdel(active2)
						active2 = null
				else
					temp = "This function does not appear to be working at the moment. Our apologies."

	add_fingerprint(usr)
	updateUsrDialog()
	return
// BLUEMOON EDIT END

/obj/machinery/computer/secure_data/proc/get_photo(mob/user)
	var/obj/item/photo/P = null
	if(issilicon(user))
		var/mob/living/silicon/tempAI = user
		var/datum/picture/selection = tempAI.GetPhoto(user)
		if(selection)
			P = new(null, selection)
	else if(istype(user.get_active_held_item(), /obj/item/photo))
		P = user.get_active_held_item()
	return P

/obj/machinery/computer/secure_data/proc/print_photo(icon/temp, person_name)
	if (printing)
		return
	printing = TRUE
	sleep(20)
	var/obj/item/photo/P = new/obj/item/photo(drop_location())
	var/datum/picture/toEmbed = new(name = person_name, desc = "The photo on file for [person_name].", image = temp)
	P.set_picture(toEmbed, TRUE, TRUE)
	P.pixel_x = rand(-10, 10)
	P.pixel_y = rand(-10, 10)
	printing = FALSE

/obj/machinery/computer/secure_data/emp_act(severity)
	. = ..()

	if(machine_stat & (BROKEN|NOPOWER) || . & EMP_PROTECT_SELF)
		return

	for(var/datum/data/record/R in GLOB.data_core.security)
		if(prob(severity/10))
			switch(rand(1,8))
				if(1)
					if(prob(10))
						R.fields["name"] = "[pick(lizard_name(MALE),lizard_name(FEMALE))]"
					else
						R.fields["name"] = "[pick(pick(GLOB.first_names_male), pick(GLOB.first_names_female))] [pick(GLOB.last_names)]"
				if(2)
					R.fields["gender"] = pick("Male", "Female", "Other")
				if(3)
					R.fields["age"] = rand(5, 85)
				if(4)
					R.fields["criminal"] = pick("None", "*Arrest*", "Incarcerated", "Paroled", "Discharged")
				if(5)
					R.fields["p_stat"] = pick("*Unconscious*", "Active", "Physically Unfit")
				if(6)
					R.fields["m_stat"] = pick("*Insane*", "*Unstable*", "*Watch*", "Stable")
				if(7)
					R.fields["species"] = pick(GLOB.roundstart_races)
				if(8)
					var/datum/data/record/G = pick(GLOB.data_core.general)
					R.fields["photo_front"] = G.fields["photo_front"]
					R.fields["photo_side"] = G.fields["photo_side"]
			continue

		else if(prob(severity/80))
			qdel(R)
			continue

/obj/machinery/computer/secure_data/proc/canUseSecurityRecordsConsole(mob/user, message1 = 0, record1, record2)
	if(user)
		if(authenticated)
			if(user.canUseTopic(src, !hasSiliconAccessInArea(user)))
				if(!trim(message1))
					return FALSE
				if(!record1 || record1 == active1)
					if(!record2 || record2 == active2)
						return TRUE
	return FALSE


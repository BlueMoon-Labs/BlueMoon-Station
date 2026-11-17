GLOBAL_LIST_EMPTY(allCasters)

/obj/item/wallframe/newscaster
	name = "newscaster frame"
	desc = "Used to build newscasters, just secure to the wall."
	icon_state = "newscaster"
	custom_materials = list(/datum/material/iron=14000, /datum/material/glass=8000)
	result_path = /obj/machinery/newscaster

/obj/machinery/newscaster
	name = "Новостник"
	desc = "Стандартный обработчик новостной ленты, лицензированный NanoTrasen для использования на коммерческих космических станциях. Все новости, которые вам совершенно не нужны, в одном месте!"
	icon = 'icons/obj/terminals.dmi'
	icon_state = "newscaster_normal"
	plane = ABOVE_WALL_PLANE
	verb_say = "beeps"
	verb_ask = "beeps"
	verb_exclaim = "beeps"
	armor_type = /datum/armor/newscaster
	max_integrity = 200
	integrity_failure = 0.25
	var/screen = 0
	var/paper_remaining = 15
	var/securityCaster = 0
	var/unit_no = 0
	var/alert_delay = 500
	var/alert = FALSE
	var/scanned_user = "Unknown"
	var/msg = ""
	var/datum/picture/picture
	var/channel_name = ""
	var/c_locked=0
	var/datum/news/feed_channel/viewing_channel = null
	var/allow_comments = 1

/obj/machinery/newscaster/security_unit
	name = "security newscaster"
	securityCaster = 1

/obj/machinery/newscaster/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -32 : 32)
		pixel_y = (dir & 3)? (dir ==1 ? -32 : 32) : 0

	GLOB.allCasters += src
	unit_no = GLOB.allCasters.len
	update_icon()

/obj/machinery/newscaster/Destroy()
	GLOB.allCasters -= src
	viewing_channel = null
	picture = null
	return ..()

/obj/machinery/newscaster/update_icon_state()
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "newscaster_off"
	else
		if(GLOB.news_network.wanted_issue.active)
			icon_state = "newscaster_wanted"
		else
			icon_state = "newscaster_normal"

/obj/machinery/newscaster/update_overlays()
	. = ..()

	if(!(machine_stat & (NOPOWER|BROKEN)) && !GLOB.news_network.wanted_issue.active && alert)
		. += "newscaster_alert"

	var/hp_percent = obj_integrity * 100 /max_integrity
	switch(hp_percent)
		if(75 to 100)
			return
		if(50 to 75)
			. += "crack1"
		if(25 to 50)
			. += "crack2"
		else
			. += "crack3"

/obj/machinery/newscaster/power_change()
	if(machine_stat & BROKEN)
		return
	if(powered())
		set_machine_stat(machine_stat & ~NOPOWER)
		update_icon()
	else
		spawn(rand(0, 15))
			set_machine_stat(machine_stat | NOPOWER)
			update_icon()

/obj/machinery/newscaster/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	update_icon()

/obj/machinery/newscaster/attack_ghost(mob/dead/observer/user)
	if(istype(user))
		user.read_news()

/obj/machinery/newscaster
	/// Кэш base64 для фотографий в ленте — icon2base64 ходит в savefile, кэшируем по REF иконки.
	var/list/base64_cache = list()

/obj/machinery/newscaster/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(!(ishuman(user) || issilicon(user)))
		return
	scan_user(user)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Newscaster", "Новостник #[unit_no]")
		ui.open()

/obj/machinery/newscaster/ui_data(mob/user)
	var/list/data = list()
	data["unitNo"] = unit_no
	data["securityCaster"] = !!securityCaster
	data["scannedUser"] = scanned_user
	data["screen"] = screen
	data["paperRemaining"] = paper_remaining
	data["channelName"] = channel_name
	data["cLocked"] = !!c_locked
	data["message"] = tgui_news_text(msg)
	data["allowComments"] = !!allow_comments
	data["pictureAttached"] = !!picture
	data["picture"] = picture ? picture_data(REF(picture), picture.picture_image) : null

	var/datum/news/wanted_message/wanted = GLOB.news_network.wanted_issue
	data["wantedActive"] = wanted.active
	data["wantedAdmin"] = wanted.isAdminMsg
	data["wantedCriminal"] = wanted.criminal
	data["wantedBody"] = tgui_news_text(wanted.body)
	data["wantedAuthor"] = wanted.scannedUser
	data["wantedPhoto"] = wanted.img ? picture_data(REF(wanted.img), wanted.img) : null

	var/list/channels = list()
	for(var/datum/news/feed_channel/FC in GLOB.news_network.network_channels)
		channels += list(
			"ref" = REF(FC),
			"name" = FC.channel_name,
			"author" = FC.author,
			"locked" = !!FC.locked,
			"censored" = !!FC.censored,
			"admin" = !!FC.is_admin_channel,
			"messages" = length(FC.messages),
		)
	data["channels"] = channels

	var/list/viewing = null
	if(viewing_channel && !QDELETED(viewing_channel))
		viewing = list(
			"ref" = REF(viewing_channel),
			"name" = viewing_channel.channel_name,
			"author" = viewing_channel.returnAuthor(-1),
			"censored" = !!viewing_channel.censored,
			"admin" = !!viewing_channel.is_admin_channel,
			"authorCensor" = !!viewing_channel.authorCensor,
		)
		var/list/messages = list()
		for(var/datum/news/feed_message/FM in viewing_channel.messages)
			var/list/comments = list()
			for(var/datum/news/feed_comment/comment in FM.comments)
				comments += list(
					"ref" = REF(comment),
					"body" = comment.body,
					"author" = comment.author,
					"time" = comment.time_stamp,
				)
			messages += list(
				"ref" = REF(FM),
				"body" = tgui_news_text(FM.returnBody(-1)),
				"author" = FM.returnAuthor(-1),
				"time" = FM.time_stamp,
				"image" = FM.img ? picture_data(REF(FM.img), FM.img) : null,
				"caption" = FM.caption,
				"comments" = comments,
				"locked" = !!FM.locked,
				"bodyCensor" = !!FM.bodyCensor,
				"authorCensor" = !!FM.authorCensor,
				"admin" = !!FM.is_admin_message,
			)
		viewing["messages"] = messages
	data["viewingChannel"] = viewing
	return data

/// data: URI для иконки с кэшем на время жизни аппаратa.
/obj/machinery/newscaster/proc/picture_data(key, icon/image)
	if(!image)
		return null
	var/encoded = base64_cache[key]
	if(!encoded)
		encoded = icon2base64(image)
		base64_cache[key] = encoded
	return encoded ? "data:image/png;base64,[encoded]" : null

/obj/machinery/newscaster/ui_act(action, params)
	if(..())
		return
	if(!(ishuman(usr) || issilicon(usr)))
		return
	if(!usr.canUseTopic(src, !hasSiliconAccessInArea(usr)))
		return
	scan_user(usr)
	add_fingerprint(usr)

	switch(action)
		if("navigate")
			set_screen(text2num(params["screen"]))
			. = TRUE
		if("refresh")
			scan_user(usr)
			. = TRUE
		if("setChannelName")
			var/new_name = tgui_input_text(usr, "Название новостного канала", "Создание канала", channel_name, MAX_NAME_LEN, FALSE, TRUE)
			if(new_name)
				channel_name = new_name
			. = TRUE
		if("toggleChannelLock")
			c_locked = !c_locked
			. = TRUE
		if("submitNewChannel")
			. = submit_new_channel()
		if("selectReceivingChannel")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || !(FC in GLOB.news_network.network_channels))
				return
			channel_name = FC.channel_name
			. = TRUE
		if("setMessage")
			var/raw = tgui_input_text(usr, "Напишите новость", "Редактор новостей", html_decode(msg), MAX_MESSAGE_LEN, TRUE, TRUE)
			if(raw)
				var/trimmed = trim(raw)
				if(trimmed)
					msg = trimmed
			. = TRUE
		if("toggleAttachment")
			AttachPhoto(usr)
			. = TRUE
		if("toggleComments")
			allow_comments = !allow_comments
			. = TRUE
		if("submitNewMessage")
			. = submit_new_message()
		if("printPaper")
			if(!paper_remaining)
				screen = 21
			else
				print_paper()
				screen = 20
			. = TRUE
		if("menuWanted")
			channel_name = ""
			msg = ""
			if(GLOB.news_network.wanted_issue.active)
				channel_name = GLOB.news_network.wanted_issue.criminal
				msg = GLOB.news_network.wanted_issue.body
			screen = 14
			. = TRUE
		if("setWantedName")
			var/new_name = tgui_input_text(usr, "Имя разыскиваемого", "Розыск", channel_name, MAX_NAME_LEN, FALSE, TRUE)
			if(new_name)
				channel_name = new_name
			. = TRUE
		if("setWantedDesc")
			var/new_desc = tgui_input_text(usr, "Описание разыскиваемого и детали", "Розыск", html_decode(msg), MAX_MESSAGE_LEN, TRUE, TRUE)
			if(new_desc)
				msg = new_desc
			. = TRUE
		if("submitWanted")
			. = submit_wanted(text2num(params["mode"]))
		if("cancelWanted")
			if(GLOB.news_network.wanted_issue.isAdminMsg)
				tgui_alert(usr, "Объявление распространено руководством Nanotrasen. Вы не можете снять его.", "Розыск", list("Ок"))
				return
			var/choice = tgui_alert(usr, "Подтвердите снятие объявления", "Розыск", list("Да", "Отмена"))
			if(choice == "Да")
				GLOB.news_network.deleteWanted()
				screen = 17
			. = TRUE
		if("viewChannel")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || !(FC in GLOB.news_network.network_channels))
				return
			viewing_channel = FC
			screen = 9
			. = TRUE
		if("pickCensorChannel")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || !(FC in GLOB.news_network.network_channels))
				return
			viewing_channel = FC
			screen = 12
			. = TRUE
		if("pickDNotice")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || !(FC in GLOB.news_network.network_channels))
				return
			viewing_channel = FC
			screen = 13
			. = TRUE
		if("censorChannelAuthor")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || FC.is_admin_channel)
				return
			FC.toggleCensorAuthor()
			. = TRUE
		if("censorStoryAuthor")
			var/datum/news/feed_message/FM = locate(params["message"])
			if(!istype(FM) || FM.is_admin_message)
				return
			FM.toggleCensorAuthor()
			. = TRUE
		if("censorStoryBody")
			var/datum/news/feed_message/FM = locate(params["message"])
			if(!istype(FM) || FM.is_admin_message)
				return
			FM.toggleCensorBody()
			. = TRUE
		if("toggleDNotice")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || FC.is_admin_channel)
				return
			FC.toggleCensorDclass()
			. = TRUE
		if("newComment")
			var/datum/news/feed_message/FM = locate(params["message"])
			if(!istype(FM))
				return
			var/cominput = tgui_input_text(usr, "Комментарий", "Новостник", null, 140, FALSE, TRUE)
			if(cominput)
				scan_user(usr)
				var/datum/news/feed_comment/FC = new /datum/news/feed_comment
				FC.author = scanned_user
				FC.body = cominput
				FC.time_stamp = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
				FM.comments += FC
				usr.log_message("(as [scanned_user]) commented on message [FM.returnBody(-1)] -- [FC.body]", LOG_COMMENT)
			. = TRUE
		if("delComment")
			var/datum/news/feed_comment/FC = locate(params["comment"])
			var/datum/news/feed_message/FM = locate(params["message"])
			if(istype(FC) && istype(FM))
				FM.comments -= FC
				qdel(FC)
			. = TRUE
		if("lockComment")
			var/datum/news/feed_message/FM = locate(params["message"])
			if(istype(FM))
				FM.locked ^= 1
			. = TRUE

/obj/machinery/newscaster/proc/set_screen(new_screen)
	screen = new_screen
	if(new_screen == 0)
		scanned_user = "Unknown"
		msg = ""
		c_locked = 0
		channel_name = ""
		viewing_channel = null

/obj/machinery/newscaster/proc/submit_new_channel()
	var/list/existing_authors = list()
	for(var/datum/news/feed_channel/FC in GLOB.news_network.network_channels)
		existing_authors += FC.authorCensor ? GLOB.news_network.redactedText : FC.author
	var/check = FALSE
	for(var/datum/news/feed_channel/FC in GLOB.news_network.network_channels)
		if(FC.channel_name == channel_name)
			check = TRUE
			break
	if(channel_name == "" || channel_name == "\[REDACTED\]" || scanned_user == "Unknown" || check || (scanned_user in existing_authors))
		screen = 7
		return TRUE
	var/choice = tgui_alert(usr, "Подтвердите создание канала", "Новостник", list("Да", "Отмена"))
	if(choice != "Да")
		return TRUE
	scan_user(usr)
	GLOB.news_network.CreateFeedChannel(channel_name, scanned_user, c_locked)
	SSblackbox.record_feedback("text", "newscaster_channels", 1, "[channel_name]")
	screen = 5
	return TRUE

/obj/machinery/newscaster/proc/submit_new_message()
	if(msg == "" || msg == "\[REDACTED\]" || scanned_user == "Unknown" || channel_name == "")
		screen = 6
		return TRUE
	GLOB.news_network.SubmitArticle("<font face=\"[PEN_FONT]\">[parsemarkdown(msg, usr)]</font>", scanned_user, channel_name, picture, 0, allow_comments)
	SSblackbox.record_feedback("amount", "newscaster_stories", 1)
	screen = 4
	msg = ""
	return TRUE

/obj/machinery/newscaster/proc/submit_wanted(mode)
	if(msg == "" || channel_name == "" || scanned_user == "Unknown")
		screen = 16
		return TRUE
	var/choice = tgui_alert(usr, "Подтвердите объявление в розыск", "Розыск", list("Да", "Отмена"))
	if(choice != "Да")
		return TRUE
	scan_user(usr)
	if(mode == 1)
		GLOB.news_network.submitWanted(channel_name, msg, scanned_user, picture, 0, 1)
		screen = 15
		return TRUE
	if(GLOB.news_network.wanted_issue.isAdminMsg)
		tgui_alert(usr, "Объявление распространено руководством Nanotrasen. Вы не можете его редактировать.", "Розыск", list("Ок"))
		return TRUE
	GLOB.news_network.submitWanted(channel_name, msg, scanned_user, picture)
	screen = 19
	return TRUE

/obj/machinery/newscaster/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		to_chat(user, "<span class='notice'>You start [anchored ? "un" : ""]securing [name]...</span>")
		I.play_tool_sound(src)
		if(I.use_tool(src, user, 60))
			playsound(loc, 'sound/items/deconstruct.ogg', 50, 1)
			if(machine_stat & BROKEN)
				to_chat(user, "<span class='warning'>The broken remains of [src] fall on the ground.</span>")
				new /obj/item/stack/sheet/metal(loc, 5)
				new /obj/item/shard(loc)
				new /obj/item/shard(loc)
			else
				to_chat(user, "<span class='notice'>You [anchored ? "un" : ""]secure [name].</span>")
				new /obj/item/wallframe/newscaster(loc)
			qdel(src)
	else if(I.tool_behaviour == TOOL_WELDER && user.a_intent != INTENT_HARM)
		if(machine_stat & BROKEN)
			if(!I.tool_start_check(user, amount=0))
				return
			user.visible_message("[user] is repairing [src].", \
							"<span class='notice'>You begin repairing [src]...</span>", \
							"<span class='italics'>You hear welding.</span>")
			if(I.use_tool(src, user, 40, volume=50))
				if(!(machine_stat & BROKEN))
					return
				to_chat(user, "<span class='notice'>You repair [src].</span>")
				obj_integrity = max_integrity
				set_machine_stat(machine_stat & ~BROKEN)
				update_icon()
		else
			to_chat(user, "<span class='notice'>[src] does not need repairs.</span>")
	else
		return ..()

/obj/machinery/newscaster/play_attack_sound(damage, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			if(machine_stat & BROKEN)
				playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 100, 1)
			else
				playsound(loc, 'sound/effects/glasshit.ogg', 90, 1)
		if(BURN)
			playsound(src.loc, 'sound/items/welder.ogg', 100, 1)


/obj/machinery/newscaster/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/metal(loc, 2)
		new /obj/item/shard(loc)
		new /obj/item/shard(loc)
	qdel(src)

/obj/machinery/newscaster/obj_break()
	if(!(machine_stat & BROKEN) && !(flags_1 & NODECONSTRUCT_1))
		set_machine_stat(machine_stat | BROKEN)
		playsound(loc, 'sound/effects/glassbr3.ogg', 100, 1)
		update_icon()


/obj/machinery/newscaster/attack_paw(mob/user)
	if(user.a_intent != INTENT_HARM)
		to_chat(user, "<span class='warning'>Управление диктором новостей слишком сложно для твоего маленького мозга!</span>")
	else
		take_damage(5, BRUTE, MELEE)

/obj/machinery/newscaster/proc/AttachPhoto(mob/user)
	var/obj/item/photo/photo = user.is_holding_item_of_type(/obj/item/photo)
	if(photo)
		picture = photo.picture
	if(issilicon(user))
		var/obj/item/camera/siliconcam/targetcam
		if(isAI(user))
			var/mob/living/silicon/ai/R = user
			targetcam = R.aicamera
		else if(iscyborg(user))
			var/mob/living/silicon/robot/R = user
			if(R.connected_ai)
				targetcam = R.connected_ai.aicamera
			else
				targetcam = R.aicamera
		else
			to_chat(user, "<span class='warning'>You cannot interface with silicon photo uploading!</span>")
		if(!targetcam.stored.len)
			to_chat(usr, "<span class='boldannounce'>No images saved</span>")
			return
		var/datum/picture/selection = targetcam.selectpicture(user)
		if(selection)
			picture = selection

/obj/machinery/newscaster/proc/scan_user(mob/living/user)
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		if(human_user.wear_id)
			if(istype(human_user.wear_id, /obj/item/modular_computer/pda))
				var/obj/item/modular_computer/pda/P = human_user.wear_id
				if(P.id)
					scanned_user = "[P.id.registered_name] ([P.id.get_assignment_name()])"
				else
					scanned_user = "Unknown"
			else if(istype(human_user.wear_id, /obj/item/card/id) )
				var/obj/item/card/id/ID = human_user.wear_id
				scanned_user ="[ID.registered_name] ([ID.get_assignment_name()])"
			else
				scanned_user ="Unknown"
		else if(human_user.wear_neck?.GetID())
			var/obj/item/card/id/ID = human_user.wear_neck.GetID()
			scanned_user ="[ID.registered_name] ([ID.get_assignment_name()])"
		else
			scanned_user ="Unknown"
	else if(issilicon(user))
		var/mob/living/silicon/ai_user = user
		scanned_user = "[ai_user.name] ([ai_user.job])"
	else
		CRASH("Invalid user for this proc")

/obj/machinery/newscaster/proc/print_paper()
	SSblackbox.record_feedback("amount", "newspapers_printed", 1)
	var/obj/item/newspaper/NEWSPAPER = new /obj/item/newspaper
	for(var/datum/news/feed_channel/FC in GLOB.news_network.network_channels)
		NEWSPAPER.news_content += FC
	if(GLOB.news_network.wanted_issue.active)
		NEWSPAPER.wantedAuthor = GLOB.news_network.wanted_issue.scannedUser
		NEWSPAPER.wantedCriminal = GLOB.news_network.wanted_issue.criminal
		NEWSPAPER.wantedBody = GLOB.news_network.wanted_issue.body
		if(GLOB.news_network.wanted_issue.img)
			NEWSPAPER.wantedPhoto = GLOB.news_network.wanted_issue.img
	NEWSPAPER.forceMove(drop_location())
	NEWSPAPER.creationTime = GLOB.news_network.lastAction
	paper_remaining--

/obj/machinery/newscaster/proc/remove_alert()
	alert = FALSE
	update_icon()

/obj/machinery/newscaster/proc/newsAlert(channel)
	// Озвучка только при аудитории рядом: публикация новости дёргает этот прок на
	// КАЖДОМ ньюскастере станции, и say+playsound по пустым коридорам складывались
	// в ~300мс на новость. Лампочка и таймер сброса работают всегда.
	var/has_audience = has_nearby_audience()
	if(channel)
		if(has_audience)
			say("<b>Свежие новости от [channel]</b>!")
		alert = TRUE
		update_icon()
		// Джиттер: одинаковый alert_delay у всех ньюскастеров станции разряжал
		// 500+ таймеров remove_alert одним тиком (TIMER BURST раунда 9746).
		addtimer(CALLBACK(src,PROC_REF(remove_alert)),alert_delay + rand(0, 5 SECONDS),TIMER_UNIQUE|TIMER_OVERRIDE)
		if(has_audience && channel == MARKET_NEWS_CHANNEL)
			playsound(loc, 'sound/economy/news_jingle.ogg', 60, FALSE)
		else if(has_audience)
			playsound(loc, 'sound/machines/twobeep.ogg', 75, 1)
	else if(has_audience)
		say("Attention! Wanted issue distributed!")
		playsound(loc, 'sound/machines/warning-buzzer.ogg', 75, 1)

/// Есть ли рядом клиент-моб (включая гхостов), ради которого стоит говорить и пищать.
/obj/machinery/newscaster/proc/has_nearby_audience(distance = 9)
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return FALSE
	if(!SSspatial_grid.initialized)
		return TRUE // до инициализации грида не гейтим - поведение как раньше
	for(var/mob/player as anything in SSspatial_grid.orthogonal_range_search(our_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, distance))
		if(get_dist(our_turf, player) <= distance)
			return TRUE
	return FALSE

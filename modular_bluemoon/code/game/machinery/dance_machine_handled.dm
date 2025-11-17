/obj/item/jukebox
	name = "Handled Jukebox"
	desc = "Переносная колонка для крутых."
	icon = 'modular_citadel/icons/obj/boombox.dmi'
	righthand_file = 'modular_citadel/icons/obj/boombox_righthand.dmi'
	lefthand_file = 'modular_citadel/icons/obj/boombox_lefthand.dmi'
	item_state = "raiqbawks"
	icon_state = "raiqbawks"
	verb_say = "states"
	density = FALSE
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/volume = 100
	var/queuecost = PRICE_CHEAP //Set to -1 to make this jukebox require access for queueing
	var/datum/track/playing = null
	var/datum/track/selectedtrack = null
	var/list/queuedplaylist = list()
	var/queuecooldown //This var exists solely to prevent accidental repeats of John Mulaney's 'What's New Pussycat?' incident. Intentional, however......
	var/repeat = FALSE //BLUEMOON ADD зацикливание плейлистов
	var/area_priority = FALSE //BLUEMOON ADD стационарные джукбоксы имеют приоритет игры внутри своей зоны
	var/area/privatized_area = null //BLUEMOON ADD зона которая будет забрана для конкретного джукбокса

/obj/item/jukebox/emagged
	name = "Handled Jukebox"
	desc = "Переносная колонка для крутых. ТЕПЕРЬ ВЗЛОМАННАЯ."
	obj_flags = EMAGGED
	queuecost = PRICE_FREE
	var/smileycom = "smileycom"

/obj/item/jukebox/emagged/ui_interact(mob/living/user, datum/tgui/ui)
	if(!isliving(user))
		return
	if(user.ckey == smileycom || user.mind?.antag_datums)
		. = ..()
	else
		var/message = pick(
			"Нельзя, запрещено.",
			"Только для Айко.",
			"Только для крутышей.",
			"Убейся.",
			"11010000 10111100 11010000 10110000 11010001 10000010 11010001 10001100 100000 11010000 10110101 11010000 10110001 11010000 10110000 11010000 10111011",
			"А я всё думал, когда же ты появишься.",
			"Хочу джамбургер.",
			"Сегодня нас атакуют танки, авиация и корабли. А знаете, где ещё есть танки, авиация и корабли? Конечно же, в Война Гром. Война Гром - это компьютерная многопользовательская онлайн-игра...",
			"Ты мне сейчас не поверишь, но там ебать сколько посуды, которая сама себя никак не вымоет.",
			"B чём сила, брат? В ОМах.",
			"В чём сопротивление, брат? В острых козырьках.",
			"В чём измеряют напряжение, брат? В Томасах Шелби.",
			"We can't expect god to do all the work.",
			"Заканчивай свой звонок и поцелуй меня в сладкие уста. Романтики хочется.",
			"Не надо делать мне как лучше, оставьте мне как хорошо.",
			"Я не хотела Вас обидеть, случайно просто повезло.",
			"Поскольку времени немного, я вкратце матом объясню.",
			"Башка сегодня отключилась, не вся, конечно, - есть могу.",
			"Следить стараюсь за фигурой, чуть отвлекусь - она жует.",
			"Шаман за скверную погоду недавно в бубен получил.",
			"Всё вроде с виду в шоколаде, но если внюхаться - то нет.",
			"Обидеть Таню может каждый, не каждый может убежать.",
			"Ищу приличную работу, но чтоб не связана с трудом.",
			"Мои намеренья прекрасны, пойдёмте, тут недалеко.",
			"Я за тебя переживаю - вдруг у тебя всё хорошо.",
			"Держи вот этот подорожник - щас врежу, сразу приложи.",
			"Я понимаю, что Вам нечем, но всё ж попробуйте понять.",
			"Мы были б идеальной парой, конечно, если бы не ты.",
			"Как говорится, всё проходит, но может кое-что застрять.",
			"Кого хочу я осчастливить, тому спасенья уже нет.",
			"А ты готовить-то умеешь? — Я вкусно режу колбасу.",
			"Звони почаще - мне приятно на твой «пропущенный» смотреть.",
			"Зачем учить нас, как работать, вы научитесь как платить.",
			"Характер у меня тяжёлый, всё потому, что золотой.",
			"Чтоб дело мастера боялось, он знает много страшных слов.",
			"Вы мне хотели жизнь испортить? Спасибо, справилась сама.",
			"Её сбил конь средь изб горящих, она нерусскою была…",
			"Когда все крысы убежали, корабль перестал тонуть.",
			"Дела идут пока отлично, поскольку к ним не приступал.",
			"Работаю довольно редко, а недовольно каждый день.",
			"Была такою страшной сказка, что дети вышли покурить.",
			"Когда на планы денег нету, они становятся мечтой.",
			"Женат два раза неудачно - одна ушла, вторая - нет.",
			"Есть всё же разум во Вселенной, раз не выходит на контакт.",
			"Уж вроде ноги на исходе, а юбка всё не началась.",
			"Я попросил бы Вас остаться, но вы ж останетесь, боюсь.",
			"Для женщин нет такой проблемы, которой им бы не создать.",
			"Олегу не везёт настолько, что даже лифт идет в депо.",
			"Мы называем это жизнью, а это просто список дел.",
			"И жили счастливо и долго… он долго, счастливо она.",
			"Не копай противнику яму, сам туда ляжешь.",
			"Кто глубоко скорбит - тот истово любил.")
		visible_message(span_big_warning(message))
		balloon_alert_to_viewers(message)
		playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		user.DefaultCombatKnockdown(100)
		user.adjustFireLoss(rand(25, 50))
		user.dropItemToGround(src, TRUE)
		return

///obj/item/jukebox/emag_act(mob/user)
//	. = ..()
//	if(obj_flags & EMAGGED)
//		return
//	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
//	obj_flags |= EMAGGED
//	queuecost = PRICE_FREE
//	req_one_access = null
//	to_chat(user, "<span class='notice'>You've bypassed [src]'s audio volume limiter, and enabled free play.</span>")
//	return TRUE

/obj/item/jukebox/update_icon_state()
	if(active)
		icon_state = "[initial(icon_state)]-active"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/jukebox/ui_status(mob/user)
	if((queuecost < 0 && !allowed(user)) && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: Access Denied.</span>")
		user.playsound_local(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	if(!SSjukeboxes.songs.len && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue.</span>")
		playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/obj/item/jukebox/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Jukebox", name)
		ui.open()

/obj/item/jukebox/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	// BLUEMOON DEL -- ищи в modular_bluemoon/jukebox
	// data["songs"] = list()
	// for(var/datum/track/S in SSjukeboxes.songs)
	// 	var/list/track_data = list(name = S.song_name)
	// 	data["songs"] += list(track_data)
	// BLUEMOON DEL END
	// BLUEMOON EDIT START: Better Jukebox
	data["queued_tracks"] = list()
	for (var/i = 1, i <= queuedplaylist.len, i++)
		var/datum/track/S = queuedplaylist[i]
		data["queued_tracks"] += list(
			list(
				index = i,
				name = S.song_name
			)
		)
	// BLUEMOON EDIT END: Better Jukebox
	data["track_selected"] = null
	data["track_length"] = null
	if(playing)
		data["track_selected"] = playing.song_name
		data["track_length"] = DisplayTimeText(playing.song_length)
	data["volume"] = volume
	data["is_emagged"] = (obj_flags & EMAGGED)
	data["cost_for_play"] = queuecost
	data["has_access"] = allowed(user)
	data["repeat"] = repeat		//BLUEMOON ADD
	// BLUEMOON EDIT START: Better Jukebox
	var/list/all_song_names = list()
	for (var/datum/track/T in SSjukeboxes.songs)
		all_song_names += T.song_name
	data["songs"] = all_song_names
	data["favorite_tracks"] = user?.client?.prefs?.favorite_tracks
	// BLUEMOON EDIT END: Better Jukebox
	return data

/obj/item/jukebox/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			if(QDELETED(src))
				return
			if(!allowed(usr))
				return
			if(!active && !playing)
				activate_music()
			else
				stop = 0
			return TRUE
		//BLUEMOON ADD зацикливание плейлистов
		if("repeat")
			repeat = !repeat
			return
		//BLUEMOON ADD END
		//BLUEMOON ADD START Возможность двигать треки в избранном и двигать в очереди
		if("move_favorite")
			var/mob/living/L = usr
			if(!L?.client?.prefs)
				return
			var/track = params["track"]
			if(!track)
				return
			var/list/track_list = L.client.prefs.favorite_tracks

			var/to_index = params["up"] ? track_list.Find(next_list_item(track, track_list)) : track_list.Find(previous_list_item(track, track_list))
			var/track_index = track_list.Find(track)

			if(to_index == track_list.len)
				track_list -= track
				track_list += track
			else if(to_index == 1)
				track_list -= track
				track_list.Insert(to_index, track)
			else
				track_list.Swap(track_index, to_index)

			L.client.prefs.save_preferences()
			return TRUE

		if("move_queue")
			var/track_index = params["index"]
			if (!track_index || !queuedplaylist.len || track_index < 1 || track_index > queuedplaylist.len)
				return
			var/datum/track/track = queuedplaylist[track_index]
			var/to_index = params["up"] ? queuedplaylist.Find(previous_list_item(track, queuedplaylist)) : queuedplaylist.Find(next_list_item(track, queuedplaylist))
			if(to_index == queuedplaylist.len)
				queuedplaylist.Cut(track_index, track_index+1)
				queuedplaylist += track
			else if(to_index == 1)
				queuedplaylist.Cut(track_index, track_index+1)
				queuedplaylist.Insert(to_index, track)
			else
				queuedplaylist.Swap(track_index, to_index)
			return TRUE
		//BLUEMOON ADD END
		if("add_to_queue")
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selectedtrack = available[selected]
			if(world.time < queuecooldown)
				return
			if(!istype(selectedtrack, /datum/track))
				return
			if(!allowed(usr) && queuecost)
				var/obj/item/card/id/C
				if(isliving(usr))
					var/mob/living/L = usr
					C = L.get_idcard(TRUE)
				to_chat(usr, "<span class='notice'>You spend [queuecost] credits to queue [selectedtrack.song_name].</span>")
				log_econ("[queuecost] credits were inserted into [src] by [key_name(usr)] (ID: [C.registered_name]) to queue [selectedtrack.song_name].")
			// BLUEMOON ADD START Возможность поставить трек в начало
			if(params["up"])
				queuedplaylist.Insert(1, selectedtrack)
			else
			// BLUEMOON END START
				queuedplaylist += selectedtrack
			if(active)
				say("[selectedtrack.song_name] has been added to the queue.")
			else if(!playing)
				activate_music()
			playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
			queuecooldown = world.time + (1 SECONDS)
			return TRUE
		if("select_track")
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selectedtrack = available[selected]
			return TRUE
		if("set_volume")
			if(!allowed(usr))
				return
			var/new_volume = params["volume"]
			if(new_volume  == "reset")
				volume = initial(volume)
			else if(new_volume == "min")
				volume = 0
			else if(new_volume == "max")
				volume = ((obj_flags & EMAGGED) ? 1000 : 100)
			else if(text2num(new_volume) != null)
				volume = clamp(0, text2num(new_volume), ((obj_flags & EMAGGED) ? 1000 : 100))
			var/wherejuke = SSjukeboxes.findjukeboxindex(src)
			if(wherejuke)
				SSjukeboxes.updatejukebox(wherejuke, jukefalloff = volume/35)
			return TRUE

/obj/item/jukebox/proc/activate_music()
	if(playing || !queuedplaylist.len)
		return FALSE
	// BLUEMOON ADD - Making sure not to play track if all jukebox channels are busy. That shouldn't happen.
	if(!SSjukeboxes.freejukeboxchannels.len)
		say("Cannot play song: limit of currently playing tracks has been exceeded.")
		return FALSE
	var/area/juke_area = get_area(src)
	if(juke_area.jukebox_privatized_by && juke_area.jukebox_privatized_by != src)
		say("Vibration sensor error. A reduction in the number of jukeboxes in the area is required.")
		return FALSE
	// BLUEMOON ADD END
	playing = queuedplaylist[1]
	var/jukeboxslottotake = SSjukeboxes.addjukebox(src, playing, volume/35)
	if(jukeboxslottotake)
		active = TRUE
		update_icon()
		START_PROCESSING(SSobj, src)
		stop = world.time + playing.song_length
		//BLUEMOON ADD повтор плейлиста (трек добавляется в конец плейлиста)
		if(repeat)
			queuedplaylist += queuedplaylist[1]
		// BLUEMOON ADD стационарные джукбоксы забирают приоритет зоны себе и если сидеть в этой зоне играет только их музыка
		if(area_priority)
			juke_area.jukebox_privatized_by = src
		//BLUEMOON ADD END
		queuedplaylist.Cut(1, 2)
		say("Сейчас играет: [playing.song_name]")
		playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, TRUE)
		return TRUE
	else
		return FALSE

/obj/item/jukebox/proc/dance_over()
	if(privatized_area)
		privatized_area.jukebox_privatized_by = null
	var/position = SSjukeboxes.findjukeboxindex(src)
	if(!position)
		return
	SSjukeboxes.removejukebox(position)
	STOP_PROCESSING(SSobj, src)
	playing = null
	rangers = list()

/obj/item/jukebox/process()
	if(active)
		if(world.time >= stop)
			active = FALSE
			dance_over()
			if(stop && queuedplaylist.len)
				activate_music()
			else
				playsound(src,'sound/machines/terminal_off.ogg',50,1)
				update_icon()
				playing = null
				stop = 0

/obj/item/jukebox/Destroy(mob/user)
	SSjukeboxes.removejukebox(SSjukeboxes.findjukeboxindex(src))
	. = ..()

/datum/component/jukebox
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/volume = 70
	var/queuecost = PRICE_CHEAP // For obj/machinery only! Set to -1 to make this jukebox require access for queueing.
	var/datum/track/playing = null
	var/datum/track/selectedtrack = null
	var/list/queuedplaylist = list()
	var/repeat = FALSE // BLUEMOON ADD зацикливание плейлистов
	var/area_priority = TRUE // BLUEMOON ADD стационарные джукбоксы имеют приоритет игры внутри своей зоны
	var/area/privatized_area = null // BLUEMOON ADD зона которая будет забрана для конкретного джукбокса
	var/list/emagged_ckey_allowed = list("smileycom") // BLUEMOON ADD Список сикеев, которым разерешено пользоваться взломанной, ручной колонкой
	var/need_anchored = FALSE // Обзательно ли прикручивать для работы
	COOLDOWN_DECLARE(error_message_cooldown)
	var/const/error_message_cooldown_time = 5 SECONDS
	COOLDOWN_DECLARE(queuecooldown) // This exists solely to prevent accidental repeats of John Mulaney's 'What's New Pussycat?' incident. Intentional, however......
	var/const/queuecooldown_time = 1 SECONDS

/datum/component/jukebox/Initialize(_need_anchored, _queuecost, _volume)
	. = ..()
	if(!isobj(parent))
		return COMPONENT_INCOMPATIBLE
	if(isnum(_need_anchored)) // False || True
		need_anchored = _need_anchored
	if(isnum(_queuecost) && _queuecost >= 0)
		queuecost = _queuecost
	if(isnum(_volume) && _volume >= 0)
		volume = _volume
	RegisterSignal(parent, COMSIG_MOUSEDROP_ONTO, PROC_REF(on_mouse_dropped))
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(interact)) // Для предметов
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand)) // Для машинерии
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_ICON_STATE, PROC_REF(on_update_icon_state))
	RegisterSignal(parent, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emag_act))

/datum/component/jukebox/proc/on_update_icon_state(atom/source)
	SIGNAL_HANDLER

	var/obj/box = source
	box.icon_state = box.current_skin ? box.unique_reskin[box.current_skin]["icon_state"] : initial(box.icon_state)
	if(active)
		box.icon_state += "-active"

/datum/component/jukebox/proc/on_emag_act(atom/source)
	SIGNAL_HANDLER

	var/obj/box = parent
	// Только стационарные можно емагнуть
	if(!need_anchored || box.obj_flags & EMAGGED)
		return

	queuecost = PRICE_FREE
	box.obj_flags |= EMAGGED
	box.req_one_access = null

	var/mob/living/user = usr
	if(user)
		log_admin("[key_name(user)] emagged [box] at [AREACOORD(box)]")
		to_chat(user, "<span class='notice'>You've bypassed [box]'s audio volume limiter, and enabled free play.</span>")

/datum/component/jukebox/proc/on_mouse_dropped(atom/source, atom/dropping, mob/user)
	SIGNAL_HANDLER

	if(!user || dropping != user || !user.canUseTopic(parent, TRUE, no_tk = TRUE, check_resting = FALSE))
		return
	interact(source, user)

/datum/component/jukebox/proc/on_attack_hand(atom/source, mob/user)
	SIGNAL_HANDLER

	var/obj/box = parent
	if(!box.anchored)
		return
	interact(source, user)

/datum/component/jukebox/proc/interact(atom/source, mob/user)
	SIGNAL_HANDLER

	if(!user)
		return

	var/obj/box = parent
	// Ручная, емагнутая колонка. Сkey не в списке и не антаг
	if(isliving(user) && user.canUseTopic(box, TRUE, silent = TRUE) && box.obj_flags & EMAGGED && !box.anchored && (!(user.ckey in emagged_ckey_allowed) || !user.mind?.antag_datums))
		var/mob/living/L = user
		var/static/list/messages = list(
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
			"Кто глубоко скорбит - тот истово любил."
		)
		var/message = pick(messages)
		box.visible_message(span_big_warning(message))
		box.balloon_alert_to_viewers(message)
		playsound(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		L.DefaultCombatKnockdown(100)
		L.adjustFireLoss(rand(25, 50))
		L.dropItemToGround(box, TRUE)
		return

	INVOKE_ASYNC(src, PROC_REF(ui_interact), user)

/datum/component/jukebox/ui_status(mob/user)
	var/obj/box = parent
	if(!box)
		return UI_CLOSE
	if(need_anchored && !box.anchored)
		to_chat(user, span_warning("This device must be anchored by a wrench!"))
		return UI_CLOSE
	if((queuecost < 0 && !box.allowed(user)) && !isobserver(user))
		to_chat(user,span_warning("Error: Access Denied."))
		user.playsound_local(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	if(!SSjukeboxes.songs.len && !isobserver(user))
		to_chat(user, span_warning("Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue."))
		playsound(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/datum/component/jukebox/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		var/obj/box = parent
		ui = new(user, src, "Jukebox", box.name)
		ui.open()

/datum/component/jukebox/ui_data(mob/user)
	var/obj/box = parent
	var/list/data = list()
	data["active"] = active
	data["queued_tracks"] = list()
	for (var/i = 1, i <= queuedplaylist.len, i++)
		var/datum/track/S = queuedplaylist[i]
		data["queued_tracks"] += list(
			list(
				index = i,
				name = S.song_name
			)
		)
	data["track_selected"] = null
	data["track_length"] = null
	if(playing)
		data["track_selected"] = playing.song_name
		data["track_length"] = DisplayTimeText(playing.song_length)
	data["volume"] = volume
	data["is_emagged"] = (box.obj_flags & EMAGGED)
	data["cost_for_play"] = queuecost
	data["has_access"] = box.allowed(user)
	data["repeat"] = repeat
	var/list/all_song_names = list()
	for (var/datum/track/T in SSjukeboxes.songs)
		all_song_names += T.song_name
	data["songs"] = all_song_names
	data["favorite_tracks"] = user?.client?.prefs?.favorite_tracks

	return data

/datum/component/jukebox/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	var/obj/box = parent
	switch(action)
		if("toggle")
			if(QDELETED(src) || QDELETED(box))
				return
			if(!box.allowed(usr))
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
		if("toggle_favorite", "move_favorite", "set_favorite_index")
			var/mob/living/L = usr
			if(!L?.client?.prefs)
				return
			var/datum/preferences/prefs = L.client.prefs
			var/track = params["track"]
			if(!track)
				return
			var/list/track_list = prefs.favorite_tracks

			switch(action)
				if("toggle_favorite")
					if(track in track_list)
						track_list -= track
					else
						track_list += track
				if("move_favorite")
					var/to_index = params["up"] ? track_list.Find(next_list_item(track, track_list)) : track_list.Find(previous_list_item(track, track_list))
					var/track_index = track_list.Find(track)
					if(!to_index || !track_index)
						return

					if(to_index == track_list.len)
						track_list -= track
						track_list += track
					else if(to_index == 1)
						track_list -= track
						track_list.Insert(to_index, track)
					else
						track_list.Swap(track_index, to_index)
				if("set_favorite_index")
					var/ui_index = params["index"]
					if(!ui_index)
						return

					var/from = track_list.Find(track)
					if(!from)
						return

					if(ui_index < 0)
						ui_index = track_list.len
					else
						ui_index = clamp(ui_index, 1, track_list.len)

					var/to_index = track_list.len - ui_index + 1 // Индексы в UI в обратном порядке идут

					moveElementToPos(track_list, from, to_index)

			prefs.save_preferences()
			return TRUE
		//BLUEMOON ADD END
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
		if("add_to_queue")
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || QDELETED(box) || !selected || !istype(available[selected], /datum/track))
				return
			selectedtrack = available[selected]
			if(!COOLDOWN_FINISHED(src, queuecooldown))
				return
			if(!istype(selectedtrack, /datum/track))
				return
			if(!box.allowed(usr) && queuecost && ismachinery(box))
				var/obj/machinery/box_machine = box
				var/obj/item/card/id/C
				if(isliving(usr))
					var/mob/living/L = usr
					C = L.get_idcard(TRUE)
				if(!box_machine.can_transact(C))
					if(COOLDOWN_FINISHED(src, error_message_cooldown))
						playsound(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
					COOLDOWN_START(src, queuecooldown, queuecooldown_time)
					return
				if(!box_machine.attempt_transact(C, queuecost))
					if(COOLDOWN_FINISHED(src, error_message_cooldown))
						box.say("Insufficient funds.")
						playsound(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
						COOLDOWN_START(src, error_message_cooldown, error_message_cooldown_time)
					COOLDOWN_START(src, queuecooldown, queuecooldown_time)
					return
				to_chat(usr, "<span class='notice'>You spend [queuecost] credits to queue [selectedtrack.song_name].</span>")
				log_econ("[queuecost] credits were inserted into [box] by [key_name(usr)] (ID: [C.registered_name]) to queue [selectedtrack.song_name].")
			// BLUEMOON ADD START Возможность поставить трек в начало
			if(params["up"])
				queuedplaylist.Insert(1, selectedtrack)
			else
			// BLUEMOON END START
				queuedplaylist += selectedtrack
			if(active)
				box.say("[selectedtrack.song_name] has been added to the queue.")
			else if(!playing)
				activate_music()
			playsound(box, 'sound/machines/ping.ogg', 50, TRUE)
			COOLDOWN_START(src, queuecooldown, queuecooldown_time)
			return TRUE
		if("select_track")
			var/list/available = list()
			for(var/datum/track/S in SSjukeboxes.songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || QDELETED(box) || !selected || !istype(available[selected], /datum/track))
				return
			selectedtrack = available[selected]
			return TRUE
		if("set_volume")
			if(!box.allowed(usr))
				return
			var/new_volume = params["volume"]
			if(new_volume  == "reset")
				volume = initial(volume)
			else if(new_volume == "min")
				volume = 0
			else if(new_volume == "max")
				volume = ((box.obj_flags & EMAGGED) ? 1000 : 100)
			else if(text2num(new_volume) != null)
				volume = clamp(0, text2num(new_volume), ((box.obj_flags & EMAGGED) ? 1000 : 100))
			var/wherejuke = SSjukeboxes.findjukeboxindex(box)
			if(wherejuke)
				SSjukeboxes.updatejukebox(wherejuke, jukefalloff = volume/35)
			return TRUE
		if("clear_queue")
			if(!LAZYLEN(queuedplaylist))
				return
			box.say("Очередь очищена, удалено [queuedplaylist.len] треков.")
			LAZYCLEARLIST(queuedplaylist)
		if("remove_from_queue")
			var/index = params["index"]
			if(!index || !queuedplaylist.len || index < 1 || index > queuedplaylist.len)
				return
			var/datum/track/song_to_remove = queuedplaylist[index]
			queuedplaylist.Cut(index, index + 1)
			box.say("[song_to_remove.song_name] была удалена из очереди.")
			return TRUE

/datum/component/jukebox/proc/activate_music()
	var/obj/box = parent
	if(playing || !queuedplaylist.len)
		return FALSE
	// BLUEMOON ADD - Making sure not to play track if all jukebox channels are busy. That shouldn't happen.
	if(!SSjukeboxes.freejukeboxchannels.len)
		box.say("Cannot play song: limit of currently playing tracks has been exceeded.")
		return FALSE
	if(!check_area())
		return FALSE
	// BLUEMOON ADD END
	playing = queuedplaylist[1]
	var/jukeboxslottotake = SSjukeboxes.addjukebox(box, playing, volume/35)
	if(jukeboxslottotake)
		active = TRUE
		box.update_icon()
		START_PROCESSING(SSobj, src)
		stop = world.time + playing.song_length
		//BLUEMOON ADD повтор плейлиста (трек добавляется в конец плейлиста)
		if(repeat)
			queuedplaylist += queuedplaylist[1]
		// BLUEMOON ADD стационарные джукбоксы забирают приоритет зоны себе и если сидеть в этой зоне играет только их музыка
		if(area_priority)
			if(need_anchored && privatized_area)
				privatized_area.jukebox_privatized_by = null
			var/area/juke_area = get_area(parent)
			juke_area.jukebox_privatized_by = box
			if(need_anchored)
				privatized_area = juke_area

		//BLUEMOON ADD END
		queuedplaylist.Cut(1, 2)
		box.say("Сейчас играет: [playing.song_name]")
		playsound(box, 'sound/machines/terminal_insert_disc.ogg', 50, TRUE)
		return TRUE
	else
		return FALSE

/datum/component/jukebox/proc/check_area(silent = FALSE)
	. = TRUE
	var/obj/box = parent
	var/area/juke_area = get_area(box)
	if(juke_area.jukebox_privatized_by && juke_area.jukebox_privatized_by != box)
		if(!silent)
			box.say("Vibration sensor error. A reduction in the number of jukeboxes in the area is required.")
		return FALSE

/datum/component/jukebox/proc/dance_over()
	var/obj/box = parent
	if(privatized_area)
		privatized_area.jukebox_privatized_by = null
	var/position = SSjukeboxes.findjukeboxindex(box)
	if(!position)
		return
	SSjukeboxes.removejukebox(position)
	STOP_PROCESSING(SSobj, src)
	playing = null
	rangers = list()

/datum/component/jukebox/process(delta_time)
	if((!active || world.time < stop) && check_area())
		return

	var/obj/box = parent
	active = FALSE
	dance_over()
	if(stop && queuedplaylist.len)
		activate_music()
	else
		playsound(box,'sound/machines/terminal_off.ogg',50,1)
		box.update_icon()
		playing = null
		stop = 0

/datum/component/jukebox/Destroy()
	dance_over()
	. = ..()

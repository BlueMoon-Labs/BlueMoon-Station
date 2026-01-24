/datum/component/jukebox
	dupe_mode = COMPONENT_DUPE_UNIQUE
	dupe_type = /datum/component/jukebox
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/volume = 70
	var/queuecost = PRICE_CHEAP // For obj/machinery only! Set to -1 to make this jukebox require access for queueing.
	var/datum/track/playing = null
	var/datum/track/selectedtrack = null
	var/list/queuedplaylist = list()
	var/repeat = FALSE // BLUEMOON ADD зацикливание плейлистов
	var/area/privatized_area = null // BLUEMOON ADD зона которая будет забрана для конкретного джукбокса
	var/list/emagged_ckey_allowed = list("smileycom") // BLUEMOON ADD Список сикеев, которым разерешено пользоваться взломанной, ручной колонкой
	var/need_anchored = FALSE // Обзательно ли прикручивать для работы
	COOLDOWN_DECLARE(error_message_cooldown)
	var/const/error_message_cooldown_time = 5 SECONDS
	COOLDOWN_DECLARE(queuecooldown) // This exists solely to prevent accidental repeats of John Mulaney's 'What's New Pussycat?' incident. Intentional, however......
	var/const/queuecooldown_time = 1 SECONDS
	var/const/queuecooldown_time_max = 12 SECONDS

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
	var/obj/box = parent
	if(box.obj_flags & EMAGGED)
		emag_act(silent = TRUE)
	RegisterSignal(parent, COMSIG_MOUSEDROP_ONTO, PROC_REF(on_mouse_dropped)) // Для удобства
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(interact)) // Для предметов
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_GHOST, PROC_REF(interact)) // Для гостов
	RegisterSignal(parent, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_attack_hand)) // Для машинерии
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_ICON_STATE, PROC_REF(on_update_icon_state))
	RegisterSignal(parent, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emag_act))

/datum/component/jukebox/proc/on_update_icon_state(atom/source)
	SIGNAL_HANDLER

	var/obj/box = source
	box.icon_state = box.current_skin ? box.unique_reskin[box.current_skin]["icon_state"] : initial(box.icon_state)
	if(active)
		box.icon_state += "-active"

	if(!isitem(box))
		return
	var/obj/item/ibox = box
	if(ibox.item_state)
		ibox.item_state = ibox.current_skin ? ibox.unique_reskin[ibox.current_skin]["item_state"] : initial(ibox.item_state)
		if(active)
			ibox.item_state += "-active"
		// Обновляем иконку в руке || прямо как в update_icon_updates_onmob
		if(!ismob(ibox.loc))
			return
		var/mob/M = ibox.loc
		if(M.is_holding(ibox))
			M.update_inv_hands()
		else
			M.regenerate_icons()

/datum/component/jukebox/proc/on_emag_act(atom/source)
	SIGNAL_HANDLER

	var/obj/box = parent
	// Только стационарные можно емагнуть
	if(!need_anchored || box.obj_flags & EMAGGED)
		return

	emag_act(usr)

/datum/component/jukebox/proc/emag_act(mob/user, silent = FALSE)

	var/obj/box = parent
	queuecost = PRICE_FREE
	box.obj_flags |= EMAGGED
	box.req_one_access = null

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
	data["playlists"] = user?.client?.prefs?.playlists

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
		if("repeat")
			repeat = !repeat
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
		if("add_to_queue")
			return add_to_queue(params["track"], usr, params["up"])
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
			box.say("Очередь очищена, удалено треков: [queuedplaylist.len]")
			LAZYCLEARLIST(queuedplaylist)
			return TRUE
		if("remove_from_queue")
			var/index = params["index"]
			if(!index || !queuedplaylist.len || index < 1 || index > queuedplaylist.len)
				return
			var/datum/track/song_to_remove = queuedplaylist[index]
			queuedplaylist.Cut(index, index + 1)
			box.say("[song_to_remove.song_name] была удалена из очереди.")
			return TRUE
		if("new_playlist", "change_playlist", "to_playlist", "move_playlist", "set_playlist_index", "playlist_to_queue", "json", "toggle_favorite", "move_favorite", "set_favorite_index")
			var/mob/living/L = usr
			var/datum/preferences/prefs = L?.client?.prefs
			if(!prefs)
				return
			var/current_playlist_name = params["playlist"]
			var/track = params["track"]
			switch(action)
				if("new_playlist")
					return prefs.playlists_new()
				if("change_playlist")
					return prefs.playlists_change(current_playlist_name, params["delete"])
				if("to_playlist")
					return prefs.playlist_track_change(track, current_playlist_name, params["remove"])
				if("move_playlist")
					return prefs.playlist_tack_move(track, current_playlist_name, params["up"])
				if("set_playlist_index")
					return prefs.playlist_track_set_index(params["index"], track, current_playlist_name)
				if("json")
					return params["playlist_mode"] ? prefs.playlists_json() : prefs.favorite_tracks_json()
				if("playlist_to_queue")
					if(!(current_playlist_name in prefs.playlists))
						return
					var/list/current_playlist = prefs.playlists[current_playlist_name]
					if(!LAZYLEN(current_playlist))
						return
					return add_to_queue(reverseList(current_playlist), usr, FALSE)
				if("toggle_favorite")
					return prefs.favorite_tracks_toggle(track)
				if("move_favorite")
					return prefs.favorite_tracks_move(track, params["up"])
				if("set_favorite_index")
					return prefs.favorite_track_set_index(params["index"], track)

/datum/component/jukebox/proc/add_to_queue(list/tracks, mob/user, to_top = FALSE)
	var/obj/box = parent
	if(QDELETED(src) || QDELETED(box) || !tracks || !COOLDOWN_FINISHED(src, queuecooldown))
		return

	var/list/available = list()
	for(var/datum/track/S in SSjukeboxes.songs)
		available[S.song_name] = S
	if(!islist(tracks))
		tracks = list(tracks)

	var/list/tracks_to_queue = list()
	for(var/selected in tracks)
		var/datum/track/selectedtrack = available[selected]
		if(!istype(selectedtrack))
			continue
		tracks_to_queue += selectedtrack
	if(!tracks_to_queue.len)
		return

	var/need_pay = isliving(user) && !box.allowed(user) && queuecost && ismachinery(box)
	if(need_pay && tracks_to_queue.len > 1)
		var/confirm = tgui_alert(user, "Общая сумма за добавление в очередь составит: [tracks_to_queue.len * queuecost]cr. Продолжить?", "Предупреждение об оплате", list("Да","Нет"))
		if(confirm != "Да")
			return

	var/count_added = 0
	var/spend = 0
	var/datum/track/last_selectedtrack
	var/obj/item/card/id/id_card
	for(var/datum/track/selectedtrack in tracks_to_queue)
		if(need_pay)
			var/obj/machinery/box_machine = box
			var/mob/living/L = user
			if(!id_card)
				id_card = L.get_idcard(TRUE)
			if(!box_machine.can_transact(id_card))
				if(COOLDOWN_FINISHED(src, error_message_cooldown))
					playsound(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
					COOLDOWN_START(src, error_message_cooldown, error_message_cooldown_time)
				break
			if(!box_machine.attempt_transact(id_card, queuecost))
				if(COOLDOWN_FINISHED(src, error_message_cooldown))
					box.say("Недостаточно средств для оплаты[tracks_to_queue.len > 1 ? " всех треков" : ""].")
					playsound(box, 'sound/misc/compiler-failure.ogg', 25, TRUE)
					COOLDOWN_START(src, error_message_cooldown, error_message_cooldown_time)
					sleep(0.3 SECONDS)
				break
			spend += queuecost

		if(to_top)
			queuedplaylist.Insert(1, selectedtrack)
		else
			queuedplaylist += selectedtrack
		last_selectedtrack = selectedtrack
		++count_added
		. = TRUE

	if(!.)
		return
	if(spend)
		to_chat(user, span_notice("Вы потратили [spend]cr поставив в очередь [count_added > 1? "[count_added] треков" : last_selectedtrack.song_name]."))
		log_econ("[spend] credits were inserted into [box] by [key_name(user)] (ID: [id_card?.registered_account?.account_holder]) to queue [count_added > 1 ? "[count_added] tracks" : last_selectedtrack.song_name].")

	if(count_added > 1)
		box.say("[count_added] треков добавлено в очередь.")
	else if(active)
		box.say("[last_selectedtrack.song_name] добавлена в очередь.")

	if(!playing)
		activate_music()
	playsound(box, 'sound/machines/ping.ogg', 50, TRUE)
	COOLDOWN_START(src, queuecooldown, clamp(queuecooldown_time*count_added, 0, queuecooldown_time_max))
	return TRUE

/datum/component/jukebox/proc/activate_music()
	var/obj/box = parent
	if(playing || !queuedplaylist.len)
		return FALSE
	// BLUEMOON ADD - Making sure not to play track if all jukebox channels are busy. That shouldn't happen.
	if(!SSjukeboxes.freejukeboxchannels.len)
		if(COOLDOWN_FINISHED(src, error_message_cooldown))
			box.say("Не удается воспроизвести песню: превышен лимит воспроизводимых в данный момент треков.")
			COOLDOWN_START(src, error_message_cooldown, error_message_cooldown_time)
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
		if(need_anchored)
			if(privatized_area)
				privatized_area.jukebox_privatized_by = null
			var/area/juke_area = get_area(parent)
			juke_area.jukebox_privatized_by = box
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
		if(!silent && COOLDOWN_FINISHED(src, error_message_cooldown))
			box.say("Ошибка датчика вибрации. Необходимо сократить количество музыкальных автоматов в этом районе.")
			COOLDOWN_START(src, error_message_cooldown, error_message_cooldown_time)
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
	if((!active || world.time < stop))
		if(!check_area())
			stop = 0
		else
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



//////////////////// DISCO ////////////////////
/datum/component/jukebox/disco
	var/list/spotlights = list()
	var/list/sparkles = list()

/datum/component/jukebox/disco/activate_music()
	. = ..()
	if(!.)
		return
	dance_setup()
	INVOKE_ASYNC(src, PROC_REF(lights_spin))

/datum/component/jukebox/disco/proc/dance_setup()
	var/turf/cen = get_turf(parent)
	FOR_DVIEW(var/turf/t, 3, cen, INVISIBILITY_LIGHTING)
		if(t.x == cen.x && t.y > cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_RED
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1+get_dist(parent, L)
			spotlights+=L
			continue
		if(t.x == cen.x && t.y < cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_PURPLE
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1+get_dist(parent, L)
			spotlights+=L
			continue
		if(t.x > cen.x && t.y == cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_YELLOW
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1+get_dist(parent, L)
			spotlights+=L
			continue
		if(t.x < cen.x && t.y == cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_GREEN
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1+get_dist(parent, L)
			spotlights+=L
			continue
		if((t.x+1 == cen.x && t.y+1 == cen.y) || (t.x+2==cen.x && t.y+2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_ORANGE
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1.4+get_dist(parent, L)
			spotlights+=L
			continue
		if((t.x-1 == cen.x && t.y-1 == cen.y) || (t.x-2==cen.x && t.y-2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_CYAN
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1.4+get_dist(parent, L)
			spotlights+=L
			continue
		if((t.x-1 == cen.x && t.y+1 == cen.y) || (t.x-2==cen.x && t.y+2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_BLUEGREEN
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1.4+get_dist(parent, L)
			spotlights+=L
			continue
		if((t.x+1 == cen.x && t.y-1 == cen.y) || (t.x+2==cen.x && t.y-2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_BLUE
			L.light_power = 30-(get_dist(parent,L)*8)
			L.range = 1.4+get_dist(parent, L)
			spotlights+=L
			continue
		continue
	FOR_DVIEW_END

#define DISCO_INFENO_RANGE (rand(85, 115)*0.01)

/datum/component/jukebox/disco/proc/lights_spin()
	set waitfor = FALSE
	for(var/i in 1 to 25)
		if(QDELETED(src) || QDELETED(parent) || !active)
			return
		var/obj/effect/overlay/sparkles/S = new /obj/effect/overlay/sparkles(parent)
		S.alpha = 0
		sparkles += S
		switch(i)
			if(1 to 8)
				S.orbit(parent, 30, TRUE, 60, 36, TRUE)
			if(9 to 16)
				S.orbit(parent, 62, TRUE, 60, 36, TRUE)
			if(17 to 24)
				S.orbit(parent, 95, TRUE, 60, 36, TRUE)
			if(25)
				S.pixel_y = 7
				S.forceMove(get_turf(parent))
		sleep(7)
	if(playing.song_name == "Engineering's Ultimate High-Energy Hustle")
		sleep(280)
	for(var/obj/reveal in sparkles)
		reveal.alpha = 255
	while(active)
		for(var/obj/item/flashlight/spotlight/glow in spotlights) // The multiples reflects custom adjustments to each colors after dozens of tests
			if(QDELETED(src) || QDELETED(parent) || !active || QDELETED(glow))
				return
			if(glow.light_color == LIGHT_COLOR_RED)
				glow.light_color = LIGHT_COLOR_BLUE
				glow.light_power = glow.light_power * 1.48
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_BLUE)
				glow.light_color = LIGHT_COLOR_GREEN
				glow.light_range = glow.range * DISCO_INFENO_RANGE
				glow.light_power = glow.light_power * 2 // Any changes to power must come in pairs to neutralize it for other colors
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_GREEN)
				glow.light_color = LIGHT_COLOR_ORANGE
				glow.light_power = glow.light_power * 0.5
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_ORANGE)
				glow.light_color = LIGHT_COLOR_PURPLE
				glow.light_power = glow.light_power * 2.27
				glow.light_range = glow.range * DISCO_INFENO_RANGE
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_PURPLE)
				glow.light_color = LIGHT_COLOR_BLUEGREEN
				glow.light_power = glow.light_power * 0.44
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_BLUEGREEN)
				glow.light_color = LIGHT_COLOR_YELLOW
				glow.light_range = glow.range * DISCO_INFENO_RANGE
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_YELLOW)
				glow.light_color = LIGHT_COLOR_CYAN
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_CYAN)
				glow.light_color = LIGHT_COLOR_RED
				glow.light_power = glow.light_power * 0.68
				glow.light_range = glow.range * DISCO_INFENO_RANGE
				glow.update_light()
				continue
		if(prob(2))  // Unique effects for the dance floor that show up randomly to mix things up
			INVOKE_ASYNC(src, PROC_REF(hierofunk))
		sleep(playing.song_beat)

#undef DISCO_INFENO_RANGE

/datum/component/jukebox/disco/proc/hierofunk()
	for(var/i in 1 to 10)
		spawn_atom_to_turf(/obj/effect/temp_visual/hierophant/telegraph/edge, parent, 1, FALSE)
		sleep(5)
		if(QDELETED(src) || QDELETED(parent))
			return

/datum/component/jukebox/disco/proc/dance(var/mob/living/M) //Show your moves
	set waitfor = FALSE
	// switch(rand(0,9))
	// 	if(0 to 1)
	dance2(M) // остался только эмоут, не ломающий спрайты
		// if(2 to 3)
		// 	dance3(M)
		// if(4 to 6)
		// 	dance4(M)
		// if(7 to 9)
		// 	dance5(M)

/datum/component/jukebox/disco/proc/dance2(var/mob/living/M)
	for(var/i = 1, i < 10, i++)
		for(var/d in list(NORTH,SOUTH,EAST,WEST,EAST,SOUTH,NORTH,SOUTH,EAST,WEST,EAST,SOUTH))
			M.setDir(d)
			if(i == WEST)
				M.emote("flip")
			sleep(1)
		sleep(20)

/*
/datum/component/jukebox/disco/proc/dance3(var/mob/living/M)
	var/matrix/initial_matrix = matrix(M.transform)
	for (var/i in 1 to 75)
		if (!M)
			return
		switch(i)
			if (1 to 15)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (16 to 30)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(1,-1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (31 to 45)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-1,-1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (46 to 60)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-1,1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (61 to 75)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(1,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		M.setDir(turn(M.dir, 90))
		switch (M.dir)
			if (NORTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (SOUTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,-3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (EAST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (WEST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		sleep(1)
	M.lying_fix()

/datum/component/jukebox/disco/proc/dance4(var/mob/living/M)
	var/speed = rand(1,3)
	set waitfor = 0
	var/time = 30
	while(time)
		sleep(speed)
		for(var/i in 1 to speed)
			M.setDir(pick(GLOB.cardinals))
			// update resting manually to avoid chat spam CITADEL EDIT - NO MORE RESTSPAM
			//for(var/mob/living/carbon/NS in rangers)
			//	NS.resting = !NS.resting
			//	NS.update_canmove()
		time--

/datum/component/jukebox/disco/proc/dance5(var/mob/living/M)
	animate(M, transform = matrix(180, MATRIX_ROTATE), time = 1, loop = 0)
	var/matrix/initial_matrix = matrix(M.transform)
	for (var/i in 1 to 60)
		if (!M)
			return
		if (i<31)
			initial_matrix = matrix(M.transform)
			initial_matrix.Translate(0,1)
			animate(M, transform = initial_matrix, time = 1, loop = 0)
		if (i>30)
			initial_matrix = matrix(M.transform)
			initial_matrix.Translate(0,-1)
			animate(M, transform = initial_matrix, time = 1, loop = 0)
		M.setDir(turn(M.dir, 90))
		switch (M.dir)
			if (NORTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (SOUTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,-3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (EAST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (WEST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		sleep(1)
	M.lying_fix()

/mob/living/proc/lying_fix()
	animate(src, transform = null, time = 1, loop = 0)
	lying_prev = 0
*/

/datum/component/jukebox/disco/dance_over()
	. = ..()
	QDEL_LIST(spotlights)
	QDEL_LIST(sparkles)

/datum/component/jukebox/disco/process()
	. = ..()
	if(active)
		for(var/mob/living/M in hearers(2, parent))
			var/obj/box = parent
			if(prob(5+(box.allowed(M)*4)) && CHECK_MOBILITY(M, MOBILITY_MOVE) && (!M.client || !(M.client.prefs.cit_toggles & NO_DISCO_DANCE)))
				dance(M)

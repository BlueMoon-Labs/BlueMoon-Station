//WHITE-STEEL PORT - Шифровальный ключ исследовательского канала

/obj/item/encryptionkey/headset_exp
	name = "miniaturized exploration radio encryption key"
	icon_state = "exp_cypherkey"
	channels = list(RADIO_CHANNEL_EXPLORATION = TRUE)

//WHITE-STEEL PORT - Анонс для экипажа шаттла и наблюдателей о старте миссии

/proc/exploration_announce(text, z_value)
	if(!text)
		return
	if(!z_value)
		z_value = 0
	var/list/announce_to = list()
	for(var/mob/M in GLOB.player_list)
		if(!M.client)
			continue
		if(M.stat == DEAD)
			announce_to += M
			continue
		if(z_value && M.z == z_value)
			announce_to += M
			continue
		if(istype(get_area(M), /area/shuttle/exploration))
			announce_to += M
	for(var/mob/M in announce_to)
		if(!M.client)
			continue
		SEND_SOUND(M, sound('sound/misc/notice2.ogg'))
		to_chat(M, "<span class='boldannounce'>Обновление Рейнджеров:</span>")
		to_chat(M, "<span class='notice'>[text]</span>")
	print_command_report(text, "Обновление Рейнджеров", FALSE)

//WHITE-STEEL PORT - Зоны рейнджеров

/area/cargo/exploration_prep
	name = "Подготовка рейнджеров"
	icon_state = "rangers_prep"

/area/cargo/exploration_dock
	name = "Док рейнджеров"
	icon_state = "rangers_dock"

/area/cargo/exploration_mission
	name = "Поле действий рейнджеров"
	icon_state = "rangers_mission"

/area/shuttle/exploration
	name = "Vanguard Igla shuttle"
	icon_state = "rangers_shuttle"
	ambientsounds = RANGERS_AMB

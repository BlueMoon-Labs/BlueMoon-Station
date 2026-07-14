//Helper proc to get an Eminence mob if it exists
/proc/get_eminence()
	return locate(/mob/camera/eminence) in servants_and_ghosts()

//The Eminence is a unique mob that functions like the leader of the cult. It's incorporeal but can interact with the world in several ways.
/mob/camera/eminence
	name = "\the Emininence"
	real_name = "\the Eminence"
	desc = "Избранный лидер слуг Ратвара."
	icon = 'icons/effects/clockwork_effects.dmi'
	icon_state = "eminence"
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	move_on_shuttle = TRUE
	see_in_dark = 8
	invisibility = INVISIBILITY_OBSERVER
	layer = FLY_LAYER
	faction = list("ratvar")
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	var/turf/last_failed_turf
	var/static/superheated_walls = 0
	var/lastWarning = 0

/mob/camera/eminence/CanPass(atom/movable/mover, turf/target)
	return TRUE

/mob/camera/eminence/Move(NewLoc, direct)
	var/OldLoc = loc
	if(NewLoc && !istype(NewLoc, /turf/open/indestructible/reebe_void))
		var/turf/T = get_turf(NewLoc)
		if(!GLOB.ratvar_awakens)
			if(locate(/obj/effect/blessing, T))
				if(last_failed_turf != T)
					T.visible_message("<span class='warning'>[T] внезапно издает звонкий звук!</span>", null, null, null, src)
					playsound(T, 'sound/machines/clockcult/ark_damage.ogg', 75, FALSE)
					last_failed_turf = T
				if((world.time - lastWarning) >= 30)
					lastWarning = world.time
					to_chat(src, "<span class='warning'>Эта территория освящена, и на нее нельзя входить!</span>")
				return
			if(istype(get_area(T), /area/service/chapel))
				if((world.time - lastWarning) >= 30)
					lastWarning = world.time
					to_chat(src, "<span class='warning'>Церковь является священным местом, посвящённым еретическому божеству, и вход туда запрещён!</span>")
				return
		else
			for(var/turf/TT in range(5, src))
				if(prob(166 - (get_dist(src, TT) * 33)))
					TT.ratvar_act() //Causes moving to leave a swath of proselytized area behind the Eminence
		forceMove(T)
		Moved(OldLoc, direct)

/mob/camera/eminence/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE

/mob/camera/eminence/Login()
	..()
	add_servant_of_ratvar(src, TRUE)
	var/datum/antagonist/clockcult/C = mind.has_antag_datum(/datum/antagonist/clockcult,TRUE)
	if(C && C.clock_team)
		if(C.clock_team.eminence && C.clock_team.eminence != src)
			remove_servant_of_ratvar(src,TRUE)
			qdel(src)
			return
		else
			C.clock_team.eminence = src
	to_chat(src, "<span class='bold large_brass'>Вы были выбраны в качестве Епископа!</span>")
	to_chat(src, "<span class='brass'>Как Епископ, вы возглавляете служителей. Все, что вы скажете, услышит весь культ.</span>")
	to_chat(src, "<span class='brass'>Хотя вы можете проходить сквозь стены, вы также бесплотны и практически не можете взаимодействовать с окружающим миром, за исключением нескольких способов.</span>")
	to_chat(src, "<span class='brass'>Кроме того, если маяк вестника не активирован, вы не сможете понимать речь, находясь вдали от Риба.</span>")
	eminence_help()
	for(var/V in actions)
		var/datum/action/A = V
		A.Remove(src) //So we get rid of duplicate actions; this also removes Hierophant network, since our say() goes across it anyway
	var/datum/action/innate/eminence/E
	for(var/V in subtypesof(/datum/action/innate/eminence))
		E = new V
		E.Grant(src)

/mob/camera/eminence/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, "Вы не можете отправлять IC сообщения (muted).")
			return
		if(client.handle_spam_prevention(message,MUTE_IC))
			return
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return
	src.log_talk(message, LOG_SAY, tag="clockwork eminence")
	if(GLOB.ratvar_awakens)
		visible_message("<span class='brass'><b>Ты чувствуешь, как свет врывается в твой разум и складывается в слова:</b> \"[capitalize(message)]\"</span>")
		playsound(src, 'sound/machines/clockcult/ark_scream.ogg', 50, FALSE)
	message = "<span class='big brass'><b>[GLOB.ratvar_awakens ? "Сияние" : "Епископ"]:</b> \"[message]\"</span>"
	for(var/mob/M in servants_and_ghosts())
		if(isobserver(M))
			var/link = FOLLOW_LINK(M, src)
			to_chat(M, "[link] [message]")
		else
			to_chat(M, message)

/mob/camera/eminence/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if(is_reebe(z) || is_servant_of_ratvar(speaker) || GLOB.ratvar_approaches || GLOB.ratvar_awakens) //Away from Reebe, the Eminence can't hear anything
		to_chat(src, message)
		return
	to_chat(src, "<i>[speaker] что-то говорит, но вы ни слова не понимаете...</i>")

/mob/camera/eminence/ClickOn(atom/A, params)
	var/list/modifiers = params2list(params)
	if(modifiers["shift"])
		A.examine(src)
		return
	if(modifiers["alt"] && istype(A, /turf/closed/wall/clockwork))
		superheat_wall(A)
		return
	if(modifiers["middle"] || modifiers["ctrl"])
		INVOKE_ASYNC(src, PROC_REF(issue_command), A)
		return
	if(GLOB.ark_of_the_clockwork_justiciar == A)
		var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
		INVOKE_ASYNC(src, PROC_REF(attempt_recall), G)
	else if(istype(A, /obj/structure/destructible/clockwork/trap/trigger))
		var/obj/structure/destructible/clockwork/trap/trigger/T = A
		T.visible_message("<span class='danger'>[T] стучит при дистанционном включении.</span>")
		to_chat(src, "<span class='brass'>Вы активируете [T].</span>")
		T.activate()

/mob/camera/eminence/proc/attempt_recall(obj/structure/destructible/clockwork/massive/celestial_gateway/G)
	if(G.recalling)
		return
	if(!G.recalls_remaining)
		to_chat(src, "<span class='warning'>Ковчег больше не может призывать слуг!</span>")
		return
	if(alert(src, "Инициировать массовое возвращение?", "Массовое возвращение", "Да", "Нет") != "Да" || QDELETED(src) || QDELETED(G) || !G.obj_integrity)
		return
	G.initiate_mass_recall() //wHOOPS LOOKS LIKE A HULK GOT THROUGH

/mob/camera/eminence/ratvar_act()
	name = "\improper Radiance"
	real_name = "\improper Radiance"
	desc = "Свет, забытый."
	transform = matrix() * 2
	invisibility = SEE_INVISIBLE_MINIMUM

/mob/camera/eminence/proc/issue_command(atom/movable/A)
	var/list/commands
	var/atom/movable/command_location
	if(A == src)
		commands = list("Защищайте Ковчег!", "Вперед!", "Отступайте!", "Генерируйте энергию", "Создавайте защитные механизмы (снизу вверх)", "Создавайте защитные механизмы (сверху вниз)")
	else
		command_location = A
		commands = list("Сбор здесь", "Перегруппировка здесь", "Не приближайтесь к этой зоне", "Укрепите эту зону")
		if(istype(A, /obj/structure/destructible/clockwork/powered))
			var/obj/structure/destructible/clockwork/powered/P = A
			if(!can_access_clockwork_power(P))
				commands += "Запитайте эту структуру"
			if(P.obj_integrity < P.max_integrity)
				commands += "Почините эту структуру"
	var/roma_invicta = input(src, "Выбери команду, которую хочешь отдать своему культу!", "Выполнение команд") as null|anything in commands
	if(!roma_invicta)
		return
	var/command_text = ""
	var/marker_icon
	switch(roma_invicta)
		if("Сбор здесь")
			command_text = "Епископ отдает приказ о наступлении в точке [command_location] в направлении GETDIR!"
			marker_icon = "eminence_rally"
		if("Перегруппировка здесь")
			command_text = "Епископ приказывает перегруппироваться в [command_location] в направлении GETDIR!"
			marker_icon = "eminence_rally"
		if("Не приближайтесь к этой зоне")
			command_text = "Епископ признало территорию, в направлении GETDIR, опасной и рекомендует держаться от неё подальше!"
			marker_icon = "eminence_avoid"
		if("Укрепите эту зону")
			command_text = "Епископ приказывает укрепить и удерживать область в направлении GETDIR!"
			marker_icon = "eminence_reinforce"
		if("Запитайте эту структуру")
			command_text = "[command_location] в направлении GETDIR не работает! Включите его и убедитесь, что поблизости есть сигил передачи!"
			marker_icon = "eminence_unlimited_power"
		if("Почините эту структуру")
			command_text = "Епископ приказывает как можно скорее устранить неполадку в [command_location], в направлении GETDIR!"
			marker_icon = "eminence_repair"
		if("Защищайте Ковчег!")
			command_text = "Епископ приказывает немедленно принять меры по защите Ковчега!"
		if("Вперед!")
			command_text = "Епископ приказывает вам идти вперед!"
		if("Отступайте!")
			command_text = "Епископ отдал приказ к отступлению! Отступаем!"
		if("Генерируйте энергию")
			command_text = "Епископ приказывает увеличить энергию! Постройте на станции энергетические генераторы!"
		if("Создавайте защитные механизмы (снизу вверх)")
			command_text = "Епископ приказал возвести оборонительные сооружения, начиная с нижней части Риба!"
		if("Создавайте защитные механизмы (сверху вниз)")
			command_text = "Его Преосвященство приказал возвести оборонительные сооружения, начиная с вершины Риба!"
	if(marker_icon)
		new/obj/effect/temp_visual/ratvar/command_point(get_turf(A), marker_icon)
		for(var/mob/M in servants_and_ghosts())
			to_chat(M, "<span class='large_brass'>[replacetext(command_text, "GETDIR", dir2text(get_dir(M, command_location)))]</span>")
			M.playsound_local(M, 'sound/machines/clockcult/eminence_command.ogg', 75, FALSE, pressure_affected = FALSE)
	else
		hierophant_message("<span class='bold large_brass'>[command_text]</span>")
		for(var/mob/M in servants_and_ghosts())
			M.playsound_local(M, 'sound/machines/clockcult/eminence_command.ogg', 75, FALSE, pressure_affected = FALSE)

/mob/camera/eminence/proc/superheat_wall(turf/closed/wall/clockwork/wall)
	if(!istype(wall))
		return
	if(superheated_walls >= SUPERHEATED_CLOCKWORK_WALL_LIMIT && !wall.heated)
		to_chat(src, "<span class='warning'>Вы уже тратите все ваши силы на перегрев такого количества стен! Сначала остудите их!</span>")
		return
	wall.turn_up_the_heat()
	if(wall.heated)
		superheated_walls++
		to_chat(src, "<span class='neovgre_small'>Вы перегреваете [wall]. <b>Перегретые стены:</b> [superheated_walls]/[SUPERHEATED_CLOCKWORK_WALL_LIMIT]")
	else
		superheated_walls--
		to_chat(src, "<span class='neovgre_small'>Вы остужаете [wall]. <b>Перегретые стены:</b> [superheated_walls]/[SUPERHEATED_CLOCKWORK_WALL_LIMIT]")

/mob/camera/eminence/proc/eminence_help()
	to_chat(src, "<span class='bold alloy'>Вы можете использовать определенные сочетания клавиш для выполнения различных действий:</span>")
	to_chat(src, "<span class='alloy'><b>Alt-Click по часовым стенам</b>, чтобы перегреть или охладить их. \
	Перегретые стены не поддаются разрушению ни гигантами, ни мехами, их демонтаж занимает гораздо больше времени, и они отмечены ярким красным свечением. \
	Этот эффект действует бесконечно, но одновременно можно перегреть не более [SUPERHEATED_CLOCKWORK_WALL_LIMIT] часовых стен.</span>")
	to_chat(src, "<span class='alloy'><b>Взаимодействуйте с Ковчегом</b>, чтобы инициировать экстренный отзыв, который через небольшую задержку телепортирует всех слуг прямо к нему. \
	Это можно использовать только один раз, или дважды, если был активирован маяк глашатая,</span>")
	to_chat(src, "<span class='alloy'><b>Щелкните средней кнопкой мыши или зажмите Ctrl и щелкните в любом месте</b>, чтобы вывести контекстное меню команд для вашего культа. Различные объекты открывают доступ к разным \
    командам. <i>Если вы выполните это действие на себе, появятся команды, позволяющие задать цель всему культу.</i></span>")


//Eminence actions below this point
/datum/action/innate/eminence
	name = "Eminence Action"
	desc = "Вы не должны видеть это. Отправьте отчет об этом баге!"
	icon_icon = 'icons/mob/actions/actions_clockcult.dmi'
	background_icon_state = "bg_clock"
	buttontooltipstyle = "clockcult"

/datum/action/innate/eminence/IsAvailable(silent = FALSE)
	if(!iseminence(owner))
		qdel(src)
		return
	return ..()

//Lists available powers
/datum/action/innate/eminence/power_list
	name = "Eminence Powers"
	desc = "Забыли, на что вы способны? Здесь вы сможете освежить в памяти свои способности в роли Епископа."
	button_icon_state = "eminence_rally"

/datum/action/innate/eminence/power_list/Activate()
	var/mob/camera/eminence/E = owner
	E.eminence_help()


/*

//Returns to the Ark - Commented out and replaced with obelisk_jump
/datum/action/innate/eminence/ark_jump
	name = "Return to Ark"
	desc = "Warps you to the Ark."
	button_icon_state = "Abscond"

/datum/action/innate/eminence/ark_jump/Activate()
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
	if(G)
		owner.forceMove(get_turf(G))
		owner.playsound_local(owner, 'sound/magic/magic_missile.ogg', 50, TRUE)
		flash_color(owner, flash_color = "#AF0AAF", flash_time = 25)
	else
		to_chat(owner, "<span class='warning '>There is no Ark!</span>")
*/

//Warps to a chosen Obelisk
/datum/action/innate/eminence/obelisk_jump
	name = "Warp to Obelisk"
	desc = "Переносит к выбранному механическому обелиску."
	button_icon_state = "Abscond"

/datum/action/innate/eminence/obelisk_jump/Activate()
	var/list/possible_targets = list()
	var/list/warpnames = list()

	for(var/obj/structure/destructible/clockwork/powered/clockwork_obelisk/O in GLOB.all_clockwork_objects)
		if(!O.Adjacent(owner) && O.anchored)
			var/area/A = get_area(O)
			var/locname = initial(A.name)
			possible_targets[avoid_assoc_duplicate_keys("[locname] [O.name]", warpnames)] = O

	if(!possible_targets.len)
		to_chat(owner, "<span class='warning'>Нет обелисков, на которые можно было бы телепортироваться!</span>")
		return

	var/target_key = input(owner, "Выберите обелиск, к которому хотите телепортироваться.", "Телепорт к обелиску") as null|anything in possible_targets
	var/obj/structure/destructible/clockwork/powered/clockwork_obelisk/target = possible_targets[target_key]

	if(!target_key || !owner)
		return

	if(!target)
		to_chat(owner, "<span class='warning'>Этот обелиск больше не существует!</span>")
		return
	owner.forceMove(get_turf(target))
	owner.playsound_local(owner, 'sound/magic/magic_missile.ogg', 50, TRUE)
	flash_color(owner, flash_color = "#AF0AAF", flash_time = 25)

//Warps to the Station
/datum/action/innate/eminence/station_jump
	name = "Warp to Station"
	desc = "Переносит на космическую станцию 13. Там ничего не слышно!</span>"
	button_icon_state = "warp_down"

/datum/action/innate/eminence/station_jump/Activate()
	if(is_reebe(owner.z))
		owner.forceMove(get_turf(pick(GLOB.generic_event_spawns)))
		owner.playsound_local(owner, 'sound/magic/magic_missile.ogg', 50, TRUE)
		flash_color(owner, flash_color = "#AF0AAF", flash_time = 25)
	else
		to_chat(owner, "<span class='warning'>Вы уже на станции!</span>")

//A quick-use button for recalling the servants to the Ark
/datum/action/innate/eminence/mass_recall
	name = "Mass Recall"
	desc = "Инициирует массовый отзыв, перенося всех слуг на Ковчег через небольшую задержку. Эту способность можно использовать только один раз."
	button_icon_state = "Spatial Gateway"

/datum/action/innate/eminence/mass_recall/IsAvailable(silent = FALSE)
	. = ..()
	if(.)
		var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
		if(G)
			return G.recalls_remaining && !G.recalling
		return FALSE

/datum/action/innate/eminence/mass_recall/Activate()
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/G = GLOB.ark_of_the_clockwork_justiciar
	if(G && !G.recalling && G.recalls_remaining)
		if(alert(owner, "Инициировать массовый отзыв?", "Массовый отзыв", "Да", "Нет") != "Да" || QDELETED(owner) || QDELETED(G) || !G.obj_integrity)
			return
		G.initiate_mass_recall()

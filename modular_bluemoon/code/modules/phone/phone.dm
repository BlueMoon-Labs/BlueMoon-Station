/**
 * ПАМЯТКА О КАЧЕСТВЕННОЙ РАССТАНОВКЕ ТЕЛЕФОНОВ НА СТАНЦИИ
 *
 * Данная памятка для мапперов носит рекомендательный характер.
 * Я принес данный предмет на этот билд с CMSS13 (Colonial Marines), качественно улучшил и исправил имевшееся недостатки и баги данного предмета,
 * я заинтересован в повышении качества игры тех, кто будет пользоваться моими наработками. Поэтому я поделюсь ходом моего рассуждения и принятия решений
 * при расстановке данного предмета на станции, т.к. этот предмет разработан, протестирован и откалиброван, основываясь на описанных далее принципах.
 * Даже на оригинальном билде телефоны расставлены с оглядкой на идею о назначении данного предмета, на них же и строятся эти принципы.
 *
 * Данный предмет рассматривается как "звонок в отдел". Не важно кому конкретно и не важно кто возьмет трубку, т.е. телефон это преимущественно
 * способ связи "Персона->Отдел" или "Отдел->Отдел". "Отдел" означает не конкретное подразделение отдела (ксенобиология, роботехи, детектив), а именно
 * отдел целиком (РНД, Карго, СБ). Телефон издает звон в радиусе около 10 тайлов и его слышно сквозь стены.
 * Командные телефоны считаются персональными, т.к. мы звоним конкретному главе и пользуются ими только конкретные главы. Однако на мостике должен стоять
 * один обычный телефон, т.к. он будет телефоном отдела Командования.
 * Также по станции расставлены дополнительные гражданские телефоны, которые не относятся к отделам и установлены для гражданского использования:
 * бар, библиотека, по одному на каждой стороне света станции (север, юг, запад, восток) и в центре станции.
 *
 * Существует строгая вертикальная иерархия телефонных связей:
 * 		ЦК->СИНДИ->КОМАНДОВАНИЕ->ПУБЛИЧНАЯ
 * Все прозванивается сверху вниз, но никак не наоборот, вышестоящих даже не видно.
 *
 * Принципы расстановки телефонов (начиная с обязательных, заканчивая менее важными):
 * 1) Один телефон на отдел = идеал. Не более двух телефонов на отдел.
 *		Когда пользователь хочет позвонить в отдел не важно какому лицу, ему безразлично звонить ли в токсинную, в ксенобиологию или в робо.
		Иначе пользователь воспользовался бы ПДА или голопадом. Пользователь будет звонить на первый попавшийся телефон и не будет прозванивать
		5 разных телефонов в одном и том же отделе, если в какой-то жопе отдела не было сотрудника.
 * 2) Телефон должен находиться в зоне концентрации рабочего пространства игроков или близко к нему.
 * 		Телефон надо ставить там, где ОДНОЗНАЧНО будут ходить или работать активные игроки отдела, даже если это будет в ущерб площади
 * 		"полезного покрытия". Не надо ставить телефоны в местах, где игроки почти никогда не ходят. Даже если игроки будут слышать телефон
 * 		из своей рабочей зоны, игроки могут намеренно игнорировать его или просто не успеют взять трубку, если игроку будет далеко идти
 * 		до телефона.
 * 		Пример: в отделе СБ телефон надо ставить прямо на проходной, т.к. активные игроки отдела обычно не сидят в глубине, а часто
 * 		выходят гулять, в отличие, например, от Инженерного отдела, где игроки проводят много времени внутри отдела за настройкой движков, а на
 * 		проходной почти никогда никого нет.
 * 3) Телефон должен быть заметным и легкодоступным.
 * 		Телефон должен хорошо восприниматься при беглом осмотре комнаты, не должен быть завален предметами или находиться в самом дальнем углу комнаты.
 * 		Желательно, чтобы телефон не был перегорожен стенкой и игроку не приходилось обходить какие-то сторонние предметы
 * 		на пути (столы, закутки из стен и т.п.).
 * 4) Телефон должен покрывать максимум "полезного" рабочего пространства.
 * 		Под "полезным рабочим пространством" подразумевается место с максимальной концентрацией активных игроков отдела, которые не занимаются своими
 * 		отвлеченными делами. Важно "покрывать" места, где игроки будут готовы ответить на рабочий звонок. Отдельно "покрывать" места отдыха или
 * 		удаленные закутки отдела неблагоразумно и малополезно, т.к. игроки там не работают или занимаются своими отвлеченными делами
 * 		и вероятнее всего им будет безразлично на рабочий звонок в отдел, но вероятнее всего там попросту никого не будет.
 * 5) Не надо размещать два одинаковых телефона в одной и той же области/комнате.
 * 		Это касается очень протяженных и объемных областей и холлов отделов, требующих по мнению маппера "покрытия". Телефон при появлении на карте
 * 		получает имя области/комнаты. Два телефона в одной области получат идентичные названия + номер по порядку, даже если находятся далеко друг
 * 		от друга за пределами экрана игрока и области слышимости звонка. Пользователь при попытке позвонить в отдел выберет случайный из них и
 * 		будет пытаться дозвониться до телефона на другом конце отдела, не подозревая о том, куда конкретно он звонит. Это решается установкой
 * 		второго телефона в ближайшей смежной зоне/комнате, которая имеет другое название области.
 * 6) Нежелательно, чтобы несколько различных телефонов находились близко друг к другу.
 * 		Под различными телефонами подразумеваются телефоны из разных отделов или "юрисдикций", например общедоступный гражданский телефон, телефон отдела
 * 		и телефон главы это три различных телефона и ставить их очень близко друг к другу нежелательно, т.к. могут звонить в одно место, а услышат
 * 		все в округе.
 */

GLOBAL_LIST_EMPTY_TYPED(transmitters, /obj/structure/transmitter)

#define COMSIG_TRANSMITTER_UPDATE_ICON "transmitter_update_icon"

// #define TRANSMITTER_UNAVAILABLE(T) (T.get_calling_phone() || !T.attached_to || T.attached_to.loc != T || !T.enabled)

#define TRANSMITTER_UNAVAILABLE(T) (\
	!T.attached_to \
	|| !T.enabled\
)

#define PHONE_NET_PUBLIC	"Public"
#define PHONE_NET_COMMAND	"Command"
#define PHONE_NET_SYNDICATE	"Syndicate"
#define PHONE_NET_INTEQ		"InteQ"
#define PHONE_NET_CENTCOMM	"CentComm"

#define PHONE_DND_FORCED 2
#define PHONE_DND_ON 1
#define PHONE_DND_OFF 0
#define PHONE_DND_FORBIDDEN -1

/obj/structure/transmitter
	name = "rotary telephone"
	icon = 'modular_bluemoon/icons/obj/structures/phone.dmi'
	icon_state = "rotary_phone"
	desc = "The finger plate is a little stiff."
	anchored = TRUE
	layer = OBJ_LAYER + 0.01
	pass_flags = PASSTABLE
	var/phone_category = PHONE_NET_PUBLIC
	var/phone_color = "white"
	var/phone_id = "Telephone"
	var/phone_icon
	var/obj/item/telephone/attached_to
	// var/atom/tether_holder
	var/obj/structure/transmitter/outbound_call
	var/obj/structure/transmitter/inbound_call
	var/next_ring = 0
	var/phone_type = /obj/item/telephone
	var/range = 3
	var/enabled = TRUE
	/// Whether or not the phone is receiving calls or not. Varies between on/off or forcibly on/off.
	var/do_not_disturb = PHONE_DND_OFF
	/// The Phone_ID of the last person to call this telephone.
	var/last_caller
	var/list/callers_list = list()
	var/default_icon_state
	var/timeout_timer_id
	var/timeout_duration = 30 SECONDS
	/// THEY can call you from there (and above)
	var/list/networks_receive = list(PHONE_NET_PUBLIC)
	/// YOU can call there
	var/list/networks_transmit = list(PHONE_NET_PUBLIC)
	var/datum/looping_sound/telephone/busy/busy_loop
	var/datum/looping_sound/telephone/hangup/hangup_loop
	var/datum/looping_sound/telephone/ring/outring_loop
	var/can_rename = FALSE

/obj/structure/transmitter/Initialize(mapload, ...)
	. = ..()
	default_icon_state = icon_state
	attached_to = new phone_type(src)
	RegisterSignal(attached_to, COMSIG_PARENT_PREQDELETED, PROC_REF(override_delete))
	update_icon()
	outring_loop = new(attached_to)
	busy_loop = new(attached_to)
	hangup_loop = new(attached_to)
	if(!get_turf(src))
		return
	GLOB.transmitters += src
	if(name == initial(name))
		name = "[get_area_name(src, get_base_area = TRUE)] [initial(name)]"
		phone_id = "[get_area_name(src, get_base_area = TRUE)]"

/obj/structure/transmitter/Destroy()
	if(attached_to)
		if(attached_to.loc == src)
			UnregisterSignal(attached_to, COMSIG_PARENT_PREQDELETED)
			qdel(attached_to)
		else
			attached_to.attached_to = null
		attached_to = null
	GLOB.transmitters -= src
	SStgui.close_uis(src)
	reset_call()
	return ..()

/obj/structure/transmitter/proc/override_delete()
	SIGNAL_HANDLER
	recall_phone()
	return TRUE

/obj/structure/transmitter/examine(mob/user)
	. = ..()
	if(attached_to && attached_to.loc != src)
		. += span_notice("Ctrl-Shift-Click to pull the phone back.")
	if(can_rename)
		. += span_notice("Alt-Click to rename it.")
	if(outbound_call)
		. += span_warning("Outgoing call: [outbound_call.phone_id]")
	if(inbound_call)
		. += span_warning("Inconming call: [last_caller]")
	. += span_notice("Last 5 callers:")
	for(var/i in callers_list)
		. += span_notice(i)

/obj/structure/transmitter/CtrlShiftClick(mob/user)
	recall_phone()

/obj/structure/transmitter/update_icon()
	. = ..()
	SEND_SIGNAL(src, COMSIG_TRANSMITTER_UPDATE_ICON)
	if(attached_to.loc != src)
		icon_state = "[default_icon_state]_ear"
		return
	if(inbound_call)
		icon_state = "[default_icon_state]_ring"
	else
		icon_state = default_icon_state

/obj/structure/transmitter/Moved(atom/OldLoc, Dir)
	. = ..()
	if(attached_to)
		if(!attached_to.do_zlevel_check())
			recall_phone()
		if(get_dist(attached_to, src) > range)
			if(ismob(attached_to.loc))
				var/mob/M = attached_to.loc
				M.dropItemToGround(attached_to, TRUE)
			else
				recall_phone()

/obj/structure/transmitter/attack_hand(mob/user)
	. = ..()
	if(!attached_to || attached_to.loc != src)
		return
	if(!ishuman(user))
		return
	if(!enabled)
		return
	if(!get_calling_phone())
		ui_interact(user)
		return
	var/obj/structure/transmitter/T = get_calling_phone()
	if(T.attached_to)
		if(ismob(T.attached_to.loc))
			var/mob/M = T.attached_to.loc
			to_chat(M, span_purple("[icon2html(src, M)] [phone_id] has picked up."))
		playsound(T.attached_to.loc, 'modular_bluemoon/sound/machines/telephone/remote_pickup.ogg', 20)
		if(T.timeout_timer_id)
			deltimer(T.timeout_timer_id)
			T.timeout_timer_id = null
	to_chat(user, span_purple("[icon2html(src, user)] Picked up a call from [T.phone_id]."))
	playsound(get_turf(user), pick('modular_bluemoon/sound/machines/telephone/rtb_handset_1.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_2.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_3.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_4.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_5.ogg'))
	T.outring_loop.stop()
	user.put_in_active_hand(attached_to)
	update_icon()

/obj/structure/transmitter/attackby(obj/item/I, mob/user, params)
	if(I == attached_to)
		recall_phone()
	else if(I.tool_behaviour == TOOL_WRENCH)
		if(!anchored && !isinspace())
			to_chat(user,"<span class='notice'>You secure [src] to the floor.</span>")
			setAnchored(TRUE)
		else if(anchored)
			to_chat(user,"<span class='notice'>You unsecure and disconnect [src].</span>")
			setAnchored(FALSE)
		playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
		return
	else
		return ..()

/obj/structure/transmitter/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(TRANSMITTER_UNAVAILABLE(src))
		return UI_CLOSE

/obj/structure/transmitter/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(TRANSMITTER_UNAVAILABLE(src))
		return
	if(!ishuman(usr))
		return
	var/mob/living/carbon/human/user = usr
	switch(action)
		if("call_phone")
			call_phone(user, params["phone_id"])
			. = TRUE
			SStgui.close_uis(src)
		if("toggle_dnd")
			toggle_dnd(user)
	update_icon()

/obj/structure/transmitter/ui_interact(mob/user, datum/tgui/ui)
	if(inbound_call)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PhoneMenu", phone_id)
		ui.open()

/obj/structure/transmitter/ui_data(mob/user)
	var/list/data = list()
	data["availability"] = do_not_disturb
	data["last_caller"] = last_caller
	return data

/obj/structure/transmitter/ui_static_data(mob/user)
	. = list()
	.["available_transmitters"] = get_transmitters() - list(phone_id)
	var/list/transmitters = list()
	for(var/i in GLOB.transmitters)
		var/obj/structure/transmitter/T = i
		transmitters += list(list(
			"phone_category" = T.phone_category,
			"phone_color" = T.phone_color,
			"phone_id" = T.phone_id,
			"phone_icon" = T.phone_icon
		))
	.["transmitters"] = transmitters

/obj/structure/transmitter/proc/get_transmitters()
	var/list/phone_list = list()
	for(var/possible_phone in GLOB.transmitters)
		var/obj/structure/transmitter/target_phone = possible_phone
		var/current_dnd = FALSE
		switch(target_phone.do_not_disturb)
			if(PHONE_DND_ON, PHONE_DND_FORCED)
				current_dnd = TRUE
		if(TRANSMITTER_UNAVAILABLE(target_phone) || current_dnd) // Phone not available
			continue
		var/net_link = FALSE
		for(var/network in networks_transmit)
			if(network in target_phone.networks_receive)
				net_link = TRUE
				continue
		if(!net_link)
			continue
		var/id = target_phone.phone_id
		var/num_id = 1
		while(id in phone_list)
			id = "[target_phone.phone_id] [num_id]"
			num_id++
		target_phone.phone_id = id
		phone_list[id] = target_phone
	return phone_list

/obj/structure/transmitter/proc/call_phone(mob/living/carbon/human/user, calling_phone_id)
	var/list/transmitters = get_transmitters()
	transmitters -= phone_id
	if(!length(transmitters) || !(calling_phone_id in transmitters))
		to_chat(user, span_purple("[icon2html(src, user)] No transmitters could be located to call!"))
		return
	var/obj/structure/transmitter/T = transmitters[calling_phone_id]
	if(!istype(T) || QDELETED(T))
		transmitters -= T
		CRASH("Qdelled/improper atom inside transmitters list! (istype returned: [istype(T)], QDELETED returned: [QDELETED(T)])")
	if(TRANSMITTER_UNAVAILABLE(T))
		return
	user.put_in_hands(attached_to)
	to_chat(user, span_purple("[icon2html(src, user)] Dialing [calling_phone_id].."))
	playsound(get_turf(user), pick('modular_bluemoon/sound/machines/telephone/rtb_handset_1.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_2.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_3.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_4.ogg',
									'modular_bluemoon/sound/machines/telephone/rtb_handset_5.ogg'), 100)
	if(T.get_calling_phone() || T.attached_to.loc != T)
		to_chat(user, span_purple("[icon2html(src, user)] Your call to [T.phone_id] has reached voicemail, the line is busy."))
		busy_loop.start()
		return
	outbound_call = T
	outbound_call.inbound_call = src
	T.last_caller = src.phone_id
	T.callers_list += "[src.phone_id] - [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
	if(T.callers_list.len > 5)
		T.callers_list.Remove(T.callers_list[1])
	T.update_icon()
	timeout_timer_id = addtimer(CALLBACK(src, PROC_REF(reset_call), TRUE), timeout_duration, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)
	outring_loop.start()
	START_PROCESSING(SSobj, src)
	START_PROCESSING(SSobj, T)

/obj/structure/transmitter/proc/toggle_dnd(mob/living/carbon/human/user)
	switch(do_not_disturb)
		if(PHONE_DND_ON)
			do_not_disturb = PHONE_DND_OFF
			to_chat(user, span_notice("Do Not Disturb has been disabled. You can now receive calls."))
		if(PHONE_DND_OFF)
			do_not_disturb = PHONE_DND_ON
			to_chat(user, span_warning("Do Not Disturb has been enabled. No calls will be received."))
		else
			return FALSE
	return TRUE

// /obj/structure/transmitter/proc/set_tether_holder(atom/A)
// 	tether_holder = A
// 	if(attached_to)
// 		attached_to.reset_tether()

/obj/structure/transmitter/proc/reset_call(timeout = FALSE)
	var/obj/structure/transmitter/T = get_calling_phone()
	if(T)
		if(T.attached_to && ismob(T.attached_to.loc))
			var/mob/M = T.attached_to.loc
			to_chat(M, span_purple("[icon2html(src, M)] [phone_id] has hung up on you."))
			T.hangup_loop.start()
		if(attached_to && ismob(attached_to.loc))
			var/mob/M = attached_to.loc
			if(timeout)
				to_chat(M, span_purple("[icon2html(src, M)] Your call to [T.phone_id] has reached voicemail, nobody picked up the phone."))
				busy_loop.start()
				outring_loop.stop()
			else
				to_chat(M, span_purple("[icon2html(src, M)] You have hung up on [T.phone_id]."))
	if(outbound_call)
		outbound_call.inbound_call = null
		outbound_call = null
	if(inbound_call)
		inbound_call.outbound_call = null
		inbound_call = null
	if(timeout_timer_id)
		deltimer(timeout_timer_id)
		timeout_timer_id = null
	if(T)
		if(T.timeout_timer_id)
			deltimer(T.timeout_timer_id)
			T.timeout_timer_id = null
		T.update_icon()
		STOP_PROCESSING(SSobj, T)
	outring_loop.stop()
	if(!timeout) //we place the telephone back.
		attached_to?.reset_tether()
	STOP_PROCESSING(SSobj, src)

/obj/structure/transmitter/process()
	if(attached_to)
		if(attached_to.loc != src)
			if(!attached_to.tether || attached_to.tether.finished)
				attached_to.reset_tether()
		else
			attached_to.reset_tether()
	if(inbound_call)
		if(!attached_to)
			STOP_PROCESSING(SSobj, src)
			return
		if(attached_to.loc == src)
			if(next_ring < world.time)
				// balloon_alert_to_viewers("Inconming call: [last_caller]")
				say("Inconming call: [last_caller]")
				playsound(loc, 'modular_bluemoon/sound/machines/telephone/telephone_ring.ogg', 75, FALSE, distance_multiplier = 1)
				visible_message(span_warning("[src] rings vigorously!"))
				next_ring = world.time + 3 SECONDS
	else if(outbound_call)
		var/obj/structure/transmitter/T = get_calling_phone()
		if(!T)
			STOP_PROCESSING(SSobj, src)
			return
		var/obj/item/telephone/P = T.attached_to
		// I'm pretty sure code below is never executed. But it is an original CMSS13 code. So I leave it as it is.
		if(P && attached_to.loc == src && P.loc == T && next_ring < world.time)
			playsound(get_turf(attached_to), 'modular_bluemoon/sound/machines/telephone/telephone_ring.ogg', 20, FALSE, 14)
			visible_message(span_warning("[src] rings vigorously!"))
			next_ring = world.time + 3 SECONDS
	else
		STOP_PROCESSING(SSobj, src)
		return

/obj/structure/transmitter/proc/recall_phone()
	if(ismob(attached_to.loc))
		var/mob/M = attached_to.loc
		M.dropItemToGround(attached_to)
	playsound(loc, pick('modular_bluemoon/sound/machines/telephone/rtb_handset_1.ogg',
								'modular_bluemoon/sound/machines/telephone/rtb_handset_2.ogg',
								'modular_bluemoon/sound/machines/telephone/rtb_handset_3.ogg',
								'modular_bluemoon/sound/machines/telephone/rtb_handset_4.ogg',
								'modular_bluemoon/sound/machines/telephone/rtb_handset_5.ogg'), 100, FALSE, 7)
	attached_to.forceMove(src)
	reset_call()
	busy_loop.stop()
	hangup_loop.stop()
	outring_loop.stop()
	update_icon()

/obj/structure/transmitter/proc/get_calling_phone()
	if(outbound_call)
		return outbound_call
	else if(inbound_call)
		return inbound_call
	return

/obj/structure/transmitter/proc/handle_speak(mob/speaking, list/speech_args)
	var/obj/structure/transmitter/T = get_calling_phone()
	if(!istype(T))
		return
	var/message = speech_args[SPEECH_MESSAGE]
	var/datum/language/L = speech_args[SPEECH_LANGUAGE]
	if(L && initial(L.visual_language))
		return
	var/obj/item/telephone/P = T.attached_to
	if(!P || !attached_to)
		return
	P.handle_hear(speaking, speech_args)
	// attached_to.handle_hear(message, L, speaking)
	playsound(P, pick('modular_bluemoon/sound/machines/telephone/talk_phone1.ogg',
						'modular_bluemoon/sound/machines/telephone/talk_phone2.ogg',
						'modular_bluemoon/sound/machines/telephone/talk_phone3.ogg',
						'modular_bluemoon/sound/machines/telephone/talk_phone4.ogg',
						'modular_bluemoon/sound/machines/telephone/talk_phone5.ogg',
						'modular_bluemoon/sound/machines/telephone/talk_phone6.ogg',
						'modular_bluemoon/sound/machines/telephone/talk_phone7.ogg'), 10)
	if(attached_to.raised)
		log_say("TELEPHONE: [key_name(speaking)] on Phone '[phone_id]' to '[T.phone_id]' said '[message]'")


	/// TELEPHONE ///


/obj/item/telephone
	name = "telephone"
	icon = 'modular_bluemoon/icons/obj/structures/phone.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	icon_state = "rpb_phone"
	w_class = WEIGHT_CLASS_BULKY
	var/obj/structure/transmitter/attached_to
	var/datum/beam/tether = null
	// var/datum/effects/tethering/tether_effect
	var/raised = FALSE
	var/zlevel_transfer = FALSE
	var/zlevel_transfer_timer = TIMER_ID_NULL
	var/zlevel_transfer_timeout = 5 SECONDS

/obj/item/telephone/Initialize(mapload)
	. = ..()
	if(istype(loc, /obj/structure/transmitter))
		attach_to(loc)

/obj/item/telephone/Destroy()
	remove_attached()
	return ..()

/obj/item/telephone/examine(mob/user)
	. = ..()
	. += span_notice("Activate item to lower [src] to stop talking and listening to it.")

/obj/item/telephone/on_attack_hand(mob/user, act_intent, unarmed_attack_flags)
	if(attached_to && get_dist(user, attached_to) > attached_to.range)
		return FALSE
	return ..()

/obj/item/telephone/attack_self(mob/user)
	..()
	if(raised)
		set_raised(FALSE, user)
		to_chat(user, span_notice("You lower [src]."))
	else
		set_raised(TRUE, user)
		to_chat(user, span_notice("You raise [src] to your ear."))

/obj/item/telephone/Moved(atom/OldLoc, Dir)
	. = ..()
	if(attached_to)
		reset_tether()
		if(!do_zlevel_check())
			attached_to.recall_phone()
		if(attached_to && !ismob(OldLoc))
			if(get_dist(attached_to, src) > attached_to.range)
				if(ismob(loc))
					var/mob/M = loc
					M.dropItemToGround(src, TRUE)
				else
					attached_to.recall_phone()

/obj/item/telephone/on_enter_storage(obj/item/storage/S)
	. = ..()
	if(attached_to)
		attached_to.recall_phone()

/obj/item/telephone/equipped(mob/user, slot, initial)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_SAY, PROC_REF(handle_speak))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_mob_move))
	set_raised(TRUE, user)

/obj/item/telephone/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_SAY)
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	set_raised(FALSE, user)

/obj/item/telephone/proc/on_mob_move(atom/old_loc, dir)
	SIGNAL_HANDLER
	if(attached_to)
		if(!do_zlevel_check())
			attached_to.recall_phone()
		if(get_dist(attached_to, src) > attached_to.range)
			if(ismob(loc))
				var/mob/M = loc
				M.dropItemToGround(src, TRUE)
			else
				attached_to.recall_phone()

/obj/item/telephone/proc/handle_speak(mob/speaking, list/speech_args)
	SIGNAL_HANDLER
	if(!attached_to || loc == attached_to)
		UnregisterSignal(speaking, COMSIG_MOB_SAY)
		return
	attached_to.handle_speak(speaking, speech_args)

/obj/item/telephone/proc/handle_hear(mob/speaking, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	var/datum/language/L = speech_args[SPEECH_LANGUAGE]
	// var/m_spans = speech_args[SPEECH_SPANS]
	if(!attached_to)
		return
	var/obj/structure/transmitter/T = attached_to.get_calling_phone()
	if(!T)
		return
	if(!ismob(loc))
		return
	if(!raised || !T.attached_to?.raised) //listener or speaker lowered the phone and they can't hear each other
		to_chat(loc, span_red("You hear some muffled sounds from the phone."))
		return
	send_speech(message, 0, spans = list(SPAN_TAPE_RECORDER), message_language = L)
	// var/composed_message = compose_message(M, L, message, null, spans, source = src)
	// M.Hear(composed_message, vname, L, message, null, spans, source = src)
	// to_chat(M, "[span_purple("[vname] says: ")] [span_notice(message)]")

	// var/loudness = 0
	// if(raised)
	// 	loudness = 3
	// var/mob/M = loc
	// var/vname = T.phone_id
	// if(M == speaking)
	// 	vname = attached_to.phone_id
	// M.hear_radio(
	// 	message, "says", L, part_a = "<span class='purple'><span class='name'>",
	// 	part_b = "</span><span class='message'> ", vname = vname,
	// 	speaker = speaking, command = loudness, no_paygrade = TRUE)

/obj/item/telephone/proc/attach_to(obj/structure/transmitter/to_attach)
	if(!istype(to_attach))
		return
	remove_attached()
	attached_to = to_attach

/obj/item/telephone/proc/remove_attached()
	attached_to = null
	reset_tether()

/obj/item/telephone/proc/reset_tether()
	QDEL_NULL(tether)
	if(!attached_to || loc == attached_to)
		return
	if(ismob(loc))
		tether = loc.Beam(attached_to, icon_state="wire", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)
	else
		tether = Beam(attached_to, icon_state="wire", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)
// 	SIGNAL_HANDLER
// 	if (tether_effect)
// 		UnregisterSignal(tether_effect, COMSIG_PARENT_QDELETING)
// 		if(!QDESTROYING(tether_effect))
// 			qdel(tether_effect)
// 		tether_effect = null
// 	if(!do_zlevel_check())
// 		on_beam_removed()

// /obj/item/telephone/proc/on_beam_removed()
// 	if(!attached_to)
// 		return
// 	if(loc == attached_to)
// 		return
// 	if(get_dist(attached_to, src) > attached_to.range)
// 		attached_to.recall_phone()
// 	var/atom/tether_to = src
// 	if(loc != get_turf(src))
// 		tether_to = loc
// 		if(tether_to.loc != get_turf(tether_to))
// 			attached_to.recall_phone()
// 			return
// 	var/atom/tether_from = attached_to
// 	if(attached_to.tether_holder)
// 		tether_from = attached_to.tether_holder
// 	if(tether_from == tether_to)
// 		return
// 	var/list/tether_effects = apply_tether(tether_from, tether_to, range = attached_to.range, icon = "wire", always_face = FALSE)
// 	tether_effect = tether_effects["tetherer_tether"]
// 	RegisterSignal(tether_effect, COMSIG_PARENT_QDELETING, PROC_REF(reset_tether))

/obj/item/telephone/proc/set_raised(to_raise, mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(!to_raise)
		raised = FALSE
		item_state = "rpb_phone"
		// var/obj/item/device/radio/R = H.get_type_in_ears(/obj/item/device/radio)
		// R?.on = TRUE
	else
		raised = TRUE
		item_state = "rpb_phone_ear"
		// var/obj/item/device/radio/R = H.get_type_in_ears(/obj/item/device/radio)
		// R?.on = FALSE
	// H.update_inv_r_hand()
	// H.update_inv_l_hand()

/obj/item/telephone/proc/do_zlevel_check()
	. = TRUE
	if(!attached_to || !loc.z || !attached_to.z)
		return FALSE
	if(loc.z != attached_to.z)
		return FALSE
	// if(zlevel_transfer)
	// 	if(loc.z == attached_to.z)
	// 		zlevel_transfer = FALSE
	// 		if(zlevel_transfer_timer)
	// 			deltimer(zlevel_transfer_timer)
	// 		UnregisterSignal(attached_to, COMSIG_MOVABLE_MOVED)
	// 		return FALSE
	// 	return TRUE
	// if(attached_to && loc.z != attached_to.z)
	// 	// zlevel_transfer = TRUE
	// 	// zlevel_transfer_timer = addtimer(CALLBACK(src, PROC_REF(try_doing_tether)), zlevel_transfer_timeout, TIMER_UNIQUE|TIMER_STOPPABLE)
	// 	// RegisterSignal(attached_to, COMSIG_MOVABLE_MOVED, PROC_REF(transmitter_move_handler))
	// 	return TRUE
	// return FALSE

// /obj/item/telephone/proc/transmitter_move_handler(datum/source)
// 	SIGNAL_HANDLER
// 	zlevel_transfer = FALSE
// 	if(zlevel_transfer_timer)
// 		deltimer(zlevel_transfer_timer)
// 	UnregisterSignal(attached_to, COMSIG_MOVABLE_MOVED)
	// reset_tether()

// /obj/item/telephone/proc/try_doing_tether()
// 	zlevel_transfer_timer = TIMER_ID_NULL
// 	zlevel_transfer = FALSE
// 	UnregisterSignal(attached_to, COMSIG_MOVABLE_MOVED)
// 	reset_tether()


	/// TELEPHONE TYPES ///


/// always available.
/obj/structure/transmitter/no_dnd
	do_not_disturb = PHONE_DND_FORBIDDEN

/// you don't see it in the phone lists and can't call here.
/obj/structure/transmitter/hidden
	do_not_disturb = PHONE_DND_FORCED

// mounted in a wall machine
/obj/structure/transmitter/mounted
	name = "telephone receiver"
	desc = "It is a wall mounted telephone. The fine text reads: To log your details with the mainframe please insert your keycard into the slot below. Unfortunately the slot is jammed. You can still use the phone, however."
	icon_state = "wall_phone"

/obj/structure/transmitter/mounted/no_dnd
	do_not_disturb = PHONE_DND_FORBIDDEN

/obj/structure/transmitter/mounted/hidden
	do_not_disturb = PHONE_DND_FORCED

	/// FACTIONS AND SPECIAL LINES///

//Personal command line for private offices.
/obj/structure/transmitter/command
	phone_category = PHONE_NET_COMMAND
	networks_receive = list(PHONE_NET_COMMAND)
	networks_transmit = list(PHONE_NET_PUBLIC, PHONE_NET_COMMAND)

///Special line for DS-1 and DS-2
/obj/structure/transmitter/syndicate
	phone_category = PHONE_NET_SYNDICATE
	networks_receive = list(PHONE_NET_SYNDICATE)
	networks_transmit = list(PHONE_NET_PUBLIC, PHONE_NET_COMMAND, PHONE_NET_SYNDICATE)

/obj/structure/transmitter/mounted/syndicate
	phone_category = PHONE_NET_SYNDICATE
	networks_receive = list(PHONE_NET_SYNDICATE)
	networks_transmit = list(PHONE_NET_PUBLIC, PHONE_NET_COMMAND, PHONE_NET_SYNDICATE)

/obj/structure/transmitter/inteq
	phone_category = PHONE_NET_INTEQ
	networks_receive = list(PHONE_NET_INTEQ)
	networks_transmit = list(PHONE_NET_INTEQ)

///admins can call anywhere anytime.
/obj/structure/transmitter/centcom
	phone_category = PHONE_NET_CENTCOMM
	networks_receive = list(PHONE_NET_CENTCOMM)
	networks_transmit = list(PHONE_NET_PUBLIC, PHONE_NET_COMMAND, PHONE_NET_SYNDICATE, PHONE_NET_INTEQ, PHONE_NET_CENTCOMM)
	can_rename = TRUE

/obj/structure/transmitter/centcom/AltClick(mob/user)
	var/input_name = stripped_input(user, "Rename this phone?", "Rename this phone", name, MAX_NAME_LEN)
	if(input_name)
		name = input_name
		phone_id = input_name

	/// ETC ///

/datum/looping_sound/telephone/ring
	start_sound = 'modular_bluemoon/sound/machines/telephone/dial.ogg'
	start_length = 3.2 SECONDS
	mid_sounds = 'modular_bluemoon/sound/machines/telephone/ring_outgoing.ogg'
	mid_length = 2.1 SECONDS
	volume = 20

/datum/looping_sound/telephone/busy
	start_sound = 'modular_bluemoon/sound/machines/telephone/callstation_unavailable.ogg'
	start_length = 5.7 SECONDS
	mid_sounds = 'modular_bluemoon/sound/machines/telephone/phone_busy.ogg'
	mid_length = 5 SECONDS
	volume = 50

/datum/looping_sound/telephone/hangup
	start_sound = 'modular_bluemoon/sound/machines/telephone/remote_hangup.ogg'
	start_length = 0.6 SECONDS
	mid_sounds = 'modular_bluemoon/sound/machines/telephone/phone_busy.ogg'
	mid_length = 5 SECONDS
	volume = 50

#undef TRANSMITTER_UNAVAILABLE

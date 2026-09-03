/datum/round_event_control/pizza_time
	name = "Pizza Time"
	typepath = /datum/round_event/pizza_time
	weight = 5
	max_occurrences = 1
	category = EVENT_CATEGORY_HOLIDAY
	description = "Доставка пиццы подом абсолютно всем сотрудникам с включёнными координатными датчиками."

/datum/round_event/pizza_time/announce(fake)
	priority_announce("Ваше начальство довольно вами и выделяет для вас подарочный обед за свой счёт через... Пять секунд! Для получения координатные датчики униформы должны быть включены. Слава ПАКТу!", "Центральное Командование")
	sound_to_playing_players('sound/misc/pizza_time.ogg', volume = 25)

/datum/round_event/pizza_time/start()
	var/pizzatype_list = subtypesof(/obj/item/pizzabox)
	pizzatype_list -= /obj/item/pizzabox/margherita/robo // No murder pizza
	pizzatype_list -= /obj/item/pizzabox/bomb // No robo pizza
	addtimer(CALLBACK(src, PROC_REF(deliver_pizzas), pizzatype_list), 5 SECONDS)

/datum/round_event/pizza_time/proc/deliver_pizzas(list/pizzatype_list)
	for(var/mob/living/carbon/human/person in GLOB.human_list)
		if(!person.mind || !(ckey(person.mind.key) in GLOB.joined_player_list)) // Нужно для отделения трупа НПС от игрока + поиск станционного экипажа вместо всех мобов мира
			continue
		var/turf/target_turf = get_turf(person)
		if(!target_turf || !is_station_level(target_turf.z))
			continue // НЕТ ТУРФА - НЕТ ПИЦЦЫ, НЕТ РАНТАЙМА
		var/obj/item/clothing/under/uniforms = person.w_uniform
		if(!uniforms || uniforms.sensor_mode != SENSOR_COORDS)
			to_chat(person, span_red("Мои датчики! Я остался без пиццы..."))
			continue // Униформа будет сортировать скрытных космонавтиков и трупы в морге
		// Yes, this delivers to dead bodies. It's REALLY FUNNY.
		var/obj/structure/closet/supplypod/centcompod/pod = new()
		var/pizzatype = pick(pizzatype_list)
		new pizzatype(pod)
		pod.explosionSize = list(0,0,0,0)
		to_chat(person, span_nicegreen("Время пиццы! Вот бы только чем запить..."))
		new /obj/effect/pod_landingzone(target_turf, pod)

/datum/round_event_control/pizza_time_admin
	name = "Present Time"
	typepath = /datum/round_event/pizza_time/admin
	admin_only = TRUE
	max_occurrences = 0
	category = EVENT_CATEGORY_FRIENDLY
	description = "Доставка одного выбранного предмета всем людям подом."
	admin_setup = list(/datum/event_admin_setup/pizza_time_delivery_path)

/datum/round_event/pizza_time/admin
	var/delivery_type = /obj/item/pizzabox/margherita

/datum/round_event/pizza_time/admin/announce(fake)
	priority_announce("Ваше начальство довольно вами и выделяет для вас подарок за свой счёт. Слава ПАКТу!", "Центральное Командование")
	sound_to_playing_players('modular_bluemoon/sound/effects/podarok.ogg', volume = 100)

/datum/round_event/pizza_time/admin/start()
	if(!ispath(delivery_type, /atom/movable))
		message_admins("Present Time: неверный тип доставки, событие прервано.")
		return
	for(var/mob/living/carbon/human/person in GLOB.human_list)
		if(!person.mind || !((ckey(person.mind.key)) in GLOB.joined_player_list))
			continue
		var/turf/target_turf = get_turf(person)
		if(!target_turf || !is_station_level(target_turf.z))
			continue
		var/obj/structure/closet/supplypod/centcompod/pod = new()
		new delivery_type(pod)
		pod.explosionSize = list(0,0,0,0)
		to_chat(person, span_nicegreen("К вам падает посылка!"))
		new /obj/effect/pod_landingzone(target_turf, pod)

/datum/event_admin_setup/pizza_time_delivery_path
	var/resolved

/datum/event_admin_setup/pizza_time_delivery_path/prompt_admins()
	var/raw = tgui_input_text(usr, "Path предмета (/obj/... или /mob/...), создаётся внутри пода.", "Present Time", "/obj/item/pizzabox/margherita")
	if(!raw)
		return ADMIN_CANCEL_EVENT
	var/path = text2path(trim(raw))
	if(!ispath(path, /atom/movable))
		tgui_alert(usr, "Нужен валидный path к /atom/movable.", "Ошибка", list("OK"))
		return ADMIN_CANCEL_EVENT
	resolved = path

/datum/event_admin_setup/pizza_time_delivery_path/apply_to_event(datum/round_event/pizza_time/admin/event)
	if(resolved)
		event.delivery_type = resolved

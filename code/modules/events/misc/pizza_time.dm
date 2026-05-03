/datum/round_event_control/pizza_time
	name = "Pizza Time"
	typepath = /datum/round_event/pizza_time
	weight = 5
	max_occurrences = 1
	category = EVENT_CATEGORY_HOLIDAY
	description = "Мгновенная доставка пицца подом абсолютно всем сотрудникам."

/datum/round_event/pizza_time/announce(fake)
	priority_announce("Ваше начальство довольно вами и выделяет для вас подарочный обед за свой счёт. Слава ПАКТу!", "Центральное Командование")
	sound_to_playing_players('sound/misc/pizza_time.ogg', volume = 25)

/datum/round_event/pizza_time/start()
	var/pizzatype_list = subtypesof(/obj/item/pizzabox)
	pizzatype_list -= /obj/item/pizzabox/margherita/robo // No murder pizza
	pizzatype_list -= /obj/item/pizzabox/bomb // No robo pizza
	for(var/mob/living/carbon/human/person in GLOB.human_list)
		// Yes, this delivers to dead bodies. It's REALLY FUNNY.
		var/obj/structure/closet/supplypod/centcompod/pod = new()
		var/pizzatype = pick(pizzatype_list)
		new pizzatype(pod)
		pod.explosionSize = list(0,0,0,0)
		to_chat(person, span_nicegreen("Время пиццы! Вот бы только чем запить..."))
		new /obj/effect/pod_landingzone(get_turf(person), pod)

/datum/round_event_control/pizza_time_admin
	name = "Present Time"
	typepath = /datum/round_event/pizza_time/admin
	weight = 0
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
		var/obj/structure/closet/supplypod/centcompod/pod = new()
		new delivery_type(pod)
		pod.explosionSize = list(0,0,0,0)
		to_chat(person, span_nicegreen("К вам падает посылка!"))
		new /obj/effect/pod_landingzone(get_turf(person), pod)

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

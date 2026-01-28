/datum/round_event_control/pizza_time
	name = "Pizza Time"
	typepath = /datum/round_event/pizza_time
	weight = 0
	max_occurrences = 0
	category = EVENT_CATEGORY_HOLIDAY
	description = "Мгновенная доставка пицца подом абсолютно всем сотрудникам."

/datum/round_event/pizza_time/announce(fake)
	priority_announce("Ваше начальство довольно вами и выделяет для вас подарочный обед за свой счёт. Слава ПАКТу!", "Центральное Командование")
	sound_to_playing_players('sound/misc/pizza_time.ogg', volume = 50)

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

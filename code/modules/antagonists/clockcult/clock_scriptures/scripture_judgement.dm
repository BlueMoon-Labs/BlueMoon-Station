///////////////
// JUDGEMENT // For the big game changing things. TODO: Summonable generals, just need mob sprites for them.
///////////////

//Ark of the Clockwork Justiciar: Creates a Gateway to the Celestial Derelict, summoning ratvar.
/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar
	descname = "Победа"
	name = "Ark of the Clockwork Justiciar"
	desc = "Раскрывает разлом в пространстве-времени, ведущий к Небесному Заброшенному, Рибу, затрачивая на это огромное количество энергии.\n\
    Через некоторое время этот проход вызовет Ратвара из его изгнания и значительно усилит все священные писания и инструменты."
	invocations = list("ОРУЖЕЙНИК! УЖАС! НАПРЯЖЕНИЕ! АВАНГАРД! МЫ ВЗЫВАЕМ К ВАМ!!", \
	"ПРИШЛО ВРЕМЯ НАШЕМУ ВЛАДЫКЕ РАЗОРВАТЬ ЦЕПИ ИЗГНАНИЯ!!", \
	"ОДАРИТЕ НАС СВОЕЙ ПОМОЩЬЮ! ДВИГАТЕЛЬ ГРЯДЁТ!!")
	channel_time = 150
	power_cost = 70000 //70 KW. It's literally the thing wrenching the god out of another dimension why wouldn't it be costly.
	invokers_required = 6
	multiple_invokers_used = TRUE
	object_path = /obj/structure/destructible/clockwork/massive/celestial_gateway
	creator_message = "<span class='heavy_brass'>Ковчег возникает перед вами благодаря помощи Генералов. Спустя столько времени он, наконец, обретет свободу</span>"
	usage_tip = "В течение пяти минут существования портал полностью уязвим для атак. Он будет периодически передавать информацию о своём примерном местоположении всем, кто находится на станции, \
    а также издавать звук, достаточно громкий, чтобы его было слышно по всему сектору. Защищайте его ценой своей жизни!"
	tier = SCRIPTURE_APPLICATION
	category = SCRIPTURE_CATEGORY_STRUCTURE
	sort_priority = 1
	requires_full_power = TRUE

/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/check_special_requirements()
	if(!slab.no_cost)
		if(GLOB.ratvar_awakens)
			to_chat(invoker, "<span class='big_brass'>\"Я уже здесь, в этом нет смысла.\"</span>")
			return FALSE
		for(var/obj/structure/destructible/clockwork/massive/celestial_gateway/G in GLOB.all_clockwork_objects)
			var/area/gate_area = get_area(G)
			to_chat(invoker, "<span class='userdanger'>В [gate_area.map_name] уже есть Ковчег!</span>")
			return FALSE
		var/area/A = get_area(invoker)
		var/turf/T = get_turf(invoker)
		if(!is_station_level(T.z) || isspaceturf(T) || !(A?.area_flags & CULT_PERMITTED) || isshuttleturf(T))
			to_chat(invoker, "<span class='warning'>Чтобы активировать Ковчег, вы должны находиться на станции!</span>")
			return FALSE
		if(GLOB.clockwork_gateway_activated)
			to_chat(invoker, "<span class='warning'>Недавнее изгнание Ратвара сделало его слишком слабым, чтобы его можно было вырвать из Риба!</span>")
			return FALSE
	return ..()


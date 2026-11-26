#define TIDE_LESSON_BREACH 1
#define TIDE_LESSON_MARK 2
#define TIDE_LESSON_DROWN 3
#define TIDE_LESSON_CURRENT 4
#define TIDE_LESSON_DIVE 5
#define TIDE_LESSON_SINK_DISTANCE 5

/datum/eldritch_knowledge/base_tide/on_gain(mob/user)
	. = ..()
	heretic_path_lesson_notice(user, "tide")

/// Урок Пучины: прорыв у раковины, Метка Пучины, Захлёб в своей воде, Течение и уход в слив к другому прорыву.
/datum/heretic_path_lesson/tide
	path_id = PATH_TIDE
	base_type = /datum/eldritch_knowledge/base_tide
	title = "Урок Пучины"
	icon = "water"
	knowledge_types = list(/datum/eldritch_knowledge/tide_grasp, /datum/eldritch_knowledge/spell/tide_drown, /datum/eldritch_knowledge/tide_mark, /datum/eldritch_knowledge/spell/tide_current)
	step_names = list("Прорыв", "Метка Пучины", "Захлёб", "Течение", "Уйти в слив")

/datum/heretic_path_lesson/tide/setup(datum/antagonist/heretic/heretic, datum/eldritch_knowledge/base_tide/tide, mob/living/student, mob/living/target)
	student.put_in_hands(add_prop(new /obj/item/melee/sickly_blade/tide(get_turf(student))))
	refill(tide)

/datum/heretic_path_lesson/tide/proc/refill(datum/eldritch_knowledge/base_tide/tide)
	tide.combat_resource = tide.combat_resource_max
	tide.notify_resource_changed()

/datum/heretic_path_lesson/tide/stage_text(for_stage)
	switch(for_stage)
		if(TIDE_LESSON_BREACH)
			return "Рядом стоит раковина. Коснитесь её Хваткой Мансуса: откроется прорыв, и вокруг на [HERETIC_TIDE_BREACH_RADIUS] клетки натечёт ваша чёрная вода. Так же годятся душ, туалет, кулер, бак и лоток гидропоники."
		if(TIDE_LESSON_MARK)
			return "Коснитесь мишени Хваткой: она промокнет, вы получите давление, на ней встанет Метка Пучины. Ударьте её гарпуном - метка взорвётся, и под мишенью на [HERETIC_TIDE_MARK_WATER_TIME / (1 SECONDS)] секунд разольётся ваша вода."
		if(TIDE_LESSON_DROWN)
			return "Пока мишень стоит в вашей воде, примените к ней «Захлебнуться»: через [HERETIC_TIDE_DROWN_TELEGRAPH / (1 SECONDS)] секунду вода сомкнётся, и в своей воде цель уйдёт на дно. Лужа метки высохла - снова Хватка и гарпун."
		if(TIDE_LESSON_CURRENT)
			return "Примените «Течение» к клетке не дальше восьми шагов: полоса вашей воды на [HERETIC_TIDE_CURRENT_LIFETIME / (1 SECONDS)] секунд сносит лежащих, ускоряет вас, а уход в слив с ней дешевле и чаще."
		if(TIDE_LESSON_DIVE)
			return "Вдали стоит вторая раковина. Откройте у неё прорыв Хваткой, вернитесь к первой и нажмите «Уйти в слив»: через полторы секунды вы выйдете у второго прорыва. На другой этаж станции - [HERETIC_TIDE_DIVE_FLOOR_TIME / (1 SECONDS)] секунды и на [HERETIC_TIDE_DIVE_FLOOR_COST] давление дороже."
	return "Урок пройден. Против Пучины: гаечный ключ, сварка, швабра или нулевой жезл по источнику закрывают прорыв; Захлёб срывают полторы секунды на сухом полу - оттащите тонущего, - святая вода, жезл, растолкать его; без второго прорыва уйти в слив некуда."

/datum/heretic_path_lesson/tide/prepare_stage(for_stage)
	var/mob/living/student = student_ref?.resolve()
	var/datum/eldritch_knowledge/base_tide/tide = base_ref?.resolve()
	if(!student || !tide || stage != for_stage)
		return
	switch(for_stage)
		if(TIDE_LESSON_BREACH)
			var/turf/spot = free_spot_near(student)
			if(!spot)
				say("для раковины нет места: отойдите на свободный пол и начните урок заново.")
				return
			add_prop(new /obj/structure/sink(spot))
		if(TIDE_LESSON_DROWN, TIDE_LESSON_CURRENT)
			refill(tide)
		if(TIDE_LESSON_DIVE)
			refill(tide)
			var/turf/far = spot_in_line(student, TIDE_LESSON_SINK_DISTANCE) || spot_in_line(student, TIDE_LESSON_SINK_DISTANCE - 2)
			if(!far)
				say("для второй раковины нет места: отойдите на свободный пол и начните урок заново.")
				return
			add_prop(new /obj/structure/sink(far))

/datum/heretic_path_lesson/tide/handle_event(event, atom/subject, value)
	var/mob/living/target = target_ref?.resolve()
	switch(stage)
		if(TIDE_LESSON_BREACH)
			if(event == "breach")
				advance("прорыв открыт на [HERETIC_TIDE_BREACH_LIFETIME / (1 MINUTES)] минут, Хватка по нему продлит срок. В чёрной воде враги вязнут, а вы быстрее.")
		if(TIDE_LESSON_MARK)
			if(event == "mark" && subject == target)
				advance("метка взорвалась: под мишенью ваша вода.")
		if(TIDE_LESSON_DROWN)
			if(event == "drown" && subject == target)
				if(value)
					advance("мишень на дне своей воды: [HERETIC_TIDE_DROWN_DURATION / (1 SECONDS)] секунд она немеет и еле ползёт, затем уснёт. На станции сердце уводит такую цель в изнанку с первой секунды.")
				else
					say("это простая лужа: цель захлёбывается, но на дно тянет только ваша вода - прорыв, метка, Течение.")
		if(TIDE_LESSON_CURRENT)
			if(event == "current")
				advance("течение легло. Утопающего на полосе вода уносит к её концу.")
		if(TIDE_LESSON_DIVE)
			if(event == "breach")
				say("второй прорыв открыт. Теперь к первой раковине и «Уйти в слив».")
			else if(event == "dive")
				advance("вы вынырнули у другого прорыва. Из изнанки тоже выходят к своему прорыву.")

#undef TIDE_LESSON_BREACH
#undef TIDE_LESSON_MARK
#undef TIDE_LESSON_DROWN
#undef TIDE_LESSON_CURRENT
#undef TIDE_LESSON_DIVE
#undef TIDE_LESSON_SINK_DISTANCE

/turf/open/floor
	var/heretic_rustable = FALSE

/turf/open/floor/plating
	heretic_rustable = TRUE

/turf/open/floor/plasteel
	heretic_rustable = TRUE

/turf/open/floor/wood
	heretic_rustable = TRUE

/turf/open/floor/mineral/titanium
	heretic_rustable = TRUE

/turf/open/floor/mineral/plastitanium
	heretic_rustable = TRUE

/turf/open/floor/engine
	heretic_rustable = TRUE

/turf/open/floor/engine/hull
	heretic_rustable = FALSE

/turf/open/floor/engine/cult
	heretic_rustable = FALSE

/turf/open/floor/plasteel/elevated
	heretic_rustable = FALSE

/turf/open/floor/plasteel/lowered
	heretic_rustable = FALSE

/turf/open/floor/rust_heretic_act()
	if(!heretic_rustable)
		return
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	var/turf/after = ChangeTurf(/turf/open/floor/plating/rust, flags = CHANGETURF_INHERIT_AIR)
	after?.AddElement(/datum/element/heretic_rust)
	return after

#define HERETIC_RUST_HEALING_ALERT "heretic_rust_healing"

/datum/heretic_innate/rust/bind(mob/living/user)
	. = ..()
	update_healing_alert()

/datum/heretic_innate/rust/unbind()
	body?.clear_alert(HERETIC_RUST_HEALING_ALERT)
	return ..()

/datum/heretic_innate/rust/on_move(mob/living/source, atom/old_loc, direction, forced)
	. = ..()
	update_healing_alert()

/datum/heretic_innate/rust/on_death()
	. = ..()
	body?.clear_alert(HERETIC_RUST_HEALING_ALERT)

/datum/heretic_innate/rust/proc/update_healing_alert()
	if(!valid())
		body?.clear_alert(HERETIC_RUST_HEALING_ALERT)
		return
	var/on_rust = istype(body.loc, /turf/open/floor/plating/rust)
	var/in_grove = FALSE
	var/datum/eldritch_knowledge/knowledge = knowledge_ref.resolve()
	if(on_rust)
		for(var/obj/effect/heretic_combat_zone/rust/zone in list(knowledge.combat_zone, knowledge.relic_zone))
			if(!QDELETED(zone) && (body.loc in zone.field_turfs))
				in_grove = TRUE
				break
	var/atom/movable/screen/alert/heretic_rust_healing/indicator = body.throw_alert(HERETIC_RUST_HEALING_ALERT, /atom/movable/screen/alert/heretic_rust_healing, no_anim = TRUE)
	indicator.update_healing(on_rust, in_grove)

/atom/movable/screen/alert/heretic_rust_healing
	name = "Лечение Ржавчины"
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "sigil_rust"
	maptext_width = 32
	maptext_height = 12
	maptext_y = 1
	var/healing_state

/atom/movable/screen/alert/heretic_rust_healing/proc/update_healing(on_rust, in_grove)
	var/new_state = in_grove ? "grove" : (on_rust ? "floor" : "inactive")
	if(healing_state == new_state)
		return
	healing_state = new_state
	var/label
	switch(healing_state)
		if("grove")
			name = "Ржавчина: пол и очаг лечат"
			desc = "Вы стоите на ржавом полу внутри своего очага. Работают врождённое лечение и дополнительное лечение очага. Ржавая поступь добавляет лечение, если изучена."
			label = "ОЧАГ"
			color = "#b5ffc5"
		if("floor")
			name = "Ржавчина: пол лечит"
			desc = "Работает врождённое лечение. Ржавая поступь добавляет лечение, если изучена. Дополнительное лечение очага здесь не действует: вернитесь в его отмеченную область или создайте новый."
			label = "ПОЛ"
			color = "#e7ad64"
		else
			name = "Ржавчина: лечение не действует"
			desc = "Под ногами нет ржавого пола. Заржавьте подходящий пол Хваткой или разрастанием. Очаг тоже лечит только на ржавом полу; одного нахождения рядом с ним недостаточно."
			label = "НЕТ"
			color = "#ff9e88"
	desc += " Лечение постепенно восстанавливает здоровье, но само по себе не устраняет переломы, вывихи и другие раны."
	maptext = MAPTEXT("<div style='text-align:center;color:#ffffff;font-size:8px;background-color:#17111d'>[label]</div>")

#undef HERETIC_RUST_HEALING_ALERT

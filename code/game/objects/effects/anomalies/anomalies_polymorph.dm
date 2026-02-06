/obj/effect/anomaly/poly
	name = "polymorph anomaly"
	icon = 'icons/effects/effects.dmi'
	icon_state = "hallucination"
	aSignal = /obj/item/assembly/signaler/anomaly/poly
	drops_core = FALSE
	var/const/work_range = 3
	var/const/detonate_range = 16

/obj/effect/anomaly/poly/anomalyEffect(seconds_per_tick)
	. = ..()
	for(var/mob/living/carbon/human/H in view(work_range, src))
		randomize_appearance(H)
	spawn_mass_effects(work_range, 15)

/obj/effect/anomaly/poly/detonate()
	. = ..()
	for(var/mob/living/carbon/human/H in range(detonate_range, src))
		randomize_appearance(H)
	spawn_mass_effects(detonate_range, 80, TRUE)

	playsound(get_turf(src), 'sound/effects/magic.ogg', 100, TRUE)
	priority_announce("Обнаружен вспеск полиморф частиц.", "ВНИМАНИЕ: АНОМАЛИЯ")

/obj/effect/anomaly/poly/anomalyNeutralize()
	var/obj/item/slimecross/stabilized/fetish/green/I = new(get_turf(src))
	I.name = "Странный череп"
	I.add_atom_colour(color_matrix_hsv(280, 1, 1), FIXED_COLOUR_PRIORITY)
	I.update_icon()
	return ..()

/obj/effect/anomaly/poly/proc/randomize_appearance(mob/living/carbon/human/H)
	new /obj/effect/temp_visual/revenant(H.loc)
	randomize_human(H, soft = TRUE)

// Генерим ожидаемое кол-во спавнов и раскидываем случайно.
// chance=10 означает примерно 10% площади квадрата orange.
/obj/effect/anomaly/poly/proc/spawn_mass_effects(range, chance = 10, long = FALSE)
	if(QDELETED(src) || range <= 0 || chance <= 0)
		return

	var/turf/origin = get_turf(src)
	if(!origin)
		return

	// orange = квадрат (2r+1)^2 - 1
	var/area = (2*range + 1)
	area = area*area - 1

	// ожидаемое количество
	var/target = round(area * (chance / 100))

	if(target <= 0)
		return

	var/list/used = list() // set: turf => TRUE
	var/tries = target * 6 // чтобы выбить нужное кол-во уникальных точек
	var/effect = long ? /obj/effect/temp_visual/revenant/fivesecond : /obj/effect/temp_visual/revenant

	while(target > 0 && tries-- > 0)
		var/dx = rand(-range, range)
		var/dy = rand(-range, range)
		if(!dx && !dy)
			continue

		var/turf/T = locate(origin.x + dx, origin.y + dy, origin.z)
		if(!T || used[T])
			continue

		used[T] = TRUE
		new effect(T)
		target--

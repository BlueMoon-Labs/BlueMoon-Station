/// Луч, который запоминает свой путь перед тем, как нарисовать следы.
/obj/item/projectile/beam/emitter/hitscan/substep_probe
	var/list/recorded

/obj/item/projectile/beam/emitter/hitscan/substep_probe/generate_hitscan_tracers(cleanup = TRUE, duration = 3, impacting = TRUE, generation)
	LAZYINITLIST(recorded)
	for(var/datum/point/start as anything in beam_segments)
		var/datum/point/finish = beam_segments[start]
		recorded += "отрезок [num2text(start.x, 12)],[num2text(start.y, 12)] -> [num2text(finish?.x, 12)],[num2text(finish?.y, 12)]"
	recorded += "дальность [range], остаток [pixels_range_leftover], подшагов [trajectory?.iteration], конец [num2text(trajectory?.x, 12)],[num2text(trajectory?.y, 12)]"
	for(var/atom/hit as anything in impacted)
		recorded += "попал в [hit.type] [hit.x],[hit.y]"
	return ..()

/datum/unit_test/hitscan_substep_skip/proc/shoot_probe(turf/start, angle, offset, skip, mob/living/carbon/human/target)
	target.fully_heal()
	var/obj/item/projectile/beam/emitter/hitscan/substep_probe/shot = new(start)
	shot.hitscan_substep_skip = skip
	shot.pixel_x = offset
	shot.pixel_y = -offset
	shot.fire(angle)
	var/list/result = shot.recorded || list("пусто")
	result += "ожоги цели [target.getFireLoss()], луч удалён [QDELETED(shot)]"
	shot.recorded = null
	return result

/// Пропуск подшагов внутри тайла не меняет выстрел: тот же путь до пикселя, отражения, попадания, урон и остаток дальности.
/datum/unit_test/hitscan_substep_skip/Run()
	var/datum/turf_reservation/room = beam_test_area(21, 21)
	var/turf/start = beam_area_turf(room, 10, 10)
	var/obj/structure/reflector/box/anchored/reflector = new(beam_area_turf(room, 15, 10))
	allocated += reflector
	reflector.setAngle(0)
	var/obj/structure/reflector/box/anchored/second_reflector = new(beam_area_turf(room, 6, 6))
	allocated += second_reflector
	second_reflector.setAngle(90)
	var/mob/living/carbon/human/target = new(beam_area_turf(room, 10, 16))
	allocated += target
	var/obj/structure/closet/crate = new(beam_area_turf(room, 4, 13))
	allocated += crate

	var/list/angles = list(33.3, 123.45, 271.01, 359.9)
	for(var/angle = 0; angle < 360; angle += 7.5)
		angles += angle
	var/hits_on_target = 0
	var/turned = 0
	for(var/angle in angles)
		for(var/offset in list(0, 7, -2.5))
			if(TICK_USAGE > 30)
				stoplag(1)
			crate.obj_integrity = crate.max_integrity
			var/list/reference = shoot_probe(start, angle, offset, FALSE, target)
			crate.obj_integrity = crate.max_integrity
			var/list/skipped = shoot_probe(start, angle, offset, TRUE, target)
			TEST_ASSERT_EQUAL(skipped.Join(" | "), reference.Join(" | "), "выстрел под углом [angle] со смещением [offset]")
			if(findtext(reference.Join(), "попал в [target.type]"))
				hits_on_target++
			var/segments = 0
			for(var/line in reference)
				if(findtext(line, "отрезок"))
					segments++
			if(segments > 1)
				turned++
	TEST_ASSERT(hits_on_target >= 2, "в цель попало [hits_on_target] выстрелов, сверка без попаданий ничего не доказывает")
	TEST_ASSERT(turned >= 2, "отражатели повернули [turned] выстрелов, сверка без отражений ничего не доказывает")

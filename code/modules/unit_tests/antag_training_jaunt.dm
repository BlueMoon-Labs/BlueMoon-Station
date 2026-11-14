/// Тень Кошмара с чужим участником не заходит на ринг идущей дуэли, а удалённая тень выпускает тело, а не удаляет его.
/datum/unit_test/antag_training_jaunt_duel/Run()
	var/list/sessions = training_squad_sessions(3)
	TEST_ASSERT(length(sessions) == 3, "Три участника на полигоне.")
	var/datum/antag_training_session/first = sessions[1]
	var/datum/antag_training_session/second = sessions[2]
	var/datum/antag_training_session/walker = sessions[3]
	var/datum/antag_training_arena/arena = first.arena
	TEST_ASSERT(first.request_duel(second), "Создано приглашение.")
	TEST_ASSERT(arena.duel.accept(second), "Соперник принимает вызов.")
	var/list/bounds = arena.zones["melee"]["bounds"]
	var/turf/edge = locate(bounds[1] - 1, round((bounds[3] + bounds[4]) / 2), arena.private_level.z_value)
	var/mob/living/carbon/human/body = walker.current_body
	body.forceMove(edge)
	TEST_ASSERT_EQUAL(get_turf(body), edge, "Участник стоит у края ринга.")
	var/obj/effect/dummy/phased_mob/shadow/shade = new(edge)
	body.forceMove(shade)
	shade.jaunter = body
	TEST_ASSERT_EQUAL(body.loc, shade, "Участник ушёл в тень.")
	shade.relaymove(body, EAST)
	TEST_ASSERT(!QDELETED(body), "Тень у ринга не удаляет тело участника.")
	TEST_ASSERT(!arena.inside_bounds(get_turf(body), bounds), "Тень с чужим участником не заходит на ринг идущей дуэли.")
	if(!QDELETED(shade))
		qdel(shade)

	var/obj/effect/dummy/phased_mob/shadow/second_shade = new(get_turf(body))
	body.forceMove(second_shade)
	second_shade.jaunter = body
	TEST_ASSERT_EQUAL(body.loc, second_shade, "Участник снова в тени.")
	qdel(second_shade)
	TEST_ASSERT(!QDELETED(body) && isturf(body.loc), "Удалённая тень выпускает тело, а не удаляет его.")

// ===== AI-контроллер слаймов =====
//
// Проверяют перевод погони/кормёжки с блокирующего while+sleep цикла AIprocess()
// на событийный /datum/ai_controller/slime: мозг приобретения цели, терпения,
// дисциплины и блуждания остаётся в handle_targets() (Life-цикл), контроллер
// только догоняет и повторяет решающее дерево кормёжки старого цикла.

///Голодный слайм берёт добычу мозгом Life, а контроллер ставит её целью движения
/datum/unit_test/slime_ai_hunts_prey/Run()
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, prey_turf)
	hunter.set_nutrition(hunter.get_starve_nutrition() - 1) //голодает: ест всё без бросков prob()

	hunter.handle_targets()

	TEST_ASSERT_EQUAL(hunter.Target, prey, "A starving slime's handle_targets must acquire the monkey")
	TEST_ASSERT_NOTNULL(hunter.ai_controller, "A slime must spawn with an ai_controller")
	TEST_ASSERT_EQUAL(hunter.ai_controller.blackboard[BB_SLIME_TARGET], prey, "The Life nudge must mirror the target into the controller blackboard")

	drive_ai_planning(hunter.ai_controller)

	TEST_ASSERT_EQUAL(hunter.ai_controller.current_movement_target, prey, "The pursuit plan must set the prey as the movement target")

///Слайм вплотную к добыче кормится через легаси-решающее дерево (Feedon)
/datum/unit_test/slime_ai_feeds_when_adjacent/Run()
	var/mob/living/simple_animal/slime/feeder = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, get_step(run_loc_floor_bottom_left, EAST))
	feeder.set_nutrition(feeder.get_starve_nutrition() - 1)
	feeder.Target = prey

	drive_ai_planning(feeder.ai_controller)
	feeder.ai_controller.process(0.5)

	TEST_ASSERT_EQUAL(feeder.buckled, prey, "An adjacent hungry slime must latch onto its target (Feedon)")

///Дисциплина чистит цель в мозге Life (легаси-семантика сохранена)
/datum/unit_test/slime_ai_discipline_clears_target/Run()
	var/mob/living/simple_animal/slime/disciplined = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, get_step(run_loc_floor_bottom_left, EAST))
	disciplined.set_nutrition(disciplined.get_grow_nutrition() + 50) //сыт: без шанса тут же перевзять монки заново
	disciplined.Target = prey
	disciplined.Discipline = 5

	disciplined.handle_targets()

	TEST_ASSERT_NULL(disciplined.Target, "A disciplined slime must drop its target in handle_targets")

	drive_ai_planning(disciplined.ai_controller)
	TEST_ASSERT_NULL(disciplined.ai_controller.blackboard[BB_SLIME_TARGET], "The next planning pass must clear the stale blackboard target")

///Цель за пределами радиуса погони бросается: Target и blackboard чистятся
/datum/unit_test/slime_ai_gives_up_out_of_view/Run()
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)
	var/turf/far_turf = locate(1, 1, run_loc_floor_bottom_left.z)
	if(get_dist(far_turf, run_loc_floor_bottom_left) <= SLIME_AI_PURSUIT_RANGE * 2)
		far_turf = locate(world.maxx - 1, world.maxy - 1, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, far_turf)
	hunter.set_nutrition(hunter.get_starve_nutrition() - 1)
	hunter.Target = prey

	drive_ai_planning(hunter.ai_controller)
	hunter.ai_controller.process(0.5)

	TEST_ASSERT_NULL(hunter.Target, "A target beyond the pursuit range must be dropped")
	TEST_ASSERT_NULL(hunter.ai_controller.blackboard[BB_SLIME_TARGET], "Giving up must clear the blackboard target")

///Контроллер слайма существует, возле игрока активен, при клиенте в слайме гаснет
/datum/unit_test/slime_ai_controller_wired/Run()
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	fake_player.faction = list("slime") //союзник по фракции: будильник контроллера, а не еда
	register_fake_player(fake_player, get_turf(fake_player))
	var/mob/living/simple_animal/slime/subject = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)

	TEST_ASSERT(istype(subject.ai_controller, /datum/ai_controller/slime), "A slime must spawn with the slime pursuit controller")
	TEST_ASSERT_EQUAL(subject.ai_controller.ai_status, AI_STATUS_ON, "A slime controller near a player must be ON")

	SEND_SIGNAL(subject, COMSIG_MOB_CLIENT_LOGIN)
	TEST_ASSERT_EQUAL(subject.ai_controller.ai_status, AI_STATUS_OFF, "A player-controlled slime must turn its controller OFF")

	SEND_SIGNAL(subject, COMSIG_MOB_CLIENT_LOGOUT)
	TEST_ASSERT_EQUAL(subject.ai_controller.ai_status, AI_STATUS_ON, "A player leaving the slime must restore the controller")

	unregister_fake_player(fake_player)

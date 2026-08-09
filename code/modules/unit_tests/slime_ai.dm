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

///Сколько проходов планировщика должна пережить начатая погоня. Пересъём
///голода в среднем диапазоне сытости проходит с шансом 25%, так что до фикса
///цепочка такой длины рвалась практически наверняка.
#define SLIME_CHASE_PLANNING_PASSES 20

///Начатая погоня переживает пересъёмы голода: слайм со средней сытостью
///(get_hunger_drive там - бросок prob(25)) держит план, а не бросает шаг за шагом.
/datum/unit_test/slime_ai_chase_survives_hunger_reroll/Run()
	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)
	var/turf/prey_turf = locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, prey_turf)
	hunter.set_nutrition(hunter.get_hunger_nutrition() - 1) //проголодался детерминированно: цель берётся без броска

	hunter.handle_targets()
	TEST_ASSERT_EQUAL(hunter.Target, prey, "A hungry slime must acquire the monkey before its chase can be tested")

	drive_ai_planning(hunter.ai_controller)
	TEST_ASSERT(length(hunter.ai_controller.current_behaviors), "The first planning pass must start the pursuit")

	//Слайма покормили: сытость вернулась в средний диапазон, где оценка голода -
	//бросок. Зафиксированная на погоню оценка обязана пережить эти броски.
	hunter.set_nutrition(hunter.get_grow_nutrition() - 1)
	for(var/planning_pass in 1 to SLIME_CHASE_PLANNING_PASSES)
		drive_ai_planning(hunter.ai_controller)
		TEST_ASSERT(length(hunter.ai_controller.current_behaviors), "The pursuit must survive planning pass [planning_pass]: a re-rolled hunger check used to cancel the chase")
		TEST_ASSERT_EQUAL(hunter.Target, prey, "The chase must keep its target across planning pass [planning_pass]")

	hunter.Target = null
	hunter.handle_targets()
	TEST_ASSERT_EQUAL(hunter.chase_hunger, 0, "Losing the target must release the latched hunger drive")

#undef SLIME_CHASE_PLANNING_PASSES

///Добыча за стеной целью не становится: погоня всё равно её бросит, а пока
///слайм её перевыбирает, до добычи в своём загоне очередь не доходит.
/datum/unit_test/slime_ai_ignores_prey_behind_wall/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/wall_turf = locate(start.x + 1, start.y, start.z)
	var/turf/prey_turf = locate(start.x + 2, start.y, start.z)
	var/saved_wall = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)

	var/mob/living/simple_animal/slime/hunter = allocate(/mob/living/simple_animal/slime, start)
	var/mob/living/carbon/monkey/prey = allocate(/mob/living/carbon/monkey, prey_turf)
	hunter.set_nutrition(hunter.get_starve_nutrition() - 1) //голодает: взял бы кого угодно, был бы виден
	hunter.next_wander = world.time + SLIME_WANDER_COOLDOWN //без блуждания между двумя сканами геометрия остаётся той же

	hunter.handle_targets()
	var/acquired_through_wall = hunter.Target

	//Тот же слайм и та же добыча без стены - иначе проверка выше ничего не значит
	wall_turf.ChangeTurf(saved_wall)
	hunter.Target = null
	hunter.next_hunt_scan = 0 //пустой скан взвёл кулдаун охоты
	hunter.handle_targets()
	var/acquired_in_the_open = hunter.Target

	TEST_ASSERT_NULL(acquired_through_wall, "A slime must not target prey behind a wall - the pursuit drops it on the very next tick")
	TEST_ASSERT_EQUAL(acquired_in_the_open, prey, "The same prey must be acquired with the wall gone, otherwise the check above proves nothing")

///Порог замедления на холоде содержал опечатку: гейт стоял на 183.222 K, а
///формула в той же строке считала от 283.222 K. Летальный урон от холода
///начинается на 223.15 K, то есть слайм успевал умереть, ни разу не притормозив,
///и на морозе бегал на полной скорости.
/datum/unit_test/slime_cold_slows_before_it_kills/Run()
	var/mob/living/simple_animal/slime/subject = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)

	subject.bodytemperature = T20C
	subject.adjust_bodytemperature(0)
	var/warm_slowdown = subject.cached_multiplicative_slowdown

	//Заведомо ВЫШЕ порога летального урона (223.15 K) и ниже старого гейта
	//183.222 K: именно в этой вилке замедление обязано уже работать, иначе оно
	//не успевает проявиться никогда.
	subject.bodytemperature = 250
	subject.adjust_bodytemperature(0)
	var/cold_slowdown = subject.cached_multiplicative_slowdown

	TEST_ASSERT(cold_slowdown > warm_slowdown, "холодный слайм не стал медленнее тёплого ([cold_slowdown] против [warm_slowdown])")

	//А в тепле замедления быть не должно, иначе проверка выше ловила бы что угодно.
	subject.bodytemperature = T20C
	subject.adjust_bodytemperature(0)
	TEST_ASSERT_EQUAL(subject.cached_multiplicative_slowdown, warm_slowdown, "замедление от холода не снялось при возврате в тепло")

///Вода обязана срывать слайма с жертвы. Раньше apply_water() только наносил урон
///и сбрасывал цель, да и то лишь у НЕигровых слаймов: присосавшегося слайма
///нельзя было смыть огнетушителем вообще.
/datum/unit_test/slime_water_breaks_feeding/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/slime/subject = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)

	subject.Target = victim
	subject.Feedon(victim)
	TEST_ASSERT_EQUAL(subject.buckled, victim, "предпосылка: слайм должен присосаться к жертве")

	subject.apply_water()

	TEST_ASSERT_NULL(subject.buckled, "вода не сорвала слайма с жертвы")
	TEST_ASSERT_NULL(subject.Target, "вода не сбила слайму цель")

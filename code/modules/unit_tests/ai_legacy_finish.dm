// ===== Доведение легаси-чистки hostile AI (B.1-B.4) =====
//
// Проверяют, что последние нативные сканы восприятия переведены на спатиал-грид:
// терроровский Retaliate() (был oview(7) на каждый удар) и PossibleThreats()
// (был hearers()). Ни один не должен звать hearers(), оба сохраняют LOS-границу.

///Терроровский Retaliate() ищет врагов через грид AI_TARGETS + can_see (без oview),
///троттлится как базовый retaliate, союзных терроров не записывает во враги, а
///стена блокирует обнаружение.
/datum/unit_test/ai_terror_retaliate_grid/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/spider = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight, start)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(start, EAST))
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/ally = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight, get_step(start, NORTH))

	spider.next_retaliation_scan = 0 //снять троттл для первого скана
	var/hearers_before = GLOB.ai_metrics.hearers_calls
	spider.Retaliate()

	TEST_ASSERT(prey in spider.enemies, "Видимого человека не своей фракции обязан найти грид-скан")
	TEST_ASSERT(!(ally in spider.enemies), "Союзный террор не должен попадать во враги")
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.hearers_calls, hearers_before, "Терроровский Retaliate не должен звать hearers()")
	TEST_ASSERT(spider.next_retaliation_scan > world.time, "Завершённый скан обязан взвести троттл")

	//троттл: появившаяся в окне новая жертва НЕ сканируется
	var/mob/living/carbon/human/late_prey = allocate(/mob/living/carbon/human, get_step(start, NORTHEAST))
	spider.Retaliate()
	TEST_ASSERT(!(late_prey in spider.enemies), "Второй скан внутри окна троттла обязан пропускаться")

	//окно прошло - скан возобновляется и находит новую жертву
	spider.next_retaliation_scan = 0
	spider.Retaliate()
	TEST_ASSERT(late_prey in spider.enemies, "После окна троттла скан возобновляется и находит жертву")

	//LOS: жертва за стеной не обнаруживается (паритет с oview)
	var/turf/wall_turf = locate(start.x + 2, start.y, start.z)
	var/turf/hidden_turf = locate(start.x + 3, start.y, start.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	var/mob/living/carbon/human/hidden = allocate(/mob/living/carbon/human, hidden_turf)
	spider.next_retaliation_scan = 0
	spider.Retaliate()
	wall_turf.ChangeTurf(saved_turf_type)
	TEST_ASSERT(!(hidden in spider.enemies), "Стена обязана блокировать обнаружение терроровским Retaliate")

///PossibleThreats() собирает видимых атакуемых через грид AI_TARGETS без hearers();
///стена блокирует угрозу.
/datum/unit_test/ai_possible_threats_grid/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, start)
	hunter.vision_range = 9
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, get_step(start, EAST))

	var/hearers_before = GLOB.ai_metrics.hearers_calls
	var/list/threats = hunter.PossibleThreats()
	TEST_ASSERT(prey in threats, "Видимого атакуемого моба обязан найти грид")
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.hearers_calls, hearers_before, "PossibleThreats больше не должен звать hearers()")

	//LOS: моб за стеной не является возможной угрозой
	var/turf/wall_turf = locate(start.x + 2, start.y, start.z)
	var/turf/hidden_turf = locate(start.x + 3, start.y, start.z)
	var/saved_turf_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/wall)
	var/mob/living/carbon/human/hidden = allocate(/mob/living/carbon/human, hidden_turf)
	var/list/threats_walled = hunter.PossibleThreats()
	wall_turf.ChangeTurf(saved_turf_type)
	TEST_ASSERT(!(hidden in threats_walled), "Стена обязана исключать моба из возможных угроз")

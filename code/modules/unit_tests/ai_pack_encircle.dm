// ===== Координированное окружение стаи (A.1) =====
//
// Проверяют: сородичи на одну цель расходятся по РАЗНЫМ сторонам (не штабелем),
// хантер режет открытую сторону отхода, состав капается AI_ENCIRCLE_MAX, а удаление
// цели освобождает координатор.

///Хелпер: боевой милишный контроллер, нацеленный на prey в состоянии ENGAGE.
/proc/encircle_test_controller(mob/living/pawn, atom/prey, role)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_CURRENT_TARGET, prey)
	controller.set_blackboard_key(BB_AI_STATE, AI_STATE_ENGAGE)
	if(role)
		controller.set_blackboard_key(BB_AI_PACK_ROLE, role)
	return controller

///Три сородича на одну цель занимают три РАЗНЫХ направления и валидные тайлы подхода.
/datum/unit_test/ai_pack_encircle_spread/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, center)
	var/datum/ai_planning_subtree/pack_encircle/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/pack_encircle]

	//сородичи по трём разным сторонам цели (дистанция 2)
	var/list/spawn_turfs = list(
		locate(center.x, center.y + 2, center.z), //север
		locate(center.x + 2, center.y, center.z), //восток
		locate(center.x, center.y - 2, center.z), //юг
	)
	var/list/controllers = list()
	for(var/turf/spot as anything in spawn_turfs)
		var/mob/living/simple_animal/hostile/packmate = allocate(/mob/living/simple_animal/hostile, spot)
		controllers += encircle_test_controller(packmate, prey)

	var/list/claimed_dirs = list()
	for(var/datum/ai_controller/controller as anything in controllers)
		subtree.SelectBehaviors(controller, 0.5)
		var/datum/ai_pack_focus/focus = controller.pack_focus
		TEST_ASSERT_NOTNULL(focus, "An engaging packmate must join the target's encircle focus")
		var/claimed = focus.members[controller]
		TEST_ASSERT(claimed, "A coordinating packmate must claim a direction slot")
		TEST_ASSERT(!(claimed in claimed_dirs), "Packmates must spread to distinct sides, not stack on one")
		claimed_dirs += claimed
		var/turf/approach = controller.blackboard[BB_AI_APPROACH_TILE]
		TEST_ASSERT_EQUAL(approach, get_step(center, claimed), "The approach tile must be the claimed slot next to the target")
		TEST_ASSERT(!approach.is_blocked_turf(source_atom = controller.pawn), "The claimed slot must be walkable and unoccupied")

	for(var/datum/ai_controller/controller as anything in controllers)
		qdel(controller)

///Хантер занимает открытое направление отхода на стороне ПРОЧЬ от занятых слотов.
/datum/unit_test/ai_pack_encircle_hunter_cuts_escape/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, center)
	var/datum/ai_planning_subtree/pack_encircle/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/pack_encircle]

	//два члена уже держат север и восток (пачка на NE) - брешь на SW.
	//Позиции членов роли не играют: направления задаём напрямую через API.
	var/mob/living/simple_animal/hostile/north_mate = allocate(/mob/living/simple_animal/hostile, locate(center.x, center.y + 2, center.z))
	var/mob/living/simple_animal/hostile/east_mate = allocate(/mob/living/simple_animal/hostile, locate(center.x + 2, center.y + 2, center.z))
	var/datum/ai_controller/north_ctrl = encircle_test_controller(north_mate, prey)
	var/datum/ai_controller/east_ctrl = encircle_test_controller(east_mate, prey)
	north_ctrl.join_pack_focus(prey)
	north_ctrl.pack_focus.claim_direction(north_ctrl, NORTH)
	east_ctrl.join_pack_focus(prey)
	east_ctrl.pack_focus.claim_direction(east_ctrl, EAST)

	var/mob/living/simple_animal/hostile/hunter = allocate(/mob/living/simple_animal/hostile, locate(center.x + 2, center.y, center.z))
	var/datum/ai_controller/hunter_ctrl = encircle_test_controller(hunter, prey, AI_ROLE_HUNTER)
	subtree.SelectBehaviors(hunter_ctrl, 0.5)

	TEST_ASSERT_EQUAL(hunter_ctrl.pack_focus.members[hunter_ctrl], SOUTHWEST, "A hunter must cut the open escape side away from the pack (SW opposite a NE pack)")

	qdel(north_ctrl)
	qdel(east_ctrl)
	qdel(hunter_ctrl)

///Состав координатора капается AI_ENCIRCLE_MAX: лишний сородич не координируется.
/datum/unit_test/ai_pack_encircle_caps_group/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, center)

	var/list/controllers = list()
	for(var/i in 1 to AI_ENCIRCLE_MAX)
		var/mob/living/simple_animal/hostile/packmate = allocate(/mob/living/simple_animal/hostile, get_step(center, pick(GLOB.alldirs)))
		var/datum/ai_controller/controller = encircle_test_controller(packmate, prey)
		TEST_ASSERT(controller.join_pack_focus(prey), "Members within the cap must join the focus")
		controllers += controller

	var/mob/living/simple_animal/hostile/overflow = allocate(/mob/living/simple_animal/hostile, center)
	var/datum/ai_controller/overflow_ctrl = encircle_test_controller(overflow, prey)
	TEST_ASSERT(!overflow_ctrl.join_pack_focus(prey), "A packmate beyond the cap must be refused a coordination slot")
	TEST_ASSERT_NULL(overflow_ctrl.pack_focus, "A refused packmate must not hold a focus")

	for(var/datum/ai_controller/controller as anything in controllers)
		qdel(controller)
	qdel(overflow_ctrl)

///Удаление цели освобождает координатор и всех его членов.
/datum/unit_test/ai_pack_encircle_target_qdel_releases/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, center)

	var/mob/living/simple_animal/hostile/mate = allocate(/mob/living/simple_animal/hostile, get_step(center, NORTH))
	var/datum/ai_controller/mate_ctrl = encircle_test_controller(mate, prey)
	mate_ctrl.join_pack_focus(prey)
	TEST_ASSERT_NOTNULL(GLOB.ai_pack_focuses[prey], "Joining must register a focus for the target")
	TEST_ASSERT_NOTNULL(mate_ctrl.pack_focus, "The member must hold its focus")

	qdel(prey)
	TEST_ASSERT_NULL(GLOB.ai_pack_focuses[prey], "Qdeleting the target must drop its focus from the registry")
	TEST_ASSERT_NULL(mate_ctrl.pack_focus, "Qdeleting the target must release its members")

	qdel(mate_ctrl)

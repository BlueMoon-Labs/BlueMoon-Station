// Тренировка использует отдельное ядро и общие ресурсы нового роя.
/datum/unit_test/antag_training_swarmer/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/swarmer)
	TEST_ASSERT(session.prepare(), "Подготовлен полигон свармеров.")
	var/datum/antag_training_program/creature/swarmer/program = session.program
	var/mob/living/simple_animal/hostile/swarmer/body = session.current_body
	var/datum/team/swarmer_team/team = body.team
	TEST_ASSERT(team?.training && team.swarmer_core, "Дрон входит в учебный рой с ядром.")
	TEST_ASSERT_EQUAL(team.metallic_resources, 150, "У учебного ядра есть стартовый металл.")
	TEST_ASSERT(program.handle_choice(session, body, "Материалы"), "Пульт выдаёт материалы.")
	var/obj/item/stack/sheet/metal/metal = locate() in range(1, body)
	TEST_ASSERT_NOTNULL(metal, "Металл появился около дрона.")
	var/sheet_count = metal.amount
	body.extract_resources(metal)
	TEST_ASSERT_EQUAL(metal.amount, sheet_count - 3, "Дрон перерабатывает три листа за действие.")
	TEST_ASSERT_EQUAL(team.metallic_resources, 153, "Металл поступил в общее хранилище.")
	TEST_ASSERT(team.swarmer_core.swap_class(body, /mob/living/simple_animal/hostile/swarmer/generalist), "Дрон может сменить корпус через ядро.")
	var/mob/living/simple_animal/hostile/swarmer/generalist/replacement = session.avatar_mind.current
	TEST_ASSERT(istype(replacement) && replacement.team == team, "Смена корпуса сохраняет рой и разум участника.")
	TEST_ASSERT_EQUAL(session.current_body, replacement, "Учебный сеанс использует новый корпус свармера.")
	TEST_ASSERT_EQUAL(team.metallic_resources, 133, "Цена корпуса списана с общего счёта.")

/datum/unit_test/antag_training_swarmer_isolated/Run()
	var/datum/team/swarmer_team/round_team = allocate(/datum/team/swarmer_team)
	round_team.training = TRUE
	allocate(/obj/structure/swarmer/core, run_loc_floor_bottom_left, round_team)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/swarmer)
	TEST_ASSERT(session.prepare(), "Подготовлен полигон свармеров.")
	var/mob/living/simple_animal/hostile/swarmer/body = session.current_body
	TEST_ASSERT(body.team != round_team, "Учебный рой отделён от раундового.")
	TEST_ASSERT(body.team.adjust_metal(-20), "Учебный рой расходует свои ресурсы.")
	TEST_ASSERT_EQUAL(round_team.metallic_resources, 150, "Расход на полигоне не меняет запас раундового роя.")

/datum/unit_test/antag_training_swarmer_others/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/swarmer)
	TEST_ASSERT(session.prepare(), "Подготовлен полигон свармеров.")
	var/mob/living/simple_animal/hostile/swarmer/body = session.current_body
	var/obj/item/stack/sheet/metal/foreign_metal = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left)
	TEST_ASSERT(body.training_consume_refusal(foreign_metal), "Свармер полигона не может переработать предмет снаружи.")

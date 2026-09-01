///Форсаж ножных приводов (Gygax, Medical Gygax): включение ускоряет и дорожает шаг,
///выключение возвращает штатные значения, кнопка отражает состояние шасси.
///Ветки в Trigger были перепутаны с самого форка (tg починил в #53624): первое
///нажатие только переворачивало флаг, второе - включало форсаж по 900 заряда за
///шаг, и мех умирал через секунду. Репорт: "включил форсаж, выключил - мех встал
///замертво, три Gygax бросили".
/datum/unit_test/mecha_leg_overload
	///Зона прогона: гравитацию возвращаем в Destroy(), потому что провал ассерта выходит из Run() сразу
	var/area/test_area
	var/saved_gravity

/datum/unit_test/mecha_leg_overload/Destroy()
	if(test_area)
		test_area.has_gravity = saved_gravity
		test_area = null
	return ..()

/datum/unit_test/mecha_leg_overload/Run()
	var/turf/start_turf = run_loc_floor_bottom_left
	//на резервационном z гравитации нет, а без неё шаг меха отказывает в Process_Spacemove
	test_area = get_area(start_turf)
	saved_gravity = test_area.has_gravity
	test_area.has_gravity = STANDARD_GRAVITY

	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, start_turf)
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, start_turf)
	//низкоуровневая посадка: moved_inside() требует клиента, которого у тестовых мобов нет
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	var/datum/action/vehicle/sealed/mecha/mech_overload_mode/action = LAZYACCESSASSOC(mech.occupant_actions, pilot, /datum/action/vehicle/sealed/mecha/mech_overload_mode)
	TEST_ASSERT_NOTNULL(action, "Санити: пилоту Gygax обязана выдаваться кнопка форсажа")
	TEST_ASSERT_NOTNULL(mech.cell, "Санити: у меха с карты обязана быть ячейка")
	var/base_delay = mech.movedelay
	var/base_drain = mech.step_energy_drain
	TEST_ASSERT_EQUAL(base_drain, mech.normal_step_energy_drain, "Санити: до форсажа цена шага штатная")
	TEST_ASSERT(!mech.leg_overload_mode, "Санити: свежий мех без форсажа")

	action.Trigger()
	TEST_ASSERT(mech.leg_overload_mode, "Первое нажатие обязано ВКЛЮЧАТЬ форсаж")
	TEST_ASSERT(mech.movedelay < base_delay, "Включённый форсаж обязан ускорять мех: задержка [mech.movedelay] против штатной [base_delay]")
	TEST_ASSERT(mech.step_energy_drain > base_drain, "Включённый форсаж обязан дорожать: [mech.step_energy_drain] против штатной [base_drain]")
	TEST_ASSERT_EQUAL(action.button_icon_state, "mech_overload_on", "Кнопка обязана показывать включённый форсаж")
	var/overload_drain = mech.step_energy_drain

	//шаг под форсажем берёт форсажную цену, а не штатную
	mech.cell.charge = mech.cell.maxcharge
	var/turf/east_turf = get_step(start_turf, EAST)
	//vehicle_move() в чужую сторону только разворачивает мех, шаг - со второго вызова
	mech.setDir(EAST)
	TEST_ASSERT(mech.vehicle_move(EAST), "Санити: мех с полной ячейкой обязан шагать под форсажем")
	TEST_ASSERT_EQUAL(get_turf(mech), east_turf, "Мех обязан сдвинуться на восток")
	TEST_ASSERT_EQUAL(mech.cell.charge, mech.cell.maxcharge - overload_drain, "Шаг под форсажем обязан стоить форсажную цену")

	action.Trigger()
	TEST_ASSERT(!mech.leg_overload_mode, "Второе нажатие обязано ВЫКЛЮЧАТЬ форсаж")
	TEST_ASSERT_EQUAL(mech.movedelay, base_delay, "После выключения форсажа задержка шага обязана вернуться к штатной")
	TEST_ASSERT_EQUAL(mech.step_energy_drain, base_drain, "После выключения форсажа цена шага обязана вернуться к штатной")
	TEST_ASSERT_EQUAL(mech.bumpsmash, initial(mech.bumpsmash), "После выключения форсажа таран обязан вернуться к типовому")
	TEST_ASSERT_EQUAL(action.button_icon_state, "mech_overload_off", "Кнопка обязана показывать выключенный форсаж")

	//резерв: форсаж не имеет права высушить ячейку досуха. На пороге он сам
	//отключается, и тот же шаг проходит по штатной цене - мех уходит своим ходом
	action.Trigger()
	TEST_ASSERT(mech.leg_overload_mode, "Санити: третье нажатие снова включает форсаж")
	var/reserve = mech.cell.maxcharge * MECHA_OVERLOAD_POWER_RESERVE
	mech.cell.charge = reserve - 1
	COOLDOWN_RESET(mech, cooldown_vehicle_move)
	mech.setDir(WEST)
	TEST_ASSERT(mech.vehicle_move(WEST), "Мех на резерве обязан шагать штатным ходом")
	TEST_ASSERT_EQUAL(get_turf(mech), start_turf, "Мех обязан вернуться на запад")
	TEST_ASSERT(!mech.leg_overload_mode, "На резерве заряда форсаж обязан отключиться сам")
	TEST_ASSERT_EQUAL(action.button_icon_state, "mech_overload_off", "Кнопка обязана отразить самоотключение форсажа")
	TEST_ASSERT_EQUAL(mech.cell.charge, reserve - 1 - base_drain, "Шаг после самоотключения обязан стоить штатную цену")
	TEST_ASSERT_EQUAL(mech.movedelay, base_delay, "После самоотключения задержка шага штатная")

	//на резерве форсаж не включается, вместо этого пилота предупреждают
	action.Trigger()
	TEST_ASSERT(!mech.leg_overload_mode, "На резерве заряда форсаж не обязан включаться")
	TEST_ASSERT_EQUAL(mech.step_energy_drain, base_drain, "Отказ включения обязан оставить штатную цену шага")

	//Medical Gygax таранит по умолчанию: выключение форсажа не должно это отнимать
	var/obj/vehicle/sealed/mecha/medical/medigax/medigax = allocate(/obj/vehicle/sealed/mecha/medical/medigax, east_turf)
	var/mob/living/carbon/human/medic = allocate(/mob/living/carbon/human, east_turf)
	medic.forceMove(medigax)
	medigax.add_occupant(medic)
	var/datum/action/vehicle/sealed/mecha/mech_overload_mode/medigax_action = LAZYACCESSASSOC(medigax.occupant_actions, medic, /datum/action/vehicle/sealed/mecha/mech_overload_mode)
	TEST_ASSERT_NOTNULL(medigax_action, "Санити: пилоту Medical Gygax обязана выдаваться кнопка форсажа")
	TEST_ASSERT(medigax.bumpsmash, "Санити: Medical Gygax таранит по умолчанию")
	medigax_action.Trigger()
	TEST_ASSERT(medigax.leg_overload_mode, "Форсаж Medical Gygax обязан включаться с первого нажатия")
	medigax_action.Trigger()
	TEST_ASSERT(!medigax.leg_overload_mode, "Форсаж Medical Gygax обязан выключаться со второго нажатия")
	TEST_ASSERT(medigax.bumpsmash, "Выключение форсажа не имеет права отнимать у Medical Gygax типовой таран")

	//новый пилот получает кнопку в состоянии шасси, а не в дефолтном "выключено"
	medigax_action.Trigger()
	medigax.remove_occupant(medic)
	medic.forceMove(east_turf)
	var/mob/living/carbon/human/second_medic = allocate(/mob/living/carbon/human, east_turf)
	second_medic.forceMove(medigax)
	medigax.add_occupant(second_medic)
	var/datum/action/vehicle/sealed/mecha/mech_overload_mode/second_action = LAZYACCESSASSOC(medigax.occupant_actions, second_medic, /datum/action/vehicle/sealed/mecha/mech_overload_mode)
	TEST_ASSERT_NOTNULL(second_action, "Санити: второму пилоту обязана выдаваться кнопка форсажа")
	TEST_ASSERT_EQUAL(second_action.button_icon_state, "mech_overload_on", "Кнопка нового пилота обязана показывать включённый форсаж шасси")

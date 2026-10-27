/// «Собери киборга»: тело-донор, MMI и учебная рама выдаются в мастерской; мозг, MMI и рама засчитываются по шагам, киборг уходит вместе с прогоном.
/datum/unit_test/antag_training_exercise_robotics_cyborg/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	enter_training_sector(session, ui, "robotics")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "robotics_cyborg")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в секторе робототехники.")
	var/obj/item/robot_suit/prebuilt/training/frame = run.find_prop(/obj/item/robot_suit/prebuilt/training)
	var/obj/item/mmi/mmi = run.find_prop(/obj/item/mmi)
	var/mob/living/carbon/human/donor = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(frame && isturf(frame.loc) && frame.Adjacent(user), "Учебная рама стоит рядом с участником.")
	TEST_ASSERT(mmi && mmi.Adjacent(user), "MMI лежит рядом с участником.")
	TEST_ASSERT(donor?.stat == DEAD && donor.mind, "Тело-донор мертво, но с разумом.")
	var/datum/mind/donor_mind = donor.mind

	var/obj/item/organ/brain/brain = donor.getorganslot(ORGAN_SLOT_BRAIN)
	brain.Remove()
	TEST_ASSERT_EQUAL(run.step_index, 2, "Извлечение мозга засчитано.")
	TEST_ASSERT(brain in run.props, "Извлечённый мозг уходит вместе с прогоном.")
	TEST_ASSERT(drill_hold(user, brain), "Участник держит мозг.")
	mmi.attackby(brain, user)
	TEST_ASSERT_EQUAL(run.step_index, 3, "Мозг в MMI засчитан.")
	TEST_ASSERT(drill_hold(user, mmi), "Участник держит MMI.")
	frame.attackby(mmi, user)
	var/mob/living/silicon/robot/borg = frame.loc
	TEST_ASSERT(iscyborg(borg) && borg.mind == donor_mind, "Из рамы собран киборг с разумом донора.")
	TEST_ASSERT(run.ended && run.success, "Киборг завершает упражнение: [run.result_text]")
	TEST_ASSERT(borg in run.props, "Киборг уходит вместе с прогоном.")

	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(QDELETED(borg) && QDELETED(donor) && QDELETED(brain) && QDELETED(mmi), "«Прекратить» убирает киборга, донора, мозг и MMI.")

/datum/unit_test/proc/ripley_step(obj/item/mecha_parts/chassis/ripley/chassis, mob/living/carbon/human/user, obj/item/tool)
	if(drill_hold(user, tool))
		tool.melee_attack_chain(user, chassis)

/datum/unit_test/proc/ripley_weld(obj/item/mecha_parts/chassis/ripley/chassis, mob/living/carbon/human/user, obj/item/weldingtool/welder)
	if(!drill_hold(user, welder))
		return FALSE
	if(!welder.isOn())
		welder.attack_self(user)
	if(!welder.isOn())
		return FALSE
	welder.melee_attack_chain(user, chassis)
	return TRUE

/// «Собери Рипли»: шасси и ящик с деталями рядом с участником; каждый этап сборки засчитывается своим шагом, готовый мех завершает упражнение.
/datum/unit_test/antag_training_exercise_robotics_ripley/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/mob/living/carbon/human/user = session.current_body
	user.a_intent = INTENT_HELP
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	enter_training_sector(session, ui, "robotics")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "robotics_ripley")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в секторе робототехники.")
	var/obj/item/mecha_parts/chassis/ripley/chassis = run.find_prop(/obj/item/mecha_parts/chassis/ripley)
	var/obj/structure/closet/crate/crate = run.find_prop(/obj/structure/closet/crate)
	TEST_ASSERT(chassis && crate && chassis.Adjacent(user) && crate.Adjacent(user), "Шасси и ящик стоят рядом с участником.")
	TEST_ASSERT(crate.open(user), "Ящик открывается.")
	var/turf/parts = get_turf(crate)

	for(var/part_type in list(/obj/item/mecha_parts/part/ripley_torso, /obj/item/mecha_parts/part/ripley_left_arm, /obj/item/mecha_parts/part/ripley_right_arm, /obj/item/mecha_parts/part/ripley_left_leg, /obj/item/mecha_parts/part/ripley_right_leg))
		var/obj/item/part = locate(part_type) in parts
		TEST_ASSERT_NOTNULL(part, "В ящике есть [part_type].")
		ripley_step(chassis, user, part)
	TEST_ASSERT_EQUAL(run.step_index, 2, "Конечности на шасси засчитаны.")

	var/obj/item/wrench/wrench = allocate(/obj/item/wrench, get_turf(user))
	var/obj/item/screwdriver/screwdriver = allocate(/obj/item/screwdriver, get_turf(user))
	var/obj/item/wirecutters/cutters = allocate(/obj/item/wirecutters, get_turf(user))
	var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool, get_turf(user))
	ripley_step(chassis, user, wrench)
	ripley_step(chassis, user, screwdriver)
	ripley_step(chassis, user, locate(/obj/item/stack/cable_coil) in parts)
	ripley_step(chassis, user, cutters)
	TEST_ASSERT_EQUAL(run.step_index, 3, "Гидравлика и проводка засчитаны.")

	ripley_step(chassis, user, locate(/obj/item/circuitboard/mecha/ripley/main) in parts)
	ripley_step(chassis, user, screwdriver)
	ripley_step(chassis, user, locate(/obj/item/circuitboard/mecha/ripley/peripherals) in parts)
	ripley_step(chassis, user, screwdriver)
	TEST_ASSERT_EQUAL(run.step_index, 4, "Платы засчитаны.")

	for(var/module_type in list(/obj/item/stock_parts/scanning_module, /obj/item/stock_parts/capacitor, /obj/item/stock_parts/cell))
		ripley_step(chassis, user, locate(module_type) in parts)
		ripley_step(chassis, user, screwdriver)
	TEST_ASSERT_EQUAL(run.step_index, 5, "Модули засчитаны.")

	ripley_step(chassis, user, locate(/obj/item/stack/sheet/metal) in parts)
	ripley_step(chassis, user, wrench)
	TEST_ASSERT(ripley_weld(chassis, user, welder), "Сварка включена.")
	ripley_step(chassis, user, locate(/obj/item/stack/rods) in parts)
	var/turf/bay = get_turf(chassis)
	TEST_ASSERT(ripley_weld(chassis, user, welder), "Сварка снова включена.")
	var/obj/vehicle/sealed/mecha/working/ripley/mech = locate() in bay
	TEST_ASSERT(QDELETED(chassis) && mech, "Последняя сварка заменяет шасси готовым Рипли.")
	TEST_ASSERT(run.ended && run.success, "Готовый мех завершает упражнение: [run.result_text]")
	TEST_ASSERT(mech in run.props, "Мех уходит вместе с прогоном.")
	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(QDELETED(mech) && QDELETED(crate), "«Прекратить» убирает мех и ящик.")

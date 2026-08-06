/// Собранный вентилятор стоит материалов и времени, голограмма не стоит ничего,
/// поэтому проектор давал бесплатные вечные стены. Ограничение - время: эмиттер
/// тратит заряд, пока фаны развёрнуты, и гасит их, когда заряд кончился.
///
/// Отдельно проверяем главное требование совместимости: холофаны, расставленные
/// на картах руин и эвент-зон, проектора не имеют, ни в чьём списке не числятся
/// и разрядом эмиттера не гасятся.
/datum/unit_test/holofan_projector_charge

/datum/unit_test/holofan_projector_charge/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/projected_spot = locate(origin.x + 1, origin.y, origin.z)
	var/turf/open/mapped_spot = locate(origin.x + 2, origin.y, origin.z)
	TEST_ASSERT(istype(projected_spot) && istype(mapped_spot), "тестовые клетки не открытые турфы")

	var/obj/item/holosign_creator/atmos/projector = allocate(/obj/item/holosign_creator/atmos, origin)
	TEST_ASSERT(projector.max_charge > 0, "проектор холофанов остался без ёмкости")
	TEST_ASSERT_EQUAL(projector.charge, projector.max_charge, "проектор создан не с полным зарядом")

	// Фан от проектора: числится в его списке и держит на себя обратную ссылку.
	var/obj/structure/holosign/barrier/atmos/projected_fan = new(projected_spot, projector)
	TEST_ASSERT(projected_fan in projector.signs, "спроецированный фан не попал в список проектора")
	TEST_ASSERT_EQUAL(projected_fan.projector, projector, "спроецированный фан не знает своего проектора")

	// Фан с карты: проектора нет, ни в чьём списке не числится.
	var/obj/structure/holosign/barrier/atmos/mapped_fan = new(mapped_spot)
	TEST_ASSERT_NULL(mapped_fan.projector, "фан без проектора всё равно к кому-то привязался")
	TEST_ASSERT(!(mapped_fan in projector.signs), "фан с карты попал в список чужого проектора")

	// Один проход опроса при развёрнутом фане обязан списать заряд.
	var/charge_before = projector.charge
	projector.process()
	TEST_ASSERT(projector.charge < charge_before, "заряд не тратится, пока фан развёрнут")

	// Досушиваем заряд до порога и проверяем, что проекция гаснет.
	projector.charge = 0.01
	projector.process()
	TEST_ASSERT(QDELETED(projected_fan), "разряженный эмиттер не погасил свою проекцию")
	TEST_ASSERT(!length(projector.signs), "список проектора не опустел после разряда")

	// Главное: фан с карты пережил разряд чужого эмиттера.
	TEST_ASSERT(!QDELETED(mapped_fan), "разряд проектора погасил холофан, расставленный на карте")
	TEST_ASSERT_EQUAL(mapped_fan.CanAtmosPass, ATMOS_PASS_NO, "фан с карты перестал держать газ")

	// Без развёрнутых проекций заряд восстанавливается и опрос сам себя гасит.
	projector.charge = 0
	projector.process()
	TEST_ASSERT(projector.charge > 0, "заряд не восстанавливается без развёрнутых проекций")
	projector.charge = projector.max_charge
	TEST_ASSERT_EQUAL(projector.process(), PROCESS_KILL, "полный проектор без проекций не снялся с опроса")

	// Разряженный проектор не должен ставить фан, который погаснет через секунду.
	projector.charge = projector.max_charge * HOLOFAN_PROJECTOR_DEPLOY_RATIO * 0.5
	var/mob/living/carbon/human/operator = allocate(/mob/living/carbon/human, origin)
	projector.afterattack(projected_spot, operator, TRUE)
	TEST_ASSERT(!length(projector.signs), "разряженный проектор всё равно развернул проекцию")

	// Уборочный проектор ёмкости не имеет и вести себя иначе не должен.
	var/obj/item/holosign_creator/janitor_projector = allocate(/obj/item/holosign_creator, origin)
	TEST_ASSERT_EQUAL(janitor_projector.max_charge, 0, "проектор без ёмкости внезапно её получил")
	TEST_ASSERT_EQUAL(janitor_projector.process(), PROCESS_KILL, "проектор без ёмкости остался в опросе")

	qdel(mapped_fan)

/// Стена из фанов не должна исчезать одним кадром: разряженный эмиттер гасит по
/// одной проекции, начиная с последней поставленной, и оставляет себе запас.
/// Иначе отсек вскрывается мгновенно и без всякого предупреждения, а игрок,
/// стоящий за стеной, узнаёт об этом уже в вакууме.
/datum/unit_test/holofan_projector_sheds_one

/datum/unit_test/holofan_projector_sheds_one/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/list/spots = list()
	for(var/offset in 1 to 3)
		var/turf/open/spot = locate(origin.x + offset, origin.y, origin.z)
		TEST_ASSERT(istype(spot), "тестовая клетка [offset] не открытый турф")
		spots += spot

	var/obj/item/holosign_creator/atmos/projector = allocate(/obj/item/holosign_creator/atmos, origin)
	for(var/turf/open/spot as anything in spots)
		new /obj/structure/holosign/barrier/atmos(spot, projector)
	TEST_ASSERT_EQUAL(length(projector.signs), 3, "предпосылка: проектор должен держать три проекции")

	var/obj/structure/holosign/last_placed = projector.signs[3]
	var/obj/structure/holosign/first_placed = projector.signs[1]
	projector.charge = 0.01
	projector.process()

	TEST_ASSERT(QDELETED(last_placed), "разряд погасил не последнюю поставленную проекцию")
	TEST_ASSERT(!QDELETED(first_placed), "разряд снёс проекцию, поставленную первой")
	TEST_ASSERT_EQUAL(length(projector.signs), 2, "разряд снёс больше одной проекции разом")
	TEST_ASSERT(projector.charge > 0, "эмиттер не оставил себе запаса после сброса проекции")

	for(var/obj/structure/holosign/fan as anything in projector.signs.Copy())
		qdel(fan)

/// Исследуемый проектор отличается не размером бака, а тем, что эмиттер
/// подзаряжается прямо во время работы: отдачи хватает ровно на одну проекцию,
/// каждая следующая уводит баланс в минус. Проверяем именно этот баланс, а не
/// то, что чисел стало больше.
/datum/unit_test/holofan_sustained_projector

/datum/unit_test/holofan_sustained_projector/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/first_spot = locate(origin.x + 1, origin.y + 3, origin.z)
	var/turf/open/second_spot = locate(origin.x + 2, origin.y + 3, origin.z)
	TEST_ASSERT(istype(first_spot) && istype(second_spot), "тестовые клетки не открытые турфы")

	var/obj/item/holosign_creator/atmos/sustained/projector = allocate(/obj/item/holosign_creator/atmos/sustained, origin)
	var/obj/item/holosign_creator/atmos/plain = allocate(/obj/item/holosign_creator/atmos, origin)
	TEST_ASSERT(projector.max_charge > plain.max_charge, "у исследуемого проектора запас не больше обычного")
	TEST_ASSERT(projector.charge_recovery_active > 0, "исследуемый проектор не подзаряжается на ходу")
	TEST_ASSERT_EQUAL(plain.charge_recovery_active, 0, "обычный проектор внезапно подзаряжается на ходу")

	// Одна проекция: отдача перекрывает расход, запас не убывает.
	var/obj/structure/holosign/barrier/atmos/first_fan = new(first_spot, projector)
	projector.charge = projector.max_charge * 0.5
	var/charge_with_one = projector.charge
	for(var/i in 1 to 5)
		projector.process()
	TEST_ASSERT(projector.charge >= charge_with_one, "одна проекция всё равно съедает запас исследуемого проектора")
	TEST_ASSERT(!QDELETED(first_fan), "проекция погасла при положительном балансе")

	// Вторая проекция уводит баланс в минус.
	var/obj/structure/holosign/barrier/atmos/second_fan = new(second_spot, projector)
	projector.charge = projector.max_charge * 0.5
	var/charge_with_two = projector.charge
	for(var/i in 1 to 5)
		projector.process()
	TEST_ASSERT(projector.charge < charge_with_two, "вторая проекция не начала тратить запас")

	// Обычный проектор тратит запас уже на одной.
	var/obj/structure/holosign/barrier/atmos/plain_fan = new(second_spot, plain)
	plain.charge = plain.max_charge * 0.5
	var/plain_charge_before = plain.charge
	plain.process()
	TEST_ASSERT(plain.charge < plain_charge_before, "обычный проектор перестал тратить запас на одной проекции")

	qdel(first_fan)
	qdel(second_fan)
	qdel(plain_fan)

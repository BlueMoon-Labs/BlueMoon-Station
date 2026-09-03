/// Плитка пола в зелёном интенте обязана уходить в турф под подпольным объектом:
/// трубы, венты, скрубберы и мусоропровод лежат в полу и перехватывают клик
/// раньше турфа, так что игрок целится в пол, а бьёт трубу.
/// Боевые интенты правило не трогает - ломать трубы плиткой по-прежнему можно.
/datum/unit_test/tile_pipe_placement
	/// Сколько раз плитка реально замахнулась по объекту (COMSIG_ITEM_ATTACK_OBJ).
	/// Сигнал выдаётся в attack_obj(), то есть только когда клик дошёл до самого
	/// объекта, а не был передан турфу.
	var/obj_swings = 0
	/// Цель последнего такого замаха.
	var/atom/last_swing_target

/datum/unit_test/tile_pipe_placement/proc/count_obj_swing(datum/source, obj/target, mob/user)
	SIGNAL_HANDLER
	obj_swings++
	last_swing_target = target

/// Кладёт в указанной клетке тестовой зоны плейтинг и отдаёт свежий турф.
/// Готовый пол не годится: на нём клик перехватывает try_replace_tile()
/// (floor.dm:201), которому нужен лом во второй руке, и до ветки укладки
/// в /turf/open/floor/plating/attackby() дело не доходит вовсе.
/datum/unit_test/tile_pipe_placement/proc/make_plating(offset_x, offset_y)
	var/turf/spot = locate(run_loc_floor_bottom_left.x + offset_x, run_loc_floor_bottom_left.y + offset_y, run_loc_floor_bottom_left.z)
	return spot.ChangeTurf(/turf/open/floor/plating, flags = CHANGETURF_INHERIT_AIR)

/// Проверяет один подпольный тип: зелёный интент обязан уложить пол под целью,
/// не тронув её саму и потратив ровно одну плитку.
/datum/unit_test/tile_pipe_placement/proc/check_underfloor_redirect(mob/living/carbon/human/builder, obj/item/stack/tile/tiles, target_type, offset_x, offset_y, what)
	var/turf/spot = make_plating(offset_x, offset_y)
	TEST_ASSERT(istype(spot, /turf/open/floor/plating), "предусловие [what]: под целью не удалось сделать плейтинг")
	// Координаты, а не ссылка: укладка пола идёт через PlaceOnTop(), которая
	// подменяет сам датум турфа - старая ссылка после клика ничего не значит.
	var/spot_x = spot.x
	var/spot_y = spot.y
	var/spot_z = spot.z

	var/obj/target = allocate(target_type, spot)
	TEST_ASSERT_EQUAL(target.level, PIPE_HIDDEN_LEVEL, "предусловие [what]: цель обязана лежать под полом")
	TEST_ASSERT(!target.density, "предусловие [what]: цель обязана быть неплотной")
	var/starting_integrity = target.obj_integrity
	var/starting_amount = tiles.amount
	var/starting_swings = obj_swings

	builder.a_intent = INTENT_HELP
	TEST_ASSERT(tiles.CheckAttackCooldown(builder, target), "предусловие [what]: клик-кулдаун закрыт, цепочка не дойдёт до pre_attack()")
	tiles.melee_attack_chain(builder, target)

	var/turf/after = locate(spot_x, spot_y, spot_z)
	TEST_ASSERT(istype(after, tiles.turf_type), "[what]: зелёный интент не уложил пол, турф остался [after.type]")
	TEST_ASSERT(!QDELETED(target), "[what]: цель уничтожена вместо укладки пола")
	TEST_ASSERT_EQUAL(obj_swings, starting_swings, "[what]: зелёный интент всё-таки замахнулся по цели вместо укладки пола")
	TEST_ASSERT_EQUAL(target.obj_integrity, starting_integrity, "[what]: цель получила урон в зелёном интенте")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount - 1, "[what]: укладка пола не потратила ровно одну плитку")
	TEST_ASSERT_EQUAL(get_turf(target), after, "[what]: цель обязана остаться на месте под новым полом")

/// Главный регресс: в боевом интенте плитка бьёт вент, а не проваливается в пол.
/// Без этой проверки правка могла бы незаметно отобрать возможность ломать
/// подпольную атмосферику вовсе.
/// Цель именно вент: обычная труба гасит мили-удары слабее 12 урона
/// (pipes.dm:146), а самая тяжёлая плитка бьёт на 6, так что по трубе урон
/// не наблюдаем ни до правки, ни после. У вента такого порога нет.
/datum/unit_test/tile_pipe_placement/proc/check_combat_intent_still_hits(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	var/turf/spot = make_plating(4, 0)
	TEST_ASSERT(istype(spot, /turf/open/floor/plating), "предусловие боевого интента: под вентом не удалось сделать плейтинг")
	var/spot_x = spot.x
	var/spot_y = spot.y
	var/spot_z = spot.z

	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, spot)
	var/starting_integrity = vent.obj_integrity
	var/starting_amount = tiles.amount
	var/starting_swings = obj_swings
	TEST_ASSERT(vent.run_obj_armor(tiles.force, BRUTE, MELEE) > 0, "предусловие: вент обязан пропускать урон от плитки, иначе удар нечем измерить")

	builder.a_intent = INTENT_HARM
	TEST_ASSERT(tiles.CheckAttackCooldown(builder, vent), "предусловие боевого интента: клик-кулдаун закрыт")
	tiles.melee_attack_chain(builder, vent)

	var/turf/after = locate(spot_x, spot_y, spot_z)
	TEST_ASSERT(istype(after, /turf/open/floor/plating), "боевой интент уложил пол вместо удара по венту, турф стал [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "боевой интент потратил плитку на укладку пола")
	TEST_ASSERT_EQUAL(obj_swings, starting_swings + 1, "боевой интент не довёл клик до вента")
	TEST_ASSERT_EQUAL(last_swing_target, vent, "боевой интент замахнулся не по венту")
	TEST_ASSERT(vent.obj_integrity < starting_integrity, "боевой интент не нанёс венту урона ([vent.obj_integrity] из [starting_integrity])")

/// Труба под боевым интентом тоже обязана ловить клик. Урон по ней не
/// проверяется: порог мили-урона трубы (pipes.dm:146) выше силы любой плитки,
/// так что признак удара тут - сам факт замаха по объекту.
/// Заодно проверяется интент разоружения: он тоже боевой, редиректа быть не должно.
/datum/unit_test/tile_pipe_placement/proc/check_combat_intent_reaches_pipe(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	var/turf/spot = make_plating(4, 4)
	TEST_ASSERT(istype(spot, /turf/open/floor/plating), "предусловие трубы: под трубой не удалось сделать плейтинг")
	var/spot_x = spot.x
	var/spot_y = spot.y
	var/spot_z = spot.z

	var/obj/machinery/atmospherics/pipe/simple/pipe = allocate(/obj/machinery/atmospherics/pipe/simple, spot)
	var/starting_amount = tiles.amount
	var/starting_swings = obj_swings
	// Тревожная сигнализация для будущего: если порог трубы опустят ниже силы
	// плитки, проверку боевого интента можно и нужно вернуть на obj_integrity.
	TEST_ASSERT_EQUAL(pipe.run_obj_armor(tiles.force, BRUTE, MELEE), FALSE, "труба перестала гасить слабый мили-удар - верните проверку боевого интента на obj_integrity")

	builder.a_intent = INTENT_HARM
	TEST_ASSERT(tiles.CheckAttackCooldown(builder, pipe), "предусловие трубы: клик-кулдаун закрыт")
	tiles.melee_attack_chain(builder, pipe)

	var/turf/after = locate(spot_x, spot_y, spot_z)
	TEST_ASSERT(istype(after, /turf/open/floor/plating), "боевой интент уложил пол вместо удара по трубе, турф стал [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "боевой интент потратил плитку на укладку пола под трубой")
	TEST_ASSERT_EQUAL(obj_swings, starting_swings + 1, "боевой интент не довёл клик до трубы")
	TEST_ASSERT_EQUAL(last_swing_target, pipe, "боевой интент замахнулся не по трубе")

	// Разоружение - тоже боевой интент, редиректа быть не должно.
	var/disarm_amount = tiles.amount
	var/disarm_swings = obj_swings
	builder.a_intent = INTENT_DISARM
	TEST_ASSERT(tiles.CheckAttackCooldown(builder, pipe), "предусловие интента разоружения: клик-кулдаун закрыт")
	var/redirect = tiles.pre_attack(pipe, builder)
	TEST_ASSERT(!(redirect & STOP_ATTACK_PROC_CHAIN), "интент разоружения ушёл в редирект на турф")
	var/turf/after_disarm = locate(spot_x, spot_y, spot_z)
	TEST_ASSERT(istype(after_disarm, /turf/open/floor/plating), "интент разоружения уложил пол под трубой")
	TEST_ASSERT_EQUAL(tiles.amount, disarm_amount, "интент разоружения потратил плитку")
	TEST_ASSERT_EQUAL(obj_swings, disarm_swings, "pre_attack() сам по себе не должен бить трубу")

/// Плотная атмос-машина под правило не попадает: у неё level = 2 и density = TRUE,
/// пол под ней не кладут, клик обязан дойти до самой машины.
/datum/unit_test/tile_pipe_placement/proc/check_dense_machine_ignored(mob/living/carbon/human/builder, obj/item/stack/tile/tiles)
	var/turf/spot = make_plating(0, 4)
	TEST_ASSERT(istype(spot, /turf/open/floor/plating), "предусловие плотной машины: не удалось сделать плейтинг")
	var/spot_x = spot.x
	var/spot_y = spot.y
	var/spot_z = spot.z

	var/obj/machinery/atmospherics/components/unary/cryo_cell/cryo = allocate(/obj/machinery/atmospherics/components/unary/cryo_cell, spot)
	TEST_ASSERT(cryo.density, "предусловие: криокапсула обязана быть плотной")
	TEST_ASSERT_NOTEQUAL(cryo.level, PIPE_HIDDEN_LEVEL, "предусловие: криокапсула не лежит под полом")
	var/starting_amount = tiles.amount

	builder.a_intent = INTENT_HELP
	TEST_ASSERT(tiles.CheckAttackCooldown(builder, cryo), "предусловие плотной машины: клик-кулдаун закрыт")
	var/redirect = tiles.pre_attack(cryo, builder)

	TEST_ASSERT(!(redirect & STOP_ATTACK_PROC_CHAIN), "плотная машина ушла в редирект на турф")
	var/turf/after = locate(spot_x, spot_y, spot_z)
	TEST_ASSERT(istype(after, /turf/open/floor/plating), "под плотной машиной уложили пол, турф стал [after.type]")
	TEST_ASSERT_EQUAL(tiles.amount, starting_amount, "клик по плотной машине потратил плитку")

/datum/unit_test/tile_pipe_placement/Run()
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/stack/tile/plasteel/tiles = allocate(/obj/item/stack/tile/plasteel, run_loc_floor_bottom_left, 20)
	TEST_ASSERT(builder.put_in_active_hand(tiles, forced = TRUE), "предусловие: плитки не удалось вложить в руку")
	TEST_ASSERT_NOTNULL(tiles.turf_type, "предусловие: у стальных плиток обязан быть turf_type")
	RegisterSignal(tiles, COMSIG_ITEM_ATTACK_OBJ, PROC_REF(count_obj_swing))

	// Цели разнесены по зоне, чтобы соседние атмос-машины не сцеплялись в пайплайн.
	check_underfloor_redirect(builder, tiles, /obj/machinery/atmospherics/pipe/simple, 2, 0, "труба")
	check_underfloor_redirect(builder, tiles, /obj/machinery/atmospherics/components/unary/vent_pump, 0, 2, "вент")
	check_underfloor_redirect(builder, tiles, /obj/machinery/atmospherics/components/unary/vent_scrubber, 2, 2, "скруббер")
	check_underfloor_redirect(builder, tiles, /obj/structure/disposalpipe/segment, 4, 2, "мусоропроводная труба")

	check_combat_intent_still_hits(builder, tiles)
	check_combat_intent_reaches_pipe(builder, tiles)
	check_dense_machine_ignored(builder, tiles)

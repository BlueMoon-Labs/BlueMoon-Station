/// Регрессии по прод-раунду 9827 (2026-07-29): hard delete'ы из harddels.log/runtime.log
/// и рантаймы "doMove qdel-нутого ...", которые оставляли в мире удалённые атомы.
///
/// Числа в комментариях - реальные замеры раунда: строка
/// "## GC: ... не собрался (warnfail, ~120с, внешних ссылок: N)" и вердикт REF SEARCH.

/datum/unit_test/harddel_9827_base
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/harddel_9827_base/Run()
	return

/// Модкит переносит детали донора в новый ствол макросом TRANSFER_ATOM_VAR.
/// Макрос делал qdel(TARGET.VAR) и НЕ обнулял поле, поэтому при доноре без
/// магазина (enforcer/nomag) новый ствол оставался со ссылкой на удалённый
/// магазин: attack_self делал ему forceMove и клал мертвеца игроку в руки.
/// Раунд 9827: три рантайма doMove подряд и hard delete
/// /obj/item/ammo_box/magazine/e45 (1 внешняя ссылка).
/datum/unit_test/modkit_replace_drops_dead_parts
	parent_type = /datum/unit_test/harddel_9827_base

/// Донор без магазина: новый ствол обязан остаться пустым, а не с трупом.
/datum/unit_test/modkit_replace_drops_dead_parts/proc/magless_donor_leaves_no_corpse()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, floor)
	var/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag/donor = allocate(/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag, floor)
	TEST_ASSERT_NULL(donor.magazine, "Донор nomag неожиданно приехал с магазином")

	var/obj/item/gun/ballistic/result = new /obj/item/gun/ballistic/automatic/pistol/enforcer/bwal2572(floor)
	TEST_ASSERT_NOTNULL(result.magazine, "Заводской bwal2572 обязан иметь свой магазин")
	var/list/record = target_record(result.magazine, "заводской магазин, выброшенный модкитом")

	var/obj/item/modkit/kit = allocate(/obj/item/modkit/bwal2572_kit, floor)
	kit.gun_to_gun_replace(donor, result)

	TEST_ASSERT_NULL(result.magazine, "У ствола осталась ссылка на выброшенный магазин")
	TEST_ASSERT_NULL(result.chambered, "У ствола осталась ссылка на выброшенный патрон")

	// Ровно тот путь, который рантаймил в проде.
	result.attack_self(user)
	//пустая рука в held_items - это null, поэтому фильтруем istype'ом
	for(var/obj/item/held in user.held_items)
		TEST_ASSERT(!QDELETED(held), "attack_self выдал в руки удалённый предмет")

	qdel(result)
	return record

/// Донор с магазином: магазин обязан переехать, а заводской - уйти.
/datum/unit_test/modkit_replace_drops_dead_parts/proc/loaded_donor_transfers_magazine()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/gun/ballistic/automatic/pistol/enforcer/donor = allocate(/obj/item/gun/ballistic/automatic/pistol/enforcer, floor)
	TEST_ASSERT_NOTNULL(donor.magazine, "Донор enforcer приехал без магазина")
	var/obj/item/ammo_box/magazine/donor_magazine = donor.magazine

	var/obj/item/gun/ballistic/result = new /obj/item/gun/ballistic/automatic/pistol/enforcer/bwal2572(floor)
	var/obj/item/modkit/kit = allocate(/obj/item/modkit/bwal2572_kit, floor)
	kit.gun_to_gun_replace(donor, result)

	TEST_ASSERT_EQUAL(result.magazine, donor_magazine, "Магазин донора не переехал в новый ствол")
	TEST_ASSERT_EQUAL(result.magazine.loc, result, "Магазин переехал, но остался вне ствола")
	TEST_ASSERT_NULL(donor.magazine, "У донора остался магазин, который уже в новом стволе")
	TEST_ASSERT_NOTNULL(result.pin, "Новый ствол остался без пина и не сможет стрелять")
	qdel(result)

/datum/unit_test/modkit_replace_drops_dead_parts/Run()
	begin_isolated_gc()
	var/list/discarded = magless_donor_leaves_no_corpse()
	loaded_donor_transfers_magazine()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(discarded)

/// Разбор компьютера клал плату в новый фрейм, но вычёркивал её из
/// component_parts ПОСЛЕ обнуления circuit, то есть вычитал null. Плата
/// оставалась в component_parts и уезжала в qdel вместе с машиной - фрейм
/// держал удалённую плату, а ломик рантаймил "doMove qdel-нутого
/// /obj/item/circuitboard/computer/rdconsole/production" (раунд 9827).
/datum/unit_test/computer_deconstruct_hands_over_circuit
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/computer_deconstruct_hands_over_circuit/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, floor)
	var/obj/machinery/computer/rdconsole/production/console = allocate(/obj/machinery/computer/rdconsole/production, floor)
	TEST_ASSERT_NOTNULL(console.circuit, "Консоль собралась без платы")
	TEST_ASSERT(console.circuit in console.component_parts, "Плата не числится в component_parts - тест проверяет не тот путь")

	var/obj/item/circuitboard/board = console.circuit
	console.deconstruct(TRUE, user)

	TEST_ASSERT(!QDELETED(board), "Разбор компьютера удалил плату вместе с машиной")
	var/obj/structure/frame/computer/frame = locate(/obj/structure/frame/computer) in floor
	TEST_ASSERT_NOTNULL(frame, "Разбор компьютера не оставил фрейм")
	TEST_ASSERT_EQUAL(frame.circuit, board, "Фрейм получил не ту плату")
	TEST_ASSERT_EQUAL(board.loc, frame, "Плата лежит не во фрейме")

	// Снятие ломиком - ровно тот путь, который рантаймил в проде. Разбор оставляет
	// фрейм на стадии 4 (снят монитор), а плату отдаёт ломик на стадии 1; крутить
	// весь разбор ради этого незачем, стадия - обычный вар.
	frame.state = 1
	var/obj/item/crowbar/tool = allocate(/obj/item/crowbar, floor)
	frame.attackby(tool, user, null)
	TEST_ASSERT(!QDELETED(board), "Снятие платы ломиком добралось до удалённой платы")
	TEST_ASSERT_NULL(frame.circuit, "Ломик не вынул плату из фрейма")
	TEST_ASSERT_EQUAL(board.loc, floor, "Вынутая плата не легла на пол")

/// Заклинание Hallucinations и его proc_holder ссылались друг на друга и
/// разрывали связь QDEL_NULL'ом по локальной копии - поля PH/attached_action
/// оставались забиты удалённым партнёром. Раунд 9827: в warnfail ушли обе
/// пары /obj/effect/proc_holder/horror + /datum/action/innate/cult/blood_spell/horror,
/// по одной внешней ссылке; REF SEARCH назвал вар PH.
/datum/unit_test/cult_horror_spell_releases_proc_holder
	parent_type = /datum/unit_test/harddel_9827_base

/// Сносим заклинание - proc_holder обязан уйти вместе с ним и не остаться в поле.
/datum/unit_test/cult_horror_spell_releases_proc_holder/proc/spell_first()
	var/datum/action/innate/cult/blood_spell/horror/spell = new
	var/obj/effect/proc_holder/horror/holder = spell.PH
	TEST_ASSERT_NOTNULL(holder, "Заклинание завелось без proc_holder")

	var/list/record = target_record(holder, "proc_holder заклинания Hallucinations")
	qdel(spell)
	TEST_ASSERT_NULL(spell.PH, "Заклинание удержало удалённый proc_holder")
	TEST_ASSERT_NULL(holder.attached_action, "proc_holder удержал удалённое заклинание")
	return record

/// Обратный порядок: сносим proc_holder, заклинание обязано уйти следом.
/datum/unit_test/cult_horror_spell_releases_proc_holder/proc/holder_first()
	var/datum/action/innate/cult/blood_spell/horror/spell = new
	var/obj/effect/proc_holder/horror/holder = spell.PH

	var/list/record = target_record(spell, "заклинание Hallucinations")
	qdel(holder)
	TEST_ASSERT(QDELETED(spell), "Удаление proc_holder не утащило заклинание")
	TEST_ASSERT_NULL(spell.PH, "Заклинание удержало удалённый proc_holder")
	TEST_ASSERT_NULL(holder.attached_action, "proc_holder удержал удалённое заклинание")
	return record

/datum/unit_test/cult_horror_spell_releases_proc_holder/Run()
	begin_isolated_gc()
	var/list/holder_record = spell_first()
	var/list/spell_record = holder_first()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(holder_record)
	assert_soft_collected(spell_record)

/// Печать брига складывала распечатки в GLOB.cell_logs, который никто никогда
/// не читал: список молча держал до 500 бумаг, и любая уничтоженная распечатка
/// уходила в hard delete. Раунд 9827: 20 warnfail /obj/item/paper "PermaBrig log"
/// подряд, по одной внешней ссылке.
/datum/unit_test/brig_report_does_not_retain_paper
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/brig_report_does_not_retain_paper/Run()
	begin_isolated_gc()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/machinery/computer/prisoner/management/console = allocate(/obj/machinery/computer/prisoner/management, floor)
	TEST_ASSERT(console in GLOB.prisoncomputer_list, "Консоль заключённых не встала в глобальный список")

	var/obj/structure/closet/secure_closet/genpop/locker = allocate(/obj/structure/closet/secure_closet/genpop, floor)
	locker.prisoner_name = "Test Prisoner"
	locker.crimes = "unit testing"
	locker.print_report()

	var/obj/item/paper/report = locate(/obj/item/paper) in floor
	TEST_ASSERT_NOTNULL(report, "Печать отчёта не выдала бумагу")

	var/list/record = target_record(report, "распечатка брига")
	qdel(report)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// Лоадаутные нормалайзеры писали владельца жёсткой ссылкой и держали тело до
/// конца раунда: предмет живёт дольше носителя (шкафчик, чужой рюкзак, пол).
/// Раунд 9827: REF SEARCH нашёл /mob/living/carbon/human в
/// /obj/item/clothing/neck/syntech/collar, вар owner - hard delete тела.
/datum/unit_test/syntech_normalizer_does_not_pin_owner
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/syntech_normalizer_does_not_pin_owner/Run()
	begin_isolated_gc()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/wearer = new(floor)
	var/obj/item/clothing/neck/syntech/collar/collar = allocate(/obj/item/clothing/neck/syntech/collar, floor)

	var/datum/gear/neck/syntech/collar/gear = new
	gear.on_spawn(wearer, collar)
	TEST_ASSERT_NOTNULL(collar.owner_ref, "Лоадаут не записал владельца ошейника")
	TEST_ASSERT_EQUAL(collar.owner_ref.resolve(), wearer, "Слабая ссылка не разрешается во владельца")

	var/list/record = target_record(wearer, "владелец нормалайзера")
	qdel(wearer)
	wearer = null
	TEST_ASSERT_NULL(collar.owner_ref.resolve(), "Ошейник всё ещё разрешает ссылку на удалённое тело")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// clockcult/admin_add заводит собственный датум через add_servant_of_ratvar, а
/// заготовку из add_antag_wrapper бросает без владельца. Уборка этой заготовки
/// штатная, но Destroy ругался stack_trace'ом "Destroy()ing antagonist datum
/// when it has no owner." - раунд 9827 поймал его трижды за смену.
/datum/unit_test/discarded_antag_datum_stays_quiet
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/discarded_antag_datum_stays_quiet/Run()
	var/datum/antagonist/orphan = new /datum/antagonist/clockcult
	TEST_ASSERT_NULL(orphan.owner, "Свежая заготовка антага уже с владельцем")
	TEST_ASSERT(!orphan.discarded_before_gain, "Флаг штатной уборки взведён до самой уборки")

	orphan.discarded_before_gain = TRUE
	qdel(orphan)
	TEST_ASSERT(QDELETED(orphan), "Заготовка антага пережила qdel")

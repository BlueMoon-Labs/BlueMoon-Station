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

/// Отрезанная голова хранит мозг, мозгомоба и глаза жёсткими ссылками, а своего
/// Destroy у /obj/item/bodypart/head не было вовсе: qdel уводил содержимое головы
/// в qdel штатным contents-циклом /atom/movable/Destroy, но три поля оставались
/// забиты покойниками. Раунд 9827: одна голова тянула цепочку из трёх хардделов.
/datum/unit_test/severed_head_releases_brain_chain
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/severed_head_releases_brain_chain/Run()
	begin_isolated_gc()
	var/turf/floor = run_loc_floor_bottom_left
	//mind обязателен: без него transfer_identity не заводит мозгомоба
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, floor)
	patient.mind_initialize()

	var/obj/item/bodypart/head/head = patient.get_bodypart(BODY_ZONE_HEAD)
	TEST_ASSERT_NOTNULL(head, "У человека нет головы")
	head.drop_limb()

	TEST_ASSERT_NOTNULL(head.brain, "Отрезанная голова осталась без мозга")
	TEST_ASSERT_NOTNULL(head.eyes, "Отрезанная голова осталась без глаз")
	TEST_ASSERT_NOTNULL(head.brainmob, "Отрезанная голова осталась без мозгомоба")

	//mind держит мозгомоба своим current, а мозгомоб держит mind - это отдельная
	//двусторонняя связь, к утечке головы отношения не имеющая
	var/mob/living/brain/brainmob = head.brainmob
	var/datum/mind/stored_mind = brainmob.mind
	if(stored_mind)
		stored_mind.set_current(null)
		brainmob.mind = null

	var/list/brain_record = target_record(head.brain, "мозг из отрезанной головы")
	var/list/eyes_record = target_record(head.eyes, "глаза из отрезанной головы")
	var/list/brainmob_record = target_record(brainmob, "мозгомоб из отрезанной головы")
	brainmob = null
	stored_mind = null

	qdel(head)
	TEST_ASSERT_NULL(head.brain, "Голова удержала удалённый мозг")
	TEST_ASSERT_NULL(head.eyes, "Голова удержала удалённые глаза")
	TEST_ASSERT_NULL(head.brainmob, "Голова удержала удалённого мозгомоба")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(brain_record)
	assert_soft_collected(eyes_record)
	assert_soft_collected(brainmob_record)

/// Консоль голодека дерезит убежавшего питомца сама и спавнеру об этом не
/// сообщает, а спавнер живёт до смены программы. Раунд 9827: REF SEARCH назвал
/// держателя прямо - /obj/effect/holodeck_effect/mobspawner/pet, вар mob (6 хардделов).
/datum/unit_test/holodeck_spawner_releases_derezzed_pet
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/holodeck_spawner_releases_derezzed_pet/Run()
	begin_isolated_gc()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/effect/holodeck_effect/mobspawner/pet/spawner = allocate(/obj/effect/holodeck_effect/mobspawner/pet, floor)
	//список из одного типа: ветка с pick() отрабатывает, но питомец детерминирован
	spawner.mobtype = list(/mob/living/simple_animal/butterfly)

	//activate() аргумент консоли не использует, поэтому реальный голодек не нужен
	var/mob/pet = spawner.activate(null)
	TEST_ASSERT_NOTNULL(pet, "Спавнер голодека не создал питомца")
	TEST_ASSERT_NOTNULL(spawner.mob_ref, "Спавнер не запомнил созданного питомца")
	TEST_ASSERT_EQUAL(spawner.mob_ref.resolve(), pet, "Слабая ссылка спавнера разрешается не в питомца")

	var/list/record = target_record(pet, "питомец голодека, дерезнутый консолью")
	qdel(pet)
	pet = null
	TEST_ASSERT_NULL(spawner.mob_ref.resolve(), "Спавнер всё ещё разрешает ссылку на удалённого питомца")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// Кнопка антаг-инфо висит на теле и по clear_ref сносит себя сама, но
/// антаг-датуму об этом не сообщала, а его Destroy кнопку не трогал (обнуление
/// было только в on_removal). Раунд 9827: 3 харддела /datum/action/antag_info.
/datum/unit_test/antag_info_button_two_way_release
	parent_type = /datum/unit_test/harddel_9827_base

/// Тело первым: кнопка сносит себя по clear_ref и обязана отвязаться от датума.
/datum/unit_test/antag_info_button_two_way_release/proc/body_first()
	var/mob/living/carbon/human/body = new(run_loc_floor_bottom_left)
	var/datum/antagonist/orphan = new /datum/antagonist/clockcult
	orphan.discarded_before_gain = TRUE
	orphan.info_button = new(body, orphan)

	var/datum/action/antag_info/button = orphan.info_button
	TEST_ASSERT_EQUAL(button.target, body, "Кнопка не привязалась к телу")
	TEST_ASSERT_EQUAL(button.antag_datum, orphan, "Кнопка не запомнила свой антаг-датум")

	var/list/record = target_record(button, "кнопка антаг-инфо после удаления тела")
	qdel(body)
	TEST_ASSERT(QDELETED(button), "Удаление тела не снесло кнопку антаг-инфо")
	TEST_ASSERT_NULL(orphan.info_button, "Антаг-датум удержал удалённую кнопку")

	button = null
	qdel(orphan)
	return record

/// Датум первым: его Destroy обязан унести кнопку с собой.
/datum/unit_test/antag_info_button_two_way_release/proc/datum_first()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/antagonist/orphan = new /datum/antagonist/clockcult
	orphan.discarded_before_gain = TRUE
	orphan.info_button = new(body, orphan)

	var/datum/action/antag_info/button = orphan.info_button
	var/list/record = target_record(button, "кнопка антаг-инфо после удаления датума")
	qdel(orphan)
	TEST_ASSERT(QDELETED(button), "Удаление антаг-датума не снесло кнопку")
	TEST_ASSERT_NULL(button.antag_datum, "Кнопка удержала удалённый антаг-датум")

	button = null
	return record

/datum/unit_test/antag_info_button_two_way_release/Run()
	begin_isolated_gc()
	var/list/from_body = body_first()
	var/list/from_datum = datum_first()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(from_body)
	assert_soft_collected(from_datum)

/// Крио-путь: /obj/item/doMove зовёт dropped() только когда предмет был В РУКАХ,
/// а cryoMob уносит НАДЕТЫЕ вещи forceMove'ом в под, потом в коробку, а коробка
/// живёт в control_computer.stored_packages до конца смены. Значит любая вещь,
/// которая пишет носителя в equipped() и отпускает только в dropped(), держит
/// тело весь раунд. Раунд 9827: все 18 несобранных /mob/living/carbon/human
/// прошли через cryoMob(), ни одного гиба.
/datum/unit_test/cryo_path_releases_wearer
	parent_type = /datum/unit_test/harddel_9827_base

/// МОД: unset_wearer звали только из equipped/dropped, в Destroy его не было вовсе.
/datum/unit_test/cryo_path_releases_wearer/proc/modsuit()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/wearer = new(floor)
	var/obj/item/mod/control/suit = new /obj/item/mod/control/pre_equipped/standard(floor)
	var/obj/item/storage/box/package = new(floor)

	suit.forceMove(wearer)
	suit.equipped(wearer, ITEM_SLOT_BACK)
	TEST_ASSERT_EQUAL(suit.wearer, wearer, "МОД не запомнил носителя при надевании")

	//ровно то, что делает cryoMob: перенос без dropped()
	suit.forceMove(package)
	TEST_ASSERT_EQUAL(suit.wearer, wearer, "forceMove неожиданно позвал dropped() - сценарий крио не воспроизведён")

	var/list/record = target_record(wearer, "носитель МОДа, ушедший в крио")
	qdel(wearer)
	wearer = null
	TEST_ASSERT_NULL(suit.wearer, "МОД удержал удалённого носителя")
	return record

/// ХардСпейс-трусики: owner отпускался только через on_unequip из dropped().
/datum/unit_test/cryo_path_releases_wearer/proc/hardspace_panties()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/clothing/underwear/briefs/hardspace_panties/panties = new(floor)
	var/mob/living/carbon/human/wearer = new(floor)
	var/obj/item/storage/box/package = new(floor)

	panties.forceMove(wearer)
	panties.equipped(wearer, ITEM_SLOT_UNDERWEAR)
	TEST_ASSERT_EQUAL(panties.owner, wearer, "Трусики не запомнили носителя")

	panties.forceMove(package)
	var/list/record = target_record(wearer, "носитель ХардСпейс-трусиков, ушедший в крио")
	qdel(wearer)
	wearer = null
	TEST_ASSERT_NULL(panties.owner, "Трусики удержали удалённого носителя")
	return record

/// ХардСпейс-бра: тот же паттерн, слот рубашки.
/datum/unit_test/cryo_path_releases_wearer/proc/hardspace_bra()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/clothing/underwear/shirt/bra/bra_adjustable/hardspace_bra/bra = new(floor)
	var/mob/living/carbon/human/wearer = new(floor)
	var/obj/item/storage/box/package = new(floor)

	bra.forceMove(wearer)
	bra.equipped(wearer, ITEM_SLOT_SHIRT)
	TEST_ASSERT_EQUAL(bra.owner, wearer, "Бра не запомнило носителя")

	bra.forceMove(package)
	var/list/record = target_record(wearer, "носитель ХардСпейс-бра, ушедший в крио")
	qdel(wearer)
	wearer = null
	TEST_ASSERT_NULL(bra.owner, "Бра удержало удалённого носителя")
	return record

/// ХардСпейс-маска: тот же паттерн, слот маски.
/datum/unit_test/cryo_path_releases_wearer/proc/hardspace_mask()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/clothing/mask/hardspace_mask/mask = new(floor)
	var/mob/living/carbon/human/wearer = new(floor)
	var/obj/item/storage/box/package = new(floor)

	mask.forceMove(wearer)
	mask.equipped(wearer, ITEM_SLOT_MASK)
	TEST_ASSERT_EQUAL(mask.owner, wearer, "Маска не запомнила носителя")

	mask.forceMove(package)
	var/list/record = target_record(wearer, "носитель ХардСпейс-маски, ушедший в крио")
	qdel(wearer)
	wearer = null
	TEST_ASSERT_NULL(mask.owner, "Маска удержала удалённого носителя")
	return record

/// Гипно-очки: victim не обнулялся даже в Destroy.
/datum/unit_test/cryo_path_releases_wearer/proc/hypnogoggles()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/clothing/glasses/hypno/goggles = new(floor)
	var/mob/living/carbon/human/wearer = new(floor)
	var/obj/item/storage/box/package = new(floor)

	goggles.forceMove(wearer)
	goggles.equipped(wearer, ITEM_SLOT_EYES)
	TEST_ASSERT_EQUAL(goggles.victim, wearer, "Очки не запомнили носителя")

	goggles.forceMove(package)
	var/list/record = target_record(wearer, "носитель гипно-очков, ушедший в крио")
	qdel(wearer)
	wearer = null
	TEST_ASSERT_NULL(goggles.victim, "Очки удержали удалённого носителя")
	return record

/datum/unit_test/cryo_path_releases_wearer/Run()
	begin_isolated_gc()
	var/list/records = list(
		modsuit(),
		hardspace_panties(),
		hardspace_bra(),
		hardspace_mask(),
		hypnogoggles(),
	)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	for(var/list/record as anything in records)
		assert_soft_collected(record)

/// Кастомизируемая еда удаляла ингредиенты циклом, но сам список не чистила:
/// ingredients оставался единственным держателем уже удалённых кусков.
/datum/unit_test/customizable_food_releases_ingredients
	parent_type = /datum/unit_test/harddel_9827_base

/datum/unit_test/customizable_food_releases_ingredients/Run()
	begin_isolated_gc()
	var/obj/item/reagent_containers/food/snacks/customizable/burger/burger = new(run_loc_floor_bottom_left)
	var/obj/item/reagent_containers/food/snacks/cheesewedge/filling = new(burger)
	burger.ingredients += filling
	TEST_ASSERT(filling in burger.ingredients, "Ингредиент не попал в список бургера")

	var/list/record = target_record(filling, "ингредиент кастомизируемой еды")
	filling = null
	qdel(burger)
	TEST_ASSERT(!length(burger.ingredients), "Список ингредиентов остался с трупами внутри")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// SStgui.on_close считал ключ как "[REF(ui.src_object)]" и при промахе выходил
/// return FALSE ДО чистки, а close() сразу делал qdel(src). Оставались три
/// висячие ссылки, две из них во вложенных списках - поэтому реф-сканер молчал.
/datum/unit_test/sstgui_unregisters_closed_interface
	parent_type = /datum/unit_test/harddel_9827_base

/// Штатное закрытие: запись обязана уйти из всех трёх списков.
/datum/unit_test/sstgui_unregisters_closed_interface/proc/normal_close()
	var/mob/user = new
	var/obj/item/source = allocate(/obj/item)
	var/datum/tgui/ui = new(user, source, "UnitTest")
	SStgui.on_open(ui)
	TEST_ASSERT(ui in SStgui.open_uis, "Интерфейс не встал в open_uis")
	TEST_ASSERT(ui in user.tgui_open_uis, "Интерфейс не встал в user.tgui_open_uis")
	TEST_ASSERT_NOTNULL(SStgui.open_uis_by_src["[REF(source)]"], "Интерфейс не встал в open_uis_by_src")

	SStgui.on_close(ui)
	TEST_ASSERT(!(ui in SStgui.open_uis), "open_uis удержал закрытый интерфейс")
	TEST_ASSERT(!(ui in user.tgui_open_uis), "user.tgui_open_uis удержал закрытый интерфейс")
	TEST_ASSERT_NULL(SStgui.open_uis_by_src["[REF(source)]"], "open_uis_by_src удержал закрытый интерфейс")

	qdel(ui)
	qdel(user)

/// Тот же путь, но src_object уже обнулён - ровно то состояние, в котором
/// интерфейс приходил в on_close из fire() и из /datum/tgui/Destroy.
/datum/unit_test/sstgui_unregisters_closed_interface/proc/close_without_src_object()
	var/mob/user = new
	var/obj/item/source = allocate(/obj/item)
	var/datum/tgui/ui = new(user, source, "UnitTest")
	SStgui.on_open(ui)
	ui.src_object = null

	SStgui.on_close(ui)
	TEST_ASSERT(!(ui in SStgui.open_uis), "open_uis удержал интерфейс без src_object")
	TEST_ASSERT(!(ui in user.tgui_open_uis), "user.tgui_open_uis удержал интерфейс без src_object")
	TEST_ASSERT_NULL(SStgui.open_uis_by_src["[REF(source)]"], "open_uis_by_src удержал интерфейс без src_object")

	qdel(ui)
	qdel(user)

/// qdel интерфейса мимо close(): Destroy обязан снять его с учёта сам.
/datum/unit_test/sstgui_unregisters_closed_interface/proc/destroy_without_close()
	var/mob/user = new
	var/obj/item/source = allocate(/obj/item)
	var/datum/tgui/ui = new(user, source, "UnitTest")
	SStgui.on_open(ui)

	qdel(ui)
	TEST_ASSERT(!(ui in SStgui.open_uis), "open_uis удержал удалённый интерфейс")
	TEST_ASSERT(!(ui in user.tgui_open_uis), "user.tgui_open_uis удержал удалённый интерфейс")
	TEST_ASSERT_NULL(SStgui.open_uis_by_src["[REF(source)]"], "open_uis_by_src удержал удалённый интерфейс")

	qdel(user)

/datum/unit_test/sstgui_unregisters_closed_interface/Run()
	normal_close()
	close_without_src_object()
	destroy_without_close()

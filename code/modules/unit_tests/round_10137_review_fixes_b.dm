// Ревью-правки по разбору раунда 10137, вторая партия: психоз без зрителя, окно повтора
// у экрана интегральной схемы, страховка флага заливки трека. Тесты названы по симптому,
// а не по механизму.

/// Счётчик попыток создать тестовую галлюцинацию психоза.
GLOBAL_VAR_INIT(psychosis_probe_spawns, 0)

/**
 * Тестовая галлюцинация психоза: считает попытки создания и ничего не показывает.
 *
 * В GLOB.psychosis_hallucination_list не входит, поэтому в живой пул не попадает - тест
 * подкладывает её в GLOB.psychosis_pool_by_tier руками. abstract_hallucination_parent
 * указывает на себя, чтобы тип не всплыл в админском списке выбора галлюцинаций.
 */
/datum/hallucination/psychosis/psychosis_gate_probe
	abstract_hallucination_parent = /datum/hallucination/psychosis/psychosis_gate_probe

/datum/hallucination/psychosis/psychosis_gate_probe/New(mob/living/carbon/C, forced = TRUE)
	GLOB.psychosis_probe_spawns++
	..()
	if(QDELETED(src)) // Родитель отменил галлюцинацию: показывать её некому
		return
	qdel(src)

/**
 * Ни один подтип психоза не должен переживать отмену от родителя.
 *
 * /datum/hallucination/New() помечает датум на удаление, когда у цели нет клиента: показывать
 * галлюцинацию некому. Оборвать конструктор подтипа из родителя в DM нечем, поэтому КАЖДЫЙ
 * подтип обязан сам свериться с QDELETED(src) сразу после ..(). Подтип без этой сверки
 * продолжает работать с target == null: null.overlay_fullscreen, view(3, null) с падением на
 * usr, stack_trace в /obj/effect/hallucination/simple/Initialize и второй qdel поверх первого.
 * В раунде 10137 SSD-игрок с психозом ловил такой цикл каждый тик статус-эффекта.
 *
 * Перебором подтипов, а не списком: пул психоза пополняется десятками типов за правку, и
 * тест на фиксированном перечне пропустил бы ровно тот, который добавят завтра.
 */
/datum/unit_test/psychosis_hallucination_needs_client
	requires_full_map = FALSE

/datum/unit_test/psychosis_hallucination_needs_client/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(patient.client, "предпосылка: у тестового моба не должно быть клиента")

	var/list/subtypes = subtypesof(/datum/hallucination/psychosis)
	var/list/survivors = list()
	for(var/hallucination_type as anything in subtypes)
		var/datum/hallucination/instance = new hallucination_type(patient, TRUE)
		if(QDELETED(instance))
			continue
		survivors += "[hallucination_type]"
		qdel(instance)

	TEST_ASSERT(length(subtypes) > 10, "предпосылка: подтипов психоза должно быть много, найдено [length(subtypes)]")
	TEST_ASSERT(!length(survivors), "подтипы психоза не сверились с QDELETED(src) после ..() и работали с target == null: [survivors.Join(", ")]")

/**
 * tick() психоза не должен заводить галлюцинацию мобу без клиента.
 *
 * Гард в подтипах спасает от рантаймов, но не от работы: без проверки в тике SSD-игрок с
 * психозом раз в 4 секунды платил созданием датума, его отменой и строкой в investigate-логе
 * за то, что никто не увидит. Массовая галлюцинация в 10137 так отработала сотню раз подряд
 * по обезьянам.
 */
/datum/unit_test/psychosis_tick_skips_clientless_owner
	requires_full_map = FALSE
	/// Снимок GLOB.psychosis_pool_by_tier: тест подменяет живой пул своим.
	var/list/saved_pools
	var/pools_swapped = FALSE

/datum/unit_test/psychosis_tick_skips_clientless_owner/Destroy()
	// Уборка в Destroy(), а не в хвосте Run(): провалившийся TEST_ASSERT выходит из Run()
	// немедленно, и подменённый на весь раунд пул утёк бы в соседние тесты.
	if(pools_swapped)
		GLOB.psychosis_pool_by_tier = saved_pools
	return ..()

/datum/unit_test/psychosis_tick_skips_clientless_owner/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(patient.client, "предпосылка: у тестового моба не должно быть клиента")

	var/datum/status_effect/psychosis/effect = patient.apply_status_effect(/datum/status_effect/psychosis)
	TEST_ASSERT_NOTNULL(effect, "предпосылка: психоз обязан вставать на карбона")

	saved_pools = GLOB.psychosis_pool_by_tier
	pools_swapped = TRUE
	GLOB.psychosis_pool_by_tier = list(list(/datum/hallucination/psychosis/psychosis_gate_probe = 1), list(), list())
	effect.forced_event_chance = 100

	// Контроль: подложенный пул рабочий и выбирать статус-эффекту есть из чего. Без него
	// ноль ниже был бы неотличим от пустого пула.
	var/picked = effect.pick_hallucination()

	GLOB.psychosis_probe_spawns = 0
	for(var/i in 1 to 5)
		effect.tick()
	var/spawns_without_client = GLOB.psychosis_probe_spawns

	// Второй контроль: сам тип считается. Прямое создание мимо гейта обязано двинуть счётчик.
	var/datum/hallucination/probe = new /datum/hallucination/psychosis/psychosis_gate_probe(patient, TRUE)
	var/spawns_direct = GLOB.psychosis_probe_spawns
	qdel(probe)

	TEST_ASSERT_EQUAL(picked, /datum/hallucination/psychosis/psychosis_gate_probe, "подложенный пул не отдал тестовый тип, получено [picked]")
	TEST_ASSERT_EQUAL(spawns_direct, 1, "тестовая галлюцинация не считает собственные создания")
	TEST_ASSERT_EQUAL(spawns_without_client, 0, "tick() психоза завёл галлюцинацию мобу без клиента [spawns_without_client] раз")

/**
 * Экран интегральной схемы обязан повторить ту же тревогу после окна молчания.
 *
 * Дедуп по значению без окна глушил повторяющееся сообщение до конца раунда: датчик движения,
 * подающий на экран "INTRUDER", звучал ровно один раз - на всех следующих нарушителях строка
 * не менялась и молча съедалась. Само окно при этом обязано держать самопульс: сборка дёргает
 * do_work() по нескольку раз в секунду, и в раунде 10137 одна такая написала 1520 строк в
 * circuit.html с неизменным значением.
 */
/datum/unit_test/circuit_screen_repeats_alert_after_window
	requires_full_map = FALSE

/datum/unit_test/circuit_screen_repeats_alert_after_window/Run()
	var/obj/item/integrated_circuit/output/screen/large/screen = allocate(/obj/item/integrated_circuit/output/screen/large)
	screen.stuff_to_display = "INTRUDER"

	var/first_alert = screen.display_changed()
	var/immediate_repeat = screen.display_changed()

	// Окно прошло: та же строка снова становится событием, а не шумом.
	screen.last_broadcast_time -= SCREEN_REBROADCAST_WINDOW + 1
	var/repeat_after_window = screen.display_changed()
	var/repeat_rearms_window = screen.display_changed()

	// Смена значения звучит всегда, окно её не задерживает.
	screen.stuff_to_display = "ALL CLEAR"
	var/changed_value = screen.display_changed()

	TEST_ASSERT(first_alert, "первая тревога обязана прозвучать")
	TEST_ASSERT(!immediate_repeat, "повтор в пределах окна - это самопульс, его обязаны глушить")
	TEST_ASSERT(repeat_after_window, "повторяющаяся тревога после окна обязана прозвучать заново")
	TEST_ASSERT(!repeat_rearms_window, "после повтора окно обязано взвестись заново")
	TEST_ASSERT(changed_value, "смена показанного значения обязана звучать немедленно")

/**
 * Флаг "у игрока открыт диалог заливки трека" обязан сниматься страховкой.
 *
 * Рантайм внутри do_upload_file() или разрыв связи с открытым нативным input() не возвращают
 * управление в upload_file(), и штатное снятие флага не выполняется. Без страховочного таймера
 * ckey оставался помеченным до конца раунда: кнопка заливки просто переставала работать, и ни
 * одна причина отказа об этом не говорила.
 */
/datum/unit_test/personal_music_box_upload_lock_clears
	requires_full_map = FALSE

/datum/unit_test/personal_music_box_upload_lock_clears/Run()
	var/fake_ckey = "unittestmusicboxckey"
	TEST_ASSERT_NULL(GLOB.personal_music_boxes_uploading[fake_ckey], "предпосылка: тестовый ckey не должен быть помечен заранее")

	GLOB.personal_music_boxes_uploading[fake_ckey] = TRUE
	var/lock_taken = GLOB.personal_music_boxes_uploading[fake_ckey]
	clear_personal_music_box_upload_lock(fake_ckey)
	var/lock_released = isnull(GLOB.personal_music_boxes_uploading[fake_ckey])

	// Пустой ckey не должен ни падать, ни чистить чужие записи: таймер переживает и моба,
	// и шкатулку, и на момент срабатывания аргумент может оказаться каким угодно.
	GLOB.personal_music_boxes_uploading[fake_ckey] = TRUE
	clear_personal_music_box_upload_lock(null)
	var/foreign_lock_survived = GLOB.personal_music_boxes_uploading[fake_ckey]
	GLOB.personal_music_boxes_uploading -= fake_ckey

	TEST_ASSERT(lock_taken, "предпосылка: флаг заливки обязан выставляться")
	TEST_ASSERT(lock_released, "страховка обязана снимать залипший флаг заливки")
	TEST_ASSERT(foreign_lock_survived, "снятие флага без ckey не должно чистить чужие записи")

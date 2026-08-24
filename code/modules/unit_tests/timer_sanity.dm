/datum/unit_test/timer_sanity/Run()
	TEST_ASSERT(SStimer.bucket_count >= 0,
		"SStimer is going into negative bucket count from something")

/// Сколько тиков даём планировщику на то, чтобы он успел ошибиться.
#define LONG_TIMER_GRACE_TICKS 5

/**
 * Таймеры длиннее одного оборота колеса бакетов (BUCKET_LEN - ровно минута) в бакеты не
 * влезают и ждут своей очереди в second_queue. Старая арифметика TIMER_MAX/BUCKET_POS
 * впускала такой таймер в бакет ПОЗАДИ курсора, и он срабатывал тем же проходом.
 *
 * Наружу это вылезало так: tgui_alert с таймаутом от минуты закрывался сам собой, а бонус
 * к операциям от стерилизина (ровно 600 децисекунд, то есть впритык к границе колеса) гас
 * раньше, чем хирург успевал сделать шаг - без бонуса и без зелёной строки на сканере.
 */
/datum/unit_test/long_timers_do_not_fire_early
	var/fired = FALSE

/datum/unit_test/long_timers_do_not_fire_early/proc/mark_fired()
	fired = TRUE

/datum/unit_test/long_timers_do_not_fire_early/Run()
	var/timer_id = addtimer(CALLBACK(src, PROC_REF(mark_fired)), 2 MINUTES, TIMER_STOPPABLE)
	TEST_ASSERT_NOTNULL(timer_id, "Премиса: остановимый таймер обязан вернуть id")

	var/datum/timedevent/scheduled = SStimer.timer_id_dict[timer_id]
	TEST_ASSERT_NOTNULL(scheduled, "Премиса: остановимый таймер обязан попасть в timer_id_dict")
	TEST_ASSERT(scheduled.timeToRun > world.time + 1 MINUTES, "Таймер на две минуты назначен раньше, чем через минуту")

	for(var/grace_tick in 1 to LONG_TIMER_GRACE_TICKS)
		stoplag(1)

	TEST_ASSERT(!fired, "Таймер на две минуты сработал в первые тики: длинные таймеры снова садятся в бакет позади курсора")
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[timer_id], "Таймер на две минуты исчез из очереди, не отработав")

	deltimer(timer_id)

///Замер границы колеса бакетов: какие сроки переживают первые тики, а какие нет.
///BUCKET_LEN - ровно минута, и таймеры ВОКРУГ этой границы - самый подозрительный участок:
///на 600 децисекунд заводится и бонус стерилизина, и tgui_alert с таймаутом в минуту.
/datum/unit_test/timer_boundary_probe
	var/list/fired = list()

/datum/unit_test/timer_boundary_probe/proc/mark_fired(label)
	fired[label] = TRUE

/datum/unit_test/timer_boundary_probe/Run()
	var/list/probes = list("50s" = 50 SECONDS, "59s" = 59 SECONDS, "60s" = 1 MINUTES, "61s" = 61 SECONDS, "120s" = 2 MINUTES)
	var/list/armed = list()
	for(var/label in probes)
		armed[label] = addtimer(CALLBACK(src, PROC_REF(mark_fired), label), probes[label], TIMER_STOPPABLE)

	for(var/grace_tick in 1 to LONG_TIMER_GRACE_TICKS)
		stoplag(1)

	var/list/premature = list()
	for(var/label in probes)
		if(fired[label])
			premature += label
		else
			deltimer(armed[label])

	TEST_ASSERT(!length(premature), "Сработали раньше срока: [premature.Join(", ")] (из проверенных [probes.len])")

/**
 * bucketJoin() больше не собирает отладочное имя на каждый созданный таймер - описание
 * строит get_timer_debug_string() по требованию, из живых полей. Тест сторожит вторую
 * половину сделки: описание обязано остаться читаемым, иначе диагностика "Invalid timer
 * state" превратится в тыкву ровно тогда, когда она понадобится.
 */
/datum/unit_test/timer_debug_string_is_lazy

/datum/unit_test/timer_debug_string_is_lazy/proc/never_runs()
	return

/datum/unit_test/timer_debug_string_is_lazy/Run()
	TEST_ASSERT_EQUAL(SStimer.get_timer_debug_string(null), "Timer: NULL", "Описание пустого таймера обязано быть безопасным")

	var/timer_id = addtimer(CALLBACK(src, PROC_REF(never_runs)), 30 SECONDS, TIMER_STOPPABLE)
	var/datum/timedevent/scheduled = SStimer.timer_id_dict[timer_id]
	TEST_ASSERT_NOTNULL(scheduled, "Премиса: остановимый таймер обязан попасть в timer_id_dict")

	var/described = SStimer.get_timer_debug_string(scheduled)
	TEST_ASSERT(findtext(described, "wait:[scheduled.wait]"), "Описание таймера потеряло wait: [described]")
	TEST_ASSERT(findtext(described, "TTR: [scheduled.timeToRun]"), "Описание таймера потеряло время срабатывания: [described]")
	TEST_ASSERT(findtext(described, "never_runs"), "Описание таймера потеряло колбек - по нему и опознают виновника: [described]")

	deltimer(timer_id)

/**
 * Учёт населения колеса: сколько таймеров положили, столько же обязано и уйти.
 *
 * Позиция в бакете теперь ЗАПИСЫВАЕТСЯ при вставке, а не пересчитывается при выбросе.
 * Пересчёт был неверен by design: BUCKET_POS считается от head_offset, а head_offset прыгает
 * вперёд на целое колесо каждый оборот, тогда как таймер остаётся лежать в своём слоте.
 * Расхождение раньше затыкалось сканом bucket_list.Find(src) по всем 1200 слотам, и когда
 * скан не находил ничего, bucket_count перекашивался в плюс - навсегда, до конца раунда.
 *
 * Тест держит обе половины: и что счётчик возвращается ровно к исходному, и что слот в
 * колесе за удалённым таймером не остаётся (иначе следующий проход найдёт в голове бакета
 * таймер без колбека - то самое "Invalid timer", на котором колесо пересобирается целиком).
 */
/datum/unit_test/timer_bucket_accounting
	/// Сколько таймеров ставим. Заметно больше одного бакета, чтобы были и головы, и хвосты.
	var/probe_count = 50

/datum/unit_test/timer_bucket_accounting/proc/never_runs()
	return

/datum/unit_test/timer_bucket_accounting/Run()
	// Ни одного сна до конца проверки: мир однопоточный, значит между этими строками никто
	// другой таймеров не заведёт и не спустит, и арифметика по bucket_count честная.
	var/baseline = SStimer.bucket_count

	var/list/armed = list()
	for(var/probe in 1 to probe_count)
		// Сроки внутри окна колеса (минута), иначе таймер уедет в second_queue мимо бакетов.
		// Шаг в полсекунды разносит таймеры по РАЗНЫМ бакетам: тик короче децисекунды, и
		// каждый из них становится головой своего слота. Общий бакет и снятие не-головы
		// проверяет timer_shared_bucket_eject ниже, здесь считается только население колеса.
		armed += addtimer(CALLBACK(src, PROC_REF(never_runs)), (probe * 0.5) SECONDS, TIMER_STOPPABLE)

	TEST_ASSERT_EQUAL(SStimer.bucket_count, baseline + probe_count,
		"В колесо легло не столько таймеров, сколько поставили: было [baseline], стало [SStimer.bucket_count]")

	var/list/still_listed = list()
	for(var/timer_id in armed)
		var/datum/timedevent/scheduled = SStimer.timer_id_dict[timer_id]
		if(!scheduled)
			continue
		if(scheduled.bucket_pos < 1)
			still_listed += "[timer_id] без позиции в бакете"
			continue
		if(SStimer.bucket_list[scheduled.bucket_pos] != scheduled && !scheduled.prev && !scheduled.next)
			still_listed += "[timer_id] потерял свой слот [scheduled.bucket_pos]"
	TEST_ASSERT(!length(still_listed), "Таймеры разошлись с записанной позицией: [still_listed.Join(", ")]")

	var/list/orphaned = list()
	for(var/timer_id in armed)
		var/datum/timedevent/scheduled = SStimer.timer_id_dict[timer_id]
		var/bucket_pos = scheduled?.bucket_pos
		deltimer(timer_id)
		if(bucket_pos >= 1 && SStimer.bucket_list[bucket_pos] == scheduled)
			orphaned += "[timer_id]@[bucket_pos]"

	TEST_ASSERT(!length(orphaned), "После удаления в голове бакета остался мёртвый таймер: [orphaned.Join(", ")]")
	TEST_ASSERT_EQUAL(SStimer.bucket_count, baseline,
		"Население колеса не вернулось к исходному: было [baseline], стало [SStimer.bucket_count]")

/**
 * Общий бакет: два таймера с ОДНИМ сроком ложатся в один слот кольцом, и снимать их
 * оттуда надо в двух разных качествах - не-головой и головой.
 *
 * Соседний timer_bucket_accounting этот путь не проходит ни разу: тик короче децисекунды,
 * и любой шаг между сроками разводит таймеры по разным бакетам. А переписан именно он -
 * раньше не-голова искалась сканом bucket_list.Find(src) по всем бакетам (для не-головы
 * скан всегда возвращал ноль), теперь позиция берётся из bucket_pos, и слот в колесе для
 * не-головы трогать нельзя вообще.
 */
/datum/unit_test/timer_shared_bucket_eject
	/// Сколько сроков пробуем в поисках пустого бакета. Чужой таймер мира в слоте сделал бы
	/// наш таймер не-головой, и проверка снятия головы проверяла бы не то.
	var/probe_attempts = 30

/datum/unit_test/timer_shared_bucket_eject/proc/never_runs()
	return

/datum/unit_test/timer_shared_bucket_eject/Run()
	// Ни одного сна до конца проверки: мир однопоточный, значит колесо между этими строками
	// не крутится и арифметика по bucket_count честная.
	var/baseline = SStimer.bucket_count

	var/head_id
	var/head_wait
	var/datum/timedevent/head
	for(var/attempt in 1 to probe_attempts)
		// Все сроки внутри окна колеса (минута), иначе таймер уедет в second_queue мимо бакетов.
		var/candidate_wait = (10 + attempt) SECONDS
		var/candidate_id = addtimer(CALLBACK(src, PROC_REF(never_runs)), candidate_wait, TIMER_STOPPABLE)
		var/datum/timedevent/candidate = SStimer.timer_id_dict[candidate_id]
		// Бакет был пуст, если таймер лёг ровно в свой слот и ни с кем не связался.
		if(candidate && candidate.bucket_pos >= 1 && SStimer.bucket_list[candidate.bucket_pos] == candidate && !candidate.next && !candidate.prev)
			head_id = candidate_id
			head_wait = candidate_wait
			head = candidate
			break
		deltimer(candidate_id)

	TEST_ASSERT_NOTNULL(head, "За [probe_attempts] попыток не нашлось пустого бакета - снятие головы проверять не на чем")

	var/bucket_pos = head.bucket_pos
	var/tail_id = addtimer(CALLBACK(src, PROC_REF(never_runs)), head_wait, TIMER_STOPPABLE)
	var/datum/timedevent/tail = SStimer.timer_id_dict[tail_id]
	TEST_ASSERT_NOTNULL(tail, "Премиса: второй остановимый таймер обязан попасть в timer_id_dict")

	TEST_ASSERT_EQUAL(tail.bucket_pos, bucket_pos, "Два таймера с одним сроком разошлись по разным бакетам")
	TEST_ASSERT(SStimer.bucket_list[bucket_pos] == head, "Вставка второго таймера подменила голову бакета [bucket_pos]")
	TEST_ASSERT(head.next == tail && head.prev == tail, "Голова бакета не замкнулась кольцом на второй таймер")
	TEST_ASSERT(tail.next == head && tail.prev == head, "Второй таймер не замкнулся кольцом на голову бакета")
	TEST_ASSERT_EQUAL(SStimer.bucket_count, baseline + 2, "В общий бакет легло не два таймера: было [baseline], стало [SStimer.bucket_count]")

	// Сначала не-голова: слот в колесе на неё не смотрит, значит трогать его нельзя.
	deltimer(tail_id)
	TEST_ASSERT(SStimer.bucket_list[bucket_pos] == head, "Снятие не-головы увело слот [bucket_pos] из-под головы бакета")
	TEST_ASSERT_NULL(head.next, "После снятия не-головы у головы остался next - кольцо смотрит на удалённый таймер")
	TEST_ASSERT_NULL(head.prev, "После снятия не-головы у головы остался prev - кольцо смотрит на удалённый таймер")
	TEST_ASSERT_EQUAL(SStimer.bucket_count, baseline + 1, "Снятие не-головы посчиталось неверно: ждали [baseline + 1], стало [SStimer.bucket_count]")

	// Теперь голова: слот обязан обнулиться, иначе следующий проход колеса найдёт в нём
	// таймер без колбека - то самое "Invalid timer", на котором колесо пересобирается целиком.
	deltimer(head_id)
	TEST_ASSERT_NULL(SStimer.bucket_list[bucket_pos], "После снятия головы слот [bucket_pos] остался занят")
	TEST_ASSERT_EQUAL(SStimer.bucket_count, baseline, "Население колеса не вернулось к исходному: было [baseline], стало [SStimer.bucket_count]")

/**
 * Пересборка колеса считается. Ноль в этой колонке - норма, и пока событие нигде не
 * считалось, разбор раунда не отличал "колесо работает" от "колесо трижды пересобрали".
 */
/datum/unit_test/timer_bucket_resets_are_counted

/datum/unit_test/timer_bucket_resets_are_counted/proc/never_runs()
	return

/datum/unit_test/timer_bucket_resets_are_counted/Run()
	var/before = SStimer.bucket_reset_count
	// Проверяется боевой инвариант, а не знак числа: за раунд колесо пересобирается РОВНО
	// один раз, и этот раз приходится на старт - fps из конфига применяется после
	// инициализации подсистем (master.dm) и честно пересобирает колесо через
	// world.on_tickrate_change(). Всё сверх единицы - аварийные выходы, и ловить их надо
	// здесь, а не по перф-логу через неделю.
	TEST_ASSERT(before <= 1, "Колесо бакетов пересобиралось [before] раз - норма не больше одного, на смене fps при старте мира")

	// Таймер переживает пересборку: reset_buckets() раскладывает всё заново, а не выбрасывает.
	var/timer_id = addtimer(CALLBACK(src, PROC_REF(never_runs)), 30 SECONDS, TIMER_STOPPABLE)
	SStimer.reset_buckets()

	TEST_ASSERT_EQUAL(SStimer.bucket_reset_count, before + 1, "Пересборка колеса не посчиталась")

	var/datum/timedevent/scheduled = SStimer.timer_id_dict[timer_id]
	TEST_ASSERT_NOTNULL(scheduled, "Пересборка колеса потеряла живой таймер")
	TEST_ASSERT(scheduled.bucket_pos >= 1, "После пересборки таймер остался без записанной позиции в бакете")
	TEST_ASSERT(SStimer.bucket_list[scheduled.bucket_pos] == scheduled || scheduled.prev || scheduled.next,
		"После пересборки таймер не лежит ни головой бакета, ни в его цепочке")

	deltimer(timer_id)

/// Сколько тиков даём колесу на то, чтобы дойти до таймера в один децисекунду и обратно.
#define LOOP_TIMER_GRACE_TICKS 20

/**
 * Зацикленный таймер, удалённый внутри собственного колбека, в колесо не возвращается.
 *
 * Обычным путём такого не случается: datum/Destroy() пропускает СПУЩЕННЫЕ таймеры, а
 * спущен таймер ровно на время своего колбека. Флаг TIMER_DELETE_ME эту защиту снимает
 * намеренно - и стоит он как раз на зацикленном таймере звукового цикла
 * (_looping_sound.dm), то есть путь не гипотетический.
 *
 * Цена возврата удалённого таймера в бакет - не потерянный звук, а пересборка ВСЕГО
 * колеса: следующий проход находит в голове бакета запись без колбека, объявляет
 * "Invalid timer" и сбрасывает bucket_resolution. Поэтому тест смотрит не только на
 * то, что колбек не повторился, но и на счётчик пересборок - величину, которая в
 * здоровом раунде равна единице за весь раунд.
 */
/datum/unit_test/timer_loop_self_deleted_does_not_requeue
	var/datum/timedevent/doomed
	var/fires = 0

/datum/unit_test/timer_loop_self_deleted_does_not_requeue/proc/self_destruct()
	fires++
	// Ровно то, что делает datum/Destroy() владельца для таймера с TIMER_DELETE_ME:
	// удаляет спущенный таймер прямо из его собственного колбека.
	var/datum/timedevent/victim = doomed
	doomed = null
	if(victim)
		qdel(victim)

/datum/unit_test/timer_loop_self_deleted_does_not_requeue/Run()
	// bucket_count здесь не проверяется, в отличие от соседних тестов: этот ждёт срабатывания,
	// то есть спит, а во сне мир заводит и спускает собственные таймеры - население колеса
	// за эти сорок тиков уезжает само по себе. Пересборки колеса от сна не зависят: в здоровом
	// раунде их ноль, и любая единица здесь - настоящая авария, ровно то, что тест и ловит.
	var/baseline_resets = SStimer.bucket_reset_count

	var/timer_id = addtimer(CALLBACK(src, PROC_REF(self_destruct)), 1, TIMER_STOPPABLE | TIMER_LOOP)
	doomed = SStimer.timer_id_dict[timer_id]
	TEST_ASSERT_NOTNULL(doomed, "Премиса: остановимый таймер обязан попасть в timer_id_dict")

	for(var/grace_tick in 1 to LOOP_TIMER_GRACE_TICKS)
		if(fires)
			break
		stoplag(1)

	// Если колесо за двадцать тиков не дошло до таймера в одну децисекунду, проверять нечего:
	// молча зелёный тест хуже красного, поэтому это премиса, а не тихий выход.
	TEST_ASSERT(fires, "Премиса: зацикленный таймер в одну децисекунду обязан сработать за [LOOP_TIMER_GRACE_TICKS] тиков")

	for(var/grace_tick in 1 to LOOP_TIMER_GRACE_TICKS)
		stoplag(1)

	TEST_ASSERT_EQUAL(fires, 1, "Удалённый в собственном колбеке зацикленный таймер сработал ещё раз: [fires]")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[timer_id], "Удалённый таймер остался в timer_id_dict")
	TEST_ASSERT_EQUAL(SStimer.bucket_reset_count, baseline_resets,
		"Удалённый в колбеке таймер вернулся в бакет и увёл колесо на пересборку: было [baseline_resets], стало [SStimer.bucket_reset_count]")

#undef LOOP_TIMER_GRACE_TICKS

/**
 * Слот колеса трогается только тогда, когда он ДЕЙСТВИТЕЛЬНО смотрит на снимаемый таймер.
 *
 * bucketEject() больше не ищет таймер сканом по всем бакетам, а верит записанной позиции -
 * и правильно делает, скан стоил тысячу с лишним сравнений и всё равно врал для не-головы.
 * Но верить позиции можно ровно до тех пор, пока рядом стоит проверка
 * `bucket_list[bucket_pos] == src`: без неё разошедшаяся позиция вычистит ЧУЖОЙ слот, и
 * таймер соседа останется в колесе без головы - то есть не сработает уже никогда, до самой
 * пересборки, и в стат-панели это будет выглядеть просто как "таймер завис".
 *
 * Что позиция может разойтись со слотом - не гипотеза: ровно такое состояние оставляет за
 * собой страховка в fire() ("Timer bucket head survived its own eject"). Раз она там есть,
 * инвариант обязан быть закреплён отдельно, а не держаться "по построению".
 */
/datum/unit_test/timer_eject_respects_foreign_slot
	/// Сколько сроков пробуем в поисках двух ПУСТЫХ бакетов: чужой таймер мира в слоте
	/// сделал бы наш таймер не-головой, и проверять было бы нечего.
	var/probe_attempts = 30

/datum/unit_test/timer_eject_respects_foreign_slot/proc/never_runs()
	return

/datum/unit_test/timer_eject_respects_foreign_slot/Run()
	// Ни одного сна до конца проверки: мир однопоточный, значит колесо между этими строками
	// не крутится и арифметика по bucket_count честная.
	var/baseline = SStimer.bucket_count

	var/list/claimed_ids = list()
	var/list/datum/timedevent/claimed = list()
	for(var/attempt in 1 to probe_attempts)
		if(length(claimed) >= 2)
			break
		// Все сроки внутри окна колеса (минута), иначе таймер уедет в second_queue мимо бакетов.
		var/candidate_id = addtimer(CALLBACK(src, PROC_REF(never_runs)), (10 + attempt) SECONDS, TIMER_STOPPABLE)
		var/datum/timedevent/candidate = SStimer.timer_id_dict[candidate_id]
		// Бакет был пуст, если таймер лёг ровно в свой слот и ни с кем не связался.
		if(candidate && candidate.bucket_pos >= 1 && SStimer.bucket_list[candidate.bucket_pos] == candidate && !candidate.next && !candidate.prev)
			claimed_ids += candidate_id
			claimed += candidate
			continue
		deltimer(candidate_id)

	TEST_ASSERT_EQUAL(length(claimed), 2, "За [probe_attempts] попыток не нашлось двух пустых бакетов - расхождение проверять не на чем")

	var/datum/timedevent/stranger = claimed[1]
	var/datum/timedevent/victim = claimed[2]
	var/stranger_slot = stranger.bucket_pos
	var/victim_slot = victim.bucket_pos
	TEST_ASSERT_NOTEQUAL(stranger_slot, victim_slot, "Оба таймера легли в один бакет - расхождение проверять не на чем")

	// Разводим позицию со слотом руками.
	victim.bucket_pos = stranger_slot
	deltimer(claimed_ids[2])

	TEST_ASSERT_EQUAL(SStimer.bucket_list[stranger_slot], stranger,
		"Снятие таймера с разошедшейся позицией вычистило ЧУЖОЙ слот [stranger_slot]")

	// Настоящий слот жертвы мы сами оставили смотреть на удалённый таймер - убираем за собой,
	// иначе следующий проход колеса найдёт в нём запись без колбека.
	if(SStimer.bucket_list[victim_slot] == victim)
		SStimer.bucket_list[victim_slot] = null

	deltimer(claimed_ids[1])
	TEST_ASSERT_NULL(SStimer.bucket_list[stranger_slot], "Чужой таймер не ушёл из своего слота при собственном снятии")
	TEST_ASSERT_EQUAL(SStimer.bucket_count, baseline,
		"Население колеса не вернулось к исходному: было [baseline], стало [SStimer.bucket_count]")

/// Колесо обязано догонять мир промоткой пустых бакетов.
///
/// Отстав, колесо шагало по одному бакету за прогон: хвостовой MC_TICK_CHECK прерывает
/// проход на исчерпанном тике, а под нагрузкой МК зовёт подсистему реже раза в тик. В CI
/// на multiz_debug курсор шёл со скоростью полутора процентов от реального времени, и всё
/// новое уходило в second_queue мимо колеса - ни один обычный таймер за раунд не срабатывал.
/// Проверяется сам шаг промотки на синтетическом колесе: боевой SStimer тест не трогает.
/datum/unit_test/timer_wheel_skips_empty_buckets

/datum/unit_test/timer_wheel_skips_empty_buckets/Run()
	var/list/wheel = new /list(10)

	// Все наступившие бакеты пусты - курсор обязан пройти их разом и встать за последним.
	TEST_ASSERT_EQUAL(SStimer.skip_empty_buckets(wheel, 1, 7), 8,
		"промотка не прошла отрезок пустых бакетов целиком")

	// Непустой бакет останавливает промотку на себе: его таймеры обязаны отработать.
	wheel[4] = "таймер"
	TEST_ASSERT_EQUAL(SStimer.skip_empty_buckets(wheel, 1, 7), 4,
		"промотка проскочила непустой бакет")

	// За границу наступившего времени промотка не заходит, даже если дальше пусто.
	wheel[4] = null
	TEST_ASSERT_EQUAL(SStimer.skip_empty_buckets(wheel, 1, 3), 4,
		"промотка ушла за последний наступивший бакет")

	// Курсор уже за границей - шага нет вовсе.
	TEST_ASSERT_EQUAL(SStimer.skip_empty_buckets(wheel, 9, 3), 9,
		"промотка сдвинула курсор, которому двигаться некуда")

	// Непустой бакет прямо под курсором промотку не начинает.
	wheel[2] = "таймер"
	TEST_ASSERT_EQUAL(SStimer.skip_empty_buckets(wheel, 2, 9), 2,
		"промотка сдвинулась с непустого бакета под курсором")

#undef LONG_TIMER_GRACE_TICKS

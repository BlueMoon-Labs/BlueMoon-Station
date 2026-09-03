/// Инвариант разбора подписок: после Destroy ни одна сторона не держит другую.
/// Уцелевшая регистрация - это жёсткая ссылка в обе стороны (ключ в signal_procs
/// слушателя и запись в comp_lookup цели), то есть прямой путь в hard delete.
///
/// Тесты появились из подозрения, что оба цикла в /datum/Destroy пропускают
/// каждый второй элемент: они идут прямым `for(var/x in list)` по спискам,
/// которые UnregisterSignal правит по ходу (`lookup -= sig` и
/// `signal_procs -= target` в _component.dm). Подозрение ПРОВЕРЕНО И СНЯТО:
/// на трёх подписках (с двумя пропуск мог бы не проявиться) оба направления
/// разбираются полностью на неизменённом коде. Обход ассоциативного списка по
/// ключам в DM переживает вырезание текущего ключа. Тесты оставлены, чтобы это
/// свойство не пришлось выяснять заново.
#define SIGNAL_TEARDOWN_TEST_COUNT 3

/datum/unit_test_signal_probe

/datum/unit_test_signal_probe/proc/on_test_signal(datum/source)
	SIGNAL_HANDLER
	return

/datum/unit_test/signal_teardown_target

/datum/unit_test/signal_teardown_target/Run()
	var/datum/target = new
	var/list/datum/unit_test_signal_probe/probes = list()
	for(var/index in 1 to SIGNAL_TEARDOWN_TEST_COUNT)
		var/datum/unit_test_signal_probe/probe = new
		probes += probe
		// Разные сигналы: под одним слушателем comp_lookup хранит его голым
		// датумом, и снятие подписки вырезает сам ключ - тот самый путь.
		probe.RegisterSignal(target, "unit_test_signal_[index]", TYPE_PROC_REF(/datum/unit_test_signal_probe, on_test_signal))

	for(var/datum/unit_test_signal_probe/probe as anything in probes)
		TEST_ASSERT(probe.signal_procs?[target], "зонд не зарегистрировал подписку на цель")

	qdel(target)

	for(var/index in 1 to SIGNAL_TEARDOWN_TEST_COUNT)
		var/datum/unit_test_signal_probe/probe = probes[index]
		TEST_ASSERT_NULL(probe.signal_procs?[target], "подписка [index] пережила Destroy цели - слушатель держит её жёсткой ссылкой")

	for(var/datum/unit_test_signal_probe/probe as anything in probes)
		qdel(probe)

/datum/unit_test/signal_teardown_listener

/datum/unit_test/signal_teardown_listener/Run()
	var/datum/unit_test_signal_probe/probe = new
	var/list/datum/targets = list()
	for(var/index in 1 to SIGNAL_TEARDOWN_TEST_COUNT)
		var/datum/target = new
		targets += target
		probe.RegisterSignal(target, "unit_test_signal_[index]", TYPE_PROC_REF(/datum/unit_test_signal_probe, on_test_signal))

	for(var/datum/target as anything in targets)
		TEST_ASSERT_NOTNULL(target.comp_lookup, "цель не приняла подписку")

	qdel(probe)

	for(var/index in 1 to SIGNAL_TEARDOWN_TEST_COUNT)
		var/datum/target = targets[index]
		TEST_ASSERT_NULL(target.comp_lookup, "цель [index] осталась с записью в comp_lookup после Destroy слушателя")

	for(var/datum/target as anything in targets)
		qdel(target)

#undef SIGNAL_TEARDOWN_TEST_COUNT

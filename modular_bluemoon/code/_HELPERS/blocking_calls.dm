/**
 * # Обёртки над блокирующими примитивами
 *
 * Некоторые встроенные вызовы BYOND останавливают ВЕСЬ процесс DreamDaemon, пока ждут
 * ответа с той стороны: winget/winexists уходят по сети в скин клиента и ждут его
 * ответа, savefile ходит на диск, world.Export держит HTTP-запрос. Всё это время
 * ни одна строчка DM не исполняется, а world.cpu не растёт - и SStick_spikes видит
 * ровно то, что видел в раунде 9838: "реального времени прошло на 300 мс больше
 * игрового, DM почти не работал". Половина спайков раунда (122 из 246) уехала в
 * безымянный "внешний столл" именно так.
 *
 * Отличить наше ожидание от честной проблемы хоста изнутри DM можно только одним
 * способом - засечь время вокруг самого примитива. Обёртки ниже делают это и отдают
 * замер в SStick_spikes: дорогие вызовы попадают в кольцо медленной работы (и потом
 * в отчёт о спайке поимённо), а суммарная статистика раз в пять минут уходит в
 * tick_spikes.log. Если сумма по обёрткам сопоставима с суммарным дрифтом спайков -
 * виноваты мы; если нет - виноват хост, и в коде копать нечего.
 *
 * Накладные расходы: два чтения монотонных часов rust-g на вызов. Оборачивать имеет
 * смысл только то, что действительно блокирует - не надо вешать это на горячие проки.
 */

/// Имя цели для описания замера. Принимает и клиент, и моба.
/proc/blocking_call_target_name(target)
	if(istype(target, /client))
		var/client/target_client = target
		return target_client.ckey || "<клиент без ckey>"
	if(ismob(target))
		var/mob/target_mob = target
		return target_mob.ckey || "[target_mob.type]"
	return "[target]"

/**
 * winget с замером. Сигнатура и возвращаемое значение - как у оригинала.
 *
 * winget синхронно ждёт ответа скина клиента. На клиенте с плохой связью это
 * останавливает мир на всё время round-trip.
 */
/proc/tracked_winget(target, control_id, params)
	if(!SStick_spikes)
		return winget(target, control_id, params)
	var/started_ms = SStick_spikes.now_ms()
	. = winget(target, control_id, params)
	SStick_spikes.record_blocking_call("winget", "[blocking_call_target_name(target)]: [control_id || "<окно>"].[params]", SStick_spikes.now_ms() - started_ms)

/// winexists с замером. Такой же round-trip до скина, как и у winget.
/proc/tracked_winexists(target, control_id)
	if(!SStick_spikes)
		return winexists(target, control_id)
	var/started_ms = SStick_spikes.now_ms()
	. = winexists(target, control_id)
	SStick_spikes.record_blocking_call("winexists", "[blocking_call_target_name(target)]: [control_id]", SStick_spikes.now_ms() - started_ms)

/**
 * Ручная пара для блоков, которые обёрткой не накрыть - работа с savefile,
 * world.Export и прочее, где вызовов несколько подряд.
 *
 * Использование:
 *   var/started_ms = blocking_call_start()
 *   ... блокирующая работа ...
 *   blocking_call_finish(started_ms, "savefile", "префы [ckey]")
 */
/proc/blocking_call_start()
	return SStick_spikes?.now_ms()

/proc/blocking_call_finish(started_ms, kind, desc)
	if(isnull(started_ms) || !SStick_spikes)
		return
	SStick_spikes.record_blocking_call(kind, desc, SStick_spikes.now_ms() - started_ms)

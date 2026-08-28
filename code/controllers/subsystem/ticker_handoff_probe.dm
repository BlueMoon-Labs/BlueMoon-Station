/**
 * Цена раздачи тел на старте раунда, по стадиям.
 *
 * ЗАЧЕМ. Раунд 10121 (Syndicate Station, 105 игроков): VmSize вырос на 666 МБ за ОДНО
 * десятисекундное окно перф-CSV на старте раунда - 48% всего роста раунда и 16% потолка
 * адресного пространства 32-битного DreamDaemon. Число инстансов за это окно
 * УМЕНЬШИЛОСЬ на 941 (софтделов 39 554 - чистка лобби-лендмарков), то есть ни перепись
 * инстансов, ни перепись датумов этих мегабайт не видят: они лежат не в объектах DM.
 *
 * Прибор подключения (client_connect_probe.dm) сюда не достаёт: он меряет client/New(),
 * то есть ЛОББИ. В лобби у клиента нет карты, только заставка, и поклиентская машинерия
 * карты BYOND аллоцируется позже - на переносе ключа в тело. Ста пяти игрокам разом, в
 * одну стадию, за секунды.
 *
 * ЧТО ДЕЛАЕТ. Режет старт раунда на стадии SSticker (create/collect/equip/manifest/
 * transfer/splash) и говорит про каждую: сколько секунд, сколько МБ VmSize, сколько это на
 * игрока и на сколько сдвинулся world.contents.len. Последнее и есть разделитель: стадия,
 * которая платит датумами, двигает счётчик объектов вместе с памятью, а стадия, которая
 * платит поклиентской машинерией BYOND, - нет.
 *
 * Свою цену прибор записывает на счёт фоновой работы. Без этого стартовый шторм попадал
 * в окна тех, кто в эти же секунды подключался: сумма "хвостов" по 116 входам раунда
 * 10121 дала 1919 МБ при реальном росте раунда 1395 МБ.
 *
 * На Windows /proc нет: тогда в строке остаются только времена стадий, и это тоже ответ
 * на вопрос, сколько секунд занимала каждая.
 */

/// Через сколько после конца раздачи тел снять контрольный замер. Клиент дорисовывает
/// свой первый кадр мира уже после transfer_characters(), и ступенька приходит позже.
#define HANDOFF_PROBE_FOLLOWUP_DELAY (60 SECONDS)

/datum/roundstart_handoff_probe
	/// REALTIMEOFDAY на входе в первую стадию
	var/started_at
	/// REALTIMEOFDAY последней отметки - стадии меряются от неё
	var/last_mark_at
	/// VmSize/VmRSS на входе; null - замер памяти недоступен (Windows, /proc не читается)
	var/start_vsz
	var/start_rss
	/// VmSize на последней отметке
	var/last_mark_vsz
	/// GLOB.memory_attributed_elsewhere_mb на последней отметке и на входе
	var/last_mark_attributed = 0
	var/start_attributed = 0
	/// Готовые куски строки по стадиям
	var/list/stages = list()
	/// world.contents.len на последней отметке. Разделитель "объекты / не объекты": стадия,
	/// которая платит датумами, двигает его вместе с VmSize, а стадия, которая платит
	/// поклиентской машинерией BYOND, - нет. Ровно этого разделения не хватало разбору
	/// раунда 10121, где 666 МБ пришли при УМЕНЬШИВШЕМСЯ числе инстансов.
	var/last_mark_instances = 0
	/// Итог после finish(): VmSize и момент конца раздачи, от них считается контрольный замер
	var/finished_vsz
	/// Сколько игроков доехало до тела - знаменатель итоговой цифры "на игрока"
	var/players_handed_off = 0

/datum/roundstart_handoff_probe/New()
	. = ..()
	started_at = REALTIMEOFDAY
	last_mark_at = started_at
	last_mark_instances = world.contents.len
	start_attributed = GLOB.memory_attributed_elsewhere_mb
	last_mark_attributed = start_attributed
	var/list/memory = get_process_memory_mb()
	if(memory)
		start_vsz = memory["vsz"]
		start_rss = memory["rss"]
		last_mark_vsz = start_vsz

/**
 * Закрыть стадию: сколько секунд она шла, на сколько МБ сдвинула VmSize и сколько это на
 * игрока. players_touched = null у стадий, которые игроков не перебирают (манифест).
 *
 * Своя цена стадии тут же уходит на счёт фоновой работы: прибор подключения вычитает
 * прирост этого счётчика, и входы, попавшие в стартовый шторм, перестают его наследовать.
 * Записывается ИМЕННО своя цена, за вычетом чужой - иначе постройка света z-уровня,
 * идущая в те же секунды, попала бы в счётчик дважды.
 */
/datum/roundstart_handoff_probe/proc/mark(stage_name, players_touched)
	var/now = REALTIMEOFDAY
	var/seconds = round(max(now - last_mark_at, 0) / 10, 0.1)
	last_mark_at = now
	var/instances_now = world.contents.len
	var/instances_delta = instances_now - last_mark_instances
	last_mark_instances = instances_now
	var/attributed_now = GLOB.memory_attributed_elsewhere_mb
	var/list/memory = isnull(start_vsz) ? null : get_process_memory_mb()
	var/own_spent = 0
	var/part
	if(memory)
		own_spent = probe_stage_own_mb(memory["vsz"] - last_mark_vsz, attributed_now - last_mark_attributed)
		part = probe_stage_line(stage_name, seconds, memory["vsz"] - last_mark_vsz, attributed_now - last_mark_attributed)
		last_mark_vsz = memory["vsz"]
	else
		part = probe_stage_line(stage_name, seconds, 0, 0, measured = FALSE)
	last_mark_attributed = attributed_now
	stages += handoff_stage_line(part, players_touched, own_spent, instances_delta, measured = !isnull(memory))
	attribute_memory_elsewhere_mb(own_spent)

/// Строка итога: общее время, VmSize до и после, стадии.
/datum/roundstart_handoff_probe/proc/summary_line()
	var/total_seconds = round(max(REALTIMEOFDAY - started_at, 0) / 10, 0.1)
	var/line = "## MEMORY: раздача тел [players_handed_off] игрокам за [total_seconds]с"
	if(isnull(start_vsz))
		line += ", память не меряется"
	else
		var/list/memory = get_process_memory_mb()
		if(memory)
			finished_vsz = memory["vsz"]
			var/background = max(GLOB.memory_attributed_elsewhere_mb - start_attributed, 0)
			var/own = finished_vsz - start_vsz - background
			line += ": VmSize [start_vsz] -> [finished_vsz] МБ ([format_mb_delta(own)]"
			line += background > 0 ? ", мимо [format_mb_delta(background)] фоновой работы)" : ")"
			line += ", RSS [format_mb_delta(memory["rss"] - start_rss)]"
			line += ", [handoff_per_player_text(own, players_handed_off)]"
	if(length(stages))
		line += "; стадии: [stages.Join(", ")]"
	return line

/// Конец раздачи тел: строка в лог мира и контрольный замер через минуту.
/datum/roundstart_handoff_probe/proc/finish(handed_off)
	players_handed_off = handed_off
	log_world(summary_line())
	if(isnull(finished_vsz))
		return
	addtimer(CALLBACK(src, PROC_REF(followup)), HANDOFF_PROBE_FOLLOWUP_DELAY)

/// Дельта VmSize через минуту после конца раздачи: первый кадр мира клиент дорисовывает
/// уже после transfer_characters(), и ступенька может прийти туда.
/datum/roundstart_handoff_probe/proc/followup_line(current_vsz)
	return "## MEMORY: раздача тел, через [round(HANDOFF_PROBE_FOLLOWUP_DELAY / 10)]с: VmSize [format_mb_delta(current_vsz - finished_vsz)] с конца раздачи"

/datum/roundstart_handoff_probe/proc/followup()
	var/list/memory = get_process_memory_mb()
	if(memory)
		log_world(followup_line(memory["vsz"]))

/**
 * Дописать к строке стадии число игроков, цену на игрока и дельту объектов.
 *
 * Отдельным проком, потому что это единственное место, где живёт деление на число
 * игроков, а без живого раунда его иначе не проверить. Стадия без игроков (манифест) и
 * стадия без замера памяти обязаны молчать про "МБ на игрока", а не печатать ноль:
 * ноль читался бы как измеренная бесплатность.
 *
 * Дельта объектов печатается ВСЕГДА, в том числе отрицательная и в том числе без замера
 * памяти: она и есть ответ на вопрос "стадия заплатила датумами или чем-то ещё", а на
 * Windows это вообще единственная измеримая половина.
 */
/proc/handoff_stage_line(stage_line, players_touched, own_spent_mb, instances_delta, measured = TRUE)
	var/list/notes = list()
	if(!isnull(players_touched))
		notes += "[players_touched] игроков"
		if(measured)
			notes += handoff_per_player_text(own_spent_mb, players_touched)
	notes += "[instances_delta >= 0 ? "+" : ""][instances_delta] объектов"
	return "[stage_line] ([notes.Join(", ")])"

/// "1.4 МБ на игрока" либо честное "игроков нет" вместо деления на ноль.
/proc/handoff_per_player_text(spent_mb, players)
	if(players <= 0)
		return "игроков нет"
	return "[round(spent_mb / players, 0.1)] МБ на игрока"

#undef HANDOFF_PROBE_FOLLOWUP_DELAY

/// Базовый контракт всего, что может запустить директор.
/// /datum/round_event_control и /datum/dynamic_ruleset переподвешиваются под него.
/datum/director_action
	/// DIRECTOR_KIND_EVENT или DIRECTOR_KIND_RULESET
	var/director_kind = null
	/// DIRECTOR_SEVERITY_*
	var/severity = null
	/// Сколько бюджета списывается при запуске
	var/cost = 0
	/// Вклад в активную нагрузку, пока действие живо
	var/intensity = 0
	/// Сколько вклад держится после завершения one-shot действия (децисекунды)
	var/intensity_linger = 0
	/// Вес во взвешенном выборе
	var/weight = 5
	/// Вес может стать положительным по живому условию уже во время раунда. Нужен панели:
	/// нулевой текущий вес такого действия означает "ждёт условия", а не "выключено".
	var/weight_can_change = FALSE
	/// Выключенное действие никогда не выбирается естественно
	var/enabled = TRUE
	/// Только для ручного запуска админом (заменяет хак weight = 0)
	var/admin_only = FALSE
	/// Минимальный эффективный экипаж
	var/min_players = 0
	/// Самое раннее время раунда (децисекунды от старта)
	var/earliest_start = 0
	/// Сколько раз действие уже запускалось
	var/occurrences = 0
	/// Максимум естественных запусков (0 = без лимита для базы; событtopia переопределяет)
	var/max_occurrences = 0
	/// Типы раундов, в которых действие доступно (null = любые)
	var/list/required_round_type = null
	/// Типы раундов, где действие не выбирается самостоятельно, но запускается связанным
	/// сценарием другого действия. Используется каталогом профилей, а не can_fire().
	var/list/director_linked_round_types = null
	/// Пояснение связанной доступности для каталога профилей.
	var/director_linked_detail = null
	/// Ассоциация DIRECTOR_DEPT_* -> минимум активных; null = без требований
	var/list/min_staffing = null
	/// Для пула ANTAG: тяжёлая инжекция (nuke assault и т.п.)
	var/antag_heavy = FALSE
	/// Персональное затухание повторов вместо профильного (см. director_profile.repeat_penalty); null = профиль
	var/repeat_penalty = null
	/// Семейство однотипных действий (произвольный строковый тег). Члены семейства делят затухание
	/// повторов (repeat_falloff считает по запускам всего семейства) и паузу profile.family_spacing:
	/// десять вариантов "перелива труб" не обходят анти-повторы поодиночке.
	var/family = null
	/// Навязчивость запуска (DIRECTOR_DISRUPTION_*): насколько действие мешает играть. Мягкие профили
	/// режут вес по этой метке (profile.disruption_weight_mults). null = дефолт от severity, см. get_disruption().
	var/disruption = null
	/// Филлер: пустышки вроде "Nothing" и мигания ламп. Не выбирается гарантированным битом -
	/// после долгой тишины директор обязан выдать реальный контент, а не ещё одну тишину.
	var/filler = FALSE
	/// Последняя неинтерактивная проверка фактической готовности. Панель читает эти поля,
	/// поэтому preflight не должен открывать опросы, выдавать роли или менять состояние раунда.
	var/director_preflight_detail = null
	var/director_preflight_failure = null

/// Имя для конфига/логов/панели. Обязано быть уникальным среди действий.
/datum/director_action/proc/action_name()
	return "[type]"

/// Все проверки пригодности. Наследники зовут ..() и добавляют свои.
/datum/director_action/proc/can_fire(datum/director_signals/signals)
	if(!enabled || admin_only)
		return FALSE
	if(max_occurrences && occurrences >= max_occurrences)
		return FALSE
	// SSdirector.now(), а не world.time: оффлайн-симулятор двигает время через time_override,
	// и earliest_start-события должны разблокироваться по симулированным часам (в бою идентично).
	if(earliest_start && (SSdirector.now() - SSticker.round_start_time) < earliest_start)
		return FALSE
	if(signals.effective_crew < min_players)
		return FALSE
	if(required_round_type && !(GLOB.round_type in required_round_type))
		return FALSE
	if(min_staffing)
		for(var/dept in min_staffing)
			if(signals.staffing[dept] < min_staffing[dept])
				return FALSE
	return TRUE

/// Вес с учётом сигналов. Наследники могут модифицировать.
/datum/director_action/proc/get_weight(datum/director_signals/signals)
	return weight

/// Навязчивость действия: явная метка или дефолт от ступени.
/// Флавор фоновый, minor заметный-но-терпимый, всё тяжелее (и антаг-пулы) - мешающее.
/datum/director_action/proc/get_disruption()
	if(disruption)
		return disruption
	switch(severity)
		if(DIRECTOR_SEVERITY_FLAVOR)
			return DIRECTOR_DISRUPTION_AMBIENT
		if(DIRECTOR_SEVERITY_MINOR)
			return DIRECTOR_DISRUPTION_MILD
	return DIRECTOR_DISRUPTION_DISRUPTIVE

/// Вторая ступень готовности непосредственно перед выбором. null = действие не реализует
/// отдельный preflight и полагается на execute_action(); TRUE/FALSE = явный результат.
/datum/director_action/proc/director_preflight()
	return null

/// Запуск действия. Возвращает TRUE при успехе.
/datum/director_action/proc/execute_action()
	CRASH("execute_action() не переопределён у [type]")

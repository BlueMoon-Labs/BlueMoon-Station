/** Собирает реакции, условия которых смесь удовлетворяет прямо сейчас.
 *
 * У тг каждая реакция отмечает себя в `gasmix.reaction_results`, и список чистится
 * каждый тик, так что окно анализатора показывает ровно то, что реально идёт. У нас
 * такого механизма нет: в `reaction_results` пишут только пожары (ключ "fire"), а
 * фьюжн отчитывается через `analyzer_results`. Взять оттуда список активных реакций
 * невозможно, поэтому перебираем `SSair.gas_reactions` и повторяем ровно ту проверку
 * `min_requirements`, которую делает `/datum/gas_mixture/react()` - включая порядок
 * условий и служебные ключи TEMP / ENER / MAX_TEMP / FIRE_REAGENTS.
 *
 * Это список кандидатов, а не список идущих реакций: мы не вызываем `react()`, а
 * значит не знаем ни сколько прошло, ни оборвал ли цикл STOP_REACTIONS
 * (гипер-ноблий). Показать игроку "возможна" честнее, чем всегда пустой список.
 *
 * Возвращает нумерованный список `list(id, имя, значение)`; значение всегда null.
 */
/proc/gas_mixture_reaction_candidates(datum/gas_mixture/gasmix)
	. = list()
	if(!gasmix || !SSair)
		return
	// react() выходит до цикла реакций, пока в смеси нет молей - кандидатов там нет.
	if(!gasmix.total_moles())
		return
	// Внутренний список смеси отдаётся по ссылке, а не копией: только чтение.
	var/list/cached_gases = gasmix.get_gases()
	var/temp = gasmix.return_temperature()
	var/ener = -1
	var/candidate_pressure = -1
	candidate_loop:
		for(var/datum/gas_reaction/reaction as anything in SSair.gas_reactions)
			var/list/min_reqs = reaction.min_requirements
			// Реакция без условий не индексируется SSair.auxtools_update_reactions()
			// и до смесей не доходит, так что кандидатом её не считаем.
			if(!length(min_reqs))
				continue
			if(min_reqs["TEMP"] && temp < min_reqs["TEMP"])
				continue
			if(min_reqs["ENER"])
				if(ener < 0)
					ener = gasmix.thermal_energy()
				if(ener < min_reqs["ENER"])
					continue
			if(min_reqs["MAX_TEMP"] && temp > min_reqs["MAX_TEMP"])
				continue
			if(min_reqs[REACTION_REQ_MIN_PRESSURE])
				if(candidate_pressure < 0)
					candidate_pressure = gasmix.return_pressure()
				if(candidate_pressure < min_reqs[REACTION_REQ_MIN_PRESSURE])
					continue
			for(var/id in min_reqs)
				if(id == "TEMP" || id == "ENER" || id == "MAX_TEMP" || id == REACTION_REQ_MIN_PRESSURE)
					continue
				if(id == "FIRE_REAGENTS")
					if(gasmix.get_oxidation_power(temp) < min_reqs[id] || gasmix.get_fuel_amount(temp) < min_reqs[id])
						continue candidate_loop
					continue
				if((cached_gases[id] || 0) < min_reqs[id])
					continue candidate_loop
			// Третьим элементом донор кладёт "сколько прошло" из reaction_results.
			// У нас такого числа нет - null, фронт рисует запись как "возможна".
			. += list(list(reaction.id, reaction.name, null))

/** Превращает газовую смесь в структуру для интерфейсов.
 *
 * Аргументы:
 * * gasmix: [/datum/gas_mixture]; null допустим - вернётся заготовка с пустыми полями.
 * * name: подпись смеси, необязательна.
 *
 * Возвращает ассоциативный список, в котором ключи присутствуют ВСЕГДА, даже когда
 * значения null - фронт читает ровно эти поля:
 * * name        Строка  Подпись смеси.
 * * reference   Строка  REF(gasmix), ключ смеси для интерфейса.
 * * total_moles Число   Моли.
 * * temperature Число   Кельвины.
 * * volume      Число   Литры.
 * * pressure    Число   Килопаскали.
 * * gases       Список  Нумерованный, элемент - list(строковый id, читаемое имя, моли).
 * * reactions   Список  Нумерованный, элемент - list(id реакции, имя, значение).
 */
/proc/gas_mixture_parser(datum/gas_mixture/gasmix, name)
	. = list(
		"gases" = list(),
		"reactions" = list(),
		"name" = format_text(name),
		"total_moles" = null,
		"temperature" = null,
		"volume" = null,
		"pressure" = null,
		"reference" = null,
	)
	if(!gasmix)
		return
	// Внутренний список смеси отдаётся по ссылке, а не копией: только чтение.
	var/list/cached_gases = gasmix.get_gases()
	var/list/cached_ids = GLOB.gas_data.ids
	var/list/cached_names = GLOB.gas_data.names
	var/list/parsed_gases = list()
	for(var/gas_id in cached_gases)
		// Смесь может держать ключ, которому не соответствует ни один /datum/gas
		// (set_moles() ничего не валидирует). Запасной вариант и для id, и для
		// имени - сам ключ: пустая подпись в окне хуже сырого идентификатора.
		parsed_gases += list(list(
			cached_ids[gas_id] || gas_id,
			cached_names[gas_id] || gas_id,
			cached_gases[gas_id],
		))
	.["gases"] = parsed_gases
	.["reactions"] = gas_mixture_reaction_candidates(gasmix)
	.["total_moles"] = gasmix.total_moles()
	.["temperature"] = gasmix.return_temperature()
	.["volume"] = gasmix.return_volume()
	.["pressure"] = gasmix.return_pressure()
	.["reference"] = REF(gasmix)

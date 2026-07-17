/// Ошибка отгрузки (порт идеи Baystation "Shipping Error"): автоматика снабжения сектора
/// сама добавляет в очередь карго случайный заказ, которого никто не делал. Ящик приедет
/// следующим шаттлом и будет оплачен бюджетом отдела как обычный заказ. Мелкая загадка
/// и головная боль для карго: кто заказал двадцать копий устава?
/datum/round_event_control/shipping_error
	name = "Shipping Error"
	typepath = /datum/round_event/shipping_error
	weight = 20
	max_occurrences = 2
	earliest_start = 10 MINUTES
	min_players = 5
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "A random unordered supply crate is queued for the next cargo shuttle on the department's tab."

/datum/round_event_control/shipping_error/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	if(!length(SSshuttle.supply_packs))
		return FALSE
	return TRUE

/datum/round_event/shipping_error
	fakeable = FALSE

/datum/round_event/shipping_error/start()
	var/list/datum/supply_pack/candidates = list()
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack.hidden || pack.contraband || pack.special || pack.DropPodOnly)
			continue
		if(pack.goody != PACK_GOODY_NONE)
			continue
		// Нижняя граница отсекает вырожденные паки, верхняя - чтобы ошибка отгрузки
		// оставалась мелкой пакостью, а не выносила бюджет отдела в ноль.
		if(pack.cost < 200 || pack.cost > 3000)
			continue
		candidates += pack

	if(!length(candidates))
		return kill()

	var/datum/supply_pack/chosen = pick(candidates)
	var/reason = pick(
		"Плановая закупка по форме 77-Б.",
		"Дозаказ по итогам квартальной инвентаризации.",
		"Замена утерянного при транспортировке груза.",
		"Подтверждено голосовой командой. Запись голоса повреждена.",
		"АВТОЗАКАЗ: прогнозируемая потребность станции.",
		"Ошибка маршрутизации: груз предназначался соседней станции.",
	)
	var/datum/supply_order/order = new(chosen, "Автоматическая система снабжения", "ЦентКом", null, reason, null, null)
	SSshuttle.shoppinglist += order
	log_game("EVENT: Shipping Error queued supply pack [chosen.name] (cost [chosen.cost]).")

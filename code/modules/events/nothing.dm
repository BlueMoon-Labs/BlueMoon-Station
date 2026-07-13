/// Пустышка на верхушке малой категории (запрос основателя): чаще всего малый слот
/// разрешается в тишину. Съедает бюджет, паузу ступени и глобальную паузу как обычное
/// малое событие - в этом и смысл: темп "что-то могло случиться" без нагрузки на игроков.
/datum/round_event_control/nothing
	name = "Nothing"
	typepath = /datum/round_event/nothing
	weight = 90
	max_occurrences = 15
	earliest_start = 0 MINUTES
	alert_observers = FALSE
	repeat_penalty = 0.15 // филлер обязан оставаться наверху пула весь раунд, обычное затухание не для него
	filler = TRUE // гарантированный бит после долгой тишины не должен разрешаться в ещё одну тишину
	category = EVENT_CATEGORY_BUREAUCRATIC
	severity = DIRECTOR_SEVERITY_MINOR
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "Literally nothing happens."

/datum/round_event/nothing
	fakeable = FALSE

/datum/techweb_node/spacepod_basic
	id = "spacepod_basic"
	display_name = "Конструктирование Спейсподов"
	description = "Стандартные схемы для производства небольшых космических катеров способных разогнаться до скорости 10 м/с."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	prereq_ids = list("base")
	design_ids = list("podcore", "podarmor_civ", "podarmor_dark", "spacepod_main")

/datum/techweb_node/spacepod_lock
	id = "spacepod_lock"
	display_name = "Системы защиты Спейспода"
	description = "Если необходимо держать этих серожопых подальше от вашей тарелочки."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2750)
	prereq_ids = list("spacepod_basic", "engineering")
	design_ids = list("podlock_keyed", "podkey", "podmisc_tracker")

/datum/techweb_node/spacepod_disabler
	id = "spacepod_disabler"
	display_name = "Вооружение Спейсподов"
	description = "Из этого хлама весьма сложно попасть туда куда вам хочется, но по крайней мере это весело."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
	prereq_ids = list("spacepod_basic", "weaponry")
	design_ids = list("podgun_disabler", "podgun_laser")

/datum/techweb_node/spacepod_lasers
	id = "spacepod_lasers"
	display_name = "Продвинутое вооружение Спейсподов"
	description = "Все еще слишком сложно попасть, но последствия ваших промахов стали весьма заметнее."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5250)
	prereq_ids = list("spacepod_disabler", "electronic_weapons")
	design_ids = list("podgun_bdisabler", "podgun_laser_heavylaser")

/datum/techweb_node/spacepod_ka
	id = "spacepod_ka"
	display_name = "Шахтерское снаряжение Спейспода"
	description = "Если просто копать руду в космосе уже недостаточно круто, то можно компать руду в космосе используя летающую тарелку!"
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
	prereq_ids = list("basic_mining", "spacepod_disabler")
	design_ids = list("pod_ka_basic")

/datum/techweb_node/spacepod_advmining
	id = "spacepod_aka"
	display_name = "Продвинутое шахтерское снаряжение Спейспода"
	description = "Нужно копать быстрее, еще быстрее!"
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
	prereq_ids = list("spacepod_ka", "adv_mining")
	design_ids = list("pod_ka", "pod_plasma_cutter")

/datum/techweb_node/spacepod_advplasmacutter
	id = "spacepod_apc"
	display_name = "Продвинутые плазменные резаки Спейспода"
	description = "КОПАТЬ, КОПАТЬ! БЫСТРЕЕ!! ЕЩЕ БЫСТРЕЕ!!! Черт... кажется это был гибтонит..."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 4500)
	prereq_ids = list("spacepod_aka", "adv_plasma")
	design_ids = list("pod_adv_plasma_cutter")

/datum/techweb_node/spacepod_pseat
	id = "spacepod_pseat"
	display_name = "Пасажирское кресло Спейспода"
	description = "Лететь на таран не так страшно, особенно когда ты не один."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3750)
	prereq_ids = list("spacepod_basic", "adv_engi")
	design_ids = list("podcargo_seat")

/datum/techweb_node/spacepod_storage
	id = "spacepod_storage"
	display_name = "Трюм Спейспода"
	description = "Для исследования космоса иногда надо столько всего с собой взять..."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 4500)
	prereq_ids = list("spacepod_pseat", "high_efficiency")
	design_ids = list("podcargo_crate", "podcargo_ore")

/datum/techweb_node/spacepod_lockbuster
	id = "spacepod_lockbuster"
	display_name = "Открывашка Спейсподов"
	description = "Иногда тебе просто ну очень нужно попасть внутрь."
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 8500)
	prereq_ids = list("spacepod_lasers", "high_efficiency", "adv_mining")
	design_ids = list("pod_lockbuster")

/datum/techweb_node/spacepod_iarmor
	id = "spacepod_iarmor"
	display_name = "Продвинутая броня Спейсподов"
	description = "Лучшая защита и пафосный внешний вид, что еще нужно?"
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2750)
	prereq_ids = list("spacepod_storage", "high_efficiency")
	design_ids = list("podarmor_industiral", "podarmor_sec", "podarmor_gold")

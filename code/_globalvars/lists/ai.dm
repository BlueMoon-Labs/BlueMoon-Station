// Глобальные реестры AI-контроллеров (порт tg 14140a6355d1
// code/_globalvars/lists/basic_ai.dm, адаптация: unplanned-бакет только для
// AI_STATUS_ON - спящие (IDLE) контроллеры у нас не обрабатываются вообще)

///Синглтоны сабтри планирования: типпас -> инстанс (см. SSai_controllers.setup_subtrees)
GLOBAL_LIST_EMPTY(ai_subtrees)

///Контроллеры по статусу: AI_STATUS_ON/OFF/IDLE -> список контроллеров
GLOBAL_LIST_INIT(ai_controllers_by_status, list(
	AI_STATUS_ON = list(),
	AI_STATUS_OFF = list(),
	AI_STATUS_IDLE = list(),
))

///Контроллеры по z-уровню пауна (пробуждение при появлении клиентов на z)
GLOBAL_LIST_EMPTY(ai_controllers_by_zlevel)

///Активные контроллеры без текущего плана: фоновое брождение (SSunplanned_controllers)
GLOBAL_LIST_EMPTY(unplanned_controllers)

///Враждебные машины-цели (турели, мехи, окулярные стражи, сборки):
///реестр вместо range()-сканов в поиске целей hostile AI
GLOBAL_LIST_EMPTY(hostile_machines)
///Тот же реестр, разбитый по z: обычный поиск не сканирует машины других карт.
GLOBAL_LIST_EMPTY(hostile_machines_by_zlevel)

///Цель -> /datum/ai_target_reservation. Не даёт нескольким support AI
///одновременно чинить/обслуживать одну и ту же цель.
GLOBAL_LIST_EMPTY(ai_target_reservations)
///Координаторы окружения стаи, ключ - цель
GLOBAL_LIST_EMPTY(ai_pack_focuses)

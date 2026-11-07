/datum/antag_training_sector
	/// В каком порядке своя сборка раскладывает стороны по меткам сектора.
	var/list/scenario_side_order

/datum/antag_training_sector/station
	scenario_side_order = list("arrivals", "command", "ritual", "medbay", "security", "ai")

/datum/antag_training_sector/engineering
	scenario_side_order = list("crew", "saboteur")

/datum/antag_training_sector/atmos
	scenario_side_order = list("crew", "medbay")

/datum/antag_training_sector/dark
	scenario_side_order = list("entry", "depths")

/datum/antag_training_scenario/traitor_security
	id = "traitor_security"
	name = "Предатель против СБ"
	desc = "«Эхо-7». Предатель с должностью выносит секретные документы из кабинета главы в зал прибытия, СБ и детектив должны заковать его и доставить в бриг; убитый предатель тоже засчитывается СБ. Не успел до конца отсчёта - победа СБ."
	order = 1
	sector = "station"
	min_players = 2
	max_players = 5
	timeout_winner = "security"
	sides = list("traitor" = list("name" = "Предатель", "spawn" = "medbay"), "security" = list("name" = "СБ", "spawn" = "security"))
	slot_specs = list(
		list("traitor", "Предатель", "crew:Assistant", /datum/antag_training_program/antag/traitor, 1, TRUE),
		list("security", "Офицер СБ", "crew:Security Officer", null, 3, TRUE),
		list("security", "Детектив", "crew:Detective", null, 1, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/steal, "traitor", list("name" = "Вынести документы из кабинета главы в зал прибытия", "source" = "head_office", "zone" = "arrivals")),
		list(/datum/antag_training_scenario_objective/detain, "security", list("name" = "Заковать предателя и доставить в бриг (убитый засчитывается)", "target" = "traitor", "zone" = "brig")),
	)

/datum/antag_training_scenario/decompression
	id = "decompression"
	name = "Разгерметизация"
	desc = "«Пневма». В зале пробоев выбило окно вакуумной камеры. Атмосферщики и инженеры ставят окно и возвращают давление, врачи лечат пострадавших. Не успели до конца отсчёта - партия проиграна."
	order = 2
	sector = "atmos"
	min_players = 1
	max_players = 5
	time_limit = 10 MINUTES
	sides = list("crew" = list("name" = "Экипаж", "spawn" = "crew"))
	slot_specs = list(
		list("crew", "Атмосферный техник", "crew:Atmospheric Technician", null, 2, TRUE),
		list("crew", "Инженер", "crew:Station Engineer", null, 1, FALSE),
		list("crew", "Врач", "crew:Medical Doctor", null, 2, FALSE, "medbay"),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/restore_pressure, "crew", list("name" = "Заделать пробой и вернуть давление в зал")),
		list(/datum/antag_training_scenario_objective/heal, "crew", list("name" = "Вылечить пострадавших", "count" = 3, "zone" = "casualties")),
	)

/datum/antag_training_scenario/blackout
	id = "blackout"
	name = "Блэкаут"
	desc = "«Гефест». Щиток машинного зала обесточен, SMES пуст. Инженеры поднимают питание: генератор, SMES, рубильник. Если в группе есть саботажник, он мешает, и если свет не вернули до конца отсчёта, победа его."
	order = 3
	sector = "engineering"
	min_players = 1
	max_players = 5
	time_limit = 10 MINUTES
	timeout_winner = "saboteur"
	sides = list("engineers" = list("name" = "Инженеры", "spawn" = "crew"), "saboteur" = list("name" = "Саботажник", "spawn" = "saboteur"))
	slot_specs = list(
		list("engineers", "Инженер", "crew:Station Engineer", null, 3, TRUE),
		list("engineers", "Старший инженер", "crew:Chief Engineer", null, 1, FALSE),
		list("saboteur", "Саботажник", "crew:Station Engineer", /datum/antag_training_program/antag/traitor, 1, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/restore_power, "engineers", list("name" = "Вернуть свет и питание сектора")),
	)

/datum/antag_training_scenario/raid
	id = "raid"
	name = "Налёт"
	desc = "«Эхо-7». Ядерные оперативники высаживаются в ритуальном зале и идут к учебной бомбе с диском в хранилище. СБ и главы должны вывести всех оперативников из строя. Бомба не взорвалась до конца отсчёта - победа станции."
	order = 4
	sector = "station"
	min_players = 2
	max_players = 8
	timeout_winner = "defenders"
	sides = list("operatives" = list("name" = "Оперативники", "spawn" = "ritual"), "defenders" = list("name" = "СБ и главы", "spawn" = "command"))
	slot_specs = list(
		list("operatives", "Оперативник", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/antag/nukeop, 3, TRUE),
		list("defenders", "Офицер СБ", "crew:Security Officer", null, 3, TRUE),
		list("defenders", "Капитан", "crew:Captain", null, 1, FALSE),
		list("defenders", "Глава СБ", "crew:Head of Security", null, 1, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/program_goal, "operatives", list("name" = "Взорвать учебную бомбу в хранилище")),
		list(/datum/antag_training_scenario_objective/side_down, "defenders", list("name" = "Вывести из строя всех оперативников", "target" = "operatives")),
	)

/datum/antag_training_scenario/revolution
	id = "revolution"
	name = "Революция"
	desc = "«Эхо-7». Главы революции вербуют вспышкой и валят глав с майндшилдом. Все главы в крите, мертвы или закованы - победа революции; главы революции выведены из строя - победа глав."
	order = 5
	sector = "station"
	min_players = 2
	max_players = 5
	timeout_winner = "heads"
	sides = list("revolution" = list("name" = "Революция", "spawn" = "arrivals"), "heads" = list("name" = "Главы", "spawn" = "command"))
	slot_specs = list(
		list("revolution", "Глава революции", "crew:Assistant", /datum/antag_training_program/antag/revolution, 2, TRUE),
		list("heads", "Капитан", "crew:Captain", null, 1, TRUE),
		list("heads", "Глава персонала", "crew:Head of Personnel", null, 1, FALSE),
		list("heads", "Глава СБ", "crew:Head of Security", null, 1, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "revolution", list("name" = "Вывести из строя всех глав", "target" = "heads")),
		list(/datum/antag_training_scenario_objective/side_down, "heads", list("name" = "Вывести из строя глав революции", "target" = "revolution")),
	)

/datum/antag_training_scenario/malf
	id = "malf"
	name = "ИИ-сбой"
	desc = "«Эхо-7». Сбойный ИИ в ядре с киборгами должен продержаться, инженеры и научный руководитель - вывести его и киборгов из строя."
	order = 6
	sector = "station"
	min_players = 2
	max_players = 7
	sides = list("ai" = list("name" = "ИИ", "spawn" = "ai"), "crew" = list("name" = "Инженеры и РД", "spawn" = "arrivals"))
	slot_specs = list(
		list("ai", "Сбойный ИИ", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/creature/malf_ai, 1, TRUE),
		list("ai", "Киборг", "silicon:cyborg", null, 2, FALSE),
		list("crew", "Инженер", "crew:Station Engineer", null, 3, TRUE),
		list("crew", "Научный руководитель", "crew:Research Director", null, 1, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/survive, "ai", list("minutes" = 10)),
		list(/datum/antag_training_scenario_objective/side_down, "crew", list("name" = "Вывести из строя ИИ и киборгов", "target" = "ai")),
	)

/datum/antag_training_scenario/xeno
	id = "xeno"
	name = "Ксеноугроза"
	desc = "Нижний ярус. Ксеноморфы выходят из дальних комнат, СБ держит вход. Чья сторона первой окажется вне игры, та и проиграла; до конца отсчёта без итога - победа СБ."
	order = 7
	sector = "dark"
	min_players = 2
	max_players = 6
	timeout_winner = "security"
	sides = list("xeno" = list("name" = "Ксеноморфы", "spawn" = "depths"), "security" = list("name" = "СБ", "spawn" = "entry"))
	slot_specs = list(
		list("xeno", "Ксеноморф", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/creature/xeno, 3, TRUE),
		list("security", "Офицер СБ", "crew:Security Officer", null, 3, TRUE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "xeno", list("name" = "Вывести из строя всю СБ", "target" = "security")),
		list(/datum/antag_training_scenario_objective/side_down, "security", list("name" = "Уничтожить ксеноморфов", "target" = "xeno")),
	)

/datum/antag_training_scenario/cult
	id = "cult"
	name = "Культ"
	desc = "«Эхо-7». Кровавые культисты начинают в ритуальном зале, против них священник и СБ. Побеждает сторона, которая первой выведет из строя всех противников; до конца отсчёта без итога - победа экипажа."
	order = 8
	sector = "station"
	min_players = 2
	max_players = 6
	timeout_winner = "crew"
	sides = list("cult" = list("name" = "Культ", "spawn" = "ritual"), "crew" = list("name" = "Священник и СБ", "spawn" = "security"))
	slot_specs = list(
		list("cult", "Культист", "crew:Assistant", /datum/antag_training_program/antag/cult, 3, TRUE),
		list("crew", "Священник", "crew:Chaplain", null, 1, TRUE),
		list("crew", "Офицер СБ", "crew:Security Officer", null, 2, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "cult", list("name" = "Вывести из строя священника и СБ", "target" = "crew")),
		list(/datum/antag_training_scenario_objective/side_down, "crew", list("name" = "Вывести из строя культистов", "target" = "cult")),
	)

/datum/antag_training_scenario/cult_war
	id = "cult_war"
	name = "Война культов"
	desc = "«Эхо-7». Кровавый культ Нар'Си начинает в ритуальном зале, слуги Ратвара - на мостике. Побеждает сторона, которая первой выведет из строя всех культистов противника; до конца отсчёта без итога - ничья."
	order = 9
	sector = "station"
	min_players = 2
	max_players = 6
	sides = list("blood" = list("name" = "Культ Нар'Си", "spawn" = "ritual"), "clock" = list("name" = "Слуги Ратвара", "spawn" = "command"))
	slot_specs = list(
		list("blood", "Культист Нар'Си", "crew:Assistant", /datum/antag_training_program/antag/cult, 3, TRUE),
		list("clock", "Слуга Ратвара", "crew:Assistant", /datum/antag_training_program/antag/clockcult, 3, TRUE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "blood", list("name" = "Вывести из строя слуг Ратвара", "target" = "clock")),
		list(/datum/antag_training_scenario_objective/side_down, "clock", list("name" = "Вывести из строя культистов Нар'Си", "target" = "blood")),
	)

/// Пустой лист: слоты и цели из библиотеки собирает лидер; без целей партия идёт до «Подвести итог».
/datum/antag_training_scenario/custom
	id = "custom"
	name = "Своя сборка"
	desc = "Пустой лист в любом секторе или на площадке хаба: стороны, роли и программы на выбор лидера, любые сочетания, которые выдерживает тело. Цели сторон лидер берёт из библиотеки с местами этого сектора или площадки; без целей партия идёт, пока лидер не подведёт итог."
	order = 100
	time_limit = 0
	objectives_editable = TRUE
	sides = list("a" = list("name" = "Сторона А"), "b" = list("name" = "Сторона Б"), "c" = list("name" = "Сторона В"), "d" = list("name" = "Сторона Г"))

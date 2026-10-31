/datum/techweb_node/netrunning
	id = "netrunning"
	display_name = "Сетевая инфраструктура"
	description = "Проводные терминалы, серверы данных и инструменты для работы с локальными сетями станции."
	prereq_ids = list("comptech", "datatheory")
	design_ids = list("netrun_terminal", "netrun_server", "netrun_shard", "netrun_deck", "netrun_daemon_buffer", "netrun_daemon_autobreach", "netrun_daemon_forge", "netrun_agent_mender", "netrun_combat_suite")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2000)

/datum/techweb_node/netrunning_neural
	id = "netrunning_neural"
	display_name = "Нейросетевые интерфейсы"
	description = "Прямое подключение нервной системы к сети и выращивание самообучающихся сетевых процессов."
	prereq_ids = list("netrunning", "cyber_implants")
	design_ids = list("ci-netlink", "netrun_seed", "netrun_deck_advanced", "netrun_daemon_icepick", "netrun_daemon_cloak", "netrun_agent_sentinel", "netrun_agent_workshop", "netrun_assault_suite", "netrun_daemon_composites")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 4000)

/datum/design/board/netrun_terminal
	name = "Computer Design (Network Terminal)"
	desc = "Плата проводного терминала локальной сети."
	id = "netrun_terminal"
	build_path = /obj/item/circuitboard/computer/netrun_terminal
	category = list("Computer Boards")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/netrun_server
	name = "Machine Design (Data Server)"
	desc = "Плата стойки хранения данных."
	id = "netrun_server"
	build_path = /obj/item/circuitboard/machine/netrun_server
	category = list("Research Machinery")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_shard
	name = "Data Shard"
	desc = "Переносной носитель для сетевых файлов."
	id = "netrun_shard"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 300, /datum/material/silver = 100)
	build_path = /obj/item/netrun_shard
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_deck
	name = "Cyberdeck"
	desc = "Переносной терминал с кабелем прямого подключения."
	id = "netrun_deck"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 1500, /datum/material/glass = 1000, /datum/material/gold = 300)
	build_path = /obj/item/netrun_deck
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_deck_advanced
	name = "Military Cyberdeck"
	desc = "Дека с расширенным буфером и памятью."
	id = "netrun_deck_advanced"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 1500, /datum/material/gold = 600, /datum/material/diamond = 200)
	build_path = /obj/item/netrun_deck/advanced
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/cyberimp_netlink
	name = "Neural Netlink Implant"
	desc = "Имплант прямого подключения к сети."
	id = "ci-netlink"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 60
	materials = list(/datum/material/iron = 600, /datum/material/glass = 600, /datum/material/silver = 500, /datum/material/gold = 500)
	build_path = /obj/item/organ/cyberimp/brain/netlink
	category = list("Implants")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_seed
	name = "AI Seed Shard"
	desc = "Кристалл с зачатком самообучающегося сетевого процесса."
	id = "netrun_seed"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 1000, /datum/material/diamond = 500, /datum/material/bluespace = 500)
	build_path = /obj/item/netrun_seed
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_daemon_buffer
	name = "Buffer Expansion Daemon"
	desc = "Шард с buffer.exe: дополнительная ячейка буфера протокола взлома."
	id = "netrun_daemon_buffer"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 500, /datum/material/silver = 150, /datum/material/gold = 200)
	build_path = /obj/item/netrun_shard/buffer
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_daemon_autobreach
	name = "Automatic Breach Daemon"
	desc = "Шард с autobreach.exe: медленный гарантированный подбор доступа без миниигры."
	id = "netrun_daemon_autobreach"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 700, /datum/material/gold = 400, /datum/material/silver = 200)
	build_path = /obj/item/netrun_shard/autobreach
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_daemon_icepick
	name = "ICE Analysis Daemon"
	desc = "Шард с icepick.exe: анализ защиты и атака сетевой прошивки."
	id = "netrun_daemon_icepick"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 600, /datum/material/gold = 500, /datum/material/diamond = 100)
	build_path = /obj/item/netrun_shard/icepick
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_daemon_cloak
	name = "Trace Suppression Daemon"
	desc = "Шард с cloak.exe: снижение прироста трассировки на 30%."
	id = "netrun_daemon_cloak"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 600, /datum/material/silver = 200, /datum/material/gold = 400, /datum/material/bluespace = 100)
	build_path = /obj/item/netrun_shard/cloak
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_combat_suite
	name = "Network Defense Suite"
	desc = "Базовые программы сетевой защиты: strike.exe, barrier.exe, patch.exe."
	id = "netrun_combat_suite"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 700, /datum/material/silver = 400, /datum/material/gold = 300)
	build_path = /obj/item/netrun_shard/combat
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/obj/item/netrun_shard/assault_suite
	name = "data shard (advanced network defense)"
	desc = "Тяжёлый удар и программа прерывания враждебных процессов."
	icon_state = "datadisk3"
	preload_programs = list("assault", "blackout", "fortify", "lance", "aegis", "jam")

/datum/design/netrun_assault_suite
	name = "Advanced Network Defense Suite"
	desc = "Программы assault.exe, blackout.exe и fortify.exe."
	id = "netrun_assault_suite"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 900, /datum/material/gold = 600, /datum/material/diamond = 300)
	build_path = /obj/item/netrun_shard/assault_suite
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

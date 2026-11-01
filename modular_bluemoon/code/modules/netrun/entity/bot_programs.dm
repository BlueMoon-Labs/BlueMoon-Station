/**
 * Программа поведения автономного бота: сторона, снаряжение и план.
 * Новый архетип - подтип со своим `id`; реестр находит его сам.
 */
/datum/netrun_bot_program
	var/id
	var/name = "Автономный процесс"
	var/desc = ""
	var/faction = NETRUN_FACTION_ROGUE
	/// Sanctioned station processes do not wake ICE and are trusted by station fortresses.
	var/sanctioned = FALSE
	var/max_integrity = 100
	var/storage = 8 * NETRUN_STORAGE_SCALE
	/// Combat programs installed as real files at spawn.
	var/list/programs = list()
	/// Optional capabilities/tools are real daemon files and survive recall normally.
	var/list/daemons = list()
	var/name_prefix = "PROC"
	var/avatar = "orb"
	var/accent = "silver"
	var/tagline = ""
	var/console_type = /datum/netrun_console/entity/bot
	/// Capabilities are assembled from data; new behavior does not change the brain dispatcher.
	var/list/behavior_modules = list(
		/datum/netrun_agent_behavior/pattern/temperament,
		/datum/netrun_agent_behavior/pattern/communication,
		/datum/netrun_entity_module/bot_lifecycle,
		/datum/netrun_entity_module/bot_stun,
		/datum/netrun_entity_module/bot_local/combat,
		/datum/netrun_entity_module/bot_return_wait,
		/datum/netrun_entity_module/bot_goals)
	var/list/extra_behavior_modules = list()
	var/think_idle = 4 SECONDS
	var/think_busy = 2 SECONDS
	var/think_combat = 1.2 SECONDS
	/// Below this share of integrity the bot leaves a fight it can leave.
	var/flee_ratio = 0.3
	/// Programs distributed as launchable `.bot` files have a non-zero size.
	var/file_size = 0
	/// The spawn LAN's key file lets the bot move freely inside that LAN, like a patrol.
	var/carries_lan_key = FALSE
	/// Round visitors depart and can be replaced by later arrivals; owned agents have no expiry.
	var/lifetime = 0

/datum/netrun_bot_program/proc/equip(mob/camera/netrun_entity/bot/bot)
	for(var/id in programs)
		var/datum/netrun_file/file = netrun_program_file(id)
		if(file && !bot.console.store_file(file))
			qdel(file)
	for(var/id in daemons)
		var/datum/netrun_file/file = netrun_daemon_file(id)
		if(file && !bot.console.store_file(file))
			qdel(file)
	var/datum/netrun_network/network = bot.host_node?.network
	if(carries_lan_key && !bot.is_network_visitor() && network && !network.isolated)
		bot.console.store_file(new /datum/netrun_file("[network.id].key", NETRUN_FILE_KEY, network.passcode, 1, network.id))

/datum/netrun_bot_program/proc/on_spawn(mob/camera/netrun_entity/bot/bot)
	return

/// Queue goals when the bot has none.
/datum/netrun_bot_program/proc/plan(datum/netrun_bot_brain/brain)
	brain.push_goal(new /datum/netrun_bot_goal/patrol(brain, patrol_networks(brain)))

/// Processes this program attacks on sight (besides ICE attacking it and remembered attackers).
/datum/netrun_bot_program/proc/is_enemy(datum/netrun_bot_brain/brain, mob/camera/netrun_entity/entity)
	if(!istype(entity) || QDELETED(entity))
		return FALSE
	return netrun_bot_factions_hostile(brain.owner.net_faction, entity.netrun_faction())

/// Patrol scope: null means every reachable LAN.
/datum/netrun_bot_program/proc/patrol_networks(datum/netrun_bot_brain/brain)
	var/datum/netrun_network/network = brain.owner.host_node?.network
	return network ? list(network.id) : null

/// Rogue processes fight everybody else; station and private processes coexist.
/proc/netrun_bot_factions_hostile(first, second)
	return SSnetrun.get_netrun_faction(first)?.hostile_to(second) || FALSE

/datum/controller/subsystem/netrun
	var/list/datum/netrun_bot_program/bot_programs

/datum/controller/subsystem/netrun/proc/get_bot_program(id)
	RETURN_TYPE(/datum/netrun_bot_program)
	if(!bot_programs)
		bot_programs = list()
		for(var/datum/netrun_bot_program/path as anything in subtypesof(/datum/netrun_bot_program))
			if(initial(path.id))
				var/datum/netrun_bot_program/program = new path
				bot_programs[program.id] = program
	return istext(id) ? bot_programs[id] : null

/// A launchable agent program as a real file.
/proc/netrun_bot_file(id)
	var/datum/netrun_bot_program/program = SSnetrun.get_bot_program(id)
	if(!program?.file_size)
		return null
	return new /datum/netrun_file/bot("[id].bot", NETRUN_FILE_BOT, id, program.file_size)

// MARK: Дикие процессы

/// Рейдер бродит по своей ЛВС, дерётся с ICE и чужими процессами и подбирает обломки.
/datum/netrun_bot_program/raider
	id = NETRUN_BOT_RAIDER
	name = "Рейдер"
	desc = "Дикий боевой процесс: дерётся с ICE и станционными процессами своей ЛВС, подбирает обломки."
	faction = NETRUN_FACTION_ROGUE
	max_integrity = 120
	programs = list("assault", "strike", "barrier", "needle")
	name_prefix = "RAID"
	avatar = "fox"
	accent = "rose"
	tagline = "ищет драку"
	flee_ratio = 0.2
	carries_lan_key = TRUE
	lifetime = 12 MINUTES

/datum/netrun_bot_program/raider/plan(datum/netrun_bot_brain/brain)
	var/datum/component/netrun_node/salvage = brain.find_salvage()
	if(salvage)
		brain.push_goal(new /datum/netrun_bot_goal/salvage(brain, salvage))
		return
	var/datum/component/netrun_node/prey = brain.find_nearby_node(TYPE_PROC_REF(/datum/netrun_bot_brain, node_has_ice))
	if(prey)
		brain.push_goal(new /datum/netrun_bot_goal/travel(brain, prey))
		return
	return ..()

/// A second visiting personality gathers real recoverable files rather than hunting ICE.
/datum/netrun_bot_program/scavenger
	id = "scavenger"
	name = "Сборщик обломков"
	desc = "Залётный процесс: ищет брошенные файлы, хранит добычу и отступает при угрозе."
	programs = list("strike", "barrier", "patch", "renew")
	name_prefix = "SCRAP"
	avatar = "moth"
	accent = "amber"
	tagline = "чужих файлов не бывает"
	carries_lan_key = TRUE
	lifetime = 10 MINUTES
	flee_ratio = 0.5

/datum/netrun_bot_program/scavenger/plan(datum/netrun_bot_brain/brain)
	var/datum/component/netrun_node/salvage = brain.find_salvage()
	if(salvage)
		brain.push_goal(new /datum/netrun_bot_goal/salvage(brain, salvage))
		return
	return ..()

// MARK: Станционные процессы

/// Санитар чинит станционные крепости своего отдела и сообщает полиции о диких процессах.
/datum/netrun_bot_program/custodian
	id = NETRUN_BOT_CUSTODIAN
	name = "Санитар сети"
	desc = "Станционный процесс обслуживания: чинит крепости отдела и сообщает полиции о диких процессах."
	faction = NETRUN_FACTION_STATION
	sanctioned = TRUE
	max_integrity = 100
	programs = list("strike", "patch", "needle")
	name_prefix = "CLEAN"
	avatar = "orb"
	accent = "mint"
	tagline = "обслуживание сети"
	console_type = /datum/netrun_console/entity/bot/custodian
	extra_behavior_modules = list(/datum/netrun_entity_module/bot_local/watch)
	think_idle = 6 SECONDS

/datum/netrun_bot_program/custodian/patrol_networks(datum/netrun_bot_brain/brain)
	var/datum/netrun_console/entity/bot/custodian/console = brain.owner.console
	return istype(console) && length(console.jurisdiction) ? console.jurisdiction : ..()

/datum/netrun_bot_program/custodian/plan(datum/netrun_bot_brain/brain)
	var/list/scope = patrol_networks(brain)
	for(var/address in SSnetrun.fortress_nodes)
		var/datum/component/netrun_node/node = SSnetrun.fortress_nodes[address]
		if(QDELETED(node) || node.fortress?.faction != NETRUN_FACTION_STATION || !node.network || (scope && !(node.network.id in scope)))
			continue
		if(length(node.fortress.damaged_modules()) && !brain.is_blacklisted(address))
			brain.push_goal(new /datum/netrun_bot_goal/repair(brain, node))
			return
	brain.push_goal(new /datum/netrun_bot_goal/patrol(brain, scope))

// MARK: Агенты игроков

/// Страж занимает узел и атакует посторонние процессы в нём.
/datum/netrun_bot_program/sentinel
	id = NETRUN_BOT_SENTINEL
	name = "Агент-страж"
	desc = "Охраняет указанный узел: атакует процессы без доступа ПОЛЬЗОВАТЕЛЯ, кроме владельца и его агентов."
	faction = NETRUN_FACTION_OWNER
	max_integrity = 120
	storage = 4 * NETRUN_STORAGE_SCALE
	programs = list("strike", "blackout", "barrier", "lance")
	name_prefix = "GUARD"
	avatar = "eye"
	accent = "violet"
	tagline = "охраняет узел"
	file_size = 4

/datum/netrun_bot_program/sentinel/plan(datum/netrun_bot_brain/brain)
	if(brain.order == "patrol")
		brain.push_goal(new /datum/netrun_bot_goal/patrol(brain))
		return
	brain.push_goal(new /datum/netrun_bot_goal/guard(brain, brain.post_node()))

/datum/netrun_bot_program/sentinel/is_enemy(datum/netrun_bot_brain/brain, mob/camera/netrun_entity/entity)
	if(!istype(entity) || QDELETED(entity))
		return FALSE
	var/personal_id = brain.owner.net_faction
	if(personal_id != NETRUN_FACTION_OWNER && SSnetrun.netrun_faction_family(personal_id) == NETRUN_FACTION_OWNER)
		if(personal_id == entity.netrun_faction())
			return FALSE
		return ..() || (brain.at_post() && entity.defense_threat() && entity.console.node_level(brain.owner.host_node) < NETRUN_ACCESS_USER)
	if(..())
		return TRUE
	return brain.at_post() && brain.trespasser(entity)

/// Ремонтник обслуживает крепости владельца в указанном узле.
/datum/netrun_bot_program/mender
	id = NETRUN_BOT_MENDER
	name = "Агент-ремонтник"
	desc = "Держится у указанного узла и чинит крепость владельца, пока у неё есть повреждения."
	faction = NETRUN_FACTION_OWNER
	max_integrity = 80
	storage = 4 * NETRUN_STORAGE_SCALE
	programs = list("patch", "renew")
	name_prefix = "MEND"
	avatar = "ghost"
	accent = "mint"
	tagline = "чинит укрепления"
	file_size = 4

/datum/netrun_bot_program/mender/plan(datum/netrun_bot_brain/brain)
	if(brain.order == "patrol")
		brain.push_goal(new /datum/netrun_bot_goal/patrol(brain))
		return
	var/datum/component/netrun_node/post = brain.post_node()
	if(post?.fortress && length(post.fortress.damaged_modules()))
		brain.push_goal(new /datum/netrun_bot_goal/repair(brain, post))
		return
	brain.push_goal(new /datum/netrun_bot_goal/guard(brain, post))

/// A private surveyor travels through the owner's actual grants and saves only
/// responses to delivered scan commands. It has no station inspection authority.
/datum/netrun_bot_program/surveyor
	id = "surveyor"
	name = "Агент-разведчик"
	desc = "Патрулирует доступные узлы и сохраняет результаты штатного сканирования в своей памяти."
	faction = NETRUN_FACTION_OWNER
	max_integrity = 70
	storage = 8 * NETRUN_STORAGE_SCALE
	programs = list("blackout", "patch", "jam")
	name_prefix = "SURVEY"
	avatar = "moth"
	accent = "cyan"
	tagline = "наблюдает и записывает"
	flee_ratio = 0.6
	file_size = 4

/datum/netrun_bot_program/surveyor/on_spawn(mob/camera/netrun_entity/bot/bot)
	bot.brain.order = "patrol"

/datum/netrun_bot_program/surveyor/plan(datum/netrun_bot_brain/brain)
	if(brain.order == "guard")
		brain.push_goal(new /datum/netrun_bot_goal/guard(brain, brain.post_node()))
		return
	var/datum/component/netrun_node/target = brain.patrol_destination(patrol_networks(brain))
	if(target)
		brain.push_goal(new /datum/netrun_bot_goal/survey(brain, target))
	else
		brain.push_goal(new /datum/netrun_bot_goal/guard(brain, brain.post_node()))

/// A private collector reuses ordinary salvage recovery and real memory limits.
/datum/netrun_bot_program/collector
	id = "collector"
	name = "Агент-сборщик"
	desc = "Ищет доступные обломки программ, собирает настоящие файлы и возвращает добычу при отзыве."
	faction = NETRUN_FACTION_OWNER
	max_integrity = 80
	storage = 12 * NETRUN_STORAGE_SCALE
	programs = list("barrier", "patch", "needle")
	name_prefix = "COLLECT"
	avatar = "orb"
	accent = "amber"
	tagline = "ничего не теряет"
	flee_ratio = 0.65
	file_size = 5

/datum/netrun_bot_program/collector/on_spawn(mob/camera/netrun_entity/bot/bot)
	bot.brain.order = "patrol"

/datum/netrun_bot_program/collector/plan(datum/netrun_bot_brain/brain)
	if(brain.order == "guard")
		brain.push_goal(new /datum/netrun_bot_goal/guard(brain, brain.post_node()))
		return
	var/datum/component/netrun_node/salvage = brain.find_salvage()
	if(salvage)
		brain.push_goal(new /datum/netrun_bot_goal/salvage(brain, salvage))
	else
		..()

/// A different loadout shares sentinel goals, faction policy and combat modules.
/datum/netrun_bot_program/sentinel/interceptor
	id = "interceptor"
	name = "Агент-перехватчик"
	desc = "Страж с усиленной целостностью и оглушением: удерживает пост или патрулирует по приказу владельца."
	max_integrity = 150
	storage = 6 * NETRUN_STORAGE_SCALE
	programs = list("blackout", "strike", "fortify", "lance")
	name_prefix = "INTERCEPT"
	avatar = "eye"
	accent = "mint"
	tagline = "перекрывает проход"
	file_size = 5

/// The same attachable hacking capability works on any private agent with its
/// owned autobreach file. Profiles only choose loadout and autonomous policy.
/datum/netrun_bot_program/hacker
	id = "hacker"
	name = "Агент-взломщик"
	desc = "Открывает доступные рубежи обычным автовзломом и проходит через них; выполняет адресные приказы владельца."
	faction = NETRUN_FACTION_OWNER
	max_integrity = 90
	storage = 8 * NETRUN_STORAGE_SCALE
	programs = list("blackout", "patch", "jam")
	daemons = list("autobreach", "cloak")
	name_prefix = "HACK"
	avatar = "cipher"
	accent = "violet"
	tagline = "подбирает доступ"
	flee_ratio = 0.5
	file_size = 5

/datum/netrun_bot_program/hacker/on_spawn(mob/camera/netrun_entity/bot/bot)
	bot.brain.order = "patrol"

/datum/netrun_bot_program/hacker/plan(datum/netrun_bot_brain/brain)
	var/datum/netrun_entity_module/hacking/module = brain.owner.entity_modules["hacking"]
	var/datum/component/netrun_node/target = brain.order == "patrol" ? module?.pick_target(brain) : null
	if(target)
		brain.push_goal(new /datum/netrun_bot_goal/hack(brain, target))
	else
		brain.push_goal(new /datum/netrun_bot_goal/guard(brain, brain.post_node()))

/datum/netrun_bot_program/hacker/breacher
	id = "breacher"
	name = "Агент-пробойник"
	desc = "Более живучий взломщик с боевыми программами и icepick.exe; защита, стены крепостей и трассировка действуют обычно."
	max_integrity = 140
	storage = 10 * NETRUN_STORAGE_SCALE
	programs = list("assault", "barrier", "patch", "aegis")
	daemons = list("autobreach", "icepick", "cloak")
	name_prefix = "BREACH"
	avatar = "fox"
	accent = "rose"
	tagline = "расчищает рубеж"
	flee_ratio = 0.2
	file_size = 6

/obj/item/netrun_shard/agent_sentinel
	name = "data shard (sentinel.bot)"
	desc = "Шард с программой агента-стража. Запустите её из памяти сетевого клиента."
	icon_state = "datadisk3"

/obj/item/netrun_shard/agent_sentinel/Initialize(mapload)
	. = ..()
	file_store.insert(netrun_bot_file(NETRUN_BOT_SENTINEL), TRUE)

/obj/item/netrun_shard/agent_mender
	name = "data shard (mender.bot)"
	desc = "Шард с программой агента-ремонтника. Запустите её из памяти сетевого клиента."
	icon_state = "datadisk3"

/obj/item/netrun_shard/agent_mender/Initialize(mapload)
	. = ..()
	file_store.insert(netrun_bot_file(NETRUN_BOT_MENDER), TRUE)

/// Printable templates enable the in-world agent builder on any local client.
/obj/item/netrun_shard/agent_workshop
	name = "data shard (agent workshop)"
	desc = "Шаблоны частных агентов: страж, ремонтник, разведчик, сборщик, перехватчик, взломщик и пробойник. Скопируйте шаблон в свою память или создайте из него собственную конфигурацию."
	icon_state = "datadisk3"

/obj/item/netrun_shard/agent_workshop/Initialize(mapload)
	. = ..()
	for(var/id in list(NETRUN_BOT_SENTINEL, NETRUN_BOT_MENDER, "surveyor", "collector", "interceptor", "hacker", "breacher"))
		file_store.insert(netrun_bot_file(id), TRUE)

/datum/design/netrun_agent_workshop
	name = "Agent Workshop Templates"
	desc = "Шард с семью шаблонами частных агентов для настройки поведения, программ и персоны."
	id = "netrun_agent_workshop"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 1200, /datum/material/gold = 500, /datum/material/silver = 500)
	build_path = /obj/item/netrun_shard/agent_workshop
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_agent_mender
	name = "Mender Agent Program"
	desc = "Шард с mender.bot: агент чинит крепость владельца."
	id = "netrun_agent_mender"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 600, /datum/material/gold = 200, /datum/material/silver = 200)
	build_path = /obj/item/netrun_shard/agent_mender
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

/datum/design/netrun_agent_sentinel
	name = "Sentinel Agent Program"
	desc = "Шард с sentinel.bot: агент охраняет узел."
	id = "netrun_agent_sentinel"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 700, /datum/material/gold = 300, /datum/material/silver = 300)
	build_path = /obj/item/netrun_shard/agent_sentinel
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

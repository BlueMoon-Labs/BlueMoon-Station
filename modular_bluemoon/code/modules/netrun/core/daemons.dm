/**
 * A daemon definition describes one executable file and its passive effect.
 * Add a subtype to publish a new program; consoles resolve files through this registry.
 * Programs sharing a bonus_kind use their strongest bonus, without stacking copies.
 */
/datum/netrun_program/daemon
	name = "daemon.exe"
	desc = "Программа сетевого клиента."
	size = 1
	file_kind = NETRUN_FILE_DAEMON
	var/bonus_kind
	var/bonus = 0
	/// Optional independent effects. Each kind competes with legacy bonus_kind;
	/// neither duplicate files nor multiple matching effects are added together.
	var/list/effects
	/// Zero excludes a definition from ICE salvage (e.g. test-only definitions).
	var/loot_weight = 1

/datum/netrun_program/daemon/ui_entry()
	return list("id" = id, "name" = name, "desc" = desc, "size" = size, "bonus_kind" = bonus_kind, "bonus" = bonus, "effects" = effect_values())

/datum/netrun_program/daemon/proc/effect_bonus(kind)
	. = 0
	if(bonus_kind == kind && IS_FINITE(bonus))
		. = max(., bonus)
	var/value = effects?[kind]
	if(IS_FINITE(value))
		. = max(., value)

/// Metadata is a fresh list; callers cannot modify the shared registry definition.
/datum/netrun_program/daemon/proc/effect_values()
	var/list/result = list()
	if(istext(bonus_kind) && effect_bonus(bonus_kind) > 0)
		result[bonus_kind] = effect_bonus(bonus_kind)
	for(var/kind in effects)
		if(istext(kind) && effect_bonus(kind) > 0)
			result[kind] = effect_bonus(kind)
	return result

/// Compose the strongest handlers without retaining authority from a UI snapshot.
/datum/netrun_program/daemon/proc/collect_effects(list/strongest, list/sources)
	collect_effect(bonus_kind, effect_bonus(bonus_kind), strongest, sources)
	for(var/kind in effects)
		collect_effect(kind, effect_bonus(kind), strongest, sources)

/datum/netrun_program/daemon/proc/collect_effect(kind, strength, list/strongest, list/sources)
	if(!istext(kind) || !IS_FINITE(strength) || strength <= (strongest[kind] || 0))
		return
	strongest[kind] = strength
	if(sources)
		sources[kind] = src

/// Optional source-specific automatic tool timing; ordinary composites use the effect's timing.
/datum/netrun_program/daemon/proc/breach_duration(security, kind)
	return null

/**
 * One operation's inputs and results. Nullable fields select which values are
 * being calculated; no console, file or authority is retained by a shared effect.
 */
/datum/netrun_daemon_context
	var/breach_security
	var/breach_buffer
	var/breach_time
	var/trace_factor
	var/trace_decay
	var/latency
	var/disengage_grace
	var/target_kind
	var/target_security
	var/access_reward
	var/access_name
	var/automatic_duration
	var/capability
	var/capability_granted = FALSE

/// Effect objects own the behavior; executable definitions compose them by strength.
/datum/netrun_daemon_effect
	var/id
	var/list/capabilities

/datum/netrun_daemon_effect/proc/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	if(strength > 0 && context.capability && (context.capability in capabilities))
		context.capability_granted = TRUE

/datum/netrun_daemon_effect/buffer
	id = "buffer"

/datum/netrun_daemon_effect/buffer/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.breach_buffer))
		context.breach_buffer += strength

/datum/netrun_daemon_effect/icepick
	id = "icepick"
	capabilities = list("firmware")

/datum/netrun_daemon_effect/icepick/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.breach_security))
		context.breach_security = clamp(context.breach_security - strength, 1, 5)

/datum/netrun_daemon_effect/cloak
	id = "cloak"

/datum/netrun_daemon_effect/cloak/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.trace_factor))
		context.trace_factor *= max(0.1, 1 - strength)

/datum/netrun_daemon_effect/extend
	id = "extend"

/datum/netrun_daemon_effect/extend/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.breach_time))
		context.breach_time += strength * (10 SECONDS)

/datum/netrun_daemon_effect/overclock
	id = "overclock"

/datum/netrun_daemon_effect/overclock/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.latency))
		context.latency = max(1, round(context.latency / 3))

/datum/netrun_daemon_effect/scrub
	id = "scrub"

/datum/netrun_daemon_effect/scrub/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.trace_decay))
		context.trace_decay *= 1 + strength

/datum/netrun_daemon_effect/mapper
	id = "mapper"
	capabilities = list("reveal_nodes")

/datum/netrun_daemon_effect/skeleton
	id = "skeleton"

/datum/netrun_daemon_effect/skeleton/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(context.target_kind == "node" && !isnull(context.access_reward))
		context.access_reward = max(context.access_reward, NETRUN_ACCESS_ROOT)
		context.access_name = "ОТМЫЧКА"

/datum/netrun_daemon_effect/phantom
	id = "phantom"

/datum/netrun_daemon_effect/phantom/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.disengage_grace))
		context.disengage_grace *= 1 + strength

/datum/netrun_daemon_effect/siphon
	id = "siphon"
	capabilities = list("siphon")

/datum/netrun_daemon_effect/forge
	id = "forge"
	capabilities = list("forge")

/datum/netrun_daemon_effect/black_ice
	id = "black_ice"
	capabilities = list("black_ice")

/datum/netrun_daemon_effect/autobreach
	id = "autobreach"
	capabilities = list("autobreach")
	var/base_duration = 10 SECONDS
	var/security_duration = 4 SECONDS
	var/network_duration = 8 SECONDS

/datum/netrun_daemon_effect/autobreach/proc/breach_duration(security, kind)
	return base_duration + clamp(security, 1, 5) * security_duration + (kind == "network" ? network_duration : 0)

/datum/netrun_daemon_effect/autobreach/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	if(!isnull(context.automatic_duration))
		var/source_duration = source?.breach_duration(context.target_security, context.target_kind)
		context.automatic_duration = isnull(source_duration) ? breach_duration(context.target_security, context.target_kind) : source_duration

/datum/controller/subsystem/netrun
	var/list/datum/netrun_daemon_effect/daemon_effects

/datum/controller/subsystem/netrun/proc/get_daemon_effect(id)
	RETURN_TYPE(/datum/netrun_daemon_effect)
	if(!daemon_effects)
		daemon_effects = list()
		for(var/datum/netrun_daemon_effect/path as anything in subtypesof(/datum/netrun_daemon_effect))
			var/effect_id = initial(path.id)
			if(effect_id)
				daemon_effects[effect_id] = new path
	return istext(id) ? daemon_effects[lowertext(trim(id))] : null

/datum/netrun_program/daemon/buffer
	id = "buffer"
	name = "buffer.exe"
	desc = "Увеличивает буфер протокола взлома на одну ячейку. Копии не усиливают эффект."
	size = 2
	bonus_kind = "buffer"
	bonus = 1

/datum/netrun_program/daemon/icepick
	id = "icepick"
	name = "icepick.exe"
	desc = "Снижает защиту цели при подборе на один уровень и позволяет атаковать поддерживаемую прошивку."
	size = 3
	bonus_kind = "icepick"
	bonus = 1

/datum/netrun_program/daemon/cloak
	id = "cloak"
	name = "cloak.exe"
	desc = "Снижает прирост трассировки на 30%. Копии не усиливают эффект."
	size = 3
	bonus_kind = "cloak"
	bonus = 0.3

/datum/controller/subsystem/netrun
	var/list/datum/netrun_program/daemon/daemons

/// Lazy construction also supports preloaded shards created during map initialization.
/datum/controller/subsystem/netrun/proc/get_daemon(id)
	RETURN_TYPE(/datum/netrun_program/daemon)
	if(!daemons)
		daemons = list()
		for(var/datum/netrun_program/daemon/path as anything in subtypesof(/datum/netrun_program/daemon))
			var/daemon_id = initial(path.id)
			if(!daemon_id || initial(path.file_kind) != NETRUN_FILE_DAEMON)
				continue
			daemons[daemon_id] = new path
	return istext(id) ? daemons[lowertext(trim(id))] : null

/// Shared discovery metadata for help, CLI and future interfaces.
/datum/controller/subsystem/netrun/proc/daemon_definitions()
	get_daemon(null)
	. = list()
	for(var/id in daemons)
		var/datum/netrun_program/daemon/daemon = daemons[id]
		. += list(daemon.ui_entry())

// Individually printable programs, with the same file format as the existing breach suite.
/obj/item/netrun_shard/buffer
	name = "data shard (buffer.exe)"
	desc = "Шард с программой расширения буфера сетевого клиента. Вставьте в деку или терминал."
	icon_state = "datadisk2"
	preload_daemons = list("buffer")

/obj/item/netrun_shard/icepick
	name = "data shard (icepick.exe)"
	desc = "Шард с программой анализа защиты и атаки сетевых контроллеров."
	icon_state = "datadisk2"
	preload_daemons = list("icepick")

/obj/item/netrun_shard/cloak
	name = "data shard (cloak.exe)"
	desc = "Шард с программой сокрытия активности сетевого клиента от систем трассировки."
	icon_state = "datadisk2"
	preload_daemons = list("cloak")

// MARK: Расширенный пул программ

/datum/netrun_program/daemon/extend
	id = "extend"
	name = "extend.exe"
	desc = "Продлевает окно протокола взлома: +10 секунд на демона. Копии не усиливают эффект."
	size = 2
	bonus_kind = "extend"
	bonus = 1

/datum/netrun_program/daemon/overclock
	id = "overclock"
	name = "overclock.exe"
	desc = "Разгоняет сетевой стек: удалённые операции идут почти без задержки маршрута."
	size = 3
	bonus_kind = "overclock"
	bonus = 1

/datum/netrun_program/daemon/scrub
	id = "scrub"
	name = "scrub.exe"
	desc = "Ускоряет спад трассировки в простое вдвое. Копии не усиливают эффект."
	size = 2
	bonus_kind = "scrub"
	bonus = 1

/datum/netrun_program/daemon/mapper
	id = "mapper"
	name = "mapper.exe"
	desc = "Разведка топологии: на карте видны машины и за закрытыми шлюзами подсетей."
	size = 2
	bonus_kind = "mapper"
	bonus = 1

/datum/netrun_program/daemon/skeleton
	id = "skeleton"
	name = "skeleton.exe"
	desc = "Дорогой армейский ключ: один взлом узла сразу выдаёт ROOT вместо пользователя. Расходуется редко — держите на крайний случай."
	size = 5
	bonus_kind = "skeleton"
	bonus = 1
	loot_weight = 0.2

/datum/netrun_program/daemon/phantom
	id = "phantom"
	name = "phantom.exe"
	desc = "Удлиняет окно «след потерян» после заметания следов: лёд дольше не перезахватывает процесс. Копии не усиливают эффект."
	size = 3
	bonus_kind = "phantom"
	bonus = 1

/datum/netrun_program/daemon/siphon
	id = "siphon"
	name = "siphon.exe"
	desc = "Открывает команду массового слива: за один запрос копирует все читаемые файлы узла в память."
	size = 3
	bonus_kind = "siphon"
	bonus = 1

/// Guaranteed progress replaces the puzzle, not route/access validation or ICE.
/datum/netrun_program/daemon/autobreach
	id = "autobreach"
	name = "autobreach.exe"
	desc = "Автовзлом без случайного провала: 14–30 секунд для узла, 22–38 для ЛВС. Даёт USER узла или гостевой вход в ЛВС; связь и программа должны сохраняться. Прошивка требует ручного взлома."
	size = 3
	bonus_kind = "autobreach"
	bonus = 1
	var/base_duration = 10 SECONDS
	var/security_duration = 4 SECONDS
	var/network_duration = 8 SECONDS

/datum/netrun_program/daemon/autobreach/breach_duration(security, kind)
	return base_duration + clamp(security, 1, 5) * security_duration + (kind == "network" ? network_duration : 0)

/obj/item/netrun_shard/autobreach
	name = "data shard (autobreach.exe)"
	desc = "Шард с медленным детерминированным подбором сетевого доступа."
	icon_state = "datadisk2"
	preload_daemons = list("autobreach")

// Печатаемые/добываемые шарды с новыми программами
/obj/item/netrun_shard/extend
	name = "data shard (extend.exe)"
	icon_state = "datadisk2"
	preload_daemons = list("extend")

/obj/item/netrun_shard/overclock
	name = "data shard (overclock.exe)"
	icon_state = "datadisk2"
	preload_daemons = list("overclock")

/obj/item/netrun_shard/scrub
	name = "data shard (scrub.exe)"
	icon_state = "datadisk2"
	preload_daemons = list("scrub")

/obj/item/netrun_shard/mapper
	name = "data shard (mapper.exe)"
	icon_state = "datadisk2"
	preload_daemons = list("mapper")

/obj/item/netrun_shard/phantom
	name = "data shard (phantom.exe)"
	icon_state = "datadisk2"
	preload_daemons = list("phantom")

/obj/item/netrun_shard/siphon
	name = "data shard (siphon.exe)"
	icon_state = "datadisk2"
	preload_daemons = list("siphon")

/obj/item/netrun_shard/skeleton
	name = "data shard (skeleton.exe)"
	desc = "Шард с редкой программой-отмычкой. Военного образца."
	icon_state = "datadisk3"
	preload_daemons = list("skeleton")

/obj/item/netrun_shard/fullsuite
	name = "data shard (full breach suite)"
	desc = "Набор программ опытного сетевика: буфер, разведка, разгон и заметание следов."
	icon_state = "datadisk3"
	preload_daemons = list("buffer", "icepick", "cloak", "mapper", "overclock", "scrub")

// Composite loadouts use the same native effect consumers. Their storage and
// competing effects are explicit; no extra timer or effect-specific dispatcher.
/datum/netrun_program/daemon/ghostlink
	id = "ghostlink"
	name = "ghostlink.exe"
	desc = "Снижает рост трассировки на 20% и вдвое ускоряет её штатное затухание в простое. Компактнее двух программ, но маскировка слабее отдельного cloak.exe."
	size = 4
	effects = list("cloak" = 0.2, "scrub" = 1)
	loot_weight = 0.6

/datum/netrun_program/daemon/breachkit
	id = "breachkit"
	name = "breachkit.exe"
	desc = "Объединяет icepick и расширение буфера: защита подбора ниже на один уровень, буфер ручного протокола больше на один. Занимает пять ячеек; ROOT и автоматический взлом прошивки не выдаёт."
	size = 5
	effects = list("icepick" = 1, "buffer" = 1)
	loot_weight = 0.35

/datum/netrun_program/daemon/analyst
	id = "analyst"
	name = "analyst.exe"
	desc = "Разведка закрытых сегментов и массовый слив читаемых файлов в одном пакете. Команды сохраняют обычные требования доступа и вместимости."
	size = 4
	effects = list("mapper" = 1, "siphon" = 1)
	loot_weight = 0.5

/obj/item/netrun_shard/composites
	name = "data shard (composite daemon suite)"
	desc = "Составные программы ghostlink, breachkit и analyst. Каждый эффект использует обычные правила клиента; копии не складываются."
	icon_state = "datadisk3"
	preload_daemons = list("ghostlink", "breachkit", "analyst")

/datum/design/netrun_daemon_composites
	name = "Composite Network Daemons"
	desc = "Шард с составными программами маскировки, анализа и подготовки взлома."
	id = "netrun_daemon_composites"
	build_type = PROTOLATHE
	materials = list(/datum/material/glass = 1800, /datum/material/gold = 1000, /datum/material/silver = 1200)
	build_path = /obj/item/netrun_shard/composites
	category = list("Computer Parts")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SCIENCE

// MARK: Лорные документы

/// Пул архивных документов, которые раскладываются по серверам станции в начале раунда.
/// Формат: list(имя_файла, текст).
/proc/netrun_lore_documents()
	return list(
		list("служебная_записка.txt", "Кому: всем отделам. От: ИТ-службы.\n\nНапоминаем: передача ключей доступа ЛВС по открытым каналам запрещена. \
			Инциденты последней недели (несанкционированные переходы в инженерной подсети) расследуются. Смените коды доступа."),
		list("инцидент_0x4F.log", "АВТО-ОТЧЁТ СИСТЕМЫ ЗАЩИТЫ\nОбнаружен резидентный процесс в сегменте связи. Трассировка прервана: цель заместила следы. \
			Патрульный процесс перенаправлен. Рекомендована ротация ключей."),
		list("заметка.txt", "Если читаешь это — значит, добрался до сервера. Не доверяй \"официальным\" логам переговоров, их чистят. \
			Настоящие копии я держу отдельно. Ищи шард с пометкой \"архив\"."),
		list("протокол_резервирования.txt", "Серверы данных реплицируют техвеб раз в смену. При потере узла восстановление — с ближайшего реле. \
			Пароль сервера сообщений хранится локально; при компрометации сбросить вручную."),
		list("черновик_приказа.txt", "ПРОЕКТ. В связи с участившимися сетевыми вторжениями ввести патрулирование подсетей автономными процессами защиты (ICE). \
			Санкционировать уничтожение неопознанных резидентных процессов."),
		list("личный_дневник.txt", "День сорок второй в сети. Тело давно остыло, а я всё ещё здесь, между узлами. \
			Говорят, если заместать следы достаточно часто, тебя перестанут искать. Пока работает."),
		list("техзаметка.txt", "ЛВС теперь кластеризованы по отделам: один ключ открывает весь отдел. \
			Удобно для нас, удобно и для них. Держите ключи при себе."),
		list("перехват.txt", "...получено с сервера сообщений...\n\[ЗАШИФРОВАНО\]\nДля расшифровки нужен пароль сервера. Без него — только метаданные."),
	)

/// Разовая раскладка лорных документов по случайным серверным/терминальным узлам.
/datum/controller/subsystem/netrun/proc/initialize_lore()
	lore_initialized = TRUE
	var/list/pool = netrun_lore_documents()
	if(!length(pool))
		return
	var/list/hosts = list()
	for(var/address in nodes_by_address)
		var/datum/component/netrun_node/node = nodes_by_address[address]
		if(QDELETED(node) || QDELETED(node.parent) || !node.file_store)
			continue
		if(node.node_type == NETRUN_NODE_SERVER || node.node_type == NETRUN_NODE_TERMINAL)
			hosts += node
	var/placed = 0
	while(placed < NETRUN_MAX_LORE_FILES && length(hosts) && length(pool))
		var/datum/component/netrun_node/node = pick_n_take(hosts)
		var/list/doc = pick_n_take(pool)
		var/datum/netrun_file/file = new(doc[1], NETRUN_FILE_TEXT, doc[2], 0)
		node.file_store.insert(file, TRUE)
		node.add_log("В хранилище обнаружен архивный документ: [doc[1]].")
		placed++

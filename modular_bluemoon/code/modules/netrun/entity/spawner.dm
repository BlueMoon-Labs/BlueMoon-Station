/// «Семя ИИ»: вставленное в сервер данных, порождает сетевую сущность для призрака
/obj/item/netrun_seed
	name = "AI seed shard"
	desc = "Кристалл с недоразвитой нейросетевой матрицей. В сервере данных из неё может вырасти самостоятельный сетевой процесс."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"
	w_class = WEIGHT_CLASS_TINY

/obj/machinery/netrun_server
	/// Спавнеры гост-роли, выросшие из вставленных семян
	var/list/obj/effect/mob_spawn/netrun_entity/seed_spawners

/obj/machinery/netrun_server/Destroy()
	QDEL_LIST(seed_spawners)
	return ..()

/obj/machinery/netrun_server/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/netrun_seed))
		if(!is_operational())
			to_chat(user, span_warning("Сервер обесточен."))
			return TRUE
		if(!user.temporarilyRemoveItemFromInventory(I))
			return TRUE
		qdel(I)
		plant_seed()
		to_chat(user, span_notice("Вы вставляете семя в [src]. Индикаторы начинают мерцать в неровном ритме."))
		return TRUE
	return ..()

/// Загрузить семя: появляется точка спавна в меню гост-ролей
/obj/machinery/netrun_server/proc/plant_seed(announce = TRUE)
	var/obj/effect/mob_spawn/netrun_entity/spawner = new(get_turf(src))
	spawner.server = src
	LAZYADD(seed_spawners, spawner)
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.network?.add_log("На узле [node.address] запущен самообучающийся процесс.")
	if(announce)
		notify_ghosts("В [src] ([get_area_name(src, TRUE)]) зарождается сетевая сущность. Роль доступна в меню гост-ролей.", source = src, action = NOTIFY_ATTACK, ghost_sound = 'sound/machines/chime.ogg', header = "Сетевая сущность")
	return spawner

/obj/machinery/netrun_server/examine(mob/user)
	. = ..()
	if(LAZYLEN(seed_spawners))
		. += span_notice("Индикаторы мерцают: внутри зреет сетевой процесс.")

/obj/machinery/netrun_server/attack_ghost(mob/dead/observer/user)
	. = ..()
	if(. || !LAZYLEN(seed_spawners))
		return
	var/obj/effect/mob_spawn/netrun_entity/spawner = seed_spawners[1]
	spawner.attack_ghost(user)

// MARK: Спавнер гост-роли

/obj/effect/mob_spawn/netrun_entity
	name = "Сетевая сущность"
	job_description = "Сетевая сущность"
	mob_name = "сетевая сущность"
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	density = FALSE
	roundstart = FALSE
	death = FALSE
	banType = ROLE_POSIBRAIN
	category = "midround"
	short_desc = "Вы — самообучающийся процесс, выросший в сервере данных станции."
	flavour_text = "Вы живёте в сети: перемещаетесь между машинами, говорите их динамиками и видите то, что видят они. \
	Слышать экипаж вы можете только через источники звука - например, интерком с включённым микрофоном."
	important_info = "Вы не антагонист. Экипаж может вычистить вас из любой машины."
	var/obj/machinery/netrun_server/server

/obj/effect/mob_spawn/netrun_entity/Destroy()
	if(server)
		LAZYREMOVE(server.seed_spawners, src)
		server = null
	return ..()

/obj/effect/mob_spawn/netrun_entity/allow_spawn(mob/user, silent = FALSE)
	if(QDELETED(server) || !server.is_operational())
		if(!silent)
			to_chat(user, span_warning("Сервер с семенем обесточен или разрушен."))
		return FALSE
	return TRUE

/obj/effect/mob_spawn/netrun_entity/create(ckey, name, load_character, spawn_type)
	if(QDELETED(src) || QDELETED(server))
		return
	var/datum/component/netrun_node/node = server.GetComponent(/datum/component/netrun_node)
	if(!node)
		return
	var/mob/camera/netrun_entity/entity = new(get_turf(server), node)
	var/entity_name = "PROC-[uppertext(copytext(md5("[world.time][rand(1, 99999)]"), 1, 5))]"
	entity.set_net_name(entity_name)
	if(ckey)
		entity.ckey = ckey
		to_chat(entity, examine_block("<p class='medium'>Вы — <b>[entity_name]</b>.</p><p>[short_desc]</p><p>[flavour_text]</p><span class='warning'>[important_info]</span>"))
		to_chat(entity, examine_block("<b>Первые шаги</b><p>Откройте карту, выберите соседний узел и используйте переход. В карточке узла есть «Справка узла»: она доступна уже с GUEST.</p>\
		<p>GUEST позволяет осмотреть узел, USER — читать файлы и выполнять обычные команды, ROOT — административные действия. Легальный доступ и взлом учитываются отдельно. Взлом повышает трассировку и может привлечь ICE.</p>\
		<p>В бою следите за целостностью, очередью ходов и очками действий; отступайте до разрушения процесса. Файлы и программы занимают память, шард расширяет хранилище.</p>\
		<p>В командной строке: help — команды, info — состояние, ls — локальные файлы и шард, mem — занятость памяти; Tab дополняет ввод. Ваша роль — общаться с экипажем и помогать станции; разрешения антагониста она не даёт.</p>"))
		log_game("NETRUN: [key_name(entity)] стал сетевой сущностью в [AREACOORD(server)]")
	node.network?.add_log("Процесс [entity_name] вышел на связь.")
	qdel(src)
	return entity

// MARK: Раундстарт

/datum/controller/subsystem/netrun
	/// Сколько серверов с загруженным семенем появляется на станции в начале раунда
	var/roundstart_seeds = 1
	var/roundstart_servers_created = FALSE

/datum/controller/subsystem/netrun/Initialize()
	. = ..()
	get_machine_transport().prepare_network()
	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(spawn_roundstart_servers)))

/datum/controller/subsystem/netrun/proc/spawn_roundstart_servers()
	if(roundstart_servers_created)
		return
	roundstart_servers_created = TRUE
	for(var/i in 1 to roundstart_seeds)
		var/turf/spot = find_server_spot()
		if(!spot)
			log_game("NETRUN: не нашлось места для раундстартового сервера с семенем.")
			return
		var/obj/machinery/netrun_server/server = new(spot)
		server.plant_seed(announce = FALSE)
		log_game("NETRUN: раундстартовый сервер с семенем в [AREACOORD(server)]")

/// Серверы инфраструктуры принадлежат телекоммуникациям; занятое оборудование не заменяется.
/datum/controller/subsystem/netrun/proc/find_server_spot()
	var/static/list/preferred = list(/area/tcommsat/server, /area/tcommsat)
	for(var/area_type in preferred)
		var/list/candidates = list()
		for(var/area/A in GLOB.sortedAreas)
			if(!istype(A, area_type))
				continue
			for(var/turf/open/floor/T in A)
				if(!is_station_level(T.z) || T.density || T.is_blocked_turf(TRUE))
					continue
				// Wall/floor machinery need not be dense. A mapped air alarm or vent
				// still owns its tile and must not acquire a server on top of it.
				if(locate(/obj/machinery) in T)
					continue
				candidates += T
		if(length(candidates))
			return pick(candidates)

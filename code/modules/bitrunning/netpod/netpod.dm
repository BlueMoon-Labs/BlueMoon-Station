#define BASE_DISCONNECT_DAMAGE 20
#define SCANNING_TOGGLE_COOLDOWN 5

GLOBAL_LIST_INIT(netpod_outfit_sets, list(
	"Basic" = list(
		/datum/outfit/job/bitrunner,
		/datum/outfit/job/assistant,
		/datum/outfit/job/bartender,
		/datum/outfit/job/janitor,
		/datum/outfit/job/curator,
	),
	"Cargo" = list(
		/datum/outfit/job/cargo_tech,
		/datum/outfit/job/quartermaster,
		/datum/outfit/job/miner,
	),
	"Engineering" = list(
		/datum/outfit/job/engineer,
		/datum/outfit/job/atmos,
	),
	"Medical" = list(
		/datum/outfit/job/doctor,
		/datum/outfit/job/paramedic,
		/datum/outfit/job/chemist,
	),
	"Science" = list(
		/datum/outfit/job/scientist,
		/datum/outfit/job/roboticist,
	),
	"Security" = list(
		/datum/outfit/job/security,
		/datum/outfit/job/detective,
	),
))

/obj/machinery/netpod
	name = "netpod"

	base_icon_state = "netpod"
	circuit = /obj/item/circuitboard/machine/netpod
	desc = "Связь с нетверсом. Оснащён набором кабелей для подключения к виртуальному домену."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "netpod"
	max_integrity = 300
	obj_flags = BLOCKS_CONSTRUCTION
	state_open = TRUE

	var/connected = FALSE
	var/datum/outfit/netsuit = /datum/outfit/job/bitrunner
	var/datum/weakref/avatar_ref
	var/datum/weakref/server_ref
	var/disconnect_damage
	var/list/cached_outfits = list()
	var/copy_body = FALSE
	var/scanning_can_toggle = 0
	var/stored_sensor_mode
	var/stored_has_sensor
	var/datum/weakref/stored_uniform_ref

/obj/machinery/netpod/Initialize()
	. = ..()

	disconnect_damage = BASE_DISCONNECT_DAMAGE
	find_server()

	RegisterSignal(src, COMSIG_ATOM_TAKE_DAMAGE, PROC_REF(on_damage_taken))
	RegisterSignal(src, COMSIG_MACHINERY_POWER_LOST, PROC_REF(on_power_loss))
	RegisterSignals(src, list(COMSIG_QDELETING,	COMSIG_MACHINERY_BROKEN),PROC_REF(on_broken))

	register_context()
	update_appearance()

/obj/machinery/netpod/Destroy()
	. = ..()

	cached_outfits.Cut()
	stored_uniform_ref = null

/obj/machinery/netpod/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	if(isnull(held_item))
		context[SCREENTIP_CONTEXT_LMB] = "Выбрать экипировку"
	else
		if(held_item.tool_behaviour == TOOL_SCREWDRIVER && !occupant && !state_open)
			context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Закрыть" : "Открыть"] панель"

		if(held_item.tool_behaviour == TOOL_CROWBAR)
			if(isnull(occupant))
				if(panel_open)
					context[SCREENTIP_CONTEXT_LMB] = "Разобрать"
				else
					context[SCREENTIP_CONTEXT_LMB] = "[state_open ? "Закрыть" : "Открыть"] крышку"
			else
				context[SCREENTIP_CONTEXT_LMB] = "Выбраться"

	context[SCREENTIP_CONTEXT_ALT_LMB] = "[copy_body ? "Отключить" : "Включить"] сканирование"
	return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/netpod/examine(mob/user)
	. = ..()

	. += span_notice("Панель обслуживания можно [EXAMINE_HINT("открутить")] и [panel_open ? "закрыть" : "открыть"].")
	if(isnull(occupant))
		if(panel_open)
			. += span_notice("Корпус можно [EXAMINE_HINT("поддеть")] и разобрать.")
		else
			. += span_notice("Крышку можно [EXAMINE_HINT("поддеть")] и [state_open ? "закрыть" : "открыть"].")

	if(isnull(server_ref?.resolve()))
		. += span_infoplain("Он ни к чему не подключён.")
		. += span_infoplain("Нетпод должен находиться в пределах 4 клеток от сервера.")
		return

	if(!isobserver(user))
		. += span_infoplain("Затащите себя в капсулу, чтобы подключиться.")
		. += span_infoplain("У него ограниченные реанимационные возможности. Пребывание в капсуле залечивает часть повреждений.")
		. += span_infoplain("Система безопасности предупредит находящегося внутри о вмешательстве.")
		if(copy_body)
			. += span_infoplain("Сканирование пользователя включено: при создании аватары будут выглядеть как пользователь.")
		. += span_infoplain("Alt-клик, чтобы [copy_body ? "отключить" : "включить"] сканирование пользователя.")

	if(isnull(occupant))
		. += span_infoplain("Сейчас он пуст.")
		return

	. += span_infoplain("Сейчас в нём находится [occupant].")

	if(isobserver(user))
		. += span_notice("Как наблюдатель, вы можете нажать на нетпод, чтобы перейти к его аватару.")
		return

	. += span_notice("Его можно вскрыть ломом, но система безопасности предупредит находящегося внутри.")

/obj/machinery/netpod/update_icon_state()
	if(!is_operational)
		icon_state = base_icon_state
		return ..()

	if(state_open)
		icon_state = base_icon_state + "_open_active"
		return ..()

	if(panel_open)
		icon_state = base_icon_state + "_panel"
		return ..()

	icon_state = base_icon_state + "_closed"
	if(occupant)
		icon_state += "_active"

	return ..()

/obj/machinery/netpod/MouseDrop_T(mob/target, mob/user)
	var/mob/living/carbon/player = user

	if(!iscarbon(player) || !is_operational || !state_open || player.buckled)
		return

	close_machine(target)

/obj/machinery/netpod/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!state_open && user == occupant)
		container_resist_act(user)

/obj/machinery/netpod/attack_ghost(mob/dead/observer/our_observer)
	var/our_target = avatar_ref?.resolve()
	if(isnull(our_target) || !our_observer.orbit(our_target))
		return ..()

/obj/machinery/netpod/proc/on_server_upgraded(obj/machinery/quantum_server/source)
	SIGNAL_HANDLER

	disconnect_damage = BASE_DISCONNECT_DAMAGE * (1 - source.servo_bonus)

/obj/machinery/netpod/AltClick(mob/user)
	if(world.time < scanning_can_toggle)
		return
	copy_body = !copy_body
	scanning_can_toggle = world.time + SCANNING_TOGGLE_COOLDOWN
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)
	user.balloon_alert_to_viewers("сканирование [copy_body ? "включено" : "отключено"]")

#undef BASE_DISCONNECT_DAMAGE
#undef SCANNING_TOGGLE_COOLDOWN

/obj/machinery/netpod/Exited(atom/movable/gone, direction)
	. = ..()
	if(!state_open && gone == occupant)
		container_resist_act(gone)

/obj/machinery/netpod/relaymove(mob/living/user, direction)
	if(!state_open)
		container_resist_act(user)

/obj/machinery/netpod/container_resist_act(mob/living/user)
	user.visible_message(span_notice("[occupant] выбирается из [src]!"),
		span_notice("Вы выбираетесь из [src]!"),
		span_notice("С шипением слышно, как открывается машина."))
	open_machine()

/obj/machinery/netpod/open_machine(drop = TRUE, density_to_set = FALSE)
	if(!isnull(stored_has_sensor))
		var/obj/item/clothing/under/stored_uniform = stored_uniform_ref?.resolve()
		if(istype(stored_uniform))
			stored_uniform.has_sensor = stored_has_sensor
			stored_uniform.sensor_mode = stored_sensor_mode
		stored_uniform_ref = null
		stored_has_sensor = null
		stored_sensor_mode = null

	if(!state_open)
		playsound(src, 'sound/machines/AirlockOpen.ogg', 60, TRUE, frequency = 65000)
		flick("[base_icon_state]_opening", src)
		SEND_SIGNAL(src, COMSIG_BITRUNNER_NETPOD_OPENED)
	use_power = IDLE_POWER_USE

	return ..()

/obj/machinery/netpod/close_machine(mob/user, density_to_set = TRUE)
	if(!state_open || panel_open || !is_operational || !iscarbon(user))
		return

	playsound(src, 'sound/machines/AirlockClose.ogg', 60, TRUE, frequency = 65000)
	flick("[base_icon_state]_closing", src)
	..()

	enter_matrix()

/obj/machinery/netpod/default_pry_open(obj/item/crowbar, mob/living/pryer)
	if(isnull(occupant) || !iscarbon(occupant))
		if(!state_open)
			if(panel_open)
				return FALSE
			open_machine()
		else
			shut_pod()

		return TRUE

	pryer.visible_message(
		span_danger("[pryer] начинает вскрывать [src]!"),
		span_notice("Вы начинаете вскрывать [src]."),
		span_notice("Слышен громкий скрежет металла.")
	)
	playsound(src, 'sound/machines/airlock_alien_prying.ogg', 100, TRUE)

	SEND_SIGNAL(src, COMSIG_BITRUNNER_CROWBAR_ALERT, pryer)

	if(do_after(pryer, 15 SECONDS, src))
		if(!state_open)
			sever_connection()
			open_machine()

	return TRUE

/obj/machinery/netpod/proc/shut_pod()
	state_open = FALSE
	playsound(src, 'sound/machines/AirlockClose.ogg', 60, TRUE, frequency = 65000)
	flick("[base_icon_state]_closing", src)
	density = TRUE

	update_appearance()

/obj/machinery/netpod/proc/make_outfit_collection(identifier, list/outfit_list)
	var/list/collection = list(
		"name" = identifier,
		"outfits" = list()
	)

	for(var/datum/outfit/outfit as anything in outfit_list)
		var/outfit_name = initial(outfit.name)
		if(findtext(outfit_name, "(") != 0 || findtext(outfit_name, "-") != 0)
			continue

		collection["outfits"] += list(list("path" = "[outfit]", "name" = outfit_name))

	return list(collection)

/obj/machinery/netpod/proc/resolve_outfit(text)
	var/path = text2path(text)
	if(!ispath(path, /datum/outfit))
		return

	for(var/wardrobe in cached_outfits)
		for(var/outfit in wardrobe["outfits"])
			if("[path]" == outfit["path"])
				return path

	message_admins("[usr]:[usr.ckey] попытался выбрать недоступную экипировку из нетпода")
	return

/obj/machinery/netpod/proc/on_broken(datum/source)
	SIGNAL_HANDLER

	sever_connection()

/obj/machinery/netpod/proc/on_damage_taken(datum/source, damage_amount)
	SIGNAL_HANDLER

	if(isnull(occupant) || !connected)
		return

	var/total = max_integrity - damage_amount
	var/integrity = (obj_integrity / total) * 100
	if(integrity > 50)
		return

	SEND_SIGNAL(src, COMSIG_BITRUNNER_NETPOD_INTEGRITY)

// Начисляет очки на счёт игрока в капсуле.
/obj/machinery/netpod/proc/on_domain_complete(datum/source, atom/movable/crate, reward_points)
	SIGNAL_HANDLER

	if(isnull(occupant) || !connected)
		return

	var/mob/living/player = occupant

	var/datum/bank_account/account = player.get_bank_account()
	if(isnull(account))
		return

	account.bitrunning_points += reward_points * 100

/obj/machinery/netpod/proc/on_domain_scrubbed(datum/source)
	SIGNAL_HANDLER

	var/mob/avatar = avatar_ref?.resolve()
	if(isnull(avatar))
		return

	QDEL_NULL(avatar)

/obj/machinery/netpod/proc/on_power_loss(datum/source)
	SIGNAL_HANDLER

	if(state_open)
		return

	if(isnull(occupant) || !connected)
		connected = FALSE
		open_machine()
		return

	sever_connection()

/obj/machinery/netpod/crowbar_act(mob/living/user, obj/item/tool)
	if(user.combat_mode)
		attack_hand(user)
		return ITEM_INTERACT_SUCCESS

	if(default_pry_open(tool, user) || default_deconstruction_crowbar(tool))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/netpod/screwdriver_act(mob/living/user, obj/item/tool)
	if(occupant)
		balloon_alert(user, "занято!")
		return ITEM_INTERACT_SUCCESS

	if(state_open)
		balloon_alert(user, "сначала закройте.")
		return ITEM_INTERACT_SUCCESS

	if(default_deconstruction_screwdriver(user, "[base_icon_state]_panel", "[base_icon_state]_closed", tool))
		update_appearance()
		ui_close(user)
		return ITEM_INTERACT_SUCCESS

/obj/machinery/netpod/ui_interact(mob/user, datum/tgui/ui)
	if(!is_operational || occupant)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NetpodOutfits")
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/machinery/netpod/ui_data()
	var/list/data = list()

	data["netsuit"] = "[netsuit]"
	return data

/obj/machinery/netpod/ui_static_data()
	var/list/data = list()

	if(!length(cached_outfits))
		for(var/set_name in GLOB.netpod_outfit_sets)
			cached_outfits += make_outfit_collection(set_name, GLOB.netpod_outfit_sets[set_name])

	data["collections"] = cached_outfits

	return data

/obj/machinery/netpod/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE
	switch(action)
		if("select_outfit")
			var/datum/outfit/new_suit = resolve_outfit(params["outfit"])
			if(new_suit)
				netsuit = new_suit
				return TRUE

	return FALSE

/obj/machinery/netpod/proc/add_healing(mob/living/target)
	if(target != occupant)
		return

	target.AddComponent(/datum/component/netpod_healing, pod = src)
	target.playsound_local(src, 'sound/effects/watersplash.ogg', 20, vary = TRUE)
	target.ExtinguishMob()
	use_power = ACTIVE_POWER_USE

/obj/machinery/netpod/proc/auto_disconnect()
	if(isnull(occupant) || state_open || connected)
		return

	var/mob/player = occupant
	player.playsound_local(src, 'sound/effects/splash.ogg', 60, TRUE)
	to_chat(player, span_notice("Машина отключается и начинает сливать энергию."))
	open_machine()

/obj/machinery/netpod/proc/disconnect_occupant(cause_damage = FALSE)
	connected = FALSE

	var/mob/living/mob_occupant = occupant
	if(isnull(occupant) || mob_occupant.stat == DEAD)
		open_machine()
		return

	mob_occupant.playsound_local(src, 'sound/magic/blink.ogg', 25, TRUE)
	mob_occupant.set_blurriness(4)
	mob_occupant.set_blindness(1)
	mob_occupant.Paralyze(2 SECONDS)

	if(!is_operational)
		open_machine()
		return

	var/heal_time = 1
	if(mob_occupant.health < mob_occupant.maxHealth)
		heal_time = (mob_occupant.stat + 2) * 5
	addtimer(CALLBACK(src, PROC_REF(auto_disconnect)), heal_time SECONDS, TIMER_UNIQUE|TIMER_STOPPABLE|TIMER_DELETE_ME)

	if(!cause_damage)
		return

	mob_occupant.flash_act(override_blindness_check = 1, visual = 1)
	var/brain_damage = max(0, disconnect_damage)
	mob_occupant.adjustOrganLoss(ORGAN_SLOT_BRAIN, brain_damage)
	if(brain_damage > 0)
		INVOKE_ASYNC(mob_occupant, TYPE_PROC_REF(/mob/living, emote), "scream")
	to_chat(mob_occupant, span_danger("Вас насильно отключили от аватара! Мысли путаются!"))

// Подключение игрока к аватару.
/obj/machinery/netpod/proc/enter_matrix()
	var/mob/living/carbon/human/neo = occupant
	if(!ishuman(neo) || neo.stat != CONSCIOUS || isnull(neo.mind))
		balloon_alert(neo, "неподходящий пользователь.")
		open_machine()
		return

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		balloon_alert(neo, "нет подключения к серверу!")
		open_machine()
		return

	var/datum/lazy_template/virtual_domain/generated_domain = server.generated_domain
	if(isnull(generated_domain) || !server.is_ready)
		balloon_alert(neo, "ничего не загружено!")
		open_machine()
		return

	balloon_alert(neo, "установка соединения...")

	ADD_TRAIT(neo, TRAIT_HANDS_BLOCKED, TRAIT_GENERIC)

	var/connection_successful = do_after(neo, 2 SECONDS, src)

	REMOVE_TRAIT(neo, TRAIT_HANDS_BLOCKED, TRAIT_GENERIC)

	if(!connection_successful)
		open_machine()
		return

	var/mob/living/carbon/current_avatar = avatar_ref?.resolve()
	if(isnull(current_avatar) || current_avatar.stat != CONSCIOUS)
		current_avatar = server.start_new_connection(neo, netsuit)
		if(isnull(current_avatar))
			balloon_alert(neo, "недостаточно пропускной способности!")
			open_machine()
			return

	neo.set_blurriness(4)
	add_healing(occupant)

	if(!validate_entry(neo, current_avatar))
		open_machine()
		return

	current_avatar.AddComponent( \
		/datum/component/avatar_connection, \
		old_mind = neo.mind, \
		old_body = neo, \
		server = server, \
		pod = src, \
		help_text = generated_domain.help_text, \
		copy_body = copy_body, \
	)

	server.stock_gear(current_avatar, neo, generated_domain)

	stored_uniform_ref = null
	stored_sensor_mode = null
	stored_has_sensor = null
	var/obj/item/clothing/under/host_uniform = neo.w_uniform
	if(istype(host_uniform))
		stored_uniform_ref = WEAKREF(host_uniform)
		stored_sensor_mode = host_uniform.sensor_mode
		stored_has_sensor = host_uniform.has_sensor
		host_uniform.sensor_mode = SENSOR_OFF
		host_uniform.has_sensor = NO_SENSORS

	connected = TRUE

/obj/machinery/netpod/proc/find_server()
	var/obj/machinery/quantum_server/server = server_ref?.resolve()
	if(server)
		return server

	server = locate(/obj/machinery/quantum_server) in oview(4, src)
	if(isnull(server))
		return

	server_ref = WEAKREF(server)
	RegisterSignal(server, COMSIG_MACHINERY_REFRESH_PARTS, PROC_REF(on_server_upgraded))
	RegisterSignal(server, COMSIG_BITRUNNER_DOMAIN_COMPLETE, PROC_REF(on_domain_complete))
	RegisterSignal(server, COMSIG_BITRUNNER_DOMAIN_SCRUBBED, PROC_REF(on_domain_scrubbed))

	return server

/obj/machinery/netpod/proc/sever_connection()
	if(isnull(occupant) || !connected)
		return

	SEND_SIGNAL(src, COMSIG_BITRUNNER_NETPOD_SEVER)

/obj/machinery/netpod/proc/validate_entry(mob/living/neo, mob/living/avatar)
	if(QDELETED(neo) || QDELETED(avatar) || QDELETED(src) || !is_operational)
		return FALSE

	if(occupant != neo || isnull(neo.mind) || neo.stat > SOFT_CRIT || avatar.stat == DEAD)
		return FALSE

	return TRUE

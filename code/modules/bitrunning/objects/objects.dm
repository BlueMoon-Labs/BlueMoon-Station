/obj/machinery/byteforge
	name = "byteforge"

	circuit = /obj/item/circuitboard/machine/byteforge
	desc = "Машина, используемая квантовым сервером. Квантовый код стекается сюда, материализуя расшифрованные ресурсы из виртуальной бездны."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "byteforge"
	base_icon_state = "byteforge"
	obj_flags = BLOCKS_CONSTRUCTION | CAN_BE_HIT
	var/mutable_appearance/byteforge_particles

/obj/machinery/byteforge/Initialize(mapload)
	. = ..()

	register_context()
	setup_particles()

/obj/machinery/byteforge/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = NONE
	if(isnull(held_item))
		return

	if(held_item.tool_behaviour == TOOL_SCREWDRIVER)
		context[SCREENTIP_CONTEXT_LMB] = "[panel_open ? "Закрыть" : "Открыть"] панель"
		return CONTEXTUAL_SCREENTIP_SET
	else if(held_item.tool_behaviour == TOOL_CROWBAR && panel_open)
		context[SCREENTIP_CONTEXT_LMB] = "Разобрать"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/byteforge/examine(mob/user)
	. = ..()

	. += span_notice("Должен находиться в пределах 4 клеток от квантового сервера.")

	. += span_notice("Панель обслуживания можно [EXAMINE_HINT("открутить")] и [panel_open ? "закрыть" : "открыть"].")
	if(panel_open)
		. += span_notice("Корпус можно [EXAMINE_HINT("поддеть")] и разобрать.")

/obj/machinery/byteforge/update_appearance(updates)
	. = ..()

	setup_particles()

/obj/machinery/byteforge/screwdriver_act(mob/living/user, obj/item/screwdriver)
	. = ITEM_INTERACT_FAILURE
	if(default_deconstruction_screwdriver(user, "[base_icon_state]_panel", base_icon_state, screwdriver))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/byteforge/crowbar_act(mob/living/user, obj/item/crowbar)
	. = ITEM_INTERACT_FAILURE
	if(default_deconstruction_crowbar(crowbar))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/byteforge/proc/flash(atom/movable/thing)
	playsound(src, 'sound/magic/blink.ogg', 50, TRUE)

	do_sparks(5, TRUE, loc)
	set_light(l_on = FALSE)

/obj/machinery/byteforge/proc/flicker(angry = FALSE)
	var/mutable_appearance/lighting = mutable_appearance(initial(icon), "on_overlay[angry ? "_angry" : ""]")
	flick_overlay_view(lighting, 1 SECONDS)

	set_light(l_range = 2, l_power = 1.5, l_color = angry ? LIGHT_COLOR_BUBBLEGUM : LIGHT_COLOR_BABY_BLUE, l_on = TRUE)

/obj/machinery/byteforge/proc/setup_particles(angry = FALSE)
	cut_overlay(byteforge_particles)

	byteforge_particles = mutable_appearance(initial(icon), "on_particles[angry ? "_angry" : ""]", ABOVE_MOB_LAYER)

	if(is_operational)
		add_overlay(byteforge_particles)

/obj/machinery/byteforge/proc/spawn_cache(obj/cache)
	if(QDELETED(cache))
		return

	flash()

	var/turf/drop_turf = get_turf(src)
	if(drop_turf?.is_blocked_turf(exclude_mobs = TRUE))
		for(var/direction in GLOB.alldirs)
			var/turf/adjacent = get_step(drop_turf, direction)
			if(adjacent && !adjacent.is_blocked_turf(exclude_mobs = TRUE))
				drop_turf = adjacent
				break
	cache.forceMove(drop_turf || loc)

/obj/machinery/byteforge/proc/start_to_spawn(obj/cache)
	flicker()

	addtimer(CALLBACK(src, PROC_REF(spawn_cache), cache), 1 SECONDS)

/obj/item/circuitboard/machine/netpod
	name = "Netpod (Machine Board)"
	desc = "Плата для нетпода."
	icon_state = "cargo"
	build_path = /obj/machinery/netpod
	req_components = list(
		/obj/item/stock_parts/manipulator = 1,
		/obj/item/stock_parts/matter_bin = 2,
	)

/obj/item/circuitboard/machine/quantum_server
	name = "Quantum Server (Machine Board)"
	desc = "Плата для квантового сервера."
	icon_state = "cargo"
	build_path = /obj/machinery/quantum_server
	req_components = list(
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 1,
	)

/obj/item/circuitboard/machine/byteforge
	name = "Byteforge (Machine Board)"
	desc = "Плата для байтфорджа."
	icon_state = "cargo"
	build_path = /obj/machinery/byteforge
	req_components = list(
		/obj/item/stock_parts/micro_laser = 1,
	)

/obj/item/circuitboard/computer/quantum_console
	name = "Quantum Console (Computer Board)"
	desc = "Плата для квантовой консоли."
	icon_state = "cargo"
	build_path = /obj/machinery/computer/quantum_console

/obj/item/circuitboard/computer/order_console/bitrunning
	name = "Bitrunning Vendor Console (Computer Board)"
	desc = "Плата для автомата снабжения битраннеров."
	icon_state = "cargo"
	build_path = /obj/machinery/computer/order_console/bitrunning

// Отладочные платы для тестового стенда Runtime Station: сразу с улучшенными компонентами.
/obj/item/circuitboard/machine/netpod/upgraded
	name = "Netpod (Machine Board, Upgraded)"
	def_components = list(
		/obj/item/stock_parts/manipulator = /obj/item/stock_parts/manipulator/femto,
		/obj/item/stock_parts/matter_bin = /obj/item/stock_parts/matter_bin/bluespace,
	)

/obj/item/circuitboard/machine/quantum_server/upgraded
	name = "Quantum Server (Machine Board, Upgraded)"
	def_components = list(
		/obj/item/stock_parts/manipulator = /obj/item/stock_parts/manipulator/femto,
		/obj/item/stock_parts/scanning_module = /obj/item/stock_parts/scanning_module/triphasic,
		/obj/item/stock_parts/capacitor = /obj/item/stock_parts/capacitor/quadratic,
	)

/obj/item/circuitboard/machine/byteforge/upgraded
	name = "Byteforge (Machine Board, Upgraded)"
	def_components = list(
		/obj/item/stock_parts/micro_laser = /obj/item/stock_parts/micro_laser/quadultra,
	)

/obj/item/clothing/glasses/sunglasses/oval
	name = "oval sunglasses"
	flags_cover = GLASSESCOVERSEYES
	desc = "Винтажные обтекаемые очки. Дают небольшую защиту."
	icon_state = "jensenshades"

/obj/item/clothing/suit/jacket/leather_trenchcoat
	name = "leather trenchcoat"
	desc = "Длинный чёрный плащ. С ним кажется, что вы тот самый, но вы не он."
	icon_state = "leather_trenchcoat"

/obj/item/bitrunning_debug
	name = "bitrunning debug item"
	desc = "Добавляет очки и уменьшает время перезарядки для отладки."
	icon = 'icons/obj/device.dmi'
	base_icon_state = "datadisk"
	icon_state = "scanner"

/obj/item/disk/bitrunning
	name = "generic bitrunning program"
	desc = "Диск с исходным кодом."
	base_icon_state = "datadisk"
	icon_state = "datadisk0"
	var/choice_made

/obj/item/disk/bitrunning/Initialize(mapload)
	. = ..()

	icon_state = "[base_icon_state][rand(0, 6)]"
	update_icon()

	AddComponent(/datum/component/loads_avatar_gear, \
		load_callback = CALLBACK(src, PROC_REF(load_onto_avatar)), \
	)

/obj/item/disk/bitrunning/examine(mob/user)
	. = ..()
	. += span_infoplain("Этот диск нужно взять с собой в нетпод, чтобы использовать.")

	if(isnull(choice_made))
		. += span_notice("Чтобы сделать выбор, активируйте диск в руке.")
		return

	. += span_info("Уже выбран вариант: <b>[choice_made]</b>.")
	. += span_notice("Повторный выбор невозможен.")

/obj/item/disk/bitrunning/proc/load_onto_avatar(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	return NONE

/obj/item/disk/bitrunning/ability
	desc = "Диск с исходным кодом. Позволяет заранее загрузить способности в виртуальный домен. Повторяющиеся способности игнорируются."
	var/obj/effect/proc_holder/spell/granted_spell
	var/list/obj/effect/proc_holder/spell/selectable_spells = list()

/obj/item/disk/bitrunning/ability/load_onto_avatar(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	if(domain_flags & DOMAIN_FORBIDS_ABILITIES)
		return BITRUNNER_GEAR_LOAD_BLOCKED

	if(isnull(granted_spell))
		return BITRUNNER_GEAR_LOAD_FAILED

	for(var/obj/effect/proc_holder/spell/existing as anything in avatar.mind?.spell_list)
		if(existing.type == granted_spell)
			return BITRUNNER_GEAR_LOAD_FAILED

	avatar.AddSpell(new granted_spell)
	return NONE

/obj/item/disk/bitrunning/ability/attack_self(mob/user, modifiers)

	if(choice_made)
		return

	var/names = list()
	for(var/obj/effect/proc_holder/spell/thing as anything in selectable_spells)
		names += initial(thing.name)

	var/choice = tgui_input_list(user, message = "Выберите способность",  title = "Программа битраннинга", items = names)
	if(isnull(choice) || !user.is_holding(src))
		return

	for(var/obj/effect/proc_holder/spell/thing as anything in selectable_spells)
		if(initial(thing.name) == choice)
			granted_spell = thing

	if(isnull(granted_spell))
		return

	balloon_alert(user, "выбрано")
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)
	choice_made = choice

/obj/item/disk/bitrunning/ability/tier1
	name = "bitrunning program: basic"
	selectable_spells = list(
		/obj/effect/proc_holder/spell/targeted/conjure_item/cheese,
		/obj/effect/proc_holder/spell/self/basic_heal,
	)

/obj/item/disk/bitrunning/ability/tier2
	name = "bitrunning program: complex"
	selectable_spells = list(
		/obj/effect/proc_holder/spell/aimed/fireball,
		/obj/effect/proc_holder/spell/aimed/lightningbolt,
		/obj/effect/proc_holder/spell/targeted/forcewall,
	)

/obj/item/disk/bitrunning/ability/tier3
	name = "bitrunning program: elite"
	selectable_spells = list(
		/obj/effect/proc_holder/spell/targeted/shapeshift/dragon,
		/obj/effect/proc_holder/spell/targeted/shapeshift/polar_bear,
	)

/obj/effect/proc_holder/spell/targeted/conjure_item/cheese
	name = "Summon Cheese"
	desc = "Призывает круг сыра в ваши руки. Сила богов."
	item_type = /obj/item/reagent_containers/food/snacks/store/cheesewheel
	charge_max = 150
	cooldown_min = 10

/obj/item/disk/bitrunning/item
	desc = "Диск с исходным кодом. Позволяет заранее загрузить предметы в виртуальный домен."
	var/obj/granted_item
	var/list/obj/selectable_items = list()

/obj/item/disk/bitrunning/item/load_onto_avatar(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	if(domain_flags & DOMAIN_FORBIDS_ITEMS)
		return BITRUNNER_GEAR_LOAD_BLOCKED

	if(isnull(granted_item))
		return BITRUNNER_GEAR_LOAD_FAILED

	avatar.put_in_hands(new granted_item())
	return NONE

/obj/item/disk/bitrunning/item/attack_self(mob/user, modifiers)
	. = ..()

	if(choice_made)
		return

	var/names = list()
	for(var/obj/thing as anything in selectable_items)
		names += initial(thing.name)

	var/choice = tgui_input_list(user, message = "Выберите способность",  title = "Программа битраннинга", items = names)
	if(isnull(choice) || !user.is_holding(src))
		return

	for(var/obj/thing as anything in selectable_items)
		if(initial(thing.name) == choice)
			granted_item = thing

	balloon_alert(user, "выбрано")
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)
	choice_made = choice

/obj/item/disk/bitrunning/item/tier1
	name = "bitrunning gear: simple"
	selectable_items = list(
		/obj/item/pizzabox/infinite,
		/obj/item/gun/medbeam,
		/obj/item/grenade/plastic/c4,
	)

/obj/item/disk/bitrunning/item/tier2
	name = "bitrunning gear: complex"
	selectable_items = list(
		/obj/item/reagent_containers/hypospray/medipen/survival,
		/obj/item/gun/ballistic/automatic/pistol,
		/obj/item/clothing/suit/armor/vest,
	)

/obj/item/disk/bitrunning/item/tier3
	name = "bitrunning gear: advanced"
	selectable_items = list(
		/obj/item/gun/energy/e_gun/nuclear,
		/obj/item/dualsaber/green,
		/obj/item/grenade/syndieminibomb,
	)

/obj/item/disk/bitrunning/item/pka_mods
	name = "bitrunning gear: proto-kinetic accelerator mods"
	selectable_items = list(
		/obj/item/borg/upgrade/modkit/range,
		/obj/item/borg/upgrade/modkit/damage,
		/obj/item/borg/upgrade/modkit/cooldown,
		/obj/item/borg/upgrade/modkit/aoe/mobs,
	)

/obj/item/disk/bitrunning/item/pka_mods/premium
	name = "bitrunning gear: premium proto-kinetic accelerator mods"
	selectable_items = list(
		/obj/item/borg/upgrade/modkit/cooldown/repeater,
		/obj/item/borg/upgrade/modkit/lifesteal,
		/obj/item/borg/upgrade/modkit/resonator_blasts,
		/obj/item/borg/upgrade/modkit/bounty,
		/obj/item/borg/upgrade/modkit/indoors,
	)

/obj/item/disk/bitrunning/item/pkc_mods
	name = "bitrunning gear: proto-kinetic crusher mods"
	selectable_items = list(
		/obj/item/crusher_trophy/watcher_wing,
		/obj/item/crusher_trophy/blaster_tubes/magma_wing,
		/obj/item/crusher_trophy/legion_skull,
	)

/obj/item/disk/bitrunning/item/pkc_mods/premium
	name = "bitrunning gear: premium proto-kinetic crusher mods"
	selectable_items = list(
		/obj/item/crusher_trophy/watcher_wing/ice_wing,
		/obj/item/crusher_trophy/blaster_tubes,
		/obj/item/crusher_trophy/miner_eye,
		/obj/item/crusher_trophy/tail_spike,
		/obj/item/crusher_trophy/demon_claws,
		/obj/item/crusher_trophy/vortex_talisman,
	)

/obj/item/disk/bitrunning/item/mini_uzi
	name = "bitrunning gear: mini-uzi"
	selectable_items = list(
		/obj/item/gun/ballistic/automatic/mini_uzi,
	)

/obj/structure/hololadder
	name = "hololadder"

	anchored = TRUE
	desc = "Абстрактное представление способа отключиться от виртуального домена."
	icon = 'icons/obj/structures.dmi'
	icon_state = "ladder11"
	obj_flags = BLOCK_Z_OUT_DOWN
	var/travel_time = 3 SECONDS
	var/datum/weakref/server_ref

/obj/structure/hololadder/Initialize(mapload, obj/machinery/quantum_server/origin)
	. = ..()

	RegisterSignal(loc, COMSIG_ATOM_ENTERED, PROC_REF(on_enter))
	server_ref = WEAKREF(origin)
	register_context()

/obj/structure/hololadder/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()

	context[SCREENTIP_CONTEXT_LMB] = "Disconnect"

/obj/structure/hololadder/examine(mob/user)
	. = ..()

	if(isnull(server_ref?.resolve()))
		. += span_infoplain("Он ни к чему не подключён.")
		return

	if(isobserver(user))
		. += span_notice("Левый клик — посмотреть сервер, к которому подключена лестница.")
		return

	. += span_infoplain("Лестница подключена к серверу. Нажмите на неё или пройдите по ней, чтобы отключиться.")

/obj/structure/hololadder/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(!in_range(src, user))
		return

	disconnect(user)

/obj/structure/hololadder/attack_ghost(mob/dead/observer/ghostie)
	var/our_server = server_ref?.resolve()
	if(isnull(our_server))
		return ..()

	ghostie.abstract_move(get_turf(our_server))

/obj/structure/hololadder/proc/disconnect(mob/user)
	if(isnull(user.mind))
		return

	if(!HAS_TRAIT(user, TRAIT_TEMPORARY_BODY))
		balloon_alert(user, "соединение не обнаружено")
		return

	balloon_alert(user, "отключение...")
	if(do_after(user, travel_time, src))
		SEND_SIGNAL(user, COMSIG_BITRUNNER_LADDER_SEVER)

/obj/structure/hololadder/proc/on_enter(datum/source, atom/movable/arrived, turf/old_loc)
	SIGNAL_HANDLER

	if(!isliving(arrived))
		return

	var/mob/living/user = arrived
	if(isnull(user.mind))
		return

	INVOKE_ASYNC(src, PROC_REF(disconnect), user)

/obj/item/bitrunning_host_monitor
	name = "host monitor"

	custom_materials = list(/datum/material/iron = 100)
	desc = "Сложное электронное устройство, анализирующее качество связи между хостом и аватаром."
	obj_flags = NONE
	icon = 'icons/obj/device.dmi'
	icon_state = "host_monitor"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throw_range = 7
	throw_speed = 3
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY

/obj/item/bitrunning_host_monitor/attack_self(mob/user, modifiers)
	. = ..()

	var/datum/component/avatar_connection/connection = user.GetComponent(/datum/component/avatar_connection)
	if(isnull(connection))
		balloon_alert(user, "данные не распознаны")
		return

	var/mob/living/pilot = connection.old_body_ref?.resolve()
	if(isnull(pilot))
		balloon_alert(user, "хост не распознан")
		return

	to_chat(user, span_notice("Здоровье текущего хоста: [pilot.health / pilot.maxHealth * 100]%"))

GLOBAL_LIST_EMPTY(bitrunning_landmarks)

/obj/effect/landmark/bitrunning
	name = "Generic bitrunning effect"
	icon = 'icons/effects/bitrunning.dmi'
	icon_state = "crate"

/obj/effect/landmark/bitrunning/Initialize(mapload)
	. = ..()
	GLOB.bitrunning_landmarks += src
	return .

/obj/effect/landmark/bitrunning/Destroy()
	GLOB.bitrunning_landmarks -= src
	return ..()

/obj/effect/landmark/bitrunning/loot_signal
	name = "Mysterious aura"

/obj/effect/landmark/bitrunning/hololadder_spawn
	name = "Bitrunning hololadder spawn"
	icon_state = "hololadder"

/obj/effect/landmark/bitrunning/permanent_exit
	name = "Bitrunning permanent exit"
	icon_state = "perm_exit"

/obj/effect/landmark/bitrunning/cache_goal_turf
	name = "Bitrunning goal turf"
	icon_state = "goal"

/obj/effect/landmark/bitrunning/cache_spawn
	name = "Bitrunning crate spawn"
	icon_state = "crate"

/obj/effect/landmark/bitrunning/curiosity_spawn
	name = "Bitrunning curiosity spawn"
	icon_state = "crate"

/obj/effect/landmark/bitrunning/crate_replacer
	name = "Bitrunning Goal Crate Randomizer"
	icon_state = "crate"

/obj/effect/landmark/bitrunning/crate_replacer/Initialize(mapload)
	. = ..()

#ifdef UNIT_TESTS
	return
#endif

	var/list/crate_list = list()
	var/obj/structure/closet/crate/secure/bitrunning/encrypted/encrypted_crate
	var/area/my_area = get_area(src)

	for (var/turf/area_turf as anything in my_area.contents)
		for(var/obj/structure/closet/crate/crate_to_check in area_turf)
			if(istype(crate_to_check, /obj/structure/closet/crate/secure/bitrunning/encrypted))
				encrypted_crate = crate_to_check
				crate_to_check.desc += span_hypnophrase(" Похоже, это тот самый ящик!")
			else
				crate_list += crate_to_check
			crate_to_check.name = "Unidentified Crate"

	if(!encrypted_crate)
		stack_trace("Рандомизатор целевых ящиков не нашёл зашифрованный ящик для обмена позициями.")
		return
	if(!length(crate_list))
		stack_trace("Рандомизатор целевых ящиков не нашёл обычные ящики для обмена позициями.")
		return

	var/original_location = encrypted_crate.loc
	var/obj/structure/closet/crate/selected_crate = pick(crate_list)

	encrypted_crate.abstract_move(selected_crate.loc)
	selected_crate.abstract_move(original_location)

/obj/effect/landmark/bitrunning/mob_segment
	name = "Bitrunning modular mob segment"
	icon_state = "mob_segment"

/obj/modular_map_root/safehouse
	config_file = "strings/modular_maps/safehouse.toml"
	icon = 'icons/effects/bitrunning.dmi'
	icon_state = "safehouse"

/obj/item/storage/lockbox/bitrunning
	name = "base class curiosity"
	desc = "Поговорите с кодером."
	req_access = list(ACCESS_ARMORY)
	icon_state = "lockbox+l"
	item_state = "syringe_kit"
	icon_locked = "lockbox+l"
	icon_closed = "lockbox"
	icon_broken = "lockbox+b"

/obj/item/storage/lockbox/bitrunning/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 14
	STR.max_items = 4
	STR.locked = TRUE

/obj/item/storage/lockbox/bitrunning/encrypted
	name = "encrypted curiosity"
	desc = "Требуется расшифровка в сейфхаусе, чтобы открыть."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/item/storage/lockbox/bitrunning/encrypted/emag_act(mob/user)
	return FALSE

/obj/item/storage/lockbox/bitrunning/decrypted
	name = "decrypted curiosity"
	desc = "Скомпилировано из виртуального домена. Дополнительная награда успешного битраннера."
	var/datum/lazy_template/virtual_domain/source_domain

/obj/item/storage/lockbox/bitrunning/decrypted/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.locked = FALSE

/obj/item/storage/lockbox/bitrunning/decrypted/Initialize(
	mapload,
	datum/lazy_template/virtual_domain/completed_domain,
	)
	if(isnull(completed_domain))
		log_runtime("Расшифрованная находка создана без исходного домена.")
		return INITIALIZE_HINT_QDEL

	if(!istype(completed_domain, /datum/lazy_template/virtual_domain))
		log_runtime("Расшифрованная находка создана с некорректным исходным доменом: [completed_domain.name] ([completed_domain.type]).")
		return INITIALIZE_HINT_QDEL

	source_domain = completed_domain
	. = ..()

	icon_state = icon_closed
	playsound(src, 'sound/magic/blink.ogg', 50, TRUE)

/obj/item/storage/lockbox/bitrunning/decrypted/PopulateContents()
	var/choice = SSbitrunning.pick_secondary_loot(source_domain)
	new choice(src)

#define ORE_MULTIPLIER_IRON 3
#define ORE_MULTIPLIER_GLASS 2
#define ORE_MULTIPLIER_PLASMA 1
#define ORE_MULTIPLIER_SILVER 0.7
#define ORE_MULTIPLIER_GOLD 0.6
#define ORE_MULTIPLIER_TITANIUM 0.5
#define ORE_MULTIPLIER_URANIUM 0.4
#define ORE_MULTIPLIER_DIAMOND 0.3
#define ORE_MULTIPLIER_BLUESPACE_CRYSTAL 0.2

/obj/structure/closet/crate/secure/bitrunning
	name = "base class cache"
	desc = "Поговорите с кодером."
	icon_state = "securecrate"
	base_icon_state = "securecrate"

/obj/structure/closet/crate/secure/bitrunning/encrypted
	name = "encrypted cache"
	desc = "Требуется расшифровка в сейфхаусе, чтобы открыть."
	locked = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/closet/crate/secure/bitrunning/encrypted/togglelock(mob/living/user, silent)
	return

/obj/structure/closet/crate/secure/bitrunning/decrypted
	name = "decrypted cache"
	desc = "Скомпилировано из виртуального домена. Награда успешного битраннера."
	locked = FALSE
	var/reward_points_cache = 0
	var/list/completion_loot_cache = list()
	var/rewards_multiplier_cache = 1

/obj/structure/closet/crate/secure/bitrunning/decrypted/Initialize(
	mapload,
	datum/lazy_template/virtual_domain/completed_domain,
	rewards_multiplier = 1,
	)
	if(!isnull(completed_domain))
		reward_points_cache = completed_domain.reward_points
		completion_loot_cache = completed_domain.completion_loot
		rewards_multiplier_cache = rewards_multiplier
	. = ..()
	playsound(src, 'sound/magic/blink.ogg', 50, TRUE)

// Крэйт с наградой: руда зависит от очков домена и множителя.
/obj/structure/closet/crate/secure/bitrunning/decrypted/PopulateContents()
	spawn_loot(completion_loot_cache)

	new /obj/item/stack/ore/iron(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_IRON))
	new /obj/item/stack/ore/glass(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_GLASS))

	if(reward_points_cache > 1)
		new /obj/item/stack/ore/silver(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_SILVER))
		new /obj/item/stack/ore/titanium(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_TITANIUM))

	if(reward_points_cache > 2)
		new /obj/item/stack/ore/plasma(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_PLASMA))
		new /obj/item/stack/ore/gold(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_GOLD))
		new /obj/item/stack/ore/uranium(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_URANIUM))

	if(reward_points_cache > 3)
		new /obj/item/stack/ore/diamond(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_DIAMOND))
		new /obj/item/stack/ore/bluespace_crystal(src, calculate_loot(reward_points_cache, rewards_multiplier_cache, ORE_MULTIPLIER_BLUESPACE_CRYSTAL))

/obj/structure/closet/crate/secure/bitrunning/decrypted/proc/calculate_loot(reward_points, rewards_multiplier, ore_multiplier)
	PRIVATE_PROC(TRUE)

	var/base = rewards_multiplier + reward_points
	var/random_sum = (rand() + 0.5) * base
	return max(ROUND_UP(random_sum * ore_multiplier), 1)

/obj/structure/closet/crate/secure/bitrunning/decrypted/proc/spawn_loot(list/completion_loot)
	for(var/path in completion_loot)
		if(!ispath(path))
			return FALSE

		if(isnull(completion_loot[path]))
			return FALSE

		for(var/i in 1 to completion_loot[path])
			new path(src)

	return TRUE

#undef ORE_MULTIPLIER_IRON
#undef ORE_MULTIPLIER_GLASS
#undef ORE_MULTIPLIER_PLASMA
#undef ORE_MULTIPLIER_SILVER
#undef ORE_MULTIPLIER_GOLD
#undef ORE_MULTIPLIER_TITANIUM
#undef ORE_MULTIPLIER_URANIUM
#undef ORE_MULTIPLIER_DIAMOND
#undef ORE_MULTIPLIER_BLUESPACE_CRYSTAL

/obj/item/disk/bitrunning/prefs
	name = "DeForest biological simulation disk"
	desc = "Диск с данными биологической симуляции, необходимыми для загрузки собственных персонажей в домены битраннинга."
	w_class = WEIGHT_CLASS_SMALL

	var/datum/preferences/loaded_preference
	var/include_loadout = FALSE

/obj/item/disk/bitrunning/prefs/examine(mob/user)
	. = ..()
	if(!isnull(loaded_preference))
		. += "Сейчас в нём загружен персонаж [loaded_preference.real_name]."
		. += span_notice("Ctrl-клик — изменить загрузку экипировки")

/obj/item/disk/bitrunning/prefs/CtrlClick(mob/user)
	include_loadout = !include_loadout
	balloon_alert(user, include_loadout ? "загрузка экипировки включена" : "загрузка экипировки отключена")

/obj/item/disk/bitrunning/prefs/attack_self(mob/user, modifiers)
	. = ..()

	if(!user.client?.prefs)
		return

	var/response = tgui_alert(user, "Загрузить выбранного персонажа на этот диск?", "Настройки персонажа", list("Да", "Нет"))
	if(isnull(response) || response == "Нет")
		return

	loaded_preference = user.client.prefs
	balloon_alert(user, "персонаж установлен")
	to_chat(user, span_notice("Персонаж [loaded_preference.real_name] успешно установлен!"))

/obj/machinery/computer/quantum_console
	name = "quantum console"

	circuit = /obj/item/circuitboard/computer/quantum_console
	icon_keyboard = "mining"
	icon_screen = "bitrunning"
	req_access = list(ACCESS_MINING)
	var/datum/weakref/server_ref

/obj/machinery/computer/quantum_console/Initialize(mapload, obj/item/circuitboard/circuit)
	. = ..()
	desc = "Даже в далёком [CURRENT_STATION_YEAR] году Nanotrasen всё ещё использует REST API. Как мрачно."

/obj/machinery/computer/quantum_console/LateInitialize()
	. = ..()
	find_server()

/obj/machinery/computer/quantum_console/examine(mob/user)
	. = ..()
	if(!server_ref)
		. += span_warning("Установите квантовый сервер на любую соседнюю с консолью клетку.")

/obj/machinery/computer/quantum_console/ui_interact(mob/user, datum/tgui/ui)
	. = ..()

	if(!is_operational)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "QuantumConsole")
		ui.open()

/obj/machinery/computer/quantum_console/ui_data(mob/user)
	var/list/data = list()

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		data["connected"] = FALSE
		return data

	data["connected"] = TRUE
	data["is_admin"] = !isnull(user?.client) && check_rights_for(user.client, R_ADMIN)
	data["generated_domain"] = server.generated_domain?.key
	data["occupants"] = length(server.avatar_connection_refs)
	data["points"] = server.points
	data["randomized"] = server.domain_randomized
	data["ready"] = server.is_ready && server.is_operational
	data["scanner_tier"] = server.scanner_tier
	data["retries_left"] = length(server.exit_turfs) - server.retries_spent
	data["broadcasting"] = server.broadcasting
	data["broadcasting_on_cd"] = !COOLDOWN_FINISHED(server, broadcast_toggle_cd)

	return data

/obj/machinery/computer/quantum_console/ui_static_data(mob/user)
	var/list/data = list()

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		return data

	data["available_domains"] = SSbitrunning.get_available_domains(server.scanner_tier, server.points)
	data["avatars"] = server.get_avatar_data()

	return data

/obj/machinery/computer/quantum_console/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return TRUE

	var/obj/machinery/quantum_server/server = find_server()
	if(isnull(server))
		return FALSE

	switch(action)
		if("random_domain")
			server.cold_boot_map(server.get_random_domain_id(), was_random_selection = TRUE)
			return TRUE
		if("refresh")
			ui.send_full_update()
			return TRUE
		if("set_domain")
			server.cold_boot_map(params["id"], was_random_selection = FALSE)
			return TRUE
		if("stop_domain")
			server.begin_shutdown(usr)
			return TRUE
		if("broadcast")
			server.toggle_broadcast()
			return TRUE
		if("admin_add_points")
			if(isnull(usr.client) || !check_rights_for(usr.client, R_ADMIN))
				return TRUE
			server.points += 10
			log_admin("[key_name(usr)] выдал 10 битраннинг-очков через [src].")
			return TRUE

	return FALSE

/obj/machinery/computer/quantum_console/proc/find_server()
	var/obj/machinery/quantum_server/server = server_ref?.resolve()
	if(server)
		return server

	for(var/turf/adjacent as anything in range(1, src))
		var/obj/machinery/quantum_server/nearby_server = locate(/obj/machinery/quantum_server, adjacent)
		if(nearby_server)
			server_ref = WEAKREF(nearby_server)
			return nearby_server

// Упрощённая упаковка на шесть банок: современного датума хранения здесь нет.
/datum/component/storage/concrete/sixpack
	max_items = 6
	max_w_class = WEIGHT_CLASS_NORMAL

/datum/component/storage/concrete/sixpack/Initialize()
	can_hold = typecacheof(list(
		/obj/item/reagent_containers/food/drinks/soda_cans,
	))
	return ..()

/obj/item/storage/cans
	name = "can ring"
	desc = "Вмещает до шести банок напитков и отдельные бутылки."
	icon = 'icons/obj/storage.dmi'
	icon_state = "canholder"
	item_state = "cola"
	w_class = WEIGHT_CLASS_SMALL
	component_type = /datum/component/storage/concrete/sixpack

/obj/item/storage/cans/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/storage/cans/update_icon_state()
	. = ..()
	icon_state = "canholder[min(length(contents), 6)]"

/obj/item/storage/cans/sixbeer
	name = "six-pack of beer"
	desc = "Вмещает шесть банок пива. Не забудьте сдать тару!"

/obj/item/storage/cans/sixbeer/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/food/drinks/soda_cans/beer(src)

/obj/item/storage/cans/sixsoda
	name = "six-pack of soda"
	desc = "Вмещает шесть банок газировки. Не забудьте сдать тару!"

/obj/item/storage/cans/sixsoda/PopulateContents()
	for(var/i in 1 to 6)
		new /obj/item/reagent_containers/food/drinks/soda_cans/cola(src)

/obj/item/reagent_containers/food/drinks/soda_cans/beer
	name = "space beer"
	desc = "Пиво в банке. В космосе."
	icon_state = "space_beer"
	volume = 40
	list_reagents = list(/datum/reagent/consumable/ethanol/beer = 40)
	foodtype = GRAIN

#define BITRUNNING_ORDER_MAX 20
#define BITRUNNING_STANDARD_DELIVERY_DELAY (20 SECONDS)

/obj/machinery/computer/order_console
	name = "order console"
	icon_state = "computer"
	req_access = list()

// Упрощённый вендор: на старой базе нет консоли заказов карго.
/obj/machinery/computer/order_console/bitrunning
	name = "bitrunning supplies order console"
	desc = "NexaCache(tm)! Сомнительно подлинное снаряжение для цифрового сорвиголовы."
	icon = 'icons/obj/machines/bitrunning.dmi'
	icon_state = "vendor"
	icon_keyboard = null
	icon_screen = null
	circuit = /obj/item/circuitboard/computer/order_console/bitrunning
	req_access = list(ACCESS_BIT_DEN)
	light_color = LIGHT_COLOR_BABY_BLUE

	var/credit_type = "BP"
	var/cooldown_time = 10 SECONDS
	var/cargo_cost_multiplier = 0.65
	var/express_cost_multiplier = 1
	var/purchase_tooltip = "Заказ будет доставлен из карго через некоторое время.\nНа 35% дешевле экспресс-доставки."
	var/express_tooltip = "Доставляет заказ мгновенно."
	var/list/order_categories = list(
		CATEGORY_BITRUNNING_FLAIR,
		CATEGORY_BITRUNNING_TECH,
		CATEGORY_BEPIS,
	)
	var/list/grocery_list = list()

	COOLDOWN_DECLARE(order_cooldown)

/obj/machinery/computer/order_console/bitrunning/update_icon_state()
	icon_state = "[initial(icon_state)][!is_operational ? "_off" : null]"
	return ..()

/obj/machinery/computer/order_console/bitrunning/update_overlays()
	. = ..()
	return .

/obj/machinery/computer/order_console/bitrunning/ui_interact(mob/user, datum/tgui/ui)
	if(!is_operational)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BitrunningVendor")
		ui.open()

/obj/machinery/computer/order_console/bitrunning/proc/get_total_cost()
	var/cost = 0
	for(var/datum/orderable_item/item as anything in grocery_list)
		cost += initial(item.cost_per_order) * grocery_list[item]
	return cost

/obj/machinery/computer/order_console/bitrunning/proc/get_item_name(datum/orderable_item/item)
	if(initial(item.name))
		return initial(item.name)
	var/atom/item_prototype = initial(item.purchase_path)
	return item_prototype ? initial(item_prototype.name) : "Неизвестно"

/obj/machinery/computer/order_console/bitrunning/proc/get_item_desc(datum/orderable_item/item)
	if(initial(item.desc))
		return initial(item.desc)
	var/atom/item_prototype = initial(item.purchase_path)
	return item_prototype ? initial(item_prototype.desc) : ""

/obj/machinery/computer/order_console/bitrunning/proc/find_orderable(text)
	var/datum/orderable_item/item_path = text2path("[text]")
	if(!ispath(item_path, /datum/orderable_item))
		return
	if(!(initial(item_path.category_index) in order_categories))
		return
	if(isnull(initial(item_path.purchase_path)) || initial(item_path.cost_per_order) <= 0)
		return
	return item_path

/obj/machinery/computer/order_console/bitrunning/ui_static_data(mob/user)
	var/list/data = list()
	data["credit_type"] = credit_type
	data["express_tooltip"] = express_tooltip
	data["purchase_tooltip"] = purchase_tooltip
	data["cargo_cost_multiplier"] = cargo_cost_multiplier
	data["express_cost_multiplier"] = express_cost_multiplier
	data["order_categories"] = order_categories
	data["order_datums"] = list()

	for(var/category in order_categories)
		for(var/datum/orderable_item/item as anything in get_orderable_items(category))
			data["order_datums"] += list(list(
				"name" = get_item_name(item),
				"desc" = get_item_desc(item),
				"cat" = category,
				"ref" = "[item]",
				"cost" = round(initial(item.cost_per_order) * cargo_cost_multiplier),
			))

	return data

/obj/machinery/computer/order_console/bitrunning/ui_data(mob/user)
	var/list/data = list()
	data["total_cost"] = get_total_cost()
	data["off_cooldown"] = COOLDOWN_FINISHED(src, order_cooldown)
	data["item_amts"] = list()

	for(var/datum/orderable_item/item as anything in grocery_list)
		data["item_amts"] += list(list(
			"name" = get_item_name(item),
			"amt" = grocery_list[item],
		))

	var/obj/item/card/id/card
	if(isliving(user))
		var/mob/living/living_user = user
		card = living_user.get_idcard(TRUE)
	data["points"] = card?.registered_account?.bitrunning_points || 0
	data["has_card"] = !isnull(card)
	return data

/obj/machinery/computer/order_console/bitrunning/ui_act(action, params)
	. = ..()
	if(.)
		return TRUE
	if(!isliving(usr))
		return TRUE

	switch(action)
		if("add_one")
			change_amount(find_orderable(params["target"]), 1)
		if("remove_one")
			change_amount(find_orderable(params["target"]), -1)
		if("cart_set")
			set_amount(find_orderable(params["target"]), text2num(params["amt"]))
		if("purchase")
			try_purchase(usr, express = FALSE)
		if("express")
			try_purchase(usr, express = TRUE)
		else
			return FALSE
	return TRUE

/obj/machinery/computer/order_console/bitrunning/proc/change_amount(item_path, delta)
	if(!item_path)
		return
	set_amount(item_path, (grocery_list[item_path] || 0) + delta)

/obj/machinery/computer/order_console/bitrunning/proc/set_amount(item_path, amount)
	if(!item_path)
		return
	amount = clamp(round(text2num("[amount]") || 0), 0, BITRUNNING_ORDER_MAX)
	if(amount <= 0)
		grocery_list -= item_path
		return
	grocery_list[item_path] = amount

/obj/machinery/computer/order_console/bitrunning/proc/try_purchase(mob/user, express)
	if(!is_operational || !length(grocery_list) || !COOLDOWN_FINISHED(src, order_cooldown))
		return FALSE

	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(isnull(card?.registered_account))
		say("Банковский счёт не найден!")
		return FALSE

	var/final_cost = round(get_total_cost() * (express ? express_cost_multiplier : cargo_cost_multiplier))
	if(!subtract_points(final_cost, card))
		say("Извините, но у вас недостаточно [credit_type].")
		return FALSE

	var/list/ordered_paths = list()
	for(var/datum/orderable_item/item as anything in grocery_list)
		for(var/i in 1 to grocery_list[item])
			ordered_paths += initial(item.purchase_path)

	grocery_list.Cut()
	COOLDOWN_START(src, order_cooldown, cooldown_time * (express ? express_cost_multiplier : 1))
	playsound(src, 'sound/machines/chime.ogg', 35, TRUE)

	if(express)
		say("Спасибо за покупку!")
		deliver_order(ordered_paths)
	else
		say("Заказ принят. Ожидайте доставки из карго.")
		addtimer(CALLBACK(src, PROC_REF(deliver_order), ordered_paths), BITRUNNING_STANDARD_DELIVERY_DELAY)

	return TRUE

/obj/machinery/computer/order_console/bitrunning/proc/deliver_order(list/ordered_paths)
	var/turf/delivery_turf = get_turf(src)
	if(QDELETED(src) || !delivery_turf)
		return
	for(var/path in ordered_paths)
		new path(delivery_turf)

/obj/machinery/computer/order_console/bitrunning/proc/subtract_points(final_cost, obj/item/card/id/card)
	var/datum/bank_account/account = card?.registered_account
	if(isnull(account) || account.bitrunning_points < final_cost)
		return FALSE
	account.bitrunning_points -= final_cost
	return TRUE

// Гиммик-диски загружают готовые наборы снаряжения на аватар.
/obj/item/disk/bitrunning/gimmick
	desc = "Диск с исходным кодом. Его можно использовать для предзагрузки гиммик-наборов в виртуальный домен."
	var/datum/bitrunning_gimmick/granted_loadout
	var/list/datum/bitrunning_gimmick/selectable_loadouts

/obj/item/disk/bitrunning/gimmick/Destroy()
	QDEL_NULL(granted_loadout)
	return ..()

/obj/item/disk/bitrunning/gimmick/load_onto_avatar(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	if(isnull(granted_loadout))
		return BITRUNNER_GEAR_LOAD_FAILED
	return granted_loadout.grant_loadout(neo, avatar, domain_flags)

/obj/item/disk/bitrunning/gimmick/attack_self(mob/user, modifiers)
	. = ..()

	if(granted_loadout)
		return

	var/names = list()
	for(var/datum/bitrunning_gimmick/loadout as anything in selectable_loadouts)
		names += initial(loadout.name)

	var/choice = tgui_input_list(user, message = "Выберите гиммик-набор",  title = "Программа битраннинга", items = names)
	if(isnull(choice) || !user.is_holding(src))
		return

	for(var/datum/bitrunning_gimmick/loadout as anything in selectable_loadouts)
		if(initial(loadout.name) == choice)
			granted_loadout = new loadout()

	balloon_alert(user, "выбрано")
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)
	choice_made = choice

/datum/bitrunning_gimmick
	var/name = "Gimmick Loadout"
	var/list/obj/effect/proc_holder/spell/granted_spells
	var/list/obj/item/granted_items
	var/obj/item/container_item_type = /obj/item/storage/briefcase
	var/prefix_container_name = TRUE

/datum/bitrunning_gimmick/proc/grant_loadout(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	var/return_flags = NONE
	return_flags |= grant_items(neo, avatar, domain_flags)
	return_flags |= grant_abilities(neo, avatar, domain_flags)
	return return_flags

/datum/bitrunning_gimmick/proc/grant_items(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	if(!length(granted_items))
		return NONE

	if(domain_flags & DOMAIN_FORBIDS_ITEMS)
		return BITRUNNER_GEAR_LOAD_BLOCKED

	var/obj/item/container_item = new container_item_type()
	if(prefix_container_name)
		container_item.name = "[initial(container_item.name)] — [lowertext(name)]"

	for(var/obj/item/granted_item as anything in granted_items)
		new granted_item(container_item)

	avatar.put_in_hands(container_item)

	return NONE

/datum/bitrunning_gimmick/proc/grant_abilities(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	if(!length(granted_spells))
		return NONE

	if(domain_flags & DOMAIN_FORBIDS_ABILITIES)
		return BITRUNNER_GEAR_LOAD_BLOCKED

	var/return_flags = NONE

	for(var/obj/effect/proc_holder/spell/granted_spell as anything in granted_spells)
		for(var/obj/effect/proc_holder/spell/existing as anything in avatar.mind?.spell_list)
			if(existing.type == granted_spell)
				return_flags |= BITRUNNER_GEAR_LOAD_FAILED
				continue

		avatar.AddSpell(new granted_spell)

	return return_flags

/obj/item/disk/bitrunning/gimmick/dungeon
	name = "bitrunning gimmick: dungeon crawling"
	selectable_loadouts = list(
		/datum/bitrunning_gimmick/alchemist,
		/datum/bitrunning_gimmick/rogue,
		/datum/bitrunning_gimmick/healer,
		/datum/bitrunning_gimmick/wizard,
	)

/datum/bitrunning_gimmick/alchemist
	name = "Alchemist"

	granted_items = list(
		/obj/item/clothing/suit/bio_suit/plaguedoctorsuit,
		/obj/item/clothing/mask/gas/plaguedoctor,
	)

/obj/item/reagent_containers/glass/bottle/alchemist_basic
	name = "unlabeled bottle"
	desc = "Маленький флакон. Вы не помните, что в него налили."

/obj/item/reagent_containers/glass/bottle/alchemist_basic/add_initial_reagents()
	var/list/possible_reagents = list(
		/datum/reagent/aluminium,
		/datum/reagent/bromine,
		/datum/reagent/carbon,
		/datum/reagent/chlorine,
		/datum/reagent/copper,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/fluorine,
		/datum/reagent/hydrogen,
		/datum/reagent/iodine,
		/datum/reagent/iron,
		/datum/reagent/lithium,
		/datum/reagent/mercury,
		/datum/reagent/nitrogen,
		/datum/reagent/oxygen,
		/datum/reagent/phosphorus,
		/datum/reagent/potassium,
		/datum/reagent/radium,
		/datum/reagent/silicon,
		/datum/reagent/sodium,
		/datum/reagent/stable_plasma,
		/datum/reagent/consumable/sugar,
		/datum/reagent/sulfur,
		/datum/reagent/toxin/acid,
		/datum/reagent/water,
		/datum/reagent/fuel,
		/datum/reagent/toxin/leadacetate,
		/datum/reagent/consumable/liquidgibs,
		/datum/reagent/consumable/nutriment,
		/datum/reagent/consumable/coffee,
	)

	var/our_reagent = pick(possible_reagents)
	reagents.add_reagent(our_reagent, 50)

/obj/item/reagent_containers/glass/bottle/alchemist_random
	name = "skull-labeled bottle"
	desc = "Маленький флакон. Вы не помните, что в него налили."

	var/static/list/possible_adjectives = list(
		"unlabeled",
		"skull-labeled",
		"heart-labeled",
		"explosion-labeled",
		"fish-labeled",
		"smiley-labeled",
		"frown-labeled",
		"interrobang-labeled",
		"plus-labeled",
		"d20-labeled",
		"unreadably-labeled",
		"black-labeled",
		"empty-labeled",
		"age-yellowed",
		"blood-tinged",
		"ash-marred",
		"claw-scratched",
		"marker-marked",
		"cracked",
		"ominous",
	)

/obj/item/reagent_containers/glass/bottle/alchemist_random/Initialize(mapload)
	. = ..()
	name = "[pick(possible_adjectives)] bottle"

/obj/item/reagent_containers/glass/bottle/alchemist_random/add_initial_reagents()
	var/our_reagent = get_random_reagent_id()
	var/our_amount = rand(20, 50)
	reagents.add_reagent(our_reagent, our_amount)

/datum/bitrunning_gimmick/rogue
	name = "Rogue"

	granted_items = list(
		/obj/item/clothing/under/color/black,
		/obj/item/clothing/shoes/sneakers/black/rogue,
		/obj/item/clothing/mask/facescarf/rogue,
		/obj/item/clothing/glasses/eyepatch/rogue,
		/obj/item/bedsheet/black/rogue_cape,
	)

/obj/item/clothing/shoes/sneakers/black/rogue
	name = "sneaker of SNEAKING"

/obj/item/clothing/mask/facescarf/rogue
	name = "cloth of DOOM"
	icon_state = "/obj/item/clothing/mask/facescarf/rogue"

/obj/item/clothing/glasses/eyepatch/rogue
	name = "eyepatch of SEALING"

/obj/item/bedsheet/black/rogue_cape
	name = "cape of DARKNESS"

/datum/bitrunning_gimmick/healer
	name = "Healer"

	granted_items = list(
		/obj/item/clothing/under/costume/singer/yellow,
		/obj/item/clothing/shoes/singery,
		/obj/item/rod_of_asclepius,
		/obj/item/reagent_containers/dropper,
	)

/datum/bitrunning_gimmick/wizard
	name = "Wizard"

	granted_items = list(
		/obj/item/clothing/head/wizard/fake,
		/obj/item/clothing/suit/wizrobe/fake,
		/obj/item/staff,
		/obj/item/toy/eightball,
		/obj/item/storage/fancy/cigarettes/cigpack_cannabis,
		/obj/item/storage/box/matches,
	)

	granted_spells = list(
		/obj/effect/proc_holder/spell/aoe_turf/knock,
		/obj/effect/proc_holder/spell/targeted/smoke,
	)

/obj/item/disk/bitrunning/gimmick/sports
	name = "bitrunning gimmick: sports"
	selectable_loadouts = list(
		/datum/bitrunning_gimmick/boxer,
		/datum/bitrunning_gimmick/skater,
		/datum/bitrunning_gimmick/archer,
		/datum/bitrunning_gimmick/fisher,
		/datum/bitrunning_gimmick/gamer,
	)

/datum/bitrunning_gimmick/boxer
	name = "Boxer"

	granted_items = list(
		/obj/item/clothing/gloves/boxing,
		/obj/item/clothing/under/shorts/red,
	)

/obj/item/reagent_containers/food/drinks/drinkingglass/filled/protein_blend
	name = "Protein Blend"
	list_reagents = list(/datum/reagent/consumable/nutriment = 50)

/datum/bitrunning_gimmick/skater
	name = "Skater"

	granted_items = list(
		/obj/item/clothing/shoes/wheelys,
		/obj/item/melee/skateboard,
		/obj/item/clothing/head/soft/black,
		/obj/item/clothing/shoes/sneakers/black,
	)

/datum/bitrunning_gimmick/archer
	name = "Archer"

	granted_items = list(
		/obj/item/clothing/under/costume/kimono,
		/obj/item/clothing/shoes/sandal,
		/obj/item/gun/ballistic/bow,
	)

/datum/bitrunning_gimmick/fisher
	name = "Fisher"

	granted_items = list(
		/obj/item/clothing/under/misc/overalls,
		/obj/item/clothing/suit/jacket/miljacket,
		/obj/item/clothing/head/soft/black,
		/obj/item/clothing/shoes/jackboots,
	)

/datum/bitrunning_gimmick/gamer
	name = "Gamer"

	granted_items = list(
		/obj/item/clothing/under/suit/black_really,
		/obj/item/clothing/shoes/laceup,
		/obj/item/clothing/gloves/color/black,
		/obj/item/clothing/glasses/sunglasses,
		/obj/item/modular_computer/laptop/gamer,
	)

/obj/item/modular_computer/laptop/gamer
	desc = "Дорогой ноутбук, который часто используют для метагейминга."
	device_theme = PDA_THEME_TERMINAL
	starting_programs = list(
		/datum/computer_file/program/filemanager,
		/datum/computer_file/program/notepad,
	)
	start_open = FALSE

/obj/item/modular_computer/laptop/gamer/install_default_programs()
	for(var/programs in starting_programs)
		var/datum/computer_file/program/program_type = new programs
		store_file(program_type)

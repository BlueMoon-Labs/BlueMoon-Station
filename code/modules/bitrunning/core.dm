/datum/avatar_help_text
	var/help_text

/datum/avatar_help_text/New(help_text)
	src.help_text = help_text

/datum/avatar_help_text/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AvatarHelp")
		ui.open()

/datum/avatar_help_text/ui_state(mob/user)
	return GLOB.always_state

/datum/avatar_help_text/ui_static_data(mob/user)
	var/list/data = list()

	data["help_text"] = help_text

	return data

/datum/action/avatar_domain_info
	name = "Open Virtual Domain Information"
	button_icon_state = "round_end"

/datum/action/avatar_domain_info/New(Target)
	. = ..()
	name = "Open Domain Information"

/datum/action/avatar_domain_info/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return

	target.ui_interact(owner)

/datum/action/bitrunning_emergency_disconnect
	name = "Emergency Disconnect"
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "mech_eject"

/datum/action/bitrunning_emergency_disconnect/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return

	var/mob/living/avatar = owner
	if(!isliving(avatar) || !HAS_TRAIT(avatar, TRAIT_TEMPORARY_BODY))
		return

	if(tgui_alert(avatar, "Экстренно прервать сеанс? Аватар будет отключён, носитель получит повреждение мозга.", "Экстренное отключение", list("Отключиться", "Отмена"), 0) != "Отключиться")
		return

	var/datum/component/avatar_connection/connection = avatar.GetComponent(/datum/component/avatar_connection)
	connection?.emergency_disconnect()

/atom/movable/screen/alert/bitrunning
	name = "Generic Bitrunning Alert"
	icon_state = "template"
	timeout = 10 SECONDS

/atom/movable/screen/alert/bitrunning/qserver_domain_complete
	name = "Domain Completed"
	desc = "Домен завершён. Активируйте, чтобы выйти."
	timeout = 20 SECONDS
	clickable_glow = TRUE

/atom/movable/screen/alert/bitrunning/qserver_domain_complete/Click(location, control, params)
	. = ..()
	if(!.)
		return

	var/mob/living/living_owner = owner
	if(!isliving(living_owner))
		return

	if(tgui_alert(living_owner, "Безопасно отключиться?", "Сообщение сервера", list("Выйти", "Остаться"), 10 SECONDS) == "Выйти")
		SEND_SIGNAL(living_owner, COMSIG_BITRUNNER_ALERT_SEVER)

/area/virtual_domain
	name = "Virtual Domain Ruins"
	area_flags = VIRTUAL_AREA | HIDDEN_AREA | NO_ALERTS
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY

/area/virtual_domain/fullbright

/area/virtual_domain/safehouse
	name = "Virtual Domain Safehouse"
	area_flags = UNIQUE_AREA | VIRTUAL_AREA | VIRTUAL_SAFE_AREA | NO_ALERTS
	requires_power = FALSE
	sound_environment = SOUND_ENVIRONMENT_ROOM

// Домены загружаются на отдельный z-уровень и не наследуют погоду Лаваленда.
/area/lavaland/surface/outdoors/virtual_domain
	name = "Virtual Domain Lava Ruins"
	area_flags = VIRTUAL_AREA | HIDDEN_AREA | NO_ALERTS
	outdoors = FALSE
	has_gravity = STANDARD_GRAVITY
	luminosity = 1

/area/icemoon/underground/explored/virtual_domain
	name = "Virtual Domain Ice Ruins"
	area_flags = VIRTUAL_AREA | HIDDEN_AREA | NO_ALERTS
	has_gravity = STANDARD_GRAVITY
	luminosity = 1

/area/ruin/space/virtual_domain
	name = "Virtual Domain Unexplored Location"
	area_flags = VIRTUAL_AREA | HIDDEN_AREA | NO_ALERTS
	has_gravity = STANDARD_GRAVITY

/area/space/virtual_domain
	name = "Virtual Domain Space"
	area_flags = VIRTUAL_AREA | HIDDEN_AREA | NO_ALERTS
	has_gravity = STANDARD_GRAVITY

/area/virtual_domain/protected_space
	name = "Virtual Domain Safe Zone"
	area_flags = UNIQUE_AREA | VIRTUAL_AREA | VIRTUAL_SAFE_AREA | NO_ALERTS

/area/virtual_domain/protected_space/fullbright

GLOBAL_LIST_INIT(virtual_areas, populate_virtual_areas())

/proc/populate_virtual_areas()
	var/list/virtual_areas = list()
	for(var/area/area_type as anything in subtypesof(/area))
		var/area/area_prototype = area_type
		if(initial(area_prototype.area_flags) & VIRTUAL_AREA)
			virtual_areas[area_type] = TRUE
	return virtual_areas

/proc/get_icon_dimensions(icon_file)
	if(isnull(icon_file))
		return list()
	var/icon/icon_datum = icon(icon_file)
	var/width = icon_datum.Width()
	var/height = icon_datum.Height()
	if(!width || !height)
		return list()
	return list("width" = width, "height" = height)

/obj/structure/spacevine
	var/can_spread = TRUE

/obj/machinery/conveyor/auto
	var/inverted = FALSE

/obj/effect/mapping_helpers/atom_injector/obj_flag
	var/inject_flags = NONE
	var/target_type = null

/mob/living/basic/alien/queen/large
	var/can_plant_weeds = FALSE

/obj/machinery/biogenerator/food_replicator
	var/biomass = 0

/turf/closed/indestructible/rock/snow/ice/ore
	icon = 'icons/turf/walls.dmi'
	icon_state = "icerock"

/obj/item/food/grown/banana/bunch
	var/offset_at_init = FALSE

/obj/effect/spawner/random/trash/garbage
	var/spawn_scatter_radius = 0

/mob/living/basic/alien/drone
	var/can_plant_weeds = FALSE

/mob/living/proc/fade_into_nothing(life_time = 5 SECONDS, fade_time = 3 SECONDS)
	QDEL_IN(src, life_time)
	if(fade_time <= 0)
		return
	if(life_time > fade_time)
		addtimer(CALLBACK(src, PROC_REF(fade_into_nothing_animate), fade_time), life_time - fade_time, TIMER_DELETE_ME)
	else
		fade_into_nothing_animate(fade_time)

/mob/living/proc/fade_into_nothing_animate(fade_time)
	animate(src, alpha = 0, time = fade_time, flags = ANIMATION_PARALLEL)

/mob/proc/get_faction()
	return faction

/mob/proc/add_faction(factions)
	if(isnull(factions))
		return
	if(!islist(faction))
		faction = list(faction)
	if(islist(factions))
		faction |= factions
	else
		faction |= list(factions)

/mob/proc/set_faction(list/factions)
	if(islist(factions))
		faction = factions.Copy()
	else
		faction = list(factions)

/datum/round_event_control/bitrunning_glitch
	name = "Spawn Bitrunning Glitch"
	admin_setup = list(
		/datum/event_admin_setup/minimum_candidate_requirement/bitrunning_glitch,
		/datum/event_admin_setup/listed_options/bitrunning_glitch,
	)
	category = EVENT_CATEGORY_INVASION
	description = "Вызывает кратковременного антагониста в виртуальном домене."
	min_players = 1
	max_occurrences = 0
	typepath = /datum/round_event/ghost_role/bitrunning_glitch
	weight = 100
	var/list/datum/weakref/active_servers = list()

/datum/round_event_control/bitrunning_glitch/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return FALSE

	active_servers.Cut()

	return validate_servers()

/datum/round_event_control/bitrunning_glitch/proc/validate_servers()
	active_servers.Cut()
	for(var/obj/machinery/quantum_server/server in SSmachines.get_machines_by_type(/obj/machinery/quantum_server))
		if(server.validate_mutation_candidates() && server.generated_domain.difficulty != BITRUNNER_DIFFICULTY_NONE)
			active_servers.Add(WEAKREF(server))

	return length(active_servers) > 0

/datum/event_admin_setup/listed_options/bitrunning_glitch
	input_text = "Выберите роль для спавна."

/datum/event_admin_setup/listed_options/bitrunning_glitch/get_list()
	var/list/available = list("Случайно")
	available += subtypesof(/datum/antagonist/bitrunning_glitch)

	return available

/datum/event_admin_setup/listed_options/bitrunning_glitch/apply_to_event(datum/round_event/ghost_role/bitrunning_glitch/event)
	if(chosen == "Случайно")
		event.forced_role = null
	else
		event.forced_role = chosen

/datum/event_admin_setup/minimum_candidate_requirement/bitrunning_glitch
	output_text = "Должны быть подходящие мобы для мутации!"

/datum/event_admin_setup/minimum_candidate_requirement/bitrunning_glitch/count_candidates()
	var/datum/round_event_control/bitrunning_glitch/cyber_control = event_control

	cyber_control.validate_servers()

	var/total = 0
	for(var/datum/weakref/server_ref in cyber_control.active_servers)
		var/obj/machinery/quantum_server/server = server_ref?.resolve()
		if(isnull(server) || QDELETED(server))
			continue

		total += length(server.mutation_candidate_refs)

	return total

/datum/round_event/ghost_role/bitrunning_glitch
	minimum_required = 1
	role_name = "Bitrunning Glitch"
	fakeable = FALSE
	var/forced_role

/datum/round_event/ghost_role/bitrunning_glitch/spawn_role()
	var/datum/round_event_control/bitrunning_glitch/cyber_control = control
	if(!length(cyber_control.active_servers))
		return WAITING_FOR_SOMETHING

	var/datum/weakref/server_ref = pick(cyber_control.active_servers)
	var/obj/machinery/quantum_server/unlucky_server = server_ref?.resolve()
	if(isnull(unlucky_server))
		return WAITING_FOR_SOMETHING

	cyber_control.active_servers.Cut()
	if(!unlucky_server.validate_mutation_candidates())
		return WAITING_FOR_SOMETHING

	var/mob/spawned = unlucky_server.setup_glitch(forced_role)
	if(isnull(spawned))
		return  WAITING_FOR_SOMETHING

	spawned_mobs += spawned

	return SUCCESSFUL_SPAWN

/datum/outfit/echolocator
	name = "Bitrunning Echolocator"
	glasses = /obj/item/clothing/glasses/sunglasses/blindfold
	ears = /obj/item/radio/headset
	uniform = /obj/item/clothing/under/abductor
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/jackboots
	suit = /obj/item/clothing/suit/jacket/leather_trenchcoat
	id = /obj/item/card/id/advanced

/datum/outfit/echolocator/post_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	ADD_TRAIT(user, TRAIT_BLIND, "echolocator")
	user.add_quirk(/datum/quirk/echolocation)

/datum/outfit/bitductor
	name = "Bitrunning Abductor"
	uniform = /obj/item/clothing/under/abductor
	gloves = /obj/item/clothing/gloves/fingerless
	shoes = /obj/item/clothing/shoes/jackboots

/datum/outfit/beachbum_combat
	name = "Beachbum: Island Combat"
	id = /obj/item/card/id/advanced
	l_pocket = null
	r_pocket = null
	shoes = /obj/item/clothing/shoes/sandal
	uniform = /obj/item/clothing/under/pants/jeans
	var/list/ranged_weaps = list(
		/obj/item/gun/ballistic/automatic/pistol,
		/obj/item/gun/ballistic/shotgun/boltaction,
		/obj/item/gun/ballistic/automatic/mini_uzi,
		/obj/item/gun/ballistic/automatic/pistol/deagle,
		/obj/item/gun/ballistic/rocketlauncher/unrestricted,
		/obj/item/gun/ballistic/automatic/ar,
	)
	var/list/corresponding_ammo = list(
		/obj/item/ammo_box/magazine/m10mm,
		/obj/item/ammo_box/a762,
		/obj/item/ammo_box/magazine/uzim9mm,
		/obj/item/ammo_box/magazine/m50,
		/obj/item/ammo_casing/caseless/rocket,
		/obj/item/ammo_box/magazine/m556,
	)

/datum/outfit/beachbum_combat/post_equip(mob/living/carbon/human/bum, visuals_only)
	. = ..()

	var/choice = rand(1, length(ranged_weaps))
	var/weapon = ranged_weaps[choice]
	bum.put_in_active_hand(new weapon)

	var/ammo = corresponding_ammo[choice]
	var/obj/item/ammo1 = new ammo
	var/obj/item/ammo2 = new ammo

	if(!bum.equip_to_slot_if_possible(new ammo, ITEM_SLOT_LPOCKET))
		ammo1.forceMove(get_turf(bum))
	if(!bum.equip_to_slot_if_possible(new ammo, ITEM_SLOT_RPOCKET))
		ammo2.forceMove(get_turf(bum))

	if(prob(50))
		bum.equip_to_slot_if_possible(new /obj/item/clothing/glasses/sunglasses, ITEM_SLOT_EYES)

// Ghost-роли виртуальных доменов на старой базе используют mob_spawn.
/obj/effect/mob_spawn/human/virtual_domain
	name = "virtual domain debug entity"
	mob_name = "a virtual domain debug entity"
	mob_type = /mob/living/carbon/human
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	short_desc = "Вы НЕ должны быть здесь. Как вы это допустили?"
	flavour_text = "Вы не должны это видеть. Сообщите кодору!"
	important_info = "Битраннинг — это преступление и ваша главная угроза."
	assignedrole = ROLE_GLITCH
	banType = ROLE_GLITCH
	death = FALSE
	roundstart = FALSE
	instant = FALSE
	ghost_usable = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	permanent = TRUE
	uses = -1
	can_load_appearance = FALSE
	var/antag = TRUE

/obj/effect/mob_spawn/human/virtual_domain/special(mob/living/spawned_mob)
	. = ..()

	if(ishuman(spawned_mob))
		var/mob/living/carbon/human/spawned_human = spawned_mob
		for(var/datum/quirk/quirk as anything in spawned_human.roundstart_quirks.Copy())
			spawned_human.remove_quirk(quirk.type)

	if(antag && spawned_mob.mind)
		spawned_mob.mind.add_antag_datum(/datum/antagonist/domain_ghost_actor)
		spawned_mob.mind.assigned_role = ROLE_GLITCH

/obj/effect/mob_spawn/human/virtual_domain/proc/artificial_spawn(mob/living/runner)
	SEND_SIGNAL(src, COMSIG_BITRUNNER_SPAWNED, runner)

/obj/effect/mob_spawn/human/virtual_domain/beach
	name = "virtual beach bum sleeper"
	mob_name = "a virtual beach bum"
	short_desc = "Вы — виртуальная симуляция типичного пляжного бездельника, бро."
	flavour_text = "Ага. Ты приехал сюда на весенние каникулы в надежде подцепить горячих виртуальных цыпочек, понимаешь?"
	important_info = "Битраннинг вас не смущает: вы даже не подозреваете, что находитесь в симуляции."
	outfit = /datum/outfit/beachbum
	assignedrole = "Virtual Beach Bum"
	antag = FALSE
	can_load_appearance = TRUE

/obj/effect/mob_spawn/human/virtual_domain/beach/lifeguard
	name = "virtual lifeguard sleeper"
	mob_name = "a virtual lifeguard"
	short_desc = "Вы — бодрый виртуальный спасатель!"
	flavour_text = "Ваша задача — следить, чтобы никто не завис и не был съеден малвари и прочей дрянью."
	outfit = /datum/outfit/beachbum/lifeguard
	can_load_appearance = FALSE

/obj/effect/mob_spawn/human/virtual_domain/beach/lifeguard/special(mob/living/carbon/human/lifeguard)
	. = ..()
	lifeguard.gender = FEMALE
	lifeguard.update_body()

/obj/effect/mob_spawn/human/virtual_domain/beach/bartender
	name = "virtual bartender sleeper"
	mob_name = "a virtual beach bartender"
	short_desc = "Вы — виртуальный бармен на пляже!"
	flavour_text = "Ваша работа — не давать иссякать виртуальным напиткам и помогать чувакам погружаться в симуляцию опьянения."
	outfit = /datum/outfit/spacebartender
	can_load_appearance = TRUE

/datum/outfit/beachbum
	name = "Beach Bum"
	uniform = /obj/item/clothing/under/shorts/red
	shoes = /obj/item/clothing/shoes/sandal
	glasses = /obj/item/clothing/glasses/sunglasses
	head = /obj/item/clothing/head/that

/datum/outfit/beachbum/lifeguard
	name = "Lifeguard"
	uniform = /obj/item/clothing/under/shorts/red
	shoes = /obj/item/clothing/shoes/sandal
	glasses = /obj/item/clothing/glasses/sunglasses
	head = /obj/item/clothing/head/soft/red
	r_hand = /obj/item/binoculars

/datum/outfit/spacebartender
	name = "Space Bartender"
	uniform = /obj/item/clothing/under/rank/civilian/bartender
	shoes = /obj/item/clothing/shoes/laceup
	glasses = /obj/item/clothing/glasses/sunglasses

/obj/effect/mob_spawn/human/virtual_domain/pirate
	name = "Virtual Pirate Remains"
	desc = "Какие-то неодушевлённые кости. Кажется, они вот-вот оживут!"
	density = FALSE
	icon = 'icons/effects/blood.dmi'
	icon_state = "remains"
	mob_name = "a virtual skeleton pirate"
	short_desc = "Вы — виртуальный пират. Йаррр!"
	flavour_text = "Какой-то СУХОПУТНЫЙ охотится за твоей добычей. Останови его!"
	assignedrole = "Virtual Pirate"

/datum/outfit/virtual_pirate
	name = "Virtual Pirate"
	id = /obj/item/card/id/advanced
	uniform = /obj/item/clothing/under/costume/pirate
	suit = /obj/item/clothing/suit/pirate
	glasses = /obj/item/clothing/glasses/cover/eyepatch
	head = /obj/item/clothing/head/pirate
	shoes = /obj/item/clothing/shoes/sneakers/black

/obj/effect/mob_spawn/human/virtual_domain/pirate
	outfit = /datum/outfit/virtual_pirate

/obj/effect/mob_spawn/human/virtual_domain/pirate/special(mob/living/spawned_mob)
	. = ..()
	spawned_mob.fully_replace_character_name(spawned_mob.real_name, "[pick(strings(PIRATE_NAMES_FILE, "beginnings"))][pick(strings(PIRATE_NAMES_FILE, "endings"))]")

/obj/effect/mob_spawn/human/virtual_domain/syndie
	name = "Virtual Syndicate Sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	mob_name = "a virtual syndicate operative"
	short_desc = "Вы — виртуальный оперативник Синдиката."
	flavour_text = "Вой сирен! Нас берут на абордаж!"
	outfit = /datum/outfit/virtual_syndicate
	assignedrole = ROLE_SYNDICATE

/datum/outfit/virtual_syndicate
	name = "Virtual Syndie"
	id = /obj/item/card/id/syndicate
	uniform = /obj/item/clothing/under/syndicate
	back = /obj/item/storage/backpack
	gloves = /obj/item/clothing/gloves/combat
	shoes = /obj/item/clothing/shoes/combat
	mask = /obj/item/clothing/mask/balaclava

/datum/outfit/virtual_syndicate/post_equip(mob/living/carbon/human/user, visuals_only)
	user.add_faction(ROLE_SYNDICATE)

#define REDACTED "???"

SUBSYSTEM_DEF(bitrunning)
	name = "Bitrunning"
	flags = SS_NO_FIRE

	var/list/all_domains = list()

/datum/controller/subsystem/bitrunning/Initialize(start_timeofday)
	. = ..(start_timeofday)
	InitializeDomains()
	return .

/datum/controller/subsystem/bitrunning/proc/InitializeDomains()
	for(var/path in subtypesof(/datum/lazy_template/virtual_domain))
		all_domains += new path()

/datum/controller/subsystem/bitrunning/proc/get_available_domains(scanner_tier, points)
	var/list/levels = list()

	for(var/datum/lazy_template/virtual_domain/domain as anything in all_domains)
		if(domain.domain_flags & DOMAIN_TEST_ONLY)
			continue
		var/can_view = domain.can_view_name(scanner_tier, points)
		var/can_view_reward = domain.can_view_reward(scanner_tier, points)

		levels += list(list(
			"announce_ghosts" = domain.announce_to_ghosts,
			"cost" = domain.cost,
			"desc" = can_view ? domain.desc : "Ограниченные возможности сканирования. Не удаётся определить параметры домена.",
			"difficulty" = domain.difficulty,
			"id" = domain.key,
			"is_modular" = domain.is_modular,
			"has_secondary_objectives" = counterlist_sum(domain.secondary_loot) ? TRUE : FALSE,
			"name" = can_view ? domain.name : REDACTED,
			"reward" = can_view_reward ? domain.reward_points : REDACTED,
		))

	return levels

/datum/controller/subsystem/bitrunning/proc/pick_secondary_loot(completed_domain)
	var/datum/lazy_template/virtual_domain/domain = completed_domain
	var/choice

	if(counterlist_sum(domain.secondary_loot))
		choice = pick_weight(domain.secondary_loot)
		domain.secondary_loot[choice] -= 1
	else
		choice = /obj/item/paper/paperslip/bitrunning_error
		CRASH("Виртуальный домен [domain.name] попытался выбрать добычу за дополнительную цель, но список secondary_loot пуст.")
	return choice

/obj/item/paper/paperslip/bitrunning_error
	name = "Apology Letter"
	desc = "Что-то здесь пошло не так."

/obj/item/paper/paperslip/bitrunning_error/Initialize(mapload)
	default_raw_text = "Награда за расшифрованную находку не прибыла. Сообщите об этом в техподдержку."
	return ..()

#undef REDACTED

/turf/open/indestructible/bitrunning_transport
	name = "схемный пол"
	desc = "Выглядит сложно. Сквозь пол видны бегущие схемы."
	icon = 'icons/turf/floors.dmi'
	icon_state = "floor"

/turf/closed/indestructible/binary
	name = "разрыв в ткани реальности"
	icon = 'icons/turf/floors.dmi'
	icon_state = "binary"

/obj/effect/baseturf_helper/virtual_domain
	name = "virtual domain baseturf editor"
	baseturf = /turf/open/indestructible/binary

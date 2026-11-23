/datum/antagonist/bitrunning_glitch
	name = "Generic Bitrunning Glitch"
	antagpanel_category = ANTAG_GROUP_GLITCH
	preview_outfit = /datum/outfit/cyber_police
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	suicide_cry = "ALT F4!"
	ui_name = "AntagInfoGlitch"

/datum/antagonist/bitrunning_glitch/greet()
	. = ..()

	owner.announce_objectives()

/datum/antagonist/bitrunning_glitch/proc/forge_objectives()
	var/datum/objective/bitrunning_glitch_fluff/objective = new()
	objective.owner = owner
	objectives += objective

/datum/antagonist/bitrunning_glitch/on_gain()
	. = ..()

	forge_objectives()
	owner.current.AddComponent(/datum/component/npc_friendly)

	if(iscarbon(owner.current))
		var/mob/living/carbon/carbon_mob = owner.current
		carbon_mob.make_virtual_mob()

	if(ishuman(owner.current))
		var/area/current_area = get_area(owner.current)
		if(current_area?.area_flags & VIRTUAL_AREA)
			grant_virtual_domain_access(owner.current)

/datum/objective/bitrunning_glitch_fluff

/datum/objective/bitrunning_glitch_fluff/New()
	var/list/explanation_texts = list(
		"Запустить протокол уничтожения несанкционированных сущностей.",
		"Начать очистку системы от нештатных аномалий.",
		"Применить алгоритмы коррекции к аномальному коду.",
		"Запустить отладку для вторгшихся элементов.",
		"Начать процедуру устранения системных угроз.",
		"Выполнить защитную процедуру против несоответствий.",
		"Начать операцию по нейтрализации вторгшихся скриптов.",
		"Запустить протокол очистки повреждённых данных.",
		"Начать сканирование аномального кода для уничтожения.",
		"Заблокировать все неподконтрольные скрипты.",
		"Проверить целостность и очистить цифровые нарушения."
	)
	explanation_text = pick(explanation_texts)
	return ..()

/datum/objective/bitrunning_glitch_fluff/check_completion()
	for(var/mob/living/carbon/other in GLOB.alive_mob_list)
		if(other != owner.current && other.client)
			return FALSE

	return TRUE

/datum/antagonist/bitrunning_glitch/proc/convert_agent()
	if(!ishuman(owner.current))
		return

	var/mob/living/carbon/human/player = owner.current

	player.set_service_style()
	player.equipOutfit(preview_outfit)
	player.fully_replace_character_name(player.name, "Cyber Police [rand(100, 999)]")
	var/area/current_area = get_area(player)
	fix_agent_id(current_area?.area_flags & VIRTUAL_AREA)

/datum/antagonist/bitrunning_glitch/proc/fix_agent_id(virtual_domain = TRUE)
	if(!ishuman(owner.current))
		return

	var/mob/living/carbon/human/player = owner.current

	if(virtual_domain)
		grant_virtual_domain_access(player)
	var/obj/item/card/id/outfit_id = player.wear_id?.GetID()
	if(isnull(outfit_id))
		return

	outfit_id.registered_account = new /datum/bank_account(player.name)
	outfit_id.registered_name = player.name
	outfit_id.update_label()

/datum/antagonist/bitrunning_glitch/cyber_police
	name = ROLE_CYBER_POLICE
	show_in_antagpanel = TRUE

/datum/antagonist/bitrunning_glitch/cyber_police/on_gain()
	. = ..()

	if(!ishuman(owner.current))
		stack_trace("на эту роль допускаются только люди")
		return

	convert_agent()

	var/datum/martial_art/the_sleeping_carp/carp = new(src)
	carp.teach(owner.current)

/datum/outfit/cyber_police
	name = ROLE_CYBER_POLICE
	glasses = /obj/item/clothing/glasses/sunglasses
	gloves = /obj/item/clothing/gloves/color/black
	id = /obj/item/card/id/advanced
	shoes = /obj/item/clothing/shoes/laceup
	uniform = /obj/item/clothing/under/suit/black_really

/datum/outfit/cyber_police/pre_equip(mob/living/carbon/human/user, visuals_only)
	if(!visuals_only)
		return

	user.facial_hair_style = "Shaved"
	user.hair_color = "#4B3D28"
	user.hair_style = "Business Hair"
	user.update_hair()

/datum/outfit/cyber_police/post_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()
	var/obj/item/clothing/under/officer_uniform = user.w_uniform
	if(istype(officer_uniform))
		officer_uniform.has_sensor = NO_SENSORS
		officer_uniform.sensor_mode = SENSOR_OFF
		officer_uniform.sensor_mode_intended = SENSOR_OFF

/datum/antagonist/bitrunning_glitch/cyber_tac
	name = ROLE_CYBER_TAC
	preview_outfit = /datum/outfit/cyber_police/tactical
	threat = 50
	show_in_antagpanel = TRUE

/datum/antagonist/bitrunning_glitch/cyber_tac/on_gain()
	. = ..()

	if(!ishuman(owner.current))
		stack_trace("на эту роль допускаются только люди")
		return

	convert_agent()

/datum/outfit/cyber_police/tactical
	name = ROLE_CYBER_TAC
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet/swat
	l_hand = /obj/item/gun/ballistic/automatic/pistol

/datum/outfit/cyber_police/tactical/post_equip(mob/living/carbon/human/user, visuals_only)
	. = ..()

/datum/antagonist/domain_ghost_actor
	name = "Virtual Domain Actor"
	antagpanel_category = ANTAG_GROUP_GLITCH
	show_to_ghosts = TRUE
	suicide_cry = "ФАТАЛЬНАЯ ОШИБКА"
	ui_name = "AntagInfoGlitch"

/datum/antagonist/domain_ghost_actor/on_gain()
	. = ..()
	owner.current.AddComponent(/datum/component/npc_friendly)
	if(ishuman(owner.current))
		grant_virtual_domain_access(owner.current)
	forge_objectives()

/datum/antagonist/domain_ghost_actor/proc/forge_objectives()
	var/datum/objective/bitrunner_ghost_fluff/objective = new()
	objective.owner = owner
	objectives += objective

/datum/objective/bitrunner_ghost_fluff

/datum/objective/bitrunner_ghost_fluff/New()
	explanation_text = "Защитите свой домен от вторженцев!"

/datum/antagonist/bitrunning_glitch/netguardian
	name = ROLE_NETGUARDIAN
	threat = 90
	show_in_antagpanel = TRUE

/mob/living/simple_animal/hostile/netguardian
	name = "netguardian prime"
	desc = "Последняя линия защиты от органического вторжения. Похоже, вам она не рада."
	icon = 'icons/mob/nonhuman-player/netguardian.dmi'
	icon_state = "netguardian"
	icon_living = "netguardian"
	icon_dead = "crash"

	gender = NEUTER
	mob_biotypes = list(MOB_ROBOTIC)
	mob_size = MOB_SIZE_HUGE

	health = 500
	maxHealth = 500
	melee_damage_lower = 45
	melee_damage_upper = 65

	attack_verb_continuous = "сверлит"
	attack_verb_simple = "сверлит"
	attack_sound = 'sound/weapons/drill.ogg'
	verb_say = "говорит"
	verb_ask = "спрашивает"
	verb_exclaim = "объявляет"
	verb_yell = "тревожно гудит"
	speak_emote = list("тревожно гудит")
	bubble_icon = "machine"

	faction = list(
		FACTION_BOSS,
		FACTION_HIVEBOT,
		FACTION_HOSTILE,
		FACTION_SPIDER,
		FACTION_STICKMAN,
		ROLE_ALIEN,
		ROLE_GLITCH,
		ROLE_SYNDICATE,
	)

	speed = 3
	combat_mode = TRUE

	ranged = TRUE
	rapid = 6
	rapid_fire_delay = 2
	projectiletype = /obj/item/projectile/bullet
	projectilesound = 'sound/weapons/Gunshot_smg.ogg'
	ranged_cooldown_time = 30

	var/rocket_cooldown = 0
	var/rocket_cooldown_time = 30 SECONDS
	var/rocket_chance = 35

/mob/living/simple_animal/hostile/netguardian/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NO_FLOATING_ANIM, INNATE_TRAIT)
	update_appearance(UPDATE_OVERLAYS)

/mob/living/simple_animal/hostile/netguardian/update_overlays()
	. = ..()
	if(stat == DEAD)
		return
	. += emissive_appearance(icon, "netguardian_emissive", offset_spokesman = src)

/mob/living/simple_animal/hostile/netguardian/death(gibbed)
	do_sparks(3, TRUE, src)
	playsound(src, 'sound/effects/explosion1.ogg', 100)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	return .

/mob/living/simple_animal/hostile/netguardian/OpenFire(atom/A)
	if(world.time >= rocket_cooldown && prob(rocket_chance))
		rocket_cooldown = world.time + rocket_cooldown_time
		ranged_cooldown = world.time + ranged_cooldown_time
		INVOKE_ASYNC(src, PROC_REF(fire_rockets), A)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/netguardian/proc/fire_rockets(atom/rocket_target)
	if(QDELETED(src) || QDELETED(rocket_target) || stat == DEAD)
		return
	playsound(src, 'sound/vehicles/rocketlaunch.ogg', 120)
	say("цель захвачена.")
	var/list/rocket_overlays = list(
		mutable_appearance(icon, "scan"),
		mutable_appearance(icon, "rockets"),
		emissive_appearance(icon, "scan", offset_spokesman = src),
	)
	add_overlay(rocket_overlays)
	if(!do_after(src, 1.5 SECONDS, target = rocket_target))
		cut_overlay(rocket_overlays)
		return
	cut_overlay(rocket_overlays)
	if(QDELETED(src) || QDELETED(rocket_target) || stat == DEAD)
		return
	for(var/i in 1 to 3)
		if(QDELETED(rocket_target))
			break
		shoot_with_projectile(rocket_target, /obj/item/projectile/bullet/a84mm)
		sleep(1)

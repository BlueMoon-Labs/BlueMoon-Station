#define SANDMAN_TOTAL_LAYERS 1

///Mr. sandman
/mob/living/simple_animal/hostile/morph/sandman
	name = "sandman"
	unique_name = FALSE
	desc = "Who the fuck is he?!"
	icon = 'modular_bluemoon/Ren/Icons/Mob/sandman.dmi'
	icon_state = "sandman"
	icon_living = "sandman"
	icon_dead = "sandman_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	AIStatus = AI_OFF
	maxHealth = 150
	health = 150
	minbodytemp = 270
	maxbodytemp = 350
	status_flags = (null)
	loot = list(/obj/effect/gibspawner/generic)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4)
	response_help_continuous = "touches"
	response_help_simple = "touch"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "hits"
	response_harm_simple = "hit"
	attack_verb_continuous = "gores"
	attack_verb_simple = "gore"
	speak_emote = list("murmurs")
	speed = -0.3
	see_in_dark = 7
	melee_damage_lower = 10
	melee_damage_upper = 15
	wound_bonus = 20
	damage_coeff = list(BRUTE = 0.2, BURN = 1.5, TOX = 0, CLONE = 5, STAMINA = 0, OXY = 0)
	attack_sound = 'sound/creatures/zombie_attack.ogg'
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM,)
	healable = 1
	has_penis = TRUE
	has_balls = TRUE
	has_tentacles = TRUE
	dextrous = TRUE
	has_vagina = TRUE
	dextrous_hud_type = /datum/hud/dextrous/sandman
	var/list/sandman_overlays[SANDMAN_TOTAL_LAYERS]
	var/obj/item/internal_storage
	held_items = list(null, null)
	vocal_bark_id = "bump"

/mob/living/simple_animal/hostile/morph/sandman/mob_has_gravity()
	return ..() || mob_negates_gravity()

///Дроп вещей при смерти
/mob/living/simple_animal/hostile/morph/sandman/death(gibbed)
	..()
	if(internal_storage)
		dropItemToGround(internal_storage)
	var/mob/living/brain/B = new(drop_location())
	B.name = real_name
	B.real_name = real_name
	mind.transfer_to(B)

///Инвентарь
/mob/living/simple_animal/hostile/morph/sandman/doUnEquip(obj/item/I, force, newloc, no_move, invdrop = TRUE, silent)
	if(..())
		update_inv_hands()
		if(I == internal_storage)
			internal_storage = null
			update_inv_internal_storage()
		return 1
	return 0

/mob/living/simple_animal/hostile/morph/sandman/can_equip(obj/item/I, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE, clothing_check = FALSE, list/return_warning)
	switch(slot)
		if(ITEM_SLOT_DEX_STORAGE)
			if(internal_storage)
				return 0
			return 1
	..()

/mob/living/simple_animal/hostile/morph/sandman/equip_to_slot(obj/item/I, slot)
	if(!..())
		return

	switch(slot)
		if(ITEM_SLOT_DEX_STORAGE)
			internal_storage = I
			update_inv_internal_storage()
		else
			to_chat(src, "<span class='danger'>You are trying to equip this item to an unsupported inventory slot. Report this to a coder!</span>")

/mob/living/simple_animal/hostile/morph/sandman/getBackSlot()
	return ITEM_SLOT_DEX_STORAGE

/mob/living/simple_animal/hostile/morph/sandman/getBeltSlot()
	return ITEM_SLOT_DEX_STORAGE

/mob/living/simple_animal/hostile/morph/sandman/proc/update_inv_internal_storage()
	if(internal_storage && client && hud_used && hud_used.hud_shown)
		internal_storage.screen_loc = ui_id
		client.screen += internal_storage

/mob/living/simple_animal/hostile/morph/sandman/regenerate_icons()
	..()
	update_inv_internal_storage()

///inteq mobs
/mob/living/simple_animal/hostile/syndicate/ranged/sniper
	name = "InteQ Mad Shooter"
	desc = "Ему очень нравится звук выстрела его винтовки"
	ranged = 1
	retreat_distance = 4
	minimum_distance = 4
	icon = 'modular_bluemoon/Ren/Icons/Mob/mobs.dmi'
	icon_state = "infiltrator_sniper"
	icon_living = "infiltrator_sniper"
	casingtype = /obj/item/ammo_casing/p50
	projectilesound = "sound/weapons/noscope.ogg"
	ranged_cooldown = 120
	check_friendly_fire = 1
	loot = list(/obj/effect/gibspawner/human, /obj/item/clothing/head/helmet/infiltrator/inteq, /obj/item/storage/belt/military/inteq)
	dodging = TRUE
	rapid_melee = 1
	speak_chance = 30
	speak = list("Я попал? Я попал, да?!", "Это там твои мозги вытекают?!", "Да куда я положил магазин, сука где он, где он?!", "Я буду убивать тебя медленно, отстреливая кусочек за кусочком~", "Нужно будет купить себе новые очки", "Да я тебя на сквозь вижу, ХАХ!", "Да я не бузумный стрелок. Я убийца!")

/mob/living/simple_animal/hostile/syndicate/ranged/sniper/Aggro()
	..()
	summon_backup(25)
	say("Может мне кто нибудь поможет? У нас тут мишень нарисовалась, работаем!")

/mob/living/simple_animal/hostile/syndicate/melee/ushm
	name = "InteQ Breacher"
	melee_damage_lower = 10
	melee_damage_upper = 10
	wound_bonus = 40
	bare_wound_bonus = 15
	sharpness = SHARP_EDGED
	icon = 'modular_bluemoon/Ren/Icons/Mob/mobs.dmi'
	icon_state = "infiltrator_mele"
	icon_living = "infiltrator_mele"
	loot = list(/obj/effect/gibspawner/human)
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'modular_bluemoon/Ren/Sound/USHM_hit.ogg'
	status_flags = 0

//Рандомные мобы
/mob/living/simple_animal/hostile/skeleton/meatguy
	name = "Living meat"
	desc = "Отвратительная пародия на человека из мяса и костей"
	melee_damage_lower = 10
	melee_damage_upper = 20
	sharpness = SHARP_EDGED
	wound_bonus = 10
	bare_wound_bonus = 10
	icon = 'modular_bluemoon/Ren/Icons/Mob/mobs.dmi'
	var/number

/mob/living/simple_animal/hostile/skeleton/meatguy/Initialize(mapload)
	. = ..()
	if(!number)
		number = rand(3)
	icon_state = "fleshling[number]"
	icon_living = "fleshling[number]"

/mob/living/simple_animal/hostile/russian/ranged/space
	name = "Red alert"
	icon_state = "komunist"
	icon_living = "komunist"
	icon = 'modular_bluemoon/Ren/Icons/Mob/mobs.dmi'
	maxHealth = 180
	health = 180
	casingtype = /obj/item/ammo_casing/a9x39
	projectilesound = 'modular_bluemoon/kovac_shitcode/sound/weapons/vss_shoot.ogg'
	loot = list(/obj/effect/gibspawner/human)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	rapid_melee = 1
	speak_chance = 20
	spacewalk = TRUE
	dodging = TRUE
	speak = list("Сдохни, проклятый капиталист!")

///безумный стрелок. Ивент
/datum/round_event_control/sniper
	name = "Mad shooter"
	typepath = /datum/round_event/sniper
	max_occurrences = 2
	weight = 10
	category = EVENT_CATEGORY_ENTITIES

/datum/round_event/sniper
	announce_when = 1
	start_when = 1

/datum/round_event/sniper/announce(fake)
	send_fax_to_area(new /obj/item/paper/fax_CC_message/escapee/crazy_shooter_announce, /area/security, "Психиатрический Отдел Nanotrasen", FALSE)
	// priority_announce("Один из наших... кхм... особых заключённых сбежал. Так получилось, что его последнее известное местонахождение до того, как их маячок заглох, - это ваша станция, так что будьте осторожней и остерегайтесь Технических Тоннелей. И еще... никто не знает, куда подевались ключи от оружейного сейфа?",
	// sender_override = "Психиатрический Отдел Nanotrasen", has_important_message = TRUE)

/datum/round_event/sniper/start()
	var/list/spawn_locs = list()
	var/list/unsafe_spawn_locs = list()
	for(var/X in GLOB.xeno_spawn)
		if(!isfloorturf(X))
			unsafe_spawn_locs += X
			continue
		var/turf/open/floor/F = X
		var/datum/gas_mixture/A = F.air
		var/oxy_moles = A.get_moles(GAS_O2)
		if((oxy_moles < 16 || oxy_moles > 50) || A.get_moles(GAS_PLASMA) || A.get_moles(GAS_CO2) >= 10)
			unsafe_spawn_locs += F
			continue
		if((A.return_temperature() <= 270) || (A.return_temperature() >= 360))
			unsafe_spawn_locs += F
			continue
		var/pressure = A.return_pressure()
		if((pressure <= 20) || (pressure >= 550))
			unsafe_spawn_locs += F
			continue
		spawn_locs += F

	if(!spawn_locs.len)
		spawn_locs += unsafe_spawn_locs

	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/turf/T = get_turf(pick(spawn_locs))
	var/mob/living/simple_animal/hostile/syndicate/ranged/sniper/S = new(T)
	playsound(S, 'modular_bluemoon/Ren/Sound/rifle-loading.ogg', 150, 1, 1000)
	message_admins("A mad shooter has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("A mad shooter has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN

//спавн трупа
/obj/effect/mob_spawn/human/corpse/inteq_dead
	name = "InteQ Operative"
	id_job = "Operative"
	hair_style = "Bald"
	facial_hair_style = "Shaved"
	outfit = /datum/outfit/inteq_dead

/obj/item/paper/fax_CC_message/escapee
	name = "Извещение о побеге"

/obj/item/paper/fax_CC_message/escapee/deathclaw_announce
	default_raw_text = "<font color=\"darkred\"><center><h1>Сообщение от <br>Психиатрического Отдела Nanotrasen</h1></center></font> <hr><br>Один из наших особых заключённых сбежал.<br> <br>По имеющимся у нас сведениям, его последнее известное местонахождение до того, как их маячок заглох - это **Ваша** станция.<br> <br>Соблюдайте осторожность и остерегайтесь Технических Тоннелей.<br> <br>p.s. Вы не видели ящерку уборщика?<br> <br><hr> <p><font color=\"grey\" size=1><div align=\"justify\">- Содержимое данного документа следует считать конфиденциальным. Если не указано иное, распространение содержащейся в данном документе информации среди третьих лиц и сторонних организаций строго запрещено.</div></font></p> <hr> <font color=\"RoyalBlue\"><center>Все права защищены.</center></font> <font color=\"RoyalBlue\"><center>(с) NanoTrasen, 2020 — 2564 г.</center></font><font color=\"RoyalBlue\"><center>(с) ПАКТ, 2555 — 2564 г.</center></font>"

/obj/item/paper/fax_CC_message/escapee/cat_surgeon_announce
	default_raw_text = "<font color=\"darkred\"><center><h1>Сообщение от <br>Психиатрического Отдела Nanotrasen</h1></center></font> <hr><br>Один из наших особых заключённых сбежал.<br> <br>По имеющимся у нас сведениям, его последнее известное местонахождение до того, как их маячок заглох - это **Ваша** станция.<br> <br>Соблюдайте осторожность и остерегайтесь Технических Тоннелей.<br> <br>p.s. Никто не видел наших кошек?<br> <br><hr> <p><font color=\"grey\" size=1><div align=\"justify\">- Содержимое данного документа следует считать конфиденциальным. Если не указано иное, распространение содержащейся в данном документе информации среди третьих лиц и сторонних организаций строго запрещено.</div></font></p> <hr> <font color=\"RoyalBlue\"><center>Все права защищены.</center></font> <font color=\"RoyalBlue\"><center>(с) NanoTrasen, 2020 — 2564 г.</center></font><font color=\"RoyalBlue\"><center>(с) ПАКТ, 2555 — 2564 г.</center></font>"

/obj/item/paper/fax_CC_message/escapee/mosquito_announce
	default_raw_text = "<font color=\"darkred\"><center><h1>Сообщение от <br>Психиатрического Отдела Nanotrasen</h1></center></font> <hr><br>Один из наших особых заключённых сбежал.<br> <br>По имеющимся у нас сведениям, его последнее известное местонахождение до того, как их маячок заглох - это **Ваша** станция.<br> <br>Соблюдайте осторожность и остерегайтесь Технических Тоннелей.<br> <br>p.s. Это что, выкрики на нео-русском?<br> <br><hr> <p><font color=\"grey\" size=1><div align=\"justify\">- Содержимое данного документа следует считать конфиденциальным. Если не указано иное, распространение содержащейся в данном документе информации среди третьих лиц и сторонних организаций строго запрещено.</div></font></p> <hr> <font color=\"RoyalBlue\"><center>Все права защищены.</center></font> <font color=\"RoyalBlue\"><center>(с) NanoTrasen, 2020 — 2564 г.</center></font><font color=\"RoyalBlue\"><center>(с) ПАКТ, 2555 — 2564 г.</center></font>"

/obj/item/paper/fax_CC_message/escapee/gigachad_inteq_announce
	default_raw_text = "<font color=\"darkred\"><center><h1>Сообщение от <br>Психиатрического Отдела Nanotrasen</h1></center></font> <hr><br>Один из наших особых заключённых сбежал.<br> <br>По имеющимся у нас сведениям, его последнее известное местонахождение до того, как их маячок заглох - это **Ваша** станция.<br> <br>Соблюдайте осторожность и остерегайтесь Технических Тоннелей.<br> <br>p.s. Что это за стуки металла?<br> <br><hr> <p><font color=\"grey\" size=1><div align=\"justify\">- Содержимое данного документа следует считать конфиденциальным. Если не указано иное, распространение содержащейся в данном документе информации среди третьих лиц и сторонних организаций строго запрещено.</div></font></p> <hr> <font color=\"RoyalBlue\"><center>Все права защищены.</center></font> <font color=\"RoyalBlue\"><center>(с) NanoTrasen, 2020 — 2564 г.</center></font><font color=\"RoyalBlue\"><center>(с) ПАКТ, 2555 — 2564 г.</center></font>"

/obj/item/paper/fax_CC_message/escapee/crazy_shooter_announce
	default_raw_text = "<font color=\"darkred\"><center><h1>Сообщение от <br>Психиатрического Отдела Nanotrasen</h1></center></font> <hr><br>Один из наших особых заключённых сбежал.<br> <br>По имеющимся у нас сведениям, его последнее известное местонахождение до того, как их маячок заглох - это **Ваша** станция.<br> <br>Соблюдайте осторожность и остерегайтесь Технических Тоннелей.<br> <br>p.s. Никто не знает, куда подевались ключи от оружейного сейфа?<br> <br><hr> <p><font color=\"grey\" size=1><div align=\"justify\">- Содержимое данного документа следует считать конфиденциальным. Если не указано иное, распространение содержащейся в данном документе информации среди третьих лиц и сторонних организаций строго запрещено.</div></font></p> <hr> <font color=\"RoyalBlue\"><center>Все права защищены.</center></font> <font color=\"RoyalBlue\"><center>(с) NanoTrasen, 2020 — 2564 г.</center></font><font color=\"RoyalBlue\"><center>(с) ПАКТ, 2555 — 2564 г.</center></font>"

//Unknown gallery
/datum/map_template/ruin/space/gallery
	prefix = "_maps/RandomRuins/SpaceRuins/BlueMoon/"
	id = "gallery"
	suffix = "gallery.dmm"
	name = "Abandoned Gallery"
	description = "Unknown gallery from by-gone era."

/obj/effect/spawner/lootdrop/statuesevil
	name = "statuesevil"
	loot = list(
			/mob/living/simple_animal/hostile/statue = 30,
			/obj/structure/statue/silver/secborg = 5,
			/obj/structure/statue/silver/janitor = 5,
			/obj/structure/statue/silver/sec = 5,
			/obj/structure/statue/diamond/captain = 5,
			/obj/structure/statue/diamond/ai1 = 5,
			/obj/structure/statue/gold/ce = 5,
			/obj/structure/statue/gold/rd = 5,
			/obj/structure/statue/gold/hos = 5,
			/obj/structure/statue/gold/cmo = 5,
			/obj/structure/statue/gold/hop = 5)

/obj/effect/spawner/lootdrop/mannequin
	name = "mannequinspawn"
	loot = list(
			/obj/item/lighter/qm_engraved/banished = 5, //You have a chance that mannequins just died in a fire.
			/mob/living/simple_animal/hostile/mannequin = 5,
			/mob/living/simple_animal/hostile/mannequin/bloodlust = 5,
			/mob/living/simple_animal/hostile/mannequin/damaged = 5,
			/mob/living/simple_animal/hostile/mannequin/abomination = 5)

/obj/item/lighter/qm_engraved/banished
	name = "Tarnished zippo lighter"
	desc = "Somewhat tarnished zippo lighter. For some unknown reasons, you feel reassured that evil was cleansed from these lands, at least for now."

/mob/living/simple_animal/hostile/mannequin/bloodlust //Evil version of mannequin. Hunts people.
	name = "mannequin?"
	desc = "A strange, wooden mannequin. Why it has blood on its hands?!"
	gold_core_spawnable = NO_SPAWN
	turns_per_move = 6
	maxHealth = 600
	health = 600
	obj_damage = 50
	icon_state = "mannequinevil"
	icon_living = "mannequinevil"
	environment_smash = ENVIRONMENT_SMASH_WALLS
	move_to_delay = 2
	del_on_death = TRUE
	speed = -3
	melee_damage_lower = 20
	melee_damage_upper = 30
	spacewalk = TRUE

/mob/living/simple_animal/hostile/mannequin/damaged //Somewhat destroyed evil. Hunts people.
	name = "mannequin?"
	desc = "A strange, wooden mannequin. This one looks...damaged."
	gold_core_spawnable = NO_SPAWN
	turns_per_move = 2
	maxHealth = 400
	health = 400
	obj_damage = 25
	icon_state = "mannequinbroken"
	icon_living = "mannequinbroken"
	move_to_delay = 2
	del_on_death = TRUE
	speed = 1
	melee_damage_lower = 25
	melee_damage_upper = 30

/mob/living/simple_animal/hostile/mannequin/abomination //You are fucked. Run.
	name = "mannequin?"
	desc = "A strange, wooden mannequin. Why- WHY IT HAS A SKIN ON ITSELF?!"
	gold_core_spawnable = NO_SPAWN
	turns_per_move = 8
	maxHealth = 1000
	health = 1000
	obj_damage = 50
	icon_state = "mannequinabomination"
	icon_living = "mannequinabomination"
	environment_smash = ENVIRONMENT_SMASH_WALLS
	loot = list(/obj/effect/gibspawner/human) //You..released this poor soul.
	move_to_delay = 2
	del_on_death = TRUE
	speed = -2
	melee_damage_lower = 35
	melee_damage_upper = 35
	spacewalk = TRUE

//EVENTS SINCE I LOVE STATION SO MUCH!//
/obj/item/paper/fax_CC_message/escapee/mannequinrise
	default_raw_text = "<font color=\"darkred\"><center><h1>Сообщение от <br>Отдел Эзотерики Триглава</h1></center></font> <hr><br>Одно из наших 'удержанных' существ сбежало.<br> <br>Наши сенсоры заметили его отклик где-то в вашем секторе.<br> <br>Соблюдайте осторожность и остерегайтесь Технических Тоннелей.<br> <br>p.s. Что за странный лязг?<br> <br><hr> <p><font color=\"grey\" size=1><div align=\"justify\">- Содержимое данного документа следует считать конфиденциальным. Если не указано иное, распространение содержащейся в данном документе информации среди третьих лиц и сторонних организаций строго запрещено.</div></font></p> <hr> <font color=\"darkred\"><center>Все права защищены.</center></font> <font color=\"darkred\"><center>(с) Syndicate, 2020 — 2564 г.</center></font><font color=\"darkred\"><center>(с) ПАКТ, 2555 — 2564 г.</center></font>"

/datum/round_event_control/mannequinrise
	name = "Unknown Mannequin event"
	typepath = /datum/round_event/mannequinrise
	max_occurrences = 2
	weight = 15
	category = EVENT_CATEGORY_ENTITIES

/datum/round_event/mannequinrise/announce(fake)
	send_fax_to_area(new /obj/item/paper/fax_CC_message/escapee/mannequinrise, /area/security, "Отдел Эзотерики Триглава", FALSE)

/datum/round_event/mannequinrise/start()
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
	var/mob/living/simple_animal/hostile/mannequin/bloodlust/S = new(T)
	playsound(S, 'modular_bluemoon/Gardelin0/sound/effect/spook.ogg', 75, 1, 1000)
	message_admins("An abominable mannequin has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("An abominable mannequin has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN

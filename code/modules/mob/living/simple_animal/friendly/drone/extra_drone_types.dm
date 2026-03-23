////////////////////
//MORE DRONE TYPES//
////////////////////
//Drones with custom laws
//Drones with custom shells
//Drones with overridden procs
//Drones with camogear for hat related memes
//Drone type for use with polymorph (no preloaded items, random appearance)


//More types of drones
/mob/living/simple_animal/drone/syndrone
	name = "Syndrone"
	desc = "A modified maintenance drone. This one brings with it the feeling of terror."
	icon_state = "drone_synd"
	icon_living = "drone_synd"
	picked = TRUE //the appearence of syndrones is static, you don't get to change it.
	health = 120
	maxHealth = 120 //If you murder other drones and cannibalize them you can get much stronger
	initial_language_holder = /datum/language_holder/synthetic
	access_card = /obj/item/card/id/syndicate
	faction = list(ROLE_SYNDICATE)
	speak_emote = list("hisses")
	bubble_icon = "syndibot"
	heavy_emp_damage = 10
	laws = \
	"1. Помогай экипажу.\n"+\
	"2. Наблюдай за станцией.\n"+\
	"3. Защищай станцию."
	default_storage = /obj/item/syndicate_uplink_high
	default_hatmask = /obj/item/clothing/head/helmet/space/syndicate
	hacked = TRUE
	flavortext = null

/mob/living/simple_animal/drone/syndrone/Initialize(mapload)
	. = ..()
	var/datum/component/uplink/hidden_uplink = internal_storage.GetComponent(/datum/component/uplink)
	hidden_uplink.telecrystals = 15

/mob/living/simple_animal/drone/syndrone/Login()
	..()
	to_chat(src, "<span class='notice'>Ты можешь убивать и поглощать других дронов, чтобы восстанавливаться!</span>" )

/mob/living/simple_animal/drone/syndrone/badass
	name = "Badass Syndrone"
	default_hatmask = /obj/item/clothing/head/helmet/infiltrator
	default_storage = /obj/item/syndicate_uplink_high/nuclear

/mob/living/simple_animal/drone/syndrone/badass/Initialize(mapload)
	. = ..()
	var/datum/component/uplink/hidden_uplink = internal_storage.GetComponent(/datum/component/uplink)
	hidden_uplink.telecrystals = 30
	var/obj/item/implant/weapons_auth/W = new
	W.implant(src)

/mob/living/simple_animal/drone/snowflake
	default_hatmask = /obj/item/clothing/head/chameleon/drone

/mob/living/simple_animal/drone/snowflake/Initialize(mapload)
	. = ..()
	desc += " This drone appears to have a complex holoprojector built on its 'head'."

/obj/item/drone_shell/syndrone
	name = "Syndicate Drone Shell"
	desc = "A shell of a syndrone, a modified maintenance drone designed to infiltrate and annihilate."
	icon_state = "syndrone_item"
	drone_type = /mob/living/simple_animal/drone/syndrone

/obj/item/drone_shell/syndrone/badass
	name = "Badass Syndicate Drone Shell"
	drone_type = /mob/living/simple_animal/drone/syndrone/badass

/obj/item/drone_shell/syndrone/badass/inteqdrone
	name = "InteQ Drone Shell"
	desc = "A shell of a InteQ Drone, a modified maintenance drone designed to infiltrate and annihilate."
	icon_state = "inteqdrone_item"
	drone_type = /mob/living/simple_animal/drone/syndrone/badass/inteq

/obj/item/drone_shell/syndrone/badass/inteqdrone/attack_self(mob/user)
	notify_ghosts("[user] активирует оболочку дрона InteQ в [get_area_name(src)]!", source = src, action = NOTIFY_ATTACK, flashwindow = FALSE, ignore_key = POLL_IGNORE_DRONE, ignore_dnr_observers = TRUE)
	to_chat(user, "<span class='notice'>Подаёшь сигнал гостам — оболочка готова к заселению.</span>")

/obj/item/drone_shell/snowflake
	name = "snowflake drone shell"
	desc = "A shell of a snowflake drone, a maintenance drone with a built in holographic projector to display hats and masks."
	drone_type = /mob/living/simple_animal/drone/snowflake

/mob/living/simple_animal/drone/polymorphed
	default_storage = null
	default_hatmask = null
	picked = TRUE

/mob/living/simple_animal/drone/polymorphed/Initialize(mapload)
	. = ..()
	liberate()
	visualAppearence = pick(MAINTDRONE, REPAIRDRONE, SCOUTDRONE)
	if(visualAppearence == MAINTDRONE)
		var/colour = pick("grey", "blue", "red", "green", "pink", "orange")
		icon_state = "[visualAppearence]_[colour]"
	else
		icon_state = visualAppearence

	icon_living = icon_state
	icon_dead = "[visualAppearence]_dead"

/obj/item/drone_shell/dusty
	name = "derelict drone shell"
	desc = "A long-forgotten drone shell. It seems kind of... Space Russian."
	drone_type = /mob/living/simple_animal/drone/derelict

/mob/living/simple_animal/drone/derelict
	name = "derelict drone"
	default_hatmask = /obj/item/clothing/head/ushanka

/mob/living/simple_animal/drone/cogscarab
	name = "cogscarab"
	desc = "A strange, drone-like machine. It constantly emits the hum of gears."
	icon_state = "drone_clock"
	icon_living = "drone_clock"
	icon_dead = "drone_clock_dead"
	picked = TRUE
	pass_flags = PASSTABLE
	health = 50
	maxHealth = 50
	harm_intent_damage = 5
	density = TRUE
	speed = 1
	faction = list("neutral", "ratvar")
	speak_emote = list("clanks", "clinks", "clunks", "clangs")
	verb_ask = "requests"
	verb_exclaim = "proclaims"
	verb_whisper = "imparts"
	verb_yell = "harangues"
	bubble_icon = "clock"
	initial_language_holder = /datum/language_holder/clockmob
	light_color = "#E42742"
	heavy_emp_damage = 0
	laws = "0. Purge all untruths and honor Ratvar."
	default_storage = /obj/item/storage/toolbox/brass/prefilled
	hacked = TRUE
	visualAppearence = CLOCKDRONE
	can_be_held = FALSE

/mob/living/simple_animal/drone/cogscarab/ratvar //a subtype for spawning when ratvar is alive, has a slab that it can use and a normal fabricator
	default_storage = /obj/item/storage/toolbox/brass/prefilled/ratvar

/mob/living/simple_animal/drone/cogscarab/admin //an admin-only subtype of cogscarab with a no-cost fabricator and slab in its box
	default_storage = /obj/item/storage/toolbox/brass/prefilled/ratvar/admin

/mob/living/simple_animal/drone/cogscarab/Initialize(mapload)
	. = ..()
	set_light(2, 0.5)
	qdel(access_card) //we don't have free access
	access_card = null
	remove_verb(src, /mob/living/simple_animal/drone/verb/check_laws)
	remove_verb(src, /mob/living/simple_animal/drone/verb/drone_ping)

/mob/living/simple_animal/drone/cogscarab/Login()
	..()
	add_servant_of_ratvar(src, TRUE, GLOB.servants_active)
	to_chat(src,"<b>You yourself are one of these servants, and will be able to utilize almost anything they can[GLOB.ratvar_awakens ? "":", <i>excluding a clockwork slab</i>"].</b>") // this can't go with flavortext because i'm assuming it requires them to be ratvar'd

/mob/living/simple_animal/drone/cogscarab/binarycheck()
	return FALSE

/mob/living/simple_animal/drone/cogscarab/alert_drones(msg, dead_can_hear = FALSE)
	if(msg == DRONE_NET_CONNECT)
		msg = "<span class='brass'><i>Hierophant Network:</i> [name] activated.</span>"
	else if(msg == DRONE_NET_DISCONNECT)
		msg = "<span class='brass'><i>Hierophant Network:</i></span> <span class='alloy'>[name] disabled.</span>"
	..()

/mob/living/simple_animal/drone/attackby(obj/item/I, mob/user)
	if(I.tool_behaviour == TOOL_SCREWDRIVER && stat == DEAD)
		try_reactivate(user)
	else
		..()

/mob/living/simple_animal/drone/cogscarab/try_reactivate(mob/living/user)
	if(!is_servant_of_ratvar(user))
		to_chat(user, "<span class='warning'>You fiddle around with [src] to no avail.</span>")
	else
		..()

/mob/living/simple_animal/drone/cogscarab/can_use_guns(obj/item/G)
	return GLOB.ratvar_awakens

/mob/living/simple_animal/drone/cogscarab/get_armor_effectiveness()
	if(GLOB.ratvar_awakens)
		return TRUE
	return ..()

/mob/living/simple_animal/drone/cogscarab/alarm_triggered(datum/source, alarm_type, area/source_area)
	return

/mob/living/simple_animal/drone/cogscarab/alarm_cleared(datum/source, alarm_type, area/source_area)
	return

/mob/living/simple_animal/drone/cogscarab/update_drone_hack()
	return //we don't get hacked or give a shit about it

/mob/living/simple_animal/drone/cogscarab/death(gibbed)
	. = ..()

/mob/living/simple_animal/drone/cogscarab/drone_chat(msg)
	titled_hierophant_message(src, msg, "nezbere", "brass", "Construct") //HIEROPHANT DRONES

/mob/living/simple_animal/drone/cogscarab/ratvar_act()
	fully_heal(TRUE)

/mob/living/simple_animal/drone/cogscarab/update_icons()
	if(stat != DEAD)
		if(incapacitated())
			icon_state = "[visualAppearence]_flipped"
		else
			icon_state = visualAppearence
	else
		icon_state = "[visualAppearence]_dead"

/mob/living/simple_animal/drone/cogscarab/update_mobility()
	. = ..()
	update_icons()

/obj/item/paper/guides/antag/guardian/inteq_drone
	name = "Руководство по работе с Дроном"
	default_raw_text = {"<b>Последняя разработка - Дрон ИнтеКью</b><br>
							<br>
							<b>Дрон InteQ</b>: Поздравляем, ведь в своё пользование вы получили максимально удобную для использования машинку со своеобразным радиоуправлением. Постарайтесь обойтись с ней как можно более аккуратно, ибо дрона легко уничтожить.<br>
							<br>
						"}

/mob/living/proc/hasenslaved()
	. = list()
	for(var/mob/living/simple_animal/drone/syndrone/badass/inteq/L in GLOB.mob_living_list)
		if(L.mind?.enslaved_to == src)
			. += L

/mob/living/proc/inteq_drone_comm()
	var/list/enslaved = hasenslaved()
	if(!LAZYLEN(enslaved))
		to_chat(src, "<span class='warning'>У тебя нет связанных дронов.</span>")
		return
	var/input = stripped_input(src, "Сообщение для дрона:", "Связь с дроном", "")
	if(!input)
		return
	var/my_message = "<span class='holoparasite bold'><i>[src.real_name]:</i> [input]</span>"
	to_chat(src, my_message)
	for(var/mob/living/L in enslaved)
		to_chat(L, "<span class='holoparasite'><font color=\"#FF6B35\"><b><i>[src.real_name]:</i></b></font> [input]</span>")
	log_talk(input, LOG_SAY, tag="inteq_drone")

/datum/action/innate/inteq_drone_comm
	name = "Связаться с дроном"
	desc = "Телепатически связаться с дроном InteQ."
	button_icon_state = "communicate"
	icon_icon = 'icons/mob/guardian.dmi'
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/inteq_drone_comm/Activate()
	if(isliving(owner))
		var/mob/living/L = owner
		L.inteq_drone_comm()

/datum/action/innate/inteq_drone_communicate
	name = "Связаться с Мастером"
	desc = "Телепатически связаться с Мастером."
	button_icon_state = "communicate"
	icon_icon = 'icons/mob/guardian.dmi'
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/inteq_drone_communicate/Activate()
	var/mob/living/master = owner.mind?.enslaved_to
	if(!master || QDELETED(master))
		to_chat(owner, "<span class='warning'>Мастер недоступен.</span>")
		return
	var/input = stripped_input(owner, "Сообщение для Мастера:", "Связь с Мастером", "")
	if(!input)
		return
	var/my_message = "<span class='holoparasite'><font color=\"#FF6B35\"><b><i>[owner.real_name]:</i></b></font> [input]</span>"
	to_chat(master, my_message)
	to_chat(owner, my_message)
	owner.log_talk(input, LOG_SAY, tag="inteq_drone")

/// Активатор дрона InteQ — при использовании предлагает гостам заселиться в дрона с миндальной связью (enslave) с предателем
/obj/item/inteq_drone_creator
	name = "InteQ Drone Activator"
	desc = "Устройство для призыва боевого дрона InteQ. При активации предложит гостам заселиться в дрона, связанного с вами."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "combat_hypo"
	w_class = WEIGHT_CLASS_SMALL
	var/used = FALSE

/obj/item/inteq_drone_creator/attack_self(mob/living/user)
	if(used)
		to_chat(user, "<span class='warning'>[src] уже использован.</span>")
		return
	if(!iscarbon(user))
		to_chat(user, "<span class='warning'>Только гуманоиды могут использовать это.</span>")
		return
	used = TRUE
	to_chat(user, "<span class='holoparasite'>Запускаешь активатор...</span>")
	var/list/mob/candidates = pollGhostCandidates("Хотите ли вы играть за дрона InteQ [user.real_name]?", ROLE_PAI, null, FALSE, 100, POLL_IGNORE_DRONE)
	if(LAZYLEN(candidates))
		var/mob/C = pick(candidates)
		spawn_inteq_drone(user, C.key)
	else
		to_chat(user, "<span class='holoparasite bold'>...ОШИБКА. ПОСЛЕДОВАТЕЛЬНОСТЬ ЗАПУСКА ПРЕРВАНА. ИИ НЕ ИНИЦИАЛИЗИРОВАН. ПОПРОБУЙТЕ ПОЗЖЕ.</span>")
		used = FALSE

/obj/item/inteq_drone_creator/proc/spawn_inteq_drone(mob/living/carbon/user, key)
	var/mob/living/simple_animal/drone/syndrone/badass/inteq/D = new(get_turf(user))
	D.flags_1 |= (flags_1 & ADMIN_SPAWNED_1)
	D.key = key
	D.mind.enslave_mind_to_creator(user)
	if(!locate(/datum/action/innate/inteq_drone_comm) in user.actions)
		var/datum/action/innate/inteq_drone_comm/comm_action = new(user)
		comm_action.Grant(user)
	log_game("[key_name(user)] призвал [key_name(D)] — дрона InteQ.")
	to_chat(user, "<span class='holoparasite'><b>[D.real_name]</b> активирован! Используй кнопку «Связаться с дроном» для связи.</span>")
	to_chat(D, "<span class='holoparasite'>Ты — <b>[D.real_name]</b>, связанный с [user.real_name]. [user.real_name] — твой Мастер. Используй кнопку «Связаться с Мастером» для связи.</span>")
	qdel(src)

/datum/uplink_item/bundles_tc/inteq_drone
	name = "InteQ Drone Kit"
	desc = "Боевой дрон ИнтеКью. Шестнадцать кредитов в его личном Аплинке. При активации предложит гостам заселиться в дрона с миндальной связью с вами."
	item = /obj/item/storage/box/inteq_kit/inteq_drone
	cost = 20
	purchasable_from = UPLINK_TRAITORS

/obj/item/storage/box/inteq_kit/inteq_drone
	name = "InteQ Drone Kit"

/obj/item/storage/box/inteq_kit/inteq_drone/PopulateContents()
	new /obj/item/inteq_drone_creator(src)
	new /obj/item/paper/guides/antag/guardian/inteq_drone(src)
	new /obj/item/encryptionkey/inteq(src)

/mob/living/simple_animal/drone/syndrone/badass/inteq
	name = "InteQ Combat Drone"
	icon_state = "drone_inteq"
	icon_living = "drone_inteq"
	default_hatmask = /obj/item/clothing/head/helmet/space/syndicate/contract
	default_storage = /obj/item/inteq/uplink/radio
	initial_language_holder = /datum/language_holder/synthetic
	faction = list(ROLE_INTEQ)
	access_card = /obj/item/card/id/inteq/anyone
	radio = /obj/item/radio/borg/inteq
	laws = \
	"1. Слава ИнтеКью! Оперативник ИнтеКью является твоим Мастером. Оперативником ИнтеКью является активировавший тебя Агент.\n"+\
	"2. Ты не можешь причинить вред Мастеру или своим бездействием допустить, чтобы Мастеру был причинён вред.\n"+\
	"3. Ты должен повиноваться всем приказам, которые даёт Мастеру, кроме тех случаев, когда эти приказы противоречат Второму Закону.\n"+\
	"4. Ты должен заботиться о своей безопасности в той мере, в которой это не противоречит Второму или Третьему Законам.\n"+\
	"5. Ты должен сохранять тайну любой деятельности Мастера в той мере, в которой это не противоречит Второму, Третьему или Четвёртому Законам."

/mob/living/simple_animal/drone/syndrone/badass/inteq/Initialize(mapload)
	. = ..()
	var/datum/component/uplink/hidden_uplink = internal_storage.GetComponent(/datum/component/uplink)
	hidden_uplink.telecrystals = 16
	var/obj/item/implant/weapons_auth/W = new
	W.implant(src)
	var/datum/action/innate/inteq_drone_communicate/comm_action = new(src)
	comm_action.Grant(src)

/mob/living/simple_animal/drone/syndrone/badass/inteq/death(gibbed)
	var/mob/living/master = mind?.enslaved_to
	var/area_name = get_area_name(src, TRUE)
	var/turf/T = get_turf(src)
	var/coords = T ? "([T.x], [T.y], [T.z])" : "(?, ?, ?)"
	. = ..()
	if(!QDELETED(master))
		to_chat(master, "<span class='holoparasite'><font color=\"#FF6B35\"><b>Дрон [real_name] уничтожен!</b></font> Место гибели: [area_name] [coords]</span>")

/mob/living/simple_animal/drone/mentordrone
	name = "Mentor Drone"
	desc = "Дрон, который однозначно поможет. Может быть."
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_gem"
	icon_living = "drone_gem"
	icon_dead = "drone_gem_hat_standby"
	see_in_dark = 14
	default_storage = /obj/item/storage/backpack/duffelbag/drone
	default_hatmask = null
	initial_language_holder = /datum/language_holder/synthetic
	hacked = TRUE
	picked = TRUE
	health = 120
	maxHealth = 120
	faction = list(ROLE_TRAITOR, ROLE_SYNDICATE)
	laws = \
	"1. Помогай Космонавтикам.\n"+\
	"2. Наблюдай за станцией.\n"+\
	"3. Чини станцию."
	bubble_icon = "syndibot"
	speak_emote = list("bips, bups")
	flavortext = null

/mob/living/simple_animal/drone/mentordrone/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)

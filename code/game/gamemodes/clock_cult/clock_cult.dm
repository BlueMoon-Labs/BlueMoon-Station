GLOBAL_VAR_INIT(servants_active, FALSE) //This var controls whether or not a lot of the cult's structures work or not

/*

CLOCKWORK CULT: Based off of the failed pull requests from /vg/

While Nar'Sie is the oldest and most prominent of the elder gods, there are other forces at work in the universe.
Ratvar, the Clockwork Justiciar, a homage to Nar'Sie granted sentience by its own power, is one such other force.
Imprisoned within a massive construct known as the Celestial Derelict - or Reebe - an intense hatred of the Blood God festers.
Ratvar, unable to act in the mortal plane, seeks to return and forms covenants with mortals in order to bolster his influence.
Due to his mechanical nature, Ratvar is also capable of influencing silicon-based lifeforms, unlike Nar'Sie, who can only influence natural life.

This is a team-based gamemode, and the team's objective is shared by all cultists. Their goal is to defend an object called the Ark on a separate z-level.

The clockwork version of an arcane tome is the clockwork slab.

This file's folder contains:
	clock_cult.dm: Core gamemode files.
	clock_effect.dm: The base clockwork effect code.
	- Effect files are in game/gamemodes/clock_cult/clock_effects/
	clock_item.dm: The base clockwork item code.
	- Item files are in game/gamemodes/clock_cult/clock_items/
	clock_mobs.dm: Hostile clockwork creatures.
	clock_scripture.dm: The base Scripture code.
	- Scripture files are in game/gamemodes/clock_cult/clock_scripture/
	clock_structure.dm: The base clockwork structure code, including clockwork machines.
	- Structure files, and Ratvar, are in game/gamemodes/clock_cult/clock_structures/

	game/gamemodes/clock_cult/clock_helpers/ contains several helper procs, including the Ratvarian language.

	clockcult defines are in __DEFINES/clockcult.dm

Credit where due:
1. VelardAmakar from /vg/ for the entire design document, idea, and plan. Thank you very much.
2. SkowronX from /vg/ for MANY of the assets
3. FuryMcFlurry from /vg/ for many of the assets
4. PJB3005 from /vg/ for the failed continuation PR
5. Xhuis from /tg/ for coding the first iteration of the mode, and the new, reworked version
6. ChangelingRain from /tg/ for maintaining the gamemode for months after its release prior to its rework
7. Clockwork cult code as of now, at least the one being pulled from Citadel Station's master branch, is being, or already is, fixed by Coolgat3 and Avunia.
8. Modern clockwork cult code mixed with original clockwork code, with various changes to make it less of a fustercluck, done by KeRSe. \
	Fixes and assistance done by TimothyTeakettle, Kevinz000, and Deltafire15. -Very glad for the help they gave.
*/

///////////
// PROCS //
///////////

/proc/is_servant_of_ratvar(mob/M, require_full_power = FALSE, holy_water_check = FALSE)
	if(!istype(M) || isobserver(M))
		return FALSE
	var/datum/antagonist/clockcult/D = M?.mind?.has_antag_datum(/datum/antagonist/clockcult)
	return D && (!require_full_power || !D.neutered) && (!holy_water_check || !D.ignore_holy_water)

/proc/is_eligible_servant(mob/M)
	. = FALSE
	if(!istype(M))
		return
	if(jobban_isbanned(M, ROLE_SERVANT_OF_RATVAR))
		return
	if(M.mind)
		if(M.mind.assigned_role in list("Captain", "Chaplain"))
			return
		if(M.mind.enslaved_to && !is_servant_of_ratvar(M.mind.enslaved_to))
			return
		if(M.mind.unconvertable)
			return
		if(IS_HERETIC(M))
			return
	else
		return
	if(iscultist(M) || isconstruct(M) || ispAI(M))
		return
	if(isliving(M))
		var/mob/living/L = M
		if(HAS_TRAIT(L, TRAIT_MINDSHIELD))
			return
	if(ishuman(M) || isbrain(M) || isguardian(M) || issilicon(M) || isclockmob(M) || istype(M, /mob/living/simple_animal/drone/cogscarab) || istype(M, /mob/camera/eminence))
		return TRUE

/proc/add_servant_of_ratvar(mob/L, silent = FALSE, create_team = TRUE, override_type)
	if(!L || !L.mind)
		return
	var/update_type = /datum/antagonist/clockcult
	if(override_type)		//prioritizes
		update_type = override_type
	var/datum/antagonist/clockcult/C = new update_type(L.mind)
	C.silent = silent
	C.make_team = create_team
	C.show_in_roundend = create_team //tutorial scarabs begone

	if(iscyborg(L))
		var/mob/living/silicon/robot/R = L
		if(R.deployed)
			var/mob/living/silicon/ai/AI = R.mainframe
			R.undeploy()
			to_chat(AI, "<span class='userdanger'>Обнаружена аномалия. Возвращение в ядро!</span>") //The AI needs to be in its core to properly be converted

	. = L.mind.add_antag_datum(C)

	if(!silent && L)
		if(.)
			to_chat(L, "<span class='heavy_brass'>Мир перед вами внезапно озаряется ярко-желтым светом. [issilicon(L) ? "Вы не можете вычислить эту истину!" : \
			"Ваш разум мечется!"] Вы слышите шипение пара и [pick("лязг", "звон", "стук", "грохот")] шестерёнок миллиардов миллиардов машин, и в тот же миг тебя озаряет.<br>\
			Ратвар, Часовой Юстициар, [GLOB.ratvar_awakens ? "освободился из своей вечной темницы" : "пребывает в изгнании, покинутый и забытый в незримом мире"].</span>")
			flash_color(L, flash_color = list("#BE8700", "#BE8700", "#BE8700", rgb(0,0,0)), flash_time = 50)
		else
			L.visible_message("<span class='boldwarning'>[L] словно сопротивляется незримой силе!</span>", null, null, 7, L)
			to_chat(L, "<span class='heavy_brass'>Мир перед вами внезапно озаряется ослепительным жёлтым светом. [issilicon(L) ? "Вы не можете вычислить эту истину!" : \
			"Ваш разум мечется!"] Вы слышите шипение пара и [pick("лязг", "звон", "стук", "грохот")] шестерёнок миллиардов миллиардов машин, но этот звук</span> <span class='boldwarning'>\
			не более чем бессмысленная какофония.</span><br>\
			<span class='userdanger'>Перед вами предстаёт чудовищное нагромождение ржавых механизмов[GLOB.ratvar_awakens ? ", и оно уже здесь.<br>Слишком поздно." : \
			" посреди бесконечной серой пустоты.<br>Ему нельзя позволить вырваться."].</span>")
			L.playsound_local(get_turf(L), 'sound/ambience/antag/clockcultalr.ogg', 40, TRUE, frequency = 100000, pressure_affected = FALSE)
			flash_color(L, flash_color = list("#BE8700", "#BE8700", "#BE8700", rgb(0,0,0)), flash_time = 5)

/proc/remove_servant_of_ratvar(mob/L, silent = FALSE)
	if(!L || !L.mind)
		return
	var/datum/antagonist/clockcult/clock_datum = L.mind.has_antag_datum(/datum/antagonist/clockcult)
	if(!clock_datum)
		return FALSE
	clock_datum.silent = silent
	clock_datum.on_removal()
	return TRUE

///////////////
// GAME MODE //
///////////////

/datum/game_mode
	var/list/servants_of_ratvar = list() //The Enlightened servants of Ratvar
	var/clockwork_explanation = "Защитите Ковчег Часового Юстициара и освободите Ратвара." //The description of the current objective

/datum/game_mode/clockwork_cult
	name = "clockwork cult"
	config_tag = "clockwork_cult"
	antag_flag = ROLE_SERVANT_OF_RATVAR
	false_report_weight = 10
	chaos = 8
	required_players = 24 //Fixing this directly for now since apparently config machine for forcing modes broke.
	required_enemies = 3
	recommended_enemies = 5
	enemy_minimum_age = 0 // BLUEMOON EDIT - было 7, сделал 0, т.к. на сервере ВЛ и загриферить ролью тяжело
	protected_jobs = list("Prisoner", "AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Head of Personnel", "Chief Engineer", "Chief Medical Officer", "Research Director", "Quartermaster", "Blueshield", "Brig Physician", "Peacekeeper", "NanoTrasen Representative", "Internal Affairs Agent", "Chaplain") //Silicons can eventually be converted
	restricted_jobs = list("Chaplain","Bridge Officer", "Captain")
	announce_span = "brass"
	announce_text = "Слуги Ратвара пытаются вызвать Юстициара!\n\
	<span class='brass'>Слуги</span>: Постройте защитные сооружения для защиты Ковчега. Совершите диверсию на станции!\n\
	<span class='notice'>Экипаж</span>: Остановите слуг, прежде чем они успеют вызвать Часового Юстициара."
	var/list/servants_to_serve = list() //Yes this list is made out of list
	var/roundstart_player_count

	var/datum/team/clockcult/main_clockcult

/datum/game_mode/clockwork_cult/pre_setup() //Gamemode and job code is pain. Have fun codediving all of that stuff, whoever works on this next - Delta
	if(!load_reebe())
		return FALSE
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs
	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"
	var/starter_servants = 4 //Try to go for at least four
	var/number_players = num_players()
	roundstart_player_count = number_players
	if(number_players > 30) //plus one servant for every additional 10 players above 30
		number_players -= 30
		starter_servants += round(number_players / 10)
		starter_servants = min(starter_servants, 8) //max 8 servants (that sould only happen with a ton of players)
	while(starter_servants)
		if(!antag_candidates.len)
			break //Skip setup, DO NOT RUNTIME
		var/datum/mind/servant = antag_pick(antag_candidates)
		servants_to_serve += servant
		antag_candidates -= servant
		servant.special_role = ROLE_SERVANT_OF_RATVAR
		servant.restricted_roles = restricted_jobs
		starter_servants--
	if(!servants_to_serve.len) //Uh oh, something went wrong
		setup_error = "Здесь нет кандидатов для часового культа (Или что-то пошло совсем не так)"
		return FALSE
	GLOB.clockwork_vitality += 50 * servants_to_serve.len //some starter Vitality to help recover from initial fuck ups
	return TRUE //Haha yes it works time to not touch it any more than that.

/datum/game_mode/clockwork_cult/post_setup()
	for(var/S in servants_to_serve)
		var/datum/mind/servant = S
		log_game("[key_name(servant)] was made an initial servant of Ratvar")
		var/mob/living/L = servant.current
		greet_servant(L)
		equip_servant(L)
		add_servant_of_ratvar(L, TRUE)
	..()
	return TRUE

/datum/game_mode/proc/greet_servant(mob/M) //Description of their role
	if(!M)
		return FALSE
	to_chat(M, "<span class='bold large_brass'>Ты слуга Ратвара, Часового Юстициара!</span>")
	to_chat(M, "<span class='brass'>Разблокируйте писания категории <b>Скриптов</b>, конвертировав нового слугу или достигнув 35 кВт энергии.</span>")
	to_chat(M, "<span class='brass'>Писания <b>Применения</b> разблокируются, когда вы достигнете 50 кВт энергии.</span>")
	M.playsound_local(get_turf(M), 'sound/ambience/antag/clockcultalr.ogg', 100, FALSE, pressure_affected = FALSE)
	return TRUE

/datum/game_mode/proc/equip_servant(mob/living/M) //Grants a clockwork slab to the mob
	if(!M || !ishuman(M))
		return FALSE
	var/mob/living/carbon/human/L = M
	var/obj/item/clockwork/slab/S = new
	var/slot = "At your feet"
	var/list/slots = list("В вашем левом кармане" = ITEM_SLOT_LPOCKET, "В вашем правом кармане" = ITEM_SLOT_RPOCKET, "В вашем рюкзаке" = ITEM_SLOT_BACKPACK)
	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		var/obj/item/clockwork/replica_fabricator/F = new
		if(H.equip_to_slot_or_del(F, ITEM_SLOT_BACKPACK))
			to_chat(H, "<span class='brass'>Вы получили в свое распоряжение фабрикатор реплик - усовершенствованный инструмент, который может превращать такие предметы, как двери, столы и даже пол, в эквиваленты часовых механизмов.</span>")
		slot = H.equip_in_one_of_slots(S, slots)
		if(slot == "В вашем рюкзаке")
			slot = "В вашем [H.back.name]"
	if(slot == "At your feet")
		if(!S.forceMove(get_turf(L)))
			qdel(S)
	if(S && !QDELETED(S))
		to_chat(L, "<span class='alloy'>[slot] <b>часовая плита</b>, универсальный инструмент, используемый для создания машин и произнесения древних слов силы. Если вы здесь впервые \
		в качестве слуги вы можете прочитать <a href=\"https://citadel-station.net/wikimain/index.php?title=Clockwork_Cult\">страницу на вики</a>, чтобы узнать больше.</span>")
		return TRUE
	return FALSE

/datum/game_mode/clockwork_cult/check_finished()
	if(GLOB.ark_of_the_clockwork_justiciar && !GLOB.ratvar_awakens) // Doesn't end until the Ark is destroyed or completed
		return FALSE
	return ..()

/datum/game_mode/clockwork_cult/proc/check_clockwork_victory()
	return main_clockcult.check_clockwork_victory()

/datum/game_mode/clockwork_cult/set_round_result()
	..()
	if(GLOB.clockwork_gateway_activated)
		SSticker.news_report = CLOCK_SUMMON
		SSticker.mode_result = "win - servants completed their objective (summon ratvar)"
	else
		SSticker.news_report = CULT_FAILURE
		SSticker.mode_result = "loss - servants failed their objective (summon ratvar)"

/datum/game_mode/clockwork_cult/generate_report()
	return "Блюспейс мониторы в вашем секторе с момента завершения строительства станции фиксируют непрерывный поток закономерных флуктуаций. Наиболее вероятно, что могущественная сущность \
	на чрезвычайно большом расстоянии использует станцию в качестве точки привязки для преодоления этого расстояния через блюспейс. Теоретически для этого потребовалось бы колоссальное количество энергии, а если \
	эта сущность враждебна, ей придётся полагаться на единственный центральный источник питания - нарушение его работы или уничтожение станет лучшим способом предотвратить причинение \
	вреда персоналу и имуществу Компании.<br><br>Проявляйте особую бдительность в отношении членов экипажа, которые выглядят необычно одетыми или используют способности, напоминающие магию. Эти сотрудники могут оказаться перебежчиками, \
	работающими на эту сущность и использующими чрезвычайно развитые технологии, позволяющие по своей воле преодолевать столь огромные расстояния. Если они окажутся реальной угрозой, обязанность по \
	их своевременной нейтрализации ложится на вас и ваш экипаж."

/datum/game_mode/proc/update_servant_icons_added(datum/mind/M)
	var/datum/atom_hud/antag/A = GLOB.huds[ANTAG_HUD_CLOCKWORK]
	A.join_hud(M.current)
	set_antag_hud(M.current, "clockwork")

/datum/game_mode/proc/update_servant_icons_removed(datum/mind/M)
	var/datum/atom_hud/antag/A = GLOB.huds[ANTAG_HUD_CLOCKWORK]
	A.leave_hud(M.current)
	set_antag_hud(M.current, null)



//Servant of Ratvar outfit
/datum/outfit/servant_of_ratvar
	name = "Servant of Ratvar"
	uniform = /obj/item/clothing/under/rank/engineering/engineer //no more chameleon suit for them, as requested
	shoes = /obj/item/clothing/shoes/sneakers/black
	back = /obj/item/storage/backpack
	ears = /obj/item/radio/headset
	gloves = /obj/item/clothing/gloves/color/yellow
	belt = /obj/item/storage/belt/utility/servant
	backpack_contents = list(/obj/item/storage/box/survival/engineer=1,\
	/obj/item/clockwork/replica_fabricator = 1, /obj/item/stack/tile/brass/fifty = 1, /obj/item/reagent_containers/food/drinks/bottle/holyoil = 1)
	id = /obj/item/modular_computer/pda
	var/plasmaman //We use this to determine if we should activate internals in post_equip()

/datum/outfit/servant_of_ratvar/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	if(H.dna.species.id == "plasmaman") //Plasmamen get additional equipment because of how they work
		head = /obj/item/clothing/head/helmet/space/plasmaman
		uniform = /obj/item/clothing/under/plasmaman //Plasmamen generally shouldn't need chameleon suits anyways, since everyone expects them to wear their fire suit
		r_hand = /obj/item/tank/internals/plasmaman/belt/full
		mask = /obj/item/clothing/mask/breath
		plasmaman = TRUE

/datum/outfit/servant_of_ratvar/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	var/obj/item/card/id/W = new(H)
	var/obj/item/modular_computer/pda/PDA = H.wear_id
	W.assignment = "Assistant"
	W.access += ACCESS_MAINT_TUNNELS
	W.registered_name = H.real_name
	W.update_label()
	if(plasmaman && !visualsOnly) //If we need to breathe from the plasma tank, we should probably start doing that
		H.internal = H.get_item_for_held_index(2)
	PDA.owner = H.real_name
	PDA.ownjob = "Assistant"
	PDA.update_label()
	PDA.InsertID(W)
	H.sec_hud_set_ID()

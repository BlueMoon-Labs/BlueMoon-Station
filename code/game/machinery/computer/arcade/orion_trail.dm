// *** THE ORION TRAIL ** //

#define ORION_TRAIL_WINTURN		9

//Orion Trail Events
#define ORION_TRAIL_RAIDERS		"Raiders"
#define ORION_TRAIL_FLUX		"Interstellar Flux"
#define ORION_TRAIL_ILLNESS		"Illness"
#define ORION_TRAIL_BREAKDOWN	"Breakdown"
#define ORION_TRAIL_LING		"Changelings?"
#define ORION_TRAIL_LING_ATTACK "Changeling Ambush"
#define ORION_TRAIL_MALFUNCTION	"Malfunction"
#define ORION_TRAIL_COLLISION	"Collision"
#define ORION_TRAIL_SPACEPORT	"Spaceport"
#define ORION_TRAIL_BLACKHOLE	"BlackHole"
#define ORION_TRAIL_OLDSHIP		"Old Ship"
#define ORION_TRAIL_SEARCH		"Old Ship Search"

#define ORION_STATUS_START		1
#define ORION_STATUS_NORMAL		2
#define ORION_STATUS_GAMEOVER	3
#define ORION_STATUS_MARKET		4

/obj/machinery/computer/arcade/orion_trail
	name = "Тропа Ориона"
	desc = "Узнайте, как наши предки добрались до Ориона, и повеселитесь!"
	icon_state = "arcade"
	circuit = /obj/item/circuitboard/computer/arcade/orion_trail
	var/busy = FALSE //prevent clickspam that allowed people to ~speedrun~ the game.
	var/engine = 0
	var/hull = 0
	var/electronics = 0
	var/food = 80
	var/fuel = 60
	var/turns = 4
	var/alive = 4
	var/event = null
	var/list/settlers = list("Harry","Larry","Bob")
	var/list/events = list(ORION_TRAIL_RAIDERS		= 3,
						   ORION_TRAIL_FLUX			= 1,
						   ORION_TRAIL_ILLNESS		= 3,
						   ORION_TRAIL_BREAKDOWN	= 2,
						   ORION_TRAIL_LING			= 3,
						   ORION_TRAIL_MALFUNCTION	= 2,
						   ORION_TRAIL_COLLISION	= 1,
						   ORION_TRAIL_SPACEPORT	= 2,
						   ORION_TRAIL_OLDSHIP		= 2
						   )
	var/list/stops = list()
	var/list/stopblurbs = list()
	var/lings_aboard = 0
	var/spaceport_raided = 0
	var/spaceport_freebie = 0
	var/last_spaceport_action = ""
	var/gameStatus = ORION_STATUS_START
	var/canContinueEvent = 0
	///list of event narrative text strings for TGUI
	var/list/event_text = list()
	///list of reasons for game over
	var/list/gameover_reasons = list()

	var/obj/item/radio/Radio
	var/list/gamers = list()
	var/killed_crew = 0


/obj/machinery/computer/arcade/orion_trail/Initialize(mapload)
	. = ..()
	Radio = new /obj/item/radio(src)
	Radio.listening = 0

/obj/machinery/computer/arcade/orion_trail/Destroy()
	QDEL_NULL(Radio)
	return ..()

/obj/machinery/computer/arcade/orion_trail/kobayashi
	name = "Компьютер управления Кобаяси Мару"
	desc = "Испытание для курсантов"
	icon = 'icons/obj/machines/particle_accelerator.dmi'
	icon_state = "control_boxp"
	events = list("Raiders" = 3, "Interstellar Flux" = 1, "Illness" = 3, "Breakdown" = 2, "Malfunction" = 2, "Collision" = 1, "Spaceport" = 2)
	prize_override = list(/obj/item/paper/fluff/holodeck/trek_diploma = 1)
	settlers = list("Kirk","Worf","Gene")

/obj/machinery/computer/arcade/orion_trail/Reset()
	// Sets up the main trail
	stops = list("Плутон","Пояс астероидов","Проксима Центавра","Мёртвый космос","Ригель Прайм","Тау Кита Бета","Чёрная дыра","Станция Бета-9","Орион Прайм")
	stopblurbs = list(
		"Плутон, давно оборудованный дальнобойными сенсорами и сканерами, продолжает исследовать дальние уголки галактики.",
		"На краю Солнечной системы лежит коварный пояс астероидов. Многие были раздавлены шальными астероидами и ошибочными решениями.",
		"Ближайшая к Солнцу звёздная система — когда-то она напоминала о пределах досветовых полётов, а теперь стала прибежищем путешественников и торговцев.",
		"Этот регион космоса особенно лишён материи. Такие пустоты известны, но их масштаб поражает.",
		"Ригель Прайм, центр системы Ригель, горит жарко, обогревая свои планеты теплом и радиацией.",
		"Тау Кита Бета недавно стала перевалочным пунктом для колонистов, направляющихся к Ориону. Здесь много кораблей и временных станций.",
		"Сенсоры показывают, что гравитационное поле чёрной дыры влияет на этот регион. Можно рискнуть и пройти напрямую, но есть опасность быть затянутыми. Или можно обогнуть, но это займёт больше времени.",
		"Вы подошли к первому рукотворному сооружению в этом регионе. Оно построено не путешественниками с Сола, а колонистами с Ориона. Памятник их успеху.",
		"Вы добрались до Ориона! Поздравляем! Ваш экипаж — один из немногих, кто основал новый плацдарм для человечества!"
		)

/obj/machinery/computer/arcade/orion_trail/proc/newgame()
	// Set names of settlers in crew
	settlers = list()
	for(var/i = 1; i <= 3; i++)
		add_crewmember()
	add_crewmember("[usr]")
	// Re-set items to defaults
	engine = 1
	hull = 1
	electronics = 1
	food = 80
	fuel = 60
	alive = 4
	turns = 1
	event = null
	event_text = list()
	gameover_reasons = list()
	gameStatus = ORION_STATUS_NORMAL
	lings_aboard = 0
	killed_crew = 0

	//spaceport junk
	spaceport_raided = 0
	spaceport_freebie = 0
	last_spaceport_action = ""

/obj/machinery/computer/arcade/orion_trail/proc/report_player(mob/gamer)
	if(gamers[gamer] == -2)
		return // enough harassing them

	if(gamers[gamer] == -1)
		say("ВНИМАНИЕ: Продолжение антисоциального поведения: выдача литературы по самопомощи.")
		new /obj/item/paper/pamphlet/violent_video_games(drop_location())
		gamers[gamer]--
		return

	if(!(gamer in gamers))
		gamers[gamer] = 0

	gamers[gamer]++ // How many times the player has 'prestiged' (massacred their crew)

	if(gamers[gamer] > 2 && prob(20 * gamers[gamer]))

		Radio.set_frequency(FREQ_SECURITY)
		Radio.talk_into(src, "ТРЕВОГА СЛУЖБЫ БЕЗОПАСНОСТИ: Член экипажа [gamer] демонстрирует антисоциальные склонности в [get_area(src)]. Просьба наблюдать за агрессивным поведением.", FREQ_SECURITY)

		Radio.set_frequency(FREQ_MEDICAL)
		Radio.talk_into(src, "ПСИХОЛОГИЧЕСКАЯ ТРЕВОГА: Член экипажа [gamer] демонстрирует антисоциальные склонности в [get_area(src)]. Просьба назначить психологическую оценку.", FREQ_MEDICAL)

		gamers[gamer] = -1

		gamer.client.give_award(/datum/award/achievement/misc/gamer, gamer) // PSYCH REPORT NOTE: patient kept rambling about how they did it for an "achievement", recommend continued holding for observation
		// gamer.mind?.adjust_experience(/datum/skill/gaming, 50) // cheevos make u better

		if(!isnull(GLOB.data_core.general))
			for(var/datum/data/record/R in GLOB.data_core.general)
				if(R.fields["name"] == gamer.name)
					R.fields["m_stat"] = "*Unstable*"
					return

/obj/machinery/computer/arcade/orion_trail/ui_interact(mob/user, datum/tgui/ui)
	if(!isliving(user))
		return
	check_gameover(user)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeOrionTrail", name)
		ui.open()
		ui.set_autoupdate(TRUE)

///checks if the game should end due to resource depletion and applies emag effects ONCE
/obj/machinery/computer/arcade/orion_trail/proc/check_gameover(mob/user)
	if(gameStatus == ORION_STATUS_GAMEOVER || gameStatus == ORION_STATUS_START)
		return
	if(fuel > 0 && food > 0 && settlers.len > 0)
		return
	gameStatus = ORION_STATUS_GAMEOVER
	event = null
	gameover_reasons = list()
	if(!settlers.len)
		gameover_reasons += "Весь экипаж погиб, и ваш корабль присоединяется к флоту кораблей-призраков, усеивающих галактику."
	if(food <= 0)
		gameover_reasons += "У вас кончилась еда и вы умерли от голода."
		if(obj_flags & EMAGGED && isliving(user))
			var/mob/living/L = user
			L.set_nutrition(0)
			to_chat(L, "<span class='userdanger'>Ваше тело мгновенно сжимается, как у человека, не евшего месяцами. Мучительные судороги скручивают вас, и вы падаете на пол.</span>")
	if(fuel <= 0)
		gameover_reasons += "У вас кончилось топливо, и вы медленно дрейфуете в звезду."
		if(obj_flags & EMAGGED && isliving(user))
			var/mob/living/M = user
			M.adjust_fire_stacks(5)
			M.IgniteMob()
			to_chat(M, "<span class='userdanger'>Вы чувствуете чудовищную волну жара от автомата. Ваша кожа вспыхивает пламенем.</span>")
	if(obj_flags & EMAGGED && isliving(user))
		to_chat(user, "<span class='userdanger'>Вам никогда не добраться до Ориона...</span>")
		var/mob/living/dead_user = user
		dead_user.death()
		obj_flags &= ~EMAGGED
		gameStatus = ORION_STATUS_START
		name = "Тропа Ориона"
		desc = "Узнайте, как наши предки добрались до Ориона, и повеселитесь!"

/obj/machinery/computer/arcade/orion_trail/ui_data(mob/user)
	var/list/data = list()
	data["gameStatus"] = gameStatus
	data["food"] = food
	data["fuel"] = fuel
	data["engine"] = engine
	data["hull"] = hull
	data["electronics"] = electronics
	data["settlers"] = settlers
	data["alive"] = alive
	data["turns"] = turns
	data["event"] = event
	data["event_text"] = event_text
	data["canContinueEvent"] = canContinueEvent
	data["emagged"] = !!(obj_flags & EMAGGED)
	data["spaceport_raided"] = spaceport_raided
	data["last_spaceport_action"] = last_spaceport_action
	if(turns >= 1 && turns <= stops.len)
		data["stopName"] = stops[turns]
		data["stopBlurb"] = stopblurbs[turns]
	data["gameover_reasons"] = gameover_reasons
	return data

/obj/machinery/computer/arcade/orion_trail/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(busy)
		return
	busy = TRUE

	var/gamerSkill = 0
	var/gamerSkillRands = 0

	switch(action)
		if("continue")
			if(gameStatus == ORION_STATUS_NORMAL && !event && turns != 7)
				if(turns >= ORION_TRAIL_WINTURN)
					win(usr)
				else
					food -= (alive+lings_aboard)*2
					fuel -= 5
					if(turns == 2 && prob(30-gamerSkill))
						event = ORION_TRAIL_COLLISION
						event()
					else if(prob(75-gamerSkill))
						event = pickweight(events)
						if(lings_aboard)
							if(event == ORION_TRAIL_LING || prob(55-gamerSkill))
								event = ORION_TRAIL_LING_ATTACK
						event()
					turns += 1
				if(obj_flags & EMAGGED && isliving(usr))
					var/mob/living/carbon/M = usr
					switch(event)
						if(ORION_TRAIL_RAIDERS)
							if(prob(50-gamerSkill))
								to_chat(usr, "<span class='userdanger'>Вы слышите боевые крики. Топот сапог по холодному металлу. Крики агонии. Шум выходящего воздуха. Вы сходите с ума?</span>")
								M.hallucination += 30
							else
								to_chat(usr, "<span class='userdanger'>Что-то бьёт вас сзади! Адская боль, похоже на удар тупым предметом, но никого нет...</span>")
								M.take_bodypart_damage(30)
								playsound(loc, 'sound/weapons/genhit2.ogg', 100, TRUE)
						if(ORION_TRAIL_ILLNESS)
							var/severity = rand(1,3)
							if(severity == 1)
								to_chat(M, "<span class='userdanger'>Вы внезапно чувствуете лёгкую тошноту.</span>")
							if(severity == 2)
								to_chat(usr, "<span class='userdanger'>Вы внезапно чувствуете сильнейшую тошноту и сгибаетесь пополам, пока не пройдёт.</span>")
								M.Stun(60)
							if(severity >= 3)
								to_chat(M, "<span class='warning'>Невыносимая волна тошноты накрывает вас. Вы сгибаетесь, содержимое желудка готовится к эффектному выходу.</span>")
								M.Stun(100)
								spawn()
									sleep(30)
									if(!QDELETED(M))
										M.vomit(10, distance = 5)
						if(ORION_TRAIL_FLUX)
							if(prob(75-gamerSkill))
								M.DefaultCombatKnockdown(60)
								say("Внезапный порыв мощного ветра бросает [M] на пол!")
								M.take_bodypart_damage(25)
								playsound(loc, 'sound/weapons/genhit.ogg', 100, TRUE)
							else
								to_chat(M, "<span class='userdanger'>Сильнейший ветер проносится мимо вас, и вы еле удерживаетесь на ногах!</span>")
						if(ORION_TRAIL_COLLISION)
							if(prob(90-gamerSkill))
								playsound(loc, 'sound/effects/bang.ogg', 100, TRUE)
								var/turf/open/floor/F
								for(F in orange(1, src))
									F.ScrapeAway()
								say("Что-то врезается в пол вокруг [src], обнажая его космосу!")
								if(hull)
									spawn()
										sleep(10)
										if(!QDELETED(src))
											say("Новый пол внезапно появляется вокруг [src]. Что за черт?")
											playsound(loc, 'sound/weapons/genhit.ogg', 100, TRUE)
											var/turf/open/space/T
											for(T in orange(1, src))
												T.PlaceOnTop(/turf/open/floor/plating)
							else
								say("Что-то врезается в пол вокруг [src] — к счастью, не пробило!")
								playsound(loc, 'sound/effects/bang.ogg', 50, TRUE)
						if(ORION_TRAIL_MALFUNCTION)
							playsound(loc, 'sound/effects/empulse.ogg', 50, TRUE)
							visible_message("<span class='danger'>[src] сбоит, рандомизируя игровые параметры!</span>")
							var/oldfood = food
							var/oldfuel = fuel
							food = rand(10,80) / rand(1,2)
							fuel = rand(10,60) / rand(1,2)
							if(electronics)
								spawn()
									sleep(10)
									if(!QDELETED(src))
										if(oldfuel > fuel && oldfood > food)
											audible_message("<span class='danger'>[src] lets out a somehow reassuring chime.</span>")
										else if(oldfuel < fuel || oldfood < food)
											audible_message("<span class='danger'>[src] lets out a somehow ominous chime.</span>")
										food = oldfood
										fuel = oldfuel
										playsound(loc, 'sound/machines/chime.ogg', 50, TRUE)

		if("newgame")
			if(gameStatus == ORION_STATUS_START)
				newgame()

		if("menu")
			if(gameStatus == ORION_STATUS_GAMEOVER)
				gameStatus = ORION_STATUS_START
				event = null
				food = 80
				fuel = 60
				settlers = list("Harry","Larry","Bob")

		if("search")
			if(event == ORION_TRAIL_OLDSHIP)
				event = ORION_TRAIL_SEARCH
				event()

		if("slow")
			if(event == ORION_TRAIL_FLUX)
				food -= (alive+lings_aboard)*2
				fuel -= 5
			event = null

		if("pastblack")
			if(turns == 7)
				food -= ((alive+lings_aboard)*2)*3
				fuel -= 15
				turns += 1
				event = null

		if("useengine")
			if(event == ORION_TRAIL_BREAKDOWN)
				engine = max(0, --engine)
				event = null

		if("useelec")
			if(event == ORION_TRAIL_MALFUNCTION)
				electronics = max(0, --electronics)
				event = null

		if("usehull")
			if(event == ORION_TRAIL_COLLISION)
				hull = max(0, --hull)
				event = null

		if("wait")
			if(event == ORION_TRAIL_BREAKDOWN || event == ORION_TRAIL_MALFUNCTION || event == ORION_TRAIL_COLLISION)
				food -= ((alive+lings_aboard)*2)*3
				event = null

		if("keepspeed")
			if(event == ORION_TRAIL_FLUX)
				if(prob(75))
					event = "Breakdown"
					event()
				else
					event = null

		if("blackhole")
			if(turns == 7)
				if(prob(75-gamerSkill))
					event = ORION_TRAIL_BLACKHOLE
					event()
					if(obj_flags & EMAGGED && isliving(usr))
						playsound(loc, 'sound/effects/supermatter.ogg', 100, TRUE)
						say("Миниатюрная чёрная дыра внезапно появляется перед [src], поглощая [usr] заживо!")
						var/mob/living/L = usr
						L.Stun(200, ignore_canstun = TRUE)
						var/S = new /obj/singularity/gravitational/academy(usr.loc)
						addtimer(CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), "[S] исчезает так же внезапно, как и появилось."), 50)
						QDEL_IN(S, 50)
				else
					event = null
					turns += 1

		if("holedeath")
			if(event == ORION_TRAIL_BLACKHOLE)
				gameStatus = ORION_STATUS_GAMEOVER
				gameover_reasons = list("Вы были поглощены чёрной дырой.")
				event = null

		if("eventclose")
			if(canContinueEvent)
				event = null

		if("killcrew")
			if(gameStatus == ORION_STATUS_NORMAL || event == ORION_TRAIL_LING)
				var/sheriff = remove_crewmember()
				playsound(loc,'sound/weapons/gunshot.ogg', 100, TRUE)
				killed_crew++
				if(settlers.len == 0 || alive == 0)
					say("Последний член экипажа, [sheriff], застрелился. ИГРА ОКОНЧЕНА!")
					if(obj_flags & EMAGGED && isliving(usr))
						var/mob/living/dead_user = usr
						dead_user.death(FALSE)
					gameStatus = ORION_STATUS_GAMEOVER
					gameover_reasons = list("[sheriff] застрелился. ИГРА ОКОНЧЕНА!")
					event = null
					if(killed_crew >= 4)
						report_player(usr)
				else if(obj_flags & EMAGGED && isliving(usr))
					if(usr.name == sheriff)
						say("Экипаж корабля решил убить [usr.name]!")
						var/mob/living/dead_player = usr
						dead_player.death(FALSE)
				if(event == ORION_TRAIL_LING)
					event = null
					killed_crew--

		if("buycrew")
			if(gameStatus == ORION_STATUS_MARKET)
				if(!spaceport_raided && food >= 10 && fuel >= 10)
					var/bought = add_crewmember()
					last_spaceport_action = "Вы наняли [bought] в качестве нового члена экипажа."
					fuel -= 10
					food -= 10
					killed_crew--

		if("sellcrew")
			if(gameStatus == ORION_STATUS_MARKET)
				if(!spaceport_raided && settlers.len > 1)
					var/sold = remove_crewmember()
					last_spaceport_action = "Вы продали члена экипажа [sold]!"
					fuel += 7
					food += 7

		if("leave_spaceport")
			if(gameStatus == ORION_STATUS_MARKET)
				event = null
				gameStatus = ORION_STATUS_NORMAL
				spaceport_raided = 0
				spaceport_freebie = 0
				last_spaceport_action = ""

		if("raid_spaceport")
			if(gameStatus == ORION_STATUS_MARKET)
				if(!spaceport_raided)
					var/success = min(15 * alive + gamerSkill,100)
					spaceport_raided = 1
					var/FU = 0
					var/FO = 0
					if(prob(success))
						FU = rand(5 + gamerSkillRands,15 + gamerSkillRands)
						FO = rand(5 + gamerSkillRands,15 + gamerSkillRands)
						last_spaceport_action = "Успешный налёт на космопорт! (+[FU] Топлива, +[FO] Еды)"
					else
						FU = rand(-5,-15)
						FO = rand(-5,-15)
						last_spaceport_action = "Налёт провалился! (-[FU*-1] Топлива, -[FO*-1] Еды)"
						if(prob(success*5))
							var/lost_crew = remove_crewmember()
							last_spaceport_action = "Налёт провалился! Потерян: [lost_crew], [FU*-1] Топлива, [FO*-1] Еды!"
							if(obj_flags & EMAGGED)
								say("ВИУ-ВИУ! ВИУ-ВИУ! Охрана космопорта уже в пути!")
								playsound(src, 'sound/items/weeoo1.ogg', 100, FALSE)
								for(var/i, i<=3, i++)
									var/mob/living/simple_animal/hostile/syndicate/ranged/smg/orion/O = new/mob/living/simple_animal/hostile/syndicate/ranged/smg/orion(get_turf(src))
									O.target = usr
					fuel += FU
					food += FO

		if("buyparts")
			if(gameStatus == ORION_STATUS_MARKET)
				if(!spaceport_raided && fuel > 5)
					var/part_type = text2num(params["type"])
					switch(part_type)
						if(1)
							engine++
							last_spaceport_action = "Куплены запчасти двигателя"
						if(2)
							hull++
							last_spaceport_action = "Куплены пластины корпуса"
						if(3)
							electronics++
							last_spaceport_action = "Куплена запасная электроника"
					fuel -= 5

		if("trade")
			if(gameStatus == ORION_STATUS_MARKET)
				if(!spaceport_raided)
					var/trade_type = text2num(params["type"])
					switch(trade_type)
						if(1)
							if(fuel > 5)
								fuel -= 5
								food += 5
								last_spaceport_action = "Обменяли топливо на еду"
						if(2)
							if(food > 5)
								fuel += 5
								food -= 5
								last_spaceport_action = "Обменяли еду на топливо"

	check_gameover(usr)
	add_fingerprint(usr)
	busy = FALSE
	. = TRUE

/obj/machinery/computer/arcade/orion_trail/proc/event()
	event_text = list()
	canContinueEvent = 0
	switch(event)
		if(ORION_TRAIL_RAIDERS)
			event_text += "Рейдеры проникли на ваш корабль!"
			if(prob(50))
				var/sfood = rand(1,10)
				var/sfuel = rand(1,10)
				food -= sfood
				fuel -= sfuel
				event_text += "Они украли [sfood] Еды и [sfuel] Топлива."
			else if(prob(10))
				var/deadname = remove_crewmember()
				event_text += "[deadname] попытался дать отпор, но был убит."
			else
				event_text += "К счастью, вы отбились без проблем."
			canContinueEvent = 1

		if(ORION_TRAIL_FLUX)
			event_text += "Этот регион космоса очень турбулентен."
			event_text += "Если замедлиться, можно избежать повреждений, но если держать скорость — не потратим припасы. Что будете делать?"

		if(ORION_TRAIL_OLDSHIP)
			event_text += "Экипаж заметил старый корабль, дрейфующий в космосе. Там могут быть припасы, но он выглядит небезопасно."
			canContinueEvent = 1

		if(ORION_TRAIL_SEARCH)
			switch(rand(100))
				if(0 to 15)
					var/rescued = add_crewmember()
					var/oldfood = rand(1,7)
					var/oldfuel = rand(4,10)
					food += oldfood
					fuel += oldfuel
					event_text += "Осматривая его, вы находите припасы и живого человека!"
					event_text += "[rescued] спасён с заброшенного корабля!"
					event_text += "Найдено [oldfood] Еды и [oldfuel] Топлива."
				if(15 to 35)
					var/lfuel = rand(4,7)
					var/deadname = remove_crewmember()
					fuel -= lfuel
					event_text += "[deadname] потерян в глубине обломков, а ваш корабль потерял [lfuel] Топлива при маневрировании."
				if(35 to 65)
					var/oldfood = rand(5,11)
					food += oldfood
					engine++
					event_text += "Вы нашли [oldfood] Еды и несколько запчастей среди обломков."
				else
					event_text += "Осматривая обломки, вы не находите ничего полезного."
			canContinueEvent = 1

		if(ORION_TRAIL_ILLNESS)
			event_text += "Смертельная болезнь поразила экипаж!"
			var/deadname = remove_crewmember()
			event_text += "[deadname] был убит болезнью."
			canContinueEvent = 1

		if(ORION_TRAIL_BREAKDOWN)
			event_text += "О нет! Двигатель сломался!"
			event_text += "Можно починить запчастью двигателя или потратить 3 дня на ремонт."

		if(ORION_TRAIL_MALFUNCTION)
			event_text += "Системы корабля неисправны!"
			event_text += "Можно заменить сломанную электронику запасной или потратить 3 дня на отладку ИИ."

		if(ORION_TRAIL_COLLISION)
			event_text += "Что-то врезалось в нас! Похоже, корпус повреждён."
			if(prob(25))
				var/sfood = rand(5,15)
				var/sfuel = rand(5,15)
				food -= sfood
				fuel -= sfuel
				event_text += "[sfood] Еды и [sfuel] Топлива вылетело в космос."
			if(prob(10))
				var/deadname = remove_crewmember()
				event_text += "[deadname] погиб от быстрой разгерметизации."
			event_text += "Можно починить обшивкой или потратить 3 дня на сварку обломков."

		if(ORION_TRAIL_BLACKHOLE)
			event_text += "Вас затянуло в чёрную дыру."
			settlers = list()

		if(ORION_TRAIL_LING)
			event_text += "Странные сообщения предупреждают о генокрадах, проникающих в экипажи на пути к Ориону..."
			if(settlers.len <= 2)
				event_text += "Шансы вашего экипажа добраться до Ориона столь малы, что генокрады, скорее всего, обошли вас стороной..."
				if(prob(10))
					lings_aboard = min(++lings_aboard,2)
			else
				if(lings_aboard)
					if(prob(20))
						lings_aboard = min(++lings_aboard,2)
				else if(prob(70))
					lings_aboard = min(++lings_aboard,2)
			canContinueEvent = 1

		if(ORION_TRAIL_LING_ATTACK)
			if(lings_aboard <= 0)
				event_text += "Ха-ха, попались — никаких генокрадов на борту нет!"
			else
				var/ling1 = remove_crewmember()
				var/ling2 = ""
				if(lings_aboard >= 2)
					ling2 = remove_crewmember()

				event_text += "Генокрады среди экипажа внезапно выскакивают из укрытия и атакуют!"
				if(ling2)
					event_text += "Руки [ling1] и [ling2] скручиваются и превращаются в уродливые клинки!"
				else
					event_text += "Рука [ling1] скручивается и превращается в уродливый клинок!"

				var/chance2attack = alive*20
				if(prob(chance2attack))
					var/chancetokill = 30*lings_aboard-(5*alive)
					if(prob(chancetokill))
						var/deadguy = remove_crewmember()
						var/murder_text = pick("Генокрад[ling2 ? "\u044b" : ""] настига[ling2 ? "\u044e\u0442" : "\u0435\u0442"] [deadguy] и потроша[ling2 ? "\u0442" : "\u0442"] его!", \
							"[ling2 ? pick(ling1, ling2) : ling1] загоняет [deadguy] в угол и протыкает его!", \
							"[ling2 ? pick(ling1, ling2) : ling1] обезглавливает [deadguy]!")
						event_text += murder_text
					else
						event_text += "Вы доблестно отбились от генокрад[ling2 ? "\u043e\u0432":"\u0430"]!"
						if(ling2)
							food += 30
							lings_aboard = max(0,lings_aboard-2)
						else
							food += 15
							lings_aboard = max(0,--lings_aboard)
						event_text += "Вы разделали генокрад[ling2 ? "\u043e\u0432" : "\u0430"] на мясо, получив [ling2 ? "30" : "15"] Еды!"
				else
					event_text += "Почувствовав неблагоприятные шансы, генокрад[ling2 ? "\u044b \u0438\u0441\u0447\u0435\u0437\u0430\u044e\u0442":" \u0438\u0441\u0447\u0435\u0437\u0430\u0435\u0442"] в космосе! Вы в безопасности... пока что."
					if(ling2)
						lings_aboard = max(0,lings_aboard-2)
					else
						lings_aboard = max(0,--lings_aboard)
			canContinueEvent = 1

		if(ORION_TRAIL_SPACEPORT)
			gameStatus = ORION_STATUS_MARKET
			event_text += "Прыжок в сектор привёл вас к космопорту — удачная находка!"
			event_text += "Этот космопорт — дом путешественников, которые не добрались до Ориона, но нашли другой дом..."

			if(!spaceport_freebie && (fuel < 20 || food < 20))
				spaceport_freebie++
				var/FU = 10
				var/FO = 10
				var/freecrew = 0
				if(prob(30))
					FU = 25
					FO = 25
				if(prob(10))
					add_crewmember()
					freecrew++
				event_text += "Торговцы сжалились над вами и дали бесплатные припасы! (+[FU] Топлива, +[FO] Еды)"
				if(freecrew)
					event_text += "Вы также получаете нового члена экипажа!"
				fuel += FU
				food += FO

//Add Random/Specific crewmember
/obj/machinery/computer/arcade/orion_trail/proc/add_crewmember(specific = "")
	var/newcrew = ""
	if(specific)
		newcrew = specific
	else
		if(prob(50))
			newcrew = pick(GLOB.first_names_male)
		else
			newcrew = pick(GLOB.first_names_female)
	if(newcrew)
		settlers += newcrew
		alive++
	return newcrew


//Remove Random/Specific crewmember
/obj/machinery/computer/arcade/orion_trail/proc/remove_crewmember(specific = "", dont_remove = "")
	var/list/safe2remove = settlers
	var/removed = ""
	if(dont_remove)
		safe2remove -= dont_remove
	if(specific && specific != dont_remove)
		safe2remove = list(specific)
	else
		removed = pick(safe2remove)

	if(removed)
		if(lings_aboard && prob(40*lings_aboard)) //if there are 2 lings you're twice as likely to get one, obviously
			lings_aboard = max(0,--lings_aboard)
		settlers -= removed
		alive--
	return removed


/obj/machinery/computer/arcade/orion_trail/proc/win(mob/user)
	gameStatus = ORION_STATUS_START
	say("Поздравляем, вы добрались до Ориона!")
	if(obj_flags & EMAGGED)
		new /obj/item/orion_ship(loc)
		message_admins("[ADMIN_LOOKUPFLW(usr)] добрался до Ориона на взломанном автомате и получил взрывной кораблик.")
		log_game("[key_name(usr)] добрался до Ориона на взломанном автомате и получил взрывной кораблик.")
	else
		prizevend(user)
	obj_flags &= ~EMAGGED
	name = "Тропа Ориона"
	desc = "Узнайте, как наши предки добрались до Ориона, и повеселитесь!"

/obj/machinery/computer/arcade/orion_trail/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	to_chat(user, "<span class='notice'>Вы обходите меню чит-кодов и переходите к Читу #[rand(1, 50)]: Режим реализма.</span>")
	name = "Тропа Ориона: Издание Реализм"
	desc = "Узнайте, как наши предки добрались до Ориона, и постарайтесь не умереть!"
	newgame()
	obj_flags |= EMAGGED
	return TRUE

/mob/living/simple_animal/hostile/syndicate/ranged/smg/orion
	name = "охрана космопорта"
	desc = "Элитные корпоративные силы безопасности для всех космопортов на Тропе Ориона."
	faction = list("orion")
	loot = list()
	del_on_death = TRUE

/obj/item/orion_ship
	name = "модель колониального корабля"
	desc = "Модель космического корабля, похожа на те, что использовались при полёте к Ориону! У неё даже есть миниатюрный реактор FX-293, известный своей нестабильностью и склонностью к взрывам..."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "ship"
	w_class = WEIGHT_CLASS_SMALL
	var/active = 0 //if the ship is on

/obj/item/orion_ship/examine(mob/user)
	. = ..()
	if(!(in_range(user, src)))
		return
	if(!active)
		. += "<span class='notice'>На днище есть маленький переключатель. Он опущен.</span>"
	else
		. += "<span class='notice'>На днище есть маленький переключатель. Он поднят.</span>"

/obj/item/orion_ship/attack_self(mob/user) //Minibomb-level explosion. Should probably be more because of how hard it is to survive the machine! Also, just over a 5-second fuse
	if(active)
		return

	message_admins("[ADMIN_LOOKUPFLW(usr)] активировал взрывной кораблик Ориона для детонации в [AREACOORD(usr)].")
	log_game("[key_name(usr)] активировал взрывной кораблик Ориона для детонации в [AREACOORD(usr)].")

	to_chat(user, "<span class='warning'>Вы переключаете тумблер на днище [src].</span>")
	active = 1
	visible_message("<span class='notice'>[src] тихо пикает и оживает!</span>")
	playsound(loc, 'sound/machines/defib_SaftyOn.ogg', 25, TRUE)
	say("Это корабль ID #[rand(1,1000)] вызывает диспетчерскую Ориона. Заходим на посадку, приём.")
	sleep(20)
	visible_message("<span class='warning'>[src] начинает вибрировать...</span>")
	say("Эм, диспетчер? Проблемы с реактором, можете проверить? Приём.")
	sleep(30)
	say("О боже! Код восемь! КОД ВОСЕМЬ! СЕЙЧАС РВАНЁ—")
	playsound(loc, 'sound/machines/buzz-sigh.ogg', 25, TRUE)
	sleep(3.6)
	visible_message("<span class='userdanger'>[src] взрывается!</span>")
	explosion(loc, 2,4,8, flame_range = 16)
	qdel(src)

#undef ORION_TRAIL_WINTURN
#undef ORION_TRAIL_RAIDERS
#undef ORION_TRAIL_FLUX
#undef ORION_TRAIL_ILLNESS
#undef ORION_TRAIL_BREAKDOWN
#undef ORION_TRAIL_LING
#undef ORION_TRAIL_LING_ATTACK
#undef ORION_TRAIL_MALFUNCTION
#undef ORION_TRAIL_COLLISION
#undef ORION_TRAIL_SPACEPORT
#undef ORION_TRAIL_BLACKHOLE

#undef ORION_STATUS_START
#undef ORION_STATUS_NORMAL
#undef ORION_STATUS_GAMEOVER
#undef ORION_STATUS_MARKET

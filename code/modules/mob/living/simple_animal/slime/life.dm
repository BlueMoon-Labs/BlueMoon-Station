
/mob/living/simple_animal/slime
	var/Atkcool = 0 // attack cooldown
	var/atkcool_timer_id
	var/Tempstun = 0 // temporary temperature stuns
	var/Discipline = 0 // if a slime has been hit with a freeze gun, or wrestled/attacked off a human, they become disciplined and don't attack anymore for a while
	var/SStun = 0 // stun variable
	var/next_hunt_scan = 0 // world.time gate for the prey view() scan in handle_targets(); set only after a scan that found nothing
	var/next_wander = 0 // world.time gate for aimless wandering in handle_targets()
	/// Оценка голода (0/1/2), зафиксированная на всю текущую погоню. См. latch_chase_hunger().
	var/chase_hunger = 0

	typing_indicator_state = /obj/effect/overlay/typing_indicator/slime

/// TRUE when this slime is allowed to take an aimless wander step this tick.
/// Aimless wandering was the single biggest slime cost on a packed xenobio farm:
/// one step out of a crowded turf costs hundreds of microseconds, and every slime
/// was rolling for one on every Life tick. Hunting and following a leader are
/// deliberately NOT gated by this.
/mob/living/simple_animal/slime/proc/can_wander_now()
	return world.time >= next_wander

/// Records that a wander step was taken, starting the cooldown.
/mob/living/simple_animal/slime/proc/note_wander()
	next_wander = world.time + SLIME_WANDER_COOLDOWN

/mob/living/simple_animal/slime/BiologicalLife(delta_time, times_fired)
	// Слайм в стазисе/бессознанке не доходит до AI-очистки ниже, поэтому удалённые
	// цели вычищаем до всех гейтов - иначе Target/Leader вечно держат qdel-нутого
	// моба (массовые хардделы обезьян на ферме)
	if(Target && QDELETED(Target))
		Target = null
	if(Leader && QDELETED(Leader))
		Leader = null
	if(!(. = ..()))
		return
	if(buckled)
		handle_feeding()
	if(!stat) // Slimes in stasis don't lose nutrition, don't change mood and don't respond to speech
		handle_nutrition()
		if(QDELETED(src)) // Reproduce()/Evolve() qdel-ят слайма прямо из handle_nutrition; Destroy() уже занулил speech_buffer и прочее
			return
		handle_targets()
		if (!ckey)
			handle_mood()
			handle_speech()

// Unlike most of the simple animals, slimes support UNCONSCIOUS
/mob/living/simple_animal/slime/update_stat()
	if(stat == UNCONSCIOUS && health > 0)
		return
	..()

///Нудж событийной погони (замена INVOKE_ASYNC(AIprocess) старого мозга):
///зеркалим Target в blackboard контроллера и пересчитываем его статус.
///Сама погоня и решающее дерево кормёжки живут в /datum/ai_controller/slime.
/mob/living/simple_animal/slime/proc/slime_wake_pursuit()
	if(QDELETED(src) || isnull(ai_controller))
		return
	if(QDELETED(Target))
		ai_controller.clear_blackboard_key(BB_SLIME_TARGET)
	else
		ai_controller.set_blackboard_key(BB_SLIME_TARGET, Target)
		if(ai_controller.on_failed_planning_timeout) //свежая цель не ждёт конца таймаута пустого планирования
			ai_controller.resume_planning()
	ai_controller.reset_ai_status()

/mob/living/simple_animal/slime/proc/reset_atkcool()
	Atkcool = 0

/mob/living/simple_animal/slime/handle_environment(datum/gas_mixture/environment)
	if(!environment)
		return

	var/loc_temp = get_temperature(environment)

	adjust_bodytemperature(adjust_body_temperature(bodytemperature, loc_temp, 1))

	//Account for massive pressure differences

	if(bodytemperature < (T0C + 5)) // start calculating temperature damage etc
		if(bodytemperature <= (T0C - 40)) // stun temperature
			Tempstun = 1

		if(bodytemperature <= (T0C - 50)) // hurt temperature
			if(bodytemperature <= 50) // sqrting negative numbers is bad
				adjustBruteLoss(200)
			else
				adjustBruteLoss(round(sqrt(bodytemperature)) * 2)

	else
		Tempstun = 0

	if(stat != DEAD)
		// Нервный газ - редкость, а total_moles() платился каждый тик каждым
		// слаймом фермы. Считаем долю только когда BZ вообще есть в смеси.
		var/stasis = force_stasis
		if(!stasis && bodytemperature < (T0C + 100))
			var/bz_moles = environment.get_moles(GAS_BZ)
			if(bz_moles)
				var/total_moles = environment.total_moles()
				stasis = total_moles && (bz_moles / total_moles) >= 0.05

		if(stat == CONSCIOUS && stasis)
			to_chat(src, "<span class='danger'>Nerve gas in the air has put you in stasis!</span>")
			set_stat(UNCONSCIOUS)
			powerlevel = 0
			rabid = 0
			update_mobility()
			regenerate_icons()
		else if(stat == UNCONSCIOUS && !stasis)
			to_chat(src, "<span class='notice'>You wake up from the stasis.</span>")
			set_stat(CONSCIOUS)
			update_mobility()
			regenerate_icons()

	// Безусловного updatehealth() здесь больше нет: он тянул полный каскад
	// (5 геттеров урона + update_stat + два med-HUD + healthdoll) на каждого
	// слайма каждый тик, а урон/лечение слайма и так идёт через adjust*Loss,
	// который сам зовёт updatehealth. На ферме это было ~13% стоимости SSmobs.
	return //TODO: DEFERRED

/mob/living/simple_animal/slime/proc/adjust_body_temperature(current, loc_temp, boost)
	var/temperature = current
	var/difference = abs(current-loc_temp)	//get difference
	var/increments// = difference/10			//find how many increments apart they are
	if(difference > 50)
		increments = difference/5
	else
		increments = difference/10
	var/change = increments*boost	// Get the amount to change by (x per increment)
	var/temp_change
	if(current < loc_temp)
		temperature = min(loc_temp, temperature+change)
	else if(current > loc_temp)
		temperature = max(loc_temp, temperature-change)
	temp_change = (temperature - current)
	return temp_change

/mob/living/simple_animal/slime/handle_status_effects()
	..()
	if(prob(30) && !stat)
		adjustBruteLoss(-1)

/mob/living/simple_animal/slime/proc/handle_feeding()
	if(!ismob(buckled))
		return
	var/mob/M = buckled

	if(stat)
		Feedstop(silent = TRUE)

	if(M.stat == DEAD) // our victim died
		if(!client)
			if(!rabid && !attacked)
				var/mob/living/carbon/their_attacker = M.getLAssailant()
				if(their_attacker && their_attacker != M)
					if(prob(50))
						if(!(their_attacker in Friends))
							Friends[their_attacker] = 1
							RegisterSignal(their_attacker, COMSIG_PARENT_QDELETING, PROC_REF(clear_friend))
						else
							++Friends[their_attacker]
		else
			to_chat(src, "<i>This subject does not have a strong enough life energy anymore...</i>")

		if(M.client && ishuman(M))
			if(prob(85))
				rabid = 1 //we go rabid after finishing to feed on a human with a client.

		Feedstop()
		return

	if(iscarbon(M))
		// BLUEMOON ADD START - роботы не получают повреждений от того, что ими пытается кормиться слайм
		if(HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM))
			if(prob(10))
				to_chat(src, "<i>This subject does not have a strong enough life energy anymore...</i>")
			return
		// BLUEMOON ADD END
		var/mob/living/carbon/C = M
		C.adjustCloneLoss(rand(2,4))
		C.adjustToxLoss(rand(1,2))

		if(prob(10) && C.client)
			to_chat(C, "<span class='userdanger'>[pick("You can feel your body becoming weak!", \
			"You feel like you're about to die!", \
			"You feel every part of your body screaming in agony!", \
			"A low, rolling pain passes through your body!", \
			"Your body feels as if it's falling apart!", \
			"You feel extremely weak!", \
			"A sharp, deep pain bathes every inch of your body!")]</span>")

	else if(isanimal(M))
		var/mob/living/simple_animal/SA = M

		var/totaldamage = 0 //total damage done to this unfortunate animal
		totaldamage += SA.adjustCloneLoss(rand(2,4))
		totaldamage += SA.adjustToxLoss(rand(1,2))

		if(totaldamage <= 0) //if we did no(or negative!) damage to it, stop
			Feedstop(0, 0)
			return

	else
		Feedstop(0, 0)
		return

	adjust_nutrition((rand(7, 15) * CONFIG_GET(number/damage_multiplier)), get_max_nutrition(), TRUE)

	//Heal yourself.
	adjustBruteLoss(-3)

/mob/living/simple_animal/slime/proc/handle_nutrition()

	if(docile) //God as my witness, I will never go hungry again
		nutrition = 700
		return

	if(prob(15))
		adjust_nutrition(-1 - is_adult)

	if(nutrition <= 0 && prob(75))
		adjustBruteLoss(rand(0,5))

	else if (nutrition >= get_grow_nutrition() && amount_grown < SLIME_EVOLUTION_THRESHOLD)
		adjust_nutrition(-20)
		amount_grown++
		update_action_buttons_icon()

	if(amount_grown >= SLIME_EVOLUTION_THRESHOLD && !buckled && !Target && !ckey)
		if(is_adult)
			Reproduce()
		else
			Evolve()

/mob/living/simple_animal/slime/adjust_nutrition(change, max = INFINITY, slime_check = FALSE)
	. = ..()
	if(!slime_check)
		return
	if(nutrition >= get_grow_nutrition())
		if(powerlevel<10)
			if(prob(30-powerlevel*2))
				powerlevel++
	else if(nutrition >= get_hunger_nutrition() + 100) //can't get power levels unless you're a bit above hunger level.
		if(powerlevel<5)
			if(prob(25-powerlevel*5))
				powerlevel++

/mob/living/simple_animal/slime/proc/handle_targets()
	update_mobility()

	if(attacked > 50)
		attacked = 50

	if(attacked > 0)
		attacked--

	if(Discipline > 0)

		if(Discipline >= 5 && rabid)
			if(prob(60))
				rabid = 0

		if(prob(10))
			Discipline--

	if(!client)
		if(!CHECK_MOBILITY(src, MOBILITY_MOVE))
			return

		if(buckled)
			return // if it's eating someone already, continue eating!

		if(Target)
			--target_patience
			if (target_patience <= 0 || SStun > world.time || Discipline || attacked || docile) // Tired of chasing or something draws out attention
				target_patience = 0
				Target = null

		//Погоня окончена - снимаем зафиксированную оценку голода, чтобы следующая
		//цель взяла свежую. Цель могли обнулить и снаружи (give_up контроллера,
		//дисциплина, вода), поэтому проверка стоит отдельно от блока терпения.
		if(!Target)
			chase_hunger = 0

		//Стан-фриз погони (легаси "if(AIproc && SStun ...)") переехал в гейт
		//исполнения /datum/ai_planning_subtree/slime_pursuit: стоим, цель не бросаем

		var/hungry = get_hunger_drive() // determines if the slime is hungry

		if(hungry == 2 && !client) // if a slime is starving, it starts losing its friends
			if(Friends.len > 0 && prob(1))
				var/mob/living/nofriend = pick(Friends)
				--Friends[nofriend]
				// Отбор добычи проверяет ЧЛЕНСТВО в Friends, а не величину дружбы, поэтому
				// уронить счётчик мало: дружок остаётся ключом списка и несъедобен навсегда,
				// то есть весь механизм "голодный слайм теряет друзей" не работал. Хуже того,
				// Reproduce() копирует список всем четырём детям - испорченный список тянется
				// по всей линии, и выглядит это как "вот эти слаймы почему-то не едят".
				if(Friends[nofriend] <= 0)
					clear_friend(nofriend)

		if(!Target)
			if(world.time >= next_hunt_scan && (will_hunt() && hungry || attacked || rabid)) // Only add to the list if we need to
				var/list/targets = list()

				// Lever 3: AI_TARGETS grid channel instead of view(7) - a per-cell
				// index of live mobs, no viewport build (~2x cheaper here) and an
				// empty pen, which is the common case, costs nothing at all.
				// get_dist clamps the grid's whole-cell over-return.
				// До инициализации грида слаймы всё равно не живут (SSmobs заводится
				// на RUNLEVEL_GAME), так что фолбэка на view() здесь нет.
				var/list/scan_candidates = SSspatial_grid.initialized ? SSspatial_grid.orthogonal_range_search(src, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, SLIME_AI_PURSUIT_RANGE) : list()
				for(var/mob/living/L as anything in scan_candidates)

					// хардделнутые мобы оставляют в ячейках грида null, а as anything
					// его не фильтрует: L.stat падал бы на каждой такой записи
					if(QDELETED(L))
						continue

					if(isslime(L) || L.stat == DEAD) // grid excludes DEAD; src is a slime so this also skips self
						continue

					// Погоня бросает выеденную добычу тем же тиком (slime_controller.dm,
					// правило give_up по SLIME_AI_TARGET_SPENT_HEALTH), а отбор её берёт -
					// и берёт ПЕРВОЙ попавшейся, с break. Мартышка живёт до -100, так что
					// полоса от -70 до -100 вечная: одна недоеденная тушка в загоне
					// навсегда закрывала слаймам доступ к здоровым соседкам, а ветка
					// блуждания (она под if(!Target)) при занятой цели не отрабатывала.
					if(L.health <= SLIME_AI_TARGET_SPENT_HEALTH)
						continue

					if(get_dist(src, L) > SLIME_AI_PURSUIT_RANGE) // grid returns whole cells - clamp to the real scan range
						continue

					if(L in Friends) // No eating friends!
						continue

					var/ally = FALSE
					for(var/F in faction)
						if(F == "neutral") //slimes are neutral so other mobs not target them, but they can target neutral mobs
							continue
						if(F in L.faction)
							ally = TRUE
							break
					if(ally)
						continue

					//Грид не знает о стенах, а погоня знает: слайм бросает всё, чего нет
					//в его view() (см. /datum/ai_behavior/slime_pursue_and_feed). Без этого
					//гейта слайм в ксенобио брал целью мартышку за стеклом соседнего загона,
					//тут же её бросал и на следующем тике брал снова - до добычи в своём
					//загоне очередь не доходила. Луч стоит ПОСЛЕ дешёвых отсевов: соседи по
					//загону - сами слаймы, а они отпадают первой же строкой цикла.
					if(!can_see(src, L, SLIME_AI_PURSUIT_RANGE))
						continue

					if(issilicon(L) && (rabid || attacked)) // They can't eat silicons, but they can glomp them in defence
						targets += L // Possible target found!

					if(ishuman(L)) //Ignore slime(wo)men
						var/mob/living/carbon/human/H = L
						if(src.type in H.dna.species.ignored_by)
							continue

					if(locate(/mob/living/simple_animal/slime) in L.buckled_mobs) // Only one slime can latch on at a time.
						continue

					targets += L // Possible target found!

				if(!targets.len) // Empty pen: don't burn a full view() scan every Life tick, prey rarely appears
					next_hunt_scan = world.time + SLIME_HUNT_SCAN_COOLDOWN

				if(targets.len > 0)
					if(attacked || rabid || hungry == 2)
						Target = targets[1] // I am attacked and am fighting back or so hungry I don't even care
					else
						for(var/mob/living/carbon/C in targets)
							if(!Discipline && prob(5))
								if(ishuman(C) || isalienadult(C))
									Target = C
									break

							if(islarva(C) || ismonkey(C))
								Target = C
								break

			if (Target)
				target_patience = rand(5,7)
				if (is_adult)
					target_patience += 3

		if(!Target) // If we have no target, we are wandering or following orders
			if (Leader)
				if(holding_still)
					holding_still = max(holding_still - 1, 0)
				else if(CHECK_MOBILITY(src, MOBILITY_MOVE) && isturf(loc))
					step_to(src, Leader)

			else if(hungry)
				if (holding_still)
					holding_still = max(holding_still - hungry, 0)
				else if(can_wander_now() && CHECK_MOBILITY(src, MOBILITY_MOVE) && isturf(loc) && prob(50))
					note_wander()
					step(src, pick(GLOB.cardinals))

			else
				if(holding_still)
					holding_still = max(holding_still - 1, 0)
				else if (docile && pulledby)
					holding_still = 10
				else if(can_wander_now() && CHECK_MOBILITY(src, MOBILITY_MOVE) && isturf(loc) && prob(33))
					note_wander()
					step(src, pick(GLOB.cardinals))
		else
			slime_wake_pursuit()

/mob/living/simple_animal/slime/handle_automated_movement()
	return //slime random movement is currently handled in handle_targets()

/mob/living/simple_animal/slime/handle_automated_speech()
	return //slime random speech is currently handled in handle_speech()

/mob/living/simple_animal/slime/proc/handle_mood()
	var/newmood = ""
	if (rabid || attacked)
		newmood = "angry"
	else if (docile)
		newmood = ":3"
	else if (Target)
		newmood = "mischievous"

	if (!newmood)
		if (Discipline && prob(25))
			newmood = "pout"
		else if (prob(1))
			newmood = pick("sad", ":3", "pout")

	if ((mood == "sad" || mood == ":3" || mood == "pout") && !newmood)
		if(prob(75))
			newmood = mood

	if (newmood != mood) // This is so we don't redraw them every time
		mood = newmood
		regenerate_icons()

/mob/living/simple_animal/slime/proc/handle_speech()
	//Speech understanding starts here
	var/to_say
	if (speech_buffer.len > 0)
		var/who = speech_buffer[1] // Who said it?
		var/phrase = speech_buffer[2] // What did they say?
		if ((findtext(phrase, num2text(number)) || findtext(phrase, "slimes"))) // Talking to us
			if (findtext(phrase, "hello") || findtext(phrase, "hi"))
				to_say = pick("Hello...", "Hi...")
			else if (findtext(phrase, "follow"))
				if (Leader)
					if (Leader == who) // Already following him
						to_say = pick("Yes...", "Lead...", "Follow...")
					else if (Friends[who] > Friends[Leader]) // VIVA
						Leader = who
						to_say = "Yes... I follow [who]..."
					else
						to_say = "No... I follow [Leader]..."
				else
					if (Friends[who] >= SLIME_FRIENDSHIP_FOLLOW)
						Leader = who
						to_say = "I follow..."
					else // Not friendly enough
						to_say = pick("No...", "I no follow...")
			else if (findtext(phrase, "stop"))
				if (buckled) // We are asked to stop feeding
					if (Friends[who] >= SLIME_FRIENDSHIP_STOPEAT)
						Feedstop()
						Target = null
						if (Friends[who] < SLIME_FRIENDSHIP_STOPEAT_NOANGRY)
							--Friends[who]
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (Target) // We are asked to stop chasing
					if (Friends[who] >= SLIME_FRIENDSHIP_STOPCHASE)
						Target = null
						if (Friends[who] < SLIME_FRIENDSHIP_STOPCHASE_NOANGRY)
							--Friends[who]
							to_say = "Grrr..." // I'm angry but I do it
						else
							to_say = "Fine..."
				else if (Leader) // We are asked to stop following
					if (Leader == who)
						to_say = "Yes... I stay..."
						Leader = null
					else
						if (Friends[who] > Friends[Leader])
							Leader = null
							to_say = "Yes... I stop..."
						else
							to_say = "No... keep follow..."
			else if (findtext(phrase, "stay"))
				if (Leader)
					if (Leader == who)
						holding_still = Friends[who] * 10
						to_say = "Yes... stay..."
					else if (Friends[who] > Friends[Leader])
						holding_still = (Friends[who] - Friends[Leader]) * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... keep follow..."
				else
					if (Friends[who] >= SLIME_FRIENDSHIP_STAY)
						holding_still = Friends[who] * 10
						to_say = "Yes... stay..."
					else
						to_say = "No... won't stay..."
			else if (findtext(phrase, "attack"))
				if (rabid && prob(20))
					Target = who
					slime_wake_pursuit() //Wake up the slime's Target AI, needed otherwise this doesn't work
					to_say = "ATTACK!?!?"
				else if (Friends[who] >= SLIME_FRIENDSHIP_ATTACK)
					for (var/mob/living/L in view(7,src)-list(src,who))
						if (findtext(phrase, lowertext(L.name)))
							if (isslime(L))
								to_say = "NO... [L] slime friend"
								--Friends[who] //Don't ask a slime to attack its friend
							else if(!Friends[L] || Friends[L] < 1)
								Target = L
								slime_wake_pursuit()//Wake up the slime's Target AI, needed otherwise this doesn't work
								to_say = "Ok... I attack [Target]"
							else
								to_say = "No... like [L] ..."
								--Friends[who] //Don't ask a slime to attack its friend
							break
				else
					to_say = "No... no listen"

		speech_buffer = list()

	//Speech starts here
	if (to_say)
		say (to_say)
	else if(prob(1))
		emote(pick("bounce","sway","light","vibrate","jiggle"))
	else
		if (!prob(2)) // roll the rare-chatter die before the view() scan: its results only feed the phrase list below
			return
		var/t = 10
		var/slimes_near = 0
		var/dead_slimes = 0
		var/friends_near = list()
		for (var/mob/living/L in view(7,src))
			if(isslime(L) && L != src)
				++slimes_near
				if (L.stat == DEAD)
					++dead_slimes
			if (L in Friends)
				t += 20
				friends_near += L
		if (nutrition < get_hunger_nutrition())
			t += 10
		if (nutrition < get_starve_nutrition())
			t += 10
		if (prob(t))
			var/phrases = list()
			if (Target)
				phrases += "[Target]... look yummy..."
			if (nutrition < get_starve_nutrition())
				phrases += "So... hungry..."
				phrases += "Very... hungry..."
				phrases += "Need... food..."
				phrases += "Must... eat..."
			else if (nutrition < get_hunger_nutrition())
				phrases += "Hungry..."
				phrases += "Where food?"
				phrases += "I want to eat..."
			phrases += "Rawr..."
			phrases += "Blop..."
			phrases += "Blorble..."
			if (rabid || attacked)
				phrases += "Hrr..."
				phrases += "Nhuu..."
				phrases += "Unn..."
			if (mood == ":3")
				phrases += "Purr..."
			if (attacked)
				phrases += "Grrr..."
			if (bodytemperature < T0C)
				phrases += "Cold..."
			if (bodytemperature < T0C - 30)
				phrases += "So... cold..."
				phrases += "Very... cold..."
			if (bodytemperature < T0C - 50)
				phrases += "..."
				phrases += "C... c..."
			if (buckled)
				phrases += "Nom..."
				phrases += "Yummy..."
			if (powerlevel > 3)
				phrases += "Bzzz..."
			if (powerlevel > 5)
				phrases += "Zap..."
			if (powerlevel > 8)
				phrases += "Zap... Bzz..."
			if (mood == "sad")
				phrases += "Bored..."
			if (slimes_near)
				phrases += "Slime friend..."
			if (slimes_near > 1)
				phrases += "Slime friends..."
			if (dead_slimes)
				phrases += "What happened?"
			if (!slimes_near)
				phrases += "Lonely..."
			for (var/M in friends_near)
				phrases += "[M]... friend..."
				if (nutrition < get_hunger_nutrition())
					phrases += "[M]... feed me..."
			if(!stat)
				say (pick(phrases))

/mob/living/simple_animal/slime/proc/get_max_nutrition() // Can't go above it
	if (is_adult)
		return 1200
	else
		return 1000

/mob/living/simple_animal/slime/proc/get_grow_nutrition() // Above it we grow, below it we can eat
	if (is_adult)
		return 1000
	else
		return 800

/mob/living/simple_animal/slime/proc/get_hunger_nutrition() // Below it we will always eat
	if (is_adult)
		return 600
	else
		return 500

/mob/living/simple_animal/slime/proc/get_starve_nutrition() // Below it we will eat before everything else
	if(is_adult)
		return 300
	else
		return 200

///Оценка голода на всю погоню: снимается ОДИН раз и держится до конца погони.
///
///Легаси-AIprocess() брал `hungry` локальной переменной при входе в цикл и жил с
///ней до самого конца преследования. get_hunger_drive() в среднем диапазоне
///сытости возвращает 1 лишь с шансом 25%, поэтому пересъём оценки на каждом
///проходе планировщика (два раза в секунду) рвал погоню в 75% случаев: сабтри
///не планировал, SelectBehaviors снимал уже идущее поведение как "забытое", а
///SSai_controllers гасил контроллер на AI_FAILED_PLANNING_COOLDOWN. Слайм с
///ксенобио-фермы, которого регулярно кормят, сидит ровно в этом диапазоне и до
///добычи так не доходил - пока nutrition за десятки минут не проседал ниже
///get_hunger_nutrition(), где оценка становится детерминированной.
///
///Ноль означает "оценки ещё нет": следующий проход возьмёт свежую. Обнуляется в
///handle_targets(), как только слайм остаётся без цели.
/mob/living/simple_animal/slime/proc/latch_chase_hunger()
	if(!chase_hunger)
		chase_hunger = get_hunger_drive()
	return chase_hunger

///Легаси-оценка голода (общая для handle_targets и драйва погони контроллера):
///2 - голодает и ест всё подряд, 1 - проголодался (средний диапазон с шансом 25%), 0 - сыт
/mob/living/simple_animal/slime/proc/get_hunger_drive()
	if(nutrition < get_starve_nutrition())
		return 2
	if((nutrition < get_grow_nutrition() && prob(25)) || nutrition < get_hunger_nutrition())
		return 1
	return 0

/mob/living/simple_animal/slime/proc/will_hunt(hunger = -1) // Check for being stopped from feeding and chasing
	if (docile)
		return FALSE
	if (hunger == 2 || rabid || attacked)
		return TRUE
	if (Leader)
		return FALSE
	if (holding_still)
		return FALSE
	return TRUE

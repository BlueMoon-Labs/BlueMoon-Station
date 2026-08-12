/mob/living/simple_animal/hostile
	faction = list("hostile")
	stop_automated_movement_when_pulled = 0
	obj_damage = 40
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES //Bitflags. Set to ENVIRONMENT_SMASH_STRUCTURES to break closets,tables,racks, etc; ENVIRONMENT_SMASH_WALLS for walls; ENVIRONMENT_SMASH_RWALLS for rwalls
	var/atom/target
	var/ranged = FALSE
	var/rapid = 0 //How many shots per volley.
	var/rapid_fire_delay = 2 //Time between rapid fire shots
	/// A rapid volley owns at most one outstanding timer and one target ref.
	var/rapid_fire_timer_id
	var/rapid_fire_shots_left = 0
	var/atom/rapid_fire_target

	var/dodging = FALSE
	var/in_melee = FALSE	//We should sidestep now
	var/dodge_prob = 30

	var/projectiletype	//set ONLY it and NULLIFY casingtype var, if we have ONLY projectile
	var/projectilesound
	var/casingtype		//set ONLY it and NULLIFY projectiletype, if we have projectile IN CASING
	var/move_to_delay = 3 //delay for the automated movement.
	///Пол скорости AI-погони (AI_PURSUIT_MIN_MOVE_DELAY) применяется, пока TRUE.
	///Боссы (megafauna) ставят FALSE - их высокая скорость намеренная.
	var/ai_pursuit_speed_capped = TRUE
	var/list/friends = list()
	var/list/foes = list()
	///Может ли моб в принципе завести личную обиду на СВОЮ фракцию. Ботам и
	///питомцам ставится FALSE: их владелец не должен становиться целью никогда.
	var/retaliates_against_faction = TRUE
	///Счёт дружественного урона: REF(обидчик) -> list(накоплено, world.time).
	///Ключ строковый намеренно - список не держит ссылок на мобов и не создаёт
	///кандидатов на харддел.
	var/list/friendly_fire_tally
	///Троттл группового оповещения союзников об обидчике (см. RetaliateAgainst)
	var/next_ally_alert = 0
	var/list/emote_taunt = list()
	var/taunt_chance = 0

	var/rapid_melee = 1			 //Number of melee attacks between each npc pool tick. Spread evenly.
	///Профильный темп мили контроллерного AI: доля от легаси-каденса NPC-пула.
	///Сабтип/профиль может замедлить тяжёлого (телеграф) или ускорить роя.
	var/ai_melee_cadence_scale = AI_MELEE_CADENCE_SCALE
	/// Legacy rapid-melee is a chained burst with at most one outstanding timer.
	/// Controller AI uses its behavior cooldown instead and never creates these timers.
	var/rapid_melee_timer_id
	var/rapid_melee_attacks_left = 0

	var/ranged_message = "fires" //Fluff text for ranged mobs
	var/ranged_cooldown = 0 //What the current cooldown on ranged attacks is, generally world.time + ranged_cooldown_time
	var/ranged_cooldown_time = 30 //How long, in deciseconds, the cooldown of ranged attacks is
	var/ranged_ignores_vision = FALSE //if it'll fire ranged attacks even if it lacks vision on its target, only works with environment smash
	var/check_friendly_fire = 0 // Should the ranged mob check for friendlies when shooting
	var/retreat_distance = null //If our mob runs from players when they're too close, set in tile distance. By default, mobs do not retreat.
	var/minimum_distance = 1 //Minimum approach distance, so ranged mobs chase targets down, but still keep their distance set in tiles to the target, set higher to make mobs keep distance


//These vars are related to how mobs locate and target
	var/robust_searching = 0 //By default, mobs have a simple searching method, set this to 1 for the more scrutinous searching (stat_attack, stat_exclusive, etc), should be disabled on most mobs
	var/vision_range = 9 //How big of an area to search for targets in, a vision of 9 attempts to find targets as soon as they walk into screen view
	var/aggro_vision_range = 9 //If a mob is aggro, we search in this radius. Defaults to 9 to keep in line with original simple mob aggro radius
	var/search_objects = 0 //If we want to consider objects when searching around, set this to 1. If you want to search for objects while also ignoring mobs until hurt, set it to 2. To completely ignore mobs, even when attacked, set it to 3
	var/search_objects_timer_id //Timer for regaining our old search_objects value after being attacked
	var/search_objects_regain_time = 30 //the delay between being attacked and gaining our old search_objects value back
	var/list/wanted_objects = list() //A typecache of objects types that will be checked against to attack, should we have search_objects enabled
	var/stat_attack = CONSCIOUS //Mobs with stat_attack to UNCONSCIOUS will attempt to attack things that are unconscious, Mobs with stat_attack set to DEAD will attempt to attack the dead.
	var/stat_exclusive = FALSE //Mobs with this set to TRUE will exclusively attack things defined by stat_attack, stat_attack DEAD means they will only attack corpses
	var/attack_same = 0 //Set us to 1 to allow us to attack our own faction
	var/atom/targets_from = null //all range/attack/etc. calculations should be done from this atom, defaults to the mob itself, useful for Vehicles and such
	var/attack_all_objects = FALSE //if true, equivalent to having a wanted_objects list containing ALL objects.

	var/lose_patience_timer_id //id for a timer to call LoseTarget(), used to stop mobs fixating on a target they can't reach
	var/lose_patience_timeout = 1200 //120 seconds by default, so there's no major changes to AI behaviour, beyond actually bailing if stuck forever
	/// Repeated hits/attacks refresh patience, but recreating the same long timer
	/// dozens of times per tick only churns SStimer buckets.
	var/next_patience_timer_refresh = 0

	///When a target is found, will the mob attempt to charge at it's target?
	var/charger = FALSE
	///Таймер прелюдии чарджа: пока взведён, повторный enter_charge запрещён
	var/charge_windup_timer
	///Tracks if the target is actively charging.
	var/charge_state = FALSE
	///In a charge, how many tiles will the charger travel?
	var/charge_distance = 3
	///How often can the charging mob actually charge? Effects the cooldown between charges.
	var/charge_frequency = 6 SECONDS
	///If the mob is charging, how long will it stun it's target on success, and itself on failure?
	var/knockdown_time = 3 SECONDS
	///Declares a cooldown for potential charges right off the bat.
	COOLDOWN_DECLARE(charge_cooldown)
	var/list/enemies = list()

	///Профиль AI-контроллера (оверхол): типпас адаптера либо null для
	///задокументированных AI_OFF-исключений (см. hostile_adapter/permanent_exceptions.dm).
	///Сабтипы ставят свой профиль явно; база выбирает по флагам в select_ai_profile()
	var/ai_profile_type = /datum/ai_controller/hostile_adapter/melee_chaser
	///Пауза перед мили-ударом AI; 0 сохраняет мгновенную легаси-атаку.
	var/melee_telegraph_duration = 0
	///Пауза перед ЗАЛПОМ дальника; 0 сохраняет мгновенный легаси-выстрел.
	///Ставится тем, чей залп способен убить с одного захода: точность нового ИИ
	///сделала такие залпы неотвратимыми, и урон в них никто не пересматривал.
	var/ranged_telegraph_duration = 0
	///At most one ranged telegraph may be waiting to fire.
	var/ranged_telegraph_timer_id

/mob/living/simple_animal/hostile/Initialize(mapload)
	. = ..()

	if(!targets_from)
		targets_from = src
	wanted_objects = typecacheof(wanted_objects)

	var/chosen_profile = select_ai_profile()
	//Явно выключенные типы (AI_OFF на типе) - игровые оболочки и постоянные
	//исключения: контроллер им не положен, см. MIGRATION_EXCEPTIONS.md.
	if(chosen_profile && AIStatus != AI_OFF)
		new chosen_profile(src) //PossessPawn сам вынимает моба из легаси-бакетов
	if(melee_telegraph_duration > 0)
		AddComponent(/datum/component/hostile_attack_telegraph, melee_telegraph_duration)

///Авто-подбор профиля по легаси-флагам; явный сабтиповый ai_profile_type важнее
/mob/living/simple_animal/hostile/proc/select_ai_profile()
	if(isnull(ai_profile_type))
		return null //задокументированное AI_OFF-исключение: контроллер не создаётся
	if(ai_profile_type != /datum/ai_controller/hostile_adapter/melee_chaser)
		return ai_profile_type //сабтип выбрал профиль сам
	if(charger)
		return /datum/ai_controller/hostile_adapter/brute_charger
	if(ranged)
		if(isnull(retreat_distance))
			return /datum/ai_controller/hostile_adapter/ranged_chaser
		return /datum/ai_controller/hostile_adapter/ranged_skirmisher
	return ai_profile_type


/mob/living/simple_animal/hostile/Destroy()
	deltimer(lose_patience_timer_id)
	deltimer(search_objects_timer_id)
	deltimer(charge_windup_timer)
	charge_windup_timer = null
	deltimer(ranged_telegraph_timer_id)
	ranged_telegraph_timer_id = null
	cancel_rapid_melee_sequence()
	cancel_rapid_fire_sequence()
	targets_from = null
	target = null
	friends = null
	for(var/atom/movable/the_foe in foes)
		UnregisterSignal(the_foe, COMSIG_PARENT_QDELETING)
		untrack_enemy_mind(the_foe)
	foes = null
	for(var/atom/movable/the_enemy in enemies)
		UnregisterSignal(the_enemy, COMSIG_PARENT_QDELETING)
		untrack_enemy_mind(the_enemy)
	enemies = null
	return ..()

/mob/living/simple_animal/hostile/proc/add_enemy(atom/movable/the_enemy)
	if(the_enemy in enemies)
		return
	enemies += the_enemy
	track_enemy_lifecycle(the_enemy)
	//новая обида перепроверяет даже OFF-контроллер: OFF мог остаться от пустого z-level
	if(ai_controller && ai_controller.ai_status != AI_STATUS_ON)
		ai_controller.set_ai_status(ai_controller.get_expected_ai_status())

/// Add a batch of grudges without paying one proc/list-membership check for
/// every enemy shared between every member of a hostile group.
/mob/living/simple_animal/hostile/proc/add_enemies(list/candidates)
	if(!length(candidates))
		return
	var/list/new_enemies = candidates - enemies
	if(!length(new_enemies))
		return
	var/list/invalid_enemies
	for(var/atom/movable/new_enemy as anything in new_enemies)
		if(QDELETED(new_enemy))
			LAZYADD(invalid_enemies, new_enemy)
			continue
		track_enemy_lifecycle(new_enemy)
	if(length(invalid_enemies))
		new_enemies -= invalid_enemies
	if(!length(new_enemies))
		return
	enemies |= new_enemies
	if(ai_controller && ai_controller.ai_status != AI_STATUS_ON)
		ai_controller.set_ai_status(ai_controller.get_expected_ai_status())
	return new_enemies

/mob/living/simple_animal/hostile/proc/remove_enemy(atom/movable/the_enemy)
	enemies -= the_enemy
	//сигнал держим, пока цель числится хотя бы в одном списке обид:
	//foes живёт дольше enemies (тот чистится по stat в Found)
	if(foes && foes[the_enemy])
		return
	UnregisterSignal(the_enemy, COMSIG_PARENT_QDELETING)
	untrack_enemy_mind(the_enemy)

///Track both the body lifetime and player-mind transfers for a personal enemy.
/mob/living/simple_animal/hostile/proc/track_enemy_lifecycle(atom/movable/the_enemy)
	RegisterSignal(the_enemy, COMSIG_PARENT_QDELETING, PROC_REF(on_enemy_qdeleting), override = TRUE)
	var/mob/enemy_mob = the_enemy
	if(istype(enemy_mob) && enemy_mob.mind)
		RegisterSignal(enemy_mob.mind, COMSIG_MIND_TRANSFER, PROC_REF(on_enemy_mind_transfer), override = TRUE)

/mob/living/simple_animal/hostile/proc/untrack_enemy_mind(atom/movable/the_enemy)
	var/mob/enemy_mob = the_enemy
	if(istype(enemy_mob) && enemy_mob.mind)
		UnregisterSignal(enemy_mob.mind, COMSIG_MIND_TRANSFER)

/mob/living/simple_animal/hostile/proc/on_enemy_qdeleting(datum/source)
	SIGNAL_HANDLER
	untrack_enemy_mind(source)
	enemies -= source
	if(foes)
		foes -= source

///Admin respawn, cloning and body swaps keep the same player mind but create a
///new mob datum. Move personal aggro to that body instead of leaving a boss
///permanently focused on the old corpse.
/mob/living/simple_animal/hostile/proc/on_enemy_mind_transfer(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	var/was_enemy = (old_character in enemies)
	var/was_foe = foes && foes[old_character]
	if(!was_enemy && !was_foe)
		UnregisterSignal(source, COMSIG_MIND_TRANSFER)
		return

	var/was_current_target = target == old_character || (ai_controller && ai_controller.blackboard[BB_AI_CURRENT_TARGET] == old_character)
	UnregisterSignal(old_character, COMSIG_PARENT_QDELETING)
	UnregisterSignal(source, COMSIG_MIND_TRANSFER)
	enemies -= old_character
	if(foes)
		foes -= old_character

	if(QDELETED(new_character))
		if(was_current_target)
			LoseTarget()
		return
	if(was_enemy)
		enemies += new_character
	if(was_foe)
		foes[new_character] = 1
	track_enemy_lifecycle(new_character)
	if(was_current_target && CanAttack(new_character))
		GiveTarget(new_character)

/// Clears remembered targets and grudges without changing the mob's faction behavior.
/mob/living/simple_animal/hostile/proc/clear_hostile_aggro()
	LoseTarget()
	for(var/atom/movable/old_target as anything in (foes | enemies))
		UnregisterSignal(old_target, COMSIG_PARENT_QDELETING)
		untrack_enemy_mind(old_target)
	friends.Cut()
	foes.Cut()
	enemies.Cut()

/mob/living/simple_animal/hostile/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		walk(src, 0) //stops walking
		return

/mob/living/simple_animal/hostile/proc/sidestep()
	if(!target || !isturf(target.loc) || !isturf(loc) || stat == DEAD)
		return
	var/target_dir = get_dir(src,target)

	var/static/list/cardinal_sidestep_directions = list(-90,-45,0,45,90)
	var/static/list/diagonal_sidestep_directions = list(-45,0,45)
	var/chosen_dir = 0
	if (target_dir & (target_dir - 1))
		chosen_dir = pick(diagonal_sidestep_directions)
	else
		chosen_dir = pick(cardinal_sidestep_directions)
	if(chosen_dir)
		chosen_dir = turn(target_dir,chosen_dir)
		var/turf/destination = get_step(src, chosen_dir)
		//Через контроллер, а не голым Move(): уворот обязан стоить обычный шаг
		//и ехать с glide, иначе он читается телепортом и даёт лишний тайл.
		if(ai_controller)
			ai_controller.ai_step_outside_loop(destination)
		else
			Move(destination, chosen_dir)
		face_atom(target) //Looks better if they keep looking at you when dodging

/mob/living/simple_animal/hostile/attacked_by(obj/item/I, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	//Урон считаем по факту (после брони и модификаторов), поэтому решение об
	//обиде принимается ПОСЛЕ удара, а не до него: обида на сокомандника по
	//фракции обнуляет проверку фракции в CanAttack, и цена ошибки тут - бот,
	//расстреливающий владельца из-за тычка сумкой.
	var/consider_grudge = (stat == CONSCIOUS && user && has_active_ai() && !client)
	var/health_before = health
	. = ..()
	//Удар мог оказаться смертельным. Мёртвому обида уже не нужна, но его стае -
	//нужна: RetaliateAgainst докладывает союзникам о контакте, и до переноса
	//вызова за ..() убийство с одного удара всё равно поднимало стаю - молчаливый
	//отстрел группы по одному без единой реакции был регрессом. У уничтоженного
	//(del_on_death) списки сняты - этот случай отсекает гард в RetaliateAgainst.
	if(consider_grudge && !QDELETED(src))
		consider_retaliation(user, max(0, health_before - health))

///Заводить ли личную обиду на этого обидчика. Чужак становится врагом с первого
///касания; сокомандник по фракции получает допуск на случайность - порог по
///НАКОПЛЕННОМУ урону, а не по числу ударов (три щекотки не равны трём ударам
///кувалдой). Возвращает TRUE, если обида заведена.
/mob/living/simple_animal/hostile/proc/consider_retaliation(mob/living/attacker, damage_taken = 0)
	if(QDELETED(attacker))
		return FALSE
	if(!is_faction_accident(attacker))
		RetaliateAgainst(attacker)
		return TRUE
	if(!retaliates_against_faction)
		return FALSE
	if(!tally_friendly_fire(attacker, damage_taken))
		//подпороговый, но реальный урон: обиды ещё нет, а проснуться, запомнить
		//обидчика и учитывать его в оценке опасности моб обязан уже сейчас -
		//иначе размеренные удары убивали его спящим без единой реакции
		if(damage_taken > 0)
			ai_controller?.note_attacker(attacker)
		return FALSE
	RetaliateAgainst(attacker)
	return TRUE

///Свой ли это по фракции, то есть применима ли толерантность к случайности.
///Уже записанный враг своим не считается - обида приоритетнее фракции.
/mob/living/simple_animal/hostile/proc/is_faction_accident(mob/living/attacker)
	if(!isliving(attacker) || attack_same)
		return FALSE
	if(foes && foes[attacker])
		return FALSE
	return faction_check_mob(attacker)

///Накопить дружественный урон; TRUE - порог превышен. Счёт НЕ протухает по
///времени: окно прощения обнуляло его тому, кто бьёт размеренно, и моба можно
///было убить бесплатно, выдерживая паузу между ударами.
/mob/living/simple_animal/hostile/proc/tally_friendly_fire(mob/living/attacker, damage_taken)
	if(damage_taken <= 0 || maxHealth <= 0)
		return FALSE
	LAZYINITLIST(friendly_fire_tally)
	prune_friendly_fire_tally()
	var/attacker_key = REF(attacker)
	var/list/entry = friendly_fire_tally[attacker_key]
	if(!entry)
		entry = list(0, world.time)
		friendly_fire_tally[attacker_key] = entry
	entry[1] += damage_taken
	entry[2] = world.time
	return entry[1] >= (maxHealth * AI_FRIENDLY_FIRE_TOLERANCE)

///Выкинуть при переполнении старейшую запись счёта: потолок держит список
///конечным под очередью из обидчиков
/mob/living/simple_animal/hostile/proc/prune_friendly_fire_tally()
	if(length(friendly_fire_tally) < AI_FRIENDLY_FIRE_TALLY_MAX)
		return
	var/oldest_key
	var/oldest_time = INFINITY
	for(var/attacker_key in friendly_fire_tally)
		var/list/entry = friendly_fire_tally[attacker_key]
		if(entry[2] < oldest_time)
			oldest_time = entry[2]
			oldest_key = attacker_key
	if(oldest_key)
		friendly_fire_tally -= oldest_key

/mob/living/simple_animal/hostile/bullet_act(obj/item/projectile/P)
	if(stat == CONSCIOUS && has_active_ai() && !client && P.firer)
		//Что именно в нас прилетело - вход в модель угрозы: от этого зависит,
		//считать ли стекло и решётку укрытием (см. threat_model.dm). Пишем и для
		//дружественного огня: знать тип снаряда полезно независимо от обиды.
		ai_controller?.note_incoming_projectile(P.firer, P)
		if(get_dist(src, P.firer) <= aggro_vision_range)
			//A stray allied projectile must not turn an entire squad against itself.
			//Direct melee attacks still use RetaliateAgainst() and preserve grudges.
			var/friendly_fire = isliving(P.firer) && faction_check_mob(P.firer) && !attack_same && (!foes || !foes[P.firer])
			if(!friendly_fire)
				RetaliateAgainst(P.firer)
	return ..()

/// Focus aggro on whoever just hurt us, even if we already had another target.
/mob/living/simple_animal/hostile/proc/RetaliateAgainst(atom/movable/the_attacker)
	if(!the_attacker || QDELETED(the_attacker))
		return
	//Destroy() снимает списки обид: у уничтожаемого моба foes уже null, и запись
	//в него это "bad index". Обида такому мобу всё равно не нужна.
	if(QDELETED(src) || isnull(foes))
		return
	if(isliving(the_attacker))
		add_enemy(the_attacker)
		foes[the_attacker] = 1
	//Обида будит AI и немедленно перебивает текущую цель: иначе валидная
	//старая цель блокирует перевыбор. Мобы без контроллера - AI_OFF-исключения,
	//им боевой перевыбор не нужен, достаточно учёта обиды выше.
	if(ai_controller)
		ai_controller.note_attacker(the_attacker)
		if(CanAttack(the_attacker))
			//обида ставит цель МИМО финдера, а точку отсчёта поводка погони ставит
			//только финдер: без неё погоня стартует с origin прошлой погони и
			//should_abandon_pursuit бросает её первым же планом. Ставим сами, но
			//только при СМЕНЕ цели - каждый удар текущей цели не должен обнулять
			//пройденный поводок, иначе дерущаяся цель отключает усталость погони.
			if(ai_controller.blackboard[BB_AI_CURRENT_TARGET] != the_attacker)
				ai_controller.blackboard[BB_AI_PURSUIT_ORIGIN] = get_turf(src)
				AI_TRACE(ai_controller, "target", "возмездие: цель [the_attacker]")
			ai_controller.set_blackboard_key(BB_AI_CURRENT_TARGET, the_attacker)
			//Групповой агр: retaliate-семейство делится обидчиками через свой
			//Retaliate(), а обычные отряды (лутеры, синдикат, фауна) без этого
			//стояли и смотрели, как их сокомандника расстреливают. Aggro() выше
			//уже поднял vision_range до боевого - им и ограничиваем круг оповещения.
			//Союзники получают ТОЧКУ и приметы (combat contact), не сам атом:
			//захватят цель только собственным восприятием.
			if(!istype(src, /mob/living/simple_animal/hostile/retaliate) && world.time >= next_ally_alert)
				next_ally_alert = world.time + AI_ALLY_ALERT_COOLDOWN
				//AoE по стае: N раненых в одной ячейке = один грид-скан, не N
				var/turf/victim_turf = get_turf(src)
				if(victim_turf)
					var/alert_key = "[REF(the_attacker)]:[victim_turf.x >> 3]:[victim_turf.y >> 3]:[victim_turf.z]:[faction.Join(",")]"
					if(world.time - (GLOB.ai_recent_herd_alerts[alert_key] || -INFINITY) >= AI_ALLY_ALERT_COALESCE_WINDOW)
						if(length(GLOB.ai_recent_herd_alerts) > 64) //ленивая чистка
							GLOB.ai_recent_herd_alerts.Cut()
						GLOB.ai_recent_herd_alerts[alert_key] = world.time
						ai_controller.report_contact_to_allies(the_attacker, vision_range)

//////////////HOSTILE MOB TARGETTING AND AGGRESSION////////////

///Живой список угроз в радиусе зрения для фазовой логики (мех-пилот, бумажный
///визард): видимые мобы + реестр враждебных машин, фильтр CanAttack.
/mob/living/simple_animal/hostile/proc/PossibleThreats()
	. = list()
	// Грид AI_TARGETS + can_see() вместо hearers(): живые кандидаты из ближних
	// ячеек, LOS-гейт сохраняет прежнюю границу видимости без нативного скана.
	for(var/mob/living/candidate as anything in SSspatial_grid.orthogonal_range_search(targets_from, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, vision_range))
		if(candidate == src || QDELETED(candidate) || get_dist(targets_from, candidate) > vision_range)
			continue
		//пилот в закрытой технике - не отдельная угроза: его представляет сам
		//мех из реестра машин ниже (паритет с гейтом candidate_passes финдера)
		if(istype(candidate.loc, /obj/vehicle/sealed))
			continue
		AI_METRIC_INC(los_checks)
		if(can_see(targets_from, candidate, vision_range) && CanAttack(candidate))
			. += candidate
	var/turf/search_origin = get_turf(targets_from)
	if(search_origin && search_origin.z <= length(GLOB.hostile_machines_by_zlevel))
		for(var/atom/hostile_machine as anything in GLOB.hostile_machines_by_zlevel[search_origin.z])
			if(get_dist(targets_from, hostile_machine) > vision_range)
				continue
			AI_METRIC_INC(los_checks)
			if(can_see(targets_from, hostile_machine, vision_range) && CanAttack(hostile_machine))
				. += hostile_machine

// Please do not add one-off mob AIs here, but override this function for your mob
/mob/living/simple_animal/hostile/CanAttack(atom/the_target)//Can we actually attack a possible target?
	if(isturf(the_target) || !the_target) // bail out on invalids
		return FALSE
	if(!src.loc || QDELETED(src)) // we're being destroyed or already removed from world
		return FALSE

	if(ismob(the_target)) //Target is in godmode, ignore it.
		var/mob/M = the_target
		if(M.status_flags & GODMODE)
			return FALSE

	if(see_invisible < the_target.invisibility)//Target's invisible to us, forget it
		return FALSE
	if(isbelly(the_target.loc)) //Target's inside a gut, forget about it too
		return FALSE
	if(search_objects < 2)
		if(isliving(the_target))
			var/mob/living/L = the_target
			var/faction_check = (!foes || !foes[L]) && faction_check_mob(L)
			if(robust_searching)
				if(faction_check && !attack_same)
					return FALSE
				if(L.stat > stat_attack || (L.stat == UNCONSCIOUS && stat_attack == UNCONSCIOUS && HAS_TRAIT(L, TRAIT_DEATHCOMA)))
					return FALSE
				if(friends && foes && friends[L] > 0 && foes[L] < 1)
					return FALSE
			else
				if((faction_check && !attack_same) || L.stat)
					return FALSE
			return TRUE

		if(ismecha(the_target))
			var/obj/vehicle/sealed/mecha/M = the_target
			for(var/occupant in M.occupants)
				if(CanAttack(occupant))
					return TRUE

		if(istype(the_target, /obj/machinery/porta_turret))
			var/obj/machinery/porta_turret/P = the_target
			if(P.in_faction(src)) //Don't attack if the turret is in the same faction
				return FALSE
			if(P.has_cover &&!P.raised) //Don't attack invincible turrets
				return FALSE
			if(P.machine_stat & BROKEN) //Or turrets that are already broken
				return FALSE
			return TRUE

		if(istype(the_target, /obj/item/electronic_assembly))
			var/obj/item/electronic_assembly/O = the_target
			if(O.combat_circuits)
				return TRUE

		if(istype(the_target, /obj/structure/destructible/clockwork/ocular_warden))
			var/obj/structure/destructible/clockwork/ocular_warden/OW = the_target
			if(OW.target != src)
				return FALSE
			return TRUE
	if(isobj(the_target))
		if(attack_all_objects || is_type_in_typecache(the_target, wanted_objects))
			return TRUE

	return FALSE

/mob/living/simple_animal/hostile/proc/GiveTarget(new_target)//Step 4, give us our selected target
	var/datum/ai_controller/hostile_adapter/adapter = ai_controller
	if(istype(adapter) && !adapter.syncing_target_to_pawn && adapter.blackboard[BB_AI_CURRENT_TARGET] != new_target)
		adapter.syncing_target_from_legacy = TRUE
		adapter.set_blackboard_key(BB_AI_CURRENT_TARGET, new_target)
		adapter.syncing_target_from_legacy = FALSE
	target = new_target
	LosePatience()
	if(target != null)
		GainPatience()
		Aggro()
		return TRUE

//What we do after closing in. Controller behaviors pace the cadence themselves:
//rapid_melee is represented by the behavior cooldown, so one action = one attack.
/mob/living/simple_animal/hostile/proc/MeleeAction(patience = TRUE)
	AttackingTarget()
	if(patience)
		GainPatience()

///Живой пол задержки шага AI-погони (дс). Пересчитывается от фактического
///RUN_DELAY при загрузке конфига и при его правке в рантайме, поэтому больше
///не может разойтись с реальной скоростью игрока (см. AI_PURSUIT_SPEED_RATIO).
GLOBAL_VAR_INIT(ai_pursuit_min_move_delay, AI_PURSUIT_MIN_MOVE_DELAY)

///Пересчитать пол скорости погони. Зовётся из ValidateAndSet конфига RUN_DELAY.
/proc/update_ai_pursuit_speed_floor()
	var/player_run_delay = CONFIG_GET(number/movedelay/run_delay)
	if(!player_run_delay)
		GLOB.ai_pursuit_min_move_delay = AI_PURSUIT_MIN_MOVE_DELAY
		return GLOB.ai_pursuit_min_move_delay
	GLOB.ai_pursuit_min_move_delay = max(world.tick_lag, player_run_delay * AI_PURSUIT_SPEED_RATIO)
	return GLOB.ai_pursuit_min_move_delay

///Задержка шага AI-погони (дс) из легаси move_to_delay. Небоссовые мобы
///клампятся снизу полом, который считается от скорости бегущего игрока: уйти по
///прямой можно, но без права на ошибку. Боссы (megafauna) от пола отписаны -
///их скорость это дизайн, а не недосмотр.
/mob/living/simple_animal/hostile/proc/ai_movement_delay()
	var/delay = AI_LEGACY_MOVE_DELAY_DS(move_to_delay)
	if(ai_pursuit_speed_capped)
		return max(delay, GLOB.ai_pursuit_min_move_delay)
	return delay

///Читаемое окно перед тяжёлым залпом. Точность нового ИИ (проверка реальной
///трассы снаряда с перестроением до чистого выстрела) сделала залпы дальников
///неотвратимыми, а урон в них остался легаси: боевой дрон снимал 82 HP тремя
///лучами за полсекунды, без единого признака, что сейчас выстрелит. Телеграф не
///трогает ни ум, ни точность - он даёт игроку окно уйти за укрытие, и если тот
///успел, залпа не будет.
/mob/living/simple_animal/hostile/proc/telegraphed_open_fire(atom/fire_target)
	if(QDELETED(fire_target) || stat == DEAD || ranged_telegraph_timer_id)
		return FALSE
	//Arm the full cooldown before the timer starts. Even a shot canceled by
	//lost sight must not let the planner stack another telegraph immediately.
	ranged_cooldown = world.time + ranged_cooldown_time + ranged_telegraph_duration
	var/turf/aim_turf = get_turf(fire_target)
	if(aim_turf)
		new /obj/effect/temp_visual/telegraphing/ranged_burst(aim_turf, ranged_telegraph_duration)
	ranged_telegraph_timer_id = addtimer(CALLBACK(src, PROC_REF(finish_telegraphed_open_fire), fire_target), ranged_telegraph_duration, TIMER_STOPPABLE)
	return TRUE

/mob/living/simple_animal/hostile/proc/finish_telegraphed_open_fire(atom/fire_target)
	ranged_telegraph_timer_id = null
	if(QDELETED(src) || QDELETED(fire_target) || stat == DEAD)
		return FALSE
	//цель успела разорвать линию - залп отменяется, в этом весь смысл окна
	if(!ranged_ignores_vision && !can_see(src, fire_target, AI_RANGED_MAX_FIRE_RANGE))
		return FALSE
	GiveTarget(fire_target)
	INVOKE_ASYNC(src, TYPE_PROC_REF(/mob/living/simple_animal/hostile, OpenFire), fire_target)
	return TRUE

/mob/living/simple_animal/hostile/proc/cancel_rapid_melee_sequence()
	if(rapid_melee_timer_id)
		deltimer(rapid_melee_timer_id)
	rapid_melee_timer_id = null
	rapid_melee_attacks_left = 0

/mob/living/simple_animal/hostile/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	//урон только будит контроллер: цель выберет скорер по обиде из note_attacker
	if(ai_controller && . > 0 && ai_controller.ai_status == AI_STATUS_IDLE)
		ai_controller.set_ai_status(AI_STATUS_ON)
	//легаси fight-or-flight: удар временно снимает object search (пчёлы, minebot и т.д.)
	if(!ckey && !stat && search_objects < 3 && . > 0 && search_objects)
		target = null
		LoseSearchObjects()


/mob/living/simple_animal/hostile/proc/AttackingTarget()
	if(QDELETED(src) || !target || QDELETED(target))
		return
	var/atom/attack_target = target
	if(SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, attack_target) & COMPONENT_HOSTILE_NO_ATTACK)
		return
	// Signal handlers may clear or qdel the current target.
	if(QDELETED(src) || QDELETED(attack_target))
		return
	in_melee = TRUE
	if(vore_active)
		if(isliving(attack_target))
			var/mob/living/L = attack_target
			if(!client && L.Adjacent(src) && (L.vore_flags & DEVOURABLE) && (L.vore_flags & MOBVORE)) // aggressive check to ensure vore attacks can be made
				if(prob(voracious_chance))
					vore_attack(src,L,src)
				else
					return L.attack_animal(src)
			else
				return L.attack_animal(src) //literally every single fucking one of these need this I guess.
		else
			return attack_target.attack_animal(src)
	else
		return attack_target.attack_animal(src)
	if(QDELETED(src) || QDELETED(attack_target))
		return
	return attack_target.attack_animal(src)

/mob/living/simple_animal/hostile/proc/Aggro()
	vision_range = aggro_vision_range
	if(target && emote_taunt.len && prob(taunt_chance))
		emote("me", EMOTE_VISIBLE, "[pick(emote_taunt)] at [target].")
		taunt_chance = max(taunt_chance-7,2)


/mob/living/simple_animal/hostile/proc/LoseAggro()
	stop_automated_movement = 0
	vision_range = initial(vision_range)
	taunt_chance = initial(taunt_chance)

/mob/living/simple_animal/hostile/proc/LoseTarget()
	LosePatience()
	cancel_rapid_melee_sequence()
	cancel_rapid_fire_sequence()
	var/datum/ai_controller/hostile_adapter/adapter = ai_controller
	if(istype(adapter) && !adapter.syncing_target_to_pawn && adapter.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		adapter.syncing_target_from_legacy = TRUE
		adapter.clear_blackboard_key(BB_AI_CURRENT_TARGET)
		adapter.syncing_target_from_legacy = FALSE
	target = null
	in_melee = FALSE
	walk(src, 0)
	LoseAggro()

//////////////END HOSTILE MOB TARGETTING AND AGGRESSION////////////

/mob/living/simple_animal/hostile/death(gibbed)
	LoseTarget()
	..(gibbed)

/mob/living/simple_animal/hostile/proc/summon_backup(distance, exact_faction_match)
	do_alert_animation(src)
	playsound(loc, 'sound/machines/chime.ogg', 50, 1, -1)
	//с контроллером зов - это pack-канал: союзникам уходит точка контакта,
	//цель они захватывают собственным восприятием
	if(ai_controller)
		var/atom/shared_target = ai_controller.blackboard[BB_AI_CURRENT_TARGET] || target
		if(shared_target)
			ai_controller.report_contact_to_allies(shared_target, distance)
		return
	var/turf/rally_point = get_turf(targets_from || src)
	if(!rally_point)
		return
	for(var/mob/living/simple_animal/hostile/M in oview(distance, targets_from))
		if(!faction_check_mob(M, TRUE))
			continue
		//союзник получает точку контакта в свою память, а не walk-приказ;
		//мобы без контроллера - AI_OFF-исключения, им зов не нужен
		if(M.ai_controller)
			var/turf/contact_turf = target ? get_turf(target) : null
			M.ai_controller.receive_combat_contact(target, contact_turf || rally_point, AI_CONTACT_ALLY)

/mob/living/simple_animal/hostile/proc/CheckFriendlyFire(atom/A)
	return CheckFriendlyFireFrom(A, targets_from || src)

///Legacy opt-in friendly-fire check. Use the projectile-aligned trace so a
///diagonal lane and its real cardinal split inspect the same allied turfs.
/mob/living/simple_animal/hostile/proc/CheckFriendlyFireFrom(atom/A, atom/origin)
	if(!check_friendly_fire)
		return FALSE
	return ranged_fire_lane_is_unsafe(A, origin, FALSE, !attack_same)

///Controller ranged combat always protects allies and rejects static blockers.
///This is intentionally separate from the legacy check_friendly_fire opt-in.
/mob/living/simple_animal/hostile/proc/CheckRangedFireLane(atom/A)
	return CheckRangedFireLaneFrom(A, targets_from || src)

///Check a hypothetical firing origin for tactical repositioning.
/mob/living/simple_animal/hostile/proc/CheckRangedFireLaneFrom(atom/A, atom/origin)
	return ranged_fire_lane_is_unsafe(A, origin, !ranged_ignores_vision, !attack_same)

///Three-valued lane classification (CLEAR/COVER/BLOCKED) from a hypothetical
///firing origin. Used by tactical positioning to prefer a truly clean tile over
///one that only shoots through penetrable cover, and both over a hard block.
/mob/living/simple_animal/hostile/proc/CheckRangedFireLaneStateFrom(atom/A, atom/origin)
	return ranged_fire_lane_state(A, origin, !ranged_ignores_vision, !attack_same)

///A blocked lane is one whose real projectile route ends on static geometry, a
///protected ally, or an upright corpse buckled to a chair. Penetrable cover
///(sandbags, barricades) does NOT block: the mob fires over/through it just like
///a real bullet would.
/mob/living/simple_animal/hostile/proc/ranged_fire_lane_is_unsafe(atom/A, atom/origin, check_obstacles, protect_allies)
	return ranged_fire_lane_state(A, origin, check_obstacles, protect_allies) == AI_FIRE_LANE_BLOCKED

///Trace the same centre-aimed, pixel-stepped route used by projectile.fire() and
///classify it. When one pixel step enters a diagonal turf, movable.Move() visits
///the vertical cardinal turf first and the horizontal turf second; inspecting both
///fixes the corner-wall and diagonal-friendly gaps left by getline()/can_see().
/mob/living/simple_animal/hostile/proc/ranged_fire_lane_state(atom/A, atom/origin, check_obstacles, protect_allies)
	var/turf/start_turf = get_turf(origin)
	var/turf/target_turf = get_turf(A)
	if(!start_turf || !target_turf || start_turf.z != target_turf.z)
		return AI_FIRE_LANE_BLOCKED
	if(start_turf == target_turf)
		return AI_FIRE_LANE_CLEAR

	var/obj/item/projectile/projectile_path = projectiletype
	if(!projectile_path && casingtype)
		var/obj/item/ammo_casing/casing_path = casingtype
		projectile_path = initial(casing_path.projectile_type)
	//Custom OpenFire abilities without an actual projectile keep their subtype
	//semantics; a geometric bullet lane is not meaningful for summons or AoE.
	if(!ispath(projectile_path, /obj/item/projectile))
		return AI_FIRE_LANE_CLEAR
	var/projectile_pass_flags = projectile_path ? initial(projectile_path.pass_flags) : NONE
	var/projectile_phasing = projectile_path ? initial(projectile_path.projectile_phasing) : NONE
	var/projectile_piercing = projectile_path ? initial(projectile_path.projectile_piercing) : NONE
	var/traversal_flags = projectile_pass_flags | projectile_phasing | projectile_piercing
	var/no_hit_flags = projectile_pass_flags | projectile_phasing

	var/pixel_step = max(1, SSprojectiles.global_pixel_increment_amount)
	var/delta_x = target_turf.x - start_turf.x
	var/delta_y = target_turf.y - start_turf.y
	var/cache_key = "[pixel_step]:[delta_x]:[delta_y]"
	var/static/list/offset_cache = list()
	var/list/trace_offsets = offset_cache[cache_key]
	if(isnull(trace_offsets))
		trace_offsets = list()
		var/current_x = start_turf.x
		var/current_y = start_turf.y
		var/precise_x = ((current_x - 1) * world.icon_size) + (world.icon_size / 2) + 1
		var/precise_y = ((current_y - 1) * world.icon_size) + (world.icon_size / 2) + 1
		var/angle = get_projectile_angle(start_turf, target_turf)
		var/pixel_dx = sin(angle) * pixel_step
		var/pixel_dy = cos(angle) * pixel_step
		var/safety = (abs(delta_x) + abs(delta_y) + 2) * CEILING(world.icon_size / pixel_step, 1)

		while((current_x != target_turf.x || current_y != target_turf.y) && safety-- > 0)
			precise_x += pixel_dx
			precise_y += pixel_dy
			var/next_x = CEILING(precise_x / world.icon_size, 1)
			var/next_y = CEILING(precise_y / world.icon_size, 1)
			while(current_x != next_x || current_y != next_y)
				var/x_step = SIGN(next_x - current_x)
				var/y_step = SIGN(next_y - current_y)
				// Movable.Move() splits every diagonal vertically first.
				if(y_step)
					current_y += y_step
					if(current_x == target_turf.x && current_y == target_turf.y)
						break
					trace_offsets += list(list(current_x - start_turf.x, current_y - start_turf.y))
				if(x_step && (current_x != target_turf.x || current_y != target_turf.y))
					current_x += x_step
					if(current_x == target_turf.x && current_y == target_turf.y)
						break
					trace_offsets += list(list(current_x - start_turf.x, current_y - start_turf.y))
		if(current_x != target_turf.x || current_y != target_turf.y)
			return AI_FIRE_LANE_BLOCKED
		offset_cache[cache_key] = trace_offsets

	. = AI_FIRE_LANE_CLEAR
	for(var/list/offset as anything in trace_offsets)
		var/turf/lane_turf = locate(start_turf.x + offset[1], start_turf.y + offset[2], start_turf.z)
		var/turf_state = ranged_fire_turf_state(lane_turf, A, start_turf, traversal_flags, no_hit_flags, projectile_path, check_obstacles, protect_allies)
		if(turf_state == AI_FIRE_LANE_BLOCKED)
			return AI_FIRE_LANE_BLOCKED
		if(turf_state == AI_FIRE_LANE_COVER)
			. = AI_FIRE_LANE_COVER

///Classify one lane turf: BLOCKED (static geometry, a protected ally, or a seated
///corpse is in the way), COVER (only penetrable cover the bullet gets through from
///range), or CLEAR (nothing, or cover the shooter stands right behind - guaranteed
///pass).
/mob/living/simple_animal/hostile/proc/ranged_fire_turf_state(turf/lane_turf, atom/A, turf/origin_turf, traversal_flags, no_hit_flags, obj/item/projectile/projectile_path, check_obstacles, protect_allies)
	if(!lane_turf)
		return AI_FIRE_LANE_BLOCKED
	if(check_obstacles && lane_turf.density && !(traversal_flags & lane_turf.pass_flags_self))
		return AI_FIRE_LANE_BLOCKED
	. = AI_FIRE_LANE_CLEAR
	for(var/atom/movable/blocker as anything in lane_turf)
		if(blocker == src || blocker == A)
			continue
		if(isliving(blocker))
			var/mob/living/living_blocker = blocker
			if(protect_allies && living_blocker.stat != DEAD && faction_check_mob(living_blocker) && !(no_hit_flags & living_blocker.pass_flags_self))
				return AI_FIRE_LANE_BLOCKED
			//Projectiles normally pass over a corpse on the floor. A corpse held
			//upright by a chair is visible cover, so controller mobs must reposition
			//instead of repeatedly firing through its sprite at somebody behind it.
			if(check_obstacles && living_blocker.stat == DEAD && istype(living_blocker.buckled, /obj/structure/chair) && !(no_hit_flags & living_blocker.pass_flags_self))
				return AI_FIRE_LANE_BLOCKED
			continue
		if(!check_obstacles || !blocker.density || (traversal_flags & blocker.pass_flags_self))
			continue
		//Penetrable cover (sandbags/barricades) is not a wall: a real bullet has a
		//pass chance, and standing right behind your own cover it passes 100% (the
		//structure's CanAllowThrough exempts an adjacent firer). So near cover is a
		//CLEAR lane; only far cover downgrades the lane to COVER.
		if(blocker.is_ranged_ai_penetrable_cover())
			if(origin_turf && get_dist(origin_turf, lane_turf) <= 1)
				continue
			if(. == AI_FIRE_LANE_CLEAR)
				. = AI_FIRE_LANE_COVER
			continue
		//Рефлектор для отражаемого снаряда - не тупик: луч зеркалится и летит
		//дальше. Легаси-дрон стрелял в рефлектор (луч возвращался); геометрический
		//гейт не должен запрещать это (репорт "дроны не стреляют в рефлекторы").
		if(blocker.ranged_ai_lane_passable(projectile_path))
			continue
		return AI_FIRE_LANE_BLOCKED

/mob/living/simple_animal/hostile/proc/OpenFire(atom/A)
	if(ai_controller && !client)
		if(CheckRangedFireLane(A))
			return FALSE
	else if(CheckFriendlyFire(A))
		return FALSE
	visible_message("<span class='danger'><b>[src]</b> [ranged_message] at [A]!</span>")


	if(rapid > 1)
		start_rapid_fire_sequence(A)
	else
		Shoot(A)
	ranged_cooldown = world.time + ranged_cooldown_time
	return TRUE

/// Queue one shot at a time. The previous fan-out created N timer datums and
/// shared one callback datum between them for every ranged mob in a volley.
/mob/living/simple_animal/hostile/proc/start_rapid_fire_sequence(atom/volley_target)
	if(rapid_fire_timer_id || rapid_fire_shots_left > 0 || QDELETED(volley_target))
		return
	rapid_fire_target = volley_target
	rapid_fire_shots_left = rapid
	queue_next_rapid_fire_shot(world.tick_lag)

/mob/living/simple_animal/hostile/proc/queue_next_rapid_fire_shot(delay)
	rapid_fire_timer_id = addtimer(CALLBACK(src, PROC_REF(run_rapid_fire_shot)), delay, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/proc/run_rapid_fire_shot()
	rapid_fire_timer_id = null
	if(rapid_fire_shots_left <= 0 || QDELETED(rapid_fire_target))
		cancel_rapid_fire_sequence()
		return

	Shoot(rapid_fire_target)
	if(QDELETED(src))
		return
	rapid_fire_shots_left--
	if(rapid_fire_shots_left > 0 && !QDELETED(rapid_fire_target))
		queue_next_rapid_fire_shot(rapid_fire_delay)
	else
		rapid_fire_target = null

/mob/living/simple_animal/hostile/proc/cancel_rapid_fire_sequence()
	if(rapid_fire_timer_id)
		deltimer(rapid_fire_timer_id)
	rapid_fire_timer_id = null
	rapid_fire_shots_left = 0
	rapid_fire_target = null


/mob/living/simple_animal/hostile/proc/Shoot(atom/targeted_atom)
	if(QDELETED(src) || QDELETED(targeted_atom) || targeted_atom == targets_from?.loc || targeted_atom == targets_from)
		return
	//Rapid volleys are queued with timers. Recheck every projectile because an
	//ally can enter the lane after OpenFire() approved the first shot.
	if(ai_controller && !client)
		if(CheckRangedFireLane(targeted_atom))
			return
	else if(CheckFriendlyFire(targeted_atom))
		return
	//Targets are cached between expensive scans and rapid shots use timers. Do
	//not keep firing at their old coordinates after they move behind opacity.
	if(!ranged_ignores_vision && !can_see(targets_from || src, targeted_atom, vision_range))
		return
	var/turf/startloc = get_turf(targets_from)
	if(casingtype)
		var/obj/item/ammo_casing/casing = new casingtype(startloc)
		playsound(src, projectilesound, 100, 1)
		casing.fire_casing(targeted_atom, src, null, null, null, ran_zone(), 0, src)
	else if(projectiletype)
		var/obj/item/projectile/P = new projectiletype(startloc)
		playsound(src, projectilesound, 100, 1)
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.yo = targeted_atom.y - startloc.y
		P.xo = targeted_atom.x - startloc.x
		if(get_effective_ai_status() != AI_ON)//Don't want mindless mobs to have their movement screwed up firing in space
			newtonian_move(get_dir(targeted_atom, targets_from))
		P.original = targeted_atom
		P.preparePixelProjectile(targeted_atom, src)
		P.fire()
		return P


///Может ли моб реально проломить этот турф. Права на снос проверяются ИМЕННО
///здесь, а не только у вызывающего: легаси-путь DestroyObjectsInDirection бьёт
///по ответу этого прока, а attack_animal турфа играет анимацию удара ДО проверки
///прав. Без гейта моб со SMASH_STRUCTURES бесконечно молотил стену без урона
///(жалоба "анимация удара играет постоянно, стене ничего").
/mob/living/simple_animal/hostile/proc/CanSmashTurfs(turf/T)
	if(!iswallturf(T) && !ismineralturf(T))
		return FALSE
	if(istype(T, /turf/closed/wall/r_wall))
		return environment_smash & ENVIRONMENT_SMASH_RWALLS
	return environment_smash & (ENVIRONMENT_SMASH_WALLS|ENVIRONMENT_SMASH_RWALLS)


/mob/living/simple_animal/hostile/proc/dodge(moving_to,move_direction)
	//Assuming we move towards the target we want to swerve toward them to get closer
	var/cdir = turn(move_direction,45)
	var/ccdir = turn(move_direction,-45)
	dodging = FALSE
	. = Move(get_step(loc,pick(cdir,ccdir)))
	if(!.)//Can't dodge there so we just carry on
		. =  Move(moving_to,move_direction)
	dodging = TRUE

/mob/living/simple_animal/hostile/proc/DestroyObjectsInDirection(direction)
	var/turf/T = get_step(targets_from, direction)
	if(T && T.Adjacent(targets_from))
		if(CanSmashTurfs(T))
			T.attack_animal(src)
		for(var/obj/O in T)
			if(O.density && environment_smash >= ENVIRONMENT_SMASH_STRUCTURES && !O.IsObscured())
				O.attack_animal(src)
				return


/mob/living/simple_animal/hostile/proc/DestroyPathToTarget()
	if(environment_smash)
		EscapeConfinement()
		var/dir_to_target = get_dir(targets_from, target)
		var/dir_list = list()
		if(dir_to_target in GLOB.diagonals) //it's diagonal, so we need two directions to hit
			for(var/direction in GLOB.cardinals)
				if(direction & dir_to_target)
					dir_list += direction
		else
			dir_list += dir_to_target
		for(var/direction in dir_list) //now we hit all of the directions we got in this fashion, since it's the only directions we should actually need
			DestroyObjectsInDirection(direction)


/mob/living/simple_animal/hostile/proc/DestroySurroundings() // for use with megafauna destroying everything around them
	if(environment_smash)
		EscapeConfinement()
		for(var/dir in GLOB.cardinals)
			DestroyObjectsInDirection(dir)


/mob/living/simple_animal/hostile/proc/EscapeConfinement()
	if(buckled)
		buckled.attack_animal(src)
	if(!targets_from)
		return
	if(!isturf(targets_from.loc) && targets_from.loc != null)//Did someone put us in something?
		var/atom/A = targets_from.loc
		A.attack_animal(src)//Bang on it till we get out


/mob/living/simple_animal/hostile/RangedAttack(atom/A, params) //Player firing
	if(ranged && ranged_cooldown <= world.time)
		target = A
		OpenFire(A)
		DelayNextAction()
	. = ..()
	return TRUE

//These two procs handle losing our target if we've failed to attack them for
//more than lose_patience_timeout deciseconds, which probably means we're stuck
/mob/living/simple_animal/hostile/proc/GainPatience()
	if(QDELETED(src))
		return
	if(lose_patience_timeout)
		if(lose_patience_timer_id && world.time < next_patience_timer_refresh)
			return
		LosePatience()
		lose_patience_timer_id = addtimer(CALLBACK(src, PROC_REF(LoseTarget)), lose_patience_timeout, TIMER_STOPPABLE)
		next_patience_timer_refresh = world.time + min(1 SECONDS, lose_patience_timeout / 4)


/mob/living/simple_animal/hostile/proc/LosePatience()
	deltimer(lose_patience_timer_id)
	lose_patience_timer_id = null
	next_patience_timer_refresh = 0


//These two procs handle losing and regaining search_objects when attacked by a mob
/mob/living/simple_animal/hostile/proc/LoseSearchObjects()
	if(QDELETED(src))
		return
	if(!search_objects)
		return
	var/previous_search_mode = search_objects
	search_objects = 0
	deltimer(search_objects_timer_id)
	search_objects_timer_id = addtimer(CALLBACK(src, PROC_REF(RegainSearchObjects), previous_search_mode), search_objects_regain_time, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/proc/RegainSearchObjects(value)
	if(!value)
		value = initial(search_objects)
	search_objects = value

/**
  * Proc that handles a charge attack windup for a mob.
  */
/mob/living/simple_animal/hostile/proc/enter_charge(var/atom/target)
	if((mobility_flags & (MOBILITY_MOVE | MOBILITY_STAND)) != (MOBILITY_MOVE | MOBILITY_STAND) || charge_state || charge_windup_timer)
		return FALSE

	if(!(COOLDOWN_FINISHED(src, charge_cooldown)) || !has_gravity() || !target.has_gravity())
		return FALSE
	//кулдаун взводится с началом прелюдии: она длиннее каденса планировщика, и
	//без этого AI успевал поставить второй таймер и получить двойной бросок
	COOLDOWN_START(src, charge_cooldown, charge_frequency)
	Shake(15, 15, 1 SECONDS)
	charge_windup_timer = addtimer(CALLBACK(src, PROC_REF(handle_charge_target), target), 1.5 SECONDS, TIMER_STOPPABLE)
	return TRUE

/**
  * Proc that throws the mob at the target after the windup.
  */
/mob/living/simple_animal/hostile/proc/handle_charge_target(var/atom/target)
	charge_windup_timer = null
	if(charge_state || stat == DEAD || (mobility_flags & (MOBILITY_MOVE | MOBILITY_STAND)) != (MOBILITY_MOVE | MOBILITY_STAND))
		return FALSE
	//за прелюдию цель могла умереть, исчезнуть, сменить z или выйти из броска -
	//сорванный замах не бросает моба в пустоту и не сжигает полный каденс
	if(QDELETED(target) || target.z != z || get_dist(src, target) > charge_distance + 2 || !has_gravity() || !target.has_gravity())
		COOLDOWN_START(src, charge_cooldown, 1 SECONDS)
		return FALSE
	charge_state = TRUE
	throw_at(target, charge_distance, 1, src, FALSE, TRUE, callback = CALLBACK(src, PROC_REF(charge_end)))
	return TRUE

/**
  * Proc that handles a charge attack after it's concluded.
  */
/mob/living/simple_animal/hostile/proc/charge_end()
	charge_state = FALSE

/**
  * Proc that handles the charge impact of the charging mob.
  */
/mob/living/simple_animal/hostile/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!charge_state)
		return ..()

	if(hit_atom)
		if(isliving(hit_atom))
			var/mob/living/L = hit_atom
			var/blocked = FALSE
			if(ishuman(hit_atom))
				var/mob/living/carbon/human/H = hit_atom
				var/list/return_list = list()
				if(H.mob_run_block(src, 0, "the [name]", ATTACK_TYPE_TACKLE, 0, src, null, return_list) & BLOCK_SUCCESS)
					blocked = TRUE
				if(!blocked)
					blocked = return_list[BLOCK_RETURN_MITIGATION_PERCENT]
			if(!blocked)
				L.visible_message("<span class='danger'>[src] charges on [L]!</span>", "<span class='userdanger'>[src] charges into you!</span>")
				L.Knockdown(knockdown_time)
			else
				Stun((knockdown_time * 2), 1, 1)
			charge_end()
		else if(hit_atom.density && !hit_atom.CanPass(src))
			visible_message("<span class='danger'>[src] smashes into [hit_atom]!</span>")
			Stun((knockdown_time * 2), 1, 1)

		if(charge_state)
			charge_state = FALSE
			update_icons()
			update_mobility()

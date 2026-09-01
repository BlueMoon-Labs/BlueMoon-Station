// Таблицы атак боссов. Веса откалиброваны по легаси-
// вероятностям prob()/rand()-цепочек, фазы - по их health-гейтам; сами
// атаки - нетронутые легаси-проки. Без таблицы (build_ai_attack_table
// вернул null) босс стреляет по-старому через MoveToTarget -> OpenFire.
// Осознанно БЕЗ таблиц: hierophant (уже ситуативный список possibilities),
// blood_drunk_miner (уже детерминированная дальность), sand-боссы
// (фазовые машины gladiator/sif/king_of_goats/rogueprocess).

///Хук постройки таблицы; null = легаси-путь
/mob/living/simple_animal/hostile/proc/build_ai_attack_table()
	return null

///Прелюдия перед выбором способности (легаси-шапки OpenFire)
/mob/living/simple_animal/hostile/proc/ai_ability_prelude()
	return

///Фазовый гейт таблицы: не начинать новую способность поверх рывка/свупа/энрейджа.
/mob/living/simple_animal/hostile/proc/can_use_ai_ability(atom/target)
	return TRUE

///TRUE = легаси-автострельба OpenFire из AttackingTarget подавлена таблицей
/mob/living/simple_animal/hostile
	var/ai_attack_tables_active = FALSE

// ===== Вендиго =====

/mob/living/simple_animal/hostile/megafauna/wendigo/ai_ability_prelude()
	SetRecoveryTime(0, 100)
	if(health <= maxHealth * 0.5)
		stomp_range = 2
		speed = 6
		move_to_delay = 6
	else
		stomp_range = initial(stomp_range)
		speed = initial(speed)
		move_to_delay = initial(move_to_delay)

/mob/living/simple_animal/hostile/megafauna/wendigo/build_ai_attack_table()
	return list(
		new /datum/boss_attack("heavy stomp", PROC_REF(heavy_stomp), 4 SECONDS, 12, 0, 5),
		new /datum/boss_attack("teleport", PROC_REF(teleport), 6 SECONDS, 10, 5),
		new /datum/boss_attack("disorienting scream", PROC_REF(disorienting_scream), 6 SECONDS, 10, 0, 7),
	)

// ===== Колосс =====

/mob/living/simple_animal/hostile/megafauna/colossus/ai_ability_prelude()
	anger_modifier = clamp(((maxHealth - health) / 50), 0, 20)
	move_to_delay = initial(move_to_delay)

///Редкий martial-art контрпик из старого OpenFire должен обойти обычную таблицу.
/datum/boss_attack/colossus_enrage
	name = "inescapable judgement"
	cooldown_time = 3 SECONDS
	weight = 1000

/datum/boss_attack/colossus_enrage/is_available(mob/living/simple_animal/hostile/megafauna/colossus/boss, atom/target)
	return ..() && boss.enrage(target)

/mob/living/simple_animal/hostile/megafauna/colossus/proc/ai_enrage()
	if(move_to_delay == initial(move_to_delay))
		visible_message("<span class='colossus'>\"<b>You can't dodge.</b>\"</span>")
	ranged_cooldown = world.time + 3 SECONDS
	telegraph()
	dir_shots(GLOB.alldirs)
	move_to_delay = 3

///Обёртки: телеграф + атака, как в легаси-ветках OpenFire
/mob/living/simple_animal/hostile/megafauna/colossus/proc/ai_judgement()
	visible_message("<span class='colossus'>\"<b>Judgement.</b>\"</span>")
	telegraph()
	INVOKE_ASYNC(src, PROC_REF(spiral_shoot), pick(TRUE, FALSE))

/mob/living/simple_animal/hostile/megafauna/colossus/proc/ai_final_judgement()
	telegraph()
	double_spiral()

/mob/living/simple_animal/hostile/megafauna/colossus/build_ai_attack_table()
	return list(
		new /datum/boss_attack/colossus_enrage("inescapable judgement", PROC_REF(ai_enrage), 3 SECONDS, 1000),
		new /datum/boss_attack("judgement spiral", PROC_REF(ai_judgement), 12 SECONDS, 8, 0, INFINITY, 1/3),
		new /datum/boss_attack("final judgement", PROC_REF(ai_final_judgement), 12 SECONDS, 14, 0, INFINITY, 0, 1/3),
		new /datum/boss_attack("random shots", PROC_REF(random_shots), 2 SECONDS, 6),
		new /datum/boss_attack("directed blast", PROC_REF(blast), 3 SECONDS, 12, 2),
		new /datum/boss_attack("alternating shots", PROC_REF(alternating_dir_shots), 4 SECONDS, 6),
	)

// ===== Дрейк =====

/mob/living/simple_animal/hostile/megafauna/dragon/ai_ability_prelude()
	anger_modifier = clamp(((maxHealth - health) / 50), 0, 20)

/mob/living/simple_animal/hostile/megafauna/dragon/can_use_ai_ability(atom/target)
	return !swooping

/mob/living/simple_animal/hostile/megafauna/dragon/proc/ai_meteor_swoop()
	INVOKE_ASYNC(src, PROC_REF(swoop_attack), TRUE, null, 50)

/mob/living/simple_animal/hostile/megafauna/dragon/proc/ai_plain_swoop()
	INVOKE_ASYNC(src, PROC_REF(swoop_attack))

/mob/living/simple_animal/hostile/megafauna/dragon/proc/ai_triple_swoop()
	INVOKE_ASYNC(src, PROC_REF(triple_swoop))

/mob/living/simple_animal/hostile/megafauna/dragon/build_ai_attack_table()
	return list(
		new /datum/boss_attack("fire rain", PROC_REF(fire_rain), 6 SECONDS, 10, 0, INFINITY, 0.5),
		new /datum/boss_attack("meteor swoop", PROC_REF(ai_meteor_swoop), 10 SECONDS, 12, 0, INFINITY, 0, 0.5),
		new /datum/boss_attack("swoop", PROC_REF(ai_plain_swoop), 8 SECONDS, 8, 3, INFINITY, 0.5),
		new /datum/boss_attack("triple swoop", PROC_REF(ai_triple_swoop), 10 SECONDS, 10, 0, INFINITY, 0, 0.5),
		new /datum/boss_attack("fire walls", PROC_REF(fire_walls), 5 SECONDS, 8),
	)

// ===== Бабблгам =====

/mob/living/simple_animal/hostile/megafauna/bubblegum/ai_ability_prelude()
	anger_modifier = clamp(((maxHealth - health) / 50), 0, 20)
	blood_warp() //легаси: безусловный варп перед каждым залпом

/mob/living/simple_animal/hostile/megafauna/bubblegum/can_use_ai_ability(atom/target)
	return !charging

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/ai_blood_spray()
	INVOKE_ASYNC(src, PROC_REF(blood_spray))

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/ai_charge()
	INVOKE_ASYNC(src, PROC_REF(charge))

/mob/living/simple_animal/hostile/megafauna/bubblegum/proc/ai_triple_charge()
	INVOKE_ASYNC(src, PROC_REF(triple_charge))

/mob/living/simple_animal/hostile/megafauna/bubblegum/build_ai_attack_table()
	return list(
		new /datum/boss_attack("blood spray", PROC_REF(ai_blood_spray), 5 SECONDS, 9),
		new /datum/boss_attack("slaughterlings", PROC_REF(slaughterlings), 8 SECONDS, 6),
		new /datum/boss_attack("charge", PROC_REF(ai_charge), 6 SECONDS, 12, 2, INFINITY, 0.5),
		new /datum/boss_attack("triple charge", PROC_REF(ai_triple_charge), 8 SECONDS, 12, 2, INFINITY, 0, 0.5),
	)

// ===== Легион =====

/mob/living/simple_animal/hostile/megafauna/legion/can_use_ai_ability(atom/target)
	return !charging

/mob/living/simple_animal/hostile/megafauna/legion/build_ai_attack_table()
	return list(
		new /datum/boss_attack("legion skull", PROC_REF(create_legion_skull), 3 SECONDS, 12),
		new /datum/boss_attack("charge", PROC_REF(charge_target), 6 SECONDS, 6, 2),
		new /datum/boss_attack("legion turrets", PROC_REF(create_legion_turrets), 8 SECONDS, 6),
	)

// ===== Демонический ледяной шахтёр =====

/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/ai_ability_prelude()
	if(QDELETED(src) || stat == DEAD)
		return
	check_enraged()
	if(QDELETED(src) || stat == DEAD)
		return
	projectile_speed_multiplier = enraged ? 1.33 : 1
	SetRecoveryTime(100, 100)

/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/can_use_ai_ability(atom/target)
	return !enraging

/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/proc/ai_hard_shotgun_combo()
	if(QDELETED(src) || stat == DEAD || QDELETED(target))
		return
	INVOKE_ASYNC(src, PROC_REF(ice_shotgun), 5, list(list(-180, -140, -100, -60, -20, 20, 60, 100, 140), list(-160, -120, -80, -40, 0, 40, 80, 120, 160)))
	snowball_machine_gun(5 * 8, 5)

/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/proc/ai_hard_shotgun()
	ice_shotgun(5, list(list(0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330), list(-30, -15, 0, 15, 30)))

/mob/living/simple_animal/hostile/megafauna/demonic_frost_miner/build_ai_attack_table()
	return list(
		//лёгкие паттерны: недоступны в энрейдж-фазе (<25% здоровья)
		new /datum/boss_attack("frost orbs", PROC_REF(frost_orbs), 5 SECONDS, 12, 0, INFINITY, 0.25, 1, list(10, 8)),
		new /datum/boss_attack("snowball machine gun", PROC_REF(snowball_machine_gun), 5 SECONDS, 12, 0, INFINITY, 0.25, 1),
		new /datum/boss_attack("ice shotgun", PROC_REF(ice_shotgun), 5 SECONDS, 12, 0, 7, 0.25, 1),
		//тяжёлые паттерны: всегда доступны, в энрейдже остаются единственными
		new /datum/boss_attack("dense frost orbs", PROC_REF(frost_orbs), 6 SECONDS, 5, 0, INFINITY, 0, 1, list(5, 16)),
		new /datum/boss_attack("shotgun barrage", PROC_REF(ai_hard_shotgun_combo), 8 SECONDS, 5),
		new /datum/boss_attack("lattice shotgun", PROC_REF(ai_hard_shotgun), 6 SECONDS, 5, 0, 7),
	)

// ===== Элитки =====

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/ai_trishot()
	herald_trishot(target)
	my_mirror?.herald_trishot(target)

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/ai_directionalshot()
	herald_directionalshot()
	my_mirror?.herald_directionalshot()

/mob/living/simple_animal/hostile/asteroid/elite/herald/proc/ai_teleshot()
	herald_teleshot(target)
	my_mirror?.herald_teleshot(target)

/mob/living/simple_animal/hostile/asteroid/elite/herald/build_ai_attack_table()
	return list(
		new /datum/boss_attack("trishot", PROC_REF(ai_trishot), 3 SECONDS, 10),
		new /datum/boss_attack("directional barrage", PROC_REF(ai_directionalshot), 5 SECONDS, 8),
		new /datum/boss_attack("teleshot", PROC_REF(ai_teleshot), 5 SECONDS, 10, 4),
		new /datum/boss_attack("mirror", PROC_REF(herald_mirror), 12 SECONDS, 6),
	)

/mob/living/simple_animal/hostile/asteroid/elite/legionnaire/build_ai_attack_table()
	var/list/table = list(
		new /datum/boss_attack("charge", PROC_REF(legionnaire_charge), 5 SECONDS, 10, 2),
		new /datum/boss_attack("head detach", PROC_REF(head_detach), 10 SECONDS, 8),
		new /datum/boss_attack("bonfire teleport", PROC_REF(bonfire_teleport), 8 SECONDS, 6),
		new /datum/boss_attack("smoke spew", PROC_REF(spew_smoke), 5 SECONDS, 8, 0, 5),
	)
	for(var/datum/boss_attack/entry as anything in table)
		if(entry.attack_proc == PROC_REF(legionnaire_charge) || entry.attack_proc == PROC_REF(head_detach))
			entry.pass_target = TRUE
	return table

/mob/living/simple_animal/hostile/asteroid/elite/pandora/build_ai_attack_table()
	var/list/table = list(
		new /datum/boss_attack("singular shot", PROC_REF(singular_shot), 3 SECONDS, 10),
		new /datum/boss_attack("magic box", PROC_REF(magic_box), 5 SECONDS, 8),
		new /datum/boss_attack("teleport", PROC_REF(pandora_teleport), 6 SECONDS, 8, 5),
		new /datum/boss_attack("aoe squares", PROC_REF(aoe_squares), 5 SECONDS, 10, 0, 5),
	)
	for(var/datum/boss_attack/entry as anything in table)
		entry.pass_target = TRUE
	return table

/mob/living/simple_animal/hostile/asteroid/elite/broodmother/build_ai_attack_table()
	var/list/table = list(
		new /datum/boss_attack("tentacle patch", PROC_REF(tentacle_patch), 4 SECONDS, 10),
		new /datum/boss_attack("spawn children", PROC_REF(spawn_children), 10 SECONDS, 8),
		new /datum/boss_attack("rage", PROC_REF(rage), 15 SECONDS, 6, 0, INFINITY, 0, 0.5),
		new /datum/boss_attack("call children", PROC_REF(call_children), 8 SECONDS, 6),
	)
	var/datum/boss_attack/tentacles = table[1]
	tentacles.pass_target = TRUE
	return table

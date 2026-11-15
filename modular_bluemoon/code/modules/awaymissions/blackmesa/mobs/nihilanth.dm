// =============================================================================
// NIHILANTH - финальный босс Black Mesa
// Летающий ксено-босс: чередует залп метеоритов (benrey slug x3) и разряд
// по линии (как shock plant), по HP-порогам 75/50/30% уходит в неуязвимое испытание -
// портал на арене переносит игроков к особому aegis-пилону, после его
// разрушения открывается обратный разлом. Периодически призывает фауну зена
// и активирует ксено-пилон. Со смертью оставляет два односторонних разлома.
// =============================================================================

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth
	name = "nihilanth"
	desc = "Повелитель ксено-измерения. Само пространство трещит рядом с ним."
	icon = 'modular_bluemoon/icons/mob/nihilanth.dmi'
	icon_state = "nihilanth"
	icon_living = "nihilanth"
	icon_dead = "nihilanth"
	icon_gib = "nihilanth"
	SET_BASE_PIXEL(-32, -32)
	bound_height = 64
	bound_width = 64
	mob_biotypes = MOB_ORGANIC|MOB_BEAST|MOB_EPIC
	faction = list(FACTION_XEN)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	footstep_type = FOOTSTEP_MOB_HEAVY
	speed = 3
	turns_per_move = 1
	vision_range = 12
	maxHealth = 8000
	health = 8000
	obj_damage = 50
	harm_intent_damage = 50
	melee_damage_lower = 30
	melee_damage_upper = 40
	attack_verb_continuous = "lathes"
	attack_verb_simple = "lathe"
	attack_sound = 'sound/weapons/bite.ogg'
	movement_type = FLYING
	ranged = TRUE
	ranged_message = "hurls"
	rapid = 3
	ranged_cooldown_time = 50
	minimum_distance = 4
	retreat_distance = 6
	// Метеоритный залп - снаряд benrey-босса, rapid=3 даёт залп из трёх.
	projectiletype = /obj/item/projectile/bullet/shotgun_meteorslug/benrey
	projectilesound = 'sound/weapons/flashbang.ogg'
	status_flags = NONE
	del_on_death = FALSE
	wander = FALSE
	robust_searching = TRUE
	loot = list(/obj/effect/gibspawner/xeno, /obj/item/stack/sheet/bluespace_crystal/fifty, /obj/item/key/gateway, /obj/item/uber_teleporter)
	alert_cooldown = 60 SECONDS
	death_sound = 'modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_death01.ogg'

	// --- Бой ---
	/// Чередование атак: "meteor" - залп метеоритов, "tesla" - разряд по ряду.
	var/attack_style = "meteor"

	// --- Фазовые испытания (пороги HP) ---
	var/trial_active = FALSE
	var/obj/structure/xen_pylon/nihilanth/trial_pylon
	var/turf/trial_site
	var/turf/trial_pylon_turf
	var/turf/boss_home
	var/list/used_pylons = list()
	var/list/used_sites = list()
	var/list/trial_thresholds = list(0.75, 0.50, 0.30)
	var/list/trial_done = list(FALSE, FALSE, FALSE)

	// --- Призыв фауны / пилонов ---
	var/list/minion_types = list(
		/mob/living/simple_animal/hostile/blackmesa/xen/houndeye,
		/mob/living/simple_animal/hostile/headcrab/mesa,
		/mob/living/simple_animal/hostile/blackmesa/xen/vortigaunt,
	)
	var/list/alive_minions = list()
	var/max_minions = 8

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(minion_tick)), 30 SECONDS)

/obj/item/stack/sheet/bluespace_crystal/fifty
	amount = 50

// =============================================================================
// АТАКИ
// =============================================================================

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/OpenFire(atom/A)
	if(trial_active || stat == DEAD || QDELETED(A))
		return FALSE
	if(attack_style == "tesla")
		attack_style = "meteor"
		ranged_cooldown = world.time + ranged_cooldown_time
		visible_message("<span class='danger'><b>[src]</b> releases a crackling arc of portal energy at [A]!</span>")
		tesla_row_attack(A)
		return TRUE
	attack_style = "tesla"
	return ..()

// Разряд идёт ровной линией от босса к цели и бьёт всех не-союзников на ней -
// как shock plant, но управляемый: жертвы собираются по турфам направления.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/tesla_row_attack(atom/A)
	var/turf/start = get_turf(src)
	var/turf/target_turf = get_turf(A)
	if(!istype(start) || !istype(target_turf) || start.z != target_turf.z)
		return
	var/dir = get_dir(start, target_turf)
	if(!dir)
		return
	var/list/victims = list()
	var/turf/T = start
	for(var/i in 1 to 8)
		T = get_step(T, dir)
		if(!istype(T))
			break
		for(var/mob/living/L in T)
			if(L == src || L.stat == DEAD || (L in victims))
				continue
			if(faction_check_mob(L))
				continue
			victims += L
			if(victims.len >= 6)
				break
		if(victims.len >= 6)
			break
	if(!victims.len)
		return
	playsound(start, 'sound/magic/lightningbolt.ogg', 80, FALSE)
	for(var/mob/living/V in victims)
		if(QDELETED(V) || V.stat == DEAD)
			continue
		if(get_turf(V))
			src.Beam(V, icon_state = "red_lightning", time = 15, maxdistance = 12)
		V.apply_damage(25, BURN)
		V.DefaultCombatKnockdown(20)
		V.adjustStaminaLoss(10)

// Во время испытания босс не атакует - ни в ближнем, ни в дальнем бою.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/AttackingTarget()
	if(trial_active)
		return
	return ..()

// Неуязвимость на время испытания. forced-урон (админка) пробивает.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE, spread_damage = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = NONE, attack_direction = null, attacking_item)
	if(trial_active && !forced)
		balloon_alert_to_viewers("ineffective!")
		return FALSE
	. = ..()
	if(. && stat != DEAD)
		check_trial_thresholds()
	return .

// =============================================================================
// ФАЗОВЫЕ ИСПЫТАНИЯ
// =============================================================================

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/check_trial_thresholds()
	if(trial_active || stat == DEAD)
		return
	var/frac = health / maxHealth
	for(var/i in 1 to trial_thresholds.len)
		if(trial_done[i] || frac > trial_thresholds[i])
			continue
		trial_done[i] = TRUE
		start_trial()
		return

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/start_trial()
	var/turf/home = get_turf(src)
	if(!istype(home))
		return
	// Сначала ищем площадку - без неё испытание не начинаем,
	// иначе босс застрял бы в неуязвимости навсегда.
	var/list/site_and_pylon = pick_trial_site()
	if(!site_and_pylon)
		visible_message("<span class='warning'>Пространство вокруг [src] искажается, но разлом не стабилизируется...</span>")
		return
	var/turf/site = site_and_pylon[1]
	trial_pylon = site_and_pylon[2]
	used_sites += site
	trial_pylon.used = TRUE
	trial_pylon.trial_active = TRUE
	trial_pylon.nihilanth_boss = src
	used_pylons += trial_pylon

	trial_active = TRUE
	trial_site = site
	trial_pylon_turf = get_turf(trial_pylon)
	boss_home = home
	cancel_rapid_fire_sequence()
	cancel_rapid_melee_sequence()

	var/obj/effect/portal/mesa_rift/nihilanth_rift/P = new(home)
	if(istype(P))
		P.hard_target = site
		P.hardlinked = FALSE
	playsound(home, 'sound/effects/space_wind.ogg', 90, FALSE, -4)
	visible_message("<span class='boldannounce'>[src] вспыхивает невыносимым светом! Оно неуязвимо - разлом на арене ведёт к источнику его силы!</span>")
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_iamthelast01.ogg', 100, FALSE)

// Выбирает случайную свободную точку испытания: лендмарк nihilanth_pylon_site
// - это точка ПРИБЫТИЯ (портал падает сюда), а особый пилон может стоять
// где угодно на том же z-уровне - игроки идут от точки прибытия до пилона.
// Фолбэк - любой неиспользованный особый пилон на карте (лендмарк не нужен,
// точкой прибытия станет турф самого пилона).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/pick_trial_site()
	var/list/options = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site/L in GLOB.landmarks_list)
		var/turf/T = get_turf(L)
		if(!istype(T) || !isopenturf(T) || (T in used_sites))
			continue
		var/obj/structure/xen_pylon/nihilanth/P = find_trial_pylon(T)
		if(istype(P))
			options += list(T, P)
	if(!options.len)
		for(var/obj/structure/xen_pylon/nihilanth/P in world)
			if(P.used)
				continue
			var/turf/T = get_turf(P)
			if(istype(T))
				options += list(T, P)
	if(!options.len)
		return null
	return pick(options)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/find_trial_pylon(turf/T)
	for(var/obj/structure/xen_pylon/nihilanth/P in world)
		if(P.used)
			continue
		var/turf/PT = get_turf(P)
		if(istype(PT) && PT.z == T.z)
			return P
	return null

// Вызывается особым пилоном при своём Destroy: открывает обратный разлом
// на арене босса и возвращает ему уязвимость.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/end_trial()
	if(!trial_active)
		return
	trial_active = FALSE
	var/turf/site = trial_site
	var/turf/return_turf = trial_pylon_turf
	var/turf/home = boss_home
	trial_site = null
	trial_pylon = null
	trial_pylon_turf = null
	boss_home = null
	// Обратный разлом ставим у уничтоженного пилона (точка Б) - игроки
	// возвращаются сразу после его разрушения, без возврата к точке А.
	if(!istype(return_turf) || !isopenturf(return_turf))
		return_turf = site
	if(istype(return_turf) && isopenturf(return_turf) && istype(home))
		var/obj/effect/portal/mesa_rift/nihilanth_rift/R = new(return_turf)
		if(istype(R))
			R.hard_target = home
			R.hardlinked = FALSE
			playsound(return_turf, 'sound/effects/space_wind.ogg', 90, FALSE, -4)
	visible_message("<span class='boldwarning'>Пилон разрушен! Разлом у его останков ведёт обратно на арену [src]!</span>")
	check_trial_thresholds()

// =============================================================================
// ПРИЗЫВ ФАУНЫ И ПИЛОНОВ
// =============================================================================

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/minion_tick()
	if(QDELETED(src) || stat == DEAD)
		return
	addtimer(CALLBACK(src, PROC_REF(minion_tick)), rand(12, 20) SECONDS)
	if(trial_active || !target || QDELETED(target))
		return
	if(prob(60))
		spawn_xen_fauna()
	else
		spawn_aegis_pylon()

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/spawn_xen_fauna()
	var/spawned = 0
	for(var/i in 1 to 3)
		if(alive_minions.len >= max_minions)
			break
		var/turf/T = free_turf_near(src)
		if(!istype(T))
			continue
		var/minion_type = pick(minion_types)
		var/mob/living/simple_animal/hostile/M = new minion_type(T)
		if(QDELETED(M))
			continue
		M.faction = faction
		if(isliving(target))
			M.GiveTarget(target)
		alive_minions += M
		RegisterSignal(M, COMSIG_PARENT_QDELETING, PROC_REF(remove_minion), override = TRUE)
		spawned++
	if(spawned)
		visible_message("<span class='danger'>[src] рвёт пространство - из разломов выходят ксено-мутанты!</span>")
		playsound(get_turf(src), 'sound/magic/blink.ogg', 80, FALSE)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/spawn_aegis_pylon()
	var/turf/T = free_turf_near(src, 3)
	if(!istype(T))
		return
	new /obj/structure/xen_pylon(T)
	visible_message("<span class='warning'>[src] активирует ксено-пилон - его поле окутывает союзников щитом!</span>")
	playsound(T, 'sound/magic/lightningbolt.ogg', 80, FALSE)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/remove_minion(datum/source, forced)
	alive_minions -= source

// Свободный открытый турф рядом с мобом (не космос/бездна, не сквозь стену).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/free_turf_near(atom/center, range = 4)
	var/turf/CT = get_turf(center)
	if(!istype(CT))
		return null
	var/list/turfs = list()
	for(var/turf/T in view(range, CT))
		if(T.z != CT.z)
			continue
		if(!istype(T, /turf/open) || istype(T, /turf/open/chasm) || istype(T, /turf/open/space))
			continue
		if(T.density)
			continue
		turfs += T
	return pick(turfs)

// =============================================================================
// РЕПЛИКИ / СМЕРТЬ
// =============================================================================

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/voice_lines()
	var/frac = health / maxHealth
	if(frac <= 0.33)
		return list('modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_freeeemmaan01.ogg')
	if(frac <= 0.66)
		return list('modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_foryouhewaits01.ogg', 'modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_deceiveyou01.ogg')
	return list('modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_iamthelast01.ogg', 'modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_deceiveyou01.ogg')

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/Aggro()
	. = ..()
	if(alert_cooldown_time <= world.time)
		alert_cooldown_time = world.time + alert_cooldown
		playsound(src, pick(voice_lines()), 80, FALSE)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/death(gibbed)
	. = ..()
	spawn_death_portals()

// Два односторонних разлома под трупом: один к выходу из комплекса
// (лендмарк nihilanth_exit), второй - в другую часть комплекса
// (лендмарк nihilanth_complex). Обратного пути нет.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/spawn_death_portals()
	var/turf/T = get_turf(src)
	if(!istype(T))
		T = boss_home
	if(!istype(T))
		return
	var/list/used_turfs = list()
	spawn_death_portal(T, /obj/effect/landmark/awaymission/blackmesa/nihilanth_exit, used_turfs)
	spawn_death_portal(T, /obj/effect/landmark/awaymission/blackmesa/nihilanth_complex, used_turfs)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/spawn_death_portal(turf/near_turf, landmark_type, list/used_turfs)
	var/turf/dest = null
	for(var/obj/effect/landmark/L in GLOB.landmarks_list)
		if(istype(L, landmark_type))
			var/turf/DT = get_turf(L)
			if(istype(DT))
				dest = DT
				break
	if(!istype(dest))
		visible_message("<span class='warning'>Разлом не смог стабилизироваться - точка назначения не найдена.</span>")
		return
	var/turf/T = near_turf
	if(T in used_turfs || !isopenturf(T))
		T = null
	else
		// Труп может быть плотным - портал под ним будет недостижим.
		for(var/atom/movable/AM in T)
			if(AM.density)
				T = null
				break
	for(var/attempt in 1 to 5)
		if(istype(T) && !(T in used_turfs))
			break
		T = free_turf_near(near_turf, 3)
	if(!istype(T) || (T in used_turfs))
		return
	used_turfs += T
	var/obj/effect/portal/mesa_rift/nihilanth_rift/P = new(T)
	if(!istype(P))
		return
	P.hard_target = dest
	P.hardlinked = FALSE
	playsound(T, 'sound/effects/space_wind.ogg', 90, FALSE, -4)

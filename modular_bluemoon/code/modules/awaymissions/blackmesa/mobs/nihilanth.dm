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
	var/last_trial_attempt = 0
	var/obj/structure/xen_pylon/nihilanth/trial_pylon
	var/turf/trial_site
	var/turf/trial_pylon_turf
	var/turf/boss_home
	/// Активный триальный разлом у босса. Портал permanent и без явного
	/// удаления наслаивался: обратный разлом вёл на турф, где всё ещё стоял
	/// старый, и игрока перекидывало по цепочке чужих hard_target'ов.
	var/obj/effect/portal/trial_portal
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
	/// Потолок спайренных Nihilanth'ом aegis-столбов - без капа каждый
	/// minion_tick добавлял новый пилон и арена зарастала структурами.
	var/list/spawned_add_pylons = list()
	var/max_add_pylons = 5

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(minion_tick)), 30 SECONDS)

/obj/item/stack/sheet/bluespace_crystal/fifty
	amount = 50

// =============================================================================
// АТАКИ
// =============================================================================

// Две атаки по очереди: "meteor" - залп xen blast (копия benrey-метеорита),
// "tesla" - разряд xen shock, который на попадании бьёт током несколько целей.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/OpenFire(atom/A)
	if(trial_active || stat == DEAD || QDELETED(A))
		return FALSE
	var/is_tesla = (attack_style == "tesla")
	projectiletype = is_tesla ? /obj/item/projectile/energy/tesla/xen_shock : /obj/item/projectile/bullet/shotgun_meteorslug/xen_blast
	projectilesound = is_tesla ? 'sound/magic/lightningbolt.ogg' : 'modular_bluemoon/sound/weapons/mesa/sweetvoice.ogg'
	ranged_message = is_tesla ? "discharges a xen shock" : "hurls xen blasts"
	rapid = is_tesla ? 1 : 3
	attack_style = is_tesla ? "meteor" : "tesla"
	return ..()

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
	// Неудачная попытка (пилоны кончились) не сжигает порог - ретрайм
	// с кулдауном, иначе каждый тычок регенил бы спам видимым сообщением.
	if(world.time - last_trial_attempt < 30 SECONDS)
		return
	var/frac = health / maxHealth
	for(var/i in 1 to trial_thresholds.len)
		if(trial_done[i] || frac > trial_thresholds[i])
			continue
		last_trial_attempt = world.time
		if(start_trial())
			trial_done[i] = TRUE
		return

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/start_trial()
	var/turf/home = get_turf(src)
	// Босс летающий: его турф может оказаться стеной/плотным - портал
	// встал бы в недостижимую точку, а босс остался бы неуязвимым.
	if(!istype(home) || !isopenturf(home))
		home = free_turf_near(src, 4)
	if(!istype(home) || !isopenturf(home))
		return FALSE
	// Сначала ищем площадку - без неё испытание не начинаем,
	// иначе босс застрял бы в неуязвимости навсегда.
	var/list/site_and_pylon = pick_trial_site()
	if(!islist(site_and_pylon) || length(site_and_pylon) < 2)
		visible_message("<span class='warning'>Пространство вокруг [src] искажается, но разлом не стабилизируется...</span>")
		return FALSE
	if(!istype(site_and_pylon[1], /turf) || !istype(site_and_pylon[2], /obj/structure/xen_pylon/nihilanth))
		visible_message("<span class='warning'>Пространство вокруг [src] искажается, но разлом не стабилизируется...</span>")
		return FALSE
	var/site_landmark_raw = length(site_and_pylon) >= 3 ? site_and_pylon[3] : null
	var/turf/site = site_and_pylon[1]
	var/obj/structure/xen_pylon/nihilanth/pylon = site_and_pylon[2]
	// Портал ставим ДО включения неуязвимости: если он не встанет, босс
	// остался бы в trial_active без единого пути к пилону - softlock.
	var/obj/effect/portal/P = new /obj/effect/portal/mesa_rift/nihilanth_rift(home)
	if(!istype(P))
		visible_message("<span class='warning'>Пространство вокруг [src] искажается, но разлом не стабилизируется...</span>")
		return FALSE
	P.hard_target = site
	P.hardlinked = FALSE
	trial_portal = P
	pylon.trial_portal = P
	var/turf/pylon_turf = get_turf(pylon)
	log_world("NIHILANTH: start_trial portal=([home.x],[home.y],[home.z]) hard_target=([site.x],[site.y],[site.z]) pylon=([pylon_turf.x],[pylon_turf.y],[pylon_turf.z])")

	trial_pylon = pylon
	trial_pylon.used = TRUE
	trial_pylon.trial_active = TRUE
	trial_pylon.nihilanth_boss = src
	trial_pylon.trial_home = home
	trial_pylon.set_linked_site(site_landmark_raw)

	trial_active = TRUE
	trial_site = site
	trial_pylon_turf = get_turf(trial_pylon)
	boss_home = home
	cancel_rapid_fire_sequence()
	cancel_rapid_melee_sequence()

	playsound(home, 'sound/effects/space_wind.ogg', 90, FALSE, -4)
	visible_message("<span class='boldannounce'>[src] вспыхивает невыносимым светом! Оно неуязвимо - разлом на арене ведёт к источнику его силы!</span>")
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_iamthelast01.ogg', 100, FALSE)
	return TRUE

// Выбирает случайную свободную пару испытания: лендмарк nihilanth_pylon_site
// (точка ПРИБЫТИЯ портала) + особый пилон (цель). Пара связывается по ID
// (site_id) или авто-привязкой к ближайшему свободному лендмарку на том же
// z-уровне. При уничтожении пилона его лендмарк деактивируется (site_used =
// TRUE) и больше не выбирается - следующий разлом ведёт к остальным парам.
// Возвращает list(турф прибытия, пилон, лендмарк|null).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/pick_trial_site()
	// Свободные пилоны берём из реестра GLOB.nihilanth_pylons (пилоны
	// саморегистрируются в Initialize) - без прохода по world.
	var/list/free_pylons = list()
	for(var/obj/structure/xen_pylon/nihilanth/P in GLOB.nihilanth_pylons)
		if(P && !QDELETED(P) && !P.used)
			free_pylons += P
	// Активные лендмарки: не деактивированные и стоящие на валидном турфе.
	var/list/site_landmarks = list()
	for(var/obj/effect/landmark/awaymission/blackmesa/L in GLOB.nihilanth_sites)
		if(GLOB.nihilanth_site_used[L] || !get_turf(L))
			continue
		site_landmarks += L
	var/list/options = list()
	var/list/claimed = list()
	var/branch = "site+pylon"
	for(var/obj/structure/xen_pylon/nihilanth/P in free_pylons)
		var/obj/effect/landmark/L = find_site_for_pylon(P, site_landmarks, claimed)
		if(!istype(L) || !get_turf(L))
			continue
		var/turf/T = get_turf(L)
		if(!istype(T) || !isopenturf(T))
			continue
		claimed += L
		options += list(list(T, P, L))
	if(!options.len)
		branch = "pylon-only"
		for(var/obj/structure/xen_pylon/nihilanth/P in free_pylons)
			var/turf/T = get_turf(P)
			if(istype(T))
				options += list(list(T, P, null))
	if(!options.len)
		// Особых пилонов на карте меньше, чем HP-порогов - ставим новый
		// рядом с точкой испытания, иначе третий разлом никогда не откроется.
		branch = "landmark+new-pylon"
		for(var/obj/effect/landmark/awaymission/blackmesa/L in site_landmarks)
			var/turf/T = get_turf(L)
			if(!istype(T) || !isopenturf(T))
				continue
			var/turf/PT = free_turf_near(T, 6)
			if(!istype(PT))
				continue
			var/obj/structure/xen_pylon/nihilanth/P = new /obj/structure/xen_pylon/nihilanth(PT)
			if(istype(P) && !QDELETED(P))
				options += list(list(T, P, L))
				break
	if(!options.len)
		// Совсем без лендмарков - пилон рядом с самим боссом.
		branch = "near-boss"
		var/turf/PT = free_turf_near(src, 8)
		if(istype(PT))
			var/obj/structure/xen_pylon/nihilanth/P = new /obj/structure/xen_pylon/nihilanth(PT)
			if(istype(P) && !QDELETED(P))
				options += list(list(PT, P, null))
	if(!options.len)
		log_world("NIHILANTH: pick_trial_site: NO options. pylons=[length(GLOB.nihilanth_pylons)] free=[free_pylons.len] sites=[site_landmarks.len] landmarks_total=[length(GLOB.landmarks_list)]")
		return null
	var/list/picked = pick(options)
	var/raw_s = picked[1]
	var/raw_p = picked[2]
	var/turf/s = istype(raw_s, /turf) ? raw_s : null
	var/atom/pylon_t = istype(raw_p, /atom) ? raw_p : null
	var/turf/pt = istype(pylon_t) ? get_turf(pylon_t) : null
	var/site_str = s ? "([s.x],[s.y],[s.z])" : "null"
	var/pylon_str = pt ? "([pt.x],[pt.y],[pt.z])" : "null"
	log_world("NIHILANTH: pick_trial_site branch=[branch] site=[site_str] pylon_turf=[pylon_str] pylons=[length(GLOB.nihilanth_pylons)] free=[free_pylons.len] sites=[site_landmarks.len]")
	return picked

// Находит лендмарк, привязанный к пилону: по явному site_id, иначе -
// ближайший свободный лендмарк на том же z-уровне. claimed не даёт двум
// пилонам занять один и тот же лендмарк в рамках одного выбора.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/find_site_for_pylon(obj/structure/xen_pylon/nihilanth/P, list/site_landmarks, list/claimed)
	if(P.site_id)
		for(var/obj/effect/landmark/awaymission/blackmesa/L in site_landmarks)
			if(GLOB.nihilanth_site_ids[L] == P.site_id && !(L in claimed))
				return L
		return null
	var/turf/PT = get_turf(P)
	if(!istype(PT))
		return null
	var/obj/effect/landmark/best = null
	var/best_dist = 999999
	for(var/obj/effect/landmark/awaymission/blackmesa/L in site_landmarks)
		if(L in claimed)
			continue
		var/turf/T = get_turf(L)
		if(!istype(T) || T.z != PT.z || !isopenturf(T))
			continue
		var/d = get_dist(T, PT)
		if(d < best_dist)
			best_dist = d
			best = L
	return best

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
	// Триальный разлом permanent - снимаем его до возврата, иначе он
	// остаётся на арене и следующая телепортация на его турф запускает
	// цепочку чужих hard_target'ов.
	if(istype(trial_portal) && !QDELETED(trial_portal))
		qdel(trial_portal)
	trial_portal = null
	// Обратный разлом ставим у уничтоженного пилона (точка Б) - игроки
	// возвращаются сразу после его разрушения, без возврата к точке А.
	if(!istype(return_turf) || !isopenturf(return_turf))
		return_turf = site
	// home мог быть стеной/плотным турфом на момент старта - валидируем,
	// иначе обратный разлом телепортирует игроков внутрь геометрии.
	if(!istype(home) || !isopenturf(home))
		home = free_turf_near(home, 4)
	if(istype(return_turf) && isopenturf(return_turf) && istype(home) && isopenturf(home))
		var/obj/effect/portal/R = new /obj/effect/portal/mesa_rift/nihilanth_rift(return_turf)
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
	// Список чистим свипом, а не только сигналом parent_qdeleting: если
	// регистрацию на миньоне перезапишет чужая система, кап минионов
	// навсегда встанет на мёртвых рефах.
	for(var/mob/living/dead_minion as anything in alive_minions.Copy())
		if(QDELETED(dead_minion) || dead_minion.stat == DEAD)
			alive_minions -= dead_minion
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
	// Кап на живые спайры: иначе каждый тик добавлял новый плотный
	// anchored-пилон и за долгий бой арена зарастала структурами.
	for(var/obj/structure/xen_pylon/nihilanth_add/P as anything in spawned_add_pylons.Copy())
		if(QDELETED(P))
			spawned_add_pylons -= P
	if(spawned_add_pylons.len >= max_add_pylons)
		return
	var/turf/T = free_turf_near(src, 5)
	if(!istype(T))
		return
	var/obj/structure/xen_pylon/nihilanth_add/new_pylon = new /obj/structure/xen_pylon/nihilanth_add(T)
	if(!istype(new_pylon) || QDELETED(new_pylon))
		return
	spawned_add_pylons += new_pylon
	visible_message("<span class='warning'>[src] активирует ксено-пилон - его поле окутывает союзников щитом!</span>")
	playsound(T, 'sound/magic/lightningbolt.ogg', 80, FALSE)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/remove_minion(datum/source, forced)
	alive_minions -= source

// Тот же фильтр, что в free_turf_near: открытый турф, но не хасма/космос
// и не плотный - isopenturf() их пропускает, а стоять на них нельзя.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/valid_rift_turf(turf/T)
	return istype(T) && istype(T, /turf/open) && !istype(T, /turf/open/chasm) && !istype(T, /turf/open/space) && !T.density

// На турфе уже стоит портал - Move() нового портала вернёт FALSE, и объект
// останется без лока (невидимый «фантом»).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/turf_has_portal(turf/T)
	for(var/atom/movable/AM in T)
		if(istype(AM, /obj/effect/portal) && !QDELETED(AM))
			return TRUE
	return FALSE

// Свободный открытый турф рядом с мобом (не космос/бездна, не сквозь стену).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/free_turf_near(atom/center, range = 4)
	if(!center || QDELETED(center))
		return null
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
	// Точку смерти берём ДО родительского death(): при гибе моб удаляется
	// вместе с привязкой к турфу, и get_turf(src) после ..() возвращал null -
	// без boss_home (триала не было) spawn_death_portals просто выходил,
	// и разломов на выход не появлялось.
	var/turf/death_turf = get_turf(src)
	// Триальный разлом не должен переживать босса - иначе он остаётся
	// на арене и шлёт игроков на точку уже пройденного испытания.
	if(istype(trial_portal) && !QDELETED(trial_portal))
		qdel(trial_portal)
	trial_portal = null
	. = ..()
	spawn_death_portals(death_turf)
	// Босс не оставляет труп: добиваем гибом (gib() сам вызовет death(1)
	// только если stat ещё не DEAD - здесь он уже DEAD, рекурсии нет).
	if(!gibbed)
		gib()

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/Destroy()
	if(istype(trial_portal) && !QDELETED(trial_portal))
		qdel(trial_portal)
	trial_portal = null
	// Босс удалён посреди испытания без death() (рестарт/админка): игроки
	// на точке испытания иначе останутся без обратного разлома - end_trial()
	// уже не вызовется. Ставим разлом у турфа пилона обратно на арену.
	if(trial_active)
		var/turf/rt = trial_pylon_turf
		var/turf/hm = boss_home
		if(!istype(rt) || !isopenturf(rt))
			rt = trial_site
		if(istype(hm) && !isopenturf(hm))
			hm = free_turf_near(hm, 4)
		if(istype(rt) && isopenturf(rt) && istype(hm) && isopenturf(hm))
			var/obj/effect/portal/R = new /obj/effect/portal/mesa_rift/nihilanth_rift(rt)
			if(istype(R))
				R.hard_target = hm
				R.hardlinked = FALSE
	return ..()

// Два односторонних разлома под трупом: один к выходу из комплекса
// (лендмарк nihilanth_exit), второй - в другую часть комплекса
// (лендмарк nihilanth_complex). Обратного пути нет.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/spawn_death_portals(turf/death_turf = null)
	var/turf/T = death_turf
	if(!istype(T))
		T = get_turf(src)
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
		log_world("[src] spawn_death_portal: landmark [landmark_type] not found in GLOB.landmarks_list")
		visible_message("<span class='warning'>Разлом не смог стабилизироваться - точка назначения не найдена.</span>")
		return
	if(!valid_rift_turf(dest))
		dest = free_turf_near(dest, 4)
	if(!valid_rift_turf(dest))
		log_world("[src] spawn_death_portal: landmark [landmark_type] has no open destination turf")
		visible_message("<span class='warning'>Разлом не смог стабилизироваться - точка назначения недоступна.</span>")
		return
	// Кандидаты на установку: сначала турф под трупом, затем случайные
	// рядом. Турфы с уже стоящим порталом пропускаем - Move() портала
	// вернёт FALSE, и разлом «родится» невидимым объектом без привязки.
	var/list/candidates = list()
	var/turf/T = near_turf
	if(istype(T) && !(T in used_turfs) && valid_rift_turf(T))
		// Труп может быть плотным - портал под ним будет недостижим.
		var/blocked = FALSE
		for(var/atom/movable/AM in T)
			if(AM.density)
				blocked = TRUE
				break
		if(!blocked && !turf_has_portal(T))
			candidates += T
	for(var/attempt in 1 to 12)
		if(candidates.len >= 4)
			break
		var/turf/cand = free_turf_near(near_turf, 3)
		if(!istype(cand) || (cand in used_turfs) || (cand in candidates) || !valid_rift_turf(cand) || turf_has_portal(cand))
			continue
		candidates += cand
	var/obj/effect/portal/P = null
	for(var/turf/cand in candidates)
		var/obj/effect/portal/try_P = new /obj/effect/portal/mesa_rift/nihilanth_rift(cand)
		// new на турф с уже стоящим порталом не падает, а оставляет объект
		// без лока - проверяем, что портал реально встал на кандидат.
		if(istype(try_P) && get_turf(try_P) == cand)
			P = try_P
			T = cand
			break
		if(istype(try_P))
			qdel(try_P)
	if(!istype(P))
		log_world("[src] spawn_death_portal: no placeable turf near [near_turf] for [landmark_type]")
		return
	used_turfs += T
	P.hard_target = dest
	P.hardlinked = FALSE
	playsound(T, 'sound/effects/space_wind.ogg', 90, FALSE, -4)

// =============================================================================
// СНАРЯДЫ НИХИЛАНТА
// =============================================================================

// "xen blast" - копия benrey-метеорита (тот же урон/нокдаун/иконка), но со
// своим именем; звук залпа задаётся мобом (sweet voice).
/obj/item/projectile/bullet/shotgun_meteorslug/xen_blast
	name = "xen blast"
	desc = "A slug of condensed xen energy."

// "xen shock" - разряд на манер удара xen shockplant: при попадании
// tesla_zap прыгает на несколько целей вокруг точки удара.
/obj/item/projectile/energy/tesla/xen_shock
	name = "xen shock"
	desc = "A bolt of raw xen energy that arcs between targets."
	power = 30000
	zap_range = 6
	zap_flags = ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE | ZAP_MOB_STUN

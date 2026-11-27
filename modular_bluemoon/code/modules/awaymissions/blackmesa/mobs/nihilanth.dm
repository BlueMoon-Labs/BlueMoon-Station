// =============================================================================
// NIHILANTH - финальный босс Black Mesa
// Летающий ксено-босс-турель: циклом чередует атаки - залп метеоритов
// (benrey slug x3), разряд по линии (как shock plant), спиральный ксеновый
// шторм и веерные залпы (как spiral_shoot/blast колосса), кардинально-
// диагональную канонаду и вращающийся ксеновый крест ~15 тайлов (по мотивам
// zweispin гладиатора: бьёт только не-ксено мобов, щиты и кристаллы Mesa не
// задевает). По HP-порогам 75/50/30% уходит в неуязвимое испытание -
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
	// Агро-радиус ~20 тайлов: и холодное зрение, и боевой радиус поиска
	// (get_aggro_range берёт min(профиля, vision/aggro_vision)).
	vision_range = 20
	aggro_vision_range = 20
	maxHealth = 10000
	health = 10000
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
	projectiletype = /obj/item/projectile/bullet/shotgun_meteorslug/nihilanth_blast
	projectilesound = 'sound/weapons/flashbang.ogg'
	status_flags = NONE
	del_on_death = FALSE
	wander = FALSE
	robust_searching = TRUE
	loot = list(/obj/effect/gibspawner/xeno, /obj/item/stack/sheet/bluespace_crystal/fifty, /obj/item/key/gateway, /obj/item/uber_teleporter)
	alert_cooldown = 60 SECONDS
	death_sound = 'modular_bluemoon/sound/creatures/mesa/nihilanth/nihilanth_death01.ogg'

	// --- Бой ---
	/// Цикл атак: "meteor" - залп метеоритов, "tesla" - разряд по ряду,
	/// "spiral" - спиральный ксеновый шторм, "dir" - канонада по 4 направлениям,
	/// "fan" - дробовый веер в цель, "cross" - вращающийся ксеновый крест.
	var/list/attack_cycle = list("meteor", "tesla", "spiral", "dir", "fan", "cross")
	var/attack_cycle_pos = 0
	/// Идёт ли сейчас атака-крест (длится ~10 секунд, OpenFire молчит).
	var/cross_active = FALSE
	/// Кулдаун креста: реже остальных атак, иначе он выпадал бы каждый цикл.
	var/next_cross_time = 0
	/// Активный эффект креста - снимается при старте испытания.
	var/obj/effect/nihilanth_cross/cross_effect

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

// Босс - стационарная турель: ИИ-лупы, увороты, сайдстепы и блуждание
// ходят через Move()/step(), поэтому вето здесь глушит всё добровольное
// движение разом. forceMove()/doMove() (броски, телепорты, админка) этот
// прок не проходит - физику не трогаем. Пока loc пуст (спавн через new),
// решение остаётся за родителем.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/Move(atom/newloc, direct = 0, glide_size_override = 0)
	if(loc && !QDELETED(src))
		return FALSE
	return ..()

/obj/item/stack/sheet/bluespace_crystal/fifty
	amount = 50

// =============================================================================
// АТАКИ
// =============================================================================

// Шесть атак по кругу: "meteor" - залп xen blast (копия benrey-метеорита),
// "tesla" - разряд xen shock, который на попадании бьёт током несколько целей,
// "spiral"/"dir"/"fan" - ксеновые болты паттернами колосса, "cross" - вращающийся
// ксеновый крест (длительная атака, OpenFire на её время замолкает).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/OpenFire(atom/A)
	if(trial_active || stat == DEAD || QDELETED(A) || cross_active)
		return FALSE
	var/style = attack_cycle[attack_cycle_pos]
	attack_cycle_pos = (attack_cycle_pos + 1) % attack_cycle.len
	// Крест - редкая затяжная атака: на кулдауне цикл идёт обычным залпом,
	// не срывая ритм боя и не пропуская ход.
	if(style == "cross" && world.time < next_cross_time)
		style = "meteor"
	switch(style)
		if("tesla")
			projectiletype = /obj/item/projectile/energy/tesla/xen_shock
			projectilesound = 'sound/magic/lightningbolt.ogg'
			ranged_message = "discharges a xen shock"
			rapid = 1
			return ..()
		if("spiral")
			ranged_cooldown = world.time + 120
			INVOKE_ASYNC(src, PROC_REF(spiral_volley))
			return TRUE
		if("dir")
			ranged_cooldown = world.time + 90
			INVOKE_ASYNC(src, PROC_REF(dir_barrage))
			return TRUE
		if("fan")
			ranged_cooldown = world.time + 70
			INVOKE_ASYNC(src, PROC_REF(fan_barrage), A)
			return TRUE
		if("cross")
			if(start_cross())
				return TRUE
			style = "meteor" // крест не встал - обычный залп
	// "meteor" (и fallback с "cross")
	projectiletype = /obj/item/projectile/bullet/shotgun_meteorslug/nihilanth_blast
	projectilesound = 'modular_bluemoon/sound/weapons/mesa/sweetvoice.ogg'
	ranged_message = "hurls nihilanth blasts"
	rapid = 3
	return ..()

// Босс может стрелять, только пока жив, не в испытании и не занят крестом.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/can_attack_now()
	return !QDELETED(src) && stat != DEAD && !trial_active && istype(get_turf(src), /turf)

// Телеграф тяжёлой атаки: красная вспышка и тряска камеры игрокам рядом,
// как telegraph() колосса перед спиралью.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/telegraph()
	for(var/mob/M in range(12, src))
		if(M.client)
			flash_color(M.client, "#C80000", 1)
			shake_camera(M, 4, 3)
	playsound(src, 'sound/magic/lightningbolt.ogg', 100, FALSE)

// Один ксеновый болт nihilanth blast. mark - атом/турф, в который целится
// preparePixelProjectile (original для логов); set_angle - явный угол
// (спираль/веер), перебивает прицел.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/shoot_bolt(atom/mark, set_angle)
	if(!can_attack_now())
		return FALSE
	var/turf/startloc = get_turf(src)
	if(!istype(startloc))
		return FALSE
	var/obj/item/projectile/P = new /obj/item/projectile/bullet/shotgun_meteorslug/nihilanth_blast(startloc)
	if(QDELETED(P))
		return FALSE
	P.firer = src
	P.fired_from = src
	P.starting = startloc
	// Спавним болт из центра тайла босса, а не из его угла.
	P.pixel_x = world.icon_size >> 1
	P.pixel_y = world.icon_size >> 1
	if(istype(mark) && !QDELETED(mark))
	{
		P.original = mark
		P.preparePixelProjectile(mark, src)
	}
	else if(istype(target) && !QDELETED(target))
		P.original = target
	if(isnum(set_angle))
		P.fire(set_angle)
	else
		P.fire()
	return TRUE

// Спиральный шторм (spiral_shoot колосса): болты разлетаются по спирали
// во все стороны - угрозой становится всё пространство вокруг босса.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/spiral_volley(negative = FALSE)
	var/turf/startloc = get_turf(src)
	if(!istype(startloc) || !can_attack_now())
		return
	telegraph()
	visible_message("<span class='boldwarning'>[src] начинает ксено-вихрь!</span>")
	var/angle = rand(0, 359)
	var/angle_step = negative ? -22.5 : 22.5
	for(var/i in 1 to 56)
	{
		if(!can_attack_now())
			return
		shoot_bolt(null, angle)
		angle += angle_step
		playsound(startloc, 'sound/magic/lightningbolt.ogg', 25, 1)
		sleep(2)
	}

// Канонада по четырём диагоналям, затем по кардиналам (alternating_dir_shots
// колосса) - закрывает прямые лучи по линии арен.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/dir_barrage()
	var/turf/startloc = get_turf(src)
	if(!istype(startloc) || !can_attack_now())
		return
	telegraph()
	visible_message("<span class='boldwarning'>[src] наводит ксеновые лучи!</span>")
	sleep(10)
	if(!can_attack_now())
		return
	dir_barrage_pass(GLOB.diagonals)
	sleep(10)
	if(!can_attack_now())
		return
	dir_barrage_pass(GLOB.cardinals)

/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/dir_barrage_pass(list/dirs)
	var/turf/startloc = get_turf(src)
	if(!istype(startloc))
		return
	for(var/d in dirs)
	{
		if(!can_attack_now())
			return
		var/turf/E = get_step(src, d)
		if(istype(E))
			shoot_bolt(E)
		playsound(startloc, 'sound/magic/lightningbolt.ogg', 40, 1)
		sleep(2)
	}

// Дробовый веер в цель (blast колосса): веер из 7 болтов с разбросом по
// дуге вокруг линии на цель - наказывает стоящего на месте.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/fan_barrage(atom/mark)
	var/turf/startloc = get_turf(src)
	var/turf/MT = get_turf(mark)
	if(!istype(startloc) || !istype(MT) || MT.z != startloc.z || !can_attack_now())
		return
	telegraph()
	visible_message("<span class='boldwarning'>[src] собирает ксеновый залп!</span>")
	sleep(10)
	if(!can_attack_now())
		return
	var/base_angle = get_projectile_angle(startloc, MT)
	var/static/list/fan_offsets = list(-15, -10, -5, 0, 5, 10, 15)
	for(var/off in fan_offsets)
	{
		if(!can_attack_now())
			return
		shoot_bolt(MT, base_angle + off)
		playsound(startloc, 'sound/magic/lightningbolt.ogg', 40, 1)
		sleep(1)
	}

// Вращающийся ксеновый крест - "раскрутка" гладиатора, но ксеновая и
// дальнобойная: лучи не врут мобам Mesa и не задевают щиты/кристаллы -
// это чисто анти-пехотная атака (см. /obj/effect/nihilanth_cross).
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/start_cross()
	if(cross_active || world.time < next_cross_time)
		return FALSE
	var/turf/CT = get_turf(src)
	if(!istype(CT))
		return FALSE
	cross_active = TRUE
	next_cross_time = world.time + 150
	// Кулдаун покрывает всю длительность креста - после него цикл продолжает
	// обычные атаки без немедленного повтора креста.
	ranged_cooldown = world.time + 100
	var/obj/effect/nihilanth_cross/C = new /obj/effect/nihilanth_cross(CT)
	if(QDELETED(C))
	{
		cross_active = FALSE
		return FALSE
	}
	C.boss = src
	C.faction = faction.Copy()
	cross_effect = C
	visible_message("<span class='boldwarning'>[src] разрывает реальность - ксено-крест начинает вращаться!</span>")
	telegraph()
	return TRUE

// Снять активный крест (испытание/смерть босса): сам эффект тоже гаснет
// сам по проверке boss в cross_tick, но здесь он уходит мгновенно.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/stop_cross()
	if(istype(cross_effect) && !QDELETED(cross_effect))
		qdel(cross_effect)
	cross_effect = null
	cross_active = FALSE

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
	// Портал встаёт в небольшом радиусе вокруг босса, но не ровно под ним:
	// get_turf(src) у летающего моба - турф прямо под спрайтом.
	// Увеличенный радиус: разлом не должен вставать вплотную под боссом -
	// игроки выходили бы прямо под ним и подставлялись под следующий залп.
	var/turf/home = rift_turf_near(src, 8)
	// Свободных турфов в радиусе может не оказаться - тогда обычный поиск.
	if(!istype(home))
		home = free_turf_near(src, 8)
	if(!istype(home) || !isopenturf(home) || home.density)
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
	// Крест - боевая атака: на время испытания босс не атакует, эффект гасим.
	stop_cross()

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

// Тот же фильтр, что у free_turf_near, но исключает турф под самим мобом
// и турфы с уже стоящим порталом: разлом не должен вставать под боссом
// или накладываться на чужой.
/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/proc/rift_turf_near(atom/center, range = 4)
	if(!center || QDELETED(center))
		return null
	var/turf/CT = get_turf(center)
	if(!istype(CT))
		return null
	var/list/turfs = list()
	for(var/turf/T in view(range, CT))
		if(T == CT || T.z != CT.z)
			continue
		if(!valid_rift_turf(T) || turf_has_portal(T))
			continue
		turfs += T
	return pick(turfs)

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
	mesa_boss_zone_reward(src)
	// Триальный разлом не должен переживать босса - иначе он остаётся
	// на арене и шлёт игроков на точку уже пройденного испытания.
	if(istype(trial_portal) && !QDELETED(trial_portal))
		qdel(trial_portal)
	trial_portal = null
	// Активный крест не должен бить послемортально - эффект сам гаснет
	// по проверке boss.stat == DEAD, но гасим его сразу.
	stop_cross()
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
	var/portal_type = /obj/effect/portal/mesa_rift/nihilanth_rift
	if(landmark_type == /obj/effect/landmark/awaymission/blackmesa/nihilanth_exit)
		portal_type = /obj/effect/portal/mesa_rift/nihilanth_rift/exit
	else if(landmark_type == /obj/effect/landmark/awaymission/blackmesa/nihilanth_complex)
		portal_type = /obj/effect/portal/mesa_rift/nihilanth_rift/complex
	var/obj/effect/portal/P = null
	for(var/turf/cand in candidates)
		var/obj/effect/portal/try_P = new portal_type(cand)
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

// "nihilanth blast" - бывший "xen blast" (копия benrey-метеорита: тот же
// урон/иконка), но без нокдауна - попадание лишь швыряет цель в сторону.
// У benrey свой снаряд "deadly mesa sweet voice" с knockdown - не тронут.
/obj/item/projectile/bullet/shotgun_meteorslug/nihilanth_blast
	name = "nihilanth blast"
	desc = "A slug of condensed xen energy."
	knockdown = 0
	// Залп проходит сквозь барьер арены и кристаллы-питатели - они
	// плотные, но помечены PASSNIHILANTH именно для снарядов босса.
	pass_flags = PASSTABLE | PASSNIHILANTH

// "xen shock" - разряд на манер удара xen shockplant: при попадании
// tesla_zap прыгает на несколько целей вокруг точки удара.
/obj/item/projectile/energy/tesla/xen_shock
	name = "xen shock"
	desc = "A bolt of raw xen energy that arcs between targets."
	power = 30000
	pass_flags = PASSTABLE | PASSNIHILANTH
	zap_range = 6
	zap_flags = ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE | ZAP_MOB_STUN

// =============================================================================
// КРЕСТ НИХИЛАНТА - "раскрутка" как у гладиатора, но ксеновая
// =============================================================================

// Гигантский ксеновый крест (~15 тайлов в размахе): два перпендикулярных
// луча медленно вращаются вокруг босса. Урон получают ТОЛЬКО живые мобы вне
// фракции Нихиланта: ксено-фауна Mesa (isxenmob) и союзники по фракции не
// страдают, а объекты - щитовые/aegis-пилоны и ксено-кристаллы - не трогаются
// вовсе, потому что apply_damage зовётся исключительно на /mob/living.
// Сам объект невидим: каждый кадр на турфах лучей остаются ксеновые брызги,
// поворачивающиеся вместе с крестом.
/obj/effect/nihilanth_cross
	name = "xen cross"
	desc = "Сырой ксеновый крест, медленно вращающийся вокруг Нихиланта."
	anchored = TRUE
	density = FALSE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/boss
	var/list/faction = list()
	/// Полуразмах луча в тайлах: концы в 7 клетках от центра, крест ~15 тайлов.
	var/arm_reach = 7
	/// Тиков между кадрами поворота: 8 направлений * 1.2с = оборот ~10 секунд.
	var/frame_interval = 12
	var/frame_timer
	var/frames_done = 0
	var/max_frames = 8
	/// Каденс повторного урона по одному и тому же мобу (~2 секунды).
	var/hit_cooldown = 20
	var/alist/last_hits = alist()
	var/damage = 35
	/// Поворот по часовой: N -> NE -> E -> ... - гарантированный порядок,
	/// не зависящий от раскладки GLOB.alldirs.
	var/static/list/spin_dirs = list(NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST)
	var/spin_index = 0
	/// Текущие лучи креста: list(направление_луча, направление_перпендикуляра).
	var/list/cross_dirs = list()
	/// Турфы креста текущего кадра: list(list(турф, направление_луча)).
	var/list/cross_tiles = list()

/obj/effect/nihilanth_cross/Initialize(mapload)
	. = ..()
	spin_index = rand(0, spin_dirs.len - 1)
	// Первый кадр - на ближайшем cross_tick: босс и фракция присваиваются
	// сразу после new(), до срабатывания таймера.
	schedule_frame(2)

/obj/effect/nihilanth_cross/proc/schedule_frame(delay = frame_interval)
	frame_timer = addtimer(CALLBACK(src, PROC_REF(cross_tick)), delay, TIMER_STOPPABLE)

/obj/effect/nihilanth_cross/proc/cross_tick()
	frame_timer = null
	var/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/B = boss
	if(!istype(B) || QDELETED(B) || B.stat == DEAD || B.trial_active)
	{
		qdel(src)
		return
	}
	frames_done++
	if(frames_done > max_frames)
	{
		qdel(src)
		return
	}
	advance_frame()
	schedule_frame()

// Один кадр креста: следующий угол поворота, пересчёт турфов, визуал и удар.
/obj/effect/nihilanth_cross/proc/advance_frame()
	spin_index = (spin_index + 1) % spin_dirs.len
	var/dir = spin_dirs[spin_index]
	cross_dirs = list(dir, turn(dir, 90))
	recompute_tiles()
	spawn_arm_visuals()
	strike()

// Два перпендикулярных луча от центра до arm_reach тайлов в каждую сторону.
/obj/effect/nihilanth_cross/proc/recompute_tiles()
	cross_tiles.Cut()
	var/turf/CT = loc
	if(!istype(CT))
		CT = get_turf(boss)
	if(!istype(CT))
		return
	cross_tiles += list(CT, pick(cross_dirs))
	for(var/d in cross_dirs)
	{
		var/turf/T = CT
		for(var/i in 1 to arm_reach)
		{
			var/atom/step_result = get_step(T, d)
			if(!istype(step_result, /turf))
				break
			T = step_result
			cross_tiles += list(T, d)
		}
	}

// Ксеновые брызги на каждом турфе луча: живут ~1.5с, кадры пересекаются -
// крест выглядит сплошным вращающимся символом.
/obj/effect/nihilanth_cross/proc/spawn_arm_visuals()
	for(var/entry as anything in cross_tiles)
	{
		var/turf/T = entry[1]
		var/dir = entry[2]
		new /obj/effect/temp_visual/dir_setting/bloodsplatter/xenosplatter/nihilanth_arm(T, dir)
	}

// Урон по живым мобам в турфах креста. Союзники Нихиланта и вся ксено-фауна
// Mesa пропускаются по фракции/рода; объекты не задеваются в принципе.
/obj/effect/nihilanth_cross/proc/strike()
	var/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/B = boss
	if(!istype(B) || !length(faction))
		return
	for(var/entry as anything in cross_tiles)
	{
		var/turf/T = entry[1]
		for(var/mob/living/M in T)
		{
			if(QDELETED(M) || M.stat == DEAD || M == B)
				continue
			if(isxenmob(M) || faction_check(faction, M.faction))
				continue
			if(world.time - (last_hits[M] || 0) < hit_cooldown)
				continue
			last_hits[M] = world.time
			if(M.apply_damage(damage, BRUTE, BODY_ZONE_CHEST, M.run_armor_check(BODY_ZONE_CHEST)))
				M.visible_message("<span class='danger'>Ксено-крест [B] прошивает [M]!</span>", "<span class='userdanger'>Ксено-крест [B] прошивает тебя!</span>")
		}
	}

/obj/effect/nihilanth_cross/Destroy()
	if(frame_timer)
		deltimer(frame_timer)
	var/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/B = boss
	if(istype(B) && !QDELETED(B) && B.cross_effect == src)
	{
		B.cross_effect = null
		B.cross_active = FALSE
	}
	boss = null
	faction = null
	cross_tiles = null
	last_hits = null
	return ..()

// След ксено-энергии на турфах луча: живёт ~1.5с, чтобы кадры креста
// (раз в 1.2с) перекрывали друг друга и крест читался сплошным.
/obj/effect/temp_visual/dir_setting/bloodsplatter/xenosplatter/nihilanth_arm
	duration = 15

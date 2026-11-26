/obj/structure/shockplant
	name = "Strange xen plant"
	desc = "Невероятно искрит! Не рекомендую подходить к нему слишком близко"
	icon = 'modular_bluemoon/icons/obj/structures/mesa_plants.dmi'
	icon_state = "electric_plant"
	density = TRUE
	anchored = TRUE
	max_integrity = 100
	light_range = 15
	light_power = 0.5
	light_color = "#53fafa"
	light_flags = LIGHT_NO_RANGE_CAP // статичная декорация away-mission: дальность выше базового капа
	var/faction = ROLE_SYNDICATE
	var/shock_range = 6
	var/shock_cooldown = 3 SECONDS
	var/shock_power = 10000
	COOLDOWN_DECLARE(shock_cooldown_timer)

/obj/structure/shockplant/Initialize(mapload)
	. = ..()
	for(var/turf/open/iterating_turf as anything in circle_view_turfs(src, shock_range))
		RegisterSignal(iterating_turf, COMSIG_ATOM_ENTERED, PROC_REF(trigger))

/obj/structure/shockplant/proc/trigger(datum/source, atom/movable/entered_atom)
	SIGNAL_HANDLER

	if(!COOLDOWN_FINISHED(src, shock_cooldown_timer))
		return

	if(isliving(entered_atom))
		var/mob/living/entering_mob = entered_atom
		if(faction in entering_mob.faction)
			return
		tesla_zap(src, shock_range, shock_power, shocked_targets = list(entering_mob))
		playsound(src, 'sound/magic/lightningbolt.ogg', 100, TRUE)
		COOLDOWN_START(src, shock_cooldown_timer, shock_cooldown)



/proc/circle_view_turfs(center=usr,radius=3)

	var/turf/center_turf = get_turf(center)
	var/list/turfs = new/list()
	var/rsq = radius * (radius + 0.5)

	for(var/turf/checked_turf in view(radius, center_turf))
		var/dx = checked_turf.x - center_turf.x
		var/dy = checked_turf.y - center_turf.y
		if(dx * dx + dy * dy <= rsq)
			turfs += checked_turf
	return turfs

/obj/structure/sink/puddle/healing
	name = "healing puddle"
	desc = "By some otherworldy power, this puddle of water seems to slowly regenerate things!"
	color = "#71ffff"
	light_range = 3
	light_color = "#71ffff"
	var/heal_amount = 2

/obj/structure/sink/puddle/healing/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/sink/puddle/healing/process(seconds_per_tick)
	for(var/mob/living/iterating_mob in loc)
		iterating_mob.heal_overall_damage(heal_amount, heal_amount)

/obj/structure/healstation
	name = "health station"
	desc = "wall-mounted devices that give a limited amount of health and power. They are found throughout the Black Mesa Research Facility"
	light_range = 3
	light_color = "#71ffff"
	var/heal_amount = 5
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "aid"

/obj/structure/healstation/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/healstation/process(seconds_per_tick)
	for(var/mob/living/iterating_mob in loc)
		iterating_mob.heal_overall_damage(heal_amount, heal_amount)

/mob/living/simple_animal/hostile/blackmesa/xen
	var/can_be_shielded = TRUE
	var/shielded = FALSE
	var/shield_count = 0

/mob/living/simple_animal/hostile/blackmesa/xen/update_overlays()
	. = ..()
	if(shielded)
		. += mutable_appearance('icons/effects/effects.dmi', "shield-yellow", MOB_SHIELD_LAYER)

/mob/living/simple_animal/hostile/blackmesa/xen/proc/lose_shield()
	shield_count--
	if(shield_count <= 0)
		shielded = FALSE
		update_appearance()

/mob/living/simple_animal/hostile/blackmesa/xen/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE, spread_damage = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = NONE, attack_direction = null, attacking_item)
	if(shielded)
		balloon_alert_to_viewers("ineffective!")
		return FALSE
	return ..()

/obj/structure/sign/flag/blackmesa
	name = "black mesa flag"
	desc = "The Black Mesa Research Facility, or B.M.R.F. for short, and colloquially known as Black Mesa, was a scientific research complex built around an abandoned Cold War ICBM launch silo in the New Mexico desert in the United States"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	icon_state = "flag_mesa"
	item_flag = /obj/item/sign/flag

/obj/item/sign/flag/blackmesa
	name = "folded flag of Black mesa"
	desc = "The folded flag of Black mesa."
	icon_state = "folded_mesa"
	icon = 'modular_bluemoon/icons/obj/urbanism/urbanism.dmi'
	sign_path = /obj/structure/sign/flag/blackmesa


/obj/structure/xen_pylon
	name = "shield plant"
	desc = "It seems to be some kind of force field generator."
	icon = 'modular_bluemoon/icons/obj/structures/mesa_plants.dmi'
	icon_state = "crystal_pylon"
	max_integrity = 70
	density = TRUE
	anchored = TRUE
	/// The range at which we provide shield support to a mob.
	var/shield_range = 5
	/// A list of mobs we are currently shielding with attached beams.
	var/list/shielded_mobs = list()
	var/next_shield_check = 0
	/// Каденс повторного скана радиуса: beam щита живёт 10 минут и
	/// самоудаляется - без ре-сscана моб терял неуязвимость, оставаясь
	/// в радиусе живого пилона.
	var/next_shield_scan = 0

/obj/structure/xen_pylon/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	for(var/mob/living/simple_animal/hostile/blackmesa/xen/iterating_mob in range(shield_range, src))
		if(!iterating_mob.can_be_shielded)
			continue
		register_mob(iterating_mob)
	for(var/turf/iterating_turf in RANGE_TURFS(shield_range, src))
		RegisterSignal(iterating_turf, COMSIG_ATOM_ENTERED, PROC_REF(mob_entered_range))

/obj/structure/xen_pylon/proc/mob_entered_range(datum/source, atom/movable/entered_atom)
	SIGNAL_HANDLER
	if(!isxenmob(entered_atom))
		return
	var/mob/living/simple_animal/hostile/blackmesa/xen/entered_xen_mob = entered_atom
	if(!entered_xen_mob.can_be_shielded)
		return
	register_mob(entered_xen_mob)

/obj/structure/xen_pylon/proc/register_mob(mob/living/simple_animal/hostile/blackmesa/xen/mob_to_register)
	if(mob_to_register in shielded_mobs)
		return
	if(!istype(mob_to_register))
		return
	shielded_mobs += mob_to_register
	mob_to_register.shielded = TRUE
	mob_to_register.shield_count++
	mob_to_register.update_appearance()
	var/datum/beam/created_beam = Beam(mob_to_register, icon_state = "red_lightning", time = 10 MINUTES, maxdistance = (shield_range - 1), beam_sleep_time = 10)
	shielded_mobs[mob_to_register] = created_beam
	RegisterSignal(created_beam, COMSIG_QDELETING, PROC_REF(beam_died), override = TRUE)
	RegisterSignal(mob_to_register, COMSIG_QDELETING, PROC_REF(mob_died), override = TRUE)

/obj/structure/xen_pylon/proc/mob_died(atom/movable/source, force)
	SIGNAL_HANDLER
	var/datum/beam/beam = shielded_mobs[source]
	shielded_mobs[source] = null
	shielded_mobs -= source
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	if(istype(beam))
		UnregisterSignal(beam, COMSIG_QDELETING)
	if(!QDELETED(beam))
		QDEL_NULL(beam)

/obj/structure/xen_pylon/proc/beam_died(datum/beam/beam_to_kill)
	SIGNAL_HANDLER
	for(var/mob/living/simple_animal/hostile/blackmesa/xen/iterating_mob as anything in shielded_mobs.Copy())
		if(shielded_mobs[iterating_mob] == beam_to_kill)
			// Не зовём remove_shield: он QDEL'ит луч, а луч уже умирает -
			// этот обработчик и есть его COMSIG_QDELETING.
			UnregisterSignal(iterating_mob, COMSIG_PARENT_QDELETING)
			iterating_mob.lose_shield()
			shielded_mobs[iterating_mob] = null
			shielded_mobs -= iterating_mob

// Щит держится только пока моб в радиусе и на линии видимости - как medbeam,
// который перестаёт лечить при потере цели. Без этой проверки моб уходил за
// стену, а луч и неуязвимость оставались навсегда.
/obj/structure/xen_pylon/process(seconds_per_tick)
	if(shielded_mobs && shielded_mobs.len && world.time >= next_shield_check)
		next_shield_check = world.time + 10
		for(var/mob/living/simple_animal/hostile/blackmesa/xen/iterating_mob as anything in shielded_mobs.Copy())
			if(QDELETED(iterating_mob) || iterating_mob.stat == DEAD || get_dist(src, iterating_mob) > shield_range || !shield_los(iterating_mob))
				remove_shield(iterating_mob)
	// Ре-скан радиуса: ловит ксеномобов, у которых beam щита истёк
	// (time = 10 MINUTES в register_mob) или сигнал входа был потерян.
	if(world.time >= next_shield_scan)
		next_shield_scan = world.time + 50
		for(var/mob/living/simple_animal/hostile/blackmesa/xen/M in range(shield_range, src))
			if(M.can_be_shielded && M.stat != DEAD && !(M in shielded_mobs) && shield_los(M))
				register_mob(M)

/obj/structure/xen_pylon/proc/remove_shield(mob/living/simple_animal/hostile/blackmesa/xen/mob_to_unshield)
	if(!(mob_to_unshield in shielded_mobs))
		return
	var/datum/beam/beam = shielded_mobs[mob_to_unshield]
	shielded_mobs[mob_to_unshield] = null
	shielded_mobs -= mob_to_unshield
	// Снимаем свои подписки: signal_procs пилона иначе держит сильные
	// ссылки на каждого моба/луч, что когда-либо входил в радиус.
	UnregisterSignal(mob_to_unshield, COMSIG_PARENT_QDELETING)
	if(istype(beam))
		UnregisterSignal(beam, COMSIG_QDELETING)
	if(!QDELETED(beam))
		QDEL_NULL(beam)
	if(istype(mob_to_unshield) && !QDELETED(mob_to_unshield))
		mob_to_unshield.lose_shield()

/obj/structure/xen_pylon/proc/shield_los(atom/movable/A)
	var/turf/T1 = get_turf(src)
	var/turf/T2 = get_turf(A)
	if(!istype(T1) || !istype(T2) || T1.z != T2.z)
		return FALSE
	for(var/turf/T in getline(T1, T2))
		if(T == T1 || T == T2)
			continue
		if(T.opacity || T.density)
			return FALSE
		for(var/atom/movable/AM in T)
			if(AM == src || AM == A || AM.invisibility > SEE_INVISIBLE_LIVING)
				continue
			if(AM.opacity || AM.density)
				return FALSE
	return TRUE

/obj/structure/xen_pylon/Destroy()
	STOP_PROCESSING(SSobj, src)
	// Снимаем подписки COMSIG_ATOM_ENTERED с турфов радиуса - иначе на
	// каждом турфе остаётся PROC_REF на удалённый пилон.
	var/turf/self_turf = get_turf(src)
	if(istype(self_turf))
		for(var/turf/T in RANGE_TURFS(shield_range, self_turf))
			UnregisterSignal(T, COMSIG_ATOM_ENTERED)
	for(var/mob/living/simple_animal/hostile/blackmesa/xen/iterating_mob as anything in shielded_mobs.Copy())
		if(!QDELETED(iterating_mob))
			iterating_mob.lose_shield()
		var/datum/beam/beam = shielded_mobs[iterating_mob]
		shielded_mobs[iterating_mob] = null
		shielded_mobs -= iterating_mob
		if(!QDELETED(beam))
			QDEL_NULL(beam)
	shielded_mobs = null
	playsound(src, 'sound/magic/lightningbolt.ogg', 100, TRUE)
	new /obj/item/grenade/xen_crystal(get_turf(src))
	return ..()

// Пилон, которого призывает сам Нихилант: заметно живучее и с большим
// радиусом щита, чем обычный щитовой пилон на карте.
/obj/structure/xen_pylon/nihilanth_add
	name = "xen spire"
	desc = "A hardened xen pylon torn from the rift by Nihilanth."
	max_integrity = 250
	shield_range = 8

/obj/item/grenade/xen_crystal
	name = "xen crystal"
	desc = "A crystal with anomalous properties."
	icon = 'modular_bluemoon/icons/obj/structures/mesa_plants.dmi'
	icon_state = "crystal_grenade"
	/// What range do we effect mobs?
	var/effect_range = 6
	/// The faction we convert the mobs to
	var/faction = ROLE_SYNDICATE

/obj/item/grenade/xen_crystal/prime(mob/living/lanced_by)
	for(var/mob/living/mob_to_neutralize in view(src, effect_range))
		if(is_type_in_list(mob_to_neutralize))
			return
		mob_to_neutralize.faction |= ROLE_SYNDICATE
		mob_to_neutralize.visible_message(span_green("[mob_to_neutralize] is overcome by a wave of peace and tranquility!"))
		new /obj/effect/particle_effect/sparks/quantum(get_turf(mob_to_neutralize))
	qdel(src)

/datum/export/xen_crystal
	cost = CARGO_CRATE_VALUE * 6 //1200
	unit_name = "anomalous crystal sample"
	export_types = list(/obj/item/grenade/xen_crystal)
	include_subtypes = FALSE


//записки
/obj/item/paper/fluff/hologrid
	name = "Заметка"
	default_raw_text = "Слушай, Майк, я понимаю, что твоя система защиты, основанная на ящиках очень крутая... но прошу, перестань уже, блять, прятать его в тех тоннелях комплекса. Я уже написал жалобу... Тобишь! Ещё один такой инцидент - документ полетит прямиком в административный комплекс."

/obj/item/paper/fluff/blackmesahecu
	name = "У нас точно остались союзники?"
	default_raw_text = "Дальше располагается один из наших отрядов, но при виде нас они сразу открыли огонь. Меня сильно ранили, а мои, оставшиеся в отряде, отправились дальше по комплексу, так и не вернувшись. Я просто хочу домой."



//лампы

/obj/machinery/power/floodlight/lamppost/one/mesa
	icon_state = "one"
	number_of_lamps = 1
	light_power = 1.4
	layer = 4
	light_range = 15
	light_color = "#ffffdd"
	light_flags = LIGHT_NO_RANGE_CAP // статичный фонарь away-mission: собственный свет машины выше базового капа
	max_integrity = 9999999

//ключ карты

/obj/item/keycard/maincomplex
	name = "Ключ карта первого уровня"
	desc = "Даёт доступ к большинству закрытых дверей комплекса чёрной мезы. Нет! Вы не сможете открыть при помощи него путёвку в оригинальную black mesa"
	color = "#267a7a"
	puzzle_id = "main_complex"

/obj/item/keycard/utilization
	name = "Ключ карта второго уровня"
	desc = "Даёт доступ к техническим помещениям комплеса"
	color = "#479918"
	puzzle_id = "utilizationcomplex"


/obj/item/keycard/hevstorage
	name = "Ключ карта третьего уровня"
	desc = "Даёт доступ к хранилищам H.E.V. костюма"
	color = "#183099"
	puzzle_id = "hevstorage"

/obj/item/keycard/mesaend
	name = "Ключ карта четвёртого уровня"
	desc = "Ключ карта которая позволит тебе покинуть этот клятый комплекс раз и навсегда"
	color = "#7c8ee0"
	puzzle_id = "mesaend"

/obj/machinery/door/keycard/mesa
	color = "#7c8ee0"
	puzzle_id = "mesaend"
	open_message = "Дверь со скрежетом открывает вам дальнейший путь."

/obj/machinery/power/floodlight/urbanismlight/mesaoutside
	icon_state = "oldfloodlight_on"
	density = FALSE
	layer = 4
	light_range = 45
	light_color = 	"#1a130e"
	light_flags = LIGHT_NO_RANGE_CAP // статичный наружный прожектор: дальность выше базового капа (режется до LIGHTING_MAX_RANGE_STATIC)
	max_integrity = 9999999
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	invisibility = INVISIBILITY_ABSTRACT

/obj/machinery/power/floodlight/urbanismlight/mesamisc
	icon_state = "oldfloodlight_on"
	density = FALSE
	layer = 4
	light_range = 5
	light_color = 	"#f88d66"
	light_flags = LIGHT_NO_RANGE_CAP // статичный наружный прожектор: дальность выше базового капа (режется до LIGHTING_MAX_RANGE_STATIC)
	max_integrity = 9999999
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	invisibility = INVISIBILITY_ABSTRACT


// =============================================================================
// MESA RIFT PORTALS - постоянные порталы для карты. force_teleport унаследован
// от /obj/effect/portal/permanent и пробивает NOTELEPORT-зоны Black Mesa
// (как рифт смерти гантшипа). Двусторонний вариант: ставим два портала с
// одинаковым `id`. Односторонний: один портал + /obj/effect/landmark/portal_exit
// с тем же `id` в точке выхода - вернуться через портал нельзя.
// =============================================================================

/obj/effect/portal/permanent/mesa_rift
	name = "Black Mesa rift"
	desc = "Разрыв в реальности, мерцающий ксеновской энергией."
	mech_sized = TRUE

/obj/effect/portal/permanent/one_way/mesa_rift
	name = "Black Mesa rift"
	desc = "Односторонний разрыв в реальности. Обратного пути через него нет."
	mech_sized = TRUE

// =============================================================================
// NIHILANTH - боссовые разломы и точки испытания
// =============================================================================

// Рантайм-разлом Нихиланта: односторонний (hard_target + hardlinked = FALSE),
// force_teleport/mech_sized унаследованы от /obj/effect/portal/mesa_rift -
// пробивает NOTELEPORT-зоны Black Mesa.
/obj/effect/portal/mesa_rift/nihilanth_rift
	name = "nihilanth rift"
	desc = "Разлом, разорванный силой Нихиланта."
	teleport_channel = TELEPORT_CHANNEL_WORMHOLE

// Сам босс не должен проваливаться в собственный разлом испытания: портал
// стоит у него под ногами, а teleport() пропускает любого моба.
/obj/effect/portal/mesa_rift/nihilanth_rift/teleport(atom/movable/M, force = FALSE)
	if(istype(M, /mob/living/simple_animal/hostile/blackmesa/xen/nihilanth))
		return FALSE
	var/turf/rt = get_link_target_turf()
	var/turf/orig = get_turf(M)
	var/rt_str = istype(rt) ? "([rt.x],[rt.y],[rt.z])" : "null"
	var/ht_str = istype(hard_target) ? "([hard_target.x],[hard_target.y],[hard_target.z])" : "null"
	var/orig_str = istype(orig) ? "([orig.x],[orig.y],[orig.z])" : "null"
	log_world("NIHILANTH-RIFT: teleport mob=[M] from=[orig_str] real_target=[rt_str] hard_target=[ht_str] linked=[istype(linked)] hardlinked=[hardlinked]")
	return ..()

/obj/effect/portal/mesa_rift/nihilanth_rift/exit
	name = "Вернуться домой"

/obj/effect/portal/mesa_rift/nihilanth_rift/complex
	name = "Продолжить путь по комплексу"
	color = COLOR_RED

// Все особые ксено-пилоны саморегистрируются здесь - испытаниям Нихиланта
// не нужен проход по world (сотни тысяч атомов) ради горстки пилонов.
GLOBAL_VAR_INIT(nihilanth_pylons, list())
GLOBAL_VAR_INIT(nihilanth_sites, list())
GLOBAL_VAR_INIT(nihilanth_site_ids, list())
GLOBAL_VAR_INIT(nihilanth_site_used, list())
// Реестры защиты Нихиланта: кристаллы-питатели и барьерные щиты арены.
// Щиты убираются только когда список кристаллов пустеет полностью.
GLOBAL_VAR_INIT(nihilanth_crystals, list())
GLOBAL_VAR_INIT(nihilanth_barriers, list())

// Особый подвид ксено-пилона: aegis-щит для ЛЮБОГО живого существа в радиусе
// (игроки получают xen_aegis, блокирующий apply_damage), а не только для ксеномобов.
// Используется в испытаниях Нихиланта: пока пилон жив - щит держится, как у
// medbeam, и слетает при потере дистанции/линии видимости.
/obj/structure/xen_pylon/nihilanth
	name = "xen aegis pylon"
	desc = "Ксено-пилон особого типа: его поле окутывает щитом любого существа рядом."
	var/list/aegis_mobs = list()
	var/next_aegis_check = 0
	/// Босс, для которого этот пилон - цель испытания.
	var/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/nihilanth_boss
	/// Турф арены босса на момент старта испытания - нужен для обратного
	/// разлома, если босс будет удалён до end_trial().
	var/turf/trial_home
	var/trial_active = FALSE
	/// Триальный разлом босса: копия ссылки на случай, если босс будет
	/// удалён без death() - end_trial() тогда не вызовется, а портал
	/// обязан быть снят, иначе он продолжит телепортировать на старую точку.
	var/obj/effect/portal/trial_portal
	/// Каденс повторного скана радиуса для aegis-щита (см. parent process).
	var/next_aegis_scan = 0
	/// Пилон уже отработал в испытании - повторно не выбирается.
	var/used = FALSE
	/// ID испытания, с которым связан этот пилон. Совпадает с site_id
	/// лендмарка nihilanth_pylon_site. null = авто-привязка по z.
	var/site_id = null
	/// Лендмарк, к которому привязан пилон в текущем испытании -
	/// при уничтожении пилона он деактивируется (site_used = TRUE).
	var/obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site/linked_site

/obj/structure/xen_pylon/nihilanth/proc/set_linked_site(site)
	linked_site = istype(site, /obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site) ? site : null

/obj/structure/xen_pylon/nihilanth/Initialize(mapload)
	. = ..()
	GLOB.nihilanth_pylons += src
	// Родительский цикл регистрирует только ксеномобов через register_mob -
	// для остальных живых существ в радиусе делаем свой проход.
	for(var/mob/living/M in range(shield_range, src))
		if(isxenmob(M))
			continue
		register_aegis(M)

/obj/structure/xen_pylon/nihilanth/mob_entered_range(datum/source, atom/movable/entered_atom)
	// SIGNAL_HANDLER наследуется от родителя - повторный set линтер запрещает.
	if(!isliving(entered_atom))
		return
	var/mob/living/entered_mob = entered_atom
	if(entered_mob.stat == DEAD)
		return
	register_aegis(entered_mob)

/obj/structure/xen_pylon/nihilanth/register_mob(mob/living/mob_to_register)
	// Родительский Initialize зовёт этот прок для ксеномобов в радиусе -
	// подвид переводит всех на aegis-систему.
	register_aegis(mob_to_register)

/obj/structure/xen_pylon/nihilanth/proc/register_aegis(mob/living/M)
	if(QDELETED(M) || M.stat == DEAD || (M in aegis_mobs))
		return
	M.xen_aegis++
	// Луч живёт пока get_dist < maxdistance, а щит удерживается до
	// get_dist <= shield_range: даём +1, иначе на границе beam умирал,
	// aegis_beam_died снимал щит, а ре-скан выдавал его обратно - мерцание.
	var/datum/beam/created_beam = src.Beam(M, icon_state = "red_lightning", time = 10 MINUTES, maxdistance = (shield_range + 1), beam_sleep_time = 10)
	aegis_mobs[M] = created_beam
	RegisterSignal(created_beam, COMSIG_QDELETING, PROC_REF(aegis_beam_died), override = TRUE)
	RegisterSignal(M, COMSIG_QDELETING, PROC_REF(aegis_mob_died), override = TRUE)

/obj/structure/xen_pylon/nihilanth/proc/remove_aegis(mob/living/M)
	if(!(M in aegis_mobs))
		return
	var/datum/beam/beam = aegis_mobs[M]
	aegis_mobs[M] = null
	aegis_mobs -= M
	// Снимаем свои подписки: signal_procs пилона иначе держит сильные
	// ссылки на каждого моба/луч, что когда-либо входил в радиус.
	UnregisterSignal(M, COMSIG_PARENT_QDELETING)
	if(istype(beam))
		UnregisterSignal(beam, COMSIG_QDELETING)
	// Запись из assoc убираем ДО qdel луча: beam шлёт COMSIG_QDELETING,
	// aegis_beam_died находил моба всё ещё в списке и рекурсивно звал
	// remove_aegis -> qdel уже умирающего beam ("destroy proc was called
	// multiple times") и двойной декремент xen_aegis.
	if(!QDELETED(beam))
		QDEL_NULL(beam)
	if(istype(M) && !QDELETED(M))
		M.xen_aegis = max(M.xen_aegis - 1, 0)

/obj/structure/xen_pylon/nihilanth/proc/aegis_mob_died(atom/movable/source, force)
	SIGNAL_HANDLER
	remove_aegis(source)

/obj/structure/xen_pylon/nihilanth/proc/aegis_beam_died(datum/beam/beam_to_kill)
	SIGNAL_HANDLER
	for(var/mob/living/iterating_mob as anything in aegis_mobs.Copy())
		if(aegis_mobs[iterating_mob] == beam_to_kill)
			// Не зовём remove_aegis: он QDEL'ит луч, а луч уже умирает -
			// этот обработчик и есть его COMSIG_QDELETING.
			aegis_mobs[iterating_mob] = null
			aegis_mobs -= iterating_mob
			UnregisterSignal(iterating_mob, COMSIG_PARENT_QDELETING)
			if(!QDELETED(iterating_mob))
				iterating_mob.xen_aegis = max(iterating_mob.xen_aegis - 1, 0)

/obj/structure/xen_pylon/nihilanth/process(seconds_per_tick)
	if(aegis_mobs && aegis_mobs.len && world.time >= next_aegis_check)
		next_aegis_check = world.time + 10
		for(var/mob/living/iterating_mob as anything in aegis_mobs.Copy())
			if(QDELETED(iterating_mob) || iterating_mob.stat == DEAD || get_dist(src, iterating_mob) > shield_range || !shield_los(iterating_mob))
				remove_aegis(iterating_mob)
	// Ре-скан радиуса: beam aegis-щита живёт 10 минут и самоудаляется -
	// без повторной регистрации моб терял xen_aegis, оставаясь в радиусе.
	if(world.time >= next_aegis_scan)
		next_aegis_scan = world.time + 50
		for(var/mob/living/M in range(shield_range, src))
			if(M.stat != DEAD && !(M in aegis_mobs) && shield_los(M))
				register_aegis(M)

/obj/structure/xen_pylon/nihilanth/Destroy()
	GLOB.nihilanth_pylons -= src
	// Если босс удалён без death(), end_trial() не вызовется - снимаем
	// триальный разлом здесь, иначе он останется на арене навсегда.
	if(istype(trial_portal) && !QDELETED(trial_portal))
		qdel(trial_portal)
	trial_portal = null
	var/turf/self_turf = get_turf(src)
	for(var/mob/living/iterating_mob as anything in aegis_mobs.Copy())
		remove_aegis(iterating_mob)
	aegis_mobs = null
	var/mob/living/simple_animal/hostile/blackmesa/xen/nihilanth/boss = nihilanth_boss
	nihilanth_boss = null
	var/was_trial = trial_active
	var/turf/home_turf = trial_home
	var/obj/effect/landmark/awaymission/blackmesa/nihilanth_pylon_site/site = linked_site
	linked_site = null
	trial_active = FALSE
	trial_home = null
	// Пилон уничтожен - связанный лендмарк деактивируется: точка прибытия
	// больше не выбирается, следующий разлом ведёт к другим сайтам.
	if(istype(site) && !QDELETED(site))
		site.site_used = TRUE
		GLOB.nihilanth_site_used[site] = TRUE
	. = ..()
	if(was_trial)
		if(istype(boss) && !QDELETED(boss))
			boss.end_trial()
		else if(istype(self_turf) && isopenturf(self_turf) && istype(home_turf))
			// Босс уже удалён - end_trial() не вызвать, но игроки всё равно
			// должны получить обратный разлом, иначе застрянут на точке испытания.
			var/obj/effect/portal/R = new /obj/effect/portal/mesa_rift/nihilanth_rift(self_turf)
			if(istype(R))
				R.hard_target = home_turf
				R.hardlinked = FALSE
				playsound(self_turf, 'sound/effects/space_wind.ogg', 90, FALSE, -4)

#undef COMSIG_QDELETING

// =============================================================================
// NIHILANTH DEFENSE - кристаллы-питатели и неломаемый барьер арены
// =============================================================================

// Особый кристалл вокруг Нихиланта. Сам по себе никого не щитит - только
// питает барьерный щит арены: барьер стоит, пока жив хотя бы один кристалл,
// и рассыпается, когда разрушены все. Отдельный тип, а не подвид
// /obj/structure/xen_pylon, чтобы не раздавать ксеномобам aegis-щиты.
/obj/structure/xen_crystal_pylon
	name = "xen crystal"
	desc = "Кристалл, питающий защитный барьер Нихиланта."
	icon = 'icons/obj/supermatter.dmi'
	icon_state = "xencrystal"
	max_integrity = 300
	density = TRUE
	anchored = TRUE
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	// Снаряды самого Нихиланта проходят сквозь кристалл (их pass_flags
	// содержит PASSNIHILANTH) - кристаллы бьют только игроки.
	pass_flags_self = PASSNIHILANTH

/obj/structure/xen_crystal_pylon/Initialize(mapload)
	. = ..()
	GLOB.nihilanth_crystals += src

/obj/structure/xen_crystal_pylon/Destroy()
	var/list/crystals = GLOB.nihilanth_crystals
	crystals -= src
	if(!crystals.len)
		drop_nihilanth_barrier()
	. = ..()

/obj/structure/xen_crystal_pylon/proc/drop_nihilanth_barrier()
	var/turf/sound_turf = null
	var/list/barriers = GLOB.nihilanth_barriers
	for(var/obj/structure/emergency_shield/nihilanth/S in barriers.Copy())
		if(!QDELETED(S))
			if(!istype(sound_turf))
				sound_turf = get_turf(S)
			qdel(S)
	barriers.Cut()
	if(istype(sound_turf))
		playsound(sound_turf, 'sound/magic/lightningbolt.ogg', 100, TRUE)
	visible_message("<span class='boldwarning'>Все кристаллы Нихиланта разрушены - его барьер рассыпается!</span>")

// Неломаемый барьер арены Нихиланта: тот же тайл-щит, что у emergency
// shieldgen, но неуязвим и снимается только питателями-кристаллами.
/obj/structure/emergency_shield/nihilanth
	name = "nihilanth barrier"
	desc = "Непробиваемый энергетический барьер, удерживаемый кристаллами Нихиланта."
	max_integrity = 999999
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	// Барьер держит игроков снаружи, но собственные атаки Нихиланта
	// (nihilanth_blast / xen_shock с PASSNIHILANTH) проходят насквозь.
	pass_flags_self = PASSNIHILANTH

/obj/structure/emergency_shield/nihilanth/Initialize(mapload)
	. = ..()
	GLOB.nihilanth_barriers += src

/obj/structure/emergency_shield/nihilanth/Destroy()
	var/list/barriers = GLOB.nihilanth_barriers
	barriers -= src
	..()

/obj/structure/emergency_shield/nihilanth/emp_act(severity)
	return

/obj/structure/emergency_shield/nihilanth/take_damage(damage, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	return FALSE

#define GONARCH_CHARGE 1
#define GONARCH_SPAWN_CHILDREN 2
#define GONARCH_RAGE 3
#define GONARCH_CALL_CHILDREN 4
#define GONARCH_TRISHOT 5

// Elite mining boss ported to BlueMoon.
// Children are regular mesa headcrabs, acid shots reuse the spitter's
// /obj/item/projectile/neurotox/acid_spit (acid ooze on impact).

/mob/living/simple_animal/hostile/asteroid/elite/gonarch
	name = "gonarch"
	desc = "A massive monstrous creature that is completely alien in appearence. The sac dangling upon it churns with intensity, with creatures visibly pushing against it from within."
	gender = FEMALE
	faction = list(FACTION_XEN)
	icon = 'modular_bluemoon/icons/mob/gonarch.dmi'
	icon_state = "gonarch"
	icon_living = "gonarch"
	icon_aggro = "gonarch"
	icon_dead = "gonarch_dead"
	icon_gib = "syndicate_gib"
	pixel_x = -32
	base_pixel_x = -16
	health_doll_icon = "broodmother"
	maxHealth = 4000
	health = 4000
	obj_damage = 25
	melee_damage_lower = 20
	melee_damage_upper = 30
	armour_penetration = 30
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_verb_continuous = "beats down on"
	attack_verb_simple = "beat down on"
	attack_sound = 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchattack.ogg'
	death_sound = 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchroar.ogg'
	throw_message = "does nothing to the plated hide of the"
	speed = 2
	move_to_delay = 5
	move_resist = MOVE_FORCE_STRONG
	mob_biotypes = MOB_ORGANIC|MOB_BEAST|MOB_EPIC
	mouse_opacity = MOUSE_OPACITY_ICON
	deathmessage = "falls over with a final cry!"
	footstep_type = FOOTSTEP_MOB_HEAVY

	attack_action_types = list(/datum/action/innate/elite_attack/gonarch_charge,
								/datum/action/innate/elite_attack/gonarch_spawn_children,
								/datum/action/innate/elite_attack/gonarch_rage,
								/datum/action/innate/elite_attack/gonarch_trishot,
								/datum/action/innate/elite_attack/gonarch_call_children)

	var/list/atom/movable/children_list = list()
	var/charging = FALSE
	/// Дальность рывка и меток-предупреждений charge (как у bubblegum).
	charge_distance = 8
	var/thebaby = /mob/living/simple_animal/hostile/headcrab/mesa
	var/image/rage_tint = null
	/// Varspeed/move delay to restore after rage. Boss variant runs faster,
	/// so it overrides these instead of hardcoding the base values.
	var/normal_varspeed = 2
	var/normal_move_delay = 5

/datum/action/innate/elite_attack/gonarch_charge
	name = "Charge"
	button_icon_state = "tentacle_patch"
	chosen_message = span_boldwarning("You are now attempting to charge forward.")
	chosen_attack_num = GONARCH_CHARGE

/datum/action/innate/elite_attack/gonarch_trishot
	name = "Triple Shot"
	button_icon_state = "herald_trishot"
	chosen_message = span_boldwarning("You are now firing three acid blasts in your chosen direction.")
	chosen_attack_num = GONARCH_TRISHOT

/datum/action/innate/elite_attack/gonarch_spawn_children
	name = "Spawn Children"
	button_icon_state = "spawn_children"
	chosen_message = span_boldwarning("You will spawn six children at your location to assist you in combat. You can have up to 8.")
	chosen_attack_num = GONARCH_SPAWN_CHILDREN

/datum/action/innate/elite_attack/gonarch_rage
	name = "Rage"
	button_icon_state = "rage"
	chosen_message = span_boldwarning("You will temporarily increase your movement speed.")
	chosen_attack_num = GONARCH_RAGE

/datum/action/innate/elite_attack/gonarch_call_children
	name = "Call Children"
	button_icon_state = "call_children"
	chosen_message = span_boldwarning("You will summon your children to your location.")
	chosen_attack_num = GONARCH_CALL_CHILDREN

// Boss-profile attack table: weighted picks with per-ability cooldowns and
// ranges instead of the legacy rand() chain in OpenFire. Without it the AI
// only fires OpenFire through boss_legacy_ranged when the target is not
// adjacent, and the shared ranged_cooldown lets one long cooldown (rage)
// silence every other attack.
/mob/living/simple_animal/hostile/asteroid/elite/gonarch/can_use_ai_ability(atom/target)
	return !charging && !charge_state && !charge_windup_timer

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/build_ai_attack_table()
	var/list/table = list(
		new /datum/boss_attack("charge", PROC_REF(legionnaire_charge), 5 SECONDS, 10, 2, 10),
		new /datum/boss_attack("acid trishot", PROC_REF(herald_trishot), 3 SECONDS, 10),
		// На низком HP плевок идёт чаще и тяжелее: отдельная запись с фазовым
		// окном max_health_frac=0.30 и укороченным кулдауном - каденс растёт
		// через next_use_time записи, общий ranged_cooldown не участвует.
		new /datum/boss_attack("acid barrage", PROC_REF(herald_trishot), 2 SECONDS, 20, 0, INFINITY, 0, 0.30),
		new /datum/boss_attack("spawn children", PROC_REF(spawn_children), 12 SECONDS, 8),
		new /datum/boss_attack("rage", PROC_REF(rage), 25 SECONDS, 6),
		new /datum/boss_attack("call children", PROC_REF(call_children), 10 SECONDS, 6),
	)
	for(var/datum/boss_attack/entry as anything in table)
		// Кулдауны живут в записях (next_use_time): общий ranged_cooldown
		// не трогаем, иначе rage на 25с глушил бы все остальные способности.
		entry.sync_ranged_cooldown = FALSE
		if(entry.attack_proc in list(PROC_REF(legionnaire_charge), PROC_REF(herald_trishot), PROC_REF(spawn_children)))
			entry.pass_target = TRUE
	return table

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/Move()
	if(charging || charge_state || charge_windup_timer)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/death(gibbed)
	mesa_boss_zone_reward(src)
	. = ..(gibbed)
	// Children outlive the parent; detach our signal handlers so they don't
	// keep PROC_REFs to a deleted mob around until they die themselves.
	for(var/atom/movable/child in children_list)
		if(child && !QDELETED(child))
			UnregisterSignal(child, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
	children_list.Cut()

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/drop_loot()
	. = ..()
	var/turf/drop_turf = get_turf(src)
	if(!drop_turf)
		return
	var/obj/item/keycard/hevstorage/K = new /obj/item/keycard/hevstorage(drop_turf)
	K.desc = "Кажется, кому-то очень неповезло быть сожранным этой тварью. Но ключ целый! Открывает проход дальше"
	var/client/killer_client = GLOB.directory[lastattackerckey]
	if(killer_client)
		to_chat(killer_client, span_userdanger("Из гонарча вывалилась ключ карта!"))
	visible_message(span_userdanger("[lastattacker || "Кто-то"] вырвал из туши гонарча ключ карту!"))

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/OpenFire(atom/fire_target)
	if(client)
		switch(chosen_attack)
			if(GONARCH_CHARGE)
				legionnaire_charge(target)
			if(GONARCH_TRISHOT)
				herald_trishot(target)
			if(GONARCH_SPAWN_CHILDREN)
				spawn_children(target)
			if(GONARCH_RAGE)
				rage()
			if(GONARCH_CALL_CHILDREN)
				call_children()
		return
	var/aiattack = rand(1, 5)
	switch(aiattack)
		if(GONARCH_CHARGE)
			legionnaire_charge(target)
		if(GONARCH_TRISHOT)
			herald_trishot(target)
		if(GONARCH_SPAWN_CHILDREN)
			spawn_children(target)
		if(GONARCH_RAGE)
			rage()
		if(GONARCH_CALL_CHILDREN)
			call_children()

/// Charge: один рывок как у bubblegum - метки-предупреждения на всём пути,
/// затем throw_at в точку цели. Урон и отброс - в throw_impact, конец
/// броска - в charge_end (колбэк throw_at).
/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/legionnaire_charge(atom/target)
	if(QDELETED(src) || stat == DEAD || !target)
		return
	var/turf/T = get_turf(target)
	var/turf/home = get_turf(src)
	if(!T || !home || T == home)
		return
	visible_message(span_boldwarning("[src] опускает головой и готовится к рывку!"))
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchroar.ogg', 75, FALSE)
	// Метки на всём пути рывка - тот же приём, что у bubblegum/legionnaire,
	// но со спрайтом gonarch_warning (64x64).
	var/dir_to_target = get_dir(home, T)
	var/turf/mark_turf = home
	for(var/i in 1 to charge_distance)
		mark_turf = get_step(mark_turf, dir_to_target)
		if(!mark_turf)
			break
		new /obj/effect/temp_visual/dragon_swoop/gonarch(mark_turf)
	charging = TRUE
	DestroySurroundings()
	setDir(get_dir(src, T))
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(loc, src)
	animate(D, alpha = 0, color = "#FF0000", transform = matrix()*2, time = 5)
	sleep(5)
	if(QDELETED(src) || stat == DEAD)
		charge_end()
		return
	if(!throw_at(T, get_dist(src, T), 1, src, 0, callback = CALLBACK(src, PROC_REF(charge_end))))
		charge_end()

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/charge_end()
	if(QDELETED(src))
		return
	charging = FALSE
	update_icons()
	update_mobility()

/// Урон рывка: повторяет контракт /mob/living/simple_animal/hostile/throw_impact
/// для charge_state, добавляя урон/стан/отброс как у infected charger.
/mob/living/simple_animal/hostile/asteroid/elite/gonarch/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	// charging - наш bubblegum-стиль рывок, charge_state - легаси enter_charge.
	if(!charge_state && !charging)
		return ..()

	if(isliving(hit_atom) && hit_atom != src)
		var/mob/living/L = hit_atom
		visible_message(span_boldwarning("[src] врезается в [L]!"))
		to_chat(L, span_userdanger("[src] врезается в вас!"))
		playsound(get_turf(L), 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchattack.ogg', 100, TRUE)
		L.apply_damage(40, BRUTE)
		L.adjustStaminaLoss(40)
		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)
		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
		L.throw_at(throwtarget, 6, 1, src)
	else if(hit_atom && hit_atom.density && !hit_atom.CanPass(src, get_turf(hit_atom)))
		visible_message(span_boldwarning("[src] врезается в [hit_atom]!"))
		playsound(get_turf(src), 'sound/effects/bang.ogg', 100, TRUE)
		Stun(40)

	if(charge_state)
		charge_state = FALSE
	if(charging)
		charging = FALSE
	update_icons()
	update_mobility()

/// Fires one acid spit projectile at the marker turf. is_trishot adds two
/// extra shots at +/-15 degrees for the classic 3-way spread.
/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/shoot_projectile(turf/marker, set_angle, is_trishot = FALSE)
	var/turf/startloc = get_turf(src)
	if(!startloc || !marker || QDELETED(src))
		return
	var/obj/item/projectile/neurotox/acid_spit/gonarch/H = new /obj/item/projectile/neurotox/acid_spit/gonarch(startloc)
	H.preparePixelProjectile(marker, src)
	H.firer = src
	if(target)
		H.original = target
	H.fire(set_angle)
	if(is_trishot)
		shoot_projectile(marker, set_angle + 15, FALSE)
		shoot_projectile(marker, set_angle - 15, FALSE)

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/herald_trishot(atom/target)
	if(QDELETED(src) || stat == DEAD || !target)
		return
	// При HP < 30% плевок идёт чаще (2с вместо 3с - кулдаун записи
	// "acid barrage" в таблице) и выстреливает тремя залпами вместо одного.
	var/low_hp = health < maxHealth * 0.30
	var/startloc = get_turf(src)
	var/turf/target_turf = get_turf(target)
	if(!startloc || !target_turf)
		return
	playsound(startloc, 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchacidmortar.ogg', 20, FALSE)
	icon_state = "gonarch_attack"
	charging = TRUE
	var/angle_to_target = get_projectile_angle(src, target_turf)
	addtimer(CALLBACK(src, PROC_REF(herald_trishot_fire), target_turf, angle_to_target, low_hp ? 3 : 1), 5)

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/herald_trishot_fire(turf/marker, angle_to_target, volleys_left = 1)
	if(QDELETED(src) || stat == DEAD)
		charging = FALSE
		return
	shoot_projectile(marker, angle_to_target, TRUE)
	if(volleys_left > 1)
		addtimer(CALLBACK(src, PROC_REF(herald_trishot_fire), marker, angle_to_target, volleys_left - 1), 4)
		return
	charging = FALSE
	if(stat != DEAD)
		icon_state = "gonarch"

/// Spawns up to six mesa headcrabs near the gonarch, capped at 8 children.
/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/spawn_children(atom/target = null)
	if(QDELETED(src) || stat == DEAD)
		return
	var/turf/home = get_turf(src)
	if(!home)
		return
	visible_message(span_boldwarning("[src] strains as it gives birth!"))
	playsound(home, 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchbirth.ogg', 20, FALSE)
	for(var/i in 1 to 6)
		if(children_list.len >= 8)
			break
		var/turf/spawn_turf = get_free_adjacent_turf(home)
		if(!spawn_turf)
			spawn_turf = home
		var/mob/living/simple_animal/hostile/headcrab/mesa/new_child = new thebaby(spawn_turf)
		new_child.faction = faction.Copy()
		if(istype(target, /mob/living))
			new_child.GiveTarget(target)
		visible_message(span_boldwarning("[new_child] appears below [src]!"))
		register_child(new_child)

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/get_free_adjacent_turf(turf/home)
	var/list/directions = GLOB.cardinals.Copy()
	while(directions.len)
		var/turf/T = get_step(home, pick_n_take(directions))
		if(!T)
			continue
		var/blocked = FALSE
		for(var/atom/movable/A in T.contents)
			if(A.density)
				blocked = TRUE
				break
		if(!blocked)
			return T
	return null

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/register_child(atom/movable/child)
	children_list += child
	RegisterSignals(child, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(remove_child))

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/remove_child(atom/movable/source)
	SIGNAL_HANDLER

	children_list -= source
	UnregisterSignal(source, list(
		COMSIG_PARENT_QDELETING,
		COMSIG_LIVING_DEATH,
	))

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/rage()
	if(QDELETED(src) || stat == DEAD)
		return
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/gonarch/gonarchroar.ogg', 75, FALSE)
	visible_message(span_warning("[src] starts picking up speed!"))
	if(!rage_tint)
		rage_tint = image(icon, icon_state = "gonarch")
		rage_tint.color = COLOR_RED_LIGHT
		overlays += rage_tint
	set_varspeed(0)
	move_to_delay = 3
	addtimer(CALLBACK(src, PROC_REF(reset_rage)), 5 SECONDS)

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/reset_rage()
	if(QDELETED(src) || stat == DEAD)
		return
	if(rage_tint)
		overlays -= rage_tint
		rage_tint = null
	set_varspeed(normal_varspeed)
	move_to_delay = normal_move_delay

/mob/living/simple_animal/hostile/asteroid/elite/gonarch/proc/call_children()
	if(QDELETED(src) || stat == DEAD)
		return
	visible_message(span_warning("The ground shakes near [src]!"))
	var/list/directions = GLOB.cardinals.Copy() + GLOB.diagonals.Copy()
	var/summoned = FALSE
	for(var/atom/movable/child in children_list)
		if(QDELETED(child))
			continue
		var/spawndir = pick_n_take(directions)
		var/turf/T = get_step(src, spawndir)
		if(T)
			child.forceMove(T)
			summoned = TRUE
	if(summoned)
		playsound(src, 'sound/effects/bamf.ogg', 100, 1)

// Harder variant for manual/admin spawns. No deployment_faction system in
// this build - spawn it wherever you need it.
/mob/living/simple_animal/hostile/asteroid/elite/gonarch/boss
	maxHealth = 8000
	health = 8000
	move_to_delay = 3
	speed = 1
	normal_varspeed = 1
	normal_move_delay = 3
	obj_damage = 75
	melee_damage_lower = 25
	melee_damage_upper = 35

// Метка-предупреждение на пути рывка: тот же temp_visual, что у
// bubblegum/legionnaire, но спрайт gonarch_warning (64x64) из gonarch.dmi.
/obj/effect/temp_visual/dragon_swoop/gonarch
	name = "gonarch warning"
	desc = "Don't just stand there, move!"
	icon = 'modular_bluemoon/icons/mob/gonarch.dmi'
	icon_state = "gonarch_warning"
	pixel_x = -32
	pixel_y = -32
	color = "#FF0000"
	duration = 5

// Gonarch-flavored acid spit: slightly hotter than the regular spitter blob.
/obj/item/projectile/neurotox/acid_spit/gonarch
	name = "gonarch acid"
	damage = 20
	damage_type = BURN
	flag = "acid"

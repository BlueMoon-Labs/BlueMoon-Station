#define ANTAG_TRAINING_DEMON_POOL_CAP 10
#define ANTAG_TRAINING_DEMON_POOLS_PER_PRESS 3
#define ANTAG_TRAINING_DEMON_PREY_SLEEP (2 MINUTES)
#define ANTAG_TRAINING_DEMON_START_BLOOD "Начало: в крови"
#define ANTAG_TRAINING_DEMON_START_MANIFEST "Начало: проявленным"

/datum/antag_training_program/creature/slaughter
	name = "Демон резни"
	category = "Существа"
	desc = "Тело демона резни в тёмном секторе: погружение в лужи крови и выход из них, утаскивание и пир, удар-бросок, серия ран. После смерти съеденные выпадают, сердце демона не остаётся, а вы появляетесь новым демоном в центре сектора."
	icon = "skull"
	color = "red"
	learn = "Погружение в лужи крови и выход|Утаскивание и пир|Удар-бросок и серия ран|Возвращение новым демоном"
	difficulty = 2
	sector = "dark"
	mob_type = /mob/living/simple_animal/slaughter/training
	antag_type = /datum/antagonist/slaughter/training
	options = list("Полное здоровье", "Лужи крови рядом", "Цель для утаскивания", ANTAG_TRAINING_DEMON_START_BLOOD, ANTAG_TRAINING_DEMON_START_MANIFEST)
	var/start_in_blood = TRUE
	var/list/blood_pools = list()
	var/pool_cap = ANTAG_TRAINING_DEMON_POOL_CAP

/datum/antag_training_program/creature/slaughter/New()
	. = ..()
	var/datum/action/cooldown/slam/slam_type = /datum/action/cooldown/slam
	option_hints = list(
		"Полное здоровье" = "Здоровье до максимума и сброс задержки удара-броска ([initial(slam_type.cooldown_time) / (1 SECONDS)] с). В раунде демон лечится только пиром: утащить в кровь тело без сознания или мёртвое.",
		"Лужи крови рядом" = "Под вами и рядом появятся лужи крови ([ANTAG_TRAINING_DEMON_POOLS_PER_PRESS] шт.), в которые можно погрузиться. Работает и из крови. Программа держит не больше [ANTAG_TRAINING_DEMON_POOL_CAP] луж: новые убирают самые старые. Засохшая кровь, капли и масло для погружения не годятся.",
		"Цель для утаскивания" = "Рядом ляжет манекен без сознания на [ANTAG_TRAINING_DEMON_PREY_SLEEP / (1 MINUTES)] мин. Возьмите его (Ctrl+клик) и погрузитесь в лужу: он уйдёт в кровь вместе с вами, а пир вылечит демона. Очнувшийся вырвется у самой лужи. Съеденный остаётся в общем лимите целей. В центре и переходах кнопка не работает.",
		ANTAG_TRAINING_DEMON_START_BLOOD = "Новый демон появится в центре сектора уже в крови, как при появлении в раунде: выйти можно у любой лужи. Так же он будет появляться после смерти.",
		ANTAG_TRAINING_DEMON_START_MANIFEST = "Новый демон появится в центре сектора проявленным, на полу. Так же он будет появляться после смерти.",
	)

/datum/antag_training_program/creature/slaughter/Destroy()
	for(var/datum/weakref/pool_ref as anything in blood_pools)
		qdel(pool_ref.resolve())
	blood_pools = null
	return ..()

/datum/antag_training_program/creature/slaughter/spawn_creature_body(datum/antag_training_session/session, turf/where)
	. = ..()
	var/mob/living/simple_animal/slaughter/demon = .
	if(demon && start_in_blood)
		demon.training_sink()

/datum/antag_training_program/creature/slaughter/refill(mob/living/simple_animal/slaughter/body)
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	body.slam?.StartCooldownSelf(0)

/datum/antag_training_program/creature/slaughter/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	if(option == ANTAG_TRAINING_DEMON_START_BLOOD || option == ANTAG_TRAINING_DEMON_START_MANIFEST)
		var/previous = start_in_blood
		start_in_blood = option == ANTAG_TRAINING_DEMON_START_BLOOD
		if(!replace_body(session))
			start_in_blood = previous
			to_chat(user, span_warning("Новый демон не появился. Попробуйте ещё раз."))
			return FALSE
		to_chat(session.current_body, span_notice((start_in_blood ? "Новый демон в крови в центре сектора: выйдите у любой лужи." : "Новый демон стоит в центре сектора.")))
		return TRUE
	var/mob/living/simple_animal/slaughter/body = user
	if(!istype(body) || body != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле демона. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Полное здоровье")
			refill(body)
			to_chat(body, span_notice("Здоровье восполнено, удар-бросок готов."))
		if("Лужи крови рядом")
			return spill_blood(session, body)
		if("Цель для утаскивания")
			return spawn_prey(session, body)
	return TRUE

/datum/antag_training_program/creature/slaughter/proc/spill_blood(datum/antag_training_session/session, mob/living/simple_animal/slaughter/body)
	var/datum/antag_training_arena/arena = session.arena
	var/turf/open/center = get_turf(body)
	if(arena.finished || arena.resetting)
		to_chat(body, span_warning("Дождитесь окончания сброса полигона."))
		return FALSE
	if(!istype(center) || isspaceturf(center) || !arena.owns_area(get_area(center)))
		to_chat(body, span_warning("Здесь кровь не разлить. Встаньте на пол полигона."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите секунду перед следующими лужами."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/list/spots = list()
	for(var/turf/open/spot in orange(1, center))
		if(!isspaceturf(spot) && arena.owns_area(get_area(spot)) && !spot.is_blocked_turf())
			spots += spot
	var/list/chosen = list(center)
	while(length(chosen) < ANTAG_TRAINING_DEMON_POOLS_PER_PRESS && length(spots))
		chosen += pick_n_take(spots)
	for(var/turf/open/spot as anything in chosen)
		var/obj/effect/decal/cleanable/blood/pool = new(spot)
		if(QDELETED(pool))
			continue
		pool.training_owner = WEAKREF(session)
		blood_pools += WEAKREF(pool)
	for(var/datum/weakref/pool_ref as anything in blood_pools.Copy())
		var/obj/effect/decal/cleanable/blood/existing = pool_ref.resolve()
		if(QDELETED(existing))
			blood_pools -= pool_ref
	while(length(blood_pools) > pool_cap)
		var/datum/weakref/oldest = blood_pools[1]
		blood_pools.Cut(1, 2)
		qdel(oldest.resolve())
	to_chat(body, span_notice("Рядом с вами лужи крови. «Blood Crawl» в соседней клетке от лужи погружает в неё или выводит из крови."))
	return TRUE

/datum/antag_training_program/creature/slaughter/proc/spawn_prey(datum/antag_training_session/session, mob/living/simple_animal/slaughter/body)
	var/mob/living/carbon/human/prey = spawn_prey_near(session, body, "human", "Цель ложится рядом с вами, а в центре и переходах её нет: встаньте в секторе или на площадке.")
	if(!prey)
		return FALSE
	prey.Unconscious(ANTAG_TRAINING_DEMON_PREY_SLEEP, TRUE, TRUE)
	to_chat(body, span_notice("[prey.real_name] без сознания рядом с вами. Возьмите [prey.ru_ego()] и погрузитесь в лужу крови."))
	return TRUE

/datum/antag_training_program/creature/slaughter/laughter
	name = "Демон смеха"
	desc = "Тело демона смеха в тёмном секторе: погружение в лужи крови и выход из них, утаскивание и объятия-пир, удар-бросок. После смерти обнятые выходят наружу живыми, котёнок не остаётся, а вы появляетесь новым демоном в центре сектора."
	icon = "face-laugh-squint"
	color = "pink"
	learn = "Погружение в лужи крови и выход|Утаскивание и объятия|Удар-бросок|Возвращение новым демоном"
	difficulty = 2
	mob_type = /mob/living/simple_animal/slaughter/laughter/training
	antag_type = /datum/antagonist/slaughter/training/laughter

/mob/living/simple_animal/slaughter
	var/training_manifesting = FALSE

/// Погружает демона в кровь там, где он стоит, без лужи: учебный старт «в крови».
/mob/living/simple_animal/slaughter/proc/training_sink()
	var/turf/spot = get_turf(src)
	if(!spot || holder)
		return FALSE
	var/obj/effect/dummy/phased_mob/slaughter/blood_holder = new(spot)
	holder = blood_holder
	forceMove(blood_holder)
	if(loc != blood_holder)
		holder = null
		qdel(blood_holder)
		return FALSE
	for(var/obj/effect/proc_holder/spell/bloodcrawl/crawl in mob_spell_list)
		crawl.phased = TRUE
	return TRUE

/// Демон в крови, которого полигон переносит (зоны пульта, сброс, сектор), уходит туда вместе с кровью.
/mob/living/simple_animal/slaughter/proc/training_moved(atom/old_loc)
	if(holder && loc == holder)
		RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(training_holder_deleted), override = TRUE)
		return
	var/obj/effect/dummy/phased_mob/slaughter/blood_holder = holder
	if(training_manifesting || !blood_holder || old_loc != blood_holder || !isturf(loc) || QDELETED(blood_holder))
		return
	blood_holder.forceMove(loc)
	forceMove(blood_holder)

/mob/living/simple_animal/slaughter/proc/training_holder_deleted(obj/effect/dummy/phased_mob/slaughter/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	if(holder == source)
		holder = null
	if(loc != source)
		return
	for(var/obj/effect/proc_holder/spell/bloodcrawl/crawl in mob_spell_list)
		crawl.phased = FALSE
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	training_manifesting = TRUE
	var/turf/spot = get_turf(source)
	if(spot)
		forceMove(spot)
	if(loc == source && arena?.entry_turf)
		forceMove(arena.entry_turf)
	training_manifesting = FALSE

/mob/living/simple_animal/slaughter/proc/training_exit_allowed(obj/effect/decal/cleanable/pool)
	if(!pool || training_move_allowed(get_turf(pool)))
		return TRUE
	to_chat(src, span_warning("Из этой лужи не выйти: туда полигон сейчас не пускает. Выйдите у другой лужи."))
	return FALSE

/// Тело участника полигона демон не удерживает: оно выпадает сразу после пира.
/mob/living/simple_animal/slaughter/proc/training_reject_victim(mob/living/victim)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	for(var/datum/antag_training_session/member as anything in arena?.members)
		if(member.current_body == victim)
			victim.forceMove(get_turf(src))
			victim.exit_blood_effect()
			return TRUE
	return FALSE

/mob/living/simple_animal/slaughter/proc/training_hold_victim(mob/living/victim)
	if(QDELETED(victim))
		consumed_mobs -= victim
		return
	if(!(victim in consumed_mobs))
		return
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(training_forget_victim))
	RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(training_victim_moved))

/mob/living/simple_animal/slaughter/proc/training_forget_victim(mob/living/victim)
	SIGNAL_HANDLER
	UnregisterSignal(victim, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	consumed_mobs -= victim

/mob/living/simple_animal/slaughter/proc/training_victim_moved(mob/living/victim)
	SIGNAL_HANDLER
	if(victim.loc != src)
		training_forget_victim(victim)

/mob/living/simple_animal/slaughter/proc/training_release()
	for(var/mob/living/victim as anything in consumed_mobs.Copy())
		if(QDELETED(victim) || victim.loc != src)
			training_forget_victim(victim)
	release_victims()
	for(var/mob/living/victim as anything in consumed_mobs.Copy())
		training_forget_victim(victim)

/mob/living/simple_animal/slaughter/proc/training_drop_holder()
	var/obj/effect/dummy/phased_mob/slaughter/blood_holder = holder
	if(blood_holder)
		UnregisterSignal(blood_holder, COMSIG_PARENT_QDELETING)
	holder = null
	return blood_holder

/mob/living/simple_animal/slaughter/training
	loot = list()
	del_on_death = FALSE

/mob/living/simple_animal/slaughter/training/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	training_moved(OldLoc)

/mob/living/simple_animal/slaughter/training/phasein(obj/effect/decal/cleanable/B)
	if(!training_exit_allowed(B))
		return FALSE
	training_manifesting = TRUE
	. = ..()
	training_manifesting = FALSE

/mob/living/simple_animal/slaughter/training/death(gibbed)
	. = ..()
	training_release()

/mob/living/simple_animal/slaughter/training/bloodcrawl_swallow(mob/living/victim)
	if(training_reject_victim(victim))
		return
	..()
	training_hold_victim(victim)

/mob/living/simple_animal/slaughter/training/Destroy()
	var/obj/effect/dummy/phased_mob/slaughter/blood_holder = training_drop_holder()
	training_release()
	. = ..()
	qdel(blood_holder)

/mob/living/simple_animal/slaughter/laughter/training
	loot = list()
	del_on_death = FALSE

/mob/living/simple_animal/slaughter/laughter/training/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	training_moved(OldLoc)

/mob/living/simple_animal/slaughter/laughter/training/phasein(obj/effect/decal/cleanable/B)
	if(!training_exit_allowed(B))
		return FALSE
	training_manifesting = TRUE
	. = ..()
	training_manifesting = FALSE

/mob/living/simple_animal/slaughter/laughter/training/death(gibbed)
	. = ..()
	training_release()

/mob/living/simple_animal/slaughter/laughter/training/bloodcrawl_swallow(mob/living/victim)
	if(training_reject_victim(victim))
		return
	..()
	training_hold_victim(victim)

/mob/living/simple_animal/slaughter/laughter/training/Destroy()
	var/obj/effect/dummy/phased_mob/slaughter/blood_holder = training_drop_holder()
	training_release()
	. = ..()
	qdel(blood_holder)

/proc/antag_training_demon_briefing(laughter)
	return jointext(list(
		span_boldnotice((laughter ? "Тренировка демона смеха." : "Тренировка демона резни.")),
		span_notice("«Blood Crawl» рядом с лужей крови погружает в неё, а из крови выводит через любую лужу в соседней клетке. В крови вас не видно и не задеть, вы проходите сквозь стены. После выхода вы несколько секунд быстрее."),
		span_notice("Возьмите тело без сознания или мёртвое и погрузитесь вместе с ним: начнётся пир, который полностью вылечит вас. Тот, кто в сознании, вырывается у самой лужи."),
		span_notice((laughter ? "Обнятые остаются внутри вас, а после вашей смерти выходят наружу живыми и здоровыми." : "Съеденные остаются внутри вас, а после смерти выпадают наружу. Удары по живым с разумом копят серию: раны всё тяжелее, пока вы снова не нырнёте в кровь.")),
		span_notice("«Slaughter Slam» готовит удар-бросок: следующий удар ломает кость и отшвыривает цель."),
		span_notice("«Пульт полигона», раздел «Моя роль»: полное здоровье, лужи крови рядом, цель для утаскивания и выбор начала - в крови или проявленным. После смерти вы появитесь новым демоном в центре сектора."),
	), "<br>")

/datum/antagonist/slaughter/training
	name = "Training Slaughter Demon"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training
	var/laughter = FALSE

/datum/antagonist/slaughter/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/slaughter/training/threat()
	return 0

/datum/antagonist/slaughter/training/forge_objectives()
	return

/datum/antagonist/slaughter/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/slaughter/training/proc/brief()
	to_chat(owner.current, antag_training_demon_briefing(laughter))

/datum/antagonist/slaughter/training/Destroy()
	training = null
	return ..()

/datum/antagonist/slaughter/training/laughter
	name = "Training Laughter Demon"
	objective_verb = "Hug and Tickle"
	laughter = TRUE

#undef ANTAG_TRAINING_DEMON_POOL_CAP
#undef ANTAG_TRAINING_DEMON_POOLS_PER_PRESS
#undef ANTAG_TRAINING_DEMON_PREY_SLEEP
#undef ANTAG_TRAINING_DEMON_START_BLOOD
#undef ANTAG_TRAINING_DEMON_START_MANIFEST

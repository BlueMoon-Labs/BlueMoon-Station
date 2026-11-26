#define LEAD_SCENT_MIN (30 SECONDS)
#define LEAD_SCENT_MAX (45 SECONDS)
#define LEAD_SCENT_EXAMINE_RANGE 3
#define LEAD_LAST_ROUND_RANGE 10
#define LEAD_TURN_DAMAGE_CAP 30
#define LEAD_PHANTOM_RANGE 7
#define LEAD_PHANTOM_RISE (0.5 SECONDS)
#define LEAD_PHANTOM_GAP (1.5 SECONDS)
#define LEAD_PHANTOM_RETRY (1 SECONDS)
#define LEAD_PHANTOM_INTEGRITY 10
#define LEAD_BOUNCE_TOLERANCE 30
#define LEAD_BOUNCE_TRACE (0.5 SECONDS)
#define LEAD_LAST_TRACE (0.6 SECONDS)
#define LEAD_PHANTOM_LOW 8
#define LEAD_PHANTOM_HIGH 12

/datum/eldritch_knowledge/base_lead
	/// Чужой выстрел из огнестрела: к нему ведёт Охота на звук.
	var/turf/heard_turf
	var/heard_at = 0
	/// Осечки заговорённого оружия по стрелкам за раунд: REF(mind) => число.
	var/list/misfire_counts = list()
	/// Шестая камора от барабана вознесения: следующий Последний патрон без полного барабана.
	var/free_last_round = FALSE
	COOLDOWN_DECLARE(powder_scent)
	COOLDOWN_DECLARE(sound_hunt)
	COOLDOWN_DECLARE(phantom_cooldown)

/// Цель охоты и меченые, которые чуют порох, пока еретик рядом и не на виду.
/datum/eldritch_knowledge/base_lead/proc/scent_victims()
	. = list()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	var/mob/living/prey = heretic?.hunt_target?.current
	if(isliving(prey))
		. += prey
	for(var/datum/status_effect/eldritch/lead/mark as anything in marks)
		. |= mark.owner

/// Запах пороха: щелчок курка или звон гильзы у жертвы, которая не видит еретика. Возвращает, кто его услышал.
/datum/eldritch_knowledge/base_lead/proc/powder_scent()
	. = list()
	if(!COOLDOWN_FINISHED(src, powder_scent) || QDELETED(lead_body) || lead_body.stat == DEAD)
		return
	var/turf/here = get_turf(lead_body)
	if(!here)
		return
	for(var/mob/living/victim as anything in scent_victims())
		var/turf/there = get_turf(victim)
		if(victim == lead_body || victim.stat == DEAD || !there || there.z != here.z || get_dist(here, there) > HERETIC_LEAD_SCENT_RANGE)
			continue
		if(isturf(lead_body.loc) && lead_body.invisibility <= victim.see_invisible && can_see(victim, lead_body, HERETIC_LEAD_SCENT_RANGE))
			continue
		. += victim
		var/cocked = prob(50)
		victim.playsound_local(there, heretic_lead_sound(null, cocked ? "cock" : "casing", 0), 35, TRUE)
		to_chat(victim, span_notice((cocked ? "Где-то совсем рядом щёлкает взведённый курок." : "Рядом звякает о пол гильза, хотя никто не стрелял.")))
	if(length(.))
		COOLDOWN_START(src, powder_scent, rand(LEAD_SCENT_MIN, LEAD_SCENT_MAX))

/// Счёт камор: вблизи от еретика с полным барабаном тянет порохом, и это видит любой.
/datum/eldritch_knowledge/base_lead/proc/on_body_examine(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	if(examiner == lead_body || QDELETED(lead_body) || lead_body.stat == DEAD || combat_resource < HERETIC_LEAD_SCENT_SHOWN || get_dist(examiner, lead_body) > LEAD_SCENT_EXAMINE_RANGE)
		return
	if(combat_resource >= combat_resource_max)
		examine_list += span_warning("Резко пахнет порохом, а в складках одежды что-то щёлкает, как взведённый курок: барабан полон.")
	else
		examine_list += span_warning("Тянет порохом, в складках одежды позвякивают гильзы.")
	var/datum/heretic_lead_school/chosen = school_datum()
	if(chosen)
		examine_list += span_warning(chosen.scent_line)

/// Шестая камора: изучен Слух стрелка, а барабан полон или его подарил барабан вознесения.
/datum/eldritch_knowledge/base_lead/proc/last_round_ready()
	return knows(/datum/eldritch_knowledge/lead_ear) && (free_last_round || combat_resource >= combat_resource_max)

/// Последний патрон бережётся для человека: по зверю, слизи или роботу уходит обычная пуля.
/proc/heretic_lead_last_round_target(atom/target, mob/living/user)
	var/mob/living/victim = target
	return ishuman(victim) && victim != user && victim.stat != DEAD && isturf(victim.loc) && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim)

/obj/item/heretic_path_relic/lead_revolver
	var/datum/weakref/aim_ref
	var/mutable_appearance/aim_dot
	var/datum/beam/aim_beam
	var/aim_timer

/obj/item/heretic_path_relic/lead_revolver/Destroy()
	clear_aim()
	clear_focus()
	deltimer(fan_timer)
	fan_timer = null
	return ..()

/obj/item/heretic_path_relic/lead_revolver/proc/clear_aim()
	var/mob/living/victim = aim_ref?.resolve()
	if(victim && aim_dot)
		victim.cut_overlay(aim_dot)
	QDEL_NULL(aim_beam)
	deltimer(aim_timer)
	aim_timer = null
	aim_ref = null
	aim_dot = null

/// Последний патрон: полторы секунды красной линии и прицела на груди цели, затем выстрел.
/obj/item/heretic_path_relic/lead_revolver/proc/start_last_round(mob/living/victim, mob/living/user)
	aim_ref = WEAKREF(victim)
	aim_dot = mutable_appearance(HERETIC_LEAD_FX_ICON, "lead_laser_dot", ABOVE_MOB_LAYER)
	aim_dot.appearance_flags = RESET_COLOR | KEEP_APART
	victim.add_overlay(aim_dot)
	// Линия огня видна всем: кто стоит за целью на её продолжении, тоже под пулей.
	aim_beam = user.Beam(victim, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = HERETIC_LEAD_LAST_ROUND_AIM + 1, maxdistance = LEAD_LAST_ROUND_RANGE + 1)
	aim_timer = addtimer(CALLBACK(src, PROC_REF(fire_last_round), WEAKREF(user)), HERETIC_LEAD_LAST_ROUND_AIM, TIMER_STOPPABLE)
	var/aim_text = replacetext("[HERETIC_LEAD_LAST_ROUND_AIM / (1 SECONDS)]", ".", ",")
	heretic_lead_sound(src, "last_round_charge", 55)
	user.visible_message(span_danger("[user] медленно взводит курок [src]: от ствола к [victim] тянется красная линия, на груди загорается прицел!"), span_notice("Шестая камора: Последний патрон уйдёт в [victim] через [aim_text] секунды."))
	to_chat(victim, span_userdanger("К вам тянется красная линия, на груди горит прицел! Через [aim_text] секунды выстрел: уйдите за угол, лягте или закройтесь щитом."))
	log_combat(user, victim, "берёт на прицел Последним патроном")
	return TRUE

/obj/item/heretic_path_relic/lead_revolver/proc/fire_last_round(datum/weakref/user_ref)
	aim_timer = null
	var/mob/living/victim = aim_ref?.resolve()
	clear_aim()
	var/mob/living/user = user_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_lead/lead = heretic?.get_knowledge(/datum/eldritch_knowledge/base_lead)
	if(!lead?.can_use(user) || !user.is_holding(src) || !lead.last_round_ready() || !heretic_lead_last_round_target(victim, user) || victim.z != user.z || get_dist(user, victim) > LEAD_LAST_ROUND_RANGE)
		if(user)
			to_chat(user, span_warning("Последний патрон сорвался: цель ушла или вы не удержали револьвер. Барабан цел."))
		return null
	lead.sixth_armed = FALSE
	if(lead.free_last_round)
		lead.free_last_round = FALSE
		lead.notify_resource_changed()
	else
		lead.spend_combat_resource(lead.combat_resource)
	var/obj/item/projectile/bullet/heretic_lead/last_round/bullet = new(get_turf(user))
	bullet.firer = user
	bullet.fired_from = src
	bullet.lead_ref = WEAKREF(lead)
	bullet.armour_penetration += lead.sacrifice_penetration()
	bullet.def_zone = BODY_ZONE_CHEST
	bullet.preparePixelProjectile(victim, user)
	if(QDELETED(bullet))
		return null
	lead.school_tracer(bullet)
	// Лежачего пуля не ищет: цель - клетка, а не человек.
	bullet.original = get_turf(victim)
	bullet.fire()
	var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(get_turf(user))
	flash.setDir(get_dir(user, victim))
	heretic_lead_sound(src, "last_round_shot", 80, TRUE, 10)
	user.visible_message(span_danger("[user] спускает курок: Последний патрон уходит в [victim]!"))
	log_combat(user, victim, "стреляет Последним патроном в", src)
	SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "last_round", victim)
	return bullet

/// Последний патрон пробивает первого на линии и валит каждого, кого задел; щит его останавливает.
/obj/item/projectile/bullet/heretic_lead/last_round
	name = "last round"
	damage = HERETIC_LEAD_LAST_ROUND_DAMAGE
	armour_penetration = BULLET_BR4
	color = "#ff9e8a"
	round_name = "Последний патрон"
	refunds = FALSE

/obj/item/projectile/bullet/heretic_lead/last_round/prehit_pierce(atom/target)
	. = ..()
	if(. == PROJECTILE_PIERCE_NONE && isliving(target) && pierces < HERETIC_LEAD_LAST_ROUND_TARGETS - 1)
		return PROJECTILE_PIERCE_HIT

/obj/item/projectile/bullet/heretic_lead/last_round/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	if(!istype(victim))
		return
	if(blocked >= 100)
		qdel(src)
		return
	if(!QDELETED(victim))
		victim.Knockdown(HERETIC_LEAD_LAST_ROUND_KNOCKDOWN)
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	lead?.last_round_kill(victim, hit_alive)

/// Где бы пуля ни остановилась, за ней остаётся сквозной след от ствола.
/obj/item/projectile/bullet/heretic_lead/last_round/Destroy()
	heretic_lead_trace(starting, get_turf(src), "lead_last_tracer", LEAD_LAST_TRACE)
	return ..()

/// Ствол обращается: третья осечка у того же стрелка разворачивает заговорённый ствол ему в ногу.
/datum/eldritch_knowledge/base_lead/proc/count_misfire(obj/item/gun/gun, mob/living/shooter)
	if(!shooter?.mind || !knows(/datum/eldritch_knowledge/lead_grasp))
		return FALSE
	var/key = REF(shooter.mind)
	misfire_counts[key]++
	if(misfire_counts[key] < HERETIC_LEAD_TURN_MISFIRES || !gun_turn_allowed(gun, shooter))
		return FALSE
	misfire_counts[key] = 0
	return turn_gun(gun, shooter)

/// Только живой игрок у себя на станции, только боевой огнестрел.
/datum/eldritch_knowledge/base_lead/proc/gun_turn_allowed(obj/item/gun/gun, mob/living/shooter)
	var/turf/place = get_turf(shooter)
	if(!GET_CLIENT(shooter) || shooter.stat != CONSCIOUS || !shooter.is_holding(gun) || !place || !is_station_level(place.z) || istype(get_area(place), /area/antag_training))
		return FALSE
	return istype(gun, /obj/item/gun/ballistic) && heretic_lead_curseable(gun)

/datum/eldritch_knowledge/base_lead/proc/turn_gun(obj/item/gun/gun, mob/living/shooter)
	var/obj/item/projectile/sample = heretic_lead_gun_projectile(gun)
	var/damage = min(ispath(sample) ? initial(sample.damage) : HERETIC_LEAD_REVOLVER_DAMAGE, LEAD_TURN_DAMAGE_CAP)
	var/leg = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	shooter.apply_damage(damage, BRUTE, leg, shooter.run_armor_check(leg, BULLET, silent = TRUE))
	if(gun.fire_sound)
		playsound(gun, gun.fire_sound, 60, TRUE)
	heretic_lead_sound(gun, "gun_turns", 45, TRUE)
	shooter.dropItemToGround(gun)
	shooter.visible_message(span_danger("[gun] в руках [shooter] сам разворачивается и стреляет [shooter.ru_emu()] в ногу!"), span_userdanger("Ствол [gun] выворачивается в ладони, в ухо шепчет: «Ты не мой» - и бьёт выстрелом вам в ногу! Отдайте это оружие детективу или капеллану."))
	log_combat(shooter, shooter, "получает пулю в ногу от обратившегося заговорённого", gun, "заговор Свинца, еретик [key_name(lead_body)]")
	if(!QDELETED(lead_body) && lead_body.stat != DEAD)
		to_chat(lead_body, span_eldritch("Ствол обратился против [shooter.name]: третья осечка - пуля в ногу. [get_area_name(shooter, TRUE)]."))
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "gun_turns", shooter)
	return TRUE

/// Мёртвый стрелок: огнестрел в руке павшего рядом человека поднимается призрачным стволом.
/datum/eldritch_knowledge/base_lead/proc/on_mob_death(datum/source, mob/living/dead, gibbed)
	SIGNAL_HANDLER
	if(gibbed || !ishuman(dead) || !COOLDOWN_FINISHED(src, phantom_cooldown) || !knows(/datum/eldritch_knowledge/spell/lead_rain))
		return
	if(raise_phantom(dead))
		COOLDOWN_START(src, phantom_cooldown, HERETIC_LEAD_PHANTOM_COOLDOWN)

/datum/eldritch_knowledge/base_lead/proc/raise_phantom(mob/living/carbon/human/dead)
	if(QDELETED(lead_body) || dead == lead_body || !can_use(lead_body))
		return null
	var/turf/here = get_turf(lead_body)
	var/turf/there = get_turf(dead)
	if(!here || !there || here.z != there.z || get_dist(here, there) > HERETIC_LEAD_PHANTOM_RADIUS || !is_station_level(there.z) || istype(get_area(there), /area/antag_training))
		return null
	var/obj/item/gun/ballistic/gun = heretic_lead_fallen_gun(dead)
	if(!gun)
		return null
	var/obj/structure/heretic_lead_phantom_gun/phantom = new(there, src)
	if(QDELETED(phantom))
		return null
	log_game("[key_name(lead_body)]: из рук павшего [key_name(dead)] поднимается призрачный ствол Свинца ([gun.type]) в [AREACOORD(there)].")
	return phantom

/// Оружие павшего: смерть роняет его из рук на клетку тела раньше, чем станция узнаёт о смерти.
/proc/heretic_lead_fallen_gun(mob/living/carbon/human/dead)
	for(var/obj/item/gun/ballistic/held in dead.held_items)
		if(heretic_lead_curseable(held))
			return held
	for(var/obj/item/gun/ballistic/dropped in get_turf(dead))
		if(heretic_lead_curseable(dropped))
			return dropped
	return null

/obj/structure/heretic_lead_phantom_gun
	name = "phantom gun"
	desc = "Тусклый свинцовый призрак ствола висит в воздухе над павшим стрелком. Прежде чем выстрелить, он на секунду тянет к живому красную линию прицела. Сбейте его ударом или выстрелом, пока он не нашёл вас."
	icon = HERETIC_LEAD_FX_ICON
	icon_state = "lead_phantom_gun"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	max_integrity = LEAD_PHANTOM_INTEGRITY
	armor_type = /datum/armor/none
	var/datum/weakref/lead_ref
	var/datum/weakref/aim_ref
	var/shots_left = HERETIC_LEAD_PHANTOM_SHOTS
	var/step_timer
	var/fall_timer

/obj/structure/heretic_lead_phantom_gun/Initialize(mapload, datum/eldritch_knowledge/base_lead/lead)
	. = ..()
	if(!istype(lead))
		return INITIALIZE_HINT_QDEL
	lead_ref = WEAKREF(lead)
	pixel_y = LEAD_PHANTOM_LOW
	animate(src, pixel_y = LEAD_PHANTOM_HIGH, time = 1 SECONDS, loop = -1, easing = SINE_EASING)
	animate(pixel_y = LEAD_PHANTOM_LOW, time = 1 SECONDS, easing = SINE_EASING)
	visible_message(span_danger("Из мёртвых пальцев поднимается призрачный ствол и разворачивается к живым!"))
	step_timer = addtimer(CALLBACK(src, PROC_REF(take_aim)), LEAD_PHANTOM_RISE, TIMER_STOPPABLE)
	fall_timer = addtimer(CALLBACK(src, PROC_REF(fall)), HERETIC_LEAD_PHANTOM_TIME, TIMER_STOPPABLE)

/obj/structure/heretic_lead_phantom_gun/Destroy()
	deltimer(step_timer)
	deltimer(fall_timer)
	step_timer = null
	fall_timer = null
	aim_ref = null
	lead_ref = null
	return ..()

/obj/structure/heretic_lead_phantom_gun/proc/owner_lead()
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(!lead?.owner_heretic() || QDELETED(lead.lead_body) || lead.lead_body.stat == DEAD)
		return null
	return lead

/// Ближайший живой не-еретик в поле зрения ствола, люди с разумом первыми.
/obj/structure/heretic_lead_phantom_gun/proc/pick_victim(datum/eldritch_knowledge/base_lead/lead)
	var/mob/living/best
	var/best_score
	for(var/mob/living/victim in heretic_field_view(LEAD_PHANTOM_RANGE, src))
		if(victim.stat == DEAD || !isturf(victim.loc) || victim == lead.lead_body || IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
			continue
		var/score = get_dist(src, victim) + (victim.mind ? 0 : LEAD_PHANTOM_RANGE + 1)
		if(!best || score < best_score)
			best = victim
			best_score = score
	return best

/obj/structure/heretic_lead_phantom_gun/proc/take_aim()
	step_timer = null
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead()
	if(!lead || shots_left <= 0)
		fall()
		return null
	var/mob/living/victim = pick_victim(lead)
	if(!victim)
		step_timer = addtimer(CALLBACK(src, PROC_REF(take_aim)), LEAD_PHANTOM_RETRY, TIMER_STOPPABLE)
		return null
	aim_ref = WEAKREF(victim)
	setDir(get_dir(src, victim))
	Beam(victim, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = HERETIC_LEAD_PHANTOM_AIM, maxdistance = LEAD_PHANTOM_RANGE * 2)
	to_chat(victim, span_userdanger("Призрачный ствол навёл на вас красную линию! Через секунду выстрел: укройтесь или сбейте его."))
	step_timer = addtimer(CALLBACK(src, PROC_REF(shoot)), HERETIC_LEAD_PHANTOM_AIM, TIMER_STOPPABLE)
	return victim

/// Пуля летит туда, где цель стоит сейчас: за стеной её не достать.
/obj/structure/heretic_lead_phantom_gun/proc/shoot()
	step_timer = null
	var/datum/eldritch_knowledge/base_lead/lead = owner_lead()
	var/mob/living/victim = aim_ref?.resolve()
	aim_ref = null
	if(!lead)
		fall()
		return null
	shots_left--
	var/obj/item/projectile/bullet/heretic_lead/phantom/bullet
	if(victim && victim.stat != DEAD && isturf(victim.loc) && victim.z == z)
		bullet = new(get_turf(src))
		bullet.firer = lead.lead_body
		bullet.fired_from = src
		bullet.def_zone = BODY_ZONE_CHEST
		bullet.preparePixelProjectile(victim, src)
		if(QDELETED(bullet))
			bullet = null
		else
			bullet.fire()
			var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(get_turf(src))
			flash.setDir(get_dir(src, victim))
			heretic_lead_sound(src, "phantom_shot", 60, TRUE)
			log_combat(lead.lead_body, victim, "стреляет призрачным стволом Свинца в")
	step_timer = addtimer(CALLBACK(src, shots_left > 0 ? PROC_REF(take_aim) : PROC_REF(fall)), shots_left > 0 ? LEAD_PHANTOM_GAP : LEAD_PHANTOM_RISE, TIMER_STOPPABLE)
	return bullet

/obj/structure/heretic_lead_phantom_gun/proc/fall()
	if(QDELETED(src))
		return
	visible_message(span_notice("Призрачный ствол тускнеет и осыпается свинцовой пылью."))
	new /obj/effect/temp_visual/heretic_lead/ricochet(get_turf(src))
	qdel(src)

/obj/structure/heretic_lead_phantom_gun/deconstruct(disassembled = TRUE)
	var/turf/place = get_turf(src)
	if(place)
		visible_message(span_warning("Призрачный ствол разлетается свинцовыми брызгами!"))
		new /obj/effect/temp_visual/heretic_lead/ricochet(place)
	return ..()

/obj/item/projectile/bullet/heretic_lead/phantom
	name = "phantom bullet"
	damage = HERETIC_LEAD_PHANTOM_DAMAGE
	armour_penetration = BULLET_BR4
	refunds = FALSE

/// Охота на звук: чужой выстрел из огнестрела запоминается, Рикошет может уйти к нему.
/datum/eldritch_knowledge/base_lead/proc/on_heard_shot(datum/source, obj/item/gun/gun, mob/living/shooter, atom/target, fired)
	SIGNAL_HANDLER
	if(shooter && shooter == lead_body)
		mark_combat()
	if(school == HERETIC_LEAD_SCHOOL_GUNSLINGER && heretic_lead_harmful_shot(fired) && shot_toward_body(shooter, target))
		note_duel_shooter(shooter)
	if(QDELETED(lead_body) || shooter == lead_body || (ismob(shooter) && (IS_HERETIC(shooter) || IS_HERETIC_MONSTER(shooter))) || !heretic_lead_gunshot(gun, fired))
		return
	under_fire(shooter, target)
	var/turf/place = get_turf(shooter || gun)
	if(place)
		heard_turf = place
		heard_at = world.time

/datum/eldritch_knowledge/base_lead/proc/sound_hunt_learned()
	var/datum/antagonist/heretic/heretic = owner_heretic()
	return heretic && heretic.total_sacrifices >= HERETIC_LEAD_SOUND_HUNT_SACRIFICES

/datum/eldritch_knowledge/base_lead/proc/sound_hunt_reason(mob/living/user)
	if(!COOLDOWN_FINISHED(src, sound_hunt))
		return "отдыхает ещё [CEILING(COOLDOWN_TIMELEFT(src, sound_hunt) / (1 SECONDS), 1)] с."
	if(!heard_turf || world.time > heard_at + HERETIC_LEAD_RICOCHET_MEMORY)
		return "чужих выстрелов из огнестрела не слышно."
	if(heard_turf.z != user.z || get_dist(user, heard_turf) > HERETIC_LEAD_RICOCHET_RANGE)
		return "последний чужой выстрел дальше [HERETIC_LEAD_RICOCHET_RANGE] клеток на вашем этаже."
	var/area/destination_area = get_area(heard_turf)
	if(destination_area.area_flags & NOTELEPORT)
		return "у места выстрела закрыто для телепортации."
	if(!heretic_lead_landing_near(heard_turf))
		return "у места выстрела нет свободного пола."
	return null

/proc/heretic_lead_landing_near(turf/center)
	if(!isturf(center))
		return null
	if(heretic_lead_landable(center))
		return center
	for(var/direction in GLOB.alldirs)
		var/turf/nearby = get_step(center, direction)
		if(heretic_lead_landable(nearby) && center.Adjacent(nearby))
			return nearby
	return null

/// Своей пули нет: столб порохового дыма за секунду выдаёт место выхода, затем перенос.
/datum/eldritch_knowledge/base_lead/proc/sound_hunt(mob/living/user)
	var/turf/origin = get_turf(user)
	var/turf/destination = heretic_lead_landing_near(heard_turf)
	if(!destination || !spend_combat_resource())
		return FALSE
	COOLDOWN_START(src, sound_hunt, HERETIC_LEAD_SOUND_HUNT_COOLDOWN)
	new /obj/effect/temp_visual/heretic_lead/powder_pillar(destination)
	destination.visible_message(span_danger("Из пола бьёт столб порохового дыма: сейчас здесь кто-то появится!"))
	user.visible_message(span_warning("[user] вскидывает голову на звук чужого выстрела и тает в пороховом дыму!"), span_notice("Вы идёте на звук чужого выстрела."))
	if(!do_after(user, HERETIC_LEAD_SOUND_HUNT_DELAY, target = user, timed_action_flags = IGNORE_HELD_ITEM) || !can_use(user, ignore_grab = TRUE) || user.buckled || HAS_TRAIT(user, TRAIT_NO_TELEPORT) || !heretic_lead_landable(destination) || !do_teleport(user, destination, channel = TELEPORT_CHANNEL_MAGIC) || get_turf(user) != destination)
		gain_combat_resource()
		COOLDOWN_RESET(src, sound_hunt)
		lead_failure = "Охота на звук сорвалась: вас сдвинули или перенос что-то остановило. Свинец сохранён."
		return FALSE
	heretic_lead_powder_smoke(origin, smoke_tint())
	new /obj/effect/temp_visual/heretic_lead/ricochet(destination)
	heretic_lead_sound(destination, "ricochet", 60, TRUE)
	log_game("[key_name(user)] уходит Охотой на звук Свинца из [AREACOORD(origin)] в [AREACOORD(destination)].")
	heard_turf = null
	notify_resource_changed()
	SEND_SIGNAL(src, COMSIG_HERETIC_LEAD_EVENT, "sound_hunt", destination)
	return TRUE

/// Мишень помнит: убитый меченый человек кладёт в барабан еретика ещё Свинца.
/datum/status_effect/eldritch/lead/proc/on_owner_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/base_lead/lead = lead_ref?.resolve()
	if(lead && ishuman(owner) && owner.mind && !QDELETED(lead.lead_body) && lead.lead_body.stat != DEAD)
		lead.gain_combat_resource(HERETIC_LEAD_MARK_KILL_LEAD)
		to_chat(lead.lead_body, span_eldritch("Мишень пала: в барабан ложится ещё [HERETIC_LEAD_MARK_KILL_LEAD] Свинца. Свинец: [lead.combat_resource] из [lead.combat_resource_max]."))
		log_game("[key_name(lead.lead_body)] получает Свинец за убитую Мишень [key_name(owner)] в [AREACOORD(owner)].")
		SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "mark_kill", owner)
	qdel(src)

/datum/status_effect/eldritch/lead/proc/hunt_duration(mob/living/new_owner, datum/eldritch_knowledge/base_lead/lead)
	var/datum/antagonist/heretic/heretic = lead?.owner_heretic()
	. = heretic?.hunt_target && heretic.hunt_target == new_owner?.mind ? HERETIC_LEAD_MARK_HUNT_TIME : initial(duration)
	if(lead?.school == HERETIC_LEAD_SCHOOL_HUNTER)
		. += HERETIC_LEAD_HUNTER_MARK_BONUS

/datum/eldritch_knowledge/final_eldritch/lead_final
	var/drum_timer
	var/drum_beats = 0

/// Барабан вознесения: раз в минуту, пока горит тигель; каждый третий удар - Свинец и Шестая камора.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/drum_beat()
	stop_drum()
	if(crucibles_spent || !lit_crucibles())
		return FALSE
	drum_timer = addtimer(CALLBACK(src, PROC_REF(drum_beat)), HERETIC_LEAD_DRUM_PERIOD, TIMER_STOPPABLE)
	drum_beats++
	var/drum_sound = heretic_lead_sound(null, "drum", 0)
	for(var/mob/listener as anything in GLOB.player_list)
		var/turf/place = get_turf(listener)
		if(place && !isnewplayer(listener) && shot_place_valid(place))
			listener.playsound_local(place, drum_sound, 40, FALSE, pressure_affected = FALSE)
	var/mob/living/body = applied_body
	var/datum/eldritch_knowledge/base_lead/lead = lead_of(body)
	if(!lead || body.stat == DEAD)
		return TRUE
	var/count = (drum_beats - 1) % HERETIC_LEAD_DRUM_BEATS + 1
	if(count < HERETIC_LEAD_DRUM_BEATS)
		to_chat(body, span_eldritch("Далёкий барабан отбивает отсчёт: [count] из [HERETIC_LEAD_DRUM_BEATS]."))
		return TRUE
	lead.gain_combat_resource(HERETIC_LEAD_DRUM_LEAD)
	lead.free_last_round = TRUE
	lead.notify_resource_changed()
	to_chat(body, span_eldritch("Третий удар барабана: +[HERETIC_LEAD_DRUM_LEAD] Свинца и Шестая камора даром. Взведите её Alt-кликом по Шестизаряднику - выстрел в человека станет Последним патроном без траты барабана."))
	log_game("Барабан Свинца: [key_name(body)] получает Шестую камору.")
	SEND_SIGNAL(lead, COMSIG_HERETIC_LEAD_EVENT, "drum", body)
	return TRUE

/datum/eldritch_knowledge/final_eldritch/lead_final/proc/stop_drum()
	deltimer(drum_timer)
	drum_timer = null

/// Пуля Последнего залпа: по прямой, а к укрывшемуся - рикошетом от ближайшей стены вполовину силы.
/datum/eldritch_knowledge/final_eldritch/lead_final/proc/volley_shot(mob/living/user, datum/eldritch_knowledge/base_lead/lead, turf/origin, mob/living/victim)
	var/turf/start = origin
	var/damage = HERETIC_LEAD_VOLLEY_DAMAGE
	if(!heretic_edge_line_clear(origin, victim))
		var/turf/bounce = heretic_lead_bounce_turf(origin, get_turf(victim), HERETIC_LEAD_VOLLEY_RANGE)
		if(bounce)
			user.Beam(bounce, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = LEAD_BOUNCE_TRACE, maxdistance = HERETIC_LEAD_VOLLEY_RANGE * 2)
			bounce.Beam(victim, icon_state = "lead_aim_line", icon = HERETIC_LEAD_FX_ICON, time = LEAD_BOUNCE_TRACE, maxdistance = HERETIC_LEAD_VOLLEY_RANGE * 2)
			new /obj/effect/temp_visual/heretic_lead/ricochet(bounce)
			start = bounce
			damage = round(HERETIC_LEAD_VOLLEY_DAMAGE / 2)
			log_combat(user, victim, "достаёт рикошетом Последнего залпа")
	var/obj/item/projectile/bullet/heretic_lead/volley/bullet = new(start)
	bullet.damage = damage
	bullet.firer = user
	bullet.fired_from = user
	bullet.lead_ref = WEAKREF(lead)
	bullet.def_zone = BODY_ZONE_CHEST
	bullet.preparePixelProjectile(victim, start)
	if(QDELETED(bullet))
		return null
	lead.school_tracer(bullet)
	bullet.fire()
	var/obj/effect/temp_visual/heretic_lead/muzzle/flash = new(origin)
	flash.setDir(get_dir(origin, victim))
	return bullet

/// Клетка у стены, откуда пуля дойдёт рикошетом: угол падения равен углу отражения, обе половины пути чисты.
/proc/heretic_lead_bounce_turf(turf/origin, turf/destination, range)
	if(!isturf(origin) || !isturf(destination))
		return null
	var/turf/best
	var/best_length
	for(var/turf/open/spot in range(range, origin))
		if(spot == origin || spot == destination || !heretic_tile_passable(spot) || !heretic_lead_bounce_fits(origin, spot, destination))
			continue
		var/length = get_dist_euclidian(origin, spot) + get_dist_euclidian(spot, destination)
		if(best && length >= best_length)
			continue
		if(heretic_edge_line_clear(origin, spot) && heretic_edge_line_clear(spot, destination))
			best = spot
			best_length = length
	return best

/proc/heretic_lead_bounce_fits(turf/origin, turf/spot, turf/destination)
	var/in_angle = Get_Angle(origin, spot)
	var/out_angle = Get_Angle(spot, destination)
	for(var/direction in GLOB.cardinals)
		if(!isclosedturf(get_step(spot, direction)))
			continue
		var/toward
		var/away
		var/mirrored
		if(direction & (EAST|WEST))
			var/sign = direction == EAST ? 1 : -1
			toward = (spot.x - origin.x) * sign
			away = (spot.x - destination.x) * sign
			mirrored = 360 - in_angle
		else
			var/sign = direction == NORTH ? 1 : -1
			toward = (spot.y - origin.y) * sign
			away = (spot.y - destination.y) * sign
			mirrored = 180 - in_angle
		if(toward > 0 && away > 0 && abs(closer_angle_difference(out_angle, mirrored)) <= LEAD_BOUNCE_TOLERANCE)
			return TRUE
	return FALSE

/obj/effect/temp_visual/heretic_lead/powder_pillar
	name = "powder smoke"
	icon_state = "lead_powder_pillar"
	duration = HERETIC_LEAD_SOUND_HUNT_DELAY + 0.5 SECONDS
	layer = FLY_LAYER

#undef LEAD_SCENT_MIN
#undef LEAD_SCENT_MAX
#undef LEAD_SCENT_EXAMINE_RANGE
#undef LEAD_LAST_ROUND_RANGE
#undef LEAD_TURN_DAMAGE_CAP
#undef LEAD_PHANTOM_RANGE
#undef LEAD_PHANTOM_RISE
#undef LEAD_PHANTOM_GAP
#undef LEAD_PHANTOM_RETRY
#undef LEAD_PHANTOM_INTEGRITY
#undef LEAD_BOUNCE_TOLERANCE
#undef LEAD_BOUNCE_TRACE
#undef LEAD_LAST_TRACE
#undef LEAD_PHANTOM_LOW
#undef LEAD_PHANTOM_HIGH

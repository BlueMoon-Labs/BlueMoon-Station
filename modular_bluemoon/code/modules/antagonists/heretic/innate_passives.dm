#define HERETIC_INNATE_TICK (2 SECONDS)
#define HERETIC_INNATE_BLEED_MULTIPLIER 0.75
#define HERETIC_INNATE_STEPS 3
#define HERETIC_INNATE_RESERVE_LIMIT 12
#define HERETIC_INNATE_MENDING 2
#define HERETIC_INNATE_DAMAGE_THRESHOLD 8
#define HERETIC_INNATE_DAMAGE_WINDOW (0.5 SECONDS)
#define HERETIC_INNATE_CHAIN_WINDOW (4 SECONDS)
#define HERETIC_INNATE_STEP_WINDOW (6 SECONDS)
#define HERETIC_INNATE_RESPONSE_WINDOW (5 SECONDS)
#define HERETIC_INNATE_DOOR_DURATION (2 SECONDS)
#define HERETIC_INNATE_ASH_HEAL 4
#define HERETIC_INNATE_ASH_STAMINA 6
#define HERETIC_INNATE_RUST_HEAL 1
#define HERETIC_INNATE_FLESH_PER_HIT 6
#define HERETIC_INNATE_FLESH_FRACTION 0.25
#define HERETIC_INNATE_VOID_STAMINA 6
#define HERETIC_INNATE_BLADE_STAMINA 8
#define HERETIC_INNATE_MOON_STAMINA 8
#define HERETIC_INNATE_COSMIC_STAMINA 6
#define HERETIC_INNATE_DOOR_SPEED -0.35
#define HERETIC_INNATE_BLOOD_RECOVERY 3
#define HERETIC_INNATE_ECHO_DAMAGE 4
#define HERETIC_INNATE_ECHO_STAMINA 8
#define HERETIC_INNATE_GLASS_DAMAGE 5
#define HERETIC_INNATE_TIDE_STAMINA 6
#define HERETIC_INNATE_SAND_STAMINA 12
#define HERETIC_INNATE_SPIRIT_HEAL 2
#define HERETIC_INNATE_SPIRIT_STAMINA 8
#define HERETIC_INNATE_SPIRIT_HEALTH_FRACTION 0.5

/datum/heretic_path
	var/innate_type

/datum/heretic_path/ash
	innate_type = /datum/heretic_innate/ash
/datum/heretic_path/rust
	innate_type = /datum/heretic_innate/rust
/datum/heretic_path/flesh
	innate_type = /datum/heretic_innate/flesh
/datum/heretic_path/void
	innate_type = /datum/heretic_innate/void
/datum/heretic_path/blade
	innate_type = /datum/heretic_innate/blade
/datum/heretic_path/moon
	innate_type = /datum/heretic_innate/moon
/datum/heretic_path/cosmic
	innate_type = /datum/heretic_innate/cosmic
/datum/heretic_path/lock
	innate_type = /datum/heretic_innate/lock
/datum/heretic_path/blood
	innate_type = /datum/heretic_innate/blood
/datum/heretic_path/echo
	innate_type = /datum/heretic_innate/echo
/datum/heretic_path/glass
	innate_type = /datum/heretic_innate/glass
/datum/heretic_path/tide
	innate_type = /datum/heretic_innate/tide
/datum/heretic_path/sand
	innate_type = /datum/heretic_innate/sand
/datum/heretic_path/spirit
	innate_type = /datum/heretic_innate/spirit
/datum/heretic_path/wax
	innate_type = /datum/heretic_innate/wax

/datum/eldritch_knowledge
	var/datum/heretic_innate/innate

/datum/eldritch_knowledge/proc/bind_innate(mob/living/user)
	var/datum/heretic_path/path = GLOB.heretic_paths[route]
	var/datum/antagonist/heretic/heretic = user ? IS_HERETIC(user) : null
	if(!path?.innate_type || path.knowledge[1] != type || !isliving(user) || heretic?.selected_path != route)
		return
	if(!innate)
		innate = new path.innate_type(src)
	innate.bind(user)

/datum/heretic_innate
	var/name
	var/desc
	var/datum/weakref/knowledge_ref
	var/mob/living/body
	var/cooldown = 6 SECONDS
	var/ready_at = 0
	var/next_tick = 0
	var/active_until = 0
	var/reserve = 0
	var/previous_brute = 0
	var/previous_burn = 0
	var/damage_in_window = 0
	var/damage_window_until = 0
	var/datum/weakref/last_target
	var/last_hit_at = 0
	var/last_step_at = 0
	var/list/steps = list()
	var/speed_until = 0
	var/speed_timer
	var/datum/physiology/bleeding_physiology

/datum/heretic_innate/New(datum/eldritch_knowledge/knowledge)
	knowledge_ref = WEAKREF(knowledge)
	return ..()

/datum/heretic_innate/proc/bind(mob/living/user)
	if(body == user)
		return
	unbind()
	body = user
	previous_brute = body.getBruteLoss()
	previous_burn = body.getFireLoss()
	RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	RegisterSignal(body, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_health_changed))
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_body_deleted))
	if(istype(src, /datum/heretic_innate/void))
		ADD_TRAIT(body, TRAIT_SILENT_STEP, REF(src))
	if(istype(src, /datum/heretic_innate/blood) && ishuman(body))
		var/mob/living/carbon/human/human_body = body
		bleeding_physiology = human_body.physiology
		bleeding_physiology.bleed_mod *= HERETIC_INNATE_BLEED_MULTIPLIER

/datum/heretic_innate/proc/unbind()
	reset_transient()
	if(body)
		UnregisterSignal(body, list(COMSIG_MOVABLE_MOVED, COMSIG_CARBON_UPDATEHEALTH, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		REMOVE_TRAIT(body, TRAIT_SILENT_STEP, REF(src))
	if(!QDELETED(bleeding_physiology))
		bleeding_physiology.bleed_mod /= HERETIC_INNATE_BLEED_MULTIPLIER
	bleeding_physiology = null
	body = null

/datum/heretic_innate/Destroy()
	unbind()
	knowledge_ref = null
	return ..()

/datum/heretic_innate/proc/valid()
	var/datum/eldritch_knowledge/knowledge = knowledge_ref?.resolve()
	var/datum/antagonist/heretic/heretic = body ? IS_HERETIC(body) : null
	return !QDELETED(body) && body.stat != DEAD && !QDELETED(knowledge) && heretic && !heretic.role_removed && heretic.owner?.current == body && heretic.selected_path == knowledge.route && heretic.get_knowledge(knowledge.type) == knowledge

/datum/heretic_innate/proc/reset_transient()
	active_until = 0
	reserve = 0
	last_target = null
	last_hit_at = 0
	last_step_at = 0
	damage_in_window = 0
	damage_window_until = 0
	steps.Cut()
	speed_until = 0
	deltimer(speed_timer)
	speed_timer = null
	if(body)
		body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_innate_door)

/datum/heretic_innate/proc/on_death()
	SIGNAL_HANDLER
	reset_transient()

/datum/heretic_innate/proc/on_body_deleted()
	SIGNAL_HANDLER
	unbind()

/datum/heretic_innate/proc/trigger()
	ready_at = world.time + cooldown
	body.balloon_alert(body, name)

/datum/heretic_innate/proc/tick()
	if(!valid())
		return
	if(speed_until && world.time >= speed_until)
		body.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_innate_door)
		speed_until = 0
	if(world.time < next_tick || !isturf(body.loc))
		return
	next_tick = world.time + HERETIC_INNATE_TICK
	on_tick()

/datum/heretic_innate/proc/on_tick()
	return

/datum/heretic_innate/proc/on_move(mob/living/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	if(!valid() || forced || body.incapacitated() || body.buckled || body.throwing || !isturf(old_loc) || !isturf(body.loc) || old_loc.z != body.z || get_dist(old_loc, body) != 1)
		steps.Cut()
		return
	if(world.time - last_step_at > HERETIC_INNATE_STEP_WINDOW)
		steps.Cut()
	last_step_at = world.time
	if(length(steps) < HERETIC_INNATE_STEPS)
		steps |= body.loc
	if(world.time >= ready_at)
		on_step(old_loc)

/datum/heretic_innate/proc/on_step(turf/old_loc)
	return

/datum/heretic_innate/proc/on_health_changed()
	SIGNAL_HANDLER
	var/brute = body.getBruteLoss()
	var/burn = body.getFireLoss()
	var/new_damage = max(0, round(brute - previous_brute, DAMAGE_PRECISION)) + max(0, round(burn - previous_burn, DAMAGE_PRECISION))
	var/new_burn = max(0, round(burn - previous_burn, DAMAGE_PRECISION))
	previous_brute = brute
	previous_burn = burn
	if(new_damage <= 0)
		return
	if(valid() && world.time >= ready_at)
		// Один удар с распределением по конечностям может обновить здоровье несколько раз.
		if(world.time >= damage_window_until)
			damage_window_until = world.time + HERETIC_INNATE_DAMAGE_WINDOW
			damage_in_window = 0
		damage_in_window = round(damage_in_window + new_damage, DAMAGE_PRECISION)
		on_damage(damage_in_window, new_burn)

/datum/heretic_innate/proc/on_damage(amount, burn)
	return

/datum/heretic_innate/proc/blade_hit(mob/living/victim, damage)
	if(!valid() || body.incapacitated() || !isturf(body.loc) || !body.Adjacent(victim) || damage <= 0 || !victim.mind || !heretic_can_affect(body, victim, chargecost = 0))
		return
	on_hit(victim, damage)

/datum/heretic_innate/proc/on_hit(mob/living/victim, damage)
	return

/datum/heretic_innate/ash
	name = "Голод углей"
	desc = "Попадание своим клинком по горящему разумному врагу лечит 4 ожога и восстанавливает 6 выносливости. Раз в 6 секунд."

/datum/heretic_innate/ash/on_hit(mob/living/victim, damage)
	if(world.time < ready_at || !victim.on_fire)
		return
	trigger()
	heretic_heal_damage(body, burn = HERETIC_INNATE_ASH_HEAL)
	body.adjustStaminaLoss(-HERETIC_INNATE_ASH_STAMINA)

/datum/heretic_innate/rust
	name = "Живая ржавчина"
	desc = "На ржавом полу каждые 2 секунды заживает по 1 ушибу и ожогу. Работает с выбора пути и складывается с изученной Ржавой поступью. Сам пол врагов не отравляет."

/datum/heretic_innate/rust/on_tick()
	if(istype(body.loc, /turf/open/floor/plating/rust))
		heretic_heal_damage(body, HERETIC_INNATE_RUST_HEAL, HERETIC_INNATE_RUST_HEAL)

/datum/heretic_innate/flesh
	name = "Запасная плоть"
	desc = "Ранение разумного врага своим клинком запасает четверть нанесённого урона, до 6 за удар и 12 всего. Запас автоматически лечит до 2 ушибов каждые 2 секунды; при смерти и смене тела исчезает."

/datum/heretic_innate/flesh/on_hit(mob/living/victim, damage)
	reserve = min(HERETIC_INNATE_RESERVE_LIMIT, reserve + min(HERETIC_INNATE_FLESH_PER_HIT, damage * HERETIC_INNATE_FLESH_FRACTION))

/datum/heretic_innate/flesh/on_tick()
	reserve = max(0, reserve - heretic_heal_damage(body, min(reserve, HERETIC_INNATE_MENDING)))

/datum/heretic_innate/void
	name = "Неслышный холод"
	desc = "Ваши шаги бесшумны. Удар своим клинком со спины разумного врага дополнительно истощает 6 выносливости, раз в 6 секунд."

/datum/heretic_innate/void/on_hit(mob/living/victim, damage)
	if(world.time < ready_at || !(get_dir(body, victim) & victim.dir))
		return
	trigger()
	victim.adjustStaminaLoss(HERETIC_INNATE_VOID_STAMINA)

/datum/heretic_innate/blade
	name = "Ритм дуэли"
	desc = "Повторный удар своим клинком по тому же разумному врагу в течение 4 секунд восстанавливает 8 выносливости, если вторая рука пуста. Восстановление — раз в 4 секунды."
	cooldown = 4 SECONDS

/datum/heretic_innate/blade/on_hit(mob/living/victim, damage)
	var/repeated = last_target?.resolve() == victim && world.time < last_hit_at + HERETIC_INNATE_CHAIN_WINDOW
	last_target = WEAKREF(victim)
	last_hit_at = world.time
	if(!repeated || world.time < ready_at || body.get_inactive_held_item())
		return
	trigger()
	body.adjustStaminaLoss(-HERETIC_INNATE_BLADE_STAMINA)

/datum/heretic_innate/moon
	name = "Лунная пляска"
	desc = "Пройдите три разные клетки без паузы дольше 6 секунд: следующее попадание своим клинком дополнительно истощит 8 выносливости разумного врага. Раз в 6 секунд. Телепорты и толчки сбрасывают подготовку."

/datum/heretic_innate/moon/on_hit(mob/living/victim, damage)
	if(world.time < ready_at || length(steps) < HERETIC_INNATE_STEPS || world.time > last_step_at + HERETIC_INNATE_STEP_WINDOW)
		return
	steps.Cut()
	trigger()
	victim.adjustStaminaLoss(HERETIC_INNATE_MOON_STAMINA)

/datum/heretic_innate/cosmic
	name = "Своя орбита"
	desc = "Обычный шаг в пределах одной клетки от собственной звезды восстанавливает 6 выносливости. Раз в 4 секунды."
	cooldown = 4 SECONDS

/datum/heretic_innate/cosmic/on_step(turf/old_loc)
	var/datum/eldritch_knowledge/base_cosmic/knowledge = knowledge_ref.resolve()
	for(var/obj/structure/heretic_star/star as anything in knowledge.stars)
		if(star.z == body.z && body.Adjacent(star))
			trigger()
			body.adjustStaminaLoss(-HERETIC_INNATE_COSMIC_STAMINA)
			return

/datum/heretic_innate/lock
	name = "Право прохода"
	desc = "Пройдя через открытую дверь обычным шагом, вы ускоряетесь на 2 секунды. Раз в 8 секунд. Закрытые двери и доступ эта черта не обходит."
	cooldown = 8 SECONDS

/datum/heretic_innate/lock/on_step(turf/old_loc)
	for(var/obj/machinery/door/door in old_loc)
		if(door.density)
			continue
		trigger()
		speed_until = world.time + HERETIC_INNATE_DOOR_DURATION
		body.add_movespeed_modifier(/datum/movespeed_modifier/heretic_innate_door)
		speed_timer = addtimer(CALLBACK(src, PROC_REF(end_speed)), HERETIC_INNATE_DOOR_DURATION, TIMER_STOPPABLE)
		return

/datum/heretic_innate/lock/proc/end_speed()
	speed_timer = null
	speed_until = 0
	body?.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_innate_door)

/datum/movespeed_modifier/heretic_innate_door
	multiplicative_slowdown = HERETIC_INNATE_DOOR_SPEED

/datum/heretic_innate/blood
	name = "Кровь помнит"
	desc = "Кровотечение слабее на 25%. Ранение кровеносного разумного врага своим клинком восполняет до 3 единиц вашей крови, не выше нормы тела, раз в 6 секунд. Усиленное свёртывание от Взыскания действует дополнительно."

/datum/heretic_innate/blood/on_hit(mob/living/victim, damage)
	if(world.time < ready_at || !ishuman(body) || !iscarbon(victim) || !victim.get_blood_id() || victim.blood_volume <= 0)
		return
	var/mob/living/carbon/human/human_body = body
	if((NOBLOOD in human_body.dna.species.species_traits) || !human_body.get_blood_id())
		return
	var/recovered = min(HERETIC_INNATE_BLOOD_RECOVERY, max(0, BLOOD_VOLUME_NORMAL * human_body.blood_ratio - human_body.blood_volume - human_body.integrating_blood))
	if(recovered <= 0)
		return
	trigger()
	human_body.blood_volume += recovered

/datum/heretic_innate/echo
	name = "Подхваченный такт"
	desc = "После попадания своим клинком ударьте другого разумного врага в течение 4 секунд: второй получит ещё 4 ушиба и 8 урона выносливости. Раз в 6 секунд."

/datum/heretic_innate/echo/on_hit(mob/living/victim, damage)
	var/mob/living/previous = last_target?.resolve()
	var/changed = previous && previous != victim && world.time < last_hit_at + HERETIC_INNATE_CHAIN_WINDOW
	last_target = WEAKREF(victim)
	last_hit_at = world.time
	if(!changed || world.time < ready_at)
		return
	trigger()
	victim.adjustBruteLoss(HERETIC_INNATE_ECHO_DAMAGE)
	victim.adjustStaminaLoss(HERETIC_INNATE_ECHO_STAMINA)

/datum/heretic_innate/glass
	name = "Острая трещина"
	desc = "Получив суммарно 8 ушибов или ожогов за полсекунды, на 5 секунд заряжаете ответ: попадание своим клинком по разумному врагу нанесёт ещё 5 ушибов. Заряд — не чаще раза в 10 секунд, не складывается."
	cooldown = 10 SECONDS

/datum/heretic_innate/glass/on_damage(amount, burn)
	if(amount < HERETIC_INNATE_DAMAGE_THRESHOLD)
		return
	trigger()
	active_until = world.time + HERETIC_INNATE_RESPONSE_WINDOW

/datum/heretic_innate/glass/on_hit(mob/living/victim, damage)
	if(world.time >= active_until)
		return
	active_until = 0
	victim.adjustBruteLoss(HERETIC_INNATE_GLASS_DAMAGE)

/datum/heretic_innate/tide
	name = "Обратное течение"
	desc = "Помимо врождённой устойчивости на мокром полу, шаг по воде восстанавливает 6 выносливости и снимает один заряд огня. Раз в 4 секунды; смазка вместо воды не подходит."
	cooldown = 4 SECONDS

/datum/heretic_innate/tide/on_step(turf/old_loc)
	var/datum/component/wet_floor/water = body.loc.GetComponent(/datum/component/wet_floor)
	if(!(water?.highest_strength & TURF_WET_WATER))
		return
	trigger()
	body.adjustStaminaLoss(-HERETIC_INNATE_TIDE_STAMINA)
	body.adjust_fire_stacks(-1)

/datum/heretic_innate/sand
	name = "Сквозь пальцы"
	desc = "Получив суммарно 8 ушибов или ожогов за полсекунды, сделайте обычный шаг в течение 5 секунд: восстановится 12 выносливости. Раз в 10 секунд. Толчок и телепорт бонуса не дают."
	cooldown = 10 SECONDS

/datum/heretic_innate/sand/on_damage(amount, burn)
	if(amount >= HERETIC_INNATE_DAMAGE_THRESHOLD)
		active_until = world.time + HERETIC_INNATE_RESPONSE_WINDOW

/datum/heretic_innate/sand/on_step(turf/old_loc)
	if(world.time >= active_until)
		return
	active_until = 0
	trigger()
	body.adjustStaminaLoss(-HERETIC_INNATE_SAND_STAMINA)

/datum/heretic_innate/spirit
	name = "Последний вздох"
	desc = "Попадание своим клинком по живому разумному врагу, у которого осталось меньше половины максимального здоровья, лечит 2 ушиба и 2 ожога, восстанавливает 8 выносливости. Раз в 8 секунд."
	cooldown = 8 SECONDS

/datum/heretic_innate/spirit/on_hit(mob/living/victim, damage)
	if(world.time < ready_at || victim.health >= victim.maxHealth * HERETIC_INNATE_SPIRIT_HEALTH_FRACTION)
		return
	trigger()
	heretic_heal_damage(body, HERETIC_INNATE_SPIRIT_HEAL, HERETIC_INNATE_SPIRIT_HEAL)
	body.adjustStaminaLoss(-HERETIC_INNATE_SPIRIT_STAMINA)

/datum/heretic_innate/wax
	name = "Плавкая память"
	desc = "Полученные ожоги запасаются как тёплый воск, до 12 единиц. Пока вы не горите, запас лечит до 2 ушибов каждые 2 секунды. Сами ожоги остаются; смерть и смена тела обнуляют запас."

/datum/heretic_innate/wax/on_damage(amount, burn)
	reserve = min(HERETIC_INNATE_RESERVE_LIMIT, reserve + burn)

/datum/heretic_innate/wax/on_tick()
	if(!body.on_fire)
		reserve = max(0, reserve - heretic_heal_damage(body, min(reserve, HERETIC_INNATE_MENDING)))

#undef HERETIC_INNATE_TICK
#undef HERETIC_INNATE_BLEED_MULTIPLIER
#undef HERETIC_INNATE_STEPS
#undef HERETIC_INNATE_RESERVE_LIMIT
#undef HERETIC_INNATE_MENDING
#undef HERETIC_INNATE_DAMAGE_THRESHOLD
#undef HERETIC_INNATE_DAMAGE_WINDOW
#undef HERETIC_INNATE_CHAIN_WINDOW
#undef HERETIC_INNATE_STEP_WINDOW
#undef HERETIC_INNATE_RESPONSE_WINDOW
#undef HERETIC_INNATE_DOOR_DURATION
#undef HERETIC_INNATE_ASH_HEAL
#undef HERETIC_INNATE_ASH_STAMINA
#undef HERETIC_INNATE_RUST_HEAL
#undef HERETIC_INNATE_FLESH_PER_HIT
#undef HERETIC_INNATE_FLESH_FRACTION
#undef HERETIC_INNATE_VOID_STAMINA
#undef HERETIC_INNATE_BLADE_STAMINA
#undef HERETIC_INNATE_MOON_STAMINA
#undef HERETIC_INNATE_COSMIC_STAMINA
#undef HERETIC_INNATE_DOOR_SPEED
#undef HERETIC_INNATE_BLOOD_RECOVERY
#undef HERETIC_INNATE_ECHO_DAMAGE
#undef HERETIC_INNATE_ECHO_STAMINA
#undef HERETIC_INNATE_GLASS_DAMAGE
#undef HERETIC_INNATE_TIDE_STAMINA
#undef HERETIC_INNATE_SAND_STAMINA
#undef HERETIC_INNATE_SPIRIT_HEAL
#undef HERETIC_INNATE_SPIRIT_STAMINA
#undef HERETIC_INNATE_SPIRIT_HEALTH_FRACTION

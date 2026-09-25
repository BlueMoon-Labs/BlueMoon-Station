#define HERETIC_MANSUS_EMBER_DELAY (3 SECONDS)
#define HERETIC_MANSUS_EMBER_FLARE (1.5 SECONDS)
#define HERETIC_MANSUS_EMBER_TRAIL 5
#define HERETIC_MANSUS_RUST_PLATES 40
#define HERETIC_MANSUS_RUST_COLLAPSE (1.5 SECONDS)
#define HERETIC_MANSUS_RUST_HOLE (20 SECONDS)
#define HERETIC_MANSUS_FLESH_OPEN (4 SECONDS)
#define HERETIC_MANSUS_FLESH_CLOSED (3 SECONDS)
#define HERETIC_MANSUS_FLESH_WARNING (1 SECONDS)
#define HERETIC_MANSUS_BLADE_TRAPS 5
#define HERETIC_MANSUS_BLADE_CYCLE (4 SECONDS)
#define HERETIC_MANSUS_BLADE_WARNING (1 SECONDS)
#define HERETIC_MANSUS_BLADE_STRIKE (0.5 SECONDS)
#define HERETIC_MANSUS_BLADE_SPACING (0.8 SECONDS)
#define HERETIC_MANSUS_MOON_REFLECTIONS 2
#define HERETIC_MANSUS_PORTAL_PAIRS 3
#define HERETIC_MANSUS_PORTAL_COOLDOWN (2 SECONDS)
#define HERETIC_MANSUS_TIDE_INTERVAL (25 SECONDS)
#define HERETIC_MANSUS_TIDE_DURATION (10 SECONDS)
#define HERETIC_MANSUS_TIDE_WARNING (2 SECONDS)
#define HERETIC_MANSUS_TIDE_RIPPLE_ALPHA 60
#define HERETIC_MANSUS_REFLECTION_STEPS 2
#define HERETIC_MANSUS_BLOOD_TRAIL 40
#define HERETIC_MANSUS_BLOOD_HASTE 0.7
#define HERETIC_MANSUS_RUN_NOISE 9
#define HERETIC_MANSUS_WALK_NOISE 2
#define HERETIC_MANSUS_TASK_NOISE 5
#define HERETIC_MANSUS_HOURGLASSES 5
#define HERETIC_MANSUS_HOURGLASS_FREEZE (6 SECONDS)
#define HERETIC_MANSUS_HOURGLASS_COST (10 SECONDS)
#define HERETIC_MANSUS_WAX_INTERVAL (10 SECONDS)
#define HERETIC_MANSUS_WAX_RELIGHT (30 SECONDS)
#define HERETIC_MANSUS_WAX_MAX_DARKNESS 2
#define HERETIC_MANSUS_WAX_OVERLAY "heretic_mansus_wax"
#define HERETIC_MANSUS_SPIRIT_CAGES 5
#define HERETIC_MANSUS_SPIRIT_DECOY (8 SECONDS)
#define HERETIC_MANSUS_SPIRIT_LURE_RANGE 9
#define HERETIC_MANSUS_SPIRIT_STEP (0.5 SECONDS)
#define HERETIC_MANSUS_INTERACT_TIME (1 SECONDS)

/// Особое правило Дома одного пути. Хуки зовёт посещение; объекты правила живут в visit.scenery.
/datum/heretic_mansus_rule
	var/datum/heretic_mansus_visit/visit
	var/hint = ""
	/// Короткая памятка в значке Дома.
	var/reminder = ""
	var/ice_cells = 0
	var/list/rule_timers = list()

/datum/heretic_mansus_rule/New(datum/heretic_mansus_visit/new_visit)
	visit = new_visit

/datum/heretic_mansus_rule/Destroy()
	cleanup()
	for(var/timer in rule_timers)
		deltimer(timer)
	rule_timers.Cut()
	visit = null
	return ..()

/datum/heretic_mansus_rule/proc/schedule(datum/callback/callback, delay)
	rule_timers += addtimer(callback, delay, TIMER_STOPPABLE)

/datum/heretic_mansus_rule/proc/active()
	return visit && !visit.finished && visit.started

/datum/heretic_mansus_rule/proc/spawn_object(object_type, turf/position, ...)
	var/list/arguments = args.Copy(2)
	var/atom/movable/thing = new object_type(arglist(arguments))
	visit.scenery += thing
	return thing

/// Свободная клетка комнаты под предмет правила: не у печати, не на осколке, льду или чужом предмете.
/datum/heretic_mansus_rule/proc/free_spot(cell)
	var/list/options = list()
	for(var/turf/position as anything in visit.cell_turfs(cell))
		if(!visit.walkable_turfs[position] || visit.is_safe(position) || visit.ice_turfs[position] || istype(position, /turf/open/indestructible/heretic_mansus/path))
			continue
		var/occupied = FALSE
		for(var/obj/effect/thing in position)
			if(!istype(thing, /obj/effect/heretic_mansus_sanctuary))
				occupied = TRUE
				break
		if(!occupied)
			options += position
	return length(options) ? pick(options) : null

/datum/heretic_mansus_rule/proc/ordinary_cells()
	. = list()
	for(var/cell in 1 to HERETIC_MANSUS_GRID * HERETIC_MANSUS_GRID)
		if(cell != visit.plan.gate_cell && cell != visit.plan.entry_cell)
			. += cell

/// Постоянные проёмы между комнатами, не касающиеся врат и входа.
/datum/heretic_mansus_rule/proc/inner_doors()
	. = list()
	for(var/key in visit.plan.doors)
		if(visit.plan.doors[key] != "open")
			continue
		var/list/pair = splittext(key, "-")
		var/first = text2num(pair[1])
		var/second = text2num(pair[2])
		if(first == visit.plan.gate_cell || second == visit.plan.gate_cell || first == visit.plan.entry_cell || second == visit.plan.entry_cell)
			continue
		. += key

/datum/heretic_mansus_rule/proc/on_generate()
/datum/heretic_mansus_rule/proc/on_start()
/datum/heretic_mansus_rule/proc/on_danger()
/datum/heretic_mansus_rule/proc/on_delivery()
/datum/heretic_mansus_rule/proc/on_awaken(obj/effect/heretic_mansus_memory/memory)
/datum/heretic_mansus_rule/proc/on_victim_moved(atom/old_loc, direction, forced)
/datum/heretic_mansus_rule/proc/on_process()
/datum/heretic_mansus_rule/proc/on_hit()
/datum/heretic_mansus_rule/proc/on_noise(turf/source)
/datum/heretic_mansus_rule/proc/on_hazard(obj/effect/heretic_mansus_hazard/hazard)
/datum/heretic_mansus_rule/proc/cleanup()

/datum/heretic_mansus_rule/proc/route_target()
	return null

/datum/heretic_mansus_rule/proc/route_links(turf/position)
	return null

/// Клетка закрыта и для маршрута, и для тени.
/datum/heretic_mansus_rule/proc/blocks(turf/position)
	return FALSE

/datum/heretic_mansus_rule/proc/hunter_can_enter(obj/effect/heretic_mansus_hunter/hunter, turf/position)
	return !blocks(position)

/datum/heretic_mansus_rule/proc/hunter_goal(obj/effect/heretic_mansus_hunter/hunter)
	return null

/datum/heretic_mansus_rule/proc/hunter_sees(obj/effect/heretic_mansus_hunter/hunter)
	return null

/datum/heretic_mansus_rule/proc/hunter_step_delay(obj/effect/heretic_mansus_hunter/hunter, delay)
	return delay

/datum/heretic_mansus_rule/proc/guidance()
	return reminder ? "[reminder] " : ""

/// Метка правила на клетке: без механики, только вид.
/obj/effect/heretic_mansus_mark
	name = "mark of the House"
	icon = HERETIC_MANSUS_RULES_ICON
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = TURF_LAYER + 0.1

/obj/effect/heretic_mansus_mark/Initialize(mapload, datum/heretic_mansus_visit/visit, state, new_name, new_desc)
	. = ..()
	visit?.apply_style(src, state, HERETIC_MANSUS_RULES_ICON)
	if(new_name)
		name = new_name
	if(new_desc)
		desc = new_desc
		mouse_opacity = MOUSE_OPACITY_ICON

/// Предмет правила, которым жертва пользуется, постояв на нём секунду; работает и в наручниках.
/obj/effect/heretic_mansus_device
	icon = HERETIC_MANSUS_RULES_ICON
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	var/datum/heretic_mansus_rule/rule
	var/used = FALSE
	var/busy = FALSE

/obj/effect/heretic_mansus_device/Initialize(mapload, datum/heretic_mansus_rule/new_rule, state, icon_file = HERETIC_MANSUS_RULES_ICON)
	. = ..()
	rule = new_rule
	rule?.visit?.apply_style(src, state, icon_file)

/obj/effect/heretic_mansus_device/Destroy()
	rule = null
	return ..()

/obj/effect/heretic_mansus_device/attack_hand(mob/user)
	INVOKE_ASYNC(src, PROC_REF(try_use), user)

/obj/effect/heretic_mansus_device/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser))
		INVOKE_ASYNC(src, PROC_REF(try_use), crosser)

/obj/effect/heretic_mansus_device/proc/can_use(mob/user)
	return !used && rule?.active() && user == rule.visit.victim && user.stat == CONSCIOUS && get_dist(user, src) <= 1

/obj/effect/heretic_mansus_device/proc/try_use(mob/user)
	if(busy || !can_use(user) || !ready(user))
		return FALSE
	busy = TRUE
	var/done = do_after(user, HERETIC_MANSUS_INTERACT_TIME, src, timed_action_flags = IGNORE_HELD_ITEM | IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(can_use), user))
	busy = FALSE
	if(!done || !can_use(user))
		return FALSE
	used = TRUE
	use(user)
	return TRUE

/obj/effect/heretic_mansus_device/proc/ready(mob/user)
	return TRUE

/obj/effect/heretic_mansus_device/proc/use(mob/user)
	return

// Пепел: тлеющий след за спиной.

/datum/heretic_mansus_rule/ash
	hint = "За вами тлеет след. Тень через угли не пройдёт, но через три секунды они вспыхивают: не возвращайтесь по своим следам."
	reminder = "Угли за спиной вспыхивают через три секунды."
	var/burning = FALSE
	var/list/embers = list()

/datum/heretic_mansus_rule/ash/on_danger()
	burning = TRUE

/datum/heretic_mansus_rule/ash/on_victim_moved(atom/old_loc, direction, forced)
	if(!burning || forced || !isturf(old_loc) || !visit.danger_enabled)
		return
	var/obj/effect/heretic_mansus_hazard/ember/ember = visit.place_hazard(old_loc, /obj/effect/heretic_mansus_hazard/ember, HERETIC_MANSUS_EMBER_DELAY, HERETIC_MANSUS_EMBER_FLARE)
	if(!ember)
		return
	if(prob(50))
		ember.transform = matrix(-1, 0, 0, 0, 1, 0)
	for(var/obj/effect/heretic_mansus_hazard/ember/old_ember as anything in embers.Copy())
		if(QDELETED(old_ember))
			embers -= old_ember
	embers += ember
	while(length(embers) > HERETIC_MANSUS_EMBER_TRAIL)
		var/obj/effect/heretic_mansus_hazard/ember/oldest = embers[1]
		embers.Cut(1, 2)
		qdel(oldest)

/datum/heretic_mansus_rule/ash/hunter_can_enter(obj/effect/heretic_mansus_hunter/hunter, turf/position)
	return ..() && !(locate(/obj/effect/heretic_mansus_hazard/ember) in position)

/datum/heretic_mansus_rule/ash/cleanup()
	embers.Cut()

/obj/effect/heretic_mansus_hazard/ember
	name = "smouldering footprint"
	desc = "Ваш собственный след тлеет. Тень его обходит, но скоро он вспыхнет."
	warning_state = "ember"
	warning_icon = HERETIC_MANSUS_RULES_ICON

// Ржавчина: плиты проваливаются за спиной.

/datum/heretic_mansus_rule/rust
	hint = "Ржавые плиты проваливаются через полторы секунды после того, как вы с них сошли, и двадцать секунд остаются дырой. Тень через дыру тоже не пройдёт."
	reminder = "Ржавые плиты за спиной проваливаются."
	var/list/plates = list()
	var/list/cracking = list()

/datum/heretic_mansus_rule/rust/on_generate()
	var/list/candidates = list()
	var/list/keep = list(visit.entry_turf, get_turf(visit.offering))
	for(var/obj/effect/heretic_mansus_memory/memory as anything in visit.memories)
		keep += get_turf(memory)
	for(var/turf/position as anything in visit.walkable_turfs)
		var/cell = visit.cell_of(position)
		if(!cell || cell == visit.plan.gate_cell || cell == visit.plan.entry_cell || (position in keep) || visit.ice_turfs[position] || next_to_door(position))
			continue
		candidates += position
	candidates = shuffle(candidates)
	var/list/chosen = list()
	for(var/turf/position as anything in candidates)
		if(length(chosen) >= HERETIC_MANSUS_RUST_PLATES)
			break
		chosen[position] = TRUE
		if(!connected_without(chosen, keep))
			chosen -= position
	for(var/turf/position as anything in chosen)
		plates[position] = spawn_object(/obj/effect/heretic_mansus_mark, position, visit, "plate", "rusted plate", "Проржавевший настил. Сойдёте с него - и он провалится.")

/datum/heretic_mansus_rule/rust/proc/next_to_door(turf/position)
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(position, direction)
		if(visit.walkable_turfs[neighbor] && !visit.cell_of(neighbor))
			return TRUE
	return FALSE

/// Даже если провалятся все плиты сразу, цели остаются связаны при закрытых затворах.
/datum/heretic_mansus_rule/rust/proc/connected_without(list/removed, list/keep)
	var/list/blocked = removed.Copy()
	for(var/turf/shutter as anything in visit.shutters_a + visit.shutters_b)
		blocked[shutter] = TRUE
	var/list/seen = list()
	seen[visit.entry_turf] = TRUE
	var/list/frontier = list(visit.entry_turf)
	var/index = 1
	while(index <= length(frontier))
		var/turf/current = frontier[index++]
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current, direction)
			if(!visit.walkable_turfs[neighbor] || blocked[neighbor] || seen[neighbor])
				continue
			seen[neighbor] = TRUE
			frontier += neighbor
	for(var/turf/target as anything in keep)
		if(!seen[target])
			return FALSE
	return TRUE

/datum/heretic_mansus_rule/rust/on_victim_moved(atom/old_loc, direction, forced)
	var/obj/effect/heretic_mansus_mark/plate = plates[old_loc]
	if(!plate || plate.density || cracking[old_loc])
		return
	cracking[old_loc] = TRUE
	animate(plate, pixel_x = 1, time = 0.1 SECONDS, loop = 7)
	animate(pixel_x = -1, time = 0.1 SECONDS)
	schedule(CALLBACK(src, PROC_REF(collapse), old_loc), HERETIC_MANSUS_RUST_COLLAPSE)

/datum/heretic_mansus_rule/rust/proc/collapse(turf/position)
	var/obj/effect/heretic_mansus_mark/plate = plates[position]
	if(!active() || QDELETED(plate))
		return
	if((locate(/mob/living) in position) || (locate(/obj/effect/heretic_mansus_hunter) in position))
		schedule(CALLBACK(src, PROC_REF(collapse), position), 0.5 SECONDS)
		return
	cracking -= position
	animate(plate)
	plate.pixel_x = 0
	visit.apply_style(plate, "plate_broken", HERETIC_MANSUS_RULES_ICON)
	plate.density = TRUE
	plate.desc = "Провал в ржавом настиле. Скоро Дом залатает его."
	visit.walkable_turfs -= position
	playsound(position, visit.theme["hit"], 30, FALSE)
	visit.update_route()
	schedule(CALLBACK(src, PROC_REF(restore), position), HERETIC_MANSUS_RUST_HOLE)

/datum/heretic_mansus_rule/rust/proc/restore(turf/position)
	var/obj/effect/heretic_mansus_mark/plate = plates[position]
	if(!active() || QDELETED(plate))
		return
	visit.apply_style(plate, "plate", HERETIC_MANSUS_RULES_ICON)
	plate.density = FALSE
	plate.desc = "Проржавевший настил. Сойдёте с него - и он провалится."
	visit.walkable_turfs[position] = TRUE
	visit.update_route()

/datum/heretic_mansus_rule/rust/cleanup()
	plates.Cut()
	cracking.Cut()

// Плоть: проходы дышат в общем ритме.

/datum/heretic_mansus_rule/flesh
	hint = "Проходы между комнатами дышат: четыре секунды открыты, три сжаты. Ритм у всех общий, и тень ждёт у сомкнутой плоти так же, как вы."
	reminder = "Проходы открыты четыре секунды, потом сжимаются на три."
	var/list/sphincters = list()
	var/closed = FALSE

/datum/heretic_mansus_rule/flesh/on_generate()
	for(var/key in inner_doors())
		var/turf/door = visit.door_turf(key)
		sphincters[door] = spawn_object(/obj/effect/heretic_mansus_mark, door, visit, "sphincter", "breathing passage", "Живой проход. Он сжимается и разжимается в общем ритме Дома.")

/datum/heretic_mansus_rule/flesh/on_start()
	schedule(CALLBACK(src, PROC_REF(warn)), HERETIC_MANSUS_FLESH_OPEN - HERETIC_MANSUS_FLESH_WARNING)

/datum/heretic_mansus_rule/flesh/proc/warn()
	if(!active())
		return
	for(var/turf/door as anything in sphincters)
		var/obj/effect/heretic_mansus_mark/mark = sphincters[door]
		animate(mark, color = "#c06060", time = HERETIC_MANSUS_FLESH_WARNING)
	schedule(CALLBACK(src, PROC_REF(set_closed), TRUE), HERETIC_MANSUS_FLESH_WARNING)

/datum/heretic_mansus_rule/flesh/proc/set_closed(new_closed)
	if(!active())
		return
	closed = new_closed
	for(var/turf/door as anything in sphincters)
		var/obj/effect/heretic_mansus_mark/mark = sphincters[door]
		animate(mark, color = null, time = 0.2 SECONDS)
		var/turf/result = visit.set_passage(door, !closed, /turf/open/indestructible/heretic_mansus/path, /turf/closed/indestructible/heretic_mansus/sphincter)
		visit.apply_style(mark, (closed && result.density) ? "sphincter_closed" : "sphincter", HERETIC_MANSUS_RULES_ICON)
	playsound(visit.victim, visit.theme["step"], 30, FALSE)
	visit.update_route()
	if(closed)
		schedule(CALLBACK(src, PROC_REF(set_closed), FALSE), HERETIC_MANSUS_FLESH_CLOSED)
	else
		schedule(CALLBACK(src, PROC_REF(warn)), HERETIC_MANSUS_FLESH_OPEN - HERETIC_MANSUS_FLESH_WARNING)

/datum/heretic_mansus_rule/flesh/cleanup()
	sphincters.Cut()

/turf/closed/indestructible/heretic_mansus/sphincter
	name = "clenched passage"
	desc = "Плоть сомкнулась. Через три секунды она снова разожмётся."
	baseturfs = /turf/closed/indestructible/heretic_mansus/sphincter

// Пустота: ледяные комнаты-головоломки.

/datum/heretic_mansus_rule/void
	hint = "Лёд: ступив на него, вы скользите до первой преграды. Яркий осколок остановит вас. Ищите, от каких колонн оттолкнуться."
	reminder = "На льду скользите до преграды."
	ice_cells = 4
	var/sliding = FALSE

/datum/heretic_mansus_rule/void/on_generate()
	for(var/turf/position as anything in visit.ice_turfs)
		spawn_object(/obj/effect/heretic_mansus_mark, position, visit, "ice")

/datum/heretic_mansus_rule/void/on_victim_moved(atom/old_loc, direction, forced)
	if(forced || sliding || !direction || !visit.ice_turfs[get_turf(visit.victim)])
		return
	INVOKE_ASYNC(src, PROC_REF(slide), direction)

/datum/heretic_mansus_rule/void/proc/slide(direction)
	sliding = TRUE
	while(active() && visit.victim.stat == CONSCIOUS)
		var/turf/current = get_turf(visit.victim)
		if(!visit.ice_turfs[current])
			break
		var/obj/effect/heretic_mansus_memory/memory = locate() in current
		if(memory?.awake)
			break
		if(!step(visit.victim, direction))
			break
		sleep(world.tick_lag)
	sliding = FALSE

// Клинок: лезвия в проходах бьют по расписанию.

/datum/heretic_mansus_rule/blade
	hint = "В проходах ходят лезвия. Сначала появляется призрачная полоса, через секунду бьют клинки. У каждого прохода свой ритм, тень лезвий не боится."
	reminder = "Полоса в проходе - через секунду удар клинков."
	var/list/traps = list()

/datum/heretic_mansus_rule/blade/on_generate()
	var/list/keys = shuffle(inner_doors())
	for(var/index in 1 to min(HERETIC_MANSUS_BLADE_TRAPS, length(keys)))
		traps += visit.door_turf(keys[index])

/datum/heretic_mansus_rule/blade/on_danger()
	for(var/index in 1 to length(traps))
		schedule(CALLBACK(src, PROC_REF(warn), traps[index]), (index - 1) * HERETIC_MANSUS_BLADE_SPACING)

/datum/heretic_mansus_rule/blade/proc/warn(turf/position)
	if(!active())
		return
	schedule(CALLBACK(src, PROC_REF(warn), position), HERETIC_MANSUS_BLADE_CYCLE)
	var/obj/effect/heretic_mansus_hazard/blade/strip = visit.place_hazard(position, /obj/effect/heretic_mansus_hazard/blade, HERETIC_MANSUS_BLADE_WARNING, HERETIC_MANSUS_BLADE_STRIKE)
	if(strip)
		schedule(CALLBACK(src, PROC_REF(strike), strip), HERETIC_MANSUS_BLADE_WARNING)

/datum/heretic_mansus_rule/blade/proc/strike(obj/effect/heretic_mansus_hazard/blade/strip)
	if(!active() || QDELETED(strip))
		return
	visit.arm_hazard(strip)
	playsound(strip, visit.theme["hit"], 35, FALSE)
	if(get_turf(visit.victim) == get_turf(strip))
		visit.suffer_hazard(visit.victim)

/datum/heretic_mansus_rule/blade/cleanup()
	traps.Cut()

/obj/effect/heretic_mansus_hazard/blade
	name = "blade line"
	desc = "Через проход бегут лезвия. Дождитесь, пока они пройдут."
	dispels_hunters = FALSE
	warning_state = "strip"
	warning_icon = HERETIC_MANSUS_RULES_ICON
	danger_state = "strike"
	danger_icon = HERETIC_MANSUS_RULES_ICON

// Луна: ложные осколки без тени.

/datum/heretic_mansus_rule/moon
	hint = "У настоящего осколка есть тень. Отражения без тени рассыпаются в руках и выдают вас тени. Стрелки ведут лишь в комнату осколка."
	reminder = "Настоящий осколок отбрасывает тень."
	var/deceiving = FALSE
	var/list/reflections = list()

/datum/heretic_mansus_rule/moon/on_danger()
	deceiving = TRUE

/datum/heretic_mansus_rule/moon/on_awaken(obj/effect/heretic_mansus_memory/memory)
	clear_reflections()
	if(!deceiving)
		return
	memory.add_filter("moon_shadow", 1, drop_shadow_filter(x = 3, y = -3, size = 1, color = "#000000aa"))
	for(var/index in 1 to HERETIC_MANSUS_MOON_REFLECTIONS)
		var/turf/position = free_spot(memory.chamber)
		if(position)
			reflections += spawn_object(/obj/effect/heretic_mansus_device/reflection, position, src, "memory", 'modular_bluemoon/icons/obj/heretic_mansus.dmi')

/datum/heretic_mansus_rule/moon/route_target()
	if(!deceiving || visit.carried_memory)
		return null
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[min(visit.memories_found + 1, HERETIC_MANSUS_MEMORIES)]
	var/list/room_turfs = visit.cell_turfs(memory.chamber)
	var/turf/center = room_turfs[round(length(room_turfs) / 2) + 1]
	var/turf/closest
	for(var/turf/position as anything in room_turfs)
		if(position == get_turf(memory) || !visit.walkable_turfs[position])
			continue
		if(!closest || get_dist(position, center) < get_dist(closest, center))
			closest = position
	return closest

/datum/heretic_mansus_rule/moon/proc/clear_reflections()
	for(var/obj/effect/heretic_mansus_device/reflection/reflection as anything in reflections)
		visit.scenery -= reflection
		qdel(reflection)
	reflections.Cut()

/datum/heretic_mansus_rule/moon/proc/betray(turf/position)
	for(var/obj/effect/heretic_mansus_hunter/hunter as anything in visit.hunters)
		hunter.last_seen_turf = position
		hunter.search_turf = null
	to_chat(visit.victim, span_warning("Осколок рассыпается бледным светом: это было отражение. Где-то в Доме тень повернула голову к вам."))
	playsound(position, visit.theme["warning"], 45, FALSE)

/datum/heretic_mansus_rule/moon/cleanup()
	clear_reflections()

/obj/effect/heretic_mansus_device/reflection
	name = "memory shard"
	desc = "Наступите на осколок и постойте, чтобы собрать его."
	layer = ABOVE_MOB_LAYER

/obj/effect/heretic_mansus_device/reflection/use(mob/user)
	var/datum/heretic_mansus_rule/moon/moon = rule
	var/turf/position = get_turf(src)
	moon.reflections -= src
	moon.visit.scenery -= src
	moon.betray(position)
	qdel(src)

// Космос: парные звёздные врата.

/datum/heretic_mansus_rule/cosmic
	hint = "Звёздные врата связывают далёкие комнаты попарно: шагните в них, чтобы выйти у пары. Тень ими не ходит, но пойдёт туда, где вы пропали."
	reminder = "Звёздные врата переносят к своей паре."
	var/list/portals = list()
	var/next_jump = 0

/datum/heretic_mansus_rule/cosmic/on_generate()
	var/list/cells = shuffle(ordinary_cells())
	for(var/pair in 1 to HERETIC_MANSUS_PORTAL_PAIRS)
		if(length(cells) < 2)
			break
		var/first = cells[1]
		var/second
		for(var/cell in cells)
			if(cell != first && (!second || cell_distance(first, cell) > cell_distance(first, second)))
				second = cell
		cells -= list(first, second)
		var/turf/first_spot = free_spot(first)
		var/turf/second_spot = free_spot(second)
		if(!first_spot || !second_spot)
			continue
		var/obj/effect/heretic_mansus_portal/first_portal = spawn_object(/obj/effect/heretic_mansus_portal, first_spot, src)
		var/obj/effect/heretic_mansus_portal/second_portal = spawn_object(/obj/effect/heretic_mansus_portal, second_spot, src)
		first_portal.partner = second_portal
		second_portal.partner = first_portal
		portals += list(first_portal, second_portal)

/datum/heretic_mansus_rule/cosmic/proc/cell_distance(first, second)
	return abs(visit.plan.cell_column(first) - visit.plan.cell_column(second)) + abs(visit.plan.cell_row(first) - visit.plan.cell_row(second))

/datum/heretic_mansus_rule/cosmic/proc/jump(obj/effect/heretic_mansus_portal/portal, mob/user)
	if(!active() || user != visit.victim || world.time < next_jump || QDELETED(portal.partner))
		return FALSE
	next_jump = world.time + HERETIC_MANSUS_PORTAL_COOLDOWN
	playsound(portal, visit.theme["pickup"], 40, FALSE)
	user.forceMove(get_turf(portal.partner))
	playsound(portal.partner, visit.theme["pickup"], 40, FALSE)
	return TRUE

/datum/heretic_mansus_rule/cosmic/route_links(turf/position)
	var/obj/effect/heretic_mansus_portal/portal = locate() in position
	if(portal?.partner)
		return list(get_turf(portal.partner))
	return null

/datum/heretic_mansus_rule/cosmic/cleanup()
	for(var/obj/effect/heretic_mansus_portal/portal as anything in portals)
		portal.partner = null
		portal.rule = null
	portals.Cut()

/obj/effect/heretic_mansus_portal
	name = "star gate"
	desc = "Вихрь погасших звёзд. Шагните в него, чтобы выйти у его пары в другой комнате."
	icon = HERETIC_MANSUS_RULES_ICON
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	var/datum/heretic_mansus_rule/cosmic/rule
	var/obj/effect/heretic_mansus_portal/partner

/obj/effect/heretic_mansus_portal/Initialize(mapload, datum/heretic_mansus_rule/cosmic/new_rule)
	. = ..()
	rule = new_rule
	rule?.visit?.apply_style(src, "portal", HERETIC_MANSUS_RULES_ICON)

/obj/effect/heretic_mansus_portal/Destroy()
	rule = null
	partner = null
	return ..()

/obj/effect/heretic_mansus_portal/Crossed(atom/movable/crosser)
	. = ..()
	if(ismob(crosser) && rule)
		INVOKE_ASYNC(rule, TYPE_PROC_REF(/datum/heretic_mansus_rule/cosmic, jump), src, crosser)

// Замок: комната осколка заперта, ключ в другой.

/datum/heretic_mansus_rule/lock
	hint = "Комната с осколком заперта. Ключ лежит в другой комнате: наступите на него, а потом толкните запертую дверь."
	reminder = "Сначала ключ, потом дверь."
	var/locked_cell
	var/has_key = FALSE
	var/obj/effect/heretic_mansus_device/key/key
	var/list/doors = list()
	var/list/opened_cells = list()

/datum/heretic_mansus_rule/lock/on_awaken(obj/effect/heretic_mansus_memory/memory)
	if(!visit.memories_found || (memory.chamber in opened_cells) || locked_cell == memory.chamber)
		return
	lock_cell(memory.chamber)

/datum/heretic_mansus_rule/lock/proc/lock_cell(cell)
	locked_cell = cell
	has_key = FALSE
	for(var/door_key in visit.plan.doors)
		var/list/pair = splittext(door_key, "-")
		if(text2num(pair[1]) != cell && text2num(pair[2]) != cell)
			continue
		var/turf/position = visit.door_turf(door_key)
		doors += spawn_object(/obj/effect/heretic_mansus_lock_door, position, src)
	var/list/distances = list("[visit.plan.gate_cell]" = 0)
	var/list/frontier = list(visit.plan.gate_cell)
	var/index = 1
	while(index <= length(frontier))
		var/current = frontier[index++]
		for(var/neighbor in visit.plan.cell_neighbors(current))
			if(neighbor == cell || visit.plan.doors[visit.plan.door_key(current, neighbor)] != "open" || !isnull(distances["[neighbor]"]))
				continue
			distances["[neighbor]"] = distances["[current]"] + 1
			frontier += neighbor
	var/list/options = list()
	for(var/reachable in frontier)
		if(reachable != visit.plan.gate_cell && abs(visit.plan.cell_column(reachable) - visit.plan.cell_column(cell)) + abs(visit.plan.cell_row(reachable) - visit.plan.cell_row(cell)) >= 2)
			options += reachable
	if(!length(options))
		options = frontier
	var/turf/spot
	for(var/attempt in 1 to 5)
		spot = free_spot(pick(options))
		if(spot)
			break
	if(!spot)
		unlock()
		return
	key = spawn_object(/obj/effect/heretic_mansus_device/key, spot, src, "key")
	to_chat(visit.victim, span_warning("Комната осколка заперта. Ищите ключ: он [visit.direction_text(visit.victim, spot)]."))

/datum/heretic_mansus_rule/lock/proc/take_key()
	has_key = TRUE
	visit.scenery -= key
	QDEL_NULL(key)
	to_chat(visit.victim, span_notice("Ключ у вас. Толкните запертую дверь комнаты с осколком."))
	playsound(visit.victim, visit.theme["pickup"], 40, FALSE)
	visit.update_route()

/datum/heretic_mansus_rule/lock/proc/try_unlock(mob/user)
	if(!active() || user != visit.victim || !locked_cell)
		return FALSE
	if(!has_key)
		to_chat(user, span_warning("Заперто. Нужен ключ."))
		return FALSE
	unlock()
	to_chat(user, span_notice("Замок поддаётся, двери комнаты распахиваются."))
	playsound(user, visit.theme["deposit"], 40, FALSE)
	return TRUE

/datum/heretic_mansus_rule/lock/proc/unlock()
	if(locked_cell)
		opened_cells += locked_cell
	locked_cell = null
	has_key = FALSE
	for(var/obj/effect/heretic_mansus_lock_door/door as anything in doors)
		visit.scenery -= door
		qdel(door)
	doors.Cut()
	if(key)
		visit.scenery -= key
		QDEL_NULL(key)
	visit.update_route()

/datum/heretic_mansus_rule/lock/blocks(turf/position)
	return locked_cell && (locate(/obj/effect/heretic_mansus_lock_door) in position)

/datum/heretic_mansus_rule/lock/route_target()
	if(!locked_cell || visit.carried_memory)
		return null
	if(!has_key)
		return get_turf(key)
	var/turf/closest
	for(var/obj/effect/heretic_mansus_lock_door/door as anything in doors)
		var/turf/position = get_turf(door)
		if(position.density)
			continue
		if(!closest || get_dist(visit.victim, position) < get_dist(visit.victim, closest))
			closest = position
	return closest

/datum/heretic_mansus_rule/lock/cleanup()
	doors.Cut()
	key = null

/obj/effect/heretic_mansus_device/key
	name = "key of the House"
	desc = "Наступите на ключ, чтобы подобрать его."

/obj/effect/heretic_mansus_device/key/use(mob/user)
	var/datum/heretic_mansus_rule/lock/lock = rule
	lock.take_key()

/obj/effect/heretic_mansus_lock_door
	name = "locked door"
	desc = "Дверь заперта изнутри. Толкните её, когда найдёте ключ."
	icon = HERETIC_MANSUS_RULES_ICON
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	layer = ABOVE_MOB_LAYER
	var/datum/heretic_mansus_rule/lock/rule

/obj/effect/heretic_mansus_lock_door/Initialize(mapload, datum/heretic_mansus_rule/lock/new_rule)
	. = ..()
	rule = new_rule
	rule?.visit?.apply_style(src, "door", HERETIC_MANSUS_RULES_ICON)

/obj/effect/heretic_mansus_lock_door/Destroy()
	rule = null
	return ..()

/obj/effect/heretic_mansus_lock_door/Bumped(atom/movable/bumper)
	. = ..()
	if(ismob(bumper))
		rule?.try_unlock(bumper)

/obj/effect/heretic_mansus_lock_door/attack_hand(mob/user)
	rule?.try_unlock(user)

// Пучина: прилив в южной половине.

/datum/heretic_mansus_rule/tide
	hint = "Раз в двадцать пять секунд южная половина Дома уходит под воду на десять секунд. В воде вы медленнее, а трещины видны только рябью."
	reminder = "Прилив затапливает юг Дома."
	var/flooded = FALSE
	var/list/low_turfs = list()

/datum/heretic_mansus_rule/tide/on_generate()
	for(var/turf/position as anything in visit.walkable_turfs)
		if(visit.local_row(position) > (HERETIC_MANSUS_ROOM_SIZE + 1) / 2)
			low_turfs[position] = TRUE

/datum/heretic_mansus_rule/tide/on_danger()
	schedule(CALLBACK(src, PROC_REF(warn)), HERETIC_MANSUS_TIDE_INTERVAL - HERETIC_MANSUS_TIDE_WARNING)

/datum/heretic_mansus_rule/tide/proc/warn()
	if(!active())
		return
	for(var/turf/position as anything in low_turfs)
		animate(position, color = "#a9cfdc", time = HERETIC_MANSUS_TIDE_WARNING)
	to_chat(visit.victim, span_warning("Слышен нарастающий прибой: юг Дома сейчас уйдёт под воду."))
	playsound(visit.victim, visit.theme["warning"], 40, FALSE)
	schedule(CALLBACK(src, PROC_REF(flood)), HERETIC_MANSUS_TIDE_WARNING)

/datum/heretic_mansus_rule/tide/proc/flood()
	if(!active())
		return
	flooded = TRUE
	for(var/turf/position as anything in low_turfs)
		animate(position, color = "#6f9fb3", time = 0.5 SECONDS)
	for(var/obj/effect/heretic_mansus_hazard/hazard as anything in visit.hazards)
		on_hazard(hazard)
	update_victim()
	schedule(CALLBACK(src, PROC_REF(recede)), HERETIC_MANSUS_TIDE_DURATION)

/datum/heretic_mansus_rule/tide/proc/recede()
	if(!active())
		return
	flooded = FALSE
	for(var/turf/position as anything in low_turfs)
		animate(position, color = null, time = 1 SECONDS)
	for(var/obj/effect/heretic_mansus_hazard/hazard as anything in visit.hazards)
		hazard.alpha = 255
		hazard.armed_alpha = 255
	update_victim()
	schedule(CALLBACK(src, PROC_REF(warn)), HERETIC_MANSUS_TIDE_INTERVAL - HERETIC_MANSUS_TIDE_DURATION - HERETIC_MANSUS_TIDE_WARNING)

/datum/heretic_mansus_rule/tide/proc/update_victim()
	if(QDELETED(visit.victim))
		return
	if(flooded && low_turfs[get_turf(visit.victim)])
		visit.victim.add_movespeed_modifier(/datum/movespeed_modifier/heretic_mansus_tide)
	else
		visit.victim.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_mansus_tide)

/datum/heretic_mansus_rule/tide/on_victim_moved(atom/old_loc, direction, forced)
	update_victim()

/datum/heretic_mansus_rule/tide/on_hazard(obj/effect/heretic_mansus_hazard/hazard)
	if(flooded && low_turfs[get_turf(hazard)])
		hazard.alpha = HERETIC_MANSUS_TIDE_RIPPLE_ALPHA
		hazard.armed_alpha = HERETIC_MANSUS_TIDE_RIPPLE_ALPHA

/datum/heretic_mansus_rule/tide/cleanup()
	flooded = FALSE
	update_victim()
	low_turfs.Cut()

/datum/movespeed_modifier/heretic_mansus_tide
	multiplicative_slowdown = 1.5
	movetypes = GROUND

// Стекло: отражение через центр Дома.

/datum/heretic_mansus_rule/glass
	hint = "В стекле Дома живёт ваше отражение. Оно повторяет ваши шаги зеркально через центр Дома и не должно с вами встретиться."
	reminder = "Отражение идёт зеркально через центр Дома."
	var/obj/effect/heretic_mansus_reflection/reflection

/datum/heretic_mansus_rule/glass/on_danger()
	var/turf/start = mirror_turf(get_turf(visit.victim))
	if(!visit.walkable_turfs[start])
		start = visit.entry_turf
	reflection = spawn_object(/obj/effect/heretic_mansus_reflection, start)
	reflection.appearance = visit.victim.appearance
	reflection.name = "your reflection"
	reflection.desc = "Это вы, только по ту сторону стекла. Не встречайтесь с ним."
	reflection.transform = matrix(-1, 0, 0, 0, 1, 0)
	reflection.alpha = 170
	reflection.color = "#b8d8ff"
	reflection.layer = ABOVE_MOB_LAYER
	reflection.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/heretic_mansus_rule/glass/proc/mirror_turf(turf/position)
	return visit.local_turf(HERETIC_MANSUS_ROOM_SIZE + 1 - visit.local_column(position), HERETIC_MANSUS_ROOM_SIZE + 1 - visit.local_row(position))

/datum/heretic_mansus_rule/glass/on_victim_moved(atom/old_loc, direction, forced)
	if(QDELETED(reflection))
		return
	check_meeting()
	var/turf/target = mirror_turf(get_turf(visit.victim))
	for(var/step in 1 to HERETIC_MANSUS_REFLECTION_STEPS)
		var/turf/here = get_turf(reflection)
		if(here == target || !visit.walkable_turfs[target])
			break
		var/turf/next = next_step(here, target)
		if(!next)
			break
		reflection.forceMove(next)
	check_meeting()

/datum/heretic_mansus_rule/glass/proc/next_step(turf/origin, turf/destination)
	var/list/frontier = list(destination)
	var/list/came_from = list()
	came_from[destination] = TRUE
	var/index = 1
	while(index <= length(frontier))
		var/turf/current = frontier[index++]
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current, direction)
			if(!visit.walkable_turfs[neighbor] || came_from[neighbor])
				continue
			came_from[neighbor] = current
			if(neighbor == origin)
				return current
			frontier += neighbor
	return null

/datum/heretic_mansus_rule/glass/proc/check_meeting()
	if(!QDELETED(reflection) && get_turf(reflection) == get_turf(visit.victim))
		visit.suffer_hazard(visit.victim)

/datum/heretic_mansus_rule/glass/cleanup()
	reflection = null

/obj/effect/heretic_mansus_reflection
	anchored = TRUE
	animate_movement = SLIDE_STEPS

// Кровь: тень идёт по следам.

/datum/heretic_mansus_rule/blood
	hint = "После первой доставки вы оставляете кровавые следы, и тень идёт точно по ним, быстрее обычного. Уводите её длинной петлёй."
	reminder = "Тень идёт по вашим следам."
	var/bleeding = FALSE
	var/list/steps = list()
	var/list/prints = list()

/datum/heretic_mansus_rule/blood/on_danger()
	bleeding = TRUE

/datum/heretic_mansus_rule/blood/on_victim_moved(atom/old_loc, direction, forced)
	if(!bleeding || forced || !isturf(old_loc) || !visit.walkable_turfs[old_loc])
		return
	steps += old_loc
	var/obj/effect/heretic_mansus_mark/print = spawn_object(/obj/effect/heretic_mansus_mark, old_loc, visit, "blood_step")
	print.dir = direction
	prints += print
	while(length(steps) > HERETIC_MANSUS_BLOOD_TRAIL)
		steps.Cut(1, 2)
		var/obj/effect/heretic_mansus_mark/oldest = prints[1]
		prints.Cut(1, 2)
		visit.scenery -= oldest
		qdel(oldest)

/datum/heretic_mansus_rule/blood/hunter_goal(obj/effect/heretic_mansus_hunter/hunter)
	if(!bleeding || !length(steps))
		return null
	var/position = steps.Find(get_turf(hunter))
	if(!position)
		return steps[1]
	if(position >= length(steps))
		return get_turf(visit.victim)
	return steps[position + 1]

/datum/heretic_mansus_rule/blood/hunter_step_delay(obj/effect/heretic_mansus_hunter/hunter, delay)
	return bleeding ? delay * HERETIC_MANSUS_BLOOD_HASTE : delay

/datum/heretic_mansus_rule/blood/on_hit()
	steps.Cut()
	for(var/obj/effect/heretic_mansus_mark/print as anything in prints)
		visit.scenery -= print
		qdel(print)
	prints.Cut()

/datum/heretic_mansus_rule/blood/cleanup()
	steps.Cut()
	prints.Cut()

// Эхо: слепая тень слышит бег.

/datum/heretic_mansus_rule/echo
	hint = "Тень здесь слепа, но слышит бег за девять клеток. Шаги она слышит за две клетки. Сбор и доставка осколка тоже шумят."
	reminder = "Идите шагом: бег слышен издалека."

/datum/heretic_mansus_rule/echo/hunter_sees(obj/effect/heretic_mansus_hunter/hunter)
	return FALSE

/datum/heretic_mansus_rule/echo/on_victim_moved(atom/old_loc, direction, forced)
	if(forced)
		return
	make_noise(get_turf(visit.victim), visit.victim.m_intent == MOVE_INTENT_RUN ? HERETIC_MANSUS_RUN_NOISE : HERETIC_MANSUS_WALK_NOISE)

/datum/heretic_mansus_rule/echo/on_noise(turf/source)
	make_noise(source, HERETIC_MANSUS_TASK_NOISE)

/datum/heretic_mansus_rule/echo/proc/make_noise(turf/source, radius)
	for(var/obj/effect/heretic_mansus_hunter/hunter as anything in visit.hunters)
		if(get_dist(hunter, source) <= radius)
			hunter.last_seen_turf = source
			hunter.search_turf = null

// Песок: песочные часы замораживают тени за счёт времени.

/datum/heretic_mansus_rule/sand
	hint = "В комнатах стоят песочные часы. Постойте у них секунду, чтобы перевернуть: тени замрут на шесть секунд, но Дом заберёт у вас десять секунд. Каждые часы переворачиваются один раз."
	reminder = "Часы: тени замирают, время уходит."

/datum/heretic_mansus_rule/sand/on_generate()
	var/list/cells = shuffle(ordinary_cells())
	for(var/index in 1 to min(HERETIC_MANSUS_HOURGLASSES, length(cells)))
		var/turf/position = free_spot(cells[index])
		if(position)
			spawn_object(/obj/effect/heretic_mansus_device/hourglass, position, src, "hourglass")

/datum/heretic_mansus_rule/sand/proc/flip()
	for(var/obj/effect/heretic_mansus_hunter/hunter as anything in visit.hunters)
		hunter.ready_at = max(hunter.ready_at, world.time + HERETIC_MANSUS_HOURGLASS_FREEZE)
		animate(hunter, alpha = 60, time = 0.3 SECONDS)
	visit.shorten_visit(HERETIC_MANSUS_HOURGLASS_COST)
	to_chat(visit.victim, span_notice("Песок замер. Тени застыли на шесть секунд, а времени до конца испытания стало на десять секунд меньше."))
	playsound(visit.victim, visit.theme["deposit"], 40, FALSE)

/obj/effect/heretic_mansus_device/hourglass
	name = "hourglass of the House"
	desc = "Постойте рядом секунду, чтобы перевернуть часы: тени замрут, но Дом заберёт у вас время."

/obj/effect/heretic_mansus_device/hourglass/ready(mob/user)
	if(length(rule.visit.hunters))
		return TRUE
	balloon_alert(user, "теней нет")
	return FALSE

/obj/effect/heretic_mansus_device/hourglass/use(mob/user)
	var/datum/heretic_mansus_rule/sand/sand = rule
	rule.visit.apply_style(src, "hourglass_spent", HERETIC_MANSUS_RULES_ICON)
	desc = "Песок в часах замер навсегда."
	sand.flip()

// Воск: свет тает, свечи разжигают его снова.

/datum/heretic_mansus_rule/wax
	hint = "Свечи Дома тают: чем дольше вы бродите, тем уже круг света. Встаньте на свечу, чтобы разжечь его снова на тридцать секунд."
	reminder = "Свеча под ногами возвращает свет."
	var/melting = FALSE
	var/darkness = 0
	var/bright_until = 0

/datum/heretic_mansus_rule/wax/on_danger()
	melting = TRUE
	schedule(CALLBACK(src, PROC_REF(melt)), HERETIC_MANSUS_WAX_INTERVAL)

/datum/heretic_mansus_rule/wax/proc/melt()
	if(!active())
		return
	schedule(CALLBACK(src, PROC_REF(melt)), HERETIC_MANSUS_WAX_INTERVAL)
	if(world.time < bright_until || darkness >= HERETIC_MANSUS_WAX_MAX_DARKNESS)
		return
	darkness++
	update_overlay()
	to_chat(visit.victim, span_warning("Свет вокруг вас оседает, как оплывший воск."))

/datum/heretic_mansus_rule/wax/proc/update_overlay()
	if(QDELETED(visit.victim))
		return
	if(darkness)
		visit.victim.overlay_fullscreen(HERETIC_MANSUS_WAX_OVERLAY, /atom/movable/screen/fullscreen/scaled/impaired, darkness)
	else
		visit.victim.clear_fullscreen(HERETIC_MANSUS_WAX_OVERLAY)

/datum/heretic_mansus_rule/wax/on_victim_moved(atom/old_loc, direction, forced)
	if(!melting || !(locate(/obj/effect/heretic_mansus_candle) in get_turf(visit.victim)))
		return
	bright_until = world.time + HERETIC_MANSUS_WAX_RELIGHT
	if(!darkness)
		return
	darkness = 0
	update_overlay()
	to_chat(visit.victim, span_notice("Свеча вспыхивает, и круг света снова широк."))

/datum/heretic_mansus_rule/wax/cleanup()
	darkness = 0
	update_overlay()

// Дух: освобождённые души уводят тени.

/datum/heretic_mansus_rule/spirit
	hint = "В клетках томятся души. Постойте у клетки секунду, чтобы открыть её: душа метнётся прочь, и тени восемь секунд будут гнаться за ней, а не за вами."
	reminder = "Открытая клетка уводит тени за душой."
	var/obj/effect/heretic_mansus_soul/decoy
	var/decoy_until = 0

/datum/heretic_mansus_rule/spirit/on_generate()
	var/list/cells = shuffle(ordinary_cells())
	for(var/index in 1 to min(HERETIC_MANSUS_SPIRIT_CAGES, length(cells)))
		var/turf/position = free_spot(cells[index])
		if(position)
			spawn_object(/obj/effect/heretic_mansus_device/cage, position, src, "cage")

/datum/heretic_mansus_rule/spirit/proc/release(turf/position)
	if(decoy)
		visit.scenery -= decoy
		QDEL_NULL(decoy)
	decoy = spawn_object(/obj/effect/heretic_mansus_soul, position)
	visit.apply_style(decoy, "soul", HERETIC_MANSUS_RULES_ICON)
	decoy_until = world.time + HERETIC_MANSUS_SPIRIT_DECOY
	to_chat(visit.victim, span_notice("Душа вырывается из клетки и мечется прочь. Тени бросаются за ней."))
	playsound(position, visit.theme["pickup"], 45, FALSE)
	schedule(CALLBACK(src, PROC_REF(flutter)), HERETIC_MANSUS_SPIRIT_STEP)

/datum/heretic_mansus_rule/spirit/proc/flutter()
	if(!active() || QDELETED(decoy))
		return
	if(world.time >= decoy_until)
		visit.scenery -= decoy
		QDEL_NULL(decoy)
		return
	var/turf/here = get_turf(decoy)
	var/turf/best
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(here, direction)
		if(!visit.walkable_turfs[neighbor] || visit.is_safe(neighbor))
			continue
		if(!best || get_dist(neighbor, visit.victim) + rand(0, 2) > get_dist(best, visit.victim))
			best = neighbor
	if(best)
		decoy.Move(best, get_dir(here, best), DELAY_TO_GLIDE_SIZE(HERETIC_MANSUS_SPIRIT_STEP))
	schedule(CALLBACK(src, PROC_REF(flutter)), HERETIC_MANSUS_SPIRIT_STEP)

/datum/heretic_mansus_rule/spirit/hunter_goal(obj/effect/heretic_mansus_hunter/hunter)
	if(QDELETED(decoy) || world.time >= decoy_until || get_dist(hunter, decoy) > HERETIC_MANSUS_SPIRIT_LURE_RANGE)
		return null
	return get_turf(decoy)

/datum/heretic_mansus_rule/spirit/cleanup()
	decoy = null

/obj/effect/heretic_mansus_device/cage
	name = "cage of a stranger's soul"
	desc = "Внутри мечется чужая душа. Постойте рядом секунду, чтобы открыть клетку."

/obj/effect/heretic_mansus_device/cage/use(mob/user)
	var/datum/heretic_mansus_rule/spirit/spirit = rule
	rule.visit.apply_style(src, "cage_open", HERETIC_MANSUS_RULES_ICON)
	desc = "Клетка пуста."
	spirit.release(get_turf(src))

/obj/effect/heretic_mansus_soul
	name = "freed soul"
	desc = "Чужая душа мечется по Дому, и тени идут за ней."
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	animate_movement = SLIDE_STEPS
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

#undef HERETIC_MANSUS_EMBER_DELAY
#undef HERETIC_MANSUS_EMBER_FLARE
#undef HERETIC_MANSUS_EMBER_TRAIL
#undef HERETIC_MANSUS_RUST_PLATES
#undef HERETIC_MANSUS_RUST_COLLAPSE
#undef HERETIC_MANSUS_RUST_HOLE
#undef HERETIC_MANSUS_FLESH_OPEN
#undef HERETIC_MANSUS_FLESH_CLOSED
#undef HERETIC_MANSUS_FLESH_WARNING
#undef HERETIC_MANSUS_BLADE_TRAPS
#undef HERETIC_MANSUS_BLADE_CYCLE
#undef HERETIC_MANSUS_BLADE_WARNING
#undef HERETIC_MANSUS_BLADE_STRIKE
#undef HERETIC_MANSUS_BLADE_SPACING
#undef HERETIC_MANSUS_MOON_REFLECTIONS
#undef HERETIC_MANSUS_PORTAL_PAIRS
#undef HERETIC_MANSUS_PORTAL_COOLDOWN
#undef HERETIC_MANSUS_TIDE_INTERVAL
#undef HERETIC_MANSUS_TIDE_DURATION
#undef HERETIC_MANSUS_TIDE_WARNING
#undef HERETIC_MANSUS_TIDE_RIPPLE_ALPHA
#undef HERETIC_MANSUS_REFLECTION_STEPS
#undef HERETIC_MANSUS_BLOOD_TRAIL
#undef HERETIC_MANSUS_BLOOD_HASTE
#undef HERETIC_MANSUS_RUN_NOISE
#undef HERETIC_MANSUS_WALK_NOISE
#undef HERETIC_MANSUS_TASK_NOISE
#undef HERETIC_MANSUS_HOURGLASSES
#undef HERETIC_MANSUS_HOURGLASS_FREEZE
#undef HERETIC_MANSUS_HOURGLASS_COST
#undef HERETIC_MANSUS_WAX_INTERVAL
#undef HERETIC_MANSUS_WAX_RELIGHT
#undef HERETIC_MANSUS_WAX_MAX_DARKNESS
#undef HERETIC_MANSUS_WAX_OVERLAY
#undef HERETIC_MANSUS_SPIRIT_CAGES
#undef HERETIC_MANSUS_SPIRIT_DECOY
#undef HERETIC_MANSUS_SPIRIT_LURE_RANGE
#undef HERETIC_MANSUS_SPIRIT_STEP
#undef HERETIC_MANSUS_INTERACT_TIME
#undef HERETIC_MANSUS_DURATION
#undef HERETIC_MANSUS_ECHO_TINT
#undef HERETIC_MANSUS_RECALL_TIME
#undef HERETIC_MANSUS_ROOM_SIZE
#undef HERETIC_MANSUS_GRID
#undef HERETIC_MANSUS_CELL
#undef HERETIC_MANSUS_CELL_STRIDE
#undef HERETIC_MANSUS_EXTRA_EDGES
#undef HERETIC_MANSUS_MEMORIES
#undef HERETIC_MANSUS_WARNING_TIME
#undef HERETIC_MANSUS_HAZARD_LIFETIME
#undef HERETIC_MANSUS_HAZARD_LINE
#undef HERETIC_MANSUS_HIT_GRACE
#undef HERETIC_MANSUS_HUNTER_GRACE
#undef HERETIC_MANSUS_GATE_SAFETY
#undef HERETIC_MANSUS_TRAIL_LENGTH
#undef HERETIC_MANSUS_TRAIL_CARRY_LENGTH
#undef HERETIC_MANSUS_FINAL_PRESSURE
#undef HERETIC_MANSUS_HUNTER_STEP
#undef HERETIC_MANSUS_HUNTER_FAST_STEP
#undef HERETIC_MANSUS_HUNTER_DISTANCE
#undef HERETIC_MANSUS_SIGHT_RANGE
#undef HERETIC_MANSUS_SEARCH_RANGE
#undef HERETIC_MANSUS_DISPEL_DELAY
#undef HERETIC_MANSUS_NAME_RANGE
#undef HERETIC_MANSUS_NAME_CLEAR_RANGE
#undef HERETIC_MANSUS_PENALTY_PER_MEMORY
#undef HERETIC_MANSUS_ALERT
#undef HERETIC_MANSUS_RULES_ICON
#undef HERETIC_MANSUS_GUIDANCE_ICON

// Regression tests for the Drift 2.0 space-movement fixes.
// Each datum proves one of the reported problems is fixed:
//  - mecha_inertia_mass:    mechs have mass (were drifting like a 70kg human)
//  - drift_recoil_cap:      firing can't "click to accelerate" and can't brake movement drift
//  - drift_glide_clamp:     fast drift can't make the sprite visually "teleport"
//  - mecha_stabilizer_no_drift: stabilizers stop drift on voluntary steps (wall-braced too)
//  - mecha_turn_decoupled:  mechs can turn in zero-g and turning doesn't eat the move cooldown (#6)
//  - mecha_drift_stepsound: a drifting mech doesn't play its walking sound on every drift tick
//  - drift_glide_no_starve: holding a thrust key while drifting doesn't freeze the mech in place
//  - self_thrust_cap:       voluntary steps can't accelerate past the thruster's own ceiling
//  - thrust_source_registry: several engines on one carrier compose by the best of them
//  - drift_handoff_on_release: letting go of a tow hands the cargo the tow's vector
//  - space_z_transition_no_inertia_latch: пересечение края уровня не запирает движок инерции
//  - space_z_transition_keeps_drift: дрейф переживает смену z-уровня

/// A multi-ton exosuit must resist nudges and have a capped top drift speed, unlike a human (defaults 1/1).
/datum/unit_test/mecha_inertia_mass/Run()
	var/obj/vehicle/sealed/mecha/working/ripley/ripley = allocate(/obj/vehicle/sealed/mecha/working/ripley)
	TEST_ASSERT_EQUAL(ripley.inertia_force_weight, 8, "mechs must resist impulses (inertia_force_weight should be 8)")
	TEST_ASSERT_EQUAL(ripley.inertia_move_multiplier, 3, "mechs must have a capped top drift speed (inertia_move_multiplier should be 3)")

/// Recoil from firing must never exceed the recoil cap and must never brake drift the player built by moving.
/datum/unit_test/drift_recoil_cap/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)

	// Build movement-style drift first (each voluntary nudge adds ~1 force, weight 1 for a plain item).
	var/obj/item/pen/mover = allocate(/obj/item/pen, center)
	mover.AddElement(/datum/element/forced_gravity, 0) // weightless, so drift accumulates instead of being killed by gravity
	for(var/i in 1 to 5)
		mover.newtonian_move(NORTH, drift_force = 1, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(mover.drift_handler, "five voluntary nudges should have started a drift")
	var/built_force = mover.drift_handler.drift_force
	TEST_ASSERT(built_force >= 4.5, "five north nudges should build drift_force to ~5, got [built_force]")

	// Firing while already moving must neither reduce (brake) nor increase the existing drift.
	mover.newtonian_move(NORTH, drift_force = 1, controlled_cap = INERTIA_FORCE_RECOIL_CAP, force_loop = FALSE)
	var/after_recoil = mover.drift_handler.drift_force
	TEST_ASSERT(after_recoil >= built_force - 0.01, "recoil must not brake movement-built drift ([after_recoil] < [built_force])")
	TEST_ASSERT(after_recoil <= built_force + 0.01, "recoil must not push drift past what movement built ([after_recoil] > [built_force])")

	// Spam-firing from rest must plateau at the recoil cap, not ratchet up to the global cap.
	var/turf/elsewhere = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/item/pen/clicker = allocate(/obj/item/pen, elsewhere)
	clicker.AddElement(/datum/element/forced_gravity, 0)
	for(var/i in 1 to 8)
		clicker.newtonian_move(NORTH, drift_force = 1, controlled_cap = INERTIA_FORCE_RECOIL_CAP, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(clicker.drift_handler, "recoil should have started a drift")
	TEST_ASSERT(clicker.drift_handler.drift_force <= INERTIA_FORCE_RECOIL_CAP + 0.01, "spam-firing must not exceed the recoil cap, got [clicker.drift_handler.drift_force]")

/// glide_size must be clamped so high-speed drift can't make the sprite slide past one tile per frame ("teleport").
/datum/unit_test/drift_glide_clamp/Run()
	var/obj/item/pen/thing = allocate(/obj/item/pen)
	thing.set_glide_size(MAX_GLIDE_SIZE + 64)
	TEST_ASSERT_EQUAL(thing.glide_size, MAX_GLIDE_SIZE, "glide_size above the icon size must clamp to MAX_GLIDE_SIZE")
	thing.set_glide_size(8)
	TEST_ASSERT_EQUAL(thing.glide_size, 8, "a normal glide_size must be left untouched")
	thing.set_glide_size(0)
	TEST_ASSERT_EQUAL(thing.glide_size, 0, "an instant move (glide_size 0) must be preserved")

/// Stabilizers must cancel drift (hold position) only when the mech has functional, powered thrusters.
/datum/unit_test/mecha_stabilizer/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/vehicle/sealed/mecha/working/ripley/ripley = allocate(/obj/vehicle/sealed/mecha/working/ripley, center)
	ripley.AddElement(/datum/element/forced_gravity, 0) // weightless, so the base Process_Spacemove reports "still drifting"
	ripley.step_energy_drain = 10
	TEST_ASSERT_NOTNULL(ripley.cell, "test mech should spawn with a power cell")
	ripley.cell.charge = ripley.cell.maxcharge

	var/obj/item/mecha_parts/mecha_equipment/thrusters/rcs = new /obj/item/mecha_parts/mecha_equipment/thrusters(ripley)
	rcs.attach(ripley)
	TEST_ASSERT_EQUAL(ripley.active_thrusters, rcs, "the attached thruster should become the active set")

	ripley.stabilizers = FALSE
	TEST_ASSERT(!ripley.Process_Spacemove(NORTH, continuous_move = TRUE), "stabilizers off: the mech must keep drifting (Process_Spacemove returns FALSE)")

	ripley.stabilizers = TRUE
	TEST_ASSERT(ripley.Process_Spacemove(NORTH, continuous_move = TRUE), "stabilizers on + thrusters + power: drift must be cancelled (Process_Spacemove returns TRUE)")

	ripley.cell.charge = 0
	TEST_ASSERT(!ripley.Process_Spacemove(NORTH, continuous_move = TRUE), "stabilizers must fail without power")

/// With stabilizers on, a voluntary step must not start space drift.
/datum/unit_test/mecha_stabilizer_no_drift/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/vehicle/sealed/mecha/working/ripley/ripley = allocate(/obj/vehicle/sealed/mecha/working/ripley, center)
	ripley.AddElement(/datum/element/forced_gravity, 0)
	ripley.step_energy_drain = 10
	ripley.cell.charge = ripley.cell.maxcharge
	var/obj/item/mecha_parts/mecha_equipment/thrusters/rcs = new /obj/item/mecha_parts/mecha_equipment/thrusters(ripley)
	rcs.attach(ripley)
	ripley.stabilizers = TRUE
	TEST_ASSERT(ripley.vehicle_move(NORTH), "voluntary move with stabilizers must succeed")
	TEST_ASSERT_NULL(ripley.drift_handler, "stabilizers must prevent drift after a voluntary step")

	// Braced near a wall: old code used push-off backup and still built drift.
	var/obj/structure/window/reinforced/brace = allocate(/obj/structure/window/reinforced, get_step(center, SOUTH))
	brace.setAnchored(TRUE)
	ripley.forceMove(center)
	ripley.setDir(NORTH)
	TEST_ASSERT(ripley.vehicle_move(NORTH), "stabilizers must allow movement when braced near a wall")
	TEST_ASSERT_NULL(ripley.drift_handler, "stabilizers must prevent drift when braced near a wall")

/// #6: a mech must be able to rotate even when it cannot move, and rotating must not consume the move cooldown.
/datum/unit_test/mecha_turn_decoupled/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/vehicle/sealed/mecha/working/ripley/ripley = allocate(/obj/vehicle/sealed/mecha/working/ripley, center)
	ripley.AddElement(/datum/element/forced_gravity, 0) // weightless and (below) thruster-less: voluntary movement is impossible here
	ripley.active_thrusters = null
	ripley.strafe = FALSE
	ripley.setDir(NORTH)

	// Core fix: the turn happens even though Process_Spacemove would block any actual movement.
	TEST_ASSERT(ripley.vehicle_move(EAST), "a non-strafe turn must succeed even when the mech cannot move")
	TEST_ASSERT_EQUAL(ripley.dir, EAST, "the mech should have rotated to face EAST")
	TEST_ASSERT(COOLDOWN_FINISHED(ripley, cooldown_vehicle_move), "turning must not start the movement cooldown")

	// The turn uses its own (separate) cooldown: an immediate second turn is blocked, facing unchanged.
	ripley.vehicle_move(SOUTH)
	TEST_ASSERT_EQUAL(ripley.dir, EAST, "a second turn within the turn cooldown must be blocked")

	// Strafe mode without a held Alt must NOT rotate: the mech keeps its facing while trying to strafe.
	ripley.cooldown_vehicle_turn = 0
	ripley.strafe = TRUE
	ripley.setDir(NORTH)
	ripley.vehicle_move(EAST)
	TEST_ASSERT_EQUAL(ripley.dir, NORTH, "strafe mode without Alt must not rotate the mech")

/// A drifting mech played its walking sound on every drift tick. play_stepsound must skip inertia (drift)
/// moves and consume step_silent (set for thrust / push-off) - neither of which is an actual footstep.
/datum/unit_test/mecha_drift_stepsound/Run()
	var/obj/vehicle/sealed/mecha/working/ripley/ripley = allocate(/obj/vehicle/sealed/mecha/working/ripley)

	// Thrust / push-off marks step_silent; play_stepsound must eat it (and stay silent) rather than walk-sound.
	ripley.step_silent = TRUE
	ripley.play_stepsound()
	TEST_ASSERT(!ripley.step_silent, "play_stepsound must consume step_silent (thrust/push-off is not a footstep)")

	// A drift-loop move sets inertia_moving; play_stepsound must be a no-op and must not clear the flag.
	ripley.inertia_moving = TRUE
	ripley.play_stepsound()
	TEST_ASSERT(ripley.inertia_moving, "play_stepsound must not run its body during a drift (inertia) move")

/// Holding a thrust/move key while drifting froze the mech: every voluntary step fires a glide update and the
/// drift handler re-paused its move loop each time, shoving the next fire past the key-repeat interval forever.
/// The handler must defer the loop at most once per cycle so the drift keeps advancing.
/datum/unit_test/drift_glide_no_starve/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/item/pen/thing = allocate(/obj/item/pen, center)
	thing.AddElement(/datum/element/forced_gravity, 0) // weightless, so the drift actually starts
	thing.newtonian_move(NORTH, drift_force = 5, force_loop = FALSE)
	var/datum/drift_handler/handler = thing.drift_handler
	TEST_ASSERT_NOTNULL(handler, "newtonian_move should have started a drift")
	TEST_ASSERT_NOTNULL(handler.drifting_loop, "the drift should have a move loop")

	// First glide change of the cycle defers the loop once (the intended visual sync) and marks it delayed.
	// Clear both gating flags so the call is deterministic regardless of the loop's init-time running state.
	handler.delayed = FALSE
	handler.ignore_next_glide = FALSE
	handler.handle_glidesize_update(thing, 8)
	TEST_ASSERT(handler.delayed, "an external glide change while drifting should defer the drift loop once")

	// Already delayed: further glide changes (a held key) must be ignored, so the loop's timer isn't pushed out.
	var/locked_timer = handler.drifting_loop.timer
	handler.handle_glidesize_update(thing, 4)
	handler.handle_glidesize_update(thing, 2)
	TEST_ASSERT_EQUAL(handler.drifting_loop.timer, locked_timer, "repeated glide changes must not keep re-deferring the drift loop (anti-starvation)")

/// Шаги в невесомости обязаны упираться в потолок собственной тяги. Без него каждый шаг клался
/// в общий INERTIA_FORCE_CAP, и полтора десятка шагов подряд выводили на тайл за тик - втрое
/// быстрее станционного бега (баг-репорт "Сломанное ускорение джетов в космосе", 25.07.2026).
/datum/unit_test/self_thrust_cap/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/item/pen/drifter = allocate(/obj/item/pen, center)
	drifter.AddElement(/datum/element/forced_gravity, 0) // невесомость, иначе дрейф не копится
	TEST_ASSERT_EQUAL(drifter.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "у предмета без двигателя должен быть потолок голого толчка")

	// Хук движения зовём напрямую: полигон - площадка 5x5, двух десятков шагов на разгон в ней нет.
	drifter.Moved(center, NORTH)
	TEST_ASSERT_NOTNULL(drifter.drift_handler, "первый шаг в невесомости должен был начать дрейф")
	// Замораживаем цикл: проверяем накопление силы, а не сам полёт, и уезжать с полигона незачем.
	drifter.drift_handler.drifting_loop.pause_for(10 SECONDS)
	for(var/i in 1 to 20)
		drifter.Moved(center, NORTH)
	var/built_force = drifter.drift_handler.drift_force
	TEST_ASSERT(built_force <= INERTIA_THRUST_CAP_UNAIDED + 0.01, "собственная тяга не должна разгонять выше своего потолка, получили [built_force]")
	TEST_ASSERT(built_force >= INERTIA_THRUST_CAP_UNAIDED - 0.01, "двадцать шагов обязаны довести дрейф до потолка, получили [built_force]")

	// Внешний импульс (взрыв, отдача) выше потолка остаётся: шаг оттуда не должен работать тормозом.
	var/turf/elsewhere = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/item/pen/blasted = allocate(/obj/item/pen, elsewhere)
	blasted.AddElement(/datum/element/forced_gravity, 0)
	blasted.newtonian_move(NORTH, drift_force = 10, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(blasted.drift_handler, "внешний импульс должен был начать дрейф")
	var/blast_force = blasted.drift_handler.drift_force
	blasted.drift_handler.drifting_loop.pause_for(10 SECONDS)
	blasted.Moved(elsewhere, NORTH)
	TEST_ASSERT(blasted.drift_handler.drift_force >= blast_force - 0.01, "шаг не должен срезать дрейф от внешнего импульса ([blasted.drift_handler.drift_force] < [blast_force])")

/// Носитель может нести несколько двигателей сразу; потолок задаёт лучший из работающих, и
/// выключенный не должен затирать цифры оставшегося.
/datum/unit_test/thrust_source_registry/Run()
	var/obj/item/pen/carrier = allocate(/obj/item/pen)
	var/obj/item/pen/weak_engine = allocate(/obj/item/pen)
	var/obj/item/pen/strong_engine = allocate(/obj/item/pen)

	TEST_ASSERT_EQUAL(carrier.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "без источников потолок должен быть голым")
	carrier.register_thrust_source(weak_engine, cap = INERTIA_THRUST_CAP_JETPACK)
	TEST_ASSERT_EQUAL(carrier.self_thrust_cap, INERTIA_THRUST_CAP_JETPACK, "один двигатель должен поднять потолок")
	carrier.register_thrust_source(strong_engine, cap = INERTIA_THRUST_CAP_JETPACK_FULL)
	TEST_ASSERT_EQUAL(carrier.self_thrust_cap, INERTIA_THRUST_CAP_JETPACK_FULL, "два источника берутся по лучшему")
	carrier.unregister_thrust_source(strong_engine)
	TEST_ASSERT_EQUAL(carrier.self_thrust_cap, INERTIA_THRUST_CAP_JETPACK, "снятие лучшего должно вернуть потолок оставшегося")
	carrier.unregister_thrust_source(weak_engine)
	TEST_ASSERT_EQUAL(carrier.self_thrust_cap, INERTIA_THRUST_CAP_UNAIDED, "без источников потолок возвращается к голому")

/// Отпущенный груз обязан унести вектор буксира. Иначе разжатая рука читается как рывок:
/// буксир идёт на крейсерской, буксируемый мгновенно проседает до скорости голого толчка.
/datum/unit_test/drift_handoff_on_release/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/item/pen/tug = allocate(/obj/item/pen, center)
	tug.AddElement(/datum/element/forced_gravity, 0)
	tug.newtonian_move(NORTH, drift_force = 4, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(tug.drift_handler, "у буксира должен был начаться дрейф")

	var/obj/item/pen/cargo = allocate(/obj/item/pen, get_step(center, SOUTH))
	cargo.AddElement(/datum/element/forced_gravity, 0)
	TEST_ASSERT_NULL(cargo.drift_handler, "груз до передачи никуда не летит")
	TEST_ASSERT(tug.hand_off_drift(cargo), "буксир обязан передать вектор отпущенному грузу")
	TEST_ASSERT_NOTNULL(cargo.drift_handler, "у груза должен появиться дрейф")
	TEST_ASSERT(cargo.drift_handler.drift_force >= 3.9, "груз должен унести силу буксира, получил [cargo.drift_handler.drift_force]")

	// Стоящий на месте передавать нечего - и молча, без пустого обработчика на грузе.
	var/obj/item/pen/parked = allocate(/obj/item/pen, get_step(center, EAST))
	var/obj/item/pen/idle_cargo = allocate(/obj/item/pen, get_step(center, WEST))
	TEST_ASSERT(!parked.hand_off_drift(idle_cargo), "неподвижный буксир не передаёт импульс")
	TEST_ASSERT_NULL(idle_cargo.drift_handler, "груз неподвижного буксира не должен получить дрейф")

/// Ставит на полигоне турф-переход на соседний z-уровень и возвращает его. Вернуть тип обратно - на вызывающем.
/datum/unit_test/proc/make_space_transition(turf/edge, turf/landing)
	var/turf/open/space/transit = edge.ChangeTurf(/turf/open/space)
	transit.destination_x = landing.x
	transit.destination_y = landing.y
	transit.destination_z = landing.z
	return transit

/**
 * Переход через край космического z-уровня взводил `inertia_moving` и не снимал его никогда.
 *
 * Дальше `Moved()` навсегда переставал звать `newtonian_move`, дрейф не набирался ни от одного
 * шага, и полёт выглядел ровно так, будто стабилизация включена намертво - а её переключатель
 * при этом ничего не менял, потому что гасить было нечего (баг-репорт 29.07.2026).
 */
/datum/unit_test/space_z_transition_no_inertia_latch/Run()
	var/turf/landing = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/turf/edge = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 3, run_loc_floor_bottom_left.z)
	var/edge_type = edge.type
	var/turf/open/space/transit = make_space_transition(edge, landing)

	// Стабилизированный полёт: обработчика дрейфа нет, моб просто шагает по курсу.
	var/obj/item/pen/traveller = allocate(/obj/item/pen, get_step(transit, SOUTH))
	traveller.AddElement(/datum/element/forced_gravity, 0) // невесомость, иначе дрейфа не будет вовсе
	TEST_ASSERT_NULL(traveller.drift_handler, "до перехода дрейфа быть не должно")

	traveller.Move(transit, NORTH)

	var/latched = traveller.inertia_moving
	// Свободный полёт после перехода: шаг обязан снова набирать дрейф.
	traveller.Moved(traveller.loc, NORTH)
	var/rebuilt_drift = !isnull(traveller.drift_handler)
	transit.ChangeTurf(edge_type)

	TEST_ASSERT(!latched, "переход через край z-уровня не должен оставлять inertia_moving взведённым")
	TEST_ASSERT(rebuilt_drift, "после смены уровня шаг обязан снова набирать дрейф")

/// Перенос через край - часть того же полёта: обработчик дрейфа обязан пережить смену z-уровня, а не глохнуть.
/datum/unit_test/space_z_transition_keeps_drift/Run()
	var/turf/landing = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	var/turf/edge = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y + 3, run_loc_floor_bottom_left.z)
	var/edge_type = edge.type
	var/turf/open/space/transit = make_space_transition(edge, landing)

	var/obj/item/pen/traveller = allocate(/obj/item/pen, get_step(transit, SOUTH))
	traveller.AddElement(/datum/element/forced_gravity, 0)
	traveller.newtonian_move(NORTH, drift_force = 3, force_loop = FALSE)
	TEST_ASSERT_NOTNULL(traveller.drift_handler, "до перехода дрейф должен идти")
	traveller.drift_handler.drifting_loop.pause_for(10 SECONDS) // проверяем сам переход, а не полёт по полигону
	var/force_before = traveller.drift_handler.drift_force

	traveller.Move(transit, NORTH)

	var/kept_drift = !isnull(traveller.drift_handler)
	var/force_after = kept_drift ? traveller.drift_handler.drift_force : 0
	transit.ChangeTurf(edge_type)

	TEST_ASSERT(kept_drift, "смена z-уровня не должна глушить дрейф")
	TEST_ASSERT(force_after >= force_before - 0.01, "переход не должен срезать набранную силу дрейфа ([force_after] < [force_before])")
	TEST_ASSERT(force_after <= force_before + 0.01, "переход не должен доливать силу дрейфа ([force_after] > [force_before])")

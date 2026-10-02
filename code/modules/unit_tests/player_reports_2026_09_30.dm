/// Deleting a pipe expels every holder inside it, not only the first one.
/datum/unit_test/disposal_pipe_destroy_expels_every_holder

/datum/unit_test/disposal_pipe_destroy_expels_every_holder/Run()
	var/obj/structure/disposalpipe/segment/pipe = new(run_loc_floor_bottom_left)
	pipe.dpdir = NORTH | SOUTH
	var/obj/structure/disposalholder/first_holder = new(pipe)
	var/obj/structure/disposalholder/second_holder = new(pipe)
	var/obj/item/crowbar/first_item = allocate(/obj/item/crowbar)
	var/obj/item/crowbar/second_item = allocate(/obj/item/crowbar)
	first_item.forceMove(first_holder)
	second_item.forceMove(second_holder)

	qdel(pipe)

	TEST_ASSERT(!QDELETED(first_item) && isturf(first_item.loc), "The first holder's contents must land on a turf")
	TEST_ASSERT(!QDELETED(second_item) && isturf(second_item.loc), "The second holder's contents must land on a turf, not be deleted with the pipe")

/// Planting resets the harvest counter left by the previous plant, so fast-maturing grass can be harvested.
/datum/unit_test/hydroponics_planting_resets_lastproduce

/datum/unit_test/hydroponics_planting_resets_lastproduce/Run()
	var/obj/machinery/hydroponics/constructable/tray = allocate(/obj/machinery/hydroponics/constructable)
	var/mob/living/carbon/human/gardener = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/seeds/grass/seeds = allocate(/obj/item/seeds/grass)
	gardener.put_in_active_hand(seeds)
	tray.lastproduce = 60

	tray.attackby(seeds, gardener)

	TEST_ASSERT_EQUAL(tray.myseed, seeds, "Sanity: the seeds must be planted")
	TEST_ASSERT_EQUAL(tray.lastproduce, 0, "A fresh plant must not inherit the previous plant's harvest counter")

/// The end-round heart lookup finds characters with Cyrillic names.
/datum/unit_test/heart_nominee_lookup_cyrillic

/datum/unit_test/heart_nominee_lookup_cyrillic/Run()
	var/mob/living/carbon/human/nominee = allocate(/mob/living/carbon/human)
	nominee.real_name = "Иван Петров"
	nominee.name = nominee.real_name
	var/mob/living/carbon/human/latin_nominee = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	latin_nominee.real_name = "John Doe-Smith"
	latin_nominee.name = latin_nominee.real_name

	TEST_ASSERT(nominee in heart_nominee_lookup("петров"), "A Cyrillic surname must match")
	TEST_ASSERT(nominee in heart_nominee_lookup(lowertext("Иван")), "A Cyrillic forename must match")
	TEST_ASSERT(latin_nominee in heart_nominee_lookup("doe-smith"), "A Latin surname must still match")

/// Every recipe listed in the crafting menu can actually produce something.
/datum/unit_test/crafting_listed_recipes_have_results

/datum/unit_test/crafting_listed_recipes_have_results/Run()
	for(var/datum/crafting_recipe/recipe as anything in GLOB.crafting_recipes)
		if(recipe.name == "")
			continue
		if(!ispath(recipe.result))
			TEST_FAIL("[recipe.type] ([recipe.name]) is listed in the crafting menu without a result")

/// Cleanbots target the wrapping shreds left by unwrapped parcels.
/datum/unit_test/cleanbot_targets_wrapping

/datum/unit_test/cleanbot_targets_wrapping/Run()
	var/mob/living/simple_animal/bot/cleanbot/bot = allocate(/mob/living/simple_animal/bot/cleanbot)
	bot.get_targets()
	TEST_ASSERT(bot.target_types[/obj/effect/decal/cleanable/wrapping], "Wrapping shreds must be cleanbot targets")

/// A portable pump moves gas on the first tick even after its internal pump went into idle backoff.
/datum/unit_test/portable_pump_ignores_internal_idle_backoff

/datum/unit_test/portable_pump_ignores_internal_idle_backoff/Run()
	var/obj/machinery/portable_atmospherics/pump/portable = allocate(/obj/machinery/portable_atmospherics/pump)
	var/obj/item/tank/internals/oxygen/empty/tank = allocate(/obj/item/tank/internals/oxygen/empty)
	tank.forceMove(portable)
	portable.holding = tank
	portable.air_contents.adjust_moles(GAS_O2, 100)
	portable.air_contents.set_temperature(T20C)
	portable.direction = "in"
	portable.on = TRUE
	portable.pump.atmos_idle_until = world.time + 2 MINUTES

	portable.process_atmos()

	TEST_ASSERT(tank.air_contents.total_moles() > 0, "The pump must fill the tank without waiting out the internal idle backoff")

/// A spawner a ghost already used must not spawn a second body into nullspace.
/datum/unit_test/mob_spawn_create_after_qdel

/datum/unit_test/mob_spawn_create_after_qdel/Run()
	var/obj/effect/mob_spawn/human/pirate/spawner = new(run_loc_floor_bottom_left)
	qdel(spawner)
	TEST_ASSERT_NULL(spawner.create(), "A deleted spawner must not create a mob")

/// Syndicate job outfits that ignore the backpack preference hand out syndicate bags.
/datum/unit_test/syndicate_outfits_use_syndicate_bags

/datum/unit_test/syndicate_outfits_use_syndicate_bags/Run()
	for(var/datum/outfit/job/outfit_type as anything in subtypesof(/datum/outfit/job))
		if(!findtext("[outfit_type]", "/syndicate") || !initial(outfit_type.no_custom_backpack))
			continue
		for(var/bag in list(initial(outfit_type.backpack), initial(outfit_type.satchel), initial(outfit_type.duffelbag)))
			if(bag && !ispath(bag, /obj/item/storage/backpack/duffelbag/syndie))
				TEST_FAIL("[outfit_type] hands out [bag] instead of a syndicate bag")

/// Alt-clicking an assembly holder rotates it and the infrared emitter inside.
/datum/unit_test/assembly_holder_alt_click_rotates_emitter

/datum/unit_test/assembly_holder_alt_click_rotates_emitter/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/assembly_holder/holder = allocate(/obj/item/assembly_holder)
	var/obj/item/assembly/infra/emitter = allocate(/obj/item/assembly/infra)
	var/obj/item/assembly/signaler/signaler = allocate(/obj/item/assembly/signaler)
	holder.assemble(emitter, signaler)
	var/old_dir = emitter.dir

	holder.AltClick(user)

	TEST_ASSERT_NOTEQUAL(holder.dir, old_dir, "Alt-click must rotate the holder")
	TEST_ASSERT_EQUAL(emitter.dir, holder.dir, "The emitter must follow the holder's direction")

/// Cyborg alt-click reaches the borg handler that electrifies airlocks.
/datum/unit_test/cyborg_alt_click_reaches_borg_handler

/datum/unit_test/cyborg_alt_click_reaches_borg_handler/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	var/obj/item/unit_test_borg_alt_spy/spy = allocate(/obj/item/unit_test_borg_alt_spy, get_step(run_loc_floor_bottom_left, EAST))
	borg.AltClickOn(spy)
	TEST_ASSERT(spy.borg_alt_clicked, "Cyborg alt-click must dispatch to BorgAltClick (airlock electrify, turret lethals)")

/obj/item/unit_test_borg_alt_spy
	var/borg_alt_clicked = FALSE

/obj/item/unit_test_borg_alt_spy/BorgAltClick(mob/living/silicon/robot/user)
	borg_alt_clicked = TRUE

/// Closing wings on a floor with gravity stops floating.
/datum/unit_test/closing_wings_stops_floating

/datum/unit_test/closing_wings_stops_floating/Run()
	var/area/test_area = get_area(run_loc_floor_bottom_left)
	var/saved_gravity = test_area.has_gravity
	test_area.has_gravity = STANDARD_GRAVITY
	var/mob/living/carbon/human/flyer = allocate(/mob/living/carbon/human)
	var/datum/species/species = flyer.dna.species
	species.ToggleFlight(flyer)
	var/started_flying = flyer.movement_type & FLYING
	species.ToggleFlight(flyer)
	var/still_floating = flyer.movement_type & (FLYING|FLOATING)
	test_area.has_gravity = saved_gravity

	TEST_ASSERT(started_flying, "Sanity: flight must start")
	TEST_ASSERT(!still_floating, "A mob standing on a gravity turf must stop floating once the wings close")

/// A nymph evolving into an adult diona keeps what it was holding.
/datum/unit_test/diona_nymph_evolve_keeps_held_items

/datum/unit_test/diona_nymph_evolve_keeps_held_items/Run()
	var/mob/living/simple_animal/diona_nymph/nymph = allocate(/mob/living/simple_animal/diona_nymph)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	nymph.put_in_hands(bag)
	TEST_ASSERT_EQUAL(bag.loc, nymph, "Sanity: the nymph must hold the bag")
	nymph.donors = list("a", "b", "c")
	nymph.set_nutrition(1000)

	TEST_ASSERT(nymph.evolve(), "Sanity: the nymph must evolve")

	TEST_ASSERT(!QDELETED(bag), "The held bag must survive the evolution")
	var/mob/living/carbon/human/adult = bag.loc
	TEST_ASSERT(istype(adult), "The adult diona must hold the bag")
	qdel(adult)

/// A boss does not follow a grudge into a severed head's brainmob.
/datum/unit_test/megafauna_grudge_ignores_brainmob

/datum/unit_test/megafauna_grudge_ignores_brainmob/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/brain/brainmob = allocate(/mob/living/brain, get_step(run_loc_floor_bottom_left, NORTH))
	victim.mind_initialize()
	boss_mob.add_enemy(victim)
	boss_mob.GiveTarget(victim)

	boss_mob.on_enemy_mind_transfer(victim.mind, brainmob, victim)

	TEST_ASSERT(!(brainmob in boss_mob.enemies), "The brainmob must not inherit the grudge")
	TEST_ASSERT_NOTEQUAL(boss_mob.target, brainmob, "The boss must not chase the severed head")

/// A provoked boss can target the vehicle its attacker is piloting.
/datum/unit_test/megafauna_targets_enemy_pilot_vehicle

/datum/unit_test/megafauna_targets_enemy_pilot_vehicle/Run()
	var/mob/living/simple_animal/hostile/megafauna/legion/boss_mob = allocate(/mob/living/simple_animal/hostile/megafauna/legion)
	var/obj/vehicle/sealed/mecha/working/ripley/mech = allocate(/obj/vehicle/sealed/mecha/working/ripley, get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/pilot = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	boss_mob.add_enemy(pilot)

	var/datum/targeting_strategy/strategy = GET_TARGETING_STRATEGY(/datum/targeting_strategy/hostile_legacy/ignore_sight/megafauna)
	TEST_ASSERT(strategy.can_attack(boss_mob, mech), "The mech carrying a recorded enemy must be a valid target")

	mech.remove_occupant(pilot)
	pilot.forceMove(run_loc_floor_bottom_left)

/// AI swarmers do not pile onto a tile next to their target that another swarmer already holds.
/datum/unit_test/ai_swarmers_do_not_stack_on_target

/datum/unit_test/ai_swarmers_do_not_stack_on_target/Run()
	var/turf/far_turf = run_loc_floor_bottom_left
	var/turf/near_turf = get_step(far_turf, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(near_turf, EAST))
	var/mob/living/simple_animal/hostile/swarmer/ai/melee_combat/front = allocate(/mob/living/simple_animal/hostile/swarmer/ai/melee_combat, near_turf)
	var/mob/living/simple_animal/hostile/swarmer/ai/melee_combat/back = allocate(/mob/living/simple_animal/hostile/swarmer/ai/melee_combat, far_turf)
	back.target = victim

	TEST_ASSERT(!back.Move(near_turf, EAST), "A swarmer must not step onto another swarmer next to the target")
	TEST_ASSERT_EQUAL(back.loc, far_turf, "The rear swarmer must stay put")
	TEST_ASSERT_EQUAL(front.loc, near_turf, "Sanity: the front swarmer holds its tile")

/// A loaded radiation collector shields its tank from the radiation it collects.
/datum/unit_test/rad_collector_shields_loaded_tank

/datum/unit_test/rad_collector_shields_loaded_tank/Run()
	var/obj/machinery/power/rad_collector/collector = allocate(/obj/machinery/power/rad_collector)
	var/obj/item/tank/internals/plasma/tank = allocate(/obj/item/tank/internals/plasma)
	tank.forceMove(collector)
	collector.loaded_tank = tank

	var/list/irradiated = get_rad_contents(collector)

	TEST_ASSERT(collector in irradiated, "Sanity: the collector itself still receives radiation")
	TEST_ASSERT(!(tank in irradiated), "The loaded tank must not be irradiated")
	collector.loaded_tank = null

/// AI step delays scale with the player's run delay, so a mob keeps its old speed ratio to a running player.
/datum/unit_test/ai_move_delay_scales_with_run_delay

/datum/unit_test/ai_move_delay_scales_with_run_delay/Run()
	var/player_run_delay = CONFIG_GET(number/movedelay/run_delay)
	TEST_ASSERT(player_run_delay > 0, "Sanity: the run delay config must be loaded")
	update_ai_pursuit_speed_floor()
	TEST_ASSERT_EQUAL(GLOB.ai_move_delay_scale, player_run_delay / AI_SPEED_REFERENCE_RUN_DELAY, "The AI delay scale must follow RUN_DELAY")

	var/mob/living/simple_animal/hostile/boss = allocate(/mob/living/simple_animal/hostile)
	boss.ai_pursuit_speed_capped = FALSE
	boss.move_to_delay = 3
	TEST_ASSERT(abs(boss.ai_movement_delay() - player_run_delay) < MOVEMENT_TICK_EPSILON, "A boss balanced to match the old run speed must match the current run speed, not outrun it")
	boss.move_to_delay = 2
	TEST_ASSERT(boss.ai_movement_delay() < player_run_delay, "A boss designed to be faster than a running player stays faster")

	var/mob/living/simple_animal/hostile/fauna = allocate(/mob/living/simple_animal/hostile, get_step(run_loc_floor_bottom_left, EAST))
	fauna.move_to_delay = AI_PURSUIT_BASELINE_MOVE_TO_DELAY
	TEST_ASSERT(abs(fauna.ai_movement_delay() / player_run_delay - AI_PURSUIT_SPEED_RATIO) < MOVEMENT_TICK_EPSILON, "Default fauna must stay at the pursuit ratio of the running player")

/// AI move loops carry the fractional remainder, so a step that is not a tick multiple still averages its exact cost.
/datum/unit_test/ai_move_loop_fractional_interval

/datum/unit_test/ai_move_loop_fractional_interval/Run()
	TEST_ASSERT(SSai_movement.fractional_steps, "AI movement must schedule fractional steps")
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/move_loop/loop = SSmove_manager.move_towards_legacy(pawn, prey, 1.75, subsystem = SSai_movement)
	TEST_ASSERT_NOTNULL(loop, "Sanity: the move loop must exist")
	loop.set_delay(1.75)

	var/total = 0
	for(var/step in 1 to 8)
		var/interval = loop.plan_fractional_interval()
		TEST_ASSERT(abs(round(interval / world.tick_lag, 1) * world.tick_lag - interval) < MOVEMENT_TICK_EPSILON, "Every interval must land on the tick grid ([interval])")
		total += interval
	TEST_ASSERT(abs(total / 8 - 1.75) < MOVEMENT_TICK_EPSILON, "Intervals must average the exact step cost, got [total / 8]")
	qdel(loop)

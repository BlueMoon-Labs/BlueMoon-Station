
//malfunctioning combat drones
/mob/living/simple_animal/hostile/malf_drone
	name = "Combat Drone"
	desc = "An automated combat drone armed with state of the art weaponry and shielding."
	icon_state = "drone3"
	icon_living = "drone3"
	icon_dead = "drone_dead"
	ranged = 1
	rapid = 3
	retreat_distance = 3
	minimum_distance = 3
	speak_chance = 5
	turns_per_move = 3
	response_help_continuous = "pokes the"
	response_disarm_simple = "gently pushes aside the"
	response_harm_simple = "hits the"
	speak = list("ALERT.", "Hostile-ile-ile entities dee-twhoooo-wected.", "Threat parameterszzzz- szzet.", "Bring sub-sub-sub-systems uuuup to combat alert alpha-a-a.")
	emote_see = list("beeps menacingly.", "whirrs threateningly.", "scans for targets.")
	a_intent = INTENT_HARM
	stop_automated_movement_when_pulled = FALSE
	health = 400
	maxHealth = 400
	speed = 8
	projectiletype = /obj/item/projectile/beam/laser/hellfire
	projectilesound = 'sound/weapons/laser3.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	faction = list("malf_drone")
	deathmessage = "suddenly breaks apart."
	del_on_death = 1
	var/emp_damage_modifier = 1

/mob/living/simple_animal/hostile/malf_drone/Initialize(mapload)
	. = ..()
	update_icons()

/mob/living/simple_animal/hostile/malf_drone/Process_Spacemove(check_drift = 0)
	return 1

/mob/living/simple_animal/hostile/malf_drone/AttackingTarget()
	OpenFire(target) // prevents it pointlessly nuzzling its target in melee if its cornered

/mob/living/simple_animal/hostile/malf_drone/update_icons()
	if(health / maxHealth > 0.9)
		icon_state = "drone3"
	else if(health / maxHealth > 0.7)
		icon_state = "drone2"
	else if(health / maxHealth > 0.5)
		icon_state = "drone1"
	else
		icon_state = "drone0"

/mob/living/simple_animal/hostile/malf_drone/adjustHealth(damage, updating_health)
	do_sparks(3, 1, src)
	update_icons()
	. = ..() // this will handle finding a target if there is a valid one nearby

/* BLUEMOON COMMENT OUT using modified proc in modularized drone.dm file
/mob/living/simple_animal/hostile/malf_drone/Life(seconds, times_fired)
	. = ..()
	if(.) // mob is alive. We check this just in case Life() can fire for qdel'ed mobs.
		if(times_fired % 15 == 0) // every 15 cycles, aka 30 seconds, 50% chance to switch between modes
			scramble_settings()
*/

/mob/living/simple_animal/hostile/malf_drone/proc/scramble_settings()
	if(prob(50))
		do_sparks(3, 1, src)
		visible_message("<span class='notice'>[src] retracts several targetting vanes.</span>")
		if(target)
			LoseTarget()
		else
			visible_message("<span class='warning'>[src] suddenly lights up, and additional targetting vanes slide into place.</span>")
		update_icons()

/mob/living/simple_animal/hostile/malf_drone/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	adjustHealth((100 * emp_damage_modifier) / severity) // takes the same damage as a mining drone from emp

/mob/living/simple_animal/hostile/malf_drone/drop_loot()
	do_sparks(3, 1, src)

	var/turf/T = get_turf(src)

	//shards
	var/obj/O = new /obj/item/shard(T)
	step_to(O, get_turf(pick(view(7, src))))
	if(prob(75))
		O = new /obj/item/shard(T)
		step_to(O, get_turf(pick(view(7, src))))
	if(prob(50))
		O = new /obj/item/shard(T)
		step_to(O, get_turf(pick(view(7, src))))
	if(prob(25))
		O = new /obj/item/shard(T)
		step_to(O, get_turf(pick(view(7, src))))

	//rods
	var/obj/item/stack/K = new /obj/item/stack/rods(T, pick(1, 2, 3, 4))
	step_to(K, get_turf(pick(view(7, src))))

	//plasteel
	K = new /obj/item/stack/sheet/plasteel(T, pick(1, 2, 3, 4))
	step_to(K, get_turf(pick(view(7, src))))

	//also drop dummy circuit boards deconstructable for research (loot)
	var/obj/item/circuitboard/C

	//spawn 1-4 boards of a random type
	var/spawnees = 0
	var/num_boards = rand(1, 4)
	var/list/options = list(1, 2, 4, 8, 16, 32, 64, 128, 256, 512)
	for(var/i=0, i<num_boards, i++)
		var/chosen = pick(options)
		options.Remove(options.Find(chosen))
		spawnees |= chosen

	if(spawnees & 1)
		C = new(T)
		C.name = "Drone CPU motherboard"

	if(spawnees & 2)
		C = new(T)
		C.name = "Drone neural interface"

	if(spawnees & 4)
		C = new(T)
		C.name = "Drone suspension processor"

	if(spawnees & 8)
		C = new(T)
		C.name = "Drone shielding controller"

	if(spawnees & 16)
		C = new(T)
		C.name = "Drone power capacitor"

	if(spawnees & 32)
		C = new(T)
		C.name = "Drone hull reinforcer"

	if(spawnees & 64)
		C = new(T)
		C.name = "Drone auto-repair system"

	if(spawnees & 128)
		C = new(T)
		C.name = "Drone plasma overcharge counter"

	if(spawnees & 256)
		C = new(T)
		C.name = "Drone targetting circuitboard"

	if(spawnees & 512)
		C = new(T)
		C.name = "Corrupted drone morality core"

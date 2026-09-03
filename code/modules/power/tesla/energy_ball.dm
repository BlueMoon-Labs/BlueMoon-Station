#define TESLA_DEFAULT_POWER 1738260
#define TESLA_MINI_POWER 869130
// Шанс того, что КЗ от шара обернётся мощным взрывом, вскрывающим обшивку до космоса, %
#define TESLA_BALL_STRONG_EXPLOSION_CHANCE 2
// Сколько энергии шар вбрасывает в сеть при ударе о кабель
#define TESLA_BALL_GRID_FEED 20 MEGA * WATT
// Как долго после вброса АПЦ этой сети продолжают дуговать
#define TESLA_BALL_ARC_DURATION 30 SECONDS
// Задержка между вбросами энергии в сеть
#define TESLA_BALL_FEED_COOLDOWN 5 SECONDS
//Zap constants, speeds up targeting
#define BIKE (COIL + 1)
#define COIL (ROD + 1)
#define ROD (RIDE + 1)
#define RIDE (LIVING + 1)
#define LIVING (MACHINERY + 1)
#define MACHINERY (BLOB + 1)
#define BLOB (STRUCTURE + 1)
#define STRUCTURE (1)

/obj/singularity/energy_ball
	name = "energy ball"
	desc = "An energy ball."
	icon = 'icons/obj/tesla_engine/energy_ball.dmi'
	icon_state = "energy_ball"
	pixel_x = -32
	pixel_y = -32
	current_size = STAGE_TWO
	move_self = 1
	grav_pull = 0
	contained = 0
	density = TRUE
	energy = 0
	dissipate = 1
	dissipate_delay = 5
	dissipate_strength = 1
	var/list/orbiting_balls = list()
	var/miniball = FALSE
	var/produced_power
	var/energy_to_raise = 32
	var/energy_to_lower = -20
	var/obj/machinery/power/grounding_rod/rodtarget
	var/last_grid_feed = 0 // когда шар в последний раз вбрасывал энергию в сеть
	var/list/forced_arc_timers = list() // APC -> id таймера снятия force_arcing

/obj/singularity/energy_ball/Initialize(mapload, starting_energy = 50, is_miniball = FALSE)
	miniball = is_miniball
	. = ..()
	if(!is_miniball)
		set_light(10, 7, "#EEEEFF")

/obj/singularity/energy_ball/ex_act(severity, target, origin)
	return

/obj/singularity/energy_ball/consume(severity, target)
	return

/obj/singularity/energy_ball/Destroy()
	if(orbiting && istype(orbiting.parent, /obj/singularity/energy_ball))
		var/obj/singularity/energy_ball/EB = orbiting.parent
		EB.orbiting_balls -= src

	for(var/ball in orbiting_balls)
		var/obj/singularity/energy_ball/EB = ball
		QDEL_NULL(EB)

	. = ..()

/obj/singularity/energy_ball/admin_investigate_setup()
	if(miniball)
		return //don't annnounce miniballs
	..()

/obj/singularity/energy_ball/process()
	if(!orbiting)
		handle_energy()

		determine_containment()

		move_the_basket_ball(4 + orbiting_balls.len * 1.5)

		short_out_machinery()

		feed_grid()

		playsound(src.loc, 'sound/magic/lightningbolt.ogg', 100, TRUE, extrarange = 30)

		pixel_x = 0
		pixel_y = 0

		tesla_zap(src, 7, TESLA_DEFAULT_POWER)

		pixel_x = -32
		pixel_y = -32
		for (var/ball in orbiting_balls)
			var/range = rand(1, clamp(orbiting_balls.len, 3, 7))
			tesla_zap(ball, range, TESLA_MINI_POWER/7*range)
	else
		energy = 0 // ensure we dont have miniballs of miniballs

/obj/singularity/energy_ball/examine(mob/user)
	. = ..()
	if(orbiting_balls.len)
		. += "There are [orbiting_balls.len] mini-balls orbiting it."

/obj/singularity/energy_ball/proc/move_the_basket_ball(var/move_amount)
	var/move_dir
	var/obj/machinery/power/apc/apc_target
	for(var/obj/machinery/power/apc/APC in GLOB.apcs_list)
		if(APC.z != z || QDELETED(APC))
			continue
		if(!apc_target || get_dist(src, APC) < get_dist(src, apc_target))
			apc_target = APC
	for(var/rod in GLOB.grounding_rods)
		if(!rodtarget || get_dist(src, rod) < get_dist(src, rodtarget))
			rodtarget = rod

	for(var/i in 0 to move_amount)
		if(apc_target && !QDELETED(apc_target))
			move_dir = get_dir(src, apc_target)
		else if(rodtarget)
			move_dir = get_dir(src, rodtarget)
		else if(target)
			move_dir = get_dir(src, target)
		else
			move_dir = pick(GLOB.alldirs)
		var/turf/T = get_step(src, move_dir)
		if(can_move(T))
			forceMove(T)
			setDir(move_dir)
			for(var/mob/living/carbon/C in loc)
				dust_mobs(C)

/// Шар закорачивает технику на своей клетке: обычные зэпы её не берут -
/// энергоброня (ENERGY = 100 у АПЦ, айралармов и т.д.) глотает весь урон,
/// а oview() в tesla_zap вообще исключает клетку самого шара.
/obj/singularity/energy_ball/proc/short_out_machinery()
	var/turf/T = loc
	if(!isturf(T))
		return
	var/list/to_short = list()
	for(var/obj/machinery/M in T)
		to_short += M
	for(var/obj/machinery/M in to_short)
		if(QDELETED(M))
			continue
		if(istype(M, /obj/machinery/power/grounding_rod))
			continue // стержень сам переваривает энергию шара, это его работа
		if(M.level == 1 && istype(T, /turf/open/floor))
			var/turf/open/floor/floor_turf = T
			if(floor_turf.has_tile())
				continue // техника под целым полом шару недоступна
		short_out(M)

/obj/singularity/energy_ball/proc/short_out(obj/machinery/M)
	var/turf/T = get_turf(M)
	do_sparks(rand(3, 6), FALSE, M)
	playsound(T, "sparks", 70, TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	var/big_boom = prob(TESLA_BALL_STRONG_EXPLOSION_CHANCE)
	if(big_boom)
		burn_open_turf(T)
	if(istype(M, /obj/machinery/power/apc))
		// КЗ на АПЦ - короткое замыкание со слабым взрывом и гарантированным выходом из строя.
		// Только световой радиус (-1,-1,3): severity ниже 3 уже срезает полы до космоса
		if(!QDELETED(M))
			if(!big_boom)
				explosion(T, -1, -1, 3, flame_range = 2, adminlog = FALSE, smoke = FALSE)
			M.emp_act(75)
			M.take_damage(M.max_integrity * 2, BURN, ENERGY, FALSE, armour_penetration = 100)
		return
	// прочая техника - КЗ: искры, ЭМИ и урон в обход энергоброни
	M.emp_act(rand(40, 80))
	M.take_damage(rand(50, 100), BURN, ENERGY, FALSE, armour_penetration = 100)
	if(QDELETED(M) && !big_boom)
		explosion(T, -1, -1, 2, adminlog = FALSE, smoke = FALSE)

/// Редкое мощное КЗ: большой взрыв плюс снятые слои турфа - обшивка вскрыта прям до космоса.
/obj/singularity/energy_ball/proc/burn_open_turf(turf/T)
	if(QDELETED(T))
		return
	if(is_station_level(T.z))
		for(var/i in 1 to 2)
			var/turf/scraped = T.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
			if(!scraped || scraped == T)
				break
			T = scraped
		T.visible_message("<span class='danger'>Мощный разряд выбивает кусок обшивки - путь в открытый космос открыт!</span>")
	explosion(T, 1, 2, 4, flame_range = 3, adminlog = FALSE, smoke = FALSE)

/// Шар бьёт о кабели под собой: вбрасывает энергию в сеть и заставляет АПЦ этой сети дуговать
/// (см. modular_bluemoon/code/modules/apc_arcing/apc.dm).
/obj/singularity/energy_ball/proc/feed_grid()
	if(world.time < last_grid_feed + TESLA_BALL_FEED_COOLDOWN)
		return
	for(var/obj/structure/cable/C in loc)
		last_grid_feed = world.time
		feed_powernet(C)
		return

/obj/singularity/energy_ball/proc/feed_powernet(obj/structure/cable/C)
	var/datum/powernet/PN = C.powernet
	if(!PN)
		return
	do_sparks(rand(3, 6), FALSE, C)
	//у /datum/powernet нет add_avail: вброс энергии живёт на кабеле (cable.dm)
	C.add_avail(TESLA_BALL_GRID_FEED)
	for(var/obj/machinery/power/apc/APC in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/power/apc))
		if(QDELETED(APC) || !APC.terminal || APC.terminal.powernet != PN)
			continue
		var/existing_timer = forced_arc_timers[APC]
		if(existing_timer)
			deltimer(existing_timer)
		APC.force_arcing = TRUE
		APC.apc_unpark()
		//PROC_REF ищет проц в текущем типе (шар), а end_forced_arcing живёт на АПЦ -
		//новый компилятор за это падает "undefined type path"
		forced_arc_timers[APC] = addtimer(CALLBACK(APC, TYPE_PROC_REF(/obj/machinery/power/apc, end_forced_arcing)), TESLA_BALL_ARC_DURATION)
	// BLUEMOON ADD - провод не выдерживает вброса: энергия успевает уйти в сеть,
	// затем кабель выгорает (deconstruct роняет моток кабеля на пол)
	addtimer(CALLBACK(src, PROC_REF(burn_out_cable), C), 1 SECONDS)

/// Выгорание провода, через который шар сбрасывал энергию в сеть
/obj/singularity/energy_ball/proc/burn_out_cable(obj/structure/cable/C)
	if(QDELETED(C))
		return
	investigate_log("energy ball burned out a power cable at [AREACOORD(C)].", INVESTIGATE_WIRES)
	do_sparks(rand(4, 8), FALSE, C)
	playsound(get_turf(C), "sparks", 70, TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	C.deconstruct()

/obj/machinery/power/apc/proc/end_forced_arcing()
	force_arcing = FALSE

/obj/singularity/energy_ball/proc/determine_containment()
	contained=0
	var/found
	var/tiletocheck
	for(var/direction in GLOB.cardinals) // check a radius of 10 tiles around the ball for a full containment field
		tiletocheck=get_step(src,direction)
		for(var/tile in 1 to 10)
			found=locate(/obj/machinery/field/containment) in tiletocheck
			if(found)
				continue
			else if (!found && tile==10)
				return // if one side is lacking a field it doesn't bother checking the others
			tiletocheck=get_step(tiletocheck,direction)
	contained=1

/obj/singularity/energy_ball/proc/handle_energy()
	if(energy >= energy_to_raise)
		energy_to_lower = energy_to_raise - 20
		energy_to_raise = energy_to_raise * 1.25

		playsound(src.loc, 'sound/magic/lightning_chargeup.ogg', 100, TRUE, extrarange = 30)
		addtimer(CALLBACK(src, PROC_REF(new_mini_ball)), 100)

	else if(energy < energy_to_lower && orbiting_balls.len)
		energy_to_raise = energy_to_raise / 1.25
		energy_to_lower = (energy_to_raise / 1.25) - 20

		var/Orchiectomy_target = pick(orbiting_balls)
		qdel(Orchiectomy_target)

	else if(orbiting_balls.len)
		dissipate() //sing code has a much better system.

		if(energy<=0)
			investigate_log("fizzled.", INVESTIGATE_SINGULO)
			qdel(src)

/obj/singularity/energy_ball/proc/new_mini_ball()
	if(!loc)
		return
	var/obj/singularity/energy_ball/EB = new(loc, 0, TRUE)

	EB.transform *= pick(0.3, 0.4, 0.5, 0.6, 0.7)
	var/icon/I = icon(icon,icon_state,dir)

	var/orbitsize = (I.Width() + I.Height()) * pick(0.4, 0.5, 0.6, 0.7, 0.8)
	orbitsize -= (orbitsize / world.icon_size) * (world.icon_size * 0.25)

	EB.orbit(src, orbitsize, pick(FALSE, TRUE), rand(10, 25), pick(3, 4, 5, 6, 36))

/obj/singularity/energy_ball/Bump(atom/A)
	dust_mobs(A)

/obj/singularity/energy_ball/Bumped(atom/movable/AM)
	dust_mobs(AM)

/obj/singularity/energy_ball/attack_tk(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		to_chat(C, "<span class='userdanger'>That was a shockingly dumb idea.</span>")
		var/obj/item/organ/brain/rip_u = locate(/obj/item/organ/brain) in C.internal_organs
		C.ghostize(0)
		qdel(rip_u)
		C.death()

/obj/singularity/energy_ball/orbit(obj/singularity/energy_ball/target)
	if (istype(target))
		target.orbiting_balls += src
		GLOB.poi_list -= src
		target.dissipate_strength = target.orbiting_balls.len
	. = ..()

/obj/singularity/energy_ball/stop_orbit()
	if (orbiting && istype(orbiting.parent, /obj/singularity/energy_ball))
		var/obj/singularity/energy_ball/orbitingball = orbiting.parent
		orbitingball.orbiting_balls -= src
		orbitingball.dissipate_strength = orbitingball.orbiting_balls.len
	. = ..()
	if (!QDELETED(src))
		qdel(src)

/obj/singularity/energy_ball/proc/dust_mobs(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		if(L.incorporeal_move || L.status_flags & GODMODE)
			return
	if(!iscarbon(A))
		return
	for(var/obj/machinery/power/grounding_rod/GR in orange(src, 2))
		if(GR.anchored)
			return
	var/mob/living/carbon/C = A
	C.dust()

/proc/tesla_zap(atom/source, zap_range = 3, power, zap_flags = ZAP_DEFAULT_FLAGS, list/shocked_targets)
	if(QDELETED(source))
		return
	. = source.dir
	if(power < 1000)
		return

	/*
	THIS IS SO FUCKING UGLY AND I HATE IT, but I can't make it nice without making it slower, check*N rather then n. So we're stuck with it.
	*/
	var/atom/closest_atom
	var/closest_type = 0
	var/static/things_to_shock = typecacheof(list(/obj/machinery, /mob/living, /obj/structure, /obj/vehicle/ridden))
	var/static/blacklisted_tesla_types = typecacheof(list(/obj/machinery/atmospherics,
										/obj/machinery/power/emitter,
										/obj/machinery/field/generator,
										/mob/living/simple_animal,
										/obj/machinery/particle_accelerator/control_box,
										/obj/structure/particle_accelerator/fuel_chamber,
										/obj/structure/particle_accelerator/particle_emitter/center,
										/obj/structure/particle_accelerator/particle_emitter/left,
										/obj/structure/particle_accelerator/particle_emitter/right,
										/obj/structure/particle_accelerator/power_box,
										/obj/structure/particle_accelerator/end_cap,
										/obj/machinery/field/containment,
										/obj/structure/disposalpipe,
										/obj/structure/disposaloutlet,
										/obj/machinery/disposal/deliveryChute,
										/obj/machinery/camera,
										/obj/structure/sign,
										/obj/machinery/gateway,
										/obj/structure/lattice,
										/obj/structure/grille,
										/obj/structure/frame/machine))

	//Ok so we are making an assumption here. We assume that view() still calculates from the center out.
	//This means that if we find an object we can assume it is the closest one of its type. This is somewhat of a speed increase.
	//This also means we have no need to track distance, as the doview() proc does it all for us.

	//Darkness fucks oview up hard. I've tried dview() but it doesn't seem to work
	//I hate existance
	for(var/a in typecache_filter_multi_list_exclusion(oview(zap_range+2, source), things_to_shock, blacklisted_tesla_types))
		var/atom/A = a
		if(!(zap_flags & ZAP_ALLOW_DUPLICATES) && LAZYACCESS(shocked_targets, A))
			continue
		if(closest_type >= BIKE)
			break

		else if(istype(A, /obj/vehicle/ridden/bicycle))//God's not on our side cause he hates idiots.
			var/obj/vehicle/ridden/bicycle/B = A
			if(!(B.obj_flags & BEING_SHOCKED) && B.can_buckle)//Gee goof thanks for the boolean
				//we use both of these to save on istype and typecasting overhead later on
				//while still allowing common code to run before hand
				closest_type = BIKE
				closest_atom = B

		else if(closest_type >= COIL)
			continue //no need checking these other things

		else if(istype(A, /obj/machinery/power/tesla_coil))
			var/obj/machinery/power/tesla_coil/C = A
			if(!(C.obj_flags & BEING_SHOCKED))
				closest_type = COIL
				closest_atom = C

		else if(closest_type >= ROD)
			continue

		else if(istype(A, /obj/machinery/power/grounding_rod))
			closest_type = ROD
			closest_atom = A

		else if(closest_type >= RIDE)
			continue

		else if(istype(A,/obj/vehicle/ridden))
			var/obj/vehicle/ridden/R = A
			if(R.can_buckle && !(R.obj_flags & BEING_SHOCKED))
				closest_type = RIDE
				closest_atom = A

		else if(closest_type >= LIVING)
			continue

		else if(isliving(A))
			var/mob/living/L = A
			if(L.stat != DEAD && !(HAS_TRAIT(L, TRAIT_TESLA_SHOCKIMMUNE)) && !(L.flags_1 & SHOCKED_1))
				closest_type = LIVING
				closest_atom = A

		else if(closest_type >= MACHINERY)
			continue

		else if(ismachinery(A))
			var/obj/machinery/M = A
			if(!(M.obj_flags & BEING_SHOCKED))
				closest_type = MACHINERY
				closest_atom = A

		else if(closest_type >= BLOB)
			continue

		else if(istype(A, /obj/structure/blob))
			var/obj/structure/blob/B = A
			if(!(B.obj_flags & BEING_SHOCKED))
				closest_type = BLOB
				closest_atom = A

		else if(closest_type >= STRUCTURE)
			continue

		else if(isstructure(A))
			var/obj/structure/S = A
			if(!(S.obj_flags & BEING_SHOCKED))
				closest_type = STRUCTURE
				closest_atom = A

	//Alright, we've done our loop, now lets see if was anything interesting in range
	if(!closest_atom)
		return
	//common stuff
	source.Beam(closest_atom, icon_state="lightning[rand(1,12)]", time=5, maxdistance = INFINITY)
	if(!(zap_flags & ZAP_ALLOW_DUPLICATES))
		LAZYSET(shocked_targets, closest_atom, TRUE)
	var/zapdir = get_dir(source, closest_atom)
	if(zapdir)
		. = zapdir

	var/next_range = 3
	if(closest_type == COIL)
		next_range = 5

	if(closest_type == LIVING)
		var/mob/living/closest_mob = closest_atom
		closest_mob.set_shocked()
		addtimer(CALLBACK(closest_mob, TYPE_PROC_REF(/mob/living, reset_shocked)), 10)
		var/shock_damage = (zap_flags & ZAP_MOB_DAMAGE) ? (min(round(power/600), 90) + rand(-5, 5)) : 0
		closest_mob.electrocute_act(shock_damage, source, 1, SHOCK_TESLA | ((zap_flags & ZAP_MOB_STUN) ? NONE : SHOCK_NOSTUN))
		if(issilicon(closest_mob))
			var/mob/living/silicon/S = closest_mob
			if((zap_flags & ZAP_MOB_STUN) && (zap_flags & ZAP_MOB_DAMAGE))
				S.emp_act(50)
			next_range = 7 // metallic folks bounce it further
		else
			next_range = 5
		power /= 1.5

	else
		power = closest_atom.zap_act(power, zap_flags, shocked_targets)

		var/obj/singularity/energy_ball/tesla = source
		if(istype(tesla))
			if(istype(closest_atom,/obj/machinery/power/grounding_rod) && tesla.energy>13 && !tesla.contained)

				// getting the grounding rod's capacitor rating for quick maths
				var/obj/machinery/power/grounding_rod/rod = closest_atom
				// assuming the rod is fully constructed the second part will always be a capacitor
				var/obj/item/stock_parts/capacitor/capacitor = rod.component_parts[2]

				tesla.energy = round(tesla.energy/(1 + 0.28125 * capacitor.rating))
				qdel(closest_atom) // each rod removes tesla energy depending on the power of the capacitor,
				// if there are no miniballs the rod stays and continues to pull the ball in

	if(prob(20))//I know I know
		tesla_zap(closest_atom, next_range, power * 0.5, zap_flags, shocked_targets)
		tesla_zap(closest_atom, next_range, power * 0.5, zap_flags, shocked_targets)
	else
		tesla_zap(closest_atom, next_range, power, zap_flags, shocked_targets)

#undef BIKE
#undef COIL
#undef ROD
#undef RIDE
#undef LIVING
#undef MACHINERY
#undef BLOB
#undef STRUCTURE

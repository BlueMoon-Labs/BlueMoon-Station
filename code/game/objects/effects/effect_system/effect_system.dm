/* This is an attempt to make some easily reusable "particle" type effect, to stop the code
constantly having to be rewritten. An item like the jetpack that uses the ion_trail_follow system, just has one
defined, then set up when it is created with New(). Then this same system can just be reused each time
it needs to create more trails.A beaker could have a steam_trail_follow system set up, then the steam
would spawn and follow the beaker, even if it is carried or thrown.
*/


/obj/effect/particle_effect
	name = "particle effect"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pass_flags = PASSTABLE | PASSGRILLE
	anchored = TRUE

/obj/effect/particle_effect/Initialize(mapload)
	. = ..()
	GLOB.cameranet.updateVisibility(src)

/obj/effect/particle_effect/Destroy()
	GLOB.cameranet.updateVisibility(src)
	return ..()

/datum/effect_system
	var/number = 3
	var/cardinals = FALSE
	var/turf/location
	var/atom/holder
	var/effect_type
	var/total_effects = 0
	var/autocleanup = FALSE //will delete itself after use

/datum/effect_system/Destroy()
	holder = null
	location = null
	return ..()

/datum/effect_system/proc/set_up(n = 3, c = FALSE, loca)
	if(n > 10)
		n = 10
	number = n
	cardinals = c
	if(isturf(loca))
		location = loca
	else
		location = get_turf(loca)

/datum/effect_system/proc/attach(atom/atom)
	holder = atom

/datum/effect_system/proc/start()
	if(QDELETED(src))
		return
	for(var/i in 1 to number)
		if(total_effects > 20)
			return
		INVOKE_ASYNC(src, PROC_REF(generate_effect))
	// Дыра в autocleanup: если не родился НИ ОДИН эффект (нет location - do_sparks() от
	// источника вне турфа; или на турфе больше 200 объектов), то total_effects никто не
	// увеличил и таймер на decrement_total_effect() никто не завёл - значит уборка не
	// сработает никогда, и система, обещавшая убрать себя, останется висеть.
	// Проверять можно прямо здесь: INVOKE_ASYNC крутит колбек синхронно до его первого
	// сна, а total_effects++ в generate_effect() стоит ДО sleep(5), поэтому после цикла
	// значение уже окончательное.
	if(autocleanup && total_effects <= 0)
		qdel(src)

/datum/effect_system/proc/generate_effect()
	if(holder)
		location = get_turf(holder)
	if(!location)
		return
	if(location.contents.len > 200)		//Bandaid to prevent server crash exploit
		return
	var/obj/effect/E = new effect_type(location)
	total_effects++
	var/direction
	if(cardinals)
		direction = pick(GLOB.cardinals)
	else
		direction = pick(GLOB.alldirs)
	var/steps_amt = pick(1,2,3)
	for(var/j in 1 to steps_amt)
		sleep(5)
		step(E,direction)
	if(!QDELETED(src))
		addtimer(CALLBACK(src, PROC_REF(decrement_total_effect)), 20)

/datum/effect_system/proc/decrement_total_effect()
	total_effects--
	if(autocleanup && total_effects <= 0)
		qdel(src)

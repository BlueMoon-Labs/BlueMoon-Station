/datum/idle_behavior/idle_random_walk
	///Chance that the mob random walks per second
	var/walk_chance = 25

/datum/idle_behavior/idle_random_walk/perform_idle_behavior(seconds_per_tick, datum/ai_controller/controller)
	. = ..()
	var/mob/living/living_pawn = controller.pawn
	//Паун мог уйти хардделом между постановкой в пул и этим фаером - ссылка
	//становится null молча. Пул такие записи вычищает сам, но поведение обязано
	//пережить фаер, который уже начался.
	if(QDELETED(living_pawn))
		return
	if(LAZYLEN(living_pawn.do_afters))
		return

	//!buckled: иначе Move() уедет вместе с незаанкоренным стулом вместо шага
	if(SPT_PROB(walk_chance, seconds_per_tick) && (living_pawn.mobility_flags & MOBILITY_MOVE) && isturf(living_pawn.loc) && !living_pawn.pulledby && !living_pawn.buckled)
		var/move_dir = pick_idle_direction(living_pawn, controller)
		if(!move_dir)
			return
		living_pawn.Move(get_step(living_pawn, move_dir), move_dir)

///Направление фонового шага. Точка расширения для рутин: выпас, лежбище и
///стайность отличаются именно выбором направления, а не механикой шага.
/datum/idle_behavior/idle_random_walk/proc/pick_idle_direction(mob/living/living_pawn, datum/ai_controller/controller)
	return pick(GLOB.alldirs)

/datum/idle_behavior/idle_random_walk/less_walking
	walk_chance = 10

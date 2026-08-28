// Делает фальшивый взрыв 3x3 вокруг точки попадания. Не отрывает конечности и не
// использует настоящий код взрывов (помимо ex_act по неживым объектам).
// Помимо кастомного урона это аналог EXPLODE_LIGHT.

/proc/fake_explode(atom/origin, explosion_damage=30, atom/cause)

	var/turf/our_turf = isturf(origin) ? origin : get_turf(origin)

	//Фальшивый код взрыва. Конечности людям не отрывает.
	for(var/atom/victim as anything in view(1, our_turf))
		if(!isliving(victim))
			victim.ex_act(EXPLODE_LIGHT)
			continue
		var/mob/living/victim_as_living = victim
		if(HAS_TRAIT(victim_as_living, TRAIT_BOMBIMMUNE))
			continue
		//Наносим урон.
		victim_as_living.apply_damage(
			explosion_damage,
			BRUTE,
			BODY_ZONE_CHEST,
			victim_as_living.getarmor(null, BOMB),
			FALSE,
			TRUE
		)
		//Сваливаем с ног.
		victim_as_living.Knockdown(2 SECONDS)
		//Контузим уши.
		if(iscarbon(victim_as_living))
			victim_as_living.adjustEarDamage(15, 120 SECONDS)

		continue

	playsound(our_turf, 'sound/effects/explosion1.ogg', 30, TRUE)

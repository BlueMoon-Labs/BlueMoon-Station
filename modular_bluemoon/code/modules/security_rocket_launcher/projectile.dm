#define MISSILE_SPEED_IGNITION TILES_TO_PIXELS(17.5) //обычная скорость снаряда
#define MISSILE_SPEED_LAUNCH   TILES_TO_PIXELS(6)    //медленный старт
#define MISSILE_SPEED_STALL    TILES_TO_PIXELS(2)    //почти зависает
#define MISSILE_SPEED_RAMP     TILES_TO_PIXELS(0.15) //замедление за один шаг Range()

/obj/item/projectile/bullet/security_missile
	name = "активная радарная ОФ-ракета"
	desc = "Если ты можешь это прочитать - ты слишком близко."
	icon = 'icons/obj/weapons/sec_missile.dmi'
	icon_state = "rocket_launched"

	damage = 13 //Бонк. Как ящиком с инструментами.
	sharpness = NONE
	shrapnel_type = null
	ricochets_max = 0
	pixels_per_second = MISSILE_SPEED_LAUNCH
	range = 800 //Range() тикает каждые ~4 пикселя: 800 * 4 / 32 = 100 тайлов пути

	var/explosion_damage = 50 //Лёгкий взрыв - это 30.
	var/ignited = FALSE //уже разогналась?
	var/minimum_range = 1 //дистанция в тайлах до активации двигателя
	var/turf/launch_origin

/obj/item/projectile/bullet/security_missile/Initialize(mapload)
	. = ..()
	original = null //цель нам не нужна - радар сам всё найдёт

/obj/item/projectile/bullet/security_missile/fire(angle, atom/direct_target)
	launch_origin = get_turf(src)
	return ..()

/obj/item/projectile/bullet/security_missile/Range()
	. = ..()
	if(QDELETED(src) || ignited)
		return

	if(pixels_per_second > MISSILE_SPEED_STALL)
		pixels_per_second = max(MISSILE_SPEED_STALL, pixels_per_second - MISSILE_SPEED_RAMP)

	//Разгон после минимальной дистанции (или сразу в открытом космосе, если стреляют в упор).
	var/traveled = launch_origin ? get_dist(get_turf(src), launch_origin) : minimum_range + 1
	if(traveled >= minimum_range)
		ignited = TRUE
		pixels_per_second = MISSILE_SPEED_IGNITION
		icon_state = "rocket_ignition"
		playsound(src, 'sound/weapons/sec_missile/launch.ogg', 50, FALSE, -1)
		if(istype(fired_from, /obj/item/gun/ballistic/rocketlauncher/security))
			var/obj/item/gun/ballistic/rocketlauncher/security/missile_launcher = fired_from
			if(missile_launcher.self_targeting)
				//Целься в стрелка, а не в само оружие - у оружия в руках loc не является тайлом,
				//и set_homing_target() просто откажется работать.
				set_homing_target(istype(firer, /mob/living) ? firer : get_turf(fired_from))
			else
				initialize_radar()
				process_radar()
		do_sparks(2, FALSE, src)

/obj/item/projectile/bullet/security_missile/on_hit(atom/target, blocked = 0, pierce_hit)

	var/turf/our_turf = get_turf(src) //запоминаем тайл до того, как код ниже что-нибудь натворит

	. = ..()

	if(. == BULLET_ACT_FORCE_PIERCE)
		return .

	if(!our_turf)
		return BULLET_ACT_BLOCK //Какая-то чертовщина творится.

	if(!ignited) //Ещё недостаточно быстрая, чтобы взорваться.
		new /obj/item/broken_missile/security(our_turf)
		if(isliving(target))
			var/mob/living/target_as_living = target

			if(. != BULLET_ACT_BLOCK && blocked < 15 && target_as_living.Stun(1.5 SECONDS)) //Попали, брони меньше 15 на этом месте и оглушение прошло...
				playsound(target, 'sound/effects/bonk.ogg', 50, FALSE, -1) //Бонк!
				return .

			if(isliving(firer) && prob(5))
				var/mob/living/firer_as_living = firer
				firer_as_living.say("ОСЕЧКА!!", forced = "rocket dud")

		playsound(target, 'sound/weapons/smash.ogg', 50, TRUE, -1)

		return . //Урон всё равно нанесётся (если не заблокирован), но взрыва не будет.

	fake_explode(src, explosion_damage, src)

	return .

/obj/item/projectile/bullet/security_missile/proc/initialize_radar()
	addtimer(CALLBACK(src, PROC_REF(process_radar)), 0.25 SECONDS, TIMER_STOPPABLE | TIMER_LOOP | TIMER_DELETE_ME)

/obj/item/projectile/bullet/security_missile/proc/process_radar()

	//Наверное, дороговато вызывать это каждый тик, так что пусть работает максимум пару раз в секунду.
	//Надеюсь, админ не выдаст экипажу штук шестьдесят этих ракет одновременно. Это была бы катастрофа. Ха-ха. Ха.

	if(QDELETED(src))
		return
	if(!isnum(Angle)) //Наш текущий угол. Может быть null
		return

	var/scanning_angle = homing_target ? (range/initial(range)) * 45 : 45 //Поле зрения уменьшается со временем.

	if(scanning_angle <= 0)
		return

	//Собираем все тайлы, которые мы видим.
	var/list/possible_turfs = list()
	for(var/turf/found_turf in view(7, src))
		if(found_turf != loc)
			possible_turfs += found_turf

	var/list/turf_to_weight = list()

	for(var/turf/found_turf as null|anything in possible_turfs)

		if(!found_turf)
			continue

		//Проверяем угол падения и отсеиваем всё позади нас.
		var/found_angle_difference = 0
		if(found_turf != loc)
			var/turf_angle = get_projectile_angle(src, found_turf)
			found_angle_difference = abs(closer_angle_difference(turf_angle, Angle))
			if(found_angle_difference > scanning_angle)
				continue

		var/calculated_weight = 0
		if(istype(found_turf, /turf/closed)) //Стена или другая плотная преграда.
			calculated_weight = istype(found_turf, /turf/closed/wall/r_wall) ? 6 : 3
		else //Открытый тайл - сканируем содержимое, оно добавляет вес.
			var/scan_limit = 30 //Защита от шайниганств.
			for(var/atom/movable/found_movable as null|anything in found_turf.contents)
				scan_limit--
				if(scan_limit <= 0)
					break
				if(found_movable.invisibility > INVISIBILITY_REVENANT) //Нет радиолокационной сигнатуры.
					continue
				if(isliving(found_movable))
					var/mob/living/found_living = found_movable
					calculated_weight += clamp(found_living.maxHealth/100,1,4)*4 //4 здоровья человека - примерно та же сигнатура, что у космического дракона.
					continue
				if(isobj(found_movable))
					var/obj/found_obj = found_movable
					if(found_obj.max_integrity)
						calculated_weight += found_obj.max_integrity/100
						continue

		if(calculated_weight > 0)
			calculated_weight *= 100 //Повышаем точность расчётов ниже.
			calculated_weight /= (1 + max(1, get_dist(src, found_turf))/5) //В половину веса на расстоянии 5 тайлов, минимум дистанции - 1. Помним: pickweight выбирает наибольшее.
			calculated_weight /= (1 + found_angle_difference/45) //В половину веса при отклонении в 45 градусов.
			calculated_weight = FLOOR(calculated_weight, 1)
			if(calculated_weight > 0) //Расчёт выше мог занулить значение.
				turf_to_weight[found_turf] = calculated_weight

	if(!length(turf_to_weight))
		//Сбрасываем самонаведение. set_homing_target(null) тут не работает.
		homing = FALSE
		homing_target = null
		homing_offset_x = 0
		homing_offset_y = 0
		return

	var/turf/targeting_turf = pickweight(turf_to_weight)
	set_homing_target(targeting_turf)
	original = targeting_turf

	return TRUE

#undef MISSILE_SPEED_IGNITION
#undef MISSILE_SPEED_LAUNCH
#undef MISSILE_SPEED_STALL
#undef MISSILE_SPEED_RAMP

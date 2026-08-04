// Модель напряжения трубопровода.
//
// Номинал живёт на трубе, напряжение - на сети. Сеть, чьё давление перешло
// номинал слабейшего звена, встаёт на учёт в SSair и дальше обслуживается
// редким свипом независимо от флага update: надутая и уснувшая сеть обязана
// продолжать деградировать. В нормальной игре список пуст и свипа нет.

/// Прирост усталости за один проход свипа при данном напряжении.
/datum/pipeline/proc/fatigue_gain(stress)
	return min((stress - 1) * PIPE_FATIGUE_GAIN_SCALE, PIPE_FATIGUE_GAIN_CAP)

/// Предельная стадия повреждения, до которой данное напряжение вправе дойти.
/datum/pipeline/proc/stress_stage_cap(stress)
	if(stress >= PIPE_STRESS_RUPTURE_RATIO)
		return PIPE_DAMAGE_RUPTURE
	if(stress >= PIPE_STRESS_LEAK_RATIO)
		return PIPE_DAMAGE_LEAK
	return PIPE_DAMAGE_INTACT

/// Поднимает стадию одному из слабейших звеньев. TRUE, если кому-то подняли.
/datum/pipeline/proc/escalate_damage(cap)
	if(cap <= PIPE_DAMAGE_INTACT)
		return FALSE
	var/list/candidates = list()
	for(var/obj/machinery/atmospherics/pipe/member as anything in members)
		if(QDELETED(member))
			continue
		// Усиленная секция в смешанной сети не страдает за обычную: рвётся то
		// звено, чей номинал сеть и держит.
		if(member.pressure_rating > min_rating)
			continue
		if(member.damage_stage >= cap)
			continue
		candidates += member
	if(!length(candidates))
		return FALSE
	var/obj/machinery/atmospherics/pipe/victim = pick(candidates)
	victim.take_pressure_damage()
	LAZYOR(damaged_members, victim)
	return TRUE

/// Один проход свипа. TRUE - сеть остаётся на учёте.
/datum/pipeline/proc/update_stress()
	if(!air)
		return FALSE
	var/stress = min_rating > 0 ? air.return_pressure() / min_rating : 0
	if(stress > 1)
		fatigue = min(fatigue + fatigue_gain(stress), PIPE_FATIGUE_MAX)
		announce_stress()
	else
		fatigue = max(fatigue - PIPE_FATIGUE_DECAY, 0)
	if(fatigue >= PIPE_FATIGUE_MAX)
		// Не пробили полосу - усталость держится у потолка и ждёт, пока
		// давление вырастет. Иначе она копилась бы вхолостую и труба рвалась бы
		// позже от давления, которого в тот момент уже нет.
		fatigue = escalate_damage(stress_stage_cap(stress)) ? 0 : PIPE_FATIGUE_MAX - 1
	vent_damaged_members()
	return length(damaged_members) || fatigue > 0 || stress > 1

/// Голос напряжённой сети. Говорит одна труба и редко: сеть на сотню секций не
/// должна превращать чат в стену текста.
/datum/pipeline/proc/announce_stress()
	if(world.time < next_stress_message)
		return
	next_stress_message = world.time + PIPE_STRESS_MESSAGE_COOLDOWN
	if(!length(members))
		return
	var/obj/machinery/atmospherics/pipe/speaker = pick(members)
	if(QDELETED(speaker))
		return
	var/turf/location = speaker.loc
	if(!isturf(location))
		return
	location.visible_message("<span class='warning'>[speaker] отзывается низким гулом.</span>")

/// Прогоняет утечку по всем пробитым членам сети.
/datum/pipeline/proc/vent_damaged_members()
	if(!length(damaged_members))
		return
	// Обход вниз по индексу: починенные и удалённые трубы режут список на ходу.
	for(var/i = length(damaged_members), i >= 1, i--)
		var/obj/machinery/atmospherics/pipe/member = damaged_members[i]
		if(QDELETED(member) || !member.damage_stage)
			damaged_members.Cut(i, i + 1)
			continue
		member.vent_breach()

/// Сколько литров труба выпускает за проход на своей стадии.
/obj/machinery/atmospherics/pipe/proc/breach_litres()
	switch(damage_stage)
		if(PIPE_DAMAGE_LEAK)
			return PIPE_LEAK_LITRES
		if(PIPE_DAMAGE_RUPTURE)
			return PIPE_RUPTURE_LITRES
	return 0

/// Выпускает газ в свой турф. Поток масштабируется перепадом давления, иначе
/// выдохшаяся линия сосала бы воздух из комнаты обратно в трубу фиксированным
/// расходом. Дыра при этом не заживает - она просто перестаёт быть слышной.
/obj/machinery/atmospherics/pipe/proc/vent_breach()
	var/litres = breach_litres()
	if(!litres || !parent?.air)
		return 0
	var/turf/open/location = loc
	if(!isopenturf(location))
		return 0
	var/inside = parent.air.return_pressure()
	if(inside <= 0)
		return 0
	var/datum/gas_mixture/environment = location.return_air()
	var/outside = environment ? environment.return_pressure() : 0
	var/head = clamp((inside - outside) / inside, 0, 1)
	if(head <= 0)
		return 0
	var/volume = parent.air.return_volume()
	if(volume <= 0)
		return 0
	var/datum/gas_mixture/escaped = parent.air.remove_ratio(clamp(litres * head / volume, 0, 1))
	if(!escaped)
		return 0
	location.assume_air(escaped)
	location.air_update_turf()
	// Свищ обязан быть слышен, пока травит: welder_act отправляет искать его
	// "по шипению и пару", а под плиткой это единственная наводка - сам маркер
	// повреждения на скрытой трубе не виден (доклад "газы просто пропадают из
	// труб", раунд 9875). Порог по head глушит выдохшуюся линию.
	if(head >= 0.1 && world.time >= next_breach_effect)
		next_breach_effect = world.time + PIPE_BREACH_EFFECT_COOLDOWN
		playsound(location, 'sound/effects/spray.ogg', damage_stage == PIPE_DAMAGE_RUPTURE ? 40 : 20, TRUE)
		if(damage_stage == PIPE_DAMAGE_RUPTURE)
			var/datum/effect_system/steam_spread/steam = new
			steam.set_up(1, FALSE, location)
			steam.start()
	return litres * head

/// Поднимает стадию на единицу и показывает это комнате.
/obj/machinery/atmospherics/pipe/proc/take_pressure_damage()
	damage_stage = min(damage_stage + 1, PIPE_DAMAGE_RUPTURE)
	var/turf/location = loc
	if(isturf(location))
		var/datum/effect_system/steam_spread/steam = new
		steam.set_up(damage_stage == PIPE_DAMAGE_RUPTURE ? 10 : 3, FALSE, location)
		steam.start()
		if(damage_stage == PIPE_DAMAGE_RUPTURE)
			location.visible_message("<span class='warning'>Стык [src] расходится с хлопком!</span>")
			playsound(location, 'sound/effects/spray.ogg', 70, TRUE)
		else
			location.visible_message("<span class='warning'>Из [src] с шипением бьёт струя газа.</span>")
			playsound(location, 'sound/effects/spray.ogg', 40, TRUE)
	update_icon()

/// Возврат трубы в целое состояние. Вынесено из welder_act отдельно, чтобы
/// последствие можно было проверить тестом без мока игрока и do_after.
/obj/machinery/atmospherics/pipe/proc/finish_pressure_repair()
	damage_stage = PIPE_DAMAGE_INTACT
	if(parent)
		LAZYREMOVE(parent.damaged_members, src)
		parent.fatigue = 0
	update_icon()

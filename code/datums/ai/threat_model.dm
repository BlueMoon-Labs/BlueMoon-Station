// Модель угрозы hostile AI: чем именно в моба стреляют и что от ЭТОГО укрывает.
//
// До неё у ИИ была модель линии огня, но не было модели собственной уязвимости.
// Оценка укрытия сводилась к can_see() - чистой видимости, безотносительно типа
// угрозы. Между тем у луча pass_flags = PASSTABLE|PASSGLASS|PASSGRILLE
// (projectile/beams.dm), а у базового снаряда только PASSTABLE, и окно объявляет
// pass_flags_self = PASSGLASS. То есть окно останавливает пулю и не
// останавливает лазер, а для ИИ это было неразличимо: прозрачное стекло даёт
// can_see() == TRUE и не считалось укрытием никогда - ни там, где оно работает,
// ни там, где нет. Отсюда жалобы "стоят тупят под лазером, пока их убивают".
//
// Модель намеренно дешёвая: полный проход по трассе снаряда для каждого
// кандидата в позицию стоил бы дороже всего остального планирования. Работает
// так: непрозрачную преграду где-то на линии ловит can_see(), а прозрачную -
// точечная проверка ребра между тайлом и первым шагом к стрелку. Это покрывает
// реальный игровой случай (моб стоит вплотную за окном/решёткой) и не покрывает
// стекло в пяти тайлах от моба - за такую точность здесь не платят.

///Сколько живёт запись о том, чем стрелял конкретный противник
#define AI_THREAT_MEMORY_TIMEOUT (60 SECONDS)
///Потолок записей модели: держит список конечным под очередью из стрелков
#define AI_THREAT_MEMORY_MAX 8

///Чем считать угрозу, пока по нам ею не попали. Взяты флаги ЛУЧА, и это
///намеренно осторожная оценка: чем больше у снаряда pass_flags, тем меньше
///вещей от него укрывает, то есть моб по умолчанию доверяет только глухой
///преграде. Ошибиться в эту сторону дешевле, чем спрятаться за стеклом от лазера.
#define AI_THREAT_DEFAULT_PASS_FLAGS (PASSTABLE|PASSGLASS|PASSGRILLE)

///Останавливает ли ребро между двумя тайлами снаряд с такими pass_flags.
///Направленные преграды (окна, windoor, border-файрлоки) учитываются по стороне
///тем же хелпером, что и обход препятствий.
/proc/ai_edge_stops_projectile(turf/from_turf, turf/to_turf, projectile_pass_flags)
	if(!from_turf || !to_turf)
		return FALSE
	if(to_turf.density && !(to_turf.pass_flags_self & projectile_pass_flags))
		return TRUE
	for(var/obj/barrier in from_turf)
		if(!barrier.density || (barrier.pass_flags_self & projectile_pass_flags))
			continue
		if(ai_pressure_barrier_blocks_step(barrier, from_turf, to_turf))
			return TRUE
	for(var/obj/barrier in to_turf)
		if(!barrier.density || (barrier.pass_flags_self & projectile_pass_flags))
			continue
		//направленность обязательна и для соседнего тайла: окно в нём, повёрнутое
		//БОКОМ к линии огня, снаряд не задерживает, а безусловное "плотный объект
		//рядом = укрытие" заставляло моба стоять под пулями за такой ширмой -
		//ровно та жалоба, ради которой модель строилась
		if(ai_pressure_barrier_blocks_step(barrier, from_turf, to_turf))
			return TRUE
	return FALSE

///Запомнить, чем именно в нас попали. Ключ строковый (REF), чтобы модель не
///держала ссылок на мобов и не плодила кандидатов на харддел.
/datum/ai_controller/proc/note_incoming_projectile(atom/movable/firer, obj/item/projectile/incoming)
	if(QDELETED(firer) || QDELETED(incoming))
		return
	LAZYINITLIST(threat_pass_flag_memory)
	prune_threat_memory()
	threat_pass_flag_memory[REF(firer)] = list(incoming.pass_flags, world.time)

///Return a live observation for threat, pruning it when its memory has expired.
/datum/ai_controller/proc/get_threat_memory_entry(atom/threat)
	if(QDELETED(threat) || !threat_pass_flag_memory)
		return
	var/threat_ref = REF(threat)
	var/list/entry = threat_pass_flag_memory[threat_ref]
	if(!entry)
		return
	if(world.time - entry[2] > AI_THREAT_MEMORY_TIMEOUT)
		threat_pass_flag_memory -= threat_ref
		return
	return entry

///Чем эта угроза по нам стреляет, по наблюдениям. Без наблюдений - осторожный дефолт.
/datum/ai_controller/proc/threat_pass_flags(atom/threat)
	var/list/entry = get_threat_memory_entry(threat)
	if(!entry)
		return AI_THREAT_DEFAULT_PASS_FLAGS
	return entry[1]

///Выкинуть протухшие наблюдения, а при переполнении - и старейшее живое
/datum/ai_controller/proc/prune_threat_memory()
	var/oldest_key
	var/oldest_time = INFINITY
	//обход по копии ключей: удаление из живого списка пропускает соседние записи
	for(var/threat_key in threat_pass_flag_memory.Copy())
		var/list/entry = threat_pass_flag_memory[threat_key]
		if(world.time - entry[2] > AI_THREAT_MEMORY_TIMEOUT)
			threat_pass_flag_memory -= threat_key
			continue
		if(entry[2] < oldest_time)
			oldest_time = entry[2]
			oldest_key = threat_key
	if(length(threat_pass_flag_memory) >= AI_THREAT_MEMORY_MAX && oldest_key)
		threat_pass_flag_memory -= oldest_key

///Есть ли непротухшее наблюдение, что этот атом по нам СТРЕЛЯЛ. Надёжнее любой
///проверки рук: запись появляется от факта попадания снаряда, поэтому закрывает
///и кинетик, и мех, и турель, и убранный на секунду в карман ствол - всё, что
///is_holding_item_of_type() не видит в принципе.
/datum/ai_controller/proc/knows_target_shoots(atom/threat)
	return !isnull(get_threat_memory_entry(threat))

///Прикрыт ли тайл от конкретной угрозы С УЧЁТОМ ТОГО, ЧЕМ ОНА СТРЕЛЯЕТ.
/datum/ai_controller/proc/cover_quality(turf/from_turf, atom/threat)
	var/turf/threat_turf = get_turf(threat)
	if(!from_turf || !threat_turf)
		return AI_COVER_FULL
	if(from_turf.z != threat_turf.z)
		return AI_COVER_FULL
	if(from_turf == threat_turf)
		return AI_COVER_NONE
	//глухая преграда где-то на линии укрывает от всего
	if(!can_see(from_turf, threat, AI_HIDING_LOS_RANGE))
		return AI_COVER_FULL
	//прозрачная преграда укрывает избирательно: окно и решётка держат пулю,
	//но пропускают луч, и стоять за ними от лазерщика бессмысленно
	if(ai_edge_stops_projectile(from_turf, get_step(from_turf, get_dir(from_turf, threat_turf)), threat_pass_flags(threat)))
		return AI_COVER_FULL
	return AI_COVER_NONE

///Прикрыта ли текущая позиция пауна от того, кто по нему сейчас работает.
/datum/ai_controller/proc/current_position_covered(atom/threat)
	return cover_quality(get_turf(pawn), threat) == AI_COVER_FULL

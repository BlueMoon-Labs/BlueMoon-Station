/proc/WEAKREF(datum/input)
	if(istype(input) && !QDELETED(input))
		if(istype(input, /datum/weakref))
			return input

		if(!input.weak_reference)
			input.weak_reference = new /datum/weakref(input)
		return input.weak_reference

/datum/proc/create_weakref()		//Forced creation for admin proccalls
	return WEAKREF(src)

/datum/weakref
	var/reference

/datum/weakref/New(datum/thing)
	reference = REF(thing)

/datum/weakref/Destroy(force)
	if(!force)
		return QDEL_HINT_LETMELIVE	//Let BYOND autoGC this when nothing is using it anymore.
	var/datum/target = locate(reference)
	if(target?.weak_reference == src)
		target.weak_reference = null
	return ..()

/datum/weakref/proc/resolve()
	var/datum/D = locate(reference)
	return (!QDELETED(D) && D.weak_reference == src) ? D : null

/// Как resolve(), но возвращает и qdel-нутую (ещё не собранную GC) цель.
/// Для диагностики: именование того, что как раз сейчас удаляется.
/datum/weakref/proc/hard_resolve()
	var/datum/target = locate(reference)
	if(isnull(target))
		return null
	// BYOND переиспользует ref-слоты: живой датум обязан указывать на нас,
	// иначе это уже чужой объект. У qdel-нутой цели weak_reference обнулён
	// в Destroy(), поэтому её возвращаем без этой проверки.
	if(!QDELETED(target) && target.weak_reference != src)
		return null
	return target


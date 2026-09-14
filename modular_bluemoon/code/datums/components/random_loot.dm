/datum/component/random_loot
	/// Ассоциативный список предмет -> вес (pickweight)
	var/list/loot_table
	/// Флаг, спавнить ли предмет на месте смерти (по умолчанию TRUE)
	var/spawn_on_loc = TRUE

/datum/component/random_loot/Initialize(list/_loot_table, _spawn_on_loc = TRUE)
	if(!islist(_loot_table) || !length(_loot_table))
		return COMPONENT_INCOMPATIBLE
	loot_table = _loot_table
	spawn_on_loc = _spawn_on_loc
	RegisterSignal(parent, COMSIG_MOB_DEATH, PROC_REF(on_death))
	return ..()

/datum/component/random_loot/proc/on_death(mob/source, gibbed)
	SIGNAL_HANDLER
	if(!loot_table || !length(loot_table))
		return
	var/picked = pickweight(loot_table)
	if(picked && ispath(picked))
		var/turf/spawn_turf = spawn_on_loc ? get_turf(source) : source.drop_location()
		if(spawn_turf)
			new picked(spawn_turf)

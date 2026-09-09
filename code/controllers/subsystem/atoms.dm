#define BAD_INIT_QDEL_BEFORE 1
#define BAD_INIT_DIDNT_INIT 2
#define BAD_INIT_SLEPT 4
#define BAD_INIT_NO_HINT 8

SUBSYSTEM_DEF(atoms)
	name = "Atoms"
	init_order = INIT_ORDER_ATOMS
	flags = SS_NO_FIRE

	var/old_initialized

	var/list/late_loaders = list()

	var/list/BadInitializeCalls = list()

	/// Atoms that will be deleted once the subsystem is initialized
	var/list/queued_deletions = list()

	initialized = INITIALIZATION_INSSATOMS

	#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
	var/atoms_count = 0
	var/total_duration = 0
	var/atom_types = list()
	var/type_counts = list()
	var/type_times = list()
	#endif								// --- END ATOM STATISTICS LOGGING ---

/datum/controller/subsystem/atoms/Initialize(timeofday)
	GLOB.fire_overlay.appearance_flags = RESET_COLOR
	setupGenetics() //to set the mutations' sequence

	initialized = INITIALIZATION_INNEW_MAPLOAD
	InitializeAtoms()
	initialized = INITIALIZATION_INNEW_REGULAR

	#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
	Savelog()
	#endif								// --- END ATOM STATISTICS LOGGING ---

	return ..()

/datum/controller/subsystem/atoms/last_task()
	if(initialized == INITIALIZATION_INSSATOMS)
		return "инициализация атомов карты, поздних загрузчиков [length(late_loaders)]"
	return "поздних загрузчиков [length(late_loaders)], в очереди на удаление [length(queued_deletions)]"

/datum/controller/subsystem/atoms/proc/InitializeAtoms(list/atoms)
	if(initialized == INITIALIZATION_INSSATOMS)
		return

	old_initialized = initialized
	initialized = INITIALIZATION_INNEW_MAPLOAD

	var/count
	var/list/mapload_arg = list(TRUE)

	#ifdef ATOM_STATISTICS_LOGGING			// --- ATOM STATISTICS LOGGING ---
	var/list/logged_atoms = list()
	var/list/logged_times = list()

	var/start_time
	var/total_start_time

	total_start_time = world.timeofday
	#endif									// --- END ATOM STATISTICS LOGGING ---

	if(atoms)
		count = atoms.len
		for(var/I in 1 to count)
			var/atom/A = atoms[I]
			// Атом мог быть qdel-нут и hard-del-нут (del() нуллит слот списка),
			// пока инициализация ползла по CHECK_TICK - как в цикле late_loaders.
			if(isnull(A))
				continue
			if(!(A.flags_1 & INITIALIZED_1))
				#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
				start_time = TICK_USAGE
				InitAtom(A, mapload_arg)
				LAZYADD(logged_atoms,A.type)
				LAZYADD(logged_times, TICK_USAGE_TO_MS(start_time))
				#else								// --- END ATOM STATISTICS LOGGING ---
				InitAtom(A, mapload_arg)
				#endif
				CHECK_TICK
	else
		count = 0
		for(var/atom/A in world)
			if(!(A.flags_1 & INITIALIZED_1))
				#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
				start_time = TICK_USAGE
				InitAtom(A, mapload_arg)
				LAZYADD(logged_atoms,A.type)
				LAZYADD(logged_times, TICK_USAGE_TO_MS(start_time))
				#else								// --- END ATOM STATISTICS LOGGING ---
				InitAtom(A, mapload_arg)
				#endif
				++count
				CHECK_TICK

	testing("Initialized [count] atoms")
	pass(count)

	#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
	// --- ATOM LOADING TIMER & GROUPING ---
	total_duration += (world.timeofday - total_start_time) / 10

	atoms_count = atoms_count + logged_atoms.len

	for(var/I in 1 to logged_atoms.len)
		var/the_type = logged_atoms[I]
		if(isnull(the_type)) continue
		if(the_type in atom_types)
			type_counts[the_type] += 1
			type_times[the_type] += logged_times[I]
		else
			atom_types[the_type] = TRUE
			type_counts[the_type] = 1
			type_times[the_type] = logged_times[I]
		CHECK_TICK
	#endif								// --- END ATOM STATISTICS LOGGING ---

	initialized = old_initialized

	if(late_loaders.len)
		for(var/I in 1 to late_loaders.len)
			var/atom/A = late_loaders[I]
			if(QDELETED(A))
				continue
			A.LateInitialize()
		testing("Late initialized [late_loaders.len] atoms")
		late_loaders.Cut()

	for (var/queued_deletion in queued_deletions)
		qdel(queued_deletion)

	testing("[queued_deletions.len] atoms were queued for deletion.")
	queued_deletions.Cut()

/// Init this specific atom
/datum/controller/subsystem/atoms/proc/InitAtom(atom/A, list/arguments)
	var/the_type = A.type
	if(QDELING(A))
		BadInitializeCalls[the_type] |= BAD_INIT_QDEL_BEFORE
		return TRUE

	var/start_tick = world.time

	var/result = A.Initialize(arglist(arguments))

	if(start_tick != world.time)
		BadInitializeCalls[the_type] |= BAD_INIT_SLEPT

	var/qdeleted = FALSE

	if(result != INITIALIZE_HINT_NORMAL)
		switch(result)
			if(INITIALIZE_HINT_LATELOAD)
				if(arguments[1])	//mapload
					late_loaders += A
				else
					A.LateInitialize()
			if(INITIALIZE_HINT_QDEL)
				qdel(A)
				qdeleted = TRUE
			if(INITIALIZE_HINT_QDEL_FORCE)
				qdel(A, force = TRUE)
				qdeleted = TRUE
			else
				BadInitializeCalls[the_type] |= BAD_INIT_NO_HINT

	if(!A)	//possible harddel
		qdeleted = TRUE
	else if(!(A.flags_1 & INITIALIZED_1))
		BadInitializeCalls[the_type] |= BAD_INIT_DIDNT_INIT
	else
		SEND_SIGNAL(A,COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE)

	return qdeleted || QDELING(A)

/datum/controller/subsystem/atoms/proc/map_loader_begin()
	old_initialized = initialized
	initialized = INITIALIZATION_INSSATOMS

/datum/controller/subsystem/atoms/proc/map_loader_stop()
	initialized = old_initialized

/datum/controller/subsystem/atoms/Recover()
	initialized = SSatoms.initialized
	if(initialized == INITIALIZATION_INNEW_MAPLOAD)
		InitializeAtoms()
	old_initialized = SSatoms.old_initialized
	BadInitializeCalls = SSatoms.BadInitializeCalls

/datum/controller/subsystem/atoms/proc/setupGenetics()
	var/list/mutations = subtypesof(/datum/mutation/human)
	shuffle_inplace(mutations)
	for(var/A in subtypesof(/datum/generecipe))
		var/datum/generecipe/GR = A
		GLOB.mutation_recipes[initial(GR.required)] = initial(GR.result)
	for(var/i in 1 to LAZYLEN(mutations))
		var/path = mutations[i] //byond gets pissy when we do it in one line
		var/datum/mutation/human/B = new path ()
		B.alias = "Mutation [i]"
		GLOB.all_mutations[B.type] = B
		GLOB.full_sequences[B.type] = generate_gene_sequence(B.blocks)
		GLOB.alias_mutations[B.alias] = B.type
		if(B.locked)
			continue
		if(B.quality == POSITIVE)
			GLOB.good_mutations |= B
		else if(B.quality == NEGATIVE)
			GLOB.bad_mutations |= B
		else if(B.quality == MINOR_NEGATIVE)
			GLOB.not_good_mutations |= B
		CHECK_TICK

/datum/controller/subsystem/atoms/proc/InitLog()
	. = ""
	for(var/path in BadInitializeCalls)
		. += "Path : [path] \n"
		var/fails = BadInitializeCalls[path]
		if(fails & BAD_INIT_DIDNT_INIT)
			. += "- Didn't call atom/Initialize(mapload)\n"
		if(fails & BAD_INIT_NO_HINT)
			. += "- Didn't return an Initialize hint\n"
		if(fails & BAD_INIT_QDEL_BEFORE)
			. += "- Qdel'd in New()\n"
		if(fails & BAD_INIT_SLEPT)
			. += "- Slept during Initialize()\n"

#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
/datum/controller/subsystem/atoms/proc/atom_load_log()
	var/msg = list()
	msg += "=== ATOM LOADING STATISTICS ===\nTotal atoms initialized: [atoms_count]\nTotal duration: [total_duration] seconds\n"

	for(var/path in atom_types)
		var/num = type_counts[path]
		var/duration = type_times[path]
		msg += "[path]:\n  Count: [num]\n  Duration: [duration] ms\n  Avg per atom: [duration / num] ms\n"
		CHECK_TICK

	return jointext(msg, "\n")
#endif								// --- END ATOM STATISTICS LOGGING ---

/// Prepares an atom to be deleted once the atoms SS is initialized.
/datum/controller/subsystem/atoms/proc/prepare_deletion(atom/target)
	if (initialized == INITIALIZATION_INNEW_REGULAR)
		// Atoms SS has already completed, just kill it now.
		qdel(target)
	else
		queued_deletions += WEAKREF(target)

/datum/controller/subsystem/atoms/Shutdown()
	Savelog()

/datum/controller/subsystem/atoms/proc/Savelog()
	var/initlog = InitLog()
	if(initlog)
		fdel("[GLOB.log_directory]/initialize.log")
		text2file(initlog, "[GLOB.log_directory]/initialize.log")

	#ifdef ATOM_STATISTICS_LOGGING		// --- ATOM STATISTICS LOGGING ---
	var/atom_log = atom_load_log()
	if(atom_log)
		fdel("[GLOB.log_directory]/atom_loading_stats.log")
		text2file(atom_log, "[GLOB.log_directory]/atom_loading_stats.log")
	#endif								// --- END ATOM STATISTICS LOGGING ---

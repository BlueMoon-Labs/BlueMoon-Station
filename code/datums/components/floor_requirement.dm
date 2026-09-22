/**
  * Компонент требования turf/open/floor под своим владельцем: если его нет, мы это разберём
  * Нужно для объектов машинерии и объектов с деконструкцией, например /obj/structure/fans/tiny
  * Потенциально можно апгрейднуть в вариант requires_turf, чтобы разбирать всякие /obj/machinery/power/apc при уничтожении родной стены
  */
/datum/component/requires_floor
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Переменная кэша турфа для корректного удаления
	var/turf/watched_turf

/datum/component/requires_floor/Initialize()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	var/atom/atom = parent
	if(!isfloorturf(atom.loc))
		return COMPONENT_INCOMPATIBLE
	watched_turf = atom.loc
	RegisterSignal(watched_turf, COMSIG_PARENT_QDELETING, PROC_REF(on_floor_qdeleting))

/datum/component/requires_floor/Destroy(force, silent)
	if(watched_turf)
		UnregisterSignal(watched_turf, COMSIG_PARENT_QDELETING)
		watched_turf = null
	return ..()

/**
  * Прок разборки parent компонента, если условие удаления родителя-турфа пола выполнено.
  * Неважно, что разобрало родителя: инструменты, взрыв или админ-кнопки.
  */
/datum/component/requires_floor/proc/on_floor_qdeleting(datum/source)
	SIGNAL_HANDLER
	if(source != watched_turf)
		return
	var/atom/movable/atom = parent
	if(QDELETED(atom))
		return
	addtimer(CALLBACK(src, PROC_REF(timered_floor_check), atom), 0)

/**
  * Референсный прок довыполнения кода для этого компонента.
  *
  * Поскольку наш билд выполняет проход по коду COMSIG_PARENT_QDELETING перед выполнением destroy(), как описано в code\__DEFINES\dcs\signals.dm, то
  * мы не можем корректно записать новый watched_turf, если под снятой плиткой окажется обшивка/астероид/песок/etc. Для игры в этих координатах все ещё существует старый турф.
  *
  * Таймер призван решить это, освобождая call stack для того, чтобы успел вызваться destroy(), чтобы только после этого взяться здесь за остальную логику.
  */
/datum/component/requires_floor/proc/timered_floor_check(atom/movable/atom)
	if(QDELETED(src) || QDELETED(atom))
		return
	if(isfloorturf(atom.loc))
		if(watched_turf)
			UnregisterSignal(watched_turf, COMSIG_PARENT_QDELETING)
		watched_turf = atom.loc
		RegisterSignal(watched_turf, COMSIG_PARENT_QDELETING, PROC_REF(on_floor_qdeleting))
		return
	if(ismachinery(atom) || isobj(atom))
		var/obj/object = atom
		if(object.flags_1 & NODECONSTRUCT_1)
			qdel(object)
		else
			object.deconstruct()

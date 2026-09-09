/**
 * Разрешённая сцена параллакса для одного z-уровня.
 *
 * Хранит уже созданные объекты слоёв - со снятой случайностью, выбранным
 * вариантом и наложенной палитрой. Держатели клиентов не владеют этим датумом:
 * они берут из него клоны слоёв, поэтому один экземпляр обслуживает весь z.
 */
/datum/parallax
	/// List of parallax objects - these are cloned to a parallax holder using Clone on each.
	var/list/atom/movable/screen/parallax_layer/objects
	/// Parallax layers
	var/layers = 0
	/// Профиль, из которого собрана сцена.
	var/datum/parallax_profile/profile
	/// id профиля - по нему подсистема понимает, что тип шаблона протух даже тогда,
	/// когда DM-тип остался прежним.
	var/profile_id
	/// Ревизия состояния модификаторов z на момент постройки.
	var/revision = 0
	/// Окружение уровня, под которое собрана сцена. NONE - сцена без привязки к z
	/// (админский предпросмотр, вторичная карта): гейт слоёв в ней не работает.
	var/environment = NONE

/datum/parallax/New(datum/parallax_profile/build_from, list/extra_layers, tint, revision = 0, environment = NONE)
	if(!build_from)
		objects = list()
		return
	profile = build_from
	profile_id = build_from.id
	src.revision = revision
	src.environment = environment
	objects = build_from.Build(extra_layers, tint, environment)
	layers = length(objects)

/datum/parallax/Destroy()
	QDEL_LIST(objects)
	profile = null
	return ..()

/**
 * Gets a new version of the objects inside - used when applying to a holder.
 */
/datum/parallax/proc/GetObjects()
	. = list()
	for(var/atom/movable/screen/parallax_layer/layer as anything in objects)
		. += layer.Clone()

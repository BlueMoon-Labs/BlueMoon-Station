SUBSYSTEM_DEF(parallax)
	name = "Parallax"
	wait = 2
	flags = SS_POST_FIRE_TIMING | SS_BACKGROUND
	priority = FIRE_PRIORITY_PARALLAX
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	var/list/currentrun
	/// Каталог профилей: id -> /datum/parallax_profile. Заполняется в Initialize.
	var/list/datum/parallax_profile/profiles_by_id = list()
	/// Профили, участвующие в автоподборе (weight > 0).
	var/list/datum/parallax_profile/weighted_profiles = list()
	/// Базовый профиль, выбранный для z-уровня. Ключ - "[z]".
	/// Выбирается один раз, поэтому сцена стабильна весь раунд и независима между z.
	var/list/base_profile_by_z = list()
	/// Cached parallax templates by z-level to reduce qdel/new churn on holder resets
	var/list/datum/parallax/parallax_templates_by_z = list()
	/// Стек модификаторов на z. Ключ - "[z]", значение - список /datum/parallax_modifier
	/// в порядке возрастания приоритета.
	var/list/modifiers_by_z = list()
	/// Счётчик изменений сцены на z. Шаблон с чужой ревизией считается протухшим -
	/// это страховка на случай, если инвалидацию где-то забыли позвать явно.
	var/list/revision_by_z = list()
	/// id внестанционного профиля, на который откатываемся, если ничего не подошло.
	/// Станционный Лаваленд не годится как общий fallback: иначе любой новый z без
	/// подходящего профиля снова покажет ориентир станции вдали от самой станции.
	var/fallback_profile_id = "deep_space"

/datum/controller/subsystem/parallax/Initialize()
	build_catalog()
	return ..()

/**
 * Собирает каталог профилей по подтипам. Профили - синглтоны: экземпляр на тип,
 * потому что они несут только декларацию, а вся изменяемая часть живёт в
 * /datum/parallax конкретного z.
 */
/datum/controller/subsystem/parallax/proc/build_catalog()
	// Каталог собирается лениво, если клиент в лобби попросил параллакс раньше
	// инициализации подсистемы. Тогда Initialize зовёт этот прок повторно, и без
	// выхода он выдал бы stack_trace "дубль id" на КАЖДЫЙ профиль.
	if(length(profiles_by_id))
		return
	for(var/datum/parallax_profile/profile_type as anything in subtypesof(/datum/parallax_profile))
		if(profile_type == initial(profile_type.abstract_type))
			continue
		var/profile_id = initial(profile_type.id)
		if(!profile_id)
			stack_trace("Профиль параллакса [profile_type] без id, пропущен")
			continue
		var/datum/parallax_profile/clashing = profiles_by_id[profile_id]
		if(clashing)
			stack_trace("Дубль id профиля параллакса '[profile_id]': [profile_type] и [clashing.type]")
			continue
		var/datum/parallax_profile/profile = new profile_type
		profiles_by_id[profile_id] = profile
		if(profile.weight > 0)
			weighted_profiles[profile] = profile.weight

/datum/controller/subsystem/parallax/fire(resumed = FALSE)
	if (!resumed)
		src.currentrun = GLOB.clients.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	if(times_fired % 5)		// lazy tick
		while(length(currentrun))
			var/client/processing_client = currentrun[currentrun.len]
			currentrun.len--
			if (QDELETED(processing_client) || !processing_client.eye)
				if (MC_TICK_CHECK)
					return
				continue
			if(istype(processing_client.mob, /mob/dead/new_player))
				if (MC_TICK_CHECK)
					return
				continue
			processing_client.parallax_holder?.Update()
			if (MC_TICK_CHECK)
				return
	else	// full tick
		while(length(currentrun))
			var/client/processing_client = currentrun[currentrun.len]
			currentrun.len--
			if (QDELETED(processing_client) || !processing_client.eye)
				if (MC_TICK_CHECK)
					return
				continue
			if(istype(processing_client.mob, /mob/dead/new_player))
				if (MC_TICK_CHECK)
					return
				continue
			processing_client.parallax_holder?.Update(TRUE)
			if (MC_TICK_CHECK)
				return

	currentrun = null

// ---------------------------------------------------------------------------
// Каталог и выбор профиля
// ---------------------------------------------------------------------------

/// Принимает id или сам датум профиля, возвращает датум либо null.
/datum/controller/subsystem/parallax/proc/resolve_profile(profile_or_id)
	RETURN_TYPE(/datum/parallax_profile)
	// Клиент в лобби заводит параллакс раньше, чем подсистема успевает
	// инициализироваться, и без этого получил бы пустой экран до первого Reset.
	if(!length(profiles_by_id))
		build_catalog()
	if(istype(profile_or_id, /datum/parallax_profile))
		return profile_or_id
	if(istext(profile_or_id))
		return profiles_by_id[profile_or_id]
	return null

/**
 * Определяет окружение z-уровня для автоподбора профиля.
 * Порядок важен: станционный z может нести и другие трейты.
 */
/datum/controller/subsystem/parallax/proc/environment_for_z(z)
	if(is_centcom_level(z))
		return PARALLAX_ENV_CENTCOM
	if(is_reserved_level(z))
		return PARALLAX_ENV_SHUTTLE
	if(is_station_level(z))
		return PARALLAX_ENV_STATION
	if(is_mining_level(z) || SSmapping.level_trait(z, ZTRAIT_ICE_RUINS) || SSmapping.level_trait(z, ZTRAIT_LAVA_RUINS) || SSmapping.level_trait(z, ZTRAIT_LAVA_JUNGLE_RUINS))
		return PARALLAX_ENV_PLANET
	if(SSmapping.level_trait(z, ZTRAIT_SPACE_RUINS))
		return PARALLAX_ENV_SPACE_RUINS
	// Неизвестный z по определению не станционный. Сюда попадают, например,
	// пустой космос без руин и away-уровни: им подходит общий космический пул.
	return PARALLAX_ENV_SPACE_RUINS

/// Человекочитаемое имя окружения для админского отчёта.
/datum/controller/subsystem/parallax/proc/environment_name(environment)
	switch(environment)
		if(PARALLAX_ENV_STATION)
			return "станция"
		if(PARALLAX_ENV_SPACE_RUINS)
			return "космические руины"
		if(PARALLAX_ENV_PLANET)
			return "планета"
		if(PARALLAX_ENV_SHUTTLE)
			return "гиперпространство"
		if(PARALLAX_ENV_CENTCOM)
			return "ЦК"
	return "неизвестно ([environment])"

/**
 * Базовый профиль z-уровня. Выбирается один раз и запоминается, поэтому у всех
 * клиентов на z сцена одна и та же, она не меняется в течение раунда, а разные
 * z получают свои независимые броски.
 */
/datum/controller/subsystem/parallax/proc/get_base_profile(z)
	RETURN_TYPE(/datum/parallax_profile)
	if(!length(profiles_by_id))
		build_catalog()
	var/key = "[z]"
	var/datum/parallax_profile/cached = base_profile_by_z[key]
	if(cached)
		return cached
	var/datum/parallax_profile/picked = pick_profile_for_z(z)
	base_profile_by_z[key] = picked
	return picked

/// Однократный выбор профиля под z: трейт карты, иначе взвешенный бросок, иначе запасной.
/datum/controller/subsystem/parallax/proc/pick_profile_for_z(z)
	RETURN_TYPE(/datum/parallax_profile)
	var/trait_id = SSmapping.level_trait(z, ZTRAIT_PARALLAX)
	if(trait_id)
		var/datum/parallax_profile/from_trait = resolve_profile(trait_id)
		if(from_trait)
			return from_trait
		stack_trace("z-трейт [ZTRAIT_PARALLAX] на z [z] ссылается на несуществующий профиль '[trait_id]'")

	var/environment = environment_for_z(z)
	var/list/candidates = list()
	for(var/datum/parallax_profile/profile as anything in weighted_profiles)
		if(!(profile.environment_flags & environment))
			continue
		if(length(profile.z_traits) && !SSmapping.level_has_any_trait(z, profile.z_traits))
			continue
		candidates[profile] = profile.weight
	if(length(candidates))
		return pickweight(candidates)
	return profiles_by_id[fallback_profile_id]

/// Явно закрепляет базовый профиль за z (конфиг карты, отладка). Не проходит через
/// стек модификаторов, поэтому события сверху всё равно смогут его перебить.
/datum/controller/subsystem/parallax/proc/set_base_profile(z, profile_or_id)
	var/datum/parallax_profile/profile = resolve_profile(profile_or_id)
	if(!profile)
		return FALSE
	base_profile_by_z["[z]"] = profile
	invalidate_z(z)
	return TRUE

// ---------------------------------------------------------------------------
// Шаблоны
// ---------------------------------------------------------------------------

/**
 * Собранная сцена z-уровня, общая для всех его клиентов.
 *
 * Шаблон пересобирается, если его ревизия отстала от ревизии z. Ревизию двигает
 * любое изменение стека модификаторов или базового профиля.
 */
/datum/controller/subsystem/parallax/proc/get_parallax_template(z)
	RETURN_TYPE(/datum/parallax)
	if(!isnum(z) || z < 1)
		return null
	var/key = "[z]"
	var/current_revision = revision_by_z[key] || 0
	var/datum/parallax/template = parallax_templates_by_z[key]
	if(template && !QDELETED(template) && template.revision == current_revision)
		return template

	var/datum/parallax_profile/profile = get_base_profile(z)
	if(!profile)
		return null
	var/list/extra_layers = list()
	var/tint
	for(var/datum/parallax_modifier/modifier as anything in modifiers_by_z[key])
		if(modifier.profile)
			profile = modifier.profile
		if(length(modifier.extra_layers))
			extra_layers += modifier.extra_layers
		if(modifier.tint)
			tint = modifier.tint

	template = new /datum/parallax(profile, extra_layers, tint, current_revision, environment_for_z(z))
	apply_saved_layer_colors(key, template)
	parallax_templates_by_z[key] = template
	return template

/// Возвращает на пересобранную сцену цвета, выставленные animate_layer_type().
/// Идёт по стеку снизу вверх, поэтому старший модификатор перебивает младшего - тем же
/// порядком, каким собирается и всё остальное в шаблоне.
/datum/controller/subsystem/parallax/proc/apply_saved_layer_colors(key, datum/parallax/template)
	for(var/datum/parallax_modifier/modifier as anything in modifiers_by_z[key])
		if(!LAZYLEN(modifier.layer_colors))
			continue
		for(var/atom/movable/screen/parallax_layer/layer as anything in template.objects)
			var/saved = modifier.layer_colors[layer.type]
			if(saved)
				layer.color = saved

/**
 * Помечает сцену z-уровня протухшей и перестраивает её у клиентов.
 *
 * Порядок обязателен: сперва шаблон выбрасывается из кэша, потом клиенты
 * пересобираются (и получают новый шаблон), и только затем старый удаляется.
 * Обратный порядок оставил бы держателям ссылку на удалённый датум.
 */
/datum/controller/subsystem/parallax/proc/invalidate_z(z, refresh = TRUE, fade_time = 0)
	var/key = "[z]"
	revision_by_z[key] = (revision_by_z[key] || 0) + 1
	var/datum/parallax/stale = parallax_templates_by_z[key]
	parallax_templates_by_z -= key
	if(refresh)
		refresh_clients(z, stale, fade_time)
	if(!stale)
		return
	if(fade_time > 0)
		// При плавной смене держатели пересобираются не сразу, а по таймеру затемнения,
		// и до тех пор ещё ссылаются на старый шаблон. Удалить его прямо здесь значило
		// бы оставить им ссылку на удалённый датум и подвесить его сборку мусора.
		QDEL_IN(stale, fade_time + 2)
	else
		qdel(stale)

/**
 * Пересобирает держателей, которых затронула инвалидация z.
 *
 * Сверяемся и по z глаза, и по ссылке на протухший шаблон: клиент мог смотреть
 * на z чужим глазом (гост, камера, вторичная карта), и тогда по мобу его не найти.
 */
/datum/controller/subsystem/parallax/proc/refresh_clients(z, datum/parallax/stale, fade_time = 0)
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(!holder)
			continue
		// Сверять по шаблону можно только когда он есть: invalidate_z передаёт
		// stale = null, если шаблона на z ещё не было, а у свежего держателя
		// parallax тоже null - и тогда под пересборку попадали клиенты чужих z.
		if(holder.last?.z != z && !(stale && holder.parallax == stale))
			continue
		if(fade_time > 0)
			holder.FadeAndReset(fade_time)
		else
			holder.Reset()

// ---------------------------------------------------------------------------
// Модификаторы
// ---------------------------------------------------------------------------

/**
 * Кладёт модификатор на z под уникальным токеном.
 *
 * Повторный вызов с тем же токеном заменяет запись - так источник может двигать
 * свой эффект, не плодя слоёв. Снятие идёт только по токену, поэтому наложенные
 * друг на друга события не восстанавливают чужое устаревшее состояние.
 *
 * @param profile_or_id - подмена профиля целиком, id или датум. Необязательно.
 * @param extra_layers - типпасы слоёв поверх выбранного профиля. Необязательно.
 * @param tint - цвет для слоёв с palette_tinted. Необязательно.
 * @param fade_time - если больше нуля, сцена сменится через затемнение, а не рывком.
 */
/datum/controller/subsystem/parallax/proc/add_modifier(z, token, profile_or_id, list/extra_layers, tint, priority = 0, fade_time = 0)
	RETURN_TYPE(/datum/parallax_modifier)
	if(!isnum(z) || z < 1 || !token)
		CRASH("add_modifier: некорректные z ([z]) или токен ([token])")
	var/datum/parallax_profile/profile = resolve_profile(profile_or_id)
	if(profile_or_id && !profile)
		stack_trace("add_modifier: неизвестный профиль '[profile_or_id]'")
	var/key = "[z]"
	var/list/stack = modifiers_by_z[key]
	if(!stack)
		stack = list()
		modifiers_by_z[key] = stack
	for(var/datum/parallax_modifier/existing as anything in stack)
		if(existing.token != token)
			continue
		stack -= existing
		qdel(existing)
		break
	var/datum/parallax_modifier/modifier = new(token, z, priority, profile, extra_layers, tint)
	// Вставка с сохранением порядка по приоритету: стек короткий, сортировать нечего.
	var/inserted = FALSE
	for(var/i in 1 to length(stack))
		var/datum/parallax_modifier/other = stack[i]
		if(other.priority <= priority)
			continue
		stack.Insert(i, modifier)
		inserted = TRUE
		break
	if(!inserted)
		stack += modifier
	invalidate_z(z, TRUE, fade_time)
	return modifier

/// Снимает модификатор по токену. Возвращает TRUE, если что-то сняли.
/datum/controller/subsystem/parallax/proc/remove_modifier(z, token, fade_time = 0)
	var/key = "[z]"
	var/list/stack = modifiers_by_z[key]
	if(!length(stack))
		return FALSE
	for(var/datum/parallax_modifier/modifier as anything in stack)
		if(modifier.token != token)
			continue
		stack -= modifier
		qdel(modifier)
		if(!length(stack))
			modifiers_by_z -= key
		invalidate_z(z, TRUE, fade_time)
		return TRUE
	return FALSE

/// Снимает токен со всех z-уровней сразу - удобно для завершения события.
/datum/controller/subsystem/parallax/proc/remove_modifier_everywhere(token, fade_time = 0)
	. = FALSE
	for(var/key in modifiers_by_z.Copy())
		if(remove_modifier(text2num(key), token, fade_time))
			. = TRUE

/// Ставит профиль на z под токеном.
/datum/controller/subsystem/parallax/proc/set_profile(z, profile_or_id, token, priority = 0, fade_time = 0)
	return add_modifier(z, token, profile_or_id, null, null, priority, fade_time)

/// Возвращает z его исходный профиль, снимая модификатор токена.
/datum/controller/subsystem/parallax/proc/restore_profile(z, token, fade_time = 0)
	return remove_modifier(z, token, fade_time)

/// Добавляет временные слои поверх текущей сцены z.
/datum/controller/subsystem/parallax/proc/add_layers(z, token, list/layer_paths, priority = 0, fade_time = 0)
	return add_modifier(z, token, null, layer_paths, null, priority, fade_time)

/// Перекрашивает слои сцены z, помеченные palette_tinted.
/datum/controller/subsystem/parallax/proc/set_tint(z, token, tint, priority = 0, fade_time = 0)
	return add_modifier(z, token, null, null, tint, priority, fade_time)

/// Находит модификатор по токену на z.
/datum/controller/subsystem/parallax/proc/find_modifier(z, token)
	RETURN_TYPE(/datum/parallax_modifier)
	for(var/datum/parallax_modifier/modifier as anything in modifiers_by_z["[z]"])
		if(modifier.token == token)
			return modifier
	return null

/**
 * Плавно перекрашивает слои сцены z, не пересобирая её.
 *
 * Пересборка через set_tint оборвала бы анимацию у всех сразу, поэтому цвет
 * тянется прямо на живых слоях держателей. Заодно правится и шаблон - он же
 * источник клонов, и без этого зашедший посреди перехода клиент получил бы
 * предыдущий оттенок.
 *
 * Возвращает FALSE, если модификатора с таким токеном на z нет.
 */
/datum/controller/subsystem/parallax/proc/animate_tint(z, token, tint, time = 0)
	var/datum/parallax_modifier/modifier = find_modifier(z, token)
	if(!modifier)
		return FALSE
	modifier.tint = tint
	var/datum/parallax/template = parallax_templates_by_z["[z]"]
	if(template)
		for(var/atom/movable/screen/parallax_layer/layer as anything in template.objects)
			if(layer.palette_tinted)
				layer.color = tint
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(holder?.last?.z != z)
			continue
		for(var/atom/movable/screen/parallax_layer/layer as anything in holder.layers)
			if(!layer.palette_tinted)
				continue
			if(time > 0)
				animate(layer, color = tint, time = time)
			else
				layer.color = tint
	return TRUE

/**
 * Плавно ведёт цвет ОДНОГО типа слоя на z, не трогая остальную сцену.
 *
 * animate_tint() красит всё, что помечено palette_tinted, и для фазовой подсветки это
 * не годится: в сцене могут лежать звёздные ярусы и дымки с тем же флагом, и они ушли
 * бы в цвет подсветки вместе с ней. Здесь адресатом выступает конкретный тип слоя.
 *
 * Шаблон правится наравне с живыми держателями: он источник клонов, и без этого зашедший
 * посреди явления клиент получил бы слой в цвете начала события.
 *
 * Цвет запоминается на модификаторе, который этот слой и принёс. Без этого он жил бы
 * ровно до ближайшей инвалидации z: шаблон пересобирается с нуля, а на плато пика
 * интенсивность не меняется, и следующего вызова, который вернул бы цвет, не будет.
 */
/datum/controller/subsystem/parallax/proc/animate_layer_type(z, layer_type, tint, time = 0)
	if(!ispath(layer_type, /atom/movable/screen/parallax_layer) || !tint)
		return FALSE
	// Цвет слоя с luminance_alpha занят матрицей прозрачности, и запись color поверх неё
	// превращает снег, пыль или угли в непрозрачное пятно. Тот же инвариант соблюдает
	// InstantiateLayer(), пропуская такие слои мимо палитры профиля.
	var/atom/movable/screen/parallax_layer/probe = layer_type
	if(initial(probe.luminance_alpha))
		stack_trace("animate_layer_type: [layer_type] держит прозрачность матрицей яркости, красить его нельзя")
		return FALSE
	. = FALSE
	// Модификатор, объявивший этот слой, переносит цвет через пересборку сцены. Слой из
	// самого профиля запомнить негде - его перекрасит следующий вызов.
	for(var/datum/parallax_modifier/modifier as anything in modifiers_by_z["[z]"])
		if(!(layer_type in modifier.extra_layers))
			continue
		LAZYSET(modifier.layer_colors, layer_type, tint)
	var/datum/parallax/template = parallax_templates_by_z["[z]"]
	if(template)
		for(var/atom/movable/screen/parallax_layer/layer as anything in template.objects)
			if(layer.type == layer_type)
				layer.color = tint
				. = TRUE
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(holder?.last?.z != z)
			continue
		for(var/atom/movable/screen/parallax_layer/layer as anything in holder.layers)
			if(layer.type != layer_type)
				continue
			. = TRUE
			if(time > 0)
				animate(layer, color = tint, time = time)
			else
				layer.color = tint

/// Гасит слои модификатора и снимает его, когда анимация отыграла.
/// Держит таймер на подсистеме, а не на событии: событие может кончиться раньше.
/datum/controller/subsystem/parallax/proc/fade_out_modifier(z, token, time = 5 SECONDS)
	var/datum/parallax_modifier/modifier = find_modifier(z, token)
	if(!modifier)
		return FALSE
	// Гасим только СВОИ слои: наложившееся сверху событие свои гасить не просило.
	var/list/own_layers = modifier.extra_layers
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(holder?.last?.z != z)
			continue
		for(var/atom/movable/screen/parallax_layer/layer as anything in holder.layers)
			if(layer.type in own_layers)
				animate(layer, alpha = 0, time = time)
	addtimer(CALLBACK(src, PROC_REF(remove_modifier), z, token, 0), time + 1, TIMER_UNIQUE | TIMER_OVERRIDE)
	return TRUE

/// Список z, на которых сейчас есть хоть один клиент - чтобы событие не трогало пустые.
/datum/controller/subsystem/parallax/proc/populated_z_levels()
	. = list()
	for(var/client/viewer as anything in GLOB.clients)
		var/turf/eye_turf = viewer.parallax_holder?.last
		if(!eye_turf)
			continue
		. |= eye_turf.z

// ---------------------------------------------------------------------------
// Прочее
// ---------------------------------------------------------------------------

/**
 * Gets parallax added vis contents for zlevel
 */
/datum/controller/subsystem/parallax/proc/get_parallax_vis_contents(z)
	return list()

/**
 * Gets parallax motion for a zlevel
 *
 * Returns null or list(speed, dir deg clockwise from north, windup, turnrate)
 * THE RETURNED LIST MUST BE A 4-TUPLE, OR PARALLAX WILL CRASH.
 * DO NOT SCREW WITH THIS UNLESS YOU KNOW WHAT YOU ARE DOING.
 *
 * This will override area motion
 */
/// Собственный дрейф сцены сюда НЕ приходит: он идёт по pixel_x каждого слоя и
/// потому не отнимает transform у глайда шага. Здесь остаётся только принудительная
/// прокрутка всего z целиком - её пока никто не использует.
/datum/controller/subsystem/parallax/proc/get_parallax_motion(z)
	return null

/**
 * updates all parallax for clients on a z
 */
/datum/controller/subsystem/parallax/proc/update_clients_on_z(z)
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(holder?.last?.z == z)
			holder.Update()

/**
 * resets all parallax for clients on a z
 */
/datum/controller/subsystem/parallax/proc/reset_clients_on_z(z)
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(holder?.last?.z == z)
			holder.Reset()

/**
 * updates motion of all clients on z
 */
/datum/controller/subsystem/parallax/proc/update_z_motion(z)
	for(var/client/viewer as anything in GLOB.clients)
		var/datum/parallax_holder/holder = viewer.parallax_holder
		if(holder?.last?.z == z)
			holder.UpdateMotion()

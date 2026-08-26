/atom/movable/lighting_object
	icon = LIGHTING_ICON
	icon_state = null
	plane = LIGHTING_PLANE
	layer = LIGHTING_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	anchored = TRUE
	rad_flags = RAD_NO_CONTAMINATE
	// color ставится в New() ПОСЛЕ ..(), а не типовым дефолтом. Типовой дефолт цвета
	// проходит через /atom/Initialize -> `if(color) add_atom_colour(...)`, а тот заводит
	// каждому инстансу личный atom_colours на четыре слота с личной копией этой самой
	// двадцатиэлементной матрицы внутри. Читать atom_colours у объекта освещения некому:
	// update() пишет color напрямую, мимо системы приоритетов. При четверти миллиона
	// объектов на мир это 344 Б на штуку впустую. У tg по той же причине color = null.

	///whether we are already in the SSlighting.objects_queue list
	var/needs_update = FALSE

	///the turf that our light is applied to
	var/turf/affected_turf

	// Двенадцати поканальных prev_* здесь больше нет. Они держали предыдущее значение
	// каждого канала ради гейта "ничего визуально не изменилось", но гейт сравнивал СУММУ
	// двенадцати abs-дельт с LIGHTING_ROUND_VALUE = 1/32, а углы округляются к той же 1/32
	// (lighting_corner.dm:140-148): один шаг сетки на одном канале уже даёт ровно порог, а
	// смена яркости угла двигает все три его канала разом. Контраст зоны только УВЕЛИЧИВАЕТ
	// значения (1 / 1.1 / 1.15), так что пройти под порог мог разве что одноканальный свет
	// на углу с тремя непрозрачными соседями - и то на разницу, которой не видно. За это
	// платилось три ступени блока переменных (16.2 Б * 12) на 256 761 объект прода, около
	// 50 МБ из 4094 потолка, плюс 34 арифметические операции в самом горячем проке света
	// на КАЖДЫЙ апдейт. См. lighting_object_var_diet.dm.

	/// Shared static color matrix buffer — reused across all lighting objects to avoid per-instance allocation.
	/// Safe because update() runs sequentially in SSlighting fire() and BYOND copies the list on color assignment.
	var/static/list/shared_color_buffer = list(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)

	// Fast skip for turfs that stay dark — avoids ALL corner reads, shadow, profile, and matrix work
	var/prev_was_dark = FALSE

	/// TRUE только у объекта на ГРАНИЦЕ зон - у него профиль усреднён с соседями и лежит в
	/// blended_* ниже. У всех остальных профиль равен профилю собственной зоны и на объекте
	/// не хранится: четыре записи на 256 761 объект прода это ступень блока переменных,
	/// то есть 16.6 МБ, а разыменование affected_turf.loc в апдейте не стоит ничего.
	/// Ставится и снимается ТОЛЬКО под условием - безусловная запись FALSE поверх FALSE в
	/// BYOND всё равно занимает слот (см. reference_byond_instance_var_block_model).
	var/blend_is_local = FALSE

	// Cached blended area profile — заполняется ТОЛЬКО при blend_is_local, см. выше
	var/blended_temperature = 0
	var/blended_contrast = 1
	var/blended_contact_shadow = 1
	var/blended_ambient = AMBIENT_LIGHT_DEFAULT

/atom/movable/lighting_object/New(turf/source)
	// Гибридный рендер: объект лежит на турфе (loc = source) И продублирован в vis_contents.
	// loc-канал обязателен для ДОСТАВКИ обновлений: BYOND надёжно шлёт клиентам animate() и
	// смену appearance только у ин-ворлд атомов. У nullspace-атома, видимого исключительно
	// через vis_contents, анимации цвета до клиентов не доезжают - зоны застревают в устаревшей
	// тьме до полного пересинка турфа (выход за край view, смена z-уровня, реконнект).
	// Обходы contents от служебного атома огорожены точечно: onShuttleMove() no-op,
	// скип в фотозахвате, блэклист радиации. Каноническое создание - new(turf).
	..()
	// Начальная матрица - полностью освещённая белая, чтобы первый animate() интерполировал
	// от неё, а не от пустого цвета. Ставится здесь, а не типовым дефолтом: см. комментарий
	// у объявления типа.
	color = LIGHTING_BASE_MATRIX
	if(!isturf(source))
		qdel(src, force=TRUE)
		stack_trace("a lighting object was assigned to [source], a non turf! ")
		return

	affected_turf = source
	if (affected_turf.lighting_object)
		qdel(affected_turf.lighting_object, force = TRUE)
		stack_trace("a lighting object was assigned to a turf that already had a lighting object!")

	affected_turf.lighting_object = src
	affected_turf.luminosity = 0
	affected_turf.vis_contents += src

	if(SSlighting.init_in_progress)
		// During init, collect space turfs for batch processing (deduped via assoc list)
		for(var/turf/open/space/space_tile in RANGE_TURFS(1, affected_turf))
			GLOB.lighting_deferred_starlight[space_tile] = TRUE
	else
		for(var/turf/open/space/space_tile in RANGE_TURFS(1, affected_turf))
			space_tile.update_starlight()

	// Compute blended area profile from this turf + cardinal neighbors for soft zone transitions
	calculate_area_blend()

	needs_update = TRUE
	GLOB.lighting_update_objects += src

/atom/movable/lighting_object/Destroy(force)
	if (!force)
		return QDEL_HINT_LETMELIVE
	// Remove from queues and detach from the rendering turf BEFORE we fire the animation cancel.
	// After ChangeTurf transfers this object the turf's vis_contents entry is the only DM-visible
	// ref chain; breaking it before animate() lets BYOND release the appearance ref in the same
	// tick as the cancel, instead of carrying it into the next fire() and into a harddel.
	needs_update = FALSE
	GLOB.lighting_update_objects -= src
	GLOB.lighting_update_blends -= src
	if (isturf(affected_turf))
		// Турф отвязываем только если он всё ещё наш: у призрака из переработанной резервации
		// affected_turf уже занят свежим оверлеем нового жильца - гасить его состояние нельзя
		if (affected_turf.lighting_object == src)
			affected_turf.lighting_object = null
			affected_turf.luminosity = 1
		affected_turf.vis_contents -= src
	affected_turf = null
	// Cancel any in-progress animation to release BYOND's internal reference that prevents GC.
	// ANIMATION_END_NOW alone is a no-op — BYOND only runs the "end current" path when there is a
	// real animate() call to queue. time=0 immediately completes the stub animation so the last
	// internal ref BYOND holds on the atom is released.
	// Animate a var that NO other animate() on this atom ever touches (alpha) — update() only
	// animates color, so the "new target == current target" short-circuit BYOND uses for fresh
	// LIGHTING_DARK_MATRIX vs in-flight-to-LIGHTING_DARK_MATRIX cannot apply here.
	animate(src, alpha = 0, time = 0, flags = ANIMATION_END_NOW)
	return ..()

/// Computes blended area lighting profile by averaging this turf's area with 4 cardinal neighbors.
/// Produces soft transitions at zone boundaries instead of hard color jumps.
/atom/movable/lighting_object/proc/calculate_area_blend()
	if(!affected_turf)
		return
	prev_was_dark = FALSE
	var/area/center_area = affected_turf.loc
	var/turf/n_turf = get_step(affected_turf, NORTH)
	var/turf/s_turf = get_step(affected_turf, SOUTH)
	var/turf/e_turf = get_step(affected_turf, EAST)
	var/turf/w_turf = get_step(affected_turf, WEST)
	// Fast path: all cardinal neighbors belong to the same area — skip averaging
	if((!n_turf || n_turf.loc == center_area) && (!s_turf || s_turf.loc == center_area) && \
	   (!e_turf || e_turf.loc == center_area) && (!w_turf || w_turf.loc == center_area))
		// Профиль равен профилю собственной зоны - копировать его на объект незачем,
		// update() прочитает его через affected_turf.loc. Снимаем флаг только если он был:
		// объект, ни разу не побывавший на границе, не должен платить за эту переменную.
		if(blend_is_local)
			blend_is_local = FALSE
		return
	// Slow path: area boundary — average with neighbors for soft transitions
	var/total_temp = center_area.light_temperature
	var/total_contrast = center_area.light_contrast
	var/total_contact = center_area.contact_shadow_multiplier
	var/total_ambient = center_area.ambient_light
	var/count = 1
	var/area/neighbor_area
	if(n_turf)
		neighbor_area = n_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	if(s_turf)
		neighbor_area = s_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	if(e_turf)
		neighbor_area = e_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	if(w_turf)
		neighbor_area = w_turf.loc
		total_temp += neighbor_area.light_temperature
		total_contrast += neighbor_area.light_contrast
		total_contact += neighbor_area.contact_shadow_multiplier
		total_ambient += neighbor_area.ambient_light
		count++
	blended_temperature = total_temp / count
	blended_contrast = total_contrast / count
	blended_contact_shadow = total_contact / count
	blended_ambient = total_ambient / count
	blend_is_local = TRUE

/atom/movable/lighting_object/proc/update(animate_time = LIGHTING_ANIMATE_TIME, use_animate = TRUE)

	// To the future coder who sees this and thinks
	// "Why didn't he just use a loop?"
	// Well my man, it's because the loop performed like shit.
	// And there's no way to improve it because
	// without a loop you can make the list all at once which is the fastest you're gonna get.
	// Oh it's also shorter line wise.
	// Including with these comments.

	var/static/datum/lighting_corner/dummy/dummy_lighting_corner = new

	var/datum/lighting_corner/red_corner = affected_turf.lc_bottomleft || dummy_lighting_corner
	var/datum/lighting_corner/green_corner = affected_turf.lc_bottomright || dummy_lighting_corner
	var/datum/lighting_corner/blue_corner = affected_turf.lc_topleft || dummy_lighting_corner
	var/datum/lighting_corner/alpha_corner = affected_turf.lc_topright || dummy_lighting_corner

	// Fast skip: if this turf was dark last update and all corners are still dark,
	// skip ALL 12 corner value reads, shadow calculation, profile, epsilon, and matrix work
	if(prev_was_dark)
		if(red_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD \
			&& green_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD \
			&& blue_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD \
			&& alpha_corner.cache_mx <= LIGHTING_SOFT_THRESHOLD)
			return

	var/max = max(red_corner.cache_mx, green_corner.cache_mx, blue_corner.cache_mx, alpha_corner.cache_mx)

	var/rr = red_corner.cache_r
	var/rg = red_corner.cache_g
	var/rb = red_corner.cache_b

	var/gr = green_corner.cache_r
	var/gg = green_corner.cache_g
	var/gb = green_corner.cache_b

	var/br = blue_corner.cache_r
	var/bg = blue_corner.cache_g
	var/bb = blue_corner.cache_b

	var/ar = alpha_corner.cache_r
	var/ag = alpha_corner.cache_g
	var/ab = alpha_corner.cache_b

	// Профиль зоны. У объекта на границе он усреднён и лежит на нём самом; у всех
	// остальных - это профиль собственной зоны, и читается он отсюда, а не с объекта:
	// хранить его на четверти миллиона объектов дороже, чем один раз разыменовать loc.
	var/area/profile_area = blend_is_local ? null : affected_turf.loc
	var/profile_contact_shadow = profile_area ? profile_area.contact_shadow_multiplier : blended_contact_shadow
	var/profile_contrast = profile_area ? profile_area.light_contrast : blended_contrast
	var/profile_temperature = profile_area ? profile_area.light_temperature : blended_temperature
	var/profile_ambient = profile_area ? profile_area.ambient_light : blended_ambient

	// Contact shadows: dim corners based on nearby opaque/heavy atoms, scaled by area multiplier
	// Uses pre-computed shadow_sqrt_cache on corners (set during recalc_opaque_neighbors)
	// Supports float weights for semi-transparent shadows from tables, lockers, etc.
	var/contact_str = CONTACT_SHADOW_STRENGTH * profile_contact_shadow
	var/_rsc = red_corner.shadow_sqrt_cache
	var/_gsc = green_corner.shadow_sqrt_cache
	var/_bsc = blue_corner.shadow_sqrt_cache
	var/_asc = alpha_corner.shadow_sqrt_cache
	if(contact_str > 0 && (_rsc || _gsc || _bsc || _asc))
		var/shadow_mul
		if(_rsc)
			shadow_mul = max(0, 1 - contact_str * _rsc)
			rr *= shadow_mul; rg *= shadow_mul; rb *= shadow_mul
		if(_gsc)
			shadow_mul = max(0, 1 - contact_str * _gsc)
			gr *= shadow_mul; gg *= shadow_mul; gb *= shadow_mul
		if(_bsc)
			shadow_mul = max(0, 1 - contact_str * _bsc)
			br *= shadow_mul; bg *= shadow_mul; bb *= shadow_mul
		if(_asc)
			shadow_mul = max(0, 1 - contact_str * _asc)
			ar *= shadow_mul; ag *= shadow_mul; ab *= shadow_mul

	// Area lighting profile: temperature (warm/cool) and contrast — uses blended values for soft transitions
	if(profile_contrast != 1)
		var/contrast = profile_contrast
		rr *= contrast; rg *= contrast; rb *= contrast
		gr *= contrast; gg *= contrast; gb *= contrast
		br *= contrast; bg *= contrast; bb *= contrast
		ar *= contrast; ag *= contrast; ab *= contrast
	if(profile_temperature)
		// Multiplicative temperature: brighter areas shift more, dark areas stay neutral
		// Warm (temp > 0): ↑red ↓blue; Cool (temp < 0): ↓red ↑blue
		var/warm_mul = 1 + profile_temperature
		var/cool_mul = max(0, 1 - profile_temperature)
		rr *= warm_mul; gr *= warm_mul; br *= warm_mul; ar *= warm_mul
		rb *= cool_mul; gb *= cool_mul; bb *= cool_mul; ab *= cool_mul

		// Complementary shadow tinting: shadows shift to the opposite hue of the area temperature
		// Warm light → cool (blue) shadows, cool light → warm (red) shadows
		var/shadow_shift = -profile_temperature * SHADOW_TINT_FACTOR
		var/threshold_3x = SHADOW_TINT_THRESHOLD * 3
		var/inv_threshold = 1 / SHADOW_TINT_THRESHOLD
		var/corner_sum
		var/tint_strength
		// Red corner (bottom-left) — sum check skips division for bright corners
		corner_sum = rr + rg + rb
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			rr += shadow_shift * tint_strength
			rb -= shadow_shift * tint_strength
		// Green corner (bottom-right)
		corner_sum = gr + gg + gb
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			gr += shadow_shift * tint_strength
			gb -= shadow_shift * tint_strength
		// Blue corner (top-left)
		corner_sum = br + bg + bb
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			br += shadow_shift * tint_strength
			bb -= shadow_shift * tint_strength
		// Alpha corner (top-right)
		corner_sum = ar + ag + ab
		if(corner_sum > 0 && corner_sum < threshold_3x)
			tint_strength = (1 - corner_sum * 0.333333 * inv_threshold) * corner_sum * 0.333333
			ar += shadow_shift * tint_strength
			ab -= shadow_shift * tint_strength

	#if LIGHTING_SOFT_THRESHOLD != 0
	var/set_luminosity = max > LIGHTING_SOFT_THRESHOLD
	#else
	// Because of floating points, it won't even be a flat 0.
	// This number is mostly arbitrary.
	var/set_luminosity = max > 1e-6
	#endif

	// Luminosity is a cheap boolean — always update
	affected_turf.luminosity = set_luminosity
	prev_was_dark = !set_luminosity

	affected_turf.cached_lumcount = null

	var/list/new_color
	if((rr & gr & br & ar) && (rg + gg + bg + ag + rb + gb + bb + ab == 8))
		//anything that passes the first case is very likely to pass the second, and addition is a little faster in this case
		// Fully lit — white matrix (invisible on BLEND_MULTIPLY)
		new_color = LIGHTING_BASE_MATRIX
	else if(!set_luminosity)
		if(profile_ambient > 0)
			// Ambient floor: barely-visible base light instead of pure black (textures remain faintly visible)
			// luminosity stays FALSE — turf is still "dark" for vision mechanics
			var/amb = profile_ambient
			var/amb_key = "[round(amb, 0.005)]"
			var/list/cached = GLOB.lighting_ambient_matrices[amb_key]
			if(!cached)
				cached = list(amb, amb, amb, 0, amb, amb, amb, 0, amb, amb, amb, 0, amb, amb, amb, 0, 0, 0, 0, 1)
				GLOB.lighting_ambient_matrices[amb_key] = cached
			new_color = cached
		else
			// Fully dark — black matrix (space, void areas)
			new_color = LIGHTING_DARK_MATRIX
	else
		// Normal lit — reuse shared static buffer (BYOND copies on color assignment/animate)
		shared_color_buffer[1]  = rr; shared_color_buffer[2]  = rg; shared_color_buffer[3]  = rb
		shared_color_buffer[5]  = gr; shared_color_buffer[6]  = gg; shared_color_buffer[7]  = gb
		shared_color_buffer[9]  = br; shared_color_buffer[10] = bg; shared_color_buffer[11] = bb
		shared_color_buffer[13] = ar; shared_color_buffer[14] = ag; shared_color_buffer[15] = ab
		new_color = shared_color_buffer

	if(!use_animate || animate_time <= LIGHTING_ANIMATE_TIME_FAST)
		color = new_color
	else
		animate(src, color = new_color, time = animate_time)

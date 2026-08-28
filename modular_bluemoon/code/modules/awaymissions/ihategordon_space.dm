// =============================================================================
// IHATEGORDON CUSTOM SPACE
// Кастомный космос для гейта ihategordon с невесомостью, но нормальной атмосферой
// =============================================================================

// Кастомный турф космоса с нормальной температурой и давлением
/turf/open/space/ihategordon
	name = "Ihategordon Void"
	desc = "Странное космическое пространство. Здесь есть воздух и нормальная температура, но гравитации нет."

	// Нормальная температура (20°C = 293.15K)
	initial_temperature = T20C
	thermal_conductivity = 0
	heat_capacity = 700000
	wave_explosion_multiply = EXPLOSION_DAMPEN_SPACE
	wave_explosion_block = EXPLOSION_BLOCK_SPACE

	// Свойства космоса для правильного рендеринга
	plane = PLANE_SPACE
	layer = SPACE_LAYER
	light_power = STARLIGHT_POWER_NIGHT
	light_color = COLOR_STARLIGHT
	light_height = LIGHTING_HEIGHT_SPACE
	bullet_bounce_sound = null
	vis_flags = VIS_INHERIT_ID

	// Создаём нормальную атмосферу вместо вакуума
	var/static/datum/gas_mixture/immutable/ihategordon/ihategordon_atmos

	// Для процессинга стамины
	var/list/mobs_on_turf = list()

// Кастомная immutable газовая смесь для ihategordon
/datum/gas_mixture/immutable/ihategordon
	initial_temperature = T20C

/datum/gas_mixture/immutable/ihategordon/populate()
	set_moles(GAS_O2, MOLES_O2STANDARD)
	set_moles(GAS_N2, MOLES_N2STANDARD)
	temperature = T20C

// Невидимый чазм для ihategordon - сохраняет спрайт космоса
/turf/open/chasm/ihategordon_invisible
	name = "Ihategordon Void"
	desc = "Странное космическое пространство. Здесь есть воздух и нормальная температура, но гравитации нет."
	icon = 'icons/turf/space.dmi'
	icon_state = "0"
	baseturfs = /turf/open/chasm/ihategordon_invisible
	plane = PLANE_SPACE
	layer = SPACE_LAYER
	light_power = STARLIGHT_POWER_NIGHT
	light_color = COLOR_STARLIGHT
	light_height = LIGHTING_HEIGHT_SPACE
	bullet_bounce_sound = null
	vis_flags = VIS_INHERIT_ID
	initial_temperature = T20C
	thermal_conductivity = 0
	heat_capacity = 700000

	// Создаём нормальную атмосферу вместо вакуума
	var/static/datum/gas_mixture/immutable/ihategordon/ihategordon_atmos

/turf/open/chasm/ihategordon_invisible/Initialize(mapload)
	. = ..()
	icon_state = SPACE_ICON_STATE
	vis_contents.Cut()
	visibilityChanged()

	if(flags_1 & INITIALIZED_1)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_1 |= INITIALIZED_1

	var/area/A = loc
	if(!TURF_IS_DYNAMIC_LIGHTING(src) && IS_DYNAMIC_LIGHTING(A))
		add_overlay(/obj/effect/fullbright)

	if (light_power && light_range)
		update_light()

	if (opacity)
		lighting_flags |= TURF_HAS_OPAQUE_ATOM

	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_new(src, UP)

	// Создаём нормальную атмосферу если ещё не создана
	if(!ihategordon_atmos)
		ihategordon_atmos = new /datum/gas_mixture/immutable/ihategordon
		// Принудительно вызываем populate для инициализации газов
		ihategordon_atmos.populate()
		// Устанавливаем температуру
		ihategordon_atmos.temperature = T20C

	air = ihategordon_atmos
	update_air_ref(0)
	// Блокируем телепортацию в зону ihategordon
	RegisterSignal(src, COMSIG_ATOM_INTERCEPT_TELEPORT, PROC_REF(block_teleport))

	ComponentInitialize()

	return INITIALIZE_HINT_NORMAL

/turf/open/chasm/ihategordon_invisible/proc/block_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_TELEPORT

// Переопределяем методы чтобы атмосфера работала нормально
/turf/open/chasm/ihategordon_invisible/Initalize_Atmos(times_fired)
	// Не инициализируем атмосферу как вакуум, у нас уже есть кастомная атмосфера
	return

/turf/open/chasm/ihategordon_invisible/TakeTemperature(temp)
	// Не меняем температуру, она должна быть нормальной
	return

/turf/open/chasm/ihategordon_invisible/Assimilate_Air()
	// Не ассимилируем атмосферу, сохраняем кастомную
	return

/turf/open/chasm/ihategordon_invisible/remove_air(amount)
	// Не удаляем воздух из immutable смеси
	return null

/turf/open/chasm/ihategordon_invisible/remove_air_ratio(amount)
	// Не удаляем воздух из immutable смеси
	return null

/turf/open/chasm/ihategordon_invisible/return_air()
	// Возвращаем нашу кастомную атмосферу
	return air

/turf/open/chasm/ihategordon_invisible/return_analyzable_air()
	// Возвращаем нашу кастомную атмосферу для анализа
	return air

/turf/open/chasm/ihategordon_invisible/assume_air(datum/gas_mixture/giver)
	// Не принимаем воздух из других тайлов
	return

/turf/open/chasm/ihategordon_invisible/update_air_ref()
	// Не обновляем ссылку на воздух, сохраняем нашу кастомную атмосферу
	return

/turf/open/chasm/ihategordon_invisible/air_update_turf()
	return

// Переопределяем инициализацию для создания нормальной атмосферы
/turf/open/space/ihategordon/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE)
	icon_state = SPACE_ICON_STATE

	// Создаём нормальную атмосферу если ещё не создана
	if(!ihategordon_atmos)
		ihategordon_atmos = new /datum/gas_mixture/immutable/ihategordon
		// Принудительно вызываем populate для инициализации газов
		ihategordon_atmos.populate()
		// Устанавливаем температуру
		ihategordon_atmos.temperature = T20C

	air = ihategordon_atmos
	update_air_ref(0)
	vis_contents.Cut() //removes inherited overlays
	visibilityChanged()

	if(flags_1 & INITIALIZED_1)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_1 |= INITIALIZED_1

	var/area/A = loc
	if(!TURF_IS_DYNAMIC_LIGHTING(src) && IS_DYNAMIC_LIGHTING(A))
		add_overlay(/obj/effect/fullbright)

	if (light_power && light_range)
		update_light()

	if (opacity)
		lighting_flags |= TURF_HAS_OPAQUE_ATOM

	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_new(src, UP)

	// Регистрируем сигнал для обработки входа на тайл
	RegisterSignal(src, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	RegisterSignal(src, COMSIG_MOVABLE_CROSSED, PROC_REF(on_entered))

	// Блокируем телепортацию в зону ihategordon
	RegisterSignal(src, COMSIG_ATOM_INTERCEPT_TELEPORT, PROC_REF(block_teleport))

	ComponentInitialize()

	// Начинаем процессинг для стамины
	START_PROCESSING(SSobj, src)

	return INITIALIZE_HINT_NORMAL

// Обработка входа на тайл
/turf/open/space/ihategordon/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(!L)
		return
	// Добавляем в список мобов на тайле
	mobs_on_turf |= L
	// Убираем инерцию космоса
	L.inertia_dir = 0
	// Проверяем есть ли джетпак
	if(has_jetpack(L))
		return
	// Отнимаем стамину при входе
	L.adjustStaminaLoss(30)
	// Проверяем на стамина крит
	if(IS_STAMCRIT(L))
		// Превращаем в невидимый чазм и удаляем игрока
		to_chat(L, "<span class='userdanger'>Ваши силы покинули вас! Вы проваливаетесь в бездну!</span>")
		INVOKE_ASYNC(src, PROC_REF(drop_into_chasm), L)

// Асинхронный сброс в чазм
/turf/open/space/ihategordon/proc/drop_into_chasm(mob/living/L)
	ChangeTurf(/turf/open/chasm/ihategordon_invisible, flags = CHANGETURF_INHERIT_AIR)
	var/turf/open/chasm/ihategordon_invisible/C = src
	if(istype(C))
		C.drop(L)

// Асинхронная телепортация в безопасное место
/turf/open/space/ihategordon/proc/teleport_to_safe(mob/living/L)
	// Ищем ближайший безопасный тайл (не космос)
	var/turf/safe_turf = null
	var/min_dist = 100
	for(var/turf/T in range(10, src))
		if(!istype(T, /turf/open/space) && !istype(T, /turf/open/chasm))
			var/dist = get_dist(src, T)
			if(dist < min_dist)
				min_dist = dist
				safe_turf = T
	if(safe_turf)
		L.forceMove(safe_turf)
		L.adjustStaminaLoss(-50) // Восстанавливаем немного стамины
		to_chat(L, "<span class='notice'>Вы телепортировались в безопасное место.</span>")
	else
		// Если безопасного тайла нет, телепортируем в точку входа миссии
		for(var/area/awaymission/ihategordon/entrance/E in world)
			var/list/turfs = get_area_turfs(E)
			if(turfs.len)
				L.forceMove(pick(turfs))
				L.adjustStaminaLoss(-50)
				to_chat(L, "<span class='notice'>Вы телепортировались в точку входа.</span>")
				break

/turf/open/space/ihategordon/proc/has_jetpack(mob/living/L)
	if(!L)
		return FALSE
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		if(C.back)
			if(istype(C.back, /obj/item/tank/jetpack))
				var/obj/item/tank/jetpack/J = C.back
				if(J.on)
					return TRUE
		for(var/obj/item/organ/cyberimp/chest/thrusters/T in C.internal_organs)
			if(T && T.on)
				return TRUE
	return FALSE

// Блокировка телепортации
/turf/open/space/ihategordon/proc/block_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_TELEPORT

// Процессинг стамины
/turf/open/space/ihategordon/process()
	if(!mobs_on_turf || !mobs_on_turf.len)
		return
	for(var/mob/living/L in mobs_on_turf)
		if(!L || QDELETED(L) || get_turf(L) != src)
			mobs_on_turf -= L
			continue
		// Убираем инерцию космоса
		L.inertia_dir = 0
		// Проверяем есть ли джетпак
		if(has_jetpack(L))
			continue
		// Отнимаем стамину каждый тик
		L.adjustStaminaLoss(15)
		// Проверяем на стамина крит
		if(IS_STAMCRIT(L))
			// Превращаем в невидимый чазм и удаляем игрока
			to_chat(L, "<span class='userdanger'>Ваши силы покинули вас! Вы проваливаетесь в бездну!</span>")
			INVOKE_ASYNC(src, PROC_REF(drop_into_chasm), L)
			mobs_on_turf -= L

// Останавливаем процессинг при удалении
/turf/open/space/ihategordon/Destroy()
	STOP_PROCESSING(SSobj, src)
	mobs_on_turf.Cut()
	return ..()

// Переопределяем методы чтобы атмосфера работала нормально
/turf/open/space/ihategordon/Initalize_Atmos(times_fired)
	// Не инициализируем атмосферу как вакуум, у нас уже есть кастомная атмосфера
	return

/turf/open/space/ihategordon/TakeTemperature(temp)
	// Не меняем температуру космоса, она должна быть нормальной
	return

/turf/open/space/ihategordon/Assimilate_Air()
	// Не ассимилируем атмосферу, сохраняем кастомную
	return

/turf/open/space/ihategordon/remove_air(amount)
	// Не удаляем воздух из immutable смеси
	return null

/turf/open/space/ihategordon/remove_air_ratio(amount)
	// Не удаляем воздух из immutable смеси
	return null

/turf/open/space/ihategordon/return_air()
	// Возвращаем нашу кастомную атмосферу
	return air

/turf/open/space/ihategordon/return_analyzable_air()
	// Возвращаем нашу кастомную атмосферу для анализа
	return air

/turf/open/space/ihategordon/assume_air(datum/gas_mixture/giver)
	// Не принимаем воздух из других тайлов
	return

/turf/open/space/ihategordon/update_air_ref()
	// Не обновляем ссылку на воздух, сохраняем нашу кастомную атмосферу
	return

/turf/open/space/ihategordon/air_update_turf()
	return

// =============================================================================
// IHATEGORDON CUSTOM PARALLAX LAYERS
// Кастомные слои параллакса для гейта ihategordon
// =============================================================================

// Базовый класс для ihategordon параллакса
/atom/movable/screen/parallax_layer/ihategordon
	icon = 'modular_bluemoon/icons/effects/mesaparallax.dmi'

// Базовые слои параллакса - статичный фон без тайлинга для небесшовных спрайтов
/atom/movable/screen/parallax_layer/ihategordon/layer_1
	icon_state = "layer1"
	speed = 0.6
	layer = 1
	parallax_intensity = PARALLAX_LOW
	layer_mode = PARALLAX_MODE_TILED

/atom/movable/screen/parallax_layer/ihategordon/layer_2
	icon_state = "layer2"
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED
	layer_mode = PARALLAX_MODE_TILED

/atom/movable/screen/parallax_layer/ihategordon/layer_3
	icon_state = "layer3"
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_HIGH
	layer_mode = PARALLAX_MODE_STATIC
	center_x = 3872 // 121 * 32
	center_y = 6848 // 214 * 32

/atom/movable/screen/parallax_layer/ihategordon/random/space_gas
	icon_state = "space_gas"
	blend_mode = BLEND_OVERLAY
	speed = 2
	layer = 3
	parallax_intensity = PARALLAX_INSANE
	layer_mode = PARALLAX_MODE_TILED
	palette_tinted = TRUE

// =============================================================================
// IHATEGORDON PARALLAX PROFILE
// Профиль параллакса для гейта ihategordon
// =============================================================================

/datum/parallax_profile/ihategordon
	id = "ihategordon"
	name = "Ihategordon Void"
	environment_flags = PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_SHUTTLE
	base_layers = list(
		/atom/movable/screen/parallax_layer/ihategordon/layer_1,
		/atom/movable/screen/parallax_layer/ihategordon/layer_2,
		/atom/movable/screen/parallax_layer/ihategordon/layer_3,
	)
	variant_sets = list(
		list(70, /atom/movable/screen/parallax_layer/ihategordon/random/space_gas),
		list(30),
	)
	palette = list(COLOR_TEAL, COLOR_GREEN, COLOR_YELLOW, COLOR_CYAN, COLOR_ORANGE, COLOR_PURPLE)
	min_quality = PARALLAX_LOW
	weight = 0 // Только для ручного применения
	source = "BlueMoon Station - Mesa Mission"

// =============================================================================
// IHATEGORDON PARALLAX SUBSYSTEM HOOK
// Перехватываем выбор параллакса для z-уровней с ihategordon тайлами
// =============================================================================

/datum/controller/subsystem/parallax/proc/check_ihategordon_z(z)
	// Проверяем есть ли на этом z-уровне тайлы ihategordon space
	for(var/turf/open/space/ihategordon/T in world)
		if(T.z == z)
			return TRUE
	return FALSE

// Переопределяем get_parallax_type для ihategordon z-уровней
/datum/controller/subsystem/parallax/pick_profile_for_z(z)
	. = ..()
	// Если на этом z-уровне есть ihategordon space, используем его профиль
	if(check_ihategordon_z(z))
		var/datum/parallax_profile/ihategordon/ihategordon_profile = resolve_profile("ihategordon")
		if(ihategordon_profile)
			return ihategordon_profile

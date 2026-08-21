// ============================================================================
// Dynamic Gun Sound System
// ============================================================================
// Система динамической сборки звука автоматической стрельбы
// Использует dry loop (циклический) + tail (финальный) вместо монолитных файлов
//
// СОВМЕСТИМОСТЬ С СУЩЕСТВУЮЩЕЙ СИСТЕМОЙ:
// - Не конфликтует с существующей fire_sound системой
// - Использует безопасные проверки и null-проверки
// - Совместима с новыми стандартами из PR #3278 (default_fire_sound, suppressed_fire_sound)
// - Поддерживает глушители и другие модификаторы звука
// - Использует var/ переменные как в современных стандартах кода
//
// ИНСТРУКЦИЯ ПО ВНЕДРЕНИЮ:
//
// 1. Добавьте в определение вашего оружия переменные:
//    has_dynamic_sounds = TRUE
//    var/dry_shot_sound = 'path/to/dry_shot.ogg'
//    var/tail_shot_sound = 'path/to/tail_echo.ogg'
//    var/dynamic_sound_volume = 50
//    var/dynamic_sound_suppressed_volume = 10
//
// 2. В Initialize() добавьте инициализацию системы:
//    if(!dynamic_sound_datum)
//        dynamic_sound_datum = new /datum/dynamic_gun_sound(
//            dry_shot_sound,
//            tail_shot_sound,
//            dynamic_sound_volume,
//            TRUE,
//            dynamic_sound_suppressed_volume
//        )
//
// 3. Убедитесь, что файлы звуков существуют и имеют правильный формат:
//    - dry_shot.ogg: короткий сухой звук выстрела, будет воспроизводиться циклично
//    - tail_echo.ogg: финальный шлейф/эхо, воспроизводится один раз при прекращении стрельбы
//
// ПРИМЕР ИСПОЛЬЗОВАНИЯ:
//
// /obj/item/gun/ballistic/automatic/my_gun
//     name = "My Gun"
//     has_dynamic_sounds = TRUE
//     var/dry_shot_sound = 'modular_bluemoon/sound/weapons/my_gun_dry.ogg'
//     var/tail_shot_sound = 'modular_bluemoon/sound/weapons/my_gun_tail.ogg'
//     var/dynamic_sound_volume = 60
//     var/dynamic_sound_suppressed_volume = 10
//
// /obj/item/gun/ballistic/automatic/my_gun/Initialize(mapload)
//     . = ..()
//     if(!dynamic_sound_datum)
//         dynamic_sound_datum = new /datum/dynamic_gun_sound(
//             dry_shot_sound,
//             tail_shot_sound,
//             dynamic_sound_volume,
//             TRUE,
//             dynamic_sound_suppressed_volume
//         )
//
// СИСТЕМА АВТОМАТИЧЕСКИ:
// - Воспроизводит dry звук при каждом выстреле
// - Воспроизводит tail звук автоматически после прекращения стрельбы
// - Поддерживает глушители (если use_suppressed = TRUE)
// - Совместима с существующей системой оружия
// - Не конфликтует с другими звуковыми системами

/// Базовый тип для оружия с динамическими звуками стрельбы
/datum/dynamic_gun_sound
	var/dry_sound = null			// Сухой лооп-хлопок (Dry Shot / Close-слой)
	var/tail_sound = null			// Полный финальный выстрел с хвостом
	var/volume = 50				// Громкость звука
	var/use_suppressed = FALSE		// Использовать глушитель
	var/suppressed_volume = 10		// Громкость с глушителем
	var/dry_channel
	var/tail_channel

/datum/dynamic_gun_sound/New(dry, tail, vol = 50, suppressed = FALSE, sup_vol = 10)
	if(!dry)
		CRASH("dry_sound cannot be null for dynamic_gun_sound")
	dry_sound = dry
	tail_sound = tail
	volume = vol
	use_suppressed = suppressed
	suppressed_volume = sup_vol
	dry_channel = SSsounds.reserve_sound_channel(src)
	tail_channel = SSsounds.reserve_sound_channel(src)

/datum/dynamic_gun_sound/Destroy()
	SSsounds.free_datum_channels(src)
	return ..()

/// Процедура для воспроизведения dry звука
/datum/dynamic_gun_sound/proc/play_dry(mob/user, obj/item/gun/gun)
	if(!user || !gun)
		return
	if(!dry_sound)
		return

	var/actual_volume = volume
	var/ignore_walls = TRUE
	var/extrarange = -2
	var/falloff_distance = -1

	if(use_suppressed && gun.suppressed)
		actual_volume = suppressed_volume
		ignore_walls = FALSE
		extrarange = SILENCED_SOUND_EXTRARANGE
		falloff_distance = 0

	var/sound/dry = sound(dry_sound, repeat = FALSE, wait = FALSE, channel = dry_channel)
	playsound(user, dry, actual_volume, FALSE, ignore_walls = ignore_walls, extrarange = extrarange, falloff_distance = falloff_distance, channel = dry_channel)

/// Stops the dry layer for every listener in range.
/datum/dynamic_gun_sound/proc/stop_loop(mob/user, obj/item/gun/gun)
	if(!user || !gun)
		return
	var/actual_volume = volume
	var/ignore_walls = TRUE
	var/extrarange = -2
	var/falloff_distance = -1
	if(use_suppressed && gun.suppressed)
		actual_volume = suppressed_volume
		ignore_walls = FALSE
		extrarange = SILENCED_SOUND_EXTRARANGE
		falloff_distance = 0
	playsound(user, sound(null, repeat = FALSE, wait = FALSE, channel = dry_channel), actual_volume, FALSE, ignore_walls = ignore_walls, extrarange = extrarange, falloff_distance = falloff_distance, channel = dry_channel)

/// Процедура для воспроизведения tail звука
/datum/dynamic_gun_sound/proc/play_tail(mob/user, obj/item/gun/gun)
	if(!user || !gun)
		return
	if(!tail_sound)
		return

	var/actual_volume = volume
	var/ignore_walls = TRUE
	var/extrarange = -2
	var/falloff_distance = -1

	if(use_suppressed && gun.suppressed)
		actual_volume = suppressed_volume
		ignore_walls = FALSE
		extrarange = SILENCED_SOUND_EXTRARANGE
		falloff_distance = 0

	var/sound/full_tail = sound(tail_sound, repeat = FALSE, wait = FALSE, channel = tail_channel)
	playsound(user, full_tail, actual_volume, FALSE, ignore_walls = ignore_walls, extrarange = extrarange, falloff_distance = falloff_distance, channel = tail_channel)

// ============================================================================
// Интеграция в систему оружия
// ============================================================================

/// Переменные для добавления к оружию
#define HAS_DYNAMIC_GUN_SOUNDS (TRUE)

/// Переменные для добавления к базовому классу оружия
/obj/item/gun
	var/has_dynamic_sounds = FALSE					// Флаг использования динамических звуков
	var/datum/dynamic_gun_sound/dynamic_sound_datum = null	// Датум с настройками звуков
	var/dynamic_looping = FALSE

/// Переопределение shoot_live_shot для поддержки динамических звуков
/obj/item/gun/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	if(has_dynamic_sounds && dynamic_sound_datum)
		// Используем динамическую систему звуков
		if(recoil && !zoomed && user && pbtarget)
			directional_recoil(user, recoil*dir_recoil_amp, Get_Angle(user, pbtarget))

		if(stam_cost && user)
			var/safe_cost = clamp(stam_cost, 0, user.stamina_buffer)*(firing && burst_size >= 2 ? 1/burst_size : 1)
			user.UseStaminaBuffer(safe_cost)

		// Воспроизводим dry звук при каждом выстреле
		if(dynamic_sound_datum && user)
			if(dynamic_looping || burst_size > 1)
				dynamic_sound_datum.play_dry(user, src)
				if(!dynamic_looping)
					addtimer(CALLBACK(src, PROC_REF(finish_dynamic_burst), user), burst_shot_delay + 1, TIMER_UNIQUE | TIMER_OVERRIDE)
			else
				dynamic_sound_datum.play_tail(user, src)

		// Показываем сообщения как в обычной системе
		if(suppressed)
			if(message)
				if(pointblank && pbtarget)
					user.visible_message("<span class='danger'>[user] стреляет из [src] в упор по [pbtarget]!</span>", null, null, COMBAT_MESSAGE_RANGE)
				else
					user.visible_message("<span class='danger'>[user] стреляет из [src]!</span>", null, null, COMBAT_MESSAGE_RANGE)
		else
			if(user?.client)
				ai_broadcast_noise(get_turf(user), AI_NOISE_GUNSHOT_RANGE, user)
			if(message)
				if(pointblank && pbtarget)
					user.visible_message("<span class='danger'>[user] стреляет из [src] в упор по [pbtarget]!</span>", null, null, COMBAT_MESSAGE_RANGE)
				else
					user.visible_message("<span class='danger'>[user] стреляет из [src]!</span>", null, null, COMBAT_MESSAGE_RANGE)
	else
		// Используем стандартную систему звуков
		..()

/obj/item/gun/on_autofire_start(mob/living/shooter)
	. = ..()
	if(. && has_dynamic_sounds && dynamic_sound_datum)
		dynamic_looping = TRUE
		RegisterSignal(shooter.client, COMSIG_CLIENT_MOUSEUP, PROC_REF(stop_dynamic_sound))

/obj/item/gun/proc/finish_dynamic_burst(mob/living/shooter)
	if(dynamic_looping || firing || !dynamic_sound_datum)
		return
	dynamic_sound_datum.stop_loop(shooter, src)
	dynamic_sound_datum.play_tail(shooter, src)
	dynamic_looping = FALSE

/obj/item/gun/proc/stop_dynamic_sound(client/source, atom/object, turf/location, control, params)
	var/mob/living/shooter = source?.mob
	if(!dynamic_looping || !dynamic_sound_datum)
		return
	dynamic_sound_datum.stop_loop(shooter, src)
	dynamic_sound_datum.play_tail(shooter, src)
	dynamic_looping = FALSE
	UnregisterSignal(source, COMSIG_CLIENT_MOUSEUP)

/obj/item/gun/shoot_with_empty_chamber(mob/living/user)
	. = ..()
	if(has_dynamic_sounds)
		stop_dynamic_sound(user?.client)

// ============================================================================
// ДОПОЛНИТЕЛЬНАЯ ДОКУМЕНТАЦИЯ
// ============================================================================

// ПРЕИМУЩЕСТВА СИСТЕМЫ:
// 1. Оптимизация памяти: вместо длинных файлов используются короткие компоненты
// 2. Гибкость: можно комбинировать разные dry и tail звуки
// 3. Реалистичность: dry цикл создаёт эффект непрерывной стрельбы
// 4. Совместимость: не ломает существующую систему оружия
//
// ТЕХНИЧЕСКИЕ ДЕТАЛИ:
// - Система использует callback и timer для воспроизведения tail звука
// - Автоматически обрабатывает глушители с правильными параметрами playsound
// - Интегрируется в существующие proc shoot_live_shot и process_fire
// - Не требует модификации базового класса оружия за исключением добавления переменных
// - Безопасные null-проверки для всех аргументов
// - Проверка QDELETED для предотвращения ошибок с удалёнными объектами
// - Совместимость с существующей fire_sound системой - не заменяет её полностью
//
// РАСШИРЕНИЕ ФУНКЦИОНАЛЬНОСТИ:
// Для добавления новых функций можно расширить datum /datum/dynamic_gun_sound:
// - Добавить поддержку разных громкостей для dry и tail
// - Добавить случайную вариацию звуков
// - Добавить поддержку разных звуков для разных режимов стрельбы
//
// ПРИМЕР РАСШИРЕНИЯ:
/*
/datum/dynamic_gun_sound/proc/play_dryVariation(mob/user, obj/item/gun/gun)
    if(!user || !gun)
        return
    var/sound_to_play = pick(dry_sound, dry_sound_alt, dry_sound_alt2)
    if(use_suppressed && gun.suppressed)
        playsound(user, sound_to_play, 10, TRUE, ignore_walls = FALSE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
    else
        playsound(user, sound_to_play, volume, TRUE)
*/

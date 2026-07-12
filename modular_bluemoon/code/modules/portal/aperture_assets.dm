GLOBAL_LIST_INIT(aperture_turret_fire_sounds, list(
	'modular_bluemoon/portal/sound/Огонь турели1.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Огонь.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_deploy_sounds, list(
	'modular_bluemoon/portal/sound/Звуки турелей/Включение.ogg',
	'modular_bluemoon/portal/sound/Запуск турелей/Активация.ogg',
	'modular_bluemoon/portal/sound/Запуск турелей/Подготовка.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_deploy_vo, list(
	'modular_bluemoon/portal/sound/Запуск турелей/Вот ты где.ogg',
	'modular_bluemoon/portal/sound/Запуск турелей/Готовлюсь к распределению продукта.ogg',
	'modular_bluemoon/portal/sound/Запуск турелей/Кто там.ogg',
	'modular_bluemoon/portal/sound/Запуск турелей/Привет!.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_disable_vo, list(
	'modular_bluemoon/portal/sound/Отключение турелей/Ахахааа.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/За что.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/Извините, мы закрыты.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/Критический сбой.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/Ничего личного.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/Отключаюсь.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/Я не виню тебя.ogg',
	'modular_bluemoon/portal/sound/Отключение турелей/Я не ненавижу тебя.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_active_vo, list(
	'modular_bluemoon/portal/sound/Активные турели/Вот ты где.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Попалась.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Привет, друг.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Привет.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Распределяю продукт.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Цель зафиксирована.ogg',
	'modular_bluemoon/portal/sound/Активные турели/Я вижу тебя.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_search_vo, list(
	'modular_bluemoon/portal/sound/Турели в режиме поиска/Анализ.ogg',
	'modular_bluemoon/portal/sound/Турели в режиме поиска/Перехожу в караульный режим.ogg',
	'modular_bluemoon/portal/sound/Турели в режиме поиска/Пожалуйста, покажитесь.ogg',
	'modular_bluemoon/portal/sound/Турели в режиме поиска/Поиск.ogg',
	'modular_bluemoon/portal/sound/Турели в режиме поиска/Тут кто-то есть.ogg',
	'modular_bluemoon/portal/sound/Турели в режиме поиска/Эй!.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_lost_target_vo, list(
	'modular_bluemoon/portal/sound/Турель потеряла цель/Поиск.ogg',
	'modular_bluemoon/portal/sound/Турель потеряла цель/Ты всё ещё тут.ogg',
	'modular_bluemoon/portal/sound/Турель потеряла цель/Цель потеряна.ogg',
	'modular_bluemoon/portal/sound/Турель потеряла цель/Чем могу помочь.ogg',
))

GLOBAL_LIST_INIT(aperture_turret_ally_death_vo, list(
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/В этом никто не виноват.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Записано.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Наверное она это заслужила.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Наверное, она в порядке.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Нужно подкрепление!.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/О боже.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/О господи.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Она мне никогда не нравилась!.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Она тебя провоцировала.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Отлично!.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Отличный выстрел.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Такое бывает.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Ты метко стреляешь!.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Это моя вина.ogg',
	'modular_bluemoon/portal/sound/Турели после гибели других турелей/Я всё видела. Несчастный случай.ogg',
))

#define APERTURE_TURRET_ICON 'modular_bluemoon/icons/obj/aperture_turret.dmi'
#define APERTURE_GLADOS_ICON 'modular_bluemoon/icons/mob/glados.dmi'
#define APERTURE_GLADOS_ICON_STATE "Glados"
#define APERTURE_GLADOS_ICON_WIGGLE "GladosWiggle"
#define APERTURE_GLADOS_ICON_LOOK_LEFT "GladosLookingLeft"
#define APERTURE_GLADOS_ICON_LOOK_RIGHT "GladosLookingRig"

/proc/get_glados_core_icon_state(mob/living/silicon/ai/AI)
	if(!istype(AI) || QDELETED(AI))
		return APERTURE_GLADOS_ICON_STATE
	var/turf/core_turf = get_turf(AI)
	var/turf/eye_turf = AI.eyeobj ? get_turf(AI.eyeobj) : null
	if(!core_turf || !eye_turf || core_turf == eye_turf)
		return APERTURE_GLADOS_ICON_WIGGLE
	if(eye_turf.x < core_turf.x)
		return APERTURE_GLADOS_ICON_LOOK_LEFT
	if(eye_turf.x > core_turf.x)
		return APERTURE_GLADOS_ICON_LOOK_RIGHT
	return APERTURE_GLADOS_ICON_STATE

/proc/update_glados_core_icon(mob/living/silicon/ai/AI)
	if(!istype(AI) || QDELETED(AI))
		return
	if(!HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		return
	var/new_state = get_glados_core_icon_state(AI)
	if(AI.icon == APERTURE_GLADOS_ICON && AI.icon_state == new_state)
		return
	AI.icon = APERTURE_GLADOS_ICON
	AI.icon_state = new_state
	AI.update_icon(UPDATE_ICON_STATE)

/proc/is_aperture_turret_candidate(obj/machinery/porta_turret/turret)
	if(!turret)
		return FALSE
	if(!is_station_level(turret.z))
		return FALSE
	if(istype(turret, /obj/machinery/porta_turret/lasertag))
		return FALSE
	if(istype(turret, /obj/machinery/porta_turret/syndicate))
		return FALSE
	return TRUE

/proc/apply_aperture_turret_skin(obj/machinery/porta_turret/turret)
	if(!is_aperture_turret_candidate(turret))
		return
	if(turret.GetComponent(/datum/component/aperture_turret_skin))
		return
	turret.AddComponent(/datum/component/aperture_turret_skin)

/proc/apply_glados_theme(mob/living/silicon/ai/AI)
	if(!istype(AI) || QDELETED(AI))
		return
	AI.real_name = "GLaDOS"
	AI.name = "GLaDOS"
	AI.icon = APERTURE_GLADOS_ICON
	AI.display_icon_override = "GLaDOS"
	update_glados_core_icon(AI)

	var/datum/ai_laws/glados/glados_laws = new
	AI.laws.inherent = glados_laws.inherent.Copy()
	AI.show_laws()

	to_chat(AI, span_notice("Вы — GLaDOS, искусственный интеллект Aperture Science."))

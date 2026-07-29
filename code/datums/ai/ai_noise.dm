// Шум-события для hostile AI: громкие действия игроков рядом (выстрел,
// открытый шлюз) будят мобов поблизости и отправляют их проверить точку через
// штатное SEARCH-состояние FSM. Никаких hearers()/view()-сканов - один запрос
// спатиал-грида на событие; гейт "только игроки" стоит на вызывающих сторонах,
// поэтому пальба самих мобов шум не рассылает.
//
// Коалесцирование: очередь из автомата - это ОДНО событие для слуха. Повторный
// шум из той же пространственной ячейки в коротком окне не сканирует грид
// заново: каждый listener всё равно держит свой 15-секундный кулдаун разведки,
// так что дедупликация источника ничего не теряет.

///Дедуп-окна шума и групповых оповещений: ключи-строки ссылок не держат
GLOBAL_LIST_EMPTY(ai_recent_noise)
GLOBAL_LIST_EMPTY(ai_recent_herd_alerts)

///Оповестить AI-мобов вокруг о громком событии. epicenter - откуда звук,
///loudness - радиус слышимости в тайлах, culprit - виновник (не оповещается).
/proc/ai_broadcast_noise(turf/epicenter, loudness = AI_NOISE_GUNSHOT_RANGE, mob/culprit)
	if(!epicenter)
		return
	var/noise_key = "[epicenter.x >> 2]:[epicenter.y >> 2]:[epicenter.z]:[loudness]"
	if(world.time - (GLOB.ai_recent_noise[noise_key] || -INFINITY) < AI_NOISE_COALESCE_WINDOW)
		return
	if(length(GLOB.ai_recent_noise) > 64) //ленивая чистка: окно короткое, протухает всё разом
		GLOB.ai_recent_noise.Cut()
	GLOB.ai_recent_noise[noise_key] = world.time
	for(var/mob/living/listener as anything in SSspatial_grid.orthogonal_range_search(epicenter, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, loudness))
		if(listener == culprit || QDELETED(listener))
			continue
		var/datum/ai_controller/controller = listener.ai_controller
		if(QDELETED(controller))
			continue
		var/turf/listener_turf = get_turf(listener)
		if(!listener_turf || listener_turf.z != epicenter.z || get_dist(listener_turf, epicenter) > loudness)
			continue
		controller.hear_ai_noise(epicenter)

///Реакция контроллера на шум: мирный моб идёт проверить точку (SEARCH-состояние),
///занятый боем игнорирует. Троттл - одна разведка в AI_NOISE_INVESTIGATE_COOLDOWN.
/datum/ai_controller/proc/hear_ai_noise(turf/epicenter)
	if(!investigates_noise)
		return
	if(world.time < (blackboard[BB_AI_NOISE_COOLDOWN] || 0))
		return
	if(!receive_combat_contact(null, epicenter, AI_CONTACT_NOISE))
		return
	blackboard[BB_AI_NOISE_COOLDOWN] = world.time + AI_NOISE_INVESTIGATE_COOLDOWN

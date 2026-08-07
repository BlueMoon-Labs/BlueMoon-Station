#define UPDATE_BUFFER 15 // 1.5 seconds

// CAMERA CHUNK
//
// A 16x16 grid of the map with a list of turfs that can be seen, are visible and are dimmed.
// Allows the AI Eye to stream these chunks and know what it can and cannot see.

/datum/camerachunk
	/// Турфы чанка, которые не видит ни одна камера: турф -> образ статики.
	/// Образ привязан к самому турфу, но показывается только через client.images
	/// тому, кто смотрит через камерную сеть. Раньше вместо образов в vis_contents
	/// каждого скрытого турфа лежала пара движимых объектов, и SendMaps обходил их
	/// для КАЖДОГО клиента на карте, а не только для ИИ.
	var/list/obscuredTurfs = list()
	/// Те же турфы со вторым набором образов - прозрачным для мыши. Нужен
	/// наблюдателям с USE_STATIC_TRANSPARENT (детектор ИИ в мультитуле): статику
	/// там видит живой человек, которому нельзя блокировать клики по миру.
	/// Строится лениво, до первого такого наблюдателя тут null.
	var/list/obscured_turfs_transparent
	/// Плоский список образов скрытых турфов - целиком уезжает в client.images
	var/list/active_static_images = list()
	/// То же для прозрачного набора; null, пока набор не построен
	var/list/active_static_images_transparent
	var/list/visibleTurfs = list()
	var/list/cameras = list()
	var/list/turfs = list()
	var/list/seenby = list()
	var/changed = 0
	var/x = 0
	var/y = 0
	var/z = 0

// Add an AI eye to the chunk, then update if changed.

/datum/camerachunk/proc/add(mob/camera/aiEye/eye)
	//обновляемся ДО подписки: пока глаз не в seenby, апдейт не тронет его образы,
	//и статику он получит ровно один раз - уже итоговую
	if(changed)
		update()
	eye.visibleCameraChunks += src
	seenby += eye
	eye.give_camera_static(src)

// Remove an AI eye from the chunk.

/datum/camerachunk/proc/remove(mob/camera/aiEye/eye)
	//именно присваивание нового списка, а не "-=": часть вызывающих (снятие
	//управления с камерной консоли) перебирает visibleCameraChunks и снимает
	//чанки прямо в цикле по нему, а правка списка внутри for() пропускает
	//каждый второй элемент и оставляет образы висеть у клиента навсегда
	eye.visibleCameraChunks = eye.visibleCameraChunks - src
	seenby -= eye
	//у ИИ несколько глаз (мультикам) на одном клиенте: если в чанк смотрит
	//другой его глаз, образы клиенту всё ещё нужны
	if(still_seen_by_same_client(eye))
		return
	eye.take_camera_static(src)

/// Смотрит ли в чанк другой глаз того же клиента с тем же режимом статики.
/datum/camerachunk/proc/still_seen_by_same_client(mob/camera/aiEye/leaving_eye)
	var/client/viewer = leaving_eye.GetViewerClient()
	if(!viewer)
		return FALSE
	for(var/mob/camera/aiEye/other_eye as anything in seenby)
		if(other_eye.use_static == leaving_eye.use_static && other_eye.GetViewerClient() == viewer)
			return TRUE
	return FALSE

/// Набор образов статики для наблюдателя с таким режимом. Прозрачный набор
/// строится по требованию: он нужен только детектору ИИ.
/datum/camerachunk/proc/static_images_for(use_static, build_missing = TRUE)
	if(use_static != USE_STATIC_TRANSPARENT)
		return active_static_images
	if(isnull(active_static_images_transparent) && build_missing)
		build_transparent_static()
	return active_static_images_transparent

/// Собрать прозрачный для мыши набор образов по уже известным скрытым турфам.
/datum/camerachunk/proc/build_transparent_static()
	obscured_turfs_transparent = list()
	active_static_images_transparent = list()
	for(var/turf/hidden_turf as anything in obscuredTurfs)
		var/image/transparent_image = GLOB.cameranet.make_static_image(hidden_turf, USE_STATIC_TRANSPARENT)
		obscured_turfs_transparent[hidden_turf] = transparent_image
		active_static_images_transparent += transparent_image

/// Турф перестал просматриваться камерами - завести на него образы статики.
/datum/camerachunk/proc/hide_turf(turf/hidden_turf)
	if(obscuredTurfs[hidden_turf] || istype(hidden_turf, /turf/open/ai_visible))
		return
	var/image/static_image = GLOB.cameranet.make_static_image(hidden_turf)
	obscuredTurfs[hidden_turf] = static_image
	active_static_images += static_image
	if(isnull(obscured_turfs_transparent))
		return
	var/image/transparent_image = GLOB.cameranet.make_static_image(hidden_turf, USE_STATIC_TRANSPARENT)
	obscured_turfs_transparent[hidden_turf] = transparent_image
	active_static_images_transparent += transparent_image

/// Турф снова под камерой - снять с него образы статики.
/datum/camerachunk/proc/reveal_turf(turf/shown_turf)
	var/image/static_image = obscuredTurfs[shown_turf]
	if(static_image)
		obscuredTurfs -= shown_turf
		active_static_images -= static_image
	if(isnull(obscured_turfs_transparent))
		return
	var/image/transparent_image = obscured_turfs_transparent[shown_turf]
	if(!transparent_image)
		return
	obscured_turfs_transparent -= shown_turf
	active_static_images_transparent -= transparent_image

/// Перевесить образы статики на турф: он мог быть только что пересоздан
/// (ChangeTurf), и без этого в статике осталась бы дырка.
/datum/camerachunk/proc/reattach_static(turf/changed_turf)
	var/image/static_image = obscuredTurfs[changed_turf]
	if(static_image)
		static_image.loc = changed_turf
	if(isnull(obscured_turfs_transparent))
		return
	var/image/transparent_image = obscured_turfs_transparent[changed_turf]
	if(transparent_image)
		transparent_image.loc = changed_turf

/// Забрать образы у всех наблюдателей: списки образов сейчас изменятся.
/datum/camerachunk/proc/take_static_from_watchers()
	for(var/mob/camera/aiEye/eye as anything in seenby)
		eye.take_camera_static(src)

/// Вернуть наблюдателям уже обновлённые образы.
/datum/camerachunk/proc/give_static_to_watchers()
	for(var/mob/camera/aiEye/eye as anything in seenby)
		eye.give_camera_static(src)

// Called when a chunk has changed. I.E: A wall was deleted.

/datum/camerachunk/proc/visibilityChanged(turf/loc)
	if(!visibleTurfs[loc])
		return
	hasChanged()

// Updates the chunk, makes sure that it doesn't update too much. If the chunk isn't being watched it will
// instead be flagged to update the next time an AI Eye moves near it.

/datum/camerachunk/proc/hasChanged(update_now = 0)
	if(seenby.len || update_now)
		addtimer(CALLBACK(src, PROC_REF(update)), UPDATE_BUFFER, TIMER_UNIQUE)
	else
		changed = 1

// The actual updating. It gathers the visible turfs from cameras and puts them into the appropiate lists.

/datum/camerachunk/proc/update()
	var/list/newVisibleTurfs = list()

	for(var/camera in cameras)
		var/obj/machinery/camera/c = camera

		if(!c)
			continue

		if(!c.can_use())
			continue

		var/turf/point = locate(src.x + (CHUNK_SIZE / 2), src.y + (CHUNK_SIZE / 2), src.z)
		if(get_dist(point, c) > CHUNK_SIZE + (CHUNK_SIZE / 2))
			continue

		for(var/turf/t as anything in c.get_visible_turfs())
			// Possible optimization: if(turfs[t]) here, rather than &= turfs afterwards.
			// List associations use a tree or hashmap of some sort (alongside the list itself)
			//  so are surprisingly fast. (significantly faster than var/thingy/x in list, in testing)
			newVisibleTurfs[t] = t

	// Removes turf that isn't in turfs.
	newVisibleTurfs &= turfs

	var/list/visAdded = newVisibleTurfs - visibleTurfs
	var/list/visRemoved = visibleTurfs - newVisibleTurfs

	visibleTurfs = newVisibleTurfs
	changed = 0

	if(!length(visAdded) && !length(visRemoved))
		return

	//пока наборы образов перестраиваются, у наблюдателей их быть не должно
	take_static_from_watchers()

	for(var/turf/shown_turf as anything in visAdded)
		reveal_turf(shown_turf)

	for(var/turf/hidden_turf as anything in visRemoved)
		hide_turf(hidden_turf)

	give_static_to_watchers()

// Create a new camera chunk, since the chunks are made as they are needed.

/datum/camerachunk/New(x, y, z)
	x &= ~(CHUNK_SIZE - 1)
	y &= ~(CHUNK_SIZE - 1)

	src.x = x
	src.y = y
	src.z = z

	for(var/obj/machinery/camera/c in urange(CHUNK_SIZE, locate(x + (CHUNK_SIZE / 2), y + (CHUNK_SIZE / 2), z)))
		if(c.can_use())
			cameras += c

	for(var/turf/t in block(locate(max(x, 1), max(y, 1), z), locate(min(x + CHUNK_SIZE - 1, world.maxx), min(y + CHUNK_SIZE - 1, world.maxy), z)))
		turfs[t] = t

	for(var/camera in cameras)
		var/obj/machinery/camera/c = camera
		if(!c)
			continue

		if(!c.can_use())
			continue

		for(var/turf/t as anything in c.get_visible_turfs())
			// Possible optimization: if(turfs[t]) here, rather than &= turfs afterwards.
			// List associations use a tree or hashmap of some sort (alongside the list itself)
			//  so are surprisingly fast. (significantly faster than var/thingy/x in list, in testing)
			visibleTurfs[t] = t

	// Removes turf that isn't in turfs.
	visibleTurfs &= turfs

	for(var/turf/hidden_turf as anything in turfs - visibleTurfs)
		hide_turf(hidden_turf)

/datum/camerachunk/Destroy()
	//образы обязаны уйти из client.images вместе с чанком, иначе клиент до конца
	//сессии таскает статику на турфах, которых уже никто не считает скрытыми
	for(var/mob/camera/aiEye/eye as anything in seenby)
		eye.visibleCameraChunks = eye.visibleCameraChunks - src
		eye.take_camera_static(src)
	seenby.Cut()
	obscuredTurfs.Cut()
	active_static_images.Cut()
	obscured_turfs_transparent = null
	active_static_images_transparent = null
	visibleTurfs.Cut()
	turfs.Cut()
	cameras.Cut()
	return ..()

#undef UPDATE_BUFFER
#undef CHUNK_SIZE

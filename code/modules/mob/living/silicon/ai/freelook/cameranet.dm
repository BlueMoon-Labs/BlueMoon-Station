// CAMERA NET
//
// The datum containing all the chunks.

#define CHUNK_SIZE 16 // Only chunk sizes that are to the power of 2. E.g: 2, 4, 8, 16, etc..

GLOBAL_DATUM_INIT(cameranet, /datum/cameranet, new)

/datum/cameranet
	var/name = "Camera Net" // Name to show for VV and stat()

	// The cameras on the map, no matter if they work or not. Updated in obj/machinery/camera.dm by New() and Del().
	var/list/cameras = list()
	// The chunks of the map, mapping the areas that the cameras can see.
	var/list/chunks = list()
	var/ready = 0

	/// Ленивый кэш "имя сети -> ассоц c_tag -> камера": консоли/баг/SecurEye
	/// раньше пересобирали и перефильтровывали ВЕСЬ cameras на каждый
	/// ui_static_data и каждый клик переключения камеры. null = кэш сброшен,
	/// пересоберётся при следующем запросе (см. invalidate_camera_cache).
	var/list/camera_lookup_by_network
	/// world.time сборки кэша: c_tag/network мутируют в десятках мест
	/// (переименование боргов и т.п.), все не перехватить - TTL страхует
	var/camera_lookup_built_at = -1

	// The object used for the clickable stat() button.
	var/obj/effect/statclick/statclick

	/// Шаблон образа камерной статики: клонируется на каждый скрытый от камер
	/// турф, копия уезжает в client.images только тому, кто смотрит через
	/// камерную сеть. Раньше статика жила в vis_contents самого турфа - два
	/// движимых объекта на каждом непросматриваемом турфе, которые SendMaps
	/// обходил для КАЖДОГО клиента на карте, а не только для ИИ.
	var/image/static_template
	/// То же, но прозрачный для мыши. Достаётся наблюдателям с
	/// USE_STATIC_TRANSPARENT (детектор ИИ в мультитуле): там статику видит
	/// живой человек, и блокировать ему клики по миру нельзя.
	var/image/static_template_transparent

/datum/cameranet/New()
	static_template = new /image('icons/effects/cameravis.dmi')
	static_template.layer = CAMERA_STATIC_LAYER
	static_template.plane = CAMERA_STATIC_PLANE
	// RESET_* обязательны: образ висит на настоящем турфе и без них унаследовал
	// бы его цвет, прозрачность и трансформацию (раньше он висел на нейтральном
	// объекте-подложке, которому наследовать было нечего)
	static_template.appearance_flags = RESET_TRANSFORM | RESET_ALPHA | RESET_COLOR | KEEP_APART | TILE_BOUND
	static_template.mouse_opacity = MOUSE_OPACITY_ICON

	static_template_transparent = new /image(static_template)
	static_template_transparent.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Создать образ статики, привязанный к скрытому турфу.
/datum/cameranet/proc/make_static_image(turf/target, use_static = USE_STATIC_OPAQUE)
	var/image/static_image = new(use_static == USE_STATIC_TRANSPARENT ? static_template_transparent : static_template)
	static_image.loc = target
	return static_image

/// Сбросить кэш сетей камер. Зовётся из хуков жизненного цикла камеры:
/// Initialize/Destroy, EMP (сеть обнуляется и восстанавливается),
/// connect_to_shuttle (переименование сети), сборка камеры (network+c_tag).
/datum/cameranet/proc/invalidate_camera_cache()
	camera_lookup_by_network = null

/// Ассоц-список "c_tag -> камера" для сети network_name (null, если сеть пуста).
/// Списки в кэше общие - вызывающим их мутировать нельзя.
/datum/cameranet/proc/get_cameras_by_network(network_name)
	if(isnull(camera_lookup_by_network) || world.time - camera_lookup_built_at > 30 SECONDS)
		build_camera_lookup()
	return camera_lookup_by_network[network_name]

/datum/cameranet/proc/build_camera_lookup()
	camera_lookup_by_network = list()
	camera_lookup_built_at = world.time
	for(var/obj/machinery/camera/C as anything in cameras)
		if(!C.network)
			stack_trace("Camera in a cameranet has no camera network")
			continue
		if(!islist(C.network))
			stack_trace("Camera in a cameranet has a non-list camera network")
			continue
		for(var/network_name in C.network)
			var/list/network_cameras = camera_lookup_by_network[network_name]
			if(!network_cameras)
				network_cameras = list()
				camera_lookup_by_network[network_name] = network_cameras
			network_cameras["[C.c_tag]"] = C

// Checks if a chunk has been Generated in x, y, z.
/datum/cameranet/proc/chunkGenerated(x, y, z)
	x &= ~(CHUNK_SIZE - 1)
	y &= ~(CHUNK_SIZE - 1)
	return chunks["[x],[y],[z]"]

// Returns the chunk in the x, y, z.
// If there is no chunk, it creates a new chunk and returns that.
/datum/cameranet/proc/getCameraChunk(x, y, z)
	x &= ~(CHUNK_SIZE - 1)
	y &= ~(CHUNK_SIZE - 1)
	var/key = "[x],[y],[z]"
	. = chunks[key]
	if(!.)
		chunks[key] = . = new /datum/camerachunk(x, y, z)

// Updates what the aiEye can see. It is recommended you use this when the aiEye moves or it's location is set.

/// C, other_eyes и use_static остались ради вызывающих: статику теперь выдаёт
/// каждый чанк сам, персонально глазу, а режим статики глаз знает про себя сам.
/datum/cameranet/proc/visibility(list/moved_eyes, client/C, list/other_eyes, use_static = USE_STATIC_OPAQUE)
	if(!islist(moved_eyes))
		moved_eyes = moved_eyes ? list(moved_eyes) : list()

	for(var/mob/camera/aiEye/eye as anything in moved_eyes)
		//смотрящий мог смениться (реконнект ИИ, новый пользователь консоли):
		//чанки в visibleCameraChunks остались, а images нового клиента пусты
		eye.sync_camera_static()

		var/list/visibleChunks = list()
		if(eye.loc)
			// 0xf = 15
			var/static_range = eye.static_visibility_range
			var/x1 = max(0, eye.x - static_range) & ~(CHUNK_SIZE - 1)
			var/y1 = max(0, eye.y - static_range) & ~(CHUNK_SIZE - 1)
			var/x2 = min(world.maxx, eye.x + static_range) & ~(CHUNK_SIZE - 1)
			var/y2 = min(world.maxy, eye.y + static_range) & ~(CHUNK_SIZE - 1)


			for(var/x = x1; x <= x2; x += CHUNK_SIZE)
				for(var/y = y1; y <= y2; y += CHUNK_SIZE)
					visibleChunks |= getCameraChunk(x, y, eye.z)

		var/list/remove = eye.visibleCameraChunks - visibleChunks
		var/list/add = visibleChunks - eye.visibleCameraChunks

		for(var/datum/camerachunk/chunk as anything in remove)
			chunk.remove(eye)

		for(var/datum/camerachunk/chunk as anything in add)
			chunk.add(eye)

// Updates the chunks that the turf is located in. Use this when obstacles are destroyed or	when doors open.

/datum/cameranet/proc/updateVisibility(atom/A, opacity_check = 1)
	if(!SSticker || (opacity_check && !A.opacity))
		return
	majorChunkChange(A, 2)

/datum/cameranet/proc/updateChunk(x, y, z)
	var/datum/camerachunk/chunk = chunkGenerated(x, y, z)
	if (!chunk)
		return
	chunk.hasChanged()

// Removes a camera from a chunk.

/datum/cameranet/proc/removeCamera(obj/machinery/camera/c)
	majorChunkChange(c, 0)

// Add a camera to a chunk.

/datum/cameranet/proc/addCamera(obj/machinery/camera/c)
	if(c.can_use())
		majorChunkChange(c, 1)

// Used for Cyborg cameras. Since portable cameras can be in ANY chunk.

/datum/cameranet/proc/updatePortableCamera(obj/machinery/camera/c)
	if(c.can_use())
		majorChunkChange(c, 1)

// Never access this proc directly!!!!
// This will update the chunk and all the surrounding chunks.
// It will also add the atom to the cameras list if you set the choice to 1.
// Setting the choice to 0 will remove the camera from the chunks.
// If you want to update the chunks around an object, without adding/removing a camera, use choice 2.

/datum/cameranet/proc/majorChunkChange(atom/c, choice)
	if(!c)
		return

	var/turf/T = get_turf(c)
	if(T)
		//камера добавилась/убралась/переключилась - её собственный кэш видимости протух
		if(choice != 2 && istype(c, /obj/machinery/camera))
			var/obj/machinery/camera/changed_camera = c
			changed_camera.mark_visibility_dirty()

		var/x1 = max(0, T.x - (CHUNK_SIZE / 2)) & ~(CHUNK_SIZE - 1)
		var/y1 = max(0, T.y - (CHUNK_SIZE / 2)) & ~(CHUNK_SIZE - 1)
		var/x2 = min(world.maxx, T.x + (CHUNK_SIZE / 2)) & ~(CHUNK_SIZE - 1)
		var/y2 = min(world.maxy, T.y + (CHUNK_SIZE / 2)) & ~(CHUNK_SIZE - 1)
		for(var/x = x1; x <= x2; x += CHUNK_SIZE)
			for(var/y = y1; y <= y2; y += CHUNK_SIZE)
				var/datum/camerachunk/chunk = chunkGenerated(x, y, T.z)
				if(chunk)
					if(choice == 0)
						// Remove the camera.
						chunk.cameras -= c
					else if(choice == 1)
						// You can't have the same camera in the list twice.
						chunk.cameras |= c
					else
						//изменение видимости в точке T (дверь/стена/непрозрачный объект):
						//протухают только камеры, чью зону оно могло задеть - остальные
						//переживут апдейт чанка на кэше
						for(var/obj/machinery/camera/chunk_camera as anything in chunk.cameras)
							if(chunk_camera && get_dist(chunk_camera, T) <= chunk_camera.view_range)
								chunk_camera.mark_visibility_dirty()
					chunk.hasChanged()

// Will check if a mob is on a viewable turf. Returns 1 if it is, otherwise returns 0.

/datum/cameranet/proc/checkCameraVis(mob/living/target)
	var/turf/position = get_turf(target)
	return checkTurfVis(position)


/datum/cameranet/proc/checkTurfVis(turf/position)
	var/datum/camerachunk/chunk = chunkGenerated(position.x, position.y, position.z)
	if(chunk)
		if(chunk.changed)
			chunk.hasChanged(1) // Update now, no matter if it's visible or not.
		if(chunk.visibleTurfs[position])
			return TRUE
	return FALSE

/datum/cameranet/proc/stat_entry()
	if(!statclick)
		statclick = new/obj/effect/statclick/debug(null, "Initializing...", src)

	stat(name, statclick.update("Cameras: [GLOB.cameranet.cameras.len] | Chunks: [GLOB.cameranet.chunks.len]"))

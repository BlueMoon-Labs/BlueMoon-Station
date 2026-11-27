/*
 * Photo album
 */
/obj/item/storage/photo_album
	name = "photo album"
	desc = "A big book used to store photos and mementos."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "album"
	item_state = "album"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	resistance_flags = FLAMMABLE
	w_class = WEIGHT_CLASS_SMALL
	var/persistence_id

/obj/item/storage/photo_album/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.can_hold = typecacheof(list(/obj/item/photo))
	STR.max_combined_w_class = 42
	STR.max_items = 21
	LAZYADD(SSpersistence.photo_albums, src)

/obj/item/storage/photo_album/Destroy()
	LAZYREMOVE(SSpersistence.photo_albums, src)
	return ..()

/obj/item/storage/photo_album/proc/get_picture_id_list()
	var/list/L = list()
	for(var/i in contents)
		if(istype(i, /obj/item/photo))
			L += i
	if(!L.len)
		return
	. = list()
	for(var/i in L)
		var/obj/item/photo/P = i
		if(!istype(P.picture))
			continue
		. |= P.picture.id

//Manual loading, DO NOT USE FOR HARDCODED/MAPPED IN ALBUMS. This is for if an album needs to be loaded mid-round from an ID.
/obj/item/storage/photo_album/proc/persistence_load()
	var/list/data = SSpersistence.GetPhotoAlbums()
	populate_from_id_list(data?[persistence_id])

/obj/item/storage/photo_album/proc/populate_from_id_list(list/ids)
	var/list/current_ids = get_picture_id_list()
	for(var/i in ids)
		if(i in current_ids)
			continue
		var/obj/item/photo/old/P = load_photo_from_disk(i)
		if(istype(P))
			if(!SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, P, null, TRUE, TRUE))
				qdel(P)

/obj/item/storage/photo_album/HoS
	name = "photo album (Head of Security)"
	persistence_id = "HoS"

/obj/item/storage/photo_album/RD
	name = "photo album (Research Director)"
	persistence_id = "RD"

/obj/item/storage/photo_album/HoP
	name = "photo album (Head of Personnel)"
	persistence_id = "HoP"

/obj/item/storage/photo_album/Captain
	name = "photo album (Captain)"
	persistence_id = "Captain"

/obj/item/storage/photo_album/CMO
	name = "photo album (Chief Medical Officer)"
	persistence_id = "CMO"

/obj/item/storage/photo_album/QM
	name = "photo album (Quartermaster)"
	persistence_id = "QM"

/obj/item/storage/photo_album/CE
	name = "photo album (Chief Engineer)"
	persistence_id = "CE"

/obj/item/storage/photo_album/syndicate
	name = "photo album (Syndicate)"
	icon_state = "album_red"
	persistence_id = "syndicate"

/obj/item/storage/photo_album/personal
	var/account_key
	var/save_path
	var/save_timer
	var/save_pending = FALSE
	var/preserve_backup = FALSE

/obj/item/storage/photo_album/personal/Entered(atom/movable/arrived, atom/old_loc)
	. = ..()
	if(istype(arrived, /obj/item/photo))
		queue_save()

/obj/item/storage/photo_album/personal/Exited(atom/movable/gone, atom/new_loc)
	. = ..()
	if(!QDELETED(src) && istype(gone, /obj/item/photo))
		queue_save()

/obj/item/storage/photo_album/personal/Destroy()
	if(account_key)
		save_contents()
		SSpersistence.personal_photo_albums -= account_key
	return ..()

/obj/item/storage/photo_album/personal/proc/load_for_account(player_key)
	var/owner_ckey = ckey(player_key)
	if(!owner_ckey)
		return
	var/datum/weakref/previous_ref = SSpersistence.personal_photo_albums[owner_ckey]
	var/obj/item/storage/photo_album/personal/previous = previous_ref?.resolve()
	if(previous)
		// Только последний выданный альбом сохраняет изменения. Сначала записываем содержимое предыдущего.
		if(!previous.save_contents())
			return

	var/path = personal_photo_album_path(owner_ckey)
	if(fexists(path) || fexists("[path].bak"))
		preserve_backup = !restore_contents(path)
		if(preserve_backup && !restore_contents("[path].bak"))
			return
	else
		populate_from_id_list(personal_photo_album_legacy_ids(owner_ckey, SSpersistence.GetPhotoAlbums()))

	if(previous)
		previous.account_key = null
		previous.save_path = null
	account_key = owner_ckey
	save_path = path
	SSpersistence.personal_photo_albums[account_key] = WEAKREF(src)
	if(!fexists(path) && length(contents))
		queue_save()

/proc/personal_photo_album_path(owner_ckey)
	return "data/player_saves/[owner_ckey[1]]/[owner_ckey]/photo_album.sav"

/proc/personal_photo_album_legacy_ids(owner_ckey, list/albums)
	var/list/ids = list()
	// В старом файле для одного аккаунта могли сохраниться разные варианты написания key.
	for(var/album_key in albums)
		if(findtext(album_key, "personal_", 1, 10) && ckey(copytext(album_key, 10)) == owner_ckey && islist(albums[album_key]))
			ids |= albums[album_key]
	return ids

/proc/read_personal_photo_album(path)
	if(!fexists(path))
		return null
	var/list/entries
	try
		var/savefile/archive = new(path)
		archive["photos"] >> entries
	catch(var/exception/error)
		stack_trace("Не удалось прочитать личный фотоальбом [path]: [error]")
		return null
	return entries

/obj/item/storage/photo_album/personal/proc/restore_contents(path)
	var/list/entries = read_personal_photo_album(path)
	if(!islist(entries))
		return FALSE
	for(var/list/entry as anything in entries)
		if(!islist(entry))
			continue
		var/list/picture_data = entry["picture"]
		var/source_image = entry["image"]
		var/picture_url = entry["url"]
		if(!islist(picture_data) || (!isicon(source_image) && !istext(picture_url)))
			continue
		var/datum/picture/restored = new
		restored.deserialize_metadata(picture_data)
		if(isicon(source_image))
			restored.picture_image = icon(source_image)
		restored.picture_url = picture_url
		var/obj/item/photo/restored_photo = new /obj/item/photo/old(null, restored)
		restored_photo.name = entry["name"]
		restored_photo.desc = entry["desc"]
		restored_photo.scribble = entry["scribble"]
		if(!SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, restored_photo, null, TRUE, TRUE))
			qdel(restored_photo)
	return TRUE

/obj/item/storage/photo_album/personal/proc/queue_save()
	if(!save_path)
		return
	save_pending = TRUE
	if(!save_timer)
		save_timer = addtimer(CALLBACK(src, PROC_REF(save_contents)), 1 SECONDS, TIMER_STOPPABLE)

/obj/item/storage/photo_album/personal/proc/save_contents()
	if(save_timer)
		deltimer(save_timer)
		save_timer = null
	if(!save_pending)
		return TRUE
	var/list/entries = list()
	for(var/obj/item/photo/photo in contents)
		var/datum/picture/picture = photo.picture
		if(!picture || (!picture.picture_image && !picture.picture_url))
			continue
		entries += list(list(
			"image" = picture.picture_image,
			"url" = picture.picture_url,
			"picture" = picture.serialize_list(),
			"name" = photo.name,
			"desc" = photo.desc,
			"scribble" = photo.scribble,
		))

	// Сначала записываем полный архив во временный файл, чтобы сбой записи не стирал предыдущий альбом.
	var/temp_path = "[save_path].tmp"
	fdel(temp_path)
	try
		var/savefile/archive = new(temp_path)
		archive["photos"] << entries
		archive.Flush()
	catch(var/exception/error)
		stack_trace("Не удалось записать личный фотоальбом [save_path]: [error]")
		fdel(temp_path)
		return FALSE
	if(!preserve_backup && fexists(save_path) && !fcopy(save_path, "[save_path].bak"))
		stack_trace("Не удалось создать резервную копию личного фотоальбома [save_path]")
		fdel(temp_path)
		return FALSE
	if(!fcopy(temp_path, save_path))
		preserve_backup = TRUE
		stack_trace("Не удалось обновить личный фотоальбом [save_path]")
		fdel(temp_path)
		return FALSE
	fdel(temp_path)
	preserve_backup = FALSE
	save_pending = FALSE
	return TRUE

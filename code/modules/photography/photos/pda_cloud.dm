#define PDA_PHOTO_THUMBNAIL_SIZE 96

/proc/pda_photo_thumbnail(icon/source)
	if(!source)
		return null
	var/icon/thumbnail = icon(source)
	var/width = thumbnail.Width()
	var/height = thumbnail.Height()
	var/scale = PDA_PHOTO_THUMBNAIL_SIZE / max(width, height)
	if(scale < 1)
		thumbnail.Scale(max(1, round(width * scale)), max(1, round(height * scale)))
	return icon2base64(thumbnail)

/proc/pda_photo_cloud_path(account_key)
	var/player_key = ckey(account_key)
	if(player_key)
		return "data/player_saves/[player_key[1]]/[player_key]/pda_photos/"

/proc/pda_photo_cloud_ids(directory, sort_ids = TRUE)
	var/static/regex/photo_file = regex("^(\[0-9a-f\]{8}-\[0-9a-f\]{4}-7\[0-9a-f\]{3}-\[0-9a-f\]{4}-\[0-9a-f\]{12}|000-album-\[0-9a-f\]{64})\\.sav(\\.bak)?$")
	var/list/ids = list()
	if(directory)
		for(var/filename in flist(directory))
			if(photo_file.Find(filename))
				ids[photo_file.group[1]] = TRUE
	if(sort_ids)
		sortTim(ids, GLOBAL_PROC_REF(cmp_text_dsc), associative = TRUE)
	return ids

/proc/read_pda_cloud_photo(path, with_image = FALSE)
	return read_pda_cloud_archive(path, with_image) || read_pda_cloud_archive("[path].bak", with_image)

/proc/read_pda_cloud_archive(path, with_image)
	if(!fexists(path))
		return null
	try
		var/savefile/archive = new(path)
		var/list/metadata
		archive["photo"] >> metadata
		if(!islist(metadata))
			return null
		var/image_data
		if(!with_image)
			var/thumbnail
			archive["thumbnail"] >> thumbnail
			if(!istext(thumbnail) || !length(thumbnail))
				// Старые сохранения содержат только полноразмерный снимок.
				archive["image"] >> image_data
				if(isicon(image_data))
					thumbnail = pda_photo_thumbnail(image_data)
			metadata["thumbnail"] = thumbnail
			return metadata
		archive["image"] >> image_data
		var/picture_url
		archive["url"] >> picture_url
		var/has_url = istext(picture_url) && length(picture_url)
		if(!isicon(image_data) && !has_url)
			return null
		var/datum/picture/picture = new
		picture.deserialize_metadata(metadata)
		if(isicon(image_data))
			picture.picture_image = icon(image_data)
		if(has_url)
			picture.picture_url = picture_url
		return picture
	catch(var/exception/error)
		stack_trace("Не удалось прочитать облачную фотографию [path]: [error]")
		return null

/proc/save_pda_cloud_photo(path, datum/picture/picture, thumbnail)
	var/temp_path = "[path].tmp"
	fdel(temp_path)
	try
		var/savefile/archive = new(temp_path)
		archive["photo"] << picture.serialize_list()
		archive["image"] << picture.picture_image
		archive["thumbnail"] << (thumbnail || pda_photo_thumbnail(picture.picture_image))
		if(picture.picture_url)
			archive["url"] << picture.picture_url
		archive.Flush()
	catch(var/exception/error)
		stack_trace("Не удалось записать облачную фотографию [path]: [error]")
		fdel(temp_path)
		return FALSE
	// Предыдущий снимок остаётся доступен, пока новый записывается во временный файл.
	var/saved = (!fexists(path) || fcopy(path, "[path].bak")) && fcopy(temp_path, path)
	fdel(temp_path)
	return saved

/proc/delete_pda_cloud_photo(path)
	var/backup = "[path].bak"
	return (!fexists(backup) || fdel(backup)) && (!fexists(path) || fdel(path))

/proc/migrate_personal_album_to_pda_cloud(account_key)
	var/owner_ckey = ckey(account_key)
	if(!owner_ckey)
		return TRUE
	var/directory = pda_photo_cloud_path(owner_ckey)
	var/album_path = personal_photo_album_path(owner_ckey)
	if(fexists(album_path) || fexists("[album_path].bak"))
		// Архив заменяет старый список. Удалённые из альбома снимки из списка восстанавливать нельзя.
		var/list/entries = read_personal_photo_album(album_path)
		if(!islist(entries))
			entries = read_personal_photo_album("[album_path].bak")
		if(!islist(entries))
			return FALSE
		var/list/occurrences = list()
		var/complete = TRUE
		for(var/list/entry as anything in entries)
			var/list/metadata = islist(entry) ? entry["picture"] : null
			if(!islist(metadata))
				complete = FALSE
				continue
			var/datum/picture/picture = new
			picture.deserialize_metadata(metadata)
			if(isicon(entry["image"]))
				picture.picture_image = entry["image"]
			if(istext(entry["url"]))
				picture.picture_url = entry["url"]
			if(istext(entry["name"]))
				picture.picture_name = entry["name"]
			if(istext(entry["desc"]))
				picture.picture_desc = entry["desc"]
			if("scribble" in entry)
				picture.caption = entry["scribble"]
			if(!import_pda_album_photo(directory, picture, occurrences))
				complete = FALSE
			qdel(picture)
		return complete

	var/list/legacy_albums = SSpersistence.GetPhotoAlbums()
	if(!islist(legacy_albums))
		return !fexists("data/photo_albums.json")
	return import_pda_legacy_album(directory, personal_photo_album_legacy_ids(owner_ckey, legacy_albums))

/proc/import_pda_legacy_album(directory, list/ids)
	var/list/occurrences = list()
	var/complete = TRUE
	for(var/id in ids)
		var/datum/picture/picture
		try
			picture = load_picture_from_disk(id)
		catch(var/exception/error)
			log_game("Не удалось прочитать старый снимок [id] для облака ПДА: [error]")
		if(!picture)
			complete = FALSE
			continue
		if(!import_pda_album_photo(directory, picture, occurrences))
			complete = FALSE
		qdel(picture)
	return complete

/proc/import_pda_album_photo(directory, datum/picture/picture, list/occurrences)
	var/has_image = isicon(picture.picture_image)
	if(!has_image && !(istext(picture.picture_url) && length(picture.picture_url)))
		return FALSE
	var/base64 = has_image ? picture.get_base64() : null
	if(has_image && !base64)
		return FALSE
	// Путь остаётся тем же при повторе переноса и различается для одинаковых отпечатков в альбоме.
	var/fingerprint = rustg_hash_string(RUSTG_HASH_SHA256, json_encode(list(picture.serialize_list(), picture.picture_url, base64)))
	var/occurrence = (occurrences[fingerprint] || 0) + 1
	occurrences[fingerprint] = occurrence
	var/id = rustg_hash_string(RUSTG_HASH_SHA256, "[fingerprint]/[occurrence]")
	var/path = "[directory]000-album-[id].sav"
	if(fexists(path) || fexists("[path].bak"))
		var/datum/picture/existing = read_pda_cloud_photo(path, TRUE)
		if(existing)
			qdel(existing)
			return TRUE
	return save_pda_cloud_photo(path, picture, null)

#undef PDA_PHOTO_THUMBNAIL_SIZE

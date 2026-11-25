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
	var/static/regex/photo_file = regex("^(\[0-9a-f\]{8}-\[0-9a-f\]{4}-7\[0-9a-f\]{3}-\[0-9a-f\]{4}-\[0-9a-f\]{12})\\.sav(\\.bak)?$")
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
		if(!isicon(image_data))
			return null
		var/datum/picture/picture = new
		picture.deserialize_metadata(metadata)
		picture.picture_image = icon(image_data)
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

#undef PDA_PHOTO_THUMBNAIL_SIZE

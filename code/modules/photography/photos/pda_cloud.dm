/proc/pda_photo_cloud_path(account_key)
	var/player_key = ckey(account_key)
	if(player_key)
		return "data/player_saves/[player_key[1]]/[player_key]/pda_photos/"

/proc/pda_photo_cloud_ids(directory)
	var/static/regex/photo_file = regex("^(\[0-9a-f\]{8}-\[0-9a-f\]{4}-7\[0-9a-f\]{3}-\[0-9a-f\]{4}-\[0-9a-f\]{12})\\.sav(\\.bak)?$")
	var/list/ids = list()
	if(directory)
		for(var/filename in flist(directory))
			if(photo_file.Find(filename))
				ids[photo_file.group[1]] = TRUE
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
		if(!with_image)
			return metadata
		var/image_data
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

/proc/save_pda_cloud_photo(path, datum/picture/picture)
	var/temp_path = "[path].tmp"
	fdel(temp_path)
	try
		var/savefile/archive = new(temp_path)
		archive["photo"] << picture.serialize_list()
		archive["image"] << picture.picture_image
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

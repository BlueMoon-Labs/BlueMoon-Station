/*
		name
		key
		description
		role
		comments
		ready = 0
*/

/datum/paiCandidate/proc/savefile_path(mob/user)
	return "data/player_saves/[user.ckey[1]]/[user.ckey]/pai.sav"

/datum/paiCandidate/proc/savefile_save(mob/user)
	if(IsGuestKey(user.key))
		return FALSE

	var/datum/player_save_json/storage = new /datum/player_save_json/account(savefile_path(user))
	var/savefile/F = storage.open()
	if(!F)
		to_chat(user, span_warning("Не удалось прочитать сохранение pAI. Исходные данные сохранены."))
		return FALSE
	var/version
	F["version"] >> version
	if(storage.exists() && version != 1)
		to_chat(user, span_warning("Версия сохранения pAI не поддерживается. Исходные данные сохранены."))
		return FALSE

	WRITE_FILE(F["name"], name)
	WRITE_FILE(F["description"], description)
	WRITE_FILE(F["comments"], comments)

	WRITE_FILE(F["version"], 1)

	if(!storage.commit(F))
		to_chat(user, span_warning("Не удалось записать сохранение pAI."))
		return FALSE
	return TRUE

// loads the savefile corresponding to the mob's ckey
// if silent=true, report incompatible savefiles
// returns 1 if loaded (or file was incompatible)
// returns 0 if savefile did not exist

/datum/paiCandidate/proc/savefile_load(mob/user, silent = TRUE)
	if (IsGuestKey(user.key))
		return FALSE

	var/path = savefile_path(user)

	var/datum/player_save_json/storage = new /datum/player_save_json/account(path)
	if (!storage.exists())
		return FALSE

	var/savefile/F = storage.open()

	if(!F)
		return //Not everyone has a pai savefile.

	var/version = null
	F["version"] >> version

	if (isnull(version) || version != 1)
		if (!silent)
			alert(user, "Версия сохранения pAI не поддерживается. Исходный файл сохранён.")
		return FALSE

	F["name"] >> src.name
	F["description"] >> src.description
	F["comments"] >> src.comments
	return TRUE

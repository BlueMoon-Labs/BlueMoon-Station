/datum/preferences/proc/bluemoon_character_pref_load(savefile/S) //TODO: modularize our other savefile edits... maybe?
	S["pda_style"] >> pda_style
	S["pda_color"] >> pda_color
	S["pda_skin"] >> pda_skin
	S["pda_ringtone"] >> pda_ringtone
	S["pda_theme"] >> pda_theme

	S["silicon_lawset"] >> silicon_lawset
	S["body_weight"] >> body_weight
	S["normalized_size"] >> features["normalized_size"]
	S["custom_laugh"] >> custom_laugh

	pda_style = sanitize_inlist(pda_style, GLOB.pda_styles, initial(pda_style))
	pda_color = sanitize_hexcolor(pda_color, 6, 1, initial(pda_color))
	pda_skin = sanitize_inlist(pda_skin, GLOB.pda_reskins, PDA_SKIN_ALT)
	pda_ringtone = sanitize_inlist(pda_ringtone, GLOB.pda_ringtone_list, "beep")
	var/list/valid_themes = list()
	for(var/theme_name in GLOB.pda_name_to_theme)
		valid_themes |= GLOB.pda_name_to_theme[theme_name]
	pda_theme = sanitize_inlist(pda_theme, valid_themes, PDA_THEME_NTOS)

	silicon_lawset = sanitize_inlist(silicon_lawset, CONFIG_GET(keyed_list/choosable_laws), null)
	body_weight = sanitize_inlist(body_weight, GLOB.mob_sizes, NAME_WEIGHT_NORMAL)
	features["normalized_size"] = sanitize_num_clamp(features["normalized_size"], 0.81, 1.2, 1)
	custom_laugh = sanitize_inlist(custom_laugh, GLOB.mob_laughs, "Default")

/datum/preferences/proc/bluemoon_character_pref_save(savefile/S) //TODO: modularize our other savefile edits... maybe?
	WRITE_FILE(S["pda_style"], pda_style)
	WRITE_FILE(S["pda_color"], pda_color)
	WRITE_FILE(S["pda_skin"], pda_skin)
	WRITE_FILE(S["pda_ringtone"], pda_ringtone)
	WRITE_FILE(S["pda_theme"], pda_theme)

	WRITE_FILE(S["silicon_lawset"], silicon_lawset)
	WRITE_FILE(S["body_weight"], body_weight)
	WRITE_FILE(S["normalized_size"], features["normalized_size"])
	WRITE_FILE(S["custom_laugh"], custom_laugh)

/obj/item/modular_computer/pda/proc/update_style(client/C)
	// pda_color, update_ringtone(), skin_data, pda_style, device_theme все передаются через update_pda_prefs()
	update_pda_prefs(C)

/datum/preferences
	var/list/favorite_tracks = list()

	//Ключем будет имя плейлиста, а значением, лист с треками. Пример:
	//playlists = list("Первый" = list("song1", song2), "Второй" = list("song2", "song3"))
	var/list/playlists = list()
	var/list/favorite_paintings_md5 = list()

// save_preferences / load_preferences для metadollar_minute_pool и пр. — в modular_sand (последний в цепочке),
// иначе lobby_preferences.dm перезаписывает этот proc и поля не сохранялись на диск.

/datum/preferences/update_preferences(current_version, savefile/S)
	if(current_version < 61)
		if(CHECK_BITFIELD(toggles, VERB_CONSENT))
			ENABLE_BITFIELD(toggles, RANGED_VERBS_CONSENT)
	if(current_version < 71)
		if(path && SSmetadollars)
			var/legacy_md = bm_read_metadollars_from_savefile_path(path)
			if(!legacy_md)
				legacy_md = bm_read_metadollars_from_savefile_path("[path].updatebac")
			if(legacy_md > 0)
				var/ck = bm_ckey_from_prefs_path(path)
				if(ck)
					SSmetadollars.import_legacy_balance(ck, legacy_md)
	if(current_version < 72)
		if(path && SSmetadollars)
			var/ck = bm_ckey_from_prefs_path(path)
			if(ck)
				SSmetadollars.reconcile_legacy_balance(ck)
	. = ..()

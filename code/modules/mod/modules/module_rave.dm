/obj/item/mod/module/visor/rave
	name = "MOD rave visor module"
	desc = "Развлекательный визор переливается цветами радуги и воспроизводит музыку только своему владельцу."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "rave_visor"
	complexity = 1
	var/datum/client_colour/mod_rave/rave_screen
	var/mob/living/carbon/human/rave_user
	var/datum/track/selection
	var/datum/track/fallback_track
	var/music_channel
	var/music_client_ref
	var/music_volume
	var/rave_number = 1
	var/static/list/rainbow_order = list(COLOR_RED, "#ff8000", COLOR_YELLOW, "#00ff00", "#0080ff", "#ff00ff")

/obj/item/mod/module/visor/rave/Destroy()
	clear_rave()
	selection = null
	QDEL_NULL(fallback_track)
	return ..()

/obj/item/mod/module/visor/rave/on_activation()
	if(!..())
		return FALSE
	rave_user = mod.wearer
	RegisterSignal(rave_user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	rave_screen = rave_user.add_client_colour(/datum/client_colour/mod_rave)
	update_color()
	start_music()
	return TRUE

/obj/item/mod/module/visor/rave/on_deactivation(display_message = TRUE, deleting = FALSE)
	clear_rave()
	return ..()

/obj/item/mod/module/visor/rave/on_unequip()
	clear_rave()

/obj/item/mod/module/visor/rave/proc/on_user_deleted()
	SIGNAL_HANDLER
	clear_rave()

/obj/item/mod/module/visor/rave/proc/clear_rave()
	stop_music()
	if(rave_user)
		UnregisterSignal(rave_user, COMSIG_PARENT_QDELETING)
		rave_user.client_colours -= rave_screen
		rave_user.update_client_colour()
	rave_user = null
	QDEL_NULL(rave_screen)

/obj/item/mod/module/visor/rave/proc/update_color()
	if(!rave_screen || !rave_user)
		return
	rave_screen.colour = rainbow_order[rave_number]
	rave_user.update_client_colour()
	rave_user.update_inv_back()

/obj/item/mod/module/visor/rave/on_active_process(delta_time)
	if(!rave_user)
		return
	rave_number = rave_number % length(rainbow_order) + 1
	update_color()
	if(music_channel && music_client_ref != REF(rave_user.client))
		stop_music()
	if(!SSjukeboxes.jukebox_sound_enabled(rave_user, TRUE) || !get_music_volume())
		stop_music()
	else if(!music_channel)
		start_music()
	else if(music_volume != get_music_volume())
		music_volume = get_music_volume()
		var/sound/update = sound(null, channel = music_channel, volume = music_volume)
		update.status = SOUND_UPDATE
		SEND_SOUND(rave_user, update)

/obj/item/mod/module/visor/rave/proc/get_music_tracks()
	if(length(SSjukeboxes.songs))
		return SSjukeboxes.songs
	if(!fallback_track)
		fallback_track = new("Tintin on the Moon", 'sound/ambience/title3.ogg')
	return list(fallback_track)

/obj/item/mod/module/visor/rave/proc/get_music_volume()
	return MOD_RAVE_VOLUME * (rave_user?.client?.prefs?.get_sound_volume("personal_jukeboxes") || 0) / JUKEBOX_MAX_VOLUME

/obj/item/mod/module/visor/rave/proc/start_music()
	if(!rave_user || music_channel || !SSjukeboxes.jukebox_sound_enabled(rave_user, TRUE) || !get_music_volume())
		return FALSE
	if(!selection)
		var/list/tracks = get_music_tracks()
		selection = tracks[1]
	if(!selection?.song_path)
		return FALSE
	music_channel = SSsounds.reserve_sound_channel(src)
	if(!music_channel)
		return FALSE
	music_client_ref = REF(rave_user.client)
	music_volume = get_music_volume()
	SEND_SOUND(rave_user, sound(selection.song_path, repeat = TRUE, channel = music_channel, volume = music_volume))
	return TRUE

/obj/item/mod/module/visor/rave/proc/stop_music()
	music_client_ref = null
	music_volume = null
	if(!music_channel)
		return
	if(rave_user)
		SEND_SOUND(rave_user, sound(null, channel = music_channel))
	SSsounds.free_sound_channel(music_channel)
	music_channel = null

/obj/item/mod/module/visor/rave/get_configuration()
	. = ..()
	var/list/songs = list()
	var/list/tracks = get_music_tracks()
	for(var/datum/track/song in tracks)
		songs += song.song_name
	if(!selection)
		selection = tracks[1]
	if(length(songs))
		.["selection"] = add_ui_configuration("Музыка", "list", selection?.song_name, songs)

/obj/item/mod/module/visor/rave/configure_edit(key, value)
	if(key != "selection" || active)
		return
	for(var/datum/track/song in get_music_tracks())
		if(song.song_name == value)
			selection = song
			return

/obj/item/mod/module/visor/rave/generate_worn_overlay()
	. = ..()
	if(!active || !check_required_modpart())
		return
	var/static/list/states = icon_states('icons/mob/clothing/modsuit/mod_visor_whitemoon.dmi')
	var/state = "[mod.get_helmet()?.get_visual_skin()]-helmet-visor"
	if(!(state in states))
		state = "standard-helmet-visor"
	var/mutable_appearance/visor = mutable_appearance('icons/mob/clothing/modsuit/mod_visor_whitemoon.dmi', state)
	visor.appearance_flags |= RESET_COLOR
	visor.color = rainbow_order[rave_number]
	. += visor

/datum/client_colour/mod_rave
	priority = 2

// /tg/ reverb disabled
/*
///Default override for echo
/sound
	echo = list(
		0, // Direct
		0, // DirectHF
		-10000, // Room, -10000 means no low frequency sound reverb
		-10000, // RoomHF, -10000 means no high frequency sound reverb
		0, // Obstruction
		0, // ObstructionLFRatio
		0, // Occlusion
		0.25, // OcclusionLFRatio
		1.5, // OcclusionRoomRatio
		1.0, // OcclusionDirectRatio
		0, // Exclusion
		1.0, // ExclusionLFRatio
		0, // OutsideVolumeHF
		0, // DopplerFactor
		0, // RolloffFactor
		0, // RoomRolloffFactor
		1.0, // AirAbsorptionFactor
		0, // Flags (1 = Auto Direct, 2 = Auto Room, 4 = Auto RoomHF)
	)
	environment = SOUND_ENVIRONMENT_NONE //Default to none so sounds without overrides dont get reverb
*/

/*! playsound

playsound is a proc used to play a 3D sound in a specific range. This uses SOUND_RANGE + extra_range to determine that.

source - Origin of sound
soundin - Either a file, or a string that can be used to get an SFX
vol - The volume of the sound, excluding falloff and pressure affection.
vary - bool that determines if the sound changes pitch every time it plays
extrarange - modifier for sound range. This gets added on top of SOUND_RANGE
falloff_exponent - Rate of falloff for the audio. Higher means quicker drop to low volume. Should generally be over 1 to indicate a quick dive to 0 rather than a slow dive.
frequency - playback speed of audio
channel - The channel the sound is played at
pressure_affected - Whether or not difference in pressure affects the sound (E.g. if you can hear in space)
ignore_walls - Whether or not the sound can pass through walls.
falloff_distance - Distance at which falloff begins. Sound is at peak volume (in regards to falloff) aslong as it is in this range.

*/

/proc/playsound(atom/source, soundin, vol as num, vary, extrarange as num, falloff_exponent = SOUND_FALLOFF_EXPONENT, frequency = null, channel = 0, pressure_affected = TRUE, ignore_walls = TRUE,
	falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE, envwet = -10000, envdry = 0, distance_multiplier = SOUND_DEFAULT_DISTANCE_MULTIPLIER, distance_multiplier_min_range = SOUND_DEFAULT_MULTIPLIER_EFFECT_RANGE)
	if(isarea(source))
		CRASH("playsound(): source is an area")

	var/turf/turf_source = get_turf(source)

	if (!turf_source)
		return

	//allocate a channel if necessary now so its the same for everyone
	channel = channel || SSsounds.random_available_channel()

	// Looping through the player list has the added bonus of working for mobs inside containers
	var/sound/S = sound(get_sfx(soundin))
	var/maxdistance = SOUND_RANGE + extrarange
	var/source_z = turf_source.z
	var/turf/above_turf = SSmapping.get_turf_above(turf_source)
	var/turf/below_turf = SSmapping.get_turf_below(turf_source)

	var/list/listeners
	// Extra listener lists to iterate separately when we can avoid Copy()
	var/list/extra_listeners_1
	var/list/extra_listeners_2

	if(!ignore_walls) //these sounds don't carry through walls
		listeners = SSmobs.clients_by_zlevel[source_z].Copy()
		listeners = listeners & hearers(maxdistance,turf_source)

		if(above_turf && istransparentturf(above_turf))
			listeners += hearers(maxdistance,above_turf)

		if(below_turf && istransparentturf(turf_source))
			listeners += hearers(maxdistance,below_turf)

	else
		// No Copy needed — iterate the original list plus extras separately
		listeners = SSmobs.clients_by_zlevel[source_z]

		if(above_turf && istransparentturf(above_turf))
			extra_listeners_1 = SSmobs.clients_by_zlevel[above_turf.z]

		if(below_turf && istransparentturf(turf_source))
			extra_listeners_2 = SSmobs.clients_by_zlevel[below_turf.z]

	for(var/mob/M as anything in listeners)
		var/dist = get_dist(M, turf_source)
		if(dist <= maxdistance)
			M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, S, maxdistance, falloff_distance, dist <= distance_multiplier_min_range? 1 : distance_multiplier, envwet, envdry)
	for(var/mob/M as anything in extra_listeners_1)
		var/dist = get_dist(M, turf_source)
		if(dist <= maxdistance)
			M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, S, maxdistance, falloff_distance, dist <= distance_multiplier_min_range? 1 : distance_multiplier, envwet, envdry)
	for(var/mob/M as anything in extra_listeners_2)
		var/dist = get_dist(M, turf_source)
		if(dist <= maxdistance)
			M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, S, maxdistance, falloff_distance, dist <= distance_multiplier_min_range? 1 : distance_multiplier, envwet, envdry)
	for(var/mob/M as anything in SSmobs.dead_players_by_zlevel[source_z])
		var/dist = get_dist(M, turf_source)
		if(dist <= maxdistance)
			M.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, S, maxdistance, falloff_distance, dist <= distance_multiplier_min_range? 1 : distance_multiplier, envwet, envdry)

/*! playsound

playsound_local is a proc used to play a sound directly on a mob from a specific turf.
This is called by playsound to send sounds to players, in which case it also gets the max_distance of that sound.

turf_source - Origin of sound
soundin - Either a file, or a string that can be used to get an SFX
vol - The volume of the sound, excluding falloff
vary - bool that determines if the sound changes pitch every time it plays
frequency - playback speed of audio
falloff_exponent - Rate of falloff for the audio. Higher means quicker drop to low volume. Should generally be over 1 to indicate a quick dive to 0 rather than a slow dive.
channel - The channel the sound is played at
pressure_affected - Whether or not difference in pressure affects the sound (E.g. if you can hear in space)
max_distance - The peak distance of the sound, if this is a 3D sound
falloff_distance - Distance at which falloff begins, if this is a 3D sound
distance_multiplier - Can be used to multiply the distance at which the sound is heard

*/

/mob/proc/playsound_local(turf/turf_source, soundin, vol as num, vary, frequency, falloff_exponent = SOUND_FALLOFF_EXPONENT, channel = 0, pressure_affected = TRUE, sound/S, max_distance,
	falloff_distance = SOUND_DEFAULT_FALLOFF_DISTANCE, distance_multiplier = SOUND_DEFAULT_DISTANCE_MULTIPLIER, envwet = -10000, envdry = 0, virtual_hearer)
	if(audiovisual_redirect)
		virtual_hearer = get_turf(src)
		audiovisual_redirect.playsound_local(turf_source, soundin, vol, vary, frequency, falloff_exponent, channel, pressure_affected, S, max_distance, falloff_distance, distance_multiplier, max(0, envwet), -10000, virtual_hearer)
		//No return here, as we want to deliberately support the possibility of shenanigans in which mobs with clients can have active AV redirects to completely different players
	if(!client)
		return

	if(!S)
		S = sound(get_sfx(soundin))

	if(!can_hear() && !(S.status & SOUND_UPDATE)) //This is primarily to make sure sound updates still go through when a spaceman's deaf
		return

	S.wait = 0 //No queue
	S.channel = channel || SSsounds.random_available_channel()
	S.volume = vol
	// CITADEL EDIT - Force citadel reverb
	S.environment = 7
	// End

	if(vary)
		if(frequency)
			S.frequency = frequency
		else
			S.frequency = get_rand_frequency()

	if(isturf(turf_source))
		var/turf/T = virtual_hearer || get_turf(src)

		//sound volume falloff with distance
		var/distance = get_dist(T, turf_source)

		distance *= distance_multiplier

		if(max_distance) //If theres no max_distance we're not a 3D sound, so no falloff.
			S.volume -= (max(distance - falloff_distance, 0) ** (1 / falloff_exponent)) / ((max(max_distance, distance) - falloff_distance) ** (1 / falloff_exponent)) * S.volume
			//https://www.desmos.com/calculator/sqdfl8ipgf

		if(pressure_affected)
			//Atmosphere affects sound
			var/pressure_factor = 1
			var/datum/gas_mixture/hearer_env = T.return_air()
			var/datum/gas_mixture/source_env = turf_source.return_air()

			if(hearer_env && source_env)
				var/pressure = min(hearer_env.return_pressure(), source_env.return_pressure())
				if(pressure < ONE_ATMOSPHERE)
					pressure_factor = max((pressure - SOUND_MINIMUM_PRESSURE)/(ONE_ATMOSPHERE - SOUND_MINIMUM_PRESSURE), 0)
			else //space
				pressure_factor = 0

			if(distance <= 1)
				pressure_factor = max(pressure_factor, 0.15) //touching the source of the sound

			S.volume *= pressure_factor
			//End Atmosphere affecting sound

			/// Citadel edit - Citadel reverb
			S.echo = list(envdry, null, envwet, null, null, null, null, null, null, null, null, null, null, 1, 1, 1, null, null)
			/// End

		if(S.volume <= 0)
			return //No sound

		var/dx = turf_source.x - T.x // Hearing from the right/left
		S.x = dx * distance_multiplier
		var/dz = turf_source.y - T.y // Hearing from infront/behind
		S.z = dz * distance_multiplier
		var/dy = (turf_source.z - T.z) * 5 * distance_multiplier // Hearing from  above / below, multiplied by 5 because we assume height is further along coords.
		S.y = dy + distance_multiplier

		S.falloff = isnull(max_distance)? FALLOFF_SOUNDS : max_distance //use max_distance, else just use 1 as we are a direct sound so falloff isnt relevant.

		// It's not the best decision to rely on file path, but most straightforward and reliable.
		if(HAS_TRAIT(src, TRAIT_AWOO)  && iscarbon(src))
			if((S.file == 'modular_citadel/sound/voice/awoo.ogg' || S.file == 'modular_splurt/sound/voice/wolfhowl.ogg') && (distance > 0))
				var/mob/living/carbon/C = src
				var/datum/quirk/awoo/quirk_target = locate() in C.roundstart_quirks
				quirk_target.do_awoo()

		/*
		/// Tg reverb removed
		if(S.environment == SOUND_ENVIRONMENT_NONE)
			if(sound_environment_override != SOUND_ENVIRONMENT_NONE)
				S.environment = sound_environment_override
			else
				var/area/A = get_area(src)
				if(A.sound_environment != SOUND_ENVIRONMENT_NONE)
					S.environment = A.sound_environment

		if(use_reverb)
			if(S.environment == SOUND_ENVIRONMENT_NONE) //We have reverb, reset our echo setting
				S.environment = SOUND_ENVIRONMENT_CONCERT_HALL
				S.echo = list(0, null, -10000, null, null, null, null, null, null, null, null, null, null, 1, 1, 1, null, null)
			else
				S.echo[3] = 0 //Room setting, 0 means normal reverb
				S.echo[4] = 0 //RoomHF setting, 0 means normal reverb.
		*/
		///

	SEND_SOUND(src, S)

/proc/sound_to_playing_players(soundin, volume = 100, vary = FALSE, frequency = 0, channel = 0, pressure_affected = FALSE, sound/S)
	if(!S)
		S = sound(get_sfx(soundin))
	for(var/mob/M as anything in GLOB.player_list)
		if(!isnewplayer(M))
			M.playsound_local(M, null, volume, vary, frequency, null, channel, pressure_affected, S)

/mob/proc/stop_sound_channel(chan)
	SEND_SOUND(src, sound(null, repeat = 0, wait = 0, channel = chan))

/mob/proc/set_sound_channel_volume(channel, volume)
	var/sound/S = sound(null, FALSE, FALSE, channel, volume)
	S.status = SOUND_UPDATE
	SEND_SOUND(src, S)

/client/proc/playtitlemusic(vol = 85)
	set waitfor = FALSE
	UNTIL(SSticker.login_music) //wait for SSticker init to set the login music

	if(prefs && (prefs.toggles & SOUND_LOBBY))
		SEND_SOUND(src, sound(SSticker.login_music, repeat = 0, wait = 0, volume = vol, channel = CHANNEL_LOBBYMUSIC)) // MAD JAMS

/proc/get_rand_frequency()
	return rand(32000, 55000) //Frequency stuff only works with 45kbps oggs.

///get_rand_frequency but lower range.
/proc/get_rand_frequency_low_range()
	return rand(38000, 45000)

///Used to convert a SFX define into a .ogg so we can add some variance to sounds. If soundin is already a .ogg, we simply return it
/proc/get_sfx(soundin)
	if(!istext(soundin))
		return soundin
	var/datum/sound_effect/sfx = GLOB.sfx_datum_by_key[soundin]
	return sfx?.return_sfx() || soundin

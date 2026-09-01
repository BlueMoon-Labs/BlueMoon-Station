/*
	output_atoms (list of atoms) The destination(s) for the sounds

	mid_sounds (list or soundfile) Since this can be either a list or a single soundfile you can have random sounds. May contain further lists but must contain a soundfile at the end.
	mid_length (num) The length to wait between playing mid_sounds

	start_sound (soundfile) Played before starting the mid_sounds loop
	start_length (num) How long to wait before starting the main loop after playing start_sound

	end_sound (soundfile) The sound played after the main loop has concluded

	chance (num) Chance per loop to play a mid_sound
	volume (num) Sound output volume
	max_loops (num) The max amount of loops to run for.
	direct (bool) If true plays directly to provided atoms instead of from them
*/
/datum/looping_sound
	var/atom/parent
	var/mid_sounds
	var/mid_length
	///Override for volume of start sound
	var/start_volume
	var/start_sound
	var/start_length
	///Override for volume of end sound
	var/end_volume
	var/end_sound
	var/chance
	var/volume = 100
	var/vary = FALSE
	var/max_loops
	var/direct
	var/extra_range = 0
	var/falloff_exponent
	var/timerid
	var/falloff_distance
	var/skip_starting_sounds = FALSE
	var/loop_started = FALSE

/datum/looping_sound/New(_parent, start_immediately=FALSE, _direct=FALSE, _skip_starting_sounds = FALSE)
	if(!mid_sounds)
		WARNING("A looping sound datum was created without sounds to play.")
		return

	set_parent(_parent)
	direct = _direct
	skip_starting_sounds = _skip_starting_sounds

	if(start_immediately)
		start()

/datum/looping_sound/Destroy()
	stop(TRUE)
	return ..()

/datum/looping_sound/proc/start(on_behalf_of)
	if(on_behalf_of)
		set_parent(on_behalf_of)
	if(timerid)
		return
	on_start()

/datum/looping_sound/proc/stop(null_parent)
	if(null_parent)
		set_parent(null)
	if(!timerid)
		return
	on_stop()
	deltimer(timerid)
	timerid = null
	loop_started = FALSE

/datum/looping_sound/proc/start_sound_loop()
	loop_started = TRUE
	sound_loop()
	timerid = addtimer(CALLBACK(src, PROC_REF(sound_loop), world.time), mid_length, TIMER_CLIENT_TIME | TIMER_STOPPABLE | TIMER_LOOP | TIMER_DELETE_ME)

// Соблазн пропускать такт, когда на нашем z нет клиентов (SSmobs.clients_by_zlevel),
// не реализован сознательно: playsound() отдаёт звук ещё и слушателям этажом выше
// или ниже через прозрачные турфы, а мёртвых берёт из dead_players_by_zlevel -
// обе категории мимо этого списка, и тихий цикл стал бы слышимой регрессией.
// Отсечка по слушателям живёт внутри playsound(), где видны все её источники сразу.
/datum/looping_sound/proc/sound_loop(starttime)
	if(max_loops && world.time >= starttime + mid_length * max_loops)
		stop()
		return
	if(!chance || prob(chance))
		play(get_sound(starttime))

/datum/looping_sound/proc/play(soundfile, volume_override)
	if(!parent)
		return
	if(direct)
		var/sound/S = sound(soundfile)
		S.channel = SSsounds.random_available_channel()
		S.volume = volume_override || volume //Use volume as fallback if theres no override
		SEND_SOUND(parent, S)
		return
	// Файл уходит в playsound() как есть: тот и так строит свой /sound через
	// get_sfx(), а прежняя обёртка sound() здесь удваивала счёт датумов на
	// каждый такт КАЖДОГО цикла в мире. Перепись раунда 10060 (Delta, 3.5 часа
	// без игроков) насчитала 1.6 млн /sound, половина из них рождалась тут и
	// не доезжала ни до одного клиента. Громкость, vary и extra_range и раньше
	// приезжали отдельными аргументами playsound(), обёртка их не несла.
	playsound(parent, soundfile, volume, vary, extra_range, falloff_exponent = falloff_exponent, falloff_distance = falloff_distance)

/datum/looping_sound/proc/get_sound(starttime, _mid_sounds)
	. = _mid_sounds || mid_sounds
	while(!isfile(.) && !isnull(.))
		. = pickweight(.)

/datum/looping_sound/proc/on_start()
	var/start_wait = 0
	if(start_sound && !skip_starting_sounds)
		play(start_sound, start_volume)
		start_wait = start_length
	timerid = addtimer(CALLBACK(src, PROC_REF(start_sound_loop)), start_wait, TIMER_CLIENT_TIME | TIMER_DELETE_ME | TIMER_STOPPABLE)

/datum/looping_sound/proc/on_stop()
	if(end_sound && loop_started)
		play(end_sound, end_volume)

/datum/looping_sound/proc/set_parent(new_parent)
	if(parent)
		UnregisterSignal(parent, COMSIG_PARENT_QDELETING)
	parent = new_parent
	if(parent)
		RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(handle_parent_del))

/datum/looping_sound/proc/handle_parent_del(datum/source)
	SIGNAL_HANDLER
	set_parent(null)

/// Pings admins every (time chosen in config) for all open tickets/OPFOR applications
SUBSYSTEM_DEF(ticket_ping)
	name = "Ticket Ping"
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_LOBBY | RUNLEVEL_SETUP | RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 3 MINUTES

/datum/controller/subsystem/ticket_ping/Initialize()
	initialized = TRUE
	if(CONFIG_GET(number/ticket_ping_frequency) < 1)
		flags |= SS_NO_FIRE
		return FALSE

	wait = CONFIG_GET(number/ticket_ping_frequency)

	return ..()

/datum/controller/subsystem/ticket_ping/fire(resumed)
	var/valid_ahelps
	for(var/datum/admin_help/ahelp in GLOB.ahelp_tickets.active_tickets)
		if(ahelp.handler || ahelp.ticket_ping_stop || !ahelp.ticket_ping)
			continue
		valid_ahelps++

	if(!valid_ahelps)
		return

	message_admins("У нас сейчас [valid_ahelps] [valid_ahelps == 1 ? "не взятый на рассмотрение тикет" : "не взятых на рассмотрение тикетов"].",\
	islog = FALSE, prefix = "AHELP")

	for(var/client/staff as anything in GLOB.admins)
		if(!(staff.prefs?.toggles & SOUND_ADMINHELP))
			continue
		var/sound_pick = rand(0, 1)
		var/ah_vol = staff.prefs?.get_sound_volume("adminhelp")
		if(isnull(ah_vol))
			ah_vol = 100
		switch(sound_pick)
			if(0)
				SEND_SOUND(staff, sound('modular_bluemoon/sound/effects/soft_ping.ogg', volume = ah_vol))
			if(1)
				SEND_SOUND(staff, sound('modular_bluemoon/sound/voice/fiasko.ogg', volume = ah_vol))
			// if(2)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/voice/yamete_kudasai.ogg', volume = ah_vol))
			// if(3)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/ert/combine_death.ogg', volume = ah_vol))
			// if(4)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/ert/chechnya.ogg', volume = ah_vol))
			// if(5)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/voice/ekarni_babai.ogg', volume = ah_vol))
			// if(6)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/voice/fit_ha.ogg', volume = ah_vol))
			// if(7)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/ert/get_out.ogg', volume = ah_vol))
			// if(8)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/effects/metal_pipe.ogg', volume = ah_vol))
			// if(9)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/voice/new_moan.ogg', volume = ah_vol))
			// if(10)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/sound/ert/sergeant_dornan.ogg', volume = ah_vol)) Это пиздец такая подлянка конечно, зачем такие имбовые звуки надо было комментить.
		window_flash(staff, ignorepref = TRUE)

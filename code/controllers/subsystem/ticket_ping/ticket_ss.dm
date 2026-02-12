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
	log = TRUE)

	for(var/client/staff as anything in GLOB.admins)
		var/sound_pick = rand(0, 1)
		switch(sound_pick)
			if(0)
				SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/soft_ping.ogg'))
			if(1)
				SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/fiasko.ogg'))
			// if(2)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/yamete_kudasai.ogg'))
			// if(3)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/combine_death.ogg'))
			// if(4)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/chechnya.ogg'))
			// if(5)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/ekarni_babai.ogg'))
			// if(6)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/fit_ha.ogg'))
			// if(7)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/get_out.ogg'))
			// if(8)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/metal_pipe.ogg'))
			// if(9)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/new_moan.ogg'))
			// if(10)
			// 	SEND_SOUND(staff, sound('modular_bluemoon/SmiLeY/sounds/sergeant_dornan.ogg'))
		window_flash(staff, ignorepref = TRUE)

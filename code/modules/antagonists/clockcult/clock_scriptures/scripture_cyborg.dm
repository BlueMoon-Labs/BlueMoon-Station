/////////////////
// CYBORG ONLY // Cyborgs only, fleshed ones.
/////////////////

//Linked Vanguard: grants Vanguard to the invoker and a target
/datum/clockwork_scripture/ranged_ability/linked_vanguard
	name = "Linked Vanguard"
	invocations = list("Защити нас...", "...от тьмы!")
	channel_time = 30
	primary_component = VANGUARD_COGWHEEL
	quickbind_desc = "Позволяет вам и слуге получить иммунитет к оглушению, как в писании Авангарда.<br><b>Нажмите на плитуу, чтобы отключить эффект.</b>"
	slab_overlay = "vanguard"
	ranged_type = /obj/effect/proc_holder/slab/vanguard
	ranged_message = "<span class='inathneq_small'><i>Вы заряжаете часовую плиту защитной силой.</i>\n\
	<b>Щелкните левой кнопкой мыши по другому Служителю или по себе, чтобы применить способность Авангарда!\n\
	Нажмите на свою плиту, чтобы отменить.</b></span>"
	timeout_time = 50

/datum/clockwork_scripture/ranged_ability/linked_vanguard/check_special_requirements()
	if(!GLOB.ratvar_awakens && islist(invoker.stun_absorption) && invoker.stun_absorption["vanguard"] && invoker.stun_absorption["vanguard"]["end_time"] > world.time)
		to_chat(invoker, "<span class='warning'>Вы уже находитесь под защитой Авангарда!</span>")
		return FALSE
	return TRUE

/datum/clockwork_scripture/ranged_ability/linked_vanguard/scripture_effects()
	if(GLOB.ratvar_awakens) //hey, ratvar's up! give everybody stun immunity.
		for(var/mob/living/L in view(7, get_turf(invoker)))
			if(L.stat != DEAD && is_servant_of_ratvar(L))
				L.apply_status_effect(STATUS_EFFECT_VANGUARD)
			CHECK_TICK
		return TRUE
	return ..()

//Judicial Marker: places a judicial marker at a target location
/datum/clockwork_scripture/ranged_ability/judicial_marker
	name = "Judicial Marker"
	invocations = list("Пусть язычники...", "...преклонят колени перед нашей мощью")
	channel_time = 30
	primary_component = BELLIGERENT_EYE
	quickbind_desc = "Позволяет нанести удар по области, накладывая эффект Воинственности и на короткое время оглушая цель.<br><b>Нажмите на плиту, чтобы отключить эффект.</b>"
	slab_overlay = "judicial"
	ranged_type = /obj/effect/proc_holder/slab/judicial
	ranged_message = "<span class='neovgre_small'><i>Вы заряжаете часовую плиту силой правосудия.</i>\n\
	<b>Нажмите левой кнопкой мыши на цель, чтобы установить судебный маркер!\n\
	Нажмите на свою плиту, чтобы отменить.</b></span>"
	timeout_time = 50

//These are exactly the same as the default scriptures, but cyborgs don't need a second person to create them
/datum/clockwork_scripture/create_object/mania_motor/cyborg
	invokers_required = 1
	tier = SCRIPTURE_PERIPHERAL
	multiple_invokers_used = FALSE


/datum/clockwork_scripture/create_object/clockwork_obelisk/cyborg
	invokers_required = 1
	tier = SCRIPTURE_PERIPHERAL
	multiple_invokers_used = FALSE

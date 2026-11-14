#define ANTAG_TRAINING_FLICKER_SETTLE (1 SECONDS)

/obj/machinery/light/small/red/antag_training_flicker
	name = "emergency light"
	desc = "Аварийная лампа заброшенного яруса. Плафон треснул, контакты окислились, и свет то и дело гаснет."
	obj_integrity = 35
	/// Пока TRUE, лампа не бьётся без звука: так её роняет случайный бой базового Initialize().
	var/settling = TRUE

/obj/machinery/light/small/red/antag_training_flicker/Initialize(mapload)
	. = ..()
	addtimer(VARSET_CALLBACK(src, settling, FALSE), ANTAG_TRAINING_FLICKER_SETTLE)

/obj/machinery/light/small/red/antag_training_flicker/break_light_tube(skip_sound_and_sparks = 0)
	if(settling && skip_sound_and_sparks)
		return FALSE
	return ..()

/obj/machinery/light/small/red/antag_training_flicker/update(trigger = TRUE, silent = FALSE)
	. = ..()
	if(!QDELETED(src))
		check_damage_flicker()

#undef ANTAG_TRAINING_FLICKER_SETTLE

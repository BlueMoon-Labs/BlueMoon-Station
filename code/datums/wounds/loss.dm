/datum/wound/loss
	name = "Dismembered"
	desc = "oof ouch!!"
	ru_name = "Расчленение"
	ru_name_r = "расчленения"

	sound_effect = 'sound/effects/dismember.ogg'
	severity = WOUND_SEVERITY_LOSS
	threshold_minimum = 160
	status_effect_type = null
	scar_keyword = "dismember"
	wound_flags = null
	already_scarred = TRUE // so we don't scar a limb we don't have. If I add different levels of amputation desc, do it below

/// Our special proc for our special dismembering, the wounding type only matters for what text we have
/datum/wound/loss/proc/apply_dismember(obj/item/bodypart/dismembered_part, wounding_type=WOUND_SLASH)
	. = FALSE
	if(!istype(dismembered_part) || QDELETED(dismembered_part.owner) || !(dismembered_part.body_zone in viable_zones) || isalien(dismembered_part.owner) || !dismembered_part.can_dismembered())
		qdel(src)
		return

	victim = dismembered_part.owner
	limb = dismembered_part
	second_wind()
	. = dismembered_part.dismember(wounding_type == WOUND_BURN ? BURN : BRUTE)
	if(.)
		switch(wounding_type)
			if(WOUND_BLUNT)
				occur_text = "отрывается от последнего обломка костей, что её удерживал"
			if(WOUND_SLASH)
				occur_text = "отрывается в результате режущей раны"
			if(WOUND_PIERCE)
				occur_text = "отрывается в результате колотой раны"
			if(WOUND_BURN)
				occur_text = "сгорает целиком, обращаясь в пепел"
			else
				occur_text = "отрывается"
		var/msg = span_boldwarning("[dismembered_part.ru_name_capital] персонажа [victim] [occur_text]!")
		victim.visible_message(msg, span_userdanger("Ваша [dismembered_part.ru_name] [occur_text]!"))
		log_wound(victim, src)
	qdel(src)

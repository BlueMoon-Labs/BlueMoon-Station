/mob/living/silicon/examine(mob/user) //Displays a silicon's laws to ghosts | BLUEMOON EDIT - и темпфлавор
	if(tempflavor)
		. += "\n[span_notice(tempflavor)]\n"
	if(laws && isobserver(user))
		. += "<b>[src] обладает следующими законами:</b>"
		for(var/law in laws.get_law_list(include_zeroth = TRUE))
			. += "<br>[law]"

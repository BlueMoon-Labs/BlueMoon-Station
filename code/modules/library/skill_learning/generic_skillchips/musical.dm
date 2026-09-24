/obj/item/skillchip/musical
	name = "\improper Old Copy of \"Space Station 13: The Musical\""
	desc = "An old copy of \"Space Station 13: The Musical\", \
		ran on the station's 100th anniversary...Or maybe it was the 200th?"
	skill_name = "Memory of a Musical"
	skill_description = "Allows you to hit that high note, like those that came a century before us."
	skill_icon = "music"
	activate_message = span_notice("You feel like you could \u2669 sing a soooong! \u266B")
	deactivate_message = span_notice("The musical fades from your mind, leaving you with a sense of nostalgia.")
	custom_premium_price = PAYCHECK_MEDIUM * 4

/obj/item/skillchip/musical/Initialize(mapload, is_removable)
	. = ..()
	var/current_year = text2num(time2text(world.realtime, "YYYY"))
	name = replacetext(name, "Old", round(current_year - pick(50, 100, 150, 200, 250), 5))

/obj/item/skillchip/musical/on_activate(mob/living/carbon/user, silent = FALSE)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_SAY, PROC_REF(make_music))

/obj/item/skillchip/musical/on_deactivate(mob/living/carbon/user, silent = FALSE)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_SAY)

/obj/item/skillchip/musical/proc/make_music(mob/living/carbon/source, list/speech_args)
	SIGNAL_HANDLER

	var/raw_message = speech_args[SPEECH_MESSAGE]
	if(!length(raw_message))
		return

	var/static/list/vowel_chars = list("a", "e", "i", "o", "u", "y", "A", "E", "I", "O", "U", "Y")
	var/list/words = splittext(raw_message, " ")
	if(length(words) <= 1)
		speech_args[SPEECH_MESSAGE] = "\u2669 [raw_message] \u266B"
		return
	var/last_word = words[length(words)]
	var/num_chars = length_char(last_word)
	var/last_vowel = ""
	// find the last vowel present in the word
	for(var/i in 1 to num_chars)
		var/char = copytext_char(last_word, i, i + 1)
		if(char in vowel_chars)
			last_vowel = char

	// now we'll reshape the final word to make it sound like they're singing it
	var/final_word = ""
	var/has_ellipsis = copytext(last_word, -3) == "..."
	for(var/i in 1 to num_chars)
		var/char = copytext_char(last_word, i, i + 1)
		// replacing any final periods with exclamation marks (so long as it's not an ellipsis)
		if(char == "." && i == num_chars && !has_ellipsis)
			final_word += "!"
		// or if it's the vowel we found, we're gonna repeat it a few times (holding the note)
		else if(char == last_vowel)
			for(var/j in 1 to 4)
				final_word += char
			// if we dragged out the last character of the word, just period it
			if(i == num_chars)
				final_word += "."
		// no special handling otherwise
		else
			final_word += char

	if(!has_ellipsis)
		// adding an extra exclamation mark at the end if there's no period
		var/last_char = copytext_char(final_word, -1)
		if(last_char != ".")
			final_word += "!"

	words[length(words)] = final_word
	// now we siiiiiiing
	speech_args[SPEECH_MESSAGE] = "\u2669 [jointext(words, " ")] \u266B"

/obj/item/skillchip/musical/examine(mob/user)
	. = ..()
	. += span_tinynoticeital("Huh, looks like it'd fit in a skillchip adapter.")

#define SCRAMBLE_CACHE_LEN 50 //maximum of 50 specific scrambled lines per language

/*
	Datum based languages. Easily editable and modular.
*/

/datum/language
	var/name = "an unknown language"  // Fluff name of language if any.
	var/desc = "A language."          // Short description for 'Check Languages'.
	var/speech_verb = "says"          // 'says', 'hisses', 'farts'.
	var/ask_verb = "asks"             // Used when sentence ends in a ?
	var/exclaim_verb = "exclaims"     // Used when sentence ends in a !
	var/whisper_verb = "whispers"     // Optional. When not specified speech_verb + quietly/softly is used instead.
	var/list/signlang_verb = list("signs", "gestures") // list of emotes that might be displayed if this language has NONVERBAL or SIGNLANG flags
	var/key                           // Character used to speak in language
	// If key is null, then the language isn't real or learnable.
	var/flags                         // Various language flags.
	var/visual_language = FALSE       // Whether this language is visual (sign language) rather than audible
	var/list/syllables                // Used when scrambling text for a non-speaker.
	var/sentence_chance = 5      // Likelihood of making a new sentence after each syllable.
	var/space_chance = 55        // Likelihood of getting a space in the random scramble string
	var/list/spans = list()
	var/list/scramble_cache = list()
	var/default_priority = 0          // the language that an atom knows with the highest "default_priority" is selected by default.

	//SKYRAT CHANGE - is this language available on the character setup? Set to true if not.
	var/restricted = TRUE
	//

	// if you are seeing someone speak popcorn language, then something is wrong.
	var/icon = 'icons/misc/language.dmi'
	var/icon_state = "popcorn"

	// BLUEMOON ADD START - наши добавления к языкам. Старайтесь держать здесь для упрощения отслеживания переменных
	var/complex_language = FALSE // если положительно, то у языка появляются приставки, окончания, апострофы (их нужно ещё записать)

	var/apostrophe_chance = 0 // шанс на появление апостровоф
	var/list/apostrophe_prefix = list("a") // ПОСЛЕ этих слогов идёт апостроф. Вставляется в начале предложения
	var/list/apostrophe_ending = list("a") // ПЕРЕД этими слогами идёт апостроф. Вставляется в конце предложения. Вставляют пробел после себя

	var/syllables_additions_chance = 0 // шанс на появление окончания
	var/list/syllables_prefix = list("a") // приставка.
	var/list/syllables_endings = list("a") // окончания. Вставляют пробел после себя

	// BLUEMOON ADD END

/datum/language/proc/display_icon(atom/movable/hearer)
	var/understands = hearer.has_language(src.type)
	if(flags & LANGUAGE_HIDE_ICON_IF_UNDERSTOOD && understands)
		return FALSE
	if(flags & LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD && !understands)
		return FALSE
	return TRUE

/datum/language/proc/get_icon()
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/chat)
	return sheet.icon_tag("language-[icon_state]")

/datum/language/proc/get_random_name(gender, name_count=2, syllable_count=4, syllable_divisor=2)
	if(!syllables || !syllables.len)
		if(gender==FEMALE)
			return capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names))
		else
			return capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names))

	var/full_name = ""
	var/new_name = ""

	for(var/i in 0 to name_count)
		new_name = ""
		var/Y = rand(FLOOR(syllable_count/syllable_divisor, 1), syllable_count)
		for(var/x in Y to 0)
			new_name += pick(syllables)
		full_name += " [capitalize(lowertext(new_name))]"

	return "[trim(full_name)]"

/datum/language/proc/check_cache(input)
	var/lookup = scramble_cache[input]
	if(lookup)
		scramble_cache -= input
		scramble_cache[input] = lookup
	. = lookup

/datum/language/proc/add_to_cache(input, scrambled_text)
	// Add it to cache, cutting old entries if the list is too long
	scramble_cache[input] = scrambled_text
	if(scramble_cache.len > SCRAMBLE_CACHE_LEN)
		scramble_cache.Cut(1, scramble_cache.len-SCRAMBLE_CACHE_LEN-1)

/datum/language/proc/scramble(input)

	if(!syllables || !syllables.len)
		return stars(input)

	// If the input is cached already, move it to the end of the cache and return it
	var/lookup = check_cache(input)
	if(lookup)
		return lookup

	var/input_size = length_char(input)
	var/scrambled_text = ""
	var/capitalize = TRUE

	// BLUEMOON ADD START
	if(complex_language) // более 90% языков базовые и не обладают такими усложнениями, чтобы проводить с каждым слогом новые проверки
		while(length_char(scrambled_text) < input_size) // копирование базового, но с дополнительными prob
			var/next = pick(syllables)
			if(capitalize)
				next = capitalize(next)
				capitalize = FALSE
			scrambled_text += next
			var/chance = rand(100)
			if(chance <= sentence_chance)
				scrambled_text += ". "
				capitalize = TRUE
				if(prob(apostrophe_chance)) // Большая буква для апострова в новом предложении
					scrambled_text += capitalize(pick(apostrophe_prefix))
					scrambled_text += "'"
					capitalize = FALSE
				else if(prob(syllables_additions_chance)) // Большая буква для приставки в новом предложении
					scrambled_text += capitalize(pick(syllables_prefix))
					capitalize = FALSE
			else if(chance > sentence_chance && chance <= space_chance)
				scrambled_text += " "
				if(prob(apostrophe_chance)) /// обычный апостров в начале слова
					scrambled_text += pick(apostrophe_prefix)
					scrambled_text += "'"
				else if(prob(syllables_additions_chance)) /// приставка
					scrambled_text += pick(syllables_prefix)
			else if(prob(apostrophe_chance)) // апостров в конце слова
				scrambled_text += "'"
				scrambled_text += pick(apostrophe_ending)
				scrambled_text += " "
			else if(prob(syllables_additions_chance)) // окончание
				scrambled_text += pick(syllables_endings)
				scrambled_text += " "
	else
	// BLUEMOON ADD END
		while(length_char(scrambled_text) < input_size)
			var/next = pick(syllables)
			if(capitalize)
				next = capitalize(next)
				capitalize = FALSE
			scrambled_text += next
			var/chance = rand(100)
			if(chance <= sentence_chance)
				scrambled_text += ". "
				capitalize = TRUE
			else if(chance > sentence_chance && chance <= space_chance)
				scrambled_text += " "

	scrambled_text = trim(scrambled_text)
	var/ending = copytext_char(scrambled_text, -1)
	if(ending == ".")
		scrambled_text = copytext_char(scrambled_text, 1, -2)
	var/input_ending = copytext_char(input, -1)
	if(input_ending in list("!","?","."))
		scrambled_text += input_ending

	add_to_cache(input, scrambled_text)

	return scrambled_text

/datum/language/proc/get_spoken_verb(msg_end)
	switch(msg_end)
		if("!")
			return exclaim_verb
		if("?")
			return ask_verb
	return speech_verb

#undef SCRAMBLE_CACHE_LEN

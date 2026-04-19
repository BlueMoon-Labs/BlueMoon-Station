//Readds quotes and apostrophes to HTML-encoded strings
/proc/readd_quotes(t)
	t = replacetext(t, "&#34;", "\"")
	return replacetext(t, "&#39;", "'")

/proc/TextPreview(string, len = 40)
	var/char_len = length_char(string)
	if(char_len <= len)
		if(char_len)
			return "\[...\]"
		else
			return string
	else
		return "[copytext_char(string, 1, 37)]..."

GLOBAL_LIST_EMPTY(mentorlog)
GLOBAL_PROTECT(mentorlog)

GLOBAL_LIST_EMPTY(whitelisted_species_list)

/proc/log_mentor(text)
	GLOB.mentorlog.Add(text)
	WRITE_FILE(GLOB.world_game_log, "\[[TIME_STAMP("hh:mm:ss", FALSE)]]MENTOR: [text]")

/proc/log_looc(text)
	if (CONFIG_GET(flag/log_ooc))
		WRITE_FILE(GLOB.world_game_log, "\[[TIME_STAMP("hh:mm:ss", FALSE)]]LOOC: [text]")

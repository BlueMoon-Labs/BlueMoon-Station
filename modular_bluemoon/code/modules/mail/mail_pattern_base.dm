/datum/mail_pattern
	var/name = "_Дефолтный паттерн"
	var/description = "Базовый паттерн для писем"

	var/sender = MAIL_SENDER_RANDOM_NAME

	/// Envelope / Package
	var/envelope_type = MAIL_TYPE_ENVELOPE

	/// Envelope, to which this pattern assigned
	var/obj/item/mail/parent

	/// Category of letter
	var/category = MAIL_CATEGORY_MISC
	/// Weight (chance) of getting this lettertype
	var/weight = 0

	/// Name for text letter in envelope
	var/letter_title = "БЛАНК ПОЛУЧЕНИЯ"
	/// HTML for text letter in envelope
	var/letter_html = ""
	/// Description for text letter in envelope
	var/letter_desc = "Слегка помятая исписанная бумажка с явным перегибом по середине. Видимо, её достали из конверта."
	/// Icon file for text letter in envelope
	var/letter_icon = 'icons/obj/bureaucracy.dmi'
	/// Icon state for text letter in envelope
	var/letter_icon_state = "paperslip_words"

	var/letter_sign = "С уважением, %%подпись%%"

	/// Created items during pattern applying. If items should be customised, override apply() proc
	var/list/obj/item/initial_contents = list()

	/// If this property is not null, mail shows to opener this message with choices: to open or not to open
	var/bad_feeling = null

	//
	// ОГРАНИЧЕНИЯ
	//

	// ... НА РЕЖИМ ИГРЫ

	/// List of whitelisted roundtypes. (Extended, Dynamic Hard, etc). Pattern will be available only during them
	var/list/whitelisted_roundtypes = list()
	/// List of blacklisted roundtypes (Extended, Dynamic Hard, etc). Pattern will not be available during them
	var/list/blacklisted_roundtypes = list()

	// ... НА КВИРКИ

	/// List of whitelisted quirk types. Pattern will be available only if owner has one of them
	var/list/whitelisted_quirks = list()
	/// List of blacklisted quirk types. Pattern will not be available if owner has one of them
	var/list/blacklisted_quirks = list()

	// ... НА РАСЫ

	/// List of whitelisted species types. Pattern will be available only if owner has one of them
	var/list/whitelisted_species = list()
	/// List of blacklisted species types. Pattern will not be available if owner has one of them
	var/list/blacklisted_species = list()

	// ... НА ПРОФЕССИИ. Передаётся строками из player.mind.assigned_role

	/// List of whitelisted jobs. Pattern will be available only if owner assigned role is one of them
	var/list/whitelisted_jobs = list()
	/// List of blacklisted jobs. Pattern will not be available if owner assigned role is one of them
	var/list/blacklisted_jobs = list()

	// ... НА ГЕНДЕР
	var/list/whitelisted_gender = list()
	var/list/blacklisted_gender = list()

	// ... НА МАЙНДШИЛД

	/// Will the mindshield implant in the recipient disable this pattern?
	var/mindshield_prohibited = FALSE
	/// Is the mindshield implant required to get this pattern?
	var/mindshield_required = FALSE

/datum/mail_pattern/Destroy(force, ...)
	parent = null
	initial_contents = null
	. = ..()

/// Customising text piece for specific recipient
/datum/mail_pattern/proc/text_customisation(text = "", mob/living/carbon/human/recipient)
	if(!istype(recipient) || !istype(parent))
		return
	var/output = text
	output = replacetext_char(output, "%%подпись%%", "<br><span style=\"color:black;font-family:'Segoe Script';\"><p><b>[sender]</b></p></span>")
	if(recipient.gender)
		output = replacetext_char(output, "%%СЯ%%", recipient.ru_sya())
		output = replacetext_char(output, "%%ОН%%", recipient.ru_who())
		output = replacetext_char(output, "%%ЕГО%%", recipient.ru_ego())
		output = replacetext_char(output, "%%НЕГО%%", recipient.ru_nego())
		output = replacetext_char(output, "%%НЁМ%%", recipient.ru_na())
		output = replacetext_char(output, "%%ЕМУ%%", recipient.ru_emu())
		output = replacetext_char(output, "%%А%%", recipient.ru_a())
		output = replacetext_char(output, "%%ЕН%%", recipient.ru_en())
		// " %-внучок | внучка%- "
		var/list/text_pieces = splittext_char(output,  "%-")
		var/list/formatted_text_pieces = list()
		if(text_pieces.len  > 1)
			for(var/piece in text_pieces)
				if(piece[1] == ">")
					piece = replacetext_char(piece, ">",  "")
					var/list/parts_of_replacer = splittext_char(piece,  " | ")
					if(recipient.gender == FEMALE)
						piece = parts_of_replacer[2]
					else
						piece = parts_of_replacer[1]
				formatted_text_pieces += piece
			output = jointext(formatted_text_pieces, "")

	return output

/// Proc, that applies settings of this pattern to piece of mail, for example customising text, creating letter and contents
/datum/mail_pattern/proc/apply(mob/living/carbon/human/recipient)
	if(!istype(parent))
		return

	if(envelope_type == MAIL_TYPE_PACKAGE)
		parent.convert_to_package()

	if(sender == MAIL_SENDER_RANDOM_NAME)
		sender = random_unique_name(pick(MALE, FEMALE), 1)
	else if(sender == MAIL_SENDER_RANDOM_FEMALE)
		sender = random_unique_name(FEMALE, 1)
	else if(sender == MAIL_SENDER_RANDOM_MALE)
		sender = random_unique_name(MALE, 1)

	if(letter_html)
		if(letter_sign)
			letter_sign = "<br><br><i style='text-align:right;'>[letter_sign]</i>"
			letter_sign = text_customisation(letter_sign, recipient)
			letter_html += letter_sign
		letter_html = "<html><body>" + letter_html + "</body></html>"
		letter_title = text_customisation(letter_title, recipient)
		letter_html = text_customisation(letter_html, recipient)
		sender = text_customisation(sender, recipient)
		var/obj/item/paper/letter = new /obj/item/paper(parent)
		if(letter)
			letter.show_written_words = FALSE
			letter.name = letter_title
			letter.add_raw_text(letter_html, advanced_html = TRUE)
			letter.desc = letter_desc
			letter.icon = letter_icon
			letter.icon_state = letter_icon_state
			letter.update_appearance()
			parent.included_letter = letter
	// 25% шанс получить неправильного адресата
	if(prob(25))
		sender = pick(list(MAIL_SENDER_CENTCOM, "N/A", "Не указан", "УДАЛЕНО", "НЕИЗВЕСТНО", MAIL_SENDER_RANDOM_NAME))
	parent.sender_name = sender

	for(var/good in initial_contents)
		new good(parent)

/// Special check of pattern, that called by mail/try_open() proc. If returns FALSE, piece of mail will not be open.
/datum/mail_pattern/proc/special_open_check(mob/living/carbon/human/recipient)
	. = TRUE
	if(bad_feeling)
		var/bad_feeling_response = tgui_alert(recipient, bad_feeling, "А стоит ли?", list("Не открывать", "Открыть"), 10 SECONDS)
		if(bad_feeling_response != "Открыть")
			return FALSE

/// Returns weight of selected pattern in accordance to all filters and checks, applied to specific recipient
/datum/mail_pattern/proc/regenerate_weight(mob/living/carbon/human/recipient)
	. = weight
	// Фильтр на тип раунда

	if(whitelisted_roundtypes.len)
		if(!(GLOB.round_type in whitelisted_roundtypes))
			return 0
	if(blacklisted_roundtypes.len)
		if(GLOB.round_type in blacklisted_roundtypes)
			return 0

	// Фильтр на квирки

	if(whitelisted_quirks.len)
		var/whitelist_quirk_exists = FALSE
		for(var/Q in recipient.roundstart_quirks)
			var/datum/quirk/quirk = Q
			if(quirk.type in whitelisted_quirks)
				whitelist_quirk_exists = TRUE
				break
		if(!whitelist_quirk_exists)
			return 0
	if(blacklisted_quirks.len)
		for(var/Q in recipient.roundstart_quirks)
			var/datum/quirk/quirk = Q
			if(quirk.type in blacklisted_quirks)
				return 0

	// Фильтр на расы

	if(whitelisted_species.len)
		if(!(recipient.dna?.species.type in whitelisted_species))
			return 0
	if(blacklisted_species.len)
		if(recipient.dna?.species.type in blacklisted_species)
			return 0

	// Фильтр на профессии

	if(whitelisted_jobs.len)
		if(!(recipient.mind.assigned_role in whitelisted_jobs))
			return 0
	if(blacklisted_jobs.len)
		if(recipient.mind.assigned_role in blacklisted_jobs)
			return 0

	// Фильтр на гендер
	if(whitelisted_gender.len)
		if(!(recipient.gender in whitelisted_gender))
			return 0
	if(blacklisted_gender.len)
		if(recipient.gender in blacklisted_gender)
			return 0

	// Фильтр на майндшилд

	if(mindshield_prohibited && HAS_TRAIT(recipient, TRAIT_MINDSHIELD))
		return 0
	if(mindshield_required && !HAS_TRAIT(recipient, TRAIT_MINDSHIELD))
		return 0

	return .

/// Special effects of pattern, when envelope is opened
/datum/mail_pattern/proc/on_mail_open(mob/living/carbon/human/recipient)
	return

/datum/mail_pattern/misc
	category = MAIL_CATEGORY_MISC

/datum/mail_pattern/antag
	category = MAIL_CATEGORY_ANTAG

/datum/mail_pattern/money
	category = MAIL_CATEGORY_MONEY

/datum/mail_pattern/family
	category = MAIL_CATEGORY_FAMILY

/datum/mail_pattern/job
	category = MAIL_CATEGORY_JOB

/datum/mail_pattern/shop
	category = MAIL_CATEGORY_SHOP

/datum/mail_pattern/spam
	category = MAIL_CATEGORY_SPAM

/datum/mail_pattern/lewd
	category = MAIL_CATEGORY_LEWD

/datum/mail_pattern/lewd/special_open_check(mob/living/carbon/human/recipient)
	. = ..()
	if(!istype(recipient) || recipient.client?.prefs?.erppref == "No")
		return 0

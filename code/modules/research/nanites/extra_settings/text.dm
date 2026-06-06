/datum/nanite_extra_setting/text
	setting_type = NESTYPE_TEXT

/datum/nanite_extra_setting/text/New(initial)
	value = initial

/datum/nanite_extra_setting/text/set_value(value)
	// Strip control chars: a stray C0 byte in this value would break JSON.parse for
	// the whole nanite programmer extra-settings payload.
	src.value = trim(strip_control_chars(value))

/datum/nanite_extra_setting/text/get_copy()
	return new /datum/nanite_extra_setting/text(value)

/datum/nanite_extra_setting/text/get_value()
	// Kept html_encoded: consumers inject this into unescaped HTML/chat sinks
	// (brainwash objective shown to the victim, dermal button label, mood event).
	// Callers needing the raw value (the speech sensor's phrase match) html_decode it.
	return html_encode(value)

/datum/nanite_extra_setting/text/get_frontend_list(name)
	return list(list(
		"name" = name,
		"type" = setting_type,
		"value" = value
	))

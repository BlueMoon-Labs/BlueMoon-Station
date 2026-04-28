/datum/preferences
	var/body_weight = NAME_WEIGHT_NORMAL
	var/normalized_size = RESIZE_NORMAL
	var/custom_laugh = "Default"
	var/metadollars = 0
	var/metadollar_minute_pool = 0
	var/list/metadollar_pending_items = list()

/datum/preferences/vv_edit_var(var_name, var_value, massedit)
	if(var_name == NAMEOF(src, metadollars) || var_name == NAMEOF(src, metadollar_minute_pool) || var_name == NAMEOF(src, metadollar_pending_items))
		if(usr)
			to_chat(usr, span_warning("Метадоллары нельзя менять через VV. Используйте команду TGS <b>metadollars</b> (add / remove / set)."))
		log_admin("Metadollars: VV edit of [var_name] blocked for prefs [path || "no path"] by [key_name(usr)].")
		return FALSE
	return ..()

#define ACTION_HEADSHOT_LINK_NOOP 0
#define ACTION_HEADSHOT_LINK_REMOVE -1

#define HEADSHOT_LINK_MAX_LENGTH 400


/datum/preferences/process_link(mob/user, list/href_list)
	switch(href_list["preference"])
		if ("headshot")
			set_headshot_link(user, "headshot_link")
		if ("headshot1")
			set_headshot_link(user, "headshot_link1")
		if ("headshot2")
			set_headshot_link(user, "headshot_link2")
		if ("headshot_naked")
			set_headshot_link(user, "headshot_naked_link")
		if ("headshot_naked1")
			set_headshot_link(user, "headshot_naked_link1")
		if ("headshot_naked2")
			set_headshot_link(user, "headshot_naked_link2")
		if ("open_tattoo_manager")
			user.client?.open_tattoo_manager()

	return ..()


/datum/preferences/proc/set_headshot_link(mob/user, link_id)
	var/headshot_link = get_headshot_link(user, features[link_id])
	switch(headshot_link)
		if (ACTION_HEADSHOT_LINK_REMOVE)
			features[link_id] = null
			return
		if (ACTION_HEADSHOT_LINK_NOOP)
			return
		else
			if(features[link_id] == headshot_link)
				return

			to_chat(user, span_notice("Если картинка не отображается в игре должным образом, убедитесь, что это прямая ссылка на изображение, которая правильно открывается в обычном браузере."))
			to_chat(user, span_notice("Имейте в виду, что размер фотографии будет уменьшен до 256x256 пикселей, поэтому чем квадратнее фотография, тем лучше она будет выглядеть."))

			features[link_id] = headshot_link


/datum/preferences/proc/get_headshot_link(mob/user, old_link)
	var/usr_input = input(user, "Input the image link: (For Discord links, try putting the file's type at the end of the link, after the '&'. for example '&.jpg/.png/.jpeg/.gif/.webm/.mp4')", "Headshot Image", old_link) as text|null
	if(isnull(usr_input))
		return ACTION_HEADSHOT_LINK_NOOP

	if(!usr_input)
		return ACTION_HEADSHOT_LINK_REMOVE

	var/static/link_regex = regex("^https?://.*\\.(jpg|png|jpeg|gif|webm|mp4)(\[?#].*)?$", "i")

	if (length(usr_input) > HEADSHOT_LINK_MAX_LENGTH)
		to_chat(user, span_warning("The link is too long! Max length: [HEADSHOT_LINK_MAX_LENGTH] characters!"))
		return ACTION_HEADSHOT_LINK_NOOP

	if(!findtext(usr_input, link_regex))
		to_chat(user, span_warning("The link must be a direct http(s):// image/video URL ending with .png, .jpg, .jpeg, .gif, .webm, or .mp4!"))
		return ACTION_HEADSHOT_LINK_NOOP

	var/static/list/repl_chars = list("\n"="#","\t"="#","'"="","\""=""," "="")
	return sanitize(usr_input, repl_chars)


#undef HEADSHOT_LINK_MAX_LENGTH

#undef ACTION_HEADSHOT_LINK_NOOP
#undef ACTION_HEADSHOT_LINK_REMOVE

/// Renders a headshot preview tag. `link` must be pre-sanitized (it is interpolated directly into an HTML attribute).
/proc/headshot_preview_html(link, width = 140, height = 140)
	if(!link)
		return ""
	var/static/video_regex = regex("\\.(webm|mp4)(\[?#]|$)", "i")
	if(findtext(link, video_regex))
		return "<video src='[link]' autoplay loop muted playsinline style='border: 1px solid black; object-fit: contain;' width='[width]' height='[height]'></video>"
	return "<img src='[link]' style='border: 1px solid black; object-fit: contain;' width='[width]' height='[height]'>"

/datum/preferences/proc/mob_size_name_to_num(body_weight_name)
	switch(body_weight_name)
		if(NAME_WEIGHT_LIGHT)
			return MOB_WEIGHT_LIGHT
		if(NAME_WEIGHT_NORMAL)
			return MOB_WEIGHT_NORMAL
		if(NAME_WEIGHT_HEAVY)
			return MOB_WEIGHT_HEAVY
		if(NAME_WEIGHT_HEAVY_SUPER)
			return MOB_WEIGHT_HEAVY_SUPER
		else
			return MOB_WEIGHT_NORMAL

/datum/preferences/proc/mob_size_name_to_quirk_cost(body_weight_name)
	switch(body_weight_name)
		if(NAME_WEIGHT_HEAVY)
			return 1
		if(NAME_WEIGHT_HEAVY_SUPER)
			return 2
		else
			return 0

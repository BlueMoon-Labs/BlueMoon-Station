/datum/preferences
	var/body_weight = NAME_WEIGHT_NORMAL
	var/normalized_size = RESIZE_NORMAL
	var/custom_laugh = "Default"

#define ACTION_HEADSHOT_LINK_NOOP 0
#define ACTION_HEADSHOT_LINK_REMOVE -1

#define HEADSHOT_LINK_MAX_LENGTH 100


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
	var/usr_input = input(user, "Input the image link: (For Discord links, try putting the file's type at the end of the link, after the '&'. for example '&.jpg/.png/.jpeg')", "Headshot Image", old_link) as text|null
	if(isnull(usr_input))
		return ACTION_HEADSHOT_LINK_NOOP

	if(!usr_input)
		return ACTION_HEADSHOT_LINK_REMOVE

	var/static/link_regex = regex("^(https://i\\.gyazo\\.com|https://static1\\.e621\\.net|https://i\\.ibb\\.co/)")
	var/static/end_regex = regex("(\\.jpg|\\.png|\\.jpeg)$")

	if (length(usr_input) > HEADSHOT_LINK_MAX_LENGTH)
		to_chat(user, span_warning("The link is too long! Max length: [HEADSHOT_LINK_MAX_LENGTH] characters!"))
		return ACTION_HEADSHOT_LINK_NOOP

	if(!findtext(usr_input, link_regex))
		to_chat(user, span_warning("The link needs to be an unshortened Gyazo, iBB, E621 link!"))
		return ACTION_HEADSHOT_LINK_NOOP

	if(!findtext(usr_input, end_regex))
		to_chat(user, span_warning("You need either \".png\", \".jpg\", or \".jpeg\" in the end of the link!"))
		return ACTION_HEADSHOT_LINK_NOOP

	var/static/list/repl_chars = list("\n"="#","\t"="#","'"="","\""=""," "="")
	return sanitize(usr_input, repl_chars)


#undef HEADSHOT_LINK_MAX_LENGTH

#undef ACTION_HEADSHOT_LINK_NOOP
#undef ACTION_HEADSHOT_LINK_REMOVE

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

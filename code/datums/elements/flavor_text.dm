GLOBAL_LIST_EMPTY(mobs_with_editable_flavor_text) //et tu, hacky code

/datum/element/flavor_text
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH
	id_arg_index = 3
	var/flavor_name = "Flavor Text"
	var/list/texts_by_atom = list()
	var/addendum = ""
	var/always_show = FALSE
	var/show_on_naked = FALSE //SPLURT edit
	var/max_len = MAX_FLAVOR_LEN
	var/can_edit = TRUE
	/// For preference/DNA saving/loading. Null to prevent. Prefs are only loaded from obviously if it exists in preferences.features.
	var/save_key
	/// Do not attempt to render a preview on examine. If this is on, it will display as \[flavor_name\]
	var/examine_no_preview = FALSE
	/// Examine FULLY views. Overrides examine_no_preview
	var/examine_full_view = FALSE

/datum/element/flavor_text/Attach(datum/target, text = "", _name = "Flavor Text", _addendum, _max_len = MAX_FLAVOR_LEN, _always_show = FALSE, _edit = TRUE, _save_key, _examine_no_preview = FALSE, _show_on_naked)
	. = ..()

	if(. == ELEMENT_INCOMPATIBLE || !isatom(target)) //no reason why this shouldn't work on atoms too.
		return ELEMENT_INCOMPATIBLE

	if(_max_len)
		max_len = _max_len
	texts_by_atom[target] = copytext(text, 1, max_len)
	if(_name)
		flavor_name = _name
	if(!isnull(addendum))
		addendum = _addendum
	show_on_naked = _show_on_naked
	always_show = _always_show
	can_edit = _edit
	save_key = _save_key
	examine_no_preview = _examine_no_preview

	//RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(show_flavor)) BLUEMOON EDIT - перенос флаворов на хардкод

	if(can_edit && ismob(target)) //but only mobs receive the proc/verb for the time being
		var/mob/M = target
		LAZYOR(GLOB.mobs_with_editable_flavor_text[M], src)
		add_verb(M, /mob/proc/manage_flavor_tests)

	if(!save_key)
		return
	if(ishuman(target))
		RegisterSignal(target, COMSIG_HUMAN_PREFS_COPIED_TO, PROC_REF(update_prefs_flavor_text))
	else if(iscyborg(target))
		RegisterSignal(target, COMSIG_MOB_ON_NEW_MIND, PROC_REF(borged_update_flavor_text))
		RegisterSignal(target, COMSIG_MOB_CLIENT_JOINED_FROM_LOBBY, PROC_REF(borged_update_flavor_text))

/datum/element/flavor_text/Attach(datum/target, text = "", _name = "Flavor Text", _addendum, _max_len = MAX_FLAVOR_LEN, _always_show = FALSE, _edit = TRUE, _save_key, _examine_no_preview = FALSE, _show_on_naked)
	. = ..()
	if(flavor_name == "OOC Notes") //SPLURT EDIT make it so ooc notes are always visible
		always_show = TRUE

/datum/element/flavor_text/Detach(atom/A)
	. = ..()
	UnregisterSignal(A, list(COMSIG_PARENT_EXAMINE, COMSIG_HUMAN_PREFS_COPIED_TO, COMSIG_MOB_ON_NEW_MIND, COMSIG_MOB_CLIENT_JOINED_FROM_LOBBY))
	texts_by_atom -= A
	if(can_edit && ismob(A))
		var/mob/M = A
		LAZYREMOVE(GLOB.mobs_with_editable_flavor_text[M], src)
		if(!GLOB.mobs_with_editable_flavor_text[M])
			GLOB.mobs_with_editable_flavor_text -= M
			remove_verb(M, /mob/proc/manage_flavor_tests)

/datum/element/flavor_text/proc/show_flavor(atom/target, mob/user, list/examine_list)
	var/mob/living/L = target
	if(!always_show && isliving(target))
		var/unknown = L.get_visible_name() == "Unknown"
		if(!unknown && iscarbon(target))
			var/mob/living/carbon/C = L
			unknown = (C.wear_mask && (C.wear_mask.flags_inv & HIDEFACE) && !isobserver(user)) || (C.head && (C.head.flags_inv & HIDEFACE) && !isobserver(user)) //MASSIVE nonmodular edit. Has to be done here - Yawet330 / Making ghosts ignore gas-masks
			if(show_on_naked && ishuman(C))
				var/mob/living/carbon/human/H = C
				unknown = (unknown || (H.w_uniform || H.wear_suit))
		if(unknown)
			if(!("...?" in examine_list)) //can't think of anything better in case of multiple flavor texts.
				examine_list += "...?"
			return
	var/text = texts_by_atom[target]
	if(!text && !(flavor_name == "OOC Notes" && L.client))
		return
	if(examine_no_preview)
		examine_list += "<span class='notice'><a href='?src=[REF(src)];show_flavor=[REF(target)]'>\[[flavor_name]\]</a></span>"
		return
	var/msg = replacetext(text, "\n", " ")
	if(examine_full_view)
		examine_list += "[msg]"
		return
	if(length_char(msg) <= MAX_FLAVOR_PREVIEW_LEN)
		examine_list += "<span class='notice'>[msg]</span>"
	else
		examine_list += "<span class='notice'>[copytext_char(msg, 1, (MAX_FLAVOR_PREVIEW_LEN - 3))]... <a href='?src=[REF(src)];show_flavor=[REF(target)]'>More...</span></a>"

/datum/element/flavor_text/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["show_flavor"])
		var/atom/target = locate(href_list["show_flavor"])
		var/mob/living/L = target
		var/text = texts_by_atom[target]
		if((text || (flavor_name == "OOC Notes")) && L.client)
			var/content
			if(flavor_name == "OOC Notes")

				content += "[L]'s OOC Notes: <br> <b>ERP:</b> [L.client.prefs.erppref] <b>| Non-Con:</b> [L.client.prefs.nonconpref] <b>| Vore:</b> [L.client.prefs.vorepref] <b>| Mob Non-Con Sex:</b> [L.client.prefs.mobsexpref] <b>| Horny Antags:</b> [L.client.prefs.hornyantagspref]"

				if(L.client.prefs.unholypref == "Yes")
					content += " <b>| Unholy:</b> [L.client.prefs.unholypref]\n"
				else
					content += "\n"

//				content += " <b>| Stomping Interactions:</b> [L.client.prefs.stomppref ? "Yes" : "No"]\n"

				if(L.client.prefs.extremepref == "Yes")
					content += "<br><b>Extreme content:</b> [L.client.prefs.extremepref] <b>| Extreme content harm:</b> [L.client.prefs.extremeharm]\n"

				if(L.client.prefs.be_victim == BEVICTIM_ASK || L.client.prefs.be_victim == BEVICTIM_YES)
					content += "<br><b>Be antag victim:</b> [L.client.prefs.be_victim]\n"

				content += "\n"

			content += text
			if(flavor_name == "Headshot") //SPLURT edit
				content = "<center>"
				content += "[L]<br>"
				content += "<img class='icon icon-misc' src='[text]' height=500px width=500px><br>"
				content += "</center>"
				usr << browse("<HTML><HEAD><meta http-equiv='Content-Type' content='text/html; charset=utf-8'><TITLE>[isliving(target) ? L.get_visible_name() : target.name]</TITLE></HEAD><BODY><TT>[replacetext(content, "\n", "<BR>")]</TT></BODY></HTML>", "window=[isliving(target) ? L.get_visible_name() : target.name];size=600x500")
				onclose(usr, "[target.name]")
				return TRUE
			usr << browse("<HTML><HEAD><meta http-equiv='Content-Type' content='text/html; charset=utf-8'><TITLE>[isliving(target) ? L.get_visible_name() : target.name]</TITLE></HEAD><BODY><TT>[replacetext(content, "\n", "<BR>")]</TT></BODY></HTML>", "window=[isliving(target) ? L.get_visible_name() : target.name];size=500x200")
			onclose(usr, "[target.name]")
		return TRUE

// BLUEMOON EDIT START - заменил систему ингейм смены флаворов на более простую и релевантную
/mob/proc/manage_flavor_tests()
	set name = "Manage Flavor"
	set desc = "Used to manage your various flavor."
	set category = "IC"

	if(!isliving(src))
		return
	var/list/changeable_texts = list(
		"OOC-заметки",
		"Временный Флавор (Поза)"
	)
	if(iscarbon(src))
		var/mob/living/carbon/our_mob = src
		if(!our_mob.dna)
			return
		changeable_texts.Add("Флавор", "Обнажённый Флавор", "Лор Расы", "Хедшоты", "Хедшоты без одежды")

	else if(issilicon(src))
		if(!src.mind)
			return
		changeable_texts.Add("Синтетический флавор")

	var/chosen = tgui_input_list(src, "Выберите параметр, который должен быть изменён. Изменения действуют только в течении раунда и не затрагивают сами преференсы. Если вам нужно ввести многострочный текст с ENTER-ами, то лучше введите его вне игры и скопируйте сюда.", "Управление флавор-текстами", changeable_texts, changeable_texts[1])
	if(!chosen)
		return
	switch(chosen)
		if("Флавор")
			var/mob/living/carbon/our_mob = src
			var/new_text = tgui_input_text(our_mob, "Введите новый флавор (максимум [MAX_FLAVOR_LEN] символов).", "Новый флавор", our_mob.dna.flavor_text, MAX_FLAVOR_LEN, TRUE, TRUE)
			if(new_text)
				our_mob.dna.flavor_text = new_text
		if("Обнажённый Флавор")
			var/mob/living/carbon/our_mob = src
			var/new_text = tgui_input_text(our_mob, "Введите новый флавор обнажённого тела своего персонажа (максимум [MAX_FLAVOR_LEN] символов).", "Новый обнажённый флавор", our_mob.dna.naked_flavor_text, MAX_FLAVOR_LEN, TRUE, TRUE)
			if(new_text)
				our_mob.dna.naked_flavor_text = new_text
		if("Лор Расы")
			var/mob/living/carbon/our_mob = src
			var/new_text = tgui_input_text(our_mob, "Введите новый лор биологического (или не совсем биологического) вида своего персонажа (максимум [MAX_FLAVOR_LEN] символов).", "Новый лор расы", our_mob.dna.custom_species_lore, MAX_FLAVOR_LEN, TRUE, TRUE)
			if(new_text)
				our_mob.dna.custom_species_lore = new_text
		if("OOC-заметки")
			if(iscarbon(src))
				var/mob/living/carbon/our_mob = src
				var/new_text = tgui_input_text(our_mob, "Введите новые ООС-заметки своего персонажа (максимум [MAX_FLAVOR_LEN] символов).", "Новые ООС-заметки", our_mob.dna.ooc_notes, MAX_FLAVOR_LEN, TRUE, TRUE)
				if(new_text)
					our_mob.dna.ooc_notes = new_text
			if(issilicon(src))
				var/mob/living/silicon/our_borgy = src
				var/new_text = tgui_input_text(our_borgy, "Введите новые ООС-заметки своего киборга (максимум [MAX_FLAVOR_LEN] символов).", "Новые ООС-заметки", our_borgy.mind.ooc_notes, MAX_FLAVOR_LEN, TRUE, TRUE)
				if(new_text)
					our_borgy.mind.ooc_notes = new_text
		if("Хедшоты", "Хедшоты без одежды")
			var/mob/living/carbon/our_mob = src
			var/chosen_headshot_id = tgui_input_list(our_mob, "Выберите номер хедшота, который хотите изменить.", "Управление флавор-текстами", list("1", "2", "3"), "1")
			// var/max_headshots = 3
			if(!chosen_headshot_id || !isnum(text2num(chosen_headshot_id)))
				return
			chosen_headshot_id = text2num(chosen_headshot_id)
			var/list/headshots = chosen == "Хедшоты без одежды" ? our_mob.dna.headshot_naked_links : our_mob.dna.headshot_links
			var/has_headshot_id = chosen_headshot_id <= headshots.len
			var/usr_input = tgui_input_text(our_mob, "Input the image link: (For Discord links, try putting the file's type at the end of the link, after the '&'. for example '&.jpg/.png/.jpeg')", "Headshot Image", has_headshot_id ? headshots[chosen_headshot_id] : "", 100, FALSE, FALSE)
			if(isnull(usr_input))
				return

			if(!usr_input && has_headshot_id)
				headshots[chosen_headshot_id] = null
				listclearnulls(headshots)
				return

			var/static/link_regex = regex("^(https://i\\.gyazo\\.com|https://static1\\.e621\\.net|https://i\\.ibb\\.co/)")
			var/static/end_regex = regex("(\\.jpg|\\.png|\\.jpeg)$")

			if(!findtext(usr_input, link_regex))
				to_chat(our_mob, span_warning("The link needs to be an unshortened Gyazo, iBB, E621 link!"))
				return

			if(!findtext(usr_input, end_regex))
				to_chat(our_mob, span_warning("You need either \".png\", \".jpg\", or \".jpeg\" in the end of the link!"))
				return

			var/static/list/repl_chars = list("\n"="#","\t"="#","'"="","\""=""," "="")
			var/new_link = sanitize(usr_input, repl_chars)
			if(has_headshot_id && headshots[chosen_headshot_id] == new_link)
				return

			to_chat(our_mob, span_notice("Если картинка не отображается в игре должным образом, убедитесь, что это прямая ссылка на изображение, которая правильно открывается в обычном браузере."))
			to_chat(our_mob, span_notice("Имейте в виду, что размер фотографии будет уменьшен до 256x256 пикселей, поэтому чем квадратнее фотография, тем лучше она будет выглядеть."))

			if(has_headshot_id)
				headshots[chosen_headshot_id] = new_link
			else
				LAZYADD(headshots, new_link)
		if("Временный Флавор (Поза)")
			var/mob/living/our_mob = src
			var/new_text = tgui_input_text(our_mob, "Введите новую позу своего персонажа (максимум 1024 символа).", "Новая поза", our_mob.tempflavor, 1024, TRUE, TRUE)
			our_mob.tempflavor = new_text
		if("Синтетический флавор")
			var/mob/living/silicon/our_borgy = src
			if(our_borgy.mind)
				var/new_text = tgui_input_text(our_borgy, "Введите новый синт-флавор (максимум [MAX_FLAVOR_LEN] символов). Изменения действуют только в течении раунда и не затрагивают сами преференсы.", "Новый синт-флавор", our_borgy.mind.silicon_flavor_text, MAX_FLAVOR_LEN, TRUE, TRUE)
				if(new_text)
					our_borgy.mind.silicon_flavor_text = new_text
// BLUEMOON EDIT END

/mob/proc/set_pose()
	set name = "Set Pose"
	set desc = "Sets your temporary flavor text"
	set category = "Say"
	// BLUEMOON EDIT START - перенос темпфлавора на хардкод
	var/mob/living/our_mob = src

	if(!istype(our_mob))
		return
	var/new_text = tgui_input_text(our_mob, "Введите новую позу своего персонажа (максимум 1024 символа).", "Новая поза", our_mob.tempflavor, 1024, TRUE, TRUE)
	our_mob.tempflavor = new_text

	/*
	var/list/L = GLOB.mobs_with_editable_flavor_text[src]
	var/datum/element/flavor_text/carbon/temporary/T
	for(var/i in L)
		if(istype(i, /datum/element/flavor_text/carbon/temporary))
			T = i
	if(!T)
		to_chat(src, "<span class='warning'>Your mob type does not support temporary flavor text.</span>")
		return
	T.set_flavor(src)
	*/

/datum/element/flavor_text/proc/set_flavor(mob/user)
	if(!(user in texts_by_atom))
		return FALSE

	var/lower_name = lowertext(flavor_name)
	var/new_text = stripped_multiline_input(user, "Set the [lower_name] displayed on 'examine'. [addendum]", flavor_name, html_decode(texts_by_atom[usr]), max_len, TRUE)
	if(!isnull(new_text) && (user in texts_by_atom))
		texts_by_atom[user] = new_text
		to_chat(src, "Your [lower_name] has been updated.")
		return TRUE
	return FALSE

/datum/element/flavor_text/proc/update_prefs_flavor_text(mob/living/carbon/human/H, datum/preferences/P, icon_updates = TRUE, roundstart_checks = TRUE)
	if(P.features.Find(save_key))
		texts_by_atom[H] = P.features[save_key]

/datum/element/flavor_text/proc/borged_update_flavor_text(mob/new_character, client/C)
	C = C || GET_CLIENT(new_character)
	if(!C)
		LAZYSET(texts_by_atom, new_character, "")
		return
	var/datum/preferences/P = C.prefs
	if(!P)
		LAZYSET(texts_by_atom, new_character, "")
		return
	if(P.custom_names["cyborg"] == new_character.real_name)
		LAZYSET(texts_by_atom, new_character, P.features[save_key])
	else
		LAZYSET(texts_by_atom, new_character, "")

//subtypes with additional hooks for DNA and preferences.
/datum/element/flavor_text/carbon
	//list of antagonists etcetera that should have nothing to do with people's snowflakes.
	var/static/list/i_dont_even_know_who_you_are = typecacheof(list(/datum/antagonist/abductor, /datum/antagonist/ert,
													/datum/antagonist/nukeop, /datum/antagonist/wizard))

/datum/element/flavor_text/carbon/Attach(datum/target, text = "", _name = "Flavor Text", _addendum, _max_len = MAX_FLAVOR_LEN, _always_show = FALSE, _edit = TRUE, _save_key, _examine_no_preview = FALSE, _show_on_naked)
	if(!iscarbon(target))
		return ELEMENT_INCOMPATIBLE
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE)
		return
	RegisterSignal(target, COMSIG_CARBON_IDENTITY_TRANSFERRED_TO, PROC_REF(update_dna_flavor_text))
	RegisterSignal(target, COMSIG_MOB_ANTAG_ON_GAIN, PROC_REF(on_antag_gain))
	if(ishuman(target))
		RegisterSignal(target, COMSIG_HUMAN_HARDSET_DNA, PROC_REF(update_dna_flavor_text))
		RegisterSignal(target, COMSIG_HUMAN_ON_RANDOMIZE, PROC_REF(unset_flavor))

/datum/element/flavor_text/carbon/Detach(mob/living/carbon/C)
	. = ..()
	UnregisterSignal(C, list(COMSIG_CARBON_IDENTITY_TRANSFERRED_TO, COMSIG_MOB_ANTAG_ON_GAIN, COMSIG_HUMAN_PREFS_COPIED_TO, COMSIG_HUMAN_HARDSET_DNA, COMSIG_HUMAN_ON_RANDOMIZE))

/datum/element/flavor_text/carbon/proc/update_dna_flavor_text(mob/living/carbon/C)
	texts_by_atom[C] = C.dna.features[save_key]

/datum/element/flavor_text/carbon/set_flavor(mob/living/carbon/user)
	. = ..()
	if(. && user.dna)
		user.dna.features[save_key] = texts_by_atom[user]

/datum/element/flavor_text/carbon/proc/unset_flavor(mob/living/carbon/user)
	texts_by_atom[user] = ""

/datum/element/flavor_text/carbon/proc/on_antag_gain(mob/living/carbon/user, datum/antagonist/antag)
	if(is_type_in_typecache(antag, i_dont_even_know_who_you_are))
		texts_by_atom[user] = ""
		if(user.dna)
			user.dna.features[save_key] = ""

/datum/element/flavor_text/carbon/temporary
	examine_full_view = TRUE
	max_len = 1024

/datum/element/flavor_text/carbon/temporary/Attach(datum/target, text, _name, _addendum, _max_len, _always_show, _edit, _save_key, _examine_no_preview)
	. = ..()
	if(. & ELEMENT_INCOMPATIBLE)
		return
	if(ismob(target))
		add_verb(target, /mob/proc/set_pose)

/datum/element/flavor_text/carbon/temporary/Detach(datum/source, force)
	. = ..()
	if(ismob(source))
		remove_verb(source, /mob/proc/set_pose)

/**
 * Админский инструмент подмены параллакса.
 *
 * Работает через тот же стек модификаторов, что и события, под выделенным
 * токеном PARALLAX_TOKEN_ADMIN. Поэтому админская подмена и событие не сбивают
 * друг друга: снятие любой из них пересобирает сцену из того, что осталось.
 */
/client/proc/set_parallax_profile()
	set category = "Debug.7) Testing"
	set name = "Set Parallax Profile"
	if(!check_rights(R_DEBUG))
		return

	var/turf/eye_turf = get_turf(eye)
	if(!eye_turf)
		to_chat(src, span_warning("Не удалось определить z-уровень: глаз в нигде."))
		return
	var/target_z = eye_turf.z

	var/list/options = list()
	for(var/profile_id in SSparallax.profiles_by_id)
		var/datum/parallax_profile/profile = SSparallax.profiles_by_id[profile_id]
		options["[profile.name] ([profile_id])"] = profile_id

	var/datum/parallax_profile/current = SSparallax.get_base_profile(target_z)
	var/list/menu = list("- вернуть исходный -") + sort_list(options)
	var/choice = input(src, "z [target_z], сейчас: [current?.name || "нет"]", "Профиль параллакса") as null|anything in menu
	if(!choice)
		return

	if(choice == "- вернуть исходный -")
		if(SSparallax.restore_profile(target_z, PARALLAX_TOKEN_ADMIN, 1 SECONDS))
			message_admins("[key_name_admin(src)] вернул исходный параллакс на z [target_z].")
			log_admin("[key_name(src)] restored parallax on z [target_z].")
		else
			to_chat(src, span_notice("На z [target_z] и так исходный профиль."))
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Set Parallax Profile")
		return

	var/chosen_id = options[choice]
	SSparallax.set_profile(target_z, chosen_id, PARALLAX_TOKEN_ADMIN, PARALLAX_PRIORITY_ADMIN, 1 SECONDS)
	message_admins("[key_name_admin(src)] поставил профиль параллакса '[chosen_id]' на z [target_z].")
	log_admin("[key_name(src)] set parallax profile '[chosen_id]' on z [target_z].")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Set Parallax Profile")

/// Показывает, из чего сейчас собрана сцена на текущем z - профиль, слои и стек модификаторов.
/client/proc/show_parallax_state()
	set category = "Debug.7) Testing"
	set name = "Show Parallax State"
	if(!check_rights(R_DEBUG))
		return

	var/turf/eye_turf = get_turf(eye)
	if(!eye_turf)
		to_chat(src, span_warning("Не удалось определить z-уровень: глаз в нигде."))
		return
	var/target_z = eye_turf.z

	var/datum/parallax/template = SSparallax.get_parallax_template(target_z)
	var/list/report = list("<b>Параллакс z [target_z]</b>")
	report += "Базовый профиль: [SSparallax.get_base_profile(target_z)?.id || "нет"]"
	report += "Действующий профиль: [template?.profile_id || "нет"], ревизия [template?.revision]"
	// Без этой строки отсев по окружению выглядит как пропавшие слои: профиль их
	// объявляет, а в собранной сцене их нет.
	var/environment = SSparallax.environment_for_z(target_z)
	report += "Окружение: [SSparallax.environment_name(environment)] - слои, которым оно не подходит, в сцену не попадают"

	var/list/stack = SSparallax.modifiers_by_z["[target_z]"]
	if(length(stack))
		report += "<b>Модификаторы:</b>"
		for(var/datum/parallax_modifier/modifier as anything in stack)
			report += "&nbsp;&nbsp;'[modifier.token]' приоритет [modifier.priority], профиль [modifier.profile?.id || "-"], слоёв [length(modifier.extra_layers)], цвет [modifier.tint || "-"]"
	else
		report += "Модификаторов нет."

	var/moving = 0
	if(template)
		report += "<b>Слои ([length(template.objects)]):</b>"
		for(var/atom/movable/screen/parallax_layer/layer as anything in template.objects)
			var/mode_name
			switch(layer.layer_mode)
				if(PARALLAX_MODE_TILED)
					mode_name = "тайл [layer.tile_size]"
					moving++
				if(PARALLAX_MODE_SKYBOX)
					mode_name = "скайбокс [layer.tile_size]"
				if(PARALLAX_MODE_STATIC)
					mode_name = "объект"
				if(PARALLAX_MODE_OVERLAY)
					mode_name = "тонировка"
			report += "&nbsp;&nbsp;[layer.type] - '[layer.icon_state]', [mode_name], скорость [layer.speed], качество [layer.parallax_intensity]"
		report += "Движущихся слоёв: [moving] из [PARALLAX_MAX_MOVING_LAYERS] допустимых."

	to_chat(src, examine_block(report.Join("<br>")))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Show Parallax State")

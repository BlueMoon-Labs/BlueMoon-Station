/proc/bm_tgs_get_prefs_for_ckey(target_ckey)
	var/key = ckey(target_ckey)
	if(!key)
		return null
	var/client/online = GLOB.directory[key]
	if(online?.prefs)
		return list("prefs" = online.prefs, "offline" = FALSE)
	var/datum/preferences/P = new
	P.load_path(key)
	if(!P.load_preferences(TRUE))
		return null
	return list("prefs" = P, "offline" = TRUE)

/// Returns TRUE if cleanup ok and (when save) disk write succeeded.
/proc/bm_tgs_finish_prefs_edit(list/ctx, save = TRUE)
	if(!ctx)
		return FALSE
	var/datum/preferences/P = ctx["prefs"]
	if(save && !P.save_preferences(TRUE, TRUE))
		if(ctx["offline"])
			qdel(P)
		return FALSE
	if(ctx["offline"])
		qdel(P)
	return TRUE

/datum/tgs_chat_command/metadollars
	name = "metadollars"
	help_text = "Использование: metadollars (add ckey сумма | remove ckey сумма | set ckey сумма | balance ckey)"
	admin_only = TRUE

/datum/tgs_chat_command/metadollars/Run(datum/tgs_chat_user/sender, params)
	var/list/parts = splittext(params, " ")
	if(!length(parts) || !parts[1])
		return new /datum/tgs_message_content(src.help_text)

	switch(lowertext(parts[1]))
		if("add")
			if(length(parts) < 3)
				return new /datum/tgs_message_content("Укажите: metadollars add <ckey> <сумма>")
			var/key = ckey(parts[2])
			var/amt = text2num(parts[3])
			if(!isnum(amt) || round(amt) != amt || amt <= 0)
				return new /datum/tgs_message_content("Неверная сумма: нужно целое число больше нуля.")
			var/list/ctx = bm_tgs_get_prefs_for_ckey(key)
			if(!ctx)
				return new /datum/tgs_message_content("Не удалось загрузить префы для `[key]` (нет savefile или неверный ckey).")
			var/datum/preferences/P = ctx["prefs"]
			var/old_bal = P.metadollars
			P.metadollars = max(0, round(P.metadollars + amt))
			var/new_bal = P.metadollars
			if(!bm_tgs_finish_prefs_edit(ctx, TRUE))
				return new /datum/tgs_message_content("Не удалось сохранить префы на диск для `[key]` (проверьте data/player_saves и лог сервера). Баланс в памяти был бы [new_bal] М$.")
			log_admin("TGS метадоллары: [sender.friendly_name] (id [sender.id]) ADD [amt] М$ → [key]: [old_bal] -> [new_bal].")
			message_admins("TGS: [sender.friendly_name] начислил [amt] М$ игроку [key] (сейчас [new_bal] М$).")
			return new /datum/tgs_message_content("Начислено [amt] М$ игроку `[key]`. Баланс: [old_bal] → [new_bal] М$.")

		if("remove")
			if(length(parts) < 3)
				return new /datum/tgs_message_content("Укажите: metadollars remove <ckey> <сумма>")
			var/key = ckey(parts[2])
			var/amt = text2num(parts[3])
			if(!isnum(amt) || round(amt) != amt || amt <= 0)
				return new /datum/tgs_message_content("Неверная сумма: нужно целое число больше нуля.")
			var/list/ctx = bm_tgs_get_prefs_for_ckey(key)
			if(!ctx)
				return new /datum/tgs_message_content("Не удалось загрузить префы для `[key]` (нет savefile или неверный ckey).")
			var/datum/preferences/P = ctx["prefs"]
			var/old_bal = P.metadollars
			P.metadollars = max(0, round(P.metadollars - amt))
			var/new_bal = P.metadollars
			if(!bm_tgs_finish_prefs_edit(ctx, TRUE))
				return new /datum/tgs_message_content("Не удалось сохранить префы на диск для `[key]`. Баланс в памяти был бы [new_bal] М$.")
			log_admin("TGS метадоллары: [sender.friendly_name] (id [sender.id]) REMOVE [amt] М$ у [key]: [old_bal] -> [new_bal].")
			message_admins("TGS: [sender.friendly_name] снял [amt] М$ у [key] (сейчас [new_bal] М$).")
			return new /datum/tgs_message_content("Снято [amt] М$ у `[key]`. Баланс: [old_bal] → [new_bal] М$.")

		if("set")
			if(length(parts) < 3)
				return new /datum/tgs_message_content("Укажите: metadollars set <ckey> <сумма>")
			var/key = ckey(parts[2])
			var/amt = text2num(parts[3])
			if(!isnum(amt) || round(amt) != amt || amt < 0)
				return new /datum/tgs_message_content("Неверная сумма: нужно неотрицательное целое число.")
			var/list/ctx = bm_tgs_get_prefs_for_ckey(key)
			if(!ctx)
				return new /datum/tgs_message_content("Не удалось загрузить префы для `[key]` (нет savefile или неверный ckey).")
			var/datum/preferences/P = ctx["prefs"]
			var/old_bal = P.metadollars
			P.metadollars = max(0, round(amt))
			var/new_bal = P.metadollars
			if(!bm_tgs_finish_prefs_edit(ctx, TRUE))
				return new /datum/tgs_message_content("Не удалось сохранить префы на диск для `[key]`. Баланс в памяти был бы [new_bal] М$.")
			log_admin("TGS метадоллары: [sender.friendly_name] (id [sender.id]) SET [key] = [new_bal] М$ (было [old_bal]).")
			message_admins("TGS: [sender.friendly_name] выставил [key] баланс [new_bal] М$ (было [old_bal]).")
			return new /datum/tgs_message_content("Баланс `[key]` установлен: [new_bal] М$ (было [old_bal]).")

		if("balance")
			if(length(parts) < 2)
				return new /datum/tgs_message_content("Укажите: metadollars balance <ckey>")
			var/key = ckey(parts[2])
			var/list/ctx = bm_tgs_get_prefs_for_ckey(key)
			if(!ctx)
				return new /datum/tgs_message_content("Не удалось загрузить префы для `[key]` (нет savefile или неверный ckey).")
			var/datum/preferences/P = ctx["prefs"]
			var/bal = P.metadollars
			if(!bm_tgs_finish_prefs_edit(ctx, FALSE))
				return new /datum/tgs_message_content("Внутренняя ошибка при закрытии префов для `[key]`.")
			return new /datum/tgs_message_content("`[key]` — баланс: [bal] М$.")

		else
			return new /datum/tgs_message_content("Неизвестная подкоманда. [src.help_text]")

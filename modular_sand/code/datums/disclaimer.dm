/client
	var/disclaimer_shown = FALSE
	var/datum/disclaimer/disclaimer

/client/proc/show_disclaimer(auto_show = FALSE)
	if(QDELETED(src) || !mob)
		return
	if(QDELETED(disclaimer))
		disclaimer = new()
	disclaimer.accept_required = auto_show && !prefs?.bm_disclaimer_accepted
	if(!disclaimer.ui_interact(mob))
		addtimer(CALLBACK(src, TYPE_PROC_REF(/client, show_disclaimer), auto_show), 1 SECONDS)

/datum/disclaimer
	var/accept_required = FALSE
	var/title_text = "ДИСКЛЕЙМЕР"
	var/body_text = "Добро пожаловать на наш проект!\n\nМы — сервер с взрослым контентом (SERP). Наш главный фокус — свобода самовыражения: здесь вы можете быть собой, отыгрывать любые роли и находить единомышленников. Мы ценим весёлую, расслабленную и дружелюбную атмосферу и стараемся поддерживать её каждый раунд.\n\nПомните, что это всего лишь игра про космонавтиков. Всё, что происходит на станции, остаётся на станции и не имеет отношения к реальному миру.\n\nНе связывайте своего персонажа с собой. Вы отыгрываете роль, а не являетесь ею — и ваши собеседники делают то же самое.\n\nНа сервере действуют внутриигровые правила, Космический Закон (КЗ) и правила НРП. Полные тексты документов доступны по ссылкам ниже.\n\nОтноситесь к другим игрокам с уважением. Любые конфликты остаются в раунде и не переносятся в реальную жизнь.\n\nВсе персонажи и события являются вымышленными, а любые взрослые взаимодействия происходят только по взаимному согласию сторон.\n\nНужна помощь или вы заметили нарушение правил? Администрация всегда на связи — не бойтесь обращаться."
	var/list/link_list = list(
		list("name" = "Дискорд-Сервер", "url" = "https://discord.com/invite/ss13-bluemoon"),
		list("name" = "Внутриигровые Правила", "url" = "https://docs.google.com/document/d/15vlHyQC9YwyAQWrTzm6yACHnmaPYPzYr4t-1XByF-yo/edit?usp=sharing"),
		list("name" = "КЗ", "url" = "https://docs.google.com/document/d/1PPTvirk_GqQprhiMLr_2z1QWA2bcXw0cSkV9KWWziMg/edit?tab=t.0"),
		list("name" = "НРП", "url" = "https://docs.google.com/document/d/10EI9HMp0KBxCns_1wJzdzh4JZDxQFj_0OUt4CV3_aSs/edit?usp=sharing"),
		list("name" = "Лор", "url" = "https://discord.com/channels/875735187449847830/1388821733506683012/1388821733506683012")
	)

/datum/disclaimer/ui_state(mob/user)
	return GLOB.always_state

/datum/disclaimer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Disclaimer")
		return ui.open()
	return TRUE

/datum/disclaimer/ui_data(mob/user)
	. = ..()
	.["title"] = title_text
	.["body"] = body_text
	.["links"] = link_list
	.["show_accept"] = accept_required

/datum/disclaimer/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("open_link")
			ui.user << link(params["url"])
			return TRUE
		if("accept")
			var/client/user_client = ui.user.client
			if(user_client?.prefs)
				user_client.prefs.bm_disclaimer_accepted = TRUE
				user_client.prefs.save_preferences()
			ui.close()
			return TRUE
		if("close")
			if(accept_required)
				return TRUE
			ui.close()
			return TRUE

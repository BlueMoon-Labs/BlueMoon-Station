/client
	var/disclaimer_shown = FALSE

/client/proc/show_disclaimer()
	if(QDELETED(src) || !mob)
		return
	var/datum/disclaimer/disclaimer = new()
	if(!disclaimer.ui_interact(mob))
		addtimer(CALLBACK(src, TYPE_PROC_REF(/client, show_disclaimer)), 1 SECONDS)

/datum/disclaimer
	var/title_text = "ДИСКЛЕЙМЕР"
	var/body_text = "Этот сервер строго для лиц, достигших 18 лет. Подключаясь к нему, вы подтверждаете свой возраст и соглашаетесь со всеми правилами проекта.\n\nПомните, что это всего лишь игра про космонавтиков. Всё, что происходит на станции, остаётся на станции и не имеет отношения к реальному миру.\n\nНе связывайте своего персонажа с собой. Вы отыгрываете роль, а не являетесь ею - и ваши собеседники делают то же самое.\n\nНа сервере действуют внутриигровые правила, Космический Закон (КЗ) и правила НРП. Полные тексты документов доступны по ссылкам ниже.\n\nОтноситесь к другим игрокам с уважением. Любые конфликты остаются в раунде и не переносятся в реальную жизнь.\n\nСервер содержит взрослый контент. Все персонажи и события являются вымышленными, а любые взаимодействия происходят только по взаимному согласию сторон.\n\nНужна помощь или вы заметили нарушение правил? Администрация всегда на связи - не бойтесь обращаться."
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

/datum/disclaimer/ui_act(action, params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	switch(action)
		if("open_link")
			ui.user << link(params["url"])
			return TRUE
		if("close")
			ui.close()
			return TRUE

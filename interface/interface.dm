//Please use mob or src (not usr) in these procs. This way they can be called in the same fashion as procs.
/client/verb/wiki()
	set name = "wiki"
	set desc = "Type what you want to know about.  This will open the wiki in your web browser. Type nothing to go to the main page."
	set hidden = 1
	var/wikiurl = CONFIG_GET(string/wikiurl)
	if(!wikiurl)
		to_chat(src, "<span class='danger'>The wiki URL is not set in the server configuration.</span>")
		return
	var/query = tgui_input_text(src, "Введите, о чём хотите узнать. Откроется вики в вашем браузере. Пустое поле — главная страница.", "wiki")
	if(isnull(query))
		return
	if(query)
		var/output = wikiurl + "/index.php?title=Служебная:Поиск&search=" + query
		src << link(output)
	else
		src << link(wikiurl)
	return

/client/verb/discord()
	set name = "discord"
	set desc = "Join the discord."
	set hidden = 1
	var/discordurl = CONFIG_GET(string/discordurl)
	if(discordurl)
		if(tgui_alert(src, "Это откроет приглашение Discord в вашем браузере. Вы уверены?", "Discord", list("Да", "Нет")) != "Да")
			return
		src << link(discordurl)
	else
		to_chat(src, "<span class='danger'>The discord invite URL is not set in the server configuration.</span>")
	return

/client/verb/rules()
	set name = "rules"
	set desc = "Show Server Rules."
	set hidden = 1
	var/rulesurl = CONFIG_GET(string/rulesurl)
	if(rulesurl)
		if(tgui_alert(src, "Это откроет правила в вашем браузере. Вы уверены?", "Rules", list("Да", "Нет")) != "Да")
			return
		src << link(rulesurl)
	else
		to_chat(src, "<span class='danger'>The rules URL is not set in the server configuration.</span>")
	return

/client/verb/github()
	set name = "github"
	set desc = "Visit Github"
	set hidden = 1
	var/githuburl = CONFIG_GET(string/githuburl)
	if(githuburl)
		if(tgui_alert(src, "Это откроет репозиторий Github в вашем браузере. Вы уверены?", "Github", list("Да", "Нет")) != "Да")
			return
		src << link(githuburl)
	else
		to_chat(src, "<span class='danger'>The Github URL is not set in the server configuration.</span>")
	return

/client/verb/reportissue()
	set name = "report-issue"
	set desc = "Report an issue"
	set hidden = 1
	var/reportissue = CONFIG_GET(string/reportissue)
	var/message
	if(reportissue)
		message = "Это откроет репортер проблем в вашем браузере. Вы уверены?"
		if(GLOB.revdata.testmerge.len)
			message += "\nАктивные экспериментальные изменения (тест-мерджи) — возможная причина новых проблем. По возможности найдите конкретный тред вместо общего трекера:\n"
			message += strip_html_tags(replacetext(GLOB.revdata.GetTestMergeInfo(FALSE), "<br>", "\n"))
		if(tgui_alert(src, message, "Report Issue", list("Да", "Нет")) != "Да")
			return
		src << link(reportissue)
		return

	var/githuburl = CONFIG_GET(string/githuburl)
	if(githuburl)
		message = "Это откроет репортер проблем Github в вашем браузере. Вы уверены?"
		if(GLOB.revdata.testmerge.len)
			message += "\nАктивные экспериментальные изменения (тест-мерджи) — возможная причина новых проблем. По возможности найдите конкретный тред вместо общего трекера:\n"
			message += strip_html_tags(replacetext(GLOB.revdata.GetTestMergeInfo(FALSE), "<br>", "\n"))
		if(tgui_alert(src, message, "Report Issue", list("Да", "Нет")) != "Да")
			return
		var/static/issue_template = file2text(".github/ISSUE_TEMPLATE.md")
		var/servername = CONFIG_GET(string/servername)
		var/url_params = "Reporting client version: [byond_version].[byond_build]\n\n[issue_template]"
		if(GLOB.round_id || servername)
			url_params = "Issue reported from [GLOB.round_id ? " Round ID: [GLOB.round_id][servername ? " ([servername])" : ""]" : servername]\n\n[url_params]"
		DIRECT_OUTPUT(src, link("[githuburl]/issues/new?body=[url_encode(url_params)]"))
	else
		to_chat(src, "<span class='danger'>The Github URL is not set in the server configuration.</span>")
	return

/client/verb/changelog()
	set name = "Changelog"
	set category = "OOC"
	if(!GLOB.changelog_tgui)
		GLOB.changelog_tgui = new /datum/changelog()

	if(!mob)
		return
	GLOB.changelog_tgui.ui_interact(mob)
	if(prefs.lastchangelog != GLOB.changelog_hash)
		prefs.lastchangelog = GLOB.changelog_hash
		prefs.save_pref_var("lastchangelog")
		winset(src, "infowindow.changelog", "font-style=;")

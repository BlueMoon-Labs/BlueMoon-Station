// Нашлемный просмотр новостных каналов для призраков.
// Старое окно на datum/browser заменено на tgui.

/mob/dead/observer
	var/datum/news_browser/news_browser

/mob/dead/observer/verb/read_news()
	set name = "Read Newscaster"
	set desc = "Open a list of available news channels"
	set category = "Ghost"

	if(QDELETED(news_browser))
		news_browser = new(src)
	news_browser.ui_interact(src)

/// Держит состояние просмотра новостей (выбранный канал) и кэш фотографий.
/datum/news_browser
	var/mob/dead/observer/owner
	var/datum/news/feed_channel/channel
	var/list/base64_cache = list()

/datum/news_browser/New(mob/dead/observer/_owner)
	owner = _owner
	return ..()

/datum/news_browser/Destroy()
	owner = null
	channel = null
	base64_cache = null
	return ..()

/datum/news_browser/ui_state(mob/user)
	return GLOB.observer_state

/datum/news_browser/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NewsChannels", "Каналы новостей")
		ui.open()

/datum/news_browser/ui_data(mob/user)
	var/list/data = list()
	if(QDELETED(channel))
		channel = null

	var/list/channels = list()
	for(var/datum/news/feed_channel/FC in GLOB.news_network.network_channels)
		channels += list(list(
			"ref" = REF(FC),
			"name" = FC.channel_name,
			"messages" = length(FC.messages),
			"locked" = !!FC.locked,
			"censored" = !!FC.censored,
			"admin" = !!FC.is_admin_channel,
		))
	data["channels"] = channels
	data["selected"] = channel ? REF(channel) : null

	var/list/messages = list()
	if(channel)
		data["channelName"] = channel.channel_name
		data["channelAuthor"] = channel.returnAuthor(-1)
		data["channelCensored"] = !!channel.censored
		for(var/datum/news/feed_message/FM in channel.messages)
			var/list/comments = list()
			for(var/datum/news/feed_comment/comment in FM.comments)
				comments += list(list(
					"body" = comment.body,
					"author" = comment.author,
					"time" = comment.time_stamp,
				))
			var/image_data = null
			if(FM.img)
				var/key = REF(FM)
				var/encoded = base64_cache[key]
				if(!encoded)
					encoded = icon2base64(FM.img)
					base64_cache[key] = encoded
				if(encoded)
					image_data = "data:image/png;base64,[encoded]"
			messages += list(list(
				"body" = tgui_news_text(FM.returnBody(-1)),
				"author" = FM.returnAuthor(-1),
				"time" = FM.time_stamp,
				"image" = image_data,
				"caption" = FM.caption,
				"comments" = comments,
				"locked" = !!FM.locked,
			))
	data["messages"] = messages
	return data

/datum/news_browser/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("select")
			var/datum/news/feed_channel/FC = locate(params["channel"])
			if(!istype(FC) || !(FC in GLOB.news_network.network_channels))
				return
			channel = FC
			return TRUE
		if("back")
			channel = null
			return TRUE

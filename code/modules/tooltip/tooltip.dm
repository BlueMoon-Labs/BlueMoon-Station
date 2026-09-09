/*
Tooltips v1.1 - 22/10/15
Developed by Wire (#goonstation on irc.synirc.net)
- Added support for screen_loc pixel offsets. Should work. Maybe.
- Added init function to more efficiently send base vars

Configuration:
- Set control to the correct skin element (remember to actually place the skin element)
- Set file to the correct path for the .html file (remember to actually place the html file)
- Attach the datum to the user client on login, e.g.
	/client/New()
		src.tooltips = new /datum/tooltip(src)

Usage:
- Define mouse event procs on your (probably HUD) object and simply call the show and hide procs respectively:
	/atom/movable/screen/hud
		MouseEntered(location, control, params)
			usr.client.tooltip.show(params, title = src.name, content = src.desc)

		MouseExited()
			usr.client.tooltip.hide()

Customization:
- Theming can be done by passing the theme var to show() and using css in the html file to change the look
- For your convenience some pre-made themes are included

Notes:
- You may have noticed 90% of the work is done via javascript on the client. Gotta save those cycles man.
- This is entirely untested in any other codebase besides goonstation so I have no idea if it will port nicely. Good luck!
	- After testing and discussion (Wire, Remie, MrPerson, AnturK) ToolTips are ok and work for /tg/station13
*/


/// Сколько ждём загрузки browse()-страницы окна, прежде чем слать в неё первый показ.
/// Страница едет клиенту асинхронно, а output() в ещё не загруженный документ теряется молча.
#define TOOLTIP_PAGE_LOAD_GRACE (1 SECONDS)

/datum/tooltip
	var/client/owner
	var/control = "mainwindow.tooltip"
	var/showing = 0
	var/queueHide = 0
	/// world.time момента, когда странице окна отправили browse()
	var/page_sent_at = 0
	/// Готовая строка показа, придержанная на время загрузки страницы
	var/pending_payload
	/// Таймер, который отправит придержанный показ
	var/pending_timer


/datum/tooltip/New(client/C)
	if (C)
		owner = C
		// jQuery отсюда убран, страница переписана на ванильный JS. Это был ЕДИНСТВЕННЫЙ
		// ассет с legacy = TRUE, то есть единственный, который на проде с CDN уезжал по
		// игровому соединению, и единственный, который межсессионный кэш пропустить не
		// может: клиентский список ассетов выбрасывает всё с расширением .js
		// (asset_cache_client.dm). За прод-раунд 10121 набегало 117 отправок по 95 КБ на
		// 104 игрока - 11.2 МБ, треть из них в первые полторы минуты, ровно когда курсор
		// впервые задевает кнопку действия или экранный алерт.
		var/datum/asset/simple/namespaced/fonts/fonts = get_asset_datum(/datum/asset/simple/namespaced/fonts)
		fonts.send(owner)
		var/static/file2send
		if(!file2send)
			file2send = replacetext(file2text('code/modules/tooltip/tooltip.html'), "THE_FONT_GOES_HERE!!!!!!!!!!!!!!!", SSassets.transport.get_asset_url("fonts.css"))

		owner << browse(file2send, "window=[control]")
		page_sent_at = world.time

	..()


/datum/tooltip/Destroy(force)
	//Незакрытый таймер держит на датуме жёсткую ссылку через CALLBACK и пережил бы владельца
	if (pending_timer)
		deltimer(pending_timer)
		pending_timer = null
	owner = null
	pending_payload = null
	return ..()


/datum/tooltip/proc/show(atom/movable/thing, params = null, title = null, content = null, theme = "default", special = "none")
	if (!thing || !params || (!title && !content) || !owner || !isnum(world.icon_size))
		return FALSE

	showing = 1

	if (title && content)
		title = "<h1>[title]</h1>"
		content = "<p>[content]</p>"
	else if (title && !content)
		title = "<p>[title]</p>"
	else if (!title && content)
		content = "<p>[content]</p>"

	// Strip macros from item names
	title = replacetext(title, "\proper", "")
	title = replacetext(title, "\improper", "")

	//Make our dumb param object
	params = {"{ "cursor": "[params]", "screenLoc": "[thing.screen_loc]" }"}

	//Send stuff to the tooltip
	var/view_size = getviewsize(owner.view)
	send_update(list2params(list(params, view_size[1] , view_size[2], "[title][content]", theme, special)))

	//If a hide() was hit while we were showing, run hide() again to avoid stuck tooltips
	showing = 0
	if (queueHide)
		hide()

	return TRUE


/**
 * Отправляет клиенту готовую строку показа, придерживая её, пока грузится страница окна.
 *
 * tooltip.init задаёт JS-стороне размер тайла и id скин-элемента, без которого её winset
 * уходит в никуда. Раньше init отправлялся ровно один раз, и флаг взводился независимо от
 * того, дошло ли сообщение: одной потери хватало, чтобы тултипы умерли на всю сессию.
 * Теперь init идёт перед каждым показом (это две сотни байт), а показы, выпавшие на окно
 * загрузки страницы, придерживаются и уезжают одной пачкой, когда документ уже готов.
 */
/datum/tooltip/proc/send_update(payload)
	if (world.time < page_sent_at + TOOLTIP_PAGE_LOAD_GRACE)
		pending_payload = payload
		if (!pending_timer)
			pending_timer = addtimer(CALLBACK(src, PROC_REF(flush_pending)), (page_sent_at + TOOLTIP_PAGE_LOAD_GRACE) - world.time, TIMER_STOPPABLE)
		return

	deliver(payload)


/datum/tooltip/proc/flush_pending()
	pending_timer = null
	var/payload = pending_payload
	pending_payload = null
	if (payload)
		deliver(payload)


/// Собственно отправка. init идёт перед каждым показом, потому что доставку output() подтвердить нечем.
/datum/tooltip/proc/deliver(payload)
	if (!owner)
		return

	owner << output(list2params(list(world.icon_size, control)), "[control]:tooltip.init")
	owner << output(payload, "[control]:tooltip.update")


/datum/tooltip/proc/hide()
	//Курсор уже ушёл: придержанный показ больше не нужен, иначе он вылезет после того,
	//как наведение кончилось, и повиснет до следующего MouseExited
	pending_payload = null

	queueHide = showing ? TRUE : FALSE

	if (queueHide)
		addtimer(CALLBACK(src, PROC_REF(do_hide)), 1)
	else
		do_hide()

	return TRUE

/datum/tooltip/proc/do_hide()
	if (!owner)
		return
	winshow(owner, control, FALSE)

/* TG SPECIFIC CODE */


//Open a tooltip for user, at a location based on params
//Theme is a CSS class in tooltip.html, by default this wrapper chooses a CSS class based on the user's UI_style (Midnight, Plasmafire, Retro, etc)
//Includes sanity.checks
/proc/openToolTip(mob/user = null, atom/movable/tip_src = null, params = null,title = "",content = "",theme = "")
	if(istype(user))
		// Ленивое создание: датум тянет за собой jquery и html, и платить за это
		// на каждом логине незачем - подавляющее большинство сессий тултипов не
		// открывает вовсе. Цена - первый показ за сессию придерживается на время
		// загрузки страницы окна, см. send_update().
		if(user.client && !user.client.tooltips)
			user.client.tooltips = new /datum/tooltip(user.client)
		if(user.client && user.client.tooltips)
			if(!theme && user.client.prefs && user.client.prefs.UI_style)
				theme = lowertext(user.client.prefs.UI_style)
			if(!theme)
				theme = "default"
			user.client.tooltips.show(tip_src, params,title,content,theme)


//Arbitrarily close a user's tooltip
//Includes sanity checks.
/proc/closeToolTip(mob/user)
	if(istype(user))
		if(user.client && user.client.tooltips)
			user.client.tooltips.hide()
			deltimer(user.client.tip_timer) //delete any in-progress timer if the mouse is moved off the item before it finishes
			user.client.tip_timer = null

/**
 * If set, will return a list for the tooltip (that will also be put together in a `Join()`)
 * However, if returning `null`, the tooltip will not be shown as #14942 changed it.
 *
 * Though no tooltips will be created for atoms that have `tooltips = FALSE`
*/
/atom/movable/proc/get_tooltip_data()
	return // i did not ask you to create a list, this shit is meant to be overriden

/atom/movable/MouseEntered(location, control, params)
	. = ..()
	if(tooltips)
		if(!QDELETED(usr) && !QDELETED(src) && usr?.client?.prefs.enable_tips)
			var/list/tooltip_data = get_tooltip_data()
			if(length(tooltip_data))
				var/examine_data = tooltip_data.Join("<br />")
				var/timedelay = max(usr.client.prefs.tip_delay * 0.01, 0.01) // I heard multiplying is faster, also runtimes from very low/negative numbers
				params = ClearTooltipsParams(params)
				usr.client.tip_timer = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(openToolTip), usr, src, params, name, examine_data), timedelay, TIMER_STOPPABLE)//timer takes delay in deciseconds, but the pref is in milliseconds. multiplying by 0.01 converts it.

//It should be done in tooltip.html but JS is not my cup of tea
/proc/ClearTooltipsParams(dirty)
	var/list/parts = splittext(dirty, ";")
	if(parts.len == 3)
		return dirty //acceptable.
	var/list/clear = list()
	//This "icon-x=32;icon-y=29;screen-loc=3:10,15:29" (example) must be transfered to tooltip.html
	for(var/part in parts)
		if((findtext(part, "icon-x")!=0) || (findtext(part, "icon-y")!=0) || (findtext(part, "screen-loc")!=0))
			clear.Add(part)
	return clear.Join(";")

/atom/movable/MouseExited(location, control, params)
	. = ..()
	closeToolTip(usr)

/client/MouseDown(object, location, control, params)
	. = ..()
	closeToolTip(usr)

// Break my stuff again and i'll kill you, kisses

#undef TOOLTIP_PAGE_LOAD_GRACE

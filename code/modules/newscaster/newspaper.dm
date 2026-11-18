/obj/item/newspaper
	name = "newspaper"
	desc = "An issue of The Griffon, the newspaper circulating aboard Nanotrasen Space Stations."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "newspaper"
	lefthand_file = 'icons/mob/inhands/misc/books_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/books_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	attack_verb = list("bapped")
	var/screen = 0
	var/pages = 0
	var/curr_page = 0
	var/list/datum/news/feed_channel/news_content = list()
	var/scribble=""
	var/scribble_page = null
	var/wantedAuthor
	var/wantedCriminal
	var/wantedBody
	var/wantedPhoto
	var/creationTime

/obj/item/newspaper/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is focusing intently on [src]! It looks like [user.p_theyre()] trying to commit sudoku... until [user.p_their()] eyes light up with realization!</span>")
	user.say(";JOURNALISM IS MY CALLING! EVERYBODY APPRECIATES UNBIASED REPORTI-GLORF", forced="newspaper suicide")
	var/mob/living/carbon/human/H = user
	var/obj/W = new /obj/item/reagent_containers/food/drinks/bottle/whiskey(H.loc)
	playsound(H.loc, 'sound/items/drink.ogg', rand(10,50), 1)
	W.reagents.trans_to(H, W.reagents.total_volume)
	user.visible_message("<span class='suicide'>[user] downs the contents of [W.name] in one gulp! Shoulda stuck to sudoku!</span>")

	return(TOXLOSS)

/obj/item/newspaper/ui_interact(mob/user, datum/tgui/ui)
	if(!ishuman(user))
		to_chat(user, "The paper is full of unintelligible symbols!")
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Newspaper", "Газета")
		ui.open()

/obj/item/newspaper/ui_data(mob/user)
	pages = length(news_content)
	var/list/data = list()
	data["currPage"] = curr_page
	data["pages"] = pages
	data["lastPage"] = pages + 1
	data["scribble"] = (scribble_page == curr_page) ? tgui_news_text(scribble) : null
	data["wantedAuthor"] = wantedAuthor
	data["wantedCriminal"] = wantedCriminal
	data["wantedBody"] = tgui_news_text(wantedBody)
	data["wantedPhoto"] = wantedPhoto ? "data:image/png;base64,[icon2base64(wantedPhoto)]" : null

	var/list/contents = list()
	var/index = 0
	for(var/datum/news/feed_channel/NP in news_content)
		index++
		contents += list(list("name" = NP.channel_name, "page" = index))
	data["contents"] = contents

	var/list/channel = null
	if(curr_page >= 1 && curr_page <= pages)
		var/datum/news/feed_channel/C = news_content[curr_page]
		channel = list(
			"name" = C.channel_name,
			"author" = C.returnAuthor(notContent(C.authorCensorTime)),
			"censored" = !!notContent(C.DclassCensorTime),
		)
		var/list/messages = list()
		var/stories = 0
		// D-Notice: статьи канала не попадают в газету при печати.
		var/list/printed_messages = notContent(C.DclassCensorTime) ? list() : C.messages
		for(var/datum/news/feed_message/MESSAGE in printed_messages)
			if(MESSAGE.creationTime > creationTime)
				break
			stories++
			messages += list(list(
				"body" = tgui_news_text(MESSAGE.returnBody(notContent(MESSAGE.bodyCensorTime))),
				"author" = MESSAGE.returnAuthor(notContent(MESSAGE.authorCensorTime)),
				"image" = MESSAGE.img ? "data:image/png;base64,[icon2base64(MESSAGE.img)]" : null,
			))
		channel["messages"] = messages
		channel["empty"] = !stories
	data["channel"] = channel
	return data

/obj/item/newspaper/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	pages = length(news_content)
	var/mob/living/user = ui.user
	if(!(src in user.contents || (isturf(loc) && in_range(src, user))))
		return
	switch(action)
		if("nextPage")
			if(curr_page >= pages + 1)
				return
			curr_page++
			screen = curr_page == 0 ? 0 : (curr_page > pages ? 2 : 1)
			playsound(loc, "pageturn", 50, 1)
			. = TRUE
		if("prevPage")
			if(curr_page <= 0)
				return
			curr_page--
			screen = curr_page == 0 ? 0 : (curr_page > pages ? 2 : 1)
			playsound(loc, "pageturn", 50, 1)
			. = TRUE
		if("close")
			ui.close()

/obj/item/newspaper/proc/notContent(list/L)
	if(!L.len)
		return FALSE
	for(var/i=L.len;i>0;i--)
		var/num = abs(L[i])
		if(creationTime <= num)
			continue
		else
			if(L[i] > 0)
				return TRUE
			else
				return FALSE
	return FALSE

/obj/item/newspaper/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/pen))
		if(!user.is_literate())
			to_chat(user, "<span class='notice'>You scribble illegibly on [src]!</span>")
			return
		if(scribble_page == curr_page)
			to_chat(user, "<span class='notice'>There's already a scribble in this page... You wouldn't want to make things too cluttered, would you?</span>")
		else
			var/s = tgui_input_text(user, "Напишите что-нибудь", "Газета", "", MAX_MESSAGE_LEN, FALSE, TRUE)
			if (!s)
				return
			if(!user.canUseTopic(src, BE_CLOSE))
				return
			scribble_page = curr_page
			scribble = s
			SStgui.update_uis(src)
	else
		return ..()

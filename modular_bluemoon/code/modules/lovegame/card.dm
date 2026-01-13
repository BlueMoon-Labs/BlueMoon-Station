/obj/item/toy/cards/deck/love_cards
	icon = 'modular_bluemoon/icons/obj/toys/love_cards.dmi'
	alt_tooltip = null
	card_types = null

/obj/item/toy/cards/deck/love_cards/populate_deck()
	cards = world.file2list("strings/pack_[deckstyle].txt")
	icon_state = "deck_[deckstyle]_full"

/obj/item/toy/cards/deck/love_cards/draw_card(mob/user)
	if(user.lying)
		return
	if(cards.len == 0)
		to_chat(user, "<span class='warning'>There are no more cards to draw!</span>")
		return TRUE
	var/obj/item/toy/cards/singlecard/love_card/H = new(user.loc)
	if(holo)
		holo.spawned += H
	var/choice = popleft(cards)
	H.name = "[deckstyle] card"
	H.parentdeck = src
	H.cardname = choice
	if(H.cardname == "Blank card")
		H.blank = TRUE
	H.apply_card_vars(H, src)
	H.pickup(user)
	user.put_in_hands(H)
	playsound(src, 'sound/items/carddraw.ogg', 50, 1)
	user.visible_message("[user] draws a card from the deck.", "<span class='notice'>You draw a card from the deck.</span>")
	update_icon()

/obj/item/toy/cards/deck/love_cards/AltClick(mob/living/user, obj/item/I)
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user), FALSE)) //, TRUE))
		return
	if(!card_types)
		return
	var/cards_to_find = tgui_input_list(user, "Select cards to remove", "Cards to remove", card_types, null)
	if(isnull(cards_to_find))
		return
	user.visible_message("[user] searches through the deck to remove [cards_to_find] cards.")
	var/list/found_cards = list()
	var/obj/item/toy/cards/singlecard/love_card/S
	for(var/c in cards)
		if(findtext(c, cards_to_find))
			cards.Remove(c)
			S = new(user.loc)
			if(holo)
				holo.spawned += S // track them leaving the holodeck
			S.cardname = "[deckstyle] cards"
			S.parentdeck = src
			S.cardname = c
			if(S.cardname == "Blank card")
				S.blank = TRUE
			S.apply_card_vars(S, src)
			found_cards += S
	switch(length(found_cards))
		if(0)
			to_chat(user, "There are no [cards_to_find] cards to remove!")
		if(1)
			S.pickup(user)
			user.put_in_active_hand(S)
			update_icon()
		else
			update_icon()

/obj/item/toy/cards/deck/love_cards/truths
	name = "Deck of Truths"
	desc = "Колода вопросов."
	icon_state = "deck_truth_full"
	deckstyle = "truth"

/obj/item/toy/cards/deck/love_cards/kinks
	name = "Deck of Kinks"
	desc = "Колода с сексуальными действиями и вопросами."
	icon_state = "deck_kinks_full"
	deckstyle = "kinks"
	alt_tooltip = "to remove unwanted cards."
	card_types = list("Truth", "Action")

/obj/item/toy/cards/deck/love_cards/actions
	name = "Deck of Actions"
	desc = "Колода с игровыми действиями."
	icon_state = "deck_actions_full"
	deckstyle = "actions"

/obj/item/toy/cards/deck/love_cards/blanks
	name = "Deck of Blanks"
	desc = "Колода с пустыми картами."
	icon_state = "deck_blanks_full"
	deckstyle = "blanks"
	original_size = 30
	card_types = list("Blank")

/obj/item/toy/cards/deck/love_cards/blanks/populate_deck()
	for(var/i in 1 to original_size)
		cards += "Blank card"
	icon_state = "deck_[deckstyle]_full"

/obj/item/toy/cards/singlecard/love_card
	cardname = "" // на самом деле описание в карте у love_card
	var/blank = FALSE
	icon = 'modular_bluemoon/icons/obj/toys/love_cards.dmi'
	icon_state = "singlecard_down_kinks"

/obj/item/toy/cards/singlecard/love_card/Flip()
	set name = "Flip Card"
	set category = "Object"
	set src in range(2)
	if(!ishuman(usr) || !usr.canUseTopic(src, BE_CLOSE))
		return
	if(!flipped)
		icon_state = "sc_[deckstyle][blank ? "_blank" : ""]"
		desc = cardname
		pixel_x = 5
	else
		icon_state = "singlecard_down_[deckstyle]"
		desc = "A card"
		pixel_x = -5

	flipped = !flipped

/obj/item/toy/cards/singlecard/love_card/attackby(obj/item/I, mob/living/user, params)
	// Disable combining love cards into a hand or merging with other cards
	if(istype(I, /obj/item/toy/cards/singlecard) || istype(I, /obj/item/toy/cards/cardhand))
		to_chat(user, "<span class='warning'>These cards can't be combined into a hand.</span>")
		return
	else if(istype(I, /obj/item/pen))
		if(!user.can_write(I))
			to_chat(user, "<span class='notice'>You scribble illegibly on [src]!</span>")
			return
		if(!blank)
			to_chat(user, "You cannot write on that card.")
			return
		var/cardtext = tgui_input_text(user, "What do you wish to write on the card?", "Card Writing", "", 250, encode = TRUE)
		if(!cardtext || !user.canUseTopic(src, BE_CLOSE))
			return
		cardname = cardtext
		blank = FALSE
		if(flipped) // просто и элегантно
			Flip()
		Flip()
	return ..()

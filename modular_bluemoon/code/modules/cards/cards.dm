/obj/item/toy/cards/deck/love_cards
	icon = 'modular_bluemoon/icons/obj/toys/love_cards.dmi'
	card_types = null

/obj/item/toy/cards/deck/love_cards/populate_deck()
	cards = world.file2list("strings/pack_[deckstyle].txt")
	icon_state = "deck_[deckstyle]_full"

/obj/item/toy/cards/deck/love_cards/draw(mob/living/user, card, card_type = /obj/item/toy/cards/singlecard/love_card)
	. = ..()
	var/obj/item/toy/cards/singlecard/love_card/S = .
	if(S)
		S.name = "[deckstyle] card"
		if(S.cardname == "Blank card")
			S.blank = TRUE
		S.update_icon()
	return S

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
	icon = 'modular_bluemoon/icons/obj/toys/love_cards.dmi'
	icon_state = "singlecard_down_kinks"
	allow_merge = FALSE
	var/blank = FALSE

/obj/item/toy/cards/singlecard/love_card/update_icon_state()
	. = ..()
	if(!flipped)
		icon_state = "singlecard_down_[deckstyle]"
		desc = "A card"
	else
		icon_state = "sc_[deckstyle][blank ? "_blank" : ""]"
		desc = cardname

/obj/item/toy/cards/singlecard/love_card/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/pen))
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

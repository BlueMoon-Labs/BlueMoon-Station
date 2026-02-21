// CARDS AGAINST SPESS
// This is a parody of Cards Against Humanity (https://en.wikipedia.org/wiki/Cards_Against_Humanity)
// which is licensed under CC BY-NC-SA 2.0, the full text of which can be found at the following URL:
// https://creativecommons.org/licenses/by-nc-sa/2.0/legalcode
// Original code by Zuhayr, Polaris Station, ported with modifications
/datum/playingcard
	var/name = "playing card"
	var/card_icon = "card_back"
	var/suit
	var/number

/obj/item/toy/cards/deck/cas
	name = "\improper CAS deck (white)"
	desc = "A deck for the game Cards Against Spess, still popular after all these centuries. Warning: may include traces of broken fourth wall. This is the white deck."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "deck_caswhite_full"
	deckstyle = "caswhite"
	card_types = null
	var/card_face = "cas_white"
	var/blanks = 25
	var/decksize = 150
	var/card_text_file = "strings/cas_white.txt"
	var/list/allcards = list()

/obj/item/toy/cards/deck/cas/black
	name = "\improper CAS deck (black)"
	desc = "A deck for the game Cards Against Spess, still popular after all these centuries. Warning: may include traces of broken fourth wall. This is the black deck."
	icon_state = "deck_casblack_full"
	deckstyle = "casblack"
	card_face = "cas_black"
	blanks = 0
	decksize = 50
	card_text_file = "strings/cas_black.txt"

/obj/item/toy/cards/deck/cas/populate_deck()
	var/static/list/cards_against_space = list("cas_white" = world.file2list("strings/cas_white.txt"),"cas_black" = world.file2list("strings/cas_black.txt"))
	allcards = cards_against_space[card_face]
	var/list/possiblecards = allcards.Copy()
	if(possiblecards.len < decksize) // sanity check
		decksize = (possiblecards.len - 1)
	var/list/randomcards = list()
	for(var/x in 1 to decksize)
		randomcards += pick_n_take(possiblecards)
	for(var/x in 1 to randomcards.len)
		var/cardtext = randomcards[x]
		var/datum/playingcard/P
		P = new()
		P.name = "[cardtext]"
		P.card_icon = "[src.card_face]"
		cards += P
	if(!blanks)
		return
	for(var/x in 1 to blanks)
		var/datum/playingcard/P
		P = new()
		P.name = "Blank Card"
		P.card_icon = "cas_white"
		cards += P
	shuffle_inplace(cards) // distribute blank cards throughout deck

/obj/item/toy/cards/deck/cas/draw(mob/living/user, card, card_type = /obj/item/toy/cards/singlecard/cas)
	. = ..()
	var/obj/item/toy/cards/singlecard/cas/S = .
	if(S)
		if(S.cardname == "Blank card")
			S.blank = TRUE
			S.update_icon()
	return S

/obj/item/toy/cards/deck/cas/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/toy/cards/singlecard/cas))
		var/obj/item/toy/cards/singlecard/cas/SC = I
		if(!user.temporarilyRemoveItemFromInventory(SC))
			to_chat(user, "<span class='warning'>The card is stuck to your hand, you can't add it to the deck!</span>")
			return
		var/datum/playingcard/RC // replace null datum for the re-added card
		RC = new()
		RC.name = "[SC.name]"
		RC.card_icon = SC.card_face
		cards += RC
		user.visible_message("[user] adds a card to the bottom of the deck.","<span class='notice'>You add the card to the bottom of the deck.</span>")
		qdel(SC)
	update_icon()

/obj/item/toy/cards/deck/cas/update_icon_state()
	. = ..()
	if(cards.len < 26)
		icon_state = "deck_[deckstyle]_low"

/obj/item/toy/cards/singlecard/cas
	name = "CAS card"
	desc = "A CAS card."
	icon_state = "cas_white"
	flipped = FALSE
	allow_merge = FALSE
	var/card_face = "cas_white"
	var/blank = FALSE
	var/buffertext = "A funny bit of text."

/obj/item/toy/cards/singlecard/cas/examine(mob/user)
	. = ..()
	if (flipped)
		. += "<span class='notice'>The card is face down.</span>"
	else if (blank)
		. += "<span class='notice'>The card is blank. Write on it with a pen.</span>"
	else
		. += "<span class='notice'>The card reads: [name]</span>"
	. += "<span class='notice'>Alt-click to flip it.</span>"

/obj/item/toy/cards/singlecard/cas/update_icon_state()
	. = ..()
	if(flipped)
		name = buffertext
		icon_state = "[card_face]_flipped"
	else
		name = "CAS card"
		icon_state = "[card_face]"

/obj/item/toy/cards/singlecard/cas/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/pen))
		if(!user.can_write(I))
			to_chat(user, "<span class='notice'>You scribble illegibly on [src]!</span>")
			return
		if(!blank)
			to_chat(user, "You cannot write on that card.")
			return
		var/cardtext = stripped_input(user, "What do you wish to write on the card?", "Card Writing", "", 50)
		if(!cardtext || !user.canUseTopic(src, BE_CLOSE))
			return
		name = cardtext
		buffertext = cardtext
		blank = FALSE

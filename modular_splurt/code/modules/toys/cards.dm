/obj/item/toy/cards/deck
	icon = 'modular_splurt/icons/obj/toy.dmi'
	original_size = 54
	var/alt_tooltip = "to remove unwanted cards."
	var/list/card_types = list("Hearts", "Spades", "Clubs", "Diamonds", "Joker", "Ace", "King", "Queen", "Jack", "2", "3", "4", "5", "6", "7", "8", "9", "10")

/obj/item/toy/cards/deck/examine()
	. = ..()
	if(alt_tooltip)
		. += span_notice("Alt-click [src] [alt_tooltip]")

/obj/item/toy/cards/deck/populate_deck()
	. = ..()
	cards += "Monochrome Joker"
	cards += "Colorful Joker"

/obj/item/toy/cards/deck/AltClick(mob/living/user, obj/item/I)
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user), FALSE)) //, TRUE))
		return
	var/cards_to_find = tgui_input_list(user, "Select cards to remove", "Cards to remove", list("Hearts", "Spades", "Clubs", "Diamonds", "Joker", "Ace", "King", "Queen", "Jack", "2", "3", "4", "5", "6", "7", "8", "9", "10"), null)
	if(isnull(cards_to_find))
		return
	user.visible_message("[user] searches through the deck to remove [cards_to_find] cards.")
	var/list/found_cards = list()
	var/obj/item/toy/cards/singlecard/S
	for(var/c in cards)
		if(findtext(c, cards_to_find))
			cards.Remove(c)
			S = new/obj/item/toy/cards/singlecard(user.loc)
			if(holo)
				holo.spawned += S // track them leaving the holodeck
			S.cardname = c
			S.parentdeck = src
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
			var/obj/item/toy/cards/cardhand/C = new/obj/item/toy/cards/cardhand(user.loc)
			for(var/obj/item/toy/cards/singlecard/SC in found_cards)
				C.currenthand += SC.cardname
				C.parentdeck = SC.parentdeck
				C.apply_card_vars(C,SC)
				qdel(SC)
			C.pickup(user)
			user.put_in_active_hand(C)
			update_icon()

/obj/item/toy/cards/cardhand
	icon = 'modular_splurt/icons/obj/toy.dmi'

/obj/item/toy/cards/singlecard
	icon = 'modular_splurt/icons/obj/toy.dmi'

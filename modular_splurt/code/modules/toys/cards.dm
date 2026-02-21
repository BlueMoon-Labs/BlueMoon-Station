/obj/item/toy/cards/deck
	icon = 'modular_splurt/icons/obj/toy.dmi'
	original_size = 54
	/// used for specific card type removal on alt-click
	var/list/card_types = list("Hearts", "Spades", "Clubs", "Diamonds", "Joker", "Ace", "King", "Queen", "Jack", "2", "3", "4", "5", "6", "7", "8", "9", "10")

/obj/item/toy/cards/deck/examine()
	. = ..()
	if(!isnull(card_types) && length(card_types)>1)
		. += span_notice("Alt-click to remove unwanted cards.")

/obj/item/toy/cards/deck/populate_deck()
	. = ..()
	cards += "Monochrome Joker"
	cards += "Colorful Joker"

/obj/item/toy/cards/deck/AltClick(mob/living/user, obj/item/I)
	if(!user.canUseTopic(src, TRUE, TRUE, TRUE))
		return
	if(isnull(card_types) || length(card_types)<=1)
		return
	var/cards_to_find = tgui_input_list(user, "Select cards to remove", "Cards to remove", card_types, null)
	if(isnull(cards_to_find))
		return
	user.visible_message("[user] searches through the deck to remove [cards_to_find] cards.")
	user.balloon_alert_to_viewers("takes all [cards_to_find] from the deck")
	var/list/found_cards = list()
	var/obj/item/toy/cards/singlecard/S
	for(var/c in cards)
		if(findtext(c, cards_to_find))
			S = draw(user, c)
			found_cards += S
	switch(length(found_cards))
		if(0)
			to_chat(user, "There are no [cards_to_find] cards to remove!")
		if(1)
			S.pickup(user)
			user.put_in_active_hand(S)
			update_icon()
		else
			if(S.allow_merge)
				var/obj/item/toy/cards/cardhand/C = new /obj/item/toy/cards/cardhand(user.loc)
				for(var/obj/item/toy/cards/singlecard/SC in found_cards)
					C.cards += SC.cardname
					C.apply_card_vars(SC)
					qdel(SC)
				C.pickup(user)
				user.put_in_active_hand(C)
			else
				for(var/obj/item/toy/cards/singlecard/SC in found_cards)
					SC.forceMove(drop_location(user))
			update_icon()

/obj/item/toy/cards/cardhand
	icon = 'modular_splurt/icons/obj/toy.dmi'

/obj/item/toy/cards/singlecard
	icon = 'modular_splurt/icons/obj/toy.dmi'

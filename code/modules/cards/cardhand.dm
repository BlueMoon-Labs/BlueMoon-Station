/obj/item/toy/cards/cardhand
	name = "hand of cards"
	desc = "A number of cards not in a deck, customarily held in ones hand."
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "nanotrasen_hand2"
	w_class = WEIGHT_CLASS_TINY
	/// is TRUE if you see contents
	var/cards_flipped = FALSE

/obj/item/toy/cards/cardhand/Initialize(mapload)
	. = ..()
	register_context()
	register_item_context()

/obj/item/toy/cards/cardhand/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	context[SCREENTIP_CONTEXT_ALT_LMB] = "Flip"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/toy/cards/cardhand/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	. = ..()
	if(istype(target, /obj/item/toy/cards) && !istype(target, /obj/item/toy/cards/deck))
		context[SCREENTIP_CONTEXT_LMB] = "Merge cards"
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/toy/cards/cardhand/examine()
	. = ..()
	if(cards_flipped)
		. += "It contains: <b>[dd_list2text(cards, " | ")]</b>."
	. += span_notice("Alt-click to flip cards.")

/obj/item/toy/cards/cardhand/attack_self(mob/user)
	if(usr.stat || !ishuman(usr))
		return
	var/mob/living/carbon/human/cardUser = usr
	if(!(cardUser.mobility_flags & MOBILITY_USE))
		return
	interact(user)
	var/list/handradial = list()
	for(var/t in cards)
		handradial[t] = image(icon = src.icon, icon_state = "sc_[t]_[deckstyle]")
	var/choice = show_radial_menu(usr,src, handradial, custom_check = CALLBACK(src, PROC_REF(check_menu), user), radius = 36, require_near = TRUE)
	if(!choice)
		return FALSE
	draw(user, choice)

/obj/item/toy/cards/cardhand/draw(mob/living/user, card, card_type)
	. = ..()
	if(!.)
		return
	var/obj/item/toy/cards/singlecard/S = .
	S.pickup(user)
	user.put_in_hands(S)
	if(cards_flipped && user.is_holding(S))
		S.Flip()
	user.visible_message("[user] draws a card from their's hand.", "You take the [S.cardname] from your hand.")
	if(length(cards) == 1)
		user.temporarilyRemoveItemFromInventory(src, TRUE)
		draw(user)
		qdel(src)

/obj/item/toy/cards/cardhand/attackby(obj/item/I, mob/living/user, params)
	if(!is_type_in_list(I, list(/obj/item/toy/cards/deck, /obj/item/toy/cards/singlecard, /obj/item/toy/cards/cardhand)))
		return ..()
	var/obj/item/toy/cards/singlecard/card = null
	if(istype(I, /obj/item/toy/cards/singlecard))
		card = I
	if(istype(I, /obj/item/toy/cards/deck))
		var/obj/item/toy/cards/deck/dealer_deck = I
		if(!HAS_TRAIT(dealer_deck, TRAIT_WIELDED)) // recycle card into deck (if unwielded)
			if(dealer_deck.insert(src, user))
				user.balloon_alert_to_viewers("puts card in deck")
			return
		if(dealer_deck.count_cards())
			user.balloon_alert_to_viewers("deals a card")
		card = dealer_deck.draw(user)
	if(card)
		if(insert(card, user))
			user.visible_message("[user] adds a card to [src].")
		else if(!user.is_holding(card))
			card.forceMove(drop_location())
	if(istype(I, /obj/item/toy/cards/cardhand))
		var/obj/item/toy/cards/cardhand/C = I
		if(C.insert(src, user))
			user.visible_message("[user] adds a cards to [user.ru_ego()] hand.", "You add the cards to your hand.")

/obj/item/toy/cards/cardhand/AltClick(mob/user)
	cards_flipped = !cards_flipped
	update_icon()

/obj/item/toy/cards/cardhand/insert(obj/item/toy/cards/card_item, mob/living/user)
	var/card_item_cache = card_item
	. = ..()
	if(!.)
		return
	apply_card_vars(card_item_cache)

/obj/item/toy/cards/cardhand/apply_card_vars(obj/item/toy/cards/sourceobj)
	. = ..()
	if(!.)
		return
	resistance_flags = sourceobj.resistance_flags
	update_icon()

/**
  * check_menu: Checks if we are allowed to interact with a radial menu
  *
  * Arguments:
  * * user The mob interacting with a menu
  */
/obj/item/toy/cards/cardhand/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated())
		return FALSE
	return TRUE

/obj/item/toy/cards/cardhand/update_icon_state()
	. = ..()
	if(deckstyle && cards.len)
		if(cards.len > 3 && cards_flipped)
			icon_state = "[deckstyle]_hand[cards.len - 3 < 5 ? "[cards.len - 3]" : "5"]"
		else
			icon_state = ""

#define CARDS_MAX_DISPLAY_LIMIT 5 // the amount of cards that are displayed in a hand
#define CARDS_PIXEL_X_OFFSET -5 // start out displaying the 1st card -5 pixels left
#define CARDS_ANGLE_OFFSET -45 // start out displaying the 1st card -45 degrees counter clockwise

/obj/item/toy/cards/cardhand/update_overlays()
	. = ..()
	// cut_overlays()
	// var/overlay_cards = cards.len
	// var/k = max(1, overlay_cards - 2)
	// var/card_overlay
	// for(var/i in k to overlay_cards)
	// 	card_overlay = image(icon=src.icon,icon_state="sc_[cards[i]]_[deckstyle]",pixel_x=(1-i+k)*3,pixel_y=(1-i+k)*3)
	// 	. += card_overlay
	cut_overlays()
	if(cards.len <= 1)
		icon_state = null // we want an error icon to appear if this doesn't get qdel
		return
	var/starting_card_pos = max(0, cards.len - CARDS_MAX_DISPLAY_LIMIT) + 1 // only display the top cards in the cardhand, +1 because list indexes start at 1
	var/cards_to_display = min(CARDS_MAX_DISPLAY_LIMIT, cards.len)
	// 90 degrees from the 1st card to the last, so split the divider by total cards displayed
	var/angle_divider = round(90/(cards_to_display - 1))
	// 10 pixels from the 1st card to the last, so split the divider by total cards displayed
	var/pixel_divider = round(10/(cards_to_display - 1))
	// starting from the 1st card to last, we want to slowly increase the angle and pixel_x offset
	// to spread the cards out using our dividers
	for(var/i in 0 to cards_to_display - 1)
		// var/obj/item/toy/cards/singlecard/card = cards[starting_card_pos + i]
		// var/image/card_overlay = image(icon, icon_state = card.icon_state, pixel_x = CARDS_PIXEL_X_OFFSET + (i * pixel_divider))
		var/image/card_overlay
		if(cards_flipped)
			card_overlay = image(icon, icon_state="sc_[cards[starting_card_pos+i]]_[deckstyle]", pixel_x = CARDS_PIXEL_X_OFFSET + (i * pixel_divider))
		else
			card_overlay = image(icon, icon_state="singlecard_down_[deckstyle]", pixel_x = CARDS_PIXEL_X_OFFSET + (i * pixel_divider))
		var/rotation_angle = CARDS_ANGLE_OFFSET + (i * angle_divider)
		var/matrix/M = matrix()
		M.Turn(rotation_angle)
		card_overlay.transform = M
		add_overlay(card_overlay)

#undef CARDS_MAX_DISPLAY_LIMIT
#undef CARDS_PIXEL_X_OFFSET
#undef CARDS_ANGLE_OFFSET

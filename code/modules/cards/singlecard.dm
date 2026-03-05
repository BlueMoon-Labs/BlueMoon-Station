/obj/item/toy/cards/singlecard
	name = "card"
	desc = "A card"
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "singlecard_down_nanotrasen"
	w_class = WEIGHT_CLASS_TINY
	pixel_x = -5
	var/cardname = null
	/// is TRUE if you see contents
	var/flipped = FALSE
	/// allow merge cards into cardhand
	var/allow_merge = TRUE

/obj/item/toy/cards/singlecard/Initialize(mapload)
	. = ..()
	register_context()

/obj/item/toy/cards/singlecard/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	context[SCREENTIP_CONTEXT_ALT_LMB] = "Flip"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/toy/cards/singlecard/examine(mob/user)
	. = ..()
	if(ishuman(user))
		var/mob/living/carbon/human/cardUser = user
		if(cardUser.is_holding(src))
			cardUser.visible_message("[cardUser] checks [cardUser.ru_ego()] card.", "<span class='notice'>The card reads: [cardname].</span>")
		. += span_notice("[span_bold("Alt-Click")] to flip [src].")

// to prevent exposing holder's card when examining them
/obj/item/toy/cards/singlecard/get_examine_string(mob/user)
	if(istype(user) && ismob(loc) && !user.is_holding(src) && flipped)
		return " a card"
	return ..()

/obj/item/toy/cards/singlecard/AltClick(mob/user)
	. = ..()
	Flip()

/obj/item/toy/cards/singlecard/verb/Flip()
	set name = "Flip Card"
	set category = "Object"
	set src in range(2)
	. = TRUE
	if(!ishuman(usr) || !usr.canUseTopic(src, BE_CLOSE))
		return FALSE
	if(flipped)
		flipped = FALSE
		icon_state = "singlecard_down_[deckstyle]"
		name = "card"
	else
		flipped = TRUE
		if (cardname)
			icon_state = "sc_[cardname]_[deckstyle]"
			name = cardname
		else
			icon_state = "sc_Ace of Spades_[deckstyle]"
			name = "What Card"
	update_appearance()

/obj/item/toy/cards/singlecard/attackby(obj/item/I, mob/living/user, params)
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
	if(card) // card + card = combine into cardhand
		// if(LAZYACCESS(params2list(params), RIGHT_CLICK))
		// 	card.Flip()
		if(parentdeck != card.parentdeck || !allow_merge || !card.allow_merge)
			to_chat(user, span_warning("You can't mix those cards!"))
			if(!user.is_holding(card))
				card.forceMove(drop_location())
			return
		var/obj/item/toy/cards/cardhand/new_cardhand = new (drop_location())
		new_cardhand.insert(src, user)
		new_cardhand.insert(card, user)
		new_cardhand.pixel_x = pixel_x
		new_cardhand.pixel_y = pixel_y
		if(!isturf(loc)) // make a cardhand in our active hand
			user.temporarilyRemoveItemFromInventory(src, TRUE)
			new_cardhand.pickup(user)
			user.put_in_active_hand(new_cardhand)
		return
	if(istype(I, /obj/item/toy/cards/cardhand)) // insert into cardhand
		return I.attackby(src, user, params)

/obj/item/toy/cards/singlecard/attack_self(mob/living/user)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return
	if(!CHECK_MOBILITY(user, MOBILITY_USE))
		return
	Flip()

/obj/item/toy/cards/singlecard/apply_card_vars(obj/item/toy/cards/sourceobj)
	. = ..()
	if(!.)
		return
	icon_state = "singlecard_down_[deckstyle]" // Without this the card is invisible until flipped. It's an ugly hack, but it works.
	hitsound = card_hitsound
	force = card_force
	throwforce = card_throwforce
	throw_speed = card_throw_speed
	throw_range = card_throw_range
	attack_verb = card_attack_verb

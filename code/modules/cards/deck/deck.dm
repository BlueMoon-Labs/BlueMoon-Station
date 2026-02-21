/obj/item/toy/cards/deck
	name = "deck of cards"
	desc = "A deck of space-grade playing cards."
	icon = 'icons/obj/toys/toy.dmi'
	deckstyle = "nanotrasen"
	icon_state = "deck_nanotrasen_full"
	w_class = WEIGHT_CLASS_SMALL
	COOLDOWN_DECLARE(shuffle_cooldown)
	var/obj/machinery/computer/holodeck/holo = null // Holodeck cards should not be infinite
	var/original_size = 52

/obj/item/toy/cards/deck/Initialize(mapload)
	. = ..()
	parentdeck = src
	populate_deck()
	register_context()
	register_item_context()

/obj/item/toy/cards/deck/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, attacksound='sound/items/carddraw.ogg')

///Generates all the cards within the deck.
/obj/item/toy/cards/deck/proc/populate_deck()
	icon_state = "deck_[deckstyle]_full"
	for(var/suit in list("Hearts", "Spades", "Clubs", "Diamonds"))
		cards += "Ace of [suit]"
		for(var/i in 2 to 10)
			cards += "[i] of [suit]"
		for(var/person in list("Jack", "Queen", "King"))
			cards += "[person] of [suit]"

/obj/item/toy/cards/deck/examine()
	. = ..()
	. += span_notice("Ctrl-click [src] to shuffle cards.")

/obj/item/toy/cards/deck/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(isnull(held_item))
		context[SCREENTIP_CONTEXT_LMB] = "Draw card"
		. = CONTEXTUAL_SCREENTIP_SET
	if(src == held_item)
		context[SCREENTIP_CONTEXT_LMB] = HAS_TRAIT(src, TRAIT_WIELDED) ? "Recycle mode" : "Dealer mode"
		. = CONTEXTUAL_SCREENTIP_SET
	if(user.is_holding(src))
		context[SCREENTIP_CONTEXT_CTRL_LMB] = "Shuffle"
		. = CONTEXTUAL_SCREENTIP_SET
	if(!isnull(card_types) && length(card_types)>1)
		context[SCREENTIP_CONTEXT_ALT_LMB] = "Remove unwanted cards"
		. = CONTEXTUAL_SCREENTIP_SET

/obj/item/toy/cards/deck/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	. = ..()
	if(HAS_TRAIT(src, TRAIT_WIELDED))
		context[SCREENTIP_CONTEXT_LMB] = "Deal/Throw card"
		// context[SCREENTIP_CONTEXT_RMB] = "Deal card faceup"
		. = CONTEXTUAL_SCREENTIP_SET
	else
		if(istype(target, /obj/item/toy/cards) && !istype(target, /obj/item/toy/cards/deck))
			context[SCREENTIP_CONTEXT_LMB] = "Recycle cards"
			. = CONTEXTUAL_SCREENTIP_SET


/obj/item/toy/cards/deck/update_icon_state()
	switch(LAZYLEN(cards))
		if(27 to INFINITY)
			icon_state = "deck_[deckstyle]_full"
		if(11 to 27)
			icon_state = "deck_[deckstyle]_half"
		if(1 to 11)
			icon_state = "deck_[deckstyle]_low"
		else
			icon_state = "deck_[deckstyle]_empty"
	return ..()

/obj/item/toy/cards/deck/draw(mob/living/user, card, card_type = /obj/item/toy/cards/singlecard)
	. = ..()
	var/obj/item/toy/cards/singlecard/S = .
	if(S && holo)
		holo.spawned += S
	return S

/obj/item/toy/cards/deck/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	var/obj/item/toy/cards/singlecard/card = draw(user)
	if(!card)
		return
	// if(flip_card)
	// 	card.Flip()
	card.pickup(user)
	user.put_in_hands(card)
	user.balloon_alert_to_viewers("draws a card")

/obj/item/toy/cards/deck/CtrlClick(mob/user)
	. = ..()
	if(!HAS_TRAIT(src, TRAIT_WIELDED) && user.has_left_hand() && user.has_right_hand()) // скидка на инвалидность
		to_chat(user, span_warning("You must hold the [src] with both hands to shuffle."))
	else
		shuffle_cards(user)

/obj/item/toy/cards/deck/proc/shuffle_cards(mob/living/user)
	if(!COOLDOWN_FINISHED(src, shuffle_cooldown))
		return
	COOLDOWN_START(src, shuffle_cooldown, 5 SECONDS)
	shuffle_inplace(cards)
	playsound(src, 'sound/items/cardshuffle.ogg', 50, TRUE)
	user.balloon_alert_to_viewers("shuffles the deck")

/obj/item/toy/cards/deck/pre_attack(atom/A, mob/living/user, params, attackchain_flags, damage_multiplier)
	. = ..()
	if(HAS_TRAIT(src, TRAIT_WIELDED))
		if(isfloorturf(A) || istype(A, /obj/structure/table))
			var/obj/item/toy/cards/singlecard/card = draw(user)
			if(!card)
				return STOP_ATTACK_PROC_CHAIN
			user.balloon_alert_to_viewers("deals a card")
			card.forceMove(get_turf(A))
			// if(LAZYACCESS(params2list(params), RIGHT_CLICK))
			// 	card.Flip()
			var/list/click_params = params2list(params)
			//Center the icon where the user clicked.
			if(click_params && click_params["icon-x"] && click_params["icon-y"])
				//Clamp it so that the icon never moves more than 16 pixels in either direction (thus leaving the table turf)
				card.pixel_x = clamp(text2num(click_params["icon-x"]) - 16, -(world.icon_size/2), world.icon_size/2)
				card.pixel_y = clamp(text2num(click_params["icon-y"]) - 16, -(world.icon_size/2), world.icon_size/2)
			return STOP_ATTACK_PROC_CHAIN

/obj/item/toy/cards/deck/attackby(obj/item/I, mob/living/user, params)
	if(!istype(I, /obj/item/toy/cards/singlecard) && !istype(I, /obj/item/toy/cards/cardhand))
		return ..()
	var/card_grammar = istype(I, /obj/item/toy/cards/singlecard) ? "card" : "cards"
	if(insert(I, user))
		user.balloon_alert_to_viewers("puts [card_grammar] in deck")

/obj/item/toy/cards/deck/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag && HAS_TRAIT(src, TRAIT_WIELDED) && user.CheckActionCooldown(CLICK_CD_RANGE))
		var/obj/item/toy/cards/singlecard/card = draw(user)
		if(!card)
			return
		card.throw_at(target, range = card.throw_range, speed = card.throw_speed, thrower = user, spin = TRUE)
		user.balloon_alert_to_viewers("throws a card")
		if(card.throwforce)
			log_combat(user, target, "threw the harmful playing card", src)
		user.DelayNextAction(CLICK_CD_RANGE)

/obj/item/toy/cards/deck/MouseDrop(atom/over_object)
	. = ..()
	var/mob/living/M = usr
	if(!istype(M) || usr.incapacitated())
		return
	if(Adjacent(usr))
		if(over_object == M && loc != M)
			M.put_in_hands(src)
			to_chat(usr, "You pick up the deck.")
		else if(istype(over_object, /atom/movable/screen/inventory/hand))
			var/atom/movable/screen/inventory/hand/H = over_object
			if(M.putItemFromInventoryInHandIfPossible(src, H.held_index))
				to_chat(usr, "You pick up the deck.")
	else
		to_chat(usr, "You can't reach it from here!")

/obj/item/toy/cards/deck/syndicate
	name = "suspicious looking deck of cards"
	desc = "A deck of space-grade playing cards. They seem unusually rigid."
	icon_state = "deck_syndicate_full"
	deckstyle = "syndicate"
	card_hitsound = 'sound/weapons/bladeslice.ogg'
	card_force = 5
	card_throwforce = 10
	card_throw_speed = 3
	card_throw_range = 7
	card_attack_verb = list("attacked", "sliced", "diced", "slashed", "cut")
	resistance_flags = NONE

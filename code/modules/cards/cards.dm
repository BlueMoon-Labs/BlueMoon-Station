/obj/item/toy/cards
	resistance_flags = FLAMMABLE
	max_integrity = 50
	var/list/cards = list()
	var/parentdeck = null
	var/deckstyle = "nanotrasen"
	var/card_hitsound = null
	var/card_force = 0
	var/card_throwforce = 0
	var/card_throw_speed = 3
	var/card_throw_range = 7
	var/list/card_attack_verb = list("attacked")

/obj/item/toy/cards/examine()
	. = ..()
	. += "<span class='notice'>Лежащие на столе карты можно взять с большего расстояния.</span>"

/obj/item/toy/cards/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] is slitting [user.ru_ego()] wrists with \the [src]! It looks like [user.ru_who()] [user.p_have()] a crummy hand!</span>")
	playsound(src, 'sound/items/cardshuffle.ogg', 50, 1)
	return BRUTELOSS

/obj/item/toy/cards/proc/apply_card_vars(obj/item/toy/cards/sourceobj) // Applies variables for supporting multiple types of card deck
	. = TRUE
	if(!istype(sourceobj))
		return FALSE
	parentdeck = sourceobj.parentdeck || sourceobj
	deckstyle = sourceobj.deckstyle
	card_hitsound = sourceobj.card_hitsound
	card_force = sourceobj.card_force
	card_throwforce = sourceobj.card_throwforce
	card_throw_speed = sourceobj.card_throw_speed
	card_throw_range = sourceobj.card_throw_range
	card_attack_verb = sourceobj.card_attack_verb

/obj/item/toy/cards/Adjacent(atom/neighbor, recurse = 1)
	if(isturf(src.loc) && locate(/obj/structure/table) in src.loc)
		for(var/obj/structure/table/T in orange(src, 1))
			if(T.Adjacent(neighbor))
				return TRUE
	. = ..()

/// Picks what card the user draws from the deck
/obj/item/toy/cards/proc/pick_card(mob/living/user, list/obj/item/toy/cards/singlecard/cards)
	// By default just pick the top card
	return cards[1]

/// Returns the number of cards in the deck.
/// Must be redefined.
/obj/item/toy/cards/proc/count_cards()
	return cards.len

/**
 * Draws a card from the deck or hand of cards.
 *
 * Draws the top card, removing it from the associated card atoms list,
 * unless a card arg is supplied; then it picks that specific card, removes it from the
 * associated card atoms list, and returns it (the card arg is used by the radial menu for cardhands to select
 * specific cards out of the cardhand).
 * Arguments:
 * * mob/living/user - The user drawing the card.
 * * obj/item/toy/singlecard/card (optional) - The card drawn from the hand.
 * * card type - the type of singlecard, that will be created and returned.
**/
/obj/item/toy/cards/proc/draw(mob/living/user, card, card_type = /obj/item/toy/cards/singlecard)
	if(!isliving(user) || !user.canUseTopic(src, TRUE, TRUE, TRUE))
		return
	if(count_cards() == 0)
		to_chat(user, span_warning("There are no more cards to draw!"))
		return
	var/obj/item/toy/cards/singlecard/S = new card_type(user.loc)
	card ||= pick_card(user, cards)
	cards -= card
	S.cardname = card
	S.apply_card_vars(src)
	update_appearance()
	S.update_appearance()
	playsound(src, 'sound/items/carddraw.ogg', 50, TRUE)
	return S

/**
 * This is used to insert a list of cards into a deck or cardhand
 *
 * All cards that are inserted have their angle and pixel offsets reset to zero however their
 * flip state does not change unless it's being inserted into a deck which is always facedown
 * (see the deck/insert proc)
 * Returns the list of inserted cards
 *
 * Arguments:
 * * card_item - Either a singlecard or cardhand that gets inserted into the src
 * * user - user
 */
/obj/item/toy/cards/proc/insert(obj/item/toy/cards/card_item, mob/living/user)
	if(!isnull(parentdeck) && parentdeck != card_item.parentdeck)
		to_chat(user, span_warning("You can't mix cards from other decks!"))
		return FALSE
	if(user.is_holding(card_item) && !user.temporarilyRemoveItemFromInventory(card_item))
		to_chat(user, span_warning("The card is stuck to your hand, you can't add it to the deck!"))
		return FALSE
	if(isnull(parentdeck))
		parentdeck = card_item.parentdeck
	if(istype(card_item, /obj/item/toy/cards/singlecard))
		var/obj/item/toy/cards/singlecard/S = card_item
		cards += S.cardname
	if(istype(card_item, /obj/item/toy/cards/cardhand))
		cards += card_item.cards
	qdel(card_item)
	update_appearance()
	return TRUE

#define TAROT_GHOST_TIMER (666 SECONDS) // this translates into 11 mins and 6 seconds

//Some silly tarot cards for predicting when the Clown will die. Ported from TG. https://github.com/tgstation/tgstation/pull/51318/
/obj/item/toy/cards/deck/tarot
	name = "Tarot Card Deck"
	desc = "A full 78 card deck of Tarot Cards, no refunds on false predicitons."
	icon = 'modular_splurt/icons/obj/toy.dmi'
	icon_state = "deck_tarot_full"
	deckstyle = "tarot"
	card_types = null

/obj/item/toy/cards/deck/tarot/populate_deck()
	for(var/suit in list("Cups", "Wands", "Swords", "Coins"))
		for(var/i in 1 to 10)
			cards += "[i] of [suit]"
		for(var/person in list("Page", "Champion", "Queen", "King"))
			cards += "[person] of [suit]"
	for(var/trump in list("The Magician", "The High Priestess", "The Empress", "The Emperor", "The Hierophant", "The Lover", "The Chariot", "Justice", "The Hermit", "The Wheel of Fortune", "Strength", "The Hanged Man", "Death", "Temperance", "The Devil", "The Tower", "The Star", "The Moon", "The Sun", "Judgement", "The World", "The Fool"))
		cards += "[trump]"

/obj/item/toy/cards/deck/tarot/draw(mob/living/user, card, card_type)
	. = ..()
	if(prob(50))
		var/obj/item/toy/cards/singlecard/S = .
		if(!S)
			return
		var/matrix/M = matrix()
		M.Turn(180)
		S.transform = M

/obj/item/toy/cards/deck/tarot/pick_card(mob/living/user, list/obj/item/toy/cards/singlecard/cards)
	// If the user is cursed they have increase chance of drawing Death or The Tower
	if(!HAS_TRAIT(user, TRAIT_CURSED))
		return ..()
	var/total_card = length(cards)
	// give a boosted chance if they're using the full deck
	var/chance_modifier = total_card >= 56 ? 24 : 4
	if(!prob(min(33, chance_modifier / total_card * 100)))
		return ..()
	for(var/card in cards)
		if(card == "Death" || card == "The Tower")
			return card
	return ..()

/obj/item/toy/cards/deck/tarot/haunted
	name = "haunted tarot game deck"
	desc = "A spooky looking tarot deck. You can sense a supernatural presence linked to the cards..."
	/// ghost notification cooldown
	COOLDOWN_DECLARE(ghost_alert_cooldown)

/obj/item/toy/cards/deck/tarot/haunted/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/toy/cards/deck/tarot/haunted/proc/on_wield(obj/item/source, mob/living/carbon/user)
	ADD_TRAIT(user, TRAIT_SIXTHSENSE, MAGIC_TRAIT)
	to_chat(user, span_notice("The veil to the underworld is opened. You can sense the dead souls calling out..."))
	if(!COOLDOWN_FINISHED(src, ghost_alert_cooldown))
		return
	COOLDOWN_START(src, ghost_alert_cooldown, TAROT_GHOST_TIMER)
	notify_ghosts(
		"Someone has begun playing with a [name] in [get_area(src)]!",
		source = src,
		header = "Haunted Tarot Deck",
		ghost_sound = 'sound/effects/ghost2.ogg',
	)

/obj/item/toy/cards/deck/tarot/haunted/proc/on_unwield(obj/item/source, mob/living/carbon/user)
	REMOVE_TRAIT(user, TRAIT_SIXTHSENSE, MAGIC_TRAIT)
	to_chat(user, span_notice("The veil to the underworld closes shut. You feel your senses returning to normal."))

#undef TAROT_GHOST_TIMER

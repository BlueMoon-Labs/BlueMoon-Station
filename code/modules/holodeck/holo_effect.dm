/*
	The holodeck activates these shortly after the program loads,
	and deactivates them immediately before changing or disabling the holodeck.

	These remove snowflake code for special holodeck functions.
*/
/obj/effect/holodeck_effect
	icon = 'icons/mob/screen_gen.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT

/obj/effect/holodeck_effect/proc/activate(var/obj/machinery/computer/holodeck/HC)
	return

/obj/effect/holodeck_effect/proc/deactivate(var/obj/machinery/computer/holodeck/HC)
	qdel(src)
	return

// Called by the holodeck computer as long as the program is running
/obj/effect/holodeck_effect/proc/tick(var/obj/machinery/computer/holodeck/HC)
	return

/obj/effect/holodeck_effect/proc/safety(var/active)
	return


// Generates a holodeck-tracked card deck
/obj/effect/holodeck_effect/cards
	icon = 'icons/obj/toys/toy.dmi'
	icon_state = "deck_nanotrasen_full"
	/// Колода нужна эффекту только для перенастройки безопасности, а дерезит её
	/// консоль сама и спавнеру об этом не сообщает - держим слабой ссылкой.
	var/datum/weakref/deck_ref

/obj/effect/holodeck_effect/cards/activate(obj/machinery/computer/holodeck/HC)
	var/obj/item/toy/cards/deck/deck = new(loc)
	deck_ref = WEAKREF(deck)
	safety(!(HC.obj_flags & EMAGGED))
	deck.holo = HC
	return deck

/obj/effect/holodeck_effect/cards/safety(active)
	var/obj/item/toy/cards/deck/deck = deck_ref?.resolve()
	if(!deck)
		deck_ref = null
		return
	if(active)
		deck.card_hitsound = null
		deck.card_force = 0
		deck.card_throwforce = 0
		deck.card_throw_speed = 3
		deck.card_throw_range = 7
		deck.card_attack_verb = list("attacked")
	else
		deck.card_hitsound = 'sound/weapons/bladeslice.ogg'
		deck.card_force = 5
		deck.card_throwforce = 10
		deck.card_throw_speed = 3
		deck.card_throw_range = 7
		deck.card_attack_verb = list("attacked", "sliced", "diced", "slashed", "cut")


/obj/effect/holodeck_effect/sparks/activate(var/obj/machinery/computer/holodeck/HC)
	var/turf/T = get_turf(src)
	if(T)
		var/datum/effect_system/spark_spread/s = new
		s.set_up(3, 1, T)
		s.start()
		T.set_temperature(5000)
		T.hotspot_expose(50000, 50000, TRUE, TRUE)



/obj/effect/holodeck_effect/mobspawner
	var/mobtype = /mob/living/simple_animal/hostile/carp/holocarp
	/// Моб нужен спавнеру ровно один раз - в deactivate. Консоль дерезит убежавшего
	/// питомца в своём process и спавнеру об этом не сообщает, а спавнер живёт до
	/// смены программы, поэтому жёсткая ссылка держала удалённого моба до конца.
	var/datum/weakref/mob_ref

/obj/effect/holodeck_effect/mobspawner/activate(obj/machinery/computer/holodeck/HC)
	if(islist(mobtype))
		mobtype = pick(mobtype)
	var/mob/spawned_mob = new mobtype(loc)
	mob_ref = WEAKREF(spawned_mob)

	// these vars are not really standardized but all would theoretically create stuff on death
	for(var/v in list("butcher_results","corpse","weapon1","weapon2","blood_volume") & spawned_mob.vars)
		spawned_mob.vars[v] = null
	spawned_mob.flags_1 |= HOLOGRAM_1
	if(isliving(spawned_mob))
		var/mob/living/L = spawned_mob
		L.vore_flags = 0
	return spawned_mob

/obj/effect/holodeck_effect/mobspawner/deactivate(obj/machinery/computer/holodeck/HC)
	var/mob/spawned_mob = mob_ref?.resolve()
	mob_ref = null
	if(spawned_mob && HC)
		HC.derez(spawned_mob)
	qdel(src)

/obj/effect/holodeck_effect/mobspawner/pet
	mobtype = list(
		/mob/living/simple_animal/butterfly, /mob/living/simple_animal/chick/holo,
		/mob/living/simple_animal/pet/cat, /mob/living/simple_animal/pet/cat/kitten,
		/mob/living/simple_animal/pet/dog/corgi, /mob/living/simple_animal/pet/dog/corgi/puppy,
		/mob/living/simple_animal/pet/dog/pug, /mob/living/simple_animal/pet/fox)

/obj/effect/holodeck_effect/mobspawner/bee
	mobtype = /mob/living/simple_animal/hostile/poison/bees/toxin

/obj/effect/holodeck_effect/mobspawner/monkey
	mobtype = /mob/living/simple_animal/holodeck_monkey

/obj/effect/holodeck_effect/mobspawner/penguin
	mobtype = /mob/living/simple_animal/pet/penguin/emperor

/obj/effect/holodeck_effect/mobspawner/penguin/Initialize(mapload)
	if(prob(1))
		mobtype = /mob/living/simple_animal/pet/penguin/emperor/shamebrero
	return ..()

/obj/effect/holodeck_effect/mobspawner/penguin_baby
	mobtype = /mob/living/simple_animal/pet/penguin/baby

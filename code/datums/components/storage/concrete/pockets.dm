/datum/component/storage/concrete/pockets
	max_items = 2
	max_w_class = WEIGHT_CLASS_SMALL
	max_combined_w_class = 50
	rustle_sound = FALSE

/datum/component/storage/concrete/pockets/handle_item_insertion(obj/item/I, prevent_warning, mob/user)
	. = ..()
	if(. && silent && !prevent_warning)
		if(quickdraw)
			to_chat(user, "<span class='notice'>You discreetly slip [I] into [parent]. Alt-click [parent] to remove it.</span>")
		else
			to_chat(user, "<span class='notice'>You discreetly slip [I] into [parent].</span>")

/datum/component/storage/concrete/pockets
	max_w_class = WEIGHT_CLASS_NORMAL

/datum/component/storage/concrete/pockets/small
	max_items = 1
	attack_hand_interact = FALSE

/datum/component/storage/concrete/pockets/small/collar
	max_items = 1

/datum/component/storage/concrete/pockets/small/collar/Initialize()
	. = ..()
	// Static typecaches throughout this file: these Initialize() procs run on
	// every spawn of the owning item, and typecacheof() walks typesof() per
	// entry. Shared lists must never be mutated in place.
	var/static/list/collar_can_hold = typecacheof(list(
	/obj/item/reagent_containers/food/snacks/cookie,
	/obj/item/reagent_containers/food/snacks/sugarcookie,
	/obj/item/card,
	/obj/item/key/collar)) // SPLURT EDIT
	can_hold = collar_can_hold

/datum/component/storage/concrete/pockets/small/collar/locked/Initialize()
	. = ..()
	var/static/list/locked_collar_can_hold = typecacheof(list(
	/obj/item/reagent_containers/food/snacks/cookie,
	/obj/item/reagent_containers/food/snacks/sugarcookie,
	/obj/item/key/collar,
	/obj/item/card))
	can_hold = locked_collar_can_hold

/datum/component/storage/concrete/pockets/tiny
	max_items = 1
	max_w_class = WEIGHT_CLASS_TINY
	attack_hand_interact = FALSE

/datum/component/storage/concrete/pockets/small/detective
	attack_hand_interact = TRUE // so the detectives would discover pockets in their hats

/datum/component/storage/concrete/pockets/shoes
	attack_hand_interact = FALSE
	quickdraw = TRUE
	silent = TRUE

/datum/component/storage/concrete/pockets/shoes/Initialize()
	. = ..()
	var/static/list/shoes_cant_hold = typecacheof(list(/obj/item/screwdriver/power))
	var/static/list/shoes_can_hold = typecacheof(list(
		/obj/item/kitchen/knife, /obj/item/switchblade, /obj/item/pen, /obj/item/melee/cultblade/dagger,
		/obj/item/scalpel, /obj/item/reagent_containers/syringe, /obj/item/dnainjector,
		/obj/item/reagent_containers/hypospray/medipen, /obj/item/reagent_containers/dropper,
		/obj/item/implanter, /obj/item/screwdriver, /obj/item/weldingtool/mini,
		/obj/item/firing_pin, /obj/item/gun/ballistic/automatic/pistol, /obj/item/gun/ballistic/automatic/magrifle/pistol,
		/obj/item/toy/plush/snakeplushie, /obj/item/gun/energy/e_gun/mini, /obj/item/gun/ballistic/derringer,
		/obj/item/toy/crayon/ritualdagger
		))
	cant_hold = shoes_cant_hold
	can_hold = shoes_can_hold

/datum/component/storage/concrete/pockets/shoes/clown/Initialize()
	. = ..()
	var/static/list/clown_shoes_cant_hold = typecacheof(list(/obj/item/screwdriver/power))
	var/static/list/clown_shoes_can_hold = typecacheof(list(
		/obj/item/kitchen/knife, /obj/item/switchblade, /obj/item/pen, /obj/item/melee/cultblade/dagger,
		/obj/item/scalpel, /obj/item/reagent_containers/syringe, /obj/item/dnainjector,
		/obj/item/reagent_containers/hypospray/medipen, /obj/item/reagent_containers/dropper,
		/obj/item/implanter, /obj/item/screwdriver, /obj/item/weldingtool/mini,
		/obj/item/firing_pin, /obj/item/bikehorn, /obj/item/gun/ballistic/automatic/pistol, /obj/item/gun/energy/e_gun/mini,
		/obj/item/toy/crayon/ritualdagger
		))
	cant_hold = clown_shoes_cant_hold
	can_hold = clown_shoes_can_hold

/datum/component/storage/concrete/pockets/pocketprotector
	max_items = 3
	max_w_class = WEIGHT_CLASS_TINY
	var/atom/original_parent

/datum/component/storage/concrete/pockets/pocketprotector/Initialize()
	original_parent = parent
	. = ..()
	var/static/list/protector_can_hold = typecacheof(list( //Same items as a PDA
		/obj/item/pen,
		/obj/item/toy/crayon,
		/obj/item/lipstick,
		/obj/item/flashlight/pen,
		/obj/item/clothing/mask/cigarette))
	can_hold = protector_can_hold

/datum/component/storage/concrete/pockets/pocketprotector/Destroy()
	original_parent = null
	return ..()

/datum/component/storage/concrete/pockets/pocketprotector/real_location()
	// if the component is reparented to a jumpsuit, the items still go in the protector
	return original_parent

/datum/component/storage/concrete/pockets/small/rushelmet
	max_items = 1
	quickdraw = TRUE

/datum/component/storage/concrete/pockets/small/rushelmet/Initialize()
	. = ..()
	var/static/list/rushelmet_can_hold = typecacheof(list(/obj/item/reagent_containers/glass/bottle,
								/obj/item/ammo_box/a762))
	can_hold = rushelmet_can_hold

/datum/component/storage/concrete/pockets/void_cloak
	quickdraw = TRUE
	max_items = 3

/datum/component/storage/concrete/pockets/void_cloak/Initialize()
	. = ..()
	var/static/list/exception_cache = typecacheof(list(/obj/item/living_heart,/obj/item/forbidden_book))

// BLUEMOON ADD Предметы в кустах

/datum/component/storage/concrete/pockets/plants
	max_items = 1
	max_w_class = WEIGHT_CLASS_SMALL
	attack_hand_interact = FALSE
	silent = FALSE
	quickdraw = FALSE // квикдроу показался мне не уместным, но если кто-то захочет - можно добавить

// BLUEMOON ADD END

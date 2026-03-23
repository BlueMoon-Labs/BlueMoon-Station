/obj/item/demolition_hammer	// https://en.wikipedia.org/wiki/Demolition_Hammer
	name = "demolition hammer"
	desc = "Кувалда Старшего Инженера, также известная как \"Молот\" в СССП. Лучший выбор чтобы снести что-то... Или что-то кому-то."
	icon = 'modular_bluemoon/icons/obj/items_and_weapons.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	icon_state = "dmolotred_0"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_NONE	// Blunt damage exclusive.
	slot_flags = NONE		// Doesn't have on_back sprites...
	force = 5
	throwforce = 15
	armour_penetration = 40
	wound_bonus = 8
	bare_wound_bonus = 14
	max_integrity = 200
	attack_verb = list("crushed", "big ironed", "smashed", "destroyed", "demolished", "nailed")
	hitsound = 'modular_bluemoon/fluffs/sound/weapon/stab_hammer.ogg'
	usesound = 'sound/weapons/sonic_jackhammer.ogg'

	// Track wielded status on item.
	var/wielded = FALSE


/obj/item/demolition_hammer/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))


/obj/item/demolition_hammer/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded = 5, force_wielded = 22, icon_wielded = "dmolotred_1")


/obj/item/demolition_hammer/update_icon_state()
	icon_state = "dmolotred_0"


/obj/item/demolition_hammer/attack(mob/living/M, mob/living/user, attackchain_flags, damage_multiplier)
	. = ..()
	if(!wielded)
		wound_bonus = 4
		bare_wound_bonus = 6
	else
		wound_bonus = 8
		bare_wound_bonus = 14


// Fireaxe window breaking feature, reworked
/obj/item/demolition_hammer/afterattack(atom/A, mob/living/user, proximity)
	. = ..()

	if(!proximity || !wielded || IS_STAMCRIT(user))
		return

	if(istype(A, /obj/structure/window/reinforced))	// Works better with unarmored windows.
		var/obj/structure/window/reinforced/reinforced = A
		reinforced.take_damage(10, BRUTE, MELEE, FALSE)
		user.visible_message(span_warning("Головка кувалды отскочила от стекла!"))

	else if(istype(A, /obj/structure/window/plasma))
		var/obj/structure/window/plasma/plasma = A
		plasma.take_damage(5, BRUTE, MELEE, FALSE)
		user.visible_message(span_warning("Головка кувалды отскочила от плазма-стекла!"))

	else if(istype(A, /obj/structure/window)) // Unarmored breaks in ~2 hits.
		var/obj/structure/window/window = A
		window.take_damage(15, BRUTE, MELEE, FALSE)


// Triggered on wield of two handed item.
/obj/item/demolition_hammer/proc/on_wield(obj/item/source, mob/user)
	wielded = TRUE


// Triggered on unwield of two handed item.
/obj/item/demolition_hammer/proc/on_unwield(obj/item/source, mob/user)
	wielded = FALSE

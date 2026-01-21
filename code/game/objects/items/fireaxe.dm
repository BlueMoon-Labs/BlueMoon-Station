/*
 * Fireaxe
 */
/obj/item/fireaxe  // DEM AXES MAN, marker -Agouri
	icon_state = "fireaxe0"
	lefthand_file = 'icons/mob/inhands/weapons/axes_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/axes_righthand.dmi'
	name = "fire axe"
	desc = "Truly, the weapon of a madman. Who would think to fight fire with an axe?"
	force = 5
	throwforce = 15
	armour_penetration = 25
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	attack_verb = list("attacked", "chopped", "cleaved", "torn", "cut")
	hitsound = 'sound/weapons/bladeslice.ogg'
	sharpness = SHARP_EDGED
	max_integrity = 200
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 30)
	resistance_flags = FIRE_PROOF
	wound_bonus = 7
	bare_wound_bonus = 12
	tool_behaviour = TOOL_CROWBAR
	can_force_powered = TRUE
	var/wielded = FALSE // track wielded status on item

/obj/item/fireaxe/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/fireaxe/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/butchering, 100, 80, 0 , hitsound) //axes are not known for being precision butchering tools
	AddComponent(/datum/component/two_handed, force_unwielded=5, force_wielded=28, icon_wielded="fireaxe1")

/// triggered on wield of two handed item
/obj/item/fireaxe/proc/on_wield(obj/item/source, mob/user)
	wielded = TRUE

/// triggered on unwield of two handed item
/obj/item/fireaxe/proc/on_unwield(obj/item/source, mob/user)
	wielded = FALSE

/* Check modular_bluemoon\code\game\objects\items\energy_axe.dm
/obj/item/fireaxe/update_icon_state()
	icon_state = "fireaxe0"
*/

/obj/item/fireaxe/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] axes себя from head to toe! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (BRUTELOSS)

/obj/item/fireaxe/afterattack(atom/A, mob/living/user, proximity)
	. = ..()
	if(!proximity || !wielded || IS_STAMCRIT(user))
		return
	if(istype(A, /obj/structure/window)) //destroys windows and grilles in one hit (or more if it has a ton of health like plasmaglass)
		var/obj/structure/window/W = A
		W.take_damage(200, BRUTE, MELEE, 0)
	else if(istype(A, /obj/structure/grille))
		var/obj/structure/grille/G = A
		G.take_damage(40, BRUTE, MELEE, 0)

/*
 * Bone Axe
 */
/obj/item/fireaxe/boneaxe  // Blatant imitation of the fireaxe, but made out of bone.
	icon_state = "bone_axe0"
	name = "bone axe"
	desc = "A large, vicious axe crafted out of several sharpened bone plates and crudely tied together. Made of monsters, by killing monsters, for killing monsters."

/obj/item/fireaxe/boneaxe/update_icon_state()
	icon_state = "bone_axe0"

/obj/item/fireaxe/boneaxe/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=5, force_wielded=23, icon_wielded="bone_axe1")

/obj/item/fireaxe/boneaxe/ShisHar  //An artifact of the Ashwalker tribe, one of a kind.
	icon_state = "bonemetal_axe0"
	name = "ShisHar"
	desc = "Forged from Lavalands depths, this axe slays only intelligent beings."

/obj/item/fireaxe/boneaxe/ShisHar/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=12, force_wielded=35, icon_wielded="bonemetal_axe1")

/obj/item/fireaxe/energized
	desc = "Someone with a love for fire axes decided to turn this one into a high-powered energy weapon. Seems excessive."
	armour_penetration = 50
	icon_state = "fireaxe_old0"
	icon = 'modular_bluemoon/icons/obj/items_and_weapons.dmi'
	var/charge = 90
	var/max_charge = 90

/obj/item/fireaxe/energized/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=12, force_wielded=30, icon_wielded="fireaxe_old1")

/obj/item/fireaxe/energized/update_icon_state()
		icon_state = "fireaxe_old0"

/obj/item/fireaxe/energized/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/fireaxe/energized/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/fireaxe/energized/process()
	charge = min(charge + 1, max_charge)

/obj/item/fireaxe/energized/attack(mob/M, mob/user)
	. = ..()
	if(wielded && charge == max_charge)
		if(isliving(M))
			var/mob/living/target = M
			charge = 0
			playsound(loc, 'sound/magic/lightningbolt.ogg', 5, 1)
			user.visible_message("<span class='danger'>[user] slams the charged axe into [M.name] with all [user.p_their()] might!</span>")
			do_sparks(1, 1, src)
			target.DefaultCombatKnockdown(60)
			target.confused += 15
			var/atom/throw_target = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
			M.throw_at(throw_target, 5, 1)

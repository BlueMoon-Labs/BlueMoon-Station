// Team Deathmatch C4.
//
// This is deliberately a standalone item rather than a regular grenade subtype:
// the mode needs a visible, clickable planted object, a fixed fuse and CT-only
// defusing, none of which the normal plastic-explosive planting code provides.

/obj/item/deathmatch_c4
	name = "C4"
	desc = "A Team Deathmatch bomb. Use it in your hand while standing in plant_a or plant_b to plant it."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "plastic-explosive0"
	item_state = "plastic-explosive"
	lefthand_file = 'icons/mob/inhands/weapons/bombs_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/bombs_righthand.dmi'
	item_flags = NOBLUDGEON
	flags_1 = NONE
	resistance_flags = INDESTRUCTIBLE
	w_class = WEIGHT_CLASS_SMALL

	/// The TDM lobby which issued this bomb. Also validates who may interact.
	var/datum/deathmatch_lobby/team_deathmatch/lobby
	/// Time needed to plant, defuse, and wait for detonation respectively.
	var/plant_time = 3 SECONDS
	var/defuse_time = 5 SECONDS
	var/fuse_time = 45 SECONDS
	/// Explosion radii: devastation, heavy, light. Kept configurable for tests.
	var/list/explosion_size = list(3, 7, 14)

	var/planted = FALSE
	/// Set after defusal, detonation, or the end of the round. An inactive bomb
	/// cannot start another countdown or be defused a second time.
	var/resolved = FALSE
	var/defuse_in_progress = FALSE
	var/plant_zone
	var/detonation_timer
	var/detonation_ends_at
	var/mob/living/planter

/obj/item/deathmatch_c4/Destroy()
	if(detonation_timer)
		deltimer(detonation_timer)
		detonation_timer = null
	if(!isnull(lobby))
		// Normally the lobby has already cleared bomb_planted by this point. If
		// an admin or unexpected code deleted an active bomb instead, this also
		// restores elimination and round-timer resolution instead of stalling.
		lobby.on_bomb_deleted(src)
	lobby = null
	planter = null
	return ..()

/obj/item/deathmatch_c4/examine(mob/user)
	. = ..()
	if(planted && !resolved && detonation_ends_at)
		. += span_userdanger("До взрыва: [DisplayTimeText(max(0, detonation_ends_at - world.time))].")
	else if(!planted)
		. += span_notice("Используйте C4 в руке, стоя в зоне plant_a или plant_b.")

/// Returns the callout letter only when the turf belongs to a designated plant
/// area. Painting more plant_a/plant_b areas on a TDM map needs no code changes.
/obj/item/deathmatch_c4/proc/get_plant_zone(turf/T)
	if(isnull(T))
		return null
	var/area/A = get_area(T)
	if(istype(A, /area/deathmatch/tdm/plant_a))
		return "A"
	if(istype(A, /area/deathmatch/tdm/plant_b))
		return "B"
	return null

/obj/item/deathmatch_c4/attack_self(mob/user)
	try_plant(user)
	return TRUE

/obj/item/deathmatch_c4/proc/try_plant(mob/living/user)
	if(planted || resolved)
		return FALSE
	if(isnull(lobby) || !lobby.can_plant_bomb(user))
		to_chat(user, span_warning("Установить эту C4 может только живой террорист из текущего TDM-раунда."))
		return FALSE
	if(!user.is_holding(src))
		to_chat(user, span_warning("Возьмите C4 в руку, чтобы установить её."))
		return FALSE

	var/turf/plant_turf = get_turf(user)
	var/zone = get_plant_zone(plant_turf)
	if(isnull(zone))
		to_chat(user, span_warning("C4 можно установить только в зонах plant_a и plant_b."))
		return FALSE

	user.visible_message(
		span_warning("[user] начинает устанавливать C4."),
		span_notice("Вы начинаете установку C4. Не двигайтесь."),
	)
	if(!do_after(user, plant_time, target = src))
		return FALSE
	// Both the zone and round state may have changed during the planting bar.
	plant_turf = get_turf(user)
	zone = get_plant_zone(plant_turf)
	if(isnull(zone) || isnull(lobby) || !lobby.can_plant_bomb(user) || !user.is_holding(src))
		to_chat(user, span_warning("Установка C4 прервана."))
		return FALSE
	if(!user.temporarilyRemoveItemFromInventory(src))
		return FALSE

	planter = user
	forceMove(plant_turf)
	anchored = TRUE
	planted = TRUE
	plant_zone = zone
	visible_message(span_userdanger("[user] установил C4 на точке [zone]!"))
	playsound(plant_turf, 'sound/weapons/armbomb.ogg', 60, TRUE)

	if(!lobby.on_bomb_planted(src, zone))
		// The round ended on the same tick as the planting completed. Leave an
		// ordinary unplanted item on the floor rather than starting a stale fuse.
		planted = FALSE
		anchored = FALSE
		plant_zone = null
		return FALSE

	detonation_ends_at = world.time + fuse_time
	detonation_timer = addtimer(CALLBACK(src, PROC_REF(detonate)), fuse_time)
	return TRUE

/// Clicking a planted bomb with an empty hand starts the CT defusal bar. A
/// second defuser cannot run a competing bar on the same bomb.
/obj/item/deathmatch_c4/attack_hand(mob/user)
	if(!planted)
		// As in Counter-Strike, a dropped bomb can be picked up by either
		// Terrorist, but a Counter-Terrorist cannot simply carry it away.
		if(!isnull(lobby) && !lobby.can_plant_bomb(user))
			to_chat(user, span_warning("Подобрать C4 может только живой террорист из текущего TDM-раунда."))
			return TRUE
		return ..()
	if(resolved)
		to_chat(user, span_notice("Эта C4 уже не представляет опасности."))
		return TRUE
	if(!ishuman(user) || !user.Adjacent(src) || user.incapacitated())
		return TRUE
	if(isnull(lobby) || !lobby.can_defuse_bomb(user))
		to_chat(user, span_warning("Обезвредить C4 может только живой контр-террорист из текущего раунда."))
		return TRUE
	if(defuse_in_progress)
		to_chat(user, span_warning("C4 уже обезвреживают."))
		return TRUE

	defuse_in_progress = TRUE
	user.visible_message(
		span_warning("[user] начинает обезвреживать C4."),
		span_userdanger("Вы начинаете обезвреживать C4. Не двигайтесь."),
	)
	var/succeeded = do_after(user, defuse_time, target = src)
	if(QDELETED(src))
		return TRUE
	defuse_in_progress = FALSE
	if(!succeeded || resolved || !planted)
		return TRUE
	if(isnull(lobby) || !lobby.can_defuse_bomb(user))
		return TRUE
	defuse(user)
	return TRUE

/obj/item/deathmatch_c4/proc/defuse(mob/living/user)
	if(resolved || !planted)
		return FALSE
	resolved = TRUE
	planted = FALSE
	if(detonation_timer)
		deltimer(detonation_timer)
		detonation_timer = null
	visible_message(span_boldnotice("[user] обезвредил C4."))
	playsound(src, 'sound/machines/twobeep.ogg', 50, TRUE)
	if(!isnull(lobby))
		lobby.on_bomb_defused(src, user)
	log_game("Deathmatch: C4 defused by [key_name(user)] at [AREACOORD(src)].")
	qdel(src)
	return TRUE

/// Stops the fuse when a round ends by elimination or is aborted by the host.
/// The object remains visible during the intermission and is removed next round.
/obj/item/deathmatch_c4/proc/deactivate()
	resolved = TRUE
	if(detonation_timer)
		deltimer(detonation_timer)
		detonation_timer = null

/obj/item/deathmatch_c4/proc/detonate()
	if(resolved || !planted)
		return FALSE
	resolved = TRUE
	planted = FALSE
	detonation_timer = null
	var/turf/epicenter = get_turf(src)
	visible_message(span_userdanger("<big>C4 ВЗОРВАЛАСЬ!</big>"))

	// Award the round before the explosion can kill the remaining avatars and
	// trigger the ordinary elimination checks a second time.
	if(!isnull(lobby))
		lobby.on_bomb_detonated(src)
	if(!isnull(epicenter))
		explosion(
			epicenter,
			explosion_size[1],
			explosion_size[2],
			explosion_size[3],
			attacker = planter,
		)
	log_game("Deathmatch: C4 detonated at [AREACOORD(epicenter)].")
	qdel(src)
	return TRUE

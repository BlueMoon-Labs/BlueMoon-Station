/obj/item/hilbertshotel
	name = "Hilbert's Hotel"
	desc = "A sphere of what appears to be an intricate network of bluespace. Observing it in detail seems to give you a headache as you try to comprehend the infinite amount of infinitesimally distinct points on its surface."
	icon_state = "hilbertshotel"
	w_class = WEIGHT_CLASS_GIGANTIC
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/rooms_can_be_locked = FALSE
	var/is_ghost_cafe = FALSE
	var/ruinSpawned = FALSE
	var/list/list/mob_dorms = list()
	var/list/activeRooms = list()
	var/list/storedRooms = list()
	var/list/checked_in_ckeys = list()
	var/list/lockedRooms = list()
	light_color = "#5692d6"
	light_range = 5
	light_power = 3

/obj/item/hilbertshotel/ghostdojo
	name = "Infinite Dormitories"
	anchored = TRUE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND

/obj/item/hilbertshotel/ghostdojo/ghostcafe
	rooms_can_be_locked = TRUE

/obj/item/hilbertshotel/Initialize(mapload)
	. = ..()
	if(!length(SShilbertshotel.hotel_map_list) && CONFIG_GET(flag/hilbertshotel_enabled))
		INVOKE_ASYNC(SShilbertshotel, TYPE_PROC_REF(/datum/controller/subsystem/hilbertshotel, prepare_rooms))

	SShilbertshotel.all_hilbert_spheres += src

/obj/item/hilbertshotel/Destroy()
	SShilbertshotel.all_hilbert_spheres -= src
	ejectRooms()
	return ..()

/obj/item/hilbertshotel/attack(mob/living/M, mob/living/user)
	if(M.mind)
		to_chat(user, span_notice("You invite [M] to the hotel."))
		ui_interact(user)
	else
		to_chat(user, span_warning("[M] is not intelligent enough to understand how to use this device!"))

/obj/item/hilbertshotel/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/hilbertshotel/ui_interact(mob/user, datum/tgui/ui)
	if(!check_user(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HilbertsHotelCheckout")
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/item/hilbertshotel/ui_static_data(mob/user)
	. = ..()

	// Shouldn't change during the round so we may as well cache it
	.["hotel_map_list"] = list()
	for(var/template in SShilbertshotel.hotel_map_list)
		var/datum/map_template/hilbertshotel/room_template = SShilbertshotel.hotel_map_list[template]
		.["hotel_map_list"] += list(list(
			"name" = room_template.name,
			"category" = room_template.category,
			"donator_tier" = room_template.donator_tier,
			"ckeywhitelist" = room_template.ckeywhitelist
		))

/obj/item/hilbertshotel/ui_data(mob/user)
	var/list/data = list()

	if(!SShilbertshotel.user_data[user.ckey])
		SShilbertshotel.user_data[user.ckey] = list(
			"room_number" = 1,
			"template" = SShilbertshotel.default_template,
			"donator_tier" = is_donator_group(user.ckey, DONATOR_GROUP_TIER_2) ? DONATOR_GROUP_TIER_2 : is_donator_group(user.ckey, DONATOR_GROUP_TIER_1) ? DONATOR_GROUP_TIER_1 : DONATOR_GROUP_NONE
		)

	data["current_room"] = SShilbertshotel.user_data[user.ckey]["room_number"]
	data["selected_template"] = SShilbertshotel.user_data[user.ckey]["template"]
	data["user_donator_tier"] = SShilbertshotel.user_data[user.ckey]["donator_tier"]
	data["user_ckey"] = user.ckey


	data["active_rooms"] = list()
/*
	for(var/room_number in SShilbertshotel.room_data)
		var/list/room = SShilbertshotel.room_data["[room_number]"]
		if(room["room_preferences"]["visibility"] == ROOM_VISIBLE && (room["is_ghost_cafe"] == is_ghost_cafe || !CONFIG_GET(flag/hilbertshotel_ghost_cafe_restricted)))
			data["active_rooms"] += list(list(
				"number" = room_number,
				"occupants" = SShilbertshotel.generate_occupant_list(room_number),
				"room_preferences" = room["room_preferences"]
			))
*/
	data["conservated_rooms"] = list()
/*
	for(var/room_number in SShilbertshotel.conservated_rooms)
		var/list/room = SShilbertshotel.conservated_rooms[room_number]
		var/visibility = room["room_preferences"]["visibility"]
		if(room["is_ghost_cafe"] != is_ghost_cafe && CONFIG_GET(flag/hilbertshotel_ghost_cafe_restricted))
			continue
		switch(visibility)
			if(ROOM_VISIBLE)
				data["conservated_rooms"] += list(list(
					"number" = room_number,
					"room_preferences" = room["room_preferences"]
					))
			if(ROOM_GUESTS_ONLY)
				if((user.mind in room["access_restrictions"]["trusted_guests"]) || (user.mind == room["access_restrictions"]["room_owner"]))
					data["conservated_rooms"] += list(list(
						"number" = room_number,
						"room_preferences" = room["room_preferences"]
					))
			if(ROOM_CLOSED)
				if((user.mind == room["access_restrictions"]["room_owner"]))
					data["conservated_rooms"] += list(list(
						"number" = room_number,
						"room_preferences" = room["room_preferences"]
					))
*/
	return data

/obj/item/hilbertshotel/ui_act(action, params)
	. = ..()
	if(.) // Orange eye; updates but is not interactive
		return

	if(!usr.ckey)
		return

	if(!SShilbertshotel.user_data[usr.ckey])
		SShilbertshotel.user_data[usr.ckey] = list(
			"room_number" = 1,
			"template" = SShilbertshotel.default_template
		)

	switch(action)
		if("update_room")
			var/new_room = params["room"]
			if(!new_room)
				return FALSE
			if(new_room < 1)
				return FALSE
			SShilbertshotel.user_data[usr.ckey]["room_number"] = new_room
			return TRUE

		if("select_room")
			var/template_name = params["room"]
			if(!(template_name in SShilbertshotel.hotel_map_list))
				return FALSE
			SShilbertshotel.user_data[usr.ckey]["template"] = template_name
			return TRUE

		if("checkin")
			var/template = SShilbertshotel.user_data[usr.ckey]["template"] || SShilbertshotel.default_template
			var/room_number = params["room"] || SShilbertshotel.user_data[usr.ckey]["room_number"] || 1
			if(!room_number || !(template in SShilbertshotel.hotel_map_list))
				return FALSE
			var/mob/living/user = usr
			if(type == /obj/item/hilbertshotel)
				user = istype(loc, /mob/living) ? loc : usr
			promptAndCheckIn(user, usr, room_number, template)
			return TRUE

/obj/item/hilbertshotel/proc/check_user(mob/user)
	if(GLOB.master_mode == "Extended")
		return TRUE
	if(!user.mind)
		return TRUE

	var/datum/mind/mind = user.mind
	if(!(mind.antag_datums || HAS_MIND_TRAIT(user, TRAIT_MINDSHIELD)))
		return TRUE
	if(mind.has_antag_datum(/datum/antagonist/ghost_role))
		return TRUE
	if(mind.has_antag_datum(/datum/antagonist/ashwalker))
		return TRUE

	to_chat(user, "<span class='warning'>Your special role doesn't allow you to enter infinity dormitory.</span>")
	return FALSE

/obj/item/hilbertshotel/proc/promptAndCheckIn(mob/user, mob/target, room_number, template)
	//SPLURT EDIT - max infinidorms rooms
	var/max_rooms = CONFIG_GET(number/max_infinidorms)
	if(!max_rooms)
		playsound(src, 'sound/machines/terminal_error.ogg', 15, 1)
		to_chat(user, span_warning("We're currently not offering service, please come back another day!"))
		return

	if(!mob_dorms[user] || !mob_dorms[user].Find(room_number)) //BLUEMOON ADD владелец комнаты может зайти в комнату даже если она закрыта и активна
		if(activeRooms.len && activeRooms["[room_number]"])	//лесенка ради удобства восприятия, точно-точно говорю
			if(lockedRooms.len && lockedRooms["[room_number]"])
				to_chat(user, span_warning("You cant enter in locked room, contact with room owner."))
				return												//BLUEMOON ADD END
	if(max_rooms > 0 && mob_dorms[user]?.len >= max_rooms && !activeRooms["[room_number]"] && !storedRooms["[room_number]"])
		to_chat(user, span_warning("Your free trial of Hilbert's Hotel has ended! Please select one of the rooms you've already visited."))
		room_number = input(user, "Select one of your previous rooms", "Room number") as null|anything in mob_dorms[user]

	//SPLURT EDIT END
	if(!room_number || !user.CanReach(src))
		return
	if(room_number > SHORT_REAL_LIMIT)
		to_chat(user, span_warning("You have to check out the first [SHORT_REAL_LIMIT] rooms before you can go to a higher numbered one!"))
		return
	if((room_number < 1) || (room_number != round(room_number)))
		to_chat(user, span_warning("That is not a valid room number!"))
		return
	if(!isturf(loc))
		if((loc == user) || (loc.loc == user) || (loc.loc in user.contents) || (loc in user.GetAllContents(type)))		//short circuit, first three checks are cheaper and covers almost all cases (loc.loc covers hotel in box in backpack).
			forceMove(get_turf(user))

	if(!SShilbertshotel.storageTurf) //Blame subsystems for not allowing... huh...
		SShilbertshotel.setup_storage_turf()
	checked_in_ckeys |= user.ckey		//if anything below runtimes, guess you're outta luck!
	if(tryActiveRoom(room_number, user))
		return
	if(tryStoredRoom(room_number, user))
		return
	sendToNewRoom(room_number, user, template)

/area/hilbertshotel/proc/storeRoom()
	// Calculate the actual room size based on the reservation coordinates
	var/roomWidth = reservation.top_right_coords[1] - reservation.bottom_left_coords[1] + 1
	var/roomHeight = reservation.top_right_coords[2] - reservation.bottom_left_coords[2] + 1
	var/roomSize = roomWidth * roomHeight
	var/storage[roomSize]
	var/turfNumber = 1
	var/obj/item/abstracthotelstorage/storageObj = new(SShilbertshotel.storageTurf)
	storageObj.roomNumber = roomnumber
	storageObj.parentSphere = parentSphere
	storageObj.roomType = roomType // Save the room type here
	storageObj.name = "Room [roomnumber] Storage"
	for(var/i=0, i<roomWidth, i++)
		for(var/j=0, j<roomHeight, j++)
			var/turf/T = locate(reservation.bottom_left_coords[1] + i, reservation.bottom_left_coords[2] + j, reservation.bottom_left_coords[3])
			var/list/turfContents = list()
			for(var/atom/movable/A in T)
				if(istype(A, /obj/effect/overlay/water) || istype(A, /obj/effect/overlay/water/top) || istype(A, /obj/machinery/atmospherics/components)) // Skip pool water and effects, and atmos components
					continue
				if(ismob(A) && !isliving(A) || !isturf(A.loc)) // Turf check for items that are inside containers
					continue // Don't want to store ghosts
				turfContents += A
				A.forceMove(storageObj)
			storage[turfNumber] = turfContents
			turfNumber++
	parentSphere.storedRooms["[roomnumber]"] = storage
	parentSphere.activeRooms -= "[roomnumber]"
	qdel(reservation)

/area/hilbertshotel/proc/update_light_switches() //SPLURT ADDITION: This will update all light switches in the given area
	for(var/obj/machinery/light_switch/LS in src)
		LS.area = src // Update the area reference for each light switch
		LS.update_appearance() // Update the appearance of the light switch

/obj/item/hilbertshotel/proc/tryActiveRoom(var/roomNumber, var/mob/user)
	if(!activeRooms["[roomNumber]"])
		return FALSE
	var/datum/turf_reservation/roomReservation = activeRooms["[roomNumber]"]
	var/area/hilbertshotel/currentArea = get_area(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	var/datum/map_template/hilbertshotel/mapTemplate = getMapTemplate(currentArea.roomType)

	do_sparks(3, FALSE, get_turf(user))
	MobTransfer(user, locate(roomReservation.bottom_left_coords[1] + mapTemplate.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + mapTemplate.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
	return TRUE

/obj/item/hilbertshotel/proc/tryStoredRoom(var/roomNumber, var/mob/user)
// SPLURT EDIT START: Load the correct stored room by loading an empty template and adding stored atoms on top of it.
	if(!storedRooms["[roomNumber]"])
		return FALSE
	// Find the storage object for the stored room
	var/obj/item/abstracthotelstorage/storageObj
	for(var/obj/item/abstracthotelstorage/S in SShilbertshotel.storageTurf)
		if(S.roomNumber == roomNumber && S.parentSphere == src)
			storageObj = S
			break

	if(!storageObj)
		return FALSE // No storage object found for this room number

	// Use the stored roomType from the storage object
	var/datum/map_template/hilbertshotel/mapTemplate = getMapTemplate(storageObj.roomType)
	var/datum/turf_reservation/roomReservation = SSmapping.RequestBlockReservation(mapTemplate.width, mapTemplate.height)
	mapTemplate.load(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))

	// Clear all movable atoms from the loaded room template
	for(var/i in 0 to mapTemplate.width - 1)
		for(var/j in 0 to mapTemplate.height - 1)
			var/turf/T = locate(roomReservation.bottom_left_coords[1] + i, roomReservation.bottom_left_coords[2] + j, roomReservation.bottom_left_coords[3])
			for(var/atom/movable/A in T)
				if(istype(A, /obj/effect/overlay/water) || istype(A, /obj/effect/overlay/water/top)) // Skip pool water overlays
					continue
				QDEL_LIST(A.contents)
				qdel(A)

	// Place the STORED atoms back into the room
	var/turfNumber = 1
	for(var/i in 0 to mapTemplate.width - 1)
		for(var/j in 0 to mapTemplate.height - 1)
			for(var/atom/movable/A in storedRooms["[roomNumber]"][turfNumber])
				if(istype(A.loc, /obj/item/abstracthotelstorage)) // Don't want to recall something that's been moved
					A.forceMove(locate(roomReservation.bottom_left_coords[1] + i, roomReservation.bottom_left_coords[2] + j, roomReservation.bottom_left_coords[3]))
			turfNumber++
	for(var/obj/item/abstracthotelstorage/S in SShilbertshotel.storageTurf)
		if((S.roomNumber == roomNumber) && (S.parentSphere == src))
			qdel(S)

	// Re-Set the room type
	var/area/hilbertshotel/currentArea = get_area(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	if(storageObj)
		currentArea.roomType = storageObj.roomType // Set the room type for the area
		currentArea.update_light_switches() // Update all light switches in the area

	storedRooms -= "[roomNumber]"
	activeRooms["[roomNumber]"] = roomReservation

	//To send the user one tile above default when teleported
	// SPLURT EDIT END
	linkTurfs(roomReservation, roomNumber)
	do_sparks(3, FALSE, get_turf(user))
	MobTransfer(user, locate(roomReservation.bottom_left_coords[1] + mapTemplate.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + mapTemplate.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
	return TRUE

/obj/item/hilbertshotel/proc/MobTransfer(mob/living/user, turf/T, depth = 0)
	depth++
	if(depth > 4)
		return
	if(!istype(T))
		return
	var/atom/movable/AM
	if(user.pulling)
		AM = user.pulling
		if(istype(AM, /mob/living))
			if(check_user(AM))
				MobTransfer(AM, T, depth)
		else
			AM.forceMove(T)
	if(user.buckled && !user.buckled.anchored)
		var/atom/movable/seating = user.buckled
		if(istype(seating, /mob/living))
			if(check_user(seating))
				MobTransfer(seating, T, depth)
			else
				user.forceMove(T)
		else
			seating.forceMove(T)
			user.forceMove(T)
			seating.buckle_mob(user, TRUE, TRUE)
	else if(user.buckled_mobs)
		var/datum/component/riding/human/riding_datum_human = user.GetComponent(/datum/component/riding/human)
		var/mob/living/buckled_mob
		for(var/mob/living/I in user.buckled_mobs)
			buckled_mob = I
			I.forceMove(T)
		user.unbuckle_all_mobs(TRUE)
		user.forceMove(T)
		if(riding_datum_human && ishuman(user))
			var/mob/living/carbon/human/H = user
			H.buckle_mob(buckled_mob, TRUE, TRUE, buckle_type = riding_datum_human.buckle_type, auto_by_type = TRUE)
		else
			user.buckle_mob(buckled_mob, TRUE, TRUE)
	else
		user.forceMove(T)
	if(AM)
		user.start_pulling(AM)

/obj/item/hilbertshotel/proc/getMapTemplate(roomType) // To load a map and remove it's atoms
	if(roomType == "Mystery Room")
		return SShilbertshotel.hotel_room_template_lore
	else if(roomType in SShilbertshotel.hotel_map_list)
		return SShilbertshotel.hotel_map_list[roomType]

	return SShilbertshotel.hotel_room_template // Default to Hotel Room if no match is found

/obj/item/hilbertshotel/proc/sendToNewRoom(roomNumber, mob/user, chosen_room)
	var/datum/map_template/hilbertshotel/mapTemplate

	if(SShilbertshotel.lore_room_spawned && roomNumber == SShilbertshotel.hhMysteryroom_number)
		chosen_room = "Mystery Room"
		mapTemplate = SShilbertshotel.hotel_room_template_lore
	else
		mapTemplate = SShilbertshotel.hotel_map_list[chosen_room]
	if(!mapTemplate)
		mapTemplate = SShilbertshotel.hotel_room_template //Default Hotel Room

	var/datum/turf_reservation/roomReservation = SSmapping.RequestBlockReservation(mapTemplate.width, mapTemplate.height)
	mapTemplate.load(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	activeRooms["[roomNumber]"] = roomReservation

	// Set the room type for the newly created area
	var/area/hilbertshotel/currentArea = get_area(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	currentArea.roomType = chosen_room // Sets the room type here

	linkTurfs(roomReservation, roomNumber)
	do_sparks(3, FALSE, get_turf(user))
	MobTransfer(user, locate(roomReservation.bottom_left_coords[1] + mapTemplate.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + mapTemplate.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
	if(!mob_dorms[user]?.Find(roomNumber))
		LAZYADD(mob_dorms[user], roomNumber)

/obj/item/hilbertshotel/proc/linkTurfs(var/datum/turf_reservation/currentReservation, var/currentRoomnumber, var/chosen_room)
	var/area/hilbertshotel/currentArea = get_area(locate(currentReservation.bottom_left_coords[1], currentReservation.bottom_left_coords[2], currentReservation.bottom_left_coords[3]))
	currentArea.name = "Hilbert's Hotel Room [currentRoomnumber]"
	currentArea.parentSphere = src
	currentArea.storageTurf = SShilbertshotel.storageTurf
	currentArea.roomnumber = currentRoomnumber
	currentArea.reservation = currentReservation
	for(var/turf/closed/indestructible/hoteldoor/door in currentArea)
		door.parentSphere = src
		door.roomnumber = currentRoomnumber
	for(var/turf/open/space/bluespace/BSturf in currentArea)
		BSturf.parentSphere = src

/obj/item/hilbertshotel/proc/ejectRooms()
	if(activeRooms.len)
		for(var/x in activeRooms)
			var/datum/turf_reservation/room = activeRooms[x]
			for(var/i in 0 to room.width-1)
				for(var/j in 0 to room.height-1)
					for(var/atom/movable/A in locate(room.bottom_left_coords[1] + i, room.bottom_left_coords[2] + j, room.bottom_left_coords[3]))
						if(ismob(A))
							var/mob/M = A
							if(M.mind)
								to_chat(M, "<span class='warning'>As the sphere breaks apart, you're suddenly ejected into the depths of space!</span>")
						var/max = world.maxx-TRANSITIONEDGE
						var/min = 1+TRANSITIONEDGE
						var/list/possible_transtitons = list()
						for(var/AZ in SSmapping.z_list)
							var/datum/space_level/D = AZ
							if(D.linkage == CROSSLINKED)
								possible_transtitons += D.z_value
						var/_z = pick(possible_transtitons)
						var/_x = rand(min,max)
						var/_y = rand(min,max)
						var/turf/T = locate(_x, _y, _z)
						A.forceMove(T)
			qdel(room)

	if(storedRooms.len)
		for(var/x in storedRooms)
			var/list/atomList = storedRooms[x]
			for(var/atom/movable/A in atomList)
				var/max = world.maxx-TRANSITIONEDGE
				var/min = 1+TRANSITIONEDGE
				var/list/possible_transtitons = list()
				for(var/AZ in SSmapping.z_list)
					var/datum/space_level/D = AZ
					if (D.linkage == CROSSLINKED)
						possible_transtitons += D.z_value
				var/_z = pick(possible_transtitons)
				var/_x = rand(min,max)
				var/_y = rand(min,max)
				var/turf/T = locate(_x, _y, _z)
				A.forceMove(T)

//Turfs and Areas
/turf/closed/indestructible/hotelwall
	name = "hotel wall"
	desc = "A wall designed to protect the security of the hotel's guests."
	icon_state = "hotelwall"
	canSmoothWith = list(/turf/closed/indestructible/hotelwall)
	explosion_block = INFINITY

/turf/open/indestructible/hotelwood
	desc = "Stylish dark wood with extra reinforcement. Secured firmly to the floor to prevent tampering."
	icon_state = "wood"
	footstep = FOOTSTEP_WOOD
	tiled_dirt = FALSE

/turf/open/indestructible/hoteltile
	desc = "Smooth tile with extra reinforcement. Secured firmly to the floor to prevent tampering."
	icon_state = "showroomfloor"
	footstep = FOOTSTEP_FLOOR
	tiled_dirt = FALSE

/turf/open/space/bluespace
	name = "\proper bluespace hyperzone"
	icon_state = "bluespace"
	baseturfs = /turf/open/space/bluespace
	flags_1 = NOJAUNT_1
	explosion_block = INFINITY
	var/obj/item/hilbertshotel/parentSphere

/turf/open/space/bluespace/Entered(atom/movable/A)
	. = ..()
	if (parentSphere)
		A.forceMove(get_turf(parentSphere))

/turf/closed/indestructible/hoteldoor
	name = "Hotel Door"
	icon_state = "hoteldoor"
	explosion_block = INFINITY
	var/obj/item/hilbertshotel/parentSphere
	var/roomnumber
	desc = "The door to this hotel room. Strange, this door doesnt even seem openable. The doorknob, however, seems to buzz with unusual energy..."

/turf/closed/indestructible/hoteldoor/proc/promptExit(mob/living/user)
	if(!isliving(user))
		return
	if(!user.mind)
		return
	if(!parentSphere)
		to_chat(user, "<span class='warning'>The door seems to be malfunctioning and refuses to operate!</span>")
		return
	if(alert(user, "Hilbert's Hotel would like to remind you that while we will do everything we can to protect the belongings you leave behind, we make no guarantees of their safety while you're gone, especially that of the health of any living creatures. With that in mind, are you ready to leave?", "Exit", "Leave", "Stay") == "Leave")
		if(!CHECK_MOBILITY(user, MOBILITY_MOVE) || (get_dist(get_turf(src), get_turf(user)) > 1)) //no teleporting around if they're dead or moved away during the prompt.
			return
		parentSphere.MobTransfer(user, get_turf(parentSphere))
		do_sparks(3, FALSE, get_turf(user))

/turf/closed/indestructible/hoteldoor/attack_ghost(mob/dead/observer/user)
	if(!isobserver(user) || !parentSphere)
		return ..()
	user.forceMove(get_turf(parentSphere))

//If only this could be simplified...
/turf/closed/indestructible/hoteldoor/attack_tk(mob/user)
	return //need to be close.

/turf/closed/indestructible/hoteldoor/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_animal(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_paw(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_hulk(mob/living/carbon/human/user, does_attack_animation)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_larva(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_slime(mob/user)
	promptExit(user)

/turf/closed/indestructible/hoteldoor/attack_robot(mob/user)
	if(get_dist(get_turf(src), get_turf(user)) <= 1)
		promptExit(user)

/turf/closed/indestructible/hoteldoor/examine(mob/user)
	. = ..()
	if(!isliving(user))
		return
	. += "The placard reads 'Room [roomnumber]'."
	. += "<span class='info'>Alt-Click to look through the peephole.</span>"
	if(parentSphere && parentSphere.rooms_can_be_locked)
		. += "<span class='info'>Ctrl-Click to lock door if you owner of the room.</span>"

/turf/closed/indestructible/hoteldoor/CtrlClick(mob/user)
	. = ..()
	var/area/hilbertshotel/HB = get_area(src)
	var/roomnumber = "[HB.roomnumber]"
	if(!parentSphere)
		return
	if(!parentSphere.rooms_can_be_locked)
		return
	if(!parentSphere.mob_dorms[user] || !parentSphere.mob_dorms[user].Find(HB.roomnumber))
		return
	if(get_dist(get_turf(src), get_turf(user)) > 1)
		return

	if(parentSphere.lockedRooms[roomnumber])
		parentSphere.lockedRooms -= roomnumber
		playsound(src, 'sound/machines/locker_open.ogg', 50, 1)
	else
		parentSphere.lockedRooms[roomnumber] = TRUE
		playsound(src, 'sound/machines/locker_close.ogg', 50, 1)

	to_chat(user, "<span class='notice'>You [parentSphere.lockedRooms[roomnumber] ? "locked" : "unlocked"] room...</span>")

/turf/closed/indestructible/hoteldoor/AltClick(mob/user)
	. = ..()
	if(get_dist(get_turf(src), get_turf(user)) <= 1)
		to_chat(user, "<span class='notice'>You peak through the door's bluespace peephole...</span>")
		user.reset_perspective(parentSphere)
		user.set_machine(src)
		var/datum/action/peepholeCancel/PHC = new
		user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/scaled/impaired, 1)
		PHC.Grant(user)
		return TRUE

/turf/closed/indestructible/hoteldoor/check_eye(mob/user)
	if(get_dist(get_turf(src), get_turf(user)) >= 2)
		user.unset_machine()
		for(var/datum/action/peepholeCancel/PHC in user.actions)
			PHC.Trigger()

/datum/action/peepholeCancel
	name = "Cancel View"
	desc = "Stop looking through the bluespace peephole."
	button_icon_state = "cancel_peephole"

/datum/action/peepholeCancel/Trigger()
	. = ..()
	to_chat(owner, "<span class='warning'>You move away from the peephole.</span>")
	owner.reset_perspective()
	owner.clear_fullscreen("remote_view", 0)
	qdel(src)

/area/hilbertshotel
	name = "Hilbert's Hotel Room"
	icon_state = "hilbertshotel"
	requires_power = FALSE
	has_gravity = TRUE
	area_flags =  NOTELEPORT | HIDDEN_AREA
	dynamic_lighting = DYNAMIC_LIGHTING_FORCED
	var/roomnumber = 0
	var/obj/item/hilbertshotel/parentSphere
	var/datum/turf_reservation/reservation
	var/turf/storageTurf
	var/roomType = "Hotel Room" // SPLURT ADDITION: Default room type

/area/hilbertshotel/illuminated
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/hilbertshotel/Entered(atom/movable/AM)
	. = ..()
	if(istype(AM, /obj/item/hilbertshotel))
		relocate(AM)
	var/list/obj/item/hilbertshotel/hotels = AM.GetAllContents(/obj/item/hilbertshotel)
	for(var/obj/item/hilbertshotel/H in hotels)
		if(parentSphere == H)
			relocate(H)

/area/hilbertshotel/proc/relocate(obj/item/hilbertshotel/H)
	if(prob(0.135685)) //Because screw you
		qdel(H)
		return
	var/turf/targetturf = find_safe_turf()
	if(!targetturf)
		if(GLOB.blobstart.len > 0)
			targetturf = get_turf(pick(GLOB.blobstart))
		else
			CRASH("Unable to find a blobstart landmark")
	var/turf/T = get_turf(H)
	var/area/A = T.loc
	log_game("[H] entered itself. Moving it to [loc_name(targetturf)].")
	message_admins("[H] entered itself. Moving it to [ADMIN_VERBOSEJMP(targetturf)].")
	for(var/mob/M in A)
		to_chat(M, "<span class='danger'>[H] almost implodes in upon itself, but quickly rebounds, shooting off into a random point in space!</span>")
	H.forceMove(targetturf)

/area/hilbertshotel/Exited(atom/movable/AM)
	. = ..()
	if(!ismob(AM))
		return
	var/mob/M = AM
	parentSphere?.checked_in_ckeys -= M.ckey
	if(M.mind)
		var/stillPopulated = FALSE
		var/list/currentLivingMobs = GetAllContents(/mob/living) //Got to catch anyone hiding in anything
		for(var/mob/living/L in currentLivingMobs) //Check to see if theres any sentient mobs left.
			if(L.mind)
				stillPopulated = TRUE
				break
		if(!stillPopulated)
			storeRoom()

/area/hilbertshotelstorage
	name = "Hilbert's Hotel Storage Room"
	icon_state = "hilbertshotel"
	requires_power = FALSE
	has_gravity = TRUE
	area_flags =  NOTELEPORT | HIDDEN_AREA

/obj/item/abstracthotelstorage
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	item_flags = ABSTRACT
	var/roomNumber
	var/obj/item/hilbertshotel/parentSphere
	var/roomType = "Hotel Room" // Default room type

/obj/item/abstracthotelstorage/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	if(ismob(AM))
		var/mob/M = AM
		M.mob_transforming = TRUE

/obj/item/abstracthotelstorage/Exited(atom/movable/AM, atom/newLoc)
	. = ..()
	if(ismob(AM))
		var/mob/M = AM
		M.mob_transforming = FALSE

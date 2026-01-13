GLOBAL_VAR_INIT(hhStorageTurf, null)
GLOBAL_VAR_INIT(hhmysteryRoomNumber, 1337)

/obj/item/hilbertshotel
	name = "Hilbert's Hotel"
	desc = "A sphere of what appears to be an intricate network of bluespace. Observing it in detail seems to give you a headache as you try to comprehend the infinite amount of infinitesimally distinct points on its surface."
	icon_state = "hilbertshotel"
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	//SPLURT EDIT START
	var/list/static/hotel_maps = list("Hotel Room", "Apartment-1","Apartment-2", "Apartment-3", "Apartment-4", "Apartment-Syndi", "Apartment-Bar", "Apartment-dojo", "Apartment-Sauna", "Apartment-Beach", "Apartment-Forest", "Apartment-Jungle", "Apartment-Winter", "Apartment-Prison","Apartment-GYM","Apartment-Capsule","Apartment-Train")
	var/datum/map_template/hilbertshotel/apartment/hilberts_hotel_rooms_apartment_one
	var/datum/map_template/hilbertshotel/apartment/one/hilberts_hotel_rooms_apartment_two
	var/datum/map_template/hilbertshotel/apartment/two/hilberts_hotel_rooms_apartment_three
	var/datum/map_template/hilbertshotel/apartment/three/hilberts_hotel_rooms_apartment_four
	var/datum/map_template/hilbertshotel/apartment/syndi/hilberts_hotel_rooms_apartment_syndi
	var/datum/map_template/hilbertshotel/apartment/bar/hilberts_hotel_rooms_apartment_bar
	var/datum/map_template/hilbertshotel/apartment/dojo/hilberts_hotel_rooms_apartment_dojo
	var/datum/map_template/hilbertshotel/apartment/sauna/hilberts_hotel_rooms_apartment_sauna
	var/datum/map_template/hilbertshotel/apartment/beach/hilberts_hotel_rooms_apartment_beach
	var/datum/map_template/hilbertshotel/apartment/forest/hilberts_hotel_rooms_apartment_forest
	var/datum/map_template/hilbertshotel/apartment/jungle/hilberts_hotel_rooms_apartment_jungle
	var/datum/map_template/hilbertshotel/apartment/winter/hilberts_hotel_rooms_apartment_winter
	var/datum/map_template/hilbertshotel/apartment/prison/hilberts_hotel_rooms_apartment_prison
	var/datum/map_template/hilbertshotel/apartment/sport/hilberts_hotel_rooms_apartment_sport
	var/datum/map_template/hilbertshotel/apartment/capsule/hilberts_hotel_rooms_apartment_capsule
	var/datum/map_template/hilbertshotel/apartment/train/hilberts_hotel_rooms_apartment_train
	//SPLURT EDIT END
	var/datum/map_template/hilbertshotel/hotelRoomTemp
	var/datum/map_template/hilbertshotel/empty/hotelRoomTempEmpty
	var/datum/map_template/hilbertshotel/lore/hotelRoomTempLore
	var/list/activeRooms = list()
	var/list/storedRooms = list()
	var/list/checked_in_ckeys = list()
	var/list/lockedRooms = list()
	var/storageTurf
	//Lore Stuff
	var/ruinSpawned = FALSE
	var/mysteryRoom

/obj/item/hilbertshotel/Initialize(mapload)
	. = ..()
	//Load templates
	INVOKE_ASYNC(src, PROC_REF(prepare_rooms))

/obj/item/hilbertshotel/proc/prepare_rooms()
	hotelRoomTemp = new()
	hotelRoomTempEmpty = new()
	hotelRoomTempLore = new()

	hilberts_hotel_rooms_apartment_one = new()
	hilberts_hotel_rooms_apartment_two = new()
	hilberts_hotel_rooms_apartment_three = new()
	hilberts_hotel_rooms_apartment_four = new()
	hilberts_hotel_rooms_apartment_syndi = new()
	hilberts_hotel_rooms_apartment_bar = new()
	hilberts_hotel_rooms_apartment_dojo = new()
	hilberts_hotel_rooms_apartment_sauna = new()
	hilberts_hotel_rooms_apartment_beach = new()
	hilberts_hotel_rooms_apartment_forest = new()
	hilberts_hotel_rooms_apartment_jungle = new()
	hilberts_hotel_rooms_apartment_winter = new()
	hilberts_hotel_rooms_apartment_prison = new()
	hilberts_hotel_rooms_apartment_sport = new()
	hilberts_hotel_rooms_apartment_capsule = new()
	hilberts_hotel_rooms_apartment_train = new()

	var/area/currentArea = get_area(src)
	if(currentArea.type == /area/ruin/space/has_grav/hilbertresearchfacility)
		ruinSpawned = TRUE

/obj/item/hilbertshotel/Destroy()
	ejectRooms()
	return ..()

/obj/item/hilbertshotel/attack(mob/living/M, mob/living/user)
	if(M.mind)
		to_chat(user, span_notice("You invite [M] to the hotel."))
		promptAndCheckIn(user, M)
	else
		to_chat(user, span_warning("[M] is not intelligent enough to understand how to use this device!"))

/obj/item/hilbertshotel/attack_self(mob/user)
	. = ..()
	promptAndCheckIn(user, user)

/obj/item/hilbertshotel/proc/promptAndCheckIn(mob/user)
	//SPLURT EDIT - max infinidorms rooms
	var/max_rooms = CONFIG_GET(number/max_infinidorms)
	var/chosenRoomNumber
	if(max_rooms == 0)
		playsound(src, 'sound/machines/terminal_error.ogg', 15, 1)
		to_chat(user, span_warning("We're currently not offering service, please come back another day!"))
		return

	chosenRoomNumber = input(user, "What number room will you be checking into?", "Room Number") as null|num
	if(!mob_dorms[user] || !mob_dorms[user].Find(chosenRoomNumber)) //BLUEMOON ADD владелец комнаты может зайти в комнату даже если она закрыта и активна
		if(activeRooms.len && activeRooms["[chosenRoomNumber]"])	//лесенка ради удобства восприятия, точно-точно говорю
			if(lockedRooms.len && lockedRooms["[chosenRoomNumber]"])
				to_chat(user, span_warning("You cant enter in locked room, contact with room owner."))
				return												//BLUEMOON ADD END
	if(max_rooms > 0 && mob_dorms[user]?.len >= max_rooms && !activeRooms["[chosenRoomNumber]"] && !storedRooms["[chosenRoomNumber]"])
		to_chat(user, span_warning("Your free trial of Hilbert's Hotel has ended! Please select one of the rooms you've already visited."))
		chosenRoomNumber = input(user, "Select one of your previous rooms", "Room number") as null|anything in mob_dorms[user]

	//SPLURT EDIT END
	if(!chosenRoomNumber || !user.CanReach(src))
		return
	if(chosenRoomNumber > SHORT_REAL_LIMIT)
		to_chat(user, span_warning("You have to check out the first [SHORT_REAL_LIMIT] rooms before you can go to a higher numbered one!"))
		return
	if((chosenRoomNumber < 1) || (chosenRoomNumber != round(chosenRoomNumber)))
		to_chat(user, span_warning("That is not a valid room number!"))
		return
	if(!isturf(loc))
		if((loc == user) || (loc.loc == user) || (loc.loc in user.contents) || (loc in user.GetAllContents(type)))		//short circuit, first three checks are cheaper and covers almost all cases (loc.loc covers hotel in box in backpack).
			forceMove(get_turf(user))

	//SPLURT EDIT START
	// Check if the room is already active, stored, or the secret room. If so, skip room type selection
	var/chosen_room = "Nothing"
	if(!activeRooms["[chosenRoomNumber]"] && !storedRooms["[chosenRoomNumber]"] && chosenRoomNumber != GLOB.hhmysteryRoomNumber)
		chosen_room = tgui_input_list(user, "Choose your desired room:", "∼♦️ Time to choose a room ♦️∼!", hotel_maps)
		if(!chosen_room || !user.CanReach(src))
			return FALSE
	//SPLURT EDIT END

	if(!storageTurf) //Blame subsystems for not allowing this to be in Initialize
		if(!GLOB.hhStorageTurf)
			var/datum/map_template/hilbertshotelstorage/storageTemp = new()
			var/datum/turf_reservation/storageReservation = SSmapping.RequestBlockReservation(3, 3)
			storageTemp.load(locate(storageReservation.bottom_left_coords[1], storageReservation.bottom_left_coords[2], storageReservation.bottom_left_coords[3]))
			GLOB.hhStorageTurf = locate(storageReservation.bottom_left_coords[1]+1, storageReservation.bottom_left_coords[2]+1, storageReservation.bottom_left_coords[3])
		//SPLURT EDIT START: Removed else statement in this line (to fix first room not storing correctly)
		storageTurf = GLOB.hhStorageTurf
		//SPLURT EDIT END
	checked_in_ckeys |= user.ckey		//if anything below runtimes, guess you're outta luck!
	if(tryActiveRoom(chosenRoomNumber, user))
		return
	if(tryStoredRoom(chosenRoomNumber, user, chosen_room))
		return
	sendToNewRoom(chosenRoomNumber, user, chosen_room)

/area/hilbertshotel/proc/storeRoom()
	// Calculate the actual room size based on the reservation coordinates
	var/roomWidth = reservation.top_right_coords[1] - reservation.bottom_left_coords[1] + 1
	var/roomHeight = reservation.top_right_coords[2] - reservation.bottom_left_coords[2] + 1
	var/roomSize = roomWidth * roomHeight
	var/storage[roomSize]
	var/turfNumber = 1
	var/obj/item/abstracthotelstorage/storageObj = new(storageTurf)
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
	if(activeRooms["[roomNumber]"])
		var/datum/turf_reservation/roomReservation = activeRooms["[roomNumber]"]
		var/area/hilbertshotel/currentArea = get_area(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
		var/datum/map_template/hilbertshotel/mapTemplate = getMapTemplate(currentArea.roomType)

		do_sparks(3, FALSE, get_turf(user))
		MobTransfer(user, locate(roomReservation.bottom_left_coords[1] + mapTemplate.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + mapTemplate.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
		return TRUE
	else
		return FALSE

/obj/item/hilbertshotel/proc/tryStoredRoom(var/roomNumber, var/mob/user)
// SPLURT EDIT START: Load the correct stored room by loading an empty template and adding stored atoms on top of it.
	if(storedRooms["[roomNumber]"])
		// Find the storage object for the stored room
		var/obj/item/abstracthotelstorage/storageObj
		for(var/obj/item/abstracthotelstorage/S in storageTurf)
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
		for(var/i=0, i<mapTemplate.width, i++)
			for(var/j=0, j<mapTemplate.height, j++)
				var/turf/T = locate(roomReservation.bottom_left_coords[1] + i, roomReservation.bottom_left_coords[2] + j, roomReservation.bottom_left_coords[3])
				for(var/atom/movable/A in T)
					if(istype(A, /obj/effect/overlay/water) || istype(A, /obj/effect/overlay/water/top)) // Skip pool water overlays
						continue
					QDEL_LIST(A.contents)
					qdel(A)

		// Place the STORED atoms back into the room
		var/turfNumber = 1
		for(var/i=0, i<mapTemplate.width, i++)
			for(var/j=0, j<mapTemplate.height, j++)
				for(var/atom/movable/A in storedRooms["[roomNumber]"][turfNumber])
					if(istype(A.loc, /obj/item/abstracthotelstorage)) // Don't want to recall something that's been moved
						A.forceMove(locate(roomReservation.bottom_left_coords[1] + i, roomReservation.bottom_left_coords[2] + j, roomReservation.bottom_left_coords[3]))
				turfNumber++
		for(var/obj/item/abstracthotelstorage/S in storageTurf)
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
	else
		return FALSE

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
			MobTransfer(AM, T, depth)
		else
			AM.forceMove(T)
	if(user.buckled && !user.buckled.anchored)
		var/atom/movable/seating = user.buckled
		if(istype(seating, /mob/living))
			MobTransfer(seating, T, depth)
		else
			seating.forceMove(T)
			user.forceMove(T)
			seating.buckle_mob(user, TRUE, TRUE)
	else if(user.buckled_mobs)
		var/datum/component/riding/riding_datum = user.GetComponent(/datum/component/riding)
		var/datum/component/riding/human/riding_datum_human
		var/mob/living/buckled_mob
		var/buckle_type
		if(istype(riding_datum, /datum/component/riding/human))
			riding_datum_human = riding_datum
			buckle_type = riding_datum_human.face_to_face_carrying ? "face_to_face" : riding_datum_human.princess_carrying ? "princess" : "firefiremanned"
		for(var/mob/living/I in user.buckled_mobs)
			buckled_mob = I
			I.forceMove(T)
		user.unbuckle_all_mobs(TRUE)
		user.forceMove(T)
		if(riding_datum_human)
			switch(buckle_type)
				if("face_to_face")
					user.buckle_mob(buckled_mob, TRUE, TRUE, 0, 1, 0, FALSE, "face_to_face")
				if("princess")
					user.buckle_mob(buckled_mob, TRUE, TRUE, 90, 2, 0, FALSE, "princess")
				if("firefiremanned")
					user.buckle_mob(buckled_mob, TRUE, TRUE, 90, 1, 0, TRUE)
		else
			user.buckle_mob(buckled_mob, TRUE, TRUE)
	else
		user.forceMove(T)
	if(AM)
		user.start_pulling(AM)

/obj/item/hilbertshotel/proc/getMapTemplate(roomType) // To load a map and remove it's atoms
	switch(roomType)
		if("Hotel Room") return hotelRoomTemp
		if("Apartment-1") return hilberts_hotel_rooms_apartment_one
		if("Apartment-2") return hilberts_hotel_rooms_apartment_two
		if("Apartment-3") return hilberts_hotel_rooms_apartment_three
		if("Apartment-4") return hilberts_hotel_rooms_apartment_four
		if("Apartment-Bar") return hilberts_hotel_rooms_apartment_bar
		if("Apartment-Syndi") return hilberts_hotel_rooms_apartment_syndi
		if("Apartment-dojo") return hilberts_hotel_rooms_apartment_dojo
		if("Apartment-Sauna") return hilberts_hotel_rooms_apartment_sauna
		if("Apartment-Beach") return hilberts_hotel_rooms_apartment_beach
		if("Apartment-Forest") return hilberts_hotel_rooms_apartment_forest
		if("Apartment-Jungle") return hilberts_hotel_rooms_apartment_jungle
		if("Apartment-Winter") return hilberts_hotel_rooms_apartment_winter
		if("Apartment-Prison") return hilberts_hotel_rooms_apartment_prison
		if("Apartment-GYM") return hilberts_hotel_rooms_apartment_sport
		if("Apartment-Capsule") return hilberts_hotel_rooms_apartment_capsule
		if("Apartment-Train") return hilberts_hotel_rooms_apartment_train
		if("Mystery Room") return hotelRoomTempLore
	return hotelRoomTemp // Default to Hotel Room if no match is found

//SPLURT EDIT START: HOTEL UPDATE. Was sendToNewRoom(chosenRoomNumber, target) | Added new selectable apartments
/obj/item/hilbertshotel/proc/sendToNewRoom(roomNumber, mob/user, chosen_room)
	var/datum/turf_reservation/roomReservation = SSmapping.RequestBlockReservation(hotelRoomTemp.width, hotelRoomTemp.height)
	mysteryRoom = GLOB.hhmysteryRoomNumber

	var/datum/map_template/hilbertshotel/mapTemplate

	if(ruinSpawned && roomNumber == mysteryRoom)
		chosen_room = "Mystery Room"
		mapTemplate = hotelRoomTempLore
	else
		switch(chosen_room)
			if("Hotel Room") mapTemplate = hotelRoomTemp
			if("Apartment-1") mapTemplate = hilberts_hotel_rooms_apartment_one
			if("Apartment-2") mapTemplate = hilberts_hotel_rooms_apartment_two
			if("Apartment-3") mapTemplate = hilberts_hotel_rooms_apartment_three
			if("Apartment-4") mapTemplate = hilberts_hotel_rooms_apartment_four
			if("Apartment-Syndi") mapTemplate = hilberts_hotel_rooms_apartment_syndi
			if("Apartment-Bar") mapTemplate = hilberts_hotel_rooms_apartment_bar
			if("Apartment-dojo") mapTemplate = hilberts_hotel_rooms_apartment_dojo
			if("Apartment-Sauna") mapTemplate = hilberts_hotel_rooms_apartment_sauna
			if("Apartment-Beach") mapTemplate = hilberts_hotel_rooms_apartment_beach
			if("Apartment-Forest") mapTemplate = hilberts_hotel_rooms_apartment_forest
			if("Apartment-Jungle") mapTemplate = hilberts_hotel_rooms_apartment_jungle
			if("Apartment-Winter") mapTemplate = hilberts_hotel_rooms_apartment_winter
			if("Apartment-Prison") mapTemplate = hilberts_hotel_rooms_apartment_prison
			if("Apartment-GYM") mapTemplate = hilberts_hotel_rooms_apartment_sport
			if("Apartment-Capsule") mapTemplate = hilberts_hotel_rooms_apartment_capsule
			if("Apartment-Train") mapTemplate = hilberts_hotel_rooms_apartment_train
	if(!mapTemplate)
		mapTemplate = hotelRoomTemp //Default Hotel Room

	mapTemplate.load(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	activeRooms["[roomNumber]"] = roomReservation

	// Set the room type for the newly created area
	var/area/hilbertshotel/currentArea = get_area(locate(roomReservation.bottom_left_coords[1], roomReservation.bottom_left_coords[2], roomReservation.bottom_left_coords[3]))
	currentArea.roomType = chosen_room // Sets the room type here

	linkTurfs(roomReservation, roomNumber)
	do_sparks(3, FALSE, get_turf(user))
	MobTransfer(user, locate(roomReservation.bottom_left_coords[1] + mapTemplate.landingZoneRelativeX, roomReservation.bottom_left_coords[2] + mapTemplate.landingZoneRelativeY, roomReservation.bottom_left_coords[3]))
//SPLURT EDIT END

/obj/item/hilbertshotel/proc/linkTurfs(var/datum/turf_reservation/currentReservation, var/currentRoomnumber, var/chosen_room)
	var/area/hilbertshotel/currentArea = get_area(locate(currentReservation.bottom_left_coords[1], currentReservation.bottom_left_coords[2], currentReservation.bottom_left_coords[3]))
	currentArea.name = "Hilbert's Hotel Room [currentRoomnumber]"
	currentArea.parentSphere = src
	currentArea.storageTurf = storageTurf
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
			for(var/i=0, i<hotelRoomTemp.width, i++)
				for(var/j=0, j<hotelRoomTemp.height, j++)
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
							if (D.linkage == CROSSLINKED)
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

/obj/item/hilbertshotel/ghostdojo
	name = "Infinite Dormitories"
	anchored = TRUE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND

/obj/item/hilbertshotel/ghostdojo/linkTurfs(datum/turf_reservation/currentReservation, currentRoomnumber)
	. = ..()
	var/area/hilbertshotel/currentArea = get_area(locate(currentReservation.bottom_left_coords[1], currentReservation.bottom_left_coords[2], currentReservation.bottom_left_coords[3]))
	for(var/turf/closed/indestructible/hoteldoor/door in currentArea)
		door.parentSphere = src
		door.roomnumber = currentRoomnumber

//Template Stuff
/datum/map_template/hilbertshotel
	name = "Hilbert's Hotel Room"
	mappath = '_maps/templates/hilbertshotel.dmm'
	var/landingZoneRelativeX = 2
	var/landingZoneRelativeY = 8

/datum/map_template/hilbertshotel/empty
	name = "Empty Hilbert's Hotel Room"
	mappath = '_maps/templates/hilbertshotelempty.dmm'

/datum/map_template/hilbertshotel/lore
	name = "Doctor Hilbert's Deathbed"
	mappath = '_maps/templates/hilbertshotellore.dmm'

/datum/map_template/hilbertshotelstorage
	name = "Hilbert's Hotel Storage"
	mappath = '_maps/templates/hilbertshotelstorage.dmm'

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
	if(ismob(AM))
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

//Space Ruin stuff
/area/ruin/space/has_grav/hilbertresearchfacility
	name = "Hilbert Research Facility"

/obj/item/analyzer/hilbertsanalyzer
	name = "custom rigged analyzer"
	desc = "A hand-held environmental scanner which reports current gas levels. This one seems custom rigged to additionally be able to analyze some sort of bluespace device."
	icon_state = "hilbertsanalyzer"

/obj/item/analyzer/hilbertsanalyzer/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(istype(target, /obj/item/hilbertshotel))
		if(!proximity)
			to_chat(user, "<span class='warning'>It's to far away to scan!</span>")
			return
		var/obj/item/hilbertshotel/sphere = target
		if(sphere.activeRooms.len)
			to_chat(user, "Currently Occupied Rooms:")
			for(var/roomnumber in sphere.activeRooms)
				to_chat(user, roomnumber)
		else
			to_chat(user, "No currenty occupied rooms.")
		if(sphere.storedRooms.len)
			to_chat(user, "Vacated Rooms:")
			for(var/roomnumber in sphere.storedRooms)
				to_chat(user, roomnumber)
		else
			to_chat(user, "No vacated rooms.")

/obj/effect/mob_spawn/human/doctorhilbert
	name = "Doctor Hilbert"
	mob_name = "Doctor Hilbert"
	mob_gender = "male"
	assignedrole = null
	ghost_usable = FALSE
	oxy_damage = 500
	mob_species = /datum/species/skeleton
	id_job = "Head Researcher"
	id_access = ACCESS_RESEARCH
	id_access_list = list(ACCESS_AWAY_GENERIC3, ACCESS_RESEARCH)
	instant = TRUE
	id = /obj/item/card/id/silver
	uniform = /obj/item/clothing/under/rank/rnd/research_director
	shoes = /obj/item/clothing/shoes/sneakers/brown
	back = /obj/item/storage/backpack/satchel/leather
	suit = /obj/item/clothing/suit/toggle/labcoat

/obj/item/paper/crumpled/docslogs
	name = "Research Logs"

/obj/item/paper/crumpled/docslogs/Initialize(mapload)
	. = ..()
	GLOB.hhmysteryRoomNumber = rand(1, SHORT_REAL_LIMIT)
	default_raw_text = {"
###  Research Logs
I might just be onto something here!
The strange space-warping properties of bluespace have been known about for awhile now, but I might be on the verge of discovering a new way of harnessing it.
It's too soon to say for sure, but this might be the start of something quite important!
I'll be sure to log any major future breakthroughs. This might be a lot more than I can manage on my own, perhaps I should hire that secretary after all...
###  Breakthrough!
I can't believe it, but I did it! Just when I was certain it couldn't be done, I made the final necessary breakthrough.
Exploiting the effects of space dilation caused by specific bluespace structures combined with a precise use of geometric calculus, I've discovered a way to correlate an infinite amount of space within a finite area!
While the potential applications are endless, I utilized it in quite a nifty way so far by designing a system that recursively constructs subspace rooms and spatially links them to any of the infinite infinitesimally distinct points on the spheres surface.
I call it: Hilbert's Hotel!
<h4>Goodbye</h4>
I can't take this anymore. I know what happens next, and the fear of what is coming leaves me unable to continue working.
Any fool in my field has heard the stories. It's not that I didn't believe them, it's just... I guess I underestimated the importance of my own research...
Robert has reported a further increase in frequency of the strange, prying visitors who ask questions they have no business asking. I've requested him to keep everything on strict lockdown and have permanently dismissed all other assistants.
I've also instructed him to use the encryption method we discussed for any important quantitative data. The poor lad... I don't think he truly understands what he's gotten himself into...
It's clear what happens now. One day they'll show up uninvited, and claim my research as their own, leaving me as nothing more than a bullet ridden corpse floating in space.
I can't stick around to the let that happen.
I'm escaping into the very thing that brought all this trouble to my doorstep in the first place - my hotel.
I'll be in <u>[uppertext(num2hex(GLOB.hhmysteryRoomNumber, 0))]</u> (That will make sense to anyone who should know)
I'm sorry that I must go like this. Maybe one day things will be different and it will be safe to return... maybe...
Goodbye
     _Doctor Hilbert_"}

/obj/item/paper/crumpled/robertsworkjournal
	name = "Work Journal"
	default_raw_text = {"<h4>First Week!</h4>
	First week on the new job. It's a secretarial position, but hey, whatever pays the bills. Plus it seems like some interesting stuff goes on here.<br>
	Doc says its best that I don't openly talk about his research with others, I guess he doesn't want it getting out or something. I've caught myself slipping a few times when talking to others, it's hard not to brag about something this cool!<br>
	I'm not really sure why I'm choosing to journal this. Doc seems to log everything. He says it's incase he discovers anything important.<br>
	I guess that's why I'm doing it too, I've always wanted to be a part of something important.<br>
	Here's to a new job and to becoming a part of something important!<br>
	<h4>Weird times...</h4>
	Things are starting to get a little strange around here. Just weeks after Doc's amazing breakthrough, weird visitors have began showing up unannounced, asking strange things about Doc's work.<br>
	I knew Doc wasn't a big fan of company, but even he seemed strangely unnerved when I told him about the visitors.<br>
	He said it's important that from here on out we keep tight security on everything, even other staff members.<br>
	He also said something about securing data, something about hexes. What's that mean? Some sort of curse? Doc never struck me as the magic type...<br>
	He often uses a lot of big sciencey words that I don't really understand, but I kinda dig it, it makes me feel like I'm witnessing something big.<br>
	I hope things go back to normal soon, but I guess that's the price you pay for being a part of something important.<br>
	<h4>Last day I guess?</h4>
	Things are officially starting to get too strange for me.<br>
	The visitors have been coming a lot more often, and they all seem increasingly aggressive and nosey. I'm starting to see why they made Doc so nervous, they're certainly starting to creep me out too.<br>
	Awhile ago Doc started having me keep the place on strict lockdown and requested I refuse entry to anyone else, including previous staff.<br>
	But the weirdest part?<br>
	I haven't seen Doc in days. It's not unusual for him to work continuously for long periods of time in the lab, but when I took a peak in their yesterday - he was nowhere to be seen! I didn't risk prying much further, Doc had a habit of leaving the defense systems on these last few weeks.<br>
	I'm thinking it might be time to call it quits. Can't work much without a boss, plus things are starting to get kind of shady. I wanted to be a part of something important, but you gotta know when to play it safe.<br>
	As my dad always said, "The smart get famous, but the wise survive..."<br>
	<br>
	<i>Robert P.</i>"}

/obj/item/paper/crumpled/bloody/docsdeathnote
	name = "note"
	default_raw_text = {"
This is it isn't it?
No one's coming to help, that much has become clear.
Sure, it's lonely, but do I have much choice? At least I brought the analyzer with me, they shouldn't be able to find me without it.
Who knows who's waiting for me out there. Its either die out there in their hands, or die a slower, slightly more comfortable death in here.
Everyday I can feel myself slipping away more and more, both physically and mentally. Who knows what happens now...
Heh, so it's true then, this must be the inescapable path of all great minds... so be it then.
_Choose a room, and enter the sphere
Lay your head to rest, it soon becomes clear
There's always more room around every bend
Not all that's countable has an end..._
"}

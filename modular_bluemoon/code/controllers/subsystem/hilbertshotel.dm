SUBSYSTEM_DEF(hilbertshotel)
	name = "Hilbert's Hotel"
	flags = SS_NO_FIRE
	init_order = INIT_ORDER_HILBERTSHOTEL

	/// List for all hilberts spheres
	var/list/obj/item/hilbertshotel/all_hilbert_spheres = list()

	// Some placeholder templates
	var/datum/map_template/hilbertshotel/hotel_room_template
	var/datum/map_template/hilbertshotel/lore/hotel_room_template_lore

	// Actual templates
	var/list/datum/map_template/hilbertshotel/apartment/hotel_map_list = list()
	/// Name of the first template in the list - used as default
	var/default_template

	/// Storage for conserved rooms
	var/storageTurf

	/// List of ckey-based user preferences
	var/list/user_data = list()

	// Lore stuff
	var/lore_room_spawned = FALSE
	var/hhMysteryroom_number

/datum/controller/subsystem/hilbertshotel/Initialize()
	. = ..()
	if(!CONFIG_GET(flag/hilbertshotel_enabled))
		return SS_INIT_NO_NEED
	//RegisterSignal(src, COMSIG_HILBERT_ROOM_UPDATED, PROC_REF(on_room_updated))
	hhMysteryroom_number = hhMysteryroom_number || rand(1, 999999)
	prepare_rooms()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/hilbertshotel/proc/setup_storage_turf()
	if(storageTurf) // setting up a storage for the room objects
		return
	var/datum/map_template/hilbertshotelstorage/storageTemp = new()
	var/datum/turf_reservation/storageReservation = SSmapping.RequestBlockReservation(3, 3)
	var/turf/bottom_left = get_turf(locate(storageReservation.bottom_left_coords[1], storageReservation.bottom_left_coords[2], storageReservation.bottom_left_coords[3]))
	storageTemp.load(bottom_left)
	storageTurf = locate(bottom_left.x + 1, bottom_left.y + 1, bottom_left.z)

/datum/controller/subsystem/hilbertshotel/proc/prepare_rooms()
	if(length(hotel_map_list)) // if somehow it already generated
		return

	hotel_room_template = new()
	hotel_room_template_lore = new()

	hotel_map_list[hotel_room_template.name] = hotel_room_template

	var/list/hotel_map_templates = typecacheof(list(/datum/map_template/hilbertshotel/apartment))
	for(var/template_type in hotel_map_templates)
		var/datum/map_template/this_template = new template_type()
		hotel_map_list[this_template.name] = this_template

	default_template = hotel_map_list[1]

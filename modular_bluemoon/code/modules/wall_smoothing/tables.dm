/obj/structure/table/reinforced/brass
	icon = 'modular_bluemoon/icons/obj/smooth_structures/brass_table.dmi'
	icon_state = "brass_table-0"
	base_icon_state = "brass_table"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_BRONZE_TABLES
	canSmoothWith = SMOOTH_GROUP_BRONZE_TABLES

/obj/structure/table/bronze
	icon = 'modular_bluemoon/icons/obj/smooth_structures/brass_table.dmi'
	icon_state = "brass_table-0"
	base_icon_state = "brass_table"
	smooth = SMOOTH_FALSE
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = SMOOTH_GROUP_BRONZE_TABLES
	canSmoothWith = SMOOTH_GROUP_BRONZE_TABLES

/obj/structure/table/reinforced/brass/update_icon()
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH(src)
		QUEUE_SMOOTH_NEIGHBORS(src)
		return
	return ..()

/obj/structure/table/bronze/update_icon()
	if(smoothing_flags & USES_SMOOTHING)
		QUEUE_SMOOTH(src)
		QUEUE_SMOOTH_NEIGHBORS(src)
		return
	return ..()

/obj/structure/table/reinforced/brass/update_icon_state()
	if(smoothing_flags & USES_SMOOTHING)
		icon_state = "[base_icon_state]-[smoothing_junction]"
		return ..()
	return ..()

/obj/structure/table/bronze/update_icon_state()
	if(smoothing_flags & USES_SMOOTHING)
		icon_state = "[base_icon_state]-[smoothing_junction]"
		return ..()
	return ..()

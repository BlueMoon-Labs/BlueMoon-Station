#define AIRLOCK_LIGHT_POWER 1
#define AIRLOCK_LIGHT_RANGE 2
#define AIRLOCK_LIGHT_ENGINEERING "engineering"
#define AIRLOCK_POWERON_LIGHT_COLOR "#3aa7c2"
#define AIRLOCK_BOLTS_LIGHT_COLOR "#c22323"
#define AIRLOCK_ACCESS_LIGHT_COLOR "#57e69c"
#define AIRLOCK_EMERGENCY_LIGHT_COLOR "#d1d11d"
#define AIRLOCK_ENGINEERING_LIGHT_COLOR "#fd8719"
#define AIRLOCK_DENY_LIGHT_COLOR "#c22323"

#define AIRLOCK_CLOSED	1
#define AIRLOCK_CLOSING	2
#define AIRLOCK_OPEN	3
#define AIRLOCK_OPENING	4
#define AIRLOCK_DENY	5
#define AIRLOCK_EMAG	6

/obj/machinery/door/airlock
	doorOpen = 'modular_bluemoon/sound/machines/airlock/open.ogg'
	doorClose = 'modular_bluemoon/sound/machines/airlock/close.ogg'
	boltUp = 'modular_bluemoon/sound/machines/airlock/bolts_up.ogg'
	boltDown = 'modular_bluemoon/sound/machines/airlock/bolts_down.ogg'
	//noPower = 'sound/machines/doorclick.ogg'
	var/forcedOpen = 'modular_bluemoon/sound/machines/airlock/open_force.ogg' //Come on guys, why aren't all the sound files like this.
	var/forcedClosed = 'modular_bluemoon/sound/machines/airlock/close_force.ogg'

	/// For those airlocks you might want to have varying "fillings" for, without having to
	/// have an icon file per door with a different filling.
	var/fill_state_suffix = null
	/// For the airlocks that use greyscale lights, set this to the color you want your lights to be.
	var/greyscale_lights_color = null
	/// For the airlocks that use a greyscale accent door color, set this color to the accent color you want it to be.
	var/greyscale_accent_color = null

	var/has_environment_lights = TRUE //Does this airlock emit a light?
	var/light_color_poweron = AIRLOCK_POWERON_LIGHT_COLOR
	var/light_color_bolts = AIRLOCK_BOLTS_LIGHT_COLOR
	var/light_color_access = AIRLOCK_ACCESS_LIGHT_COLOR
	var/light_color_emergency = AIRLOCK_EMERGENCY_LIGHT_COLOR
	var/light_color_engineering = AIRLOCK_ENGINEERING_LIGHT_COLOR
	var/light_color_deny = AIRLOCK_DENY_LIGHT_COLOR
	var/door_light_range = AIRLOCK_LIGHT_RANGE
	var/door_light_power = AIRLOCK_LIGHT_POWER
	///Is this door external? E.g. does it lead to space? Shuttle docking systems bolt doors with this flag.
	var/external = FALSE

/obj/machinery/door/airlock/external
	external = TRUE

/obj/machinery/door/airlock/shuttle
	external = TRUE

/obj/machinery/door/airlock/power_change()
	..()
	update_icon()

/obj/machinery/door/airlock/update_overlays()
	. = ..()
	var/pre_light_range = 0
	var/pre_light_power = 0
	var/pre_light_color = ""
	var/lights_overlay = ""

	var/frame_state
	var/light_state
	switch(airlock_state)
		if(AIRLOCK_CLOSED)
			frame_state = AIRLOCK_FRAME_CLOSED
			if(locked)
				light_state = AIRLOCK_LIGHT_BOLTS
				lights_overlay = "lights_bolts"
				pre_light_color = light_color_bolts
			else if(emergency)
				light_state = AIRLOCK_LIGHT_EMERGENCY
				lights_overlay = "lights_emergency"
				pre_light_color = light_color_emergency
			else
				lights_overlay = "lights_poweron"
				pre_light_color = light_color_poweron
		if(AIRLOCK_DENY)
			frame_state = AIRLOCK_FRAME_CLOSED
			light_state = AIRLOCK_LIGHT_DENIED
			lights_overlay = "lights_denied"
			pre_light_color = light_color_deny
		if(AIRLOCK_EMAG)
			frame_state = AIRLOCK_FRAME_CLOSED
		if(AIRLOCK_CLOSING)
			frame_state = AIRLOCK_FRAME_CLOSING
			light_state = AIRLOCK_LIGHT_CLOSING
			lights_overlay = "lights_closing"
			pre_light_color = light_color_access
		if(AIRLOCK_OPEN)
			frame_state = AIRLOCK_FRAME_OPEN
			if(locked)
				lights_overlay = "lights_bolts_open"
				pre_light_color = light_color_bolts
			else if(emergency)
				lights_overlay = "lights_emergency_open"
				pre_light_color = light_color_emergency
			else
				lights_overlay = "lights_poweron_open"
				pre_light_color = light_color_poweron
		if(AIRLOCK_OPENING)
			frame_state = AIRLOCK_FRAME_OPENING
			light_state = AIRLOCK_LIGHT_OPENING
			lights_overlay = "lights_opening"
			pre_light_color = light_color_access

	. += get_airlock_overlay(frame_state, icon, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)
	if(airlock_material)
		. += get_airlock_overlay("[airlock_material]_[frame_state]", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)
	else
		. += get_airlock_overlay("fill_[frame_state + fill_state_suffix]", icon, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)

	if(greyscale_lights_color && !light_state)
		lights_overlay += "_greyscale"

	if(lights && hasPower())
		. += get_airlock_overlay("lights_[light_state]", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)
		pre_light_range = door_light_range
		pre_light_power = door_light_power
		if(has_environment_lights)
			set_light(pre_light_range, pre_light_power, pre_light_color, TRUE)
			filler?.set_light(pre_light_range, pre_light_power, pre_light_color)
	else
		lights_overlay = ""

	var/mutable_appearance/lights_appearance = mutable_appearance(overlays_file, lights_overlay, FLOAT_LAYER, src, ABOVE_LIGHTING_PLANE)

	if(greyscale_lights_color && !light_state)
		lights_appearance.color = greyscale_lights_color

	if(filler)
		lights_appearance.dir = dir

	. += lights_appearance

	if(greyscale_accent_color)
		. += get_airlock_overlay("[frame_state]_accent", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)

	if(panel_open)
		. += get_airlock_overlay("panel_[frame_state][security_level ? "_protected" : null]", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)
	if(frame_state == AIRLOCK_FRAME_CLOSED && welded)
		. += get_airlock_overlay("welded", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)

	if(airlock_state == AIRLOCK_EMAG)
		. += get_airlock_overlay("sparks", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)

	if(hasPower())
		if(frame_state == AIRLOCK_FRAME_CLOSED)
			if(obj_integrity < integrity_failure * max_integrity)
				. += get_airlock_overlay("sparks_broken", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)
			else if(obj_integrity < (0.75 * max_integrity))
				. += get_airlock_overlay("sparks_damaged", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)
		else if(frame_state == AIRLOCK_FRAME_OPEN)
			if(obj_integrity < (0.75 * max_integrity))
				. += get_airlock_overlay("sparks_open", overlays_file, targetlayer = FLOAT_LAYER, targetplane = FLOAT_PLANE)

	if(hasPower() && unres_sides)
		for(var/heading in list(NORTH,SOUTH,EAST,WEST))
			if(!(unres_sides & heading))
				continue
			var/mutable_appearance/floorlight = mutable_appearance('icons/obj/doors/airlocks/station/overlays.dmi', "unres_[heading]", FLOAT_LAYER, src, ABOVE_LIGHTING_PLANE)
			switch (heading)
				if (NORTH)
					floorlight.pixel_x = 0
					floorlight.pixel_y = 32
				if (SOUTH)
					floorlight.pixel_x = 0
					floorlight.pixel_y = -32
				if (EAST)
					floorlight.pixel_x = 32
					floorlight.pixel_y = 0
				if (WEST)
					floorlight.pixel_x = -32
					floorlight.pixel_y = 0
			. += floorlight

//STATION AIRLOCKS
/obj/machinery/door/airlock
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/public.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/overlays.dmi'

/obj/machinery/door/airlock/command
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/command.dmi'

/obj/machinery/door/airlock/security
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/security.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_sec

/obj/machinery/door/airlock/security/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/engineering
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/engineering.dmi'

/obj/machinery/door/airlock/medical
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/medical.dmi'

/obj/machinery/door/airlock/maintenance
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/maintenance.dmi'

/obj/machinery/door/airlock/maintenance/external
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/maintenanceexternal.dmi'

/obj/machinery/door/airlock/mining
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/mining.dmi'

/obj/machinery/door/airlock/atmos
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/atmos.dmi'

/obj/machinery/door/airlock/research
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/research.dmi'

/obj/machinery/door/airlock/freezer
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/freezer.dmi'

/obj/machinery/door/airlock/science
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/science.dmi'

/obj/machinery/door/airlock/virology
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/virology.dmi'

//STATION CUSTOM ARILOCKS
/obj/machinery/door/airlock/corporate
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/corporate.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_corporate
	normal_integrity = 450

/obj/machinery/door/airlock/corporate/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/service
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/service.dmi'
	assemblytype = /obj/structure/door_assembly/door_assembly_service

/obj/machinery/door/airlock/service/glass
	opacity = FALSE
	glass = TRUE

/obj/machinery/door/airlock/captain
	name = "Captain's Office"
	req_access = list(ACCESS_CAPTAIN)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/cap.dmi'

/obj/machinery/door/airlock/hop
	name = "Head of Personnel Office"
	req_access = list(ACCESS_HOP)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hop.dmi'

/obj/machinery/door/airlock/hos
	name = "Head of Security Office"
	req_access = list(ACCESS_HOS)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hos.dmi'

/obj/machinery/door/airlock/hos/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/ce
	name = "Chief Engineer Office"
	req_access = list(ACCESS_CE)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/ce.dmi'

/obj/machinery/door/airlock/ce/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/rd
	name = "Research Director Office"
	req_access = list(ACCESS_RD)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/rd.dmi'

/obj/machinery/door/airlock/rd/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/qm
	name = "Quartermaster's Office"
	req_access = list(ACCESS_QM)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/qm.dmi'

/obj/machinery/door/airlock/qm/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/cmo
	name = "Chief Medical Officer Office"
	req_access = list(ACCESS_CMO)
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/cmo.dmi'

/obj/machinery/door/airlock/cmo/glass
	opacity = FALSE
	glass = TRUE
	normal_integrity = 400

/obj/machinery/door/airlock/psych
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/psych.dmi'

/obj/machinery/door/airlock/asylum
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/asylum.dmi'

/obj/machinery/door/airlock/bathroom
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/bathroom.dmi'

//STATION MINERAL AIRLOCKS
/obj/machinery/door/airlock/gold
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/gold.dmi'

/obj/machinery/door/airlock/silver
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/silver.dmi'

/obj/machinery/door/airlock/diamond
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/diamond.dmi'

/obj/machinery/door/airlock/uranium
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/uranium.dmi'

/obj/machinery/door/airlock/plasma
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/plasma.dmi'

/obj/machinery/door/airlock/bananium
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/bananium.dmi'

/obj/machinery/door/airlock/sandstone
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/sandstone.dmi'

/obj/machinery/door/airlock/wood
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/wood.dmi'

//STATION 2 AIRLOCKS

/obj/machinery/door/airlock/public
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station2/glass.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station2/overlays.dmi'

//EXTERNAL AIRLOCKS
/obj/machinery/door/airlock/external
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/external/external.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/external/overlays.dmi'

//CENTCOM
/obj/machinery/door/airlock/centcom
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/centcom.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/overlays.dmi'

/obj/machinery/door/airlock/grunge
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/centcom.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/overlays.dmi'

//VAULT
/obj/machinery/door/airlock/vault
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/vault/vault.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/vault/overlays.dmi'

//HATCH
/obj/machinery/door/airlock/hatch
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/centcom.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/overlays.dmi'

/obj/machinery/door/airlock/hatch/syndicate
	doorDeni = 'modular_bluemoon/icons/obj/machines/airlock/access_denied.ogg'
	doorOpen = 'modular_bluemoon/icons/obj/machines/airlock/airlock_ext_open.ogg'
	doorClose = 'modular_bluemoon/icons/obj/machines/airlock/airlock_ext_close.ogg'

/obj/machinery/door/airlock/maintenance_hatch
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/maintenance.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/overlays.dmi'

//HIGH SEC
/obj/machinery/door/airlock/highsecurity
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/highsec/highsec.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/highsec/overlays.dmi'


// MULTI TILE

/obj/machinery/door/airlock/multi_tile/metal
	icon = 'modular_bluemoon/icons/obj/aesthetics/large_doors/metal/multi_tile.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/large_doors/metal/overlays.dmi'
	doorDeni = 'modular_bluemoon/icons/obj/machines/airlock/access_denied.ogg'
	doorOpen = 'modular_bluemoon/icons/obj/machines/airlock/airlockopen.ogg'
	doorClose = 'modular_bluemoon/icons/obj/machines/airlock/airlockclose.ogg'

/obj/machinery/door/airlock/multi_tile/glass
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/multi_tile/multi_tile.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/multi_tile/overlays.dmi'


//ASSEMBLYS
/obj/structure/door_assembly/door_assembly_public
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station2/glass.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station2/overlays.dmi'

/obj/structure/door_assembly/door_assembly_com
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/command.dmi'

/obj/structure/door_assembly/door_assembly_sec
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/security.dmi'

/obj/structure/door_assembly/door_assembly_eng
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/engineering.dmi'

/obj/structure/door_assembly/door_assembly_min
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/mining.dmi'

/obj/structure/door_assembly/door_assembly_atmo
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/atmos.dmi'

/obj/structure/door_assembly/door_assembly_research
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/research.dmi'

/obj/structure/door_assembly/door_assembly_science
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/science.dmi'

/obj/structure/door_assembly/door_assembly_viro
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/virology.dmi'

/obj/structure/door_assembly/door_assembly_med
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/medical.dmi'

/obj/structure/door_assembly/door_assembly_mai
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/maintenance.dmi'

/obj/structure/door_assembly/door_assembly_extmai
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/maintenanceexternal.dmi'

/obj/structure/door_assembly/door_assembly_ext
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/external/external.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/external/overlays.dmi'

/obj/structure/door_assembly/door_assembly_fre
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/freezer.dmi'

/obj/structure/door_assembly/door_assembly_hatch
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/centcom.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/overlays.dmi'

/obj/structure/door_assembly/door_assembly_mhatch
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/maintenance.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hatch/overlays.dmi'

/obj/structure/door_assembly/door_assembly_highsecurity
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/highsec/highsec.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/highsec/overlays.dmi'

/obj/structure/door_assembly/door_assembly_vault
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/vault/vault.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/vault/overlays.dmi'


/obj/structure/door_assembly/door_assembly_centcom
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/centcom.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/overlays.dmi'

/obj/structure/door_assembly/door_assembly_grunge
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/centcom.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/centcom/overlays.dmi'

/obj/structure/door_assembly/door_assembly_gold
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/gold.dmi'

/obj/structure/door_assembly/door_assembly_silver
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/silver.dmi'

/obj/structure/door_assembly/door_assembly_diamond
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/diamond.dmi'

/obj/structure/door_assembly/door_assembly_uranium
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/uranium.dmi'

/obj/structure/door_assembly/door_assembly_plasma
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/plasma.dmi'

/obj/structure/door_assembly/door_assembly_bananium
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/bananium.dmi'

/obj/structure/door_assembly/door_assembly_sandstone
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/sandstone.dmi'

/obj/structure/door_assembly/door_assembly_wood
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/wood.dmi'

/obj/structure/door_assembly/door_assembly_corporate
	name = "corporate airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/corporate.dmi'
	glass_type = /obj/machinery/door/airlock/corporate/glass
	airlock_type = /obj/machinery/door/airlock/corporate

/obj/structure/door_assembly/door_assembly_service
	name = "service airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/service.dmi'
	base_name = "service airlock"
	glass_type = /obj/machinery/door/airlock/service/glass
	airlock_type = /obj/machinery/door/airlock/service

/obj/structure/door_assembly/door_assembly_captain
	name = "captain airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/cap.dmi'
	glass_type = /obj/machinery/door/airlock/command/glass
	airlock_type = /obj/machinery/door/airlock/captain

/obj/structure/door_assembly/door_assembly_hop
	name = "head of personnel airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hop.dmi'
	glass_type = /obj/machinery/door/airlock/command/glass
	airlock_type = /obj/machinery/door/airlock/hop

/obj/structure/door_assembly/hos
	name = "head of security airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/hos.dmi'
	glass_type = /obj/machinery/door/airlock/hos/glass
	airlock_type = /obj/machinery/door/airlock/hos

/obj/structure/door_assembly/door_assembly_cmo
	name = "chief medical officer airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/cmo.dmi'
	glass_type = /obj/machinery/door/airlock/cmo/glass
	airlock_type = /obj/machinery/door/airlock/cmo

/obj/structure/door_assembly/door_assembly_ce
	name = "chief engineer airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/ce.dmi'
	glass_type = /obj/machinery/door/airlock/ce/glass
	airlock_type = /obj/machinery/door/airlock/ce

/obj/structure/door_assembly/door_assembly_rd
	name = "research director airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/rd.dmi'
	glass_type = /obj/machinery/door/airlock/rd/glass
	airlock_type = /obj/machinery/door/airlock/rd

/obj/structure/door_assembly/door_assembly_qm
	name = "quartermaster airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/qm.dmi'
	glass_type = /obj/machinery/door/airlock/qm/glass
	airlock_type = /obj/machinery/door/airlock/qm

/obj/structure/door_assembly/door_assembly_psych
	name = "psychologist airlock assembly"
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/psych.dmi'
	glass_type = /obj/machinery/door/airlock/medical/glass
	airlock_type = /obj/machinery/door/airlock/psych

/obj/structure/door_assembly/door_assembly_asylum
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/asylum.dmi'

/obj/structure/door_assembly/door_assembly_bathroom
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/bathroom.dmi'

/obj/machinery/door/airlock/hydroponics
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/botany.dmi'

/obj/structure/door_assembly/door_assembly_hydro
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/botany.dmi'

/obj/structure/door_assembly/
	icon = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/public.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/aesthetics/airlock/airlocks/station/overlays.dmi'

#undef AIRLOCK_LIGHT_POWER
#undef AIRLOCK_LIGHT_RANGE

#undef AIRLOCK_POWERON_LIGHT_COLOR
#undef AIRLOCK_BOLTS_LIGHT_COLOR
#undef AIRLOCK_ACCESS_LIGHT_COLOR
#undef AIRLOCK_EMERGENCY_LIGHT_COLOR
#undef AIRLOCK_DENY_LIGHT_COLOR

#undef AIRLOCK_CLOSED
#undef AIRLOCK_CLOSING
#undef AIRLOCK_OPEN
#undef AIRLOCK_OPENING
#undef AIRLOCK_DENY
#undef AIRLOCK_EMAG

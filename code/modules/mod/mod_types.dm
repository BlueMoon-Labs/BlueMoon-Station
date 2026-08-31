/obj/item/mod/control/pre_equipped
	var/applied_skin
	var/equip_cell = /obj/item/stock_parts/cell/high

/obj/item/mod/control/pre_equipped/Initialize(mapload, new_theme, new_skin)
	new_skin = applied_skin
	MOD_CELL = equip_cell
	return ..()

/obj/item/mod/control/pre_equipped/standard
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
	)

/obj/item/mod/control/pre_equipped/engineering
	theme = /datum/mod_theme/engineering
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/magboot,
	)

/obj/item/mod/control/pre_equipped/atmospheric
	theme = /datum/mod_theme/atmospheric
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/t_ray,
	)

/obj/item/mod/control/pre_equipped/advanced
	theme = /datum/mod_theme/advanced
	equip_cell = /obj/item/stock_parts/cell/super
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/jetpack,
	)

/obj/item/mod/control/pre_equipped/mining
	theme = /datum/mod_theme/mining
	equip_cell = /obj/item/stock_parts/cell/high/plus
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/orebag,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/magboot,
		/obj/item/mod/module/drill,
	)

/obj/item/mod/control/pre_equipped/medical
	theme = /datum/mod_theme/medical
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/health_analyzer,
		/obj/item/mod/module/quick_carry,
	)

/obj/item/mod/control/pre_equipped/rescue
	theme = /datum/mod_theme/rescue
	equip_cell = /obj/item/stock_parts/cell/super
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/health_analyzer,
		/*/obj/item/mod/module/injector,*/ //Injector module unported as of now.
	)

/obj/item/mod/control/pre_equipped/research
	theme = /datum/mod_theme/research
	equip_cell = /obj/item/stock_parts/cell/super
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/t_ray,
	)

/obj/item/mod/control/pre_equipped/security
	theme = /datum/mod_theme/security
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

/obj/item/mod/control/pre_equipped/security/catcrin
	theme = /datum/mod_theme/security/catcrin

/obj/item/mod/control/pre_equipped/safeguard
	theme = /datum/mod_theme/safeguard
	equip_cell = /obj/item/stock_parts/cell/super
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/jetpack,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

/obj/item/mod/control/pre_equipped/magnate
	theme = /datum/mod_theme/magnate
	equip_cell = /obj/item/stock_parts/cell/hyper
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

/obj/item/mod/control/pre_equipped/traitor
	theme = /datum/mod_theme/syndicate
	equip_cell = /obj/item/stock_parts/cell/super
	initial_modules = list(
		/obj/item/mod/module/storage/syndicate,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/dna_lock,
		/obj/item/mod/module/jetpack/advanced,
	)

/obj/item/mod/control/pre_equipped/nuclear
	theme = /datum/mod_theme/syndicate
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage/extended/syndicate,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/visor/thermal,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

/obj/item/mod/control/pre_equipped/elite
	theme = /datum/mod_theme/elite
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage/extended/syndicate,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/emp_shield,
		/obj/item/mod/module/visor/thermal,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/holster,
	)

/obj/item/mod/control/pre_equipped/prototype
	theme = /datum/mod_theme/prototype
	equip_cell = /obj/item/stock_parts/cell/high/plus
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/tether,
	)

/obj/item/mod/control/pre_equipped/responsory
	theme = /datum/mod_theme/responsory
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/emp_shield,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)
	var/insignia_type = /obj/item/mod/module/insignia
	var/additional_module

/obj/item/mod/control/pre_equipped/responsory/Initialize(mapload, new_theme, new_skin)
	initial_modules.Insert(1, insignia_type)
	if(additional_module)
		initial_modules.Add(additional_module)
	return ..()

/obj/item/mod/control/pre_equipped/responsory/commander
	insignia_type = /obj/item/mod/module/insignia/commander
	additional_module = /obj/item/mod/module/noslip

/obj/item/mod/control/pre_equipped/responsory/security
	insignia_type = /obj/item/mod/module/insignia/security
	additional_module = /obj/item/mod/module/gps

/obj/item/mod/control/pre_equipped/responsory/engineer
	insignia_type = /obj/item/mod/module/insignia/engineer
	additional_module = /obj/item/mod/module/rad_protection

/obj/item/mod/control/pre_equipped/responsory/medic
	insignia_type = /obj/item/mod/module/insignia/medic
	additional_module = /obj/item/mod/module/quick_carry

/obj/item/mod/control/pre_equipped/responsory/janitor
	insignia_type = /obj/item/mod/module/insignia/janitor
	additional_module = /obj/item/mod/module/clamp

/obj/item/mod/control/pre_equipped/responsory/clown
	insignia_type = /obj/item/mod/module/insignia/clown
	additional_module = /obj/item/mod/module/bikehorn

/obj/item/mod/control/pre_equipped/responsory/chaplain
	insignia_type = /obj/item/mod/module/insignia/chaplain
	/*additional_module = /obj/item/mod/module/injector*/ //Injector module unported as of now.

/obj/item/mod/control/pre_equipped/responsory/inquisitory
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/anti_magic,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/emp_shield,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/holster,
	)
	applied_skin = "inquisitory"

/obj/item/mod/control/pre_equipped/responsory/inquisitory/commander
	insignia_type = /obj/item/mod/module/insignia/commander
	additional_module = /obj/item/mod/module/noslip

/obj/item/mod/control/pre_equipped/responsory/inquisitory/security
	insignia_type = /obj/item/mod/module/insignia/security
	additional_module = /obj/item/mod/module/gps

/obj/item/mod/control/pre_equipped/responsory/inquisitory/medic
	insignia_type = /obj/item/mod/module/insignia/medic
	additional_module = /obj/item/mod/module/quick_carry

/obj/item/mod/control/pre_equipped/responsory/inquisitory/chaplain
	insignia_type = /obj/item/mod/module/insignia/chaplain
	/*additional_module = /obj/item/mod/module/injector*/ //Injector module unported as of now.

/obj/item/mod/control/pre_equipped/apocryphal
	theme = /datum/mod_theme/apocryphal
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/emp_shield,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/jetpack,
	)

/obj/item/mod/control/pre_equipped/corporate
	theme = /datum/mod_theme/corporate
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/holster,
	)

/obj/item/mod/control/pre_equipped/debug
	theme = /datum/mod_theme/debug
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/bikehorn,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/tether,
		/*/obj/item/mod/module/injector,*/ //Injector module unported as of now.
	) //one of every type of module, for testing if they all work correctly

/obj/item/mod/control/pre_equipped/administrative
	theme = /datum/mod_theme/administrative
	equip_cell = /obj/item/stock_parts/cell/infinite/abductor
	initial_modules = list(
		/obj/item/mod/module/storage,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/quick_carry/advanced,
		/obj/item/mod/module/magboot/advanced,
		/obj/item/mod/module/jetpack/advanced,
	)

/obj/item/mod/control/pre_equipped/inteq
	theme = /datum/mod_theme/inteq
	equip_cell = /obj/item/stock_parts/cell/bluespace
	initial_modules = list(
		/obj/item/mod/module/storage/extended/syndicate,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/flashlight,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

//these exist for the prefs menu
/obj/item/mod/control/pre_equipped/syndicate_empty
	theme = /datum/mod_theme/syndicate

/obj/item/mod/control/pre_equipped/syndicate_empty/elite
	theme = /datum/mod_theme/elite

/obj/item/mod/control/pre_equipped/lustwish
	slot_flags = ITEM_SLOT_BELT
	theme = /datum/mod_theme/lustwish
	initial_modules = list(
		/obj/item/mod/module/nudity_lover,
	)

/obj/item/mod/control/pre_equipped/infiltrator_inteq
	slot_flags = ITEM_SLOT_BELT
	equip_cell = /obj/item/stock_parts/cell/bluespace
	theme = /datum/mod_theme/inteq/infiltrator
	initial_modules = list(
		/obj/item/mod/module/storage/extended/syndicate,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/noslip,
		/obj/item/mod/module/stealth,
		/obj/item/mod/module/visor/night,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/springlock/advanced/antagonist, //нерушима
		/obj/item/mod/module/infiltrator,
		/obj/item/mod/module/dna_lock/antag,
	)

/obj/item/mod/control/pre_equipped/traitor/inteq
	equip_cell = /obj/item/stock_parts/cell/bluespace
	theme = /datum/mod_theme/inteq/traitor
	initial_modules = list(
		/obj/item/mod/module/storage/extended/syndicate,
		/obj/item/mod/module/welding,
		/obj/item/mod/module/visor/night,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/dna_lock/antag,
	)

/obj/item/mod/control/pre_equipped/blueshied
	equip_cell = /obj/item/stock_parts/cell/hyper
	theme = /datum/mod_theme/blueshied
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/holster,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

/obj/item/choice_beacon/blueshied_suit
	name = "blueshied Suit Beacon"
	desc = "MOD или хардсьют"

/obj/item/choice_beacon/blueshied_suit/generate_display_names()
	var/static/list/suit_list
	if(!suit_list)
		suit_list = list()
		var/list/templist = list(
		/obj/item/mod/control/pre_equipped/blueshied,
		/obj/item/storage/box/blue_shield_hs,
		)
		for(var/V in templist)
			var/atom/A = V
			suit_list[initial(A.name)] = A
	return suit_list

/obj/item/mod/control/pre_equipped/expeditor
	theme = /datum/mod_theme/security/expeditor
	initial_modules = list(
		/obj/item/mod/module/storage/extended,
		/obj/item/mod/module/jetpack/advanced,
		/obj/item/mod/module/flashlight/vanguard,
		/obj/item/mod/module/gps/vanguard,
		/obj/item/mod/module/armor/prebuild/bullet,
		/obj/item/mod/module/armor/prebuild/laser,
	)

INITIALIZE_IMMEDIATE(/obj/item/mod/control/pre_equipped/syndicate_empty)

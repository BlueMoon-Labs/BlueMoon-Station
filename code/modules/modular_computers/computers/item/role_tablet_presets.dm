/**
 * ## Role Tablet Presets
 *
 * Job-specific PDA subtypes with pre-installed programs.
 * Adapted from SPLURT for BlueMoon without greyscale system — uses fixed icon_states from pda_alt.dmi.
 */

// =====================
// Command
// =====================

/obj/item/modular_computer/pda/heads
	max_capacity = 64
	cell = /obj/item/stock_parts/cell/super
	var/static/list/datum/computer_file/head_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/robocontrol,
		/datum/computer_file/program/budgetorders,
	)

/obj/item/modular_computer/pda/heads/Initialize(mapload)
	. = ..()
	var/obj/item/computer_hardware/hard_drive/hdd = all_components[MC_HDD]
	for(var/programs in head_programs)
		var/datum/computer_file/program/program_type = new programs
		program_type.computer = src
		if(hdd)
			hdd.store_file(program_type)
		else
			store_file(program_type)

/obj/item/modular_computer/pda/heads/captain
	name = "captain PDA"
	icon_state = "pda-captain"
	inserted_item = /obj/item/pen/fountain/captain

/obj/item/modular_computer/pda/heads/captain/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TABLET_CHECK_DETONATE, PROC_REF(tab_no_detonate))
	for(var/datum/computer_file/program/messenger/messenger_app in get_all_files())
		messenger_app.spam_mode = TRUE

/obj/item/modular_computer/pda/heads/captain/proc/tab_no_detonate()
	SIGNAL_HANDLER
	return COMPONENT_TABLET_NO_DETONATE

/obj/item/modular_computer/pda/heads/hop
	name = "head of personnel PDA"
	icon_state = "pda-hop"
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/job_management,
	)

/obj/item/modular_computer/pda/heads/hos
	name = "head of security PDA"
	icon_state = "pda-hos"
	inserted_item = /obj/item/pen/red
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
	)

/obj/item/modular_computer/pda/heads/ce
	name = "chief engineer PDA"
	icon_state = "pda-ce"
	starting_programs = list(
		/datum/computer_file/program/atmosscan,
		/datum/computer_file/program/alarm_monitor,
		/datum/computer_file/program/supermatter_monitor,
	)

/obj/item/modular_computer/pda/heads/cmo
	name = "chief medical officer PDA"
	icon_state = "pda-cmo"
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
	)

/obj/item/modular_computer/pda/heads/rd
	name = "research director PDA"
	icon_state = "pda-rd"
	inserted_item = /obj/item/pen/fountain
	starting_programs = list(
		/datum/computer_file/program/borg_monitor,
		/datum/computer_file/program/signaler,
	)

/obj/item/modular_computer/pda/heads/quartermaster
	name = "quartermaster PDA"
	icon_state = "pda-qm"
	inserted_item = /obj/item/pen/survival
	stored_paper = 20
	starting_programs = list(
		/datum/computer_file/program/shipping,
		/datum/computer_file/program/budgetorders,
	)

// =====================
// Security
// =====================

/obj/item/modular_computer/pda/security
	name = "security PDA"
	icon_state = "pda-security"
	inserted_item = /obj/item/pen/red
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/robocontrol,
	)

/obj/item/modular_computer/pda/detective
	name = "detective PDA"
	icon_state = "pda-detective"
	inserted_item = /obj/item/pen/red
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/robocontrol,
	)

/obj/item/modular_computer/pda/warden
	name = "warden PDA"
	icon_state = "pda-warden"
	inserted_item = /obj/item/pen/red
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/robocontrol,
	)

/obj/item/modular_computer/pda/security/brigdoc
	name = "brig physician PDA"
	icon_state = "pda-security"
	inserted_item = /obj/item/pen/red
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/robocontrol,
		/datum/computer_file/program/secureye,
		/datum/computer_file/program/radar/lifeline,
	)

// =====================
// Engineering
// =====================

/obj/item/modular_computer/pda/engineering
	name = "engineering PDA"
	icon_state = "pda-engineer"
	starting_programs = list(
		/datum/computer_file/program/alarm_monitor,
		/datum/computer_file/program/atmosscan,
		/datum/computer_file/program/supermatter_monitor,
	)

/obj/item/modular_computer/pda/atmos
	name = "atmospherics PDA"
	icon_state = "pda-atmos"
	starting_programs = list(
		/datum/computer_file/program/alarm_monitor,
		/datum/computer_file/program/atmosscan,
		/datum/computer_file/program/supermatter_monitor,
	)

// =====================
// Science
// =====================

/obj/item/modular_computer/pda/science
	name = "scientist PDA"
	icon_state = "pda-science"
	starting_programs = list(
		/datum/computer_file/program/atmosscan,
		/datum/computer_file/program/signaler,
	)

/obj/item/modular_computer/pda/roboticist
	name = "roboticist PDA"
	icon_state = "pda-roboticist"
	starting_programs = list(
		/datum/computer_file/program/robocontrol,
		/datum/computer_file/program/borg_monitor,
	)

/obj/item/modular_computer/pda/geneticist
	name = "geneticist PDA"
	icon_state = "pda-genetics"
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
	)

// =====================
// Medical
// =====================

/obj/item/modular_computer/pda/medical
	name = "medical PDA"
	icon_state = "pda-medical"
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/robocontrol,
	)

/obj/item/modular_computer/pda/medical/paramedic
	name = "paramedic PDA"
	icon_state = "pda-medical"
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
		/datum/computer_file/program/radar/lifeline,
	)

/obj/item/modular_computer/pda/chemist
	name = "chemist PDA"
	icon_state = "pda-chemistry"

/obj/item/modular_computer/pda/virology
	name = "virologist PDA"
	icon_state = "pda-virology"
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
	)

// =====================
// Supply
// =====================

/obj/item/modular_computer/pda/cargo
	name = "cargo technician PDA"
	icon_state = "pda-cargo"
	stored_paper = 20
	starting_programs = list(
		/datum/computer_file/program/shipping,
		/datum/computer_file/program/budgetorders,
		/datum/computer_file/program/robocontrol,
	)

/obj/item/modular_computer/pda/shaftminer
	name = "shaft miner PDA"
	icon_state = "pda-miner"

// =====================
// Service
// =====================

/obj/item/modular_computer/pda/janitor
	name = "janitor PDA"
	icon_state = "pda-janitor"

/obj/item/modular_computer/pda/chaplain
	name = "chaplain PDA"
	icon_state = "pda-chaplain"

/obj/item/modular_computer/pda/lawyer
	name = "lawyer PDA"
	icon_state = "pda-security"
	inserted_item = /obj/item/pen/fountain
	starting_programs = list(
		/datum/computer_file/program/crew_manifest,
	)

/obj/item/modular_computer/pda/lawyer/Initialize(mapload)
	. = ..()
	for(var/datum/computer_file/program/messenger/messenger_app in get_all_files())
		messenger_app.spam_mode = TRUE

/obj/item/modular_computer/pda/botanist
	name = "botanist PDA"
	icon_state = "pda-hydro"

/obj/item/modular_computer/pda/cook
	name = "cook PDA"
	icon_state = "pda-cook"

/obj/item/modular_computer/pda/bar
	name = "bartender PDA"
	icon_state = "pda-bartender"
	inserted_item = /obj/item/pen/fountain

/obj/item/modular_computer/pda/clown
	name = "clown PDA"
	icon = 'icons/obj/devices/modular_pda.dmi'
	icon_state = "pda-clown"
	inserted_disk = /obj/item/cartridge/virus/clown
	inserted_item = /obj/item/toy/crayon/rainbow

/obj/item/modular_computer/pda/clown/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/slippery, 12 SECONDS, NO_SLIP_WHEN_WALKING, CALLBACK(src, PROC_REF(AfterSlip)))

/// Returns whether the PDA can slip or not.
/obj/item/modular_computer/pda/clown/proc/try_slip(mob/living/slipper, mob/living/slippee)
	if(isnull(slipper))
		return TRUE
	if(!istype(slipper.get_item_by_slot(ITEM_SLOT_FEET), /obj/item/clothing/shoes/clown_shoes))
		to_chat(slipper, span_warning("[src] failed to slip anyone. Perhaps I shouldn't have abandoned my legacy..."))
		return FALSE
	return TRUE

/obj/item/modular_computer/pda/clown/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "pda_stripe_clown")

/obj/item/modular_computer/pda/clown/proc/AfterSlip(mob/living/carbon/human/M)
	if(istype(M) && (M.real_name != saved_identification))
		var/obj/item/cartridge/virus/clown/cart = inserted_disk
		if(istype(cart) && cart.charges < 5)
			cart.charges++
			playsound(src, 'sound/machines/ping.ogg', 30, TRUE)

/obj/item/modular_computer/pda/mime
	name = "mime PDA"
	icon_state = "pda-mime"
	inserted_disk = /obj/item/cartridge/virus/mime
	inserted_item = /obj/item/toy/crayon/mime

/obj/item/modular_computer/pda/mime/Initialize(mapload)
	. = ..()
	for(var/datum/computer_file/program/messenger/msg in get_all_files())
		msg.mime_mode = TRUE
		msg.alert_silenced = TRUE

/obj/item/modular_computer/pda/curator
	name = "curator PDA"
	desc = "A small experimental microcomputer."
	icon = 'icons/obj/devices/modular_pda.dmi'
	icon_state = "pda-library"
	inserted_item = /obj/item/pen/fountain
	long_ranged = TRUE
	starting_programs = list(
		/datum/computer_file/program/portrait_printer,
	)

// =====================
// No department / misc
// =====================

/obj/item/modular_computer/pda/assistant
	name = "assistant PDA"
	max_capacity = 32

/obj/item/modular_computer/pda/lieutenant
	name = "nanotrasen representative PDA"
	icon_state = "pda-lieutenant"

/obj/item/modular_computer/pda/syndicate
	name = "military PDA"
	icon_state = "pda-syndi"
	saved_identification = "John Doe"
	saved_job = "Citizen"
	device_theme = PDA_THEME_SYNDICATE

/obj/item/modular_computer/pda/syndicate/Initialize(mapload)
	. = ..()
	var/datum/computer_file/program/messenger/msg = locate(/datum/computer_file/program/messenger) in get_all_files()
	if(msg)
		msg.invisible = TRUE

/obj/item/modular_computer/pda/clear
	name = "clear PDA"
	icon = 'icons/obj/devices/modular_pda.dmi'
	icon_state = "pda-clear"
	long_ranged = TRUE

/obj/item/modular_computer/pda/bouncer
	name = "bouncer PDA"
	icon_state = "pda-bartender"
	inserted_item = /obj/item/pen/fountain

/obj/item/modular_computer/pda/heads/ntr
	name = "nanotrasen representative PDA"
	icon_state = "pda-lieutenant"

/obj/item/modular_computer/pda/syndicate/no_deto
	name = "military PDA"
	inserted_item = /obj/item/pen/fountain

/obj/item/modular_computer/pda/chameleon
	name = "PDA"
	var/datum/action/item_action/chameleon/change/pda/chameleon_action

/obj/item/modular_computer/pda/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/modular_computer/pda
	chameleon_action.chameleon_name = "PDA"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item/modular_computer/pda/heads, /obj/item/modular_computer/pda/silicon, /obj/item/modular_computer/pda/silicon/pai), only_root_path = TRUE)
	chameleon_action.initialize_disguises()

/obj/item/modular_computer/pda/chameleon/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	chameleon_action.emp_randomise()

/obj/item/modular_computer/pda/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/modular_computer/pda/neko
	name = "neko PDA"
	icon_state = "pda-neko"
	icon_state_menu = "screen_neko"

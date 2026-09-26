/obj/item/disk/nifsoft_uploader/dorms/nif_gfluid_disk
	name = "genital fluid"
	loaded_nifsoft = /datum/nifsoft/action_granter/free/nif_gfluid

/datum/nifsoft/action_granter/free
	// Variant with pre-configured settings
	// This is designed to replace old 'free' quirks

	// Very low purchase price
	purchase_price = 100

	// Disable energy cost
	activation_cost = 0
	active_cost = 0

	// Allow persistence
	able_to_keep = TRUE

	// Default to persistent
	keep_installed = TRUE

	// Do not grant reward points
	rewards_points_rate = 0

/datum/nifsoft/action_granter/free/nif_gfluid
	name = "Genital Fluid Inducer"
	program_desc = "Allows the user to induce their genitals into producing a specific reagent. Will prevent harmful liquids from being accepted as a genital fluid replacement."
	buying_category = NIFSOFT_CATEGORY_FUN
	lewd_nifsoft = TRUE
	ui_icon = "eye"
	action_to_grant = /datum/action/innate/genital_fluid_infuse

/datum/action/innate/genital_fluid_infuse
	name = "Infuse Genital Fluids"
	desc = "Activate an integrated reagent receptor device to modify your genital contents."
	icon_icon = 'modular_splurt/icons/obj/implants.dmi'
	button_icon_state = "genital_fluid"
	button_icon = 'modular_bluemoon/code/modules/nif/icons/mob/actions/action_backgrounds.dmi'
	background_icon_state = "android"

	// Restrict non-synthesizable reagents?
	var/use_blacklist = TRUE

/datum/action/innate/genital_fluid_infuse/Activate()
	..()

	// Set list of possible genitals
	var/list/obj/item/organ/genital/genitals_list

	// Set list of possible fluids
	var/list/datum/reagent/fluid_list = list()

	// Set owner
	var/mob/living/carbon/human/genital_owner = owner

	// List their genitals if they have any at all
	for(var/obj/item/organ/genital/genital_checked in genital_owner.internal_organs)
		if(istype(genital_checked) && (genital_checked.genital_flags & GENITAL_FUID_PRODUCTION))
			// Add genitals to the list
			LAZYADD(genitals_list, genital_checked)

	// List their current reagents if they're valid
	for(var/datum/reagent/genital_reagent in genital_owner.reagents.reagent_list)
		if((find_reagent_object_from_type(genital_reagent.type)) && ((genital_reagent.type in allowed_gfluid_paths()) || !use_blacklist))
			// Add valid reagents to the list
			LAZYADD(fluid_list, find_reagent_object_from_type(genital_reagent.type))

	// List any reagents they may be holding in their hands
	if(genital_owner.available_rosie_palms(TRUE, /obj/item/reagent_containers))
		for(var/obj/item/reagent_containers/container in genital_owner.held_items)
			if(container.is_open_container() || istype(container, /obj/item/reagent_containers/food/snacks))
				for(var/datum/reagent/genital_reagent in container.reagents.reagent_list)
					if((find_reagent_object_from_type(genital_reagent.type)) && ((genital_reagent.type in allowed_gfluid_paths()) || !use_blacklist))
						// Add valid reagents to the list
						LAZYADD(fluid_list, find_reagent_object_from_type(genital_reagent.type))

	// Return if genitals list is void/null
	if(!genitals_list)
		// Play an error sound
		SEND_SOUND(genital_owner, 'sound/machines/terminal_error.ogg')

		// Alert the user in chat
		to_chat(genital_owner, span_notice("ERROR: No compatible genitals detected."))

		// Escape
		return

	// Prompt user for which genital to use
	var/obj/item/organ/genital/genital_input = tgui_input_list(genital_owner, "Pick a genital", "Genital Fluid Infuser", genitals_list)
	if(!genital_input)
		// No selection was made
		return

	// Update list of possible fluids
	fluid_list = list(find_reagent_object_from_type(genital_input.get_default_fluid())) + fluid_list

	// Prompt user to select a new fluid
	var/datum/reagent/reagent_selection = tgui_input_list(genital_owner, "Choose your new reagent", "Genital Fluid Infuser", fluid_list)
	if(!reagent_selection)
		// No selection was made
		return

	// Set new fluid
	genital_input.fluid_id = reagent_selection.type

	// Play the reagent processing sound effect
	SEND_SOUND(genital_owner, 'sound/effects/bubbles.ogg')

	// Display flavor text
	to_chat(genital_owner, span_notice("You feel the fluids inside your [genital_input.name] bubble and swirl..."))

	// Send admin notice
	message_admins("[ADMIN_LOOKUPFLW(genital_owner)] changed the fluid of [genital_owner.ru_ego()] [genital_input.name] to [reagent_selection].")

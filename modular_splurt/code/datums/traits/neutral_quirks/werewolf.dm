/datum/quirk/werewolf //adds the werewolf quirk
	name = "Оборотень"
	desc = "Ликантропия позволяет вам перевоплощаться в большого прямоходящего волка."
	value = 0
	mob_trait = TRAIT_WEREWOLF
	gain_text = span_notice("Полная луна зовёт.")
	lose_text = span_notice("Зов луны растворяется в тишине.")
	medical_record_text = "Сообщалось, что пациент выл на ночное небо."
	var/list/old_features

/datum/quirk/werewolf/add()
	// Define old features
	old_features = list("species" = SPECIES_HUMAN, "legs" = "Plantigrade", "size" = 1, "bark")

	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Record features
	old_features = quirk_mob.dna.features.Copy()
	old_features["species"] = quirk_mob.dna.species.type
	old_features["custom_species"] = quirk_mob.custom_species
	old_features["size"] = get_size(quirk_mob)
	old_features["bark"] = quirk_mob.vocal_bark_id
	old_features["taur"] = quirk_mob.dna.features["taur"]
	old_features["eye_type"] = quirk_mob.dna.species.eye_type

/datum/quirk/werewolf/post_add()
	// Define quirk action
	var/datum/action/cooldown/werewolf/transform/quirk_action = new

	// Grant quirk action
	quirk_action.Grant(quirk_holder)

/datum/quirk/werewolf/remove()
	// BLUEMOON EDIT START - sanity check
	if(!quirk_holder)
		return
	// BLUEMOON EDIT END
	// Define quirk action
	var/datum/action/cooldown/werewolf/transform/quirk_action = locate() in quirk_holder.actions

	// Revoke quirk action
	if(quirk_action)
		quirk_action.Remove(quirk_holder)

//
// Quirk actions: Werewolf
//

/datum/action/cooldown/werewolf
	name = "Werewolf Ability"
	desc = "Do something related to werewolves."
	icon_icon = 'modular_splurt/icons/mob/actions/misc_actions.dmi'
	button_icon_state = "Transform"
	check_flags = AB_CHECK_RESTRAINED | AB_CHECK_STUN | AB_CHECK_CONSCIOUS | AB_CHECK_ALIVE
	cooldown_time = 5 SECONDS
	transparent_when_unavailable = TRUE

/datum/action/cooldown/werewolf/transform
	name = "Toggle Werewolf Form"
	desc = "Transform in or out of your wolf form."
	var/transformed = FALSE
	var/species_changed = FALSE
	var/werewolf_gender = "Lycan"
	var/list/old_features

/datum/action/cooldown/werewolf/transform/Grant()
	. = ..()

	// Define carbon owner
	var/mob/living/carbon/action_owner_carbon = owner

	// Define parent quirk
	var/datum/quirk/werewolf/quirk_data = locate() in action_owner_carbon.roundstart_quirks

	// Check if data was copied
	if(!quirk_data)
		// Log error and return
		log_game("Failed to get species data for werewolf action!")
		return

	// Define stored features
	old_features = quirk_data.old_features.Copy()

	// Define action owner
	var/mob/living/carbon/human/action_owner = owner

	// Set species gendered name
	switch(action_owner.gender)
		if(MALE)
			werewolf_gender = "Wer"
		if(FEMALE)
			werewolf_gender = "Wīf"
		if(PLURAL)
			werewolf_gender = "Hie"
		if(NEUTER)
			werewolf_gender = "Þing"

/datum/action/cooldown/werewolf/transform/Activate()
	// Define action owner
	var/mob/living/carbon/human/action_owner = owner

	// Check for restraints
	if(!CHECK_MOBILITY(action_owner, MOBILITY_USE))
		// Warn user, then return
		action_owner.visible_message(span_warning("You cannot transform while restrained!"))
		return

	// Define citadel organs
	var/obj/item/organ/genital/penis/organ_penis = action_owner.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/organ/genital/breasts/organ_breasts = action_owner.getorganslot(ORGAN_SLOT_BREASTS)
	var/obj/item/organ/genital/vagina/organ_vagina = action_owner.getorganslot(ORGAN_SLOT_VAGINA)

	// Play shake animation
	action_owner.shake_animation(2)

	// Transform into wolf form
	if(!transformed)
		// Define current species type
		var/datum/species/owner_species = action_owner.dna.species.type

		// Check if species has changed
		if(old_features["species"] != owner_species)
			// Set old species
			old_features["species"] = owner_species

		// Define species prefix
		var/custom_species_prefix

		// Check if species is mammal (anthro)
		if(ismammal(action_owner))
			// Do nothing!

		// Check if species is already a mammal sub-type
		else if(ispath(owner_species, /datum/species/mammal))
			// Do nothing!

		// Check if species is a jelly
		else if(isjellyperson(action_owner))
			// Set species prefix
			custom_species_prefix = "Jelly "

		// Check if species is a jelly subtype
		else if(ispath(owner_species, /datum/species/jelly))
			// Set species prefix
			custom_species_prefix = "Slime "

		// Species is not a mammal
		else
			// Change species
			action_owner.set_species(/datum/species/mammal, 1)

			// Set species changed
			species_changed = TRUE

		// Set species features
		action_owner.dna.custom_species = "[custom_species_prefix][werewolf_gender]wulf"
		action_owner.dna.species.mutant_bodyparts["mam_tail"] = "Otusian"
		action_owner.dna.species.mutant_bodyparts["legs"] = "Digitigrade"
		action_owner.Digitigrade_Leg_Swap(FALSE)
		action_owner.dna.species.mutant_bodyparts["mam_snouts"] = "Sergal"
		action_owner.dna.features["mam_ears"] = "Jackal"
		action_owner.dna.features["mam_tail"] = "Otusian"
		action_owner.dna.features["mam_snouts"] = "Sergal"
		action_owner.dna.features["legs"] = "Digitigrade"
		action_owner.dna.features["insect_fluff"] = "Hyena"
		action_owner.update_size(clamp(get_size(action_owner) + 0.5, RESIZE_MICRO, RESIZE_MACRO))
		action_owner.set_bark("bark")
		if(old_features["taur"] != "None")
			action_owner.dna.features["taur"] = "Canine"
		if(!(action_owner.dna.species.species_traits.Find(DIGITIGRADE)))
			action_owner.dna.species.species_traits += DIGITIGRADE
		action_owner.update_body()
		action_owner.update_body_parts()

		// Update possible citadel organs
		if(organ_breasts)
			organ_breasts.color = "#[action_owner.dna.features["mcolor"]]"
			organ_breasts.update()
		if(organ_penis)
			organ_penis.shape = "Knotted"
			organ_penis.color = "#ff7c80"
			organ_penis.update()
			organ_penis.modify_size(6)
		if(organ_vagina)
			organ_vagina.shape = "Furred"
			organ_vagina.color = "#[action_owner.dna.features["mcolor"]]"
			organ_vagina.update()

	// Un-transform from wolf form
	else
		// Check if species was already mammal (anthro)
		if(!species_changed)
			// Do nothing!

		// Species was not a mammal
		else
			// Revert species
			action_owner.set_species(old_features["species"], TRUE)

			// Clear species changed flag
			species_changed = FALSE

		// Revert species trait
		action_owner.set_bark(old_features["bark"])
		action_owner.dna.custom_species = old_features["custom_species"]
		action_owner.dna.features["mam_ears"] = old_features["mam_ears"]
		action_owner.dna.features["mam_snouts"] = old_features["mam_snouts"]
		action_owner.dna.features["mam_tail"] = old_features["mam_tail"]
		action_owner.dna.features["legs"] = old_features["legs"]
		action_owner.dna.features["insect_fluff"] = old_features["insect_fluff"]
		action_owner.dna.species.eye_type = old_features["eye_type"]
		if(old_features["taur"] != "None")
			action_owner.dna.features["taur"] = old_features["taur"]
		if(old_features["legs"] == "Plantigrade")
			action_owner.dna.species.species_traits -= DIGITIGRADE
			action_owner.Digitigrade_Leg_Swap(TRUE)
			action_owner.dna.species.mutant_bodyparts["legs"] = old_features["legs"]
		action_owner.update_body()
		action_owner.update_body_parts()
		action_owner.update_size(clamp(get_size(action_owner) - 0.5, RESIZE_MICRO, RESIZE_MACRO))

		// Revert citadel organs
		if(organ_breasts)
			organ_breasts.color = "#[old_features["breasts_color"]]"
			organ_breasts.update()
		if(action_owner.has_penis())
			organ_penis.shape = old_features["cock_shape"]
			organ_penis.color = "#[old_features["cock_color"]]"
			organ_penis.update()
			organ_penis.modify_size(-6)
		if(action_owner.has_vagina())
			organ_vagina.shape = old_features["vag_shape"]
			organ_vagina.color = "#[old_features["vag_color"]]"
			organ_vagina.update()
			organ_vagina.update_size()

	// Set transformation message
	var/owner_p_their = action_owner.p_their()
	var/toggle_message = (!transformed ? "[action_owner] shivers, [owner_p_their] flesh bursting with a sudden growth of thick fur as [owner_p_their] features contort to that of a beast, fully transforming [action_owner.p_them()] into a werewolf!" : "[action_owner] shrinks, [owner_p_their] wolfish features quickly receding.")

	// Alert in local chat
	action_owner.visible_message(span_danger(toggle_message))

	// Toggle transformation state
	transformed = !transformed

	// Start cooldown
	StartCooldown()

	// Return success
	return TRUE

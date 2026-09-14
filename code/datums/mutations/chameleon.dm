//Chameleon causes the owner to slowly become transparent when not moving.
// Получение мутации будет усиливать квирк хамелеона, который работает "умнее"
/datum/mutation/human/chameleon
	name = "Chameleon"
	desc = "A genome that causes the holder's skin to become transparent over time."
	quality = POSITIVE
	difficulty = 16
	text_gain_indication = "<span class='notice'>You feel one with your surroundings.</span>"
	text_lose_indication = "<span class='notice'>You feel oddly exposed.</span>"
	time_coeff = 5
	instability = 25
	var/paused = FALSE
	var/datum/action/cooldown/chameleon_mutation_toggle/mutation_action

/datum/mutation/human/chameleon/on_acquiring(mob/living/carbon/human/owner)
	if(..() || check_strong_alpha_sources(owner) || owner.has_quirk(/datum/quirk/chameleon))
		return
	paused = FALSE
	owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY
	ADD_TRAIT(owner, TRAIT_WEAK_INVISIBILITY, GENETIC_MUTATION)
	mutation_action = new
	mutation_action.mutation_ref = src
	mutation_action.Grant(owner)

/datum/mutation/human/chameleon/on_life()
	if(check_strong_alpha_sources(owner) || owner.has_quirk(/datum/quirk/chameleon) || paused)
		return
	owner.alpha = max(0, owner.alpha - 25)

/datum/mutation/human/chameleon/on_move(atom/new_loc)
	if(check_strong_alpha_sources(owner) || owner.has_quirk(/datum/quirk/chameleon) || paused)
		return
	owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY

/datum/mutation/human/chameleon/on_attack_hand(atom/target, proximity)
	if(proximity) //stops tk from breaking chameleon
		if(check_strong_alpha_sources(owner) || owner.has_quirk(/datum/quirk/chameleon) || paused)
			return
		owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY
		return

/datum/mutation/human/chameleon/on_losing(mob/living/carbon/human/owner)
	if(..())
		return
	if(owner.has_quirk(/datum/quirk/chameleon) && owner.has_status_effect(/datum/status_effect/chameleon_quirk))
		to_chat(owner, span_warning("Вы утратили концентрацию..."))
		var/datum/action/cooldown/toggle_chameleon_quirk/quirk_toggle = locate() in owner.actions
		if(quirk_toggle)
			quirk_toggle.Activate()
	if(mutation_action)
		mutation_action.Remove(owner)
		QDEL_NULL(mutation_action)
	owner.alpha = 255
	REMOVE_TRAIT(owner, TRAIT_WEAK_INVISIBILITY, GENETIC_MUTATION)

/datum/mutation/human/chameleon/proc/toggle_mutation()
	if(!owner)
		return
	paused = !paused
	if(paused)
		owner.alpha = 255
		REMOVE_TRAIT(owner, TRAIT_WEAK_INVISIBILITY, GENETIC_MUTATION)
		to_chat(owner, span_notice("Вы отключили ген хамелеона."))
	else
		owner.alpha = CHAMELEON_MUTATION_DEFAULT_TRANSPARENCY
		ADD_TRAIT(owner, TRAIT_WEAK_INVISIBILITY, GENETIC_MUTATION)
		to_chat(owner, span_notice("Вы активировали ген хамелеона."))
	if(mutation_action)
		mutation_action.UpdateButtons()

/datum/action/cooldown/chameleon_mutation_toggle
	name = "Toggle Chameleon Gene"
	desc = "Переключить работу гена хамелеона. Позволяет включать и выключать эффект маскировки."
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "wip_spell_stone"
	cooldown_time = 0
	var/datum/mutation/human/chameleon/mutation_ref

/datum/action/cooldown/chameleon_mutation_toggle/Activate()
	if(!mutation_ref)
		return
	mutation_ref.toggle_mutation()

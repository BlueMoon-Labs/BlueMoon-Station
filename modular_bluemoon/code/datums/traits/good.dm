/datum/quirk/high_pain_threshold
	name = "Высокий болевой порог"
	desc = "Жизнь, генетика, или что-то ещё научило вас если и не жить, то терпеть физическую боль. \
	Вы можете выдержать хирургическую операцию без наркоза легче, чем большинство вашего рода. Не повышает шанс при самооперации."
	value = 1
	mob_trait = TRAIT_BLUEMOON_HIGH_PAIN_THRESHOLD
	gain_text = "<span class='notice'>Боль - иллюзия чувств. И вы предпочитаете жить не в иллюзиях.</span>"
	lose_text = "<span class='warning'>Вам кажется, что ваше тело стало более чувствительным к боли...</span>"
	medical_record_text = "Пациент во время одной из проверок физических возможностей показал повышенный болевой порог."

/datum/quirk/TK_potential
	name = "Потенциал к телекинезу"
	desc = "Мутация, природная предрасположенность или попросту видовая характеристика, но всёж вы имеете потенциал в телекинезе. \
	Впрочем, подобные силы крайне ограничены и позволяют влиять только на других в небольшом радиусе. \[Добавляет новые интеракты через панель]"
	value = 1
	mob_trait = TRAIT_TK_POTENTIAL
	gain_text = "<span class='notice'>Сила разума даёт возможность влиять на других в новом ключе.</span>"
	lose_text = "<span class='warning'>Кажется влияние вашего разума перестало действовать на других...</span>"
	medical_record_text = "Пациент имеет потенциал в телекинезе."

////////////////////////////////

/datum/quirk/chameleon
	name = "Хамелеон"
	desc = "Ввиду природных причин, псионических задатков или вмешательства, генетического или технологического, вы способны частично становиться невидимым."
	value = 2
	mob_trait = TRAIT_CHAMELEON_QUIRK
	gain_text = span_notice("Ваше тело может сливаться с окружением... Лучшая способность для пряток!")
	lose_text = span_notice("Ваше тело утратило способность частично быть невидимым...")
	medical_record_text = "Пациент способен становиться частично прозрачным."
	var/chameleon_status = /datum/status_effect/chameleon_quirk

/datum/quirk/chameleon/add()
	var/mob/living/carbon/human/quirk_mob = quirk_holder
	var/datum/action/cooldown/toggle_chameleon_quirk/chameleon_toggle = new
	chameleon_toggle.Grant(quirk_mob)

/datum/quirk/chameleon/remove()
	var/mob/living/carbon/human/quirk_mob = quirk_holder
	if(!quirk_mob)
		return
	var/datum/action/cooldown/toggle_chameleon_quirk/chameleon_toggle = locate() in quirk_mob.actions
	if(chameleon_toggle)
		if(quirk_mob.has_status_effect(chameleon_status))
			quirk_mob.remove_status_effect(chameleon_status)
		chameleon_toggle.Remove(quirk_mob)
	if(!HAS_TRAIT(quirk_mob, TRAIT_STRONG_INVISIBILITY))
		quirk_mob.alpha = 255
	if(quirk_mob.has_movespeed_modifier(/datum/movespeed_modifier/quirk_chameleon_slowdown))
		quirk_mob.remove_movespeed_modifier(/datum/movespeed_modifier/quirk_chameleon_slowdown)

// По образу и подобию квирка отстраненного, аве реимплементация
/datum/action/cooldown/toggle_chameleon_quirk
	name = "Toggle Chameleon"
	desc = "Используйте способность своего тела для адаптации к окружающей среде."
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "chameleon_quirk_off"

/datum/action/cooldown/toggle_chameleon_quirk/Activate()
	var/mob/living/carbon/human/action_owner = owner
	var/chameleon_status = /datum/status_effect/chameleon_quirk
	if(action_owner.has_status_effect(chameleon_status))
		to_chat(action_owner, span_notice("Вы перестали адаптироваться к окружению."))
		REMOVE_TRAIT(owner, TRAIT_WEAK_INVISIBILITY, QUIRK_TRAIT)
		button_icon_state = "chameleon_quirk_off"
		action_owner.remove_status_effect(chameleon_status)
	else
		to_chat(action_owner, span_warning("Вы активировали свою маскировку и концентрируетесь для сохранения эффекта!"))
		ADD_TRAIT(owner, TRAIT_WEAK_INVISIBILITY, QUIRK_TRAIT)
		button_icon_state = "chameleon_quirk_on"
		action_owner.apply_status_effect(chameleon_status)
	UpdateButtons()

////////////////////////////////

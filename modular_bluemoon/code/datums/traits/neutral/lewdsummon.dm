/datum/preferences
	var/summon_nickname = null

/datum/quirk/lewdsummon
	name = "Призываемый"
	desc = "Вы были одарены силой демонов похоти или же сами являлись её источником, что давала возможность осмелившимся безумцам призывать вас при помощи рун. Сможете ли вы исполнить их фантазии?."
	mob_trait = TRAIT_LEWD_SUMMON
	gain_text = "<span class='notice'>Призываемый - ЕРП квирк. Использование его для абуза механик, будет крайне строго наказываться ©️. </span>"

/datum/quirk/lewdsummon/add()
	var/mob/living/carbon/human/quirk_mob = quirk_holder
	var/datum/action/cooldown/toggle_lewdsummon/act_toggle = new
	act_toggle.Grant(quirk_mob)

/datum/quirk/lewdsummon/remove()
	var/mob/living/carbon/human/quirk_mob = quirk_holder
	// sanity check
	if(!quirk_mob)
		return
	var/datum/action/cooldown/toggle_lewdsummon/act_toggle = locate() in quirk_mob.actions
	if(act_toggle)
		act_toggle.Remove(quirk_mob)

/datum/action/cooldown/toggle_lewdsummon
	name = "Переключить призываемость"
	desc = "Позволяет переключить возможность вашего призыва через квирк \"призываемый\""
	icon_icon = 'modular_splurt/icons/mob/actions/lewd_actions/lewd_icons.dmi'
	button_icon_state = "arousal_max"

/datum/action/cooldown/toggle_lewdsummon/Activate()
	var/mob/living/carbon/human/action_owner = owner

	if(HAS_TRAIT_FROM(action_owner, TRAIT_LEWD_SUMMONED, "lewd_summon_dont_disturb")) // объясняю позицию - не хочу плодить сущности
		REMOVE_TRAIT(action_owner, TRAIT_LEWD_SUMMONED, "lewd_summon_dont_disturb") // но и не хочу удалять трейт от квирка
		to_chat(action_owner, span_notice("Теперь вас смогут призвать!"))
		button_icon_state = "arousal_max"
	else
		ADD_TRAIT(action_owner, TRAIT_LEWD_SUMMONED, "lewd_summon_dont_disturb")
		to_chat(action_owner, span_warning("Теперь вас не смогут призвать!"))
		button_icon_state = "pleasure_max"

	UpdateButtons()

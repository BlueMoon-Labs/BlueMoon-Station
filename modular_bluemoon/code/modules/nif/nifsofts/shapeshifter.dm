/obj/item/disk/nifsoft_uploader/shapeshifter
	name = "Polymorph"
	loaded_nifsoft = /datum/nifsoft/action_granter/shapeshifter

/datum/nifsoft/action_granter/shapeshifter
	name = "Polymorph"
	program_desc = "This program is a large-scale refitting of the nanomachine channels running over the skin of a NIF user. This allows the nanites to reach under the skin and even into the very bone structure of the host; including incorporation of mimetic materials and femto-level manipulation devices all for the purpose of allowing the user to, essentially, shapeshift on a low level. However, despite the incredible complexity behind these processes, there are still limits on the range of 'forms' a user can take. Mass can neither be created nor destroyed, after all, and you can only distribute and rearrange it in so many ways across a functioning humanoid body; meaning, the user cannot adopt forms too far out of their 'true' one."
	compatible_nifs = list(/obj/item/organ/cyberimp/brain/nif/standard)
	purchase_price = 350
	buying_category = NIFSOFT_CATEGORY_COSMETIC
	ui_icon = "paintbrush"
	action_to_grant = /datum/action/innate/ability/humanoid_customization/nif

/// The NIF version of form alteration, powered by the same menu as the innate humans one.
/datum/action/innate/ability/humanoid_customization/nif
	name = "Polymorph"
	button_icon = 'modular_bluemoon/code/modules/nif/icons/mob/actions/action_backgrounds.dmi'
	background_icon_state = "android"
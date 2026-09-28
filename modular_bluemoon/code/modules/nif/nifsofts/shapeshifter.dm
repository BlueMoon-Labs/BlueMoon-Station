/obj/item/disk/nifsoft_uploader/shapeshifter
	name = "Polymorph"
	loaded_nifsoft = /datum/nifsoft/action_granter/shapeshifter

/datum/nifsoft/action_granter/shapeshifter
	name = "Polymorph"
	program_desc = "Эта программа — масштабная перестройка каналов наномашин, проходящих по коже пользователя NIF. Наниты проникают под кожу и даже в саму костную структуру носителя, включая встраивание миметических материалов и устройств фемто-манипуляции — всё ради того, чтобы позволить пользователю, по сути, менять облик на низком уровне. Однако, несмотря на невероятную сложность этих процессов, есть пределы диапазону «форм», которые может принять пользователь. Массу нельзя ни создать, ни уничтожить, и распределить её по функциональному гуманоидному телу можно лишь ограниченным числом способов; значит, пользователь не может принять форму, слишком далёкую от своей «истинной»."
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

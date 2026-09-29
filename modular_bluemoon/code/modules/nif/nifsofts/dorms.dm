/obj/item/disk/nifsoft_uploader/dorms
	name = "Grimoire Libidine"
	loaded_nifsoft = /datum/nifsoft/summoner/dorms

/datum/nifsoft/summoner/dorms
	name = "Grimoire Libidine"
	program_desc = "Grimoire Libidine, ответвление кода Grimoire Caeruleam, предоставляет пользователям удобный доступ к обширной базе различных взрослых игрушек. Из-за особенностей кодовой базы, размещающей большинство этих конструктов, доступный ассортимент несколько ограничен тем, что допускает локальный каталог прошивок."
	holographic_filter = FALSE //No RGB toys
	name_tag = "libidine "
	lewd_nifsoft = TRUE
	ui_icon = "heart"

	//This uses a stripped down selection from the local lewd vendor stock.
	summonable_items  = list(
					/obj/item/dildo,
					/obj/item/dildo/custom,
					/obj/item/dildo/flared/huge,
					/obj/item/dildo/knotted,
					/obj/item/restraints/handcuffs/kinky,
					/obj/item/clothing/glasses/hypno,
					/obj/item/clothing/under/misc/latex_catsuit,
					/obj/item/clothing/shoes/latex_socks,
					/obj/item/clothing/gloves/latex_gloves,
					/obj/item/clothing/head/helmet/space/deprivation_helmet,
					/obj/item/clothing/neck/mind_collar,
					/obj/item/clothing/underwear/briefs/strapon,
					/obj/item/clothing/mask/muzzle/ballgag,
	)
	purchase_price = 150

/obj/item/disk/nifsoft_uploader/dorms/contract
	name = "\improper Libidine Contract"
	loaded_nifsoft = /datum/nifsoft/hypno
	reusable = TRUE //This is set to true because of how this handles updating laws
	///What laws will be assigned when using the NIFSoft on someone?
	var/laws_to_assign = "Law 1: Be nice to others."

/obj/item/disk/nifsoft_uploader/dorms/contract/attempt_software_install(mob/living/carbon/human/target)
	var/datum/nifsoft/hypno/target_nifsoft = target.find_nifsoft(/datum/nifsoft/hypno)
	if(target_nifsoft)
		target_nifsoft.fake_laws = laws_to_assign
		return TRUE

	. = ..()
	if(. == FALSE)
		return FALSE

	target_nifsoft = target.find_nifsoft(/datum/nifsoft/hypno)
	if(!target_nifsoft)
		return FALSE

	target_nifsoft.fake_laws = laws_to_assign

/obj/item/disk/nifsoft_uploader/dorms/contract/attack_self(mob/user, list/modifiers)
	var/new_law = tgui_input_text(user, "Input a new law to add", src, laws_to_assign)
	if(!new_law)
		return FALSE

	laws_to_assign = new_law
	return TRUE

/datum/nifsoft/hypno
	name = "Libidine Contract"
	program_desc = "После установки Libidine Contract принуждает пользователя следовать правилам, хранящимся в данных NIFSoft. \n OOC-примечание: это строго для взрослых ролевых игр. Никакие из этих «законов» соблюдать не обязательно, и вы можете в любой момент удалить этот NIFSoft."
	purchase_price = 0
	lewd_nifsoft = TRUE
	ui_icon = "file-contract"

	/// What "laws" does the person with this NIFSoft installed have?
	var/fake_laws = ""

/datum/nifsoft/hypno/activate()
	. = ..()
	if(!.)
		return FALSE

	to_chat(linked_mob, span_abductor(fake_laws))

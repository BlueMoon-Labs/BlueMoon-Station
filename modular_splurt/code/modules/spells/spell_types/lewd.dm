#define LEWD_BOOK_ALL_REAG_ADD "All of the above"
#define LEWD_BOOK_REAG_VOLUME 30
#define LEWD_BOOK_ALL_REAG_VOLUME 10

/obj/effect/proc_holder/spell/targeted/lewd_chems
	name = "Cast Lewd Chems"
	desc = "Cast spells that will cause the target to feel the power of lewd chemistry."
	include_user = TRUE
	clothes_req = NONE
	invocation_type = "whisper"
	invocation = "Et invoco..."
	charge_max = 10 SECONDS
	cooldown_min = 5 SECONDS
	icon = 'modular_splurt/icons/obj/syringe.dmi'
	base_icon_state = "bombpen"
	sparks_amt = 10
	do_log = FALSE

/obj/effect/proc_holder/spell/targeted/lewd_chems/cast(list/targets, mob/user = usr)
	. = ..()

	var/static/list/datum/reagent/choices = list(
		"Crocin" = /datum/reagent/drug/aphrodisiac,
		"Hexacrocin" = /datum/reagent/drug/aphrodisiacplus,
		"Succubus milk" = /datum/reagent/fermi/breast_enlarger,
		"Incubus draft" = /datum/reagent/fermi/penis_enlarger,
		"Denbu Tincture" = /datum/reagent/fermi/butt_enlarger,
		"Belladine nectar" = /datum/reagent/fermi/belly_inflator,
		"Prospacillin" = /datum/reagent/growthchem
	)
	var/datum/reagent/chem = input(user, "What chemical do you want to use?", "Lewd Chems") as null|anything in choices + LEWD_BOOK_ALL_REAG_ADD
	if(!chem)
		return

	var/datum/reagent/used_reagent //istype
	var/add_volume = 0
	for(var/mob/living/carbon/C in targets)
		if(choices.Find(chem))
			C.reagents.add_reagent(choices[chem], LEWD_BOOK_REAG_VOLUME)
			used_reagent = choices[chem]
			add_volume = LEWD_BOOK_REAG_VOLUME
		else
			for(var/reagent in choices - "Hexacrocin")
				C.reagents.add_reagent(choices[reagent], LEWD_BOOK_ALL_REAG_VOLUME)
				add_volume = LEWD_BOOK_ALL_REAG_VOLUME

	var/msg = "cast the spell «[name]»"
	if(LAZYLEN(targets))
		var/list/to_log = list()
		for(var/t in targets)
			to_log += key_name(t)
		msg += " on targets: [english_list(to_log, and_text = ", ")]"
	msg += " and add [chem == LEWD_BOOK_ALL_REAG_ADD ? "all lewd reagents" : "[initial(used_reagent.name)]"], volume: [add_volume]"
	user.log_message("[msg].", LOG_ATTACK)

#undef LEWD_BOOK_ALL_REAG_ADD
#undef LEWD_BOOK_REAG_VOLUME
#undef LEWD_BOOK_ALL_REAG_VOLUME

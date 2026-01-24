/datum/reagent/consumable/semen/reaction_mob(mob/living/M, method, reac_volume, affected_bodypart) //splashing or ingesting
	. = ..()
	if(!.)
		return
	if(!istype(src, /datum/reagent/consumable/semen/femcum))
		if(HAS_TRAIT(M, TRAIT_GFLUID_DETECT))
			to_chat(M, span_love("Вы узнаете хорошо знакомый вам вкус свежей спермы~"))
		if(HAS_TRAIT(M, TRAIT_DUMB_CUM))
			//var/datum/quirk/dumb4cum/quirk_target = locate() in M.roundstart_quirks
			//quirk_target.uncrave()
			//M.set_drugginess(1)
			if(prob(15))
				to_chat(M, span_love(pick("Как же вкусно!~", "Восхитительно!~", "Невозможно удержаться!~")))
				M.emote("moan")

/datum/reagent/consumable/semen/on_merge(data, amount, mob/living/carbon/M, purity) //when we add more through ERP panel
	. = ..()
	if(!iscarbon(M))
		return
	if(HAS_TRAIT(M,TRAIT_DUMB_CUM) && !istype(src, /datum/reagent/consumable/semen/femcum))
		var/datum/quirk/dumb4cum/quirk_target = locate() in M.roundstart_quirks
		quirk_target.uncrave()

/datum/reagent/consumable/semen/on_mob_life(mob/living/carbon/M)
	. = ..()
	if(iscatperson(M) && HAS_TRAIT(M,TRAIT_DUMB_CUM)  && !istype(src, /datum/reagent/consumable/semen/femcum)) //special "milk" tastes nice for special felinids
		if(prob(3))
			to_chat(M, span_notice(pick("Mmmm~ boy's milk feels so good inside me~", "Ahh~ boy's milk~")))
			M.emote("purr")

/datum/reagent/consumable/ethanol/cum_in_a_hot_tub/semen/reaction_mob(mob/living/carbon/M, affected_bodypart)
	. = ..()
	if(!.)
		return
	if(HAS_TRAIT(M, TRAIT_GFLUID_DETECT) || HAS_TRAIT(M,TRAIT_DUMB_CUM))
		to_chat(M, span_love("Вы чувствуете явную нотку свежей спермы в напитке~"))

/datum/reagent/blood/oil
	data = list("donor"=null,"viruses"=null,"blood_DNA"="REPLICATED", "bloodcolor" = BLOOD_COLOR_OIL, "bloodblend" = BLEND_MULTIPLY, "blood_type"="HF","resistances"=null,"trace_chem"=null,"mind"=null,"ckey"=null,"gender"=null,"real_name"=null,"cloneable"=null,"factions"=null)
	name = "Synthesized Hydraulic Liquid"
	description = "Hydraulic liquid for synthetic crewmembers."
	taste_description = "oil"
	color = BLOOD_COLOR_OIL
	value = REAGENT_VALUE_NONE

/datum/reagent/blood/fancy
	name = "High Quality Blood"
	description = "A noble virgin donor's blood."
	taste_description = "sweet innocence"
	glass_name = "glass of Vampire Delight"
	glass_desc = "To sate the fanged gentlemen and gentlewomen."

/datum/reagent/pax/catnip
	color = "#009900"

/datum/reagent/consumable/organicprecursor
	name = "Organic Precursor"
	description = "A very simple precursor-alike chemical that can be used in the creation of any specific liquids."
	color = "#FFFFFF" // rgb: 255, 255, 255
	taste_mult = 0 // oderless and tasteless

/datum/reagent/consumable/organicprecursor/xenochimeric
	name = "Xenochimeric Sub-Precursor"
	description = "This precursor can be used in creation of different xenochimeric 'organical' designs. You can use it almost as a sci-fi clay for organic life!"
	color = "#11002e" // rgb: 17, 0, 46
	taste_mult = 0 // oderless and tasteless.

/datum/reagent/consumable/organicprecursor/bionanites
	name = "Deactivated Printing Nanites"
	description = "A special batch for nanites that can be used in printing of several organic designs. Somewhat inactive."
	color = "#1c1a15" // rgb: 28, 26, 21
	taste_mult = 0 // oderless and tasteless. Why would you?

/datum/reagent/consumable/organicprecursor/advbionanites
	name = "Volatile Printing Nanites"
	description = "A special batch for nanites that can be used in printing of several organic designs. These ones are hyper-active and can detonate if provoked with a wrong command."
	color = "#332f22" // rgb: 51, 47, 34
	taste_mult = 0 // oderless and tasteless. Why would you?

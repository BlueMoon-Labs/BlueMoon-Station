/datum/reagent/drug/mdp2p
	name = "MDP2P"
	description = "Химическое соединение, прекурсор метилендиоксифенилэтиламинов."
	color = "#f6fdb4"
	reagent_state = LIQUID
	taste_description = "WHAT THE FUCK?"
	metabolization_rate = 0.40
	metabolizing = FALSE

/datum/chemical_reaction/fermi/mdp2p
	name = "MDP2P precursor"
	id = /datum/reagent/drug/mdp2p
	results = list(/datum/reagent/drug/mdp2p = 3)
	required_reagents = list(/datum/reagent/diethylamine = 2, /datum/reagent/nitrous_oxide = 1, /datum/reagent/consumable/ethanol = 2, /datum/reagent/phenol = 1)
	mix_message = "Смесь бурно реагирует, оставляя после себя желтую маслянистую жидкость с резким запахом мочи."
	//FermiChem vars:
	OptimalTempMin 	= 450
	OptimalTempMax 	= 550
	ExplodeTemp 	= 800
	OptimalpHMin 	= 5
	OptimalpHMax 	= 8
	ReactpHLim 		= 3
	CurveSharpT 	= 1
	CurveSharppH 	= 1
	ThermicConstant = 10
	HIonRelease 	= 0.02
	RateUpLim 		= 1
	FermiChem		= TRUE
	PurityMin 		= 0.25

/datum/reagent/drug/mdp2p/on_mob_metabolize(mob/living/M)
	M.adjustToxLoss(rand(5,10), 0)

/datum/reagent/drug/mdp2p/on_mob_life(mob/living/M)
	..()

/obj/item/reagent_containers/glass/bottle/mdp2p
	name = "MDP2P bottle"
	desc = "A small bottle of MDP2P."
	icon = 'icons/obj/chemical.dmi'
	list_reagents = list(/datum/reagent/drug/mdp2p = 30)



/datum/reagent/drug/mdma
	name = "МДМА"
	description = "Синтетический психоактивный препарат."
	color = "#f7cbc0"
	reagent_state = LIQUID
	taste_description = "plastic"
	overdose_threshold = 30
	metabolization_rate = 0.10
	metabolizing = FALSE

/datum/chemical_reaction/mdma
	name = "MDMA"
	id = /datum/reagent/drug/mdma
	results = list(/datum/reagent/drug/mdma = 0.5, /datum/reagent/consumable/ethanol = 1, /datum/reagent/space_cleaner = 1)
	required_reagents = list(/datum/reagent/drug/mdp2p = 1, /datum/reagent/drug/aphrodisiac = 0.5, /datum/reagent/consumable/ethanol = 2, /datum/reagent/space_cleaner = 2)
	mix_message = "Смесь бурно реагирует и оставляет после себя мутный раствор нежно-розового цвета."
	required_temp = 300



/datum/reagent/drug/mdma/on_mob_metabolize(mob/living/M)
	. = ..()

	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "mdma", /datum/mood_event/mdma, name)
	var/datum/component/mood/mood = M.GetComponent(/datum/component/mood)
	mood?.setSanity(SANITY_NEUTRAL)
	var/sound/sound = sound(pick('modular_bluemoon/sound/hallucinations/mdma/slowslippy.ogg'), TRUE)
	sound.environment = 35
	sound.volume = 75
	SEND_SOUND(M.client, sound)
	M.sound_environment_override = SOUND_ENVIRONMENT_DRUGGED

	to_chat(M, "<span class='horriblestate' style='font-size: 135%;'><b><i><span style='color:red'>G</span><span style='color:orange'>o</span><span style='color:yellow'>t</span><span style='color:green'>t</span>\
	<span style='color:blue'>a</span> <span style='color:purple'>g</span><span style='color:red'>e</span><span style='color:orange'>t</span> <span style='color:purple'>a</span> <span style='color:green'>g</span>\
	<span style='color:blue'>r</span><span style='color:purple'>i</span><span style='color:red'>p</span><span style='color:orange'>!</span></i></b></span>")

	if(!M.hud_used)
		return

	var/atom/movable/plane_master_controller/game_plane_master_controller = M.hud_used.plane_master_controllers[PLANE_MASTERS_GAME]
	var/list/col_filter_identity = list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1, 0.000,0,0,0)
	var/list/col_filter_shift_once = list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1, 0.333,0.2,0,0)
	var/list/col_filter_shift_twice = list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1, 0.666,0.2,0,0)
	var/list/col_filter_reset = list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1, 1.000,0,0,0)

	game_plane_master_controller.add_filter("rainbow", 10, color_matrix_filter(col_filter_reset, FILTER_COLOR_HSL))

	for(var/filter in game_plane_master_controller.get_filters("rainbow"))
		animate(filter, color = col_filter_identity, time = 0 SECONDS, loop = -1, flags = ANIMATION_PARALLEL)
		animate(color = col_filter_shift_once, time = 4 SECONDS)
		animate(color = col_filter_shift_twice, time = 4 SECONDS)
		animate(color = col_filter_reset, time = 4 SECONDS)

	game_plane_master_controller.add_filter("psihota", 1, list("type" = "wave", "size" = 2, "x" = 32, "y" = 32))

	for(var/filter in game_plane_master_controller.get_filters("psihota"))
		animate(filter, time = 128 SECONDS, loop = -1, easing = LINEAR_EASING, offset = 32, flags = ANIMATION_PARALLEL)


/datum/reagent/drug/mdma/on_mob_life(mob/living/M)
	if(prob(20))
		M.emote(pick("drool","moan","stare","spin","flip"))
	..()

/datum/reagent/drug/mdma/on_mob_end_metabolize(mob/living/M)
	if(!M.hud_used)
		return
	var/atom/movable/plane_master_controller/game_plane_master_controller = M.hud_used.plane_master_controllers[PLANE_MASTERS_GAME]
	game_plane_master_controller.remove_filter("rainbow")
	game_plane_master_controller.remove_filter("psihota")
	DIRECT_OUTPUT(M.client, sound(null))
	..()


/datum/mood_event/mdma
	mood_change = 3
	timeout = 3600

/datum/mood_event/mdma/add_effects(param)
	description = "<span class='nicegreen'>Оооааа)) Аоммао-оо)ъ</span>\n"


/obj/item/reagent_containers/pill/mdma
	name = "MDMA pill"
	desc = "Маленькое цветное колесико. Выглядит забавно."
	list_reagents = list(/datum/reagent/drug/mdma = 5)

/obj/item/reagent_containers/pill/mdma/Initialize()
	icon_state = pick(list("pill7", "pill8", "pill10","pill11","pill12"))
	. =..()


/obj/item/reagent_containers/pill/powder_mdma
	name = "МДМА"
	desc = "Горстка небольших кристаликов нежно-розового цвета."
	icon = 'modular_bluemoon/icons/obj/moredrugs.dmi'
	icon_state = "mdmapowder"
	volume = 5
	list_reagents = list(/datum/reagent/drug/mdma = 5)

/datum/chemical_reaction/powder_mdma
	is_cold_recipe = TRUE
	required_reagents = list(/datum/reagent/drug/mdma = 5)
	results = list()
	required_temp = 250
	mix_message = "Смесь выпадает в осадок, формируя маленькие кристалы нежно-розового цвета."

/datum/chemical_reaction/powder_mdma/on_reaction(datum/reagents/holder, created_volume)
	var/location = get_turf(holder.my_atom)
	for(var/i in 1 to created_volume)
		new /obj/item/reagent_containers/pill/powder_mdma(location)


/obj/item/reagent_containers/pill/powder_mdma/proc/snort(mob/living/user)
	if(!iscarbon(user))
		return
	var/covered = ""
	if(user.is_mouth_covered(ITEM_SLOT_HEAD))
		covered = "headgear"
	else if(user.is_mouth_covered(ITEM_SLOT_MASK))
		covered = "mask"
	if(covered)
		to_chat(user, span_warning("You have to remove your [covered] first!"))
		return
	var/snort_message = pick("снюхивает","пылесосит носом","долбит по ноздре","вмазывает")
	user.visible_message(span_notice("[user] [snort_message] [src]."))
	if(do_after(user, 30, src))
		to_chat(user, span_notice("You finish snorting the [src]."))
		if(user.gender == FEMALE || (user.gender == PLURAL && isfeminine(user)))
			playsound(user, pick('sound/voice/sniff_f1.ogg'), 50, 1)
		else
			playsound(user, pick('sound/voice/sniff_m1.ogg'), 50, 1)
		if(reagents.total_volume)
			reagents.trans_to(user, reagents.total_volume)
		qdel(src)


/obj/item/reagent_containers/pill/powder_mdma/MouseDrop_T(mob/target, mob/user)
	if(user.stat || !Adjacent(user) || !user.Adjacent(target) || !iscarbon(target))
		return

	snort(target)

	return

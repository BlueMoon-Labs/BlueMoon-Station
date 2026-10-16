/datum/component/latex_mimicry
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/valid_object_type = /obj/item
	var/need_merge_on_pickup = TRUE
	var/mob/living/simple_animal/latexmob/stored_latexmob
	var/datum/antagonist/living_latex/my_LL

/datum/component/latex_mimicry/Initialize(object_type)
	. = ..()
	RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(do_merge_if_possible))

/datum/component/latex_mimicry/proc/setup(mob/living/simple_animal/latexmob/target_mob)
	stored_latexmob = target_mob
	if(!stored_latexmob)
		stack_trace("Mimicry компонент инициализирован без latexmob!")
		return
	my_LL = stored_latexmob.mind ? locate(/datum/antagonist/living_latex) in stored_latexmob.mind.antag_datums : null
	if(!my_LL)
		stack_trace("Mimicry компонент инициализирован без antag датума!")
		return

/datum/component/latex_mimicry/Destroy(force, silent)
	UnregisterSignal(parent, COMSIG_ITEM_PICKUP)
	. = ..()

/datum/component/latex_mimicry/proc/do_merge_if_possible(datum/source, mob/user)
	SIGNAL_HANDLER
	if(!stored_latexmob)
		return
	INVOKE_ASYNC(src, PROC_REF(try_merging), source, user)

/datum/component/latex_mimicry/proc/try_merging(obj/item/I, mob/user)
	if(!istype(I))
		return FALSE

	if(!need_merge_on_pickup || !isloc(user.loc))
		return FALSE

	var/datum/action/cooldown/latexmob/venomAction/merge_action = my_LL.get_ability_by_path(/datum/action/cooldown/latexmob/venomAction)
	if(!merge_action)
		return FALSE

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		merge_action.handle_merging(H)
		merge_action.enter_in_host(my_LL, stored_latexmob, my_LL.mergingDelay, H, merge_action)
		return TRUE

	if(isanimal(user))
		var/mob/living/simple_animal/A = user
		merge_action.do_absorb_simple_mob(A, stored_latexmob, my_LL, merge_action)
		return TRUE

	return FALSE

/datum/component/latex_mimicry/chair
	valid_object_type = /obj/structure/chair

/datum/component/latex_mimicry/book
	valid_object_type = /obj/item/book

/datum/component/latex_mimicry/clothing
	valid_object_type = /obj/item/clothing

/datum/component/latex_mimicry/food_container
	valid_object_type = /obj/item/reagent_containers/food

/datum/component/latex_mimicry/closet
	valid_object_type = /obj/structure/closet

/datum/component/latex_mimicry/sleeper
	valid_object_type = /obj/machinery/sleeper

/datum/component/latex_mimicry/crate
	valid_object_type = /obj/structure/closet/crate

/datum/component/latex_mimicry/vending_machine
	valid_object_type = /obj/machinery/vending

/datum/component/latex_mimicry/computer
	valid_object_type = /obj/machinery/computer

/datum/component/latex_mimicry/washing_machine
	valid_object_type = /obj/machinery/washing_machine

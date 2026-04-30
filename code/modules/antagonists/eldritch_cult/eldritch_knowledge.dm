
/**
  * #Eldritch Knowledge
  *
  * Datum that makes eldritch cultist interesting.
  *
  * Eldritch knowledge aren't instantiated anywhere roundstart, and are initalized and destroyed as the round goes on.
  */
/datum/eldritch_knowledge
	///Name of the knowledge
	var/name = "Basic knowledge"
	///Description of the knowledge
	var/desc = "Basic knowledge of forbidden arts."
	///What shows up
	var/gain_text = ""
	///Cost of knowledge in souls
	var/cost = 0
	///Required sacrifices to unlock
	var/sacs_needed = 0
	///Next knowledge in the research tree
	var/list/next_knowledge = list()
	///What knowledge is incompatible with this. This will simply make it impossible to research knowledges that are in banned_knowledge once this gets researched.
	var/list/banned_knowledge = list()
	///Used with rituals, how many items this needs
	var/list/required_atoms = list()
	///What do we get out of this
	var/list/result_atoms = list()
	///What path is this on defaults to "Side"
	var/route = PATH_SIDE

/datum/eldritch_knowledge/New()
	. = ..()
	var/list/temp_list
	for(var/X in required_atoms)
		var/atom/A = X
		temp_list += list(typesof(A))
	required_atoms = temp_list

/**
  * What happens when this is assigned to an antag datum
  *
  * This proc is called whenever a new eldritch knowledge is added to an antag datum
  */
/datum/eldritch_knowledge/proc/on_gain(mob/user)
	to_chat(user, "<span class='warning'>[gain_text]</span>")
	return
/**
  * What happens when you loose this
  *
  * This proc is called whenever antagonist looses his antag datum, put cleanup code in here
  */
/datum/eldritch_knowledge/proc/on_lose(mob/user)
	return
/**
  * What happens every tick
  *
  * This proc is called on SSprocess in eldritch cultist antag datum. SSprocess happens roughly every second
  */
/datum/eldritch_knowledge/proc/on_life(mob/user)
	return

/**
  * Special check for recipes
  *
  * If you are adding a more complex summoning or something that requires a special check that parses through all the atoms in an area override this.
  */
/datum/eldritch_knowledge/proc/recipe_snowflake_check(list/atoms,loc)
	return TRUE

/**
  * A proc that handles the code when the mob dies
  *
  * This proc is primarily used to end any soundloops when the heretic dies
  */
/datum/eldritch_knowledge/proc/on_death(mob/user)
	return

/**
  * What happens once the recipe is succesfully finished
  *
  * By default this proc creates atoms from result_atoms list. Override this is you want something else to happen.
  */
/datum/eldritch_knowledge/proc/on_finished_recipe(mob/living/user,list/atoms,loc)
	if(result_atoms.len == 0)
		return FALSE

	for(var/A in result_atoms)
		new A(loc)

	return TRUE

/**
  * Used atom cleanup
  *
  * Overide this proc if you dont want ALL ATOMS to be destroyed. useful in many situations.
  */
/datum/eldritch_knowledge/proc/cleanup_atoms(list/atoms)
	for(var/X in atoms)
		var/atom/A = X
		if(!isliving(A))
			atoms -= A
			qdel(A)
	return

/**
  * Mansus grasp act
  *
  * Gives addtional effects to mansus grasp spell
  */
/datum/eldritch_knowledge/proc/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	return FALSE

/**
  * Sickly blade act
  *
  * Gives addtional effects to sickly blade weapon
  */
/datum/eldritch_knowledge/proc/on_eldritch_blade(target,user,proximity_flag,click_parameters)
	return

/**
  * Sickly blade distant act
  *
  * Same as [/datum/eldritch_knowledge/proc/on_eldritch_blade] but works on targets that are not in proximity to you.
  */
/datum/eldritch_knowledge/proc/on_ranged_attack_eldritch_blade(atom/target,mob/user,click_parameters)
	return

//////////////
///Subtypes///
//////////////

/datum/eldritch_knowledge/spell
	var/obj/effect/proc_holder/spell/spell_to_add

/datum/eldritch_knowledge/spell/on_gain(mob/user)
	var/obj/effect/proc_holder/S = new spell_to_add
	user.mind.AddSpell(S)
	return ..()

/datum/eldritch_knowledge/spell/on_lose(mob/user)
	user.mind.RemoveSpell(spell_to_add)
	return ..()

/datum/eldritch_knowledge/curse
	var/timer = 5 MINUTES
	var/list/fingerprints = list()

/datum/eldritch_knowledge/curse/recipe_snowflake_check(list/atoms, loc)
	fingerprints = list()
	for(var/X in atoms)
		var/atom/A = X
		fingerprints |= A.fingerprints
	listclearnulls(fingerprints)
	if(fingerprints.len == 0)
		return FALSE
	return TRUE

/datum/eldritch_knowledge/curse/on_finished_recipe(mob/living/user,list/atoms,loc)

	var/list/compiled_list = list()

	for(var/H in GLOB.human_list)
		var/mob/living/carbon/human/human_to_check = H
		if(fingerprints[md5(human_to_check.dna.uni_identity)])
			compiled_list |= human_to_check.real_name
			compiled_list[human_to_check.real_name] = human_to_check

	if(compiled_list.len == 0)
		to_chat(user, "<span class='warning'>На этих предметах нет необходимых отпечатков пальцев или ДНК цели.</span>")
		return FALSE

	var/chosen_mob = input("Выберите цель вашего проклятия","Ваша цель") as null|anything in sort_list(compiled_list, GLOBAL_PROC_REF(cmp_mob_realname_dsc))
	if(!chosen_mob)
		return FALSE
	curse(compiled_list[chosen_mob])
	addtimer(CALLBACK(src, PROC_REF(uncurse), compiled_list[chosen_mob]),timer)
	return TRUE

/datum/eldritch_knowledge/curse/proc/curse(mob/living/chosen_mob)
	return

/datum/eldritch_knowledge/curse/proc/uncurse(mob/living/chosen_mob)
	return

/datum/eldritch_knowledge/summon
	//Mob to summon
	var/mob/living/mob_to_summon


/datum/eldritch_knowledge/summon/on_finished_recipe(mob/living/user,list/atoms,loc)
	//we need to spawn the mob first so that we can use it in pollCandidatesForMob, we will move it from nullspace down the code
	var/mob/living/summoned = new mob_to_summon(loc)
	message_admins("[summoned.name] был призван [user.real_name] в <b>[loc]</b>")
	var/list/mob/dead/observer/candidates = pollCandidatesForMob("Хочешь сыграть за [summoned.name]", ROLE_HERETIC, null, FALSE, 100, summoned)
	if(!LAZYLEN(candidates))
		to_chat(user,"<span class='warning'>Никого из призраков найти не удалось...</span>")
		qdel(summoned)
		return FALSE
	var/mob/dead/observer/C = pick(candidates)
	log_game("[key_name_admin(C)] принимает контроль над ([key_name_admin(summoned)]), его хозяин [user.real_name]")
	summoned.ghostize(FALSE)
	summoned.key = C.key
	summoned.mind.add_antag_datum(/datum/antagonist/heretic_monster)
	var/datum/antagonist/heretic_monster/heretic_monster = summoned.mind.has_antag_datum(/datum/antagonist/heretic_monster)
	var/datum/antagonist/heretic/master = user.mind.has_antag_datum(/datum/antagonist/heretic)
	heretic_monster.set_owner(master)
	return TRUE

//Ascension knowledge
/datum/eldritch_knowledge/final_eldritch
	var/finished = FALSE

/datum/eldritch_knowledge/final_eldritch/recipe_snowflake_check(list/atoms, loc,selected_atoms)
	if(finished)
		return FALSE
	var/counter = 0
	for(var/mob/living/carbon/human/H in atoms)
		selected_atoms |= H
		counter++
		if(counter == 3)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/final_eldritch/on_finished_recipe(	mob/living/user, list/atoms, loc)
	finished = TRUE
	return TRUE

/datum/eldritch_knowledge/final_eldritch/cleanup_atoms(list/atoms)
	. = ..()
	for(var/mob/living/carbon/human/H in atoms)
		atoms -= H
		H.gib()

///////////////
///Base lore///
///////////////

/datum/eldritch_knowledge/spell/basic
	name = "Рассвет"
	desc = "Начните свое путешествие в Мансусе. Позволяет выбрать цель, используя живое сердце на руне трансмутации."
	gain_text = "Еще один день на бессмысленной работе. Я ощущаю мерцание вокруг себя, когда осознаю, что в моем рюкзаке есть что-то странное. Я смотрю на это, неосознанно открывая новую главу в своей жизни."
	next_knowledge = list(/datum/eldritch_knowledge/base_rust,/datum/eldritch_knowledge/base_ash,/datum/eldritch_knowledge/base_flesh,/datum/eldritch_knowledge/base_void)
	cost = 0
	spell_to_add = /obj/effect/proc_holder/spell/targeted/touch/mansus_grasp
	required_atoms = list(/obj/item/living_heart)
	route = "Start"

/datum/eldritch_knowledge/spell/basic/recipe_snowflake_check(list/atoms, loc)
	. = ..()
	for(var/obj/item/living_heart/LH in atoms)
		if(!LH.target)
			return TRUE
		if(LH.target in atoms)
			return TRUE
	return FALSE

/datum/eldritch_knowledge/spell/basic/on_finished_recipe(mob/living/user, list/atoms, loc)
	. = TRUE
	var/mob/living/carbon/carbon_user = user
	for(var/obj/item/living_heart/LH in atoms)

		if(LH.target && LH.target.stat == DEAD)
			to_chat(carbon_user,"<span class='danger'>Мои покровители принимают это предложение...</span>")
			var/mob/living/carbon/human/H = LH.target
			H.become_husk("burn") //Husks the target with removable husking, but causes a bunch of additional burn damage to prevent it from being 'too easy' to do
			H.adjustFireLoss(200)
			LH.target = null
			var/datum/antagonist/heretic/EC = carbon_user.mind.has_antag_datum(/datum/antagonist/heretic)

			EC.actually_sacced.Add(H.real_name)
			if(LH.sac_targetter)
				LH.sac_targetter.sac_targetted.Remove(H.real_name)
			LH.sac_targetter = null
			EC.total_sacrifices++
			for(var/X in carbon_user.get_all_gear())
				if(!istype(X,/obj/item/forbidden_book))
					continue
				var/obj/item/forbidden_book/FB = X
				FB.charge++
				FB.charge++
				break

		if(!LH.target)
			var/datum/objective/A = new
			A.owner = user.mind
			var/list/targets = list()
			var/list/target_blacklist = list()
			for(var/obj/item/living_heart/CLH in GLOB.living_heart_cache)
				if(!CLH || !CLH.target || !CLH.target.mind)
					continue
				target_blacklist.Add(CLH.target.mind)

			for(var/i in 0 to 3)
				var/datum/mind/targeted =  A.find_target(blacklist = target_blacklist)//easy way, i dont feel like copy pasting that entire block of code
				if(!targeted)
					break
				targets["[targeted.current.real_name] the [targeted.assigned_role]"] = targeted.current
			LH.target = targets[input(user,"Выберите следующую цель","Цель") in targets]

			if(!LH.target && targets.len)
				LH.target = pick(targets)	//Tsk tsk, you can and will get another target if you want it or not.

			if(LH.target)
				target_blacklist = list()
				for(var/obj/item/living_heart/CLH in (GLOB.living_heart_cache - LH))	//Recreate blacklist, excluding ourselves.
					if(!CLH || !CLH.target || !CLH.target.mind)
						continue
					target_blacklist.Add(CLH.target.mind)
				if(LH.target.mind in target_blacklist)	//Someone was faster, or you tried to cheese the system.
					to_chat(user, "<span class='warning'>Кажется, я был слишком медлительным, и моя цель уже была выбрана другим живым сердцем!</span>")
					LH.target = null

			qdel(A)
			if(LH.target)
				to_chat(user,"<span class='warning'>Моя цель выбрана, время принести в жертву [LH.target.real_name]!</span>")
				var/datum/antagonist/heretic/EC = carbon_user.mind.has_antag_datum(/datum/antagonist/heretic)
				LH.sac_targetter = EC
				EC.sac_targetted.Add(LH.target.real_name)
			else
				to_chat(user,"<span class='warning'>не удалось найти цель для живого сердца.</span>")

/datum/eldritch_knowledge/spell/basic/cleanup_atoms(list/atoms)
	return

/datum/eldritch_knowledge/spell/summon
	next_knowledge = list()
	cost = 0
	required_atoms = list()
	route = "Start"

/datum/eldritch_knowledge/spell/summon/heart
	name = "Зов к сердцу"
	desc = "Позволяет призывать и прятать живое сердце в пучине безумия. Остальные услышат очень тихий звук призыва, только вплотную к вам."
	gain_text = "Что-то живое и теплое откликается на мой зов."
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_summon/heart

/datum/eldritch_knowledge/spell/summon/book
	name = "Зов к кодексу"
	desc = "Позволяет призывать и прятать кодекс в тайных глубинах. Остальные услышат очень тихий звук призыва, только вплотную к вам."
	gain_text = "Я могу дотянуться до своего кодекса сквозь пространство."
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_summon/book

/datum/eldritch_knowledge/living_heart
	name = "Живое сердце"
	desc = "Позволяет создавать дополнительные живые сердца, используя обычное сердце, лужицу крови и мак. Живые сердца, используемые на руне трансмутации, выбирают вам человека, на которого можно охотиться и приносить в жертву с помощью этой руны. Каждая жертва дает вам дополнительный знания в книге."
	gain_text = "Врата Мансуса открылись твоему разуму."
	cost = 0
	required_atoms = list(/obj/item/organ/heart,/obj/effect/decal/cleanable/blood,/obj/item/reagent_containers/food/snacks/grown/poppy)
	next_knowledge = list(/datum/eldritch_knowledge/spell/silence)
	result_atoms = list(/obj/item/living_heart)
	route = "Start"

/datum/eldritch_knowledge/codex_cicatrix
	name = "Кодекс Резцов"
	desc = "Позволяет вам создать запасной Кодекс Резцов, если вы его потеряли, используя библию, человеческую кожу, ручку и пару глаз."
	gain_text = "Их руки на твоем горле, но ты их не видишь."
	cost = 0
	required_atoms = list(/obj/item/organ/eyes,/obj/item/stack/sheet/animalhide/human,/obj/item/storage/book/bible,/obj/item/pen)
	result_atoms = list(/obj/item/forbidden_book)
	route = "Start"

/datum/eldritch_knowledge/spell/silence
	name = "Молчание"
	desc = "Позволяет вам использовать силу Мансуса, чтобы заставить человека замолчать на срок до двадцати секунд. Однако он быстро заметит это."
	gain_text = "Они должны держать язык за зубами, потому что ничего не понимают."
	cost = 1
	spell_to_add = /obj/effect/proc_holder/spell/pointed/trigger/mute/eldritch
	route = PATH_SIDE

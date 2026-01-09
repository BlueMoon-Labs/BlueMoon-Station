/// Attempts to open the tgui menu
/mob/verb/interact_with()
	set name = "Interact With"
	set desc = "Perform an interaction with someone."
	set category = "IC"
	set src in view(usr.client)

	var/datum/component/interaction_menu_granter/menu = usr.GetComponent(/datum/component/interaction_menu_granter)
	if(!menu)
		to_chat(usr, span_warning("You must have done something really bad to not have an interaction component."))
		return

	if(!src)
		to_chat(usr, span_warning("Your interaction target is gone!"))
		return
	menu.open_menu(usr, src)

#define INTERACTION_UNHOLY 3 //SPLURT Edit

/// The menu itself, only var is target which is the mob you are interacting with
/datum/component/interaction_menu_granter
	var/mob/living/target
	var/mob/living/auto_interaction_target
	var/datum/interaction/currently_active_interaction
	var/next_interaction_time
	var/auto_interaction_pace = 1 SECONDS

/datum/component/interaction_menu_granter/process(delta_time)
	if(!currently_active_interaction)
		auto_interaction_target = null
		currently_active_interaction = null
		return PROCESS_KILL
	if(QDELETED(auto_interaction_target))
		auto_interaction_target = null
		currently_active_interaction = null
		return PROCESS_KILL
	if(world.time <= next_interaction_time)
		return
	next_interaction_time = world.time + auto_interaction_pace
	if(!currently_active_interaction.do_action(parent, auto_interaction_target, apply_cooldown = FALSE))
		auto_interaction_target = null
		currently_active_interaction = null
		return PROCESS_KILL

/datum/component/interaction_menu_granter/Initialize(...)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/parent_mob = parent
	if(!parent_mob.client)
		return COMPONENT_INCOMPATIBLE
	return ..()

/datum/component/interaction_menu_granter/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_CTRLSHIFTCLICKON, PROC_REF(open_menu))

/datum/component/interaction_menu_granter/Destroy(force, ...)
	STOP_PROCESSING(SSinteractions, src)
	if(target)
		UnregisterSignal(target, COMSIG_PARENT_QDELETING)
		target = null
	auto_interaction_target = null
	currently_active_interaction = null
	return ..()

/datum/component/interaction_menu_granter/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_CTRLSHIFTCLICKON)
	return ..()

/// The one interacting is clicker, the interacted is clicked.
/datum/component/interaction_menu_granter/proc/open_menu(mob/living/clicker, mob/living/clicked)
	if(!isliving(clicker))
		return
	// COMSIG_MOB_CTRLSHIFTCLICKON accepts `atom`s, prevent it
	if(!istype(clicked))
		return FALSE
	// Don't cancel admin quick spawn
	if(isobserver(clicked) && check_rights_for(clicker.client, R_SPAWN))
		return FALSE
	// Changing targets!!
	if(target)
		UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	target = clicked
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_target_deleted))
	ui_interact(clicker)
	return COMSIG_MOB_CANCEL_CLICKON

/// Such a shame
/datum/component/interaction_menu_granter/proc/on_target_deleted(datum/source, ...)
	UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	target = null
	SStgui.close_user_uis(parent, src)

/datum/component/interaction_menu_granter/ui_state(mob/living/user)
	// Funny admin, don't you dare be the extra funny now.
	if(user.client.holder && !user.client.holder.deadmined)
		return GLOB.always_state
	if(user == parent)
		return GLOB.conscious_state
	return GLOB.never_state

/datum/component/interaction_menu_granter/ui_interact(mob/living/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MobInteraction", "Interactions")
		ui.open()

/proc/pref_to_num(pref)
	switch(pref)
		if("Yes")
			return 1
		if("Ask")
			return 2
		else
			return 0

/datum/component/interaction_menu_granter/ui_data(mob/living/user)
	. = ..()
	//Getting player
	var/mob/living/self = parent
	//Getting info
	.["isTargetSelf"] = target == self // Why all of these?
	.["user"] = self // Because people may have the same name
	.["target"] = target // target == self can distinguish
	.["selfAttributes"] = self.list_interaction_attributes(self)
	.["lust"] = self.get_lust()
	.["maxLust"] = self.get_climax_threshold() // BLUEMOON EDIT

	.["max_distance"] = 0
	.["user_is_blacklisted"] = SSinteractions.is_blacklisted(self)
	var/required_from_user = NONE
	var/user_has_penis = self.has_penis()
	if(self.has_mouth())
		required_from_user |= INTERACTION_REQUIRE_MOUTH
	if(self.has_hands())
		required_from_user |= INTERACTION_REQUIRE_HANDS
	if(self.is_topless())
		required_from_user |= INTERACTION_REQUIRE_TOPLESS
	if(self.is_bottomless())
		required_from_user |= INTERACTION_REQUIRE_BOTTOMLESS
	// BLUEMOON ADD
	if(self.has_tail())
		required_from_user |= INTERACTION_REQUIRE_TAIL
	if(self.check_mutation(TK) || HAS_TRAIT(self, TRAIT_TK_POTENTIAL))
		required_from_user |= INTERACTION_REQUIRE_TK
	if(user_has_penis)
		var/shape_desc = get_penis_shape_desc(self)
		if(self?.client?.prefs.sexknotting && target?.client?.prefs.sexknotting && findtext(shape_desc, "узл"))
			required_from_user |= INTERACTION_REQUIRE_KNOT
		if(findtext(shape_desc, "двойн"))
			required_from_user |= INTERACTION_REQUIRE_DOUBLE_PENIS
	// BLUEMOON ADD
	.["required_from_user"] = required_from_user

	var/required_from_user_exposed = NONE
	var/required_from_user_unexposed = NONE

	user_has_penis = user_has_penis || self.has_strapon()
	switch(user_has_penis)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_PENIS
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_PENIS
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_PENIS
			required_from_user_unexposed |= INTERACTION_REQUIRE_PENIS

	var/user_has_anus = self.has_anus()
	switch(user_has_anus)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_ANUS
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_ANUS
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_ANUS
			required_from_user_unexposed |= INTERACTION_REQUIRE_ANUS

	var/user_has_vagina = self.has_vagina()
	switch(user_has_vagina)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_VAGINA
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_VAGINA
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_VAGINA
			required_from_user_unexposed |= INTERACTION_REQUIRE_VAGINA

	var/user_has_breasts = self.has_breasts()
	switch(user_has_breasts)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_BREASTS
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_BREASTS
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_BREASTS
			required_from_user_unexposed |= INTERACTION_REQUIRE_BREASTS

	var/user_has_feet = self.has_feet()
	switch(user_has_feet)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_FEET
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_FEET
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_FEET
			required_from_user_unexposed |= INTERACTION_REQUIRE_FEET

	var/user_has_balls = self.has_balls()
	switch(user_has_balls)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_BALLS
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_BALLS
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_BALLS
			required_from_user_unexposed |= INTERACTION_REQUIRE_BALLS

	var/user_has_ears = self.has_ears()
	if(self.getorganslot(ORGAN_SLOT_EARS))
		switch(user_has_ears)
			if(HAS_EXPOSED_GENITAL)
				required_from_user_exposed |= INTERACTION_REQUIRE_EARS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_user_unexposed |= INTERACTION_REQUIRE_EARS
	else
		switch(user_has_ears)
			if(HAS_EXPOSED_GENITAL)
				required_from_user_exposed |= INTERACTION_REQUIRE_EARSOCKETS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_user_unexposed |= INTERACTION_REQUIRE_EARSOCKETS

	var/user_has_eyes = self.has_eyes()
	if(self.getorganslot(ORGAN_SLOT_EYES))
		switch(user_has_eyes)
			if(HAS_EXPOSED_GENITAL)
				required_from_user_exposed |= INTERACTION_REQUIRE_EYES
			if(HAS_UNEXPOSED_GENITAL)
				required_from_user_unexposed |= INTERACTION_REQUIRE_EYES
	else
		switch(user_has_eyes)
			if(HAS_EXPOSED_GENITAL)
				required_from_user_exposed |= INTERACTION_REQUIRE_EYESOCKETS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_user_unexposed |= INTERACTION_REQUIRE_EYESOCKETS

	//SPLURT EDIT
	var/user_has_belly = self.has_belly()
	switch(user_has_belly)
		if(HAS_EXPOSED_GENITAL)
			required_from_user_exposed |= INTERACTION_REQUIRE_BELLY
		if(HAS_UNEXPOSED_GENITAL)
			required_from_user_unexposed |= INTERACTION_REQUIRE_BELLY
		if(TRUE)
			required_from_user_exposed |= INTERACTION_REQUIRE_BELLY
			required_from_user_unexposed |= INTERACTION_REQUIRE_BELLY
	//SPLURT EDIT END

	.["required_from_user_exposed"] = required_from_user_exposed
	.["required_from_user_unexposed"] = required_from_user_unexposed
	.["user_num_feet"] = self.get_num_feet()

	// Let's clear it in case the user goes directly from interacting with someone to themself
	.["theirAttributes"] = null
	.["target_has_active_player"] = null
	.["max_distance"] = null
	.["target_is_blacklisted"] = null
	.["required_from_target"] = null
	.["required_from_target_exposed"] = null
	.["required_from_target_unexposed"] = null
	.["target_num_feet"] = null
	.["theirPrefs"] = null
	.["theirLust"] = null
	.["theyAllowLewd"] = null
	.["theyAllowRanged"] = null
	.["theyAllowExtreme"] = null
	//SPLURT EDIT
	.["theyAllowUnholy"] = null
	.["theyHaveBondage"] = null
	//SPLURT EDIT END
	if(target != self)
		.["theirAttributes"] = target.list_interaction_attributes(self)

		// Always TRUE if has key, 2 if cliented, FALSE if nobody owns it
		.["target_has_active_player"] = target.ckey ? (target.client ? 2 : TRUE) : FALSE
		.["max_distance"] = get_dist(self, target)
		.["target_is_blacklisted"] = SSinteractions.is_blacklisted(target)
		var/required_from_target = NONE
		var/target_has_penis = target.has_penis()
		if(target.has_mouth())
			required_from_target |= INTERACTION_REQUIRE_MOUTH
		if(target.has_hands())
			required_from_target |= INTERACTION_REQUIRE_HANDS
		if(target.is_topless())
			required_from_target |= INTERACTION_REQUIRE_TOPLESS
		if(target.is_bottomless())
			required_from_target |= INTERACTION_REQUIRE_BOTTOMLESS
		// BLUEMOON ADD
		if(target.has_tail())
			required_from_target |= INTERACTION_REQUIRE_TAIL
		if(target_has_penis)
			var/shape_desc = get_penis_shape_desc(target)
			if(self?.client?.prefs.sexknotting && target?.client?.prefs.sexknotting && findtext(shape_desc, "узл"))
				required_from_target |= INTERACTION_REQUIRE_KNOT
			if(findtext(shape_desc, "двойн"))
				required_from_target |= INTERACTION_REQUIRE_DOUBLE_PENIS
		// BLUEMOON ADD
		.["required_from_target"] = required_from_target

		var/required_from_target_exposed = NONE
		var/required_from_target_unexposed = NONE

		target_has_penis = target_has_penis || target.has_strapon()
		switch(target_has_penis)
			if(HAS_EXPOSED_GENITAL)
				required_from_target_exposed |= INTERACTION_REQUIRE_PENIS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_target_unexposed |= INTERACTION_REQUIRE_PENIS
			if(TRUE)
				required_from_target_exposed |= INTERACTION_REQUIRE_PENIS
				required_from_target_unexposed |= INTERACTION_REQUIRE_PENIS

		var/target_has_anus = target.has_anus()
		switch(target_has_anus)
			if(HAS_EXPOSED_GENITAL)
				required_from_target_exposed |= INTERACTION_REQUIRE_ANUS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_target_unexposed |= INTERACTION_REQUIRE_ANUS
			if(TRUE)
				required_from_target_exposed |= INTERACTION_REQUIRE_ANUS
				required_from_target_unexposed |= INTERACTION_REQUIRE_ANUS

		var/target_has_vagina = target.has_vagina()
		switch(target_has_vagina)
			if(HAS_EXPOSED_GENITAL)
				required_from_target_exposed |= INTERACTION_REQUIRE_VAGINA
			if(HAS_UNEXPOSED_GENITAL)
				required_from_target_unexposed |= INTERACTION_REQUIRE_VAGINA
			if(TRUE)
				required_from_target_exposed |= INTERACTION_REQUIRE_VAGINA
				required_from_target_unexposed |= INTERACTION_REQUIRE_VAGINA

		var/target_has_breasts = target.has_breasts()
		switch(target_has_breasts)
			if(HAS_EXPOSED_GENITAL)
				required_from_target_exposed |= INTERACTION_REQUIRE_BREASTS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_target_unexposed |= INTERACTION_REQUIRE_BREASTS
			if(TRUE)
				required_from_target_exposed |= INTERACTION_REQUIRE_BREASTS
				required_from_target_unexposed |= INTERACTION_REQUIRE_BREASTS

		var/target_has_feet = target.has_feet()
		switch(target_has_feet)
			if(HAS_EXPOSED_GENITAL)
				required_from_target_exposed |= INTERACTION_REQUIRE_FEET
			if(HAS_UNEXPOSED_GENITAL)
				required_from_target_unexposed |= INTERACTION_REQUIRE_FEET
			if(TRUE)
				required_from_target_exposed |= INTERACTION_REQUIRE_FEET
				required_from_target_unexposed |= INTERACTION_REQUIRE_FEET

		var/target_has_balls = target.has_balls()
		switch(target_has_balls)
			if(HAS_EXPOSED_GENITAL)
				required_from_target_exposed |= INTERACTION_REQUIRE_BALLS
			if(HAS_UNEXPOSED_GENITAL)
				required_from_target_unexposed |= INTERACTION_REQUIRE_BALLS
			if(TRUE)
				required_from_target_exposed |= INTERACTION_REQUIRE_BALLS
				required_from_target_unexposed |= INTERACTION_REQUIRE_BALLS

		var/target_has_ears = target.has_ears()
		if(target.getorganslot(ORGAN_SLOT_EARS))
			switch(target_has_ears)
				if(HAS_EXPOSED_GENITAL)
					required_from_target_exposed |= INTERACTION_REQUIRE_EARS
				if(HAS_UNEXPOSED_GENITAL)
					required_from_target_unexposed |= INTERACTION_REQUIRE_EARS
		else
			switch(target_has_ears)
				if(HAS_EXPOSED_GENITAL)
					required_from_target_exposed |= INTERACTION_REQUIRE_EARSOCKETS
				if(HAS_UNEXPOSED_GENITAL)
					required_from_target_unexposed |= INTERACTION_REQUIRE_EARSOCKETS

		var/target_has_eyes = target.has_eyes()
		if(target.getorganslot(ORGAN_SLOT_EYES))
			switch(target_has_eyes)
				if(HAS_EXPOSED_GENITAL)
					required_from_target_exposed |= INTERACTION_REQUIRE_EYES
				if(HAS_UNEXPOSED_GENITAL)
					required_from_target_unexposed |= INTERACTION_REQUIRE_EYES
		else
			switch(target_has_eyes)
				if(HAS_EXPOSED_GENITAL)
					required_from_target_exposed |= INTERACTION_REQUIRE_EYESOCKETS
				if(HAS_UNEXPOSED_GENITAL)
					required_from_target_unexposed |= INTERACTION_REQUIRE_EYESOCKETS

		.["required_from_target_exposed"] = required_from_target_exposed
		.["required_from_target_unexposed"] = required_from_target_unexposed
		.["target_num_feet"] = target.get_num_feet()
		if(target?.client?.prefs)
			.["theyAllowLewd"] = !!(target.client.prefs.toggles & VERB_CONSENT)
			.["theyAllowExtreme"] = !!pref_to_num(target.client.prefs.extremepref)
			.["theyAllowUnholy"] = !!pref_to_num(target.client.prefs.unholypref) //SPLURT EDIT
			.["theyAllowRanged"] = !!(target.client.prefs.toggles & RANGED_VERBS_CONSENT)
		if(HAS_TRAIT(user, TRAIT_ESTROUS_DETECT))
			.["theirLust"] = target.get_lust()
			.["theirMaxLust"] = target.get_climax_threshold() // BLUEMOON EDIT
		//SPLURT EDIT
		.["theyHaveBondage"] = FALSE
		if(iscarbon(target))
			var/mob/living/carbon/C = target
			if(istype(C.handcuffed, /obj/item/restraints/bondage_rope) || istype(C.legcuffed, /obj/item/restraints/bondage_rope))
				.["theyHaveBondage"] = TRUE
		//SPLURT EDIT END
	.["auto_interaction_pace"] = auto_interaction_pace
	.["is_auto_target_self"] = auto_interaction_target == self
	.["auto_interaction_target"] = auto_interaction_target
	.["currently_active_interaction"] = currently_active_interaction?.type

	//Get their genitals
	var/list/genitals = list()
	var/mob/living/carbon/get_genitals = self
	if(istype(get_genitals))
		for(var/obj/item/organ/genital/genital in get_genitals.internal_organs)	//Only get the genitals
			if(CHECK_BITFIELD(genital.genital_flags, GENITAL_INTERNAL))			//Not those though
				continue
			var/list/genital_entry = list()
			genital_entry["name"] = "[capitalize(genital.name)]" //Prevents code from adding a prefix
			genital_entry["key"] = REF(genital) //The key is the reference to the object
			var/visibility = "Invalid"
			if(CHECK_BITFIELD(genital.genital_flags, GENITAL_THROUGH_CLOTHES))
				visibility = "Always visible"
			else if(CHECK_BITFIELD(genital.genital_flags, GENITAL_UNDIES_HIDDEN))
				visibility = "Hidden by underwear"
			else if(CHECK_BITFIELD(genital.genital_flags, GENITAL_HIDDEN))
				visibility = "Always hidden"
			else
				visibility = "Hidden by clothes"

			genital_entry["visibility"] = visibility
			genital_entry["possible_choices"] = GLOB.genitals_visibility_toggles
			genital_entry["can_arouse"] = (
				!!CHECK_BITFIELD(genital.genital_flags, GENITAL_CAN_AROUSE) \
				&& !(HAS_TRAIT(get_genitals, TRAIT_PERMABONER) \
				|| HAS_TRAIT(get_genitals, TRAIT_NEVERBONER)))
			genital_entry["arousal_state"] = genital.aroused_state
			genital_entry["always_accessible"] = genital.always_accessible
			genitals += list(genital_entry)
		if(!get_genitals.getorganslot(ORGAN_SLOT_ANUS)) //SPLURT Edit
			var/simulated_ass = list()
			simulated_ass["name"] = "Анус"
			simulated_ass["key"] = "anus"
			var/visibility = "Invalid"
			switch(get_genitals.anus_exposed)
				if(1)
					visibility = "Always visible"
				if(0)
					visibility = "Hidden by underwear"
				else
					visibility = "Always hidden"
			simulated_ass["visibility"] = visibility
			simulated_ass["possible_choices"] = GLOB.genitals_visibility_toggles - GEN_VISIBLE_NO_CLOTHES
			simulated_ass["always_accessible"] = get_genitals.anus_always_accessible
			genitals += list(simulated_ass)
	.["genitals"] = genitals

	var/datum/preferences/prefs = self?.client.prefs
	if(prefs)
	//Lust stuff, appears at the very top
		.["use_arousal_multiplier"] = 	prefs.use_arousal_multiplier
		.["arousal_multiplier"] =		prefs.arousal_multiplier
		.["use_moaning_multiplier"] = 	prefs.use_moaning_multiplier
		.["moaning_multiplier"] = 		prefs.moaning_multiplier

	//Let's get their favorites!
		.["favorite_interactions"] = 	SANITIZE_LIST(prefs.favorite_interactions)

	//Getting char prefs
		.["erp_pref"] = 				pref_to_num(prefs.erppref)
		.["noncon_pref"] = 				pref_to_num(prefs.nonconpref)
		.["vore_pref"] = 				pref_to_num(prefs.vorepref)
		.["mobsex_pref"] = 				pref_to_num(prefs.mobsexpref)	//Hentai
		.["hornyantags_pref"] = 		pref_to_num(prefs.hornyantagspref)	//Hentai
		.["extreme_pref"] = 			pref_to_num(prefs.extremepref)
		.["extreme_harm"] = 			pref_to_num(prefs.extremeharm)
		.["unholy_pref"] =				pref_to_num(prefs.unholypref)

	//Getting preferences
		.["verb_consent"] = 			!!CHECK_BITFIELD(prefs.toggles, VERB_CONSENT)
		.["ranged_verb_pref"] = 		!!CHECK_BITFIELD(prefs.toggles, RANGED_VERBS_CONSENT)
		.["lewd_verb_sounds"] = 		!!CHECK_BITFIELD(prefs.toggles, LEWD_VERB_SOUNDS)
		.["arousable"] = 				prefs.arousable
		.["sexknotting"] = 				prefs.sexknotting // BLUEMONN ADD
		.["genital_examine"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, GENITAL_EXAMINE)
		.["vore_examine"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, VORE_EXAMINE)
		.["medihound_sleeper"] =		!!CHECK_BITFIELD(prefs.cit_toggles, MEDIHOUND_SLEEPER)
		.["eating_noises"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, EATING_NOISES)
		.["digestion_noises"] =			!!CHECK_BITFIELD(prefs.cit_toggles, DIGESTION_NOISES)
		.["trash_forcefeed"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, TRASH_FORCEFEED)
		.["forced_fem"] = 				!!CHECK_BITFIELD(prefs.cit_toggles, FORCED_FEM)
		.["forced_masc"] = 				!!CHECK_BITFIELD(prefs.cit_toggles, FORCED_MASC)
		.["hypno"] = 					!!CHECK_BITFIELD(prefs.cit_toggles, HYPNO)
		.["bimbofication"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, BIMBOFICATION)
		.["breast_enlargement"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, BREAST_ENLARGEMENT)
		.["penis_enlargement"] =		!!CHECK_BITFIELD(prefs.cit_toggles, PENIS_ENLARGEMENT)
		.["butt_enlargement"] =			!!CHECK_BITFIELD(prefs.cit_toggles, BUTT_ENLARGEMENT)
		.["belly_inflation"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, BELLY_INFLATION)
		.["never_hypno"] = 				!CHECK_BITFIELD(prefs.cit_toggles, NEVER_HYPNO)
		.["no_aphro"] = 				!CHECK_BITFIELD(prefs.cit_toggles, NO_APHRO)
		.["no_ass_slap"] = 				!CHECK_BITFIELD(prefs.cit_toggles, NO_ASS_SLAP)
		.["no_auto_wag"] = 				!CHECK_BITFIELD(prefs.cit_toggles, NO_AUTO_WAG)
		.["chastity_pref"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, CHASTITY)
		.["stimulation_pref"] = 		!!CHECK_BITFIELD(prefs.cit_toggles, STIMULATION)
		.["edging_pref"] =				!!CHECK_BITFIELD(prefs.cit_toggles, EDGING)
		.["cum_onto_pref"] = 			!!CHECK_BITFIELD(prefs.cit_toggles, CUM_ONTO)
		.["sex_jitter"] = 				!!CHECK_BITFIELD(prefs.cit_toggles, SEX_JITTER)	//By Gardelin0
		.["no_disco_dance"] = 			!CHECK_BITFIELD(prefs.cit_toggles, NO_DISCO_DANCE) //By SmiLeY

/datum/component/interaction_menu_granter/ui_static_data(mob/living/user)
	. = ..()
	//Getting interactions
	var/list/sent_interactions = list()
	for(var/interaction_key in SSinteractions.interactions)
		var/datum/interaction/I = SSinteractions.interactions[interaction_key]
		// THIS IS A BASETYPE, DO NOT SEND
		if(!I.description)
			continue
		var/list/interaction = list()
		interaction["key"] = I.type
		interaction["desc"] = I.description
		if(istype(I, /datum/interaction/lewd))
			var/datum/interaction/lewd/O = I
			if(O.interaction_flags & INTERACTION_FLAG_EXTREME_CONTENT)
				interaction["type"] = INTERACTION_EXTREME
			//SPLURT EDIT
			else if(O.interaction_flags & INTERACTION_FLAG_UNHOLY_CONTENT)
				interaction["type"] = INTERACTION_UNHOLY
			//SPLURT EDIT END
			else
				interaction["type"] = INTERACTION_LEWD
			interaction["require_user_num_feet"] = O.require_user_num_feet
			interaction["require_target_num_feet"] = O.require_target_num_feet
		else
			interaction["type"] = INTERACTION_NORMAL
		interaction["maxDistance"] = I.max_distance

		interaction["interactionFlags"] = I.interaction_flags

		interaction["required_from_user"] = I.required_from_user
		interaction["required_from_user_exposed"] = I.required_from_user_exposed
		interaction["required_from_user_unexposed"] = I.required_from_user_unexposed

		interaction["required_from_target"] = I.required_from_target
		interaction["required_from_target_exposed"] = I.required_from_target_exposed
		interaction["required_from_target_unexposed"] = I.required_from_target_unexposed
		interaction["additionalDetails"] = I.additional_details
		sent_interactions += list(interaction)
	.["interactions"] = sent_interactions
	.["interaction_speeds"] = GLOB.interaction_speeds

/proc/num_to_pref(num)
	switch(num)
		if(1)
			return "Yes"
		if(2)
			return "Ask"
		else
			return "No"

/datum/component/interaction_menu_granter/ui_act(action, params)
	if(..())
		return
	var/mob/living/parent_mob = parent
	switch(action)
		if("interact")
			var/datum/interaction/o = SSinteractions.interactions[params["interaction"]]
			if(!o)
				return FALSE
			if(o == currently_active_interaction)
				to_chat(parent_mob, span_notice("Включена автоматическая интеракция."))
				return TRUE
			o.do_action(parent_mob, target)
			return TRUE
		if("interaction_pace")
			var/speed = params["speed"]
			if(!(speed in GLOB.interaction_speeds))
				return FALSE
			src.auto_interaction_pace = speed
			return TRUE
		if("toggle_auto_interaction")
			var/datum/interaction/o = SSinteractions.interactions[params["interaction"]]
			if(!o || (currently_active_interaction == o) && (auto_interaction_target == target))
				auto_interaction_target = null
				currently_active_interaction = null
				STOP_PROCESSING(SSinteractions, src)
			else
				auto_interaction_target = target
				currently_active_interaction = o
				START_PROCESSING(SSinteractions, src)
			return TRUE
		if("favorite")
			var/datum/interaction/interaction = SSinteractions.interactions[params["interaction"]]
			if(!interaction)
				return FALSE
			var/datum/preferences/prefs = parent_mob.client.prefs
			if(interaction.type in prefs.favorite_interactions)
				LAZYREMOVE(prefs.favorite_interactions, interaction.type)
			else
				LAZYADD(prefs.favorite_interactions, interaction.type)
			prefs.save_preferences()
			return TRUE
		if("genital")
			var/mob/living/carbon/self = parent_mob
			if("visibility" in params)
				if(params["genital"] == "anus")
					self.anus_toggle_visibility(params["visibility"])
					return TRUE
				var/obj/item/organ/genital/genital = locate(params["genital"], self.internal_organs)
				if(genital && (genital in self.internal_organs))
					genital.toggle_visibility(params["visibility"])
					return TRUE
			if("set_arousal" in params)
				var/obj/item/organ/genital/genital = locate(params["genital"], self.internal_organs)
				if(!genital || (genital \
					&& (!CHECK_BITFIELD(genital.genital_flags, GENITAL_CAN_AROUSE) \
					|| HAS_TRAIT(self, TRAIT_PERMABONER) \
					|| HAS_TRAIT(self, TRAIT_NEVERBONER))))
					return FALSE
				var/original_state = genital.aroused_state
				genital.set_aroused_state(params["set_arousal"])// i'm not making it just `!aroused_state` because
				if(original_state != genital.aroused_state)		// someone just might port skyrat's new genitals
					to_chat(self, span_userlove("[genital.aroused_state ? genital.arousal_verb : genital.unarousal_verb]."))
					. = TRUE
				else
					to_chat(self, span_userlove("Ты не можешь [genital.aroused_state ? "сбросить возбуждение" : "возбудиться"]!"))
					. = FALSE
				genital.update_appearance()
				if(ishuman(self))
					var/mob/living/carbon/human/human = self
					human.update_genitals()
				return
			if("set_accessibility" in params)
				if(!self.getorganslot(ORGAN_SLOT_ANUS) && params["genital"] == "anus")
					self.toggle_anus_always_accessible()
					return TRUE
				var/obj/item/organ/genital/genital = locate(params["genital"], self.internal_organs)
				if(!genital)
					return FALSE
				genital.toggle_accessibility()
				return TRUE
			else
				return FALSE
		if("char_pref")
			var/datum/preferences/prefs = parent_mob.client.prefs
			var/value = num_to_pref(params["value"])
			switch(params["char_pref"])
				if("erp_pref")
					if(prefs.erppref == value)
						return FALSE
					else
						prefs.erppref = value
				if("noncon_pref")
					if(prefs.nonconpref == value)
						return FALSE
					else
						message_admins("[parent_mob.ckey]/[parent_mob.real_name] [ADMIN_FLW(parent_mob)][parent_mob.stat == DEAD ? " (DEAD)" : ""] меняет Non-Con c [prefs.nonconpref] на [value].")
						log_admin("[parent_mob.ckey]/[parent_mob.real_name][parent_mob.stat == DEAD ? " (DEAD)" : ""] меняет Non-Con c [prefs.nonconpref] на [value].")
						parent_mob.balloon_alert_to_viewers("Меняет Non-Con c [prefs.nonconpref] на [value].")
						prefs.nonconpref = value
				if("vore_pref")
					if(prefs.vorepref == value)
						return FALSE
					else
						prefs.vorepref = value

				if("mobsex_pref") //Hentai
					if(prefs.mobsexpref == value)
						return FALSE
					else
						prefs.mobsexpref = value

				if("hornyantags_pref") //Hentai
					if(prefs.hornyantagspref == value)
						return FALSE
					else
						prefs.hornyantagspref = value

				if("unholy_pref")
					if(prefs.unholypref == value)
						return FALSE
					else
						prefs.unholypref = value
				if("extreme_pref")
					if(prefs.extremepref == value)
						return FALSE
					else
						prefs.extremepref = value
						if(prefs.extremepref == "No")
							prefs.extremeharm = "No"
				if("extreme_harm")
					if(prefs.extremeharm == value)
						return FALSE
					else
						prefs.extremeharm = value
				else
					return FALSE
			prefs.save_character()
			return TRUE
		if("pref")
			var/datum/preferences/prefs = parent_mob.client.prefs
			switch(params["pref"])
				if("use_arousal_multiplier")
					prefs.use_arousal_multiplier = !prefs.use_arousal_multiplier
				if("arousal_multiplier")
					prefs.arousal_multiplier = params["amount"]
				if("use_moaning_multiplier")
					prefs.use_moaning_multiplier = !prefs.use_moaning_multiplier
				if("moaning_multiplier")
					prefs.moaning_multiplier = params["amount"]

				if("verb_consent")
					TOGGLE_BITFIELD(prefs.toggles, VERB_CONSENT)
				if("ranged_verb_pref")
					TOGGLE_BITFIELD(prefs.toggles, RANGED_VERBS_CONSENT)
				if("lewd_verb_sounds")
					TOGGLE_BITFIELD(prefs.toggles, LEWD_VERB_SOUNDS)
				if("arousable")
					prefs.arousable = !prefs.arousable
				if("sexknotting")
					prefs.sexknotting = !prefs.sexknotting
				if("genital_examine")
					TOGGLE_BITFIELD(prefs.cit_toggles, GENITAL_EXAMINE)
				if("vore_examine")
					TOGGLE_BITFIELD(prefs.cit_toggles, VORE_EXAMINE)
				if("medihound_sleeper")
					TOGGLE_BITFIELD(prefs.cit_toggles, MEDIHOUND_SLEEPER)
				if("eating_noises")
					TOGGLE_BITFIELD(prefs.cit_toggles, EATING_NOISES)
				if("digestion_noises")
					TOGGLE_BITFIELD(prefs.cit_toggles, DIGESTION_NOISES)
				if("trash_forcefeed")
					TOGGLE_BITFIELD(prefs.cit_toggles, TRASH_FORCEFEED)
				if("forced_fem")
					TOGGLE_BITFIELD(prefs.cit_toggles, FORCED_FEM)
				if("forced_masc")
					TOGGLE_BITFIELD(prefs.cit_toggles, FORCED_MASC)
				if("hypno")
					TOGGLE_BITFIELD(prefs.cit_toggles, HYPNO)
				if("bimbofication")
					TOGGLE_BITFIELD(prefs.cit_toggles, BIMBOFICATION)
				if("breast_enlargement")
					TOGGLE_BITFIELD(prefs.cit_toggles, BREAST_ENLARGEMENT)
				if("penis_enlargement")
					TOGGLE_BITFIELD(prefs.cit_toggles, PENIS_ENLARGEMENT)
				if("butt_enlargement")
					TOGGLE_BITFIELD(prefs.cit_toggles, BUTT_ENLARGEMENT)
				if("belly_inflation")
					TOGGLE_BITFIELD(prefs.cit_toggles, BELLY_INFLATION)
				if("never_hypno")
					TOGGLE_BITFIELD(prefs.cit_toggles, NEVER_HYPNO)
				if("no_aphro")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_APHRO)
				if("no_ass_slap")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_ASS_SLAP)
				if("no_auto_wag")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_AUTO_WAG)
				if("no_disco_dance")
					TOGGLE_BITFIELD(prefs.cit_toggles, NO_DISCO_DANCE)
				// SPLURT edit
				if("chastity_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, CHASTITY)
				if("stimulation_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, STIMULATION)
				if("edging_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, EDGING)
				if("cum_onto_pref")
					TOGGLE_BITFIELD(prefs.cit_toggles, CUM_ONTO)
				if("sex_jitter") //By Gardelin0
					TOGGLE_BITFIELD(prefs.cit_toggles, SEX_JITTER)
				//
				else
					return FALSE
			prefs.save_preferences()
			return TRUE
		if("genitals_menu")
			switch(params["who"])
				if("user")
					if(iscarbon(parent_mob))
						var/mob/living/carbon/C = parent_mob
						C.genital_menu()
						return TRUE
					else
						to_chat(parent_mob, span_warning("Unavailable for this mob."))
						return FALSE
				if("target")
					if(iscarbon(target))
						var/mob/living/carbon/C = target
						C.genital_menu()
						return TRUE
					else
						to_chat(parent_mob, span_warning("Unavailable for this mob."))
						return FALSE

#undef INTERACTION_UNHOLY //SPLURT Edit

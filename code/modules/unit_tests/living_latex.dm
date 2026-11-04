/datum/unit_test/proc/latex_actor()
	var/mob/living/simple_animal/latexmob/actor = allocate(/mob/living/simple_animal/latexmob)
	actor.mind_initialize()
	allocated += actor.mind
	var/datum/antagonist/living_latex/latex = actor.mind.add_antag_datum(/datum/antagonist/living_latex)
	allocated += latex
	return actor

/datum/latex_capture/unit_test/players_present()
	return TRUE

/obj/item/organ/latexOrgan/unit_test/host_present()
	return TRUE

/datum/unit_test/living_latex_contact/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	actor.on_attack_hand(human)
	var/datum/status_effect/latex_stained/stain = human.has_status_effect(/datum/status_effect/latex_stained)
	TEST_ASSERT(stain, "Touching latex must stain the visitor")
	TEST_ASSERT_EQUAL(stain.stage, LATEX_STAIN_HANDS, "The first touch must apply the first stage")
	actor.on_attack_hand(human)
	TEST_ASSERT(human.has_status_effect(/datum/status_effect/latex_stained) == stain, "Repeated contact must refresh one status")
	TEST_ASSERT_EQUAL(stain.stage, LATEX_STAIN_ARMS, "The second touch must advance one stage")
	human.remove_status_effect(/datum/status_effect/latex_stained)
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	latex.leave_traces = FALSE
	actor.on_attack_hand(human)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/latex_stained), "Disabled traces must leave no status")
	latex.leave_traces = TRUE
	actor.on_attack_hand(human)
	SEND_SIGNAL(human, COMSIG_COMPONENT_CLEAN_ACT)
	TEST_ASSERT(!human.has_status_effect(/datum/status_effect/latex_stained), "Washing must remove the stain")

/datum/status_effect/latex_stained/unit_test
	var/removal_succeeds = FALSE

/datum/status_effect/latex_stained/unit_test/roll_removal()
	return removal_succeeds

/datum/unit_test/living_latex_stain_stages/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	actor.attack_hand(human, INTENT_HELP)
	var/datum/status_effect/latex_stained/stain = human.has_status_effect(/datum/status_effect/latex_stained)
	TEST_ASSERT(stain, "A real hand interaction must apply the stain")
	TEST_ASSERT_EQUAL(stain.stage, LATEX_STAIN_HANDS, "One hand interaction must not count both hand signals")
	for(var/stage in LATEX_STAIN_ARMS to LATEX_STAIN_MAX_STAGE)
		actor.on_attack_hand(human)
		TEST_ASSERT_EQUAL(stain.stage, stage, "Each additional touch must advance exactly one stage")
		TEST_ASSERT_EQUAL(length(stain.stain_overlays), stage, "Each stage must add another latex patch")
		for(var/mutable_appearance/patch as anything in stain.stain_overlays)
			TEST_ASSERT_EQUAL(patch.icon, initial(actor.icon), "The stain must use the latex mob texture")
			TEST_ASSERT(patch in human.overlays, "Each patch must be visible on the affected mob")
		TEST_ASSERT(findtext(stain.linked_alert.name, "[stage]/[LATEX_STAIN_MAX_STAGE]"), "The alert must show the current stage")
	actor.on_attack_hand(human)
	TEST_ASSERT_EQUAL(stain.stage, LATEX_STAIN_MAX_STAGE, "Further touches must not exceed the third stage")
	var/list/patches = stain.stain_overlays.Copy()
	human.regenerate_icons()
	for(var/mutable_appearance/patch as anything in patches)
		TEST_ASSERT(patch in human.overlays, "Redrawing the human must preserve latex patches")
	SEND_SIGNAL(human, COMSIG_COMPONENT_CLEAN_ACT)
	for(var/mutable_appearance/patch as anything in patches)
		TEST_ASSERT(!(patch in human.overlays), "Washing must remove every latex patch")
	TEST_ASSERT(QDELETED(stain) && !stain.stain_overlays, "Washing must release the status and its appearances")

/datum/unit_test/living_latex_stain_removal/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human)
	var/datum/status_effect/latex_stained/unit_test/stain = human.apply_status_effect(/datum/status_effect/latex_stained/unit_test)
	for(var/stage in LATEX_STAIN_ARMS to LATEX_STAIN_MAX_STAGE)
		human.apply_status_effect(stain.type)
	TEST_ASSERT(!stain.try_remove(other), "Another player must not use the owner's alert")
	TEST_ASSERT(!stain.try_remove(human), "An unsuccessful roll must leave the stain")
	TEST_ASSERT_EQUAL(stain.stage, LATEX_STAIN_MAX_STAGE, "Failed shaking must not reduce its stage")
	stain.removal_succeeds = TRUE
	TEST_ASSERT(!stain.try_remove(human), "Failed attempts must also start the click cooldown")
	COOLDOWN_RESET(stain, shake_cooldown)
	TEST_ASSERT(stain.try_remove(human), "A successful roll must remove one stage")
	TEST_ASSERT_EQUAL(stain.stage, LATEX_STAIN_ARMS, "A successful attempt must lower the stage by one")
	TEST_ASSERT_EQUAL(length(stain.stain_overlays), stain.stage, "Shaking must also remove the corresponding patch")
	while(!QDELETED(stain))
		COOLDOWN_RESET(stain, shake_cooldown)
		TEST_ASSERT(stain.try_remove(human), "Later successful attempts must finish cleaning")
	TEST_ASSERT(!human.has_status_effect(stain.type) && !stain.stain_overlays, "The last stage must remove the effect and its visual references")

/datum/unit_test/living_latex_coating/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/overlay_effect/other = new /datum/overlay_effect/living_latex
	allocated += other
	human.apply_bodypart_overlays(list(BODY_ZONE_HEAD), effect_datum = other)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(human.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Uniform fixture must equip")
	var/old_color = uniform.color
	var/datum/latex_coating/coating = new(human)
	allocated += coating
	coating.cover(BODY_ZONE_L_LEG)
	coating.cover(BODY_ZONE_CHEST)
	coating.cover(BODY_ZONE_HEAD)
	TEST_ASSERT(length(human.overlays_standing[BODY_HARDLIGHT_LAYER]), "Per-limb coating must render through the PR API")
	TEST_ASSERT(length(human.overlays_standing[LATEX_CLOTHING_LAYER]), "Worn clothes must receive a coating overlay")
	TEST_ASSERT_EQUAL(uniform.color, old_color, "Clothing itself must retain its color")
	human.dropItemToGround(uniform, TRUE)
	TEST_ASSERT(!length(human.overlays_standing[LATEX_CLOTHING_LAYER]), "Removed clothes must not leave a phantom coating")
	qdel(coating)
	TEST_ASSERT_NULL(human.latex_coating, "Coating cleanup must clear its owner reference")
	TEST_ASSERT_NULL(human.layers_for_apply_effect[BODY_ZONE_CHEST], "Cleanup must clear the latex body layer")
	var/list/head = human.layers_for_apply_effect[BODY_ZONE_HEAD]
	TEST_ASSERT_EQUAL(head[LATEX_EFFECT_INDEX], other, "Cleanup must preserve another system's overlay")
	human.clear_bodypart_overlays()

/datum/unit_test/living_latex_capture_cancel/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/latex_capture/attempt = new /datum/latex_capture/unit_test(latex, actor, human)
	TEST_ASSERT(attempt.start(), "Capture must attach")
	TEST_ASSERT_EQUAL(actor.loc, human, "Latex must follow the target while attached")
	TEST_ASSERT(BODY_ZONE_L_LEG in human.latex_coating.covered, "Capture must begin with a leg")
	TEST_ASSERT(!attempt.stop_pointer(actor, attempt.round_id), "Attacker cannot answer the host QTE")
	TEST_ASSERT(!attempt.stop_pointer(human, attempt.round_id + 1), "Stale or future QTE rounds must be rejected")
	qdel(attempt)
	TEST_ASSERT(isturf(actor.loc), "Cancellation must return latex to a turf")
	TEST_ASSERT(!HAS_TRAIT(actor, TRAIT_IMMOBILIZED), "Cancellation must release movement")
	TEST_ASSERT_NULL(human.latex_capture, "Cancellation must release the target lock")
	TEST_ASSERT_NULL(human.latex_coating, "Cancellation must remove all temporary coating")
	TEST_ASSERT_NULL(latex.capture, "Cancellation must release the attacker lock")

/datum/unit_test/living_latex_qte/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/latex_capture/attempt = new /datum/latex_capture/unit_test(latex, actor, human)
	TEST_ASSERT(attempt.start(), "Capture fixture must attach")
	attempt.round_start = world.time - LATEX_QTE_PERIOD / 4
	attempt.zone_start = 0
	TEST_ASSERT(!attempt.stop_pointer(human, attempt.round_id), "A miss must fail")
	TEST_ASSERT(!attempt.stop_pointer(human, attempt.round_id), "One attempt per round must be enforced")
	attempt.next_round()
	attempt.round_start = world.time - LATEX_QTE_PERIOD / 4
	attempt.zone_start = 0.5 - LATEX_QTE_WIDTH / 2
	TEST_ASSERT(attempt.stop_pointer(human, attempt.round_id), "A hit must let the host escape")
	TEST_ASSERT(QDELETED(attempt), "Successful resistance must end the capture")
	TEST_ASSERT(isturf(actor.loc) && !human.latex_coating, "Successful resistance must fully restore both mobs")

/datum/unit_test/living_latex_capture_disconnect/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/latex_capture/attempt = new /datum/latex_capture/unit_test(latex, actor, human)
	TEST_ASSERT(attempt.start(), "Capture fixture must attach")
	SEND_SIGNAL(human, COMSIG_MOB_CLIENT_LOGOUT)
	TEST_ASSERT(QDELETED(attempt), "Host logout must interrupt the capture")
	TEST_ASSERT(isturf(actor.loc) && !human.latex_coating, "Logout cleanup must leave no intermediate state")

/datum/unit_test/living_latex_control/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/datum/mind/latex_mind = actor.mind
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.mind_initialize()
	var/datum/mind/host_mind = human.mind
	allocated += host_mind
	var/obj/item/organ/eyes/robotic/eyes = allocate(/obj/item/organ/eyes/robotic)
	eyes.Insert(human)
	var/datum/species/species = human.dna.species
	var/list/organs = human.internal_organs.Copy()
	var/obj/item/organ/latexOrgan/organ = allocate(/obj/item/organ/latexOrgan/unit_test)
	TEST_ASSERT(organ.attach(latex, actor, human), "Latex must join without changing the host")
	TEST_ASSERT(organ.swap_control(), "Latex must be able to take control")
	TEST_ASSERT_EQUAL(latex_mind.current, human, "Latex must control the original body")
	TEST_ASSERT_EQUAL(host_mind.current, organ.ObserverBackseat, "Host must remain in the backseat")
	TEST_ASSERT(organ.swap_control(), "Latex must be able to return control")
	TEST_ASSERT_EQUAL(host_mind.current, human, "Original host must regain control")
	for(var/obj/item/organ/expected as anything in organs)
		TEST_ASSERT((expected in human.internal_organs) && !QDELETED(expected), "Original organ [expected.type] must survive both transfers; deleted=[QDELETED(expected)], owner=[expected.owner], in host=[expected in human.internal_organs]")
	TEST_ASSERT_EQUAL(human.dna.species, species, "Control transfer must retain the exact species datum")
	organ.release()
	allocated += latex_mind.current
	TEST_ASSERT(islatexmob(latex_mind.current) && isturf(latex_mind.current.loc), "Release must restore a free latex body")
	TEST_ASSERT_EQUAL(host_mind.current, human, "Release must preserve the host mind")

/datum/unit_test/living_latex_observers/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.mind_initialize()
	allocated += human.mind
	var/obj/item/organ/latexOrgan/organ = allocate(/obj/item/organ/latexOrgan/unit_test)
	TEST_ASSERT(organ.attach(latex, actor, human), "Latex must join")
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)
	ghost.orbit(human)
	TEST_ASSERT(organ.swap_control(), "Control swap fixture must work")
	TEST_ASSERT_EQUAL(ghost.orbit_target, human, "Observers must keep following the same body")
	ghost.forceMove(run_loc_floor_top_right)
	var/turf/ghost_turf = get_turf(ghost)
	TEST_ASSERT_NULL(ghost.orbit_target, "A ghost that leaves must detach")
	TEST_ASSERT(organ.swap_control(), "Return swap fixture must work")
	TEST_ASSERT_EQUAL(get_turf(ghost), ghost_turf, "A detached observer must never teleport on a swap")
	organ.release()
	allocated += latex.owner.current

/datum/unit_test/living_latex_mimicry/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/datum/action/cooldown/latexmob/mimicry/ability = new
	allocated += ability
	ability.my_living_latex = latex
	ability.Grant(actor)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(ability.copy_target(bag), "Nested item subtypes must be copyable")
	qdel(bag)
	TEST_ASSERT(actor.do_mimicry(ability), "Snapshot must remain usable after source deletion")
	var/obj/shell = actor.mimic_shell
	TEST_ASSERT(istype(shell, /obj/item/latex_disguise), "Mimicry must create an inert shell")
	TEST_ASSERT(!shell.GetComponent(/datum/component/storage), "Copied storage must not duplicate storage mechanics")
	qdel(shell)
	TEST_ASSERT(isturf(actor.loc) && !actor.mimicry_in_use && !actor.mimic_shell, "Deleting a shell must safely release its player")
	TEST_ASSERT(actor.do_mimicry(ability), "Mimicry must work again after forced shell deletion")
	TEST_ASSERT(actor.go_back(), "Manual reveal must work")
	TEST_ASSERT(isturf(actor.loc) && !actor.mimic_shell, "Manual reveal must not leave a shell")

/datum/unit_test/living_latex_evolution/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	latex.evolve_points = LATEX_MAX_POINTS
	TEST_ASSERT(!latex.upgrade_stage(LATEX_MAX_STAGE), "Stage skipping must be refused")
	TEST_ASSERT(latex.upgrade_stage(1), "The next stage must be purchasable")
	latex.evolve_points = LATEX_MAX_POINTS
	var/datum/action/cooldown/latexmob/heal/template = /datum/action/cooldown/latexmob/heal
	TEST_ASSERT(latex.search_ability_name(initial(template.name)), "An affordable ability must be purchasable")
	TEST_ASSERT(!latex.search_ability_name(initial(template.name)), "A purchase must not permit negative evolution points")
	latex.evolve_points = LATEX_MAX_POINTS
	latex.process(1)
	TEST_ASSERT_EQUAL(latex.evolve_points, LATEX_MAX_POINTS, "Regeneration must never exceed the point cap")
	var/datum/action/cooldown/latexmob/traces/traces = latex.get_ability_by_path(/datum/action/cooldown/latexmob/traces)
	TEST_ASSERT(traces.Activate() && traces.Activate(), "Abilities must remain usable after their first activation")

/datum/unit_test/living_latex_upgrades/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	latex.stage = LATEX_MAX_STAGE
	for(var/ability_type in latex.all_abilities)
		check_upgrades(latex, ability_type)
	var/datum/action/cooldown/latexmob/venomAction/absorb = latex.get_ability_by_path(/datum/action/cooldown/latexmob/venomAction)
	TEST_ASSERT(absorb.can_absorb_alive && !absorb.pick_only_simplemob, "Upgrading absorption must enable living and human targets")
	TEST_ASSERT((/datum/reagent/medicine/salbutamol in latex.avaible_reagents) && (/datum/reagent/medicine/antihol in latex.avaible_reagents), "Healing upgrades must unlock both reagent tiers")
	var/datum/action/cooldown/latexmob/ferral_form/feral = latex.get_ability_by_path(/datum/action/cooldown/latexmob/ferral_form)
	TEST_ASSERT_EQUAL(feral.melee_damage, LATEX_FORM_DAMAGE * (LATEX_FORM_DAMAGE_STEP ** LATEX_MAX_STAGE), "Feral upgrades must increase damage")

/datum/unit_test/living_latex_upgrades/proc/check_upgrades(datum/antagonist/living_latex/latex, ability_type)
	var/datum/action/cooldown/latexmob/template = ability_type
	var/ability_name = initial(template.name)
	if(!latex.get_ability_by_path(ability_type))
		latex.evolve_points = LATEX_MAX_POINTS
		TEST_ASSERT(latex.search_ability_name(ability_name), "Initial purchase must succeed")
	var/datum/action/cooldown/latexmob/ability = latex.get_ability_by_path(ability_type)
	var/ability_count = length(latex.available_abilities)
	var/datum/hud/hud = allocate(/datum/hud, latex.owner.current)
	var/atom/movable/screen/movable/action_button/button = allocate(/atom/movable/screen/movable/action_button)
	ability.viewers[hud] = button
	while(ability.stage < ability.finall_stage)
		var/old_stage = ability.stage
		latex.evolve_points = LATEX_MAX_POINTS
		TEST_ASSERT(latex.search_ability_name(ability_name), "Repeated purchase must upgrade [ability_name]")
		TEST_ASSERT_EQUAL(ability.stage, old_stage + 1, "Each purchase must add exactly one upgrade")
		TEST_ASSERT_EQUAL(latex.evolve_points, LATEX_MAX_POINTS - ability.points_need_to_upgrade, "Each upgrade must charge exactly once")
		TEST_ASSERT_EQUAL(ability.button_icon_state, "[initial(template.button_icon_state)]_[ability.stage]", "Upgrades must select the corresponding sprite")
		TEST_ASSERT_EQUAL(button.button_icon_state, ability.button_icon_state, "The existing HUD button must update immediately")
		var/list/data = latex.evolution_store.ui_data(latex.owner.current)
		for(var/list/entry as anything in data["abilities"])
			if(entry["name"] == ability_name)
				TEST_ASSERT_EQUAL(entry["icon"], icon2base64(icon(ability.icon_icon, ability.button_icon_state)), "The shop must show the owned ability's current icon")
	latex.evolve_points = LATEX_MAX_POINTS
	TEST_ASSERT(!latex.search_ability_name(ability_name), "A fully upgraded ability must refuse another purchase")
	TEST_ASSERT_EQUAL(latex.evolve_points, LATEX_MAX_POINTS, "Refused upgrades must not spend points")
	TEST_ASSERT_EQUAL(length(latex.available_abilities), ability_count, "Upgrades must not create duplicate actions")
	ability.viewers -= hud

/datum/unit_test/living_latex_debug/Run()
	var/mob/living/simple_animal/latexmob/debug/actor = allocate(/mob/living/simple_animal/latexmob/debug)
	TEST_ASSERT(actor.mind, "The debug mob must create a mind immediately")
	allocated += actor.mind
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	TEST_ASSERT(latex, "The debug mob must create its antagonist datum immediately")
	allocated += latex
	TEST_ASSERT_EQUAL(latex.stage, LATEX_MAX_STAGE, "The debug mob must start at the final evolution stage")
	TEST_ASSERT_EQUAL(latex.evolve_points, LATEX_MAX_POINTS, "The debug mob must start with full evolution points")
	for(var/ability_type in latex.all_abilities)
		var/datum/action/cooldown/latexmob/ability = latex.get_ability_by_path(ability_type)
		TEST_ASSERT(ability && ability.owner == actor, "Each debug ability must already belong to its mob")
		TEST_ASSERT_EQUAL(ability.stage, min(latex.stage, ability.finall_stage), "Every debug ability must start fully upgraded")
	var/datum/action/cooldown/latexmob/venomAction/absorb = latex.get_ability_by_path(/datum/action/cooldown/latexmob/venomAction)
	TEST_ASSERT(absorb.can_absorb_alive && !absorb.pick_only_simplemob, "Debug upgrades must apply their functional effects")
	TEST_ASSERT(latex.avaible_reagents.Find(/datum/reagent/medicine/antihol), "Debug healing must include the final reagent tier")

/datum/unit_test/living_latex_capture_complete/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.mind_initialize()
	var/datum/mind/host_mind = human.mind
	allocated += host_mind
	var/datum/latex_capture/attempt = new /datum/latex_capture/unit_test(latex, actor, human)
	TEST_ASSERT(attempt.start(), "Capture fixture must attach")
	while(!QDELETED(attempt))
		attempt.next_round()
	var/obj/item/organ/latexOrgan/organ = latex.host_organ
	TEST_ASSERT(organ, "Finishing every limb must create the host organ")
	TEST_ASSERT(human.latex_coating && !QDELETED(human.latex_coating), "Completed capture must preserve its coating")
	TEST_ASSERT_EQUAL(length(human.latex_coating.covered), length(list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_HEAD)), "All body zones must be covered")
	TEST_ASSERT_EQUAL(host_mind.current, human, "Engulfing must not take control automatically")
	organ.release()
	allocated += latex.owner.current
	TEST_ASSERT_NULL(human.latex_coating, "Release after completion must remove the coating")

/datum/unit_test/living_latex_host_deletion/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/latexOrgan/organ = allocate(/obj/item/organ/latexOrgan)
	var/datum/latex_coating/coating = new(human, latex)
	coating.cover(BODY_ZONE_CHEST)
	TEST_ASSERT(organ.attach(latex, actor, human, coating), "Latex must join a body")
	qdel(human)
	TEST_ASSERT(islatexmob(latex.owner.current) && isturf(latex.owner.current.loc), "Deleting the host must release the latex player")
	allocated += latex.owner.current
	TEST_ASSERT_NULL(latex.host_organ, "Deleting the host must clear the link")

/datum/unit_test/living_latex_blocked_control/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.mind_initialize()
	var/datum/mind/host_mind = human.mind
	allocated += host_mind
	var/obj/item/organ/latexOrgan/organ = allocate(/obj/item/organ/latexOrgan/unit_test)
	TEST_ASSERT(organ.attach(latex, actor, human), "Latex must join")
	RegisterSignal(host_mind, COMSIG_PRE_MIND_TRANSFER, PROC_REF(block_transfer))
	TEST_ASSERT(!organ.swap_control(), "A blocked host transfer must cancel the swap")
	UnregisterSignal(host_mind, COMSIG_PRE_MIND_TRANSFER)
	TEST_ASSERT_EQUAL(host_mind.current, human, "A blocked swap must restore the host")
	TEST_ASSERT_EQUAL(latex.owner.current, organ.ObserverBackseat, "A blocked swap must restore latex")
	TEST_ASSERT_EQUAL(latex.current_controller, BODY_OWNER, "A blocked swap must preserve the controller flag")
	organ.release()
	allocated += latex.owner.current

/datum/unit_test/living_latex_blocked_control/proc/block_transfer(datum/source, mob/new_body, mob/old_body)
	SIGNAL_HANDLER
	if(isbackseatmob(new_body))
		return COMPONENT_STOP_MIND_TRANSFER

/datum/unit_test/living_latex_offline_host/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.mind_initialize()
	var/datum/mind/host_mind = human.mind
	allocated += host_mind
	var/obj/item/organ/latexOrgan/organ = allocate(/obj/item/organ/latexOrgan)
	TEST_ASSERT(organ.attach(latex, actor, human), "Latex must join")
	TEST_ASSERT(!organ.swap_control(), "An offline player's body must not be taken over")
	TEST_ASSERT_EQUAL(host_mind.current, human, "Refused takeover must leave the host untouched")
	TEST_ASSERT(organ.release(), "An offline host must never prevent latex from leaving")
	allocated += latex.owner.current

/datum/unit_test/living_latex_mimic_nullspace/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/datum/action/cooldown/latexmob/mimicry/ability = new
	allocated += ability
	ability.my_living_latex = latex
	ability.Grant(actor)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(ability.copy_target(bag) && actor.do_mimicry(ability), "Mimic fixture must work")
	var/obj/shell = actor.mimic_shell
	shell.moveToNullspace()
	qdel(shell)
	TEST_ASSERT(isturf(actor.loc) && !actor.mimicry_in_use, "A shell deleted in nullspace must return its player to the last known turf")

/datum/unit_test/living_latex_role_removal/Run()
	var/mob/living/simple_animal/latexmob/actor = latex_actor()
	var/datum/antagonist/living_latex/latex = actor.mind.has_antag_datum(/datum/antagonist/living_latex)
	var/datum/action/cooldown/latexmob/mimicry/ability = new
	latex.available_abilities += ability
	ability.my_living_latex = latex
	ability.Grant(actor)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(ability.copy_target(bag) && actor.do_mimicry(ability), "Mimic fixture must work")
	actor.mind.remove_antag_datum(/datum/antagonist/living_latex)
	TEST_ASSERT(isturf(actor.loc) && !actor.mimic_shell && !actor.mimicry_in_use, "Role removal must reveal the player before removing their abilities")
	TEST_ASSERT(QDELETED(ability) && QDELETED(latex), "Role removal must delete its initialized datums")

	var/mob/living/simple_animal/latexmob/hosted_actor = latex_actor()
	var/datum/mind/hosted_mind = hosted_actor.mind
	var/datum/antagonist/living_latex/hosted_latex = hosted_mind.has_antag_datum(/datum/antagonist/living_latex)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/latexOrgan/organ = allocate(/obj/item/organ/latexOrgan)
	TEST_ASSERT(organ.attach(hosted_latex, hosted_actor, human), "Hosted role-removal fixture must work")
	hosted_mind.remove_antag_datum(/datum/antagonist/living_latex)
	allocated += hosted_mind.current
	TEST_ASSERT(isturf(hosted_mind.current?.loc), "Removing the role inside a host must restore a free body")
	TEST_ASSERT(QDELETED(organ), "Role removal must also delete its host organ")

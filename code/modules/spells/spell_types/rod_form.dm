/obj/effect/proc_holder/spell/targeted/rod_form
	name = "Rod Form"
	desc = "Take on the form of an immovable rod, destroying all in your path."
	charge_max = 250
	cooldown_min = 100
	range = -1
	include_user = 1
	invocation = "CLANG!"
	invocation_type = "shout"
	action_icon_state = "immrod"

/obj/effect/proc_holder/spell/targeted/rod_form/cast(list/targets,mob/user = usr)
	for(var/mob/living/M in targets)
		var/turf/start = get_turf(M)
		var/obj/effect/immovablerod/wizard/W = new(start, get_ranged_target_turf(M, M.dir, (15 + spell_level * 3)))
		W.wizard = M
		W.max_distance += spell_level * 3 //You travel farther when you upgrade the spell
		W.damage_bonus += spell_level * 20 //You do more damage when you upgrade the spell
		W.start_turf = start
		M.forceMove(W)
		M.mob_transforming = 1
		M.status_flags |= GODMODE

//Wizard Version of the Immovable Rod

/obj/effect/immovablerod/wizard
	var/max_distance = 13
	var/damage_bonus = 0
	var/turf/start_turf
	///The wizard who is currently piloting the rod.
	var/mob/living/wizard
	notify = FALSE
	dnd_style_level_up = FALSE

/obj/effect/immovablerod/wizard/Moved(atom/old_loc, movement_dir, forced)
	if(get_dist(start_turf, get_turf(src)) >= max_distance)
		qdel(src)
		return //без выхода ..() двигал уже уничтоженный род
	return ..()

/obj/effect/immovablerod/wizard/Destroy()
	if(wizard)
		wizard.status_flags &= ~GODMODE
		wizard.mob_transforming = 0
		wizard.forceMove(get_turf(src))
		wizard = null //иначе род тянет за собой визарда, а тот - свой мозг
	start_turf = null
	return ..()

/obj/effect/immovablerod/wizard/penetrate(mob/living/smeared_mob)
	if(smeared_mob.anti_magic_check())
		smeared_mob.visible_message(span_danger("[src] hits [smeared_mob], but it bounces back, then vanishes!") , span_userdanger("[src] hits you... but it bounces back, then vanishes!") , span_danger("You hear a weak, sad, CLANG."))
		qdel(src)
		return
	smeared_mob.visible_message(span_danger("[smeared_mob] is penetrated by an immovable rod!") , span_userdanger("The rod penetrates you!") , span_danger("You hear a CLANG!"))
	smeared_mob.adjustBruteLoss(70 + damage_bonus)

/obj/effect/immovablerod/wizard/suplex_rod(mob/living/strongman)
	if(!wizard)
		return ..() //Нет визарда в стержне? Тогда это просто обычный стержень

	strongman.visible_message(
		span_boldwarning("[src] превращается обратно в [wizard], когда [strongman] суплексит его!"),
		span_warning("Когда вы хватаете [src], он внезапно превращается в [wizard], которого вы впечатываете в пол!")
		)
	to_chat(wizard, span_boldwarning("Вас внезапно выбивает из формы стержня, когда [strongman] каким-то образом ухитряется схватить вас и впечатать вас в пол!"))
	wizard.Stun(60)
	wizard.apply_damage(25, BRUTE)
	qdel(src)
	return TRUE

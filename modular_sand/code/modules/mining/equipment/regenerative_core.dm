/obj/item/organ/regenerative_core/afterattack(atom/target, mob/user, proximity_flag)
	if(proximity_flag)
		if(ishuman(target))
			apply_healing_core(target, user)

/obj/item/organ/regenerative_core/attack_self(mob/user)
	if(iscarbon(user))
		apply_healing_core(user, user)

/obj/item/organ/regenerative_core/proc/apply_healing_core(atom/target, mob/user)
	if(!user || !ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	if(inert)
		to_chat(user, span_notice("[src] разложилось и не может быть применено для лечения."))
		return
	if(H.stat == DEAD)
		to_chat(user, span_notice("[src] не сработает на уже  мёртвых."))
		return
	if(H != user)
		H.visible_message("[user] заставляет [H] принять [src]... Чёрные щупальца обвиваются и скрепляют едино [H.ru_ego()] тело!")
		SSblackbox.record_feedback("nested tally", "hivelord_core", 1, list("[type]", "used", "other"))
	else
		to_chat(user, span_notice("Вы стали размазывать [src] по своему телу. Отвратительные щупальца обхватывают вас и помогают вам идти, но как долго?"))
		SSblackbox.record_feedback("nested tally", "hivelord_core", 1, list("[type]", "used", "self"))
	if(!is_mining_level(H.z))
		H.adjustBruteLoss(-25, 0)
		H.adjustFireLoss(-25, 0)
		for(var/obj/item/organ/O in H)
			O.damage = 0
	else
		H.revive(full_heal = 1)
	if(H.has_quirk(/datum/quirk/undead))
		if(H != user)
			H.visible_message(span_danger("После применения [src], тело [H] странно дёргается..."))
		else
			to_chat(user, span_danger("Чёрные щупальца проникают в ваше тело... Какая-то часть вас внезапно откликается и вы ощущаете себя... Живым!"))
		H.remove_quirk(/datum/quirk/undead)
	qdel(src)
	user.log_message("[user] used [src] to heal [H == user ? "[H.p_them()]self" : H]! Wake the fuck up, Samurai!", LOG_ATTACK, color="green") //Logging for 'old' style legion core use, when clicking on a sprite of yourself or another.

/obj/structure/eldritch_crucible
	name = "зловещий тигель"
	desc = "Чугунный тигель на стальных зубчатых ножках. Вязкая жидкость внутри поглощает плоть и превращает её в колдовские напитки."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "crucible"
	anchored = FALSE
	density = TRUE
	///How much mass this currently holds
	var/current_mass = 5
	///Maximum amount of mass
	var/max_mass = 5
	///Check to see if it is currently being used.
	var/in_use = FALSE

/obj/structure/eldritch_crucible/examine(mob/user)
	. = ..()
	if(!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user))
		return
	if(current_mass < max_mass)
		. += "Для заполнения тигля нужно ещё [max_mass - current_mass] органов или частей тела."
	else
		. += "Тигель готов к использованию!"

	. += "Кодекс позволяет закрепить или освободить тигель."
	. += "Сейчас он [anchored ? "закреплён" : "не закреплён"]."
	. += "Напиток крепкой души позволяет проходить сквозь стены в течение 15 секунд, затем возвращает туда, где его выпили."
	. += "Напиток заката и рассвета позволяет видеть сквозь стены и предметы в течение 60 секунд."
	. += "Напиток раненого солдата в течение 60 секунд лечит каждую рану и защищает от замедления из-за урона. Незначительные раны восстанавливаются на 1 единицу урона в секунду, средние — на 3, критические — на 6."

/obj/structure/eldritch_crucible/attacked_by(obj/item/I, mob/living/user)
	if(istype(I,/obj/item/nullrod))
		qdel(src)
		return

	if(!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user))
		if(iscarbon(user))
			devour(user)
		return

	if(istype(I,/obj/item/forbidden_book))
		playsound(src, 'sound/misc/desceration-02.ogg', 75, TRUE)
		anchored = !anchored
		to_chat(user,"<span class='notice'>Вы [anchored == FALSE ? "освобождаете" : "закрепляете"] тигель.</span>")
		return

	if(istype(I,/obj/item/bodypart) || istype(I,/obj/item/organ))
		if(istype(I, /obj/item/bodypart))
			var/obj/item/bodypart/part = I
			if(part.status != BODYPART_ORGANIC)
				return
		else
			var/obj/item/organ/organ = I
			if(organ.status != ORGAN_ORGANIC)
				return

		if(current_mass >= max_mass)
			to_chat(user,"<span class='notice'> Тигель полон!</span>")
			return
		playsound(src, 'sound/items/eatfood.ogg', 100, TRUE)
		to_chat(user,"<span class='notice'>Тигель поглощает [I.name] и наполняется небольшим количеством вязкой жидкости!</span>")
		current_mass++
		qdel(I)
		update_icon_state()
		return

	return ..()

/obj/structure/eldritch_crucible/attack_hand(mob/user)
	if(!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user))
		if(iscarbon(user))
			devour(user)
		return

	if(user.incapacitated() || !Adjacent(user))
		return
	if(in_use)
		to_chat(user, span_notice("Тигель уже занят приготовлением."))
		return

	if(current_mass < max_mass)
		to_chat(user,"<span class='notice'>Тигель недостаточно полон! Принесите ещё органов или частей тел!</span>")
		return

	in_use = TRUE
	var/list/lst = list()
	for(var/X in subtypesof(/obj/item/eldritch_potion))
		var/obj/item/eldritch_potion/potion = X
		lst[initial(potion.name)] = potion
	var/choice = tgui_input_list(user, "Выберите варево", "Тигель", lst)
	in_use = FALSE
	if(QDELETED(src) || QDELETED(user) || !choice || !lst[choice] || user.incapacitated() || !Adjacent(user) || current_mass < max_mass || (!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user)))
		return
	var/type = lst[choice]
	playsound(src, 'sound/misc/desceration-02.ogg', 75, TRUE)
	new type(drop_location())
	current_mass = 0
	in_use = FALSE
	update_icon_state()

///Proc that eats the active limb of the victim
/obj/structure/eldritch_crucible/proc/devour(mob/living/carbon/user)
	if(HAS_TRAIT(user,TRAIT_NODISMEMBER))
		return
	var/obj/item/bodypart/arm = user.get_active_hand()
	if(!arm || !arm.dismember())
		return
	playsound(src, 'sound/items/eatfood.ogg', 100, TRUE)
	to_chat(user, span_danger("Тигель хватает вашу руку и пожирает её целиком!"))
	qdel(arm)
	current_mass += current_mass < max_mass ? 1 : 0
	update_icon_state()

/obj/structure/eldritch_crucible/update_icon_state()
	. = ..()
	if(current_mass == max_mass)
		icon_state = "crucible"
	else
		icon_state = "crucible_empty"

/obj/structure/trap/eldritch
	name = "запретная руна"
	desc = "Неизвестные символы, от которых веет смутно знакомым прошлым."
	icon = 'icons/obj/eldritch.dmi'
	charges = 1
	///Owner of the trap
	var/mob/owner

/obj/structure/trap/eldritch/Crossed(atom/movable/AM)
	if(!isliving(AM))
		return ..()
	var/mob/living/living_mob = AM
	if((owner && living_mob == owner) || IS_HERETIC(living_mob) || IS_HERETIC_MONSTER(living_mob))
		return
	return ..()

/obj/structure/trap/eldritch/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(istype(I,/obj/item/melee/rune_knife) || istype(I,/obj/item/nullrod))
		qdel(src)

///Proc that sets the owner
/obj/structure/trap/eldritch/proc/set_owner(mob/_owner)
	owner = _owner

/obj/structure/trap/eldritch/alert
	name = "предупреждающая руна"
	icon_state = "alert_rune"
	alpha = 10

/obj/structure/trap/eldritch/alert/trap_effect(mob/living/L)
	if(owner)
		to_chat(owner,"<span class='big boldwarning'>[L.real_name] наступает на предупреждающую руну в [get_area(src)]!</span>")
	return ..()

//this trap can only get destroyed by rune carving knife or nullrod
/obj/structure/trap/eldritch/alert/flare()
	return

/obj/structure/trap/eldritch/tentacle
	name = "хватающая руна"
	icon_state = "tentacle_rune"

/obj/structure/trap/eldritch/tentacle/trap_effect(mob/living/L)
	if(!iscarbon(L))
		return
	var/mob/living/carbon/carbon_victim = L
	carbon_victim.DefaultCombatKnockdown(50)
	carbon_victim.drop_all_held_items()
	carbon_victim.apply_damage(20,BRUTE,BODY_ZONE_R_LEG)
	carbon_victim.apply_damage(20,BRUTE,BODY_ZONE_L_LEG)
	playsound(src, 'sound/magic/demon_attack1.ogg', 75, TRUE)
	return ..()

/obj/structure/trap/eldritch/mad
	name = "руна безумия"
	icon_state = "madness_rune"

/obj/structure/trap/eldritch/mad/trap_effect(mob/living/L)
	if(!iscarbon(L))
		return
	var/mob/living/carbon/carbon_victim = L
	carbon_victim.adjustStaminaLoss(60)
	carbon_victim.silent += 10
	carbon_victim.confused += 5
	carbon_victim.Jitter(10)
	carbon_victim.Dizzy(20)
	carbon_victim.blind_eyes(2)
	SEND_SIGNAL(carbon_victim, COMSIG_ADD_MOOD_EVENT, "gates_of_mansus", /datum/mood_event/gates_of_mansus)
	return ..()

#define CRUCIBLE_FILL_STAGES 3

/obj/structure/eldritch_crucible
	name = "eldritch crucible"
	desc = "Чугунный котёл, утопленный в мясистую челюсть с костяными клыками. Костяная поварёшка сама мешает вязкую жидкость, которая поглощает плоть и превращает её в колдовские напитки; руны на брюхе загораются по мере наполнения."
	icon = 'modular_bluemoon/icons/obj/heretic_crucible.dmi'
	icon_state = "crucible_0"
	anchored = FALSE
	density = TRUE
	///How much mass this currently holds
	var/current_mass = 0
	///Maximum amount of mass
	var/max_mass = 3
	///How long the crucible takes to gather one unit of mass by itself
	var/refill_time = 30 SECONDS
	var/refill_timer
	///Check to see if it is currently being used.
	var/in_use = FALSE

/obj/structure/eldritch_crucible/Initialize(mapload)
	. = ..()
	update_icon()
	queue_refill()

/obj/structure/eldritch_crucible/Destroy()
	deltimer(refill_timer)
	refill_timer = null
	return ..()

/obj/structure/eldritch_crucible/examine(mob/user)
	. = ..()
	if(!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user))
		return
	if(current_mass < max_mass)
		. += "Тигель наполнен на [current_mass] из [max_mass]. Он сам набирает одну долю каждые [DisplayTimeText(refill_time)]; орган или часть тела добавляет долю сразу."
	else
		. += "Тигель готов к использованию! Одно зелье забирает все [max_mass] доли."
	. += "Мозг и голову с мозгом тигель не примет."
	. += "Повторный обряд тигля переносит его вместе с содержимым."
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
		consume(I, user)
		return

	return ..()

/obj/structure/eldritch_crucible/proc/consume(obj/item/fuel, mob/living/user)
	if(isbodypart(fuel))
		var/obj/item/bodypart/part = fuel
		if(part.status != BODYPART_ORGANIC)
			return FALSE
		if(locate(/obj/item/organ/brain) in part)
			to_chat(user, span_warning("Тигель не примет голову с мозгом. Сначала извлеките мозг."))
			return FALSE
	else
		var/obj/item/organ/organ = fuel
		if(organ.status != ORGAN_ORGANIC)
			return FALSE
		if(istype(organ, /obj/item/organ/brain) || (organ.organ_flags & ORGAN_VITAL))
			to_chat(user, span_warning("Тигель не примет мозг."))
			return FALSE

	if(current_mass >= max_mass)
		to_chat(user, span_notice("Тигель полон!"))
		return FALSE
	playsound(src, 'sound/items/eatfood.ogg', 100, TRUE)
	to_chat(user, span_notice("Тигель поглощает [fuel.name] и наполняется небольшим количеством вязкой жидкости!"))
	qdel(fuel)
	set_mass(current_mass + 1)
	flick("crucible_chomp", src)
	return TRUE

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
		to_chat(user, span_notice("Тигель наполнен на [current_mass] из [max_mass]. Подождите или принесите органы и части тел."))
		return

	INVOKE_ASYNC(src, PROC_REF(choose_potion), user)

/obj/structure/eldritch_crucible/proc/choose_potion(mob/living/user)
	var/static/list/choices
	var/static/list/names_to_path
	if(!choices)
		choices = list()
		names_to_path = list()
		for(var/obj/item/eldritch_potion/potion as anything in subtypesof(/obj/item/eldritch_potion))
			names_to_path[initial(potion.name)] = potion
			choices[initial(potion.name)] = image(icon = initial(potion.icon), icon_state = initial(potion.icon_state))
	in_use = TRUE
	var/choice = show_radial_menu(user, src, choices, require_near = TRUE, tooltips = TRUE)
	in_use = FALSE
	if(QDELETED(src) || QDELETED(user) || !choice || user.incapacitated() || !Adjacent(user) || (!IS_HERETIC(user) && !IS_HERETIC_MONSTER(user)))
		return
	brew(user, names_to_path[choice])

/obj/structure/eldritch_crucible/proc/brew(mob/living/user, potion_type)
	if(current_mass < max_mass || !ispath(potion_type, /obj/item/eldritch_potion))
		return null
	var/obj/item/eldritch_potion/potion = new potion_type(drop_location())
	playsound(src, 'sound/misc/desceration-02.ogg', 75, TRUE)
	visible_message(span_notice("Сияющая жидкость из [src] стекает в колбу: [potion.name]."))
	set_mass(0)
	return potion

/obj/structure/eldritch_crucible/proc/set_mass(amount)
	current_mass = clamp(amount, 0, max_mass)
	update_icon()
	if(current_mass < max_mass)
		queue_refill()
		return
	deltimer(refill_timer)
	refill_timer = null

/obj/structure/eldritch_crucible/proc/queue_refill()
	if(refill_timer || current_mass >= max_mass)
		return
	refill_timer = addtimer(CALLBACK(src, PROC_REF(refill)), refill_time, TIMER_STOPPABLE)

/obj/structure/eldritch_crucible/proc/refill()
	refill_timer = null
	playsound(src, 'sound/effects/bubbles.ogg', 40, TRUE)
	set_mass(current_mass + 1)

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
	set_mass(current_mass + 1)
	flick("crucible_chomp", src)

/obj/structure/eldritch_crucible/update_icon_state()
	. = ..()
	icon_state = "crucible_[max_mass ? round(CRUCIBLE_FILL_STAGES * current_mass / max_mass) : 0]"

#undef CRUCIBLE_FILL_STAGES

/obj/structure/trap/eldritch
	name = "forbidden rune"
	desc = "Неизвестные символы, от которых веет смутно знакомым прошлым."
	icon = 'icons/obj/eldritch.dmi'
	charges = 1
	///Owner of the trap
	var/mob/owner

/obj/structure/trap/eldritch/Destroy()
	owner = null
	return ..()

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
	name = "warning rune"
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
	name = "grasping rune"
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
	name = "rune of madness"
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

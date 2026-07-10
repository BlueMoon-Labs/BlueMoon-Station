//Repeater: Activates every second.
/obj/structure/destructible/clockwork/trap/trigger/repeater
	name = "repeater"
	desc = "Маленькая черная призма с драгоценным камнем в центре."
	clockwork_desc = "Репитер, который будет отправлять сигнал активации каждую секунду."
	max_integrity = 15 //Fragile!
	icon_state = "repeater"

/obj/structure/destructible/clockwork/trap/trigger/repeater/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!is_servant_of_ratvar(user))
		return
	if(!(datum_flags & DF_ISPROCESSING))
		START_PROCESSING(SSprocessing, src)
		to_chat(user, "<span class='notice'>Вы активируете [src].</span>")
		icon_state = "[icon_state]_on"
	else
		STOP_PROCESSING(SSprocessing, src)
		to_chat(user, "<span class='notice'>Вы останавливаете тиканье [src].</span>")
		icon_state = initial(icon_state)

/obj/structure/destructible/clockwork/trap/trigger/repeater/process()
	activate()
	playsound(src, 'sound/items/screwdriver2.ogg', 25, FALSE)

/obj/structure/destructible/clockwork/trap/trigger/repeater/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

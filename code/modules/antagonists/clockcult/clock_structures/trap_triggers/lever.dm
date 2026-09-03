//Lever: Do I really need to explain this?
/obj/structure/destructible/clockwork/trap/trigger/lever
	name = "lever"
	desc = "Причудливый рычаг, сделанный из дерева и покрытый латунью."
	clockwork_desc = "Необычный рычаг, который активируется при потягивании."
	max_integrity = 75
	icon_state = "lever"

/obj/structure/destructible/clockwork/trap/trigger/lever/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	user.visible_message("<span class='notice'>[user] тянет [src]!</span>", "<span class='notice'>Вы тянете [src]. Он щелкает, а затем снова поднимается вверх.</span>")
	if(wired_to.len)
		audible_message("<i>Вы слышите лязг шестеренок.</i>")
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
	activate()

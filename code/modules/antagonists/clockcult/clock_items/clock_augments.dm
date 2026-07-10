//This file is for snowflakey clock augmentations and clock-themed cybernetic implants.

//The base clockie arm implant, which only clock cultist can use unless it is emagged. THIS SHOULD NEVER ACTUALLY EXIST
/obj/item/organ/cyberimp/arm/clockwork
	name = "clock-themed arm-mounted implant"
	var/clockwork_desc = "По словам Ратвара, такого вообще не должно быть. Немедленно сообщите об этом ему."
	syndicate_implant = TRUE
	icon_state = "toolkit_implant"

/obj/item/organ/cyberimp/arm/clockwork/ui_action_click()
	if(is_servant_of_ratvar(owner) || (obj_flags & EMAGGED)) //If you somehow manage to steal a clockie's implant AND have an emag AND manage to get it implanted for yourself, good on ya!
		return ..()
	to_chat(owner, "<span class='warning'>Имплант отказывается активироваться...</span>")

/obj/item/organ/cyberimp/arm/clockwork/examine(mob/user)
	if((is_servant_of_ratvar(user) || isobserver(user)) && clockwork_desc)
		desc = clockwork_desc
	. = ..()
	desc = initial(desc)

/obj/item/organ/cyberimp/arm/clockwork/emag_act()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>Вы емагнули [src], в надежде, что это принесет какой-то результат...</span>")

//Brass claw implant. Holds the brass claw from brass_claw.dm and can extend / retract it at will.
/obj/item/organ/cyberimp/arm/clockwork/claw
	name = "brass claw implant"
	desc = "Ух ты, этот крюк выглядит чертовски острым."
	clockwork_desc = "Этот имплант, установленный в руку слуги, позволяет ему по желанию выдвигать и втягивать коготь, хотя это сопровождается легкой болью. У всех, кто не является слугой, он не будет работать."
	contents = newlist(/obj/item/clockwork/brass_claw)

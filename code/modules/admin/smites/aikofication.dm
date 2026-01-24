/// Fires an absurd amount of bullets at the target
/datum/smite/aikofication
	name = "Aikofication"

/datum/smite/aikofication/effect(client/user, mob/living/target)
	. = ..()
	if(!ishuman(target))
		alert(usr, "ERROR: This doesn't look like a human now, does it?")
		return
	var/mob/living/carbon/human/human_target = target
	switch(input(usr, "What to do now<br>The GLOBAL currently contains [GLOB.dna_for_copying ? GLOB.dna_for_copying.real_name : "Nothing"]", "Setting appearance") as null|anything in list("Save", "Load"))
		if("Save")
			if(!GLOB.dna_for_copying || !istype(GLOB.dna_for_copying, /datum/dna))
				GLOB.dna_for_copying = new
			human_target.dna.copy_dna(GLOB.dna_for_copying)
			message_admins("[key_name(human_target)]'s dna has been saved into the punishment buffer.")
		if("Load")
			if(!GLOB.dna_for_copying || !istype(GLOB.dna_for_copying, /datum/dna))
				alert(usr, "ERROR: There's nothing to copy!")
				return
			var/old_name = human_target.real_name
			GLOB.dna_for_copying.transfer_identity(human_target, TRUE)
			human_target.real_name = human_target.dna.real_name
			var/obj/item/pda/worn = human_target.wear_id
			var/obj/item/card/id/W = human_target.wear_id?.GetID()
			if(W)
				W.registered_name = human_target.real_name
				W.update_label()
				if(worn)
					if(istype(worn, /obj/item/pda))
						worn.owner = W.registered_name
						worn.update_label()
			human_target.updateappearance(mutcolor_update=1)
			human_target.domutcheck()
			human_target.visible_message("[old_name] transforms into [human_target.real_name]")
			message_admins("[key_name(human_target)]'s dna has been loaded from the punishment buffer.")

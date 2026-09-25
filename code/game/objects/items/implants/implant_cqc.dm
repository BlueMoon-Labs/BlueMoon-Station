/obj/item/implant/cqc
	name = "CQC implant"
	desc = "Grants holder CQC martial art skills."
	activated = 0
	var/datum/martial_art/cqc/style = new

/obj/item/implant/cqc/get_data()
	var/dat = {"<b>Implant Specifications:</b><BR>
				<b>Name:</b> Nanotrasen CQC Implant<BR>
				<b>Implant Details:</b> Teaches the host the arts of CQC.<BR>"}
	return dat

/obj/item/implant/cqc/implant(mob/living/target, mob/user, silent = FALSE)
	if(..())
		if(target.mind && !target.mind.has_martialart(MARTIALART_CQC))
			style.teach(target, TRUE)
		return TRUE
	return FALSE

/obj/item/implanter/cqc
	name = "Implanter (CQC)"
	imp_type = /obj/item/implant/cqc

/obj/item/implantcase/cqc
	name = "implant case - 'CQC'"
	desc = "A glass case containing an CQC implant."
	imp_type = /obj/item/implant/cqc

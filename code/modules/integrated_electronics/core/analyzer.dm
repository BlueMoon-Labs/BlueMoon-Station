/obj/item/integrated_electronics/analyzer
	name = "circuit analyzer"
	desc = "This tool can scan an assembly and generate code necessary to recreate it in a circuit printer."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "analyzer"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_SMALL

/obj/item/integrated_electronics/analyzer/afterattack(var/atom/A, var/mob/living/user)
	. = ..()
	if(istype(A, /obj/item/electronic_assembly))
		var/saved = "[A.name] analyzed! On circuit printers with cloning enabled, you may use the code below to clone the circuit:<br><br><code>[SScircuit.save_electronic_assembly(A)]</code>"
		if(saved)
			to_chat(user, "<span class='notice'>You scan [A].</span>")
			var/datum/browser/popup = new(user, "circuit_scan", "Circuit Scan", 500, 600)
			popup.set_content(saved)
			popup.open()
		else
			to_chat(user, "<span class='warning'>[A] is not complete enough to be encoded!</span>")

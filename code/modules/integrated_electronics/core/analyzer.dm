/obj/item/integrated_electronics/analyzer
	name = "circuit analyzer"
	desc = "Этот инструмент может просканировать сборку и сгенерировать код, необходимый для ее воспроизведения на принтере схем."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "analyzer"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_SMALL

/obj/item/integrated_electronics/analyzer/afterattack(var/atom/A, var/mob/living/user)
	. = ..()
	if(istype(A, /obj/item/electronic_assembly))
		var/saved = "[A.name] проанализировано! На принтерах схем с включенной функцией клонирования вы можете использовать приведенный ниже код для клонирования схемы:<br><br><code>[SScircuit.save_electronic_assembly(A)]</code>"
		if(saved)
			to_chat(user, "<span class='notice'>Вы сканируете [A].</span>")
			var/datum/browser/popup = new(user, "circuit_scan", "Circuit Scan", 500, 600)
			popup.set_content(saved)
			popup.open()
		else
			to_chat(user, "<span class='warning'>[A] is not complete enough to be encoded!</span>")

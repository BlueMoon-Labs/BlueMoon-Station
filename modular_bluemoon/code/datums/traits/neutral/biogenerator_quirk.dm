/datum/quirk/biogenerator
	name = "Биогенератор"
	desc = "ТОЛЬКО ДЛЯ СИНТЕТИКОВ! Ваш желудок заменён биогенератором, позволяющим получать энергию из пищи. Вместо штатного зарядного кабеля установлен биогенератор."
	value = 0
	gain_text = span_notice("Ваш желудок перестроен под биогенератор.")
	lose_text = span_notice("Биогенератор удалён, восстановлен штатный зарядный кабель.")
	on_spawn_immediate = FALSE

/datum/quirk/biogenerator/on_spawn()
	. = ..()
	if(!isrobotic(quirk_holder))
		to_chat(quirk_holder, span_warning("Все квирки были сброшены, т.к. квирк [src] не подходит виду персонажа."))
		var/list/user_quirks = quirk_holder.roundstart_quirks
		user_quirks -= src
		for(var/datum/quirk/Q as anything in user_quirks)
			qdel(Q)
		qdel(src)
		return
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H))
		return
	var/obj/item/organ/cyberimp/arm/power_cord/cord = locate(/obj/item/organ/cyberimp/arm/power_cord) in H.internal_organs
	if(cord)
		cord.Remove()
		qdel(cord)
	if(!locate(/obj/item/organ/stomach/ipc/biogenerator) in H.internal_organs)
		var/obj/item/organ/stomach/ipc/biogenerator/gen = new()
		gen.Insert(H, 0, FALSE)
	REMOVE_TRAIT(H, TRAIT_NO_PROCESS_FOOD, SPECIES_TRAIT)

/datum/quirk/biogenerator/add()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	var/obj/item/organ/cyberimp/arm/power_cord/cord = locate(/obj/item/organ/cyberimp/arm/power_cord) in H.internal_organs
	if(cord)
		cord.Remove()
		qdel(cord)
	var/obj/item/organ/stomach/ipc/biogenerator/gen = new()
	gen.Insert(H, 0, FALSE)
	REMOVE_TRAIT(H, TRAIT_NO_PROCESS_FOOD, SPECIES_TRAIT)

/datum/quirk/biogenerator/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(!istype(H) || !isrobotic(H))
		return
	var/obj/item/organ/stomach/ipc/biogenerator/gen = locate(/obj/item/organ/stomach/ipc/biogenerator) in H.internal_organs
	if(gen)
		gen.Remove()
		qdel(gen)
	if(!H.getorganslot(ORGAN_SLOT_STOMACH))
		var/stomach_type = H.dna.species.mutantstomach
		if(!stomach_type)
			stomach_type = /obj/item/organ/stomach/ipc
		var/obj/item/organ/stomach/new_stomach = new stomach_type()
		new_stomach.Insert(H, 0, FALSE)
	var/obj/item/organ/cyberimp/arm/power_cord/cord = new()
	cord.Insert(H, 0, FALSE)
	ADD_TRAIT(H, TRAIT_NO_PROCESS_FOOD, SPECIES_TRAIT)

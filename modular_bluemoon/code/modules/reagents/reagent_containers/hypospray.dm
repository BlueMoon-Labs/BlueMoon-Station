/obj/item/reagent_containers/hypospray/medipen/lewdsleepy
	name = "Lewd sleepy medipen"
	desc = "Усыпляющий Автоинъектор. Использовать исключительно в целях воплощения своих сексуальных фантазий. Вы же не хотите, чтобы нас засудили? С любовью, Silver Love Co."
	icon = 'modular_splurt/icons/obj/syringe.dmi'
	lefthand_file = 'modular_splurt/icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'modular_splurt/icons/mob/inhands/equipment/medical_righthand.dmi'
	icon_state = "succupen"
	item_state = "succupen"
	volume = 45
	amount_per_transfer_from_this = 45
	list_reagents = list(
						/datum/reagent/toxin/chloralhydrate = 20,
						/datum/reagent/toxin/mutetoxin = 15,
						/datum/reagent/toxin/staminatoxin = 10,
							)

/obj/item/reagent_containers/hypospray/medipen/lewdsleepy/attack(mob/M, mob/user)
	if(GLOB.master_mode != "Extended")
		to_chat(user, "<span class='warning'>Автоинъектор не функционирует в опасных секторах, какая досада.</span>")
		return
	if(M.client?.prefs.nonconpref != "Yes")
		to_chat(user, "<span class='warning'>Инъекция не удалась, какая досада.</span>")
		return
	..()

/obj/item/reagent_containers/hypospray/medipen/ferrocortex
	name = "ferrocortex injector"
	desc = "Механоинъектор. На этикетке виден логотип компании Cybersun. Внутри есть доза феррокортекса для стабилизации работников-КПБ в критическом состоянии. Не более одной инъекции за короткое время."
	icon_state = "ferrocorpen"
	item_state = "ferrocorpen"
	volume = 12
	amount_per_transfer_from_this = 12
	list_reagents = list(/datum/reagent/medicine/ferrocortex = 12)


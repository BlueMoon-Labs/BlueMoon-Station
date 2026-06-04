
/mob/living/silicon/robot/Login()
	..()
	if(module?.use_private_skin_optional_menu)
		module.show_optional_donator_borg_icon_menu(src, TRUE)
	regenerate_icons()
	show_laws(0)

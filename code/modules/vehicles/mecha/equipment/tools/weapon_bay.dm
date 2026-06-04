/obj/item/mecha_parts/concealed_weapon_bay
	name = "concealed weapon bay"
	desc = "Отсек, позволяющий небоевому экзокостюму экипировать одно оружие, скрывая его от посторонних глаз."
	icon = 'icons/mecha/mecha_equipment.dmi'
	icon_state = "mecha_weapon_bay"

/obj/item/mecha_parts/concealed_weapon_bay/try_attach_part(mob/user, obj/vehicle/sealed/mecha/M)
	if(istype(M, /obj/vehicle/sealed/mecha/combat))
		to_chat(user, "<span class='warning'>[M] can already hold weapons!</span>")
		return
	if(locate(/obj/item/mecha_parts/concealed_weapon_bay) in M.contents)
		to_chat(user, "<span class='warning'>[M] already has a concealed weapon bay!</span>")
		return
	..()

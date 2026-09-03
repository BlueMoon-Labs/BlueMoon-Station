/obj/item/sensor_device
	name = "Handheld Crew Monitor" //Thanks to Gun Hog for the name!
	desc = "A miniature machine that tracks suit sensors across the station."
	icon = 'icons/obj/device.dmi'
	icon_state = "scanner"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	custom_price = PRICE_ABOVE_EXPENSIVE

/obj/item/sensor_device/attack_self(mob/user)
	GLOB.crewmonitor.show(user,src) //Proc already exists, just had to call it

/obj/item/sensor_device_security
	name = "Handheld Security Crew Monitor" //Thanks to Gun Hog for the name!
	desc = "A miniature machine that tracks suit sensors across the station."
	icon = 'icons/obj/device.dmi'
	icon_state = "s_scanner"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT

/obj/item/sensor_device_security/attack_self(mob/user)
	GLOB.crewmonitor_security.show(user,src) //Proc already exists, just had to call it

/obj/item/sensor_device_command
	name = "Handheld Command Crew Monitor" //Thanks to Gun Hog for the name!
	desc = "A miniature machine that tracks suit sensors across the station."
	icon = 'icons/obj/device.dmi'
	icon_state = "c_scanner"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT


/obj/item/sensor_device_command/attack_self(mob/user)
	GLOB.crewmonitor_command.show(user,src) //Proc already exists, just had to call it

/obj/item/sensor_device_siege
	name = "PACT Siege Defender Monitor"
	desc = "A handheld device that tracks suit sensors of registered InteQ defenders on the siege battlefield."
	icon = 'icons/obj/device.dmi'
	icon_state = "s_scanner"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT

/obj/item/sensor_device_siege/attack_self(mob/user)
	GLOB.crewmonitor_siege.show(user, src)

/obj/item/clothing/suit/armor/mark45_armor
	var/hudhealth_overlay_icon_state = "hudhealth"
	var/hudhealth_overlay_icon = "hudhealth_hardcrit"
	var/hudhealth_overlay_old_icon_state = ""
	var/mutable_appearance/hudhealth_overlay

/obj/item/clothing/suit/armor/mark45_armor/Initialize(mapload)
	hudhealth_overlay = mutable_appearance(mob_overlay_icon, hudhealth_overlay_icon, -13)
	. = ..()

/obj/item/clothing/suit/armor/mark45_armor/equipped(mob/user, slot)
	..()
	if(slot_flags & slot)
		if(iscarbon(user) && user.stat != DEAD)
			user.add_overlay(hudhealth_overlay)
			RegisterSignal(user, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(update_damage), user)

/obj/item/clothing/suit/armor/mark45_armor/dropped(mob/user)
	..()
	user.cut_overlay(hudhealth_overlay)
	UnregisterSignal(user, COMSIG_CARBON_UPDATEHEALTH)

/obj/item/clothing/suit/armor/mark45_armor/proc/update_damage(mob/living/carbon/user)
	if(user.stat == DEAD)
		return
	var/healthpercent = (user.health/user.maxHealth) * 100
	switch(healthpercent)
		if(100 to INFINITY)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_full"
		if(65 to 100)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_mid"
		if(35 to 65)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_lower"
		if(0 to 25)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_low"
		if(-99 to 0)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_crit"
		else
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_hardcrit"
	if(hudhealth_overlay_old_icon_state != hudhealth_overlay_icon)
		update_healthbar_overlay(user)

/obj/item/clothing/suit/armor/mark45_armor/proc/update_healthbar_overlay(mob/living/carbon/user)
	user.cut_overlay(hudhealth_overlay)
	hudhealth_overlay = mutable_appearance(mob_overlay_icon, hudhealth_overlay_icon, -13)
	hudhealth_overlay_old_icon_state = hudhealth_overlay_icon
	user.add_overlay(hudhealth_overlay)
	user.update_icon(UPDATE_OVERLAYS)

//////////////////// КОД ДЛЯ БРОНИ ХОСА \\\\\\\\\\\\\\\\\\\\\\

/obj/item/clothing/suit/armor/hos/mark45_armor_officer
	var/hudhealth_overlay_icon_state = "hudhealth"
	var/hudhealth_overlay_icon = "hudhealth_hardcrit"
	var/hudhealth_overlay_old_icon_state = ""
	var/mutable_appearance/hudhealth_overlay

/obj/item/clothing/suit/armor/hos/mark45_armor_officer/Initialize(mapload)
	hudhealth_overlay = mutable_appearance(mob_overlay_icon, hudhealth_overlay_icon, -13)
	. = ..()

/obj/item/clothing/suit/armor/hos/mark45_armor_officer/equipped(mob/user, slot)
	..()
	if(slot_flags & slot)
		if(iscarbon(user) && user.stat != DEAD)
			user.add_overlay(hudhealth_overlay)
			RegisterSignal(user, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(update_damage), user)

/obj/item/clothing/suit/armor/hos/mark45_armor_officer/dropped(mob/user)
	..()
	user.cut_overlay(hudhealth_overlay)
	UnregisterSignal(user, COMSIG_CARBON_UPDATEHEALTH)

/obj/item/clothing/suit/armor/hos/mark45_armor_officer/proc/update_damage(mob/living/carbon/user)
	if(user.stat == DEAD)
		return
	var/healthpercent = (user.health/user.maxHealth) * 100
	switch(healthpercent)
		if(100 to INFINITY)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_full"
		if(65 to 100)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_mid"
		if(35 to 65)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_lower"
		if(0 to 25)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_low"
		if(-99 to 0)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_crit"
		else
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_hardcrit"
	if(hudhealth_overlay_old_icon_state != hudhealth_overlay_icon)
		update_healthbar_overlay(user)

/obj/item/clothing/suit/armor/hos/mark45_armor_officer/proc/update_healthbar_overlay(mob/living/carbon/user)
	user.cut_overlay(hudhealth_overlay)
	hudhealth_overlay = mutable_appearance(mob_overlay_icon, hudhealth_overlay_icon, -13)
	hudhealth_overlay_old_icon_state = hudhealth_overlay_icon
	user.add_overlay(hudhealth_overlay)
	user.update_icon(UPDATE_OVERLAYS)

//////////////////// КОД ДЛЯ БРОНИ БРИГМЕДА \\\\\\\\\\\\\\\\\\\\\\

/obj/item/clothing/suit/armor/brigdoc/mark45_armor
	var/hudhealth_overlay_icon_state = "hudhealth"
	var/hudhealth_overlay_icon = "hudhealth_hardcrit"
	var/hudhealth_overlay_old_icon_state = ""
	var/mutable_appearance/hudhealth_overlay

/obj/item/clothing/suit/armor/brigdoc/mark45_armor/Initialize(mapload)
	hudhealth_overlay = mutable_appearance(mob_overlay_icon, hudhealth_overlay_icon, -13)
	. = ..()

/obj/item/clothing/suit/armor/brigdoc/mark45_armor/equipped(mob/user, slot)
	..()
	if(slot_flags & slot)
		if(iscarbon(user) && user.stat != DEAD)
			user.add_overlay(hudhealth_overlay)
			RegisterSignal(user, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(update_damage), user)

/obj/item/clothing/suit/armor/brigdoc/mark45_armor/dropped(mob/user)
	..()
	user.cut_overlay(hudhealth_overlay)
	UnregisterSignal(user, COMSIG_CARBON_UPDATEHEALTH)

/obj/item/clothing/suit/armor/brigdoc/mark45_armor/proc/update_damage(mob/living/carbon/user)
	if(user.stat == DEAD)
		return
	var/healthpercent = (user.health/user.maxHealth) * 100
	switch(healthpercent)
		if(100 to INFINITY)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_full"
		if(65 to 100)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_mid"
		if(35 to 65)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_lower"
		if(0 to 25)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_low"
		if(-99 to 0)
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_crit"
		else
			hudhealth_overlay_icon = hudhealth_overlay_icon_state + "_hardcrit"
	if(hudhealth_overlay_old_icon_state != hudhealth_overlay_icon)
		update_healthbar_overlay(user)

/obj/item/clothing/suit/armor/brigdoc/mark45_armor/proc/update_healthbar_overlay(mob/living/carbon/user)
	user.cut_overlay(hudhealth_overlay)
	hudhealth_overlay = mutable_appearance(mob_overlay_icon, hudhealth_overlay_icon, -13)
	hudhealth_overlay_old_icon_state = hudhealth_overlay_icon
	user.add_overlay(hudhealth_overlay)
	user.update_icon(UPDATE_OVERLAYS)

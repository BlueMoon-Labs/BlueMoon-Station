//Clockwork armor: High melee protection but weak to lasers
/obj/item/clothing/head/helmet/clockwork
	name = "clockwork helmet"
	desc = "Тяжелый шлем из латуни."
	icon = 'icons/obj/clothing/clockwork_garb.dmi'
	icon_state = "clockwork_helmet"
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDEEARS|HIDEHAIR|HIDEFACE|HIDESNOUT
	mutantrace_variation = STYLE_MUZZLE
	armor = list(MELEE = 50, BULLET = 70, LASER = 50, ENERGY = 50, BOMB = 60, BIO = 0, RAD = 0, FIRE = 100, ACID = 100, MAGIC = 60, WOUND = 65)

/obj/item/clothing/head/helmet/clockwork/Initialize(mapload)
	. = ..()
	ratvar_act()
	GLOB.all_clockwork_objects += src

/obj/item/clothing/head/helmet/clockwork/Destroy()
	GLOB.all_clockwork_objects -= src
	return ..()

/obj/item/clothing/head/helmet/clockwork/ratvar_act()
	if(GLOB.ratvar_awakens)
		armor = getArmor(melee = 100, bullet = 100, laser = 100, energy = 100, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100, magic = 100, wound = 100)
		clothing_flags |= STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
		min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	else if(GLOB.ratvar_approaches)
		armor = getArmor(melee = 70, bullet = 50, laser = 65, energy = 65, bomb = 75, bio = 0, rad = 0, fire = 100, acid = 100,, magic = 70, wound = 75)
		clothing_flags |= STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
		min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	else
		armor = getArmor(melee = 50, bullet = 25, laser = 50, energy = 50, bomb = 50, bio = 0, rad = 0, fire = 50, acid = 100, magic = 60, wound = 50)
		clothing_flags &= ~STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = initial(max_heat_protection_temperature)
		min_cold_protection_temperature = initial(min_cold_protection_temperature)

/obj/item/clothing/head/helmet/clockwork/equipped(mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_HEAD && !is_servant_of_ratvar(user))
		if(!iscultist(user))
			to_chat(user, "<span class='heavy_brass'>\"Эй-эй, это для моих слуг, а не для тебя.\"</span>")
			user.visible_message("<span class='warning'>Как только [user] надевает [src], шлем срывается с [user.ru_ego()] головы!</span>", "<span class='warning'>Шлем срывается с головы, оставляя после себя лишь тошноту!</span>")
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.vomit(20)
		else
			to_chat(user, "<span class='heavy_brass'>\"У тебя в голове дырка? Скоро будет.\"</span>")
			to_chat(user, "<span class='userdanger'>Шлем словно пытается проткнуть тебе голову шипом, пока ты изо всех сил пытаешься его снять!</span>")
			user.emote("realagony")
			user.apply_damage(30, BRUTE, BODY_ZONE_HEAD)
			user.adjustOrganLoss(ORGAN_SLOT_BRAIN, 30)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, dropItemToGround), src, TRUE), 1) //equipped happens before putting stuff on(but not before picking items up), 1). thus, we need to wait for it to be on before forcing it off.

/obj/item/clothing/head/helmet/clockwork/mob_can_equip(M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(equipper && !is_servant_of_ratvar(equipper))
		return FALSE
	return ..()

/obj/item/clothing/suit/armor/clockwork
	name = "clockwork cuirass"
	desc = "Массивная кираса из латуни."
	icon = 'icons/obj/clothing/clockwork_garb.dmi'
	icon_state = "clockwork_cuirass"
	w_class = WEIGHT_CLASS_BULKY
	body_parts_covered = CHEST|GROIN|LEGS
	cold_protection = CHEST|GROIN|LEGS
	heat_protection = CHEST|GROIN|LEGS
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDETAUR
	armor = list(MELEE = 60, BULLET = 70, LASER = 50, ENERGY = 50, BOMB = 60, BIO = 0, RAD = 0, FIRE = 100, ACID = 100, MAGIC = 60, WOUND = 65)
	allowed = list(/obj/item/clockwork, /obj/item/clothing/glasses/wraith_spectacles, /obj/item/clothing/glasses/judicial_visor, /obj/item/mmi/posibrain/soul_vessel, /obj/item/reagent_containers/food/drinks/bottle/holyoil)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC

/obj/item/clothing/suit/armor/clockwork/Initialize(mapload)
	. = ..()
	ratvar_act()
	GLOB.all_clockwork_objects += src

/obj/item/clothing/suit/armor/clockwork/Destroy()
	GLOB.all_clockwork_objects -= src
	return ..()

/obj/item/clothing/suit/armor/clockwork/ratvar_act()
	if(GLOB.ratvar_awakens)
		armor = getArmor(melee = 100, bullet = 100, laser = 100, energy = 100, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100, magic = 100, wound = 100)
		clothing_flags |= STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
		min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	else if(GLOB.ratvar_approaches)
		armor = getArmor(melee = 70, bullet = 50, laser = 65, energy = 65, bomb = 75, bio = 0, rad = 0, fire = 100, acid = 100,, magic = 70, wound = 75)
		clothing_flags |= STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
		min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	else
		armor = getArmor(melee = 50, bullet = 25, laser = 50, energy = 50, bomb = 50, bio = 0, rad = 0, fire = 50, acid = 100, magic = 60, wound = 50)
		clothing_flags &= ~STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = initial(max_heat_protection_temperature)
		min_cold_protection_temperature = initial(min_cold_protection_temperature)

/obj/item/clothing/suit/armor/clockwork/mob_can_equip(M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(equipper && !is_servant_of_ratvar(equipper))
		return FALSE
	return ..()

/obj/item/clothing/suit/armor/clockwork/equipped(mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_OCLOTHING && !is_servant_of_ratvar(user))
		if(!iscultist(user))
			to_chat(user, "<span class='heavy_brass'>\"Эй-эй, это для моих слуг, а не для тебя.\"</span>")
			user.visible_message("<span class='warning'>Как только [user] надевает [src] на себя, кираса срывается с [user.ru_ego()] туловища!</span>", "<span class='warning'>Кираса срывается с туловища, оставляя после себя лишь тошноту!</span>")
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.vomit(20)
		else
			to_chat(user, "<span class='heavy_brass'>\"Эта броня для тебя слишком горячая штучка.\"</span>")
			to_chat(user, "<span class='userdanger'>Кираса извергает языки пламени, обжигая тебя, пока ты изо всех сил пытаешься избавиться от неё!</span>")
			user.emote("realagony")
			user.apply_damage(15, BURN, BODY_ZONE_CHEST)
			user.adjust_fire_stacks(2)
			user.IgniteMob()
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, dropItemToGround), src, TRUE), 1)

/obj/item/clothing/gloves/clockwork
	name = "clockwork gauntlets"
	desc = "Тяжёлые, ударопрочные перчатки с латунным укреплением."
	icon = 'icons/obj/clothing/clockwork_garb.dmi'
	icon_state = "clockwork_gauntlets"
	item_state = "clockwork_gauntlets"
	strip_delay = 50
	equip_delay_other = 30
	body_parts_covered = ARMS
	cold_protection = ARMS
	heat_protection = ARMS
	siemens_coefficient = 0
	permeability_coefficient = 0.05
	resistance_flags = FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 80, BULLET = 70, LASER = 50, ENERGY = 50, BOMB = 60, BIO = 0, RAD = 0, FIRE = 100, ACID = 100, MAGIC = 70, WOUND = 85)

/obj/item/clothing/gloves/clockwork/Initialize(mapload)
	. = ..()
	ratvar_act()
	GLOB.all_clockwork_objects += src

/obj/item/clothing/gloves/clockwork/Destroy()
	GLOB.all_clockwork_objects -= src
	return ..()

/obj/item/clothing/gloves/clockwork/ratvar_act()
	if(GLOB.ratvar_awakens)
		armor = getArmor(melee = 100, bullet = 100, laser = 100, energy = 100, bomb = 100, bio = 100, rad = 100, fire = 100, acid = 100)
		clothing_flags |= STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
		min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	else
		armor = getArmor(melee = 50, bullet = 50, laser = 50, energy = 50, bomb = 50, bio = 0, rad = 0, fire = 50, acid = 100, magic = 50, wound = 50)
		clothing_flags &= ~STOPSPRESSUREDAMAGE
		max_heat_protection_temperature = initial(max_heat_protection_temperature)
		min_cold_protection_temperature = initial(min_cold_protection_temperature)

/obj/item/clothing/gloves/clockwork/mob_can_equip(M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(equipper && !is_servant_of_ratvar(equipper))
		return FALSE
	return ..()

/obj/item/clothing/gloves/clockwork/equipped(mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_GLOVES && !is_servant_of_ratvar(user))
		if(!iscultist(user))
			to_chat(user, "<span class='heavy_brass'>\"Эй-эй, это для моих слуг, а не для тебя.\"</span>")
			user.visible_message("<span class='warning'>Как только [user] надевает [src], перчатки срываются с [user.ru_ego()] рук!</span>", "<span class='warning'>Перчатки срываются с рук, оставляя после себя лишь тошноту!</span>")
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.vomit()
		else
			to_chat(user, "<span class='heavy_brass'>\"Тебе нравилось, что у тебя были руки?\"</span>")
			to_chat(user, "<span class='userdanger'>Перчатки внезапно сжимаются, сдавливая руки, и ты не успеваешь их снять!</span>")
			user.emote("realagony")
			user.apply_damage(7, BRUTE, BODY_ZONE_L_ARM)
			user.apply_damage(7, BRUTE, BODY_ZONE_R_ARM)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, dropItemToGround), src, TRUE), 1)

/obj/item/clothing/shoes/clockwork
	name = "clockwork treads"
	desc = "Промышленные ботинки из латуни. Они очень тяжелые."
	icon = 'icons/obj/clothing/clockwork_garb.dmi'
	icon_state = "clockwork_treads"
	w_class = WEIGHT_CLASS_NORMAL
	strip_delay = 50
	equip_delay_other = 30
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/shoes/clockwork/Initialize(mapload)
	. = ..()
	ratvar_act()
	GLOB.all_clockwork_objects += src

/obj/item/clothing/shoes/clockwork/Destroy()
	GLOB.all_clockwork_objects -= src
	return ..()

/obj/item/clothing/shoes/clockwork/negates_gravity()
	return TRUE

/obj/item/clothing/shoes/clockwork/ratvar_act()
	if(GLOB.ratvar_awakens)
		clothing_flags |= NOSLIP
	else
		clothing_flags &= ~NOSLIP

/obj/item/clothing/shoes/clockwork/mob_can_equip(M, equipper, slot, disable_warning, bypass_equip_delay_self)
	if(equipper && !is_servant_of_ratvar(equipper))
		return FALSE
	return ..()

/obj/item/clothing/shoes/clockwork/equipped(mob/living/user, slot)
	..()
	if(slot == ITEM_SLOT_FEET && !is_servant_of_ratvar(user))
		if(!iscultist(user))
			to_chat(user, "<span class='heavy_brass'>\"Эй-эй, это для моих слуг, а не для тебя.\"</span>")
			user.visible_message("<span class='warning'>Как только [user] надевает [src], ботинки срываются с [user.ru_ego()] ног!</span>", "<span class='warning'>Ботинки срываются с ног, оставляя после себя лишь тошноту!</span>")
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.vomit()
		else
			to_chat(user, "<span class='heavy_brass'>\"Посмотрим, сможешь ли ты танцевать в этом.\"</span>")
			to_chat(user, "<span class='userdanger'>Когда ты пытаешься их снять, подошвы становятся раскаленными!</span>")
			user.emote("realagony")
			user.apply_damage(7, BURN, BODY_ZONE_L_LEG)
			user.apply_damage(7, BURN, BODY_ZONE_R_LEG)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, dropItemToGround), src, TRUE), 1)

/obj/item/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_CONSUME

/obj/item/integrate_amount()
	if(!length(custom_materials))
		return 0
	if(custom_materials[GET_MATERIAL_REF(/datum/material/iron)] || custom_materials[GET_MATERIAL_REF(/datum/material/glass)] || custom_materials[GET_MATERIAL_REF(/datum/material/plastic)] || custom_materials[GET_MATERIAL_REF(/datum/material/titanium)])
		return 1
	return 0

/obj/item/deactivated_swarmer/integrate_amount()
	return 100

/obj/item/gun/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_DAMAGE

/obj/item/soulscythe/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_DAMAGE

/obj/item/storage/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	for(var/obj/item/stored_item in contents)
		SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, stored_item, drop_location(), TRUE)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_CONSUME

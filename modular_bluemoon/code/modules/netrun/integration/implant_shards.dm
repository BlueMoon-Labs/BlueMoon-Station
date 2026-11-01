/// The installed port belongs to its conscious wearer. A removed implant can
/// be loaded on the workbench with the same physical transfer as a cyberdeck.
/datum/netrun_console/implant/insert_shard(obj/item/netrun_shard/new_shard, mob/user)
	var/obj/item/organ/cyberimp/brain/netlink/implant = host
	if(QDELETED(implant) || QDELETED(new_shard) || !isliving(user) || user.incapacitated())
		return FALSE
	if(implant.owner)
		if(!available_to(user))
			return FALSE
	else if(!user.Adjacent(implant))
		return FALSE
	return ..()

/obj/item/organ/cyberimp/brain/netlink/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/netrun_shard))
		console?.insert_shard(item, user)
		return TRUE
	return ..()

/obj/item/organ/cyberimp/brain/netlink/examine(mob/user)
	. = ..()
	. += span_notice("Шард можно подключить через настройки нейролинка или применить к себе, держа его в руке.")
	if(console?.inventory.shard)
		. += span_notice("В разъёме установлен [console.inventory.shard.name].")

/// Applying a shard to oneself reaches the implanted port without exposing the
/// internal organ as a target or allowing a bystander to load somebody's brain.
/obj/item/netrun_shard/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && target == user && iscarbon(user))
		var/mob/living/carbon/wearer = user
		var/obj/item/organ/cyberimp/brain/netlink/implant = wearer.getorganslot("brain_netlink")
		if(istype(implant))
			implant.console?.insert_shard(src, user)
			return
	return ..()

/obj/item/organ/cyberimp/brain/netlink/proc/insert_held_shard(mob/user)
	if(!console?.available_to(user) || console.inventory.shard)
		return FALSE
	var/list/shards = list()
	for(var/obj/item/netrun_shard/shard as anything in user.held_items)
		if(istype(shard))
			shards += shard
	if(!length(shards))
		to_chat(user, span_warning("Возьмите шард в руку, чтобы подключить его к нейролинку."))
		return FALSE
	var/obj/item/netrun_shard/chosen = length(shards) == 1 ? shards[1] : tgui_input_list(user, "Какой шард подключить?", "Нейролинк", shards)
	// Selecting media can yield; both ownership and possession are checked again.
	if(QDELETED(src) || QDELETED(chosen) || !(chosen in user.held_items))
		return FALSE
	return console?.insert_shard(chosen, user)

/datum/hud/dextrous/drone/New(mob/owner)
	..()
	var/atom/movable/screen/inventory/inv_box

	inv_box = new /atom/movable/screen/inventory(null, src)
	inv_box.name = "internal storage"
	inv_box.icon = ui_style
	inv_box.icon_state = "suit_storage"
//	inv_box.icon_full = "template"
	inv_box.screen_loc = ui_drone_storage
	inv_box.slot_id = ITEM_SLOT_DEX_STORAGE
	static_inventory += inv_box

	inv_box = new /atom/movable/screen/inventory(null, src)
	inv_box.name = "head/mask"
	inv_box.icon = ui_style
	inv_box.icon_state = "mask"
//	inv_box.icon_full = "template"
	inv_box.screen_loc = ui_drone_head
	inv_box.slot_id = ITEM_SLOT_HEAD
	static_inventory += inv_box

	for(var/atom/movable/screen/inventory/inv in (static_inventory + toggleable_inventory))
		if(inv.slot_id)
			inv_slots[TOBITSHIFT(inv.slot_id) + 1] = inv
			inv.update_icon()


/datum/hud/dextrous/drone/persistent_inventory_update()
	if(!mymob)
		return
	var/mob/living/simple_animal/drone/D = mymob

	//Хад переживает разрыв клиента: дрон без игрока продолжает обновлять инвентарь,
	//а ветка hud_shown писала прямо в D.client.screen. screen_loc проставляем всегда -
	//он понадобится при следующем логине.
	if(hud_shown)
		var/client/viewer = D.client
		if(D.internal_storage)
			D.internal_storage.screen_loc = ui_drone_storage
			if(viewer)
				viewer.screen += D.internal_storage
		if(D.head)
			D.head.screen_loc = ui_drone_head
			if(viewer)
				viewer.screen += D.head
	else
		if(D.internal_storage)
			D.internal_storage.screen_loc = null
		if(D.head)
			D.head.screen_loc = null

	..()

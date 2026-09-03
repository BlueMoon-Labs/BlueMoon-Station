/obj/item/paper/fluff/jobs/cargo/manifest
	var/order_cost = 0
	var/order_id = 0
	var/errors = 0

/obj/item/paper/fluff/jobs/cargo/manifest/New(atom/A, id, cost)
	..()
	order_id = id
	order_cost = cost

	if(prob(MANIFEST_ERROR_CHANCE))
		errors |= MANIFEST_ERROR_NAME
	if(prob(MANIFEST_ERROR_CHANCE))
		errors |= MANIFEST_ERROR_CONTENTS
	if(prob(MANIFEST_ERROR_CHANCE))
		errors |= MANIFEST_ERROR_ITEM

/obj/item/paper/fluff/jobs/cargo/manifest/proc/is_approved()
	return LAZYLEN(stamp_cache) && !is_denied()

/obj/item/paper/fluff/jobs/cargo/manifest/proc/is_denied()
	return LAZYLEN(stamp_cache) && ("stamp-deny" in stamp_cache)

/datum/supply_order
	var/id
	var/orderer
	var/orderer_rank
	var/orderer_ckey
	var/reason
	var/discounted_pct
	var/datum/supply_pack/pack
	var/datum/bank_account/paying_account
	var/obj/item/coupon/applied_coupon

/datum/supply_order/New(datum/supply_pack/pack, orderer, orderer_rank, orderer_ckey, reason, paying_account, coupon)
	id = SSshuttle.ordernum++
	src.pack = pack
	src.orderer = orderer
	src.orderer_rank = orderer_rank
	src.orderer_ckey = orderer_ckey
	src.reason = reason
	src.paying_account = paying_account
	src.applied_coupon = coupon

/datum/supply_order/proc/generateRequisition(turf/T)
	var/obj/item/paper/requisition_paper = new(T)

	requisition_paper.name = "Requisition Form - #[id] ([pack.name])"
	var/requisition_text = "<h2>[station_name()] Манифест Запроса</h2>"
	requisition_text += "<hr/>"
	requisition_text += "Заказ под Номером #[id]<br/>"
	requisition_text+= "Время Заказа: [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]<br/>"
	requisition_text += "Объект Заказа: [pack.name]<br/>"
	requisition_text += "Ограничения на Доступ: [get_access_desc(pack.access)]<br/>"
	requisition_text += "Приобретено со стороны [orderer]<br/>"
	if(paying_account)
		requisition_text += "Оплачено со стороны [paying_account.account_holder]<br/>"
	requisition_text += "Ранг: [orderer_rank]<br/>"
	requisition_text += "Комментарий: [reason]<br/>"

	requisition_paper.add_raw_text(requisition_text)
	requisition_paper.update_appearance()
	return requisition_paper

/datum/supply_order/proc/generateManifest(obj/container, owner, packname, cost) //generates-the-manifests.
	var/obj/item/paper/fluff/jobs/cargo/manifest/manifest_paper = new(null, id, cost)

	var/station_name = (manifest_paper.errors & MANIFEST_ERROR_NAME) ? new_station_name() : station_name()

	manifest_paper.name = "Shipping Manifest - [packname?"#[id] ([pack.name])":"(Grouped Item Crate)"]"

	var/manifest_text = "<h2>[command_name()] Манифест Отгрузки</h2>"
	manifest_text += "<hr/>"
	if(owner && !(owner == "Cargo"))
		manifest_text += "Прямая покупка у [owner]<br/>"
		manifest_paper.name += " - Приобретено со стороны [owner]"
	manifest_text += "Заказ под Номером #[id]<br/>"
	manifest_text += "Доставить на [station_name]<br/>"
	if(packname)
		manifest_text += "Заказ в виде [packname]<br/>"
	manifest_text += "Содержимое: <br/>"
	manifest_text += "<ul>"
	for(var/atom/movable/AM in container.contents - manifest_paper)
		if((manifest_paper.errors & MANIFEST_ERROR_CONTENTS))
			if(prob(50))
				manifest_text += "<li>[AM.name]</li>"
			else
				continue
		manifest_text += "<li>[AM.name]</li>"
	manifest_text += "</ul>"
	manifest_text += "<h4>Ниже поставьте штамп, подтверждающий получение товара:</h4>"

	manifest_paper.add_raw_text(manifest_text)

	if(manifest_paper.errors & MANIFEST_ERROR_ITEM)
		if(prob(50))
			manifest_paper.errors &= ~MANIFEST_ERROR_ITEM
		else
			var/lost = max(round(container.contents.len / 10), 1)
			while(--lost >= 0)
				qdel(pick(container.contents))


	manifest_paper.update_appearance()
	manifest_paper.forceMove(container)

	if(istype(container, /obj/structure/closet/crate))
		var/obj/structure/closet/crate/C = container
		C.set_manifest(manifest_paper)
		C.update_appearance()
	else
		container.contents += manifest_paper

	return manifest_paper

/datum/supply_order/proc/generate(atom/A)
	var/account_holder
	if(paying_account)
		account_holder = paying_account.account_holder
	else
		account_holder = "Cargo"
	var/obj/structure/closet/crate/C = pack.generate(A, paying_account)
	generateManifest(C, account_holder, pack)
	return C

/datum/supply_order/proc/generateCombo(miscbox, misc_own, misc_contents)
	for (var/I in misc_contents)
		new I(miscbox)
	generateManifest(miscbox, misc_own, "")
	return

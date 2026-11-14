/obj/item/mod/core
	name = "MOD core"
	desc = "Источник питания модульного костюма."
	icon = 'modular_bluemoon/icons/obj/clothing/modsuit/mod_construction.dmi'
	icon_state = "mod-core-standard"
	var/obj/item/mod/control/mod

/obj/item/mod/core/Destroy()
	if(mod?.core == src)
		mod.core = null
	mod = null
	return ..()

/obj/item/mod/core/proc/install(obj/item/mod/control/mod_unit)
	mod = mod_unit
	mod.core = src
	moveToNullspace()

/obj/item/mod/core/proc/charge_source()
	RETURN_TYPE(/obj/item)
	return null

/obj/item/mod/core/proc/charge_amount()
	return 0

/obj/item/mod/core/proc/max_charge_amount()
	return 1

/obj/item/mod/core/proc/add_charge(amount)
	return FALSE

/obj/item/mod/core/proc/subtract_charge(amount)
	return FALSE

/obj/item/mod/core/proc/check_charge(amount)
	return FALSE

/obj/item/mod/core/standard
	name = "MOD standard core"

/obj/item/mod/core/standard/charge_source()
	return mod?.get_cell()

/obj/item/mod/core/standard/charge_amount()
	var/obj/item/stock_parts/cell/cell = charge_source()
	return cell?.charge || 0

/obj/item/mod/core/standard/max_charge_amount()
	var/obj/item/stock_parts/cell/cell = charge_source()
	return cell?.maxcharge || 1

/obj/item/mod/core/standard/add_charge(amount)
	var/obj/item/stock_parts/cell/cell = charge_source()
	return cell?.give(amount)

/obj/item/mod/core/standard/subtract_charge(amount)
	var/obj/item/stock_parts/cell/cell = charge_source()
	if(!cell)
		return FALSE
	cell.charge = max(0, cell.charge - amount)
	return TRUE

/obj/item/mod/core/standard/check_charge(amount)
	return charge_source() && charge_amount() >= amount

/obj/item/mod/control/proc/get_charge()
	return core?.charge_amount() || 0

/obj/item/mod/control/proc/get_charge_percent()
	return core ? PERCENT(get_charge() / core.max_charge_amount()) : 0

/obj/item/mod/control/proc/check_charge(amount)
	return core?.check_charge(amount)

/obj/item/mod/control/proc/subtract_charge(amount)
	if(!core)
		return FALSE
	core.subtract_charge(amount)
	return TRUE

/obj/item/mod/core/infinite
	name = "MOD infinite core"
	desc = "Ядро на фиксиуме, обеспечивающее костюм неограниченной энергией."
	icon_state = "mod-core-infinite"

/obj/item/mod/core/infinite/charge_source()
	return src

/obj/item/mod/core/infinite/charge_amount()
	return INFINITY

/obj/item/mod/core/infinite/max_charge_amount()
	return INFINITY

/obj/item/mod/core/infinite/add_charge(amount)
	return TRUE

/obj/item/mod/core/infinite/subtract_charge(amount)
	return TRUE

/obj/item/mod/core/infinite/check_charge(amount)
	return TRUE

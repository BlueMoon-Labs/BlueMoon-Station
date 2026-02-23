#define EXPIRE_TIMER addtimer(CALLBACK(src, PROC_REF(adjustCharges), -1), charge_expire_time)
#define EXPIRE_TIMER_CHECK if(charge_expire_time) EXPIRE_TIMER

/datum/component/anti_magic
	var/magic = FALSE
	var/holy = FALSE
	var/psychic = FALSE
	var/allowed_slots = ~ITEM_SLOT_BACKPACK
	var/charges = INFINITY
	var/blocks_self = TRUE
	var/charge_expire_time = 0 // Время, через сколько 1 заряд исчерпается. 0 = заряды не тратяться со временем
	var/datum/callback/reaction
	var/datum/callback/expire
	var/datum/callback/on_charges_change

/datum/component/anti_magic/Initialize(_magic = FALSE, _holy = FALSE, _psychic = FALSE, _allowed_slots, _charges, _blocks_self = TRUE, datum/callback/_reaction, datum/callback/_expire, _charge_expire_time, var/datum/callback/_on_charges_change)
	if(isitem(parent))
		RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equip))
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	else if(ismob(parent))
		RegisterSignal(parent, COMSIG_MOB_RECEIVE_MAGIC, PROC_REF(protect))
	else
		return COMPONENT_INCOMPATIBLE

	magic = _magic
	holy = _holy
	psychic = _psychic
	if(_allowed_slots)
		allowed_slots = _allowed_slots
	if(!isnull(_charges))
		charges = _charges
	if(_charge_expire_time > 0)
		charge_expire_time = _charge_expire_time
		EXPIRE_TIMER
	blocks_self = _blocks_self
	reaction = _reaction
	expire = _expire
	on_charges_change = _on_charges_change

/datum/component/anti_magic/proc/on_equip(datum/source, mob/equipper, slot)
	if(!(allowed_slots & slot)) //Check that the slot is valid for antimagic
		UnregisterSignal(equipper, COMSIG_MOB_RECEIVE_MAGIC)
		return
	RegisterSignal(equipper, COMSIG_MOB_RECEIVE_MAGIC, PROC_REF(protect), TRUE)

/datum/component/anti_magic/proc/on_drop(datum/source, mob/user)
	UnregisterSignal(user, COMSIG_MOB_RECEIVE_MAGIC)

/datum/component/anti_magic/proc/protect(datum/source, mob/user, _magic, _holy, _psychic, chargecost = 1, self, list/protection_sources)
	if(((_magic && magic) || (_holy && holy) || (_psychic && psychic)) && (!self || blocks_self))
		protection_sources += parent
		reaction?.Invoke(user, chargecost)
		adjustCharges(-chargecost)
		return COMPONENT_BLOCK_MAGIC

/datum/component/anti_magic/proc/adjustCharges(count, mob/user)
	if(QDELETED(src))
		return
	charges += count
	on_charges_change?.Invoke(user, charges)
	if(charges <= 0)
		expire?.Invoke(user)
		qdel(src)
	else
		EXPIRE_TIMER_CHECK

#undef EXPIRE_TIMER
#undef EXPIRE_TIMER_CHECK

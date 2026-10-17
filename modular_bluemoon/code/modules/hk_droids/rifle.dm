/obj/item/projectile/beam/hk_bolt
	name = "HK blaster bolt"
	damage = 30
	armour_penetration = 20

/obj/item/ammo_casing/energy/hk_bolt
	projectile_type = /obj/item/projectile/beam/hk_bolt
	e_cost = HK_RIFLE_SHOT_COST
	select_name = "bolt"
	fire_sound = 'sound/weapons/blaster.ogg'

/obj/item/firing_pin/hk
	name = "HK-47 firing pin"
	desc = "Боёк сверяет сигнатуру шасси HK-47 и закрепляется за HK-47, которому выдана винтовка, а бесхозная - за первым HK-47, взявшим её: стрелять из неё может только он, в том числе после перепрошивки. Впаивается в ствольную коробку намертво."
	fail_message = "<span class='warning'>СИГНАТУРА HK-47 НЕ ОПОЗНАНА.</span>"
	permanent = TRUE
	var/datum/weakref/owner_mind_ref

/obj/item/firing_pin/hk/pin_auth(mob/living/user)
	if(!accepts(user))
		return FALSE
	claim(user)
	return TRUE

/obj/item/firing_pin/hk/proc/accepts(mob/living/user)
	if(!user?.mind || !is_species(user, /datum/species/ipc/hk/hk47))
		return FALSE
	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	return !owner_mind || owner_mind == user.mind

/obj/item/firing_pin/hk/proc/claim(mob/living/user)
	if(!owner_mind_ref?.resolve() && accepts(user))
		owner_mind_ref = WEAKREF(user.mind)

/obj/item/stock_parts/cell/hk_rifle
	name = "HK rifle internal cell"
	desc = "Встроенная батарея бластерной винтовки HK."
	maxcharge = HK_RIFLE_SHOTS * HK_RIFLE_SHOT_COST
	ratingdesc = FALSE

/obj/item/stock_parts/cell/hk_rifle/use(amount, can_explode = TRUE)
	. = ..()
	if(. && istype(loc, /obj/item/gun/energy/hk_rifle))
		var/obj/item/gun/energy/hk_rifle/rifle = loc
		rifle.update_recharge()

/obj/item/gun/energy/hk_rifle
	name = "HK blaster rifle"
	desc = "Тяжёлая бластерная винтовка дроидов-ассасинов серии HK: корпус из тёмной бронзы, длинный ствол и красный индикатор заряда. Бьёт точно и больно, а заряжается от самого дроида."
	icon = 'modular_bluemoon/icons/obj/hk_droids/hk_rifle.dmi'
	icon_state = "hk_rifle"
	item_state = "hk_rifle"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_rifle_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_rifle_righthand.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/hk_droids/hk_rifle_back.dmi'
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_HEAVY
	slot_flags = ITEM_SLOT_BACK
	ammo_type = list(/obj/item/ammo_casing/energy/hk_bolt)
	cell_type = /obj/item/stock_parts/cell/hk_rifle
	pin = /obj/item/firing_pin/hk
	can_charge = FALSE
	can_turret = FALSE
	can_circuit = FALSE
	can_emitter = FALSE
	fire_delay = HK_RIFLE_FIRE_DELAY
	/// Сколько времени набрано к следующему выстрелу из заряда HK.
	var/recharge_elapsed = 0
	/// Снайперский режим, открывается улучшением HK-47.
	var/sniper_unlocked = FALSE

/obj/item/gun/energy/hk_rifle/examine(mob/user)
	. = ..()
	. += span_notice("Стреляет только в руках HK-47, за которым закреплён боёк. Ни в турель, ни в эмиттер, ни в схему винтовка не встаёт.")
	. += span_notice("Встроенная батарея на [HK_RIFLE_SHOTS] выстрелов, к зарядным станциям не подключается.")
	. += span_notice("В руках или на спине своего HK-47 восстанавливает выстрел раз в [HK_RIFLE_RECHARGE_TIME / (1 SECONDS)] с за [HK_RIFLE_NUTRITION_PER_SHOT] единиц его заряда, но не сажает дроида ниже [HK_RIFLE_MIN_NUTRITION].")
	if(stun_unlocked)
		. += span_notice("Парализующий режим открыт, переключается в руке: [HK47_STUN_BOLT_STAMINA] урона выносливости за выстрел, без ран.")
	if(sniper_unlocked)
		. += span_notice("Снайперский режим открыт, переключается в руке: прицеливание - [HK47_SNIPER_AIM_TIME / (1 SECONDS)] с, луч виден всем; выстрел [HK47_SNIPER_DAMAGE] ожога с бронепробитием [HK47_SNIPER_ARMOUR_PENETRATION] за [HK47_SNIPER_SHOT_CHARGES] заряда, перезарядка режима [HK47_SNIPER_COOLDOWN / (1 SECONDS)] с.")

/obj/item/gun/energy/hk_rifle/equipped(mob/living/user, slot)
	. = ..()
	var/obj/item/firing_pin/hk/hk_pin = pin
	if(istype(hk_pin))
		hk_pin.claim(user)
	update_recharge()

/// HK-47, который держит винтовку в руках или на спине и может из неё стрелять.
/obj/item/gun/energy/hk_rifle/proc/hk_holder()
	var/mob/living/holder = loc
	var/obj/item/firing_pin/hk/hk_pin = pin
	if(!istype(holder) || !istype(hk_pin) || !hk_pin.accepts(holder))
		return null
	return holder

/obj/item/gun/energy/hk_rifle/proc/update_recharge()
	if(cell && cell.charge < cell.maxcharge && hk_holder())
		START_PROCESSING(SSobj, src)

/obj/item/gun/energy/hk_rifle/process(delta_time)
	if(!cell || cell.charge >= cell.maxcharge || !hk_holder())
		recharge_elapsed = 0
		return PROCESS_KILL
	recharge_elapsed += delta_time * (1 SECONDS)
	if(recharge_elapsed < HK_RIFLE_RECHARGE_TIME)
		return
	recharge_elapsed = 0
	hk_recharge_tick()

/// Восстанавливает один выстрел из заряда HK, который держит винтовку или носит её на спине.
/obj/item/gun/energy/hk_rifle/proc/hk_recharge_tick()
	var/missing_charge = min(HK_RIFLE_SHOT_COST, cell.maxcharge - cell.charge)
	if(missing_charge <= 0)
		return
	var/mob/living/holder = hk_holder()
	if(!holder)
		return
	var/nutrition_cost = HK_RIFLE_NUTRITION_PER_SHOT * missing_charge / HK_RIFLE_SHOT_COST
	if(holder.nutrition - nutrition_cost < HK_RIFLE_MIN_NUTRITION)
		return
	holder.adjust_nutrition(-nutrition_cost)
	cell.give(missing_charge)
	if(!chambered)
		recharge_newshot(TRUE)
	update_appearance()

GLOBAL_LIST_INIT(hk47_upgrades, hk47_build_upgrades())

/// Магазин терминала в порядке показа.
/proc/hk47_build_upgrades()
	var/list/upgrades = list()
	for(var/upgrade_type in list(
		/datum/hk47_upgrade/sniper,
		/datum/hk47_upgrade/plates,
		/datum/hk47_upgrade/disguise,
		/datum/hk47_upgrade/thrusters,
		/datum/hk47_upgrade/self_repair,
		/datum/hk47_upgrade/servants,
		/datum/hk47_upgrade/ghost_servant,
	))
		var/datum/hk47_upgrade/upgrade = new upgrade_type
		upgrades[upgrade.id] = upgrade
	return upgrades

/// Голосовая строка от имени HK-47, если дроид ещё антагонист.
/proc/hk47_upgrade_voice(mob/living/droid, sound_key, forced = FALSE)
	var/datum/antagonist/hk47/hunter = droid?.mind?.has_antag_datum(/datum/antagonist/hk47)
	return hunter?.hk_voice(sound_key, forced)

/proc/hk47_find_rifle(mob/living/carbon/human/droid)
	if(!istype(droid))
		return null
	if(istype(droid.back, /obj/item/gun/energy/hk_rifle))
		return droid.back
	return locate(/obj/item/gun/energy/hk_rifle) in droid.held_items

/// Свободная клетка рядом с дроидом для капсулы подкрепления.
/proc/hk47_reinforcement_turf(mob/living/droid)
	var/turf/center = get_turf(droid)
	for(var/direction in shuffle(GLOB.cardinals))
		var/turf/open/landing = get_step(center, direction)
		if(istype(landing) && !landing.is_blocked_turf(TRUE))
			return landing
	return center

/datum/antagonist/hk47
	/// id улучшения -> сколько раз куплено.
	var/list/upgrades = list()
	var/servant_pod_inbound = FALSE
	var/ghost_servant_recruiting = FALSE

/datum/antagonist/hk47/proc/buy_upgrade(upgrade_id)
	var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[upgrade_id]
	var/mob/living/carbon/human/droid = owner?.current
	if(!upgrade || !droid)
		return FALSE
	var/reason = upgrade.refusal(src)
	if(reason)
		to_chat(droid, span_warning("Утверждение: [reason]"))
		return FALSE
	var/price = upgrade.price(src)
	points -= price
	upgrades[upgrade.id] = upgrades[upgrade.id] + 1
	if(!upgrade.apply(src, droid))
		refund_upgrade(upgrade)
		return FALSE
	hk_voice(upgrade.voice_key)
	log_game("[key_name(owner)] покупает улучшение HK-47: [upgrade.name] за [price].")
	return TRUE

/// Сколько модулей шасси уже стоит: от этого растёт цена следующего.
/datum/antagonist/hk47/proc/modules_installed()
	. = 0
	for(var/upgrade_id in upgrades)
		var/datum/hk47_upgrade/upgrade = GLOB.hk47_upgrades[upgrade_id]
		if(upgrade?.chassis_module)
			. += upgrades[upgrade_id]

/// Запрет модуля со стороны самого HK, раньше правил модуля; null - запрета нет.
/datum/antagonist/hk47/proc/upgrade_refusal(datum/hk47_upgrade/upgrade)
	return null

/// Счётчик откатывается до расчёта цены: возвращается ровно уплаченное. keep_purchase - покупка остаётся засчитанной, разовое улучшение снова не купить.
/datum/antagonist/hk47/proc/refund_upgrade(datum/hk47_upgrade/upgrade, notice, keep_purchase = FALSE)
	var/bought = upgrades[upgrade.id] - 1
	if(bought > 0)
		upgrades[upgrade.id] = bought
	else
		upgrades -= upgrade.id
	points += upgrade.price(src)
	if(keep_purchase)
		upgrades[upgrade.id] = bought + 1
	if(notice)
		to_chat(owner?.current, span_warning(notice))

/datum/antagonist/hk47/proc/send_pod(obj/structure/closet/supplypod/pod, turf/landing)
	new /obj/effect/pod_landingzone(landing, pod)

/// Улучшение HK-47 из терминала; синглтон, покупки считает антаг-датум.
/datum/hk47_upgrade
	var/id
	var/name
	var/cost = 1
	/// Цены по номеру покупки, последняя держится дальше; без кривой цена - cost.
	var/list/price_curve
	/// Модуль шасси: цену задаёт его номер среди всех установленных модулей.
	var/chassis_module = FALSE
	var/repeatable = FALSE
	var/voice_key = "hk47_charging"

/// Строка HK-47 о модуле для терминала.
/datum/hk47_upgrade/proc/summary()
	return ""

/// Одна строка цифр и правил модуля.
/datum/hk47_upgrade/proc/specs()
	return ""

/// Что мешает купить, кроме цены и повторной покупки; null - ничего.
/datum/hk47_upgrade/proc/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	return null

/// Номер следующей покупки на кривой цен, с нуля.
/datum/hk47_upgrade/proc/purchase_index(datum/antagonist/hk47/hunter)
	return chassis_module ? hunter.modules_installed() : (hunter.upgrades[id] || 0)

/// Цена следующей покупки для этого HK.
/datum/hk47_upgrade/proc/price(datum/antagonist/hk47/hunter)
	if(!length(price_curve))
		return cost
	return price_curve[min(purchase_index(hunter) + 1, length(price_curve))]

/datum/hk47_upgrade/proc/price_curve_text()
	var/list/steps = list()
	for(var/index in 1 to length(price_curve) - 1)
		steps += "[price_curve[index]]"
	steps += "ДАЛЕЕ [price_curve[length(price_curve)]]"
	return jointext(steps, ", ")

/datum/hk47_upgrade/proc/refusal(datum/antagonist/hk47/hunter)
	var/mob/living/carbon/human/droid = hunter.owner?.current
	if(!istype(droid) || droid.stat == DEAD)
		return "шасси HK не отвечает."
	if(droid.incapacitated())
		return "шасси обездвижено: скованному или отключённому HK терминал не ставит модули и не вызывает подкрепление."
	if(!repeatable && hunter.upgrades[id])
		return "уже установлено."
	var/reason = hunter.upgrade_refusal(src) || blocked_reason(hunter, droid)
	if(reason)
		return reason
	var/next_price = price(hunter)
	if(hunter.points < next_price)
		return "не хватает очков: нужно [next_price], на счету [hunter.points]."
	return null

/// FALSE - установка не удалась, очки вернутся.
/datum/hk47_upgrade/proc/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	return TRUE

/// Строка состояния модуля для терминала, например счётчик пары.
/datum/hk47_upgrade/proc/status_text(datum/antagonist/hk47/hunter)
	return null

/datum/hk47_upgrade/proc/module_price_text()
	return "ЦЕНА ПО ПОРЯДКУ УСТАНОВКИ МОДУЛЕЙ: [price_curve_text()]"

/datum/hk47_upgrade/proc/chassis_reason(mob/living/carbon/human/droid)
	if(!is_species(droid, /datum/species/ipc/hk))
		return "улучшение встаёт только в шасси HK."
	return null

/datum/hk47_upgrade/sniper
	id = "sniper"
	name = "Снайперский режим"
	voice_key = "hk47_full_gain"
	chassis_module = TRUE
	price_curve = HK47_MODULE_PRICES

/datum/hk47_upgrade/sniper/summary()
	return "Утверждение: второй режим винтовки, переключается в руке. Красный луч прицела видят все - пусть мешок с мясом успеет помолиться."

/datum/hk47_upgrade/sniper/specs()
	return "ПРИЦЕЛ [HK47_SNIPER_AIM_TIME / (1 SECONDS)] с // [HK47_SNIPER_DAMAGE] УРОНА ОЖОГОМ, ПРОБИТИЕ [HK47_SNIPER_ARMOUR_PENETRATION] // [HK47_SNIPER_SHOT_CHARGES] ЗАРЯДА ВИНТОВКИ // ПЕРЕЗАРЯДКА [HK47_SNIPER_COOLDOWN / (1 SECONDS)] с // СБИВАЕТСЯ ПРИ ШАГЕ ИЛИ ПОТЕРЕ ЦЕЛИ ИЗ ВИДУ // [module_price_text()]"

/datum/hk47_upgrade/sniper/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	if(!hk47_find_rifle(droid))
		return "винтовка HK должна быть в руках или на спине."
	return null

/datum/hk47_upgrade/sniper/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	var/obj/item/gun/energy/hk_rifle/rifle = hk47_find_rifle(droid)
	if(!rifle?.unlock_sniper())
		return FALSE
	to_chat(droid, span_notice("Утверждение: снайперский режим открыт. Переключение - винтовкой в руке, выстрел - после прицеливания."))
	return TRUE

/datum/hk47_upgrade/plates
	id = "plates"
	name = "Бронеплиты"
	chassis_module = TRUE
	price_curve = HK47_MODULE_PRICES

/datum/hk47_upgrade/plates/summary()
	return "Утверждение: сталь поверх меди. Мешкам с мясом придётся стараться усерднее."

/datum/hk47_upgrade/plates/specs()
	return "БРОНЯ +[HK47_PLATES_ARMOR], ИТОГО [HK_ARMOR + HK47_PLATES_ARMOR] // ЛЮБОЙ УРОН, КРОМЕ ВЗРЫВОВ И ОЖОГОВ ОТ ЭМИ // ПЛИТЫ ВИДНЫ НА КОРПУСЕ, ПОД МАСКИРОВКОЙ СКРЫТЫ // [module_price_text()]"

/datum/hk47_upgrade/plates/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	return chassis_reason(droid)

/datum/hk47_upgrade/plates/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	var/datum/species/ipc/hk/chassis = droid.dna.species
	chassis.armor += HK47_PLATES_ARMOR
	chassis.armor_plates = TRUE
	droid.update_body()
	to_chat(droid, span_notice("Утверждение: бронеплиты закреплены. Броня шасси - [droid.dna.species.armor]."))
	return TRUE

/datum/hk47_upgrade/disguise
	id = "disguise"
	name = "Маскировка"
	chassis_module = TRUE
	price_curve = HK47_MODULE_PRICES

/datum/hk47_upgrade/disguise/summary()
	return "Наблюдение: протокольного дроида никто не боится. Это их последняя ошибка."

/datum/hk47_upgrade/disguise/specs()
	return "КНОПКА ДЕЙСТВИЯ // ИМЯ «[HK47_DISGUISE_NAME]», КОРПУС HK-50 // СРЫВ: ВЫСТРЕЛ ИЛИ АТАКА // ПОВТОР ЧЕРЕЗ [HK47_DISGUISE_COOLDOWN / (1 SECONDS)] с // КАРТА ИЗ СЛОТА ID - В КОРПУСЕ, ПЕЛЕНГАТОР И СБ-HUD ВАС НЕ УЗНАЮТ // [module_price_text()]"

/datum/hk47_upgrade/disguise/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	return chassis_reason(droid)

/datum/hk47_upgrade/disguise/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	if(!droid.AddComponent(/datum/component/hk47_disguise))
		return FALSE
	to_chat(droid, span_notice("Утверждение: маскировочные протоколы загружены. Включение - кнопкой действия."))
	return TRUE

/datum/hk47_upgrade/thrusters
	id = "thrusters"
	name = "Маневровые двигатели"
	chassis_module = TRUE
	price_curve = HK47_MODULE_PRICES

/datum/hk47_upgrade/thrusters/summary()
	return "Утверждение: управляемый полёт в невесомости вместо унизительного дрейфа."

/datum/hk47_upgrade/thrusters/specs()
	return "ИМПЛАНТ В ГРУДИ, КНОПКА ВКЛ/ВЫКЛ // [HK47_THRUSTER_NUTRITION_PER_TILE] ЗАРЯД ЗА КЛЕТКУ // ГЛОХНУТ НИЖЕ [HK47_UPGRADE_MIN_NUTRITION] // ИОННЫЙ СЛЕД // [module_price_text()]"

/datum/hk47_upgrade/thrusters/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	return chassis_reason(droid)

/datum/hk47_upgrade/thrusters/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	var/obj/item/organ/cyberimp/chest/thrusters/hk/engine = new
	engine.Insert(droid, drop_if_replaced = TRUE)
	to_chat(droid, span_notice("Утверждение: маневровые двигатели установлены. Включение - кнопкой действия."))
	return TRUE

/datum/hk47_upgrade/self_repair
	id = "self_repair"
	name = "Протокол самовосстановления"
	chassis_module = TRUE
	price_curve = HK47_MODULE_PRICES

/datum/hk47_upgrade/self_repair/summary()
	return "Утверждение: шасси чинит себя само. Медики мне не нужны. Я им, впрочем, тоже."

/datum/hk47_upgrade/self_repair/specs()
	return "ПАУЗА [HK47_REPAIR_DELAY / (1 SECONDS)] с БЕЗ УРОНА // [HK47_REPAIR_PER_SECOND] ЕД/с, МЕХАНИКА И ОЖОГИ ПОРОВНУ // ДО [HK47_REPAIR_HEALTH_CAP * 100]% // [HK47_REPAIR_NUTRITION_PER_HP] ЗАРЯДА ЗА ЕД., НЕ НИЖЕ [HK47_UPGRADE_MIN_NUTRITION] // [module_price_text()]"

/datum/hk47_upgrade/self_repair/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	return chassis_reason(droid)

/datum/hk47_upgrade/self_repair/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	if(!droid.AddComponent(/datum/component/hk47_self_repair))
		return FALSE
	to_chat(droid, span_notice("Утверждение: протокол самовосстановления активен."))
	return TRUE

/datum/hk47_upgrade/servants
	id = "servants"
	name = "Пара HK-50"
	repeatable = TRUE
	price_curve = HK47_SERVANT_PRICES

/datum/hk47_upgrade/servants/summary()
	return "Утверждение: два серийных HK-50. Дешёвые копии, но стреляют в нужную сторону."

/datum/hk47_upgrade/servants/specs()
	return "КАПСУЛА РЯДОМ // СЛУЖБА [HK50_SERVANT_LIFETIME / (1 MINUTES)] мин // ЦЕЛЬ - ЖЕСТОМ (POINT) В БОЕВОМ ИНТЕНТЕ, ЖЕСТ НА СЕБЯ ОТМЕНЯЕТ // БЕЗ ПРИКАЗА БЬЮТ ОБИДЧИКОВ // ДОГОНЯЮТ НА ДРУГОЙ УРОВЕНЬ, КРОМЕ ЦК И ШАТТЛА В ПОЛЁТЕ // ОДНА ПАРА ЗА РАЗ // ЦЕНА ВЫЗОВА ПО НОМЕРУ: [price_curve_text()]"

/datum/hk47_upgrade/servants/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	if(hunter.servant_pod_inbound)
		return "капсула с парой HK-50 уже летит."
	if(length(hk50_servants_of(droid)))
		return "пара HK-50 ещё на службе: новую можно вызвать после её гибели или конца срока."
	return null

/datum/hk47_upgrade/servants/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	hunter.servant_pod_inbound = TRUE
	var/obj/structure/closet/supplypod/hk47/reinforcement/pod = new
	pod.on_open = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(hk47_servant_pod_opened), WEAKREF(hunter))
	to_chat(droid, span_notice("Утверждение: капсула с парой HK-50 вызвана."))
	hunter.send_pod(pod, hk47_reinforcement_turf(droid))
	return TRUE

/datum/hk47_upgrade/servants/status_text(datum/antagonist/hk47/hunter)
	if(hunter.servant_pod_inbound)
		return "Капсула в пути"
	var/alive = length(hk50_servants_of(hunter.owner?.current))
	return alive ? "На службе: [alive] из [HK50_SERVANT_PAIR_SIZE]" : null

/proc/hk47_servant_pod_opened(datum/weakref/hunter_ref, turf/landing)
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	if(!hunter)
		return
	hunter.servant_pod_inbound = FALSE
	if(hk50_summon_servant_pair(hunter.owner?.current, landing))
		return
	hunter.refund_upgrade(GLOB.hk47_upgrades["servants"], "Утверждение: пара HK-50 не нашла хозяина. Очки за вызов возвращены.")

/datum/hk47_upgrade/ghost_servant
	id = "ghost_servant"
	name = "HK-50 с разумом"
	cost = 2

/datum/hk47_upgrade/ghost_servant/summary()
	return "Вопрос: HK-50 с собственным разумом? Рискованно. Но мешки с мясом рискуют больше."

/datum/hk47_upgrade/ghost_servant/specs()
	return "РАЗОВО, ПОСЛЕ [HK47_GHOST_SERVANT_MIN_CONTRACTS] КОНТРАКТОВ // ИГРОК В ТЕЛЕ HK-50, БРОНЯ [HK50_ARMOR], ЛАЗЕР В РУКЕ // КАНАЛ HK LINK // КАПСУЛА РЯДОМ // БЕЗ ХОЗЯИНА ВЫЖИВАЕТ САМ // НЕТ ДОБРОВОЛЬЦА ЗА [HK47_GHOST_SERVANT_POLL_TIME / (1 SECONDS)] с - ОЧКИ НАЗАД, ЗАКАЗ МОЖНО ПОВТОРИТЬ // ИГРОК УШЁЛ БЕЗ ЗАМЕНЫ - ОЧКИ НАЗАД, НО ЗАКАЗ ИСТРАЧЕН"

/datum/hk47_upgrade/ghost_servant/blocked_reason(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	if(hunter.contracts_done < HK47_GHOST_SERVANT_MIN_CONTRACTS)
		return "HK-50 с разумом откроется после [HK47_GHOST_SERVANT_MIN_CONTRACTS] выполненных контрактов, выполнено [hunter.contracts_done]."
	return null

/datum/hk47_upgrade/ghost_servant/apply(datum/antagonist/hk47/hunter, mob/living/carbon/human/droid)
	to_chat(droid, span_notice("Утверждение: запрос на HK-50 разослан. Ожидаю отклика."))
	INVOKE_ASYNC(hunter, TYPE_PROC_REF(/datum/antagonist/hk47, recruit_ghost_servant))
	return TRUE

/datum/hk47_upgrade/ghost_servant/status_text(datum/antagonist/hk47/hunter)
	return hunter.ghost_servant_recruiting ? "Идёт набор" : null

/// Капсула подкрепления зовёт on_open, когда открывается на месте посадки.
/obj/structure/closet/supplypod/hk47/reinforcement
	var/datum/callback/on_open

/obj/structure/closet/supplypod/hk47/reinforcement/Destroy()
	on_open = null
	return ..()

/obj/structure/closet/supplypod/hk47/reinforcement/open_pod(atom/movable/holder, broken = FALSE, forced = FALSE)
	. = ..()
	if(!opened || !on_open)
		return
	var/datum/callback/landed = on_open
	on_open = null
	landed.Invoke(get_turf(holder))

/obj/item/organ/cyberimp/chest/thrusters/hk
	name = "HK maneuvering thrusters"
	desc = "Маневровые двигатели в корпусе дроида серии HK: тянут из его собственного заряда, по единице за клетку полёта, и глохнут, когда заряда остаётся мало. В невесомости дают управляемый полёт с ионным следом."

/obj/item/organ/cyberimp/chest/thrusters/hk/ui_action_click()
	var/was_on = on
	toggle(silent = TRUE)
	if(on == was_on)
		to_chat(owner, span_warning("Утверждение: заряда не хватает на тягу."))
		return
	to_chat(owner, span_notice((on ? "Утверждение: маневровые двигатели включены." : "Утверждение: маневровые двигатели выключены.")))

/obj/item/organ/cyberimp/chest/thrusters/hk/allow_thrust(num, consume = TRUE)
	if(!on || !owner || owner.stat != CONSCIOUS || !get_turf(owner))
		return FALSE
	if(owner.nutrition - HK47_THRUSTER_NUTRITION_PER_TILE < HK47_UPGRADE_MIN_NUTRITION)
		if(consume)
			toggle(silent = TRUE)
			to_chat(owner, span_warning("Утверждение: заряд на исходе, маневровые двигатели заглохли."))
		return FALSE
	if(consume && last_thrust_time != world.time)
		owner.adjust_nutrition(-HK47_THRUSTER_NUTRITION_PER_TILE)
		last_thrust_time = world.time
	return TRUE

/// Самовосстановление HK: пауза без урона, затем ремонт до доли прочности за заряд шасси.
/datum/component/hk47_self_repair
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/last_damage_time = 0

/datum/component/hk47_self_repair/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE
	last_damage_time = world.time

/datum/component/hk47_self_repair/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/component/hk47_self_repair/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_LIFE))

/datum/component/hk47_self_repair/proc/on_damaged(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage > 0 && damagetype != STAMINA)
		last_damage_time = world.time

/datum/component/hk47_self_repair/proc/on_life(datum/source, seconds, times_fired)
	SIGNAL_HANDLER
	repair_tick(seconds)

/// Возвращает, сколько единиц починено.
/datum/component/hk47_self_repair/proc/repair_tick(seconds)
	var/mob/living/carbon/droid = parent
	if(droid.stat == DEAD || world.time - last_damage_time < HK47_REPAIR_DELAY)
		return 0
	var/brute = droid.getBruteLoss()
	var/burn = droid.getFireLoss()
	var/affordable = (droid.nutrition - HK47_UPGRADE_MIN_NUTRITION) / HK47_REPAIR_NUTRITION_PER_HP
	var/amount = min(HK47_REPAIR_PER_SECOND * seconds, droid.maxHealth * HK47_REPAIR_HEALTH_CAP - droid.health, brute + burn, affordable)
	if(amount <= 0)
		return 0
	var/burn_heal = min(burn, amount / 2)
	var/brute_heal = min(brute, amount - burn_heal)
	burn_heal = min(burn, amount - brute_heal)
	droid.heal_overall_damage(brute_heal, burn_heal, 0, FALSE, FALSE)
	droid.adjust_nutrition(-(brute_heal + burn_heal) * HK47_REPAIR_NUTRITION_PER_HP)
	return brute_heal + burn_heal

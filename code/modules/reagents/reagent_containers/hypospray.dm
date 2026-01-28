/obj/item/reagent_containers/hypospray
	name = "hypospray"
	desc = "Гипоспрей компании DeForest Medical Corporation - стерильный, воздушный инъектор. Предназначендля экстренного введения препаратов пациентам."
	icon = 'icons/obj/syringe.dmi'
	item_state = "hypo"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	icon_state = "hypo"
	amount_per_transfer_from_this = 5
	volume = 30
	possible_transfer_amounts = list()
	resistance_flags = ACID_PROOF
	reagent_flags = OPENCONTAINER
	slot_flags = ITEM_SLOT_BELT
	var/ignore_flags = 0
	var/infinite = FALSE

/obj/item/reagent_containers/hypospray/Initialize(mapload, vol)
	. = ..()
	register_item_context()

/obj/item/reagent_containers/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	. = ..()
	if(iscarbon(target))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Inject")
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/reagent_containers/hypospray/attack_paw(mob/user)
	return attack_hand(user)

/obj/item/reagent_containers/hypospray/attack(mob/living/M, mob/user)
	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return
	if(!iscarbon(M))
		return

	//Always log attemped injects for admins
	var/list/injected = list()
	for(var/datum/reagent/R in reagents.reagent_list)
		injected += R.name
	var/contained = english_list(injected)
	log_combat(user, M, "attempted to inject", src, "([contained])")

	if(reagents.total_volume && (ignore_flags || M.can_inject(user, 1))) // Ignore flag should be checked first or there will be an error message.
		to_chat(M, "<span class='warning'>Вы ощущаете лёгкий укол!</span>")
		to_chat(user, "<span class='notice'>Вы сделали инъекцию [M] при помощи [src].</span>")
		playsound(loc, 'sound/items/medi/hypo.ogg', 80, 0)

		var/fraction = min(amount_per_transfer_from_this/reagents.total_volume, 1)
		reagents.reaction(M, INJECT, fraction)
		if(M.reagents)
			var/trans = 0
			if(!infinite)
				trans = reagents.trans_to(M, amount_per_transfer_from_this, log = "hypospray injection")
			else
				trans = reagents.copy_to(M, amount_per_transfer_from_this)

			to_chat(user, "<span class='notice'>[trans]u введено. [reagents.total_volume]u осталось в [src].</span>")


			log_combat(user, M, "injected", src, "([contained])")

/obj/item/reagent_containers/hypospray/CMO
	list_reagents = list(/datum/reagent/medicine/omnizine = 30)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/item/reagent_containers/hypospray/combat
	name = "combat stimulant injector"
	desc = "Модифицированный пневматический игольный автоинъектор для поддержки оперативников. Нацелен на быстрое закрытие ран в бою и возвращение солдат в строй."
	amount_per_transfer_from_this = 10
	item_state = "combat_hypo"
	icon_state = "combat_hypo"
	volume = 100
	ignore_flags = 1 // So they can heal their comrades.
	list_reagents = list(/datum/reagent/medicine/epinephrine = 30, /datum/reagent/medicine/lesser_syndicate_nanites = 40, /datum/reagent/medicine/leporazine = 15, /datum/reagent/medicine/atropine = 15)

/obj/item/reagent_containers/hypospray/combat/omnizine // owned idiot
	desc = "Модифицированный пневматический игольный автоинъектор, используется недофинансированными военными частями для латания ран в бою и выковыливания прочь из боя."
	volume = 90
	list_reagents = list(/datum/reagent/medicine/epinephrine = 30, /datum/reagent/medicine/omnizine = 30, /datum/reagent/medicine/leporazine = 15, /datum/reagent/medicine/atropine = 15)

/obj/item/reagent_containers/hypospray/combat/nanites
	name = "experimental combat stimulant injector"
	desc = "Модифицированный пневматический игольный автоинъектор для использования в боевых условиях. Заполнен экспериментальными мед-нанитами и стимуляторами для быстрого лечения и повышения эффективности в условиях боя."
	item_state = "nanite_hypo"
	icon_state = "nanite_hypo"
	volume = 100
	list_reagents = list(/datum/reagent/medicine/adminordrazine/quantum_heal = 80, /datum/reagent/medicine/synaptizine = 20)

/obj/item/reagent_containers/hypospray/combat/nanites/update_icon()
	. = ..()
	if(reagents.total_volume > 0)
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]0"

/obj/item/reagent_containers/hypospray/combat/heresypurge
	name = "holy water piercing injector"
	desc = "Модифицированный пневматический игольный автоинъектор для использования в боевых условиях. Заполнен пятью дозами святой воды и пацифицирующей смесью. Не используйте на своих товарищах."
	item_state = "holy_hypo"
	icon_state = "holy_hypo"
	volume = 250
	list_reagents = list(/datum/reagent/water/holywater = 150, /datum/reagent/peaceborg_tire = 50, /datum/reagent/peaceborg_confuse = 50)
	amount_per_transfer_from_this = 50

//MediPens

/obj/item/reagent_containers/hypospray/medipen
	name = "epinephrine medipen"
	desc = "Стремительный и стабильный способ стабилизации пациентов в критическом состоянии для экипажа без знаний медицины. Содержит сильный консервант, способный задерживать разложение мёртвого тела."
	icon_state = "medipen"
	item_state = "medipen"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	amount_per_transfer_from_this = 15
	volume = 15
	ignore_flags = 1 //so you can medipen through hardsuits
	reagent_flags = DRAWABLE
	flags_1 = null
	list_reagents = list(/datum/reagent/medicine/epinephrine = 10, /datum/reagent/preservahyde = 3, /datum/reagent/medicine/coagulant = 2)
	custom_premium_price = PRICE_ALMOST_EXPENSIVE

/obj/item/reagent_containers/hypospray/medipen/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] начинает давиться [src]! Похоже, [user.ru_who()] пытаются совершить суицид!</span>")
	return OXYLOSS//ironic. he could save others from oxyloss, but not himself.

/obj/item/reagent_containers/hypospray/medipen/attack(mob/M, mob/user)
	if(!reagents.total_volume)
		to_chat(user, "<span class='warning'>[src] пуст!</span>")
		return
	..()
	if(!iscyborg(user))
		reagents.maximum_volume = 0 //Makes them useless afterwards
		reagent_flags = NONE
	update_icon()
	addtimer(CALLBACK(src, PROC_REF(cyborg_recharge), user), 80)

/obj/item/reagent_containers/hypospray/medipen/attack_self()
	attack(usr, usr)

/obj/item/reagent_containers/hypospray/medipen/proc/cyborg_recharge(mob/living/silicon/robot/user)
	if(!reagents.total_volume && iscyborg(user))
		var/mob/living/silicon/robot/R = user
		if(R.cell.use(100))
			reagents.add_reagent_list(list_reagents)
			update_icon()

/obj/item/reagent_containers/hypospray/medipen/update_icon_state()
	if(reagents.total_volume > 0)
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]0"

/obj/item/reagent_containers/hypospray/medipen/examine()
	. = ..()
	if(reagents && reagents.reagent_list.len)
		. += "<span class='notice'>Заряжен и готов к применению.</span>"
	else
		. += "<span class='notice'>Потрачен!</span>"

/obj/item/reagent_containers/hypospray/medipen/ekit
	name = "emergency first-aid autoinjector"
	desc = "Эпинефриновый медипен. Содержит дозу коагулянта и антибиотиков для стабилизации тяжёлых травм и ожогов."
	icon_state = "healthpen"
	item_state = "healthpen"
	volume = 15
	amount_per_transfer_from_this = 15
	list_reagents = list(/datum/reagent/medicine/epinephrine = 12, /datum/reagent/medicine/coagulant = 2.5, /datum/reagent/medicine/spaceacillin = 0.5)

/obj/item/reagent_containers/hypospray/medipen/blood_loss
	name = "hypovolemic-response autoinjector"
	desc = "Медипен для стабилизации пациента и обращения последствий тяжёлых кровопотерь."
	icon_state = "hypovolemic"
	item_state = "hypovolemic"
	volume = 15
	amount_per_transfer_from_this = 15
	list_reagents = list(/datum/reagent/medicine/epinephrine = 5, /datum/reagent/medicine/coagulant = 2.5, /datum/reagent/iron = 3.5, /datum/reagent/medicine/salglu_solution = 4)

/obj/item/reagent_containers/hypospray/medipen/stimulants
	name = "stimpack medipen"
	desc = "Содержит стимуляторы."
	icon_state = "syndipen"
	item_state = "syndipen"
	volume = 50
	amount_per_transfer_from_this = 50
	list_reagents = list(/datum/reagent/medicine/stimulants = 50)

/obj/item/reagent_containers/hypospray/medipen/stimulants/baseball
	name = "the reason the syndicate major league team wins"
	desc = "Говорят, химия никогда не решает, но, посмотри где ты сейчас, а потом - где они."
	icon_state = "baseballstim"
	volume = 50
	amount_per_transfer_from_this = 50
	list_reagents = list(/datum/reagent/medicine/stimulants = 50)

/obj/item/reagent_containers/hypospray/medipen/stimpack //goliath kiting
	name = "stimpack medipen"
	desc = "Способ быстрой стимуляции организм на выброс адреналина, позволяя двигаться свободнее в сковывающей броне."
	icon_state = "stimpen"
	item_state = "stimpen"
	volume = 20
	amount_per_transfer_from_this = 20
	list_reagents = list(/datum/reagent/medicine/ephedrine = 10, /datum/reagent/consumable/coffee = 10)

/obj/item/reagent_containers/hypospray/medipen/stimpack/traitor
	desc = "Модифицированный автоинъектор стимуляторов для боевых условий. Смесь немного затягивает раны пациента."
	list_reagents = list(/datum/reagent/medicine/stimulants = 10, /datum/reagent/medicine/omnizine = 10)

/obj/item/reagent_containers/hypospray/medipen/morphine
	name = "morphine medipen"
	desc = "Быстрый способ выбраться из сложной ситуации! Ценой ощущения сильной заторможенности."
	icon_state = "morphen"
	item_state = "morphen"
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/morphine = 10)

/obj/item/reagent_containers/hypospray/medipen/penacid
	name = "pentetic acid medipen"
	desc = "Автоинъектор с пентеновой кислотой, она же ДТПА, для стабилизации высоких доз радиации и средних интоксикаций."
	icon_state = "penacid"
	item_state = "penacid"
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/pen_acid = 10)

/obj/item/reagent_containers/hypospray/medipen/atropine
	name = "atropine autoinjector"
	desc = "Быстрый способ спасти кого-то в критическом состоянии!"
	icon_state = "atropen"
	item_state = "atropen"
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/atropine = 10)

/obj/item/reagent_containers/hypospray/medipen/salacid
	name = "salicyclic acid medipen"
	desc = "Автоинъектор с салициловой кислотой, для стабилизации тяжелейших травм."
	icon_state = "salacid"
	item_state = "salacid"
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/sal_acid = 10)

/obj/item/reagent_containers/hypospray/medipen/oxandrolone
	name = "oxandrolone medipen"
	desc = "Автоинъектор с оксандролоном, для стабилизации тяжелейших ожогов."
	icon_state = "oxapen"
	item_state = "oxapen"
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/oxandrolone = 10)

/obj/item/reagent_containers/hypospray/medipen/salbutamol
	name = "salbutamol medipen"
	desc = "Автоинъектор с сальбутамолом, для быстрой стабилизации гипоксии любой тяжести."
	icon_state = "salpen"
	item_state = "salpen"
	volume = 10
	amount_per_transfer_from_this = 10
	list_reagents = list(/datum/reagent/medicine/salbutamol = 10)

/obj/item/reagent_containers/hypospray/medipen/tuberculosiscure
	name = "BVAK autoinjector"
	desc = "Автоинъектор \"Bio Virus Antidote Kit\". Имеет две системы: для вас и для кого-то ещё. Применять при инфекционном заражении."
	icon_state = "tbpen"
	item_state = "tbpen"
	volume = 60
	amount_per_transfer_from_this = 30
	list_reagents = list(/datum/reagent/medicine/atropine = 10, /datum/reagent/medicine/epinephrine = 10, /datum/reagent/medicine/salbutamol = 20, /datum/reagent/medicine/spaceacillin = 20)

/obj/item/reagent_containers/hypospray/medipen/tuberculosiscure/update_icon()
	. = ..()
	if(reagents.total_volume > 30)
		icon_state = initial(icon_state)
	else if (reagents.total_volume > 0)
		icon_state = "[initial(icon_state)]1"
	else
		icon_state = "[initial(icon_state)]0"

/obj/item/reagent_containers/hypospray/medipen/survival
	name = "survival medipen"
	desc = "Медипен-инъектор для выживания в самых тяжёлых условиях, лечит и защищает от угроз окружающей среды. ВНИМАНИЕ: не делать более одной инъекции за короткое время."
	icon_state = "minepen"
	item_state = "minepen"
	volume = 52
	amount_per_transfer_from_this = 52
	list_reagents = list(/datum/reagent/medicine/salbutamol = 10, /datum/reagent/medicine/leporazine = 15, /datum/reagent/medicine/neo_jelly = 15, /datum/reagent/medicine/epinephrine = 10, /datum/reagent/medicine/lavaland_extract = 2)

/obj/item/reagent_containers/hypospray/medipen/firelocker
	name = "fire treatment medipen"
	desc = "Медипен-инъектор, наполненный препаратами для лечения ожогов для экипажа без знаний медицины."
	icon_state = "firepen"
	item_state = "firepen"
	volume = 15
	amount_per_transfer_from_this = 15
	list_reagents = list(/datum/reagent/medicine/oxandrolone = 5, /datum/reagent/medicine/kelotane = 10)

/obj/item/reagent_containers/hypospray/medipen/magillitis
	name = "experimental autoinjector"
	desc = "Игольный инъектор ручной работы с одноразовым резервуаром, содержащим экспериментальную смесь. В отличие от привычных инъекторов, не пробивает толстый слой одежды или скафандры и не может быть опустошён без утери содержимого."
	icon_state = "gorillapen"
	item_state = "gorillapen"
	volume = 5
	ignore_flags = 0
	reagent_flags = NONE
	list_reagents = list(/datum/reagent/magillitis = 5)

#define HYPO_SPRAY 0
#define HYPO_INJECT 1

#define WAIT_SPRAY 25
#define WAIT_INJECT 25
#define SELF_SPRAY 15
#define SELF_INJECT 15

#define DELUXE_WAIT_SPRAY 20
#define DELUXE_WAIT_INJECT 20
#define DELUXE_SELF_SPRAY 10
#define DELUXE_SELF_INJECT 10

#define COMBAT_WAIT_SPRAY 15
#define COMBAT_WAIT_INJECT 15
#define COMBAT_SELF_SPRAY 0
#define COMBAT_SELF_INJECT 0

//A vial-loaded hypospray. Cartridge-based!
/obj/item/hypospray/mkii
	name = "hypospray mk.II"
	icon_state = "hypo2"
	icon = 'icons/obj/syringe.dmi'
	desc = "Новая разработка DeForest Medical, этот гипоспрей принимает гипоампулы по 30u и поддерживает функцию быстрой перезарядки."
	w_class = WEIGHT_CLASS_TINY
	var/list/allowed_containers = list(/obj/item/reagent_containers/glass/bottle/vial/tiny, /obj/item/reagent_containers/glass/bottle/vial/small)
	var/mode = HYPO_INJECT
	var/obj/item/reagent_containers/glass/bottle/vial/vial
	var/start_vial = /obj/item/reagent_containers/glass/bottle/vial/small
	var/spawnwithvial = TRUE
	var/inject_wait = WAIT_INJECT
	var/spray_wait = WAIT_SPRAY
	var/spray_self = SELF_SPRAY
	var/inject_self = SELF_INJECT
	var/quickload = FALSE
	var/penetrates = FALSE

/obj/item/hypospray/mkii/brute
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/small/bicaridine

/obj/item/hypospray/mkii/toxin
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/small/antitoxin

/obj/item/hypospray/mkii/oxygen
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/small/dexalin

/obj/item/hypospray/mkii/burn
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/small/kelotane

/obj/item/hypospray/mkii/tricord
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/small/tricord

/obj/item/hypospray/mkii/enlarge
	spawnwithvial = FALSE

/obj/item/hypospray/mkii/CMO
	name = "hypospray mk.II deluxe"
	allowed_containers = list(/obj/item/reagent_containers/glass/bottle/vial/tiny, /obj/item/reagent_containers/glass/bottle/vial/small, /obj/item/reagent_containers/glass/bottle/vial/large)
	icon_state = "cmo2"
	desc = "Deluxe-модель гипроспрея, способная принимать ампулы большого размера. Помимо этого, работает быстре и доставляет больше препаратов за раз."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/large/CMO
	inject_wait = DELUXE_WAIT_INJECT
	spray_wait = DELUXE_WAIT_SPRAY
	spray_self = DELUXE_SELF_SPRAY
	inject_self = DELUXE_SELF_INJECT

/obj/item/hypospray/mkii/CMO/combat
	name = "combat hypospray mk.II"
	desc = "Готовый к бою deluxe-гипоспрей, делающий укол почти мгновенно. Может быть тактически перезаряжен другой ампулой в руках."
	icon_state = "combat2"
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/large/combat
	inject_wait = COMBAT_WAIT_INJECT
	spray_wait = COMBAT_WAIT_SPRAY
	spray_self = COMBAT_SELF_SPRAY
	inject_self = COMBAT_SELF_INJECT
	quickload = TRUE
	penetrates = TRUE

/obj/item/hypospray/mkii/CMO/combat/synthflesh
	name = "Combat Hypospray with Neosynth" // BLUEMOON EDIT
	icon = 'icons/obj/syringe.dmi'
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	mode = HYPO_SPRAY
	item_state = "holy_hypo"
	icon_state = "holy_hypo"
	start_vial = /obj/item/reagent_containers/glass/bottle/vial/large/synthflesh/neo // BLUEMOON EDIT

/obj/item/hypospray/mkii/Initialize(mapload)
	. = ..()
	if(!spawnwithvial)
		update_icon()
		return
	if(start_vial)
		vial = new start_vial
	update_icon()
	register_context()
	register_item_context()

/obj/item/hypospray/mkii/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	// Did you know that clicking something while you're holding it is the same as attack_self()?
	if(vial && (held_item == src))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Убрать [vial]")
	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, "Режим: [mode ? "спрей" : "инъекция"]")
	LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Задать объем передачи")
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/hypospray/mkii/add_item_context(obj/item/source, list/context, atom/target, mob/living/user)
	. = ..()
	if(iscarbon(target))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, mode ? "Инъекция" : "Спрей")
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/hypospray/mkii/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/hypospray/mkii/update_icon_state()
	icon_state = "[initial(icon_state)][vial ? "" : "-e"]"

/obj/item/hypospray/mkii/examine(mob/user)
	. = ..()
	if(vial)
		. += "В [vial] осталось [vial.reagents.total_volume]u."
	else
		. += "Внутри нет ампулы."
	. += span_info("[src] выставлен в режим [mode ? "инъекции" : "спрея тела"] пациента.")

/obj/item/hypospray/mkii/proc/unload_hypo(obj/item/I, mob/user)
	if((istype(I, /obj/item/reagent_containers/glass/bottle/vial)))
		var/obj/item/reagent_containers/glass/bottle/vial/V = I
		V.forceMove(user.loc)
		user.put_in_hands(V)
		to_chat(user, "<span class='notice'>Вы извлекли [vial] из [src].</span>")
		vial = null
		update_icon()
		playsound(loc, 'sound/weapons/empty.ogg', 50, 1)
	else
		to_chat(user, "<span class='notice'>Этот гипоспрей не заряжен!</span>")
		return

/obj/item/hypospray/mkii/attackby(obj/item/I, mob/living/user)
	if((istype(I, /obj/item/reagent_containers/glass/bottle/vial) && vial != null))
		if(!quickload)
			to_chat(user, "<span class='warning'>[src] не может держать больше одной ампулы!</span>")
			return FALSE
		unload_hypo(vial, user)
	if((istype(I, /obj/item/reagent_containers/glass/bottle/vial)))
		var/obj/item/reagent_containers/glass/bottle/vial/V = I
		if(!is_type_in_list(V, allowed_containers))
			to_chat(user, "<span class='notice'>[src] не принимает этот тип ампул.</span>")
			return FALSE
		if(!user.transferItemToLoc(V,src))
			return FALSE
		vial = V
		user.visible_message("<span class='notice'>[user] зарядил ампулу в [src].</span>","<span class='notice'>Вы зарядили [vial] в [src].</span>")
		update_icon()
		playsound(loc, 'sound/weapons/autoguninsert.ogg', 35, 1)
		return TRUE
	else
		to_chat(user, "<span class='notice'>Это не поместится в [src].</span>")
		return FALSE

/obj/item/hypospray/mkii/AltClick(mob/user)
	. = ..()
	if(vial)
		vial.attack_self(user)
		return TRUE

// Gunna allow this for now, still really don't approve - Pooj
/obj/item/hypospray/mkii/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		to_chat(user, "[src], оказывается, уже перегружен.")
		return
	inject_wait = COMBAT_WAIT_INJECT
	spray_wait = COMBAT_WAIT_SPRAY
	spray_self = COMBAT_SELF_INJECT
	inject_self = COMBAT_SELF_SPRAY
	penetrates = TRUE
	to_chat(user, "Вы перегрузили схемы управления [src].")
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	return TRUE

/obj/item/hypospray/mkii/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..() //Don't bother changing this or removing it from containers will break.

/obj/item/hypospray/mkii/attack(obj/item/I, mob/user, params)
	return

/obj/item/hypospray/mkii/afterattack(atom/target, mob/user, proximity)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(attempt_inject), target, user, proximity)

/obj/item/hypospray/mkii/proc/attempt_inject(atom/target, mob/user, proximity)
	if(!vial || !proximity || !isliving(target))
		return
	var/mob/living/L = target

	if(!L.reagents || !L.can_inject(user, TRUE, user.zone_selected, penetrates))
		return

	var/obj/item/bodypart/affecting = L.get_bodypart(check_zone(user.zone_selected))
	if(iscarbon(L))
		if(!affecting)
			to_chat(user, "<span class='warning'>Конечность отсутствует!</span>")
			return
		if(!affecting.is_organic_limb())
			to_chat(user, "<span class='notice'>Препараты не работают на роботических конечностях!</span>")
			return
		else if(!affecting.is_organic_limb(FALSE) && mode != HYPO_INJECT)
			to_chat(user, "<span class='notice'>Биомеханические конечности могут быть обслужены только через их интегрированный порт для инъекций, не спреем!</span>")
			return
	//Always log attemped injections for admins
	var/contained = vial.reagents.log_list()
	log_combat(user, L, "attemped to inject", src, addition="which had [contained]")

	if(!vial)
		to_chat(user, "<span class='notice'>[src] не имеет какой-либо ампулы!</span>")
		return
	if(!vial.reagents.total_volume)
		to_chat(user, "<span class='notice'>Ампула внутри [src] пуста!</span>")
		return

	var/fp_verb = mode == HYPO_SPRAY ? "нанести спрей" : "сделать инъекцию"
	var/method = mode == HYPO_SPRAY ? PATCH : INJECT	//Medsprays use patch when spraying, feels like an inconsistancy here.

	if(L != user)
		L.visible_message("<span class='danger'>[user] пытается [fp_verb] [L] при помощи [src]!</span>", \
						"<span class='userdanger'>[user] пытается [fp_verb] вам при помощи [src]!</span>")
	if(!do_mob(user, L, inject_wait, extra_checks = CALLBACK(L, TYPE_PROC_REF(/mob/living, can_inject), user, FALSE, user.zone_selected, penetrates)))
		return
	if(!vial.reagents.total_volume)
		return
	log_attack("<font color='red'>[user.name] ([user.ckey]) applied [src] to [L.name] ([L.ckey]), which had [contained] (INTENT: [uppertext(user.a_intent)]) (MODE: [mode])</font>")
	if(L != user)
		L.visible_message("<span class='danger'>[user] использует [src] на [L]!</span>", \
						"<span class='userdanger'>[user] использует [src] на вас!</span>")

	var/fraction = min(vial.amount_per_transfer_from_this/vial.reagents.total_volume, 1)
	vial.reagents.reaction(L, method, fraction, affected_bodypart = affecting)
	vial.reagents.trans_to(target, vial.amount_per_transfer_from_this, log = "hypospray fill")
	var/long_sound = vial.amount_per_transfer_from_this >= 15
	playsound(loc, long_sound ? 'sound/items/medi/hypospray_long.ogg' : pick('sound/items/medi/hypospray.ogg','sound/items/medi/hypospray2.ogg'), 50, 1, -1)
	to_chat(user, "<span class='notice'>Вы истратили [vial.amount_per_transfer_from_this]u смеси. Ампула гипоспрея теперь содержит [vial.reagents.total_volume]u.</span>")

/obj/item/hypospray/mkii/attack_self(mob/living/user)
	if(user)
		if(user.incapacitated())
			return
		else if(!vial)
			to_chat(user, "Гипоспрей сначала должен быть заряжен!")
			return
		else
			unload_hypo(vial,user)

/obj/item/hypospray/mkii/CtrlClick(mob/living/user)
	. = ..()
	if(user.canUseTopic(src, FALSE) && user.get_active_held_item(src))
		switch(mode)
			if(HYPO_SPRAY)
				mode = HYPO_INJECT
				to_chat(user, "[src] теперь будет производить инъекции пациенту.")
			if(HYPO_INJECT)
				mode = HYPO_SPRAY
				to_chat(user, "[src] теперь будет спреить участок тела пациента.")
		return TRUE

/obj/item/hypospray/mkii/examine(mob/user)
	. = ..()
	. += "<span class='notice'><b>Ctrl-Click</b> для переключения режима со спрея на инъекции и наоборот.</span>"

#undef HYPO_SPRAY
#undef HYPO_INJECT
#undef WAIT_SPRAY
#undef WAIT_INJECT
#undef SELF_SPRAY
#undef SELF_INJECT
#undef DELUXE_WAIT_SPRAY
#undef DELUXE_WAIT_INJECT
#undef DELUXE_SELF_SPRAY
#undef DELUXE_SELF_INJECT
#undef COMBAT_WAIT_SPRAY
#undef COMBAT_WAIT_INJECT
#undef COMBAT_SELF_SPRAY
#undef COMBAT_SELF_INJECT

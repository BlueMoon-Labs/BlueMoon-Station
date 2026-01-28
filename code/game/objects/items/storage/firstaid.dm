
/* First aid storage
 * Contains:
 *		First Aid Kits
 * 		Pill Bottles
 *		Dice Pack (in a pill bottle)
 */

/*
 * First Aid Kits
 */
/obj/item/storage/firstaid
	name = "first-aid kit"
	desc = "It's an emergency medical kit for those serious boo-boos."
	icon_state = "firstaid"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 3
	throw_range = 7
	var/empty = FALSE

/obj/item/storage/firstaid/regular
	icon_state = "firstaid"
	desc = "Аптечка первой помощи со снаряжением для борьбы с распространнёными видами ранений."

/obj/item/storage/firstaid/regular/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins giving себя aids with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return BRUTELOSS

/obj/item/storage/firstaid/regular/PopulateContents()
	if(empty)
		return
	new /obj/item/stack/medical/gauze(src)
	new /obj/item/stack/medical/suture(src)
	new /obj/item/stack/medical/suture(src)
	new /obj/item/stack/medical/mesh(src)
	new /obj/item/stack/medical/mesh(src)
	new /obj/item/reagent_containers/hypospray/medipen/ekit(src)
	new /obj/item/healthanalyzer(src)

/obj/item/storage/firstaid/emergency
	icon_state = "firstaid-briefcase"
	name = "emergency first-aid kit"
	desc = "Очень простая аптечка для стабилизации серьёзных ран перед полноценным лечением."

/obj/item/storage/firstaid/emergency/PopulateContents()
	if(empty)
		return
	var/static/items_inside = list(
		/obj/item/healthanalyzer/wound = 1,
		/obj/item/stack/medical/gauze = 1,
		/obj/item/stack/medical/suture/emergency = 1,
		/obj/item/stack/medical/ointment = 1,
		/obj/item/reagent_containers/hypospray/medipen/ekit = 2)
	generate_items_inside(items_inside,src)

/obj/item/storage/firstaid/ancient
	name = "ancient first-aid kit"
	icon_state = "oldfirstaid"
	desc = "Аптечка первой помощи со снаряжением для борьбы с распространнёными видами ранений. Один взгляд на неё навеивает мысли о старых добрых деньках."

/obj/item/storage/firstaid/ancient/PopulateContents()
	if(empty)
		return
	new /obj/item/stack/medical/gauze(src)
	new /obj/item/stack/medical/suture(src)
	new /obj/item/stack/medical/suture(src)
	new /obj/item/stack/medical/suture(src)
	new /obj/item/stack/medical/mesh(src)
	new /obj/item/stack/medical/mesh(src)
	new /obj/item/stack/medical/mesh(src)

/obj/item/storage/firstaid/ancient/heirloom
	// Long since been ransacked by hungry powergaming assistants breaking into med storage
	empty = TRUE

/obj/item/storage/firstaid/brute
	name = "trauma treatment kit"
	desc = "Аптечка первой помощи, нужная после знакомства с ящиком с инструментами."
	icon_state = "firstaid-brute"
	item_state = "firstaid-brute"

/obj/item/storage/firstaid/brute/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins beating себя over the head with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return BRUTELOSS

/obj/item/storage/firstaid/brute/PopulateContents()
	if(empty)
		return
	for(var/i in 1 to 4)
		new /obj/item/reagent_containers/pill/patch/styptic(src)
	new /obj/item/reagent_containers/hypospray/medipen/salacid(src)
	new /obj/item/reagent_containers/hypospray/medipen/salacid(src)
	new /obj/item/healthanalyzer(src)

/obj/item/storage/firstaid/fire
	name = "burn treatment kit"
	desc = "Специализированная аптечка, нужная после <i>-случайных-</i> пожаров лабораторий токсинологии."
	icon_state = "firstaid-burn"
	item_state = "firstaid-burn"

/obj/item/storage/firstaid/fire/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins rubbing \the [src] against себя! It looks like [user.ru_who()] trying to start a fire!</span>")
	return FIRELOSS

/obj/item/storage/firstaid/fire/PopulateContents()
	if(empty)
		return
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/pill/patch/silver_sulf(src)
	new /obj/item/reagent_containers/hypospray/medipen/oxandrolone(src)
	new /obj/item/reagent_containers/hypospray/medipen/oxandrolone(src)
	new /obj/item/reagent_containers/pill/oxandrolone(src)
	new /obj/item/healthanalyzer(src)

/obj/item/storage/firstaid/toxin
	name = "toxin treatment kit"
	desc = "Нужна для вывеения токсинов из крови и третирования радиационного отравления."
	icon_state = "firstaid-toxin"
	item_state = "firstaid-toxin"

/obj/item/storage/firstaid/toxin/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins licking the lead paint off \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return TOXLOSS

/obj/item/storage/firstaid/toxin/PopulateContents()
	if(empty)
		return
	for(var/i in 1 to 2)
		new /obj/item/reagent_containers/syringe/charcoal(src)
	for(var/i in 1 to 2)
		new /obj/item/reagent_containers/hypospray/medipen/penacid(src)
	for(var/i in 1 to 2)
		new /obj/item/storage/pill_bottle/charcoal(src)
	new /obj/item/healthanalyzer(src)

/obj/item/storage/firstaid/o2
	name = "oxygen deprivation treatment kit"
	desc = "Коробка, полная антигипоксичных вещиц."
	icon_state = "firstaid-o2"
	item_state = "firstaid-o2"

/obj/item/storage/firstaid/o2/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins hitting [user.ru_ego()] neck with \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return OXYLOSS

/obj/item/storage/firstaid/o2/PopulateContents()
	if(empty)
		return
	for(var/i in 1 to 4)
		new /obj/item/reagent_containers/pill/salbutamol(src)
	new /obj/item/reagent_containers/hypospray/medipen/salbutamol(src)
	new /obj/item/reagent_containers/hypospray/medipen/salbutamol(src)
	new /obj/item/healthanalyzer(src)

/obj/item/storage/firstaid/tactical
	name = "tactical first-aid kit"
	desc = "Надеемся, у вас есть страховка."
	icon_state = "firstaid-tactical"
	item_state = "firstaid-tactical"

/obj/item/storage/firstaid/tactical/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 16
	STR.max_items = 8

/obj/item/storage/firstaid/tactical/PopulateContents()
	if(empty)
		return
	new /obj/item/stack/medical/gauze(src)
	new /obj/item/defibrillator/compact/combat(src)
	new /obj/item/reagent_containers/hypospray/combat/omnizine(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)
	new /obj/item/healthanalyzer/advanced(src)
	new /obj/item/clothing/glasses/hud/health/night/syndicate(src)

/obj/item/storage/firstaid/tactical/nukeop

/obj/item/storage/firstaid/tactical/nukeop/PopulateContents()
	if(empty)
		return
	new /obj/item/stack/medical/gauze(src)
	new /obj/item/defibrillator/compact/combat(src)
	new /obj/item/reagent_containers/hypospray/combat/omnizine(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)
	new /obj/item/healthanalyzer/advanced(src)
	new /obj/item/clothing/glasses/hud/health/night/syndicate(src)

/obj/item/storage/firstaid/tactical/ert_first
	name = "Advanced tactical first-aid kit c1"

/obj/item/storage/firstaid/tactical/ert_first/PopulateContents()
	if(empty)
		return
	new /obj/item/healthanalyzer/advanced(src)
	new /obj/item/reagent_containers/syringe/piercing(src)
	new /obj/item/bonesetter(src)
	new /obj/item/pinpointer/crew(src)
	new /obj/item/sensor_device(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)
	new /obj/item/reagent_containers/glass/bottle/morphine(src)
	new /obj/item/hypospray/mkii/CMO/combat/synthflesh(src)


/obj/item/storage/firstaid/tactical/ert_second
	name = "Advanced tactical first-aid kit c2"

/obj/item/storage/firstaid/tactical/ert_second/PopulateContents()
	if(empty)
		return
	new /obj/item/stack/medical/gauze(src)
	new /obj/item/reagent_containers/medspray/sterilizine(src)
	new /obj/item/reagent_containers/glass/bottle/chloralhydrate(src)
	new /obj/item/reagent_containers/glass/bottle/chloralhydrate(src)
	new /obj/item/reagent_containers/glass/bottle/chloralhydrate(src)
	new /obj/item/reagent_containers/hypospray/combat/omnizine(src)
	new /obj/item/reagent_containers/hypospray/medipen/penacid(src)
	new /obj/item/reagent_containers/hypospray/medipen/penacid(src)


/obj/item/storage/firstaid/radbgone
	name = "radiation treatment kit"
	desc = "Нужна для выведения из крови малых доз токсинов и серьёзного радиационного отравления."
	icon_state = "firstaid-rad"
	item_state = "firstaid-rad"

/obj/item/storage/firstaid/radbgone/suicide_act(mob/living/carbon/user)
	user.visible_message("<span class='suicide'>[user] begins licking the lead paint off \the [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return TOXLOSS

/obj/item/storage/firstaid/radbgone/PopulateContents()
	if(empty)
		return
	if(prob(50))
		new /obj/item/reagent_containers/pill/mutarad(src)
	if(prob(80))
		new /obj/item/reagent_containers/pill/antirad_plus(src)
	new /obj/item/reagent_containers/syringe/charcoal(src)
	new /obj/item/storage/pill_bottle/charcoal(src)
	new /obj/item/reagent_containers/pill/mutadone(src)
	new /obj/item/reagent_containers/pill/antirad(src)
	new /obj/item/reagent_containers/food/drinks/bottle/vodka(src)
	new /obj/item/healthanalyzer(src)

/*
 * Pill Bottles
 */

/obj/item/storage/pill_bottle
	name = "pill bottle"
	desc = "Воздухонепроницаемый контейнер для хранения медикаментов."
	icon_state = "pill_canister"
	icon = 'icons/obj/chemical.dmi'
	item_state = "contsolid"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	obj_flags = UNIQUE_RENAME

/obj/item/storage/pill_bottle/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT
	STR.max_volume = STORAGE_VOLUME_PILL_BOTTLE
	STR.allow_quick_gather = TRUE
	STR.click_gather = TRUE
	STR.can_hold = typecacheof(list(/obj/item/reagent_containers/pill, /obj/item/dice))

/obj/item/storage/pill_bottle/AltClick(mob/living/carbon/user)
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	if(!length(user.get_empty_held_indexes()))
		to_chat(user, "<span class='warning'>Ваши руки заняты</span>")
		return
	var/obj/item/reagent_containers/pill/P = locate() in contents
	if(P)
		SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, P, user)
		if(!user.put_in_hands(P))
			P.forceMove(user.drop_location())	// make sure it's not stuck in the user if the put in hands somehow fails
			to_chat(user, "<span class='warning'>[P] выпадает на пол!</span>")
		else
			to_chat(user, "<span class='notice'>Вы взяли \a [P] из [src].</span>")
	else
		to_chat(user, "<span class='notice'>В бутылочке не осталось пилюль.</span>")
	return TRUE


/obj/item/storage/pill_bottle/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is trying to get the cap off [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	return (TOXLOSS)

/obj/item/storage/pill_bottle/charcoal
	name = "bottle of charcoal pills"
	desc = "Содержит пилюли для борьбы с токсинами."

/obj/item/storage/pill_bottle/charcoal/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/charcoal(src)

/obj/item/storage/pill_bottle/antirad
	name = "bottle of potassium iodide pills"
	desc = "Содержит пилюли для борьбы с радиационным отравлением."

/obj/item/storage/pill_bottle/anitrad/PopulateContents()
	for(var/i in 1 to 4)
		new /obj/item/reagent_containers/pill/antirad(src)

/obj/item/storage/pill_bottle/epinephrine
	name = "bottle of epinephrine pills"
	desc = "Содержит пилюли для стабилизации пациентов."

/obj/item/storage/pill_bottle/epinephrine/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/epinephrine(src)

/obj/item/storage/pill_bottle/mutadone
	name = "bottle of mutadone pills"
	desc = "Содержит пилюли для ухода генетических отклонений."

/obj/item/storage/pill_bottle/mutadone/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/mutadone(src)

/obj/item/storage/pill_bottle/mannitol
	name = "bottle of mannitol pills"
	desc = "Содержит пилюли для ухода повреждений мозга."

/obj/item/storage/pill_bottle/mannitol/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/mannitol(src)

/obj/item/storage/pill_bottle/stimulant
	name = "bottle of stimulant pills"
	desc = "Гарантированно придаст вам приток сил и энергии для долгой смены!"

/obj/item/storage/pill_bottle/stimulant/PopulateContents()
	for(var/i in 1 to 4)
		new /obj/item/reagent_containers/pill/stimulant(src)

/obj/item/storage/pill_bottle/mining
	name = "bottle of patches"
	desc = "Содержит пластыри для травм и ожогов."

/obj/item/storage/pill_bottle/mining/PopulateContents()
	new /obj/item/reagent_containers/pill/patch/silver_sulf(src)
	for(var/i in 1 to 3)
		new /obj/item/reagent_containers/pill/patch/styptic(src)

/obj/item/storage/pill_bottle/zoom
	name = "suspicious pill bottle"
	desc = "Этикетка очень стара и почти нечитаема, вы распознаете парочку химических соединений."

/obj/item/storage/pill_bottle/zoom/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/zoom(src)

/obj/item/storage/pill_bottle/happy
	name = "suspicious pill bottle"
	desc = "Сверху виден смайлик."

/obj/item/storage/pill_bottle/happy/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/happy(src)

/obj/item/storage/pill_bottle/lsd
	name = "suspicious pill bottle"
	desc = "Видна плохо нарисованная каракуля формы гриба."

/obj/item/storage/pill_bottle/lsd/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/lsd(src)

/obj/item/storage/pill_bottle/aranesp
	name = "suspicious pill bottle"
	desc = "Этикетка пишет: \"gotta go fast\"."

/obj/item/storage/pill_bottle/aranesp/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/aranesp(src)

/obj/item/storage/pill_bottle/psicodine
	name = "bottle of psicodine pills"
	desc = "Содержит пилюли для ухода ментальных расстройств и травм."

/obj/item/storage/pill_bottle/psicodine/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/psicodine(src)

/obj/item/storage/pill_bottle/happiness
	name = "happiness pill bottle"
	desc = "Этикетки давно нет, на её месте написана буква 'С' маркером."

/obj/item/storage/pill_bottle/happiness/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/happiness(src)

/obj/item/storage/pill_bottle/antirad_plus
	name = "anti radiation deluxe pill bottle"
	desc = "Этикетка пишет: \"Пилюли бренда Med-Co\"."

/obj/item/storage/pill_bottle/antirad_plus/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/antirad_plus(src)

/obj/item/storage/pill_bottle/mutarad
	name = "radiation treatment deluxe pill bottle"
	desc = "Этиктека пишет: \"Пилюли бренда Med-Co\", а под ним: \"Содержит мутадон в каждой пилюле!\"."

/obj/item/storage/pill_bottle/mutarad/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/mutarad(src)

/obj/item/storage/pill_bottle/penis_enlargement
	name = "penis enlargement pills"
	desc = "Хотите таблетки для увеличения члена?"

/obj/item/storage/pill_bottle/penis_enlargement/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/penis_enlargement(src)

/obj/item/storage/pill_bottle/breast_enlargement
	name = "breast enlargement pills"
	desc = "Сделано компанией Fermichem - таблетница показывает женщину с грудями больше её самой. Предупреждение предостерегает не применять больше 10 u за раз."

/obj/item/storage/pill_bottle/breast_enlargement/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/breast_enlargement(src)

/obj/item/storage/pill_bottle/butt_enlargement
	name = "butt enlargement pills"
	desc = "Хлопанье ягодиц может тревожить офицеров при попытках красться, если достаточно таблеток было выпито. Будьте толстозадыми ответственно."

/obj/item/storage/pill_bottle/butt_enlargement/PopulateContents()
	for(var/i in 1 to 10)
		new /obj/item/reagent_containers/pill/butt_enlargement(src)

/obj/item/storage/pill_bottle/neurine
	name = "bottle of neurine pills"
	desc = "Содержит пилюли для лечения несерьёзных ментальных травм."

/obj/item/storage/pill_bottle/neurine/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/reagent_containers/pill/neurine(src)

/obj/item/storage/pill_bottle/floorpill
	name = "bottle of floorpills"
	desc = "Старая таблетница. Пахнет затхлостью."

/obj/item/storage/pill_bottle/floorpill/Initialize(mapload)
	. = ..()
	var/obj/item/reagent_containers/pill/P = locate() in src
	name = "bottle of [P.name]s"

/obj/item/storage/pill_bottle/floorpill/PopulateContents()
	for(var/i in 1 to rand(1,7))
		new /obj/item/reagent_containers/pill/floorpill(src)

/obj/item/storage/pill_bottle/floorpill/full/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/pill/floorpill(src)

/////////////
//Organ Box//
/////////////

/obj/item/storage/belt/organbox
	name = "Organ Storage"
	desc = "Компактный контейнер для переноски огромного количества имплантатов, органов и некоторых инструментов. С поясным карабином для упрощённой переноски."
	w_class = WEIGHT_CLASS_BULKY
	icon = 'icons/obj/mysterybox.dmi'
	icon_state = "organbox_open"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 1
	throw_range = 1

/obj/item/storage/belt/organbox/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 16
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.max_combined_w_class = 20
	STR.can_hold = typecacheof(list(
	/obj/item/storage/pill_bottle,
	/obj/item/reagent_containers/hypospray,
	/obj/item/pinpointer/crew,
	/obj/item/tele_iv,
	/obj/item/sequence_scanner,
	/obj/item/sensor_device,
	/obj/item/bodybag,
	/obj/item/surgicaldrill/advanced,
	/obj/item/healthanalyzer,
	/obj/item/reagent_containers/syringe,
	/obj/item/clothing/glasses/hud/health,
	/obj/item/hemostat,
	/obj/item/scalpel,
	/obj/item/retractor,
	/obj/item/cautery,
	/obj/item/blood_filter,
	/obj/item/surgical_drapes,
	/obj/item/bonesetter,
	/obj/item/autosurgeon,
	/obj/item/organ,
	/obj/item/implant,
	/obj/item/implantpad,
	/obj/item/implantcase,
	/obj/item/implanter,
	/obj/item/circuitboard/computer/operating,
	/obj/item/circuitboard/computer/crew,
	/obj/item/stack/sheet/glass,
	/obj/item/stack/sheet/mineral/silver,
	/obj/item/organ_storage,
	/obj/item/reagent_containers/chem_pack
	))

//hijacking the minature first aids for hypospray boxes. <3
/obj/item/storage/hypospraykit
	name = "hypospray kit"
	desc = "Набор для хранения гипоспрея и специализированных флаконов-ампул с препаратами."
	icon_state = "firstaid-mini"
	item_state = "firstaid"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 3
	throw_range = 7
	var/empty = FALSE
	custom_price = PRICE_ABOVE_NORMAL
	custom_premium_price = PRICE_EXPENSIVE

/obj/item/storage/hypospraykit/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 12
	STR.can_hold = typecacheof(list(
	/obj/item/hypospray/mkii,
	/obj/item/reagent_containers/glass/bottle/vial))

/obj/item/storage/hypospraykit/regular
	name = "first-aid hypospray kit"
	desc = "Набор с гипоспреем и ампулами общего назначения."

/obj/item/storage/hypospraykit/regular/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/tricord(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/tricord(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/tricord(src)

/obj/item/storage/hypospraykit/brute
	name = "trauma hypospray kit"
	icon_state = "firstaid-brute-mini"
	item_state = "firstaid-brute"

/obj/item/storage/hypospraykit/brute/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/brute(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/bicaridine(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/bicaridine(src)


/obj/item/storage/hypospraykit/fire
	name = "burn treatment hypospray kit"
	desc = "Спецаилизированный набор с гипоспреем и ожоговыми препаратами. \"Apply with sass\"."
	icon_state = "firstaid-burn-mini"
	item_state = "firstaid-burn"

/obj/item/storage/hypospraykit/fire/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/burn(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/kelotane(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/kelotane(src)

/obj/item/storage/hypospraykit/toxin
	name = "toxin treatment hypospray kit"
	icon_state = "firstaid-toxin-mini"
	item_state = "firstaid-toxin"

/obj/item/storage/hypospraykit/toxin/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/toxin(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/antitoxin(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/antitoxin(src)

/obj/item/storage/hypospraykit/o2
	name = "oxygen deprivation hypospray kit"
	icon_state = "firstaid-o2-mini"
	item_state = "firstaid-o2"

/obj/item/storage/hypospraykit/o2/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/oxygen(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/dexalin(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/dexalin(src)

/obj/item/storage/hypospraykit/enlarge
	name = "organomegaly trauma hypospray kit"
	icon_state = "firstaid-enlarge-mini"
	item_state = "firstaid-brute"

/obj/item/storage/hypospraykit/tactical
	name = "tactical first-aid hypospray kit"
	desc = "Набор с гипоспреем и химией для боевой обстановки."
	icon_state = "firstaid-tactical-mini"
	item_state = "firstaid-tactical-mini"

/obj/item/storage/hypospraykit/tactical/PopulateContents()
	if(empty)
		return
	new /obj/item/defibrillator/compact/combat(src)
	new /obj/item/hypospray/mkii/CMO/combat(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/combat(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/combat(src)

/obj/item/storage/hypospraykit/cmo
	name = "deluxe hypospray kit"
	desc = "Набор, содержащий делюкс-гипоспрей и ампулы для него."
	icon_state = "firstaid-rad-mini"
	item_state = "firstaid-rad"

/obj/item/storage/hypospraykit/cmo/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/CMO(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/tricord(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/charcoal(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/salglu(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/dexalin(src)
	new /obj/item/reagent_containers/glass/bottle/vial/large/synthflesh(src)

/obj/item/storage/hypospraykit/enlarge/PopulateContents()
	if(empty)
		return
	new /obj/item/hypospray/mkii/enlarge(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/breastreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/breastreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/breastreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/penisreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/penisreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/penisreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/buttreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/buttreduction(src)
	new /obj/item/reagent_containers/glass/bottle/vial/small/buttreduction(src)

/obj/item/storage/box/vials
	name = "box of hypovials"

/obj/item/storage/box/vials/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/reagent_containers/glass/bottle/vial/small( src )

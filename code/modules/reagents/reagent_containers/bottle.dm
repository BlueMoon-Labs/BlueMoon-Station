//Not to be confused with /obj/item/reagent_containers/food/drinks/bottle

/obj/item/reagent_containers/glass/bottle
	name = "bottle"
	desc = "Маленькая бутылочка. Плотно закрыта крышкой."
	icon_state = "bottle"
	item_state = "atoxinbottle"
	possible_transfer_amounts = list(5,10,15,25,30)
	volume = 30
	spillable = FALSE

/obj/item/reagent_containers/glass/bottle/Initialize(mapload)
	. = ..()
	if(!icon_state)
		icon_state = "bottle"
	update_icon()

/obj/item/reagent_containers/glass/bottle/on_reagent_change(changetype)
	update_icon()

/obj/item/reagent_containers/glass/bottle/update_overlays()
	. = ..()
	if(!cached_icon)
		cached_icon = icon_state
	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance('icons/obj/reagentfillings.dmi', "[cached_icon]-10", color = mix_color_from_reagents(reagents.reagent_list))

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 9)
				filling.icon_state = "[cached_icon]-10"
			if(10 to 29)
				filling.icon_state = "[cached_icon]25"
			if(30 to 49)
				filling.icon_state = "[cached_icon]50"
			if(50 to 69)
				filling.icon_state = "[cached_icon]75"
			if(70 to INFINITY)
				filling.icon_state = "[cached_icon]100"

		. += filling

/obj/item/reagent_containers/glass/bottle/epinephrine
	name = "epinephrine bottle"
	desc = "Маленькая бутылочка. Содержит эпинефрин - для стабилизации пациентов."
	list_reagents = list(/datum/reagent/medicine/epinephrine = 30)

/obj/item/reagent_containers/glass/bottle/bicaridine
	name = "bicaridine bottle"
	desc = "Маленькая бутылочка. Содержит бикаридин - для лечения повреждений типа \"травмы\"."
	list_reagents = list(/datum/reagent/medicine/bicaridine = 30)

/obj/item/reagent_containers/glass/bottle/kelotane
	name = "kelotane bottle"
	desc = "Маленькая бутылочка. Содержит келотан - для лечения повреждений типа \"ожоги\"."
	list_reagents = list(/datum/reagent/medicine/kelotane = 30)

/obj/item/reagent_containers/glass/bottle/antitoxin
	name = "anti-toxin bottle"
	desc = "Маленькая бутылочка. Содержит анти-токсин - для лечения малой интоксикации."
	list_reagents = list(/datum/reagent/medicine/antitoxin = 30)

/obj/item/reagent_containers/glass/bottle/dexalin
	name = "dexalin bottle"
	desc = "Маленькая бутылочка. Содержит dexalin - для лечения малой гипоксии."
	list_reagents = list(/datum/reagent/medicine/dexalin = 30)

/obj/item/reagent_containers/glass/bottle/toxin
	name = "toxin bottle"
	desc = "Маленькая бутылочка токсинов. Не употреблять: ядовито."
	list_reagents = list(/datum/reagent/toxin = 30)

/obj/item/reagent_containers/glass/bottle/cyanide
	name = "cyanide bottle"
	desc = "Маленькая бутылочка цианида. Горьковатый миндаль?"
	list_reagents = list(/datum/reagent/toxin/cyanide = 30)

/obj/item/reagent_containers/glass/bottle/spewium
	name = "spewium bottle"
	desc = "Маленькая бутылочка спевия."
	list_reagents = list(/datum/reagent/toxin/spewium = 30)

/obj/item/reagent_containers/glass/bottle/morphine
	name = "morphine bottle"
	desc = "Маленькая бутылочка морфина. Для внутривенных инъекций."
	icon = 'icons/obj/chemical.dmi'
	list_reagents = list(/datum/reagent/medicine/morphine = 30)

/obj/item/reagent_containers/glass/bottle/chloralhydrate
	name = "Chloral Hydrate Bottle"
	desc = "Маленькая бутылочка хлоргидрата. Mickey's Favorite!"
	icon_state = "bottle20"
	list_reagents = list(/datum/reagent/toxin/chloralhydrate = 15)

/obj/item/reagent_containers/glass/bottle/charcoal
	name = "charcoal bottle"
	desc = "Маленькая бутылочка активированного угля, для дотоксикации организма и выведения препаратов из кровотока."
	list_reagents = list(/datum/reagent/medicine/charcoal = 30)

/obj/item/reagent_containers/glass/bottle/cryoxadone
	name = "cryoxadone bottle"
	desc = "Маленькая бутылочка криоксадона, он лечит большинство видов повреждений в условиях особо низких температур."
	list_reagents = list(/datum/reagent/medicine/cryoxadone = 30)

/obj/item/reagent_containers/glass/bottle/mutagen
	name = "unstable mutagen bottle"
	desc = "Маленькая бутылочка нестабильного мутагена. Случайно меняет ДНК-структуру употребившего."
	list_reagents = list(/datum/reagent/toxin/mutagen = 30)

/obj/item/reagent_containers/glass/bottle/plasma
	name = "liquid plasma bottle"
	desc = "Маленькая бутылочка жидкой плазмы. Чрезвычайно токсична и вступает в реакцию с микроорганизмами внутри кровотока."
	list_reagents = list(/datum/reagent/toxin/plasma = 30)

/obj/item/reagent_containers/glass/bottle/synaptizine
	name = "synaptizine bottle"
	desc = "Маленькая бутылочка синаптизина."
	list_reagents = list(/datum/reagent/medicine/synaptizine = 30)

/obj/item/reagent_containers/glass/bottle/formaldehyde
	name = "formaldehyde bottle"
	desc = "Маленькая бутылочка формальдегида."
	list_reagents = list(/datum/reagent/toxin/formaldehyde = 30)

/obj/item/reagent_containers/glass/bottle/ammonia
	name = "ammonia bottle"
	desc = "Маленькая бутылочка аммиака."
	list_reagents = list(/datum/reagent/ammonia = 30)

/obj/item/reagent_containers/glass/bottle/diethylamine
	name = "diethylamine bottle"
	desc = "Маленькая бутылочка диэтиламина."
	list_reagents = list(/datum/reagent/diethylamine = 30)

/obj/item/reagent_containers/glass/bottle/facid
	name = "Fluorosulfuric Acid Bottle"
	desc = "Маленькая бутылочка. Содержит малую дозу фторсерной кислоты."
	list_reagents = list(/datum/reagent/toxin/acid/fluacid = 30)

/obj/item/reagent_containers/glass/bottle/adminordrazine
	name = "Adminordrazine Bottle"
	desc = "Маленькая бутылочка. Содержит жидкую эссенцию богов."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "holyflask"
	list_reagents = list(/datum/reagent/medicine/adminordrazine = 30)

/obj/item/reagent_containers/glass/bottle/capsaicin
	name = "Capsaicin Bottle"
	desc = "Маленькая бутылочка. Содержит острый соус."
	list_reagents = list(/datum/reagent/consumable/capsaicin = 30)

/obj/item/reagent_containers/glass/bottle/frostoil
	name = "Frost Oil Bottle"
	desc = "Маленькая бутылочка. Содержит холодный соус."
	list_reagents = list(/datum/reagent/consumable/frostoil = 30)

/obj/item/reagent_containers/glass/bottle/traitor
	name = "syndicate bottle"
	desc = "Маленькая бутылочка. Содержит случаный отвратный препарат."
	icon = 'icons/obj/chemical.dmi'
	var/extra_reagent = null

/obj/item/reagent_containers/glass/bottle/traitor/Initialize(mapload)
	. = ..()
	extra_reagent = pick(/datum/reagent/toxin/polonium, /datum/reagent/toxin/histamine, /datum/reagent/toxin/formaldehyde,
					/datum/reagent/toxin/venom, /datum/reagent/toxin/fentanyl, /datum/reagent/toxin/cyanide)
	reagents.add_reagent(extra_reagent, 3)

/obj/item/reagent_containers/glass/bottle/polonium
	name = "polonium bottle"
	desc = "Маленькая бутылочка. Содержит полоний."
	list_reagents = list(/datum/reagent/toxin/polonium = 30)

/obj/item/reagent_containers/glass/bottle/magillitis
	name = "magillitis bottle"
	desc = "Маленькая бутылочка. Содержит сыворотку, известную как 'магиллитис'."
	list_reagents = list(/datum/reagent/magillitis = 5)

/obj/item/reagent_containers/glass/bottle/venom
	name = "venom bottle"
	desc = "Маленькая бутылочка. Содержит яд."
	list_reagents = list(/datum/reagent/toxin/venom = 30)

/obj/item/reagent_containers/glass/bottle/fentanyl
	name = "fentanyl bottle"
	desc = "Маленькая бутылочка. Содержит фентанил."
	list_reagents = list(/datum/reagent/toxin/fentanyl = 30)

/obj/item/reagent_containers/glass/bottle/formaldehyde
	name = "formaldehyde bottle"
	desc = "Маленькая бутылочка. Содержит фформальдегид."
	list_reagents = list(/datum/reagent/toxin/formaldehyde = 30)

/obj/item/reagent_containers/glass/bottle/initropidril
	name = "initropidril bottle"
	desc = "Маленькая бутылочка. Содержит инитропидрил."
	list_reagents = list(/datum/reagent/toxin/initropidril = 30)

/obj/item/reagent_containers/glass/bottle/pancuronium
	name = "pancuronium bottle"
	desc = "Маленькая бутылочка. Содержит панкуроний."
	list_reagents = list(/datum/reagent/toxin/pancuronium = 30)

/obj/item/reagent_containers/glass/bottle/sodium_thiopental
	name = "sodium thiopental bottle"
	desc = "Маленькая бутылочка. Содержит тиопентал натрия."
	list_reagents = list(/datum/reagent/toxin/sodium_thiopental = 30)

/obj/item/reagent_containers/glass/bottle/coniine
	name = "coniine bottle"
	desc = "Маленькая бутылочка. Содержит кониин."
	list_reagents = list(/datum/reagent/toxin/coniine = 30)

/obj/item/reagent_containers/glass/bottle/curare
	name = "curare bottle"
	desc = "Маленькая бутылочка. Содержит яд кураре."
	list_reagents = list(/datum/reagent/toxin/curare = 30)

/obj/item/reagent_containers/glass/bottle/amanitin
	name = "amanitin bottle"
	desc = "Маленькая бутылочка. Содержит аманитин."
	list_reagents = list(/datum/reagent/toxin/amanitin = 30)

/obj/item/reagent_containers/glass/bottle/histamine
	name = "histamine bottle"
	desc = "Маленькая бутылочка. Содержит гистамин."
	list_reagents = list(/datum/reagent/toxin/histamine = 30)

/obj/item/reagent_containers/glass/bottle/diphenhydramine
	name = "antihistamine bottle"
	desc = "Маленькая бутылочка димедрола."
	list_reagents = list(/datum/reagent/medicine/diphenhydramine = 30)

/obj/item/reagent_containers/glass/bottle/potass_iodide
	name = "anti-radiation bottle"
	desc = "Маленькая бутылочка калистого иода."
	list_reagents = list(/datum/reagent/medicine/potass_iodide = 30)

/obj/item/reagent_containers/glass/bottle/salglu_solution
	name = "saline-glucose solution bottle"
	desc = "Маленькая бутылочка физраствора глюкозы."
	icon_state = "bottle1"
	list_reagents = list(/datum/reagent/medicine/salglu_solution = 30)

/obj/item/reagent_containers/glass/bottle/atropine
	name = "atropine bottle"
	desc = "Маленькая бутылочка атропина."
	list_reagents = list(/datum/reagent/medicine/atropine = 30)

/obj/item/reagent_containers/glass/bottle/zeolites
	name = "Zeolites bottle"
	desc = "Маленькая бутылочка лабораторного цеолита, стремительно выводящего радионуклиды пациентов и рад-контаминацию на вещах."
	list_reagents = list(/datum/reagent/fermi/zeolites = 30)

// Viro bottles

/obj/item/reagent_containers/glass/bottle/romerol
	name = "Romerol Bottle"
	desc = "Маленькая бутылочка ромерола. НАСТОЯЩИЙ зомби-порошок."
	list_reagents = list(/datum/reagent/romerol = 30)

/obj/item/reagent_containers/glass/bottle/random_virus
	name = "Experimental disease culture bottle"
	desc = "Маленькая бутылочка. Содержит неизученный вирусный патоген в синт-кровяном агаре."
	spawned_disease = /datum/disease/advance/random

/obj/item/reagent_containers/glass/bottle/pierrot_throat
	name = "Pierrot's Throat culture bottle"
	desc = "Маленькая бутылочка. Содержит вирусную культуру H0NI<42 в синт-кровяном агаре."
	spawned_disease = /datum/disease/pierrot_throat

/obj/item/reagent_containers/glass/bottle/cold
	name = "Rhinovirus culture bottle"
	desc = "Маленькая бутылочка. Содержит вирусную культуру XY-rhinovirus в синт-кровяном агаре."
	spawned_disease = /datum/disease/advance/cold

/obj/item/reagent_containers/glass/bottle/flu_virion
	name = "Flu virion culture bottle"
	desc = "Маленькая бутылочка. Содержит вирусную культуру H13N1 flu в синт-кровяном агаре."
	spawned_disease = /datum/disease/advance/flu

/obj/item/reagent_containers/glass/bottle/retrovirus
	name = "Retrovirus culture bottle"
	desc = "Маленькая бутылочка. Содержит ретровирусную культуру в синт-кровяном агаре."
	spawned_disease = /datum/disease/dna_retrovirus

/obj/item/reagent_containers/glass/bottle/gbs
	name = "GBS culture bottle"
	desc = "Маленькая бутылочка. Содержит вирусную культуру Gravitokinetic Bipotential SADS+  в синт-кровяном агаре."//Or simply - General BullShit
	amount_per_transfer_from_this = 5
	spawned_disease = /datum/disease/gbs

/obj/item/reagent_containers/glass/bottle/fake_gbs
	name = "GBS culture bottle"
	desc = "Маленькая бутылочка. Содержит вирусную культуру Gravitokinetic Bipotential SADS- в синт-кровяном агаре."//Or simply - General BullShit
	spawned_disease = /datum/disease/fake_gbs

/obj/item/reagent_containers/glass/bottle/brainrot
	name = "Brainrot culture bottle"
	desc = "Маленькая бутылочка. Содержит вирусную культуру Cryptococcus Cosmosis в синт-кровяном агаре."
	icon_state = "bottle3"
	spawned_disease = /datum/disease/brainrot

/obj/item/reagent_containers/glass/bottle/magnitis
	name = "Magnitis culture bottle"
	desc = "Маленькая бутылочка. Содержит небольшую дозу культуры Fukkos Miracos."
	spawned_disease = /datum/disease/magnitis

/obj/item/reagent_containers/glass/bottle/wizarditis
	name = "Wizarditis culture bottle"
	desc = "Маленькая бутылочка. Содержит образец культуры Rincewindus Vulgaris."
	spawned_disease = /datum/disease/wizarditis

/obj/item/reagent_containers/glass/bottle/anxiety
	name = "Severe Anxiety culture bottle"
	desc = "Маленькая бутылочка. Содержит образец культуры Lepidopticides."
	spawned_disease = /datum/disease/anxiety

/obj/item/reagent_containers/glass/bottle/beesease
	name = "Beesease culture bottle"
	desc = "Маленькая бутылочка. Содержит образец инвазивной культуры Apidae."
	spawned_disease = /datum/disease/beesease

/obj/item/reagent_containers/glass/bottle/fluspanish
	name = "Spanish flu culture bottle"
	desc = "Маленькая бутылочка. Содержит образец культуры Inquisitius."
	spawned_disease = /datum/disease/fluspanish

/obj/item/reagent_containers/glass/bottle/tuberculosis
	name = "Fungal Tuberculosis culture bottle"
	desc = "Маленькая бутылочка. Содержит бациллы культуры Fungal Tubercle."
	spawned_disease = /datum/disease/tuberculosis

/obj/item/reagent_containers/glass/bottle/tuberculosiscure
	name = "BVAK bottle"
	desc = "Маленькая бутылочка с биркой \"Bio Virus Antidote Kit\"."
	list_reagents = list(/datum/reagent/medicine/atropine = 5, /datum/reagent/medicine/epinephrine = 5, /datum/reagent/medicine/salbutamol = 10, /datum/reagent/medicine/spaceacillin = 10)

//Oldstation.dmm chemical storage bottles

/obj/item/reagent_containers/glass/bottle/hydrogen
	name = "hydrogen bottle"
	list_reagents = list(/datum/reagent/hydrogen = 30)

/obj/item/reagent_containers/glass/bottle/lithium
	name = "lithium bottle"
	list_reagents = list(/datum/reagent/lithium = 30)

/obj/item/reagent_containers/glass/bottle/carbon
	name = "carbon bottle"
	list_reagents = list(/datum/reagent/carbon = 30)

/obj/item/reagent_containers/glass/bottle/nitrogen
	name = "nitrogen bottle"
	list_reagents = list(/datum/reagent/nitrogen = 30)

/obj/item/reagent_containers/glass/bottle/oxygen
	name = "oxygen bottle"
	list_reagents = list(/datum/reagent/oxygen = 30)

/obj/item/reagent_containers/glass/bottle/fluorine
	name = "fluorine bottle"
	list_reagents = list(/datum/reagent/fluorine = 30)

/obj/item/reagent_containers/glass/bottle/sodium
	name = "sodium bottle"
	list_reagents = list(/datum/reagent/sodium = 30)

/obj/item/reagent_containers/glass/bottle/aluminium
	name = "aluminium bottle"
	list_reagents = list(/datum/reagent/aluminium = 30)

/obj/item/reagent_containers/glass/bottle/silicon
	name = "silicon bottle"
	list_reagents = list(/datum/reagent/silicon = 30)

/obj/item/reagent_containers/glass/bottle/phosphorus
	name = "phosphorus bottle"
	list_reagents = list(/datum/reagent/phosphorus = 30)

/obj/item/reagent_containers/glass/bottle/sulfur
	name = "sulfur bottle"
	list_reagents = list(/datum/reagent/sulfur = 30)

/obj/item/reagent_containers/glass/bottle/chlorine
	name = "chlorine bottle"
	list_reagents = list(/datum/reagent/chlorine = 30)

/obj/item/reagent_containers/glass/bottle/potassium
	name = "potassium bottle"
	list_reagents = list(/datum/reagent/potassium = 30)

/obj/item/reagent_containers/glass/bottle/iron
	name = "iron bottle"
	list_reagents = list(/datum/reagent/iron = 30)

/obj/item/reagent_containers/glass/bottle/copper
	name = "copper bottle"
	list_reagents = list(/datum/reagent/copper = 30)

/obj/item/reagent_containers/glass/bottle/mercury
	name = "mercury bottle"
	list_reagents = list(/datum/reagent/mercury = 30)

/obj/item/reagent_containers/glass/bottle/radium
	name = "radium bottle"
	list_reagents = list(/datum/reagent/radium = 30)

/obj/item/reagent_containers/glass/bottle/water
	name = "water bottle"
	list_reagents = list(/datum/reagent/water = 30)

/obj/item/reagent_containers/glass/bottle/ethanol
	name = "ethanol bottle"
	list_reagents = list(/datum/reagent/consumable/ethanol = 30)

/obj/item/reagent_containers/glass/bottle/sugar
	name = "sugar bottle"
	list_reagents = list(/datum/reagent/consumable/sugar = 30)

/obj/item/reagent_containers/glass/bottle/sacid
	name = "sulphuric acid bottle"
	list_reagents = list(/datum/reagent/toxin/acid = 30)

/obj/item/reagent_containers/glass/bottle/welding_fuel
	name = "welding fuel bottle"
	list_reagents = list(/datum/reagent/fuel = 30)

/obj/item/reagent_containers/glass/bottle/silver
	name = "silver bottle"
	list_reagents = list(/datum/reagent/silver = 30)

/obj/item/reagent_containers/glass/bottle/iodine
	name = "iodine bottle"
	list_reagents = list(/datum/reagent/iodine = 30)

/obj/item/reagent_containers/glass/bottle/bromine
	name = "bromine bottle"
	list_reagents = list(/datum/reagent/bromine = 30)

/obj/item/reagent_containers/glass/bottle/crocin
	name = "Crocin bottle"
	desc = "Бутылочка афродизиака. Повышает либидо."
	list_reagents = list(/datum/reagent/drug/aphrodisiac = 30)

/obj/item/reagent_containers/glass/bottle/hexacrocin
	name = "Hexacrocin bottle"
	desc = "Бутылочка сильного афродизиака. Повышает либидо."
	list_reagents = list(/datum/reagent/drug/aphrodisiacplus = 30)

/obj/item/reagent_containers/glass/bottle/camphor
	name = "Camphor bottle"
	desc = "Бутылочка анафродизиака. Снижает либидо."
	list_reagents = list(/datum/reagent/drug/anaphrodisiac = 30)

/obj/item/reagent_containers/glass/bottle/hexacamphor
	name = "Hexacamphor bottle"
	desc = "Бутылочка сильного анафродизиака. Снижает либид."
	list_reagents = list(/datum/reagent/drug/anaphrodisiacplus = 30)

/obj/item/reagent_containers/glass/bottle/copium // BLUEMOON FINK ADD
	name = "Copium bottle"
	desc = "Бутылочка сильного копиума. Уменьшает либидо."
	list_reagents = list(/datum/reagent/drug/copium = 30)

//Ichors
/obj/item/reagent_containers/glass/bottle/ichor
	possible_transfer_amounts = list(1)
	volume = 1

/obj/item/reagent_containers/glass/bottle/ichor/red
	name = "healing potion"
	list_reagents = list(/datum/reagent/red_ichor = 1)

/obj/item/reagent_containers/glass/bottle/ichor/blue
	name = "blue potion"
	list_reagents = list(/datum/reagent/blue_ichor = 1)

/obj/item/reagent_containers/glass/bottle/ichor/green
	name = "green potion"
	list_reagents = list(/datum/reagent/green_ichor = 1)

/obj/item/reagent_containers/glass/bottle/thermite
	name = "thermite bottle"
	list_reagents = list(/datum/reagent/thermite = 30)

/*
 *	Syrup bottles, basically a unspillable cup that transfers reagents upon clicking on it with a cup
 */

/obj/item/reagent_containers/glass/bottle/syrup_bottle
	name = "syrup bottle"
	desc = "Бутылочка сиропа для дозировки вкуснейшего вещества прямиком в вашу чашечку кофе."
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "syrup"
	//fill_icon_state = "syrup"
	//fill_icon_thresholds = list(0, 20, 40, 60, 80, 100)
	possible_transfer_amounts = list(5, 10)
	amount_per_transfer_from_this = 5
	spillable = FALSE
	///variable to tell if the bottle can be refilled
	var/cap_on = TRUE

/obj/item/reagent_containers/glass/bottle/syrup_bottle/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click для регулировки крышечки.")
	. += span_notice("Используйте ручку для переименовки.")
	return

//when you attack the syrup bottle with a container it refills it
/obj/item/reagent_containers/glass/bottle/syrup_bottle/attackby(obj/item/attacking_item, mob/user, params)

	if(!cap_on)
		return ..()

	if(!check_allowed_items(attacking_item,target_self = TRUE))
		return

	if(attacking_item.is_refillable())
		if(!reagents.total_volume)
			balloon_alert(user, "бутылка пуста!")
			return TRUE

		if(attacking_item.reagents.holder_full())
			balloon_alert(user, "бутылка заполнена!")
			return TRUE

		var/transfer_amount = reagents.trans_to(attacking_item, amount_per_transfer_from_this)
		balloon_alert(user, "перелито [transfer_amount] u")
		flick("syrup_anim",src)

	if(istype(attacking_item, /obj/item/pen))
		rename(user, attacking_item)

	attacking_item.update_appearance()
	update_appearance()

	return TRUE

/obj/item/reagent_containers/glass/bottle/syrup_bottle/AltClick(mob/user)
	cap_on = !cap_on
	if(!cap_on)
		icon_state = "syrup_open"
		balloon_alert(user, "крышечка убрана")
	else
		icon_state = "syrup"
		balloon_alert(user, "крышечка возвращена")
	update_icon_state()
	return ..()

/obj/item/reagent_containers/glass/bottle/syrup_bottle/proc/rename(mob/user, obj/item/writing_instrument)
	if(!user.can_write(writing_instrument))
		return

	var/inputvalue = tgui_input_text(user, "Как бы вы хотели назвать бутылочку сиропа?", "Наклейка этикетки на сироп", max_length = MAX_NAME_LEN)

	if(!inputvalue)
		return

	if(user.canUseTopic(src))
		name = "[(inputvalue ? "[inputvalue]" : null)] bottle"

//types of syrups

/obj/item/reagent_containers/glass/bottle/syrup_bottle/caramel
	name = "bottle of caramel syrup"
	desc = "Дозирующая бутылочка с карамелизированным сахаром, карамелью. Не лизать."
	list_reagents = list(/datum/reagent/consumable/caramel = 50)

/obj/item/reagent_containers/glass/bottle/syrup_bottle/liqueur
	name = "bottle of coffee liqueur syrup"
	desc = "Дозирующая бутылочка с максиканским ликерным сиропом со вкусом кофе. В производстве 1936-го, HONK."
	list_reagents = list(/datum/reagent/consumable/ethanol/kahlua = 50)

/obj/item/reagent_containers/glass/bottle/syrup_bottle/korta_nectar
	name = "bottle of korta syrup"
	desc = "Дозирующая бутылочка с сиропом корты. Сладкая, сахаристая субстанция, сделанная из размолотых ядер ореха корта."
	list_reagents = list(/datum/reagent/consumable/korta_nectar = 50)

//secret syrup
/obj/item/reagent_containers/glass/bottle/syrup_bottle/laughsyrup
	name = "bottle of laugh syrup"
	desc = "Дозирующая бутылочка с сиропом смеха. Продукт выжимки гороха \"Laughin' Peas\". Газированный, и, кажется, меняет вкус на основе того, с чем приготовлен!"
	list_reagents = list(/datum/reagent/consumable/laughsyrup = 50)

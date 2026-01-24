//Contains the target item datums for Steal objectives.

/datum/objective_item
	var/name = "A silly bike horn! Honk!"
	var/targetitem = /obj/item/bikehorn		//typepath of the objective item
	var/difficulty = 9001							//vaguely how hard it is to do this objective
	var/list/excludefromjob = list()				//If you don't want a job to get a certain objective (no captain stealing his own medal, etcetc)
	var/list/altitems = list()				//Items which can serve as an alternative to the objective (darn you blueprints)
	var/list/special_equipment = list()

/datum/objective_item/proc/check_special_completion() //for objectives with special checks (is that slime extract unused? does that intellicard have an ai in it? etcetc)
	return TRUE

/datum/objective_item/proc/TargetExists()
	return TRUE

/datum/objective_item/steal/New()
	..()
	if(TargetExists())
		GLOB.possible_items += src
	else
		qdel(src)

/datum/objective_item/steal/Destroy()
	GLOB.possible_items -= src
	return ..()

/datum/objective_item/steal/caplaser
	name = "Антикварный Лазерный Пистолет Капитана."
	targetitem = /obj/item/gun/energy/laser/captain
	difficulty = 8
	excludefromjob = list("Captain")

/datum/objective_item/steal/rubberducky
	name = "Уточку Капитана."
	targetitem = /obj/item/bikehorn/rubberducky/captain
	difficulty = 10
	excludefromjob = list("Captain")

/datum/objective_item/steal/zippo_cap
	name = "Зажигалку Капитана."
	targetitem = /obj/item/lighter/cap
	difficulty = 10
	excludefromjob = list("Captain")

/datum/objective_item/steal/zippo_hop
	name = "Зажигалку ГП."
	targetitem = /obj/item/lighter/hop
	difficulty = 6
	excludefromjob = list("Head of Personnel")

/datum/objective_item/steal/zippo_hos
	name = "Зажигалку ГСБ."
	targetitem = /obj/item/lighter/hos
	difficulty = 10
	excludefromjob = list("Head Of Security")

/datum/objective_item/steal/zippo_nt_rep
	name = "Зажигалку Представителя ПАКТа."
	targetitem = /obj/item/lighter/nt_rep
	difficulty = 10
	excludefromjob = list("NanoTrasen Representative")

/datum/objective_item/steal/zippo_cmo
	name = "Зажигалку Старшего Медицинского Офицера."
	targetitem = /obj/item/lighter/cmo
	difficulty = 5
	excludefromjob = list("Chief Medical Officer")

/datum/objective_item/steal/zippo_ce
	name = "Зажигалку Старшего Инженера."
	targetitem = /obj/item/lighter/ce
	difficulty = 5
	excludefromjob = list("Chief Engineer")

/datum/objective_item/steal/zippo_rd
	name = "Зажигалку Научного Руководителя."
	targetitem = /obj/item/lighter/ce
	difficulty = 5
	excludefromjob = list("Research Director")

/datum/objective_item/steal/zippo_qm
	name = "Зажигалку Завхоза."
	targetitem = /obj/item/lighter/qm_engraved
	difficulty = 2
	excludefromjob = list("Quartermaster")

/datum/objective_item/steal/hoslaser
	name = "личное вооружение Синего Щита или Главы Службы Безопасности."
	targetitem = /obj/item/gun/energy/e_gun/hos
	difficulty = 8
	excludefromjob = list("Head Of Security")
	altitems = list(/obj/item/gun/ballistic/revolver/mws, /obj/item/choice_beacon/hosgun, /obj/item/gun/ballistic/automatic/pistol/g22, /obj/item/gun/ballistic/shotgun/rsh12) //We now look for either the alt verson of the hos gun or the beacon picker.

/datum/objective_item/steal/handtele
	name = "Компактное Телепортирующее Устройство."
	targetitem = /obj/item/hand_tele
	difficulty = 5
	excludefromjob = list("Captain", "Research Director")

/datum/objective_item/steal/jetpack
	name = "реактивный ранец Капитана."
	targetitem = /obj/item/tank/jetpack/oxygen/captain
	difficulty = 5
	excludefromjob = list("Captain")

/datum/objective_item/steal/magboots
	name = "усовершенствованные Магнитные Ботинки Главного Инженера."
	targetitem =  /obj/item/clothing/shoes/magboots/advance
	difficulty = 5
	excludefromjob = list("Chief Engineer", "Station Engineer", "Atmospheric Technician")

/datum/objective_item/steal/capmedal
	name = "медаль Капитана."
	targetitem = /obj/item/clothing/accessory/medal/gold/captain
	difficulty = 10
	excludefromjob = list("Captain")

/datum/objective_item/steal/hypo
	name = "гипоспрей MKII Главного Врача."
	targetitem = /obj/item/hypospray/mkii/CMO //CITADEL EDIT, changing theft objective for the Hypo MK II
	difficulty = 5
	excludefromjob = list("Chief Medical Officer", "Medical Doctor", "Chemist", "Virologist", "Geneticist")

/datum/objective_item/steal/nukedisc
	name = "Диск Ядерной Аутентификации."
	targetitem = /obj/item/disk/nuclear
	difficulty = 5
	excludefromjob = list("Captain")

/datum/objective_item/steal/nukedisc/check_special_completion(obj/item/disk/nuclear/N)
	return !N.fake

/datum/objective_item/steal/reflector
	name = "Жилет со Светоотражателями из Арсенала."
	targetitem = /obj/item/clothing/suit/hooded/ablative
	difficulty = 3
	excludefromjob = list("Head of Security", "Warden")

/datum/objective_item/steal/reactive
	name = "Реактивная Телепортационная Броня."
	targetitem = /obj/item/clothing/suit/armor/reactive
	difficulty = 5
	excludefromjob = list("Research Director","Scientist", "Roboticist")

/datum/objective_item/steal/documents
	name = "Секретные Документы."
	targetitem = /obj/item/documents //Any set of secret documents. Doesn't have to be NT's
	difficulty = 5

/datum/objective_item/steal/stamp
	name = "печать представителя Корпорации."
	targetitem = /obj/item/stamp/ntr
	difficulty = 2
	excludefromjob = list("NanoTrasen Representative")
	altitems = /obj/item/stamp/syndicate

/datum/objective_item/steal/krav_maga
	name = "особые перчатки Смотрителя службы безопасности."
	targetitem = /obj/item/clothing/gloves/krav_maga/sec
	difficulty = 10

/datum/objective_item/steal/blackbox
	name = "черный ящик из бортового устройства записи. Позаботьтесь о том, чтобы при извлечении черного ящика вы использовали соответствующее оборудование безопасности, так как телекоммуникационный массив, скорее всего, будет находиться в негостеприимных, особо холодных условиях."
	targetitem = /obj/item/blackbox //steal the forbidden ssblackbox
	difficulty = 10

/datum/objective_item/steal/nuke_core
	name = "радиоактивное плутониевое ядро из Бортовой Системы Самоуничтожения. При извлечении активной зоны необходимо использовать соответствующие средства безопасности!"
	targetitem = /obj/item/nuke_core
	difficulty = 15

/datum/objective_item/steal/nuke_core/New()
	special_equipment += /obj/item/storage/box/syndie_kit/nuke
	..()

/datum/objective_item/steal/supermatter
	name = "осколок кристалла Суперматерии. При извлечении осколка обязательно используйте надлежащее оборудование для обеспечения безопасности!"
	targetitem = /obj/item/nuke_core/supermatter_sliver
	difficulty = 15

/datum/objective_item/steal/supermatter/New()
	special_equipment += /obj/item/storage/box/syndie_kit/supermatter
	..()

/datum/objective_item/steal/supermatter/TargetExists()
	return GLOB.main_supermatter_engine != null

//Items with special checks!
/datum/objective_item/steal/plasma
	name = "двадцать восемь молей плазмы (полный баллон)."
	targetitem = /obj/item/tank
	difficulty = 3
	excludefromjob = list("Chief Engineer","Research Director","Station Engineer","Scientist","Atmospheric Technician")

/datum/objective_item/steal/plasma/check_special_completion(obj/item/tank/T)
	var/target_amount = text2num(name)
	var/found_amount = 0
	found_amount += T.air_contents.get_moles(GAS_PLASMA)
	return found_amount>=target_amount


/datum/objective_item/steal/functionalai
	name = "функциональный Искусственный Интеллект."
	targetitem = /obj/item/aicard
	difficulty = 20 //beyond the impossible

/datum/objective_item/steal/functionalai/check_special_completion(obj/item/aicard/C)
	for(var/mob/living/silicon/ai/A in C)
		if(isAI(A) && A.stat != DEAD) //See if any AI's are alive inside that card.
			return TRUE
	return FALSE

/datum/objective_item/steal/blueprints
	name = "Чертежи Станции."
	targetitem = /obj/item/areaeditor/blueprints
	difficulty = 10
	excludefromjob = list("Chief Engineer", "Station Engineer", "Atmospheric Technician")
	altitems = list(/obj/item/photo)

/datum/objective_item/steal/blueprints/check_special_completion(obj/item/I)
	if(istype(I, /obj/item/areaeditor/blueprints))
		return TRUE
	if(istype(I, /obj/item/photo))
		var/obj/item/photo/P = I
		if(P.picture.has_blueprints)	//if the blueprints are in frame
			return TRUE
	return FALSE

/datum/objective_item/steal/slime
	name = "неиспользованный Образец Экстракта Слизи."
	targetitem = /obj/item/slime_extract
	difficulty = 3
	excludefromjob = list("Research Director","Scientist", "Roboticist")

/datum/objective_item/steal/slime/check_special_completion(obj/item/slime_extract/E)
	if(E.Uses > 0)
		return TRUE
	return FALSE

//Unique Objectives
/datum/objective_item/unique/docs_red
	name = "\"Красные\" секретные документы."
	targetitem = /obj/item/documents/syndicate/red
	difficulty = 10

/datum/objective_item/unique/docs_blue
	name = "\"Голубые\" секретные документы."
	targetitem = /obj/item/documents/syndicate/blue
	difficulty = 10

/datum/objective_item/special/New()
	..()
	if(TargetExists())
		GLOB.possible_items_special += src
	else
		qdel(src)

/datum/objective_item/special/Destroy()
	GLOB.possible_items_special -= src
	return ..()

//Old ninja objectives.
/datum/objective_item/special/pinpointer/nuke
	name = "the captain's pinpointer."
	targetitem = /obj/item/pinpointer
	difficulty = 10

/datum/objective_item/special/aegun
	name = "an advanced energy gun."
	targetitem = /obj/item/gun/energy/e_gun/nuclear
	difficulty = 10

/datum/objective_item/special/ddrill
	name = "a diamond drill."
	targetitem = /obj/item/pickaxe/drill/diamonddrill
	difficulty = 10

/datum/objective_item/special/boh
	name = "a type of bag of holding."
	targetitem = /obj/item/storage/backpack/holding
	difficulty = 10

/datum/objective_item/special/adv_surgical_drapes
	name = "a set of smart surgical drapes."
	targetitem = /obj/item/surgical_drapes/advanced
	difficulty = 10 //would be 15 but cmo rarely have it on themselfs and leave it in their lockers...

/datum/objective_item/special/bluespace
	name = "a bluespace power cell."
	targetitem = /obj/item/stock_parts/cell/bluespace
	difficulty = 5

/datum/objective_item/special/laserpointer
	name = "a laser pointer."
	targetitem = /obj/item/laser_pointer
	difficulty = 5

/datum/objective_item/special/corgimeat
	name = "a piece of corgi meat."
	targetitem = /obj/item/reagent_containers/food/snacks/meat/slab/corgi
	difficulty = 5

/datum/objective_item/stack/New()
	..()
	if(TargetExists())
		GLOB.possible_items_special += src
	else
		qdel(src)

/datum/objective_item/stack/Destroy()
	GLOB.possible_items_special -= src
	return ..()

//Stack objectives get their own subtype
/datum/objective_item/stack
	name = "пять картонок."
	targetitem = /obj/item/stack/sheet/cardboard
	difficulty = 9001

/datum/objective_item/stack/check_special_completion(obj/item/stack/S)
	var/target_amount = text2num(name)
	var/found_amount = 0

	if(istype(S, targetitem))
		found_amount = S.amount
	return found_amount>=target_amount

/datum/objective_item/stack/diamond
	name = "десять алмазов."
	targetitem = /obj/item/stack/sheet/mineral/diamond
	difficulty = 10

/datum/objective_item/stack/gold
	name = "пятьдесят слитков золота."
	targetitem = /obj/item/stack/sheet/mineral/gold
	difficulty = 15

/datum/objective_item/stack/uranium
	name = "двадцать пять слитков обработанного урана."
	targetitem = /obj/item/stack/sheet/mineral/uranium
	difficulty = 10

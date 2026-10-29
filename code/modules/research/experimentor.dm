//this is designed to replace the destructive analyzer

//NEEDS MAJOR CODE CLEANUP

#define SCANTYPE_POKE 1
#define SCANTYPE_IRRADIATE 2
#define SCANTYPE_GAS 3
#define SCANTYPE_HEAT 4
#define SCANTYPE_COLD 5
#define SCANTYPE_OBLITERATE 6
#define SCANTYPE_DISCOVER 7

#define EFFECT_PROB_VERYLOW 20
#define EFFECT_PROB_LOW 35
#define EFFECT_PROB_MEDIUM 50
#define EFFECT_PROB_HIGH 75
#define EFFECT_PROB_VERYHIGH 95

#define FAIL 8
/obj/machinery/rnd/experimentor
	name = "\improper E.X.P.E.R.I-MENTOR"
	desc = "\"Замена\" деструктивному анализатору с лёгкой склонностью к катастрофам."
	icon = 'icons/obj/machines/heavy_lathe.dmi'
	icon_state = "h_lathe"
	density = TRUE
	use_power = IDLE_POWER_USE
	circuit = /obj/item/circuitboard/machine/experimentor
	var/recentlyExperimented = 0
	/// Global pets are optional targets, not machine-owned objects. Strong
	/// references here made every experimentor keep a deleted pet alive.
	var/datum/weakref/trackedIan
	var/datum/weakref/trackedRuntime
	var/badThingCoeff = 0
	var/resetTime = 15
	var/cloneMode = FALSE
	var/list/item_reactions = list()
	var/list/valid_items = list() //valid items for special reactions like transforming
	var/list/critical_items = list() //items that can cause critical reactions

/obj/machinery/rnd/experimentor/proc/ConvertReqString2List(list/source_list)
	var/list/temp_list = params2list(source_list)
	for(var/O in temp_list)
		temp_list[O] = text2num(temp_list[O])
	return temp_list


/obj/machinery/rnd/experimentor/proc/SetTypeReactions()
	for(var/I in typesof(/obj/item))
		if(ispath(I, /obj/item/relic))
			item_reactions["[I]"] = SCANTYPE_DISCOVER
		else
			item_reactions["[I]"] = pick(SCANTYPE_POKE,SCANTYPE_IRRADIATE,SCANTYPE_GAS,SCANTYPE_HEAT,SCANTYPE_COLD,SCANTYPE_OBLITERATE)

		if(ispath(I, /obj/item/stock_parts) || ispath(I, /obj/item/grenade/chem_grenade) || ispath(I, /obj/item/kitchen))
			var/obj/item/tempCheck = I
			if(initial(tempCheck.icon_state) != null) //check it's an actual usable item, in a hacky way
				if(ispath(I, /obj/item/grenade/chem_grenade/tuberculosis))
					continue
				valid_items["[I]"] += 15

		if(ispath(I, /obj/item/reagent_containers/food))
			var/obj/item/tempCheck = I
			if(initial(tempCheck.icon_state) != null) //check it's an actual usable item, in a hacky way
				valid_items["[I]"] += rand(1,4)

		if(ispath(I, /obj/item/construction/rcd) || ispath(I, /obj/item/grenade) || ispath(I, /obj/item/aicard) || ispath(I, /obj/item/storage/backpack/holding) || ispath(I, /obj/item/slime_extract) || ispath(I, /obj/item/onetankbomb) || ispath(I, /obj/item/transfer_valve))
			var/obj/item/tempCheck = I
			if(initial(tempCheck.icon_state) != null)
				critical_items += I

/obj/machinery/rnd/experimentor/Initialize(mapload)
	. = ..()

	trackedIan = WEAKREF(locate(/mob/living/simple_animal/pet/dog/corgi/Ian) in GLOB.mob_living_list)
	trackedRuntime = WEAKREF(locate(/mob/living/simple_animal/pet/cat/Runtime) in GLOB.mob_living_list)
	SetTypeReactions()

/obj/machinery/rnd/experimentor/RefreshParts()
	resetTime = 20 //17-> 5
	badThingCoeff = -4 //0 -> 16
	for(var/obj/item/stock_parts/manipulator/M in component_parts) //X2
		resetTime -= M.rating*1.5
	for(var/obj/item/stock_parts/scanning_module/M in component_parts)
		badThingCoeff += M.rating*2
	for(var/obj/item/stock_parts/micro_laser/M in component_parts) //X2
		badThingCoeff += M.rating

/obj/machinery/rnd/experimentor/examine_display_content(mob/user)
	. += "– Вероятность сбоя снижена на <b>[badThingCoeff]%</b>.\n\
	– Интервал между экспериментами: <b>[resetTime / (1 SECONDS)]</b> с."

/obj/machinery/rnd/experimentor/proc/checkCircumstances(obj/item/O)
	//snowflake check to only take "made" bombs
	if(istype(O, /obj/item/transfer_valve))
		var/obj/item/transfer_valve/T = O
		if(!T.tank_one || !T.tank_two || !T.attached_device)
			return FALSE
	return TRUE

/obj/machinery/rnd/experimentor/Insert_Item(obj/item/O, mob/user)
	if(user.a_intent != INTENT_HARM)
		. = 1
		if(!is_insertion_ready(user))
			return
		if(!user.transferItemToLoc(O, src))
			return
		loaded_item = O
		to_chat(user, span_notice("Вы помещаете [O] в машину."))
		flick("h_lathe_load", src)

/obj/machinery/rnd/experimentor/default_deconstruction_crowbar(obj/item/O)
	ejectItem()
	. = ..(O)

/obj/machinery/rnd/experimentor/ui_interact(mob/user)
	var/list/dat = list("<center>")
	if(!linked_console)
		dat += "<b><a href='byond://?src=[REF(src)];function=search'>Найти консоль R&D</A></b>"
	if(loaded_item)
		dat += "<b>Загруженный предмет:</b> [loaded_item]"

		dat += "<div>Доступные тесты:"
		dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_POKE]'>Ткнуть</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_IRRADIATE];'>Облучить</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_GAS]'>Газ</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_HEAT]'>Нагреть</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_COLD]'>Заморозить</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_OBLITERATE]'>Уничтожить</A></b></div>"
		if(istype(loaded_item,/obj/item/relic))
			dat += "<b><a href='byond://?src=[REF(src)];item=[REF(loaded_item)];function=[SCANTYPE_DISCOVER]'>Изучить</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];function=eject'>Извлечь</A>"
		var/list/listin = techweb_item_boost_check(src)
		if(listin)
			var/list/output = list("<b><font color='purple'>Данные об ускорении исследований:</font></b>")
			var/list/res = list("<b><font color='blue'>Уже исследовано:</font></b>")
			var/list/boosted = list("<b><font color='red'>Уже ускорено:</font></b>")
			for(var/node_id in listin)
				if(!node_id)
					continue
				var/datum/techweb_node/N = SSresearch.techweb_node_by_id(node_id)
				if(!N)
					continue
				var/str = "<b>[N.display_name]</b>: очков — [listin[node_id]].</b>"
				if(SSresearch.science_tech.researched_nodes[N.id])
					res += str
				else if(SSresearch.science_tech.boosted_nodes[N.id])
					boosted += str
				if(SSresearch.science_tech.visible_nodes[N.id])	//JOY OF DISCOVERY!
					output += str
			output += boosted + res
			dat += output
		dat += "<b><a href='byond://?src=[REF(src)];function=recalibrate'>Рекалибровать алгоритм</A></b>"
	else
		dat += "<b>Ничего не загружено.</b>"
	dat += "<a href='byond://?src=[REF(src)];function=refresh'>Обновить</A>"
	dat += "<a href='byond://?src=[REF(src)];close=1'>Закрыть</A></center>"
	var/datum/browser/popup = new(user, "experimentor","Экспериментатор", 700, 400, src)
	popup.set_content(dat.Join("<br>"))
	popup.open()
	onclose(user, "experimentor")

/obj/machinery/rnd/experimentor/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)

	var/scantype = href_list["function"]
	var/obj/item/process = locate(href_list["item"]) in src

	if(href_list["close"])
		usr << browse(null, "window=experimentor")
		return
	if(scantype == "search")
		var/obj/machinery/computer/rdconsole/D = locate(/obj/machinery/computer/rdconsole) in oview(3,src)
		if(D)
			linked_console = D
	else if(scantype == "eject")
		ejectItem()
	else if(scantype == "recalibrate") //SPLURT EDIT - RECALIBRATE SCAN TYPES
		SetTypeReactions()
		to_chat(usr, span_notice("Выполнена рекалибровка [src]: выбраны новые возможные алгоритмы сканирования."))
	else if(scantype == "refresh")
		updateUsrDialog()
	else
		if(recentlyExperimented)
			to_chat(usr, span_warning("Слишком рано для повторного использования [src]!"))
		else if(!loaded_item)
			to_chat(usr, span_warning("В [src] ничего не загружено!"))
		else if(!process || process != loaded_item) //Interface exploit protection (such as hrefs or swapping items with interface set to old item)
			to_chat(usr, span_danger("В интерфейсе [src] обнаружен сбой. Попробуйте ещё раз."))
		else
			var/dotype
			if(text2num(scantype) == SCANTYPE_DISCOVER)
				dotype = SCANTYPE_DISCOVER
			else
				dotype = matchReaction(process,scantype)
			experiment(dotype,process)
			use_power(750)
			if(dotype != FAIL)
				var/list/nodes = techweb_item_boost_check(process)
				var/picked = length(nodes) ? pickweight(nodes) : null
				if(picked && linked_console && !QDELETED(linked_console) && linked_console.stored_research)	//BLUEMOON ADD: !QDELETED — консоль могла быть уничтожена; && stored_research — консоль без подключённой сети
					var/datum/techweb_node/boost_node = SSresearch.techweb_node_by_id(picked)
					if(boost_node)
						linked_console.stored_research.boost_with_path(boost_node, process.type)
	updateUsrDialog()

/obj/machinery/rnd/experimentor/proc/matchReaction(matching,reaction)
	var/obj/item/D = matching
	if(D)
		if(item_reactions.Find("[D.type]"))
			var/tor = item_reactions["[D.type]"]
			if(tor == text2num(reaction))
				return tor
			else
				return FAIL
		else
			return FAIL
	else
		return FAIL

/obj/machinery/rnd/experimentor/proc/ejectItem(delete=FALSE)
	if(loaded_item)
		if(cloneMode)
			visible_message(span_notice("Выскакивает дубликат [loaded_item]!"))
			var/type_to_make = loaded_item.type
			new type_to_make(get_turf(pick(oview(1,src))))
			cloneMode = FALSE
			return
		var/turf/dropturf = get_turf(pick(view(1,src)))
		if(!dropturf) //Failsafe to prevent the object being lost in the void forever.
			dropturf = drop_location()
		loaded_item.forceMove(dropturf)
		if(delete)
			qdel(loaded_item)
		loaded_item = null

/obj/machinery/rnd/experimentor/proc/throwSmoke(turf/where)
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(0, where)
	smoke.start()


/obj/machinery/rnd/experimentor/proc/experiment(exp,obj/item/exp_on)
	recentlyExperimented = 1
	icon_state = "h_lathe_wloop"
	var/chosenchem
	var/criticalReaction = (exp_on.type in critical_items) ? TRUE : FALSE
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == SCANTYPE_POKE)
		visible_message("[src] тычет механическими манипуляторами в [exp_on].")
		if(prob(EFFECT_PROB_LOW) && criticalReaction)
			visible_message("[exp_on] идеально зажимается, что повышает фокусировку.")
			badThingCoeff++
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			visible_message(span_danger("[src] даёт сбой и уничтожает [exp_on], размахивая манипуляторами по находящимся рядом существам!"))
			for(var/mob/living/m in oview(1, src))
				m.apply_damage(15, BRUTE, pick(BODY_ZONE_HEAD,BODY_ZONE_CHEST,BODY_ZONE_PRECISE_GROIN))
				investigate_log("Experimentor dealt minor brute to [m].", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_LOW-badThingCoeff))
			visible_message(span_warning("[src] даёт сбой!"))
			exp = SCANTYPE_OBLITERATE
		else if(prob(EFFECT_PROB_MEDIUM-badThingCoeff))
			visible_message(span_danger("[src] даёт сбой и выбрасывает [exp_on]!"))
			var/mob/living/target = locate(/mob/living) in oview(7,src)
			if(target)
				var/obj/item/throwing = loaded_item
				investigate_log("Experimentor has thrown [loaded_item] at [key_name(target)]", INVESTIGATE_EXPERIMENTOR)
				ejectItem()
				if(throwing)
					throwing.throw_at(target, 10, 1)
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == SCANTYPE_IRRADIATE)
		visible_message(span_danger("[src] направляет радиоактивные лучи на [exp_on]!"))
		if(prob(EFFECT_PROB_LOW) && criticalReaction)
			visible_message("В [exp_on] активируется неизвестная подпрограмма!")
			cloneMode = TRUE
			investigate_log("Experimentor has made a clone of [exp_on]", INVESTIGATE_EXPERIMENTOR)
			ejectItem()
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			visible_message(span_danger("[src] даёт сбой, плавя [exp_on] и излучая радиацию!"))
			radiation_pulse(src, 500)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_LOW-badThingCoeff))
			visible_message(span_warning("[src] даёт сбой, извергая токсичные отходы!"))
			for(var/turf/T in oview(1, src))
				if(!T.density)
					if(prob(EFFECT_PROB_VERYHIGH) && !(locate(/obj/effect/decal/cleanable/greenglow) in T))
						var/obj/effect/decal/cleanable/reagentdecal = new/obj/effect/decal/cleanable/greenglow(T)
						reagentdecal.reagents.add_reagent(/datum/reagent/radium, 7)
		else if(prob(EFFECT_PROB_MEDIUM-badThingCoeff))
			var/savedName = "[exp_on]"
			ejectItem(TRUE)
			var/newPath = text2path(pickweight(valid_items))
			loaded_item = new newPath(src)
			visible_message(span_warning("[src] даёт сбой, превращая [savedName] в [loaded_item]!"))
			investigate_log("Experimentor has transformed [savedName] into [loaded_item]", INVESTIGATE_EXPERIMENTOR)
			if(istype(loaded_item, /obj/item/grenade/chem_grenade))
				var/obj/item/grenade/chem_grenade/CG = loaded_item
				CG.prime()
			ejectItem()
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == SCANTYPE_GAS)
		visible_message(span_warning("[src] наполняет камеру газом вместе с [exp_on]."))
		if(prob(EFFECT_PROB_LOW) && criticalReaction)
			visible_message("[exp_on] достигает идеальной смеси!")
			new /obj/item/stack/sheet/mineral/plasma(get_turf(pick(oview(1,src))))
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			visible_message(span_danger("[src] уничтожает [exp_on], выпуская опасный газ!"))
			chosenchem = pick(/datum/reagent/carbon,/datum/reagent/radium,/datum/reagent/toxin,
							/datum/reagent/consumable/condensedcapsaicin,/datum/reagent/drug/mushroomhallucinogen,
							/datum/reagent/drug/space_drugs,/datum/reagent/consumable/ethanol,/datum/reagent/consumable/ethanol/beepsky_smash)
			var/datum/reagents/R = new/datum/reagents(50)
			R.my_atom = src
			R.add_reagent(chosenchem , 50)
			investigate_log("Experimentor has released [chosenchem] smoke.", INVESTIGATE_EXPERIMENTOR)
			var/datum/effect_system/smoke_spread/chem/smoke = new
			smoke.set_up(R, 0, src, silent = TRUE)
			playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
			smoke.start()
			qdel(R)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			visible_message(span_danger("В химической камере [src] образовалась течь!"))
			chosenchem = pick(/datum/reagent/mutationtoxin,/datum/reagent/nanomachines,/datum/reagent/toxin/acid)
			var/datum/reagents/R = new/datum/reagents(50)
			R.my_atom = src
			R.add_reagent(chosenchem , 50)
			var/datum/effect_system/smoke_spread/chem/smoke = new
			smoke.set_up(R, 0, src, silent = TRUE)
			playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
			smoke.start()
			qdel(R)
			ejectItem(TRUE)
			warn_admins(usr, "[chosenchem] smoke")
			investigate_log("Experimentor has released <font color='red'>[chosenchem]</font> smoke!", INVESTIGATE_EXPERIMENTOR)
		else if(prob(EFFECT_PROB_LOW-badThingCoeff))
			visible_message("[src] даёт сбой, выпуская безвредный газ.")
			throwSmoke(loc)
		else if(prob(EFFECT_PROB_MEDIUM-badThingCoeff))
			visible_message(span_warning("[src] плавит [exp_on], ионизируя воздух вокруг!"))
			empulse_using_range(loc, 9)
			investigate_log("Experimentor has generated an Electromagnetic Pulse.", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == SCANTYPE_HEAT)
		visible_message("[src] повышает температуру [exp_on].")
		if(prob(EFFECT_PROB_LOW) && criticalReaction)
			visible_message(span_warning("Аварийная система охлаждения [src] издаёт тихий звоночек!"))
			playsound(src, 'sound/machines/ding.ogg', 50, 1)
			var/obj/item/reagent_containers/food/drinks/coffee/C = new /obj/item/reagent_containers/food/drinks/coffee(get_turf(pick(oview(1,src))))
			chosenchem = pick(/datum/reagent/toxin/plasma,/datum/reagent/consumable/capsaicin,/datum/reagent/consumable/ethanol)
			C.reagents.remove_any(25)
			C.reagents.add_reagent(chosenchem , 50)
			C.name = "Чашка подозрительной жидкости"
			C.desc = "На боку выцветающими чернилами нанесён большой знак опасности."
			investigate_log("Experimentor has made a cup of [chosenchem] coffee.", INVESTIGATE_EXPERIMENTOR)
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			var/turf/start = get_turf(src)
			var/mob/M = locate(/mob/living) in view(src, 3)
			var/turf/MT = get_turf(M)
			if(MT)
				visible_message(span_danger("[src] опасно перегревается и запускает сгусток горящего топлива!"))
				investigate_log("Experimentor has launched a <font color='red'>fireball</font> at [M]!", INVESTIGATE_EXPERIMENTOR)
				var/obj/item/projectile/magic/aoe/fireball/FB = new /obj/item/projectile/magic/aoe/fireball(start)
				FB.preparePixelProjectile(MT, start)
				FB.fire()
		else if(prob(EFFECT_PROB_LOW-badThingCoeff))
			visible_message(span_danger("[src] даёт сбой, плавя [exp_on] и выпуская вспышку пламени!"))
			explosion(loc, -1, 0, 0, 0, 0, flame_range = 2)
			investigate_log("Experimentor started a fire.", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_MEDIUM-badThingCoeff))
			visible_message(span_warning("[src] даёт сбой, плавя [exp_on] и выпуская горячий воздух!"))
			var/datum/gas_mixture/env = loc.return_air()
			env.adjust_heat(100000)
			air_update_turf()
			investigate_log("Experimentor has released hot air.", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_MEDIUM-badThingCoeff))
			visible_message(span_warning("[src] даёт сбой, включая аварийные системы охлаждения!"))
			throwSmoke(loc)
			for(var/mob/living/m in oview(1, src))
				m.apply_damage(5, BURN, pick(BODY_ZONE_HEAD,BODY_ZONE_CHEST,BODY_ZONE_PRECISE_GROIN))
				investigate_log("Experimentor has dealt minor burn damage to [key_name(m)]", INVESTIGATE_EXPERIMENTOR)
			ejectItem()
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == SCANTYPE_COLD)
		visible_message("[src] понижает температуру [exp_on].")
		if(prob(EFFECT_PROB_LOW) && criticalReaction)
			visible_message(span_warning("Аварийная система охлаждения [src] издаёт тихий звоночек!"))
			var/obj/item/reagent_containers/food/drinks/coffee/C = new /obj/item/reagent_containers/food/drinks/coffee(get_turf(pick(oview(1,src))))
			playsound(src, 'sound/machines/ding.ogg', 50, 1) //Ding! Your death coffee is ready!
			chosenchem = pick(/datum/reagent/uranium,/datum/reagent/consumable/frostoil,/datum/reagent/medicine/ephedrine)
			C.reagents.remove_any(25)
			C.reagents.add_reagent(chosenchem , 50)
			C.name = "Чашка подозрительной жидкости"
			C.desc = "На боку выцветающими чернилами нанесён большой знак опасности."
			investigate_log("Experimentor has made a cup of [chosenchem] coffee.", INVESTIGATE_EXPERIMENTOR)
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			visible_message(span_danger("[src] даёт сбой, разбивая [exp_on] и выпуская опасное облако хладагента!"))
			var/datum/reagents/R = new/datum/reagents(50)
			R.my_atom = src
			R.add_reagent(/datum/reagent/consumable/frostoil, 50)
			investigate_log("Experimentor has released frostoil gas.", INVESTIGATE_EXPERIMENTOR)
			var/datum/effect_system/smoke_spread/chem/smoke = new
			smoke.set_up(R, 0, src, silent = TRUE)
			playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
			smoke.start()
			qdel(R)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_LOW-badThingCoeff))
			visible_message(span_warning("[src] даёт сбой, разбивая [exp_on] и выпуская холодный воздух!"))
			var/datum/gas_mixture/env = loc.return_air()
			env.adjust_heat(-75000)
			air_update_turf()
			investigate_log("Experimentor has released cold air.", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
		else if(prob(EFFECT_PROB_MEDIUM-badThingCoeff))
			visible_message(span_warning("[src] даёт сбой, выпуская порыв холодного воздуха, пока [exp_on] выскакивает наружу!"))
			var/datum/effect_system/smoke_spread/smoke = new
			smoke.set_up(0, loc)
			smoke.start()
			ejectItem()
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == SCANTYPE_OBLITERATE)
		visible_message(span_warning("[src] активирует дробильный механизм, [exp_on] уничтожается!"))
		if(linked_console.linked_lathe)
			var/datum/component/material_container/linked_materials = linked_console.linked_lathe.GetComponent(/datum/component/material_container)
			for(var/material in exp_on.custom_materials)
				linked_materials.insert_amount_mat( min((linked_materials.max_amount - linked_materials.total_amount), (exp_on.custom_materials[material])), material)
		if(prob(EFFECT_PROB_LOW) && criticalReaction)
			visible_message(span_warning("Дробильный механизм [src] медленно и плавно опускается, расплющивая [exp_on]!"))
			new /obj/item/stack/sheet/plasteel(get_turf(pick(oview(1,src))))
		else if(prob(EFFECT_PROB_VERYLOW-badThingCoeff))
			visible_message(span_danger("Дробилка [src] выставляется на слишком, слишком высокий уровень и прорезает пространство-время насквозь!"))
			playsound(src, 'sound/effects/supermatter.ogg', 50, 1, -3)
			investigate_log("Experimentor has triggered the 'throw things' reaction.", INVESTIGATE_EXPERIMENTOR)
			for(var/atom/movable/AM in oview(7,src))
				if(!AM.anchored)
					AM.throw_at(src,10,1)
		else if(prob(EFFECT_PROB_LOW-badThingCoeff))
			visible_message(span_danger("Дробилка [src] выставляется на один уровень выше нормы и вдавливается прямо в пространство-время!"))
			playsound(src, 'sound/effects/supermatter.ogg', 50, 1, -3)
			investigate_log("Experimentor has triggered the 'minor throw things' reaction.", INVESTIGATE_EXPERIMENTOR)
			var/list/throwAt = list()
			for(var/atom/movable/AM in oview(7,src))
				if(!AM.anchored)
					throwAt.Add(AM)
			for(var/counter = 1, counter < throwAt.len, ++counter)
				var/atom/movable/cast = throwAt[counter]
				cast.throw_at(pick(throwAt),10,1)
		ejectItem(TRUE)
	////////////////////////////////////////////////////////////////////////////////////////////////
	if(exp == FAIL)
		var/a = pick("грохочет","трясётся","вибрирует","содрогается")
		var/b = pick("давит","вращается","потрошит","крушит","оскорбляет")
		visible_message(span_warning("[exp_on] [a] и [b], эксперимент провалился."))

	if(exp == SCANTYPE_DISCOVER)
		visible_message("[src] сканирует [exp_on], раскрывая его истинную природу!")
		playsound(src, 'sound/effects/supermatter.ogg', 50, 3, -1)
		var/obj/item/relic/R = loaded_item
		if(!R.revealed) //BLUEMOON ADD награда за изучение
			var/datum/techweb/web = find_rnd_network_for_object(src)
			if(web)
				web.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = pick(5000))) //BLUEMOON ADD END
		R.reveal()
		investigate_log("Experimentor has revealed a relic with <span class='danger'>[R.realProc]</span> effect.", INVESTIGATE_EXPERIMENTOR)
		ejectItem()

	//Global reactions
	if(prob(EFFECT_PROB_VERYLOW-badThingCoeff) && loaded_item)
		var/globalMalf = rand(1,100)
		if(globalMalf < 15)
			visible_message(span_warning("Бортовая система обнаружения [src] вышла из строя!"))
			item_reactions["[exp_on.type]"] = pick(SCANTYPE_POKE,SCANTYPE_IRRADIATE,SCANTYPE_GAS,SCANTYPE_HEAT,SCANTYPE_COLD,SCANTYPE_OBLITERATE)
			ejectItem()
		if(globalMalf > 16 && globalMalf < 35)
			visible_message(span_warning("[src] плавит [exp_on], иан-изируя воздух вокруг!"))
			throwSmoke(loc)
			var/mob/ian = trackedIan?.resolve()
			if(ian)
				throwSmoke(ian.loc)
				ian.forceMove(loc)
				investigate_log("Experimentor has stolen Ian!", INVESTIGATE_EXPERIMENTOR) //...if anyone ever fixes it...
			else
				new /mob/living/simple_animal/pet/dog/corgi(loc)
				investigate_log("Experimentor has spawned a new corgi.", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
		if(globalMalf > 36 && globalMalf < 50)
			visible_message(span_warning("Экспериментатор вытягивает жизненную сущность из находящихся рядом!"))
			for(var/mob/living/m in view(4,src))
				to_chat(m, span_danger("Вы чувствуете, как плоть отрывается от вас, а облака крови тянутся к [src]!"))
				m.apply_damage(50, BRUTE, BODY_ZONE_CHEST)
				investigate_log("Experimentor has taken 50 brute a blood sacrifice from [m]", INVESTIGATE_EXPERIMENTOR)
		if(globalMalf > 51 && globalMalf < 75)
			visible_message(span_warning("[src] сталкивается с ошибкой времени выполнения!"))
			throwSmoke(loc)
			var/mob/runtime_cat = trackedRuntime?.resolve()
			if(runtime_cat)
				throwSmoke(runtime_cat.loc)
				runtime_cat.forceMove(drop_location())
				investigate_log("Experimentor has stolen Runtime!", INVESTIGATE_EXPERIMENTOR)
			else
				new /mob/living/simple_animal/pet/cat(loc)
				investigate_log("Experimentor failed to steal runtime, and instead spawned a new cat.", INVESTIGATE_EXPERIMENTOR)
			ejectItem(TRUE)
		if(globalMalf > 76)
			visible_message(span_warning("[src] начинает дымиться и шипеть, сильно сотрясаясь!"))
			use_power(500000)
			investigate_log("Experimentor has drained power from its APC", INVESTIGATE_EXPERIMENTOR)

	addtimer(CALLBACK(src, PROC_REF(reset_exp)), resetTime)

/obj/machinery/rnd/experimentor/proc/reset_exp()
	update_icon()
	recentlyExperimented = FALSE

/obj/machinery/rnd/experimentor/update_icon_state()
	icon_state = "h_lathe"

/obj/machinery/rnd/experimentor/proc/warn_admins(user, ReactionName)
	var/turf/T = get_turf(user)
	message_admins("Experimentor reaction: [ReactionName] generated by [ADMIN_LOOKUPFLW(user)] at [ADMIN_VERBOSEJMP(T)]")
	log_game("Experimentor reaction: [ReactionName] generated by [key_name(user)] in [AREACOORD(T)]")

#undef SCANTYPE_POKE
#undef SCANTYPE_IRRADIATE
#undef SCANTYPE_GAS
#undef SCANTYPE_HEAT
#undef SCANTYPE_COLD
#undef SCANTYPE_OBLITERATE
#undef SCANTYPE_DISCOVER

#undef EFFECT_PROB_VERYLOW
#undef EFFECT_PROB_LOW
#undef EFFECT_PROB_MEDIUM
#undef EFFECT_PROB_HIGH
#undef EFFECT_PROB_VERYHIGH

#undef FAIL


//////////////////////////////////SPECIAL ITEMS////////////////////////////////////////

/obj/item/relic
	name = "strange object"
	desc = "Какие тайны это может хранить?"
	icon = 'icons/obj/assemblies.dmi'
	var/realName = "defined object"
	var/revealed = FALSE
	var/realProc
	var/cooldownMax = 60
	var/cooldown

/obj/item/relic/Initialize(mapload)
	. = ..()
	icon_state = pick("shock_kit","armor-igniter-analyzer","infra-igniter0","infra-igniter1","radio-multitool","prox-radio1","radio-radio","timer-multitool0","radio-igniter-tank")
	realName = "[pick("broken","twisted","spun","improved","silly","regular","badly made")] [pick("device","object","toy","illegal tech","weapon")]"


/obj/item/relic/proc/reveal()
	if(revealed) //Re-rolling your relics seems a bit overpowered, yes?
		return
	revealed = TRUE
	name = realName
	cooldownMax = rand(60,300)
	realProc = pick("teleport","explode","rapidDupe","petSpray","flash","clean","corgicannon")

/obj/item/relic/attack_self(mob/user)
	if(revealed)
		if(cooldown)
			to_chat(user, span_warning("[src] не реагирует!"))
			return
		else if(loc == user)
			cooldown = TRUE
			call(src,realProc)(user)
			if(!QDELETED(src))
				addtimer(CALLBACK(src, PROC_REF(cd)), cooldownMax)
	else
		to_chat(user, span_notice("Вы пока не совсем понимаете, что с этим делать."))

/obj/item/relic/proc/cd()
	cooldown = FALSE

//////////////// RELIC PROCS /////////////////////////////

/obj/item/relic/proc/throwSmoke(turf/where)
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(0, get_turf(where))
	smoke.start()

/obj/item/relic/proc/corgicannon(mob/user)
	playsound(src, "sparks", rand(25,50), 1)
	var/mob/living/simple_animal/pet/dog/corgi/C = new/mob/living/simple_animal/pet/dog/corgi(get_turf(user))
	C.throw_at(pick(oview(10,user)), 10, rand(3,8), callback = CALLBACK(src, PROC_REF(throwSmoke), C))
	warn_admins(user, "Corgi Cannon", 0)

/obj/item/relic/proc/clean(mob/user)
	playsound(src, "sparks", rand(25,50), 1)
	var/obj/item/grenade/chem_grenade/cleaner/CL = new/obj/item/grenade/chem_grenade/cleaner(get_turf(user))
	CL.prime()
	warn_admins(user, "Smoke", 0)

/obj/item/relic/proc/flash(mob/user)
	playsound(src, "sparks", rand(25,50), 1)
	var/obj/item/grenade/flashbang/CB = new/obj/item/grenade/flashbang(user.loc)
	CB.prime()
	warn_admins(user, "Flash")

/obj/item/relic/proc/petSpray(mob/user)
	var/message = span_danger("[src] начинает трястись, а вдали слышится шум разъярённых животных!")
	visible_message(message)
	to_chat(user, message)
	var/animals = rand(1,25)
	var/counter
	var/list/valid_animals = list(/mob/living/simple_animal/parrot, /mob/living/simple_animal/butterfly, /mob/living/simple_animal/pet/cat, /mob/living/simple_animal/pet/dog/corgi, /mob/living/simple_animal/crab, /mob/living/simple_animal/pet/fox, /mob/living/simple_animal/hostile/lizard, /mob/living/simple_animal/mouse, /mob/living/simple_animal/pet/dog/pug, /mob/living/simple_animal/hostile/bear, /mob/living/simple_animal/hostile/poison/bees, /mob/living/simple_animal/hostile/carp)
	for(counter = 1; counter < animals; counter++)
		var/mobType = pick(valid_animals)
		new mobType(get_turf(src))
	warn_admins(user, "Mass Mob Spawn")
	if(prob(60))
		to_chat(user, span_warning("[src] разваливается на части!"))
		qdel(src)

/obj/item/relic/proc/rapidDupe(mob/user)
	audible_message("[src] издаёт громкий хлопок!")
	var/list/dupes = list()
	var/counter
	var/max = rand(5,10)
	for(counter = 1; counter < max; counter++)
		var/obj/item/relic/R = new type(get_turf(src))
		R.name = name
		R.desc = desc
		R.realName = realName
		R.realProc = realProc
		R.revealed = TRUE
		dupes |= R
		R.throw_at(pick(oview(7,get_turf(src))),10,1)
	counter = 0
	QDEL_LIST_IN(dupes, rand(10, 100))
	warn_admins(user, "Rapid duplicator", 0)

/obj/item/relic/proc/explode(mob/user)
	to_chat(user, span_danger("[src] начинает нагреваться!"))
	addtimer(CALLBACK(src, PROC_REF(do_explode), user), rand(35, 100))

/obj/item/relic/proc/do_explode(mob/user)
	if(loc == user)
		visible_message(span_notice("Крышка [src] раскрывается, высвобождая мощный взрыв!"))
		explosion(user.loc, 0, rand(1,5), rand(1,5), rand(1,5), rand(1,5), flame_range = 2)
		warn_admins(user, "Explosion")
		qdel(src) //Comment this line to produce a light grenade (the bomb that keeps on exploding when used)!!

/obj/item/relic/proc/teleport(mob/user)
	to_chat(user, span_notice("[src] начинает вибрировать!"))
	addtimer(CALLBACK(src, PROC_REF(do_the_teleport), user), rand(10, 30))

/obj/item/relic/proc/do_the_teleport(mob/user)
	var/turf/userturf = get_turf(user)
	if(loc == user && !is_centcom_level(userturf.z)) //Because Nuke Ops bringing this back on their shuttle, then looting the ERT area is 2fun4you!
		visible_message(span_notice("[src] скручивается и изгибается, перемещаясь!"))
		throwSmoke(userturf)
		do_teleport(user, userturf, 8, asoundin = 'sound/effects/phasein.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
		throwSmoke(get_turf(user))
		warn_admins(user, "Teleport", 0)

//Admin Warning proc for relics
/obj/item/relic/proc/warn_admins(mob/user, RelicType, priority = 1)
	var/turf/T = get_turf(src)
	var/log_msg = "[RelicType] relic used by [key_name(user)] in [AREACOORD(T)]"
	if(priority) //For truly dangerous relics that may need an admin's attention. BWOINK!
		message_admins("[RelicType] relic activated by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(T)]")
	log_game(log_msg)
	investigate_log(log_msg, "experimentor")

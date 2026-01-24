/obj/item/reagent_containers/glass
	name = "glass"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50)
	volume = 50
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	resistance_flags = ACID_PROOF
	container_HP = 2
	var/gulp_size = 5
	var/beingChugged = FALSE

/obj/item/reagent_containers/glass/attack(mob/M, mob/user, obj/target)
	if(!canconsume(M, user))
		return

	if(!reagents || !reagents.total_volume)
		to_chat(user, "<span class='warning'>Внутри [src] пусто!</span>")
		return

	var/gulp_amount = gulp_size
	var/self_fed = M == user
	if(self_fed && ishuman(M))
		var/mob/living/carbon/human/H = M
		gulp_amount = H.self_gulp_size
	if(istype(M))
		if(user.a_intent == INTENT_HARM)
			if(!spillable)
				to_chat(user, span_danger("Закупорено: не вылить!"))
				return
			M.visible_message("<span class='danger'>[user] выливает содержимое [src] на [M]!</span>", \
							"<span class='userdanger'>[user] выливает содержимое [src] на [M]!</span>")
			if(iscatperson(M))
				M.emote("hiss")
			var/R = reagents?.log_list()
			var/mob/thrown_by = thrownby?.resolve()
			if(isturf(target) && reagents.reagent_list.len && thrown_by)
				log_combat(thrown_by, target, "splashed (thrown) [english_list(reagents.reagent_list)]")
				message_admins("[ADMIN_LOOKUPFLW(thrown_by)] splashed (thrown) [english_list(reagents.reagent_list)] on [target] at [ADMIN_VERBOSEJMP(target)].")
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				var/obj/item/bodypart/affecting = H.get_bodypart(check_zone(user.zone_selected))
				reagents.reaction(M, TOUCH, affected_bodypart = affecting)
			else
				reagents.reaction(M, TOUCH)
			log_combat(user, M, "splashed", R)
			var/turf/UT = get_turf(user)
			var/turf/MT = get_turf(M)
			var/turf/OT = get_turf(target)
			log_reagent("SPLASH: attack(target mob [key_name(M)] at [AREACOORD(MT)], from user [key_name(user)] at [AREACOORD(UT)], target object [target] at [AREACOORD(OT)]) - [R]")
			reagents.clear_reagents()
		else
			if(self_fed)
				if(user.zone_selected == BODY_ZONE_PRECISE_MOUTH && !beingChugged)
					beingChugged = TRUE
					user.visible_message("<span class='notice'>[user] начинает выпивать залпом из [src].</span>", \
						"<span class='notice'>Вы пьёте залпом из [src]...</span>")
					if(!do_mob(user, M))
						beingChugged = FALSE
						return
					if(!reagents || !reagents.total_volume)
						beingChugged = FALSE
						return
					gulp_amount = 50
					user.visible_message(span_notice("[user] выпивает залпом из [src]."), \
						span_notice("Вы отпили залпом содержимое [src]."))
					beingChugged = FALSE
				else
					var/turf/T = get_turf(user)
					to_chat(user, "<span class='notice'>Вы отпили глоток из [src].</span>")
					log_reagent("INGESTION: SELF: [key_name(user)] (loc [user.loc] at [AREACOORD(T)]) - [reagents.log_list()]")
			else
				M.visible_message("<span class='danger'>[user] пытается скормить что-то [M].</span>", \
							"<span class='userdanger'>[user] пытается что-то вам скормить.</span>")
				log_combat(user, M, "is attempting to feed", reagents.log_list())
				if(!do_mob(user, M))
					return
				if(!reagents || !reagents.total_volume)
					return // The drink might be empty after the delay, such as by spam-feeding
				var/turf/UT = get_turf(user)		// telekenesis memes
				var/turf/MT = get_turf(M)
				M.visible_message("<span class='danger'>[user] кормит чем-то [M].</span>", "<span class='userdanger'>[user] кормит вас чем-то.</span>")
				log_combat(user, M, "fed", reagents.log_list())
				log_reagent("INGESTION: FED BY: [key_name(user)] (loc [user.loc] at [AREACOORD(UT)]) -> [key_name(M)] (loc [M.loc] at [AREACOORD(MT)]) - [reagents.log_list()]")
			var/fraction = min(gulp_amount/reagents.total_volume, 1)
			reagents.reaction(M, INGEST, fraction)
			reagents.trans_to(M, gulp_amount, log = TRUE)
			playsound(M.loc,'sound/items/drink.ogg', rand(10,50), 1)
			return TRUE

/obj/item/reagent_containers/glass/afterattack(obj/target, mob/user, proximity)
	. = ..()
	if((!proximity) || !check_allowed_items(target,target_self=1))
		return

	if(target.is_refillable()) //Something like a glass. Player probably wants to transfer TO it.
		if(!reagents.total_volume)
			to_chat(user, "<span class='warning'>Внутри [src] пусто!</span>")
			return

		if(target.reagents.holder_full())
			to_chat(user, "<span class='warning'>[target] is full.</span>")
			return

		var/trans = reagents.trans_to(target, amount_per_transfer_from_this, log = "reagentcontainer-glass afterattack transfer to")
		to_chat(user, "<span class='notice'>Вы перелили [trans] u веществ в [target].</span>")

	else if(target.is_drainable()) //A dispenser. Transfer FROM it TO us.
		if(!target.reagents.total_volume)
			to_chat(user, "<span class='warning'>[target] пуст и не может быть заправлен!</span>")
			return

		if(reagents.holder_full())
			to_chat(user, "<span class='warning'>[src] is full.</span>")
			return

		var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, log = "reagentcontainer-glass afterattack fill from")
		to_chat(user, "<span class='notice'>Вы заполнили [src] на [trans] u содержимого [target].</span>")

	else if(reagents.total_volume && reagent_flags & OPENCONTAINER && spillable)
		if(user.a_intent == INTENT_HARM)
			user.visible_message("<span class='danger'>[user] разливает содержимое [src] на [target]!</span>", \
								"<span class='notice'>Вы вылили содержимое [src] на [target].</span>")
			reagents.reaction(target, TOUCH)
			reagents.clear_reagents()

/obj/item/reagent_containers/glass/attackby(obj/item/I, mob/user, params)
	// var/hotness = I.get_temperature()
	// if(hotness && reagents)
	// 	reagents.expose_temperature(hotness)
	// 	to_chat(user, "<span class='notice'>You heat [name] with [I]!</span>")

	if(istype(I, /obj/item/reagent_containers/food/snacks/egg)) //breaking eggs
		var/obj/item/reagent_containers/food/snacks/egg/E = I
		if(reagents)
			if(reagents.total_volume >= reagents.maximum_volume)
				to_chat(user, "<span class='notice'>[src] is full.</span>")
			else
				to_chat(user, "<span class='notice'>Вы сломали скорлупу и вылили [E] в [src].</span>")
				E.reagents.trans_to(src, E.reagents.total_volume, log = "reagentcontainer-glass break egg in")
				qdel(E)
			return
	..()

/obj/item/reagent_containers/glass/beaker
	name = "beaker"
	desc = "Мензурка. Может держать 60 u объёма. Не выдержит экстремальные алканно-кислотные значения pH."
	icon = 'icons/obj/chemical.dmi'
	volume = 60
	icon_state = "beaker"
	item_state = "beaker"
	custom_materials = list(/datum/material/glass=500)
	possible_transfer_amounts = list(5,10,15,20,25,30,50,60)
	container_flags = PH_WEAK|APTFT_ALTCLICK|APTFT_VERB

/obj/item/reagent_containers/glass/beaker/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/reagent_containers/glass/beaker/get_part_rating()
	return reagents.maximum_volume

/obj/item/reagent_containers/glass/beaker/on_reagent_change(changetype)
	update_icon()

/obj/item/reagent_containers/glass/beaker/update_overlays()
	. = ..()
	if(!cached_icon)
		cached_icon = icon_state

	if(reagents.total_volume)
		var/mutable_appearance/filling = mutable_appearance('icons/obj/reagentfillings.dmi', "[cached_icon]10", color = mix_color_from_reagents(reagents.reagent_list))

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 9)
				filling.icon_state = "[cached_icon]-10"
			if(10 to 24)
				filling.icon_state = "[cached_icon]10"
			if(25 to 49)
				filling.icon_state = "[cached_icon]25"
			if(50 to 74)
				filling.icon_state = "[cached_icon]50"
			if(75 to 79)
				filling.icon_state = "[cached_icon]75"
			if(80 to 90)
				filling.icon_state = "[cached_icon]80"
			if(91 to INFINITY)
				filling.icon_state = "[cached_icon]100"
		. += filling

/obj/item/reagent_containers/glass/beaker/jar
	name = "honey jar"
	desc = "Банка из под мёда, может держать до 60 u сладкого удовольствия. Плавится, если у вещества внутри радикальные значения pH."
	icon_state = "honey"

/obj/item/reagent_containers/glass/beaker/glass_dish
	name = "glass dish"
	desc = "Стеклянное блюдце... В него можно налить до 3 u. Плавится, если у вещества внутри радикальные значения pH."
	custom_materials = list(/datum/material/glass = 500)
	icon_state = "glass_disk"
	possible_transfer_amounts = list(0.1,0.5,0.75,1,2,3)
	volume = 3

/obj/item/reagent_containers/glass/beaker/flask/large
	name = "large flask"
	desc = "Большая колба, объёмом в 80 u. Плавится, если у вещества внутри радикальные значения pH."
	custom_materials = list(/datum/material/glass = 2500)
	icon_state = "flasklarge"
	volume = 80

/obj/item/reagent_containers/glass/beaker/flask
	name = "small flask"
	desc = "Малая колба, объёмом в 40 u. Плавится, если у вещества внутри радикальные значения pH."
	custom_materials = list(/datum/material/glass = 1000)
	icon_state = "flasksmall"
	volume = 40

/obj/item/reagent_containers/glass/beaker/flask/spouty
	name = "flask with spout"
	desc = "Колба с носиком! Объёмом в 120 u. Плавится, если у вещества внутри радикальные значения pH."
	custom_materials = list(/datum/material/glass = 2500)
	icon_state = "flaskspouty"
	possible_transfer_amounts = list(1,2,3,4,5,10,15,20,25,30,50,100,120)
	volume = 120

/obj/item/reagent_containers/glass/beaker/large
	name = "large beaker"
	desc = "Большая мензурка, объёмом в 120 u. Плавится, если у вещества внутри радикальные значения pH."
	icon_state = "beakerlarge"
	custom_materials = list(/datum/material/glass=2500)
	volume = 120
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,20,25,30,40,50,60,120)
	container_HP = 3

/obj/item/reagent_containers/glass/beaker/plastic
	name = "x-large beaker"
	desc = "Мензурка экстра-размера, объёмом в 180 u. Выдерживает кислотные и алканные растворы, но плавится при температуре 444 K."
	icon_state = "beakerwhite"
	custom_materials = list(/datum/material/glass=2500, /datum/material/plastic=3000)
	volume = 180
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,20,25,30,40,50,60,120,180)
	container_flags = TEMP_WEAK|APTFT_ALTCLICK|APTFT_VERB
	cached_icon = "beakerlarge"

/obj/item/reagent_containers/glass/beaker/meta
	name = "metamaterial beaker"
	desc = "Особо большая мензурка из метаматериалов. Может держать до 240 u и стрессоустойчива к любым химическим задачам."
	icon_state = "beakergold"
	custom_materials = list(/datum/material/glass=2500, /datum/material/plastic=3000, /datum/material/gold=1000, /datum/material/titanium=1000)
	volume = 240
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,20,25,30,40,50,60,120,200,240)
	container_flags = APTFT_ALTCLICK|APTFT_VERB

/obj/item/reagent_containers/glass/beaker/noreact
	name = "cryostasis beaker"
	desc = "Криостазисная мензурка, позволяющая хранить реагенты \
			без реакционного смешивания. Может держать до 50 u."
	icon_state = "beakernoreact"
	custom_materials = list(/datum/material/iron=3000)
	reagent_flags = OPENCONTAINER | NO_REACT
	volume = 50
	amount_per_transfer_from_this = 10
	container_flags = APTFT_ALTCLICK|APTFT_VERB
	container_HP = 10//shouldn't be needed

/obj/item/reagent_containers/glass/beaker/bluespace
	name = "bluespace beaker"
	desc = "Блюспейс-мензурка, улучшенная экспериментальной блюспейс-технологией \
		и технологией Element Cuban в совокупности с технологией Compound Pete. \
		Может держать до 300 u. Не выдержит вещества слишком высоких или низких значений pH."
	icon_state = "beakerbluespace"
	custom_materials = list(/datum/material/glass = 5000, /datum/material/plasma = 3000, /datum/material/diamond = 1000, /datum/material/bluespace = 1000)
	volume = 300
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,20,25,30,50,100,300)
	container_HP = 5

/obj/item/reagent_containers/glass/beaker/cryoxadone
	list_reagents = list(/datum/reagent/medicine/cryoxadone = 30)

/obj/item/reagent_containers/glass/beaker/sulphuric
	list_reagents = list(/datum/reagent/toxin/acid = 50)

/obj/item/reagent_containers/glass/beaker/slime
	list_reagents = list(/datum/reagent/toxin/slimejelly = 50)

/obj/item/reagent_containers/glass/beaker/large/styptic
	name = "styptic reserve tank"
	list_reagents = list(/datum/reagent/medicine/styptic_powder = 50)

/obj/item/reagent_containers/glass/beaker/large/silver_sulfadiazine
	name = "silver sulfadiazine reserve tank"
	list_reagents = list(/datum/reagent/medicine/silver_sulfadiazine = 50)

/obj/item/reagent_containers/glass/beaker/large/charcoal
	name = "charcoal reserve tank"
	list_reagents = list(/datum/reagent/medicine/charcoal = 50)

/obj/item/reagent_containers/glass/beaker/large/epinephrine
	name = "epinephrine reserve tank"
	list_reagents = list(/datum/reagent/medicine/epinephrine = 50)

/obj/item/reagent_containers/glass/beaker/synthflesh
	list_reagents = list(/datum/reagent/medicine/synthflesh = 50)

/obj/item/reagent_containers/glass/bucket
	name = "bucket"
	desc = "Это ведро."
	icon = 'icons/obj/janitor.dmi'
	icon_state = "bucket"
	item_state = "bucket"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	custom_materials = list(/datum/material/iron=200)
	w_class = WEIGHT_CLASS_NORMAL
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = list(5,10,15,20,25,30,40,50,60,120) // BLUEMOON CHANGE подгоняем под большую банку
	volume = 120 // BLUEMOON CHANGE подгоняем под большую банку
	flags_inv = HIDEHAIR
	slot_flags = ITEM_SLOT_HEAD
	resistance_flags = NONE
	armor = list(MELEE = 10, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 75, ACID = 50) //Weak melee protection, because you can wear it on your head
	slot_equipment_priority = list( \
		ITEM_SLOT_BACK, ITEM_SLOT_ID,\
		ITEM_SLOT_UNDERWEAR,\
		ITEM_SLOT_SOCKS,\
		ITEM_SLOT_SHIRT,\
		ITEM_SLOT_ICLOTHING, ITEM_SLOT_OCLOTHING,\
		ITEM_SLOT_MASK, ITEM_SLOT_HEAD, ITEM_SLOT_NECK,\
		ITEM_SLOT_FEET, ITEM_SLOT_WRISTS, ITEM_SLOT_GLOVES,\
		ITEM_SLOT_EARS_LEFT, ITEM_SLOT_EARS_RIGHT,\
		ITEM_SLOT_EYES,\
		ITEM_SLOT_BELT, ITEM_SLOT_SUITSTORE,\
		ITEM_SLOT_LPOCKET, ITEM_SLOT_RPOCKET,\
		ITEM_SLOT_DEX_STORAGE\
	)
	container_flags = APTFT_ALTCLICK|APTFT_VERB
	container_HP = 1

/obj/item/reagent_containers/glass/bucket/attackby(obj/O, mob/user, params)
	if(istype(O, /obj/item/mop))
		var/obj/item/mop/MOP = O
		if(reagents.total_volume < 1)
			to_chat(user, "<span class='warning'>[src] не имеет воды!</span>")
		else
			reagents.trans_to(O, MOP.mopcap, log = "reagentcontainer-bucket fill mop")
			to_chat(user, "<span class='notice'>Вы смочили [O] в [src].</span>")
			playsound(loc, 'sound/effects/slosh.ogg', 25, 1)
	else if(isprox(O))
		to_chat(user, "<span class='notice'>Вы добавили [O] в [src].</span>")
		qdel(O)
		qdel(src)
		user.put_in_hands(new /obj/item/bot_assembly/cleanbot)
	else
		..()

/obj/item/reagent_containers/glass/bucket/equipped(mob/user, slot)
	..()
	if (slot == ITEM_SLOT_HEAD)
		if(reagents.total_volume)
			to_chat(user, "<span class='userdanger'>Содержимое [src] облило вас!</span>")
			var/R = reagents.log_list()
			log_reagent("SPLASH: [user] splashed [src] on their head via bucket/equipped(self, ITEM_SLOT_HEAD) - [R]")
			reagents.reaction(user, TOUCH)
			reagents.clear_reagents()
		reagent_flags = NONE

/obj/item/reagent_containers/glass/bucket/dropped(mob/user)
	. = ..()
	reagent_flags = initial(reagent_flags)

/obj/item/reagent_containers/glass/bucket/equip_to_best_slot(var/mob/M)
	if(reagents.total_volume) //If there is water in a bucket, don't quick equip it to the head
		var/index = slot_equipment_priority.Find(ITEM_SLOT_HEAD)
		slot_equipment_priority.Remove(ITEM_SLOT_HEAD)
		. = ..()
		slot_equipment_priority.Insert(index, ITEM_SLOT_HEAD)
		return
	return ..()

/obj/item/reagent_containers/glass/bucket/wood
	name = "wooden bucket"
	desc = "Деревянное ведро... Сделанное из дерева."
	icon_state = "bucket_wooden"
	custom_materials = list(/datum/material/wood = MINERAL_MATERIAL_AMOUNT * 2)
	slot_flags = NONE
	item_flags = NO_MAT_REDEMPTION

/obj/item/reagent_containers/glass/beaker/waterbottle
	name = "bottle of water"
	desc = "Бутылка воды, наполненная на бутылочном предприятии с Терры."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "smallbottle"
	item_state = "bottle"
	custom_price = PRICE_CHEAP_AS_FREE
	list_reagents = list(/datum/reagent/water = 49.5, /datum/reagent/fluorine = 0.5)//see desc, don't think about it too hard
	custom_materials = list(/datum/material/glass=0)
	volume = 50
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,20,25,30,50)
	container_flags = TEMP_WEAK|APTFT_ALTCLICK|APTFT_VERB
	container_HP = 1

/obj/item/reagent_containers/glass/beaker/waterbottle/empty
	list_reagents = list()

/obj/item/reagent_containers/glass/beaker/waterbottle/large
	desc = "Новенькая бутылка воды потребительских размеров."
	icon_state = "largebottle"
	custom_materials = list(/datum/material/glass=0)
	list_reagents = list(/datum/reagent/water = 100)
	volume = 100
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = list(5,10,15,20,25,30,50,100)
	container_HP = 1

/obj/item/reagent_containers/glass/beaker/waterbottle/large/empty
	list_reagents = list()

/obj/item/reagent_containers/glass/beaker/waterbottle/wataur
	name = "Bottled Wataur"
	desc = "Наконец, бутылка под ваши габариты."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "wataur"
	custom_materials = list(/datum/material/plastic=0)
	list_reagents = list(/datum/reagent/water = 100)
	volume = 100
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = list(5,10,15,20,25,30,50, 100)
	container_flags = TEMP_WEAK|APTFT_ALTCLICK|APTFT_VERB
	container_HP = 1
	cached_icon = "wataur"

/obj/item/reagent_containers/glass/get_belt_overlay()
	return mutable_appearance('icons/obj/clothing/belt_overlays.dmi', "bottle")

//Mortar & Pestle

/obj/item/pestle
	name = "pestle"
	desc = "Древний и простой инстрмент, используемый со ступой для растирания или выжимания вещей."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "pestle"
	force = 4

/obj/item/reagent_containers/glass/mortar
	name = "mortar"
	desc = "Особой формы чаша, стародавней задумки. В ней можно растирать или выжимать предметы с помощью пестика; процесс, впрочем, не по сегодняшним меркам утомителем. Alt-click для опустошения чаши."
	icon_state = "mortar"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 50)
	item_flags = NO_MAT_REDEMPTION
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	var/obj/item/grinded

/obj/item/reagent_containers/glass/mortar/AltClick(mob/user)
	. = ..()
	if(grinded)
		grinded.forceMove(drop_location())
		grinded = null
		to_chat(user, "<span class='notice'>Вы вытащили предмет наружу.</span>")
		return TRUE

/obj/item/reagent_containers/glass/mortar/attackby(obj/item/I, mob/living/carbon/human/user)
	..()
	if(istype(I,/obj/item/pestle))
		if(grinded)
			if(IS_STAMCRIT(user))
				to_chat(user, "<span class='warning'>Вы слишком устали!</span>")
				return
			to_chat(user, "<span class='notice'>Вы стали перемалывать...</span>")
			if((do_after(user, 25, target = src)) && grinded)
				user.adjustStaminaLoss(20)
				if(grinded.juice_results) //prioritize juicing
					grinded.on_juice()
					reagents.add_reagent_list(grinded.juice_results)
					to_chat(user, "<span class='notice'>Вы выдавили [grinded] в жидкую форму.</span>")
					QDEL_NULL(grinded)
					return
				grinded.on_grind()
				reagents.add_reagent_list(grinded.grind_results)
				if(grinded.reagents) //food and pills
					grinded.reagents.trans_to(src, grinded.reagents.total_volume, log = "mortar powdering")
				to_chat(user, "<span class='notice'>Вы растолкли [grinded] в порошок.</span>")
				QDEL_NULL(grinded)
				return
			return
		else
			to_chat(user, "<span class='warning'>Нечего размалывать!</span>")
			return
	if(grinded)
		to_chat(user, "<span class='warning'>Что-то уже есть внутри!</span>")
		return
	if(I.juice_results || I.grind_results)
		I.forceMove(src)
		grinded = I
		return
	to_chat(user, "<span class='warning'>Вы не можете размолоть это!</span>")

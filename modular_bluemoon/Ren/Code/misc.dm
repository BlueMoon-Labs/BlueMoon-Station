//--------------------------------------------------------[хранилища]----------------------------------------------------------------------------------------------
//коробка инфильтратора
/obj/item/storage/toolbox/infiltrator/inteq
	name = "SpecOps case"
	desc = "Элегантный кейс с отделкой из кожи и эмблемой золотого щита. Содержит внутри костюм, разработанный для понижения заметности пользователя в условиях тесных пространств замкнутых помещений. Сам кейс же отлично подходит для переноса всего того арсенала оружия, что ты взял с собой на 'тихую' миссию."
	icon_state = "infiltrator_case"
	item_state = "infiltrator_case"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
//тулбокс интека
/obj/item/storage/toolbox/inteq
	name = "Brown toolbox"
	icon_state = "toolbox_inteq"
	item_state = "toolbox_inteq"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	desc = "Элегантный ящик с инструментами. Ярко оранжевая полоса проходит вдоль стыка крышки, а в центре виднеется голографическая наклейка в виде жёлтого щита."
	force = 15
	throwforce = 18
///Чехол гитары
/obj/item/storage/backpack/guitarbag
	name = "Guitar bag"
	desc = "Обычный чехол от гитары. В него поместится много всего."
	icon_state = "guitarbag"
	item_state = "guitarbag"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'

/obj/item/storage/backpack/guitarbag/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_BULKY
	STR.max_combined_w_class = INFINITY
	STR.max_items = 7
	STR.can_hold = typecacheof(list(/obj/item/storage/box, /obj/item/gun, /obj/item/ammo_box,
	/obj/item/reagent_containers/food, /obj/item/melee, /obj/item/grenade, /obj/item/reagent_containers/peacehypo, /obj/item/storage/firstaid, /obj/item/card/id, /obj/item/instrument))
//--------------------------------------------------------[Инструменты]----------------------------------------------------------------------------------------------
/obj/item/screwdriver/nuke/inteq
	icon_state = "screwdriver_caravan"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'

/obj/item/crowbar/brown
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	desc = "A small brown crowbar that seems to have extra sharped edges."
	icon_state = "crowbar_brown"
	force = 8
	toolspeed = 0.9

/obj/item/wirecutters/brown
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	desc = "Pair of brown wirecutters with fairly sharp blades."
	icon_state = "cutters"
	random_color = FALSE
	force = 9
	toolspeed = 0.9

///шуруповёрт
/obj/item/screwdriver/power/inteq
	name = "Brown hand Drill"
	desc = "Карманный электроинструмент. Теперь в элегантной обёртке. Установлена насадка крестовой отвёртки."
	icon_state = "drill_inteq_screw"
	item_state = "drill"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	force = 11
	toolspeed = 0.30

/obj/item/wrench/power/inteq/attack_self(mob/user)
	playsound(get_turf(user),'sound/items/change_drill.ogg',50,1)
	var/obj/item/screwdriver/power/inteq/q_drill = new /obj/item/screwdriver/power/inteq(drop_location())
	to_chat(user, "<span class='notice'>You attach the screw driver bit to [src].</span>")
	qdel(src)
	user.put_in_active_hand(q_drill)
///гайковёрт
/obj/item/wrench/power/inteq
	name = "Brown hand drill"
	desc = "Карманный электроинструмент. Теперь в элегантной обёртке. Установлена насадка с шестигранником."
	icon_state = "drill_inteq_bolt"
	item_state = "drill"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'

/obj/item/screwdriver/power/inteq/attack_self(mob/user)
	playsound(get_turf(user),'sound/items/change_drill.ogg',50,1)
	var/obj/item/wrench/power/inteq/q_drill = new /obj/item/wrench/power/inteq(drop_location())
	to_chat(user, "<span class='notice'>You attach the bolt driver bit to [src].</span>")
	qdel(src)
	user.put_in_active_hand(q_drill)
///клещи
/obj/item/crowbar/power/inteq
	name = "Brown jaws of life"
	icon_state = "jaws_inteq_pry"
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	desc = "Карманный пневматический инструмент. Нет, мы не украли контейнер клешней с транспортника НТ и просто перекрасили его. Устанановлена насадка клешней."
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	force = 15
	toolspeed = 0.30

/obj/item/crowbar/power/inteq/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	var/obj/item/wirecutters/power/inteq/cutjaws = new /obj/item/wirecutters/power/inteq(drop_location())
	cutjaws.name = name
	to_chat(user, "<span class='notice'>You attach the cutting jaws to [src].</span>")
	qdel(src)
	user.put_in_active_hand(cutjaws)
///кусачки
/obj/item/wirecutters/power/inteq
	name = "jaws of life"
	desc = "Карманный пневматический инструмент. Нет, мы не украли контейнер клешней с транспортника НТ и просто перекрасили его. Установлена насадка кусачек."
	icon_state = "jaws_inteq_cutter"
	item_state = "jawsoflife"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	force = 15
	toolspeed = 0.30

/obj/item/wirecutters/power/inteq/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	var/obj/item/crowbar/power/inteq/pryjaws = new /obj/item/crowbar/power/inteq(drop_location())
	pryjaws.name = name
	to_chat(user, "<span class='notice'>You attach the pry jaws to [src].</span>")
	qdel(src)
	user.put_in_active_hand(pryjaws)
//сварка
/obj/item/weldingtool/experimental/inteq
	name = "Brown Welder"
	icon_state = "exwelder"
	item_state = "brasswelder"
	desc = "Небольшой сварочный аппарат с самовостанавливающимся топливным блоком. Выглядит довольно нелегально."
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
//боевой ключ
/obj/item/wrench/combat/inteq
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	desc = "Перекраска твёрдого света повысила уровень военных преступлений на 20%"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
//индуктор
/obj/item/inducer/inteq
	icon_state = "inducer"
	item_state = "inducer"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	powertransfer = 2000
	cell_type = /obj/item/stock_parts/cell/super
//---------------------------------------------------------------------[хлам]--------------------------------------------------------------------------------
//Шарик интека
/obj/item/toy/inteqballoon
	name = "InteQ balloon"
	desc = "Сзади видна странная бирка \"НАХУЙ ПАКТ!!1111\"."
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	icon_state = "inteqballoon"
	item_state = "inteqballoon"
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	w_class = WEIGHT_CLASS_BULKY
///Sandman - превращает тебя в симпл моба с руками и механикой морфа. Уязвим к лазерам.
/obj/item/reagent_containers/syringe/sand
	name = "Sand parasite"
	desc = "Шприц со странной чёрной жидкостью, находящейся постоянно в движении."
	amount_per_transfer_from_this = 1
	volume = 1
	list_reagents = list(/datum/reagent/sandparasite = 1)

/datum/reagent/sandparasite
	name = "Sand parasite"
	description = "Миллионы маленьких паразитов готовых съесть любую органику, до которой смогут добраться."
	color = "#000000"
	chemical_flags = REAGENT_ALL_PROCESS
	can_synth = FALSE
	taste_description = "hopelessness"
	value = REAGENT_VALUE_GLORIOUS

/datum/reagent/sandparasite/reaction_mob(mob/living/L, method=TOUCH, reac_volume, affected_bodypart)
	L.ForceContractDisease(new /datum/disease/transformation/sand(), FALSE, TRUE)

/datum/disease/transformation/sand
	name = "Sand parasite"
	cure_text = "nothing"
	cures = list(/datum/reagent/medicine/adminordrazine)
	agent = "Sand parasite"
	desc = "Рой из десятка миллионов паразитов в одной маленькой капле, готовых сожрать любую попавшуюся им органику"
	stage_prob = 20
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = 0
	stage1	= list("<span class='danger'>Ваши мышцы горят огнём.</span>")
	stage2	= list("<span class='danger'>Ваша кожа чернеет и болит так, словно её сдирают заживо.</span>")
	stage3	= list("<span class='danger'>Твой позвоночник воет от боли словно его пытаются растянуть на дыбе</span>", "<span class='danger'>похоже ты становишься выше.</span>")
	stage4	= list("<span class='danger'>Что то разрывает твою кожу на спине.</span>")
	stage5	= list("<span class='danger'>Трансформация завершается. Паразиты глубоко укоренились в теле и теперь не отделимы от него. Вы чувствуете невероятную боль, получив взамен новые возможности.<br><br>Используй Shift+Click, что бы принять вид объекта или существа.<br>Alt+Click по вентиляции или скраберу, что бы залезть в систему труб.<br>Поедай трупы или используй медицинские нитки для восстановления здоровья.<br>Ты можешь выдержать много физических повреждений, но огонь и лазеры для тебя смертельно опасны.</span>")
	new_form = /mob/living/simple_animal/hostile/morph/sandman
	infectable_biotypes = MOB_ORGANIC|MOB_MINERAL|MOB_UNDEAD
//Автохирург
/obj/item/autosurgeon/syndicate/inteq
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
//Библия интека
/obj/item/storage/book/bible/syndicate/inteq
	name = "InteQ Tome"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
//Секретные документы
/obj/item/documents/inteq
	name = "orange secret documents"
	desc = "\"Совершенно Секретно\". Документы, содержащие разрозненные координаты, имена, наборы шифров и схем. Эти документы заверены оранжевой сургучной печатью."
	icon_state = "docs_orange"

/obj/item/folder/inteq
	name = "folder - 'TOP SECRET'"
	icon_state = "folder_sorange"
	bg_color = "#331414"

/obj/item/folder/inteq/Initialize(mapload)
	. = ..()
	new /obj/item/documents/inteq(src)
	update_icon()
//маяк выбора оружия для FTU
/obj/item/choice_beacon/ftu
	name = "FTU sec kit"
	desc = "Маяк для выбора снаряжения охранниками торговых кораблей"

/obj/item/choice_beacon/ftu/generate_display_names()
	var/static/list/ftu_item_list
	if(!ftu_item_list)
		ftu_item_list = list()
		var/list/templist = typesof(/obj/item/storage/backpack/satchel/ftu)
		for(var/V in templist)
			var/atom/A = V
			ftu_item_list[initial(A.name)] = A
	return ftu_item_list

/obj/item/choice_beacon/ftu/generate_display_names()
	var/static/list/ftu_item_list
	if(!ftu_item_list)
		ftu_item_list = list()
		var/list/templist = list(
		/obj/item/storage/backpack/satchel/ftu/shootgun,
		/obj/item/storage/backpack/satchel/ftu/fire,
		/obj/item/storage/backpack/satchel/ftu/sniper,
		/obj/item/storage/backpack/satchel/ftu/med)
		for(var/V in templist)
			var/atom/A = V
			ftu_item_list[initial(A.name)] = A
	return ftu_item_list

//Энергетический щит
/obj/item/shield/inteq_energy
	name = "Old energy shield"
	desc = "Устаревшая на несколько поколений модель энергетического щита. Использует механические ограничители силового поля и эргономика немного страдает, но всё ещё является желанным элементом экипировки."
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	lefthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_l.dmi'
	righthand_file = 'modular_bluemoon/Ren/Icons/Mob/inhand_r.dmi'
	w_class = WEIGHT_CLASS_TINY
	base_icon_state = "shield"
	var/on_force = 10
	var/on_throwforce = 8
	var/on_throw_speed = 2
	var/active = 0
	var/clumsy_check = TRUE

/obj/item/shield/inteq_energy/Initialize(mapload)
	. = ..()
	icon_state = "[base_icon_state]0"

/obj/item/shield/inteq_energy/run_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return)
	if((attack_type & ATTACK_TYPE_PROJECTILE) && is_energy_reflectable_projectile(object))
		playsound(src, 'sound/weapons/parry.ogg', 75, 1)
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
		return BLOCK_SUCCESS | BLOCK_REDIRECTED | BLOCK_SHOULD_REDIRECT
	return ..()

/obj/item/shield/inteq_energy/directional_block(mob/living/owner, atom/object, damage, attack_text, attack_type, armour_penetration, mob/attacker, def_zone, final_block_chance, list/block_return, override_direction)
	if((attack_type & ATTACK_TYPE_PROJECTILE) && is_energy_reflectable_projectile(object))
		block_return[BLOCK_RETURN_REDIRECT_METHOD] = REDIRECT_METHOD_DEFLECT
		return BLOCK_SUCCESS | BLOCK_REDIRECTED | BLOCK_SHOULD_REDIRECT
	return ..()

/obj/item/shield/inteq_energy/attack_self(mob/living/carbon/human/user)
	if(clumsy_check && HAS_TRAIT(user, TRAIT_CLUMSY) && prob(50))
		to_chat(user, "<span class='userdanger'>You beat yourself in the head with [src]!</span>")
		user.take_bodypart_damage(5)
	active = !active
	icon_state = "[base_icon_state][active]"

	if(active)
		force = on_force
		throwforce = on_throwforce
		throw_speed = on_throw_speed
		w_class = WEIGHT_CLASS_BULKY
		playsound(user, 'sound/weapons/saberon.ogg', 35, TRUE)
		to_chat(user, "<span class='notice'>[src] is now active.</span>")
	else
		force = initial(force)
		throwforce = initial(throwforce)
		throw_speed = initial(throw_speed)
		w_class = WEIGHT_CLASS_TINY
		playsound(user, 'sound/weapons/saberoff.ogg', 35, TRUE)
		to_chat(user, "<span class='notice'>[src] can now be concealed.</span>")
	add_fingerprint(user)

//---------------------------------------------------------------------------------------------------------------------------------
/obj/item/robot_module/inteq_builder
	name = "InteQ Engineering"
	has_snowflake_deadsprite = TRUE
	basic_modules = list(
		/obj/item/pickaxe/drill/jackhammer/angle_grinder,
		/obj/item/assembly/flash/cyborg,
		/obj/item/construction/rcd/borg, //----------------
		/obj/item/pipe_dispenser,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/screwdriver/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/multitool/cyborg,
		/obj/item/storage/part_replacer/cyborg,
		/obj/item/holosign_creator/combifan,
		/obj/item/gripper,
		/obj/item/lightreplacer/cyborg,
		/obj/item/assembly/signaler/cyborg,
		/obj/item/areaeditor/blueprints/cyborg,
		/obj/item/electroadaptive_pseudocircuit,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/sheet/glass/cyborg,
		/obj/item/stack/sheet/rglass/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/stack/tile/plasteel/cyborg,
		/obj/item/screwdriver/power/inteq,
		/obj/item/stack/cable_coil/cyborg,
		/obj/item/cyborg_inducer)
	emag_modules = list(/obj/item/borg/stun)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/engineer,
		/obj/item/clockwork/replica_fabricator/cyborg)
	cyborg_base_icon = "mekainteq"
	cyborg_icon_override = 'modular_bluemoon/Ren/Icons/Mob/robot.dmi'
	hasrest = TRUE
	magpulsing = TRUE
	hat_offset = -4

/mob/living/silicon/robot/modules/inteq/builder
	icon_state = "mekainteq"
	playstyle_string = "<span class='big bold'>Вы - Строительный Киборг ИнтеКью!</span><br>\
						<b>Вы вооружены надежными инженерными средствами, которые помогут вам выполнить задание: помочь союзным оперативникам. \
						Ваш Маркер Назначения позволит Вам скрытно перемещаться по сети утилизации по всей станции. \
						Ваш сварочный аппарат позволит Вам ремонтировать экзокостюмы оперативников, а также себя и своих товарищей-киборгов. \
						Ваш Киборг-Проектор Хамелеон позволит вам принять облик и зарегистрированное имя инженерного борга Nanotrasen и проводить тайные операции на Космических Станциях. \
						Имейте в виду, что почти любой физический контакт или случайное повреждение нарушит ваш камуфляж! \
						<i>Помогите оперативникам любой ценой!!!</i></b>"
	set_module = /obj/item/robot_module/inteq_builder
//---------------------------------------------------------------------------[ловушки]------------------------------------------------------------------------
//колючая проволока
/obj/structure/oldtrap
	name = "old trap"
	desc = "Ты не должен этого видеть"
	icon = 'modular_bluemoon/Ren/Icons/Obj/misc.dmi'
	icon_state = "razor"
	anchored = TRUE
	density = FALSE

/obj/structure/oldtrap/razor_wire
	name = "Razor wire"
	desc = "Она и правда колючая."
	max_integrity = 100
	var/base = /obj/item/stack/sheet/mineral/wood
	var/damage = 10

/obj/structure/oldtrap/razor_wire/industrial
	icon_state = "razor_industrial"
	max_integrity = 400
	base = /obj/item/stack/sheet/plasteel
	damage = 20

/obj/structure/oldtrap/razor_wire/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /mob/living/silicon/robot))
		return TRUE
	if(istype(mover, /obj/item/projectile))
		return TRUE
	if(prob(50))
		to_chat(mover, "<span class='danger'>Ты цепляешься за колючую проволоку, застревая в ней.</span>")
		return FALSE

/obj/structure/oldtrap/razor_wire/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/caltrop, 5, damage, 50, CALTROP_BYPASS_SHOES)

/obj/structure/oldtrap/razor_wire/deconstruct(disassembled = TRUE)
	if(!loc)
		return
	if(!(flags_1&NODECONSTRUCT_1))
		var/amount = rand(1,10)
		var/obj/R = new /obj/item/stack/rods(drop_location(), amount)
		var/obj/D = new base(drop_location(), 5)
		transfer_fingerprints_to(R,D)
		qdel(src)
	..()

/obj/structure/oldtrap/razor_wire/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/wirecutters))
		to_chat(user, "<span class='notice'>Ты разрезаешь колючую проволоку с помощью [I].</span>")
		if(I.use_tool(src, user, 8 SECONDS, volume=50))
			deconstruct()
	if(istype(I, /obj/item/wrench))
		if(anchored == TRUE)
			to_chat(user, "<span class='notice'>Ты откручиваешь основание колючей проволоки с помощью [I].</span>")
		else
			to_chat(user, "<span class='notice'>Ты закручиваешь основание колючей проволоки с помощью [I].</span>")
		if(I.use_tool(src, user, 20 SECONDS, volume=50))
			anchored = !anchored
	else
		..()
//Шипы
/obj/structure/oldtrap/floor_spike
	name = "Strange floor"
	desc = "Я бы на него не наступал."
	icon_state = "spike_trap"
	max_integrity = 200
	var/screwd = 0

/obj/structure/oldtrap/floor_spike/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/caltrop, 25, 30, 100, CALTROP_BYPASS_SHOES)

/obj/structure/oldtrap/floor_spike/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /mob/living))
		mover.visible_message("<span class='danger'>Ловушка активируется, выбрасывая свои шипы вверх!</span>", "<span class='danger'>Ты активируешь ловушку, заставляя шипы устремиться вверх!</span>")
		icon_state = "spike_trap-2"
		update_icon()

/obj/structure/oldtrap/floor_spike/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/screwdriver))
		if(screwd == 0)
			to_chat(user, "<span class='notice'>Ты раскручиваешь винты креплений ловушки с шипами [I].</span>")
			if(I.use_tool(src, user, 16 SECONDS, volume=50))
				screwd = !screwd
		else
			to_chat(user, "<span class='notice'>Ты закручиваешь винты креплений ловушки с шипами [I].</span>")
			if(I.use_tool(src, user, 16 SECONDS, volume=50))
				screwd = !screwd
	if(istype(I, /obj/item/crowbar))
		if(screwd == 1)
			to_chat(user, "<span class='notice'>Ты приподнимаешь пластину, удерживающую пружины ловушки.</span>")
			if(I.use_tool(src, user, 30 SECONDS, volume=50))
				deconstruct()
	else
		. = ..()

/obj/structure/oldtrap/floor_spike/deconstruct(disassembled = TRUE)
	if(!loc)
		return
	if(!(flags_1&NODECONSTRUCT_1))
		var/amount = rand(1,5)
		var/obj/R = new /obj/item/stack/sheet/plasteel(drop_location(), amount)
		var/obj/D = new /obj/item/stake/hardened/silver(drop_location(), 3)
		transfer_fingerprints_to(R,D)
		qdel(src)
	..()

/obj/structure/billboard/fishstore
	name = "Billboard"
	desc = "An advertisement for a fishing store."
	icon = 'modular_bluemoon/Ren/Icons/Obj/billboard.dmi'
	icon_state = "billboard_fishstore"
	max_integrity = 1000
	bound_width = 96
	bound_height = 64
	density = TRUE
	anchored = TRUE

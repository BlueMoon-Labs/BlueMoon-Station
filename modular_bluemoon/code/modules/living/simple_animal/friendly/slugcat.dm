/mob/living/simple_animal/pet/slugcat
	name = "слизнекот"
	desc = "Удивительное существо, напоминающее кота и слизня в одном обличии. Но это не слизь, а иной вид существа. Гордость ксенобиологии. Крайне ловкое и умное, родом с планеты с опасной средой обитания. Обожает копья, не стоит давать ему его в лапки. На нём отлично смотрятся шляпы."
	icon_state = "slugcat"
	icon = 'modular_sand/icons/mob/animal.dmi'
	icon_living = "slugcat"
	icon_dead = "slugcat_dead"
	speak = list("Furrr.", "Uhh.", "Hurrr.")
	gender = MALE
	turns_per_move = 5
	see_in_dark = 8
	health = 100
	maxHealth = 100
	blood_volume = BLOOD_VOLUME_NORMAL
	melee_damage_type = STAMINA
	melee_damage_lower = 0
	melee_damage_upper = 0
	mob_size = MOB_SIZE_SMALL
	pass_flags = PASSTABLE
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat = 5)
	gold_core_spawnable = FRIENDLY_SPAWN
	footstep_type = FOOTSTEP_MOB_SLIME
	faction = list("slime","neutral")
	speed = 1

	// Переменные инвентаря
	var/obj/item/inventory_head
	var/obj/item/inventory_hand

	// Переменные шляпы
	var/hat_offset_y = -8
	var/hat_offset_y_rest = -19
	var/hat_icon_file = 'icons/mob/clothing/head.dmi'
	var/hat_icon_state
	var/hat_alpha
	var/hat_color

	// Поведенческие переменные
	var/is_pacifist = FALSE
	var/is_reduce_damage = TRUE


/mob/living/simple_animal/pet/slugcat/Initialize(mapload)
	. = ..()
	add_verb(src, /mob/living/proc/lay_down)
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)

/mob/living/simple_animal/pet/slugcat/monk
	name = "слизнекот-монах"
	desc = "Удивительное существо, напоминающее кота и слизня в одном обличии. Но это не слизь, а иной вид существа. Гордость ксенобиологии. Крайне ловкое и умное, родом с планеты с опасной средой обитания. Не любит охоту и не умеет пользоваться копьями. На нём отлично смотрятся шляпы."
	icon_state = "slugcat_monk"
	icon_living = "slugcat_monk"
	icon_dead = "slugcat_monk_dead"
	is_pacifist = TRUE
	gold_core_spawnable = FRIENDLY_SPAWN
	health = 80
	maxHealth = 80

/mob/living/simple_animal/pet/slugcat/hunter
	name = "слизнекот-охотник"
	desc = "Удивительное существо, напоминающее кота и слизня в одном обличии. Но это не слизь, а иной вид существа. Гордость ксенобиологии. Крайне ловкое и умное, родом с планеты с опасной средой обитания. Обожает копья и умело управляется ими, не стоит давать ему его в лапки. На нём отлично смотрятся шляпы."
	icon_state = "slugcat_hunter"
	icon_living = "slugcat_hunter"
	icon_dead = "slugcat_hunter_dead"
	is_pacifist = FALSE
	is_reduce_damage = FALSE
	faction = list("slime","neutral","hostile")
	gold_core_spawnable = HOSTILE_SPAWN
	health = 150
	maxHealth = 150

/mob/living/simple_animal/pet/slugcat/gold
	name = "золотой слизнекот"
	desc = "Уникальный золотой слизнекот полученный чудотворным путём."
	icon_state = "slugcat_gold"
	icon_living = "slugcat_gold"
	icon_dead = "slugcat_gold_dead"
	is_pacifist = FALSE
	is_reduce_damage = FALSE
	gold_core_spawnable = NO_SPAWN
	health = 300
	maxHealth = 300

/mob/living/simple_animal/pet/slugcat/Initialize(mapload)
	. = ..()
	add_verb(src, /mob/living/proc/lay_down)
	regenerate_icons()

/mob/living/simple_animal/pet/slugcat/attackby(obj/item/W, mob/user, params)
	if(stat != DEAD)
		if(istype(W, /obj/item/clothing/head) && user.a_intent == INTENT_HELP)
			place_on_head(W, user)
			return
		if(istype(W, /obj/item/spear) && user.a_intent != INTENT_HARM)
			place_to_hand(W, user)
			return
	. = ..()

/mob/living/simple_animal/pet/slugcat/death(gibbed)
	drop_hat()
	drop_hand()
	. = ..()

/mob/living/simple_animal/pet/slugcat/Topic(href, href_list)
	if(..())
		return TRUE

	if(!iscarbon(usr) || usr.incapacitated() || !Adjacent(usr))
		usr << browse(null, "window=mob\[UID()\]")
		usr.unset_machine()
		return

	if(stat == DEAD)
		return FALSE

	if(href_list["remove_inv"])
		var/remove_from = href_list["remove_inv"]
		switch(remove_from)
			if("head")
				remove_from_head(usr)
			if("hand")
				remove_from_hand(usr)
		show_inv(usr)

	else if(href_list["add_inv"])
		var/add_to = href_list["add_inv"]
		switch(add_to)
			if("head")
				place_on_head(usr.get_active_hand(), usr)
			if("hand")
				place_to_hand(usr.get_active_hand(), usr)
		show_inv(usr)

	if(usr != src)
		return TRUE

/mob/living/simple_animal/pet/slugcat/regenerate_icons()
	..()
	if(inventory_hand)
		if(istype(inventory_hand, /obj/item/spear))
			speared()

	if(inventory_head)
		var/image/head_icon

		if(!hat_icon_state)
			hat_icon_state = inventory_head.icon_state
		if(!hat_alpha)
			hat_alpha = inventory_head.alpha
		if(!hat_color)
			hat_color = inventory_head.color

		head_icon = get_hat_overlay()

		add_overlay(head_icon)

/mob/living/simple_animal/pet/slugcat/update_mobility()
	. = ..()
	if(stat != DEAD)
		if(!CHECK_MOBILITY(src, MOBILITY_STAND))
			if(inventory_head || inventory_hand)
				hat_offset_y = hat_offset_y_rest
				drop_hand()
			icon_state = "[icon_living]_rest"
		else
			if(inventory_head)
				hat_offset_y = initial(hat_offset_y)
			icon_state = "[icon_living]"
		regenerate_icons()

/mob/living/simple_animal/pet/slugcat/proc/speared()
	icon_state = "[initial(icon_state)]_spear"

	var/obj/item/spear/spear_weapon = inventory_hand

	attack_sound = 'sound/weapons/bladeslice.ogg'
	melee_damage_type = BRUTE
	melee_damage_lower = round(spear_weapon.force / (is_reduce_damage ? 2 : 1))
	melee_damage_upper = round(spear_weapon.force / (is_reduce_damage ? 2 : 1))
	armour_penetration = spear_weapon.armour_penetration
	obj_damage = spear_weapon.force

/mob/living/simple_animal/pet/slugcat/proc/unspeared()
	icon_state = initial(icon_state)
	attack_sound = initial(attack_sound)
	melee_damage_type = initial(melee_damage_type)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	armour_penetration = initial(armour_penetration)
	obj_damage = initial(obj_damage)

/mob/living/simple_animal/pet/slugcat/proc/get_hat_overlay()
	if(hat_icon_file && hat_icon_state)
		var/image/slugI = image(hat_icon_file, hat_icon_state)
		slugI.alpha = hat_alpha
		slugI.color = hat_color
		slugI.pixel_y = hat_offset_y
		return slugI

/mob/living/simple_animal/pet/slugcat/proc/show_inv(mob/user)
	if(user.incapacitated() || !Adjacent(user))
		return
	user.set_machine(src)

	var/head_href
	if(inventory_head)
		head_href = "<A href='?src=\[UID()\];remove_inv=head'>\[inventory_head\]</A>"
	else
		head_href = "<A href='?src=\[UID()\];add_inv=head'>Nothing</A>"

	var/hand_href
	if(inventory_hand)
		hand_href = "<A href='?src=\[UID()\];remove_inv=hand'>\[inventory_hand\]</A>"
	else
		hand_href = "<A href='?src=\[UID()\];add_inv=hand'>Nothing</A>"

	var/dat = {"<meta charset="UTF-8"><div align='center'><b>Inventory of \[name\]</b></div><p>"}
	dat += "<br><B>Head:</B> [head_href]"
	dat += "<br><B>Hand:</B> [hand_href]"
	var/datum/browser/popup = new(user, "mob\[UID()\]", "\[src\]", 440, 250)
	popup.set_content(dat)
	popup.open()

/mob/living/simple_animal/pet/slugcat/proc/place_on_head(obj/item/item_to_add, mob/user)
	if(!item_to_add)
		user.visible_message(span_notice("[user] похлопывает по голове слизнекота."), span_notice("Вы положили руку на голову слизнекота."))
		return FALSE

	if(!istype(item_to_add, /obj/item/clothing/head))
		to_chat(user, span_warning("Этот предмет нельзя надеть на голову слизнекота!"))
		return FALSE

	if(inventory_head)
		if(user)
			to_chat(user, span_warning("Нельзя надеть больше одного головного убора на голову слизнекота!"))
		return FALSE

	if(user && !user.transferItemToLoc(item_to_add, src))
		to_chat(user, span_warning("Предмет застрял в ваших руках!"))
		return FALSE

	user.visible_message(span_notice("[user] надевает предмет на голову слизнекота."),
		span_notice("Вы надеваете предмет на голову слизнекота."),
		span_italics("Вы слышите как что-то нацепили."))
	inventory_head = item_to_add
	regenerate_icons()

	return TRUE


/mob/living/simple_animal/pet/slugcat/proc/remove_from_head(mob/user)
	if(inventory_head)
		to_chat(user, span_warning("Вы сняли головной убор с головы слизнекота."))
		inventory_head.forceMove(get_turf(src))
		inventory_head.dropped(src)
		user.put_in_hands(inventory_head)

		null_hat()

		regenerate_icons()
	else
		to_chat(user, span_warning("На голове слизнекота нет головного убора!"))
		return FALSE

	return TRUE

/mob/living/simple_animal/pet/slugcat/proc/drop_hat()
	if(inventory_head)
		inventory_head.forceMove(get_turf(src))
		inventory_head.dropped(src)
		null_hat()
		regenerate_icons()

/mob/living/simple_animal/pet/slugcat/proc/null_hat()
	inventory_head = null
	hat_icon_state = null
	hat_alpha = null
	hat_color = null

/mob/living/simple_animal/pet/slugcat/proc/place_to_hand(obj/item/item_to_add, mob/user)
	if(!item_to_add)
		user.visible_message(span_notice("[user] пощупал лапки слизнекота."), span_notice("Вы пощупали лапки слизнекота."))
		return FALSE

	if(resting)
		to_chat(user, span_warning("Слизнекот спит и не принимает предмет!"))
		return FALSE

	if(!istype(item_to_add, /obj/item/spear))
		to_chat(user, span_warning("Слизнекот не принимает этот предмет!"))
		return FALSE
	if(inventory_hand)
		if(user)
			to_chat(user, span_warning("Лапки слизнекота заняты!"))
		return FALSE

	if(user && !user.dropItemToGround(item_to_add))
		to_chat(user, span_warning("Предмет застрял в ваших руках!"))
		return FALSE

	if(is_pacifist)
		to_chat(user, span_warning("Этот слизнекот - пацифист и не пользуется оружием!"))
		return FALSE

	user.visible_message(span_notice("Слизнекот выхватывает предмет из рук [user]."),
		span_notice("Слизнекот выхватывает предмет из ваших рук."),
		span_italics("Вы видите довольные глаза."))
	move_item_to_hand(item_to_add)

	return TRUE

/mob/living/simple_animal/pet/slugcat/proc/move_item_to_hand(obj/item/item_to_add)
	item_to_add.forceMove(src)
	inventory_hand = item_to_add
	regenerate_icons()

/mob/living/simple_animal/pet/slugcat/proc/remove_from_hand(mob/user)
	if(inventory_hand)
		to_chat(user, span_warning("Вы забрали предмет из лап слизнекота."))
		inventory_hand.forceMove(get_turf(src))
		inventory_hand.dropped(src)
		user.put_in_hands(inventory_hand)

		null_hand()

		regenerate_icons()
	else
		to_chat(user, span_warning("В лапах слизнекота нечего отбирать!"))
		return FALSE

	return TRUE

/mob/living/simple_animal/pet/slugcat/proc/drop_hand()
	if(inventory_hand)
		inventory_hand.forceMove(get_turf(src))
		inventory_hand.dropped(src)
		null_hand()
		regenerate_icons()

/mob/living/simple_animal/pet/slugcat/proc/null_hand()
	unspeared()
	inventory_hand = null

/mob/living/simple_animal/hostile/slugcat_hunter
	name = "дикий слизнекот-охотник"
	desc = "Опасное существо, напоминающее кота и слизня в одном обличии. Крайне агрессивное и умелое в обращении с копьём. Лучше держаться подальше!"
	icon = 'modular_sand/icons/mob/animal.dmi'
	icon_state = "slugcat_hunter_spear"
	icon_living = "slugcat_hunter_spear"
	icon_dead = "slugcat_hunter_dead"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	gender = MALE
	speak_chance = 0
	turns_per_move = 3
	speed = 0
	maxHealth = 150
	health = 150
	mob_size = MOB_SIZE_SMALL
	see_in_dark = 8
	stat_attack = UNCONSCIOUS
	robust_searching = 1
	blood_volume = BLOOD_VOLUME_NORMAL

	harm_intent_damage = 10
	obj_damage = 40
	melee_damage_lower = 15
	melee_damage_upper = 25
	melee_damage_type = BRUTE
	attack_verb_continuous = "бьёт копьём"
	attack_verb_simple = "бьёт"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	speak_emote = list("growls")

	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0

	faction = list("hostile")
	gold_core_spawnable = HOSTILE_SPAWN
	footstep_type = FOOTSTEP_MOB_SLIME

	emote_taunt = list("hisses", "growls")
	taunt_chance = 30

/mob/living/simple_animal/hostile/slugcat_hunter/AttackingTarget()
	. = ..()
	if(. && prob(15) && iscarbon(target))
		var/mob/living/carbon/C = target
		C.DefaultCombatKnockdown(40)
		C.visible_message("<span class='danger'>\The [src] сбивает \the [C] с ног копьём!</span>", \
				"<span class='userdanger'>\The [src] сбивает вас с ног копьём!</span>")

/mob/living/simple_animal/hostile/slugcat_hunter/death(gibbed)
	visible_message("<span class='danger'>[src] издаёт последний вздох...</span>")
	. = ..()

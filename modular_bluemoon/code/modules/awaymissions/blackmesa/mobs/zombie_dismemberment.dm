// =============================================================================
// MODULAR INFECTED ZOMBIE DISMEMBERMENT SYSTEM
// High-performance Lego-style layered limb loss and visual gore effects
// =============================================================================

#define ZOMBIE_LIMB_HEAD    (1<<0)
#define ZOMBIE_LIMB_R_ARM   (1<<1)
#define ZOMBIE_LIMB_L_ARM   (1<<2)
#define ZOMBIE_LIMB_R_LEG   (1<<3)
#define ZOMBIE_LIMB_L_LEG   (1<<4)

// =============================================================================
// MOVE SPEED MODIFIERS
// =============================================================================

// Move speed modifier for infected with missing leg (severe slowdown)
/datum/movespeed_modifier/infected_legless
	id = "infected_legless"
	multiplicative_slowdown = 8.0
	blacklisted_movetypes = FLOATING

// =============================================================================
// FLYING LIMB & GORE TEMP EFFECTS (Matrix-rotated, self-cleaning)
// =============================================================================

/obj/effect/temp_visual/flying_limb
	name = "flying limb"
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "zombie_dead" // Плейсхолдер, заменяется на sci_flying_*
	duration = 8
	randomdir = FALSE
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/flying_limb/proc/launch(turf/start_turf, target_dir, custom_state = null, custom_icon = null)
	if(custom_icon)
		icon = custom_icon
	if(custom_state)
		icon_state = custom_state

	var/offset_x = rand(-16, 16)
	var/offset_y = rand(8, 24)
	if(target_dir & EAST)
		offset_x += 32
	else if(target_dir & WEST)
		offset_x -= 32
	if(target_dir & NORTH)
		offset_y += 32
	else if(target_dir & SOUTH)
		offset_y -= 16

	var/matrix/M = matrix()
	M.Turn(pick(-180, -90, 90, 180, 270))

	animate(src, transform = M, pixel_x = offset_x, pixel_y = offset_y, time = 6, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 0, time = 2)

/obj/effect/temp_visual/blood_fountain
	name = "blood fountain"
	icon = 'icons/effects/blood.dmi'
	icon_state = "splatter"
	duration = 10
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/blood_fountain/Initialize(mapload)
	. = ..()
	var/matrix/M = matrix()
	M.Scale(1.2, 1.6)
	transform = M
	animate(src, alpha = 0, pixel_y = 12, time = 10, easing = EASE_OUT)

/obj/effect/temp_visual/blood_spurt
	name = "blood spurt"
	icon = 'icons/effects/blood.dmi'
	icon_state = "splatter"
	duration = 6
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/blood_spurt/proc/spurt(target_dir)
	setDir(target_dir)
	var/offset_x = (target_dir & EAST ? 24 : (target_dir & WEST ? -24 : 0))
	var/offset_y = (target_dir & NORTH ? 24 : (target_dir & SOUTH ? -24 : 0))
	animate(src, pixel_x = offset_x, pixel_y = offset_y, alpha = 0, time = 6, easing = EASE_OUT)

/obj/effect/temp_visual/gore_burst
	name = "gore burst"
	icon = 'icons/effects/blood.dmi'
	icon_state = "gib_core"
	duration = 8
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/gore_burst/Initialize(mapload)
	. = ..()
	var/matrix/M = matrix()
	M.Scale(1.8, 1.8)
	animate(src, transform = M, alpha = 0, time = 8, easing = EASE_OUT)


// =============================================================================
// MODULAR SCIENTIST INFECTED MOB (TEST PROTOTYPE)
// =============================================================================

/mob/living/simple_animal/hostile/infected/modular
	name = "infected scientist"
	desc = "A horrifying mutated research scientist with modular decaying limbs."
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "scientist_zombie" // Базовый плейсхолдер
	icon_living = "scientist_zombie"
	icon_dead = "zombie_dead"

	// DMI-файл расчлененки (будет заменён на ваш infected_gore.dmi)
	var/gore_dmi = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	var/prefix = "sci"

	// Битовая маска целых конечностей (голова, 2 руки, 2 ноги)
	var/limbs_status = ZOMBIE_LIMB_HEAD | ZOMBIE_LIMB_R_ARM | ZOMBIE_LIMB_L_ARM | ZOMBIE_LIMB_R_LEG | ZOMBIE_LIMB_L_LEG

	// Состояния
	var/legs_lost_count = 0
	var/instant_kill_on_single_leg = FALSE // Если TRUE - потеря даже одной ноги убивает на месте
	var/wound_chest_active = FALSE
	var/dismemberment_threshold = 20 // Минимальный урон для шанса отстрела конечности

/mob/living/simple_animal/hostile/infected/modular/Initialize(mapload)
	. = ..()
	assemble_modular_limbs()

// Сборка внешнего вида моба из активных слоев
/mob/living/simple_animal/hostile/infected/modular/proc/assemble_modular_limbs()
	if(stat == DEAD)
		return

	icon_state = "[prefix]_body"
	icon_living = "[prefix]_body"

	cut_overlays()

	// Слой головы / культи шеи
	if(limbs_status & ZOMBIE_LIMB_HEAD)
		add_overlay(mutable_appearance(gore_dmi, "[prefix]_head"))
	else
		add_overlay(mutable_appearance(gore_dmi, "stump_neck"))

	// Слой правой руки / культи
	if(limbs_status & ZOMBIE_LIMB_R_ARM)
		add_overlay(mutable_appearance(gore_dmi, "[prefix]_arm_r"))
	else
		add_overlay(mutable_appearance(gore_dmi, "stump_arm_r"))

	// Слой левой руки / культи
	if(limbs_status & ZOMBIE_LIMB_L_ARM)
		add_overlay(mutable_appearance(gore_dmi, "[prefix]_arm_l"))
	else
		add_overlay(mutable_appearance(gore_dmi, "stump_arm_l"))

	// Слой правой ноги / культи
	if(limbs_status & ZOMBIE_LIMB_R_LEG)
		add_overlay(mutable_appearance(gore_dmi, "[prefix]_leg_r"))
	else
		add_overlay(mutable_appearance(gore_dmi, "stump_leg_r"))

	// Слой левой ноги / культи
	if(limbs_status & ZOMBIE_LIMB_L_LEG)
		add_overlay(mutable_appearance(gore_dmi, "[prefix]_leg_l"))
	else
		add_overlay(mutable_appearance(gore_dmi, "stump_leg_l"))

	// Оверлей ранения груди
	if(wound_chest_active)
		add_overlay(mutable_appearance(gore_dmi, "wound_chest"))

// Отстрел головы (Хедшот -> мгновенная смерть)
/mob/living/simple_animal/hostile/infected/modular/proc/sever_head(atom/attacker, dir_hit = null)
	if(!(limbs_status & ZOMBIE_LIMB_HEAD))
		return
	limbs_status &= ~ZOMBIE_LIMB_HEAD

	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/splat.ogg', 70, TRUE)

	// Фонтан крови вверх
	new /obj/effect/temp_visual/blood_fountain(T)

	// Вылет головы
	var/obj/effect/temp_visual/flying_limb/L = new(T)
	L.launch(T, dir_hit ? dir_hit : pick(GLOB.cardinals), "[prefix]_flying_head", gore_dmi)

	spawn_optimized_blood_decal(T)

	// Хедшот = мгновенная смерть
	icon_dead = "[prefix]_dead_decap"
	death(FALSE)

// Отстрел правой руки
/mob/living/simple_animal/hostile/infected/modular/proc/sever_r_arm(atom/attacker, dir_hit = null)
	if(!(limbs_status & ZOMBIE_LIMB_R_ARM))
		return
	limbs_status &= ~ZOMBIE_LIMB_R_ARM

	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/blobattack.ogg', 60, TRUE)

	// Летящая рука
	var/obj/effect/temp_visual/flying_limb/L = new(T)
	L.launch(T, dir_hit ? dir_hit : dir, "[prefix]_flying_arm", gore_dmi)

	// Струя крови
	var/obj/effect/temp_visual/blood_spurt/S = new(T)
	S.spurt(dir_hit ? dir_hit : dir)

	// Снижение боевой эффективности
	melee_damage_lower = max(2, melee_damage_lower * 0.7)
	melee_damage_upper = max(5, melee_damage_upper * 0.7)

	spawn_optimized_blood_decal(T)
	assemble_modular_limbs()

// Отстрел левой руки
/mob/living/simple_animal/hostile/infected/modular/proc/sever_l_arm(atom/attacker, dir_hit = null)
	if(!(limbs_status & ZOMBIE_LIMB_L_ARM))
		return
	limbs_status &= ~ZOMBIE_LIMB_L_ARM

	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/blobattack.ogg', 60, TRUE)

	// Летящая рука
	var/obj/effect/temp_visual/flying_limb/L = new(T)
	L.launch(T, dir_hit ? dir_hit : dir, "[prefix]_flying_arm", gore_dmi)

	// Струя крови
	var/obj/effect/temp_visual/blood_spurt/S = new(T)
	S.spurt(dir_hit ? dir_hit : dir)

	// Потеря левой руки отключает захват / замедление
	melee_damage_lower = max(2, melee_damage_lower * 0.7)
	melee_damage_upper = max(5, melee_damage_upper * 0.7)

	spawn_optimized_blood_decal(T)
	assemble_modular_limbs()

// Отстрел ноги (Замедление при потере одной, мгновенная смерть при потере обеих или травматическом шоке)
/mob/living/simple_animal/hostile/infected/modular/proc/sever_leg(leg_type = "r_leg", atom/attacker = null, dir_hit = null)
	var/target_bit = (leg_type == "r_leg") ? ZOMBIE_LIMB_R_LEG : ZOMBIE_LIMB_L_LEG
	if(!(limbs_status & target_bit))
		return

	limbs_status &= ~target_bit
	legs_lost_count++

	var/turf/T = get_turf(src)
	playsound(T, 'sound/effects/bonebreak.ogg', 70, TRUE)

	// Вылет оторванной ноги
	var/obj/effect/temp_visual/flying_limb/L = new(T)
	L.launch(T, dir_hit ? dir_hit : dir, "[prefix]_flying_leg", gore_dmi)

	// Струя крови
	var/obj/effect/temp_visual/blood_spurt/S = new(T)
	S.spurt(dir_hit ? dir_hit : dir)

	spawn_optimized_blood_decal(T)

	// Логика смерти / замедления:
	// Если потерял обе ноги ИЛИ включена мгновенная смерть от потери конечности
	if(legs_lost_count >= 2 || instant_kill_on_single_leg)
		visible_message(span_warning("[src] падает замертво от травматического шока и потери конечностей!"))
		icon_dead = "[prefix]_dead_legless" // Отдельный icon state для смерти от потери ног
		death(FALSE)
		return

	// Если потерял только одну ногу - критическое замедление (хромает на одной ноге)
	visible_message(span_warning("[src] начинает хромать, потеряв ногу!"))
	speed = 4
	turns_per_move = 1
	add_movespeed_modifier(/datum/movespeed_modifier/infected_legless, TRUE)
	assemble_modular_limbs()

// Полный разрыв тела (Взрыв / оверкилл)
/mob/living/simple_animal/hostile/infected/modular/proc/gib_explosion(atom/attacker)
	var/turf/T = get_turf(src)
	if(!T)
		return

	playsound(T, 'sound/effects/splat.ogg', 80, TRUE)
	new /obj/effect/temp_visual/gore_burst(T)

	// Разлёт конечностей и костей в разные стороны
	for(var/d in GLOB.cardinals)
		if(prob(75))
			var/obj/effect/temp_visual/flying_limb/L = new(T)
			var/part = pick("flying_ribs", "flying_guts", "[prefix]_flying_arm", "[prefix]_flying_head", "[prefix]_flying_leg")
			L.launch(T, d, part, gore_dmi)

	spawn_optimized_blood_decal(T, TRUE)

	// Оставляем разорванный труп
	icon_dead = "[prefix]_dead_half"

// Оптимизированный спавн декалей крови с защитой от FPS-просадок и авто-очисткой
/mob/living/simple_animal/hostile/infected/modular/proc/spawn_optimized_blood_decal(turf/T, forced = FALSE)
	if(!T)
		return
	var/blood_count = 0
	for(var/obj/effect/decal/cleanable/blood/B in T)
		blood_count++
		if(blood_count >= 2 && !forced)
			return // Больше 2 пятен на тайле не спавним для оптимизации

	var/obj/effect/decal/cleanable/blood/splatter/B = new(T)
	QDEL_IN(B, 3 MINUTES) // Авто-исчезновение через 3 минуты

// Обработка получения урона с проверкой расчленения
/mob/living/simple_animal/hostile/infected/modular/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(amount > 0 && stat != DEAD)
		if(amount >= dismemberment_threshold)
			check_random_dismemberment(amount)
		else if(prob(30))
			var/turf/T = get_turf(src)
			var/obj/effect/temp_visual/blood_spurt/S = new(T)
			S.spurt(pick(GLOB.alldirs))

// Случайная потеря конечности в зависимости от урона
/mob/living/simple_animal/hostile/infected/modular/proc/check_random_dismemberment(damage_amount)
	if(stat == DEAD)
		return

	var/list/possible_losses = list()
	if(limbs_status & ZOMBIE_LIMB_R_ARM)
		possible_losses += "r_arm"
	if(limbs_status & ZOMBIE_LIMB_L_ARM)
		possible_losses += "l_arm"
	if(limbs_status & ZOMBIE_LIMB_R_LEG)
		possible_losses += "r_leg"
	if(limbs_status & ZOMBIE_LIMB_L_LEG)
		possible_losses += "l_leg"
	if(limbs_status & ZOMBIE_LIMB_HEAD)
		possible_losses += "head"

	if(!possible_losses.len)
		return

	var/chosen = pick(possible_losses)
	switch(chosen)
		if("r_arm")
			sever_r_arm(null, pick(GLOB.cardinals))
		if("l_arm")
			sever_l_arm(null, pick(GLOB.cardinals))
		if("r_leg")
			sever_leg("r_leg", null, pick(GLOB.cardinals))
		if("l_leg")
			sever_leg("l_leg", null, pick(GLOB.cardinals))
		if("head")
			if(health <= 35 || prob(25)) // Хедшот добивает или срабатывает при малом HP
				sever_head(null, pick(GLOB.cardinals))

/mob/living/simple_animal/hostile/infected/modular/death(gibbed)
	if(health <= -50 || gibbed)
		gib_explosion(null)
	else if(!(limbs_status & ZOMBIE_LIMB_HEAD))
		icon_dead = "[prefix]_dead_decap"
	. = ..(gibbed)

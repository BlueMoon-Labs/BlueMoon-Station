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
// FLYING LIMB TEMP EFFECT (Matrix-rotated, self-cleaning)
// =============================================================================

/obj/effect/temp_visual/flying_limb
	name = "flying limb"
	icon = 'modular_bluemoon/icons/mob/gibsnguts/infected.dmi'
	icon_state = "sci_flying_arm"
	duration = 14
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

	animate(src, transform = M, pixel_x = offset_x, pixel_y = offset_y, time = 9, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 0, time = 4)

// =============================================================================
// MODULAR SCIENTIST INFECTED MOB (TEST PROTOTYPE)
// =============================================================================

/mob/living/simple_animal/hostile/infected/modular
	name = "infected scientist"
	desc = "A horrifying mutated research scientist with modular decaying limbs."
	icon = 'modular_bluemoon/icons/mob/gibsnguts/infected.dmi'
	icon_state = "sci_body"
	icon_living = "sci_body"
	icon_dead = "sci_dead"

	// DMI-файл расчлененки
	var/gore_dmi = 'modular_bluemoon/icons/mob/gibsnguts/infected.dmi'
	var/prefix = "sci"

	// Битовая маска целых конечностей (голова, 2 руки, 2 ноги)
	var/limbs_status = ZOMBIE_LIMB_HEAD | ZOMBIE_LIMB_R_ARM | ZOMBIE_LIMB_L_ARM | ZOMBIE_LIMB_R_LEG | ZOMBIE_LIMB_L_LEG

	// Флаг хедшота текущего урона - выставляется в apply_damage по def_zone
	var/last_damage_was_headshot = FALSE

	// Ссылки на оверлеи конечностей: mutable_appearance БЕЗ dir рендерится всегда
	// в SOUTH-кадре (известный баг BYOND), поэтому dir задаём при создании
	// и синхронизируем при повороте моба.
	var/list/gore_overlay_refs = list()

	// Состояния
	var/legs_lost_count = 0
	var/instant_kill_on_single_leg = FALSE // Если TRUE - потеря даже одной ноги убивает на месте
	var/wound_chest_active = FALSE

	// Burst-урон за короткое окно (дробовик в упор и т.п.) -> гарантированный гиб
	var/burst_damage = 0
	var/burst_damage_expire = 0
	var/gib_pending = FALSE

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
	gore_overlay_refs.Cut()

	// Слой головы / культи шеи
	if(limbs_status & ZOMBIE_LIMB_HEAD)
		add_gore_overlay("[prefix]_head")
	else
		add_gore_overlay("stump_neck")

	// Слой правой руки / культи
	if(limbs_status & ZOMBIE_LIMB_R_ARM)
		add_gore_overlay("[prefix]_arm_r")
	else
		add_gore_overlay("stump_arm_r")

	// Слой левой руки / культи
	if(limbs_status & ZOMBIE_LIMB_L_ARM)
		add_gore_overlay("[prefix]_arm_l")
	else
		add_gore_overlay("stump_arm_l")

	// Слой правой ноги / культи
	if(limbs_status & ZOMBIE_LIMB_R_LEG)
		add_gore_overlay("[prefix]_leg_r")
	else
		add_gore_overlay("stump_leg_r")

	// Слой левой ноги / культи
	if(limbs_status & ZOMBIE_LIMB_L_LEG)
		add_gore_overlay("[prefix]_leg_l")
	else
		add_gore_overlay("stump_leg_l")

	// Оверлей ранения груди
	if(wound_chest_active)
		add_gore_overlay("wound_chest")

/mob/living/simple_animal/hostile/infected/modular/proc/add_gore_overlay(icon_state)
	var/mutable_appearance/A = mutable_appearance(gore_dmi, icon_state)
	gore_overlay_refs += A
	sync_gore_overlay_dir(A) // dir до add_overlay: mutable_appearance без dir залипает в SOUTH
	add_overlay(A)

// Прокидывает направление моба в оверлей. dir обязан быть задан до/при добавлении
// в overlays - mutable_appearance без dir навсегда рендерит SOUTH-кадр (баг BYOND).
/mob/living/simple_animal/hostile/infected/modular/proc/sync_gore_overlay_dir(mutable_appearance/A)
	A.dir = dir

// Поворот моба: mutable_appearance не наследует dir атома автоматически,
// поэтому вручную синхронизируем направление во всех оверлеях конечностей.
/mob/living/simple_animal/hostile/infected/modular/setDir(newdir, ismousemovement = FALSE)
	. = ..(newdir, ismousemovement)
	for(var/mutable_appearance/A in gore_overlay_refs)
		sync_gore_overlay_dir(A)

// Отстрел головы (Хедшот -> мгновенная смерть)
/mob/living/simple_animal/hostile/infected/modular/proc/sever_head(atom/attacker, dir_hit = null)
	if(stat == DEAD || !(limbs_status & ZOMBIE_LIMB_HEAD))
		return
	limbs_status &= ~ZOMBIE_LIMB_HEAD

	var/turf/T = get_turf(src)
	if(T)
		playsound(T, pick( 'sound/effects/wounds/pierce2.ogg', 'sound/effects/splat.ogg', 'sound/effects/wounds/blood3.ogg'), 75, TRUE)

	// Вылет головы
	if(T)
		var/obj/effect/temp_visual/flying_limb/L = new(T)
		L.launch(T, dir_hit ? dir_hit : pick(GLOB.cardinals), "[prefix]_flying_head", gore_dmi)

	// Отрыв головы = чистая декапитация, без взрыва тела
	gib_pending = FALSE
	icon_dead = "[prefix]_dead_decap"
	death(FALSE)

// Отстрел правой руки
/mob/living/simple_animal/hostile/infected/modular/proc/sever_r_arm(atom/attacker, dir_hit = null)
	if(stat == DEAD || !(limbs_status & ZOMBIE_LIMB_R_ARM))
		return
	limbs_status &= ~ZOMBIE_LIMB_R_ARM

	var/turf/T = get_turf(src)
	if(T)
		playsound(T, pick('sound/effects/blobattack.ogg', 'sound/effects/meatslap.ogg', 'sound/effects/gib_step.ogg'), 60, TRUE)
		var/obj/effect/temp_visual/flying_limb/L = new(T)
		L.launch(T, dir_hit ? dir_hit : dir, "[prefix]_flying_arm", gore_dmi)

	// Снижение боевой эффективности
	melee_damage_lower = max(2, melee_damage_lower * 0.7)
	melee_damage_upper = max(5, melee_damage_upper * 0.7)

	assemble_modular_limbs()

// Отстрел левой руки
/mob/living/simple_animal/hostile/infected/modular/proc/sever_l_arm(atom/attacker, dir_hit = null)
	if(stat == DEAD || !(limbs_status & ZOMBIE_LIMB_L_ARM))
		return
	limbs_status &= ~ZOMBIE_LIMB_L_ARM

	var/turf/T = get_turf(src)
	if(T)
		playsound(T, pick('sound/effects/blobattack.ogg', 'sound/effects/meatslap.ogg', 'sound/effects/gib_step.ogg'), 60, TRUE)
		var/obj/effect/temp_visual/flying_limb/L = new(T)
		L.launch(T, dir_hit ? dir_hit : dir, "[prefix]_flying_arm", gore_dmi)

	// Потеря левой руки отключает захват / замедление
	melee_damage_lower = max(2, melee_damage_lower * 0.7)
	melee_damage_upper = max(5, melee_damage_upper * 0.7)

	assemble_modular_limbs()

// Отстрел ноги (Замедление при потере одной, мгновенная смерть при потере обеих или травматическом шоке)
/mob/living/simple_animal/hostile/infected/modular/proc/sever_leg(leg_type = "r_leg", atom/attacker = null, dir_hit = null)
	var/target_bit = (leg_type == "r_leg") ? ZOMBIE_LIMB_R_LEG : ZOMBIE_LIMB_L_LEG
	if(stat == DEAD || !(limbs_status & target_bit))
		return

	limbs_status &= ~target_bit
	legs_lost_count++

	var/turf/T = get_turf(src)
	if(T)
		playsound(T, pick('sound/effects/wounds/crack1.ogg', 'sound/effects/wounds/crack2.ogg', 'sound/effects/wounds/crackandbleed.ogg'), 70, TRUE)

	// Вылет оторванной ноги
	if(T)
		var/obj/effect/temp_visual/flying_limb/L = new(T)
		L.launch(T, dir_hit ? dir_hit : dir, "[prefix]_flying_leg", gore_dmi)

	// Логика смерти / замедления:
	// Если потерял обе ноги ИЛИ включена мгновенная смерть от потери конечности
	if(legs_lost_count >= 2 || instant_kill_on_single_leg)
		visible_message(span_warning("[src] падает замертво от травматического шока и потери конечностей!"))
		icon_dead = "[prefix]_dead" // в DMI нет sci_dead_legless, берём базовый труп
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

	playsound(T, pick('sound/effects/splat.ogg', 'sound/effects/meatslap.ogg', 'sound/effects/butcher.ogg'), 80, TRUE)

	// Разлёт конечностей и костей в разные стороны
	for(var/d in GLOB.alldirs)
		if(prob(80))
			var/obj/effect/temp_visual/flying_limb/L = new(T)
			var/part = pick("flying_ribs", "flying_guts", "[prefix]_flying_arm", "[prefix]_flying_head", "[prefix]_flying_leg")
			L.launch(T, d, part, gore_dmi)

	// Гарантированный минимум кусков, чтобы взрыв всегда выглядел мясным
	for(var/i in 1 to 3)
		var/obj/effect/temp_visual/flying_limb/L = new(T)
		L.launch(T, pick(GLOB.alldirs), pick("flying_ribs", "flying_guts", "[prefix]_flying_arm", "[prefix]_flying_head", "[prefix]_flying_leg"), gore_dmi)

	playsound(T, pick('sound/effects/wounds/blood1.ogg', 'sound/effects/wounds/blood2.ogg', 'sound/effects/wounds/crackandbleed.ogg'), 60, TRUE)

	// Оставляем разорванный труп
	icon_dead = "[prefix]_dead_half"

// apply_damage получает def_zone от снарядов/ударов - adjustHealth её не видит.
// Запоминаем хедшот, чтобы adjustHealth мог оторвать голову по факту попадания.
/mob/living/simple_animal/hostile/infected/modular/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE, spread_damage = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	last_damage_was_headshot = (def_zone == BODY_ZONE_HEAD)
	. = ..(damage, damagetype, def_zone, blocked, forced, spread_damage, wound_bonus, bare_wound_bonus, sharpness)
	last_damage_was_headshot = FALSE

// Обработка получения урона с проверкой расчленения
/mob/living/simple_animal/hostile/infected/modular/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(amount <= 0 || stat == DEAD)
		return

	// Накапливаем урон за ~2 сек: серия попаданий (дробь в упор) гарантированно gib'ает
	if(world.time >= burst_damage_expire)
		burst_damage = 0
		burst_damage_expire = world.time + 20
	burst_damage += amount
	if(burst_damage >= 50)
		gib_pending = TRUE

	// Рана груди видна уже при 75% HP - при старом пороге в 50% её почти не было видно
	if(health <= maxHealth * 0.75 && !wound_chest_active)
		wound_chest_active = TRUE
		assemble_modular_limbs()

	// Хедшот отрывает голову при любом заметном уроне, без порога расчленения
	if(last_damage_was_headshot) {
		sever_head(null, pick(GLOB.cardinals))
		return
	}

	// Любой урон (даже самый слабый) гарантированно отрывает конечность,
	// а голова отлетает часто и без прицеливания - см. check_random_dismemberment
	check_random_dismemberment(amount)

// Отрыв случайной целой конечности. Возвращает TRUE, если что-то оторвало.
/mob/living/simple_animal/hostile/infected/modular/proc/sever_random_limb()
	if(stat == DEAD)
		return FALSE

	var/list/possible_losses = list()
	if(limbs_status & ZOMBIE_LIMB_R_ARM)
		possible_losses += "r_arm"
	if(limbs_status & ZOMBIE_LIMB_L_ARM)
		possible_losses += "l_arm"
	if(limbs_status & ZOMBIE_LIMB_R_LEG)
		possible_losses += "r_leg"
	if(limbs_status & ZOMBIE_LIMB_L_LEG)
		possible_losses += "l_leg"
	// Голова НЕ входит в пул конечностей: у неё свой высокий шанс ниже,
	// иначе guaranteed-отрыв срабатывал бы на голову так же часто, как на руку.

	if(!possible_losses.len)
		return FALSE

	switch(pick(possible_losses))
		if("r_arm")
			sever_r_arm(null, pick(GLOB.cardinals))
		if("l_arm")
			sever_l_arm(null, pick(GLOB.cardinals))
		if("r_leg")
			sever_leg("r_leg", null, pick(GLOB.cardinals))
		if("l_leg")
			sever_leg("l_leg", null, pick(GLOB.cardinals))
	return TRUE

// Потеря конечностей и головы при попадании
/mob/living/simple_animal/hostile/infected/modular/proc/check_random_dismemberment(damage_amount)
	if(stat == DEAD)
		return

	// 1) Гарантированно: каждый удар отрывает одну целую конечность.
	var/severed_limb = sever_random_limb()

	// Тяжёлые попадания (дробь, тяжёлое оружие) могут оторвать вторую конечность.
	if(damage_amount >= 30 && severed_limb && prob(clamp(damage_amount * 0.6, 20, 55)))
		sever_random_limb()

	// Отрыв второй ноги мог убить моба - дальше крутить голову не нужно
	if(stat == DEAD)
		return

	// 2) Голова отлетает часто и без прицеливания; шанс растёт с силой удара.
	// Когда конечности уже все оторваны, голова отлетает почти всегда -
	// именно поэтому stump_neck/dead_decap теперь реально попадаются.
	var/intact_limbs = (limbs_status & (ZOMBIE_LIMB_R_ARM | ZOMBIE_LIMB_L_ARM | ZOMBIE_LIMB_R_LEG | ZOMBIE_LIMB_L_LEG)) != 0
	var/head_chance = intact_limbs ? clamp(30 + damage_amount * 1.2, 30, 90) : 70
	if((limbs_status & ZOMBIE_LIMB_HEAD) && prob(head_chance))
		sever_head(null, pick(GLOB.cardinals))

// Разлёт кусков тела при ЛЮБОЙ смерти - даже без гиба труп не уходит чистым.
/mob/living/simple_animal/hostile/infected/modular/proc/death_gore_scatter()
	var/turf/T = get_turf(src)
	if(!T)
		return
	playsound(T, pick('sound/effects/splat.ogg', 'sound/effects/meatslap.ogg'), 70, TRUE)
	for(var/i in 1 to 2 + rand(0, 2))
		var/obj/effect/temp_visual/flying_limb/L = new(T)
		L.launch(T, pick(GLOB.alldirs), pick("flying_ribs", "flying_guts", "[prefix]_flying_arm", "[prefix]_flying_head", "[prefix]_flying_leg"), gore_dmi)

/mob/living/simple_animal/hostile/infected/modular/death(gibbed)
	var/exploded = FALSE
	if(health <= -50 || gibbed || gib_pending)
		gib_explosion(null)
		exploded = TRUE
	else if(!(limbs_status & ZOMBIE_LIMB_HEAD))
		icon_dead = "[prefix]_dead_decap"
	if(!exploded)
		death_gore_scatter()
	. = ..(gibbed)
	// Труп чистый: снимаем ВСЕ оверлеи (конечности, культи, ранения)
	cut_overlays()
	gore_overlay_refs.Cut()

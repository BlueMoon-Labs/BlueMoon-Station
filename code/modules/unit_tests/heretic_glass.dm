/datum/unit_test/proc/glass_blind_timer(datum/eldritch_knowledge/base_glass/glass, mob/living/victim)
	return SStimer.timer_id_dict[glass.blind_timers[REF(victim)]]

/datum/unit_test/proc/expire_glass_blind(datum/eldritch_knowledge/base_glass/glass, mob/living/victim)
	var/timer_id = glass.blind_timers[REF(victim)]
	var/datum/timedevent/cure = SStimer.timer_id_dict[timer_id]
	cure?.callBack.Invoke()
	deltimer(timer_id)

/// Хватка не создаёт грани, взрыв метки даёт одну, восстановление имеет отдельную задержку.
/datum/unit_test/heretic_glass_combat_cycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_mark)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/glass_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/glass_grasp)
	var/datum/eldritch_knowledge/glass_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/glass_mark)
	var/obj/item/melee/sickly_blade/glass/blade = allocate(/obj/item/melee/sickly_blade/glass)
	blade.wound_bonus = CANT_WOUND
	blade.bare_wound_bonus = CANT_WOUND
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Строительство начинается с двух граней.")
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка оставляет трещины.")
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE), "Хватка оставляет метку.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Хватка не производит строительный запас.")
	blade.afterattack(victim, user, TRUE, null)
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(glass.combat_resource, 3, "Взрыв метки настоящим ударом даёт одну грань.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/glass), "Удар клинком расходует метку.")
	TEST_ASSERT(abs(victim.getBruteLoss() - blade.force - 8) < 0.01, "Взрыв метки добавляет к удару клинком ровно восемь ушибов.")
	TEST_ASSERT(victim.is_blind(), "Взрыв метки ослепляет цель.")
	var/datum/timedevent/cure = glass_blind_timer(glass, victim)
	TEST_ASSERT_NOTNULL(cure, "Слепоту снимает свой таймер.")
	TEST_ASSERT(abs(cure.timeToRun - world.time - (1 SECONDS)) < 0.1, "Взрыв метки ослепляет ровно на секунду. Осталось: [cure.timeToRun - world.time] дс.")
	TEST_ASSERT(wait_for_var(victim, NAMEOF(victim, eye_blind), 0, 3 SECONDS), "Слепота от метки проходит сама.")
	TEST_ASSERT(!victim.is_blind(), "После секунды цель снова видит.")
	var/damage_before = victim.getBruteLoss()
	glass.release(user, victim)
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - damage_before - 30) < 0.01, "Трещины не добавляют урона прямому лучу.")
	TEST_ASSERT(victim.is_blind(), "Луч по трещинам ослепляет цель.")
	glass.combat_resource = 2
	COOLDOWN_RESET(glass, facet_regeneration)
	glass.on_life(user)
	TEST_ASSERT_EQUAL(glass.combat_resource, 3, "Пассивное восстановление даёт одну строительную грань.")
	glass.on_life(user)
	TEST_ASSERT_EQUAL(glass.combat_resource, 3, "Повторный life не обходит задержку.")
	glass.gain_combat_resource(100)
	TEST_ASSERT_EQUAL(glass.combat_resource, 4, "Строительный запас ограничен вместимостью.")

/// Бесплатный луч предупреждает об ударе и расходует антимагию один раз при попадании.
/datum/unit_test/heretic_glass_release_protection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(protected, EAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/effect/proc_holder/spell/pointed/heretic_glass/release/spell = glass.combat_power
	glass.combat_resource = 0
	TEST_ASSERT(!spell.can_target(protected, user, TRUE), "Предварительный выбор учитывает антимагию.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Выбор не расходует заряды.")
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Пустой строительный запас не мешает лучу.")
	TEST_ASSERT(glass.release(user, victim), "Луч выпускается без граней.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Во время предупреждения урона нет.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	TEST_ASSERT(wait_for_qdeleted(attack), "Настоящий таймер завершает предупреждённый удар.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) < 0.01, "Луч наносит тридцать ушибов без подготовки сети.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует урон.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Один луч тратит один заряд на цель.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Союзник не получает урон.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Создатель не получает урон.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 0, "Попадания не возвращают строительный ресурс.")

/// Своя призма поворачивает луч за угол, а разрушение узла и новые стены отменяют зависимую трассу.
/datum/unit_test/heretic_glass_telegraph_and_walls/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/node_place = get_step(get_step(user, EAST), EAST)
	user.setDir(NORTH)
	TEST_ASSERT(glass.shards(user, node_place), "Свободная клетка принимает призму.")
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(node_place, NORTH), NORTH))
	var/obj/corner = allocate(/obj, get_step(user, NORTHEAST))
	corner.density = TRUE
	TEST_ASSERT(!glass.line_clear(user, victim), "Прямая линия до противника закрыта углом.")
	glass.fracture(victim)
	TEST_ASSERT(glass.release(user, prism), "Луч можно направить в собственную призму.")
	var/datum/heretic_glass_attack/first = glass.attacks[1]
	first.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) < 0.01, "Преломление обходит угол, трещины урон не добавляют.")
	TEST_ASSERT(victim.eye_blind > 0, "Преломлённый луч ослепляет треснувшую цель.")
	var/damage_before = victim.getBruteLoss()
	glass.release(user, prism)
	var/datum/heretic_glass_attack/second = glass.attacks[1]
	var/obj/blocker = allocate(/obj, get_step(node_place, NORTH))
	blocker.density = TRUE
	second.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), damage_before, "Новая стена прерывает уже предупреждённый участок.")
	qdel(blocker)
	glass.release(user, prism)
	var/datum/heretic_glass_attack/third = glass.attacks[1]
	qdel(prism)
	third.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), damage_before, "Удалённая призма не продолжает отражать старый луч.")
	var/turf/straight = get_step(user, EAST)
	glass.release(user, straight)
	var/datum/heretic_glass_attack/fourth = glass.attacks[1]
	victim.forceMove(get_step(straight, NORTH))
	fourth.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), damage_before, "Противник на непредупреждённой клетке избегает луча.")

/// Защитные преграды остаются отдельными конструкциями с пределом и сохранением старого урона.
/datum/unit_test/heretic_glass_barriers_and_temper/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/east = get_step(user, EAST)
	TEST_ASSERT_NULL(glass.create_barrier(user, east), "Без призм преграда не создаётся.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	glass.combat_resource = 4
	TEST_ASSERT_NULL(glass.create_barrier(user, get_turf(user)), "Преграда не возникает внутри человека.")
	var/obj/structure/heretic_glass_barrier/first = glass.create_barrier(user, east)
	TEST_ASSERT_NOTNULL(first, "Свободная клетка принимает преграду.")
	TEST_ASSERT_EQUAL(first.obj_integrity, 45, "Начальная прочность конечна.")
	TEST_ASSERT(!user.Move(east, EAST), "Создатель не проходит сквозь защитное стекло.")
	TEST_ASSERT_NULL(glass.create_barrier(user, east), "Преграды не складываются на одной клетке.")
	var/obj/structure/heretic_glass_barrier/second = glass.create_barrier(user, get_step(user, NORTH))
	TEST_ASSERT_NOTNULL(second, "Можно создать вторую защитную преграду.")
	TEST_ASSERT_NULL(glass.create_barrier(user, get_step(user, NORTHEAST)), "Общий предел преград соблюдается.")
	first.take_damage(10, BRUTE, MELEE)
	var/old_damage = first.max_integrity - first.obj_integrity
	var/old_expiry = first.expires_at
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_temper)
	var/datum/eldritch_knowledge/glass_temper/temper = heretic.get_knowledge(/datum/eldritch_knowledge/glass_temper)
	TEST_ASSERT_EQUAL(glass.combat_resource_max, 5, "Первая закалка вмещает пять граней.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Изучение не наполняет строительный запас.")
	temper.passive_level = 3
	temper.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(glass.combat_resource_max, 7, "Третья закалка вмещает семь граней.")
	TEST_ASSERT_EQUAL(first.max_integrity, 90, "Третья закалка даёт 90 прочности.")
	TEST_ASSERT_EQUAL(first.max_integrity - first.obj_integrity, old_damage, "Закалка не чинит старый урон.")
	TEST_ASSERT_EQUAL(first.expires_at, old_expiry, "Закалка не продлевает жизнь преграды.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	first.attackby(rod, user)
	TEST_ASSERT(QDELETED(first), "Нулевой жезл уничтожает защитное стекло.")
	second.take_damage(200, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(second), "Обычный урон тоже разрушает преграду.")
	TEST_ASSERT_EQUAL(length(glass.barriers), 0, "Разрушенные преграды освобождают предел.")

/// Отражения расходуют прочность даже без урона и не восстанавливаются закалкой.
/datum/unit_test/heretic_glass_reflection_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/heretic_glass_barrier/barrier = glass.create_barrier(user, get_step(user, EAST))
	var/obj/item/projectile/energy/shot = allocate(/obj/item/projectile/energy, get_turf(barrier))
	shot.setAngle(37)
	shot.range = 12
	shot.decayedRange = 50
	TEST_ASSERT_EQUAL(barrier.bullet_act(shot), BULLET_ACT_FORCE_PIERCE, "Энергетический выстрел продолжает полёт после отражения.")
	TEST_ASSERT_EQUAL(shot.Angle, 217, "Возврат сохраняет обратное направление между сторонами света.")
	TEST_ASSERT_EQUAL(shot.range, 7, "Отражение сокращает оставшуюся дальность, не восстанавливая её.")
	TEST_ASSERT_EQUAL(shot.decayedRange, 7, "Следующее отражение не вернёт исходную дальность.")
	TEST_ASSERT_EQUAL(barrier.obj_integrity, 30, "Даже безвредный выстрел снимает 15 прочности.")
	TEST_ASSERT_EQUAL(barrier.reflections_left, 1, "Первый возврат расходует одно отражение.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_temper)
	TEST_ASSERT_EQUAL(barrier.reflections_left, 1, "Закалка не восстанавливает отражения.")
	TEST_ASSERT_EQUAL(barrier.obj_integrity, 45, "Закалка сохраняет полученный износ.")
	shot = allocate(/obj/item/projectile/energy, get_turf(barrier))
	TEST_ASSERT_EQUAL(barrier.bullet_act(shot), BULLET_ACT_FORCE_PIERCE, "Второй выстрел тоже отражается.")
	TEST_ASSERT_EQUAL(barrier.reflections_left, 0, "Бюджет отражений исчерпан.")
	shot = allocate(/obj/item/projectile/energy, get_turf(barrier))
	TEST_ASSERT_NOTEQUAL(barrier.bullet_act(shot), BULLET_ACT_FORCE_PIERCE, "Третий выстрел обрабатывается обычной преградой.")
	TEST_ASSERT(!shot.ignore_source_check, "Третий выстрел не получает свойства отражённого.")

/// Пули, запрет отражения и истёкший срок преграды сохраняют обычное попадание.
/datum/unit_test/heretic_glass_reflection_exclusions/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/heretic_glass_barrier/barrier = glass.create_barrier(user, get_step(user, EAST))
	var/obj/item/projectile/bullet/bullet = allocate(/obj/item/projectile/bullet, get_turf(barrier))
	bullet.damage = 10
	bullet.is_reflectable = TRUE
	TEST_ASSERT_NOTEQUAL(barrier.bullet_act(bullet), BULLET_ACT_FORCE_PIERCE, "Даже отражаемая пуля не возвращается стеклом.")
	TEST_ASSERT_EQUAL(barrier.obj_integrity, 35, "Пуля наносит обычный урон преграде.")
	var/obj/item/projectile/beam/beam = allocate(/obj/item/projectile/beam, get_turf(barrier))
	beam.is_reflectable = FALSE
	TEST_ASSERT_NOTEQUAL(barrier.bullet_act(beam), BULLET_ACT_FORCE_PIERCE, "Явный запрет отражения соблюдается.")
	TEST_ASSERT_EQUAL(barrier.obj_integrity, 15, "Неотражаемый луч повреждает стекло.")
	barrier.expires_at = world.time
	var/obj/item/projectile/energy/shot = allocate(/obj/item/projectile/energy, get_turf(barrier))
	TEST_ASSERT_NOTEQUAL(barrier.bullet_act(shot), BULLET_ACT_FORCE_PIERCE, "Истёкшая преграда не отражает до следующего process.")
	TEST_ASSERT_EQUAL(barrier.reflections_left, 2, "Обычные попадания не расходуют отражения.")

/datum/unit_test/heretic_glass_reflection_flight
	var/instant_shot = FALSE
	var/fragile_barrier = FALSE

/// Реальный выстрел возвращается стрелку, теряет наведение и не задевает укрытого еретика.
/datum/unit_test/heretic_glass_reflection_flight/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/heretic_glass_barrier/barrier = glass.create_barrier(user, get_step(get_step(user, EAST), EAST))
	if(fragile_barrier)
		barrier.take_damage(40, BRUTE, sound_effect = FALSE)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, get_step(get_step(barrier, EAST), EAST))
	var/obj/item/projectile/beam/shot = allocate(/obj/item/projectile/beam, get_turf(shooter))
	shot.firer = shooter
	shot.hitscan = instant_shot
	shot.ricochet_chance = 0
	shot.preparePixelProjectile(user, shooter)
	shot.set_homing_target(user)
	shot.fire()
	for(var/step_index in 1 to 8)
		if(QDELETED(shot))
			break
		shot.process(1)
	TEST_ASSERT(QDELETED(shot), "Выстрел завершает полёт после обратного попадания.")
	TEST_ASSERT(abs(shooter.getFireLoss() - 20) < DAMAGE_PRECISION, "Исходный стрелок получает полный урон отражённого луча.")
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Преграда защищает еретика за собой.")
	if(fragile_barrier)
		TEST_ASSERT(QDELETED(barrier), "Смертельный износ разрушает преграду, сохраняя последний возврат.")
	else
		TEST_ASSERT_EQUAL(barrier.obj_integrity, 25, "Отражение снимает прочность в размере урона луча.")
		TEST_ASSERT_EQUAL(barrier.reflections_left, 1, "Реальное столкновение расходует только одно отражение.")

/datum/unit_test/heretic_glass_reflection_flight/hitscan
	instant_shot = TRUE

/datum/unit_test/heretic_glass_reflection_flight/shattering
	fragile_barrier = TRUE

/// Заклинание размещает и поворачивает реальные узлы, а касание рукой расщепляет луч выбранного узла.
/datum/unit_test/heretic_glass_prism/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/spell/glass_shards/placement = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/spell = placement.granted_spell
	var/turf/node_place = get_step(user, EAST)
	TEST_ASSERT(spell.can_target(node_place, user, TRUE), "Pointed-заклинание позволяет выбрать свободный пол.")
	user.setDir(EAST)
	spell.cast(list(node_place), user)
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	TEST_ASSERT_NOTNULL(prism, "Настоящий cast устанавливает призму.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 1, "Установка стоит одну строительную грань.")
	TEST_ASSERT_EQUAL(prism.dir, EAST, "Стрелка следует направлению взгляда.")
	TEST_ASSERT(spell.can_target(prism, user, TRUE), "Свою призму можно выбрать повторно.")
	user.setDir(NORTH)
	spell.cast(list(prism), user)
	TEST_ASSERT_EQUAL(prism.dir, NORTH, "Повторный cast меняет направление.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 1, "Поворот бесплатен.")
	prism.setDir(EAST)
	TEST_ASSERT(glass.shards(user, get_step(user, WEST)), "Второй узел занимает своё место.")
	glass.gain_combat_resource()
	TEST_ASSERT(glass.shards(user, get_step(user, SOUTH)), "Третий узел укладывается в предел.")
	glass.gain_combat_resource()
	TEST_ASSERT(!glass.shards(user, get_step(user, NORTHEAST)), "Четвёртый узел не обходит предел строительства.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 1, "Отклонённое строительство не тратит ресурс.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	other.selected_path = PATH_GLASS
	other.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	other.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/datum/eldritch_knowledge/base_glass/other_glass = other.get_knowledge(/datum/eldritch_knowledge/base_glass)
	other_glass.shards(other.owner.current, get_step(other.owner.current, NORTH))
	var/obj/structure/heretic_glass_prism/foreign = other_glass.prisms[1]
	TEST_ASSERT(!spell.can_target(foreign, user, TRUE), "Чужая призма не выбирается для поворота.")
	TEST_ASSERT(!glass.shards(user, foreign), "Прямой вызов тоже не присваивает чужой узел.")
	prism.attack_hand(user)
	TEST_ASSERT(prism.split, "Касание рукой переводит призму в режим расщепления.")
	TEST_ASSERT_EQUAL(prism.dir, EAST, "Касание рукой не поворачивает стрелку.")
	var/obj/structure/heretic_glass_prism/selected = glass.prisms[3]
	selected.attack_hand(user)
	TEST_ASSERT(selected.split && prism.split, "Каждая призма переключается отдельно.")
	var/mob/living/upper = allocate(/mob/living/carbon/human, get_step(node_place, NORTHEAST))
	var/mob/living/lower = allocate(/mob/living/carbon/human, get_step(node_place, SOUTHEAST))
	glass.release(user, prism)
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(upper.getBruteLoss() - 30) < 0.01, "Верхняя ветвь наносит тридцать ушибов.")
	TEST_ASSERT(abs(lower.getBruteLoss() - 30) < 0.01, "Нижняя ветвь наносит тридцать ушибов.")

/// Пересечение сети бьёт один раз, а поворот и разрушение узлов не расширяют старое предупреждение.
/datum/unit_test/heretic_glass_storm/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	TEST_ASSERT(glass.storm(user), "Свет выпускается и без призм.")
	var/datum/heretic_glass_attack/unprepared = glass.attacks[1]
	unprepared.resolve()
	user.setDir(NORTH)
	glass.shards(user, get_step(get_step(user, EAST), EAST))
	user.setDir(EAST)
	glass.shards(user, get_step(get_step(get_step(user, NORTH), NORTH), NORTH))
	var/obj/structure/heretic_glass_prism/eastern = glass.prisms[1]
	var/obj/structure/heretic_glass_prism/northern = glass.prisms[2]
	var/turf/crossing = get_step(get_step(get_step(get_turf(eastern), NORTH), NORTH), NORTH)
	var/mob/living/victim = allocate(/mob/living/carbon/human, crossing)
	var/mob/living/protected = allocate(/mob/living/carbon/human, crossing)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(glass.storm(user), "Два узла создают предупреждённую сеть.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 0, "Сеть не требует нового строительного ресурса.")
	var/datum/heretic_glass_attack/first = glass.attacks[1]
	first.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 46) < 0.01, "Пересечение двух лучей не удваивает урон.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Пересечение тратит один заряд антимагии.")
	glass.storm(user)
	var/datum/heretic_glass_attack/second = glass.attacks[1]
	eastern.setDir(WEST)
	qdel(northern)
	second.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 46) < 0.01, "Разобранная геометрия не исполняет прежние лучи.")
	eastern.setDir(NORTH)
	glass.storm(user)
	var/datum/heretic_glass_attack/third = glass.attacks[1]
	user.forceMove(get_step(user, NORTH))
	TEST_ASSERT(!QDELETED(third), "Движение не отменяет уже предупреждённый свет.")
	third.resolve()

/// Смерть и переселение убирают призмы, чужие статусы, предупреждения и прежнюю способность, но оставляют настроенные стёкла.
/datum/unit_test/heretic_glass_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_mark)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/structure/window/fulltile/pane = allocate(/obj/structure/window/fulltile, get_step(user, SOUTH))
	TEST_ASSERT(glass.attune(pane, user), "Окно настроено до смерти.")
	glass.fracture(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/glass, glass)
	glass.shards(user, get_step(user, NORTH))
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	glass.release(user, victim)
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	var/old_generation = glass.glass_generation
	user.stat = DEAD
	glass.on_death(user)
	TEST_ASSERT(QDELETED(attack), "Смерть удаляет ожидающий луч.")
	TEST_ASSERT(QDELETED(prism), "Смерть удаляет оптическую установку.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_glass_fracture), "Смерть снимает чужие трещины.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/glass), "Смерть снимает метку.")
	TEST_ASSERT_EQUAL(length(glass.visuals), 0, "Смерть убирает все предупреждения.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 0, "Смерть обнуляет строительный запас.")
	TEST_ASSERT(glass.glass_generation > old_generation, "Поколение прежних атак закрыто.")
	TEST_ASSERT(pane in glass.attuned_panes, "Настроенное стекло переживает смерть.")
	user.stat = CONSCIOUS
	glass.release(user, victim)
	attack = glass.attacks[1]
	var/obj/effect/proc_holder/spell/old_power = glass.combat_power
	var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(victim, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(QDELETED(attack), "Переселение отменяет луч старого тела.")
	TEST_ASSERT(QDELETED(old_power), "Переселение удаляет прежнюю способность.")
	TEST_ASSERT_EQUAL(glass.glass_body, new_body, "Оптика принадлежит новому телу.")
	TEST_ASSERT(!glass.can_use(user), "Старое тело теряет полномочия.")
	TEST_ASSERT(glass.can_use(new_body), "Новое тело получает полномочия.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(pane, "glass_pane"), "Настроенное стекло переживает смену тела.")
	glass.release(new_body, victim)
	attack = glass.attacks[1]
	qdel(glass)
	TEST_ASSERT(QDELETED(attack), "Удаление основного знания отменяет оставшийся луч.")
	TEST_ASSERT_NULL(heretic_craft_on(pane, "glass_pane"), "Удаление основного знания снимает настройку стекла.")

/// Удаление знания строительства разбирает узлы, а утрата метки снимает статус с чужого тела.
/datum/unit_test/heretic_glass_knowledge_removal/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass.shards(user, get_step(user, EAST))
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	var/obj/structure/heretic_glass_barrier/barrier = glass.create_barrier(user, get_step(user, NORTH))
	TEST_ASSERT_NOTNULL(barrier, "Знание призм поднимает и преграду.")
	var/datum/eldritch_knowledge/shards = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	qdel(shards)
	TEST_ASSERT(QDELETED(prism), "Удаление строительства удаляет существующие призмы.")
	TEST_ASSERT(QDELETED(barrier), "Удаление строительства разбирает и преграды.")
	glass.combat_resource = 2
	TEST_ASSERT(!glass.shards(user, get_step(user, EAST)), "Удалённое знание не создаёт новый узел.")
	TEST_ASSERT_NULL(glass.create_barrier(user, get_step(user, NORTH)), "Удалённое знание не поднимает преграду.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.apply_status_effect(/datum/status_effect/eldritch/glass, glass)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/glass), "Перед удалением знания метка существует.")
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/glass_mark))
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/glass), "Удаление знания снимает метку.")

/// Вознесённый витраж делает три отдельных снимка и целиком прекращается при разрушении исходного узла.
/datum/unit_test/heretic_glass_ascension/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/final_eldritch/glass_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	TEST_ASSERT(!glass.crown(user), "Незавершённое вознесение не открывает витраж.")
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_EQUAL(glass.combat_resource_max, 8, "Вознесение расширяет строительный запас до восьми.")
	user.setDir(EAST)
	glass.shards(user, get_step(user, EAST))
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	var/mob/living/east_victim = allocate(/mob/living/carbon/human, get_step(prism, EAST))
	var/mob/living/north_victim = allocate(/mob/living/carbon/human, get_step(prism, NORTH))
	TEST_ASSERT(glass.crown(user), "Живая сеть запускает витраж.")
	var/datum/heretic_glass_network/network = glass.active_network
	TEST_ASSERT_EQUAL(network.pulses, 1, "Запуск подготавливает только первую волну.")
	var/datum/heretic_glass_attack/first = glass.attacks[1]
	first.resolve()
	TEST_ASSERT(abs(east_victim.getBruteLoss() - 50) < 0.01, "Первая волна следует первоначальному направлению.")
	TEST_ASSERT(abs(north_victim.getBruteLoss() - 44) < 0.01, "Диагональный луч первой волны действует без призмы.")
	var/north_damage_before = north_victim.getBruteLoss()
	prism.setDir(NORTH)
	user.forceMove(get_step(user, SOUTH))
	TEST_ASSERT(!QDELETED(network), "После первой подготовки можно перемещаться.")
	TEST_ASSERT(network.pulse(), "Следующая волна строит новый снимок.")
	var/datum/heretic_glass_attack/second = glass.attacks[1]
	TEST_ASSERT_EQUAL(north_victim.getBruteLoss(), north_damage_before, "Новая геометрия сначала предупреждает, затем бьёт.")
	second.resolve()
	TEST_ASSERT(abs(north_victim.getBruteLoss() - north_damage_before - 50) < 0.01, "Вторая волна использует новое направление узла.")
	TEST_ASSERT(abs(east_victim.getBruteLoss() - 50) < 0.01, "Вторая волна не повторяет исчезнувшую линию.")
	TEST_ASSERT(network.pulse(), "Третья волна доступна.")
	var/datum/heretic_glass_attack/third = glass.attacks[1]
	TEST_ASSERT(!network.pulse(), "Четвёртая волна запрещена.")
	qdel(prism)
	TEST_ASSERT(!QDELETED(network), "Разрушение исходного узла сохраняет остальные лучи витража.")
	TEST_ASSERT(!QDELETED(third), "Подготовленная волна сохраняется до проверки отдельных маршрутов.")
	var/mob/living/radial_victim = allocate(/mob/living/carbon/human, get_step(user, WEST))
	var/north_before_third = north_victim.getBruteLoss()
	third.resolve()
	TEST_ASSERT_EQUAL(north_victim.getBruteLoss(), north_before_third, "Ветка разрушенной призмы больше не наносит урон.")
	TEST_ASSERT(abs(radial_victim.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Независимый луч подготовленной волны всё равно наносит урон.")
	qdel(network)
	TEST_ASSERT_NULL(glass.active_network, "Завершённый витраж освобождает ссылку владельца.")
	glass.combat_resource = 2
	var/turf/root_place = get_step(get_step(user, EAST), EAST)
	var/turf/relay_place = get_step(get_step(root_place, NORTH), NORTH)
	user.setDir(EAST)
	TEST_ASSERT(glass.shards(user, relay_place), "Промежуточный узел можно поставить до закрытия прямой видимости.")
	var/obj/structure/heretic_glass_prism/relay = glass.prisms[1]
	user.setDir(NORTH)
	TEST_ASSERT(glass.shards(user, root_place), "Исходная призма направляет луч к промежуточной.")
	var/obj/corner = allocate(/obj, get_step(user, NORTHEAST))
	corner.density = TRUE
	TEST_ASSERT(!glass.line_clear(user, relay, allow_prisms = TRUE), "Промежуточная призма скрыта от владельца за углом.")
	TEST_ASSERT(glass.crown(user), "Витраж включает промежуточный узел через преломление.")
	network = glass.active_network
	var/datum/heretic_glass_attack/relayed_attack = glass.attacks[1]
	qdel(relay)
	TEST_ASSERT(!QDELETED(network), "Разрушение промежуточного узла сохраняет сеть.")
	TEST_ASSERT(!QDELETED(relayed_attack), "Независимые маршруты подготовленной волны остаются активными.")
	final_knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(network) && QDELETED(relayed_attack), "Потеря знания по-прежнему полностью обрывает витраж.")
	TEST_ASSERT(!glass.ascension_active, "Потеря тела снимает усиление сети.")
	TEST_ASSERT_EQUAL(glass.combat_resource_max, 4, "Без вознесения возвращается базовая вместимость.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOBREATH), "Черты вознесения сняты.")

/// Две обращённые друг к другу призмы не зацикливают трассировку и не удваивают урон.
/datum/unit_test/heretic_glass_prism_loop/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/near_place = get_step(get_step(user, EAST), EAST)
	var/turf/far_place = get_step(get_step(near_place, EAST), EAST)
	user.setDir(WEST)
	TEST_ASSERT(glass.shards(user, far_place), "Дальняя призма устанавливается первой.")
	user.setDir(EAST)
	TEST_ASSERT(glass.shards(user, near_place), "Ближняя призма смотрит на дальнюю.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(near_place, EAST))
	var/list/cells = glass.trace_ray(get_turf(user), EAST)
	TEST_ASSERT(length(cells) <= 12, "Циклическая геометрия укладывается в конечный бюджет.")
	TEST_ASSERT(glass.release(user, near_place), "В циклическую сеть можно направить луч.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) < 0.01, "Проходы луча в обе стороны наносят один урон.")
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	prism.take_damage(100, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(prism), "Обычный урон разбирает оптическую установку.")
	TEST_ASSERT_EQUAL(length(glass.prisms), 1, "Разрушение освобождает место для нового узла.")

/// Разветвлённая трасса достигает общего бюджета до и после вознесения.
/datum/unit_test/heretic_glass_ray_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/turf_reservation/arena = SSmapping.RequestBlockReservation(19, 19, turf_type_override = /turf/open/floor/plating, border_type_override = /turf/closed/wall)
	TEST_ASSERT_NOTNULL(arena, "Выделена площадка для длинной разветвлённой трассы.")
	allocated += arena
	var/turf/start = locate(arena.bottom_left_coords[1] + 8, arena.bottom_left_coords[2] + 5, arena.bottom_left_coords[3])
	var/turf/bend = locate(start.x + 3, start.y + 3, start.z)
	var/obj/structure/heretic_glass_prism/root = allocate(/obj/structure/heretic_glass_prism, start, glass)
	var/obj/structure/heretic_glass_prism/branch = allocate(/obj/structure/heretic_glass_prism, bend, glass)
	root.setDir(NORTH)
	root.toggle_split()
	branch.setDir(NORTH)
	branch.toggle_split()
	var/list/cells = glass.trace_ray(start, NORTH, root)
	TEST_ASSERT_EQUAL(length(cells), 11, "Бюджет 12 включает одну клетку преломляющей призмы.")
	glass.ascension_active = TRUE
	cells = glass.trace_ray(start, NORTH, root)
	TEST_ASSERT_EQUAL(length(cells), 17, "Вознесённый бюджет 18 продолжает ту же трассу ещё на шесть клеток.")
	qdel(root)
	qdel(branch)

/datum/unit_test/heretic_glass_hand_interaction/proc/block_hand(datum/source)
	SIGNAL_HANDLER
	return COMPONENT_NO_ATTACK_HAND

/// Касание рукой своей призмы и преграды соблюдает общий запрет взаимодействия.
/datum/unit_test/heretic_glass_hand_interaction/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/heretic_glass_prism/prism = allocate(/obj/structure/heretic_glass_prism, get_step(user, EAST), glass)
	RegisterSignal(prism, COMSIG_ATOM_ATTACK_HAND, PROC_REF(block_hand))
	prism.attack_hand(user)
	TEST_ASSERT(!prism.split, "Запрет общего обработчика не позволяет переключить призму.")
	UnregisterSignal(prism, COMSIG_ATOM_ATTACK_HAND)
	prism.attack_hand(user)
	TEST_ASSERT(prism.split, "Без запрета владелец переключает призму рукой.")
	var/obj/structure/heretic_glass_barrier/barrier = allocate(/obj/structure/heretic_glass_barrier, get_step(user, NORTH), glass)
	RegisterSignal(barrier, COMSIG_ATOM_ATTACK_HAND, PROC_REF(block_hand))
	barrier.attack_hand(user)
	TEST_ASSERT(!QDELETED(barrier), "Запрет общего обработчика сохраняет барьер.")
	UnregisterSignal(barrier, COMSIG_ATOM_ATTACK_HAND)
	barrier.attack_hand(user)
	TEST_ASSERT(QDELETED(barrier), "Без запрета владелец убирает барьер рукой.")

/// Луч достигает указанной клетки вне восьми направлений и сохраняет предупреждённую трассу.
/datum/unit_test/heretic_glass_exact_aim/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/destination = locate(user.x + 3, user.y + 1, user.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	var/mob/living/outside = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 3, user.z))
	var/mob/living/behind = allocate(/mob/living/carbon/human, locate(user.x + 4, user.y + 1, user.z))
	var/mob/living/bent = allocate(/mob/living/carbon/human, locate(user.x + 4, user.y + 2, user.z))
	var/mob/living/endpoint = allocate(/mob/living/carbon/human, locate(user.x + 5, user.y + 2, user.z))
	TEST_ASSERT(glass.release(user, victim), "Можно прицелиться между сторонами света.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "До окончания предупреждения урона нет.")
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) < 0.01, "Указанная клетка получает полный урон.")
	TEST_ASSERT_EQUAL(outside.getBruteLoss(), 0, "Прежняя диагональ не подменяет указанную линию.")
	TEST_ASSERT(abs(behind.getBruteLoss() - 30) < 0.01, "За близкой целью луч сохраняет исходный наклон.")
	TEST_ASSERT_EQUAL(bent.getBruteLoss(), 0, "Луч не поворачивает по диагонали после выбранной клетки.")
	TEST_ASSERT(abs(endpoint.getBruteLoss() - 30) < 0.01, "Исходный наклон сохраняется до предела дальности.")

/// Призма за выбранной клеткой перехватывает продолжение прицельного луча и поворачивает его.
/datum/unit_test/heretic_glass_aimed_refraction/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/aimed = locate(user.x + 3, user.y + 1, user.z)
	var/turf/prism_place = locate(user.x + 4, user.y + 1, user.z)
	user.setDir(NORTH)
	TEST_ASSERT(glass.shards(user, prism_place), "На продолжении прицельной линии устанавливается призма.")
	var/mob/living/refracted = allocate(/mob/living/carbon/human, get_step(prism_place, NORTH))
	var/mob/living/straight = allocate(/mob/living/carbon/human, get_step(prism_place, NORTHEAST))
	TEST_ASSERT(glass.release(user, aimed), "Луч направляется в клетку перед призмой.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(refracted.getBruteLoss() - 36) < 0.01, "Призма поворачивает продолжение луча и усиливает урон.")
	TEST_ASSERT_EQUAL(straight.getBruteLoss(), 0, "После призмы первоначальная линия не продолжается.")

/// Массовый свет работает без построек, сохраняет безопасные промежутки и не поражает союзников.
/datum/unit_test/heretic_glass_mobile_storm/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y, user.z))
	var/mob/living/outside = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 1, user.z))
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	glass.combat_resource = 0
	TEST_ASSERT(glass.storm(user), "Пустой запас и отсутствие призм не мешают свету.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	user.forceMove(get_step(user, WEST))
	TEST_ASSERT(!QDELETED(attack), "Перемещение сохраняет подготовленный залп.")
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 40) < 0.01, "Массовый свет наносит полный урон без сети.")
	TEST_ASSERT_EQUAL(outside.getBruteLoss(), 0, "Между предупреждёнными лучами остаётся укрытие.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Свет не поражает другого еретика.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Свет не поражает создателя после перемещения.")

/// Дальняя установка проходит через свои призмы, но соблюдает занятость пола и перезарядку ресурса.
/datum/unit_test/heretic_glass_remote_placement/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/spell/glass_shards/placement = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/spell = placement.granted_spell
	var/turf/near_place = get_step(user, EAST)
	var/turf/far_place = locate(user.x + 5, user.y, user.z)
	TEST_ASSERT(glass.shards(user, near_place), "Ближняя призма устанавливается первой.")
	TEST_ASSERT(spell.can_target(far_place, user, TRUE), "Своё стекло не закрывает выбор свободного пола в пяти клетках.")
	spell.cast(list(far_place), user)
	TEST_ASSERT_EQUAL(length(glass.prisms), 2, "Настоящий cast устанавливает дальнюю призму.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 0, "Обе установки оплачены.")
	glass.gain_combat_resource()
	TEST_ASSERT(!glass.valid_prism_turf(user, near_place), "Нельзя сложить две призмы на одной клетке.")
	var/obj/blocker = allocate(/obj, get_step(near_place, EAST))
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(locate(user.x + 4, user.y, user.z), user, TRUE), "Обычная плотная преграда блокирует дальнюю установку.")
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	prism.take_damage(50, BRUTE, MELEE)
	TEST_ASSERT(!QDELETED(prism), "Призма выдерживает 50 урона.")
	prism.take_damage(25, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(prism), "75 урона разбивают призму и освобождают место.")
	COOLDOWN_RESET(glass, facet_regeneration)
	glass.on_life(user)
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(glass, facet_regeneration) - 4 SECONDS) <= world.tick_lag, "Обычная грань восстанавливается за четыре секунды.")
	glass.ascension_active = TRUE
	COOLDOWN_RESET(glass, facet_regeneration)
	glass.on_life(user)
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(glass, facet_regeneration) - 2 SECONDS) <= world.tick_lag, "Вознесение сокращает восстановление до двух секунд.")

/// Все связанные призмы целятся в выбранную клетку, а пересечения соблюдают антимагию и один удар.
/datum/unit_test/heretic_glass_aimed_volley/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	user.setDir(WEST)
	TEST_ASSERT(glass.shards(user, locate(user.x, user.y + 2, user.z)), "Первая призма стоит в стороне от прямого луча.")
	TEST_ASSERT(glass.shards(user, locate(user.x + 1, user.y + 4, user.z)), "Вторая призма тоже смотрит в сторону от цели.")
	var/turf/destination = locate(user.x + 4, user.y + 2, user.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	var/mob/living/protected = allocate(/mob/living/carbon/human, destination)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/antagonist/heretic/ally = allocate_heretic(destination)
	var/mob/living/first_lane = allocate(/mob/living/carbon/human, locate(user.x + 1, user.y + 2, user.z))
	var/mob/living/second_lane = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 3, user.z))
	TEST_ASSERT(glass.release(user, victim), "Выбор цели запускает всю сеть без ручного поворота.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Общий залп сначала показывает предупреждение.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_glass/warning) in get_turf(first_lane), "Первая боковая линия предупреждена.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/heretic_glass/warning) in get_turf(second_lane), "Вторая боковая линия тоже предупреждена.")
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Три пересекающихся луча наносят один усиленный удар.")
	TEST_ASSERT(abs(first_lane.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Первая призма действительно стреляет в цель.")
	TEST_ASSERT(abs(second_lane.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Вторая призма тоже стреляет в цель.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует общий залп.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Вся сеть расходует один заряд защиты на цель.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Пересечение не поражает союзника.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 0, "Пустой запас граней не мешает залпу.")
	for(var/obj/structure/heretic_glass_prism/prism as anything in glass.prisms)
		TEST_ASSERT_EQUAL(prism.dir, WEST, "Прицельный залп сохраняет ручную настройку стрелки.")

/// Выстрел в одну призму включает соседнюю за углом и отменяет только разорванную ветвь.
/datum/unit_test/heretic_glass_relay_breaks/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	user.setDir(EAST)
	TEST_ASSERT(glass.shards(user, locate(user.x + 2, user.y, user.z)), "Входная призма стоит перед владельцем.")
	TEST_ASSERT(glass.shards(user, locate(user.x + 2, user.y + 3, user.z)), "Вторая призма не стоит на выходящем луче первой.")
	var/obj/structure/heretic_glass_prism/root = glass.prisms[1]
	var/obj/structure/heretic_glass_prism/relay = glass.prisms[2]
	var/obj/corner = allocate(/obj, get_step(user, NORTHEAST))
	corner.density = TRUE
	TEST_ASSERT(!glass.line_clear(user, relay, allow_prisms = TRUE), "Стена закрывает вторую призму от владельца.")
	var/mob/living/near_victim = allocate(/mob/living/carbon/human, get_step(root, EAST))
	var/mob/living/far_victim = allocate(/mob/living/carbon/human, get_step(relay, EAST))
	TEST_ASSERT(glass.release(user, root), "Выстрел в входную призму запускает сеть.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(near_victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Входная призма стреляет по своей стрелке.")
	TEST_ASSERT(abs(far_victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Скрытая призма тоже стреляет, не требуя направлять на неё первый луч.")
	TEST_ASSERT(glass.release(user, root), "Повторный залп создаёт новый снимок сети.")
	attack = glass.attacks[1]
	var/obj/blocker = allocate(/obj, get_step(root, NORTH))
	blocker.density = TRUE
	attack.resolve()
	TEST_ASSERT(abs(near_victim.getBruteLoss() - 72) <= DAMAGE_PRECISION, "Независимый луч остаётся рабочим.")
	TEST_ASSERT(abs(far_victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Новая стена между призмами обрывает уже подготовленную передачу.")
	qdel(blocker)
	TEST_ASSERT(glass.release(user, root), "После удаления стены связь восстанавливается.")
	attack = glass.attacks[1]
	qdel(root)
	attack.resolve()
	TEST_ASSERT(abs(far_victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Разрушение входной призмы отменяет зависимый залп.")

/// Прицельная сеть сохраняет отмеченные клетки и теряет только луч разрушенного узла.
/datum/unit_test/heretic_glass_volley_snapshot/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	TEST_ASSERT(glass.shards(user, locate(user.x - 1, user.y + 2, user.z)), "Установлена первая призма.")
	TEST_ASSERT(glass.shards(user, locate(user.x + 1, user.y + 4, user.z)), "Установлена вторая призма.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(user.x + 4, user.y + 2, user.z))
	var/mob/living/first_lane = allocate(/mob/living/carbon/human, locate(user.x + 1, user.y + 2, user.z))
	var/mob/living/second_lane = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 3, user.z))
	TEST_ASSERT(glass.release(user, victim), "Подготовлен прицельный залп.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	victim.forceMove(get_step(user, WEST))
	qdel(glass.prisms[1])
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Сеть не доворачивает вслед за убежавшей целью.")
	TEST_ASSERT_EQUAL(first_lane.getBruteLoss(), 0, "Уничтоженная призма не исполняет старое предупреждение.")
	TEST_ASSERT(abs(second_lane.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Независимая призма сохраняет свой залп.")

/// Раздвоенная призма при выстреле в цель бьёт по ней полным лучом, а второй луч отходит на 45°.
/datum/unit_test/heretic_glass_aimed_split/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	user.setDir(WEST)
	TEST_ASSERT(glass.shards(user, locate(user.x, user.y + 2, user.z)), "Призма изначально направлена от цели.")
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	prism.toggle_split()
	var/mob/living/aimed = allocate(/mob/living/carbon/human, locate(user.x + 4, user.y + 2, user.z))
	var/mob/living/upper = allocate(/mob/living/carbon/human, get_step(prism, NORTHEAST))
	var/obj/cover = allocate(/obj, locate(user.x + 1, user.y + 1, user.z))
	cover.density = TRUE
	TEST_ASSERT(glass.release(user, aimed), "Сеть наводится на цель на востоке.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(aimed.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Раздвоенная призма попадает в выбранную цель полным преломлённым лучом.")
	TEST_ASSERT(abs(upper.getBruteLoss() - 30) <= DAMAGE_PRECISION, "Второй луч отходит на 45° с уменьшенным уроном.")
	TEST_ASSERT(prism.split && prism.dir == WEST, "Залп не меняет сохранённые настройки призмы.")

/// Сеть не подключает чужие призмы и не передаёт залп через промежуток больше пяти клеток.
/datum/unit_test/heretic_glass_relay_limits/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/turf_reservation/arena = SSmapping.RequestBlockReservation(19, 19, turf_type_override = /turf/open/floor/plating, border_type_override = /turf/closed/wall)
	TEST_ASSERT_NOTNULL(arena, "Выделена площадка для проверки дальности сети.")
	allocated += arena
	var/turf/start = locate(arena.bottom_left_coords[1] + 4, arena.bottom_left_coords[2] + 4, arena.bottom_left_coords[3])
	user.forceMove(start)
	var/obj/structure/heretic_glass_prism/root = allocate(/obj/structure/heretic_glass_prism, locate(start.x + 2, start.y, start.z), glass)
	var/obj/structure/heretic_glass_prism/relay = allocate(/obj/structure/heretic_glass_prism, locate(start.x + 2, start.y + 4, start.z), glass)
	var/obj/structure/heretic_glass_prism/distant = allocate(/obj/structure/heretic_glass_prism, locate(start.x + 8, start.y + 4, start.z), glass)
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(start, SOUTH))
	other.selected_path = PATH_GLASS
	other.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	other.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/datum/eldritch_knowledge/base_glass/other_glass = other.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/heretic_glass_prism/foreign = allocate(/obj/structure/heretic_glass_prism, locate(start.x + 2, start.y - 3, start.z), other_glass)
	for(var/obj/structure/heretic_glass_prism/prism as anything in list(root, relay, distant, foreign))
		prism.setDir(EAST)
	var/mob/living/connected_victim = allocate(/mob/living/carbon/human, get_step(relay, EAST))
	var/mob/living/distant_victim = allocate(/mob/living/carbon/human, get_step(distant, EAST))
	var/mob/living/foreign_victim = allocate(/mob/living/carbon/human, get_step(foreign, EAST))
	TEST_ASSERT(glass.release(user, root), "Выстрел передаётся по доступной части сети.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	TEST_ASSERT(length(attack.cells) <= 3 * 12, "Каждая доступная призма трассируется один раз в пределах бюджета.")
	attack.resolve()
	TEST_ASSERT(abs(connected_victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Связанный собственный узел стреляет.")
	TEST_ASSERT_EQUAL(distant_victim.getBruteLoss(), 0, "Шестиклеточный разрыв не передаёт залп.")
	TEST_ASSERT_EQUAL(foreign_victim.getBruteLoss(), 0, "Чужой узел не подключается к сети.")

/// Буря и вознесение используют ту же связанную сеть, включая узлы за углом.
/datum/unit_test/heretic_glass_relay_storm_and_crown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	user.setDir(EAST)
	TEST_ASSERT(glass.shards(user, locate(user.x + 2, user.y, user.z)), "Установлен вход в сеть.")
	TEST_ASSERT(glass.shards(user, locate(user.x + 2, user.y + 3, user.z)), "Установлен боковой узел сети.")
	var/obj/structure/heretic_glass_prism/relay = glass.prisms[2]
	var/obj/corner = allocate(/obj, get_step(user, NORTHEAST))
	corner.density = TRUE
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(relay, EAST))
	TEST_ASSERT(!glass.line_clear(user, relay, allow_prisms = TRUE), "Прямая видимость бокового узла закрыта.")
	TEST_ASSERT(glass.storm(user), "Буря выпускает залп сети.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 46) <= DAMAGE_PRECISION, "Боковой узел наносит усиленный урон бури за углом.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	var/datum/eldritch_knowledge/final_eldritch/glass_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT(glass.crown(user), "Вознесение включает ту же сеть.")
	attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 96) <= DAMAGE_PRECISION, "Витраж передаёт волну в скрытый узел.")

/datum/unit_test/proc/ascend_glass_fixture()
	var/datum/antagonist/heretic/heretic = allocate_heretic(run_loc_floor_bottom_left)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/glass_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	return list("user" = user, "heretic" = heretic, "finale" = finale, "attacker" = attacker)

/datum/unit_test/proc/glass_test_projectile(mob/living/attacker, projectile_type)
	var/obj/item/projectile/projectile = allocate(projectile_type, get_turf(attacker))
	projectile.damage = 20
	projectile.damage_type = BRUTE
	projectile.firer = attacker
	projectile.starting = get_turf(attacker)
	projectile.setAngle(270)
	return projectile

/// Витраж преломляет лазеры и энергию, но не пули; потеря тела снимает аспект.
/datum/unit_test/heretic_glass_stained_refraction/Run()
	var/list/fixture = ascend_glass_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/final_eldritch/glass_final/finale = fixture["finale"]
	var/datum/component/heretic_glass_stained/aspect = user.GetComponent(/datum/component/heretic_glass_stained)
	TEST_ASSERT_NOTNULL(aspect, "Вознесение Стекла даёт витраж.")
	TEST_ASSERT_EQUAL(aspect.refract_chance, HERETIC_GLASS_REFRACT_CHANCE, "Шанс преломления по умолчанию - 35 процентов.")
	aspect.refract_chance = 100
	var/obj/item/projectile/beam/laser = glass_test_projectile(attacker, /obj/item/projectile/beam/laser)
	TEST_ASSERT_EQUAL(user.bullet_act(laser, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Лазер преломляется и летит дальше.")
	var/turn = SIMPLIFY_DEGREES(laser.Angle - 270)
	TEST_ASSERT(turn >= 120 && turn <= 240, "Преломлённый лазер уходит назад веером, поворот [turn].")
	var/obj/item/projectile/beam/disabler/disabler = glass_test_projectile(attacker, /obj/item/projectile/beam/disabler)
	TEST_ASSERT_EQUAL(user.bullet_act(disabler, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Луч дизаблера тоже преломляется.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Преломлённые лучи не ранят.")
	var/obj/item/projectile/bullet/bullet = glass_test_projectile(attacker, /obj/item/projectile/bullet)
	TEST_ASSERT_NOTEQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Пули витраж не преломляет.")
	TEST_ASSERT(user.getBruteLoss() > 0, "Пуля ранит вознёсшегося.")
	aspect.refract_chance = 0
	var/brute_before = user.getBruteLoss()
	TEST_ASSERT_NOTEQUAL(user.bullet_act(glass_test_projectile(attacker, /obj/item/projectile/beam/laser), BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Без удачного броска лазер не преломляется.")
	TEST_ASSERT(user.getBruteLoss() > brute_before, "Не преломлённый лазер ранит.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_glass_stained), "Потеря тела снимает витраж.")

/// Удар предметом по вознёсшемуся Стеклу наносит на четверть больше ушибов, союзники бьют без надбавки.
/datum/unit_test/heretic_glass_stained_fragility/Run()
	var/list/fixture = ascend_glass_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/attacker = fixture["attacker"]
	attacker.forceMove(get_step(user, EAST))
	var/obj/item/weapon = allocate(/obj/item)
	weapon.force = 20
	weapon.damtype = BRUTE
	TEST_ASSERT(abs(user.check_weakness(weapon, attacker) - (1 + HERETIC_GLASS_MELEE_FRAGILITY)) < DAMAGE_PRECISION, "Вознёсшееся Стекло хрупко к ударам предметами.")
	var/obj/item/burn_weapon = allocate(/obj/item)
	burn_weapon.damtype = BURN
	TEST_ASSERT_EQUAL(user.check_weakness(burn_weapon, attacker), 1, "Хрупкость касается только ушибов.")
	var/datum/antagonist/heretic/ally_heretic = allocate_heretic(get_step(user, NORTH))
	var/mob/living/ally = ally_heretic.owner.current
	TEST_ASSERT_EQUAL(user.check_weakness(weapon, ally), 1, "Союзный еретик бьёт без надбавки.")
	var/datum/component/heretic_glass_stained/aspect = user.GetComponent(/datum/component/heretic_glass_stained)
	aspect.refract_chance = 0
	user.attacked_by(weapon, attacker)
	var/expected = weapon.force * (1 + HERETIC_GLASS_MELEE_FRAGILITY) * HERETIC_ASCENDED_DAMAGE_MOD
	TEST_ASSERT(abs(user.getBruteLoss() - expected) < 1, "Удар предметом наносит на четверть больше урона: ожидалось [expected], получено [user.getBruteLoss()].")
	var/datum/eldritch_knowledge/final_eldritch/glass_final/finale = fixture["finale"]
	finale.on_body_lose(user)
	TEST_ASSERT_EQUAL(user.check_weakness(weapon, attacker), 1, "Без вознесения хрупкость пропадает.")

/// Преломление вспыхивает гранью на стороне нового курса и чертит отражённый луч, урона нет.
/datum/unit_test/heretic_glass_refraction_visuals/Run()
	var/list/fixture = ascend_glass_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/component/heretic_glass_stained/aspect = user.GetComponent(/datum/component/heretic_glass_stained)
	aspect.refract_chance = 100
	var/turf/place = get_turf(user)
	var/list/before = list_vfx_bursts(place)
	var/obj/item/projectile/beam/laser = glass_test_projectile(attacker, /obj/item/projectile/beam/laser)
	TEST_ASSERT_EQUAL(user.bullet_act(laser, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Лазер преломляется.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Преломлённый луч по-прежнему не ранит.")
	var/obj/effect/temp_visual/heretic_glass/facet/facet = locate() in place
	TEST_ASSERT_NOTNULL(facet, "В точке преломления вспыхивает грань.")
	TEST_ASSERT(facet.pixel_x * sin(laser.Angle) > 0, "Грань вспыхивает на стороне, куда ушёл луч.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_path_feedback) in place, "Старая плоская вспышка заменена гранью.")
	var/obj/effect/temp_visual/heretic_glass/beam/trace = locate() in place
	TEST_ASSERT_NOTNULL(trace, "Отражённый луч оставляет след.")
	TEST_ASSERT(abs(trace.angle - laser.Angle) < 1, "След идёт по новому курсу луча.")
	TEST_ASSERT(trace.mouse_opacity == MOUSE_OPACITY_TRANSPARENT && facet.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Вспышки не мешают кликам.")
	var/obj/effect/temp_visual/heretic_vfx/burst/shards = find_vfx_burst(place, /particles/heretic_ascension/glass, before)
	TEST_ASSERT_NOTNULL(shards, "Грань осыпается осколками.")
	TEST_ASSERT(wait_for_qdeleted(facet), "Грань гаснет.")
	TEST_ASSERT(wait_for_qdeleted(trace), "След луча тает.")
	TEST_ASSERT(wait_for_qdeleted(shards), "Осколки оседают.")

/// Удар оружием по витражу проступает трещинами и сыплет осколками, урон прежний.
/datum/unit_test/heretic_glass_fragility_visuals/Run()
	var/list/fixture = ascend_glass_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/attacker = fixture["attacker"]
	attacker.forceMove(get_step(user, EAST))
	var/datum/component/heretic_glass_stained/aspect = user.GetComponent(/datum/component/heretic_glass_stained)
	aspect.refract_chance = 0
	var/obj/item/weapon = allocate(/obj/item)
	weapon.force = 20
	weapon.damtype = BRUTE
	var/turf/place = get_turf(user)
	var/list/before = list_vfx_bursts(place)
	user.check_weakness(weapon, attacker)
	TEST_ASSERT_NULL(locate(/obj/effect/abstract/heretic_vfx_attached) in user.vis_contents, "Без нанесённого урона трещин нет.")
	user.attacked_by(weapon, attacker)
	var/expected = weapon.force * (1 + HERETIC_GLASS_MELEE_FRAGILITY) * HERETIC_ASCENDED_DAMAGE_MOD
	TEST_ASSERT(abs(user.getBruteLoss() - expected) < 1, "Урон удара прежний: ожидалось [expected], получено [user.getBruteLoss()].")
	var/obj/effect/abstract/heretic_vfx_attached/cracks = locate() in user.vis_contents
	TEST_ASSERT_NOTNULL(cracks, "На витраже проступают трещины.")
	TEST_ASSERT_EQUAL(cracks.icon_state, "glass_crack", "Трещины рисуются своим стейтом.")
	TEST_ASSERT(!(cracks.appearance_flags & (RESET_TRANSFORM | RESET_ALPHA)), "Трещины лежат на теле: ложатся и прячутся вместе с ним.")
	TEST_ASSERT(cracks.fading, "Трещины сразу начинают гаснуть.")
	var/obj/effect/temp_visual/heretic_vfx/burst/shards = find_vfx_burst(place, /particles/heretic_ascension/glass, before)
	TEST_ASSERT_NOTNULL(shards, "От удара летят осколки.")
	TEST_ASSERT(shards.pixel_x < 0, "Осколки летят дальше по ходу удара, прочь от бьющего.")
	TEST_ASSERT(wait_for_qdeleted(cracks), "Трещины гаснут.")
	TEST_ASSERT(!(cracks in user.vis_contents), "Погасшие трещины снимаются с тела.")
	TEST_ASSERT(wait_for_qdeleted(shards), "Осколки оседают.")

/// Вечный витраж: лучи проступают линиями до залпа; в миг удара живые линии вспыхивают, а перекрытые и лучи разбитой призмы гаснут; урон прежний.
/datum/unit_test/heretic_glass_crown_visuals/Run()
	var/list/fixture = ascend_glass_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/victim = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/turf/center = get_turf(user)
	var/turf/prism_place = locate(center.x, center.y + 2, center.z)
	user.setDir(EAST)
	TEST_ASSERT(glass.shards(user, prism_place), "Призма встаёт в двух клетках к северу.")
	var/obj/structure/heretic_glass_prism/prism = locate() in prism_place
	TEST_ASSERT(glass.crown(user), "Витраж запускается.")
	var/datum/heretic_glass_attack/volley = glass.attacks[1]
	var/obj/effect/temp_visual/heretic_glass/beam/east_beam
	var/obj/effect/temp_visual/heretic_glass/beam/diagonal_beam
	var/list/prism_beams = list()
	for(var/obj/effect/temp_visual/heretic_glass/beam/beam as anything in volley.beams)
		TEST_ASSERT(beam in glass.visuals, "Линии луча числятся за путём и убираются с ним.")
		if(beam.start_node || beam.end_node)
			prism_beams += beam
			continue
		TEST_ASSERT_EQUAL(beam.loc, center, "Луч без призм выходит из героя.")
		var/turf/end = beam.end_tile
		if(end.y == center.y && end.x > center.x)
			east_beam = beam
		else if(end.x > center.x && end.x - center.x == end.y - center.y)
			diagonal_beam = beam
	TEST_ASSERT_NOTNULL(east_beam, "Луч на восток виден до залпа.")
	TEST_ASSERT_NOTNULL(diagonal_beam, "Диагональный луч виден до залпа.")
	TEST_ASSERT(length(prism_beams) >= 2, "Путь через призму проступает отрезками до неё и от неё.")
	TEST_ASSERT(!east_beam.fired && !east_beam.fizzled, "До залпа линия только копит свет.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/gather) in center, "Свет стягивается к герою перед залпом.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "До залпа луч не ранит.")
	var/obj/blocker = allocate(/obj, locate(center.x + 1, center.y + 1, center.z))
	blocker.density = TRUE
	qdel(prism)
	var/turf/victim_place = get_turf(victim)
	var/list/before = list_vfx_bursts(victim_place)
	volley.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Залп наносит прежние 44 урона, получено [victim.getBruteLoss()].")
	TEST_ASSERT(east_beam.fired && !east_beam.fizzled, "Живая линия вспыхивает в миг удара.")
	TEST_ASSERT(diagonal_beam.fizzled && !diagonal_beam.fired, "Перекрытая линия гаснет, не вспыхнув.")
	for(var/obj/effect/temp_visual/heretic_glass/beam/beam as anything in prism_beams)
		TEST_ASSERT(beam.fizzled && !beam.fired, "Линия разбитой призмы гаснет, не вспыхнув.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(victim_place, /particles/heretic_ascension/glass, before), "Цель осыпают осколки.")
	TEST_ASSERT(wait_for_qdeleted(east_beam), "Вспыхнувшая линия гаснет.")
	var/datum/heretic_glass_network/network = glass.active_network
	TEST_ASSERT(network.pulse(), "Вторая волна готовится.")
	var/datum/heretic_glass_attack/second = glass.attacks[1]
	var/obj/effect/temp_visual/heretic_glass/beam/doomed = second.beams[1]
	qdel(network)
	TEST_ASSERT(QDELETED(second), "Оборванный витраж снимает подготовленную волну.")
	TEST_ASSERT(doomed.fizzled && !doomed.fired, "Линия оборванной волны гаснет, не вспыхнув.")
	TEST_ASSERT(wait_for_qdeleted(doomed), "Линия оборванной волны исчезает.")

/datum/unit_test/heretic_glass_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_glass/facet, /obj/effect/temp_visual/heretic_glass/beam, /obj/effect/temp_visual/heretic_vfx/gather))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/// Хватка настраивает окно и зеркало без урона, считает дело, держит шесть стёкол и отдаёт настройку жезлу.
/datum/unit_test/heretic_glass_attune/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_GLASS)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(user, EAST))
	TEST_ASSERT(glass.on_mansus_grasp(window, user, TRUE), "Хватка настраивает окно.")
	TEST_ASSERT_EQUAL(window.obj_integrity, window.max_integrity, "Настройка не повреждает стекло.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(window, "glass_pane"), "Окно несёт ремесло Стекла.")
	TEST_ASSERT_EQUAL(length(glass.attuned_panes), 1, "Окно попало в список настроенных.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Настройка продвигает дело.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/heretic_trace) in get_turf(user), "След дела лежит на клетке еретика.")
	TEST_ASSERT_NULL(locate(/obj/effect/decal/cleanable/heretic_trace) in get_turf(window), "Под полноклеточным окном след не прячется.")
	TEST_ASSERT(findtext(jointext(window.examine(crew), " "), "не эта комната"), "Экипаж видит улику при осмотре.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!glass.on_mansus_grasp(window, user, TRUE), "Настроенное стекло не настраивается повторно.")
	TEST_ASSERT(findtext(glass.grasp_failure_reason, "уже настроено"), "Отказ объясняет повтор.")
	TEST_ASSERT(COOLDOWN_FINISHED(heretic.deed, progress_cooldown), "Отказ не тратит перезарядку дела.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Повтор не продвигает дело.")
	var/list/panes = list(window)
	for(var/index in 2 to HERETIC_GLASS_ATTUNE_LIMIT)
		var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, get_step(user, NORTHEAST))
		TEST_ASSERT(glass.attune(mirror, user), "Зеркало [index] настраивается.")
		panes += mirror
	TEST_ASSERT_EQUAL(length(glass.attuned_panes), HERETIC_GLASS_ATTUNE_LIMIT, "Все стёкла до предела настроены.")
	var/obj/structure/mirror/extra = allocate(/obj/structure/mirror, get_step(user, NORTHEAST))
	TEST_ASSERT(glass.attune(extra, user), "Стекло сверх предела настраивается.")
	TEST_ASSERT_EQUAL(length(glass.attuned_panes), HERETIC_GLASS_ATTUNE_LIMIT, "Предел настроенных стёкол соблюдается.")
	TEST_ASSERT_NULL(heretic_craft_on(window, "glass_pane"), "Старейшее стекло вытеснено.")
	TEST_ASSERT_EQUAL(glass.attuned_panes[1], panes[2], "Старейшим становится следующее стекло.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	var/obj/structure/mirror/rodded = panes[2]
	rod.melee_attack_chain(crew, rodded)
	TEST_ASSERT_NULL(heretic_craft_on(rodded, "glass_pane"), "Нулевой жезл снимает настройку с зеркала.")
	TEST_ASSERT(!(rodded in glass.attuned_panes), "Снятое зеркало уходит из списка.")
	TEST_ASSERT(glass.attune(window, user), "Вытесненное окно можно настроить заново.")
	rod.melee_attack_chain(crew, window)
	TEST_ASSERT_NULL(heretic_craft_on(window, "glass_pane"), "Нулевой жезл снимает настройку с окна.")
	TEST_ASSERT(!(window in glass.attuned_panes), "Снятое окно уходит из списка.")
	TEST_ASSERT_EQUAL(window.obj_integrity, window.max_integrity, "Жезл снимает настройку, не ударяя окно.")
	var/list/remaining = glass.attuned_panes.Copy()
	TEST_ASSERT(length(remaining), "Перед удалением знания остаются настроенные стёкла.")
	qdel(glass)
	for(var/atom/pane as anything in remaining)
		TEST_ASSERT_NULL(heretic_craft_on(pane, "glass_pane"), "Удаление знания снимает настройку со всех стёкол.")

/// Вечный витраж, как до переработки, бьёт треснувшую цель на 14 сильнее и не ослепляет её.
/datum/unit_test/heretic_glass_eternal_fracture/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/final_eldritch/glass_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/glass_final)
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	var/mob/living/carbon/human/cracked = allocate(/mob/living/carbon/human, get_step(user, WEST))
	var/mob/living/carbon/human/plain = allocate(/mob/living/carbon/human, get_step(user, SOUTH))
	TEST_ASSERT_NOTNULL(glass.fracture(cracked), "Цель треснула.")
	TEST_ASSERT(glass.crown(user), "Вечный витраж запускается.")
	var/datum/heretic_glass_attack/wave = glass.attacks[1]
	wave.resolve()
	TEST_ASSERT(abs(plain.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Волна бьёт на 44: [plain.getBruteLoss()].")
	TEST_ASSERT(abs(cracked.getBruteLoss() - 44 - HERETIC_GLASS_ETERNAL_FRACTURE_BONUS) <= DAMAGE_PRECISION, "По трещинам волна бьёт на 14 сильнее: [cracked.getBruteLoss()].")
	TEST_ASSERT(!cracked.is_blind() && !glass_blind_timer(glass, cracked), "Волна витража треснувшую цель не ослепляет.")
	qdel(glass.active_network)

/// Луч по треснувшей цели ослепляет её, не добавляя урона.
/datum/unit_test/heretic_glass_fracture_blinds/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_grasp)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/glass_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/glass_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка оставляет трещины.")
	TEST_ASSERT(glass.release(user, victim), "Луч выпускается в треснувшую цель.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) < 0.01, "Трещины не добавляют урона: [victim.getBruteLoss()].")
	TEST_ASSERT(victim.is_blind(), "Луч ослепляет треснувшую цель.")
	var/datum/timedevent/cure = glass_blind_timer(glass, victim)
	TEST_ASSERT_NOTNULL(cure, "Слепоту снимает свой таймер.")
	TEST_ASSERT(abs(cure.timeToRun - world.time - (HERETIC_GLASS_FRACTURE_BLIND)) < 0.1, "Луч по трещинам ослепляет ровно на две секунды. Осталось: [cure.timeToRun - world.time] дс.")
	TEST_ASSERT(abs(bystander.getBruteLoss() - 30) < 0.01, "Луч проходит дальше по линии.")
	TEST_ASSERT(!bystander.is_blind(), "Цель без трещин не ослеплена.")
	var/cure_at = cure.timeToRun
	glass.blind(victim, 1 SECONDS)
	cure = glass_blind_timer(glass, victim)
	TEST_ASSERT_NOTNULL(cure, "После короткой вспышки слепоту всё так же снимает таймер.")
	TEST_ASSERT(abs(cure.timeToRun - cure_at) < 0.1, "Короткая вспышка не сокращает идущую слепоту. Осталось: [cure.timeToRun - world.time] дс.")
	expire_glass_blind(glass, victim)
	TEST_ASSERT(!victim.is_blind(), "По истечении срока цель снова видит.")

/// Призма в намерении «Разоружить» ставит преграду, а касание рукой переключает раздвоение.
/datum/unit_test/heretic_glass_prism_barrier_mode/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/spell/glass_shards/placement = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/spell = placement.granted_spell
	var/turf/east = get_step(user, EAST)
	var/turf/north = get_step(user, NORTH)
	user.a_intent = INTENT_DISARM
	TEST_ASSERT(spell.can_target(east, user, TRUE), "Разоружение выбирает свободный пол для преграды.")
	spell.cast(list(east), user)
	TEST_ASSERT_NOTNULL(locate(/obj/structure/heretic_glass_barrier) in east, "Разоружение поднимает преграду.")
	TEST_ASSERT_EQUAL(length(glass.prisms), 0, "Вместо преграды призма не ставится.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 1, "Преграда стоит одну грань.")
	TEST_ASSERT(!spell.can_target(north, user, TRUE), "Вторая преграда ждёт своей перезарядки.")
	user.a_intent = INTENT_HELP
	TEST_ASSERT(spell.can_target(north, user, TRUE), "Без разоружения тот же пол принимает призму.")
	spell.cast(list(north), user)
	var/obj/structure/heretic_glass_prism/prism = locate() in north
	TEST_ASSERT_NOTNULL(prism, "Без разоружения ставится призма.")
	user.setDir(EAST)
	prism.setDir(NORTH)
	prism.attack_hand(user)
	TEST_ASSERT(prism.split, "Касание рукой раздваивает луч призмы.")
	TEST_ASSERT_EQUAL(prism.dir, NORTH, "Касание рукой не поворачивает стрелку ни к еретику, ни по его взгляду.")
	prism.attack_hand(user)
	TEST_ASSERT(!prism.split, "Повторное касание возвращает один луч.")

/datum/unit_test/heretic_glass_casket
	var/obj/item/touched_with

/datum/unit_test/heretic_glass_casket/proc/record_touch(datum/source, obj/item/item, mob/user)
	SIGNAL_HANDLER
	touched_with = item
	return COMPONENT_NO_AFTERATTACK

/datum/unit_test/heretic_glass_casket/Destroy()
	touched_with = null
	return ..()

/// Витраж берёт только поверженную цель, держит её, отражает лазер, ломается от ударов и оставляет невосприимчивость.
/datum/unit_test/heretic_glass_casket/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/spell/glass_casket/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	TEST_ASSERT(istype(knowledge.granted_spell, /obj/effect/proc_holder/spell/pointed/heretic_glass/casket), "Знание выдаёт заклинание Витража.")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	glass.combat_resource = 4
	TEST_ASSERT(!glass.casket(user, victim), "Стоящую цель без трещин Витраж не берёт.")
	TEST_ASSERT(findtext(glass.glass_failure, "Витраж смыкается только"), "Отказ называет подходящие цели.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 4, "Отказ не тратит грани.")
	glass.fracture(victim)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!glass.casket(user, victim), "Антимагия отталкивает Витраж.")
	TEST_ASSERT(findtext(glass.glass_failure, "защищена от магии"), "Отказ называет антимагию.")
	qdel(protection)
	TEST_ASSERT(glass.casket(user, victim), "Треснувшая цель запирается.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Витраж стоит две грани.")
	TEST_ASSERT(!victim.IsParalyzed(), "Во время нарастания стекла цель ещё свободна.")
	TEST_ASSERT(wait_for_var(victim, NAMEOF(victim, anchored), TRUE, 3 SECONDS), "После секунды нарастания саркофаг смыкается.")
	var/obj/structure/heretic_glass_casket/casket = locate() in get_turf(victim)
	TEST_ASSERT_NOTNULL(casket, "На клетке цели стоит саркофаг.")
	TEST_ASSERT(casket.density, "Клетку саркофага не пройти.")
	TEST_ASSERT(victim.IsParalyzed(), "Запертая цель неподвижна.")
	TEST_ASSERT(findtext(glass.casket_block_reason(user, victim), "уже заперта"), "Повторный Витраж по запертой цели называет саркофаг, а не линию.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Запертая цель готова к обряду.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(victim, NORTH))
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Запертую цель не утащить.")
	RegisterSignal(victim, COMSIG_PARENT_ATTACKBY, PROC_REF(record_touch))
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart)
	user.put_in_hands(heart)
	casket.attackby(heart, user)
	UnregisterSignal(victim, COMSIG_PARENT_ATTACKBY)
	TEST_ASSERT_EQUAL(touched_with, heart, "Касание саркофага сердцем доходит до цели.")
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, get_step(get_step(victim, EAST), EAST))
	var/obj/item/projectile/beam/laser = glass_test_projectile(shooter, /obj/item/projectile/beam/laser)
	TEST_ASSERT_EQUAL(casket.bullet_act(laser), BULLET_ACT_FORCE_PIERCE, "Саркофаг отражает лазер.")
	TEST_ASSERT_EQUAL(casket.max_integrity, 90, "Прочность саркофага 90.")
	TEST_ASSERT_EQUAL(casket.obj_integrity, casket.max_integrity, "Отражение не ранит стекло.")
	casket.take_damage(10, BRUTE, MELEE)
	TEST_ASSERT_EQUAL(casket.obj_integrity, 75, "Удар в ближнем бою наносит полуторный урон.")
	casket.take_damage(200, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(casket), "Разбитый саркофаг исчезает.")
	TEST_ASSERT(!victim.anchored, "Освобождённую цель снова можно тянуть.")
	TEST_ASSERT(!victim.IsParalyzed(), "Освобождённая цель может двигаться.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "glass"), "приходит в себя"), "После саркофага цель невосприимчива.")
	glass.combat_resource = 4
	TEST_ASSERT(!glass.casket(user, victim), "Повторный Витраж в течение минуты отклонён.")
	TEST_ASSERT(findtext(glass.glass_failure, "приходит в себя"), "Отказ называет невосприимчивость.")
	var/mob/living/carbon/human/runner = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	glass.fracture(runner)
	TEST_ASSERT(glass.casket(user, runner), "Витраж нарастает вокруг второй цели.")
	var/obj/effect/temp_visual/heretic_glass/casket_growth/growth = locate() in get_turf(runner)
	TEST_ASSERT_NOTNULL(growth, "Нарастание стекла видно заранее.")
	runner.forceMove(get_step(get_turf(runner), NORTH))
	TEST_ASSERT(wait_for_qdeleted(growth, 3 SECONDS), "Нарастание завершается.")
	TEST_ASSERT(!runner.anchored && !runner.IsParalyzed(), "Отошедшая цель не запечатана.")
	TEST_ASSERT_NULL(locate(/obj/structure/heretic_glass_casket) in range(1, runner), "Саркофаг не смыкается на пустой клетке.")

/// Витраж берёт сбитых с ног, обессиленных, ослеплённых светом и треснувших, но не лёгших сами, спящих и незрячих.
/datum/unit_test/heretic_glass_casket_readiness/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass.combat_resource = 4
	var/mob/living/carbon/human/rester = allocate(/mob/living/carbon/human, locate(user.x + 1, user.y + 2, user.z))
	rester.set_resting(TRUE, silent = TRUE)
	TEST_ASSERT(findtext(glass.casket_block_reason(user, rester), "Витраж смыкается только"), "Добровольно лёгшая цель не подходит.")
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 1, user.z))
	sleeper.SetSleeping(10 SECONDS)
	sleeper.blind_eyes(1)
	TEST_ASSERT(sleeper.is_blind(), "Спящий считается незрячим.")
	TEST_ASSERT(findtext(glass.casket_block_reason(user, sleeper), "Витраж смыкается только"), "Спящая цель не подходит.")
	var/mob/living/carbon/human/blindman = allocate(/mob/living/carbon/human, locate(user.x + 1, user.y + 3, user.z))
	ADD_TRAIT(blindman, TRAIT_BLIND, TRAIT_SOURCE_UNIT_TESTS)
	blindman.blind_eyes(1)
	TEST_ASSERT(blindman.is_blind(), "Незрячий действительно не видит.")
	TEST_ASSERT(findtext(glass.casket_block_reason(user, blindman), "Витраж смыкается только"), "Незрячая от природы цель не подходит.")
	REMOVE_TRAIT(blindman, TRAIT_BLIND, TRAIT_SOURCE_UNIT_TESTS)
	var/mob/living/carbon/human/knocked = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 1, user.z))
	knocked.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT_NULL(glass.casket_block_reason(user, knocked), "Сбитая с ног цель подходит.")
	var/mob/living/carbon/human/exhausted = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 2, user.z))
	exhausted.adjustStaminaLoss(500)
	TEST_ASSERT(IS_STAMCRIT(exhausted), "Цель в стамкрите.")
	TEST_ASSERT_NULL(glass.casket_block_reason(user, exhausted), "Обессиленная цель подходит.")
	var/mob/living/carbon/human/dazzled = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(findtext(glass.casket_block_reason(user, dazzled), "Витраж смыкается только"), "Стоящая зрячая цель не подходит.")
	TEST_ASSERT(glass.storm(user), "Буря выпускается.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(dazzled.is_blind(), "Буря ослепила стоящую цель.")
	TEST_ASSERT_NULL(glass.casket_block_reason(user, dazzled), "Ослеплённая светом Стекла цель подходит.")
	expire_glass_blind(glass, dazzled)
	TEST_ASSERT(findtext(glass.casket_block_reason(user, dazzled), "Витраж смыкается только"), "Прозревшая цель снова не подходит.")

/// Шаг сквозь настроенное окно переносит на другую сторону за грань и оставляет окно целым; стена за окном и наручники мешают.
/datum/unit_test/heretic_glass_passage/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_passage)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/glass_passage/passage = heretic.get_knowledge(/datum/eldritch_knowledge/glass_passage)
	TEST_ASSERT(istype(passage.combat_power, /obj/effect/proc_holder/spell/pointed/heretic_glass/passage), "Знание выдаёт заклинание шага.")
	var/obj/structure/window/fulltile/walled = allocate(/obj/structure/window/fulltile, get_step(user, WEST))
	TEST_ASSERT(iswallturf(get_step(walled, WEST)), "За проверочным окном стена.")
	TEST_ASSERT(glass.attune(walled, user), "Окно у стены настроено.")
	TEST_ASSERT(!glass.step_through(user, walled), "Стена за окном не пускает.")
	TEST_ASSERT(findtext(glass.glass_failure, "стена"), "Отказ называет стену.")
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(user, EAST))
	var/turf/exit = get_step(window, EAST)
	TEST_ASSERT(glass.attune(window, user), "Окно настроено.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!glass.step_through(user, window), "В наручниках стекло не пускает.")
	TEST_ASSERT(findtext(glass.glass_failure, "наручниках"), "Отказ называет наручники.")
	user.uncuff()
	glass.combat_resource = 2
	TEST_ASSERT(glass.step_through(user, window), "Еретик проходит сквозь окно.")
	TEST_ASSERT_EQUAL(get_turf(user), exit, "Выход на клетке за окном.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 1, "Шаг стоит одну грань.")
	TEST_ASSERT(!QDELETED(window) && window.obj_integrity == window.max_integrity, "Окно остаётся целым.")
	TEST_ASSERT_NOTNULL(window.GetComponent(/datum/component/heretic_glass_passage_trace), "На окне остаётся трещина-след.")
	var/obj/structure/window/thin = allocate(/obj/structure/window, exit, EAST)
	TEST_ASSERT(glass.attune(thin, user), "Направленное окно настроено.")
	TEST_ASSERT(glass.step_through(user, thin), "Направленное окно пропускает с его стороны.")
	TEST_ASSERT_EQUAL(get_turf(user), get_step(exit, EAST), "Выход по ту сторону направленного окна.")
	glass.combat_resource = 1
	TEST_ASSERT(glass.step_through(user, thin), "Направленное окно пропускает и обратно.")
	TEST_ASSERT_EQUAL(get_turf(user), exit, "Обратный шаг возвращает на клетку окна.")
	TEST_ASSERT(!glass.step_through(user, thin), "Без граней шаг не выходит.")

/// Вдовья призма смотрит сквозь настроенное стекло, пока владелец неподвижен, цел и держит линзу.
/datum/unit_test/heretic_glass_gaze/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_relic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/glass_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/glass_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт линзу.")
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), center), "Вторая линза не создаётся.")
	var/obj/item/heretic_path_relic/glass/lens = recipe.new_path_relic_ref.resolve()
	allocated += lens
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(get_step(center, EAST), EAST))
	var/obj/structure/window/fulltile/stranger = allocate(/obj/structure/window/fulltile, get_step(get_step(center, NORTH), NORTH))
	TEST_ASSERT(glass.attune(window, user), "Окно настроено.")
	TEST_ASSERT(!lens.gaze(user, window), "Линза на полу не действует.")
	user.put_in_hands(lens)
	var/list/choices = lens.gaze_choices(user)
	TEST_ASSERT_EQUAL(length(choices), 1, "Выбор предлагает только настроенные стёкла.")
	TEST_ASSERT(findtext(choices[1], get_area_name(window, TRUE)), "Стекло подписано отделом.")
	TEST_ASSERT_EQUAL(choices[choices[1]], window, "Подпись ведёт к своему стеклу.")
	TEST_ASSERT(!lens.gaze(user, stranger), "Ненастроенное стекло не открывает взгляд.")
	TEST_ASSERT(lens.gaze(user, window), "Взгляд уходит в настроенное стекло.")
	TEST_ASSERT_EQUAL(lens.gaze_pane, window, "Линза помнит, куда смотрит владелец.")
	user.forceMove(get_step(center, SOUTH))
	TEST_ASSERT_NULL(lens.gaze_pane, "Движение возвращает взгляд в тело.")
	TEST_ASSERT(!lens.gaze(user, window), "После взгляда линза перезаряжается.")
	COOLDOWN_RESET(lens, relic_cooldown)
	TEST_ASSERT(lens.gaze(user, window), "После перезарядки взгляд снова доступен.")
	user.adjustBruteLoss(5)
	TEST_ASSERT_NULL(lens.gaze_pane, "Урон обрывает взгляд.")
	COOLDOWN_RESET(lens, relic_cooldown)
	TEST_ASSERT(lens.gaze(user, window), "Взгляд доступен после урона.")
	qdel(heretic_craft_on(window, "glass_pane"))
	TEST_ASSERT_NULL(lens.gaze_pane, "Снятая со стекла настройка обрывает взгляд.")
	COOLDOWN_RESET(lens, relic_cooldown)
	TEST_ASSERT(glass.attune(window, user), "Окно настроено снова.")
	TEST_ASSERT(lens.gaze(user, window), "Взгляд доступен после новой настройки.")
	user.dropItemToGround(lens)
	TEST_ASSERT_NULL(lens.gaze_pane, "Выпавшая линза обрывает взгляд.")

/// Перекрёстный свет стреляет и из настроенного стекла рядом, ослепляя всех поражённых.
/datum/unit_test/heretic_glass_storm_attuned/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, locate(user.x + 4, user.y + 1, user.z))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 1, user.z))
	var/mob/living/carbon/human/direct = allocate(/mob/living/carbon/human, locate(user.x + 1, user.y + 1, user.z))
	TEST_ASSERT(glass.storm(user), "Свет выпускается без настроенных стёкол.")
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Ненастроенное окно не стреляет.")
	TEST_ASSERT(abs(direct.getBruteLoss() - 40) < 0.01, "Прямой луч бури наносит 40 ушибов.")
	TEST_ASSERT(direct.is_blind(), "Прямой луч бури ослепляет.")
	TEST_ASSERT(glass.attune(window, user), "Окно в семи клетках настроено.")
	TEST_ASSERT(glass.storm(user), "Свет выпускается вместе с настроенным стеклом.")
	attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 40) < 0.01, "Настроенное окно стреляет вместе с бурей: [victim.getBruteLoss()].")
	TEST_ASSERT(victim.is_blind(), "Поражённый лучом стекла ослеплён.")
	var/datum/timedevent/cure = glass_blind_timer(glass, victim)
	TEST_ASSERT_NOTNULL(cure, "Слепоту снимает свой таймер.")
	TEST_ASSERT(abs(cure.timeToRun - world.time - (3 SECONDS)) < 0.1, "Буря ослепляет ровно на три секунды. Осталось: [cure.timeToRun - world.time] дс.")
	expire_glass_blind(glass, victim)
	TEST_ASSERT(!victim.is_blind(), "По истечении срока цель снова видит.")

/datum/unit_test/heretic_glass_casket_sacrifice
	var/casket_at_revive = FALSE
	var/revived = FALSE

/datum/unit_test/heretic_glass_casket_sacrifice/proc/on_revive(mob/living/source)
	SIGNAL_HANDLER
	revived = TRUE
	casket_at_revive = !!(locate(/obj/structure/heretic_glass_casket) in source.loc)

/// Саркофаг рассыпается до лечения Мансуса и не держит жертву в Доме; невосприимчивость остаётся.
/datum/unit_test/heretic_glass_casket_sacrifice/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	var/obj/structure/heretic_glass_casket/casket = allocate(/obj/structure/heretic_glass_casket, get_turf(victim), glass, victim)
	TEST_ASSERT(victim.IsParalyzed(), "Саркофаг держит жертву.")
	RegisterSignal(victim, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))
	var/datum/heretic_mansus_visit/visit = allocate(/datum/heretic_mansus_visit/mansus_fixture)
	TEST_ASSERT(visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Комната готова.")
	TEST_ASSERT(visit.start(), "Жертва входит в Мансус.")
	UnregisterSignal(victim, COMSIG_LIVING_REVIVE)
	TEST_ASSERT(revived, "Мансус лечит жертву.")
	TEST_ASSERT(!casket_at_revive, "Саркофаг рассыпается до лечения Мансуса.")
	TEST_ASSERT(QDELETED(casket), "Саркофаг не уходит за жертвой.")
	TEST_ASSERT(!victim.IsParalyzed(), "В Доме саркофаг жертву не держит.")
	TEST_ASSERT(!victim.anchored, "Жертва не прикована к месту.")
	TEST_ASSERT_NOTNULL(capture_immunity(victim, "glass"), "После саркофага невосприимчивость остаётся.")

/// Саркофаг держит своим параличом: удержание обряда не становится срочным и не снимается при освобождении.
/datum/unit_test/heretic_glass_casket_keeps_rite/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/rite = new(list(victim, -1, TRUE))
	var/obj/structure/heretic_glass_casket/casket = allocate(/obj/structure/heretic_glass_casket, get_turf(victim), glass, victim)
	TEST_ASSERT(victim.IsParalyzed(), "Цель в саркофаге неподвижна.")
	TEST_ASSERT_EQUAL(rite.duration, -1, "Саркофаг не делает удержание обряда срочным.")
	qdel(casket)
	TEST_ASSERT(!QDELETED(rite), "Освобождение из саркофага не снимает удержание обряда.")
	TEST_ASSERT_EQUAL(rite.duration, -1, "Удержание обряда остаётся бессрочным.")
	TEST_ASSERT(victim.IsParalyzed(), "Обряд по-прежнему держит цель.")
	qdel(rite)
	TEST_ASSERT(!victim.IsParalyzed(), "Без обряда и саркофага цель свободна.")

/// Сквозь стекло ведёт только своё настроенное окно и только сбоку: чужое окно и шаг по диагонали отклоняются без траты грани.
/datum/unit_test/heretic_glass_passage_attuned/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_passage)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/start = get_turf(user)
	glass.combat_resource = 2
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(user, EAST))
	TEST_ASSERT(!glass.step_through(user, window), "Ненастроенное окно не пускает.")
	TEST_ASSERT(findtext(glass.glass_failure, "настроенное"), "Отказ называет настройку: [glass.glass_failure]")
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Отказ не тратит грань.")
	TEST_ASSERT_EQUAL(get_turf(user), start, "Еретик остаётся на месте.")
	var/obj/structure/window/fulltile/corner = allocate(/obj/structure/window/fulltile, get_step(user, NORTHEAST))
	TEST_ASSERT(glass.attune(corner, user), "Угловое окно настроено.")
	TEST_ASSERT(!glass.step_through(user, corner), "По диагонали сквозь окно не шагнуть.")
	TEST_ASSERT(findtext(glass.glass_failure, "вплотную"), "Отказ просит встать вплотную: [glass.glass_failure]")
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Отказ по диагонали не тратит грань.")
	var/obj/structure/window/fulltile/distant = allocate(/obj/structure/window/fulltile, locate(user.x, user.y + 2, user.z))
	TEST_ASSERT(glass.attune(distant, user), "Окно через клетку настроено.")
	TEST_ASSERT(!glass.step_through(user, distant), "Сквозь окно через клетку не шагнуть.")
	TEST_ASSERT(findtext(glass.glass_failure, "вплотную"), "Отказ просит встать вплотную: [glass.glass_failure]")
	TEST_ASSERT_EQUAL(get_turf(user), start, "Отказ издалека не переносит.")
	TEST_ASSERT(glass.attune(window, user), "Окно настроено.")
	TEST_ASSERT(glass.step_through(user, window), "Своё настроенное окно пропускает.")
	TEST_ASSERT_EQUAL(get_turf(user), get_step(window, EAST), "Выход по ту сторону окна.")

/// Запись о слепоте уходит вместе со слепотой, а удаление знания снимает идущую слепоту.
/datum/unit_test/heretic_glass_blind_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	glass.blind(victim, 0.5 SECONDS)
	TEST_ASSERT(victim.is_blind(), "Вспышка ослепляет.")
	TEST_ASSERT_EQUAL(length(glass.blind_timers), 1, "Слепота записана.")
	var/list/budget = new_wait_budget(2 SECONDS, "слепота Стекла проходит")
	while(length(glass.blind_timers))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_EQUAL(length(glass.blind_timers), 0, "Прошедшая слепота не оставляет записи.")
	TEST_ASSERT(!victim.is_blind(), "По сроку цель снова видит.")
	glass.blind(victim, 2 SECONDS)
	qdel(glass)
	TEST_ASSERT(!victim.is_blind(), "Удаление знания снимает идущую слепоту.")

/// Столы и операционный стол не закрывают Витражу линию, плотная машина закрывает.
/datum/unit_test/heretic_glass_casket_over_tables/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass.combat_resource = 4
	allocate(/obj/structure/table, locate(user.x + 1, user.y, user.z))
	var/turf/bed = locate(user.x + 2, user.y, user.z)
	allocate(/obj/structure/table/optable, bed)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, bed)
	patient.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT_NULL(glass.casket_block_reason(user, patient), "Цель на операционном столе за столом доступна Витражу.")
	var/obj/machinery/hydroponics/machine = allocate(/obj/machinery/hydroponics, locate(user.x + 1, user.y + 1, user.z))
	TEST_ASSERT(machine.density, "Лоток гидропоники плотный.")
	var/mob/living/carbon/human/hidden = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 2, user.z))
	hidden.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(findtext(glass.casket_block_reason(user, hidden), "открытой линии"), "Плотная машина закрывает линию.")

/// Взгляд сквозь стекло обрывают урон выносливости, оглушение и беспамятство с неотнимаемой линзой и урон по телу без плоти.
/datum/unit_test/heretic_glass_gaze_breaks/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_relic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/glass_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/glass_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт линзу.")
	var/obj/item/heretic_path_relic/glass/lens = recipe.new_path_relic_ref.resolve()
	allocated += lens
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(get_step(center, EAST), EAST))
	TEST_ASSERT(glass.attune(window, user), "Окно настроено.")
	user.put_in_hands(lens)
	ADD_TRAIT(lens, TRAIT_NODROP, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(lens.gaze(user, window), "Взгляд уходит в стекло.")
	user.adjustStaminaLoss(10)
	TEST_ASSERT_NULL(lens.gaze_pane, "Урон выносливости обрывает взгляд.")
	user.setStaminaLoss(0)
	COOLDOWN_RESET(lens, relic_cooldown)
	TEST_ASSERT(lens.gaze(user, window), "Взгляд снова доступен.")
	user.Stun(1 SECONDS)
	TEST_ASSERT_NULL(lens.gaze_pane, "Оглушение обрывает взгляд.")
	user.SetStun(0)
	COOLDOWN_RESET(lens, relic_cooldown)
	TEST_ASSERT(lens.gaze(user, window), "После оглушения взгляд доступен.")
	user.Unconscious(1 SECONDS)
	TEST_ASSERT_NULL(lens.gaze_pane, "Беспамятство обрывает взгляд.")
	user.SetUnconscious(0)
	REMOVE_TRAIT(lens, TRAIT_NODROP, TRAIT_SOURCE_UNIT_TESTS)
	user.dropItemToGround(lens)
	var/mob/living/simple_animal/drone/drone = allocate(/mob/living/simple_animal/drone, center)
	heretic.owner.transfer_to(drone, TRUE)
	TEST_ASSERT_EQUAL(glass.glass_body, drone, "Стекло следует за разумом в новое тело.")
	TEST_ASSERT(drone.put_in_hands(lens), "Дрон держит линзу.")
	COOLDOWN_RESET(lens, relic_cooldown)
	TEST_ASSERT(lens.gaze(drone, window), "Взгляд доступен телу без плоти.")
	drone.apply_damage(5, BRUTE)
	TEST_ASSERT_NULL(lens.gaze_pane, "Урон по телу без плоти обрывает взгляд.")

/area/unit_test_glass_gallery
	name = "Glass Gallery Test Room"
	requires_power = FALSE

/// Во время паузы дела окно в незачтённом отделе не настраивается, в зачтённом настраивается как обычно.
/datum/unit_test/heretic_glass_attune_waits_for_deed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_GLASS)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(user, EAST))
	COOLDOWN_START(heretic.deed, progress_cooldown, HERETIC_DEED_COOLDOWN)
	TEST_ASSERT(!glass.on_mansus_grasp(window, user, TRUE), "Во время паузы окно в новом отделе не настраивается.")
	TEST_ASSERT(findtext(glass.grasp_failure_reason, "Слишком быстро"), "Отказ называет паузу: [glass.grasp_failure_reason]")
	TEST_ASSERT_NULL(heretic_craft_on(window, "glass_pane"), "Окно осталось без ремесла.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Отказ не трогает дело.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(glass.on_mansus_grasp(window, user, TRUE), "После паузы окно настраивается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Отдел засчитан.")
	var/obj/structure/window/fulltile/neighbour = allocate(/obj/structure/window/fulltile, get_step(user, NORTH))
	TEST_ASSERT(glass.on_mansus_grasp(neighbour, user, TRUE), "В зачтённом отделе пауза настройке не мешает.")
	var/turf/gallery = locate(user.x + 2, user.y + 2, user.z)
	heretic_test_area(gallery, /area/unit_test_glass_gallery)
	var/obj/structure/window/fulltile/far = allocate(/obj/structure/window/fulltile, gallery)
	TEST_ASSERT(!glass.attune(far, user), "Окно в другом отделе ждёт конца паузы.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(glass.attune(far, user), "После паузы окно в другом отделе настраивается.")
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 2, "Оба отдела засчитаны.")

/// Дверь Стекла: цель в своём саркофаге или готовая у своего стекла уводится в изнанку, где вход держит её вместо разбитого саркофага; стоящая, вдали от стёкол или у снятого стекла - нет; клик «Помощи» по цели саркофаг не открывает, 2 секунды «Помощи» по саркофагу - открывают; выходы - свои стёкла, снятые и чужие не в счёт.
/datum/unit_test/heretic_glass_pocket_door/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_casket)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/origin = get_turf(user)
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, get_step(spot, NORTH))
	TEST_ASSERT(glass.attune(window, user), "Окно у цели настроено.")
	TEST_ASSERT_NULL(glass.pocket_door(user, victim), "Стоящую цель стекло не уводит.")
	var/obj/structure/heretic_glass_casket/casket = new(spot, glass, victim)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(spot, SOUTH))
	victim.help_shake_act(helper)
	helper.forceMove(get_step(helper, EAST))
	TEST_ASSERT(!QDELETED(casket) && victim.IsParalyzed(), "Клик «Помощи» не открывает саркофаг.")
	var/list/door = glass.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Цель в своём саркофаге у своего стекла уводится.")
	TEST_ASSERT_EQUAL(door["name"], "в стекло", "Дверь подписана.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Дверь Стекла занимает [HERETIC_POCKET_PULL_TIME / (1 SECONDS)] с.")
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь Стекла уводит цель в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(QDELETED(casket), "Саркофаг остаётся на станции и рассыпается.")
	var/datum/timedevent/release = SStimer.timer_id_dict[heretic.pocket.entry_hold_timer]
	TEST_ASSERT(victim.IsParalyzed() && abs(release?.timeToRun - world.time - HERETIC_POCKET_ENTRY_HOLD) < 1, "Вход держит цель [HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS)] с: [release?.timeToRun - world.time] дс.")
	TEST_ASSERT_NULL(heretic.heart_rite_refusal_reason(victim, ritual), "Обряд сердцем над удержанной целью начинается.")
	heretic.pocket.collapse("проверка")
	TEST_ASSERT_EQUAL(get_turf(victim), spot, "Цель выпадает у входа.")
	casket = new(spot, glass, victim)
	helper.forceMove(get_step(spot, SOUTH))
	helper.a_intent = INTENT_HELP
	casket.attack_hand(helper)
	TEST_ASSERT(LAZYFIND(helper.do_afters, victim), "«Помощь» по саркофагу начинает расталкивать запертого.")
	helper.forceMove(get_step(helper, EAST))
	var/list/budget = new_wait_budget(HERETIC_CAPTURE_SHAKE_TIME * 2, "сорванная попытка растолкать")
	while(LAZYFIND(helper.do_afters, victim))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(!QDELETED(casket), "Отошедший не растолкал запертого.")
	helper.forceMove(get_step(spot, SOUTH))
	casket.attack_hand(helper)
	TEST_ASSERT(wait_for_qdeleted(casket, HERETIC_CAPTURE_SHAKE_TIME * 2), "Две секунды «Помощи» по саркофагу выпускают запертого.")

	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Скованная цель готова к обряду.")
	TEST_ASSERT_NOTNULL(glass.pocket_door(user, victim), "Готовая цель у своего стекла уводится.")
	var/turf/far_spot = locate(spot.x + 3, spot.y + 3, spot.z)
	victim.forceMove(far_spot)
	user.forceMove(get_step(far_spot, WEST))
	TEST_ASSERT_NULL(glass.pocket_door(user, victim), "Вдали от своих стёкол готовую цель не увести.")
	user.forceMove(origin)
	victim.forceMove(spot)
	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, locate(spot.x + 3, spot.y, spot.z))
	TEST_ASSERT(glass.attune(mirror, user), "Зеркало настроено.")
	var/datum/antagonist/heretic/rival = allocate_heretic(locate(spot.x + 2, spot.y + 3, spot.z))
	rival.selected_path = PATH_GLASS
	rival.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/base_glass/rival_glass = rival.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/mirror/foreign = allocate(/obj/structure/mirror, locate(spot.x + 3, spot.y + 3, spot.z))
	TEST_ASSERT(rival_glass.attune(foreign, rival.owner.current), "Чужое зеркало настроено другим еретиком.")
	var/list/exits = glass.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 2, "Оба своих стекла - выходы.")
	for(var/label in exits)
		var/turf/exit = exits[label]
		TEST_ASSERT(findtext(label, "Стекло - "), "Выход подписан стеклом и отделом: [label]")
		TEST_ASSERT(heretic_pocket_landable(exit), "Выход - свободный пол: [label]")
		TEST_ASSERT(get_dist(exit, window) <= 1 || get_dist(exit, mirror) <= 1, "Выход у своего стекла: [label]")
		TEST_ASSERT(get_turf(foreign) != exit, "Чужое стекло не выход.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(window, EAST))
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, window)
	TEST_ASSERT_EQUAL(length(glass.pocket_exits(user)), 1, "Снятое стекло больше не выход.")
	TEST_ASSERT_NULL(glass.pocket_door(user, victim), "У снятого стекла готовую цель не увести.")

/datum/unit_test/heretic_glass_theft
	var/theft_done = FALSE
	var/theft_result

/datum/unit_test/heretic_glass_theft/proc/steal_in_background(datum/eldritch_knowledge/base_glass/glass, mob/living/user, obj/structure/through, label)
	theft_result = glass.steal_through(user, through, label)
	theft_done = TRUE

/// Кража сквозь стекло: цель у своего стекла одна (или треснула) и её никто не держит, канал рвётся, если цель отошла, удача тратит перезарядку, отказ - нет; цель предупреждена один раз; разрыв у дальнего стекла; два стекла в одном отделе - два выбора.
/datum/unit_test/heretic_glass_theft/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/window/fulltile/near_pane = allocate(/obj/structure/window/fulltile, locate(start.x + 1, start.y, start.z))
	var/obj/structure/window/fulltile/far_pane = allocate(/obj/structure/window/fulltile, locate(start.x + 5, start.y + 3, start.z))
	TEST_ASSERT(glass.attune(near_pane, user), "Ближнее стекло настроено.")
	TEST_ASSERT(glass.attune(far_pane, user), "Дальнее стекло настроено.")
	var/turf/by_glass = locate(start.x + 4, start.y + 3, start.z)
	var/mob/living/carbon/human/echo_chat_probe/victim = allocate(/mob/living/carbon/human/echo_chat_probe, by_glass)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y + 5, start.z))
	user.a_intent = INTENT_HELP

	TEST_ASSERT_EQUAL(length(glass.theft_doors(user, near_pane)), 0, "При свидетеле рядом с целью кражи нет.")
	TEST_ASSERT_EQUAL(glass.on_pane_hand(near_pane, user), NONE, "Без одинокой цели рука по стеклу работает как обычно.")
	witness.forceMove(locate(start.x, start.y + 5, start.z))
	var/list/doors = glass.theft_doors(user, near_pane)
	TEST_ASSERT_EQUAL(length(doors), 1, "Одинокая цель у своего стекла видна сквозь стекло.")
	var/label = doors[1]
	TEST_ASSERT(findtext(label, "Стекло - ") && findtext(label, victim.real_name), "Выбор назван стеклом, отделом и целью: [label]")
	witness.forceMove(get_step(by_glass, NORTH))
	TEST_ASSERT(!glass.steal_through(user, near_pane, label), "Свидетель рядом срывает кражу.")
	TEST_ASSERT(COOLDOWN_FINISHED(glass, theft_cooldown), "Отказ не тратит перезарядку.")
	witness.forceMove(locate(start.x, start.y + 5, start.z))

	INVOKE_ASYNC(src, PROC_REF(steal_in_background), glass, user, near_pane, label)
	TEST_ASSERT(!theft_done, "Кража идёт каналом.")
	sleep(HERETIC_GLASS_THEFT_TIME / 2)
	TEST_ASSERT(!theft_done, "Через секунду кража ещё идёт.")
	victim.forceMove(locate(start.x + 2, start.y + 3, start.z))
	TEST_ASSERT(wait_for_var(src, NAMEOF(src, theft_done), TRUE, HERETIC_GLASS_THEFT_TIME * 2), "Канал кражи завершается.")
	TEST_ASSERT(!theft_result, "Отошедшую от стекла цель не утянуть.")
	TEST_ASSERT(!heretic.pocket?.active, "Сорванная кража не открывает изнанку.")
	TEST_ASSERT(COOLDOWN_FINISHED(glass, theft_cooldown), "Сорванная кража не тратит перезарядку.")

	victim.forceMove(by_glass)
	victim.shown.Cut()
	var/started = world.time
	TEST_ASSERT(glass.steal_through(user, near_pane, label), "Одинокую цель у своего стекла утягивает сквозь стекло.")
	TEST_ASSERT_EQUAL(victim.count_shown("Стекло рядом с вами идёт рябью"), 1, "Цель предупреждена о краже один раз.")
	TEST_ASSERT(world.time - started >= HERETIC_GLASS_THEFT_TIME - 1, "Кража длится [HERETIC_GLASS_THEFT_TIME / (1 SECONDS)] с: [world.time - started] дс.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(heretic.pocket.contains(user), "Еретик в изнанке с целью.")
	TEST_ASSERT_EQUAL(heretic.pocket.entry_turf, by_glass, "Вход изнанки - у дальнего стекла.")
	TEST_ASSERT(get_dist(heretic.pocket.rift, far_pane) <= 1, "Разрыв остаётся у дальнего стекла.")
	TEST_ASSERT(abs(glass.theft_cooldown - world.time - HERETIC_GLASS_THEFT_COOLDOWN) < 1, "Перезарядка кражи [HERETIC_GLASS_THEFT_COOLDOWN / (1 SECONDS)] с: [glass.theft_cooldown - world.time] дс.")

	heretic.pocket.collapse("проверка")
	COOLDOWN_RESET(heretic.pocket, reopen_cooldown)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)
	user.forceMove(start)
	victim.forceMove(by_glass)
	TEST_ASSERT_EQUAL(length(glass.theft_doors(user, near_pane)), 1, "Цель снова одна у стекла.")
	TEST_ASSERT(!glass.steal_through(user, near_pane, label), "В перезарядке кражи нет.")
	TEST_ASSERT(!heretic.pocket.active, "В перезарядке цель остаётся на станции.")
	TEST_ASSERT_EQUAL(glass.on_pane_hand(near_pane, user), COMPONENT_NO_ATTACK_HAND, "Рука по стеклу при цели за стеклом не стучит, а объясняет перезарядку.")
	user.a_intent = INTENT_HARM
	TEST_ASSERT_EQUAL(glass.on_pane_hand(near_pane, user), NONE, "В намерении вреда рука по стеклу работает как обычно.")
	var/obj/structure/mirror/twin_pane = allocate(/obj/structure/mirror, locate(start.x + 3, start.y + 4, start.z))
	TEST_ASSERT(glass.attune(twin_pane, user), "Второе стекло у цели в том же отделе настроено.")
	var/list/twin_doors = glass.theft_doors(user, near_pane)
	TEST_ASSERT_EQUAL(length(twin_doors), 2, "Оба стекла у цели в одном отделе остаются разными выборами.")

/// Витраж стоит на четвёртой ступени Стекла, Метка - на пятой.
/datum/unit_test/heretic_glass_tiers/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_GLASS]
	TEST_ASSERT_EQUAL(path.knowledge[4], /datum/eldritch_knowledge/spell/glass_casket, "Витраж - четвёртая ступень.")
	TEST_ASSERT_EQUAL(path.knowledge[5], /datum/eldritch_knowledge/glass_mark, "Метка Стекла - пятая ступень.")

/// Кража сквозь стекло берёт и треснувшую цель при свидетеле рядом; цель, которую тащат, несут на плечах или пристегнули, не крадётся, а схваченная посреди канала срывает кражу.
/datum/unit_test/heretic_glass_theft/cracked/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/window/fulltile/near_pane = allocate(/obj/structure/window/fulltile, locate(start.x + 1, start.y, start.z))
	var/obj/structure/window/fulltile/far_pane = allocate(/obj/structure/window/fulltile, locate(start.x + 5, start.y + 3, start.z))
	TEST_ASSERT(glass.attune(near_pane, user), "Ближнее стекло настроено.")
	TEST_ASSERT(glass.attune(far_pane, user), "Дальнее стекло настроено.")
	var/turf/by_glass = locate(start.x + 4, start.y + 3, start.z)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, by_glass)
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y + 5, start.z))
	user.a_intent = INTENT_HELP
	TEST_ASSERT_EQUAL(length(glass.theft_doors(user, near_pane)), 0, "Цель без трещин при свидетеле рядом не утянуть.")
	TEST_ASSERT_NOTNULL(glass.fracture(victim), "Цель треснула.")
	var/list/doors = glass.theft_doors(user, near_pane)
	TEST_ASSERT_EQUAL(length(doors), 1, "Треснувшую цель у своего стекла видно сквозь стекло и при свидетеле.")
	var/label = doors[1]
	witness.forceMove(get_step(by_glass, NORTH))
	witness.start_pulling(victim)
	TEST_ASSERT_EQUAL(witness.pulling, victim, "Свидетель держит цель.")
	TEST_ASSERT_EQUAL(length(glass.theft_doors(user, near_pane)), 0, "Цель в чужих руках сквозь стекло не утянуть.")
	TEST_ASSERT(!glass.steal_through(user, near_pane, label), "Кража не начинается, пока цель держат.")
	TEST_ASSERT(COOLDOWN_FINISHED(glass, theft_cooldown), "Отказ не тратит перезарядку.")
	witness.stop_pulling()
	INVOKE_ASYNC(src, PROC_REF(steal_in_background), glass, user, near_pane, label)
	TEST_ASSERT(!theft_done, "Кража идёт каналом.")
	witness.start_pulling(victim)
	TEST_ASSERT(wait_for_var(src, NAMEOF(src, theft_done), TRUE, HERETIC_GLASS_THEFT_TIME * 2), "Канал кражи завершается.")
	TEST_ASSERT(!theft_result, "Свидетель, схвативший цель, срывает кражу.")
	TEST_ASSERT(!heretic.pocket?.active, "Сорванная кража не открывает изнанку.")
	witness.stop_pulling()
	witness.buckle_mob(victim, TRUE, buckle_type = RIDING_FIREMAN, auto_by_type = TRUE)
	TEST_ASSERT_EQUAL(victim.buckled, witness, "Свидетель несёт цель на плечах.")
	TEST_ASSERT(get_dist(victim, far_pane) <= 1, "Цель на плечах стоит у стекла.")
	TEST_ASSERT_EQUAL(length(glass.theft_doors(user, near_pane)), 0, "Цель на чужих плечах сквозь стекло не утянуть.")
	witness.unbuckle_mob(victim, TRUE)
	victim.forceMove(by_glass)
	var/obj/structure/bed/bed = allocate(/obj/structure/bed, by_glass)
	TEST_ASSERT(bed.buckle_mob(victim, TRUE), "Цель пристёгнута к кровати у стекла.")
	TEST_ASSERT_EQUAL(length(glass.theft_doors(user, near_pane)), 0, "Пристёгнутую цель сквозь стекло не утянуть.")
	bed.unbuckle_mob(victim, TRUE)
	theft_done = FALSE
	TEST_ASSERT(glass.steal_through(user, near_pane, label), "Треснувшую цель без чужих рук утягивает сквозь стекло при свидетеле рядом.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	heretic.pocket.collapse("проверка")

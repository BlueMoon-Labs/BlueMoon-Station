/// Клинок и метка не создают строительный ресурс; восстановление имеет отдельную задержку.
/datum/unit_test/heretic_glass_combat_cycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_mark)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_upgrade)
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
	TEST_ASSERT_EQUAL(glass.combat_resource, 2, "Настоящий удар и детонация тоже не дают граней.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/glass), "Удар клинком расходует метку.")
	TEST_ASSERT(abs(victim.getBruteLoss() - blade.force - 8) < 0.01, "Усиление луча не превращается в лишний клинковый урон.")
	var/damage_before = victim.getBruteLoss()
	glass.release(user, victim)
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - damage_before - 16) < 0.01, "Прямой луч не получает бонус от трещин.")
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
	TEST_ASSERT(abs(victim.getBruteLoss() - 16) < 0.01, "Луч наносит шестнадцать ушибов.")
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
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_upgrade)
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
	TEST_ASSERT(abs(victim.getBruteLoss() - 26) < 0.01, "Преломление обходит угол и усиливает луч по трещинам.")
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
	TEST_ASSERT_NULL(glass.create_barrier(user, east), "Неизученная преграда не создаётся.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_barrier)
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

/// Заклинание размещает и поворачивает реальные узлы, а линза расщепляет ближайший собственный луч.
/datum/unit_test/heretic_glass_prism/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_relic)
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
	var/datum/eldritch_knowledge/glass_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/glass_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт линзу.")
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), center), "Вторая линза не создаётся.")
	var/obj/item/heretic_path_relic/glass/lens = recipe.new_path_relic_ref.resolve()
	allocated += lens
	TEST_ASSERT(!lens.rotate_prism(user), "Линза на полу не действует.")
	user.put_in_hands(lens)
	TEST_ASSERT(lens.rotate_prism(user), "Линза меняет ближайший собственный узел.")
	TEST_ASSERT(prism.split, "Призма переходит в режим расщепления.")
	TEST_ASSERT(!lens.rotate_prism(user), "Повторное переключение ограничено перезарядкой.")
	var/mob/living/upper = allocate(/mob/living/carbon/human, get_step(node_place, NORTHEAST))
	var/mob/living/lower = allocate(/mob/living/carbon/human, get_step(node_place, SOUTHEAST))
	glass.release(user, prism)
	var/datum/heretic_glass_attack/attack = glass.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(upper.getBruteLoss() - 12) < 0.01, "Верхняя ветвь наносит двенадцать ушибов.")
	TEST_ASSERT(abs(lower.getBruteLoss() - 12) < 0.01, "Нижняя ветвь наносит двенадцать ушибов.")
	TEST_ASSERT(lens.authorized(user), "Линза находится у законного владельца до удаления знания.")
	qdel(recipe)
	TEST_ASSERT(!lens.authorized(user), "Удалённое знание отключает удерживаемую линзу.")
	TEST_ASSERT(!prism.split, "Потеря знания возвращает узел к одному выходу.")

/// Пересечение сети бьёт один раз, а поворот и разрушение узлов не расширяют старое предупреждение.
/datum/unit_test/heretic_glass_storm/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_storm)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	TEST_ASSERT(!glass.storm(user), "Сеть без призм не выпускает лучи.")
	user.setDir(NORTH)
	glass.shards(user, get_step(get_step(user, EAST), EAST))
	user.setDir(EAST)
	glass.shards(user, get_step(get_step(user, NORTH), NORTH))
	var/obj/structure/heretic_glass_prism/eastern = glass.prisms[1]
	var/obj/structure/heretic_glass_prism/northern = glass.prisms[2]
	var/turf/crossing = get_step(get_step(get_turf(eastern), NORTH), NORTH)
	var/mob/living/victim = allocate(/mob/living/carbon/human, crossing)
	var/mob/living/protected = allocate(/mob/living/carbon/human, crossing)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(glass.storm(user), "Два узла создают предупреждённую сеть.")
	TEST_ASSERT_EQUAL(glass.combat_resource, 0, "Сеть не требует нового строительного ресурса.")
	var/datum/heretic_glass_attack/first = glass.attacks[1]
	first.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 16) < 0.01, "Пересечение двух лучей не удваивает урон.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Пересечение тратит один заряд антимагии.")
	glass.storm(user)
	var/datum/heretic_glass_attack/second = glass.attacks[1]
	eastern.setDir(WEST)
	qdel(northern)
	second.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 16) < 0.01, "Разобранная геометрия не исполняет прежние лучи.")
	eastern.setDir(NORTH)
	glass.storm(user)
	var/datum/heretic_glass_attack/third = glass.attacks[1]
	user.forceMove(get_step(user, NORTH))
	TEST_ASSERT(QDELETED(third), "Первая подготовка сети отменяется реальным движением.")
	eastern.setDir(SOUTH)
	var/list/cells = glass.trace_ray(get_turf(eastern), EAST, eastern)
	TEST_ASSERT(length(cells) <= 12, "Один источник не превышает общий бюджет трассировки.")

/// Смерть и переселение убирают призмы, чужие статусы, предупреждения и прежнюю способность.
/datum/unit_test/heretic_glass_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_mark)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	glass.release(new_body, victim)
	attack = glass.attacks[1]
	qdel(glass)
	TEST_ASSERT(QDELETED(attack), "Удаление основного знания отменяет оставшийся луч.")

/// Удаление знания строительства разбирает узлы, а утрата метки снимает статус с чужого тела.
/datum/unit_test/heretic_glass_knowledge_removal/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_barrier)
	heretic.gain_knowledge(/datum/eldritch_knowledge/glass_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	glass.shards(user, get_step(user, EAST))
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	var/datum/eldritch_knowledge/shards = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	qdel(shards)
	TEST_ASSERT(QDELETED(prism), "Удаление строительства удаляет существующие призмы.")
	TEST_ASSERT(!glass.shards(user, get_step(user, EAST)), "Удалённое знание не создаёт новый узел.")
	var/obj/structure/heretic_glass_barrier/barrier = glass.create_barrier(user, get_step(user, NORTH))
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_barrier))
	TEST_ASSERT(QDELETED(barrier), "Удаление защиты разбирает защитную преграду.")
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
	TEST_ASSERT(abs(east_victim.getBruteLoss() - 16) < 0.01, "Первая волна следует первоначальному направлению.")
	prism.setDir(NORTH)
	user.forceMove(get_step(user, SOUTH))
	TEST_ASSERT(!QDELETED(network), "После первой подготовки можно перемещаться.")
	TEST_ASSERT(network.pulse(), "Следующая волна строит новый снимок.")
	var/datum/heretic_glass_attack/second = glass.attacks[1]
	TEST_ASSERT_EQUAL(north_victim.getBruteLoss(), 0, "Новая геометрия сначала предупреждает, затем бьёт.")
	second.resolve()
	TEST_ASSERT(abs(north_victim.getBruteLoss() - 16) < 0.01, "Вторая волна использует новое направление узла.")
	TEST_ASSERT(abs(east_victim.getBruteLoss() - 16) < 0.01, "Вторая волна не повторяет исчезнувшую линию.")
	TEST_ASSERT(network.pulse(), "Третья волна доступна.")
	var/datum/heretic_glass_attack/third = glass.attacks[1]
	TEST_ASSERT(!network.pulse(), "Четвёртая волна запрещена.")
	qdel(prism)
	TEST_ASSERT(QDELETED(network), "Разрушение исходного узла прекращает весь витраж.")
	TEST_ASSERT(QDELETED(third), "Разрушение убирает и предупреждённую, но ещё не сработавшую волну.")
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
	TEST_ASSERT(QDELETED(network), "Разрушение промежуточного узла тоже прекращает весь витраж.")
	TEST_ASSERT(QDELETED(relayed_attack), "Промежуточный узел снимает уже подготовленную волну.")
	final_knowledge.on_body_lose(user)
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
	TEST_ASSERT(abs(victim.getBruteLoss() - 16) < 0.01, "Проходы луча в обе стороны наносят один урон.")
	var/obj/structure/heretic_glass_prism/prism = glass.prisms[1]
	prism.take_damage(100, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(prism), "Обычный урон разбирает оптическую установку.")
	TEST_ASSERT_EQUAL(length(glass.prisms), 1, "Разрушение освобождает место для нового узла.")

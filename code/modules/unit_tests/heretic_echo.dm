/// Отмеченные клетки остаются на месте, а выход с них до удара позволяет уклониться.
/datum/unit_test/heretic_echo_telegraph_and_dodge/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/staying = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/mob/living/dodging = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	TEST_ASSERT(echo.release(user), "Начального резонанса хватает на первую волну.")
	TEST_ASSERT_EQUAL(echo.combat_resource, initial(echo.combat_resource) - 1, "Волна расходует единицу резонанса.")
	TEST_ASSERT_EQUAL(staying.getBruteLoss(), 0, "Предупреждение само по себе не ранит.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Волна хранится как одна отложенная атака.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT(length(attack.warnings), "Каждая запланированная волна имеет видимое предупреждение.")
	var/list/warnings = attack.warnings.Copy()
	dodging.forceMove(get_step(center, NORTHEAST))
	user.forceMove(get_step(center, SOUTHWEST))
	attack.resolve()
	TEST_ASSERT(staying.getBruteLoss() > 0, "Оставшийся на прежней клетке противник получает удар.")
	TEST_ASSERT_EQUAL(dodging.getBruteLoss(), 0, "Ушедший на диагональ противник уклоняется.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Собственная волна не ранит создателя.")
	TEST_ASSERT(QDELETED(attack), "Одиночная волна освобождает отложенную атаку.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Завершённая волна освобождает место в лимите.")
	for(var/obj/effect/warning as anything in warnings)
		TEST_ASSERT(QDELETED(warning), "Завершённая волна удаляет предупреждения.")

/// Новая преграда останавливает уже подготовленную волну.
/datum/unit_test/heretic_echo_closing_obstacle/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	TEST_ASSERT(echo.release(user), "Волна проходит по изначально свободной линии.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, get_step(center, EAST))
	TEST_ASSERT(blocker.density, "Закрытый ящик перекрывает линию.")
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Закрытая после предупреждения линия блокирует удар.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "За преградой нет скрытого урона выносливости.")

/// Открытая после предупреждения линия не добавляет в удар непомеченные клетки.
/datum/unit_test/heretic_echo_opening_obstacle/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, get_step(center, EAST))
	TEST_ASSERT(echo.release(user), "Преграда в одной стороне не отменяет всю волну.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	qdel(blocker)
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Открытие линии не превращает безопасную клетку в непредупреждённый удар.")

/// Волна пропускает союзников и закрытые контейнеры, тратя один заряд антимагии на цель.
/datum/unit_test/heretic_echo_target_protection/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(center, WEST))
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_step(center, SOUTH))
	var/mob/living/hidden = allocate(/mob/living/carbon/human, closet)
	var/mob/living/dead = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	dead.stat = DEAD
	TEST_ASSERT(echo.release(user), "Волна может быть подготовлена рядом с защищёнными целями.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Предупреждение не расходует антимагию.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует ушибы.")
	TEST_ASSERT_EQUAL(protected.getStaminaLoss(), 0, "Антимагия блокирует урон выносливости.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Удар расходует ровно один заряд.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Другой еретик защищён от волны.")
	TEST_ASSERT_EQUAL(hidden.getBruteLoss(), 0, "Волна не поражает содержимое контейнера.")
	TEST_ASSERT_EQUAL(dead.getBruteLoss(), 0, "Волна не атакует трупы.")

/// Сервер отвергает неизученные способности, чужое тело и расход отсутствующего резонанса.
/datum/unit_test/heretic_echo_authority/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/stranger = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/turf/target = get_step(user, EAST)
	TEST_ASSERT(!echo.can_use(stranger), "Чужое тело не владеет знанием.")
	TEST_ASSERT(!echo.release(stranger), "Чужое тело не расходует резонанс владельца.")
	TEST_ASSERT(!echo.refrain(user, target), "Нельзя вызвать неизученный Припев напрямую.")
	TEST_ASSERT(!echo.create_resonator(user, target), "Нельзя создать неизученный резонатор напрямую.")
	TEST_ASSERT(!echo.crescendo(user, target), "Нельзя вызвать неизученное Крещендо напрямую.")
	TEST_ASSERT(!echo.final_chorus(user), "Финал недоступен до вознесения.")
	TEST_ASSERT_EQUAL(echo.combat_resource, initial(echo.combat_resource), "Отказы сохраняют начальный запас.")
	echo.combat_resource = 0
	TEST_ASSERT(!echo.release(user), "Волна требует доступного резонанса.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Отказы не оставляют запланированных атак.")
	TEST_ASSERT_EQUAL(length(echo.resonators), 0, "Отказы не оставляют резонаторов.")

/// Резонаторы ограничены количеством и разрушаются нулевым жезлом.
/datum/unit_test/heretic_echo_resonator_limits/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_resonator)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo.combat_resource = 4
	TEST_ASSERT(echo.create_resonator(user, get_step(center, EAST)), "Первый резонатор создаётся рядом.")
	TEST_ASSERT(echo.create_resonator(user, get_step(center, WEST)), "Второй резонатор создаётся рядом.")
	TEST_ASSERT_EQUAL(length(echo.resonators), 2, "Одновременно поддерживаются два резонатора.")
	var/resource_before = echo.combat_resource
	TEST_ASSERT(!echo.create_resonator(user, get_step(center, NORTH)), "Третий резонатор не обходит лимит.")
	TEST_ASSERT_EQUAL(echo.combat_resource, resource_before, "Отказ по лимиту не расходует резонанс.")
	var/obj/structure/heretic_echo_resonator/resonator = echo.resonators[1]
	var/obj/item/nullrod/nullrod = allocate(/obj/item/nullrod, user)
	resonator.attackby(nullrod, user)
	TEST_ASSERT(QDELETED(resonator), "Прикосновение нулевого жезла уничтожает резонатор.")
	TEST_ASSERT_EQUAL(length(echo.resonators), 1, "Разрушение освобождает место в лимите.")
	TEST_ASSERT(echo.create_resonator(user, get_step(center, NORTH)), "После разрушения можно создать новый резонатор.")

/// Перекрывающиеся отголоски не умножают урон и расход антимагии одного залпа.
/datum/unit_test/heretic_echo_overlapping_resonators/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_resonator)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo.combat_resource = 4
	TEST_ASSERT(echo.create_resonator(user, get_step(center, EAST)), "Первая точка повтора создана.")
	TEST_ASSERT(echo.create_resonator(user, get_step(center, WEST)), "Вторая точка повтора создана.")
	var/mob/living/protected = allocate(/mob/living/carbon/human, center)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/mob/living/victim = allocate(/mob/living/carbon/human, center)
	TEST_ASSERT(echo.release(user), "Один залп захватывает прямую волну и повторы резонаторов.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(protection.charges, 4, "Три перекрывающиеся зоны расходуют один заряд защиты.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Все составляющие залпа заблокированы одной проверкой защиты.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 24) < 0.001, "Попадания одного залпа выбирают сильнейший урон вместо сложения.")

/// Смена тела удаляет старые волны и конструкции, сохраняя прогресс знания.
/datum/unit_test/heretic_echo_body_transfer_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	var/mob/living/user = heretic.owner.current
	heretic.apply_innate_effects(user)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_resonator)
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo.combat_resource = 4
	TEST_ASSERT(echo.create_resonator(user, get_step(user, EAST)), "Прежнее тело создаёт резонатор.")
	TEST_ASSERT(echo.release(user), "Прежнее тело готовит волну.")
	var/obj/structure/heretic_echo_resonator/resonator = echo.resonators[1]
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/list/warnings = attack.warnings.Copy()
	var/obj/effect/proc_holder/spell/old_power = echo.combat_power
	var/old_generation = echo.echo_generation
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(echo.echo_body, new_body, "Знание следует за разумом в новое тело.")
	TEST_ASSERT(echo.echo_generation > old_generation, "Смена тела инвалидирует старую последовательность атак.")
	TEST_ASSERT(QDELETED(resonator) && QDELETED(attack), "Прежние конструкции и атаки удалены.")
	TEST_ASSERT(QDELETED(old_power), "Способность прежнего тела удалена.")
	TEST_ASSERT(echo.combat_power && echo.combat_power != old_power, "Новое тело получает собственный экземпляр способности.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 2, "Смена тела не восстанавливает потраченный резонанс.")
	for(var/obj/effect/warning as anything in warnings)
		TEST_ASSERT(QDELETED(warning), "Предупреждения прежнего тела также удалены.")
	echo.gain_combat_resource()
	TEST_ASSERT(echo.release(new_body), "После перехода можно подготовить новую волну.")
	var/datum/heretic_echo_attack/new_attack = echo.attacks[1]
	qdel(heretic)
	TEST_ASSERT(QDELETED(new_attack), "Удаление роли останавливает волну нового тела.")

/// Смерть снимает эффекты с жертвы, гасит резонаторы и обнуляет запас.
/datum/unit_test/heretic_echo_death_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/echo_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/echo_mark)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_resonator)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/echo_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/echo_grasp)
	var/datum/eldritch_knowledge/echo_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/echo_mark)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE, null), "Хватка оставляет остаточный звон.")
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE, null), "Хватка оставляет метку.")
	TEST_ASSERT(length(echo.ringing) && length(echo.marks), "Знание отслеживает эффекты жертвы.")
	var/list/effects = echo.ringing + echo.marks
	TEST_ASSERT(echo.create_resonator(user, get_step(user, NORTH)), "До смерти создан резонатор.")
	TEST_ASSERT(echo.release(user), "До смерти подготовлен удар.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/obj/structure/heretic_echo_resonator/resonator = echo.resonators[1]
	user.stat = DEAD
	echo.on_death(user)
	TEST_ASSERT(QDELETED(attack) && QDELETED(resonator), "Смерть немедленно останавливает атаки и конструкции.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 0, "Смерть обнуляет резонанс.")
	TEST_ASSERT_EQUAL(length(echo.ringing) + length(echo.marks), 0, "Смерть освобождает списки эффектов.")
	for(var/datum/status_effect/effect as anything in effects)
		TEST_ASSERT(QDELETED(effect), "Каждый эффект умершего источника снят с жертвы.")

/// Настоящий таймер проводит удар после предупреждения и освобождает свои эффекты.
/datum/unit_test/heretic_echo_timer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.anchored = TRUE
	TEST_ASSERT(echo.release(user), "Волна запускается обычным игровым вызовом.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/list/warnings = attack.warnings.Copy()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Урон не предшествует предупреждению.")
	TEST_ASSERT(wait_for_qdeleted(attack, 4 SECONDS), "Настоящий таймер завершает одиночный удар.")
	TEST_ASSERT(victim.getBruteLoss() > 0, "Таймер действительно наносит урон оставшейся цели.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "В списке не остаётся завершённая атака.")
	for(var/obj/effect/warning as anything in warnings)
		TEST_ASSERT(QDELETED(warning), "Таймер снимает предупреждения после удара.")

/// Незавершённые атаки имеют общий предел, а освобождение слота допускает новый залп.
/datum/unit_test/heretic_echo_pending_limit/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	for(var/attack_index in 1 to 4)
		echo.gain_combat_resource()
		TEST_ASSERT(echo.release(user), "В пределах лимита можно подготовить очередную волну.")
	echo.gain_combat_resource()
	var/resource_before = echo.combat_resource
	TEST_ASSERT(!echo.release(user), "Пятая незавершённая атака отклоняется.")
	TEST_ASSERT_EQUAL(echo.combat_resource, resource_before, "Отказ по лимиту не списывает резонанс.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 4, "Отклонённая атака не оставляет таймер или слот.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT(echo.release(user), "Завершённый залп освобождает место для следующего.")

/// Хватка, настоящее попадание и детонация метки пополняют запас без сбора на промахе.
/datum/unit_test/heretic_echo_blade_mark_cycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	for(var/knowledge in list(/datum/eldritch_knowledge/base_echo, /datum/eldritch_knowledge/echo_grasp, /datum/eldritch_knowledge/echo_mark))
		heretic.gain_knowledge(knowledge)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/echo_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/echo_grasp)
	var/datum/eldritch_knowledge/echo_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/echo_mark)
	var/obj/item/melee/sickly_blade/echo/blade = allocate(/obj/item/melee/sickly_blade/echo)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	echo.combat_resource = 0
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE, null), "Хватка попадает по противнику.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 2, "Первая хватка даёт две единицы.")
	grasp.on_mansus_grasp(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(echo.combat_resource, 2, "Повторная хватка в тот же момент не обходит задержку сбора.")
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE, null), "Хватка оставляет метку.")
	blade.afterattack(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(echo.combat_resource, 2, "afterattack без ранения не собирает ресурс.")
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(echo.combat_resource, 4, "Настоящее попадание и активация метки дают по единице.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/echo), "Клинок активирует метку своего пути.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Метка готовит отдельный избегаемый повтор.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/damage_after_melee = victim.getBruteLoss()
	victim.forceMove(get_step(get_step(victim, NORTH), NORTH))
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), damage_after_melee, "Уход с отмеченного места позволяет избежать повторного удара метки.")

/// Камертон меняет будущий рисунок, сохраняя уже показанное предупреждение.
/datum/unit_test/heretic_echo_fork_pattern/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/echo_fork)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/echo_fork/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/echo_fork)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт личный камертон.")
	var/obj/item/heretic_path_relic/echo_fork/fork = recipe.new_path_relic_ref.resolve()
	allocated += fork
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), center), "Второй камертон недоступен, пока существует первый.")
	TEST_ASSERT(!fork.retune(user), "Камертон на полу не переключает рисунок.")
	user.put_in_hands(fork)
	TEST_ASSERT(echo.release(user), "До настройки подготовлен крест.")
	var/datum/heretic_echo_attack/first_attack = echo.attacks[1]
	var/list/old_warnings = first_attack.warnings.Copy()
	TEST_ASSERT(fork.retune(user), "Создатель переключает рисунок в руке.")
	TEST_ASSERT(echo.diagonal_echo, "Новый рисунок идёт по диагоналям.")
	TEST_ASSERT(!fork.retune(user), "Повторная настройка ограничена перезарядкой.")
	TEST_ASSERT_EQUAL(length(first_attack.warnings - old_warnings), 0, "Старая волна сохраняет свои предупреждения.")
	var/mob/living/cardinal = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/mob/living/diagonal = allocate(/mob/living/carbon/human, get_step(center, NORTHEAST))
	first_attack.resolve()
	TEST_ASSERT(cardinal.getBruteLoss() > 0 && diagonal.getBruteLoss() == 0, "Первая волна остаётся крестом после настройки.")
	echo.gain_combat_resource()
	var/cardinal_damage = cardinal.getBruteLoss()
	TEST_ASSERT(echo.release(user), "Следующая волна использует новый рисунок.")
	var/datum/heretic_echo_attack/second_attack = echo.attacks[1]
	second_attack.resolve()
	TEST_ASSERT(diagonal.getBruteLoss() > 0, "Новая волна поражает диагональную клетку.")
	TEST_ASSERT_EQUAL(cardinal.getBruteLoss(), cardinal_damage, "Новая волна не поражает прежний крест.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(center, SOUTH))
	other.selected_path = PATH_ECHO
	other.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	other.gain_knowledge(/datum/eldritch_knowledge/echo_fork)
	user.dropItemToGround(fork, TRUE)
	other.owner.current.put_in_hands(fork)
	COOLDOWN_RESET(fork, relic_cooldown)
	TEST_ASSERT(!fork.retune(other.owner.current), "Другой еретик не настраивает чужой камертон.")

/// Разрушенный после предупреждения резонатор не выпускает свой повтор.
/datum/unit_test/heretic_echo_destroyed_relay/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_resonator)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo.combat_resource = 4
	TEST_ASSERT(echo.create_resonator(user, get_step(center, NORTHEAST)), "Резонатор создаётся вне прямого креста.")
	var/obj/structure/heretic_echo_resonator/resonator = echo.resonators[1]
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_turf(resonator))
	TEST_ASSERT(echo.release(user), "Волна готовит повтор резонатора.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/warned_victim = FALSE
	for(var/obj/effect/warning as anything in attack.warnings)
		if(warning.loc == victim.loc)
			warned_victim = TRUE
	TEST_ASSERT(warned_victim, "Точка резонатора действительно была включена в предупреждение.")
	qdel(resonator)
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Разрушение отменяет подготовленный повтор, не оставляя невидимого урона.")

/// Крещендо чередует три предупреждённых рисунка вокруг неизменной точки.
/datum/unit_test/heretic_echo_crescendo_sequence/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_crescendo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo.combat_resource = 4
	TEST_ASSERT(echo.crescendo(user, center), "Крещендо запускает последовательность.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 0, "Крещендо расходует весь запас.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/list/warnings = attack.warnings.Copy()
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, NORTHEAST))
	var/mob/living/staying = allocate(/mob/living/carbon/human, get_step(center, EAST))
	user.forceMove(get_step(center, SOUTHWEST))
	attack.resolve()
	TEST_ASSERT(abs(staying.getBruteLoss() - 26) < 0.001, "Оставшаяся на кресте цель получает рассчитанный урон первого такта.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "На первом такте безопасна диагональ.")
	TEST_ASSERT_EQUAL(attack.pulse_index, 2, "После креста начинается предупреждение диагоналей.")
	for(var/obj/effect/warning as anything in warnings)
		TEST_ASSERT(QDELETED(warning), "Предыдущие предупреждения сменяются новым рисунком.")
	TEST_ASSERT(length(attack.warnings), "Второй такт имеет собственное предупреждение.")
	victim.forceMove(get_step(center, EAST))
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "На втором такте можно уйти с диагонали на прямую.")
	TEST_ASSERT_EQUAL(attack.pulse_index, 3, "Третий такт предупреждает внешнее кольцо.")
	victim.forceMove(center)
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Центр безопасен от внешнего кольца.")
	TEST_ASSERT(QDELETED(attack), "Три такта завершают последовательность.")

/// Полный запас пассивки и вознесения сохраняется при переносе разума.
/datum/unit_test/heretic_echo_capacity_transfer/Run()
	for(var/ascended in list(FALSE, TRUE))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		heretic.selected_path = PATH_ECHO
		var/mob/living/old_body = heretic.owner.current
		heretic.apply_innate_effects(old_body)
		heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
		heretic.gain_knowledge(/datum/eldritch_knowledge/echo_sustain)
		var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
		var/datum/eldritch_knowledge/echo_sustain/sustain = heretic.get_knowledge(/datum/eldritch_knowledge/echo_sustain)
		sustain.passive_level = 3
		sustain.on_passive_upgrade(old_body)
		TEST_ASSERT_EQUAL(echo.combat_resource, initial(echo.combat_resource), "Расширение вместимости не начисляет резонанс.")
		if(ascended)
			heretic.ascended = TRUE
			heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
			var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
			finale.finished = TRUE
			finale.on_body_gain(old_body)
		var/expected_max = ascended ? 8 : 7
		TEST_ASSERT_EQUAL(echo.combat_resource_max, expected_max, "Полный предел учитывает пассивку и вознесение.")
		echo.gain_combat_resource(20)
		var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
		heretic.owner.transfer_to(new_body, TRUE)
		TEST_ASSERT_EQUAL(echo.echo_body, new_body, "Путь следует за новым телом.")
		TEST_ASSERT_EQUAL(echo.combat_resource, expected_max, "Временное снятие сил не отрезает накопленный запас.")
		TEST_ASSERT_EQUAL(echo.combat_resource_max, expected_max, "Новое тело сохраняет полный предел.")
		TEST_ASSERT_EQUAL(sustain.passive_level, 3, "Перенос сохраняет уровень пассивки.")
		qdel(heretic)

/// Снятие роли обработчиком смерти жертвы немедленно обрывает оставшийся залп.
/datum/unit_test/heretic_echo_damage_cleanup
	var/datum/antagonist/heretic/role_to_remove

/datum/unit_test/heretic_echo_damage_cleanup/proc/on_victim_death(datum/source)
	SIGNAL_HANDLER
	QDEL_NULL(role_to_remove)

/datum/unit_test/heretic_echo_damage_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	role_to_remove = heretic
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/turf/target_tile = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, target_tile)
	victim.setToxLoss(victim.health - (HEALTH_THRESHOLD_DEAD + 5), forced = TRUE)
	TEST_ASSERT(victim.stat != DEAD, "Первая жертва пока жива.")
	RegisterSignal(victim, COMSIG_MOB_DEATH, PROC_REF(on_victim_death))
	var/mob/living/bystander = allocate(/mob/living/carbon/human, target_tile)
	TEST_ASSERT(echo.release(user), "Перед снятием роли подготовлен настоящий залп.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "Урон первой цели запускает обработчик смерти.")
	TEST_ASSERT(QDELETED(heretic) && QDELETED(attack), "Обработчик удаляет роль вместе с атакой.")
	TEST_ASSERT_EQUAL(bystander.getBruteLoss(), 0, "После удаления источника залп не ранит следующую цель.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_ringing), "Удалённый источник не оставляет новый статус после урона.")
	UnregisterSignal(victim, COMSIG_MOB_DEATH)

/// Знания безопасно снимаются без тела после удаления разума.
/datum/unit_test/heretic_echo_unbound_cleanup/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ECHO]
	for(var/knowledge_type in path.knowledge)
		var/datum/eldritch_knowledge/knowledge = allocate(knowledge_type)
		knowledge.on_lose(null)
		qdel(knowledge)
		TEST_ASSERT(QDELETED(knowledge), "Знание [knowledge_type] удаляется без владельца и незавершённых эффектов.")

/// Припев наносит первый удар сразу, а от отмеченного повтора можно уйти.
/datum/unit_test/heretic_echo_refrain_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/turf/center = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, center)
	var/mob/living/nearby = allocate(/mob/living/carbon/human, get_step(center, EAST))
	echo.combat_resource = 0
	TEST_ASSERT(echo.refrain(user, center), "Припев работает без резонанса и предварительной метки.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) < 0.01, "Цель получает первый удар сразу.")
	TEST_ASSERT_EQUAL(nearby.getBruteLoss(), 0, "Соседняя клетка получает только предупреждение.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 1, "Первый удар возвращает резонанс для базовой волны.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT_EQUAL(attack.pulse_index, 2, "После первого удара остаётся отдельный повтор.")
	TEST_ASSERT(length(attack.warnings), "Повтор отмечен на полу.")
	victim.forceMove(get_step(center, NORTHEAST))
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) < 0.01, "Выход на диагональ позволяет избежать повтора.")
	TEST_ASSERT(abs(nearby.getBruteLoss() - 22) < 0.01, "Оставшийся в кресте противник получает полный повтор.")
	TEST_ASSERT(QDELETED(attack), "Два такта полностью освобождают атаку.")

/// Первый удар и повтор отдельно проверяют антимагию и исключают союзников.
/datum/unit_test/heretic_echo_refrain_protection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/echo_refrain)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/turf/center = get_step(user, EAST)
	var/mob/living/protected = allocate(/mob/living/carbon/human, center)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/antagonist/heretic/ally = allocate_heretic(center)
	TEST_ASSERT(echo.refrain(user, center), "Припев запускается по клетке с защищёнными целями.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Первый удар расходует один заряд защиты.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(protection.charges, 3, "Повтор расходует ещё один заряд за удар.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss() + protected.getStaminaLoss(), 0, "Оба удара заблокированы антимагией.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Оба удара пропускают союзника.")

/// Пустой запас восстанавливает базовую атаку, но не накапливает бесплатный полный залп.
/datum/unit_test/heretic_echo_empty_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	TEST_ASSERT_EQUAL(echo.combat_resource, 2, "Начальный запас даёт две попытки базовой атаки.")
	echo.combat_resource = 0
	COOLDOWN_RESET(echo, ascended_resonance)
	echo.on_life(user)
	TEST_ASSERT_EQUAL(echo.combat_resource, 1, "Пустой запас получает одну единицу.")
	COOLDOWN_RESET(echo, ascended_resonance)
	echo.on_life(user)
	TEST_ASSERT_EQUAL(echo.combat_resource, 1, "Обычное восстановление не заполняет весь запас.")
	echo.combat_resource = 0
	user.stat = UNCONSCIOUS
	COOLDOWN_RESET(echo, ascended_resonance)
	echo.on_life(user)
	TEST_ASSERT_EQUAL(echo.combat_resource, 0, "Недееспособный владелец не восстанавливает боевой запас.")

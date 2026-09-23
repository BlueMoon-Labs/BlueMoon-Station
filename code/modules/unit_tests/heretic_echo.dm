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
	TEST_ASSERT_EQUAL(echo.combat_resource, initial(echo.combat_resource), "Первый удар возвращает потраченную единицу резонанса.")
	TEST_ASSERT(abs(staying.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Сплошная первая волна поражает цель сразу.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Волна хранится как одна отложенная атака.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT(length(attack.warnings), "Каждая запланированная волна имеет видимое предупреждение.")
	var/list/warnings = attack.warnings.Copy()
	dodging.forceMove(get_step(center, NORTHEAST))
	user.forceMove(get_step(center, SOUTHWEST))
	attack.resolve()
	TEST_ASSERT(abs(staying.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Оставшийся на прежней клетке получает первый удар и сильный повтор.")
	TEST_ASSERT(abs(dodging.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Ушедший на диагональ избегает сильного повтора.")
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
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Закрытая после первого удара линия блокирует сильный повтор.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 10) <= DAMAGE_PRECISION, "Преграда блокирует урон выносливости повторного такта.")

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
	TEST_ASSERT_EQUAL(protection.charges, 4, "Первая волна тратит один заряд; предупреждение повтора не тратит следующий.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует ушибы.")
	TEST_ASSERT_EQUAL(protected.getStaminaLoss(), 0, "Антимагия блокирует урон выносливости.")
	TEST_ASSERT_EQUAL(protection.charges, 3, "Каждый из двух тактов расходует ровно один заряд.")
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
	TEST_ASSERT_EQUAL(protection.charges, 3, "Три перекрывающиеся зоны повтора расходуют один заряд после заряда первой волны.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Все составляющие залпа заблокированы одной проверкой защиты.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Первый удар и повтор наносят 36; перекрытия повторов не складываются.")

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
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Первый такт ударяет сразу, пока сильный повтор ещё предупреждает.")
	TEST_ASSERT(wait_for_qdeleted(attack, 4 SECONDS), "Настоящий таймер завершает одиночный удар.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Таймер действительно добавляет сильный повтор к первому удару.")
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
	TEST_ASSERT(abs(diagonal.getBruteLoss() - 36) <= DAMAGE_PRECISION, "После настройки диагональная цель получает и первую волну, и сильный повтор.")
	TEST_ASSERT(abs(cardinal.getBruteLoss() - cardinal_damage - 12) <= DAMAGE_PRECISION, "После настройки сплошной первый такт остаётся, но диагональный повтор не поражает прежний крест.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(center, SOUTH))
	other.selected_path = PATH_ECHO
	other.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	other.gain_knowledge(/datum/eldritch_knowledge/echo_fork)
	user.dropItemToGround(fork, TRUE)
	other.owner.current.put_in_hands(fork)
	COOLDOWN_RESET(fork, relic_cooldown)
	TEST_ASSERT(!fork.retune(other.owner.current), "Другой еретик не настраивает чужой камертон.")

/// Удержанный повтор сохраняет рисунок, заново предупреждает и не продолжает диссонанс.
/datum/unit_test/heretic_echo_held_repeat/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/echo_fork)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/echo_fork/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/echo_fork)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт лиру.")
	var/obj/item/heretic_path_relic/echo_fork/fork = recipe.new_path_relic_ref.resolve()
	allocated += fork
	TEST_ASSERT(!fork.hold_echo(user), "Лира на полу не готовит удержание.")
	user.put_in_hands(fork)
	TEST_ASSERT(fork.AltClick(user), "Alt-клик готовит задержку следующего повтора.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	TEST_ASSERT(echo.release(user), "Последний удар запускается с удержанием.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT(attack.held && !echo.hold_next_repeat, "Удержание применяется только к одному повтору.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Первая волна всё равно наносит немедленный урон.")
	TEST_ASSERT(!attack.resolve(), "Удержанный повтор нельзя выпустить без нового предупреждения.")
	TEST_ASSERT(fork.AltClick(user), "Выпуск доступен во время перезарядки настройки.")
	TEST_ASSERT(!attack.held && length(attack.warnings), "Выпуск снова показывает предупреждение.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Само отпускание не наносит урона.")
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Задержка сохраняет исходный урон двух волн.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_dissonance), "Задержанный такт не продлевает контроль первой волны.")
	COOLDOWN_RESET(fork, relic_cooldown)
	TEST_ASSERT(fork.hold_echo(user) && echo.release(user), "Можно подготовить следующий задержанный повтор.")
	var/datum/heretic_echo_attack/pending = echo.attacks[1]
	qdel(recipe)
	TEST_ASSERT(QDELETED(pending), "Потеря лиры как знания отменяет удержанный звук.")
	TEST_ASSERT(!echo.hold_next_repeat, "Потеря знания очищает подготовку.")

/// Удержание само заканчивается и всё равно оставляет время на уклонение.
/datum/unit_test/heretic_echo_held_timer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	echo.hold_next_repeat = TRUE
	TEST_ASSERT(echo.release(user), "Подготавливается задержанный повтор.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	var/datum/weakref/attack_ref = WEAKREF(attack)
	sleep(3.1 SECONDS)
	attack = attack_ref.resolve()
	TEST_ASSERT(attack && !attack.held && length(attack.warnings), "Через три секунды таймер выпускает новое предупреждение.")
	TEST_ASSERT(wait_for_qdeleted(attack, 2 SECONDS), "Предупреждённый повтор завершается своим таймером.")

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
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Разрушение отменяет подготовленный повтор; остаётся только урон первой волны.")

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
	var/mob/living/outer = allocate(/mob/living/carbon/human, get_step(get_step(get_step(center, EAST), EAST), EAST))
	user.forceMove(get_step(center, SOUTHWEST))
	attack.resolve()
	TEST_ASSERT(abs(staying.getBruteLoss() - 26) < 0.001, "Оставшаяся на кресте цель получает рассчитанный урон первого такта.")
	TEST_ASSERT(abs(outer.getBruteLoss() - 26) <= DAMAGE_PRECISION, "Крещендо достигает третьей клетки первым тактом.")
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
	TEST_ASSERT(abs(outer.getBruteLoss() - 52) <= DAMAGE_PRECISION, "Последнее кольцо Крещендо проходит по третьему радиусу.")
	TEST_ASSERT(QDELETED(attack), "Три такта завершают последовательность.")

/// Лира выбирает один узел; поздние волны сохраняют выбор и не умножают урон пересечений.
/datum/unit_test/heretic_echo_conductor/Run()
	var/turf/center = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	for(var/knowledge in list(/datum/eldritch_knowledge/base_echo, /datum/eldritch_knowledge/spell/echo_resonator, /datum/eldritch_knowledge/echo_fork, /datum/eldritch_knowledge/spell/echo_crescendo))
		heretic.gain_knowledge(knowledge)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/echo_fork/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/echo_fork)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Создаётся личная лира.")
	var/obj/item/heretic_path_relic/echo_fork/fork = recipe.new_path_relic_ref.resolve()
	allocated += fork
	user.put_in_hands(fork)
	echo.combat_resource = 4
	TEST_ASSERT(echo.create_resonator(user, get_step(get_step(center, EAST), EAST)), "Первый узел размещается справа.")
	TEST_ASSERT(echo.create_resonator(user, get_step(get_step(center, NORTH), NORTH)), "Второй узел размещается сверху.")
	var/obj/structure/heretic_echo_resonator/first = echo.resonators[1]
	var/obj/structure/heretic_echo_resonator/second = echo.resonators[2]
	TEST_ASSERT(fork.afterattack(first, user, FALSE), "Лира выбирает собственный удалённый узел.")
	var/mob/living/relayed = allocate(/mob/living/carbon/human, get_step(get_step(first, EAST), EAST))
	var/mob/living/unselected = allocate(/mob/living/carbon/human, get_step(get_step(second, NORTH), NORTH))
	TEST_ASSERT(isfloorturf(relayed.loc) && isfloorturf(unselected.loc), "Обе удалённые цели остаются внутри тестовой комнаты.")
	var/mob/living/overlap = allocate(/mob/living/carbon/human, get_step(center, EAST))
	echo.combat_resource = 4
	TEST_ASSERT(echo.crescendo(user, center), "Крещендо готовит поздний повтор.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 0, "Резонатор не меняет расход Крещендо.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT(fork.afterattack(second, user, FALSE), "Можно выбрать другой узел для следующего заклинания.")
	attack.resolve()
	TEST_ASSERT(abs(relayed.getBruteLoss() - 26) <= DAMAGE_PRECISION, "Уже предупреждённая волна звучит у первоначального узла.")
	TEST_ASSERT_EQUAL(unselected.getBruteLoss(), 0, "Новый выбор не переносит уже подготовленную волну.")
	TEST_ASSERT(abs(overlap.getBruteLoss() - 26) <= DAMAGE_PRECISION, "Пересечение основного креста и узла наносит только один такт.")
	qdel(attack)
	TEST_ASSERT(fork.afterattack(first, user, FALSE), "Выбор возвращается к первому узлу.")
	echo.combat_resource = 4
	TEST_ASSERT(echo.crescendo(user, center), "Вторая последовательность готовится до разрушения.")
	attack = echo.attacks[1]
	qdel(first)
	TEST_ASSERT_NULL(echo.conductor_ref, "Разрушение убирает выбранный узел.")
	attack.resolve()
	TEST_ASSERT(abs(relayed.getBruteLoss() - 26) <= DAMAGE_PRECISION, "Разрушенный узел не наносит подготовленный урон.")
	TEST_ASSERT(abs(overlap.getBruteLoss() - 52) <= DAMAGE_PRECISION, "Основная область сохраняется при разрушении узла.")
	qdel(attack)
	TEST_ASSERT(fork.afterattack(second, user, FALSE), "Оставшийся узел доступен для финала.")
	heretic.ascended = TRUE
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	finale.finished = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT(echo.final_chorus(user), "Последняя служба подхватывает выбранный узел.")
	attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT_EQUAL(unselected.getBruteLoss(), 0, "Второе кольцо не наносит урон до своего предупреждения.")
	attack.resolve()
	TEST_ASSERT(abs(unselected.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Второе кольцо финала доходит через выбранный узел.")
	qdel(attack)
	qdel(recipe)
	TEST_ASSERT_NULL(echo.conductor_ref, "Утрата знания лиры снимает выбор узла.")

/// Волны Последней службы перекрываются: стоящая рядом цель получает два удара подряд.
/datum/unit_test/heretic_echo_final_bands/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	var/mob/living/near = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/mob/living/far = allocate(/mob/living/carbon/human, locate(center.x - 3, center.y, center.z))
	TEST_ASSERT(isfloorturf(far.loc), "Дальняя цель стоит на полу комнаты.")
	TEST_ASSERT(echo.final_chorus(user), "Вознесённый еретик начинает Последнюю службу.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(near.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Первая волна накрывает соседнюю клетку.")
	attack.resolve()
	TEST_ASSERT(abs(near.getBruteLoss() - 64) <= DAMAGE_PRECISION, "Вторая волна снова задевает цель на расстоянии одной клетки.")
	TEST_ASSERT_EQUAL(far.getBruteLoss(), 0, "Дальняя цель ещё вне первых двух волн.")
	attack.resolve()
	TEST_ASSERT(abs(near.getBruteLoss() - 64) <= DAMAGE_PRECISION, "Третья волна не достаёт до соседней клетки.")
	TEST_ASSERT(abs(far.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Третья волна накрывает третью клетку.")
	TEST_ASSERT(QDELETED(attack), "Три волны завершают службу.")

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
	for(var/immediate in list(TRUE, FALSE))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		heretic.selected_path = PATH_ECHO
		heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
		role_to_remove = heretic
		var/mob/living/user = heretic.owner.current
		var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
		var/turf/target_tile = get_step(user, EAST)
		var/mob/living/victim = allocate(/mob/living/carbon/human, target_tile)
		var/mob/living/bystander = allocate(/mob/living/carbon/human, target_tile)
		if(immediate)
			victim.setToxLoss(victim.health - (HEALTH_THRESHOLD_DEAD + 5), forced = TRUE)
		RegisterSignal(victim, COMSIG_MOB_DEATH, PROC_REF(on_victim_death))
		TEST_ASSERT(echo.release(user), "Запускается настоящая звуковая волна.")
		var/datum/heretic_echo_attack/attack
		if(!immediate)
			attack = echo.attacks[1]
			victim.setToxLoss(victim.getToxLoss() + victim.health - (HEALTH_THRESHOLD_DEAD + 5), forced = TRUE)
			attack.resolve()
		TEST_ASSERT_EQUAL(victim.stat, DEAD, "Урон первой цели запускает обработчик смерти.")
		TEST_ASSERT(QDELETED(heretic), "Обработчик удаляет роль.")
		TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Удалённый источник не оставляет ни текущий, ни отложенный такт.")
		if(attack)
			TEST_ASSERT(QDELETED(attack), "Удаление роли отменяет уже подготовленный повтор.")
		TEST_ASSERT(abs(bystander.getBruteLoss() - (immediate ? 0 : 12)) <= DAMAGE_PRECISION, "После удаления источника текущий такт не ранит следующую цель.")
		TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_echo_ringing), "Удалённый источник не оставляет новый статус после урона.")
		UnregisterSignal(victim, COMSIG_MOB_DEATH)
		qdel(victim)
		qdel(bystander)

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
	var/mob/living/diagonal = allocate(/mob/living/carbon/human, get_step(center, NORTHEAST))
	echo.combat_resource = 0
	TEST_ASSERT(echo.refrain(user, center), "Припев работает без резонанса и предварительной метки.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) < 0.01, "Цель получает первый удар сразу.")
	TEST_ASSERT(abs(nearby.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Широкий первый такт поражает и соседнюю клетку.")
	TEST_ASSERT(abs(diagonal.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Припев покрывает и диагонали выбранной области 3×3.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 1, "Первый удар возвращает резонанс для базовой волны.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT_EQUAL(attack.pulse_index, 2, "После первого удара остаётся отдельный повтор.")
	TEST_ASSERT(length(attack.warnings), "Повтор отмечен на полу.")
	victim.forceMove(get_step(center, NORTHEAST))
	attack.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) < 0.01, "Выход на диагональ позволяет избежать повтора.")
	TEST_ASSERT(abs(nearby.getBruteLoss() - 40) <= DAMAGE_PRECISION, "Оставшийся в кресте получает первый удар и полный повтор.")
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

/// Сплошной первый такт покрывает края области, а расширенный повтор наказывает оставшегося в трёх клетках.
/datum/unit_test/heretic_echo_wide_opening/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/side = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), NORTHEAST))
	var/mob/living/corner = allocate(/mob/living/carbon/human, get_step(get_step(center, NORTHEAST), NORTHEAST))
	var/mob/living/outer = allocate(/mob/living/carbon/human, get_step(get_step(get_step(center, EAST), EAST), EAST))
	TEST_ASSERT(echo.release(user), "Звуковая волна работает без резонаторов и лиры.")
	TEST_ASSERT(abs(side.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Первый такт покрывает край вне креста и диагоналей.")
	TEST_ASSERT(abs(corner.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Первый такт покрывает угол области 5×5.")
	TEST_ASSERT_EQUAL(outer.getBruteLoss(), 0, "Сильный дальний отзвук ещё не ударил.")
	TEST_ASSERT_EQUAL(echo.combat_resource, 2, "Несколько целей возвращают только одну потраченную единицу.")
	side.forceMove(get_step(center, SOUTHEAST))
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(side.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Подвижная цель может избежать сильного повтора.")
	TEST_ASSERT(abs(outer.getBruteLoss() - 24) <= DAMAGE_PRECISION, "Отзвук достигает третьей клетки.")
	TEST_ASSERT(!HAS_TRAIT(outer, TRAIT_MOBILITY_NOUSE), "Попадание только отзвука не вызывает контузию.")

/// Стена и закрытый диагональный угол гасят широкую первую волну без утечки на край области.
/datum/unit_test/heretic_echo_wide_opening_walls/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/obj/blocker = allocate(/obj, get_step(center, EAST))
	blocker.density = TRUE
	var/mob/living/behind = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	var/mob/living/corner = allocate(/mob/living/carbon/human, get_step(get_step(center, NORTHEAST), NORTHEAST))
	var/mob/living/open = allocate(/mob/living/carbon/human, get_step(get_step(center, NORTH), NORTH))
	TEST_ASSERT(echo.release(user), "Свободная часть области принимает звуковую волну.")
	TEST_ASSERT_EQUAL(behind.getBruteLoss(), 0, "Плотная преграда блокирует прямой участок первой волны.")
	TEST_ASSERT_EQUAL(corner.getBruteLoss(), 0, "Первая волна не просачивается через закрытый диагональный угол.")
	TEST_ASSERT(abs(open.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Открытая часть области получает полезный первый удар.")
	TEST_ASSERT(!corner.has_status_effect(/datum/status_effect/heretic_echo_ringing), "За закрытым углом нет скрытого Остаточного звона.")

/// Контузия останавливает одиночный выстрел, продолжение очереди и автоогонь без расхода патронов.
/datum/unit_test/heretic_echo_gun_interruption/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/mob/living/shooter = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/gun/ballistic/automatic/c20r/unrestricted/gun = allocate(/obj/item/gun/ballistic/automatic/c20r/unrestricted, get_turf(shooter))
	TEST_ASSERT(shooter.put_in_active_hand(gun), "Стрелок держит заряженное оружие.")
	gun.burst_size = 1
	var/turf/target = get_step(get_step(shooter, EAST), EAST)
	var/ammo_before = gun.get_ammo()
	TEST_ASSERT(ammo_before > 2, "Оружие действительно заряжено.")
	gun.last_fire = world.time - gun.fire_delay - 1
	gun.process_fire(target, shooter)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo_before - 1, "Без контузии настоящий выстрел расходует патрон.")
	ammo_before = gun.get_ammo()
	var/datum/status_effect/heretic_echo_dissonance/dissonance = shooter.apply_status_effect(/datum/status_effect/heretic_echo_dissonance, echo)
	TEST_ASSERT(!QDELETED(dissonance), "Стрелок получает контузию.")
	gun.last_fire = world.time - gun.fire_delay - 1
	gun.process_fire(target, shooter)
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo_before, "Контузия останавливает прямой вызов стрельбы, включая отложенный выстрел второй руки.")
	gun.firing = TRUE
	TEST_ASSERT(!gun.do_burst_shot(shooter, target, iteration = 2), "Контузия обрывает уже начатую очередь.")
	TEST_ASSERT(!gun.firing, "Очередь не остаётся активной.")
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo_before, "Прерванная очередь сохраняет патроны.")
	var/datum/component/automatic_fire/automatic = gun.GetComponent(/datum/component/automatic_fire)
	if(!automatic)
		automatic = gun.AddComponent(/datum/component/automatic_fire)
	automatic.shooter = shooter
	automatic.target = target
	automatic.target_loc = target
	automatic.autofire_stat = AUTOFIRE_STAT_FIRING
	var/shot_result = automatic.process_shot()
	automatic.autofire_stat = AUTOFIRE_STAT_IDLE
	TEST_ASSERT(!shot_result, "Автоогонь приостанавливает выстрелы на время контузии.")
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo_before, "Автоогонь не расходует патроны во время контузии.")
	TEST_ASSERT(shooter.is_holding(gun), "Прерывание стрельбы не выбивает оружие из рук.")
	qdel(dissonance)
	shot_result = gun.do_autofire(gun, target, shooter, null)
	TEST_ASSERT(shot_result, "После контузии автоогонь снова выпускает выстрел.")
	TEST_ASSERT_EQUAL(gun.get_ammo(), ammo_before - 1, "После восстановления настоящий выстрел расходует патрон.")

/datum/unit_test/proc/ascend_echo_fixture(turf/center)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_ECHO
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_echo)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/echo_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return list("center" = center, "user" = user, "heretic" = heretic, "finale" = finale, "echo" = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo))

/datum/unit_test/proc/echo_test_bullet(atom/firer, damage)
	var/obj/item/projectile/bullet/bullet = allocate(/obj/item/projectile/bullet, get_turf(firer))
	bullet.damage = damage
	bullet.damage_type = BRUTE
	bullet.firer = firer
	bullet.starting = get_turf(firer)
	return bullet

/// Попадание по вознёсшемуся Эху отвечает отложенным крестом вокруг него; откат, слабые, свои и союзные удары отзвука не дают.
/datum/unit_test/heretic_echo_reprise/Run()
	var/list/fixture = ascend_echo_fixture(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/turf/center = fixture["center"]
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_echo/echo = fixture["echo"]
	var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = fixture["finale"]
	var/datum/component/heretic_echo_reprise/reprise = user.GetComponent(/datum/component/heretic_echo_reprise)
	TEST_ASSERT_NOTNULL(reprise, "Вознесение Эха даёт отзвук.")
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	var/mob/living/carbon/human/diagonal = allocate(/mob/living/carbon/human, get_step(center, NORTHEAST))
	user.bullet_act(echo_test_bullet(shooter, 20), BODY_ZONE_CHEST)
	TEST_ASSERT(user.getBruteLoss() > HERETIC_ECHO_REPRISE_MIN_DAMAGE, "Пуля ранит вознёсшегося.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Попадание запускает отзвук.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT(length(attack.warnings), "Отзвук заранее отмечает крест.")
	user.bullet_act(echo_test_bullet(shooter, 20), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Второе попадание в пределах двух секунд отзвука не даёт.")
	attack.resolve()
	TEST_ASSERT(abs(shooter.getBruteLoss() - HERETIC_ECHO_REPRISE_DAMAGE) <= DAMAGE_PRECISION, "Стрелок на кресте получает 15 ушибов.")
	TEST_ASSERT(abs(shooter.getStaminaLoss() - HERETIC_ECHO_REPRISE_STAMINA) <= DAMAGE_PRECISION, "Стрелок на кресте получает 15 урона выносливости.")
	TEST_ASSERT_EQUAL(diagonal.getBruteLoss(), 0, "Диагональ вне креста.")
	TEST_ASSERT(QDELETED(attack), "Отзвук звучит один раз.")
	COOLDOWN_RESET(reprise, reprise_cooldown)
	user.bullet_act(echo_test_bullet(shooter, HERETIC_ECHO_REPRISE_MIN_DAMAGE), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Слабое попадание отзвука не даёт.")
	user.bullet_act(echo_test_bullet(user, 20), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Собственный выстрел отзвука не даёт.")
	var/datum/antagonist/heretic/ally_heretic = allocate_heretic(get_step(center, NORTH))
	user.bullet_act(echo_test_bullet(ally_heretic.owner.current, 20), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Союзный еретик отзвука не вызывает.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_echo_reprise), "Потеря тела снимает отзвук.")

/// Слабость отзвука: дальние стрелки и те, кого закрывает преграда, не страдают.
/datum/unit_test/heretic_echo_reprise_weakness/Run()
	var/list/fixture = ascend_echo_fixture(run_loc_floor_bottom_left)
	var/turf/center = fixture["center"]
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_echo/echo = fixture["echo"]
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, locate(center.x, center.y + HERETIC_ECHO_REPRISE_RADIUS + 1, center.z))
	var/mob/living/carbon/human/covered = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	var/mob/living/carbon/human/open = allocate(/mob/living/carbon/human, get_step(center, SOUTH))
	allocate(/obj/structure/closet/crate, get_step(center, EAST))
	user.bullet_act(echo_test_bullet(far, 20), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Дальний выстрел тоже запускает отзвук.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT(isfloorturf(far.loc), "Дальний стрелок стоит на полу комнаты.")
	TEST_ASSERT_EQUAL(far.getBruteLoss(), 0, "Стрелок дальше трёх клеток вне отзвука.")
	TEST_ASSERT_EQUAL(covered.getBruteLoss(), 0, "Преграда глушит отзвук.")
	TEST_ASSERT(abs(open.getBruteLoss() - HERETIC_ECHO_REPRISE_DAMAGE) <= DAMAGE_PRECISION, "Открытая линия креста поражается.")
	var/list/examine_lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, far, examine_lines)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "издалека"), "Осмотр называет слабость отзвука.")

/datum/unit_test/heretic_echo_reprise_consumed
	var/block_hits = FALSE

/datum/unit_test/heretic_echo_reprise_consumed/proc/block_attack(datum/source)
	SIGNAL_HANDLER
	return block_hits ? BLOCK_SUCCESS : BLOCK_NONE

/// Заблокированное или слабое попадание не превращает постороннюю потерю здоровья в том же тике в отзвук.
/datum/unit_test/heretic_echo_reprise_consumed/Run()
	var/list/fixture = ascend_echo_fixture(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/turf/center = fixture["center"]
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_echo/echo = fixture["echo"]
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	RegisterSignal(user, COMSIG_LIVING_RUN_BLOCK, PROC_REF(block_attack))
	block_hits = TRUE
	user.bullet_act(echo_test_bullet(shooter, 20), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Заблокированная пуля не ранит.")
	user.adjustBruteLoss(20)
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Урон после заблокированного попадания отзвука не даёт.")
	block_hits = FALSE
	user.bullet_act(echo_test_bullet(shooter, HERETIC_ECHO_REPRISE_MIN_DAMAGE), BODY_ZONE_CHEST)
	user.adjustBruteLoss(20)
	TEST_ASSERT_EQUAL(length(echo.attacks), 0, "Урон после слабого попадания отзвука не даёт.")
	user.bullet_act(echo_test_bullet(shooter, 20), BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Настоящее попадание после них запускает отзвук.")
	UnregisterSignal(user, COMSIG_LIVING_RUN_BLOCK)

/// Отзвук молчит, пока герой не может действовать или все такты уже заняты.
/datum/unit_test/heretic_echo_reprise_guards/Run()
	var/list/fixture = ascend_echo_fixture(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST))
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_echo/echo = fixture["echo"]
	var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = fixture["finale"]
	user.Paralyze(10 SECONDS, ignore_canstun = TRUE)
	TEST_ASSERT(user.incapacitated(), "Парализованный еретик не способен действовать.")
	TEST_ASSERT(!echo.reprise(user, finale), "Беспомощный еретик не отвечает отзвуком.")
	user.SetParalyzed(0)
	var/started = 0
	while(started < 10 && echo.reprise(user, finale))
		started++
	TEST_ASSERT(started > 0 && started < 10, "Отзвуки упираются в предел одновременных тактов, а не звучат без конца.")
	TEST_ASSERT_EQUAL(length(echo.attacks), started, "Отказ сверх предела не создаёт лишних тактов.")

/// Кольца отзвука из прошлых тестов догорают, прежде чем считать новые; клетка теста своя, чужие отложенные кольца на неё не падают.
/datum/unit_test/proc/drain_echo_rings(turf/center)
	var/list/budget = new_wait_budget(2 SECONDS, "старые кольца отзвука")
	while(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in center)
		if(!wait_budget_tick(budget))
			return FALSE
	return TRUE

/// Отзвук расходится от героя золотыми кольцами одно за другим, затем звучит прежний крест.
/datum/unit_test/heretic_echo_reprise_rings/Run()
	var/list/fixture = ascend_echo_fixture(get_step(run_loc_floor_bottom_left, NORTH))
	var/turf/center = fixture["center"]
	TEST_ASSERT(drain_echo_rings(center), "Старые кольца догорели.")
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_echo/echo = fixture["echo"]
	var/datum/eldritch_knowledge/final_eldritch/echo_final/finale = fixture["finale"]
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	var/list/before = list_vfx_bursts(center)
	TEST_ASSERT(echo.reprise(user, finale), "Отзвук звучит.")
	TEST_ASSERT_EQUAL(length(echo.attacks), 1, "Отзвук готовит один крест.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	TEST_ASSERT(length(attack.warnings), "Крест отзвука по-прежнему отмечается сразу.")
	var/list/rings = list()
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/ring in center)
		rings += ring
	TEST_ASSERT_EQUAL(length(rings), 1, "Первое кольцо звука расходится в миг попадания.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(center, /particles/heretic_ascension/echo, before), "Отзвук рассыпает латунные кольца.")
	var/list/budget = new_wait_budget(1 SECONDS, "кольца отзвука")
	while(length(rings) < 3 && wait_budget_tick(budget))
		for(var/obj/effect/temp_visual/heretic_vfx/shockwave/ring in center)
			rings |= ring
	TEST_ASSERT_EQUAL(length(rings), 3, "За первым кольцом расходятся ещё два.")
	TEST_ASSERT(!QDELETED(attack), "Кольца идут раньше креста.")
	attack.resolve()
	TEST_ASSERT(abs(shooter.getBruteLoss() - HERETIC_ECHO_REPRISE_DAMAGE) <= DAMAGE_PRECISION, "Крест наносит прежние 15 ушибов.")
	TEST_ASSERT(abs(shooter.getStaminaLoss() - HERETIC_ECHO_REPRISE_STAMINA) <= DAMAGE_PRECISION, "Крест наносит прежние 15 урона выносливости.")
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/ring as anything in rings)
		TEST_ASSERT(wait_for_qdeleted(ring), "Кольца отзвука гаснут.")

/// Последняя служба: колокол стягивает звук к герою, каждая волна расходится кольцом и поднимает пыль; урон прежний.
/datum/unit_test/heretic_echo_chorus_visuals/Run()
	var/list/fixture = ascend_echo_fixture(get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTH))
	var/turf/center = fixture["center"]
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_echo/echo = fixture["echo"]
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human, get_step(center, EAST))
	TEST_ASSERT(drain_echo_rings(center), "Старые кольца догорели.")
	var/list/before = list_vfx_bursts(center)
	TEST_ASSERT(echo.final_chorus(user), "Последняя служба начинается.")
	var/obj/effect/temp_visual/heretic_vfx/gather/toll = locate() in center
	TEST_ASSERT_NOTNULL(toll, "Колокол стягивает звук к герою.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Герой вспыхивает золотом, как колокол.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in center, "До первого удара волна не расходится.")
	var/datum/heretic_echo_attack/attack = echo.attacks[1]
	attack.resolve()
	TEST_ASSERT(abs(near.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Первая волна наносит прежние 32 ушиба.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in center
	TEST_ASSERT_NOTNULL(wave, "Волна расходится кольцом в миг удара.")
	var/obj/effect/temp_visual/heretic_vfx/burst/dust = find_vfx_burst(center, /particles/heretic_ascension/echo/dust, before)
	TEST_ASSERT_NOTNULL(dust, "Волна поднимает пыль.")
	attack.resolve()
	attack.resolve()
	TEST_ASSERT(QDELETED(attack), "Три волны завершают службу.")
	TEST_ASSERT(abs(near.getBruteLoss() - 64) <= DAMAGE_PRECISION, "Волны по-прежнему дважды задевают соседнюю клетку.")
	TEST_ASSERT(wait_for_qdeleted(toll), "Кольцо колокола гаснет.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Кольцо волны гаснет.")
	TEST_ASSERT(wait_for_qdeleted(dust, 3 SECONDS), "Пыль оседает.")

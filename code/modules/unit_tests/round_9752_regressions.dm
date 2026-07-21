/// Combining cards must retain the real deck after the consumed card is qdeleted.
/datum/unit_test/cardhand_merge_retains_parent_deck/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/toy/cards/deck/deck = allocate(/obj/item/toy/cards/deck)
	var/obj/item/toy/cards/cardhand/hand = allocate(/obj/item/toy/cards/cardhand)
	var/obj/item/toy/cards/singlecard/first = allocate(/obj/item/toy/cards/singlecard)
	var/obj/item/toy/cards/singlecard/second = allocate(/obj/item/toy/cards/singlecard)
	first.parentdeck = deck
	first.cardname = "Ace of Spades"
	second.parentdeck = deck
	second.cardname = "Two of Spades"

	TEST_ASSERT(hand.insert(first, user), "Не удалось добавить первую карту в руку")
	TEST_ASSERT_EQUAL(hand.parentdeck, deck, "Рука сохранила удалённую карту вместо исходной колоды")
	TEST_ASSERT(hand.insert(second, user), "Вторая карта той же колоды была отклонена")
	TEST_ASSERT_EQUAL(length(hand.cards), 2, "После объединения в руке не две карты")
	TEST_ASSERT_EQUAL(hand.parentdeck, deck, "Повторное объединение потеряло исходную колоду")

/// RCD charge state belongs in update_overlays()'s return value.
/datum/unit_test/rcd_charge_overlay_survives_update/Run()
	var/obj/item/construction/rcd/rcd = allocate(/obj/item/construction/rcd)
	rcd.has_ammobar = TRUE
	rcd.max_matter = 100
	rcd.matter = 50
	var/ratio = CEILING((rcd.matter / rcd.max_matter) * rcd.ammo_sections, 1)
	var/list/generated_overlays = rcd.update_overlays()
	TEST_ASSERT("[rcd.icon_state]_charge[ratio]" in generated_overlays, "update_overlays() потерял полоску заряда RCD")

/// Research materials are initialized to datum instances, not material typepaths.
/datum/unit_test/design_disk_accepts_basic_material_instances/Run()
	var/datum/design/advanced_bin = SSresearch.techweb_design_by_id("adv_matter_bin")
	TEST_ASSERT_NOTNULL(advanced_bin, "Не найден дизайн Advanced Matter Bin")
	TEST_ASSERT(advanced_bin.is_autolathe_compatible(), "Железно-стеклянный tier-2 дизайн нельзя импортировать в автолат")

/// The female ash-walker subtype should not inherit the male chunky-fingers restriction.
/datum/unit_test/western_ashwalker_has_item_dexterity/Run()
	var/datum/species/lizard/ashwalker/western/species = new
	TEST_ASSERT(!(TRAIT_CHUNKYFINGERS in species.inherent_traits), "Western Ash Walker сохранила TRAIT_CHUNKYFINGERS")
	qdel(species)

/// A normal Lazarus revival must discard targets retained by the hostile AI.
/datum/unit_test/lazarus_hostile_aggro_cleanup/Run()
	var/mob/living/simple_animal/hostile/animal = allocate(/mob/living/simple_animal/hostile)
	var/mob/living/carbon/human/old_target = allocate(/mob/living/carbon/human)
	animal.target = old_target
	animal.friends[old_target] = 1
	animal.foes[old_target] = 1
	animal.add_enemy(old_target)

	animal.clear_hostile_aggro()
	TEST_ASSERT_NULL(animal.target, "Lazarus оставил текущую цель")
	TEST_ASSERT(!length(animal.friends), "Lazarus оставил список друзей старого ИИ")
	TEST_ASSERT(!length(animal.foes), "Lazarus оставил персональные обиды")
	TEST_ASSERT(!length(animal.enemies), "Lazarus оставил список врагов")

/// A medically revived xenochimera should be released without waiting for its old timer.
/datum/unit_test/xenochimera_medical_revive_cancels_regeneration/Run()
	var/mob/living/carbon/human/chimera = allocate(/mob/living/carbon/human)
	var/ready_state = initial(chimera.revive_ready)
	chimera.revive_ready = -1
	chimera.revive_started_stat = DEAD
	chimera.revive_finished = world.time + 5 MINUTES
	chimera.SetParalyzed(5 MINUTES)
	chimera.set_stat(UNCONSCIOUS)

	TEST_ASSERT(chimera.cancel_chimera_regeneration(), "Регенерация трупа не отменилась после лечения")
	TEST_ASSERT_EQUAL(chimera.revive_ready, ready_state, "Способность не вернулась в готовое состояние")
	TEST_ASSERT_NULL(chimera.revive_started_stat, "Осталось исходное состояние регенерации трупа")
	TEST_ASSERT(!chimera.IsParalyzed(), "Медицински оживлённая химера осталась парализована")

/// A xenochimera that naturally heals out of critical condition should also be released.
/datum/unit_test/xenochimera_critical_recovery_cancels_regeneration/Run()
	var/mob/living/carbon/human/chimera = allocate(/mob/living/carbon/human)
	var/ready_state = initial(chimera.revive_ready)
	chimera.revive_ready = -1
	chimera.revive_started_stat = SOFT_CRIT
	chimera.revive_finished = world.time + 5 MINUTES
	chimera.SetParalyzed(5 MINUTES)
	chimera.set_stat(CONSCIOUS)

	TEST_ASSERT(chimera.cancel_chimera_regeneration(), "Выход из критического состояния не отменил регенерацию")
	TEST_ASSERT_EQUAL(chimera.revive_ready, ready_state, "После выхода из крита способность не вернулась в готовое состояние")
	TEST_ASSERT_NULL(chimera.revive_started_stat, "После выхода из крита осталось исходное состояние регенерации")
	TEST_ASSERT(!chimera.IsParalyzed(), "Вышедшая из крита химера осталась парализована")

/// Stone form is a restraint, and breaking the statue must reset both quirk/action state.
/datum/unit_test/gargoyle_statue_releases_all_state/Run()
	var/mob/living/carbon/human/gargoyle = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/quirk/gargoyle/quirk = new(gargoyle, FALSE)
	var/datum/action/gargoyle/transform/action = locate() in gargoyle.actions
	var/obj/structure/statue/gargoyle/statue = new(run_loc_floor_bottom_left, gargoyle)
	quirk.transformed = TRUE
	quirk.current = statue
	action.current = statue

	TEST_ASSERT(gargoyle.restrained(), "Каменная форма не считается ограничивающей действия")
	TEST_ASSERT(!CHECK_MOBILITY(gargoyle, MOBILITY_UI), "Каменная форма оставила доступ к UI")
	qdel(statue)
	TEST_ASSERT(!quirk.transformed, "Разрушенная статуя оставила включённое восстановление энергии")
	TEST_ASSERT_NULL(quirk.current, "Квирк удерживает разрушенную статую")
	TEST_ASSERT_NULL(action.current, "Action удерживает разрушенную статую")
	TEST_ASSERT(!gargoyle.restrained(), "После разрушения статуи моб остался скован")
	qdel(quirk)

/// Externally deleting a tackle component must clear the gloves' long-lived reference.
/datum/unit_test/tackler_gloves_component_qdel_cleanup/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/gloves/tackler/gloves = allocate(/obj/item/clothing/gloves/tackler)
	var/datum/component/tackler/component = user.AddComponent(/datum/component/tackler)
	gloves.set_tackler_component(component)
	qdel(component)
	TEST_ASSERT_NULL(gloves.tackler, "Перчатки удерживают удалённый tackler component")

/// A repeating personal track must leave every jukebox field before it is deleted.
/datum/unit_test/personal_music_track_qdel_cleanup/Run()
	var/obj/item/personal_music_box/box = allocate(/obj/item/personal_music_box)
	var/datum/component/jukebox/personal_music_box/jukebox = box.get_jukebox_component()
	var/datum/track/track = new("unit test", null, 1 MINUTES, 50, "unit_test")
	jukebox.custom_track = track
	jukebox.selectedtrack = track
	jukebox.queuedplaylist = list(track)

	jukebox.clear_custom_track()
	TEST_ASSERT_NULL(jukebox.custom_track, "Компонент сохранил custom_track")
	TEST_ASSERT_NULL(jukebox.selectedtrack, "Компонент сохранил selectedtrack")
	TEST_ASSERT(!(track in jukebox.queuedplaylist), "Компонент сохранил трек в очереди")
	TEST_ASSERT(QDELETED(track), "Пользовательский track не был удалён")

/// Mentor following must be invalidated when the followed mob is deleted.
/datum/unit_test/mentor_following_qdel_cleanup/Run()
	var/datum/mentors/mentor = new("unit_test_mentor")
	var/mob/living/carbon/human/followed = allocate(/mob/living/carbon/human)
	mentor.set_following(followed)
	qdel(followed)
	TEST_ASSERT_NULL(mentor.following, "Mentor datum удерживает удалённого моба")
	qdel(mentor)

/// Mob destruction must clear registered TGUI datums even when no client remains.
/datum/unit_test/mob_qdel_closes_registered_tgui/Run()
	var/mob/user = new
	var/obj/item/source = allocate(/obj/item)
	var/datum/tgui/ui = new(user, source, "UnitTest")
	user.tgui_open_uis |= ui
	qdel(user)
	TEST_ASSERT(QDELETED(ui), "Удалённый mob остался владельцем зарегистрированного TGUI")

/// The shell path must use a death signal rather than a shared-body soullink.
/datum/unit_test/ai_shell_disconnects_on_death_source/Run()
	var/source = read_source_file("code/modules/mob/living/silicon/ai/ai.dm")
	TEST_ASSERT_NOTNULL(source, "Не удалось прочитать ai.dm")
	TEST_ASSERT(findtext(source, "RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(disconnect_shell))"), "ИИ не подписан на смерть активной оболочки")
	TEST_ASSERT(!findtext(source, "soullink(/datum/soullink/sharedbody, src, target)"), "Оболочка ИИ всё ещё создаёт второе sharedbody-состояние")

/// UI state must reflect the actual borg lamp switch, not its configured intensity.
/datum/unit_test/borg_headlamp_ui_uses_enabled_state/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	borg.lamp_intensity = 3
	borg.lamp_enabled = FALSE
	var/list/data = borg.modularInterface.ui_data(borg)
	TEST_ASSERT_EQUAL(data["light_on"], FALSE, "UI показывает разбитый выключенный фонарь включённым")

/// Frequency UI changes must unregister the signaler from its previous radio datum.
/datum/unit_test/signaler_frequency_ui_unregisters_old_connection/Run()
	var/obj/item/assembly/signaler/signaler = allocate(/obj/item/assembly/signaler)
	var/datum/radio_frequency/old_connection = signaler.radio_connection
	var/new_frequency = signaler.frequency + 2
	signaler.set_frequency_from_ui(format_frequency(new_frequency))
	TEST_ASSERT_EQUAL(signaler.frequency, new_frequency, "UI не установил новую частоту")
	TEST_ASSERT_NOTEQUAL(signaler.radio_connection, old_connection, "UI оставил старое radio_connection")
	TEST_ASSERT(!(signaler in old_connection.devices), "Старая radio frequency удерживает signaler")

/// A stale floating action entry must be removed even if its cached location reset.
/datum/unit_test/floating_action_qdel_cleanup/Run()
	var/mob/owner = allocate(/mob)
	var/datum/hud/hud = new(owner)
	var/atom/movable/screen/movable/action_button/button = new
	hud.floating_actions = list(button)
	button.our_hud = hud
	button.location = SCRN_OBJ_DEFAULT
	qdel(button)
	TEST_ASSERT(!(button in hud.floating_actions), "HUD удерживает удалённую floating action button")
	qdel(hud)

/// Production harddels showed stale mobs in every mode-owned current_players cache.
/datum/unit_test/mob_qdel_clears_mode_player_caches/Run()
	if(!SSticker?.mode)
		return
	var/mob/living/carbon/human/player = new
	SSticker.mode.current_players[CURRENT_LIVING_PLAYERS] |= player
	SSticker.mode.current_players[CURRENT_LIVING_ANTAGS] |= player
	SSticker.mode.current_players[CURRENT_DEAD_PLAYERS] |= player
	SSticker.mode.current_players[CURRENT_OBSERVERS] |= player
	qdel(player)
	for(var/player_list_key in list(CURRENT_LIVING_PLAYERS, CURRENT_LIVING_ANTAGS, CURRENT_DEAD_PLAYERS, CURRENT_OBSERVERS))
		TEST_ASSERT(!(player in SSticker.mode.current_players[player_list_key]), "Удалённый mob остался в current_players key [player_list_key]")

/// DNA vault lottery keys must not keep a mob datum alive for the rest of the round.
/datum/unit_test/dna_vault_lottery_uses_ckeys_source/Run()
	var/source = read_source_file("code/modules/station_goals/dna_vault.dm")
	TEST_ASSERT_NOTNULL(source, "Не удалось прочитать dna_vault.dm")
	TEST_ASSERT(findtext(source, "power_lottery\[user.ckey\]"), "DNA Vault не хранит выбор по ckey")
	TEST_ASSERT(!findtext(source, "power_lottery\[user\]"), "DNA Vault всё ещё использует mob как ключ лотереи")

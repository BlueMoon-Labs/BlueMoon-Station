// Team Deathmatch: two teams, round based respawns, a new pair of kits every
// round.
//
// This is a /datum/deathmatch_lobby subtype rather than a second lobby system.
// Everything the free-for-all lobby does (VR sleepers, roster, stakes, TGUI,
// arena reservation, modifiers) is reused; the only differences are how players
// are split into teams, how a death is treated (elimination for the round, not
// removal from the game), and what happens between rounds.
//
// The kits are team aware: each round hands out one pair of loadouts, one per
// side, so both teams get the same weapon family but each gets its own version
// of it. Nobody picks; the random preset pool picks for them, and the same
// preset never arms two rounds in a row.
//
// The map template selects it through /datum/map_template/deathmatch/lobby_type.

/// Team one. The Terrorist side: on de_dust2 it owns the Peacebreaker and the
/// m40a1, and it spawns on the alpha landmarks.
#define TDM_TEAM_ALPHA 1
/// Team two. The Counter-Terrorist side: the stock riot shotgun, the Enforcer
/// and the standard sniper rifle, on the bravo landmarks.
#define TDM_TEAM_BRAVO 2

/datum/deathmatch_lobby/team_deathmatch
	// Round state.
	var/round_number = 0
	var/round_live = FALSE
	var/round_started_at = 0
	var/round_token = 0
	/// How long a single round may run before it is decided on survivors.
	var/round_time = 2 MINUTES
	/// The pause between rounds, used to show the score and rebuild bodies.
	var/intermission_time = 8 SECONDS
	/// The outer match clock. A match is first to five round wins, so nine to
	/// eleven two minute rounds plus intermissions is roughly 24 minutes. This
	/// is only the backstop for a game that never gets there, such as an endless
	/// run of drawn rounds.
	game_time = 30 MINUTES
	/// Round wins a team needs to take the match. There is no round cap: a draw
	/// awards no point, so a 4 - 4 game simply keeps playing rounds until one
	/// side takes its fifth win.
	var/rounds_to_win = 5
	var/team_one_score = 0
	var/team_two_score = 0
	var/team_one_name = "Terrorists"
	var/team_two_name = "Counter-Terrorists"
	/// Minimum number of fighters each side needs before a match may start. One
	/// is enough for a duel, but a team with nobody on it is not a match, so a
	/// lone player waiting in the lobby cannot start it alone.
	var/min_team_size = 1
	/// The five round presets. Each pair contains the Terrorist kit first and the
	/// Counter-Terrorist kit second, so the two sides can be equipped separately.
	var/list/loadout_presets = list(
		"Knives" = list(
			/datum/outfit/vr/deathmatch_loadout/tdm_knives_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_knives_counter,
		),
		"Sniper rifles" = list(
			/datum/outfit/vr/deathmatch_loadout/tdm_sniper_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_sniper_counter,
		),
		"Pump shotguns" = list(
			/datum/outfit/vr/deathmatch_loadout/tdm_shotgun_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_shotgun_counter,
		),
		"Pistols" = list(
			/datum/outfit/vr/deathmatch_loadout/tdm_pistol_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_pistol_counter,
		),
		"Assault rifles" = list(
			/datum/outfit/vr/deathmatch_loadout/tdm_assault_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_assault_counter,
		),
	)
	/// Names of the presets already played, oldest first. Used for diagnostics
	/// and to keep the next draw from repeating the previous round.
	var/list/played_loadout_presets = list()
	/// The preset equipping the current round, or the upcoming one while waiting.
	var/current_loadout_preset
	var/next_loadout_preset

	/// The single C4 issued to a random Terrorist each round.
	var/obj/item/deathmatch_c4/round_bomb
	var/bomb_planted = FALSE
	var/bomb_site

/datum/deathmatch_lobby/team_deathmatch/New(...)
	. = ..()
	reset_loadout_presets()

/// Clears the match history and draws the first round's preset.
/datum/deathmatch_lobby/team_deathmatch/proc/reset_loadout_presets()
	played_loadout_presets = list()
	current_loadout_preset = null
	next_loadout_preset = draw_loadout_preset()

/**
 * Returns a random preset name, never the one the previous round just used.
 *
 * A match now runs to five round wins, which is more rounds than there are
 * presets, so the five of them are reused rather than drawn without
 * replacement. Skipping only the most recent one is what keeps the repetition
 * from being felt: the same weapons can never arm two rounds in a row, while
 * any preset may come back once another round has been played in between.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/draw_loadout_preset()
	var/list/candidates = loadout_presets.Copy()
	if(length(played_loadout_presets))
		candidates -= played_loadout_presets[length(played_loadout_presets)]
	if(!length(candidates))
		// A custom config with a single preset has nothing else to alternate
		// with, so repeating it is better than stalling the match.
		candidates = loadout_presets.Copy()
	if(!length(candidates))
		return null
	return pick(candidates)

/datum/deathmatch_lobby/team_deathmatch/to_string()
	return "Team Deathmatch lobby (host [host_key], [player_count()] player(s), round [round_number])"

//
// Teams.
//

/datum/deathmatch_lobby/team_deathmatch/proc/team_name(team)
	switch(team)
		if(TDM_TEAM_ALPHA)
			return team_one_name
		if(TDM_TEAM_BRAVO)
			return team_two_name
	return "Spectator"

/// Fighters on a team, eliminated or not. Observers are never on a team.
/datum/deathmatch_lobby/team_deathmatch/proc/team_member_count(team)
	var/count = 0
	for(var/datum/deathmatch_player/player as anything in players)
		if(isnull(player) || player.is_observer)
			continue
		if(player.team == team)
			count++
	return count

/**
 * The TDM override of the base requirement.
 *
 * The base lobby only counts bodies, so two players sitting on the same side
 * would satisfy it. TDM additionally requires min_team_size fighters on each
 * side, which with the default of one means a duel at minimum and a full side
 * for anybody who joins later.
 */
/datum/deathmatch_lobby/team_deathmatch/players_needed()
	var/short = 0
	for(var/team in list(TDM_TEAM_ALPHA, TDM_TEAM_BRAVO))
		short += max(0, min_team_size - team_member_count(team))
	return max(short, ..())

/// Fighters on a team who are still standing in the current round.
/datum/deathmatch_lobby/team_deathmatch/proc/team_alive_count(team)
	var/count = 0
	for(var/datum/deathmatch_player/player as anything in players)
		if(isnull(player) || player.is_observer || player.is_eliminated)
			continue
		if(player.team != team)
			continue
		// A player whose body is gone is out for this round. This also covers the
		// gap between death and the next reap, because virtual_reality has
		// already handed the ckey back by then.
		if(isnull(player.vr_body) || QDELETED(player.vr_body))
			continue
		if(player.vr_body.stat == DEAD)
			continue
		count++
	return count

/// The team with fewer fighters, so a lobby that fills one at a time ends up
/// evenly split instead of everybody piling onto the host's side.
/datum/deathmatch_lobby/team_deathmatch/proc/pick_team()
	var/alpha = team_member_count(TDM_TEAM_ALPHA)
	var/bravo = team_member_count(TDM_TEAM_BRAVO)
	return (alpha <= bravo) ? TDM_TEAM_ALPHA : TDM_TEAM_BRAVO

/datum/deathmatch_lobby/team_deathmatch/join(mob/real_body, loadout = null, is_host = FALSE, observe = FALSE)
	// The parent returns the new /datum/deathmatch_player on success, or FALSE
	// (which is 0, not null) with a reason already sent to the player. istype()
	// is what separates the two; isnull() would let FALSE through and the reads
	// below would runtime on a number.
	var/datum/deathmatch_player/player = ..()
	if(!istype(player))
		return FALSE
	if(!player.is_observer)
		if(!player.team)
			player.team = pick_team()
		// Before the first round the roster shows the kit the player will
		// actually get, not whatever they happened to join with.
		if(state == DM_LOBBY_WAITING)
			player.loadout = get_round_loadout(team = player.team)
		to_chat(player.real_body, span_notice("You are on [team_name(player.team)]."))
	return player

//
// Round start and loadouts.
//

/// The kit pair for the live round, or the already drawn upcoming pair while
/// the lobby is waiting or between rounds. The upcoming pair is drawn only once,
/// so repeated TGUI refreshes cannot reroll it.
/datum/deathmatch_lobby/team_deathmatch/proc/get_round_kits()
	var/preset = round_live ? current_loadout_preset : next_loadout_preset
	if(isnull(preset))
		return null
	return loadout_presets[preset]

/**
 * The kit one team gets for the current or upcoming round.
 *
 * A preset entry is a pair of paths: Terrorists first, Counter-Terrorists
 * second. A lone path is also accepted for custom presets and is given to both.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/get_round_loadout(team = TDM_TEAM_ALPHA)
	var/list/kits = get_round_kits()
	if(!islist(kits))
		return template?.loadout
	if(length(kits) == 1)
		return kits[1]
	return (team == TDM_TEAM_BRAVO) ? kits[2] : kits[1]

/datum/deathmatch_lobby/team_deathmatch/available_loadouts()
	var/list/kits = list()
	var/alpha_kit = get_round_loadout(team = TDM_TEAM_ALPHA)
	var/bravo_kit = get_round_loadout(team = TDM_TEAM_BRAVO)
	if(!isnull(alpha_kit))
		kits += alpha_kit
	if(!isnull(bravo_kit) && bravo_kit != alpha_kit)
		kits += bravo_kit
	return kits

/datum/deathmatch_lobby/team_deathmatch/ui_act(action, list/params, ui_obj, datum/ui_state/tgui_state)
	// Kits are handed out by the random round preset. Letting somebody pick one
	// here would only last until the round starts.
	if(action == "select_loadout")
		return FALSE
	return ..()

/datum/deathmatch_lobby/team_deathmatch/proc/apply_round_loadouts()
	for(var/datum/deathmatch_player/player as anything in players)
		if(isnull(player) || player.is_observer)
			continue
		player.loadout = get_round_loadout(team = player.team)

/**
 * The two perks every fighter has this round, whatever their kit, given to a
 * body that has already been built and outfitted.
 *
 * They are deliberately not part of a kit: they are the mode's floor, so they
 * go on after the outfit rather than through it. The reflex art is taught
 * straight to the avatar's mind, and the regeneration is a status effect that
 * runs until the body is reaped.
 *
 * A mindless body (one whose build somehow left it without one) is skipped
 * silently. virtual_reality refuses to seat one anyway, so this only ever
 * matters for a body that is already on its way out.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/apply_round_perks(datum/deathmatch_player/player)
	var/mob/living/carbon/human/body = player?.vr_body
	if(!istype(body) || isnull(body.mind))
		return FALSE
	if(!istype(body.mind.martial_art, /datum/martial_art/deathmatch_reflex))
		var/datum/martial_art/deathmatch_reflex/reflexes = new
		reflexes.teach(body)
	body.apply_status_effect(/datum/status_effect/deathmatch_stamina)
	return TRUE

/**
 * How the round's kits read in chat: "Terrorists: X, Counter-Terrorists: Y",
 * or just the one name when the pair is the same kit on both sides.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/round_kits_label()
	var/alpha_kit = loadout_name(get_round_loadout(team = TDM_TEAM_ALPHA))
	var/bravo_kit = loadout_name(get_round_loadout(team = TDM_TEAM_BRAVO))
	if(alpha_kit == bravo_kit)
		return alpha_kit
	return "[team_one_name]: [alpha_kit], [team_two_name]: [bravo_kit]"

/**
 * The TDM version of begin_match(): same arena load and modifier checks, but
 * the bodies are spawned by start_round() so that round one is set up exactly
 * like every later round.
 */
/datum/deathmatch_lobby/team_deathmatch/begin_match()
	if(state != DM_LOBBY_WAITING)
		return FALSE
	if(players_needed() > 0)
		return FALSE
	if(length(start_refusal()))
		return FALSE
	if(isnull(arena) || arena.is_loaded() || !arena.load_arena())
		log_game("Deathmatch: [to_string()] could not load its arena.")
		end_lobby()
		return FALSE

	// Anybody who joined before the first round has a team by now. The fallback
	// covers a player datum made by a mode change or an admin edit.
	for(var/datum/deathmatch_player/player as anything in players)
		if(!player.is_observer && !player.team)
			player.team = pick_team()

	state = DM_LOBBY_RUNNING
	time_started = world.time
	round_number = 0
	team_one_score = 0
	team_two_score = 0

	for(var/modifier_path as anything in selected_modifiers)
		var/datum/deathmatch_modifier/modifier = get_deathmatch_modifier_instance(modifier_path)
		if(isnull(modifier) || !modifier.selectable(src))
			continue
		try
			modifier.on_start_game(src)
		catch(var/exception/e)
			log_game("Deathmatch: modifier [modifier] failed on lobby start: [e]")

	if(!start_round())
		end_lobby(reason = "the first round could not be started")
		return FALSE

	announce_start()
	addtimer(CALLBACK(src, PROC_REF(on_time_up)), game_time)
	log_game("Deathmatch: [to_string()] started on [arena.to_string()].")
	return TRUE

/**
 * Builds a fresh body for everybody and starts the next round.
 *
 * Old bodies are cleared first: a round ends with the survivors still alive in
 * the arena, and spawn_player() refuses to seat a player who already has a
 * living avatar. Clearing in one pass also hands every spawn landmark back
 * before the next pass claims them again.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/start_round()
	if(is_finished() || state != DM_LOBBY_RUNNING)
		return FALSE
	if(isnull(arena) || !arena.is_loaded())
		log_game("Deathmatch: [to_string()] cannot start round [round_number + 1]: arena is not loaded.")
		return FALSE
	if(isnull(next_loadout_preset))
		// Only reachable when loadout_presets itself is empty: the draw reuses
		// presets, so it always has a candidate otherwise and never runs dry.
		log_game("Deathmatch: [to_string()] has no loadout preset for round [round_number + 1].")
		if(round_number > 0)
			finish_match()
		return FALSE

	clear_round_bomb()
	current_loadout_preset = next_loadout_preset
	played_loadout_presets += current_loadout_preset
	// Draw the following round now, so the intermission roster shows a stable
	// preview. The history already holds this round's preset, which is exactly
	// what the draw excludes.
	next_loadout_preset = draw_loadout_preset()

	round_number++
	round_live = TRUE
	round_started_at = world.time
	round_token++
	apply_round_loadouts()

	for(var/datum/deathmatch_player/player as anything in players.Copy())
		if(isnull(player) || player.is_observer)
			continue
		clear_round_body(player)
		player.is_eliminated = FALSE

	for(var/datum/deathmatch_player/player as anything in players.Copy())
		if(isnull(player) || player.is_observer)
			continue
		if(spawn_player(player))
			apply_round_perks(player)
			continue
		// A body that fails to build is out for this round rather than out of
		// the game. The first round is the exception: without the host there is
		// no game to play.
		player.is_eliminated = TRUE
		if(round_number == 1 && player.is_host)
			log_game("Deathmatch: [to_string()] could not seat its host for round 1.")
			return FALSE

	give_round_bomb()
	announce_to_players(span_boldnotice("Round [round_number] begins. First to [rounds_to_win] round wins takes the match. Kits: [round_kits_label()]."))
	announce_to_players(span_notice("Both teams can slip bullets mid-jump and recover stamina quickly."))
	announce_to_players(span_notice("[team_one_name] [team_one_score] - [team_two_score] [team_two_name]"))
	addtimer(CALLBACK(src, PROC_REF(round_timer_callback), round_token), round_time)
	refresh_uis()
	// Both teams may have lost everybody to failed spawns, which is a round end
	// that happened before the timer was even armed.
	check_round_end()
	return TRUE

/// Deletes a player's current avatar and gives its spawn back, without any of
/// the "you left the game" messaging evict_body() does.
/datum/deathmatch_lobby/team_deathmatch/proc/clear_round_body(datum/deathmatch_player/player)
	if(isnull(player))
		return FALSE
	if(!isnull(arena))
		arena.release_spawn_point(player.spawn_landmark)
	player.spawn_landmark = null
	var/mob/living/vr_body = player.vr_body
	player.vr_body = null
	if(isnull(vr_body) || QDELETED(vr_body))
		return FALSE
	// A living avatar still holds the player's ckey. quit() is what hands it
	// back before the body is deleted; a dead one has already done this through
	// its death signal, and quit() is a no-op there.
	var/datum/component/virtual_reality/VR = vr_body.GetComponent(/datum/component/virtual_reality)
	if(!isnull(VR))
		VR.quit(FALSE, FALSE)
	qdel(vr_body)
	return TRUE

//
// C4.
//

/// Removes the previous round's bomb, including a planted one and its timer.
/datum/deathmatch_lobby/team_deathmatch/proc/clear_round_bomb()
	bomb_planted = FALSE
	bomb_site = null
	if(isnull(round_bomb))
		return
	var/obj/item/deathmatch_c4/bomb = round_bomb
	round_bomb = null
	if(!QDELETED(bomb))
		qdel(bomb)

/// Gives the round's only C4 to one living Terrorist, chosen independently of
/// the kit preset. If both hands are occupied it is dropped at their feet.
/datum/deathmatch_lobby/team_deathmatch/proc/give_round_bomb()
	var/list/possible_carriers = list()
	for(var/datum/deathmatch_player/player as anything in players)
		if(isnull(player) || player.is_observer || player.is_eliminated)
			continue
		if(player.team != TDM_TEAM_ALPHA)
			continue
		if(isnull(player.vr_body) || QDELETED(player.vr_body) || player.vr_body.stat == DEAD)
			continue
		possible_carriers += player
	if(!length(possible_carriers))
		return FALSE

	var/datum/deathmatch_player/carrier = pick(possible_carriers)
	var/mob/living/body = carrier.vr_body
	var/obj/item/deathmatch_c4/bomb = new(get_turf(body))
	bomb.lobby = src
	round_bomb = bomb
	if(body.put_in_hands(bomb))
		to_chat(body, span_boldnotice("Вам выдана C4. Используйте её в руке на точке plant_a или plant_b, чтобы начать закладку."))
	else
		to_chat(body, span_boldnotice("Вам выдана C4, но руки заняты: она лежит у ваших ног."))
	log_game("Deathmatch: [to_string()] gave C4 to [carrier.ckey || "unknown"] for round [round_number].")
	return TRUE

/// Only a living Terrorist avatar from this lobby may plant the round's bomb.
/datum/deathmatch_lobby/team_deathmatch/proc/can_plant_bomb(mob/living/user)
	if(is_finished() || !round_live || bomb_planted || isnull(user))
		return FALSE
	var/datum/deathmatch_player/player = player_of(user.ckey)
	if(isnull(player) || player.is_observer || player.is_eliminated || player.team != TDM_TEAM_ALPHA)
		return FALSE
	return player.vr_body == user && user.stat != DEAD && !user.incapacitated()

/// Only a living Counter-Terrorist avatar may defuse an active planted bomb.
/datum/deathmatch_lobby/team_deathmatch/proc/can_defuse_bomb(mob/living/user)
	if(is_finished() || !round_live || !bomb_planted || isnull(user))
		return FALSE
	var/datum/deathmatch_player/player = player_of(user.ckey)
	if(isnull(player) || player.is_observer || player.is_eliminated || player.team != TDM_TEAM_BRAVO)
		return FALSE
	return player.vr_body == user && user.stat != DEAD && !user.incapacitated()

/datum/deathmatch_lobby/team_deathmatch/proc/on_bomb_planted(obj/item/deathmatch_c4/bomb, site)
	if(is_finished() || !round_live || bomb != round_bomb)
		return FALSE
	bomb_planted = TRUE
	bomb_site = site
	to_chat(world, span_userdanger("<big>C4 УСТАНОВЛЕНА НА ТОЧКЕ [site]! До взрыва [DisplayTimeText(bomb.fuse_time)]!</big>"))
	announce_to_players(span_boldnotice("Counter-Terrorists: подойдите к C4 и нажмите по ней пустой рукой, чтобы обезвредить её."))
	log_game("Deathmatch: [to_string()] planted C4 at site [site] in round [round_number].")
	return TRUE

/datum/deathmatch_lobby/team_deathmatch/proc/on_bomb_defused(obj/item/deathmatch_c4/bomb, mob/living/user)
	if(is_finished() || !round_live || bomb != round_bomb || !bomb_planted)
		return FALSE
	bomb_planted = FALSE
	to_chat(world, span_boldnotice("<big>[user.name] обезвредил C4. Counter-Terrorists выигрывают раунд!</big>"))
	end_round(TDM_TEAM_BRAVO, "[team_two_name] defused the bomb")
	return TRUE

/datum/deathmatch_lobby/team_deathmatch/proc/on_bomb_detonated(obj/item/deathmatch_c4/bomb)
	if(is_finished() || !round_live || bomb != round_bomb || !bomb_planted)
		return FALSE
	bomb_planted = FALSE
	end_round(TDM_TEAM_ALPHA, "the bomb exploded")
	return TRUE

/// Last-resort cleanup for an active bomb deleted outside defusal/detonation.
/// C4 is indestructible, so this is mainly for admin deletion and future code.
/datum/deathmatch_lobby/team_deathmatch/proc/on_bomb_deleted(obj/item/deathmatch_c4/bomb)
	if(bomb != round_bomb)
		return
	round_bomb = null
	var/was_planted = bomb_planted
	bomb_planted = FALSE
	bomb_site = null
	if(!was_planted || is_finished() || !round_live)
		return
	if(check_round_end())
		return
	// If the ordinary clock already expired while the bomb was active, its timer
	// deliberately did nothing. Re-run that decision now that resolution is back.
	if(world.time >= round_started_at + round_time)
		round_timer_callback(round_token)

/datum/deathmatch_lobby/team_deathmatch/get_player_spawn_point(datum/deathmatch_player/player)
	// Each team spawns on its own side of the map. A map with only untyped
	// spawns falls through to any of them, so TDM still works on an old arena.
	return arena.get_spawn_point(player?.team || 0)

//
// Round end.
//

/datum/deathmatch_lobby/team_deathmatch/proc/round_time_left()
	if(!round_live)
		return 0
	return max(0, round_time - (world.time - round_started_at))

/datum/deathmatch_lobby/team_deathmatch/proc/round_timer_callback(token)
	if(is_finished() || !round_live || token != round_token)
		return
	// Once C4 is planted its own fuse decides the round. The normal round clock
	// must not award a survivors win while that countdown is still running.
	if(bomb_planted)
		return
	var/alpha_alive = team_alive_count(TDM_TEAM_ALPHA)
	var/bravo_alive = team_alive_count(TDM_TEAM_BRAVO)
	if(alpha_alive > bravo_alive)
		end_round(TDM_TEAM_ALPHA, "[team_one_name] had more players left")
	else if(bravo_alive > alpha_alive)
		end_round(TDM_TEAM_BRAVO, "[team_two_name] had more players left")
	else
		end_round(0, "both teams were dead even")

/// Called from reap_bodies() every few seconds and by start_round().
/datum/deathmatch_lobby/team_deathmatch/proc/check_round_end()
	if(is_finished() || !round_live)
		return FALSE
	var/alpha_alive = team_alive_count(TDM_TEAM_ALPHA)
	var/bravo_alive = team_alive_count(TDM_TEAM_BRAVO)
	var/alpha_total = team_member_count(TDM_TEAM_ALPHA)
	var/bravo_total = team_member_count(TDM_TEAM_BRAVO)

	if(!alpha_total && !bravo_total)
		end_round(0, "nobody was left to fight")
		return TRUE
	// Eliminating the Terrorists does not end a round after they have planted:
	// the Counter-Terrorists still have to defuse C4 or let it explode.
	if(bomb_planted)
		if(bravo_alive <= 0)
			end_round(TDM_TEAM_ALPHA, "[team_one_name] eliminated [team_two_name]")
			return TRUE
		return FALSE
	if(alpha_alive <= 0 && bravo_alive <= 0)
		end_round(0, "both teams were wiped out")
		return TRUE
	if(alpha_alive <= 0)
		end_round(TDM_TEAM_BRAVO, "[team_two_name] eliminated [team_one_name]")
		return TRUE
	if(bravo_alive <= 0)
		end_round(TDM_TEAM_ALPHA, "[team_one_name] eliminated [team_two_name]")
		return TRUE
	return FALSE

/**
 * Closes the current round, awards the point, and either starts the next round
 * or ends the match.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/end_round(winner_team, reason = null)
	if(is_finished() || !round_live)
		return FALSE
	round_live = FALSE
	// Invalidates the round timer that is still sitting on the timer queue.
	round_token++
	if(!isnull(round_bomb) && !QDELETED(round_bomb))
		round_bomb.deactivate()
	bomb_planted = FALSE

	if(winner_team == TDM_TEAM_ALPHA)
		team_one_score++
	else if(winner_team == TDM_TEAM_BRAVO)
		team_two_score++

	announce_to_players(span_boldnotice("Round [round_number] over[reason ? ": [reason]" : ""]."))
	if(winner_team)
		announce_to_players(span_notice("[team_name(winner_team)] takes the round. [team_one_name] [team_one_score] - [team_two_score] [team_two_name]"))
	else
		announce_to_players(span_notice("No point awarded. [team_one_name] [team_one_score] - [team_two_score] [team_two_name]"))
	refresh_uis()

	// Only the score decides the match. No round cap and no preset exhaustion:
	// a drawn round awards no point, so play simply continues until one side
	// reaches rounds_to_win (or the outer match clock fires).
	if(team_one_score >= rounds_to_win || team_two_score >= rounds_to_win)
		addtimer(CALLBACK(src, PROC_REF(finish_match)), intermission_time)
	else
		addtimer(CALLBACK(src, PROC_REF(start_round)), intermission_time)
	return TRUE

/datum/deathmatch_lobby/team_deathmatch/end_lobby(delete_arena = TRUE, reason = "")
	clear_round_bomb()
	return ..()

/// The match is over: announce the winner, pay the pot to their team, tear the
/// lobby down.
/datum/deathmatch_lobby/team_deathmatch/proc/finish_match(forced_winner = 0)
	if(is_finished())
		return FALSE
	round_live = FALSE
	var/winner_team = forced_winner
	if(!winner_team)
		if(team_one_score > team_two_score)
			winner_team = TDM_TEAM_ALPHA
		else if(team_two_score > team_one_score)
			winner_team = TDM_TEAM_BRAVO

	if(!winner_team)
		to_chat(world, span_boldnotice("[template.display_name] ends in a draw, [team_one_score] - [team_two_score]."))
		refund_all_bets()
		end_lobby(reason = "the match ended in a draw")
		return TRUE

	var/winner_name = team_name(winner_team)
	to_chat(world, span_boldnotice("[winner_name] wins [template.display_name], [max(team_one_score, team_two_score)] - [min(team_one_score, team_two_score)]!"))
	award_team_pot(winner_team)
	end_lobby(reason = "[winner_name] won the match")
	return TRUE

/// Splits a non-empty pot between the winning team's fighters. Betters on the
/// losing team lose their stake, which is the point of a stake.
/datum/deathmatch_lobby/team_deathmatch/proc/award_team_pot(winner_team)
	if(pot <= 0)
		return
	var/list/winners = list()
	for(var/datum/deathmatch_player/player as anything in players)
		if(isnull(player) || player.is_observer || player.team != winner_team)
			continue
		winners += player
	if(!length(winners))
		refund_all_bets()
		return
	var/payout = pot
	pot = 0
	var/share = round(payout / length(winners))
	if(share <= 0)
		refund_all_bets()
		return
	for(var/datum/deathmatch_player/player as anything in winners)
		if(!player.ckey)
			continue
		SSmetadollars.metadollar_adjust(share, player.ckey, player.real_body?.key)
	to_chat(world, span_boldnotice("[payout] M$ goes to [team_name(winner_team)]."))

//
// Upkeep.
//

/**
 * TDM's reap: dead fighters are eliminated for the round, not kicked out of the
 * lobby. Only players who disconnect or quit VR by hand leave the game.
 */
/datum/deathmatch_lobby/team_deathmatch/reap_bodies()
	if(is_finished())
		return
	if(state == DM_LOBBY_RUNNING)
		for(var/datum/deathmatch_player/player as anything in players.Copy())
			if(isnull(player))
				players -= player
				continue
			if(player.is_observer)
				if(isnull(player.real_body) || QDELETED(player.real_body) || !player.real_body.key)
					players -= player
				continue
			// The real body is where the ckey goes back after a round death, so
			// it has to exist even when the avatar does not.
			if(isnull(player.real_body) || QDELETED(player.real_body))
				if(isnull(player.vr_body) || QDELETED(player.vr_body))
					players -= player
					continue
			var/mob/living/vr_body = player.vr_body
			if(isnull(vr_body) || QDELETED(vr_body) || vr_body.stat == DEAD)
				player.is_eliminated = TRUE
				continue
			// Alive and no ckey: virtual_reality has taken the player back to
			// their real body, either through the Quit VR action or a
			// disconnect. Neither leaves them able to come back this round.
			if(!vr_body.key)
				players -= player
				evict_body(player, "You left [template.display_name].")
				continue
		if(round_live)
			check_round_end()

	if(!players.len)
		end_lobby(reason = "everybody left")
		return
	if(state == DM_LOBBY_RUNNING && combatant_count() <= 0)
		end_lobby(reason = "everybody fighting left")
		return
	if(!is_finished())
		addtimer(CALLBACK(src, PROC_REF(reap_bodies)), reap_interval)

/// The match clock. Team rounds have their own clock; this is only the outer
/// limit for a game that has dragged on too long.
/datum/deathmatch_lobby/team_deathmatch/on_time_up()
	if(is_finished())
		return
	to_chat(world, span_boldnotice("[template.display_name] has run out of time."))
	finish_match()

//
// TGUI.
//

/datum/deathmatch_lobby/team_deathmatch/ui_data(mob/user)
	. = ..()
	var/datum/deathmatch_player/you = player_of(user?.ckey)
	var/your_team = you?.team || 0
	// An observer has no side, so the roster shows them the Terrorist half rather
	// than nothing at all.
	var/your_kit = get_round_loadout(team = your_team || TDM_TEAM_ALPHA)
	var/alpha_kit = get_round_loadout(team = TDM_TEAM_ALPHA)
	var/bravo_kit = get_round_loadout(team = TDM_TEAM_BRAVO)
	.["team_deathmatch"] = list(
		"round" = round_number,
		"round_live" = round_live,
		"round_time_left" = DisplayTimeText(round_time_left()),
		"score_one" = team_one_score,
		"score_two" = team_two_score,
		"team_one_name" = team_one_name,
		"team_two_name" = team_two_name,
		"rounds_to_win" = rounds_to_win,
		"your_team" = your_team,
		"kit_one" = loadout_name(alpha_kit),
		"kit_two" = loadout_name(bravo_kit),
	)
	// There is nothing to pick: the rotation decides, and the picker is handed
	// exactly this round's kit for the viewer's own side so it has something to
	// render and so its selection matches what the body will spawn with.
	.["your_loadout"] = your_kit
	var/list/kits = list()
	var/list/kit_row = list()
	UNTYPED_LIST_ADD(kit_row, your_kit)
	UNTYPED_LIST_ADD(kit_row, loadout_name(your_kit))
	UNTYPED_LIST_ADD(kit_row, "")
	UNTYPED_LIST_ADD(kits, kit_row)
	.["your_loadouts"] = kits

/// Chat to everybody with an avatar right now. Dead players are back in their
/// real body and can still read it there.
/datum/deathmatch_lobby/team_deathmatch/proc/announce_to_players(message)
	for(var/datum/deathmatch_player/player as anything in players)
		if(isnull(player))
			continue
		var/mob/target = player.vr_body
		if(isnull(target) || QDELETED(target))
			target = player.real_body
		if(isnull(target) || QDELETED(target))
			continue
		to_chat(target, message)

#undef TDM_TEAM_ALPHA
#undef TDM_TEAM_BRAVO

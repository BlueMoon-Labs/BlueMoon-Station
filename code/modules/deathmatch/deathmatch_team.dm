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
// of it. Nobody picks; the rotation picks for them.
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
	/// The outer match clock. A match is three to five two minute rounds plus
	/// intermissions, so this leaves room for a fifth round to run long and is
	/// only the backstop for a match that somehow never reaches its win
	/// condition.
	game_time = 15 MINUTES
	/// Rounds a team has to take to win the match. With the round cap below
	/// (rounds_to_win * 2 - 1) this makes a match three to five rounds long.
	var/rounds_to_win = 3
	var/team_one_score = 0
	var/team_two_score = 0
	var/team_one_name = "Terrorists"
	var/team_two_name = "Counter-Terrorists"
	/// Kits are handed out automatically, one pair per round, in this order.
	/// Each entry is a pair: the first path goes to TDM_TEAM_ALPHA, the second to
	/// TDM_TEAM_BRAVO. Rounds cycle through the list, so a match that goes the
	/// full five rounds shows every entry exactly once.
	var/list/loadout_rotation = list(
		list(
			/datum/outfit/vr/deathmatch_loadout/tdm_shotgun_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_shotgun_counter,
		),
		list(
			/datum/outfit/vr/deathmatch_loadout/tdm_pistol_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_pistol_counter,
		),
		list(
			/datum/outfit/vr/deathmatch_loadout/tdm_deagle,
			/datum/outfit/vr/deathmatch_loadout/tdm_deagle,
		),
		list(
			/datum/outfit/vr/deathmatch_loadout/tdm_sniper_terror,
			/datum/outfit/vr/deathmatch_loadout/tdm_sniper_counter,
		),
		list(
			/datum/outfit/vr/deathmatch_loadout/tdm_knives,
			/datum/outfit/vr/deathmatch_loadout/tdm_knives,
		),
	)

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

/// The pair of kits for a 1-based round number. Rounds cycle through
/// loadout_rotation, so the same pair comes back around if a match outlives the
/// list.
/datum/deathmatch_lobby/team_deathmatch/proc/get_round_kits(round = null)
	if(!length(loadout_rotation))
		return null
	var/wanted_round = isnull(round) ? (round_live ? round_number : round_number + 1) : round
	wanted_round = max(wanted_round, 1)
	return loadout_rotation[(wanted_round - 1) % length(loadout_rotation) + 1]

/**
 * The kit one team gets for a round.
 *
 * `round` defaults to the round that is running, or the next one if none is, so
 * the roster before the first round and the announcement when a round starts
 * both agree on what is coming. `team` defaults to the Terrorist side.
 *
 * A rotation entry is a pair of paths. A lone path is also accepted, which is
 * what a hand-written rotation or a map-specific override would look like, and
 * is handed to both teams.
 */
/datum/deathmatch_lobby/team_deathmatch/proc/get_round_loadout(round = null, team = TDM_TEAM_ALPHA)
	var/list/kits = get_round_kits(round)
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
	// Kits are handed out by the round rotation. Letting somebody pick one here
	// would only last until the round starts.
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

	announce_to_players(span_boldnotice("Round [round_number] of [rounds_to_win * 2 - 1] begins. Kits: [round_kits_label()]."))
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

	if(team_one_score >= rounds_to_win || team_two_score >= rounds_to_win || team_one_score + team_two_score >= rounds_to_win * 2 - 1)
		addtimer(CALLBACK(src, PROC_REF(finish_match)), intermission_time)
	else
		addtimer(CALLBACK(src, PROC_REF(start_round)), intermission_time)
	return TRUE

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

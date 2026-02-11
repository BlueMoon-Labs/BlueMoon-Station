#define DEFAULT_TEAM_SIZE 3

/client/proc/thunderome()
  set name = "Start Thunderome"
  set desc = "Start thunderome for ghosts"
  set category = "Admin.Events"

  var/datum/start_thunderome/ui = new(usr)
  ui.ui_interact(usr)

/datum/start_thunderome
  var/client/user
  
  var/datum/outfit/selected_outfit_1 = /datum/outfit
  var/datum/outfit/selected_outfit_2 = /datum/outfit

  var/dummy_1_key
  var/dummy_2_key

  var/team_1_size = DEFAULT_TEAM_SIZE
  var/team_2_size = DEFAULT_TEAM_SIZE

/datum/start_thunderome/New(_user)
  user = CLIENT_FROM_VAR(_user)

/datum/start_thunderome/ui_interact(mob/user, datum/tgui/ui)
  ui = SStgui.try_update_ui(user, src, ui)
  if(!ui)
    ui = new(user, src, "StartThunderome")
    ui.open()
    ui.set_autoupdate(FALSE)

/datum/start_thunderome/ui_state(mob/user)
  return GLOB.admin_state

/datum/start_thunderome/proc/init_dummy()
  dummy_1_key = "createthunderomeUI_[user]_1"
  dummy_2_key = "createthunderomeUI_[user]_2"

  generate_or_wait_for_human_dummy(dummy_1_key)
  generate_or_wait_for_human_dummy(dummy_2_key)

  unset_busy_human_dummy(dummy_1_key)
  unset_busy_human_dummy(dummy_2_key)
  return

/datum/start_thunderome/ui_data(mob/user)
  var/list/data = list()
  data["team_1"] = list()
  data["team_2"] = list()
  if(!dummy_1_key || !dummy_2_key)
    init_dummy()
  var/icon/dummysprite_1 = get_flat_human_icon(null,
    dummy_key = dummy_1_key,
    outfit_override = selected_outfit_1,
    no_anim = TRUE)
  data["team_1"]["icon64"] = icon2base64(dummysprite_1)

  var/icon/dummysprite_2 = get_flat_human_icon(null,
    dummy_key = dummy_2_key,
    outfit_override = selected_outfit_2,
    no_anim = TRUE)
  data["team_2"]["icon64"] = icon2base64(dummysprite_2)

  data["team_1"]["players"] = team_1_size
  data["team_2"]["players"] = team_2_size

  return data

/datum/start_thunderome/ui_close(mob/user)
  clear_human_dummy(dummy_1_key)
  clear_human_dummy(dummy_2_key)
  qdel(src)

/datum/start_thunderome/ui_act(action, params)
  . = ..()
  if(.)
    return

  var/team = params["team"]
  team = check_str_and_return_as_num(team)
  switch(action)
    if("select-equip")
      if(!team)
        return
      switch (team)
        if (1)
          selected_outfit_1 = tgui_input_list(user, "Выбери аутфит", "", subtypesof(/datum/outfit), selected_outfit_1)
          return TRUE
        if (2)
          selected_outfit_2 = tgui_input_list(user, "Выбери аутфит", "", subtypesof(/datum/outfit), selected_outfit_2)
          return TRUE
    if ("team-set-players")
      if(!team)
        return
      var/players = params["players"]
      players = check_str_and_return_as_num(players)
      switch (team)
        if (1)
          team_1_size = players
          return TRUE
        if (2)
          team_2_size = players
          return TRUE
    if ("start-thunderome")
      SStgui.close_uis(src)
      var/list/mob/candidates = pollGhostCandidates("Do you wish to be considered for Thunderome?", "Thunderome", null, priority_check = FALSE)
      if(candidates.len > 0)
        var/team_1_coeff = team_1_size / (team_2_size + team_1_size)
        var/team_1_players_num = round_down(team_1_coeff * candidates.len)
        var/team_2_players_num = candidates.len - team_1_players_num
        var/list/spawnpoints_t1 = GLOB.tdome1
        while(team_1_players_num)
          var/spawnloc = spawnpoints_t1[team_1_players_num]
          var/mob/chosen_candidate = pick_n_take(candidates)
          if(!chosen_candidate.key)
            continue
          var/mob/living/carbon/human/thunderwarior = new /mob/living/carbon/human(spawnloc)
          chosen_candidate.client.prefs.copy_to(thunderwarior)
          chosen_candidate.transfer_ckey(thunderwarior)
          if(thunderwarior.dna.species.dangerous_existence) // Don't want any exploding plasmemes
            thunderwarior.set_species(/datum/species/human)
          
          thunderwarior.equipOutfit(selected_outfit_1)
          thunderwarior.regenerate_icons()
          team_1_players_num--

        var/list/spawnpoints_t2 = GLOB.tdome2
        while(team_2_players_num)
          var/spawnloc = spawnpoints_t2[team_2_players_num]
          var/mob/chosen_candidate = pick_n_take(candidates)
          if(!chosen_candidate.key)
            continue

          var/mob/living/carbon/human/thunderwarior = new /mob/living/carbon/human(spawnloc)
          chosen_candidate.client.prefs.copy_to(thunderwarior)
          chosen_candidate.transfer_ckey(thunderwarior)

          if(thunderwarior.dna.species.dangerous_existence) // Don't want any exploding plasmemes
            thunderwarior.set_species(/datum/species/human)
          thunderwarior.equipOutfit(selected_outfit_2)
          thunderwarior.regenerate_icons()
          team_2_players_num--
        return TRUE

/datum/start_thunderome/proc/check_str_and_return_as_num(str)
  if(!str)
    return
  if(!isnum(str))
    return
  return text2num(str)

#undef DEFAULT_TEAM_SIZE

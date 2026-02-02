#define APPEARANCE_CATEGORY_COLUMN "<td valign='top' width='17%'>"
#define MAX_MUTANT_ROWS 5

/datum/preferences
	max_save_slots = DEFAULT_SAVE_SLOTS
	var/unholypref = "No" //Goin 2 hell fo dis one
//	var/stomppref = TRUE // Please step on me.
	var/list/gfluid_blacklist = list() //Stuff you don't want people to cum into you
	var/new_character_creator = TRUE // old/new character creator
	var/show_in_directory = 1	//Show in Character Directory
	var/directory_tag = "Unset" //Sorting tag to use in character directory
	var/directory_erptag = "Unset"	//ditto, but for non-vore scenes
	var/directory_ad = ""		//Advertisement stuff to show in character directory.
	var/fuzzy = FALSE			//Fuzzy scaling

/datum/preferences/New(client/C)
	// Check if readable fluids list exists
	// Please move this check a better location if possible
	if(!GLOB.genital_fluids_list)
		// Build list
		build_genital_fluids_list()

	//Extra saves for donators
	max_save_slots = CONFIG_GET(number/base_save_slots)
	if(istype(C))
		var/extra_slots = 0
		if(IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_3))
			extra_slots = 30
		else if(IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_2))
			extra_slots = 20
		else if(IS_CKEY_DONATOR_GROUP(C.key, DONATOR_GROUP_TIER_1))
			extra_slots = 10
		max_save_slots = max_save_slots + extra_slots

	. = ..()

/datum/preferences/copy_to(mob/living/carbon/human/character, icon_updates, roundstart_checks, initial_spawn)
	character.fuzzy = fuzzy
	. = ..()

/datum/preferences/ShowChoices(mob/user)
	//check if the player wants to use the new character creation menu
	if(new_character_creator)
		return ..()

	//Use the old character creation menu
	if(!user || !user.client)
		return
	update_preview_icon(current_tab)
	var/list/dat = list("<center>")

	var/settings_class = ""
	var/appearance_class = ""
	var/speech_class = ""
	var/loadout_class = ""
	var/game_prefs_class = ""
	var/content_prefs_class = ""
	var/keybinds_class = ""
	if(current_tab == SETTINGS_TAB)
		settings_class = "class='linkOn'"
	if(current_tab == APPEARANCE_TAB)
		appearance_class = "class='linkOn'"
	if(current_tab == SPEECH_TAB)
		speech_class = "class='linkOn'"
	if(current_tab == LOADOUT_TAB)
		loadout_class = "class='linkOn'"
	if(current_tab == GAME_PREFERENCES_TAB)
		game_prefs_class = "class='linkOn'"
	if(current_tab == CONTENT_PREFERENCES_TAB)
		content_prefs_class = "class='linkOn'"
	if(current_tab == KEYBINDINGS_TAB_OLD)
		keybinds_class = "class='linkOn'"

	dat += "<a href='?_src_=prefs;preference=tab;tab=[SETTINGS_TAB]' [settings_class]>Character Settings</a>"
	dat += "<a href='?_src_=prefs;preference=tab;tab=[APPEARANCE_TAB]' [appearance_class]>Character Appearance</a>"
	dat += "<a href='?_src_=prefs;preference=tab;tab=[SPEECH_TAB]' [speech_class]>Character Speech</a>"
	dat += "<a href='?_src_=prefs;preference=tab;tab=[LOADOUT_TAB]' [loadout_class]>Loadout</a>"
	dat += "<a href='?_src_=prefs;preference=tab;tab=[GAME_PREFERENCES_TAB]' [game_prefs_class]>Game Preferences</a>"
	dat += "<a href='?_src_=prefs;preference=tab;tab=[CONTENT_PREFERENCES_TAB]' [content_prefs_class]>Content Preferences</a>"
	dat += "<a href='?_src_=prefs;preference=tab;tab=[KEYBINDINGS_TAB_OLD]' [keybinds_class]>Keybindings</a>"
	var/char_setup_ui = "Old"
	if(new_character_creator)
		char_setup_ui = "New"
		if(findtext(charcreation_theme, "modern"))
			char_setup_ui = "Modern"
	dat += "<b>Character Setup UI ([char_setup_ui]):</b> <a href='?_src_=prefs;preference=charcreation_set;theme=old'>Old</a> <a href='?_src_=prefs;preference=charcreation_set;theme=classic'>New</a> <a href='?_src_=prefs;preference=charcreation_set;theme=modern'>Modern</a><br>"

	if(!path)
		dat += "<div class='notice'>Please create an account to save your preferences</div>"

	dat += "</center>"

	dat += "<HR>"

	switch(current_tab)
		if(SETTINGS_TAB) // Character Settings#
			if(path)
				var/savefile/S = new /savefile(path)
				if(S)
					dat += "<center>"
					var/name
					var/unspaced_slots = 0
					for(var/i=1, i<=max_save_slots, i++)
						unspaced_slots++
						if(unspaced_slots > 4)
							dat += "<br>"
							unspaced_slots = 0
						S.cd = "/character[i]"
						S["real_name"] >> name
						if(!name)
							name = "Character[i]"
						dat += "<a style='white-space:nowrap;' href='?_src_=prefs;preference=changeslot;num=[i];' [i == default_slot ? "class='linkOn'" : ""]>[name]</a> "
					dat += "</center>"

			dat += "<center><h2>Occupation Choices</h2>"
			dat += "<a href='?_src_=prefs;preference=job;task=menu'>Set Occupation Preferences</a><br></center>"
			if(CONFIG_GET(flag/roundstart_traits))
				dat += "<center><h2>Quirk Setup ([GetQuirkBalance(user)] points left)</h2>"
				dat += "<a href='?_src_=prefs;preference=trait;task=menu'>Configure Quirks</a><br></center>"
				dat += "<center><b>Current Quirks:</b> [all_quirks.len ? all_quirks.Join(", ") : "None"]</center>"
			dat += "<table width='100%'><tr><td valign='top'>"
			dat += "<h2>Identity</h2>"
			if(jobban_isbanned(user, "appearance"))
				dat += "<b>You are banned from using custom names and appearances. You can continue to adjust your characters, but you will be randomised once you join the game.</b><br>"
			dat += "<b>Always Random Name:</b><a style='display:block;width:30px' href='?_src_=prefs;preference=name'>[be_random_name ? "Yes" : "No"]</a><BR>"
			dat += "<b>Hardsuit With Tail:</b><a style='display:block;width:30px' href='?_src_=prefs;preference=hardsuit'>[features["hardsuit_with_tail"] == TRUE ? "Yes" : "No"]</a><BR>"

			dat += "<b>[nameless ? "Default designation" : "Name"]:</b>"
			dat += "<div class='csetup-name-row'><a href='?_src_=prefs;preference=name;task=input'>[real_name]</a><a class='csetup-dice-btn' href='?_src_=prefs;preference=name;task=random' title='Рандомное имя' aria-label='Рандомное имя'>&#127922;</a></div><BR>"
			dat += "<a href='?_src_=prefs;preference=nameless'>Be nameless: [nameless ? "Yes" : "No"]</a><BR>"

			dat += "<b>Gender:</b> <a href='?_src_=prefs;preference=gender;task=input'>[gender == MALE ? "Male" : (gender == FEMALE ? "Female" : (gender == PLURAL ? "Non-binary" : "Object"))]</a><BR>"
			dat += "<b>Age:</b> <a style='display:block;width:30px' href='?_src_=prefs;preference=age;task=input'>[age]</a><BR>"

			dat += "<b>Special Names:</b><BR>"
			var/old_group
			for(var/custom_name_id in GLOB.preferences_custom_names)
				var/namedata = GLOB.preferences_custom_names[custom_name_id]
				if(!old_group)
					old_group = namedata["group"]
				else if(old_group != namedata["group"])
					old_group = namedata["group"]
					dat += "<br>"
				dat += "<a href ='?_src_=prefs;preference=[custom_name_id];task=input'><b>[namedata["pref_name"]]:</b> [custom_names[custom_name_id]]</a> "
			dat += "<br><br>"

			dat += "<b>Custom job preferences:</b><BR>"
			dat += "<a href='?_src_=prefs;preference=ai_core_icon;task=input'><b>Preferred AI Core Display:</b> [preferred_ai_core_display]</a><br>"
			dat += "<a href='?_src_=prefs;preference=sec_dept;task=input'><b>Preferred Security Department:</b> [prefered_security_department]</a><BR></td>"
			dat += "<br><a href='?_src_=prefs;preference=hide_ckey;task=input'><b>Hide ckey: [hide_ckey ? "Enabled" : "Disabled"]</b></a><br>"
			dat += "</td>"

			dat += "<td valign='top'>"
			dat += "<h2>PDA preferences</h2>"
			dat += "<b>PDA Color:</b> <span style='border:1px solid #161616; background-color: [pda_color];'><font color='[color_hex2num(pda_color) < 200 ? "FFFFFF" : "000000"]'>[pda_color]</font></span> <a href='?_src_=prefs;preference=pda_color;task=input'>Change</a><BR>"
			dat += "<b>PDA Style:</b> <a href='?_src_=prefs;task=input;preference=pda_style'>[pda_style]</a><br>"
			dat += "<b>PDA Reskin:</b> <a href='?_src_=prefs;task=input;preference=pda_skin'>[pda_skin]</a><br>"
			dat += "<b>PDA Ringtone:</b> <a href='?_src_=prefs;task=input;preference=pda_ringtone'>[pda_ringtone]</a><br>"
			dat += "</td>"

			dat += "<h2>Silicon preferences</h2>"
			if(!CONFIG_GET(flag/allow_silicon_choosing_laws))
				dat += "<i>The server has disabled choosing your own laws, you can still choose and save, but it won't do anything in-game.</i><br>"
			dat += "<b>Starting lawset:</b> <a href='?_src_=prefs;task=input;preference=silicon_lawset'>[silicon_lawset ? silicon_lawset : "No custom"]</a><br>"

			if(silicon_lawset)
				var/list/config_laws = CONFIG_GET(keyed_list/choosable_laws)
				var/datum/ai_laws/law_datum = GLOB.all_law_datums[config_laws[silicon_lawset]]
				if(law_datum)
					dat += "<i>[law_datum]</i><br>"
					dat += english_list(law_datum.get_law_list(TRUE),
						"I was unable to find the laws for your lawset, sorry  <font style='translate: rotate(90deg)'>:(</font>",
						"<br>", "<br>")

			dat += "</td></tr></table>"

		//Character Appearance
		if(APPEARANCE_TAB)
			if(path)
				var/savefile/S = new /savefile(path)
				if(S)
					dat += "<center>"
					var/name
					var/unspaced_slots = 0
					for(var/i=1, i<=max_save_slots, i++)
						unspaced_slots++
						if(unspaced_slots > 4)
							dat += "<br>"
							unspaced_slots = 0
						S.cd = "/character[i]"
						S["real_name"] >> name
						if(!name)
							name = "Character[i]"
						dat += "<a style='white-space:nowrap;' href='?_src_=prefs;preference=changeslot;num=[i];' [i == default_slot ? "class='linkOn'" : ""]>[name]</a> "
					dat += "</center>"

			dat += "<table><tr><td width='20%' height='300px' valign='top'>"
			dat += "<h2>Flavor Text</h2>"
			dat += "<a href='?_src_=prefs;preference=flavor_text;task=input'><b>Set Examine Text</b></a><br>"
			if(length(features["flavor_text"]) <= MAX_FLAVOR_PREVIEW_LEN)
				if(!length(features["flavor_text"]))
					dat += "\[...\]<BR>" //skyrat - adds <br> //come to brazil or brazil comes to you
				else
					dat += "[html_encode(features["flavor_text"])]<BR>" //skyrat - adds <br> and uses html_encode
			else
				dat += "[TextPreview(html_encode(features["flavor_text"]))]...<BR>" //skyrat edit, uses html_encode
			//SPLURT edit - naked flavor text
			dat += "<h2>Naked Flavor Text</h2>"
			dat += "<a href='?_src_=prefs;preference=naked_flavor_text;task=input'><b>Set Naked Examine Text</b></a><br>"
			if(length(features["naked_flavor_text"]) <= 40)
				if(!length(features["naked_flavor_text"]))
					dat += "\[...\]<BR>"
				else
					dat += "[html_encode(features["naked_flavor_text"])]<BR>"
			else
				dat += "[TextPreview(html_encode(features["naked_flavor_text"]))]...<BR>"
			//SPLURT edit end
			dat += "<h2>Silicon Flavor Text</h2>"
			dat += "<a href='?_src_=prefs;preference=silicon_flavor_text;task=input'><b>Set Silicon Examine Text</b></a><br>"
			if(length(features["silicon_flavor_text"]) <= MAX_FLAVOR_PREVIEW_LEN)
				if(!length(features["silicon_flavor_text"]))
					dat += "\[...\]<BR>"
				else
					dat += "[features["silicon_flavor_text"]]<BR>"
			else
				dat += "[TextPreview(features["silicon_flavor_text"])]...<BR>"
			dat += "<h2>Custom Species Lore</h2>"
			dat += "<a href='?_src_=prefs;preference=custom_species_lore;task=input'><b>Set Custom Species Lore Text</b></a><br>"
			if(length(features["custom_species_lore"]) <= MAX_FLAVOR_PREVIEW_LEN)
				if(!length(features["custom_species_lore"]))
					dat += "\[...\]<BR>"
				else
					dat += "[features["custom_species_lore"]]<BR>"
			else
				dat += "[TextPreview(features["custom_species_lore"])]...<BR>"
			dat += "<h2>OOC notes</h2>"
			dat += "<a href='?_src_=prefs;preference=ooc_notes;task=input'><b>Set OOC notes</b></a><br>"
			var/ooc_notes_len = length(features["ooc_notes"])
			if(ooc_notes_len <= MAX_FLAVOR_PREVIEW_LEN)
				if(!ooc_notes_len)
					dat += "\[...\]<BR>"
				else
					dat += "[features["ooc_notes"]]<BR>"
			else
				dat += "[TextPreview(features["ooc_notes"])]...<BR>"
			//SPLURT EDIT
			dat += "<h2>Headshot Image</h2>"
			dat += "<a href='?_src_=prefs;preference=headshot'><b>Set Headshot Image</b></a><br>"
			if(features["headshot_link"])
				dat += "<img src='[features["headshot_link"]]' width='160px' height='120px'>"
			dat += "<br><br>"
			//SPLURT EDIT END
			//SKYRAT EDIT
			var/consent_preferences_label = src.use_modern_translations ? get_modern_text("consent_preferences", src) : "Consent preferences"
			var/erp_pref_label = src.use_modern_translations ? get_modern_text("erp_pref", src) : "ERP"
			var/noncon_pref_label = src.use_modern_translations ? get_modern_text("noncon_pref", src) : "Non-Con"
			var/vore_pref_label = src.use_modern_translations ? get_modern_text("vore_pref", src) : "Vore"
			var/mobsex_pref_label = src.use_modern_translations ? get_modern_text("mobsex_pref", src) : "Mob Non-Con Sex"
			var/hornyantags_pref_label = src.use_modern_translations ? get_modern_text("hornyantags_pref", src) : "Horny Antags"
			dat += "<h2>[consent_preferences_label]</h2>"
			dat += 	"[erp_pref_label] : <a href='?_src_=prefs;preference=erp_pref'>[erppref]</a><br>"
			dat += 	"[noncon_pref_label] : <a href='?_src_=prefs;preference=noncon_pref'>[nonconpref]</a><br>"
			dat += 	"[vore_pref_label] : <a href='?_src_=prefs;preference=vore_pref'>[vorepref]</a><br>"
			//END OF SKYRAT EDIT

			//Gardelin0 Addoon
			dat += 	"[mobsex_pref_label] : <a href='?_src_=prefs;preference=mobsex_pref'>[mobsexpref]</a><br>"
			dat += 	"[hornyantags_pref_label] : <a href='?_src_=prefs;preference=hornyantags_pref'>[hornyantagspref]</a><br>"
			//END OF Gardelin0 Addoon

			dat += "<h2>Records</h2><br>"
			dat += "<a href='?_src_=prefs;preference=security_records;task=input'><b>Security Records</b></a><br>"
			if(length_char(security_records) <= 40)
				if(!length(security_records))
					dat += "\[...\]"
				else
					dat += "[security_records]"
			else
				dat += "[TextPreview(security_records)]...<BR>"

			dat += "<br><a href='?_src_=prefs;preference=medical_records;task=input'><b>Medical Records</b></a><br>"
			if(length_char(medical_records) <= 40)
				if(!length(medical_records))
					dat += "\[...\]<br>"
				else
					dat += "[medical_records]"
			else
				dat += "[TextPreview(medical_records)]...<BR>"

			dat += APPEARANCE_CATEGORY_COLUMN //body moves right sandstorm change

			dat += "<h2>Body</h2>"
			dat += "<b>Gender:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=gender;task=input'>[gender == MALE ? "Male" : (gender == FEMALE ? "Female" : (gender == PLURAL ? "Non-binary" : "Object"))]</a><BR>"
			dat += "<b>Custom Blood Color:</b>"
			dat += "<a href='?_src_=prefs;preference=custom_blood_color'>[custom_blood_color ? "Enabled" : "Disabled"]</a><BR>"
			if(custom_blood_color)
				dat += "<b>Blood Color:</b> <span style='border:1px solid #161616; background-color: [blood_color];'><font color='[color_hex2num(blood_color) < 200 ? "FFFFFF" : "000000"]'>[blood_color]</font></span> <a href='?_src_=prefs;preference=blood_color;task=input'>Change</a><BR>"
			if(pref_species.sexes)
				dat += "<b>Body Model:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=body_model'>[features["body_model"] == MALE ? "Masculine" : "Feminine"]</a><BR>"
			dat += "<b>Limb Modification:</b><BR>"
			dat += "<a href='?_src_=prefs;preference=modify_limbs;task=input'>Modify Limbs</a><BR>"
			for(var/modification in modified_limbs)
				if(modified_limbs[modification][1] == LOADOUT_LIMB_PROSTHETIC)
					dat += "<b>[modification]: [modified_limbs[modification][2]]</b><BR>"
				else
					dat += "<b>[modification]: [modified_limbs[modification][1]]</b><BR>"
			dat += "<BR>"
			dat += "<b>Species:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=species;task=input'>[pref_species.name]</a><BR>"
			dat += "<b>Custom Species Name:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=custom_species;task=input'>[custom_species ? custom_species : "None"]</a><BR>"
			dat += "<b>Random Body:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=all;task=random'>Randomize!</A><BR>"
			dat += "<b>Always Random Body:</b><a href='?_src_=prefs;preference=all'>[be_random_body ? "Yes" : "No"]</A><BR>"
			dat += "<br><b>Cycle background:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=cycle_bg;task=input'>[bgstate]</a><BR>"

			dat += "</td>" //body moves right sandstorm change

			var/use_skintones = pref_species.use_skintones
			if(use_skintones)
				dat += APPEARANCE_CATEGORY_COLUMN

				dat += "<h3>Skin Tone</h3>"

				dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=s_tone;task=input'>[use_custom_skin_tone ? "custom: <span style='border:1px solid #161616; background-color: [skin_tone];'><font color='[color_hex2num(skin_tone) < 200 ? "FFFFFF" : "000000"]'>[skin_tone]</font></span>" : skin_tone]</a><BR>"

			var/mutant_colors
			if((MUTCOLORS in pref_species.species_traits) || (MUTCOLORS_PARTSONLY in pref_species.species_traits))
				if(!use_skintones)
					dat += APPEARANCE_CATEGORY_COLUMN

				dat += "<h3>Advanced Coloring</h3>"
				dat += "</b><a style='display:block;width:100px' href='?_src_=prefs;preference=color_scheme;task=input'>[(features["color_scheme"] == ADVANCED_CHARACTER_COLORING) ? "Enabled" : "Disabled"]</a>"

				dat += "<h2>Body Colors</h2>"

				dat += "<b>Primary Color:</b><BR>"
				dat += "<span style='border: 1px solid #161616; background-color: #[features["mcolor"]];'><font color='[color_hex2num(features["mcolor"]) < 200 ? "FFFFFF" : "000000"]'>#[features["mcolor"]]</font></span> <a href='?_src_=prefs;preference=mutant_color;task=input'>Change</a><BR>"

				dat += "<b>Secondary Color:</b><BR>"
				dat += "<span style='border: 1px solid #161616; background-color: #[features["mcolor2"]];'><font color='[color_hex2num(features["mcolor2"]) < 200 ? "FFFFFF" : "000000"]'>#[features["mcolor2"]]</font></span> <a href='?_src_=prefs;preference=mutant_color2;task=input'>Change</a><BR>"

				dat += "<b>Tertiary Color:</b><BR>"
				dat += "<span style='border: 1px solid #161616; background-color: #[features["mcolor3"]];'><font color='[color_hex2num(features["mcolor3"]) < 200 ? "FFFFFF" : "000000"]'>#[features["mcolor3"]]</font></span> <a href='?_src_=prefs;preference=mutant_color3;task=input'>Change</a><BR>"
				mutant_colors = TRUE

				dat += "<b>Sprite Size:</b> <a href='?_src_=prefs;preference=body_size;task=input'>[features["body_size"]*100]%</a><br>"
				dat += "<b>Scaled Appearance:</b> <a href='?_src_=prefs;preference=toggle_fuzzy;task=input'>[fuzzy ? "Fuzzy" : "Sharp"]</a><br>"

			if(!(NOEYES in pref_species.species_traits))
				dat += "<h3>Eye Type</h3>"
				dat += "</b><a style='display:block;width:100px' href='?_src_=prefs;preference=eye_type;task=input'>[eye_type]</a><BR>"
				if((EYECOLOR in pref_species.species_traits))
					if(!use_skintones && !mutant_colors)
						dat += APPEARANCE_CATEGORY_COLUMN
					if(left_eye_color != right_eye_color)
						split_eye_colors = TRUE
					dat += "<h3>Heterochromia</h3>"
					dat += "</b><a style='display:block;width:100px' href='?_src_=prefs;preference=toggle_split_eyes;task=input'>[split_eye_colors ? "Enabled" : "Disabled"]</a>"
					if(!split_eye_colors)
						dat += "<h3>Eye Color</h3>"
						dat += "<span style='border: 1px solid #161616; background-color: #[left_eye_color];'><font color='[color_hex2num(left_eye_color) < 200 ? "FFFFFF" : "000000"]'>#[left_eye_color]</font></span> <a href='?_src_=prefs;preference=eyes;task=input'>Change</a>"
					else
						dat += "<h3>Left Eye Color</h3>"
						dat += "<span style='border: 1px solid #161616; background-color: #[left_eye_color];'><font color='[color_hex2num(left_eye_color) < 200 ? "FFFFFF" : "000000"]'>#[left_eye_color]</font></span> <a href='?_src_=prefs;preference=eye_left;task=input'>Change</a>"
						dat += "<h3>Right Eye Color</h3>"
						dat += "<span style='border: 1px solid #161616; background-color: #[right_eye_color];'><font color='[color_hex2num(right_eye_color) < 200 ? "FFFFFF" : "000000"]'>#[right_eye_color]</font></span> <a href='?_src_=prefs;preference=eye_right;task=input'>Change</a><BR>"

			if(HAIR in pref_species.species_traits)

				dat += APPEARANCE_CATEGORY_COLUMN

				dat += "<h3>Hair Style</h3>"

				dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=hair_style;task=input'>[hair_style]</a>"
				dat += "<a href='?_src_=prefs;preference=previous_hair_style;task=input'>&lt;</a> <a href='?_src_=prefs;preference=next_hair_style;task=input'>&gt;</a><BR>"
				dat += "<span style='border:1px solid #161616; background-color: #[hair_color];'><font color='[color_hex2num(hair_color) < 200 ? "FFFFFF" : "000000"]'>#[hair_color]</font></span> <a href='?_src_=prefs;preference=hair;task=input'>Change</a><BR>"

				dat += "<h3>Facial Hair Style</h3>"

				dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=facial_hair_style;task=input'>[facial_hair_style]</a>"
				dat += "<a href='?_src_=prefs;preference=previous_facehair_style;task=input'>&lt;</a> <a href='?_src_=prefs;preference=next_facehair_style;task=input'>&gt;</a><BR>"
				dat += "<span style='border: 1px solid #161616; background-color: #[facial_hair_color];'><font color='[color_hex2num(facial_hair_color) < 200 ? "FFFFFF" : "000000"]'>#[facial_hair_color]</font></span> <a href='?_src_=prefs;preference=facial;task=input'>Change</a><BR>"

				dat += "<h3>Hair Gradient</h3>"

				dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=grad_style;task=input'>[grad_style]</a>"
				dat += "<a href='?_src_=prefs;preference=previous_grad_style;task=input'>&lt;</a> <a href='?_src_=prefs;preference=next_grad_style;task=input'>&gt;</a><BR>"
				dat += "<span style='border: 1px solid #161616; background-color: #[grad_color];'><font color='[color_hex2num(grad_color) < 200 ? "FFFFFF" : "000000"]'>#[grad_color]</font></span> <a href='?_src_=prefs;preference=grad_color;task=input'>Change</a><BR>"

				dat += "</td>"
			//Mutant stuff
			var/mutant_category = 0

			dat += APPEARANCE_CATEGORY_COLUMN
			dat += "<h3>Show mismatched markings</h3>"
			dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=mismatched_markings;task=input'>[show_mismatched_markings ? "Yes" : "No"]</a>"
			mutant_category++
			if(mutant_category >= MAX_MUTANT_ROWS) //just in case someone sets the max rows to 1 or something dumb like that
				dat += "</td>"
				mutant_category = 0

			// rp marking selection
			// assume you can only have mam markings or regular markings or none, never both
			var/marking_type
			if(parent.can_have_part("mam_body_markings"))
				marking_type = "mam_body_markings"
			if(marking_type)
				dat += APPEARANCE_CATEGORY_COLUMN
				dat += "<h3>[src.use_modern_translations ? get_modern_text(marking_type, src) : GLOB.all_mutant_parts[marking_type]]</h3>" // give it the appropriate title for the type of marking
				dat += "<a href='?_src_=prefs;preference=marking_add;marking_type=[marking_type];task=input'>Add marking</a>"
				// list out the current markings you have
				if(length(features[marking_type]))
					dat += "<table>"
					var/list/markings = features[marking_type]
					if(!islist(markings))
						// something went terribly wrong
						markings = list()
					var/list/reverse_markings = reverseList(markings)
					for(var/list/marking_list in reverse_markings)
						var/marking_index = markings.Find(marking_list) // consider changing loop to go through indexes over lists instead of using Find here
						var/limb_value = marking_list[1]
						var/actual_name = GLOB.bodypart_names[num2text(limb_value)] // get the actual name from the bitflag representing the part the marking is applied to
						var/color_marking_dat = ""
						var/number_colors = 1
						var/datum/sprite_accessory/mam_body_markings/S = GLOB.mam_body_markings_list[marking_list[2]]
						var/matrixed_sections = S.covered_limbs[actual_name]
						if(S && matrixed_sections)
							// if it has nothing initialize it to white
							if(length(marking_list) == 2)
								var/first = "#FFFFFF"
								var/second = "#FFFFFF"
								var/third = "#FFFFFF"
								if(features["mcolor"])
									first = "#[features["mcolor"]]"
								if(features["mcolor2"])
									second = "#[features["mcolor2"]]"
								if(features["mcolor3"])
									third = "#[features["mcolor3"]]"
								marking_list += list(list(first, second, third)) // just assume its 3 colours if it isnt it doesnt matter we just wont use the other values
							// index magic
							var/primary_index = 1
							var/secondary_index = 2
							var/tertiary_index = 3
							switch(matrixed_sections)
								if(MATRIX_GREEN)
									primary_index = 2
								if(MATRIX_BLUE)
									primary_index = 3
								if(MATRIX_RED_BLUE)
									secondary_index = 2
								if(MATRIX_GREEN_BLUE)
									primary_index = 2
									secondary_index = 3

							// we know it has one matrixed section at minimum
							color_marking_dat += "<span style='border: 1px solid #161616; background-color: [marking_list[3][primary_index]];'><font color='[color_hex2num(marking_list[3][primary_index]) < 200 ? "FFFFFF" : "000000"]'>[marking_list[3][primary_index]]</font></span>"
							// if it has a second section, add it
							if(matrixed_sections == MATRIX_RED_BLUE || matrixed_sections == MATRIX_GREEN_BLUE || matrixed_sections == MATRIX_RED_GREEN || matrixed_sections == MATRIX_ALL)
								color_marking_dat += "<span style='border: 1px solid #161616; background-color: [marking_list[3][secondary_index]];'><font color='[color_hex2num(marking_list[3][secondary_index]) < 200 ? "FFFFFF" : "000000"]'>[marking_list[3][secondary_index]]</font></span>"
								number_colors = 2
							// if it has a third section, add it
							if(matrixed_sections == MATRIX_ALL)
								color_marking_dat += "<span style='border: 1px solid #161616; background-color: [marking_list[3][tertiary_index]];'><font color='[color_hex2num(marking_list[3][tertiary_index]) < 200 ? "FFFFFF" : "000000"]'>[marking_list[3][tertiary_index]]</font></span>"
								number_colors = 3
							color_marking_dat += " <a href='?_src_=prefs;preference=marking_color;marking_index=[marking_index];marking_type=[marking_type];number_colors=[number_colors];task=input'>Change</a><BR>"
						dat += "<tr><td>[marking_list[2]] - [actual_name]</td> <td><a href='?_src_=prefs;preference=marking_down;task=input;marking_index=[marking_index];marking_type=[marking_type];'>&#708;</a> <a href='?_src_=prefs;preference=marking_up;task=input;marking_index=[marking_index];marking_type=[marking_type]'>&#709;</a> <a href='?_src_=prefs;preference=marking_remove;task=input;marking_index=[marking_index];marking_type=[marking_type]'>X</a> [color_marking_dat]</td></tr>"
					dat += "</table>"

			for(var/mutant_part in GLOB.all_mutant_parts)
				if(mutant_part == "mam_body_markings")
					continue
				if(parent.can_have_part(mutant_part))
					if(!mutant_category)
						dat += APPEARANCE_CATEGORY_COLUMN
					var/mutant_part_label = src.use_modern_translations ? get_modern_text(mutant_part, src) : GLOB.all_mutant_parts[mutant_part]
					dat += "<h3>[mutant_part_label]</h3>"
					dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=[mutant_part];task=input'>[features[mutant_part]]</a>"
					var/color_type = GLOB.colored_mutant_parts[mutant_part] //if it can be coloured, show the appropriate button
					if(color_type)
						dat += "<span style='border:1px solid #161616; background-color: #[features[color_type]];'><font color='[color_hex2num(features[color_type]) < 200 ? "FFFFFF" : "000000"]'>#[features[color_type]]</font></span> <a href='?_src_=prefs;preference=[color_type];task=input'>Change</a><BR>"
					else
						if(features["color_scheme"] == ADVANCED_CHARACTER_COLORING) //advanced individual part colouring system
							//is it matrixed or does it have extra parts to be coloured?
							var/find_part = features[mutant_part] || pref_species.mutant_bodyparts[mutant_part]
							var/find_part_list = GLOB.mutant_reference_list[mutant_part]
							if(find_part && find_part != "None" && find_part_list)
								var/datum/sprite_accessory/accessory = find_part_list[find_part]
								if(accessory)
									if(accessory.color_src == MATRIXED || accessory.color_src == MUTCOLORS || accessory.color_src == MUTCOLORS2 || accessory.color_src == MUTCOLORS3) //mutcolors1-3 are deprecated now, please don't rely on these in the future
										var/mutant_string = accessory.mutant_part_string
										var/primary_feature = "[mutant_string]_primary"
										var/secondary_feature = "[mutant_string]_secondary"
										var/tertiary_feature = "[mutant_string]_tertiary"
										if(!features[primary_feature])
											features[primary_feature] = features["mcolor"]
										if(!features[secondary_feature])
											features[secondary_feature] = features["mcolor2"]
										if(!features[tertiary_feature])
											features[tertiary_feature] = features["mcolor3"]

										var/matrixed_sections = accessory.matrixed_sections
										if(accessory.color_src == MATRIXED && !matrixed_sections)
											message_admins("Sprite Accessory Failure (customization): Accessory [accessory.type] is a matrixed item without any matrixed sections set!")
											continue
										else if(accessory.color_src == MATRIXED)
											switch(matrixed_sections)
												if(MATRIX_GREEN) //only composed of a green section
													primary_feature = secondary_feature //swap primary for secondary, so it properly assigns the second colour, reserved for the green section
												if(MATRIX_BLUE)
													primary_feature = tertiary_feature //same as above, but the tertiary feature is for the blue section
												if(MATRIX_RED_BLUE) //composed of a red and blue section
													secondary_feature = tertiary_feature //swap secondary for tertiary, as blue should always be tertiary
												if(MATRIX_GREEN_BLUE) //composed of a green and blue section
													primary_feature = secondary_feature //swap primary for secondary, as first option is green, which is linked to the secondary
													secondary_feature = tertiary_feature //swap secondary for tertiary, as second option is blue, which is linked to the tertiary
										dat += "<b>Primary Color</b><BR>"
										dat += "<span style='border:1px solid #161616; background-color: #[features[primary_feature]];'><font color='[color_hex2num(features[primary_feature]) < 200 ? "FFFFFF" : "000000"]'>#[features[primary_feature]]</font></span> <a href='?_src_=prefs;preference=[primary_feature];task=input'>Change</a><BR>"
										if((accessory.color_src == MATRIXED && (matrixed_sections == MATRIX_RED_BLUE || matrixed_sections == MATRIX_GREEN_BLUE || matrixed_sections == MATRIX_RED_GREEN || matrixed_sections == MATRIX_ALL)) || (accessory.extra && (accessory.extra_color_src == MUTCOLORS || accessory.extra_color_src == MUTCOLORS2 || accessory.extra_color_src == MUTCOLORS3)))
											dat += "<b>Secondary Color</b><BR>"
											dat += "<span style='border:1px solid #161616; background-color: #[features[secondary_feature]];'><font color='[color_hex2num(features[secondary_feature]) < 200 ? "FFFFFF" : "000000"]'>#[features[secondary_feature]]</font></span> <a href='?_src_=prefs;preference=[secondary_feature];task=input'>Change</a><BR>"
											if((accessory.color_src == MATRIXED && matrixed_sections == MATRIX_ALL) || (accessory.extra2 && (accessory.extra2_color_src == MUTCOLORS || accessory.extra2_color_src == MUTCOLORS2 || accessory.extra2_color_src == MUTCOLORS3)))
												dat += "<b>Tertiary Color</b><BR>"
												dat += "<span style='border:1px solid #161616; background-color: #[features[tertiary_feature]];'><font color='[color_hex2num(features[tertiary_feature]) < 200 ? "FFFFFF" : "000000"]'>#[features[tertiary_feature]]</font></span> <a href='?_src_=prefs;preference=[tertiary_feature];task=input'>Change</a><BR>"

					mutant_category++
					if(mutant_category >= MAX_MUTANT_ROWS)
						dat += "</td>"
						mutant_category = 0

			if(length(pref_species.allowed_limb_ids))
				if(!chosen_limb_id || !(chosen_limb_id in pref_species.allowed_limb_ids))
					chosen_limb_id = pref_species.limbs_id || pref_species.id
				dat += "<h3>Body sprite</h3>"
				dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=bodysprite;task=input'>[chosen_limb_id]</a>"

			if(mutant_category)
				dat += "</td>"
				mutant_category = 0

			dat += "</tr></table>"

			dat += "</td>"
			dat += "<table><tr><td width='340px' height='300px' valign='top'>"
			var/clothing_equipment_label = src.use_modern_translations ? get_modern_text("clothing_equipment", src) : "Clothing & Equipment"
			var/backpack_label = src.use_modern_translations ? get_modern_text("backpack", src) : "Backpack"
			var/jumpsuit_label = src.use_modern_translations ? get_modern_text("jumpsuit", src) : "Jumpsuit"
			dat += "<h2>[clothing_equipment_label]</h2>"
			/* skyrat change
			dat += "<b>Underwear:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=underwear;task=input'>[underwear]</a>"
			if(GLOB.underwear_list[underwear]?.has_color)
				dat += "<b>Underwear Color:</b> <span style='border:1px solid #161616; background-color: #[undie_color];'><font color='[color_hex2num(undie_color) < 200 ? "FFFFFF" : "000000"]'>#[undie_color]</font></span> <a href='?_src_=prefs;preference=undie_color;task=input'>Change</a><BR>"
			dat += "<b>Undershirt:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=undershirt;task=input'>[undershirt]</a>"
			if(GLOB.undershirt_list[undershirt]?.has_color)
				dat += "<b>Undershirt Color:</b> <span style='border:1px solid #161616; background-color: #[shirt_color];'><font color='[color_hex2num(shirt_color) < 200 ? "FFFFFF" : "000000"]'>#[shirt_color]</font></span> <a href='?_src_=prefs;preference=shirt_color;task=input'>Change</a><BR>"
			dat += "<b>Socks:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=socks;task=input'>[socks]</a>"
			if(GLOB.socks_list[socks]?.has_color)
				dat += "<b>Socks Color:</b> <span style='border:1px solid #161616; background-color: #[socks_color];'><font color='[color_hex2num(socks_color) < 200 ? "FFFFFF" : "000000"]'>#[socks_color]</font></span> <a href='?_src_=prefs;preference=socks_color;task=input'>Change</a><BR>"
			*/
			dat += "<b>[backpack_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=bag;task=input'>[backbag]</a>"
			dat += "<b>[jumpsuit_label]:</b><BR><a href ='?_src_=prefs;preference=suit;task=input'>[jumpsuit_style]</a><BR>"
			if((HAS_FLESH in pref_species.species_traits) || (HAS_BONE in pref_species.species_traits))
				dat += "<BR><b>Temporal Scarring:</b><BR><a href='?_src_=prefs;preference=persistent_scars'>[(persistent_scars) ? "Enabled" : "Disabled"]</A>"
				dat += "<a href='?_src_=prefs;preference=clear_scars'>Clear scar slots</A><BR>"
			dat += "<b>Uplink Location:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=uplink_loc;task=input'>[uplink_spawn_loc]</a>"
			dat += "</td>"

			dat += "<table><tr><td height='300px' valign='top'>"
			var/lewd_preferences_label = src.use_modern_translations ? get_modern_text("lewd_preferences", src) : "Lewd preferences"
			var/lust_tolerance_label = src.use_modern_translations ? get_modern_text("lust_tolerance", src) : "Lust tolerance"
			var/sexual_potency_label = src.use_modern_translations ? get_modern_text("sexual_potency", src) : "Sexual potency"
			dat += "<h2>[lewd_preferences_label]</h2>"
			dat += "<b>[lust_tolerance_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=lust_tolerance;task=input'>[lust_tolerance]</a>"
			dat += "<b>[sexual_potency_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=sexual_potency;task=input'>[sexual_potency]</a>"
			dat += "</td>"

			//SPLURT EDIT BEGIN - gregnancy preferences
			dat += "<td width='220px' height='300px' valign='top'>"
			var/pregnancy_preferences_label = src.use_modern_translations ? get_modern_text("pregnancy_preferences", src) : "Pregnancy preferences"
			var/chance_impregnation_label = src.use_modern_translations ? get_modern_text("chance_impregnation", src) : "Chance of impregnation"
			var/chance_pregnant_label = src.use_modern_translations ? get_modern_text("chance_pregnant", src) : "Chance of getting pregnant"
			var/lay_inert_eggs_label = src.use_modern_translations ? get_modern_text("lay_inert_eggs", src) : "Lay inert eggs"
			var/pregnancy_inflation_label = src.use_modern_translations ? get_modern_text("pregnancy_inflation", src) : "Pregnancy inflation"
			var/pregnancy_breast_growth_label = src.use_modern_translations ? get_modern_text("pregnancy_breast_growth", src) : "Pregnancy breast growth"
			var/egg_shell_label = src.use_modern_translations ? get_modern_text("egg_shell", src) : "Egg shell"
			dat += "<h3>[pregnancy_preferences_label]</h3>"
			dat += "<b>[chance_impregnation_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=virility;task=input'>[virility ? virility : "Disabled"]</a>"
			dat += "<b>[chance_pregnant_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=fertility;task=input'>[fertility ? fertility : "Disabled"]</a>"
			dat += "<b>[lay_inert_eggs_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=inert_eggs'>[features["inert_eggs"] == TRUE ? "Enabled" : "Disabled"]</a>"
			if(fertility)
				dat += "<b>[pregnancy_inflation_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=pregnancy_inflation;task=input'>[pregnancy_inflation ? "Enabled" : "Disabled"]</a>"
				dat += "<b>[pregnancy_breast_growth_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=pregnancy_breast_growth;task=input'>[pregnancy_breast_growth ? "Enabled" : "Disabled"]</a>"
			if(fertility || features["inert_eggs"])
				dat += "<b>[egg_shell_label]:</b><a style='display:block;width:100px' href ='?_src_=prefs;preference=egg_shell;task=input'>[egg_shell]</a>"
			dat += "</td>"
			//SPLURT EDIT END
			dat += APPEARANCE_CATEGORY_COLUMN
			dat += "<td height='300px' valign='top'>"
			if(NOGENITALS in pref_species.species_traits)
				dat += "<b>Your species ([pref_species.name]) does not support genitals!</b><br>"
			else
				// Translation variables for genital section headers
				var/penis_header = src.use_modern_translations ? get_modern_text("penis", src) : "Penis"
				var/vagina_header = src.use_modern_translations ? get_modern_text("vagina", src) : "Vagina"
				var/breasts_header = src.use_modern_translations ? get_modern_text("breasts", src) : "Breasts"
				var/butt_header = src.use_modern_translations ? get_modern_text("butt", src) : "Butt"
				var/belly_header = src.use_modern_translations ? get_modern_text("belly", src) : "Belly"
				var/neckfire_header = src.use_modern_translations ? get_modern_text("neckfire", src) : "Neckfire"
				// Translation variables for Penis section labels
				var/penis_color_label = src.use_modern_translations ? get_modern_text("penis_color", src) : "Penis Color"
				var/penis_shape_label = src.use_modern_translations ? get_modern_text("penis_shape", src) : "Penis Shape"
				var/penis_length_label = src.use_modern_translations ? get_modern_text("penis_length", src) : "Penis Length"
				var/penis_diameter_ratio_label = src.use_modern_translations ? get_modern_text("penis_diameter_ratio", src) : "Diameter Ratio"
				var/penis_visibility_label = src.use_modern_translations ? get_modern_text("penis_visibility", src) : "Penis Visibility"
				var/penis_accessible_label = src.use_modern_translations ? get_modern_text("penis_accessible", src) : "Penis Always Accessible"
				var/penis_stuffing_label = src.use_modern_translations ? get_modern_text("penis_stuffing", src) : "Toys and Egg Stuffing"
				var/has_penis_label = src.use_modern_translations ? get_modern_text("has_penis", src) : "Has Penis"
				var/has_testicles_label = src.use_modern_translations ? get_modern_text("has_testicles", src) : "Has Testicles"
				var/testicles_color_label = src.use_modern_translations ? get_modern_text("testicles_color", src) : "Testicles Color"
				var/testicles_shape_label = src.use_modern_translations ? get_modern_text("testicles_shape", src) : "Testicles Shape"
				var/testicles_visibility_label = src.use_modern_translations ? get_modern_text("testicles_visibility", src) : "Testicles Visibility"
				var/testicles_accessible_label = src.use_modern_translations ? get_modern_text("testicles_accessible", src) : "Testicles Always Accessible"
				var/testicles_stuffing_label = src.use_modern_translations ? get_modern_text("testicles_stuffing", src) : "Toys and Egg Stuffing"
				var/testicles_fluid_label = src.use_modern_translations ? get_modern_text("testicles_fluid", src) : "Produces"
				// Translation variables for Vagina section labels
				var/vagina_type_label = src.use_modern_translations ? get_modern_text("vagina_type", src) : "Vagina Type"
				var/vagina_color_label = src.use_modern_translations ? get_modern_text("vagina_color", src) : "Vagina Color"
				var/vagina_visibility_label = src.use_modern_translations ? get_modern_text("vagina_visibility", src) : "Vagina Visibility"
				var/vagina_accessible_label = src.use_modern_translations ? get_modern_text("vagina_accessible", src) : "Vagina Always Accessible"
				var/vagina_stuffing_label = src.use_modern_translations ? get_modern_text("vagina_stuffing", src) : "Toys and Egg Stuffing"
				var/has_vagina_label = src.use_modern_translations ? get_modern_text("has_vagina", src) : "Has Vagina"
				var/has_womb_label = src.use_modern_translations ? get_modern_text("has_womb", src) : "Has Womb"
				var/womb_fluid_label = src.use_modern_translations ? get_modern_text("womb_fluid", src) : "Produces"
				// Translation variables for Breasts section labels
				var/breasts_color_label = src.use_modern_translations ? get_modern_text("breasts_color", src) : "Color"
				var/breasts_size_label = src.use_modern_translations ? get_modern_text("breasts_size", src) : "Cup Size"
				var/breasts_shape_label = src.use_modern_translations ? get_modern_text("breasts_shape", src) : "Breasts Shape"
				var/breasts_visibility_label = src.use_modern_translations ? get_modern_text("breasts_visibility", src) : "Breasts Visibility"
				var/breasts_lactates_label = src.use_modern_translations ? get_modern_text("breasts_lactates", src) : "Lactates"
				var/breasts_stuffing_label = src.use_modern_translations ? get_modern_text("breasts_stuffing", src) : "Toys and Egg Stuffing"
				var/has_breasts_label = src.use_modern_translations ? get_modern_text("has_breasts", src) : "Has Breasts"
				var/breast_fluid_label = src.use_modern_translations ? get_modern_text("breast_fluid", src) : "Produces"
				// Translation variables for Butt/Anus section labels
				var/butt_color_label = src.use_modern_translations ? get_modern_text("butt_color", src) : "Color"
				var/butt_size_label = src.use_modern_translations ? get_modern_text("butt_size", src) : "Butt Size"
				var/butt_visibility_label = src.use_modern_translations ? get_modern_text("butt_visibility", src) : "Butt Visibility"
				var/butt_stuffing_label = src.use_modern_translations ? get_modern_text("butt_stuffing", src) : "Toys and Egg Stuffing"
				var/has_butt_label = src.use_modern_translations ? get_modern_text("has_butt", src) : "Has Butt"
				var/has_anus_label = src.use_modern_translations ? get_modern_text("has_anus", src) : "Has Anus"
				var/anus_color_label = src.use_modern_translations ? get_modern_text("anus_color", src) : "Butthole Color"
				var/anus_shape_label = src.use_modern_translations ? get_modern_text("anus_shape", src) : "Butthole Shape"
				var/anus_visibility_label = src.use_modern_translations ? get_modern_text("anus_visibility", src) : "Butthole Visibility"
				var/anus_stuffing_label = src.use_modern_translations ? get_modern_text("anus_stuffing", src) : "Toys and Egg Stuffing"
				// Translation variables for Belly section labels
				var/belly_color_label = src.use_modern_translations ? get_modern_text("belly_color", src) : "Color"
				var/belly_size_label = src.use_modern_translations ? get_modern_text("belly_size", src) : "Belly Size"
				var/belly_visibility_label = src.use_modern_translations ? get_modern_text("belly_visibility", src) : "Belly Visibility"
				var/belly_stuffing_label = src.use_modern_translations ? get_modern_text("belly_stuffing", src) : "Toys and Egg Stuffing"
				var/has_belly_label = src.use_modern_translations ? get_modern_text("has_belly", src) : "Has Belly"
				// Translation variables for Neckfire section labels
				var/has_neckfire_label = src.use_modern_translations ? get_modern_text("has_neckfire", src) : "Has Neckfire"
				var/neckfire_color_label = src.use_modern_translations ? get_modern_text("neckfire_color", src) : "Color"
				var/genitals_use_skintone_label = src.use_modern_translations ? get_modern_text("genitals_use_skintone", src) : "Genitals use skintone"

				dat += "<b>[genitals_use_skintone_label]:</b><a href='?_src_=prefs;preference=genital_colour'>[features["genitals_use_skintone"] == TRUE ? "Yes" : "No"]</a><BR>"
				dat += "<h3>[penis_header]</h3>"
				dat += "<b>[has_penis_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_cock'>[features["has_cock"] == TRUE ? "Yes" : "No"]</a>"
				if(features["has_cock"])
					if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
						dat += "<b>[penis_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)</a><br>"
					else
						dat += "<b>[penis_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: #[features["cock_color"]];'><font color='[color_hex2num(features["cock_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["cock_color"]]</font></span> <a href='?_src_=prefs;preference=cock_color;task=input'>Change</a><br>"
					var/tauric_shape = FALSE
					if(features["cock_taur"])
						var/datum/sprite_accessory/penis/P = GLOB.cock_shapes_list[features["cock_shape"]]
						if(P.taur_icon && parent.can_have_part("taur"))
							var/datum/sprite_accessory/taur/T = GLOB.taur_list[features["taur"]]
							if(T.taur_mode & P.accepted_taurs)
								tauric_shape = TRUE
					dat += "<b>[penis_shape_label]:</b> <a style='display:block;width:120px' href='?_src_=prefs;preference=cock_shape;task=input'>[features["cock_shape"]][tauric_shape ? " (Taur)" : ""]</a>"
					dat += "<b>[penis_length_label]:</b> <a style='display:block;width:120px' href='?_src_=prefs;preference=cock_length;task=input'>[features["cock_length"]] inch(es)</a>"
					dat += "<b>[penis_diameter_ratio_label]:</b> <a style='display:block;width:120px' href='?_src_=prefs;preference=cock_diameter_ratio;task=input'>[features["cock_diameter_ratio"]]</a>"
					dat += "<b>[penis_visibility_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=cock_visibility;task=input'>[features["cock_visibility"]]</a>"
					dat += "<b>[penis_accessible_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=cock_accessible'>[features["cock_accessible"] ? "Yes" : "No"]</a>"
					dat += "<b>[penis_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=cock_stuffing'>[features["cock_stuffing"] == TRUE ? "Yes" : "No"]</a>"
					dat += "<b>[has_testicles_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_balls'>[features["has_balls"] == TRUE ? "Yes" : "No"]</a>"
					if(features["has_balls"])
						if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
							dat += "<b>[testicles_color_label]:</b></a><BR>"
							dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)<br>"
						else
							dat += "<b>[testicles_color_label]:</b></a><BR>"
							dat += "<span style='border: 1px solid #161616; background-color: #[features["balls_color"]];'><font color='[color_hex2num(features["balls_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["balls_color"]]</font></span> <a href='?_src_=prefs;preference=balls_color;task=input'>Change</a><br>"
						dat += "<b>[testicles_shape_label]:</b> <a style='display:block;width:120px' href='?_src_=prefs;preference=balls_shape;task=input'>[features["balls_shape"]]</a>"
						dat += "<b>[testicles_visibility_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=balls_visibility;task=input'>[features["balls_visibility"]]</a>"
						dat += "<b>[testicles_accessible_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=balls_accessible'>[features["balls_accessible"] ? "Yes" : "No"]</a>"
						dat += "<td height='300px' valign='top'>"
						dat += "<b>[testicles_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=balls_stuffing'>[features["balls_stuffing"] == TRUE ? "Yes" : "No"]</a>"
						dat += "<b>[testicles_fluid_label]:</b>"
						var/datum/reagent/balls_fluid = find_reagent_object_from_type(features["balls_fluid"])
						if(balls_fluid && (balls_fluid in GLOB.genital_fluids_list))
							dat += "<a style='display:block;width:50px' href='?_src_=prefs;preference=balls_fluid;task=input'>[balls_fluid.name]</a>"
						else
							dat += "<a style='display:block;width:50px' href='?_src_=prefs;preference=balls_fluid;task=input'>Nothing?</a>"
				dat += "</td>"
				dat += APPEARANCE_CATEGORY_COLUMN
				dat += "<h3>[vagina_header]</h3>"
				dat += "<b>[has_vagina_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_vag'>[features["has_vag"] == TRUE ? "Yes" : "No"]</a>"
				if(features["has_vag"])
					dat += "<b>[vagina_type_label]:</b> <a style='display:block;width:100px' href='?_src_=prefs;preference=vag_shape;task=input'>[features["vag_shape"]]</a>"
					if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
						dat += "<b>[vagina_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)<br>"
					else
						dat += "<b>[vagina_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: #[features["vag_color"]];'><font color='[color_hex2num(features["vag_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["vag_color"]]</font></span> <a href='?_src_=prefs;preference=vag_color;task=input'>Change</a><br>"
					dat += "<b>[vagina_visibility_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=vag_visibility;task=input'>[features["vag_visibility"]]</a>"
					dat += "<b>[vagina_accessible_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=vag_accessible'>[features["vag_accessible"] ? "Yes" : "No"]</a>"
					dat += "<b>[vagina_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=vag_stuffing'>[features["vag_stuffing"] == TRUE ? "Yes" : "No"]</a>"
					dat += "<b>[has_womb_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_womb'>[features["has_womb"] == TRUE ? "Yes" : "No"]</a>"
					if(features["has_womb"] == TRUE)
						dat += "<b>[womb_fluid_label]:</b>"
						var/datum/reagent/womb_fluid = find_reagent_object_from_type(features["womb_fluid"])
						if(womb_fluid && (womb_fluid in GLOB.genital_fluids_list))
							dat += "<a style='display:block;width:50px' href='?_src_=prefs;preference=womb_fluid;task=input'>[womb_fluid.name]</a>"
						else
							dat += "<a style='display:block;width:50px' href='?_src_=prefs;preference=womb_fluid;task=input'>Nothing?</a>"
				dat += "</td>"
				dat += APPEARANCE_CATEGORY_COLUMN
				dat += "<h3>[breasts_header]</h3>"
				dat += "<b>[has_breasts_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_breasts'>[features["has_breasts"] == TRUE ? "Yes" : "No"]</a>"
				if(features["has_breasts"])
					if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
						dat += "<b>[breasts_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)<br>"
					else
						dat += "<b>[breasts_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: #[features["breasts_color"]];'><font color='[color_hex2num(features["breasts_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["breasts_color"]]</font></span> <a href='?_src_=prefs;preference=breasts_color;task=input'>Change</a><br>"
					dat += "<b>[breasts_size_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=breasts_size;task=input'>[features["breasts_size"]]</a>"
					dat += "<b>[breasts_shape_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=breasts_shape;task=input'>[features["breasts_shape"]]</a>"
					dat += "<b>[breasts_visibility_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=breasts_visibility;task=input'>[features["breasts_visibility"]]</a>"
					dat += "<b>[breasts_lactates_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=breasts_producing'>[features["breasts_producing"] == TRUE ? "Yes" : "No"]</a>"
					dat += "<b>[breasts_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=breasts_stuffing'>[features["breasts_stuffing"] == TRUE ? "Yes" : "No"]</a>"
					if(features["breasts_producing"] == TRUE)
						dat += "<b>[breast_fluid_label]:</b>"
						var/datum/reagent/breasts_fluid = find_reagent_object_from_type(features["breasts_fluid"])
						if(breasts_fluid && (breasts_fluid in GLOB.genital_fluids_list))
							dat += "<a style='display:block;width:50px' href='?_src_=prefs;preference=breasts_fluid;task=input'>[breasts_fluid.name]</a>"
						else
							dat += "<a style='display:block;width:50px' href='?_src_=prefs;preference=breasts_fluid;task=input'>Nothing?</a>"
				dat += "</td>"
				dat += APPEARANCE_CATEGORY_COLUMN
				dat += "<h3>[butt_header]</h3>"
				var/has_butt_text = features["has_butt"] == TRUE ? "Yes" : "No"
				dat += "<b>[has_butt_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_butt'>[has_butt_text]</a>"
				if(features["has_butt"])
					if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
						dat += "<b>[butt_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)<br>"
					else
						dat += "<b>[butt_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: #[features["butt_color"]];'><font color='[color_hex2num(features["butt_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["butt_color"]]</font></span> <a href='?_src_=prefs;preference=butt_color;task=input'>Change</a><br>"
					var/butt_size_value = features["butt_size"]
					var/butt_visibility_value = features["butt_visibility"]
					dat += "<b>" + butt_size_label + ":</b><a style='display:block;width:50px' href='?_src_=prefs;preference=butt_size;task=input'>" + butt_size_value + "</a>"
					dat += "<b>" + butt_visibility_label + ":</b><a style='display:block;width:100px' href='?_src_=prefs;preference=butt_visibility;task=input'>" + butt_visibility_value + "</a>"
					var/butt_stuffing_text = features["butt_stuffing"] == TRUE ? "Yes" : "No"
					dat += "<b>[butt_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=butt_stuffing'>[butt_stuffing_text]</a>"
					var/has_anus_text = features["has_anus"] == TRUE ? "Yes" : "No"
					dat += "<b>[has_anus_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_anus'>[has_anus_text]</a>"
					if(features["has_anus"] == TRUE)
						dat += "<b>[anus_color_label]:</b></a><BR>"
						if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
							dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)<br>"
						else
							dat += "<span style='border: 1px solid #161616; background-color: #[features["anus_color"]];'><font color='[color_hex2num(features["anus_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["anus_color"]]</font></span> <a href='?_src_=prefs;preference=anus_color;task=input'>Change</a><br>"
						dat += "<b>[anus_shape_label]:</b> <a style='display:block;width:120px' href='?_src_=prefs;preference=anus_shape;task=input'>[features["anus_shape"]]</a>"
						var/anus_visibility_value = features["anus_visibility"]
						dat += "<b>[anus_visibility_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=anus_visibility;task=input'>[anus_visibility_value]</a>"
						var/anus_stuffing_text = features["anus_stuffing"] == TRUE ? "Yes" : "No"
						dat += "<b>[anus_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=anus_stuffing'>[anus_stuffing_text]</a>"
				dat += "</td>"
				dat += APPEARANCE_CATEGORY_COLUMN
				dat += "<h3>[belly_header]</h3>"
				dat += "<b>[has_belly_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_belly'>[features["has_belly"] == TRUE ? "Yes" : "No"]</a>"
				if(features["has_belly"])
					if(pref_species.use_skintones && features["genitals_use_skintone"] == TRUE)
						dat += "<b>[belly_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: [SKINTONE2HEX(skin_tone)];'><font color='[color_hex2num(SKINTONE2HEX(skin_tone)) < 200 ? "FFFFFF" : "000000"]'>[SKINTONE2HEX(skin_tone)]</font></span>(Skin tone overriding)<br>"
					else
						dat += "<b>[belly_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: #[features["belly_color"]];'><font color='[color_hex2num(features["belly_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["belly_color"]]</font></span> <a href='?_src_=prefs;preference=belly_color;task=input'>Change</a><br>"
					dat += "<b>[belly_size_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=belly_size;task=input'>[features["belly_size"]]</a>"
					dat += "<b>[belly_visibility_label]:</b><a style='display:block;width:100px' href='?_src_=prefs;preference=belly_visibility;task=input'>[features["belly_visibility"]]</a>"
					dat += "<b>[belly_stuffing_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=belly_stuffing'>[features["belly_stuffing"] == TRUE ? "Yes" : "No"]</a>"
				dat += "</td>"
				if(all_quirks.Find("Dullahan"))
					dat += APPEARANCE_CATEGORY_COLUMN

					dat += "<h3>[neckfire_header]</h3>"
					dat += "<b>[has_neckfire_label]:</b><a style='display:block;width:50px' href='?_src_=prefs;preference=has_neckfire;task=input'>[features["neckfire"] ? "Yes" : "No"]</a>"
					if(features["neckfire"])
						dat += "<b>[neckfire_color_label]:</b></a><BR>"
						dat += "<span style='border: 1px solid #161616; background-color: #[features["neckfire_color"]];'><font color='[color_hex2num(features["neckfire_color"]) < 200 ? "FFFFFF" : "000000"]'>#[features["neckfire_color"]]</font></span><a href='?_src_=prefs;preference=has_neckfire_color;task=input'>Change</a><br>"

					dat += "</td>"
			dat += "</td>"
			dat += "</tr></table>"

		if(SPEECH_TAB)
			if(path)
				var/savefile/S = new /savefile(path)
				if(S)
					dat += "<center>"
					var/name
					var/unspaced_slots = 0
					for(var/i=1, i<=max_save_slots, i++)
						unspaced_slots++
						if(unspaced_slots > 4)
							dat += "<br>"
							unspaced_slots = 0
						S.cd = "/character[i]"
						S["real_name"] >> name
						if(!name)
							name = "Character[i]"
						dat += "<a style='white-space:nowrap;' href='?_src_=prefs;preference=changeslot;num=[i];' [i == default_slot ? "class='linkOn'" : ""]>[name]</a> "
					dat += "</center>"

			dat += "<table><tr><td width='340px' height='300px' valign='top'>"
			dat += "<h2>Speech preferences</h2>"
			dat += "<b>Custom Speech Verb:</b><BR>"
			dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=speech_verb;task=input'>[custom_speech_verb]</a><BR>"
			dat += "<b>Custom Tongue:</b><BR>"
			dat += "<a style='display:block;width:100px' href='?_src_=prefs;preference=tongue;task=input'>[custom_tongue]</a><BR>"
			//SANDSTORM EDIT - additional language + runechat color
			dat += "<b>Additional Language</b><br>"
			var/list/languages_sorted = sort_list(language)
			dat += "<a href='?_src_=prefs;preference=language;task=menu'>[language.len ? languages_sorted.Join(", ") : "None"]</a></center><br>"
			dat += "<b>Custom runechat color:</b> <a href='?_src_=prefs;preference=enable_personal_chat_color'>[enable_personal_chat_color ? "Enabled" : "Disabled"]</a><br> [enable_personal_chat_color ? "<span style='border: 1px solid #161616; background-color: [personal_chat_color];'><font color='[color_hex2num(personal_chat_color) < 200 ? "FFFFFF" : "000000"]'>[personal_chat_color]</font></span> <a href='?_src_=prefs;preference=personal_chat_color;task=input'>Change</a>" : ""]<br>"
			dat += "</td>"
			//END OF SANDSTORM EDIT
			dat += "<td width='340px' height='300px' valign='top'>"
			dat += "<h2>Vocal Bark preferences</h2>"
			var/datum/bark/B = GLOB.bark_list[bark_id]
			dat += "<b>Vocal Bark Sound:</b><BR>"
			dat += "<a style='display:block;width:200px' href='?_src_=prefs;preference=barksound;task=input'>[B ? initial(B.name) : "INVALID"]</a><BR>"
			dat += "<b>Vocal Bark Speed:</b> <a href='?_src_=prefs;preference=barkspeed;task=input'>[bark_speed]</a><BR>"
			dat += "<b>Vocal Bark Pitch:</b> <a href='?_src_=prefs;preference=barkpitch;task=input'>[bark_pitch]</a><BR>"
			dat += "<b>Vocal Bark Variance:</b> <a href='?_src_=prefs;preference=barkvary;task=input'>[bark_variance]</a><BR>"
			dat += "<BR><a href='?_src_=prefs;preference=barkpreview'>Preview Bark</a><BR>"
			dat += "</td>"
			dat += "</tr></table>"

		if(GAME_PREFERENCES_TAB) // Game Preferences
			dat += "<table><tr><td width='340px' height='300px' valign='top'>"
			dat += "<h2>General Settings</h2>"
			dat += "<b>UI Style:</b> <a href='?_src_=prefs;task=input;preference=ui'>[UI_style]</a><br>"
			dat += "<b>Outline:</b> <a href='?_src_=prefs;preference=outline_enabled'>[outline_enabled ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Outline Color:</b> [outline_color ? "<span style='border:1px solid #161616; background-color: [outline_color];'>" : "Theme-based (null)"]<font color='[color_hex2num(outline_color) < 200 ? "FFFFFF" : "000000"]'>[outline_color]</font></span> <a href='?_src_=prefs;preference=outline_color'>Change</a><BR>"
			dat += "<b>Screentip:</b> <a href='?_src_=prefs;preference=screentip_pref'>[screentip_pref]</a><br>"
			dat += "<b>Screentip Color:</b> <span style='border:1px solid #161616; background-color: [screentip_color];'><font color='[color_hex2num(screentip_color) < 200 ? "FFFFFF" : "000000"]'>[screentip_color]</font></span> <a href='?_src_=prefs;preference=screentip_color'>Change</a><BR>"
			dat += "<b>tgui Monitors:</b> <a href='?_src_=prefs;preference=tgui_lock'>[(tgui_lock) ? "Primary" : "All"]</a><br>"
			dat += "<b>tgui Style:</b> <a href='?_src_=prefs;preference=tgui_fancy'>[(tgui_fancy) ? "Fancy" : "No Frills"]</a><br>"
			dat += "<b>Input Framework:</b> <a href='?_src_=prefs;preference=tgui_input_mode'>[(tgui_input_mode) ? "tgui" : "BYOND"]</a><br>"
			dat += "<b>tgui Button Size:</b> <a href='?_src_=prefs;preference=tgui_large_buttons'>[(tgui_large_buttons) ? "Large" : "Small"]</a><br>"
			dat += "<b>tgui Buttons Swapped:</b> <a href='?_src_=prefs;preference=tgui_swapped_buttons'>[(tgui_swapped_buttons) ? "Yes" : "No"]</a><br>"
			dat += "<b>Show Runechat Chat Bubbles:</b> <a href='?_src_=prefs;preference=chat_on_map'>[chat_on_map ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Runechat message char limit:</b> <a href='?_src_=prefs;preference=max_chat_length;task=input'>[max_chat_length]</a><br>"
			dat += "<b>See Runechat for non-mobs:</b> <a href='?_src_=prefs;preference=see_chat_non_mob'>[see_chat_non_mob ? "Enabled" : "Disabled"]</a><br>"
			//SKYRAT CHANGES BEGIN
			dat += "<b>See Runechat for emotes:</b> <a href='?_src_=prefs;preference=see_chat_emotes'>[see_chat_emotes ? "Enabled" : "Disabled"]</a><br>"
			//SKYRAT CHANGES END
			dat += "<b>Shift view when pixelshifting:</b> <a href='?_src_=prefs;preference=view_pixelshift'>[view_pixelshift ? "Enabled" : "Disabled"]</a><br>" //SPLURT Edit
			dat += "<br>"
			dat += "<b>PDA Color:</b> <span style='border:1px solid #161616; background-color: [pda_color];'><font color='[color_hex2num(pda_color) < 200 ? "FFFFFF" : "000000"]'>[pda_color]</font></span> <a href='?_src_=prefs;preference=pda_color;task=input'>Change</a><BR>"
			dat += "<b>PDA Style:</b> <a href='?_src_=prefs;task=input;preference=pda_style'>[pda_style]</a><br>"
			dat += "<b>PDA Reskin:</b> <a href='?_src_=prefs;task=input;preference=pda_skin'>[pda_skin]</a><br>"
			dat += "<br>"
			dat += "<b>Ghost Ears:</b> <a href='?_src_=prefs;preference=ghost_ears'>[(chat_toggles & CHAT_GHOSTEARS) ? "All Speech" : "Nearest Creatures"]</a><br>"
			dat += "<b>Ghost Radio:</b> <a href='?_src_=prefs;preference=ghost_radio'>[(chat_toggles & CHAT_GHOSTRADIO) ? "All Messages":"No Messages"]</a><br>"
			dat += "<b>Ghost Sight:</b> <a href='?_src_=prefs;preference=ghost_sight'>[(chat_toggles & CHAT_GHOSTSIGHT) ? "All Emotes" : "Nearest Creatures"]</a><br>"
			dat += "<b>Ghost Whispers:</b> <a href='?_src_=prefs;preference=ghost_whispers'>[(chat_toggles & CHAT_GHOSTWHISPER) ? "All Speech" : "Nearest Creatures"]</a><br>"
			dat += "<b>Ghost PDA:</b> <a href='?_src_=prefs;preference=ghost_pda'>[(chat_toggles & CHAT_GHOSTPDA) ? "All Messages" : "Nearest Creatures"]</a><br>"
			dat += "<b>Window Flashing:</b> <a href='?_src_=prefs;preference=winflash'>[(windowflashing) ? "Enabled":"Disabled"]</a><br>"
			dat += "<b>Window Noise:</b> <a href='?_src_=prefs;preference=winnoise'>[(windownoise) ? "Enabled":"Disabled"]</a><br>"
			dat += "<br>"
			dat += "<b>Play Admin MIDIs:</b> <a href='?_src_=prefs;preference=hear_midis'>[(toggles & SOUND_MIDI) ? "Enabled":"Disabled"]</a><br>"
			dat += "<b>Play Lobby Music:</b> <a href='?_src_=prefs;preference=lobby_music'>[(toggles & SOUND_LOBBY) ? "Enabled":"Disabled"]</a><br>"
			dat += "<b>See Pull Requests:</b> <a href='?_src_=prefs;preference=pull_requests'>[(chat_toggles & CHAT_PULLR) ? "Enabled":"Disabled"]</a><br>"
			dat += "<br>"
			if(user.client)
				if(unlock_content)
					dat += "<b>BYOND Membership Publicity:</b> <a href='?_src_=prefs;preference=publicity'>[(toggles & MEMBER_PUBLIC) ? "Public" : "Hidden"]</a><br>"
				if(unlock_content || check_rights_for(user.client, R_ADMIN))
					dat += "<b>OOC Color:</b> <span style='border: 1px solid #161616; background-color: [ooccolor ? ooccolor : GLOB.normal_ooc_colour];'><font color='[color_hex2num(ooccolor ? ooccolor : GLOB.normal_ooc_colour) < 200 ? "FFFFFF" : "000000"]'>[ooccolor ? ooccolor : GLOB.normal_ooc_colour]</font></span> <a href='?_src_=prefs;preference=ooccolor;task=input'>Change</a><br>"
					dat += "<b>Antag OOC Color:</b> <span style='border: 1px solid #161616; background-color: [aooccolor ? aooccolor : GLOB.normal_aooc_colour];'><font color='[color_hex2num(aooccolor ? aooccolor : GLOB.normal_aooc_colour) < 200 ? "FFFFFF" : "000000"]'>[aooccolor ? aooccolor : GLOB.normal_aooc_colour]</font></span> <a href='?_src_=prefs;preference=aooccolor;task=input'>Change</a><br>"

			dat += "</td>"

			dat += "<td width='300px' height='300px' valign='top'>"

			dat += "<h2>Special Role Settings</h2>"

			if(jobban_isbanned(user, ROLE_INTEQ))
				dat += "<font color=red><b>You are banned from antagonist roles.</b></font>"
				src.be_special = list()

			dat += "<b>DISABLE ALL ANTAGONISM</b> <a href='?_src_=prefs;preference=disable_antag'>[(toggles & NO_ANTAG) ? "YES" : "NO"]</a><br>"

			for (var/i in GLOB.special_roles)
				if(jobban_isbanned(user, i))
					dat += "<b>Be [capitalize(i)]:</b> <a href='?_src_=prefs;jobbancheck=[i]'>BANNED</a><br>"
				else
					var/days_remaining = null
					if(ispath(GLOB.special_roles[i]) && CONFIG_GET(flag/use_age_restriction_for_jobs)) //If it's a game mode antag, check if the player meets the minimum age
						var/mode_path = GLOB.special_roles[i]
						var/datum/game_mode/temp_mode = new mode_path
						days_remaining = temp_mode.get_remaining_days(user.client)

					if(days_remaining)
						dat += "<b>Be [capitalize(i)]:</b> <font color=red> \[IN [days_remaining] DAYS]</font><br>"
					else
						var/enabled_text = ""
						if(i in be_special)
							if(be_special[i] >= 1)
								enabled_text = "Enabled"
							else
								enabled_text = "Low"
						else
							enabled_text = "Disabled"
						dat += "<b>Be [capitalize(i)]:</b> <a href='?_src_=prefs;preference=be_special;be_special_type=[i]'>[enabled_text]</a><br>"
			dat += "<b>Midround Antagonist:</b> <a href='?_src_=prefs;preference=allow_midround_antag'>[(toggles & MIDROUND_ANTAG) ? "Enabled" : "Disabled"]</a><br>"

			dat += "<br>"

			dat += "<td width='300px' height='300px' valign='top'>"

			if(user.client.holder) // sandstorm start - moves admin prefs to the right
				dat += "<h2>Admin Settings</h2>"
				dat += "<b>Adminhelp Sounds:</b> <a href='?_src_=prefs;preference=hear_adminhelps'>[(toggles & SOUND_ADMINHELP)?"Enabled":"Disabled"]</a><br>"
				dat += "<b>Announce Login:</b> <a href='?_src_=prefs;preference=announce_login'>[(toggles & ANNOUNCE_LOGIN)?"Enabled":"Disabled"]</a><br>"
				dat += "<br>"
				dat += "<b>Combo HUD Lighting:</b> <a href = '?_src_=prefs;preference=combohud_lighting'>[(toggles & COMBOHUD_LIGHTING)?"Full-bright":"No Change"]</a><br>"
				dat += "<b>Use Modern Player Panel:</b> <a href='?_src_=prefs;preference=use_new_playerpanel'>[use_new_playerpanel ? "Yes" : "No"]</a><br>" // sandstorm end - moves admins prefs to the right

				//deadmin
				dat += "<h2>Deadmin While Playing</h2>"
				if(CONFIG_GET(flag/auto_deadmin_players))
					dat += "<b>Always Deadmin:</b> FORCED</a><br>"
				else
					dat += "<b>Always Deadmin:</b> <a href = '?_src_=prefs;preference=toggle_deadmin_always'>[(deadmin & DEADMIN_ALWAYS)?"Enabled":"Disabled"]</a><br>"
					if(!(deadmin & DEADMIN_ALWAYS))
						dat += "<br>"
						if(!CONFIG_GET(flag/auto_deadmin_antagonists))
							dat += "<b>As Antag:</b> <a href = '?_src_=prefs;preference=toggle_deadmin_antag'>[(deadmin & DEADMIN_ANTAGONIST)?"Deadmin":"Keep Admin"]</a><br>"
						else
							dat += "<b>As Antag:</b> FORCED<br>"

						if(!CONFIG_GET(flag/auto_deadmin_heads))
							dat += "<b>As Command:</b> <a href = '?_src_=prefs;preference=toggle_deadmin_head'>[(deadmin & DEADMIN_POSITION_HEAD)?"Deadmin":"Keep Admin"]</a><br>"
						else
							dat += "<b>As Command:</b> FORCED<br>"

						if(!CONFIG_GET(flag/auto_deadmin_security))
							dat += "<b>As Security:</b> <a href = '?_src_=prefs;preference=toggle_deadmin_security'>[(deadmin & DEADMIN_POSITION_SECURITY)?"Deadmin":"Keep Admin"]</a><br>"
						else
							dat += "<b>As Security:</b> FORCED<br>"

						if(!CONFIG_GET(flag/auto_deadmin_silicons))
							dat += "<b>As Silicon:</b> <a href = '?_src_=prefs;preference=toggle_deadmin_silicon'>[(deadmin & DEADMIN_POSITION_SILICON)?"Deadmin":"Keep Admin"]</a><br>"
						else
							dat += "<b>As Silicon:</b> FORCED<br>"

			dat += "<h2>Citadel Preferences</h2>" //Because fuck me if preferences can't be fucking modularized and expected to update in a reasonable timeframe.
			dat += "<b>Widescreen:</b> <a href='?_src_=prefs;preference=widescreenpref'>[widescreenpref ? "Enabled ([CONFIG_GET(string/default_view)])" : "Disabled (15x15)"]</a><br>"
			dat += "<b>Fullscreen:</b> <a href='?_src_=prefs;preference=fullscreen'>[fullscreen ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Long strip menu:</b> <a href='?_src_=prefs;preference=long_strip_menu'>[long_strip_menu ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Auto stand:</b> <a href='?_src_=prefs;preference=autostand'>[autostand ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Auto OOC:</b> <a href='?_src_=prefs;preference=auto_ooc'>[auto_ooc ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Force Slot Storage HUD:</b> <a href='?_src_=prefs;preference=no_tetris_storage'>[no_tetris_storage ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Screen Shake:</b> <a href='?_src_=prefs;preference=screenshake'>[(screenshake==100) ? "Full" : ((screenshake==0) ? "None" : "[screenshake]")]</a><br>"
			if (user && user.client && !user.client.prefs.screenshake==0)
				dat += "<b>Damage Screen Shake:</b> <a href='?_src_=prefs;preference=damagescreenshake'>[(damagescreenshake==1) ? "On" : ((damagescreenshake==0) ? "Off" : "Only when down")]</a><br>"
			dat += "<b>Recoil Screen Push:</b> <a href='?_src_=prefs;preference=recoil_screenshake'>[(recoil_screenshake==100) ? "Full" : ((recoil_screenshake==0) ? "None" : "[screenshake]")]</a><br>"

			dat += "<h2>S.P.L.U.R.T. Preferences</h2>"
			dat += "<b>Be Antagonist Victim:</b> <a href='?_src_=prefs;preference=be_victim;task=input'>[be_victim ? be_victim : BEVICTIM_ASK]</a><br>"
			dat += "<b>Disable combat mode cursor:</b> <a href='?_src_=prefs;preference=disable_combat_cursor'>[disable_combat_cursor?"Yes":"No"]</a><br>"
			dat += "<b>Splashscreen Player Panel Style:</b> <a href='?_src_=prefs;preference=tg_playerpanel'>[(toggles & TG_PLAYER_PANEL)?"TG":"Old"]</a><br>"
			dat += "<br>"

			dat += "</td>"
			dat += "</tr></table>"
			if(unlock_content)
				dat += "<b>Ghost Form:</b> <a href='?_src_=prefs;task=input;preference=ghostform'>[ghost_form]</a><br>"
				dat += "<B>Ghost Orbit: </B> <a href='?_src_=prefs;task=input;preference=ghostorbit'>[ghost_orbit]</a><br>"
			var/button_name = "If you see this something went wrong."
			switch(ghost_accs)
				if(GHOST_ACCS_FULL)
					button_name = GHOST_ACCS_FULL_NAME
				if(GHOST_ACCS_DIR)
					button_name = GHOST_ACCS_DIR_NAME
				if(GHOST_ACCS_NONE)
					button_name = GHOST_ACCS_NONE_NAME

			dat += "<b>Ghost Accessories:</b> <a href='?_src_=prefs;task=input;preference=ghostaccs'>[button_name]</a><br>"
			switch(ghost_others)
				if(GHOST_OTHERS_THEIR_SETTING)
					button_name = GHOST_OTHERS_THEIR_SETTING_NAME
				if(GHOST_OTHERS_DEFAULT_SPRITE)
					button_name = GHOST_OTHERS_DEFAULT_SPRITE_NAME
				if(GHOST_OTHERS_SIMPLE)
					button_name = GHOST_OTHERS_SIMPLE_NAME

			dat += "<b>Ghosts of Others:</b> <a href='?_src_=prefs;task=input;preference=ghostothers'>[button_name]</a><br>"
			dat += "<br>"

			dat += "<b>FPS:</b> <a href='?_src_=prefs;preference=clientfps;task=input'>[clientfps]</a><br>"

			dat += "<b>Income Updates:</b> <a href='?_src_=prefs;preference=income_pings'>[(chat_toggles & CHAT_BANKCARD) ? "Allowed" : "Muted"]</a><br>"
			dat += "<br>"

			dat += "<b>Parallax (Fancy Space):</b> <a href='?_src_=prefs;preference=parallaxdown' oncontextmenu='window.location.href=\"?_src_=prefs;preference=parallaxup\";return false;'>"
			switch (parallax)
				if (PARALLAX_LOW)
					dat += "Low"
				if (PARALLAX_MED)
					dat += "Medium"
				if (PARALLAX_INSANE)
					dat += "Insane"
				if (PARALLAX_DISABLE)
					dat += "Disabled"
				else
					dat += "High"
			dat += "</a><br>"
			dat += "<b>Ambient Occlusion:</b> <a href='?_src_=prefs;preference=ambientocclusion'>[ambientocclusion ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>Fit Viewport:</b> <a href='?_src_=prefs;preference=auto_fit_viewport'>[auto_fit_viewport ? "Auto" : "Manual"]</a><br>"
			dat += "<b>HUD Button Flashes:</b> <a href='?_src_=prefs;preference=hud_toggle_flash'>[hud_toggle_flash ? "Enabled" : "Disabled"]</a><br>"
			dat += "<b>HUD Button Flash Color:</b> <span style='border: 1px solid #161616; background-color: [hud_toggle_color];'><font color='[color_hex2num(hud_toggle_color) < 200 ? "FFFFFF" : "000000"]'>[hud_toggle_color]</font></span> <a href='?_src_=prefs;preference=hud_toggle_color;task=input'>Change</a><br>"

/* CITADEL EDIT - We're using top menu instead
			button_name = pixel_size
			dat += "<b>Pixel Scaling:</b> <a href='?_src_=prefs;preference=pixel_size'>[(button_name) ? "Pixel Perfect [button_name]x" : "Stretch to fit"]</a><br>"

			switch(scaling_method)
				if(SCALING_METHOD_NORMAL)
					button_name = "Nearest Neighbor"
				if(SCALING_METHOD_DISTORT)
					button_name = "Point Sampling"
				if(SCALING_METHOD_BLUR)
					button_name = "Bilinear"
			dat += "<b>Scaling Method:</b> <a href='?_src_=prefs;preference=scaling_method'>[button_name]</a><br>"
*/

			if (CONFIG_GET(flag/maprotation) && CONFIG_GET(flag/tgstyle_maprotation))
				var/p_map = preferred_map
				if (!p_map)
					p_map = "Default"
					if (config.defaultmap)
						p_map += " ([config.defaultmap.map_name])"
				else
					if (p_map in config.maplist)
						var/datum/map_config/VM = config.maplist[p_map]
						if (!VM)
							p_map += " (No longer exists)"
						else
							p_map = VM.map_name
					else
						p_map += " (No longer exists)"
				if(CONFIG_GET(flag/allow_map_voting))
					dat += "<b>Preferred Map:</b> <a href='?_src_=prefs;preference=preferred_map;task=input'>[p_map]</a><br>"

			dat += "</td>"

		if(LOADOUT_TAB)
			//calculate your gear points from the chosen item
			gear_points = CONFIG_GET(number/initial_gear_points) + (IS_CKEY_DONATOR_GROUP(user.ckey, DONATOR_GROUP_TIER_1) ? CONFIG_GET(number/subscriber_extra_gear_points) : 0) + (IS_CKEY_DONATOR_GROUP(user.ckey, DONATOR_GROUP_TIER_2) ? CONFIG_GET(number/sponsor_extra_gear_points) : 0)
			var/list/chosen_gear = loadout_data["SAVE_[loadout_slot]"]
			if(chosen_gear)
				for(var/loadout_item in chosen_gear)
					var/loadout_item_path = loadout_item[LOADOUT_ITEM]
					if(loadout_item_path)
						var/datum/gear/loadout_gear = text2path(loadout_item_path)
						if(loadout_gear)
							gear_points -= initial(loadout_gear.cost)
			else
				chosen_gear = list()

			dat += "<table align='center' width='100%'>"
			dat += "<tr><td colspan=4><center><b><font color='[gear_points == 0 ? "#E62100" : "#CCDDFF"]'>[gear_points]</font> loadout points remaining.</b> \[<a href='?_src_=prefs;preference=gear;clear_loadout=1'>Clear Loadout</a>\]</center></td></tr>"
			dat += "<tr><td colspan=4><center>You can only choose one item per category, unless it's an item that spawns in your backpack or hands.</center></td></tr>"
			dat += "<tr><td colspan=4><center><b>"

			if(!length(GLOB.loadout_items))
				dat += "<center>ERROR: No loadout categories - something is horribly wrong!"
			else
				if(!GLOB.loadout_categories[gear_category])
					gear_category = GLOB.loadout_categories[1]
				var/firstcat = TRUE
				for(var/category in GLOB.loadout_categories)
					if(firstcat)
						firstcat = FALSE
					else
						dat += " |"
					if(category == gear_category)
						dat += " <a href='?_src_=prefs;preference=gear;select_category=[url_encode(category)]' class='linkOn'>[category]</a> "
					else
						dat += " <a href='?_src_=prefs;preference=gear;select_category=[url_encode(category)]'>[category]</a> "

				dat += "</b></center></td></tr>"
				dat += "<tr><td colspan=4><hr></td></tr>"

				dat += "<tr><td colspan=4><center><b>"

				if(!length(GLOB.loadout_categories[gear_category]))
					dat += "No subcategories detected. Something is horribly wrong!"
				else
					var/list/subcategories = GLOB.loadout_categories[gear_category]
					if(!subcategories.Find(gear_subcategory))
						gear_subcategory = subcategories[1]

					var/firstsubcat = TRUE
					for(var/subcategory in subcategories)
						if(firstsubcat)
							firstsubcat = FALSE
						else
							dat += " |"
						if(gear_subcategory == subcategory)
							dat += " <a href='?_src_=prefs;preference=gear;select_subcategory=[url_encode(subcategory)]' class='linkOn'>[subcategory]</a> "
						else
							dat += " <a href='?_src_=prefs;preference=gear;select_subcategory=[url_encode(subcategory)]'>[subcategory]</a> "
					dat += "</b></center></td></tr>"

					dat += "<tr width=10% style='vertical-align:top;'><td width=15%><b>Name</b></td>"
					dat += "<td style='vertical-align:top'><b>Cost</b></td>"
					dat += "<td width=10%><font size=2><b>Restrictions</b></font></td>"
					dat += "<td width=80%><font size=2><b>Description</b></font></td></tr>"
					// BLUEMOON FIX - Add null check to prevent runtime when category/subcategory has no items
					var/list/category_items = GLOB.loadout_items[gear_category]
					var/list/subcategory_items = category_items ? category_items[gear_subcategory] : null
					if(!length(subcategory_items))
						// Only log if category SHOULD exist (defined in loadout_categories) but has no items (initialization failure)
						if(GLOB.loadout_categories[gear_category] && (gear_subcategory in GLOB.loadout_categories[gear_category]))
							stack_trace("Loadout init failure (splurt): Category '[gear_category]'/subcategory '[gear_subcategory]' defined but has no items (user: [user?.ckey])")
						dat += "<tr><td colspan=4><center><i style=\"color: grey;\">No items available in this category.</i></center></td></tr>"
					// BLUEMOON FIX END
					for(var/name in subcategory_items)
						var/datum/gear/gear = subcategory_items[name]
						if(!gear)
							continue
						var/donoritem = gear.donoritem
						if(donoritem && !gear.donator_ckey_check(user.ckey))
							continue
						var/class_link = ""
						var/list/loadout_item = has_loadout_gear(loadout_slot, "[gear.type]")
						var/extra_loadout_data = ""
						if(loadout_item)
							class_link = "style='white-space:normal;' class='linkOn' href='?_src_=prefs;preference=gear;toggle_gear_path=[url_encode(name)];toggle_gear=0'"
							if(gear.loadout_flags & LOADOUT_CAN_COLOR_POLYCHROMIC)
								extra_loadout_data += "<BR><a href='?_src_=prefs;preference=gear;loadout_color_polychromic=1;loadout_gear_name=[url_encode(gear.name)];'>Color</a>"
								for(var/loadout_color in loadout_item[LOADOUT_COLOR])
									var/safe_loadout_color = sanitize_hexcolor(loadout_color, 6, TRUE, "#FFFFFF")
									extra_loadout_data += "<span style='border: 1px solid #161616; background-color: [safe_loadout_color];'><font color='[color_hex2num(safe_loadout_color) < 200 ? "FFFFFF" : "000000"]'>[safe_loadout_color]</font></span>"
							else
								var/loadout_color_non_poly = "#FFFFFF"
								if(length(loadout_item[LOADOUT_COLOR]))
									loadout_color_non_poly = loadout_item[LOADOUT_COLOR][1]
								loadout_color_non_poly = sanitize_hexcolor(loadout_color_non_poly, 6, TRUE, "#FFFFFF")
								extra_loadout_data += "<BR><a href='?_src_=prefs;preference=gear;loadout_color=1;loadout_gear_name=[url_encode(gear.name)];'>Color</a>"
								extra_loadout_data += "<span style='border: 1px solid #161616; background-color: [loadout_color_non_poly];'><font color='[color_hex2num(loadout_color_non_poly) < 200 ? "FFFFFF" : "000000"]'>[loadout_color_non_poly]</font></span>"
							if(gear.loadout_flags & LOADOUT_CAN_NAME)
								extra_loadout_data += "<BR><a href='?_src_=prefs;preference=gear;loadout_rename=1;loadout_gear_name=[url_encode(gear.name)];'>Name</a> [loadout_item[LOADOUT_CUSTOM_NAME] ? loadout_item[LOADOUT_CUSTOM_NAME] : "N/A"]"
							if(gear.loadout_flags & LOADOUT_CAN_DESCRIPTION)
								extra_loadout_data += "<BR><a href='?_src_=prefs;preference=gear;loadout_redescribe=1;loadout_gear_name=[url_encode(gear.name)];'>Description</a>"
							else
								extra_loadout_data += "<BR><a href='?_src_=prefs;preference=gear;loadout_addheirloom=1;loadout_gear_name=[url_encode(gear.name)];'>Select as Heirloom</a><BR>"
							// BLUEMOON ADD START - выбор вещей из лодаута как family heirloom
							if(loadout_item[LOADOUT_IS_HEIRLOOM])
								extra_loadout_data += "<BR><a class='linkOn' href='?_src_=prefs;preference=gear;loadout_removeheirloom=1;loadout_gear_name=[url_encode(gear.name)];'>Select as Heirloom</a><BR>"
							// BLUEMOON ADD END
						else if(!is_loadout_slot_available(gear.category))
							class_link = "style='white-space:normal;' class='linkOff'"
						else if((gear_points - gear.cost) < 0)
							class_link = "style='white-space:normal;' class='linkOff'"
						else if(donoritem)
							class_link = "style='white-space:normal;background:#ebc42e;' href='?_src_=prefs;preference=gear;toggle_gear_path=[url_encode(name)];toggle_gear=1'"
						else if(!istype(gear, /datum/gear/unlockable) || can_use_unlockable(gear))
							class_link = "style='white-space:normal;' href='?_src_=prefs;preference=gear;toggle_gear_path=[url_encode(name)];toggle_gear=1'"
						else
							class_link = "style='white-space:normal;background:#eb2e2e;' class='linkOff'"
						dat += "<tr style='vertical-align:top;'><td width=15%><a [class_link]>[name]</a>[extra_loadout_data]</td>"
						dat += "<td width = 5% style='vertical-align:top'>[gear.cost]</td><td>"
						if(islist(gear.restricted_roles))
							if(gear.restricted_roles.len)
								if(gear.restricted_desc)
									dat += "<font size=2>"
									dat += gear.restricted_desc
									dat += "</font>"
								else
									dat += "<font size=2>"
									dat += gear.restricted_roles.Join(";")
									dat += "</font>"
						if(!istype(gear, /datum/gear/unlockable))
							// the below line essentially means "if the loadout item is picked by the user and has a custom description, give it the custom description, otherwise give it the default description"
							dat += "</td><td><font size=2><i>[loadout_item ? (loadout_item[LOADOUT_CUSTOM_DESCRIPTION] ? loadout_item[LOADOUT_CUSTOM_DESCRIPTION] : gear.description) : gear.description]</i></font></td></tr>"
						else
							//we add the user's progress to the description assuming they have progress
							var/datum/gear/unlockable/unlockable = gear
							var/progress_made = unlockable_loadout_data[unlockable.progress_key]
							if(!progress_made)
								progress_made = 0
							dat += "</td><td><font size=2><i>[loadout_item ? (loadout_item[LOADOUT_CUSTOM_DESCRIPTION] ? loadout_item[LOADOUT_CUSTOM_DESCRIPTION] : gear.description) : gear.description] Progress: [min(progress_made, unlockable.progress_required)]/[unlockable.progress_required]</i></font></td></tr>"

					dat += "</table>"
		if(CONTENT_PREFERENCES_TAB) // Content preferences
			dat += "<table><tr><td width='340px' height='300px' valign='top'>"
			var/fetish_content_prefs_label = src.use_modern_translations ? get_modern_text("fetish_content_prefs", src) : "Fetish content prefs"
			var/other_content_prefs_label = src.use_modern_translations ? get_modern_text("other_content_prefs", src) : "Other content prefs"
			dat += "<h2>[fetish_content_prefs_label]</h2>"
			dat += "<b>Allow Lewd Verbs:</b> <a href='?_src_=prefs;preference=verb_consent'>[(toggles & VERB_CONSENT) ? "Yes":"No"]</a><br>" // Skyrat - ERP Mechanic Addition
			dat += "<b>Mute Lewd Verb Sounds:</b> <a href='?_src_=prefs;preference=mute_lewd_verb_sounds'>[(toggles & LEWD_VERB_SOUNDS) ? "Yes":"No"]</a><br>" // Skyrat - ERP Mechanic Addition
			dat += "<b>Arousal:</b><a href='?_src_=prefs;preference=arousable'>[arousable == TRUE ? "Enabled" : "Disabled"]</a><BR>"
			dat += "<b>Allow Knotting:</b><a href='?_src_=prefs;preference=sexknotting'>[sexknotting == TRUE ? "Enabled" : "Disabled"]</a><BR>"
			dat += "<b>Genital examine text</b>:<a href='?_src_=prefs;preference=genital_examine'>[(cit_toggles & GENITAL_EXAMINE) ? "Enabled" : "Disabled"]</a><BR>"
			dat += "<b>Vore examine text</b>:<a href='?_src_=prefs;preference=vore_examine'>[(cit_toggles & VORE_EXAMINE) ? "Enabled" : "Disabled"]</a><BR>"
			dat += "<b>Voracious MediHound sleepers:</b> <a href='?_src_=prefs;preference=hound_sleeper'>[(cit_toggles & MEDIHOUND_SLEEPER) ? "Yes" : "No"]</a><br>"
			dat += "<b>Hear Vore Sounds:</b> <a href='?_src_=prefs;preference=toggleeatingnoise'>[(cit_toggles & EATING_NOISES) ? "Yes" : "No"]</a><br>"
			dat += "<b>Hear Vore Digestion Sounds:</b> <a href='?_src_=prefs;preference=toggledigestionnoise'>[(cit_toggles & DIGESTION_NOISES) ? "Yes" : "No"]</a><br>"
			dat += "<b>Allow trash forcefeeding (requires Trashcan quirk)</b> <a href='?_src_=prefs;preference=toggleforcefeedtrash'>[(cit_toggles & TRASH_FORCEFEED) ? "Yes" : "No"]</a><br>"
			dat += "<b>Forced Feminization:</b> <a href='?_src_=prefs;preference=feminization'>[(cit_toggles & FORCED_FEM) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Forced Masculinization:</b> <a href='?_src_=prefs;preference=masculinization'>[(cit_toggles & FORCED_MASC) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Lewd Hypno:</b> <a href='?_src_=prefs;preference=hypno'>[(cit_toggles & HYPNO) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Bimbofication:</b> <a href='?_src_=prefs;preference=bimbo'>[(cit_toggles & BIMBOFICATION) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "</td>"
			dat +="<td width='300px' height='300px' valign='top'>"
			dat += "<h2>[other_content_prefs_label]</h2>"
			dat += "<b>Breast Enlargement:</b> <a href='?_src_=prefs;preference=breast_enlargement'>[(cit_toggles & BREAST_ENLARGEMENT) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Penis Enlargement:</b> <a href='?_src_=prefs;preference=penis_enlargement'>[(cit_toggles & PENIS_ENLARGEMENT) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Butt Enlargement:</b> <a href='?_src_=prefs;preference=butt_enlargement'>[(cit_toggles & BUTT_ENLARGEMENT) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Belly Inflation:</b> <a href='?_src_=prefs;preference=belly_inflation'>[(cit_toggles & BELLY_INFLATION) ? "Allowed" : "Disallowed"]</a><br>"
			dat += "<b>Hypno:</b> <a href='?_src_=prefs;preference=never_hypno'>[(cit_toggles & NEVER_HYPNO) ? "Disallowed" : "Allowed"]</a><br>"
			dat += "<b>Aphrodisiacs:</b> <a href='?_src_=prefs;preference=aphro'>[(cit_toggles & NO_APHRO) ? "Disallowed" : "Allowed"]</a><br>"
			dat += "<b>Ass Slapping:</b> <a href='?_src_=prefs;preference=ass_slap'>[(cit_toggles & NO_ASS_SLAP) ? "Disallowed" : "Allowed"]</a><br>"
			//Gardelin0 EDIT
			dat += "<b>Sex Jitter:</b> <a href='?_src_=prefs;preference=sex_jitter'>[(cit_toggles & SEX_JITTER) ? "Allowed" : "Disallowed"]</a><br>"
			//SPLURT EDIT
			dat += "<span style='border-radius: 2px;border:1px dotted white;cursor:help;' title='Enables verbs involving farts, shit and piss.'>?</span> "
			dat += "<b>Unholy ERP verbs :</b> <a href='?_src_=prefs;preference=unholypref'>[unholypref]</a><br>" //https://www.youtube.com/watch?v=OHKARc-GObU
			dat += "<span style='border-radius: 2px;border:1px dotted white;cursor:help;' title='Enables macro / micro stepping and stomping interactions.'>?</span> "
//			dat += "<b>Stomping Interactions :</b> <a href='?_src_=prefs;preference=stomppref'>[stomppref ? "Yes" : "No"]</a><br>"
			//END OF SPLURT EDIT
			//SKYRAT EDIT
			dat += "<span style='border-radius: 2px;border:1px dotted white;cursor:help;' title='Enables verbs involving ear/brain fucking.'>?</span> "
			dat += 	"<b>Extreme ERP verbs :</b> <a href='?_src_=prefs;preference=extremepref'>[extremepref]</a><br>" // https://youtu.be/0YrU9ASVw6w
			if(extremepref != "No")
				dat += "<span style='border-radius: 2px;border:1px dotted white;cursor:help;' title='Enables in-game damage from extreme verbs.'>?</span> "
				dat += "<b><span style='color: #e60000;'>Harmful ERP verbs :</b> <a href='?_src_=prefs;preference=extremeharm'>[extremeharm]</a><br>"
			//END OF SKYRAT EDIT
			dat += "<b>Automatic Wagging:</b> <a href='?_src_=prefs;preference=auto_wag'>[(cit_toggles & NO_AUTO_WAG) ? "Disabled" : "Enabled"]</a><br>"
			dat += "<b>Dance Near Disco Ball:</b> <a href='?_src_=prefs;preference=disco_dance'>[(cit_toggles & NO_DISCO_DANCE) ? "Disabled" : "Enabled"]</a><br>"
			dat += "<span style='border-radius: 2px;border:1px dotted white;cursor:help;' title='If anyone cums a blacklisted fluid into you, it uses the default fluid for that genital.'>?</span> "
			dat += "<b><a href='?_src_=prefs;preference=gfluid_black;task=input'>Genital Fluid Blacklist</a></b><br>"
			if(gfluid_blacklist?.len)
				dat += "<span style='border-radius: 2px;border:1px dotted white;cursor:help;' title='Remove a genital fluid from your blacklist.'>?</span> "
				dat += "<b><a href='?_src_=prefs;preference=gfluid_unblack;task=input'>Genital Fluid Un-Blacklist</a></b><br>"
			dat += "</tr></table>"
			dat += "<br>"
		if(KEYBINDINGS_TAB_OLD) // Custom keybindings
			dat += "<b>Keybindings:</b> <a href='?_src_=prefs;preference=hotkeys'>[(hotkeys) ? "Hotkeys" : "Input"]</a><br>"
			dat += "Keybindings mode controls how the game behaves with tab and map/input focus.<br>If it is on <b>Hotkeys</b>, the game will always attempt to force you to map focus, meaning keypresses are sent \
			directly to the map instead of the input. You will still be able to use the command bar, but you need to tab to do it every time you click on the game map.<br>\
			If it is on <b>Input</b>, the game will not force focus away from the input bar, and you can switch focus using TAB between these two modes: If the input bar is pink, that means that you are in non-hotkey mode, sending all keypresses of the normal \
			alphanumeric characters, punctuation, spacebar, backspace, enter, etc, typing keys into the input bar. If the input bar is white, you are in hotkey mode, meaning all keypresses go into the game's keybind handling system unless you \
			manually click on the input bar to shift focus there.<br>\
			Input mode is the closest thing to the old input system.<br>\
			<b>IMPORTANT:</b> While in input mode's non hotkey setting (tab toggled), Ctrl + KEY will send KEY to the keybind system as the key itself, not as Ctrl + KEY. This means Ctrl + T/W/A/S/D/all your familiar stuff still works, but you \
			won't be able to access any regular Ctrl binds.<br>"
			dat += "<br><b>Modifier-Independent binding</b> - This is a singular bind that works regardless of if Ctrl/Shift/Alt are held down. For example, if combat mode is bound to C in modifier-independent binds, it'll trigger regardless of if you are \
			holding down shift for sprint. <b>Each keybind can only have one independent binding, and each key can only have one keybind independently bound to it.</b>"
			// Create an inverted list of keybindings -> key
			var/list/user_binds = list()
			var/list/user_modless_binds = list()
			for (var/key in key_bindings)
				for(var/kb_name in key_bindings[key])
					user_binds[kb_name] += list(key)
			for (var/key in modless_key_bindings)
				user_modless_binds[modless_key_bindings[key]] = key

			var/list/kb_categories = list()
			// Group keybinds by category
			for (var/name in GLOB.keybindings_by_name)
				var/datum/keybinding/kb = GLOB.keybindings_by_name[name]
				kb_categories[kb.category] += list(kb)

			for (var/category in kb_categories)
				dat += "<h3>[category]</h3>"
				for (var/i in kb_categories[category])
					var/datum/keybinding/kb = i
					var/current_independent_binding = user_modless_binds[kb.name] || "Unbound"
					if(!length(user_binds[kb.name]))
						dat += "<span class='bindname'>[kb.full_name]</span><span class='bindings'><a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=Unbound'>Unbound</a>"
						var/list/default_keys = hotkeys ? kb.hotkey_keys : kb.classic_keys
						if(LAZYLEN(default_keys))
							dat += "| Default: [default_keys.Join(", ")]"
						dat += "</span>"
						if(!kb.special && !kb.clientside)
							dat += "<span class='independent'>Independent Binding: <a href='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=[current_independent_binding];independent=1'>[current_independent_binding]</a></span>"
						dat += "<br>"
					else
						var/bound_key = user_binds[kb.name][1]
						dat += "<span class='bindname'l>[kb.full_name]</span><span class='bindings'><a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=[bound_key]'>[bound_key]</a>"
						for(var/bound_key_index in 2 to length(user_binds[kb.name]))
							bound_key = user_binds[kb.name][bound_key_index]
							dat += " | <a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=[bound_key]'>[bound_key]</a>"
						if(length(user_binds[kb.name]) < MAX_KEYS_PER_KEYBIND)
							dat += "| <a href ='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name]'>Add Secondary</a>"
						var/list/default_keys = hotkeys ? kb.classic_keys : kb.hotkey_keys
						if(LAZYLEN(default_keys))
							dat += "| Default: [default_keys.Join(", ")]"
						dat += "</span>"
						if(!kb.special && !kb.clientside)
							dat += "<span class='independent'>Independent Binding: <a href='?_src_=prefs;preference=keybindings_capture;keybinding=[kb.name];old_key=[current_independent_binding];independent=1'>[current_independent_binding]</a></span>"
						dat += "<br>"

			dat += "<br><br>"
			dat += "<a href ='?_src_=prefs;preference=keybindings_reset'>\[Reset to default\]</a>"
			dat += "</body>"


	dat += "<hr><center>"

	if(!IsGuestKey(user.key))
		dat += "<a href='?_src_=prefs;preference=load'>Undo</a> "
		dat += "<a href='?_src_=prefs;preference=save'>Save Setup</a> "

	dat += "<a href='?_src_=prefs;preference=reset_all'>Reset Setup</a>"
	dat += "</center>"

	winshow(user, "preferences_window", TRUE)
	var/datum/browser/popup = new(user, "preferences_browser", "<div align='center'>Character Setup</div>", 640, 770)
	popup.set_content(dat.Join())
	popup.open(FALSE)
	onclose(user, "preferences_window", src)

#undef APPEARANCE_CATEGORY_COLUMN
#undef MAX_MUTANT_ROWS

/datum/config_entry/multi_keyed_flag/donator_group
	abstract_type = /datum/config_entry/multi_keyed_flag/donator_group

//If we're in the middle of a config load, only do the regeneration afterwards to prevent this from wasting a massive amount of CPU for list regenerations.
/datum/config_entry/multi_keyed_flag/donator_group/ValidateAndSet(str_val, during_load)
	. = ..()
	if(. && !during_load)
		regenerate_donator_grouping_list()

/datum/config_entry/multi_keyed_flag/donator_group/process_key(key)
	return ckey(key)

/datum/config_entry/multi_keyed_flag/donator_group/OnPostload()
	. = ..()
	regenerate_donator_grouping_list()

//This is kinda weird in that the config entries are defined here but all the handling/calculations are in __HELPERS/donator_groupings.dm

/datum/config_entry/multi_keyed_flag/donator_group/tier_1_donators

/datum/config_entry/multi_keyed_flag/donator_group/tier_2_donators

/datum/config_entry/multi_keyed_flag/donator_group/tier_3_donators

/// Private AES-256-GCM key, kept in the server-only donator config.
/datum/config_entry/string/loadout_ckey_secret
	default = ""
	protection = CONFIG_ENTRY_LOCKED | CONFIG_ENTRY_HIDDEN

/// Node.js executable (not a shell command); uses only the built-in crypto module.
/datum/config_entry/string/loadout_crypto_node
	default = "node"
	protection = CONFIG_ENTRY_LOCKED

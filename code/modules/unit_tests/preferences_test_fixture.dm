// Старый тест удален полностью, это заглушка ну на всякий случай
/datum/preferences/navigation_test/New()
	..(null)

/datum/preferences/navigation_test/save_preferences(bypass_cooldown = FALSE, silent = FALSE)
	return TRUE

/datum/preferences/navigation_test/Destroy(force)
	var/test_path = path
	. = ..()
	if(test_path)
		for(var/suffix in list("", ".json", ".json.recovery"))
			fdel("[test_path][suffix]")
		fdel("[test_path].json.d/")

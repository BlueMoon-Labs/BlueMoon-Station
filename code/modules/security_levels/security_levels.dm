GLOBAL_VAR_INIT(security_level, SEC_LEVEL_GREEN)
//SEC_LEVEL_GREEN = code green
//SEC_LEVEL_BLUE = code blue
//SEC_LEVEL_ORANGE = code orange
//SEC_LEVEL_VIOLET = code violet
//SEC_LEVEL_AMBER = code amber
//SEC_LEVEL_RED = code red
//SEC_LEVEL_LAMBDA = code lambda
//SEC_LEVEL_GAMMA = code gamma
//SEC_LEVEL_EPSILON = code epsilon
//SEC_LEVEL_DELTA = code delta

/proc/get_security_level()
	switch(GLOB.security_level)
		if(SEC_LEVEL_GREEN)
			return "<font color=#b2ff59>ЗЕЛЁНЫЙ</font>"
		if(SEC_LEVEL_BLUE)
			return "<font color=#99ccff>СИНИЙ</font>"
		if(SEC_LEVEL_ORANGE)
			return "<font color=fc7d15>ОРАНЖЕВЫЙ</font>"
		if(SEC_LEVEL_VIOLET)
			return "<font color=#a059fe>ФИОЛЕТОВЫЙ</font>"
		if(SEC_LEVEL_AMBER)
			return "<font color=#ffae42>ЯНТАРНЫЙ</font>"
		if(SEC_LEVEL_RED)
			return "<font color=#ff3f34>КРАСНЫЙ</font>"
		if(SEC_LEVEL_LAMBDA)
			return "<font color=#ffae42>ЛЯМБДА</font>"
		if(SEC_LEVEL_GAMMA)
			return "<font color=#7f7f7f>ГАММА</font>"
		if(SEC_LEVEL_EPSILON)
			return "<font color=#ffffff>ЭПСИЛОН</font>"
		if(SEC_LEVEL_DELTA)
			return "<font color=purple>ДЕЛЬТА</font>"

/*
  * All security levels, per ascending alert. Nothing too fancy, really.
  * Their positions should also match their numerical values.
  */
GLOBAL_LIST_INIT(all_security_levels, list("green", "blue", "orange", "violet", "amber", "red", "lambda", "gamma", "epsilon", "delta"))

//config.alert_desc_blue_downto

/proc/set_security_level(level, secret_variant_override = null)
	SSsecurity_level.set_level(level, secret_variant_override)

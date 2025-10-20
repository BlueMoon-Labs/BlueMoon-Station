//Таков путь

/datum/shadekin_eye_model
	var/gain_in_light = 0.25
	var/gain_in_dark = 0.75

	var/nutrition_conversion_scaling = 0.5

/datum/shadekin_eye_model/red
	gain_in_light = -0.5
	gain_in_dark = 0.5
	nutrition_conversion_scaling = 2

/datum/shadekin_eye_model/orange
	gain_in_light = -0.25
	gain_in_dark = 0.75
	nutrition_conversion_scaling = 1.5

/datum/shadekin_eye_model/yellow
	gain_in_light = -2
	gain_in_dark = 3
	nutrition_conversion_scaling = 0.5

/datum/shadekin_eye_model/green
	gain_in_light = 0.125
	gain_in_dark = 2
	nutrition_conversion_scaling = 0.5

/datum/shadekin_eye_model/blue
	gain_in_light = 0.75
	gain_in_dark = 0.75
	nutrition_conversion_scaling = 0.5

/datum/shadekin_eye_model/purple
	gain_in_light = -0.5
	gain_in_dark = 1
	nutrition_conversion_scaling = 1

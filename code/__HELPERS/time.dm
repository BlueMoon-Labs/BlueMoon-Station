/proc/station_time_debug(force_set)
	if(isnum(force_set))
		SSticker.gametime_offset = force_set
		return
	SSticker.gametime_offset = rand(0, 864000)		//hours in day * minutes in hour * seconds in minute * deciseconds in second
	if(prob(50))
		SSticker.gametime_offset = FLOOR(SSticker.gametime_offset, 3600)
	else
		SSticker.gametime_offset = CEILING(SSticker.gametime_offset, 3600)

/* Returns 1 if it is the selected month and day */
/proc/isDay(month, day)
	if(isnum(month) && isnum(day))
		var/MM = text2num(time2text(world.timeofday, "MM")) // get the current month
		var/DD = text2num(time2text(world.timeofday, "DD")) // get the current day
		if(month == MM && day == DD)
			return TRUE

//returns timestamp in a sql and a not-quite-compliant ISO 8601 friendly format
/proc/SQLtime(timevar)
	return time2text(timevar || world.timeofday, "YYYY-MM-DD hh:mm:ss")


GLOBAL_VAR_INIT(midnight_rollovers, 0)
GLOBAL_VAR_INIT(rollovercheck_last_timeofday, 0)
/proc/update_midnight_rollover()
	if (world.timeofday < GLOB.rollovercheck_last_timeofday) //TIME IS GOING BACKWARDS!
		GLOB.midnight_rollovers++
	GLOB.rollovercheck_last_timeofday = world.timeofday
	return GLOB.midnight_rollovers

/proc/weekdayofthemonth()
	var/DD = text2num(time2text(world.timeofday, "DD")) 	// get the current day
	switch(DD)
		if(8 to 13)
			return 2
		if(14 to 20)
			return 3
		if(21 to 27)
			return 4
		if(28 to INFINITY)
			return 5
		else
			return TRUE

//Takes a value of time in deciseconds.
//Returns a text value of that number in hours, minutes, or seconds.
/proc/DisplayTimeText(time_value, round_seconds_to = 0.1)
	var/second = FLOOR(time_value * 0.1, round_seconds_to)
	if(!second)
		return "сейчас"
	if(second < 60)
		return "[second] секунд[second % 10 == 1 && second % 100 != 11 ? "а" : (second % 10 >= 2 && second % 10 <= 4 && (second % 100 < 10 || second % 100 >= 20) ? "ы" : "")]"
	var/minute = FLOOR(second / 60, 1)
	second = FLOOR(MODULUS(second, 60), round_seconds_to)
	var/secondT
	if(second)
		secondT = " и [second] секунд[second % 10 == 1 && second % 100 != 11 ? "а" : (second % 10 >= 2 && second % 10 <= 4 && (second % 100 < 10 || second % 100 >= 20) ? "ы" : "")]"
	if(minute < 60)
		return "[minute] минут[minute % 10 == 1 && minute % 100 != 11 ? "а" : (minute % 10 >= 2 && minute % 10 <= 4 && (minute % 100 < 10 || minute % 100 >= 20) ? "ы" : "")][secondT]"
	var/hour = FLOOR(minute / 60, 1)
	minute = MODULUS(minute, 60)
	var/minuteT
	if(minute)
		minuteT = " и [minute] минут[(minute != 1)? "":"у"]"
	if(hour < 24)
		return "[hour] час[(hour != 1)? "а":""][minuteT][secondT]"
	var/day = FLOOR(hour / 24, 1)
	hour = MODULUS(hour, 24)
	var/hourT
	if(hour)
		hourT = " и [hour] час[(hour != 1)? "а":""]"
	return "[day] д[(day != 1)? "ня":"ень"][hourT][minuteT][secondT]"

/proc/daysSince(realtimev)
	return round((world.realtime - realtimev) / (24 HOURS))

/proc/worldtime2text(wtime = world.timeofday)
	return gameTimestamp("hh:mm:ss", wtime)

/proc/gameTimestamp(format = "hh:mm:ss", wtime=world.time)
	return time2text(wtime - GLOB.timezoneOffset, format)

/// Час по часам сервера (как в time2text(world.timeofday, "hh")) в московском времени
/proc/server_hour_to_msk(hour)
	var/msk_hour = hour - GLOB.timezoneOffset / (1 HOURS) + MSK_UTC_OFFSET_HOURS
	return (msk_hour % 24 + 24) % 24

//Take a value in seconds and returns a string of minutes and seconds in the format X minute(s) and X seconds.
/proc/seconds_to_time(var/seconds as num)
	var/numSeconds = seconds % 60
	var/numMinutes = (seconds - numSeconds) / 60
	return "[numMinutes] [numMinutes > 1 ? "минут" : "минуты"] и [numSeconds] секунд"

//Take a value in seconds and makes it display like a clock
/proc/seconds_to_clock(var/seconds as num)
	return "[add_zero(num2text((seconds / 60) % 60), 2)]:[add_zero(num2text(seconds % 60), 2)]"

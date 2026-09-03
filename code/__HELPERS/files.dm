//Sends resource files to client cache
/client/proc/getFiles()
	for(var/file in args)
		src << browse_rsc(file)

#define FTPDELAY 200	//200 tick delay to discourage spam
#define ADMIN_FTPDELAY_MODIFIER 0.5		//Admins get to spam files faster since we ~trust~ them!
/*	This proc is a failsafe to prevent spamming of file requests.
	It is just a timer that only permits a download every [FTPDELAY] ticks.
	This can be changed by modifying FTPDELAY's value above.

	PLEASE USE RESPONSIBLY, Some log files can reach sizes of 4MB!	*/
/client/proc/file_spam_check()
	var/time_to_wait = GLOB.fileaccess_timer - world.time
	if(time_to_wait > 0)
		to_chat(src, "<font color='red'>Error: file_spam_check(): Spam. Please wait [DisplayTimeText(time_to_wait)].</font>")
		return TRUE
	var/delay = FTPDELAY
	if(holder)
		delay *= ADMIN_FTPDELAY_MODIFIER
	GLOB.fileaccess_timer = world.time + delay
	return FALSE
#undef FTPDELAY
#undef ADMIN_FTPDELAY_MODIFIER

/proc/pathwalk(path)
	var/list/jobs = list(path)
	var/list/filenames = list()

	while(jobs.len)
		var/current_dir = pop(jobs)
		var/list/new_filenames = flist(current_dir)
		for(var/new_filename in new_filenames)
			// if filename ends in / it is a directory, append to currdir
			if(findtext(new_filename, "/", -1))
				jobs += current_dir + new_filename
			else
				filenames += current_dir + new_filename
	return filenames

/proc/pathflatten(path)
	return replacetext(path, "/", "_")

/// Returns the md5 of a file at a given path.
/// Нативный хеш rust-g: BYOND'овский md5(file()) на путях с диска блокировал тик на ~20мс за файл
/// (генерация ассетов при коннектах). Читает файл напрямую с диска, минуя маршаллинг в BYOND.
/proc/md5filepath(path)
	. = rustg_hash_file(RUSTG_HASH_MD5, path)

/// Save file as an external file then md5 it.
/// Used because md5ing files stored in the rsc sometimes gives incorrect md5 results.
/proc/md5asfile(file)
	var/static/notch = 0
	// md5filepath теперь на rust-g (hash_file): вызов по-прежнему синхронный и блокирующий, не спящий - просто заметно короче нативного md5(file()).
	var/filename = "tmp/md5asfile.[world.realtime].[world.timeofday].[world.time].[world.tick_usage].[notch]"
	notch = WRAP(notch+1, 0, 2^15)
	fcopy(file, filename)
	. = md5filepath(filename)
	fdel(filename)

/// Basic checks so shelleo / shell snippets are not abused via crafted paths (admin-only endpoints, still).
/proc/is_safe_path_for_admin_shell(path)
	if(!path || length(path) > 1024 || findtext(path, ".."))
		return FALSE
	// "%" - от разворачивания %VAR% в cmd.exe: на Windows оно работает даже внутри кавычек.
	var/static/list/bad_substrings = list(";", "&", "|", "`", "\n", "<", ">", "\"", "*", "%")
	for(var/bad in bad_substrings)
		if(findtext(path, bad))
			return FALSE
	if(findtext(path, ascii2text(13)))
		return FALSE
	return TRUE

/// Single-quote a path for POSIX `sh -c` (e.g. wrapping `stat` / `head` arguments).
/proc/shell_single_quote_path(path)
	return "'" + replacetext(path, "'", "'\\''") + "'"

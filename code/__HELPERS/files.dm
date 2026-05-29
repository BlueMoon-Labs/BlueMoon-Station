//Sends resource files to client cache
/client/proc/getFiles()
	for(var/file in args)
		src << browse_rsc(file)

/client/proc/browse_files(root="data/logs/", max_iterations=10, list/valid_extensions=list("txt","log","htm", "html", "md", "json"))
	var/path = root

	for(var/i=0, i<max_iterations, i++)
		var/list/choices = flist(path)
		if(path != root)
			choices.Insert(1,"/")

		choices = sort_list(choices)
		var/choice = tgui_input_list(src,"Choose a file to access:","Download",choices)
		switch(choice)
			if(null)
				return
			if("/")
				path = root
				continue
		path += choice

		if(copytext_char(path, -1) != "/")		//didn't choose a directory, no need to iterate again
			break
	var/extensions
	for(var/i in valid_extensions)
		if(extensions)
			extensions += "|"
		extensions += "[i]"
	var/regex/valid_ext = new("\\.([extensions])$", "i")
	if( !fexists(path) || !(valid_ext.Find(path)) )
		to_chat(src, "<font color='red'>Error: browse_files(): File not found/Invalid file([path]).</font>")
		return

	return path

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
/proc/md5filepath(path)
	. = md5(file(path))

/// Save file as an external file then md5 it.
/// Used because md5ing files stored in the rsc sometimes gives incorrect md5 results.
/proc/md5asfile(file)
	var/static/notch = 0
	// its importaint this code can handle md5filepath sleeping instead of hard blocking, if it's converted to use rust_g.
	var/filename = "tmp/md5asfile.[world.realtime].[world.timeofday].[world.time].[world.tick_usage].[notch]"
	notch = WRAP(notch+1, 0, 2^15)
	fcopy(file, filename)
	. = md5filepath(filename)
	fdel(filename)

/// Max bytes read into memory for admin in-game log viewer (avoids DreamDaemon OOM / libbyond crash on huge files).
#define ADMIN_LOG_VIEW_MAX_BYTES (512 * 1024)

/// Basic checks so shelleo / shell snippets are not abused via crafted paths (browse_files is admin-only, still).
/proc/is_safe_path_for_admin_shell(path)
	if(!path || length(path) > 1024 || findtext(path, ".."))
		return FALSE
	var/static/list/bad_substrings = list(";", "&", "|", "`", "\n", "<", ">", "\"", "*")
	for(var/bad in bad_substrings)
		if(findtext(path, bad))
			return FALSE
	if(findtext(path, ascii2text(13)))
		return FALSE
	return TRUE

/// Single-quote a path for POSIX `sh -c` (e.g. wrapping `stat` / `head` arguments).
/proc/shell_single_quote_path(path)
	return "'" + replacetext(path, "'", "'\\''") + "'"

/proc/get_admin_log_file_size_bytes(path)
	if(!fexists(path) || !is_safe_path_for_admin_shell(path))
		return -1
	if(world.system_type == UNIX)
		var/list/so = world.shelleo("stat -c %s [shell_single_quote_path(path)]")
		if(so[1] != 0)
			return -1
		return text2num(trim(so[2]))
	if(world.system_type == MS_WINDOWS)
		var/id = "[world.realtime]_[rand(1, 999999)]"
		var/pathfile = "data/admin_log_szpath_[id].txt"
		var/ps1 = "data/admin_log_sz_[id].ps1"
		rustg_file_write(path, pathfile)
		var/ps_body = jointext(list(
			"$pf = Join-Path (Get-Location) 'data/admin_log_szpath_[id].txt'",
			"$src = (Get-Content -LiteralPath $pf -Raw).Trim()",
			"Write-Output ((Get-Item -LiteralPath $src).Length)",
		), "\n")
		rustg_file_write(ps_body, ps1)
		var/list/so = world.shelleo("powershell -NoProfile -ExecutionPolicy Bypass -File [ps1]")
		fdel(pathfile)
		fdel(ps1)
		if(so[1] != 0)
			return -1
		return text2num(trim(so[2]))
	return -1

/// Reads at most ADMIN_LOG_VIEW_MAX_BYTES from disk without loading the whole file into DM (Unix: head; Windows: PowerShell).
/proc/read_admin_log_preview(path)
	if(!fexists(path) || !is_safe_path_for_admin_shell(path))
		return null
	if(world.system_type == UNIX)
		var/tmp = "data/admin_log_view_[world.realtime]_[rand(1, 999999)].tmp"
		var/list/so = world.shelleo("head -c [ADMIN_LOG_VIEW_MAX_BYTES] [shell_single_quote_path(path)] > [shell_single_quote_path(tmp)]")
		if(so[1] != 0)
			if(fexists(tmp))
				fdel(tmp)
			return null
		if(!fexists(tmp))
			return null
		var/chunk = file2text(tmp)
		fdel(tmp)
		return chunk
	if(world.system_type == MS_WINDOWS)
		var/id = "[world.realtime]_[rand(1, 999999)]"
		var/pathfile = "data/admin_log_path_[id].txt"
		var/outfile = "data/admin_log_out_[id].tmp"
		var/ps1 = "data/admin_log_read_[id].ps1"
		rustg_file_write(path, pathfile)
		// $ и [] в тексте PS собираем через ascii2text — иначе dreamchecker ломает разбор строк.
		var/ps_dollar = ascii2text(36)
		var/ps_dot = ascii2text(46)
		var/ps_dq = ascii2text(34)
		var/ps_lb = ascii2text(91)
		var/ps_rb = ascii2text(93)
		var/ps_body = jointext(list(
			ps_dollar + "pf = Join-Path (Get-Location) " + ps_dq + "data/admin_log_path_" + id + ".txt" + ps_dq,
			ps_dollar + "out = Join-Path (Get-Location) " + ps_dq + "data/admin_log_out_" + id + ".tmp" + ps_dq,
			ps_dollar + "max = " + num2text(ADMIN_LOG_VIEW_MAX_BYTES),
			ps_dollar + "src = (Get-Content -LiteralPath " + ps_dollar + "pf -Raw).Trim()",
			ps_dollar + "fs = " + ps_lb + "System" + ps_dot + "IO" + ps_dot + "File" + ps_rb + "::OpenRead(" + ps_dollar + "src)",
			"try {",
			"  " + ps_dollar + "buf = New-Object byte" + ps_lb + ps_rb + " " + ps_dollar + "max",
			"  " + ps_dollar + "r = " + ps_dollar + "fs" + ps_dot + "Read(" + ps_dollar + "buf, 0, " + ps_dollar + "buf" + ps_dot + "Length)",
			"  if (" + ps_dollar + "r -gt 0) {",
			"    " + ps_dollar + "slice = New-Object byte" + ps_lb + ps_rb + " " + ps_dollar + "r",
			"    " + ps_lb + "Array" + ps_rb + "::Copy(" + ps_dollar + "buf, " + ps_dollar + "slice, " + ps_dollar + "r)",
			"    " + ps_lb + "System" + ps_dot + "IO" + ps_dot + "File" + ps_rb + "::WriteAllBytes(" + ps_dollar + "out, " + ps_dollar + "slice)",
			"  } else {",
			"    " + ps_lb + "System" + ps_dot + "IO" + ps_dot + "File" + ps_rb + "::WriteAllBytes(" + ps_dollar + "out, (New-Object byte" + ps_lb + ps_rb + " 0))",
			"  }",
			"} finally {",
			"  " + ps_dollar + "fs" + ps_dot + "Dispose()",
			"}",
		), "\n")
		rustg_file_write(ps_body, ps1)
		var/list/so = world.shelleo("powershell -NoProfile -ExecutionPolicy Bypass -File [ps1]")
		fdel(pathfile)
		fdel(ps1)
		if(so[1] != 0)
			if(fexists(outfile))
				fdel(outfile)
			return null
		if(!fexists(outfile))
			return null
		var/outchunk = file2text(outfile)
		fdel(outfile)
		return outchunk
	return null

#undef ADMIN_LOG_VIEW_MAX_BYTES

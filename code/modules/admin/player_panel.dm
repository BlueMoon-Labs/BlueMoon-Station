/datum/admins/proc/player_panel_new()//The new one
	if(!check_rights())
		return
	log_admin("[key_name(usr)] checked the player panel in [usr.loc] and X:[usr.x] Y:[usr.y] Z:[usr.z] coordinate.")
	var/dat = ""

	//javascript, the part that does most of the work~
	dat += {"

		<head>
			<script type='text/javascript'>

				var locked_tabs = new Array();

				function updateSearch(){


					var filter_text = document.getElementById('filter');
					var filter = filter_text.value.toLowerCase();

					if(complete_list != null && complete_list != ""){
						var mtbl = document.getElementById("maintable_data_archive");
						mtbl.innerHTML = complete_list;
					}

					if(filter.value == ""){
						return;
					}else{

						var maintable_data = document.getElementById('maintable_data');
						var ltr = maintable_data.getElementsByTagName("tr");
						for ( var i = 0; i < ltr.length; ++i )
						{
							try{
								var tr = ltr\[i\];
								if(tr.getAttribute("id").indexOf("data") != 0){
									continue;
								}
								var ltd = tr.getElementsByTagName("td");
								var td = ltd\[0\];
								var lsearch = td.getElementsByTagName("b");
								var search = lsearch\[0\];
								//var inner_span = li.getElementsByTagName("span")\[1\] //Should only ever contain one element.
								//document.write("<p>"+search.innerText+"<br>"+filter+"<br>"+search.innerText.indexOf(filter))
								if ( search.innerText.toLowerCase().indexOf(filter) == -1 )
								{
									//document.write("a");
									//ltr.removeChild(tr);
									td.innerHTML = "";
									i--;
								}
							}catch(err) {   }
						}
					}

					var count = 0;
					var index = -1;
					var debug = document.getElementById("debug");

					locked_tabs = new Array();

				}

				function expand(id,job,name,real_name,image,key,ip,antagonist,ref){

					clearAll();

					var span = document.getElementById(id);
					var ckey = key.toLowerCase().replace(/\[^a-z@0-9\]+/g,"");

					body = "<table><tr><td align='center'>";

					body += "<b>"+job+" "+name+"</b><br><b>Real name "+real_name+"</b><br><b>Played by "+key+" ("+ip+")</b>"

					body += "</td><td align='center'>";

					body += "<a href='?_src_=holder;[HrefToken()];adminplayeropts="+ref+"'>PP</a> - "
					body += "<a href='?_src_=holder;[HrefToken()];showmessageckey="+ckey+"'>N</a> - "
					body += "<a href='?_src_=vars;[HrefToken()];Vars="+ref+"'>VV</a> - "
					body += "<a href='?_src_=holder;[HrefToken()];traitor="+ref+"'>TP</a> - "
					if (job == "Cyborg")
						body += "<a href='?_src_=holder;[HrefToken()];borgpanel="+ref+"'>BP</a> - "
					body += "<a href='?priv_msg="+ckey+"'>PM</a> - "
					body += "<a href='?_src_=holder;[HrefToken()];subtlemessage="+ref+"'>SM</a> - "
					body += "<a href='?_src_=holder;[HrefToken()];adminplayerobservefollow="+ref+"'>FLW</a> - "
					body += "<a href='?_src_=holder;[HrefToken()];individuallog="+ref+"'>LOGS</a><br>"
					if(antagonist > 0)
						body += "<span class='pp-antag'><a href='?_src_=holder;[HrefToken()];secrets=check_antagonist'>Antagonist</a></span>";

					body += "</td></tr></table>";


					span.innerHTML = body
				}

				function clearAll(){
					var spans = document.getElementsByTagName('span');
					for(var i = 0; i < spans.length; i++){
						var span = spans\[i\];

						var id = span.getAttribute("id");

						if(!id || !(id.indexOf("item")==0))
							continue;

						var pass = 1;

						for(var j = 0; j < locked_tabs.length; j++){
							if(locked_tabs\[j\]==id){
								pass = 0;
								break;
							}
						}

						if(pass != 1)
							continue;




						span.innerHTML = "";
					}
				}

				function addToLocked(id,link_id,notice_span_id){
					var link = document.getElementById(link_id);
					var decision = link.getAttribute("name");
					if(decision == "1"){
						link.setAttribute("name","2");
					}else{
						link.setAttribute("name","1");
						removeFromLocked(id,link_id,notice_span_id);
						return;
					}

					var pass = 1;
					for(var j = 0; j < locked_tabs.length; j++){
						if(locked_tabs\[j\]==id){
							pass = 0;
							break;
						}
					}
					if(!pass)
						return;
					locked_tabs.push(id);
					var notice_span = document.getElementById(notice_span_id);
					notice_span.innerHTML = "<span class='pp-locked'>Locked</span> ";
					//link.setAttribute("onClick","attempt('"+id+"','"+link_id+"','"+notice_span_id+"');");
					//document.write("removeFromLocked('"+id+"','"+link_id+"','"+notice_span_id+"')");
					//document.write("aa - "+link.getAttribute("onClick"));
				}

				function attempt(ab){
					return ab;
				}

				function removeFromLocked(id,link_id,notice_span_id){
					//document.write("a");
					var index = 0;
					var pass = 0;
					for(var j = 0; j < locked_tabs.length; j++){
						if(locked_tabs\[j\]==id){
							pass = 1;
							index = j;
							break;
						}
					}
					if(!pass)
						return;
					locked_tabs\[index\] = "";
					var notice_span = document.getElementById(notice_span_id);
					notice_span.innerHTML = "";
					//var link = document.getElementById(link_id);
					//link.setAttribute("onClick","addToLocked('"+id+"','"+link_id+"','"+notice_span_id+"')");
				}

				function selectTextField(){
					var filter_text = document.getElementById('filter');
					filter_text.focus();
					filter_text.select();
				}

			</script>
			<style type='text/css'>
				.pp-title { color: #98B0C3; font-size: 18px; font-weight: bold; padding: 8px 0; }
				.pp-subtitle { color: #8a9bae; font-size: 12px; }
				#filter {
					background-color: #1e1e1e; color: #ffffff; border: 1px solid #40628a;
					border-radius: 3px; padding: 4px 8px; font-size: 13px; outline: none;
					transition: border-color 0.2s;
				}
				#filter:focus { border-color: #98B0C3; }
				#maintable_data { border-collapse: collapse; }
				.pp-row-even { background-color: #2d2d2d; }
				.pp-row-odd { background-color: #333333; }
				.pp-row:hover { background-color: #3a3a4a; }
				.pp-cell { color: #ffffff; padding: 6px 10px; border-bottom: 1px solid #1e1e1e; }
				.pp-cell b { color: #ffffff; }
				.pp-cell a { color: #98B0C3; background: none; border: none; padding: 0; margin: 0; text-decoration: none; cursor: pointer; }
				.pp-cell a:hover { color: #ffffff; background: none; text-decoration: underline; }
				.pp-cell span\[id^='item'\] table { background-color: #383838; border: 1px solid #40628a; border-radius: 3px; margin-top: 4px; width: 100%; }
				.pp-cell span\[id^='item'\] td { color: #ffffff; padding: 4px 8px; }
				.pp-cell span\[id^='item'\] a { color: #ffffff; background: #40628a; border: 1px solid #161616; padding: 1px 5px; margin: 0 1px; border-radius: 2px; text-decoration: none; font-size: 11px; }
				.pp-cell span\[id^='item'\] a:hover { background: #ffffff; color: #40628a; text-decoration: none; }
				.pp-antag { color: #ff4444; font-weight: bold; }
				.pp-locked { color: #ff4444; font-weight: bold; font-size: 11px; }
			</style>
		</head>


	"}

	//body tag start + onload and onkeypress (onkeyup) javascript event calls
	dat += "<script>window.onload = function() { selectTextField(); updateSearch(); }; document.onkeyup = function() { updateSearch(); };</script>"

	//title + search bar
	dat += {"

		<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable'>
			<tr id='title_tr'>
				<td align='center'>
					<div class='pp-title'>Player panel</div>
					<span class='pp-subtitle'>Hover over a line to see more information - <a href='?_src_=holder;[HrefToken()];check_antagonist=1'>Check antagonists</a> - Kick <a href='?_src_=holder;[HrefToken()];kick_all_from_lobby=1;afkonly=0'>everyone</a>/<a href='?_src_=holder;[HrefToken()];kick_all_from_lobby=1;afkonly=1'>AFKers</a> in lobby</span>
				</td>
			</tr>
			<tr id='search_tr'>
				<td align='center'>
					<b>Search:</b> <input type='text' id='filter' value='' placeholder='Enter name or ckey...' style='width:300px;'>
				</td>
			</tr>
	</table>

	"}

	//player table header
	dat += {"
		<span id='maintable_data_archive'>
		<table width='560' align='center' cellspacing='0' cellpadding='5' id='maintable_data'>"}

	var/list/mobs = sortmobs()
	var/i = 1
	for(var/mob/M in mobs)
		if(M.ckey)

			var/row_class = "pp-row pp-row-odd"
			if(i%2 == 0)
				row_class = "pp-row pp-row-even"
			var/is_antagonist = is_special_character(M)

			var/M_job = ""

			if(isliving(M))

				if(iscarbon(M)) //Carbon stuff
					if(ishuman(M))
						M_job = M.job
					else if(ismonkey(M))
						M_job = "Monkey"
					else if(isalien(M)) //aliens
						if(islarva(M))
							M_job = "Alien larva"
						else
							M_job = ROLE_ALIEN
					else
						M_job = "Carbon-based"

				else if(issilicon(M)) //silicon
					if(isAI(M))
						M_job = "AI"
					else if(ispAI(M))
						M_job = ROLE_PAI
					else if(iscyborg(M))
						M_job = "Cyborg"
					else
						M_job = "Silicon-based"

				else if(isanimal(M)) //simple animals
					if(iscorgi(M))
						M_job = "Corgi"
					else if(isslime(M))
						M_job = "slime"
					else
						M_job = "Animal"

				else
					M_job = "Living"

			else if(isnewplayer(M))
				M_job = "New player"

			else if(isobserver(M))
				var/mob/dead/observer/O = M
				if(O.started_as_observer)//Did they get BTFO or are they just not trying?
					M_job = "Observer"
				else
					M_job = "Ghost"

			var/M_name = html_encode(M.name)
			var/M_rname = html_encode(M.real_name)
			var/M_key = html_encode(M.key)

			//output for each mob
			dat += {"

				<tr id='data[i]' name='[i]' class='[row_class]' onClick="addToLocked('item[i]','data[i]','notice_span[i]')">
					<td align='center' class='pp-cell'>
						<span id='notice_span[i]'></span>
						<a id='link[i]'
						onmouseover='expand("item[i]","[M_job]","[M_name]","[M_rname]","--unused--","[M_key]","[M.lastKnownIP]",[is_antagonist],"[REF(M)]")'
						>
						<b id='search[i]'>[M_name] - [M_rname] - [M_key] ([M_job])</b>
						</a>
						<br><span id='item[i]'></span>
					</td>
				</tr>

			"}

			i++


	//player table ending
	dat += {"
		</table>
		</span>

		<script type='text/javascript'>
			var maintable = document.getElementById("maintable_data_archive");
			var complete_list = maintable.innerHTML;
		</script>

	"}

	var/datum/browser/popup = new(usr, "players", 0, 600, 480)
	popup.set_content(dat)
	popup.open(FALSE)

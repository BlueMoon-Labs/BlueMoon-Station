var connected = false;
var commandQueue = [];

function byond_bridge_call(path, params) {
	var query = "";
	var i = 0;
	if (params) {
		for (var key in params) {
			if (!params.hasOwnProperty(key)) continue;
			if (i++ > 0) query += "&";
			var value = params[key];
			if (value === null || typeof value === "undefined") value = "";
			query += encodeURIComponent(key) + "=" + encodeURIComponent(value);
		}
	}
	var rawUrl = (path || "") + "?" + query;
	var protocolUrl = "byond://" + rawUrl;
	if (window.cef_to_byond) {
		try { window.cef_to_byond(protocolUrl); return true; } catch (e) {}
	}
	try { window.location.href = protocolUrl; return true; } catch (e) {}
	try { var xhr = new XMLHttpRequest(); xhr.open("GET", rawUrl); xhr.send(); return true; } catch (e) {}
	return false;
}

function byond_winset(params) {
	byond_bridge_call("winset", params || {});
}

function byond_topic(href) {
	var protocolUrl = "byond://" + href;
	if (window.cef_to_byond) {
		try { window.cef_to_byond(protocolUrl); return true; } catch (e) {}
	}
	try { window.location.href = protocolUrl; return true; } catch (e) {}
	try { var xhr = new XMLHttpRequest(); xhr.open("GET", href); xhr.send(); return true; } catch (e) {}
	return false;
}

function send_byond_command(command) {
	if (connected) {
		byond_winset({ command: command });
	} else {
		commandQueue.push(command);
	}
}

function run_after_focus(callback) {
	setTimeout(callback, 0);
}

function connected_to_server() {
	if (connected) return;
	connected = true;
	for (var i = 0; i < commandQueue.length; i++) {
		byond_winset({ command: commandQueue[i] });
	}
	commandQueue = [];
}

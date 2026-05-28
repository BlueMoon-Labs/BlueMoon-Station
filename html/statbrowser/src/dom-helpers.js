var tabBar = document.getElementById("tab-bar");
var spacer = document.getElementById("spacer");
var statcontent = document.getElementById("statcontent");
var pingBarGlobal = document.getElementById("ping-bar-global");
var globalSearchOverlay = document.getElementById("global-search-overlay");
var globalSearchBox = document.getElementById("global-search-box");
var globalSearchResults = document.getElementById("global-search-results");
var zoomIndicator = document.getElementById("zoom-indicator");

function el(tag, cls, text) {
	var e = document.createElement(tag);
	if (cls) e.className = cls;
	if (text !== undefined && text !== null) e.textContent = text;
	return e;
}

function setText(node, text) {
	var s = "" + text;
	if (node.textContent !== s) node.textContent = s;
}

var g_ping = {};
(function() {
	g_ping.dot = el("span", "ping-dot");
	g_ping.text = el("span");
	g_ping.avg = el("span");
	g_ping.avg.style.color = "var(--text-secondary)";
	g_ping.max = el("span");
	g_ping.max.style.color = "var(--text-secondary)";
	g_ping.spacer = el("span");
	g_ping.spacer.style.flexGrow = "1";
	g_ping.tidiText = el("span");
	g_ping.tidiAvg = el("span");
	g_ping.tidiAvg.style.color = "var(--text-secondary)";
	pingBarGlobal.appendChild(g_ping.dot);
	pingBarGlobal.appendChild(g_ping.text);
	pingBarGlobal.appendChild(g_ping.avg);
	pingBarGlobal.appendChild(g_ping.max);
	pingBarGlobal.appendChild(g_ping.spacer);
	pingBarGlobal.appendChild(g_ping.tidiText);
	pingBarGlobal.appendChild(g_ping.tidiAvg);
	pingBarGlobal.style.display = "none";
})();

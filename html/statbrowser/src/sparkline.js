function buildSparkline(data, minVal, maxVal, colorClass) {
	var W = 80, H = 24;
	var ns = "http://www.w3.org/2000/svg";
	var svg = document.createElementNS(ns, "svg");
	svg.setAttribute("width", W);
	svg.setAttribute("height", H);
	svg.setAttribute("viewBox", "0 0 " + W + " " + H);
	svg.setAttribute("class", "sparkline");

	var dMin = Infinity, dMax = -Infinity;
	for (var i = 0; i < data.length; i++) {
		var v = parseFloat(data[i]) || 0;
		if (v < dMin) dMin = v;
		if (v > dMax) dMax = v;
	}
	var lo = Math.min(minVal, dMin);
	var hi = Math.max(maxVal, dMax);
	if (hi === lo) hi = lo + 1;

	var points = [];
	var step = W / Math.max(data.length - 1, 1);
	for (var i = 0; i < data.length; i++) {
		var v = parseFloat(data[i]) || 0;
		var x = Math.round(step * i * 10) / 10;
		var y = Math.round((H - 2) - ((v - lo) / (hi - lo)) * (H - 4) + 2);
		points.push(x + "," + y);
	}

	var polyline = document.createElementNS(ns, "polyline");
	polyline.setAttribute("points", points.join(" "));
	polyline.setAttribute("fill", "none");
	polyline.setAttribute("stroke-width", "1.5");
	polyline.setAttribute("stroke-linejoin", "round");

	var color = "var(--health-good)";
	if (colorClass && colorClass.indexOf("bad") !== -1) color = "var(--health-bad)";
	else if (colorClass && colorClass.indexOf("warn") !== -1) color = "var(--health-warn)";
	polyline.setAttribute("stroke", color);

	svg.appendChild(polyline);
	return svg;
}

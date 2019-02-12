color = {
		white =		{1.00,	1.00,	1.00},
		black =		{0.00,	0.00,	0.00},
		rouge =		{0.90,	0.20,	0.10},
		actinic =	{0.60,	0.10,	0.95},
		blue =		{0.20,	0.30,	0.90},
		ltblue =	{0.40,	0.70,	0.90},
		green =		{0.30,	0.80,	0.30},
		yellow =	{0.80,	0.70,	0.10},
		orange =	{0.90,	0.50,	0.10},
		dkgrey =	{0.20,	0.30,	0.30},
		blood =		{0.30,	0.05,	0.10},
		bg =		{0.10,	0.10,	0.30}
}

function color.r(name)
	return color[name][1]
end

function color.g(name)
	return color[name][2]
end

function color.b(name)
	return color[name][3]
end

function color.rgb(name)
	return color[name][1],color[name][2],color[name][3]
end

function color.mix(a, b, t)
	v = 1-t
	return {v*a[1] + t*b[1], v*a[2] + t*b[2], v*a[3] + t*b[3]}
end

return color

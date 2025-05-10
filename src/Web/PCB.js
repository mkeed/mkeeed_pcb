function get_colour(draw_rules,
		    layer)
{
    for(const l of draw_rules.layers) {
	if(l.name == layer) return l.colour;
    }
    return "gray";

}

function map_loc(input,in_port, out_port)
{
    const ratio = (input - in_port.start) / in_port.range;
    const range = (out_port.range - out_port.start); 
    return out_port.start + ratio * range;
}

function map_point(input,
		   view_port,
		   out_port)
{
    return {x:map_loc(input.x,
		      {start:view_port.pos.x, range:view_port.rect.x},
		      {start:out_port.pos.x, range:out_port.rect.x}),
	    y:map_loc(input.y,
		      {start:view_port.pos.y, range:view_port.rect.y},
		      {start:out_port.pos.y, range:out_port.rect.y}),
	   };
}

function mouse_move(e)
{
    //console.log("mouse move",e);
    var rect = e.target.getBoundingClientRect();
    draw_pcb(
	{
	    layers:[
		{"name":"F.Cu","idx":1, "colour":"red"},
		{"name":"B.Cu","idx":2, "colour":"blue"},
	    ],
	},
	{
	    "crosshair":{
		x:e.layerX - rect.left,
		y:e.layerY - rect.top,
	    },
	    view_port:{
		pos:{x:0,y:0},
		rect:{x:400,y:400},
	    },
	},
	{
	    "layers":[
		{
		    "name":"F.Cu",
		    "traces":[
			{"start":{x:100,y:100}, "end": {x:200,y:200},"thickness":50},
			{"start":{x:200,y:200},"end": {x:200,y:300},"thickness":50},
			{"start":{x:200,y:300},"end": {x:300,y:300},"thickness":50}
		    ]
		},
		{
		    "name":"B.Cu",
		    "traces":[
			{"start":{x:300,y:300},"end": {x:350,y:300},"thickness":50},
			{"start":{x:350,y:300},"end": {x:350,y:350},"thickness":50},
			{"start":{x:200,y:300},"end": {x:300,y:300},"thickness":50}
		    ]
		}
	    ]
	}
    );
}

function draw_pcb(
    draw_rules,
    info,
    layout) {
    var c = document.getElementById("pcb_layout");
    c.onmousemove = mouse_move;
    var ctx = c.getContext("2d");
    const out_port = {
	pos:{x:0,y:0},
	rect:{x:c.clientWidth, y:c.clientHeight}
    };
    ctx.clearRect(0,0,c.clientWidth,c.clientHeight);


    layout.layers.forEach((layer) => {
	ctx.beginPath();
	ctx.strokeStyle = get_colour(draw_rules, layer.name);
	ctx.lineCap = "round";
	layer.traces.forEach((p) => {
	    ctx.lineWidth = p.thickness;
	    const start = map_point(p.start, info.view_port, out_port);
	    const end   = map_point(p.end, info.view_port, out_port);
	    //console.log("start", start, p.start);
	    //console.log("end", end, p.end);
	    ctx.moveTo(start.x, start.y);
	    ctx.lineTo(end.x, end.y);
	});
    
	ctx.stroke();
    });
    ctx.beginPath();
    ctx.strokeStyle = "gray";
    ctx.lineWidth = 1;
    //console.log(c);
    ctx.moveTo(0,info.crosshair.y);
    ctx.lineTo(c.clientHeight,info.crosshair.y);

    ctx.moveTo(info.crosshair.x,0);
    ctx.lineTo(info.crosshair.x,c.clientHeight);
    ctx.stroke();
}


var c = document.getElementById("pcb_layout");
c.onmousemove = mouse_move;

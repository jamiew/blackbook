/*
__          __   _                          _
\ \        / /  | |                        | |
 \ \  /\  / /___| |__  _ __ ___   __ _ _ __| | _____ _ __   _ __ ___   ___
  \ \/  \/ // _ \ '_ \| '_ ` _ \ / _` | '__| |/ / _ \ '__| | '_ ` _ \ / _ \
   \  /\  /|  __/ |_) | | | | | | (_| | |  |   <  __/ | _  | | | | | |  __/
    \/  \/  \___|_.__/|_| |_| |_|\__,_|_|  |_|\_\___|_|(_) |_| |_| |_|\___|

          Webmarker Firefox Add-on, visit: www.webmarker.me

          - Authors: Tobias Leingruber, Greg Leuch, Jamie Wilkinson, Florian Strübe
          - Based on GML and the 000000book.com API/ GML Database

			Note: This file is a fork of Jamie Wilkinson's canvasplayer http://github.com/jamiew/canvasplayer
*/

// console.log("canvasplayer.js loading...");

function cutHex(h){ return (h.charAt(0)=="#") ? h.substring(1,7) : h; }

function hex2rgb2(hexcolor)
{
  R = parseInt((cutHex(hexcolor)).substring(0,2),16);
  G = parseInt((cutHex(hexcolor)).substring(2,4),16);
  B = parseInt((cutHex(hexcolor)).substring(4,6),16);
  return R + ',' + G + ',' + B;
}

// *************** Callback Method ************
// ********************************************
function load_gml(data)
{
  // TODO handle both arrays and individual items...
  // e.g. both /data.json?location=... and /data/145.json

	if(typeof(data) != 'undefined')
	{
	  var i = 1;
		gml = data.gml;

		// attach sketch script tag
		var sketch_script = document.createElement('script');
		sketch_script.setAttribute('id','sketch'+i);
		sketch_script.type = 'application/processing';
		document.getElementsByTagName('body')[0].appendChild(sketch_script);

		// use existing canvas tag
		var wm_cp_canvas = document.getElementById('canvas');

		// attach Canvas Player canvas tag
    // var wm_cp_canvas = document.createElement('canvas');
    // wm_cp_canvas.setAttribute('width','200px');
    // wm_cp_canvas.setAttribute('height','200px');
		// uncomment following line to see the tags seperated
    // wm_cp_canvas.setAttribute('style','width: 100%; height: 100%; position:absolute; pointer-events:none; z-index:1001; top:0px; left:0px;');
		//wm_cp_canvas.setAttribute('style','position:absolute; pointer-events:none; z-index:1001; top:0px; left:0px;');
		//wm_cp_canvas.setAttribute('id','canvas'+i); // single canvas for every tag
    // wm_cp_canvas.setAttribute('id','canvas'); // one canvas for all tags
    // document.getElementsByTagName('body')[0].appendChild(wm_cp_canvas);

		/*
		 * concatenate pointlists of one tag and set them as global variables, so the processing.js draw function can acces them.
		 * This is kind of a workarround because one can't give parameters to the setup or drawing functions.
  		 * Working with the iteration variable here because Objects can't be serialized and attached to the created sketch scripts, but numbers/strings can.
		 */
		pts = [];
		pts_opts = [];
		strokes = (gml.tag.drawing.stroke instanceof Array ? gml.tag.drawing.stroke : [gml.tag.drawing.stroke]);
		for(j in strokes){
			pts 		= pts.concat(strokes[j].pt);
			pts_opts 	= pts_opts.concat({
			  stroke: (strokes[j].stroke_size || 8),
			  color: (strokes[j].color ? hex2rgb2(strokes[j].color) : '255,255,255'),
			  drips: (strokes[j].dripping || false)
			});
			pts.push(undefined); // blank obj to indicate new stroke
		}

		// create global vars on demand
    // eval("pts" + i + " = pts");
    // eval("pts_opts" + i + " = pts_opts");
    // eval("strokeCount" + i + " = 0");

		// appending sketch script for current tag to its script tag
		// TODO FIXME the size should be set from the canvas...
		document.getElementById('sketch'+i).innerHTML = " \
		function setup() { \
		  size(600, 500); \
		  frameRate(30); \
		  var app_name = gml.tag.header && gml.tag.header.client && gml.tag.header.client.name; \
		  if(app_name == 'Graffiti Analysis 2.0: DustTag' || app_name == 'DustTag: Graffiti Analysis 2.0'){ \
  			rotation = 80; \
  			translation = [0, 500]; \
		  } else { \
			  rotation = 0; \
			  translation = [0, 0]; \
			} \
      pts" + i + " = pts; \
      pts_opts" + i + " = pts_opts; \
      strokeCount"+i+" = 0; \
		}; \
		function draw() { \
		  i = frameCount % pts"+i+".length; \
		  prev = pts"+i+"[i-1]; \
		  pt = pts"+i+"[i]; \
      if(i == 0){ background(0); } \
		  if(pt == undefined || pt == []){ \
  			strokeCount"+i+"++; \
  			return; \
		  } \
		  if(prev == undefined || prev == []){ \
  			prev = pt; \
		  } \
		  dimx = (prev.x -pt.x)*width; \
		  dimy = (prev.y -pt.y)*height; \
  		hyp = 1/(sqrt(pow(dimx,2),pow(dimy,2)) + 20); \
		  translate(translation[0], translation[1]); \
		  rotate(rotation); \
		  num = (pow(hyp,0.5)*90); \
  		strokeWeight(num); \
      var colors = ['255','255','255']; \
		  stroke(colors[0],colors[1],colors[2]); \
		  line(prev.x*width, prev.y*height, pt.x*width, pt.y*height); \
		}";

		//var canvas 	= document.getElementById('canvas' + i); // single canvas for every tag
		var canvas 	= document.getElementById('canvas'); // one canvas for all tags
		var sketch 	= document.getElementById('sketch' + i).text;

		// draw sketch on canvas
		new Processing(canvas, sketch);
	}
	else
	{
    // console.log('error reading gml. gml undefined');
	}
}
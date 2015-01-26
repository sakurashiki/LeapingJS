/****************************************
 * LeapingJS-fade
 * Copyright (c) 2014,2015 Queue Sakura-Shiki
 * Released under the MIT license
 */
(function(){
	var	pageChangeFrame = window.LEAPING.PAGE_CHANGE_TIME;
	window.LEAPING.actions["fade"] = function( before, after, frame ) {
		if( pageChangeFrame === frame ) {
			before.style.display = "none";
			before.style.opacity = 1.0;
			after.style.display  = "block";
			after.style.opacity  = 1.0;
		} else {
			after.style.opacity = 1.0*frame/pageChangeFrame;
			after.style.display  = "block";
		}
	};
})();

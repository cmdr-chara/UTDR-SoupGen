///@desc Load Face & Border
var result = soup_checkout("external face");
if ( result != undefined ) {
	var curface = global.faces_dict[$ result.myname], spr_ = curface[$ result.id_].sprite, extra_ = soup_store_undefined("allowmultiple"), show_ = soup_store_undefined("showmsg");
	sprite_set_offset(spr_, sprite_get_width(spr_)/ 2, sprite_get_height(spr_)/ 2); //Center sprite
	var max_dimension_ = max(sprite_get_width(spr_), sprite_get_height(spr_));
	if ( max_dimension_ > 70 ) {
		var scale_ = 140/ max_dimension_; //Match the default 2x presentation without stretching oversized portraits
		dial_face_xscale = scale_; dial_face_yscale = scale_;
	}
	if ( !extra_ ) { FACE_CURRENT = spr_; FACE_ORIGINAL = FACE_CURRENT; FACE_INTERNAL = result.myname; }

	if ( !show_ ) { soupy_message(result.msg, , , , , snd_sparkle2, , , extra_ ? true : false); }
	file_dragging = false;
}

var result = soup_checkout("external border");
if ( result != undefined ) {
	var curface = global.bords_dict[$ result.myname], spr_ = curface.sprite, extra_ = soup_store_undefined("allowmultiple");
	//sprite_set_offset(spr_, sprite_get_width(spr_)/ 2, sprite_get_height(spr_)/ 2); //Center sprite
	
	if ( !extra_ ) { spr_bord = spr_; bord_prev = spr_bord; }

	soupy_message(result.msg, , , , , snd_sparkle2, , , extra_ ? true : false);
	file_dragging = false;
}

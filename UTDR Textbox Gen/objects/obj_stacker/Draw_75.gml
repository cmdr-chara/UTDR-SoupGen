///@desc Draw Stacked Sprites
var soupstack_count = array_length(soupstack_spr);
if ( soupstack_count == 0 ) { instance_destroy(); exit; } //Cancel early if there's nothing to draw

var soupstack_i = 0;
var sprW = sprite_get_width(soupstack_spr[0]) * soupstack_scale, sprH = sprite_get_height(soupstack_spr[0]) * soupstack_scale;
var final_x = soupstack_xoff * ( soupstack_count - 1 ), step_y = sprH + soupstack_yoff, final_y = step_y * ( soupstack_count - 1 );
var soupstack_min_x = min(0, final_x), soupstack_min_y = min(0, final_y);
var soupstack_width = max(1, ceil(max(sprW, final_x + sprW) - soupstack_min_x));
var soupstack_height = max(1, ceil(max(sprH, final_y + sprH) - soupstack_min_y)); //Calculate the exact surface bounds

try {
	if ( !surface_exists(soupstack_surf) ) { soupstack_surf = surface_create(soupstack_width, soupstack_height); }
	else if ( surface_get_width(soupstack_surf) != soupstack_width || surface_get_height(soupstack_surf) != soupstack_height ) { surface_resize(soupstack_surf, soupstack_width, soupstack_height); }
	if ( !surface_exists(soupstack_surf) ) { throw "Failed to allocate the dialogue stack surface."; }
}
catch ( err_ ) {
	abort = true;
	//Guestimating the numbers here based on my testing
	if ( soupstack_width >= 3000 ) { soupy_message($"Sorry, but the stack has shifted to an|amount that is too big for this tool to handle!|Shift amount: [c_yellow]{soupstack_xoff}[/] / Surface Width: [c_red]{soupstack_width}[/]|Try a smaller shift amount.", "Damn... That's fine.", 400, , , snd_error, fnt_abaddon, function () { window_progress(window_progress_none); }, , true, 590); }
	else if ( soupstack_height >= 5000 ) { soupy_message($"Sorry, but the amount of dialogue pages([c_yellow]{soupstack_count}[/])|you have is too much for this tool to handle!|You'll need to split up your dialogue|into smaller exports.|You may also want to try lowering|the stack gap amount.([c_yellow]{soupstack_yoff}[/])", "Damn... That's fine.", 400, , , snd_error, fnt_abaddon, function () { window_progress(window_progress_none); }, , true, 590); }
	SYSTEMUI.screenshot = false; soup_checkout("finishfunc", , true)(false, true, false); instance_destroy(); window_progress(window_progress_error, 1, 1); exit;
}
surface_set_target(soupstack_surf);
draw_clear_alpha(c_black, 0);

repeat ( soupstack_count ) { 
	draw_sprite_ext(soupstack_spr[soupstack_i], 0, ( soupstack_xoff * soupstack_i ) - soupstack_min_x, ( step_y * soupstack_i ) - soupstack_min_y, soupstack_scale, soupstack_scale, 0, c_white, 1); //Draw dialogue
soupstack_i++; }

surface_reset_target();
draw_surface_ext(soupstack_surf, 0, 0, 0.5, 0.5, 0, c_white, 1);

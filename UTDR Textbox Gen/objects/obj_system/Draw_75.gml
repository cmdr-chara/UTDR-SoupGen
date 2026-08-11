///@desc Screenshot task
//if ( live_call() ) { return live_result; } 
if ( screenshot || record.enabled ) { 
	var dltrn = spr_bord == spr_border_deltarune; //Check if our border is Deltarune
	var out_ = bord_out; //Whether to save with an outline
	var folder = "UTDR-SoupGen-Export", fname = file_newname != "" ? string_exclude(file_newname, "\\/:*?\"<>|") : $"UTDR_SoupGen_-{current_month}.{current_day}.{current_year}-_{current_hour}.{current_minute}.{current_second}.{current_time}-";
	
	#region Custom File Name
		if ( file_newname != "" ) {
			var i = 0, fname_orig = fname;
			do {
				fname = $"{fname_orig}_{i}";
				i += 1;
			} until ( !file_exists($"{!is_android() ? executable_get_directory() : soup_checkout("android", false, true)}{folder}{PATHSEP}{fname}_.{record.enabled ? "gif" : "png"}") )
		}
	#endregion
	
	var offset_ = dltrn ? 8 : 0, offset_w = dltrn ? 15 : 0, offset_h = dltrn ? 16 : 0, x_ = ( 32 - offset_ ) - ( out_ ? 2 : 0 ), y_ = ( 315 - offset_ ) - ( out_ ? 2 : 0 ), w_ = ( 578 + offset_w ) + ( out_ ? 4 : 0 ), h_ = ( 152 + offset_w ) + ( out_ ? 4 : 0 ); //Border coords
	if ( global.pref.sizematters ) { offset_ = 0; offset_w = 0; offset_h = 0; x_ = 0; y_ = 0; w_ = 640; h_ = 480; }
	
	#region Draw Surface
		if ( !surface_exists( screenshot_surf ) ) { screenshot_surf = surface_create(640, 480); }
		surface_set_target(screenshot_surf);
			var myy = ( global.pref.sizematters && global.pref.sizematterstop ) ? ( -305 + ( global.pref.anyborder ? abs(bord_yoff) : 0 ) ) : ( global.pref.sizematters ? 5 : 0 );
			if ( !record.enabled ) { draw_clear_alpha(c_black, 0); } //For borders that aren't perfect rectangles
			if ( global.pref.sizematters && global.pref.showref && sprite_exists(global.refimg) && !screenshot_stacked ) { draw_sprite_ensure(global.refimg, , 0, 0); } else { draw_clear_alpha(screenshot_back, 0); } //Reference image
		
			#region Dialogue Box Outline
				if ( out_ && bord_box_visible ) {
					var out_thick = 2, offset_ = dltrn ? 8 : 0, offset_w = dltrn ? 15 : 0, offset_h = dltrn ? 16 : 0, bordx = 32 - offset_, bordy = 315 - offset_, bordw = 578 + offset_w, bordh = 152 + offset_w; //Border coords
					gpu_set_fog(true, c_black, 0, 0); //Draw solid color of sprite
						draw_surface_ext(out_surf, - out_thick, myy, 1, 1, 0, c_white, 1); //Dialogue Box Left
						draw_surface_ext(out_surf, out_thick, myy, 1, 1, 0, c_white, 1); //Dialogue Box Right
						draw_surface_ext(out_surf, 0, myy - out_thick, 1, 1, 0, c_white, 1); //Dialogue Box Up
						draw_surface_ext(out_surf, 0, myy + out_thick, 1, 1, 0, c_white, 1); //Dialogue Box Down
						
						draw_surface_ext(out_surf, -out_thick, myy - out_thick, 1, 1, 0, c_white, 1); //Dialogue Box Up Left
						draw_surface_ext(out_surf, out_thick, myy - out_thick, 1, 1, 0, c_white, 1); //Dialogue Box Up Right
						draw_surface_ext(out_surf,  -out_thick, myy + out_thick, 1, 1, 0, c_white, 1); //Dialogue Box Down Left
						draw_surface_ext(out_surf, out_thick, myy + out_thick, 1, 1, 0, c_white, 1); //Dialogue Box Down Right
					gpu_set_fog(false, c_white, 0, 0); //Reset effect
				}
			#endregion (Yes we have to draw it like this)
			draw_surface_ext(out_surf, 0, myy, 1, 1, 0, c_white, 1); //Our gen result
			if ( instance_exists(obj_mini) ) { with ( obj_mini ) { draw(); } }
		surface_reset_target();
	#endregion
	
	#region Function for finishing recording
		var discard_gif = method({ record }, function() {
			if ( record.id_ == -1 ) { exit; }
			var temp_root_ = temp_directory;
			if ( !string_ends_with(temp_root_, "/") && !string_ends_with(temp_root_, "\\") ) { temp_root_ += PATHSEP; }
			var discard_path_ = $"{temp_root_}soupy_gif_discard_{current_time}_{irandom(999999999)}.gif";
			try {
				var discard_status_ = gif_save(record.id_, discard_path_);
				if ( discard_status_ != 0 ) { show_debug_message("GameMaker could not finalize a canceled GIF for disposal."); }
			} catch ( discard_error_ ) {
				show_debug_message($"Canceled GIF disposal failed: {discard_error_.message}");
			}
			record.id_ = -1;
			if ( file_exists(discard_path_) ) { file_delete(discard_path_); }
		});

		var finish_func = method({folder, fname, file_newname, record, x_, y_, w_, h_, screenshot_surf, discard_gif }, function(gif_ = true, stack_ = false, cancel_ = false, error_ = "") { //Finished recording/ screenshotting
			var fpath_final = $"{!is_android() ? executable_get_directory() : soup_checkout("android", false, true)}{folder}{PATHSEP}{fname}_.{gif_ ? "gif" : "png"}";
			var fpath_staging = $"{fpath_final}.{current_time}.part", export_error = error_;

			if ( cancel_ ) {
				discard_gif();
				soup_checkout("export dialogue"); window_progress(window_progress_error, 1, 1);
				soupy_message("The export operation was canceled.", , 350, , , snd_cancel, , function(){ window_progress(window_progress_none); TweenScript(SYSTEMUI, 0, 2, function(){ soup_store_clear(); }); });
			}
			else {
				if ( export_error == "" && !stack_ ) {
					if ( gif_ ) {
						if ( record.id_ == -1 ) { export_error = "The GIF encoder was not available."; }
						else {
							if ( file_exists(fpath_staging) && !file_delete(fpath_staging) ) { export_error = "Could not prepare a temporary GIF file."; }
							if ( export_error == "" ) {
								var save_status = gif_save(record.id_, fpath_staging);
								record.id_ = -1;
								if ( save_status != 0 || !file_exists(fpath_staging) ) { export_error = "GameMaker could not finalize the GIF."; }
								else if ( !file_rename(fpath_staging, fpath_final) || !file_exists(fpath_final) ) { export_error = "The completed GIF could not be moved into place."; }
							}
						}
					}
					else { surface_save_part(screenshot_surf, fpath_final, x_, y_, w_, h_); } //Save screenshot
				}

				if ( export_error != "" ) {
					discard_gif();
					if ( file_exists(fpath_staging) ) { file_delete(fpath_staging); }
					soup_checkout("export dialogue"); window_progress(window_progress_error, 1, 1);
					soupy_message($"GIF export failed.|{export_error}", "Go Back", 400, , , snd_error, , function(){ window_progress(window_progress_none); TweenScript(SYSTEMUI, 0, 2, function(){ soup_store_clear(); }); });
				}
				else if ( !stack_ ) {
					MobileUtils_Vibrate_Shot(100);
					if ( !global.pref.hidemessages ) { soupy_ui_success(fname, gif_, fpath_final); }
					else { sfx_play(snd_dumbvictory); instance_create_depth(0, 0, 0, obj_success); SYSTEMUI.ui_paused = false; }
					if ( global.pref.openresult ) {
						if ( !is_android() ) {
							if ( !is_wasm() ) {
								soupy_url($"{executable_get_directory()}{folder}", , , 6); //Open the directory (Windows only)
								soupy_url(fpath_final, , , 6); //Open the image in the PC's default photo viewer (Windows only)
							}
						}
						else { file_copy(fpath_final, $"{fname}_.{gif_ ? "gif" : "png"}"); MobileUtils_Share_Open("Here's your good soup!", gif_ ? "image/gif" : "image/png", $"{fname}_.{gif_ ? "gif" : "png"}"); }
					}
					if ( !is_wasm() ) { clipboard_set_text(fpath_final); } else { var uri = data_uri(fpath_final); if ( uri != -1 ) { soupy_url(uri); clipboard_set_text(uri); soup_store("datauri", uri, , true); } else { show_message_async("Error! Couldn't make Data URI!"); } }
					if ( !gif_ && !is_android() ) { var temp = sprite_add(fpath_final, 0, 0, 0, 0, 0); clipboard_set_sprite(temp); sprite_delete(temp); }
					window_progress(window_progress_none); window_flash(window_flash_tray, 3, 350);
				}
			}
			
			soup_checkout("previewcancel", , true);
			var restore_page = soup_checkout("lastpage", , true);
			if ( !is_numeric(restore_page) ) { restore_page = 0; }
			restore_page = clamp(floor(restore_page), 0, max(0, SYSTEMUI.dial_text_page_c - 1));
			if ( surface_exists(screenshot_surf) ) { surface_free(screenshot_surf); } SYSTEMUI.screenshot_surf = -1;
			with ( record ) { frames = 0; framesmax = 0; frames_total = 0; frames_limit = 0; frame_bytes = 0; byte_limit = 0; enabled = false; id_ = -1; failed = export_error != ""; }
			SYSTEMUI.dial_text_page = restore_page;
			with ( SYSTEMUI ) { ui_finished = false; ui_preview = false; ui_finished_y = -100; typist_reset(); file_newname = ""; screenshot = false; screenshot_stacked = false; dial_text_gif = false; dial_wrap_count = 1; spr_bord = bord_prev; bord_box_visible = true; ui_tab = soup_checkout("tablast", , true); ui_visible = true; ui_reset(); }
			exit;
		});
		soup_store("finishfunc", finish_func, true, true);
	#endregion
	
	#region Cancel Early
		if ( soup_store_undefined("doublepress") ) { soup_store("doublepress", 0, , true); }
		if ( keyboard_check_pressed(vk_escape) || mouse_pressed_right || !is_undefined(soup_checkout("previewcancel", false, true)) ) {
			if ( soup_checkout("doublepress", false, true) < 1 ) { global.soupstore_global[$ "doublepress"]++; soupy_alarm_set("doublepress", "timer", 15); sfx_play(snd_bump); } else { if ( instance_exists(obj_stacker) ) { obj_stacker.abort = true; instance_destroy(obj_stacker); } finish_func(, , true); soup_store("doublepress", 0, , true); exit; }
		}
		soupy_alarm("doublepress", 15);
		soupy_alarm_run("doublepress", 0, function() { soup_store("doublepress", 0, , true); }); 
	#endregion
	
	if ( screenshot ) { 
		if ( !screenshot_stacked ) { screenshot = false; finish_func(false); exit; }
		else {
			if ( dial_text_page <= dial_text_page_c - 1 ) { //Create sprite from surface, then push them to the stack
				ui_mini();
				with ( obj_stacker ) {
					if ( soupstack_path == "" ) { var fpath_final = $"{!is_android() ? executable_get_directory() : soup_checkout("android", false, true)}{folder}{PATHSEP}{fname}_.png"; soupstack_path = fpath_final; soupstack_fname = fname; soupstack_folder = folder; }
					array_push(soupstack_spr, sprite_create_from_surface(other.screenshot_surf, x_, y_, w_, h_, false, false, 0, 0));
				}
				dial_text_page++; sfx_play(snd_equip2);
			}
			else { finish_func(false, true); screenshot = false; screenshot_stacked = false; instance_destroy(obj_stacker); exit; }
		}
	}
	else if ( record.enabled ) {
		if ( record.frames_limit <= 0 ) {
			var is_web_export = os_browser != browser_not_a_browser || is_wasm();
			var platform_byte_limit = is_web_export ? 128 * 1024 * 1024 : ( is_android() ? 192 * 1024 * 1024 : 384 * 1024 * 1024 );
			var platform_frame_limit = is_web_export ? 300 : ( is_android() ? 600 : 1200 );
			record.frame_bytes = max(1, w_ * h_ * 4);
			record.byte_limit = platform_byte_limit;
			record.frames_limit = max(1, min(platform_frame_limit, floor(platform_byte_limit / record.frame_bytes)));
		}

		if ( !ui_preview && record.type == 0 && record.framesmax > record.frames_limit ) {
			var estimated_mib = ceil(( record.framesmax * record.frame_bytes ) / ( 1024 * 1024 ));
			finish_func(true, false, false, $"This export exceeds the safe GIF budget.|Requested: {record.framesmax} frames / about {estimated_mib} MiB.|Limit for this platform and size: {record.frames_limit} frames.");
			exit;
		}

		var record_func = method({ record, screenshot_surf, screenshot_back, x_, y_, w_, h_, typist, ui_finished, ui_preview }, function(init_ = false) {
			if ( init_ ) {
				record.id_ = gif_open(w_, h_, screenshot_back);
				if ( record.id_ == -1 ) { return -1; }
				typist.reset();
				return 0;
			}
			if ( ui_finished || ui_preview ) { return 0; }
			if ( record.frames_total >= record.frames_limit ) { return -2; }
			var frame_delay_cs = ( record.frames_total mod 3 == 2 ) ? 1 : 2; //2, 2, 1 centiseconds averages exactly 60 FPS.
			var add_status = gif_add_surface(record.id_, screenshot_surf, frame_delay_cs, x_, y_, record.quant);
			if ( add_status != 0 ) { return -1; }
			record.frames_total++;
			return 0;
		});

		if ( record.id_ == -1 ) {
			if ( ui_preview ) { finish_func(true, false, false, "The existing GIF encoder was lost before preview playback."); exit; }
			if ( record_func(true) != 0 ) { finish_func(true, false, false, "GameMaker could not initialize the GIF encoder for this image size."); exit; }
			sfx_play(snd_equip);
			if ( record.type == 1 ) { exit; } //Preserve the blank first typewriter frame after resetting the typist.
		}
		if ( record.type == 1 && record.frames_total == 0 ) {
			var first_frame_result_ = record_func();
			if ( first_frame_result_ == -2 ) { finish_func(true, false, false, $"The typewriter GIF reached its safe limit of {record.frames_limit} frames before completion."); exit; }
			if ( first_frame_result_ != 0 ) { finish_func(true, false, false, "GameMaker ran out of memory while adding the first typewriter GIF frame."); exit; }
			exit;
		}

		if ( record.type == 0 ) { //No typing animation
			if ( record.frames < record.framesmax ) {
				var add_result = record_func();
				if ( add_result == -2 ) { finish_func(true, false, false, $"The GIF reached its safe limit of {record.frames_limit} frames before completion."); exit; }
				if ( add_result != 0 ) { finish_func(true, false, false, "GameMaker ran out of memory while adding a GIF frame."); exit; }
				record.frames++;
				exit;
			}
			else { if ( !global.pref.confirmexport ) { finish_func(); } else { if ( !ui_finished ) { ui_finished = true; ui_preview = false; sfx_play(snd_dimbox); TweenFire("?", SYSTEMUI, "$30", "~oback", "ui_finished_y>", 190); } } exit; } //Finish after adding exactly framesmax frames.
		}
		else { //Typing animation
			var state_ = typist.get_state();
			if ( state_ < 1 || ( state_ >= 1 && record.frames < record.delay ) ) {
				var add_result = record_func();
				if ( add_result == -2 ) { finish_func(true, false, false, $"The typewriter GIF reached its safe limit of {record.frames_limit} frames before completion."); exit; }
				if ( add_result != 0 ) { finish_func(true, false, false, "GameMaker ran out of memory while adding a typewriter GIF frame."); exit; }
			} //If we're still typing, keep recording
			if ( state_ >= 1 ) { //If we stopped typing
				if ( record.frames < record.delay ) { record.frames++; exit; } //Delay before moving on
				else { if ( dial_text_page < dial_text_page_c - 1 ) { record.frames = 0; point_visible = false; typist_reset(); dial_text_page++; sfx_play(snd_equip); exit; } else { if ( !global.pref.confirmexport ) { finish_func(); } else { if ( !ui_finished ) { ui_finished = true; ui_preview = false; ui_finished_y = -100; sfx_play(snd_dimbox); TweenFire("?", SYSTEMUI, "$30", "~oback", "ui_finished_y>", 190); } } } } //Either go to the next page or stop recording
			}
		}
	}
}

outputLog = "";
outputLogSkipped = "";
pref = {
	firsttime: true, //Whether it's the first time this tool has been launched
	killaudio: false, //Whether the tool should make sound
	sizematters: false, //Whether the tool should export dialogue with a resolution of 640x480
	sizematterstop: false, //Whether to send the dialogue box to the top
	anyborder: false, //Whether to allow any arbitrary border
	hidemessages: false, //Whether to hide output sucess message
	checkupdates: true, //Check for updates?
	showref: true, //Whether to show the reference image on export
	openresult: true, //Whether to show your generated result
	focusmode: true, //Use the calm, low-motion editor interface
	randomclr: false, //Whether the UI should randomize its color on startup
	bg3d: false, //Whether to enable the 3D background
	showfps: false, //Whether to show an FPS counter
	confirmexport: true, //Whether to press confirm to export once dialogue is finished
	autopoint: true, //Whether auto-asterisk is enabled
	themeclr: make_color_rgb(182, 154, 196), //UI theme color
	gifbgclr: c_lime, //GIF BG color
	soupyicon: true, //Whether to enable dynamic icon changing
	pausesymbols: true, //Whether to always delay when encountering symbols
	presets: {}, //Config presets
	autoscale: true, //Whether to automatically scale sprites according to the font height
	fix: false,
	macros: { example: "[c_go][wave][pulse]I'm so soupy!![/]", example2: "This is a really long macrooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo", }, //Macros for reusable text
}
#region Add External Faces
	global.faces_dict = {};
	global.faces_dict_alt = {};
	
	function load_faces() {
		///@desc Because for some reason, Android doesn't have subfolder included files.
		var find_faces_func = function () {
		var folder_arr = [], folder = file_find_first($"faces{PATHSEP}*", fa_directory); //First, get all the folders
			while ( folder != "" ) {
				if ( folder != "desktop.ini" ) {
					var dir_ = string_between(folder, "spr_", "_");
					if ( !directory_exists($"faces{PATHSEP}{dir_}") ) { directory_create($"faces{PATHSEP}{dir_}"); }
					file_copy(folder, $"faces{PATHSEP}{dir_}{PATHSEP}{folder}");
					file_delete(folder);
					array_push(folder_arr, $"faces{PATHSEP}{dir_}{PATHSEP}{folder}");
				}
				folder = file_find_next();
			}
			return folder_arr;
		}
	
		var findfaces = !is_android() ? gumshoe("faces", ".png") : ( is_android_wasm() ? gumshoe("faces", ".png") : find_faces_func() ), faces_i = 0, faces_count = 0, faces_len = array_length(findfaces);
		repeat ( faces_len ) {
			var faces_cur = findfaces[faces_i]; //Current face path we're looking at
			var faces_dir = filename_dir_name(faces_cur); //Get directory name
			if ( faces_dir != "" ) { //Not trying to load a file outside a folder
				if ( !struct_exists(global.faces_dict, faces_dir) ) { global.faces_dict[$ faces_dir] = {}; } //Create new struct face dictionary
				var temp_ = string_replace(faces_cur, $"faces{PATHSEP}{faces_dir}{PATHSEP}", ""); //Remove faces/(folder name)/
				var imgnum = string_between(temp_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : real(imgnum); //Get the image number if it's a strip file
				var faces_emote = string_exclude(string_replace(string_replace(string_replace(temp_, $"_strip", ""), $"spr_{faces_dir}_", ""), ".png", ""), "1234567890"); //Get face expression
				if ( faces_emote != "" ) { //Filename isn't just numbers
					with ( global.faces_dict[$ faces_dir] ) {
						if ( is_undefined(self[$ faces_emote]) ) { //If this dictonary doesn't already exist
						self[$ faces_emote] = { sprite: sprite_add(faces_cur, imgnum, false, false, 0, 0), expression: faces_emote, name: faces_cur, count: imgnum, } //Add sprite index and expression name to the global face dictonary
							with ( self[$ faces_emote] ) { 
								self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; show_debug_message($"External face \"{name}\" was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
								self[$ "size"] = { sprite, width: sprite_get_width(sprite), height: sprite_get_height(sprite), }
								sprite_set_offset(sprite, size.width/ 2, size.height/ 2); //Center sprite
					
								var scrib_ = $"{faces_dir}_{expression}"; scribble_external_sprite_add(sprite, scrib_); //Register sprite with Scribble
								var altname_ = $"spr_{scrib_}"; if ( !scribble_external_sprite_exists(altname_) ) { scribble_external_sprite_add(sprite, altname_); } //Alternative name
								global.faces_dict_alt[$ altname_] = { sprite, name: altname_, destroy, size } //Add sprite index and expression name to the global face alt dictonary
								var out_ = $"Added \"{expression}\" from {name}! | Image number: {count} | Scribble name: {scrib_} | Scribble alt name: {altname_}";
								show_debug_message(out_); global.outputLog += $"{out_}\n";
								faces_count++;
							}
						}
						else { 
							var out_ = $"Tried to load a sprite that already exists({faces_cur})! Skipping..."; 
							show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
							var out_ = $"|Tried to load a sprite that already exists|({faces_cur})! Skipped...|Remove duplicates before trying again!|"; 
							global.outputLogSkipped += out_; 
						}
					}
				}
				else { 
					var out_ = $"Tried to load a sprite with an invalid name({faces_cur})! Skipping..."; 
					show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
					var out_ = $"|Tried to load a sprite with an invalid filename|({faces_cur})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)|"; 
					global.outputLogSkipped += out_; 
				}
			}
			else { 
				if ( !is_android() ) {
					var out_ = $"Tried to load a sprite outside of a folder({faces_cur})! Skipping..."; 
					show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
					var out_ = $"|Tried to load a sprite outside of a folder|({faces_cur})! Skipped...|Face sprites for auto-loading should have all their faces in their own folders!|"; 
					global.outputLogSkipped += out_; 
				}
			}
		faces_i++; }
		var out_ = $"Over {faces_count} external faces were loaded!";
		show_debug_message(out_); global.outputLog += $"{out_}\n";
		with ( obj_init ) { loading_state++; alarm[0] = 2; }
	}
	
	///@desc Returns a sprite index from an externally added face sprite.
	///@param {string} name Character Name or Expression Name
	///@param {string} expression Expression type
	///@param {string} return_ What to return
	function get_face(name, expression = -1, return_ = "sprite") {
		/*
			var result = get_face("alphys", "depressed sorry");
			show_debug_message(result);

			var result = get_face("alphys depressed sorry");
			show_debug_message(result);

			var result = get_face("spr_alphys_depressed_sorry");
			show_debug_message(result);

			var result = get_face("alphys", "depressed_sorry");
			show_debug_message(result);

			var result = get_face("alphys_depressed_sorry");
			show_debug_message(result);
		*/
		var early_ = asset_get_index(name);
		if ( early_ != -1 ) { return early_; }
		if ( expression == -1 || string_letters(expression) == "" ) { //Just proving a name, probably using the quick way to get a sprite
			var getface = global.faces_dict_alt[$ name], getfacespr = global.faces_dict_alt[$ $"spr_{name}"], name2 = string_replace_all(name, " ", "_"), getfacespr2 = global.faces_dict_alt[$ $"spr_{name2}"];
			return getface != undefined ? getface[$ return_] : ( getfacespr != undefined ? getfacespr[$ return_] : ( getfacespr2 != undefined ? getfacespr2[$ return_] : -1 ) );
		}
		else { //Providing a face name and expression
			var getface = global.faces_dict[$ name];
			if ( getface != undefined ) {
				var exp_ =  getface[$ expression], getexp = string_replace_all(expression, " ", "_"), exp_2 =  getface[$ getexp];
				return exp_ != undefined ? exp_[$ return_] : ( exp_2 != undefined ? exp_2[$ return_] : -1 );
			}
		}
	}
#endregion

#region Add Borders, Icons, and Reference Image
	#region Icons
		global.icons_dict = {};
		global.icons_dict_alt = {};
	
		function load_icons() {
			var findicons = gumshoe("icons", ".png"), icons_i = 0, icons_len = array_length(findicons);
			repeat ( icons_len ) {
				var icons_cur = findicons[icons_i]; //Current icon we're looking at
		
				var temp_ = string_replace(icons_cur, $"icons{PATHSEP}", ""); 
				var imgnum = string_between(temp_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : real(imgnum); //Get the image number if it's a strip file
				temp_ = string_replace(string_replace(string_replace(temp_, $"spr_", ""), $"_strip", ""), $".png", "");
				temp_ = string_exclude(temp_, "0123456789");
				if ( temp_ != "" ) {
					if ( is_undefined(global.icons_dict[$ temp_]) ) {
						global.icons_dict[$ temp_] = { sprite: sprite_add(icons_cur, imgnum, false, false, 0, 0), name: temp_, fname_: icons_cur, count: imgnum, }
						with ( global.icons_dict[$ temp_] ) {
							self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; show_debug_message($"External icon \"{fname_}\"({name}) was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
							self[$ "size"] = { sprite, width: sprite_get_width(sprite), height: sprite_get_height(sprite), }
							sprite_set_offset(sprite, size.width/ 2, size.height/ 2); //Center sprite
				
							var out_ = $"Added \"{name}\" from {fname_}! Image Count: {count}";
							scribble_external_sprite_add(sprite, name);
				
							var temp_2 = string_replace(icons_cur, $"icons{PATHSEP}", ""); 
							temp_2 = string_replace(string_replace(temp_2, $"_strip", ""), $".png", "");
							temp_2 = string_exclude(temp_2, "0123456789");
							if ( !scribble_external_sprite_exists(temp_2) ) { scribble_external_sprite_add(sprite, temp_2); } //alternative
							global.icons_dict_alt[$ temp_2] = { sprite, name, size, } //Add sprite index and expression name to the global icon alt dictonary
							show_debug_message(out_); global.outputLog += $"{out_}\n";
						}
					}
					else { 
						var out_ = $"Tried to load a sprite that already exists({icons_cur})! Skipping..."; 
						show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
						var out_ = $"|Tried to load a sprite that already exists|({icons_cur})! Skipped...|Remove duplicates before trying again!|"; 
						global.outputLogSkipped += out_; 
					}
				}
				else { 
					var out_ = $"Tried to load a sprite with an invalid name({icons_cur})! Skipping..."; 
					show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
					var out_ = $"|Tried to load a sprite with an invalid filename|({icons_cur})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)|"; 
					global.outputLogSkipped += out_; 
				}
			icons_i++; }
			with ( obj_init ) { loading_state++; alarm[0] = 2; }
		}
		
		///@desc Returns a sprite index from an externally added icon sprite.
		///@param {string} name Icon Sprite Name (ex: soupcan, spr_dw_tv_time_its, funnytext amazing, etc.)
		function get_icon(name, return_ = "sprite") { 
			var result = global.icons_dict[$ name], result2 = global.icons_dict_alt[$ name];
			var temp_ = string_replace_all(name, " ", "_"), result3 = global.icons_dict[$ temp_]
			return !is_undefined(result) ? result[$ return_] : ( !is_undefined(result2) ? result2[$ return_] : ( !is_undefined(result3) ? result3[$ return_] : -1 ) );
		}
	#endregion
	
	#region Borders
		global.bords_dict = {};
		global.bords_dict_alt = {};
		global.bords_dict_raw = {};
	
		function load_borders() {
			var findbords = gumshoe("borders", ".png"), bords_i = 0, bords_len = array_length(findbords);
			repeat ( bords_len ) {
				var bords_cur = findbords[bords_i]; //Current border we're looking at
		
				var temp_ = string_replace(bords_cur, $"borders{PATHSEP}", ""); 
				var imgnum = string_between(temp_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : real(imgnum); //Get the image number if it's a strip file
				temp_ = string_replace(string_replace(string_replace(temp_, $"spr_", ""), $"_strip", ""), $".png", "");
				temp_ = string_exclude(temp_, "0123456789");
		
				if ( temp_ != "" ) {
					if ( is_undefined(global.bords_dict[$ temp_]) ) {
						global.bords_dict[$ temp_] = { sprite: sprite_add(bords_cur, imgnum, false, false, 0, 0), name: temp_, fname_: bords_cur, count: imgnum, }
						with ( global.bords_dict[$ temp_] ) {
							self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; show_debug_message($"External border \"{fname_}\"({name}) was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
							self[$ "size"] = { sprite, width: sprite_get_width(sprite), height: sprite_get_height(sprite), }
							//sprite_set_offset(sprite, size.width/ 2, size.height/ 2); //Center sprite
							asset_add_tags(sprite, "borders", asset_sprite);
				
							var out_ = $"Added \"{name}\" from {fname_}! | Image Count: {count}";
							var temp_2 = string_replace(bords_cur, $"borders{PATHSEP}", ""); 
							temp_2 = string_replace(string_replace(temp_2, $"_strip", ""), $".png", "");
							temp_2 = string_exclude(temp_2, "0123456789");
							global.bords_dict_alt[$ temp_2] = { sprite, name, size, } //Add sprite index and expression name to the global border alt dictonary
							global.bords_dict_raw[$ string(sprite)] = { sprite, name, size, } //Add sprite index and expression name to the global border raw dictonary
							show_debug_message(out_); global.outputLog += $"{out_}\n";
						}
					}
					else { 
						var out_ = $"Tried to load a sprite that already exists({bords_cur})! Skipping..."; 
						show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
						var out_ = $"|Tried to load a sprite that already exists|({bords_cur})! Skipped...|Remove duplicates before trying again!|"; 
						global.outputLogSkipped += out_; 
					}
				}
				else { 
					var out_ = $"Tried to load a sprite with an invalid name({bords_cur})! Skipping..."; 
					show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
					var out_ = $"|Tried to load a sprite with an invalid filename|({bords_cur})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)|"; 
					global.outputLogSkipped += out_; 
				}
			bords_i++; }
			with ( obj_init ) { loading_state++; alarm[0] = 2; }
		}
		
		///@desc Returns a sprite index from an externally added border sprite.
		///@param {string} name Border Sprite Name (ex: spr_border_custom_animated, border custom example, border_custom_example_two, etc.)
		function get_border(name, return_ = "sprite") { 
			var early_ = asset_get_index(name); if ( early_ != -1 ) { return !is_undefined(global.bords_dict_raw[$ name]) ? global.bords_dict_raw[$ name][$ return_] : early_; }
			var result = global.bords_dict[$ name], result2 = global.bords_dict_alt[$ name], result4 = global.bords_dict_raw[$ name];
			var temp_ = string_replace_all(name, " ", "_"), result3 = global.bords_dict[$ temp_]
			return !is_undefined(result) ? result[$ return_] : ( !is_undefined(result2) ? result2[$ return_] : ( !is_undefined(result3) ? result3[$ return_] : -1 ) );
		}
	#endregion
	
	#region Reference Image
		function load_ref() {
			var fname = $"reference{PATHSEP}reference_image.png", fnamedebug = string_replace(fname, $"reference{PATHSEP}", "");
			global.refimg = -1; if ( file_exists(fname) ) { global.refimg = sprite_add_ext(fname, 1, 0, 0, true); show_debug_message($"Added \"{fnamedebug}\" from {fname}!"); }
			with ( obj_init ) { loading_state++; alarm[0] = 2; }
		}
	#endregion
#endregion

#region Add Custom Fonts
	global.fonts_dict = {};
	global.fonts_dict_alt = {};
	global.fonts_dict_list = [];
	global.fonts_dict_list_custom = [];
	
	function load_fonts() {
		#region Add built-in fonts to a list
			var fonts_ = tag_get_assets("fonts"), fonts_len = array_length(fonts_), fonts_i = 0;
			repeat ( fonts_len ) {
				var cur_ = fonts_[fonts_i];
				global.fonts_dict_list[fonts_i] = cur_;
			fonts_i++; }
		#endregion
	
		var findfonts = gumshoe("fonts", ".png"), fonts_i = 0, fonts_len = array_length(findfonts);
		repeat ( fonts_len ) {
			var fonts_cur = findfonts[fonts_i]; //Current font we're looking at
		
			var temp_ = string_replace(fonts_cur, $"fonts{PATHSEP}", ""); 
			var imgnum = string_between(temp_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : real(imgnum); //Get the image number if it's a strip file
			temp_ = string_replace(string_replace(string_replace(temp_, $"spr_", ""), $"_strip", ""), $".png", "");
			temp_ = string_exclude(temp_, "0123456789");
		
			if ( temp_ != "" ) {
				if ( is_undefined(global.fonts_dict[$ temp_]) ) { 
					global.fonts_dict[$ temp_] = { sprite: sprite_add(fonts_cur, imgnum, false, false, 0, 0), name: temp_, fname_: fonts_cur, count: imgnum, }
					with ( global.fonts_dict[$ temp_] ) {
						array_push(global.fonts_dict_list, name); //Add custom font to array list
						array_push(global.fonts_dict_list_custom, name); //Add custom font to custom array list
						self[$ "font"] = font_add_sprite(sprite, ord("!"), false, 0); //Add as an actual font
						self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; font_delete(font); delete font; font = -1; show_debug_message($"External font \"{fname_}\"({name}) was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
					
						var temp_2 = string_replace(fonts_cur, $"fonts{PATHSEP}", ""); 
						temp_2 = string_replace(string_replace(temp_2, $"_strip", ""), $".png", "");
						temp_2 = string_exclude(temp_2, "0123456789");
	
						global.fonts_dict_alt[$ temp_2] = { sprite, font, name, } //Add sprite index and expression name to the global icon alt dictonary
						var getfont = asset_get_name(sprite);
						scribble_font_rename(getfont, name); //Let us use the font's filename instead of whatever name gamemaker generated for us
						scribble_font_bake_outline_and_shadow(name, $"{name}_s", 0, 0, SCRIBBLE_OUTLINE.NO_OUTLINE, 0, false);
						scribble_font_bake_outline_and_shadow(name, $"{name}_outline", 0, 0, SCRIBBLE_OUTLINE.EIGHT_DIR, 0, false);
						scribble_font_delete(name); scribble_font_rename($"{name}_s", name);
						scribble_glyph_set($"{name}_outline", all, SCRIBBLE_GLYPH.FONT_HEIGHT, scribble_glyph_get(name, "W", SCRIBBLE_GLYPH.FONT_HEIGHT));
						var out_ = $"Added \"{name}\" and outline variant from {fname_}! Renamed custom font from {getfont} to {global.fonts_dict_alt[$ temp_2].name} for use with Scribble.\nImage Count: {count}";
						show_debug_message(out_); global.outputLog += $"{out_}\n";
					}
				}
				else { 
					var out_ = $"Tried to load a sprite that already exists({fonts_cur})! Skipping..."; 
					show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
					var out_ = $"|Tried to load a sprite that already exists|({fonts_cur})! Skipped...|Remove duplicates before trying again!|"; 
					global.outputLogSkipped += out_; 
				}
			}
			else { 
				var out_ = $"Tried to load a sprite with an invalid name({fonts_cur})! Skipping..."; 
				show_debug_message(out_); global.outputLog += $"{out_}\n"; 
				
				var out_ = $"|Tried to load a sprite with an invalid filename|({fonts_cur})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)|"; 
				global.outputLogSkipped += out_; 
			}
		fonts_i++; }
		with ( obj_init ) { loading_state++; alarm[0] = 2; }
	}
	
	///@desc Returns a sprite index from an externally added font sprite.
	///@param {string} name Font Sprite Name (ex: spr_font_custom_example, font custom example two, etc.)
	function get_font(name, return_ = "font") { 
		var early_ = asset_get_index(name); if ( early_ != -1 ) { return early_; }
		var result = global.fonts_dict[$ name], result2 = global.fonts_dict_alt[$ name];
		var temp_ = string_replace_all(name, " ", "_"), result3 = global.fonts_dict[$ temp_]
		return !is_undefined(result) ? result[$ return_] : ( !is_undefined(result2) ? result2[$ return_] : ( !is_undefined(result3) ? result3[$ return_] : -1 ) );
	}
#endregion

#region Log
	if ( !is_android() ) { 
		var oLog = file_text_open_write($"{executable_get_directory()}latest_soupy_run.soupy");
		file_text_write_string(oLog, global.outputLog);
		file_text_close(oLog);
	}
#endregion

#region Functions
	#region Safe ZIP face imports
		#macro SOUPY_ZIP_MAX_ARCHIVE_BYTES (64 * 1024 * 1024)
		#macro SOUPY_ZIP_MAX_ENTRIES 512
		#macro SOUPY_ZIP_MAX_ENTRY_BYTES (16 * 1024 * 1024)
		#macro SOUPY_ZIP_MAX_TOTAL_BYTES (128 * 1024 * 1024)
		#macro SOUPY_ZIP_MAX_RATIO 100
		#macro SOUPY_ZIP_MAX_FRAMES 256
		#macro SOUPY_ZIP_MAX_SPRITE_SIDE 4096
		#macro SOUPY_ZIP_MAX_TEXTURE_SIDE 8192
		#macro SOUPY_ZIP_MAX_IMAGE_PIXELS (16 * 1024 * 1024)
		#macro SOUPY_ZIP_MAX_TOTAL_PIXELS (64 * 1024 * 1024)

		function soupy_zip_starts_with(value_, prefix_) {
			return string_length(value_) >= string_length(prefix_) && string_copy(value_, 1, string_length(prefix_)) == prefix_;
		}

		function soupy_zip_ends_with(value_, suffix_) {
			var value_len_ = string_length(value_), suffix_len_ = string_length(suffix_);
			return value_len_ >= suffix_len_ && string_copy(value_, value_len_ - suffix_len_ + 1, suffix_len_) == suffix_;
		}

		function soupy_zip_error_string(error_) {
			if ( is_struct(error_) && variable_struct_exists(error_, "message") ) { return string(error_.message); }
			return string(error_);
		}

		function soupy_zip_report_error(message_) {
			show_debug_message($"ZIP face import failed: {message_}");
			soupy_message($"ZIP import failed.|{message_}", "OK", 460, , , snd_error, fnt_abaddon, , SYSTEMUI.ui_paused, true);
		}

		function soupy_zip_u16(buffer_, offset_) {
			return buffer_peek(buffer_, offset_, buffer_u8)
				+ buffer_peek(buffer_, offset_ + 1, buffer_u8) * 256;
		}

		function soupy_zip_u32(buffer_, offset_) {
			return int64(buffer_peek(buffer_, offset_, buffer_u8))
				+ int64(buffer_peek(buffer_, offset_ + 1, buffer_u8)) * 256
				+ int64(buffer_peek(buffer_, offset_ + 2, buffer_u8)) * 65536
				+ int64(buffer_peek(buffer_, offset_ + 3, buffer_u8)) * 16777216;
		}

		function soupy_zip_u32_be(buffer_, offset_) {
			return int64(buffer_peek(buffer_, offset_, buffer_u8)) * 16777216
				+ int64(buffer_peek(buffer_, offset_ + 1, buffer_u8)) * 65536
				+ int64(buffer_peek(buffer_, offset_ + 2, buffer_u8)) * 256
				+ int64(buffer_peek(buffer_, offset_ + 3, buffer_u8));
		}

		/// @desc Validate an extracted PNG before GameMaker decodes it into a texture.
		function soupy_zip_png_info(path_, expected_crc_) {
			var png_buffer_ = -1;
			try {
				png_buffer_ = buffer_load(path_);
				if ( !buffer_exists(png_buffer_) || buffer_get_used_size(png_buffer_) < 24 ) { throw "PNG header is missing or truncated."; }
				var signature_ = [137, 80, 78, 71, 13, 10, 26, 10];
				for ( var signature_i_ = 0; signature_i_ < array_length(signature_); signature_i_++; ) {
					if ( buffer_peek(png_buffer_, signature_i_, buffer_u8) != signature_[signature_i_] ) { throw "A file has a .png name but not a PNG signature."; }
				}
				if ( soupy_zip_u32_be(png_buffer_, 8) != 13
					|| buffer_peek(png_buffer_, 12, buffer_u8) != 73 || buffer_peek(png_buffer_, 13, buffer_u8) != 72
					|| buffer_peek(png_buffer_, 14, buffer_u8) != 68 || buffer_peek(png_buffer_, 15, buffer_u8) != 82 ) {
					throw "The PNG does not begin with a valid IHDR chunk.";
				}

				var actual_crc_ = buffer_crc32(png_buffer_, 0, buffer_get_used_size(png_buffer_));
				if ( actual_crc_ < 0 ) { actual_crc_ += 4294967296; }
				if ( int64(actual_crc_) != int64(expected_crc_) ) { throw "An extracted PNG failed its ZIP CRC32 check."; }

				var width_ = soupy_zip_u32_be(png_buffer_, 16), height_ = soupy_zip_u32_be(png_buffer_, 20);
				if ( width_ < 1 || height_ < 1 ) { throw "PNG dimensions must be positive."; }
				return { width: width_, height: height_, pixels: width_ * height_, };
			}
			finally {
				if ( buffer_exists(png_buffer_) ) { buffer_delete(png_buffer_); }
			}
		}

		function soupy_zip_ascii(buffer_, offset_, length_) {
			var result_ = "";
			for ( var i_ = 0; i_ < length_; i_++; ) {
				var byte_ = buffer_peek(buffer_, offset_ + i_, buffer_u8);
				if ( is_undefined(byte_) || byte_ < 32 || byte_ > 126 ) { throw "ZIP entry names must use printable ASCII characters."; }
				result_ += chr(byte_);
			}
			return result_;
		}

		function soupy_zip_safe_segment(segment_) {
			if ( segment_ == "" || string_length(segment_) > 64 ) { return false; }
			var allowed_ = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
			for ( var i_ = 1; i_ <= string_length(segment_); i_++; ) {
				if ( string_pos(string_char_at(segment_, i_), allowed_) == 0 ) { return false; }
			}
			var upper_ = string_upper(segment_);
			if ( upper_ == "CON" || upper_ == "PRN" || upper_ == "AUX" || upper_ == "NUL" ) { return false; }
			if ( string_length(upper_) == 4 ) {
				var prefix_ = string_copy(upper_, 1, 3), suffix_ = string_char_at(upper_, 4);
				if ( (prefix_ == "COM" || prefix_ == "LPT") && string_pos(suffix_, "123456789") > 0 ) { return false; }
			}
			return true;
		}

		function soupy_zip_entry_path(raw_path_) {
			if ( raw_path_ == "" || string_length(raw_path_) > 240 ) { throw "A ZIP entry has an invalid path length."; }
			if ( string_pos("\\", raw_path_) > 0 ) { throw "Backslashes are not allowed in ZIP entry paths."; }
			if ( string_char_at(raw_path_, 1) == "/" || string_pos(":", raw_path_) > 0 || string_pos("//", raw_path_) > 0 ) {
				throw "A ZIP entry uses an absolute or ambiguous path.";
			}

			var is_directory_ = soupy_zip_ends_with(raw_path_, "/");
			var normalized_ = is_directory_ ? string_delete(raw_path_, string_length(raw_path_), 1) : raw_path_;
			if ( normalized_ == "" ) { throw "The ZIP contains an invalid root entry."; }

			var segments_ = string_split(normalized_, "/", false);
			for ( var i_ = 0; i_ < array_length(segments_); i_++; ) {
				var segment_ = segments_[i_];
				if ( segment_ == "" || segment_ == "." || segment_ == ".."
					|| !soupy_zip_safe_segment(segment_) && (is_directory_ || i_ < array_length(segments_) - 1) ) {
					throw "A ZIP entry contains an unsafe directory name.";
				}
			}
			return { path: normalized_, segments: segments_, is_directory: is_directory_, };
		}

		function soupy_zip_face_filename(character_, filename_) {
			if ( string_lower(filename_ext(filename_)) != ".png" ) { throw "Face packs may only contain PNG files."; }
			var basename_ = filename_change_ext(filename_, ""), basename_lower_ = string_lower(basename_);
			if ( !soupy_zip_safe_segment(basename_) ) { throw $"Invalid face filename: {filename_}"; }

			var frames_ = 1, stem_ = basename_;
			var strip_pos_ = string_pos("_strip", basename_lower_);
			if ( strip_pos_ > 0 ) {
				if ( string_count("_strip", basename_lower_) != 1 ) { throw $"Invalid strip filename: {filename_}"; }
				var digits_ = string_copy(basename_, strip_pos_ + 6, string_length(basename_) - strip_pos_ - 5);
				if ( digits_ == "" || string_digits(digits_) != digits_ ) { throw $"Invalid strip frame count: {filename_}"; }
				frames_ = real(digits_);
				if ( frames_ < 1 || frames_ > SOUPY_ZIP_MAX_FRAMES ) { throw $"Strip frame count is outside 1-{SOUPY_ZIP_MAX_FRAMES}: {filename_}"; }
				stem_ = string_copy(basename_, 1, strip_pos_ - 1);
			}

			var prefix_ = $"spr_{string_lower(character_)}_", stem_lower_ = string_lower(stem_);
			var expression_ = soupy_zip_starts_with(stem_lower_, prefix_)
				? string_copy(stem_, string_length(prefix_) + 1, string_length(stem_) - string_length(prefix_))
				: stem_;
			if ( expression_ == "" || !soupy_zip_safe_segment(expression_) || string_digits(expression_) != "" ) {
				throw $"Invalid face expression name: {filename_}";
			}
			return { expression: expression_, frames: frames_, };
		}

		function soupy_zip_validate_extra(buffer_, offset_, length_) {
			var end_ = offset_ + length_, position_ = offset_;
			while ( position_ < end_ ) {
				if ( position_ + 4 > end_ ) { throw "A ZIP extra field is truncated."; }
				var tag_ = soupy_zip_u16(buffer_, position_);
				var size_ = soupy_zip_u16(buffer_, position_ + 2);
				position_ += 4;
				if ( position_ + size_ > end_ ) { throw "A ZIP extra field has an invalid size."; }
				// Only timestamp and NTFS metadata are accepted. In particular, reject ZIP64 and Unicode path overrides.
				if ( tag_ != $5455 && tag_ != $000A ) { throw $"Unsupported ZIP extra field: 0x{string(tag_)}"; }
				position_ += size_;
			}
		}

		/// @desc Inspect the central directory and matching local headers before extraction.
		/// This intentionally supports a conservative ZIP subset: ASCII paths, stored/deflate PNG files, no ZIP64 or encryption.
		function soupy_zip_preflight(zip_path_) {
			var zip_buffer_ = -1;
			try {
				var disk_size_ = file_size(zip_path_);
				if ( disk_size_ <= 0 || disk_size_ > SOUPY_ZIP_MAX_ARCHIVE_BYTES ) { throw "Archive size is invalid or exceeds 64 MiB."; }

				zip_buffer_ = buffer_load(zip_path_);
				if ( zip_buffer_ == -1 ) { throw "The archive could not be read."; }
				var zip_size_ = buffer_get_used_size(zip_buffer_);
				if ( zip_size_ < 22 || zip_size_ > SOUPY_ZIP_MAX_ARCHIVE_BYTES ) { throw "The archive is empty, truncated, or too large."; }

				var eocd_ = -1, search_min_ = max(0, zip_size_ - 65557);
				for ( var pos_ = zip_size_ - 22; pos_ >= search_min_; pos_--; ) {
					if ( soupy_zip_u32(zip_buffer_, pos_) == $06054B50 ) {
						var comment_length_ = soupy_zip_u16(zip_buffer_, pos_ + 20);
						if ( pos_ + 22 + comment_length_ == zip_size_ ) { eocd_ = pos_; break; }
					}
				}
				if ( eocd_ < 0 ) { throw "The ZIP end record is missing or malformed."; }

				var disk_number_ = soupy_zip_u16(zip_buffer_, eocd_ + 4);
				var central_disk_ = soupy_zip_u16(zip_buffer_, eocd_ + 6);
				var disk_entries_ = soupy_zip_u16(zip_buffer_, eocd_ + 8);
				var entry_count_ = soupy_zip_u16(zip_buffer_, eocd_ + 10);
				var central_size_ = soupy_zip_u32(zip_buffer_, eocd_ + 12);
				var central_offset_ = soupy_zip_u32(zip_buffer_, eocd_ + 16);
				if ( disk_number_ != 0 || central_disk_ != 0 || disk_entries_ != entry_count_ ) { throw "Multi-disk ZIP files are not supported."; }
				if ( entry_count_ == $FFFF || central_size_ == $FFFFFFFF || central_offset_ == $FFFFFFFF ) { throw "ZIP64 archives are not supported."; }
				if ( entry_count_ < 1 || entry_count_ > SOUPY_ZIP_MAX_ENTRIES ) { throw $"Archive entry count is outside 1-{SOUPY_ZIP_MAX_ENTRIES}."; }
				if ( central_offset_ < 0 || central_size_ < 0 || central_offset_ + central_size_ > eocd_ ) { throw "The ZIP central directory points outside the archive."; }

				var files_ = [], seen_paths_ = {}, seen_faces_ = {}, seen_offsets_ = {};
				var central_pos_ = central_offset_, total_bytes_ = 0, layout_depth_ = -1, wrapper_ = "";
				for ( var entry_i_ = 0; entry_i_ < entry_count_; entry_i_++; ) {
					if ( central_pos_ + 46 > eocd_ || soupy_zip_u32(zip_buffer_, central_pos_) != $02014B50 ) { throw "A central directory entry is truncated or invalid."; }

					var made_by_ = soupy_zip_u16(zip_buffer_, central_pos_ + 4);
					var flags_ = soupy_zip_u16(zip_buffer_, central_pos_ + 8);
					var method_ = soupy_zip_u16(zip_buffer_, central_pos_ + 10);
					var crc_ = soupy_zip_u32(zip_buffer_, central_pos_ + 16);
					var compressed_ = soupy_zip_u32(zip_buffer_, central_pos_ + 20);
					var uncompressed_ = soupy_zip_u32(zip_buffer_, central_pos_ + 24);
					var name_length_ = soupy_zip_u16(zip_buffer_, central_pos_ + 28);
					var extra_length_ = soupy_zip_u16(zip_buffer_, central_pos_ + 30);
					var entry_comment_length_ = soupy_zip_u16(zip_buffer_, central_pos_ + 32);
					var entry_disk_ = soupy_zip_u16(zip_buffer_, central_pos_ + 34);
					var external_attributes_ = soupy_zip_u32(zip_buffer_, central_pos_ + 38);
					var local_offset_ = soupy_zip_u32(zip_buffer_, central_pos_ + 42);
					var central_end_ = central_pos_ + 46 + name_length_ + extra_length_ + entry_comment_length_;
					if ( name_length_ < 1 || central_end_ > eocd_ ) { throw "A ZIP entry has invalid field lengths."; }
					if ( entry_disk_ != 0 || compressed_ == $FFFFFFFF || uncompressed_ == $FFFFFFFF || local_offset_ == $FFFFFFFF ) { throw "ZIP64 or split entries are not supported."; }
					if ( (flags_ & $F7F1) != 0 ) { throw "Encrypted or unsupported ZIP entry flags are not allowed."; }
					if ( method_ != 0 && method_ != 8 ) { throw "Only stored and deflated ZIP entries are supported."; }
					if ( method_ == 0 && (flags_ & 6) != 0 ) { throw "Stored ZIP entries cannot use deflate option flags."; }

					var raw_name_ = soupy_zip_ascii(zip_buffer_, central_pos_ + 46, name_length_);
					soupy_zip_validate_extra(zip_buffer_, central_pos_ + 46 + name_length_, extra_length_);
					var entry_path_ = soupy_zip_entry_path(raw_name_);
					var path_key_ = string_lower(entry_path_.path);
					if ( variable_struct_exists(seen_paths_, path_key_) ) { throw $"Duplicate ZIP path: {entry_path_.path}"; }
					seen_paths_[$ path_key_] = true;

					var host_os_ = (made_by_ >> 8) & $FF;
					var unix_kind_ = (external_attributes_ >> 16) & $F000;
					if ( host_os_ == 3 && unix_kind_ != 0 && unix_kind_ != $4000 && unix_kind_ != $8000 ) { throw "Links and special filesystem entries are not allowed in face packs."; }
					if ( host_os_ == 3 && entry_path_.is_directory != (unix_kind_ == $4000) && unix_kind_ != 0 ) { throw "A ZIP entry's path and filesystem type disagree."; }

					if ( local_offset_ + 30 > central_offset_ || soupy_zip_u32(zip_buffer_, local_offset_) != $04034B50 ) { throw "A ZIP local header is missing or outside the data area."; }
					var local_flags_ = soupy_zip_u16(zip_buffer_, local_offset_ + 6);
					var local_method_ = soupy_zip_u16(zip_buffer_, local_offset_ + 8);
					var local_crc_ = soupy_zip_u32(zip_buffer_, local_offset_ + 14);
					var local_compressed_ = soupy_zip_u32(zip_buffer_, local_offset_ + 18);
					var local_uncompressed_ = soupy_zip_u32(zip_buffer_, local_offset_ + 22);
					var local_name_length_ = soupy_zip_u16(zip_buffer_, local_offset_ + 26);
					var local_extra_length_ = soupy_zip_u16(zip_buffer_, local_offset_ + 28);
					var local_data_ = local_offset_ + 30 + local_name_length_ + local_extra_length_;
					if ( local_data_ > central_offset_ || local_data_ + compressed_ > central_offset_ ) { throw "A ZIP entry's compressed data is outside the data area."; }
					var local_name_ = soupy_zip_ascii(zip_buffer_, local_offset_ + 30, local_name_length_);
					soupy_zip_validate_extra(zip_buffer_, local_offset_ + 30 + local_name_length_, local_extra_length_);
					if ( local_name_ != raw_name_ || local_flags_ != flags_ || local_method_ != method_ ) { throw "Central and local ZIP headers do not match."; }
					if ( (flags_ & 8) == 0 ) {
						if ( local_crc_ != crc_ || local_compressed_ != compressed_ || local_uncompressed_ != uncompressed_ ) { throw "Central and local ZIP sizes or checksums do not match."; }
					}
					else {
						if ( local_crc_ != 0 && local_crc_ != crc_ || local_compressed_ != 0 && local_compressed_ != compressed_
							|| local_uncompressed_ != 0 && local_uncompressed_ != uncompressed_ ) { throw "A streamed ZIP entry has contradictory local metadata."; }
						var descriptor_ = local_data_ + compressed_;
						if ( descriptor_ + 12 > central_offset_ ) { throw "A ZIP data descriptor is truncated."; }
						if ( soupy_zip_u32(zip_buffer_, descriptor_) == $08074B50 ) { descriptor_ += 4; }
						if ( descriptor_ + 12 > central_offset_ || soupy_zip_u32(zip_buffer_, descriptor_) != crc_
							|| soupy_zip_u32(zip_buffer_, descriptor_ + 4) != compressed_ || soupy_zip_u32(zip_buffer_, descriptor_ + 8) != uncompressed_ ) {
							throw "A ZIP data descriptor does not match the inspected entry.";
						}
					}
					var offset_key_ = string(local_offset_);
					if ( variable_struct_exists(seen_offsets_, offset_key_) ) { throw "Multiple entries share one local ZIP header."; }
					seen_offsets_[$ offset_key_] = true;

					if ( entry_path_.is_directory ) {
						if ( compressed_ != 0 || uncompressed_ != 0 ) { throw "Directory entries in a face pack must be empty."; }
					}
					else {
						if ( compressed_ > SOUPY_ZIP_MAX_ENTRY_BYTES || uncompressed_ > SOUPY_ZIP_MAX_ENTRY_BYTES ) { throw $"ZIP entry exceeds {SOUPY_ZIP_MAX_ENTRY_BYTES div (1024 * 1024)} MiB: {entry_path_.path}"; }
						if ( uncompressed_ > 0 && compressed_ == 0 ) { throw "A non-empty ZIP entry has no compressed data."; }
						if ( compressed_ > 0 && uncompressed_ > 1024 * 1024 && uncompressed_ > compressed_ * SOUPY_ZIP_MAX_RATIO ) { throw "A ZIP entry exceeds the allowed compression ratio."; }
						total_bytes_ += uncompressed_;
						if ( total_bytes_ > SOUPY_ZIP_MAX_TOTAL_BYTES ) { throw "The archive exceeds 128 MiB when unpacked."; }

						var segments_ = entry_path_.segments, depth_ = array_length(segments_);
						if ( depth_ != 2 && depth_ != 3 ) { throw "PNG files must use character/file.png, optionally inside one wrapper folder."; }
						if ( layout_depth_ == -1 ) {
							layout_depth_ = depth_;
							wrapper_ = depth_ == 3 ? string_lower(segments_[0]) : "";
						}
						if ( depth_ != layout_depth_ || depth_ == 3 && string_lower(segments_[0]) != wrapper_ ) { throw "All PNG files must use one consistent archive layout."; }

						var character_ = segments_[depth_ - 2], filename_ = segments_[depth_ - 1];
						if ( !soupy_zip_safe_segment(character_) ) { throw $"Invalid character folder: {character_}"; }
						var face_info_ = soupy_zip_face_filename(character_, filename_);
						var face_key_ = $"{string_lower(character_)}|{string_lower(face_info_.expression)}";
						if ( variable_struct_exists(seen_faces_, face_key_) ) { throw $"Duplicate face alias: {character_}/{face_info_.expression}"; }
						seen_faces_[$ face_key_] = true;
						array_push(files_, {
							path: entry_path_.path,
							character: character_,
							filename: filename_,
							expression: face_info_.expression,
							frames: face_info_.frames,
							crc: crc_,
							uncompressed_size: uncompressed_,
						});
					}
					central_pos_ = central_end_;
				}

				if ( central_pos_ != central_offset_ + central_size_ ) { throw "The ZIP central directory contains unsupported trailing records."; }
				if ( array_length(files_) == 0 ) { throw "The archive contains no importable PNG faces."; }
				return { ok: true, files: files_, archive_size: zip_size_, unpacked_size: total_bytes_, };
			}
			catch ( error_ ) {
				return { ok: false, error: soupy_zip_error_string(error_), files: [], };
			}
			finally {
				if ( buffer_exists(zip_buffer_) ) { buffer_delete(zip_buffer_); }
			}
		}

		function soupy_zip_canonical(path_) {
			var result_ = string_replace_all(filename_canonical(path_), "\\", "/");
			return os_type == os_windows ? string_lower(result_) : result_;
		}

		function soupy_zip_trim_directory_path(path_) {
			var result_ = path_;
			while ( string_length(result_) > 1 && (soupy_zip_ends_with(result_, "/") || soupy_zip_ends_with(result_, "\\")) ) {
				result_ = string_delete(result_, string_length(result_), 1);
			}
			return result_;
		}

		function soupy_zip_path_within(root_canonical_, path_) {
			var path_canonical_ = soupy_zip_canonical(path_);
			var prefix_ = soupy_zip_ends_with(root_canonical_, "/") ? root_canonical_ : root_canonical_ + "/";
			return soupy_zip_starts_with(path_canonical_, prefix_);
		}

		/// @desc Enumerate staging without following directory links or leaving its canonical root.
		function soupy_zip_collect_files_inner(directory_, root_canonical_, result_, counter_) {
			var base_ = soupy_zip_ends_with(directory_, PATHSEP) ? directory_ : directory_ + PATHSEP;
			var names_ = [], current_ = file_find_first(base_ + "*", fa_directory | fa_hidden | fa_sysfile | fa_readonly);
			while ( current_ != "" ) {
				if ( current_ != "." && current_ != ".." ) { array_push(names_, current_); }
				current_ = file_find_next();
			}
			file_find_close();

			for ( var i_ = 0; i_ < array_length(names_); i_++; ) {
				counter_.count++;
				if ( counter_.count > SOUPY_ZIP_MAX_ENTRIES * 2 + 4 ) { throw "The extracted archive contains too many filesystem entries."; }
				var path_ = base_ + names_[i_];
				if ( symlink_exists(path_) ) { throw "The extracted archive contains a symbolic link or junction."; }
				if ( !soupy_zip_path_within(root_canonical_, path_) ) { throw "An extracted path escaped the staging directory."; }
				if ( directory_exists(path_) ) { soupy_zip_collect_files_inner(path_, root_canonical_, result_, counter_); }
				else if ( file_exists(path_) ) { array_push(result_, path_); }
				else { throw "The extracted archive contains an unsupported filesystem entry."; }
			}
			return result_;
		}

		function soupy_zip_collect_files(directory_) {
			var root_canonical_ = soupy_zip_canonical(directory_);
			return soupy_zip_collect_files_inner(directory_, root_canonical_, [], { count: 0, });
		}

		function soupy_zip_stage_path(stage_) {
			var raw_stage_ = string_replace_all(stage_, "\\", "/");
			var raw_temp_ = string_replace_all(temp_directory, "\\", "/");
			if ( os_type == os_windows ) { raw_stage_ = string_lower(raw_stage_); raw_temp_ = string_lower(raw_temp_); }
			if ( !soupy_zip_ends_with(raw_temp_, "/") ) { raw_temp_ += "/"; }
			if ( !soupy_zip_starts_with(raw_stage_, raw_temp_) ) { return false; }
			var relative_ = string_delete(raw_stage_, 1, string_length(raw_temp_));
			if ( soupy_zip_ends_with(relative_, "/") ) { relative_ = string_delete(relative_, string_length(relative_), 1); }
			return soupy_zip_starts_with(relative_, "soupy_zip_") && string_pos("/", relative_) == 0;
		}

		function soupy_zip_delete_tree_inner(directory_, root_canonical_) {
			var base_ = soupy_zip_ends_with(directory_, PATHSEP) ? directory_ : directory_ + PATHSEP;
			var names_ = [], current_ = file_find_first(base_ + "*", fa_directory | fa_hidden | fa_sysfile | fa_readonly);
			while ( current_ != "" ) {
				if ( current_ != "." && current_ != ".." ) { array_push(names_, current_); }
				current_ = file_find_next();
			}
			file_find_close();

			for ( var i_ = 0; i_ < array_length(names_); i_++; ) {
				var path_ = base_ + names_[i_];
				if ( symlink_exists(path_) ) {
					if ( directory_exists(path_) ) { directory_destroy(path_); }
					else if ( file_exists(path_) ) { file_delete(path_); }
				}
				else if ( directory_exists(path_) ) {
					if ( soupy_zip_path_within(root_canonical_, path_) ) { soupy_zip_delete_tree_inner(path_, root_canonical_); }
				}
				else if ( file_exists(path_) && soupy_zip_path_within(root_canonical_, path_) ) { file_delete(path_); }
			}
			directory_destroy(directory_);
		}

		function soupy_zip_cleanup(stage_) {
			if ( !is_string(stage_) || !soupy_zip_stage_path(stage_) || !directory_exists(stage_) ) { return; }
			try {
				var root_canonical_ = soupy_zip_canonical(stage_);
				var temp_canonical_ = soupy_zip_canonical(temp_directory);
				if ( soupy_zip_path_within(temp_canonical_, stage_) ) { soupy_zip_delete_tree_inner(stage_, root_canonical_); }
			}
			catch ( cleanup_error_ ) { show_debug_message($"ZIP staging cleanup failed: {soupy_zip_error_string(cleanup_error_)}"); }
		}

		function soupy_zip_begin(zip_path_) {
			if ( os_browser != browser_not_a_browser || is_wasm() ) {
				soupy_zip_report_error("ZIP import is unavailable in browser builds.");
				return false;
			}
			if ( !is_string(zip_path_) || string_lower(filename_ext(zip_path_)) != ".zip" ) {
				soupy_zip_report_error("Select a file with the .zip extension.");
				return false;
			}
			if ( !is_undefined(soup_checkout("bulkload", false, true)) ) {
				soupy_zip_report_error("Another ZIP face import is already running.");
				return false;
			}

			var token_ = $"{current_time}_{irandom(999999999)}";
			var temp_root_ = temp_directory;
			if ( !string_ends_with(temp_root_, "/") && !string_ends_with(temp_root_, "\\") ) { temp_root_ += PATHSEP; }
			var stage_ = $"{temp_root_}soupy_zip_{token_}{PATHSEP}";
			var extract_ = $"{stage_}extract{PATHSEP}";
			var snapshot_ = $"{stage_}archive.zip";
			if ( directory_exists(stage_) ) { soupy_zip_report_error("Could not allocate a unique staging folder."); return false; }
			directory_create(stage_);
			if ( !directory_exists(stage_) ) { soupy_zip_report_error("Could not create the staging folder."); return false; }

			try {
				var source_size_ = file_size(zip_path_);
				if ( source_size_ <= 0 || source_size_ > SOUPY_ZIP_MAX_ARCHIVE_BYTES ) { throw "Archive size is invalid or exceeds 64 MiB."; }
				file_copy(zip_path_, snapshot_);
				if ( !file_exists(snapshot_) || file_size(snapshot_) != source_size_ ) { throw "Could not create a stable snapshot of the selected ZIP."; }

				var preflight_ = soupy_zip_preflight(snapshot_);
				if ( !preflight_.ok ) { throw preflight_.error; }
				directory_create(extract_);
				if ( !directory_exists(extract_) ) { throw "Could not create the extraction staging folder."; }

				var request_ = zip_unzip_async(snapshot_, extract_);
				if ( request_ < 0 ) { throw "GameMaker rejected the ZIP extraction request."; }
				soup_store("bulkload", {
					id: request_,
					fpath: zip_path_,
					stage: stage_,
					extract: extract_,
					archive: snapshot_,
					token: token_,
					plan: preflight_.files,
				}, false, true);
				return true;
			}
			catch ( error_ ) {
				soupy_zip_cleanup(stage_);
				soupy_zip_report_error(soupy_zip_error_string(error_));
				return false;
			}
		}

		function soupy_zip_character_key(character_) {
			var names_ = struct_get_names(global.faces_dict), wanted_ = string_lower(character_);
			for ( var i_ = 0; i_ < array_length(names_); i_++; ) {
				if ( string_lower(names_[i_]) == wanted_ ) { return names_[i_]; }
			}
			return character_;
		}

		function soupy_zip_face_exists(character_key_, expression_) {
			if ( !variable_struct_exists(global.faces_dict, character_key_) ) { return false; }
			var faces_ = struct_get_names(global.faces_dict[$ character_key_]), wanted_ = string_lower(expression_);
			for ( var i_ = 0; i_ < array_length(faces_); i_++; ) {
				if ( faces_[i_] != "NEW SPRITE" && string_lower(faces_[i_]) == wanted_ ) { return true; }
			}
			return false;
		}

		function soupy_zip_struct_key_exists_ci(struct_, key_) {
			var names_ = struct_get_names(struct_), wanted_ = string_lower(key_);
			for ( var i_ = 0; i_ < array_length(names_); i_++; ) {
				if ( string_lower(names_[i_]) == wanted_ ) { return true; }
			}
			return false;
		}
	#endregion

	///@desc Returns an external sprite or adds it if it doesn't already exist
	function external_ensure(name_, fname_, fpath_, type_ = 0, allowmultiple_ = true, showmsg_ = true) {
		if ( filename_ext(fpath_) != ".png" && !is_android() ) { soupy_message($"\"{fname_}\"|is not allowed to be loaded.|File must be a PNG format.", , 320, , , snd_error, , , SYSTEMUI.ui_paused); return -1; }
		
		switch ( type_ ) {
			case 0: { //Face Sprites
				var spr_ = get_face(name_);
				if ( spr_ != -1 ) { return spr_; } else {
					var imgnum = string_between(fname_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : imgnum; //Get the image number if it's a strip file
					if ( name_ != "" ) {
						if ( !struct_exists(global.faces_dict, name_) ) { global.faces_dict[$ name_] = {}; } //Create new struct face dictionary
						with ( global.faces_dict[$ name_] ) {
							var finalname = string_replace(string_replace(fname_, "_strip", ""), ".png", ""); finalname = string_exclude(finalname, "0123456789");
							self[$ "NEW SPRITE"] = true; //Mark the sprite as new
							self[$ name_] = { sprite: sprite_add_ext(fpath_, imgnum, 0, 0, true), expression: finalname, name: fpath_, } //Add sprite and data
							if ( allowmultiple_ ) { TweenScript(SYSTEMUI, 0, 1, soup_store, "allowmultiple"); }
							if ( !showmsg_ ) { TweenScript(SYSTEMUI, 0, 1, soup_store, "showmsg"); }
							with ( self[$ name_] ) { 
								self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; show_debug_message($"External face \"{name}\" was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
							
								var out_ = $"Added \"{expression}\"|You can now use|[{expression}] and [face,{expression}]|to reference the sprite!|The command was copied to your clipboard.";
								TweenScript(SYSTEMUI, 0, 1, soup_store, "external face", { myname: name_, id_: name_, msg: out_}); 
								if ( !scribble_external_sprite_exists(finalname) ) { scribble_external_sprite_add(sprite, finalname); } //Add sprite to Scribble
								var altname = string_replace(finalname, "spr_", "");
								if ( !scribble_external_sprite_exists(altname) ) { scribble_external_sprite_add(sprite, altname); } //Add alternative name
								global.faces_dict_alt[$ name_] = { sprite, expression, name, destroy } //Create new struct face dictionary
								clipboard_set_text($"[{expression}][face,{expression}]");
								
								return sprite;
							}
						}
					}
					else { 
						TweenScript(SYSTEMUI, 0, 5, function (fpath_ = "") {
							var out_ = $"Tried to load a sprite with an invalid filename|({fpath_})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)";
							soupy_message(out_, "Oh no!", , 135, , snd_error, fnt_abaddon, function () { SYSTEMUI.file_dragging = false; }, SYSTEMUI.ui_paused);
						}, fpath_); return -1;
					}
				}
			} break;
			
			case 1: { //Border Sprites
				var spr_ = get_border(name_);
				if ( spr_ != -1 ) { return spr_; } else {
					if ( name_ != "" ) {
						if ( !struct_exists(global.bords_dict, name_) ) { global.bords_dict[$ name_] = {}; } //Create new struct border dictionary
						var imgnum = string_between(fname_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : imgnum; //Get the image number if it's a strip file
						with ( global.bords_dict[$ name_] ) {
							var finalname = string_replace(string_replace(fname_, "_strip", ""), ".png", ""); finalname = string_exclude(finalname, "0123456789");

							self[$ "NEW SPRITE"] = true; //Mark the sprite as new
							self[$ "sprite"] = sprite_add_ext(fpath_, imgnum, 0, 0, true); self[$ "name"] = name_; self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; show_debug_message($"External border \"{name}\" was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
							self[$ "size"] = { sprite, width: sprite_get_width(sprite), height: sprite_get_height(sprite), }
							asset_add_tags(sprite, "borders", asset_sprite);
							if ( allowmultiple_ ) { TweenScript(SYSTEMUI, 0, 1, soup_store, "allowmultiple"); }
							
							var out_ = $"Added \"{finalname}\"|You can now use|[border,{finalname}]|to reference the sprite!|The command was copied to your clipboard.";
							TweenScript(SYSTEMUI, 0, 1, soup_store, "external border", { myname: name_, msg: out_}); 
							global.bords_dict_alt[$ name_] = { sprite, name, size, } //Add sprite index and expression name to the global border alt dictonary
							global.bords_dict_raw[$ string(sprite)] = { sprite, name, size, } //Add sprite index and expression name to the global border raw dictonary
							clipboard_set_text($"[border,{finalname}]");
							return sprite;
						}
					}
					else { 
						TweenScript(SYSTEMUI, 0, 5, function (fpath_ = "") {
							var out_ = $"Tried to load a sprite with an invalid filename|({fpath_})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)";
							soupy_message(out_, "Oh no!", , 135, , snd_error, fnt_abaddon, function () { SYSTEMUI.file_dragging = false; }, SYSTEMUI.ui_paused);
						}, fpath_); return -1;
					}
				}
			} break;
			
			case 2: { //Font Sprites
				var spr_ = get_font(name_);
				if ( spr_ != -1 ) { return spr_; } else {
					if ( name_ != "" ) {
						if ( !struct_exists(global.fonts_dict, name_) ) { global.fonts_dict[$ name_] = {}; } //Create new struct font dictionary
						var imgnum = string_between(fname_, "_strip", ".png"); imgnum = imgnum == "" ? 1 : imgnum; //Get the image number if it's a strip file
						global.fonts_dict[$ name_] = { sprite: sprite_add(fpath_, imgnum, false, false, 0, 0), name: name_, fname_: filename_name(fpath_), count: imgnum, }
						with ( global.fonts_dict[$ name_] ) {
							self[$ "NEW SPRITE"] = true; self[$ "NEW EXTERNALLY"] = true;//Mark the sprite as new and added externally
							array_push(global.fonts_dict_list, name_); //Add custom font to array list
							array_push(global.fonts_dict_list_custom, name_); //Add custom font to array list
							self[$ "font"] = font_add_sprite(sprite, ord("!"), false, 0); //Add as an actual font
							self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; font_delete(font); delete font; font = -1; show_debug_message($"External font \"{fname_}\"({name}) was destroyed and freed from memory successfully!"); } //Add a destroy func so we don't get memory leaks
							self[$ "size"] = { sprite, width: sprite_get_width(sprite), height: sprite_get_height(sprite), }
						
							global.fonts_dict_alt[$ name] = { sprite, font, name, } //Add sprite index and expression name to the global icon alt dictonary
							var getfont = asset_get_name(sprite);
						
							scribble_font_rename(getfont, name); //Let us use the font's filename instead of whatever name gamemaker generated for us
							scribble_font_bake_outline_and_shadow(name, $"{name}_s", 0, 0, SCRIBBLE_OUTLINE.NO_OUTLINE, 0, false);
							scribble_font_bake_outline_and_shadow(name, $"{name}_outline", 0, 0, SCRIBBLE_OUTLINE.EIGHT_DIR, 0, false);
							scribble_font_delete(name); scribble_font_rename($"{name}_s", name);
							scribble_glyph_set($"{name}_outline", all, SCRIBBLE_GLYPH.FONT_HEIGHT, scribble_glyph_get(name, "W", SCRIBBLE_GLYPH.FONT_HEIGHT));
							var out_ = $"Added \"{name}\"|You can now use|[{name}]|to reference the font!|The command was copied to your clipboard.";
							TweenScript(SYSTEMUI, 0, 2, soupy_message, out_, , , , , snd_sparkle2);
							clipboard_set_text($"[{name}]");
							return font;
						}
					}
					else { 
						TweenScript(SYSTEMUI, 0, 5, function (fpath_ = "") {
							var out_ = $"Tried to load a sprite with an invalid filename|({fpath_})! Skipped...|Make sure you properly name your files! (No numbers besides _stripN.png)";
							soupy_message(out_, "Oh no!", , 135, , snd_error, fnt_abaddon, function () { SYSTEMUI.file_dragging = false; }, SYSTEMUI.ui_paused);
						}, fpath_); return -1;
					}
				}
			} break;
		}
	}
	
	///@desc Function for choosing an externally added face
	//This code is a fucking mess of workarounds.
	function external_choose_face(multiple_ = false, inputsoup_ = "datainput", inputglobal_ = true, imagesoup_ = "dataimage", imageglobal_ = true, clear_ = true) {
		var options_ = [], options_names = struct_get_names(global.faces_dict), options_len = array_length(options_names), options_i = 0;
		repeat ( options_len ) { //Add available characters to an array
			var cur_ = options_names[options_i], isnew_ = global.faces_dict[$ cur_][$ "NEW SPRITE"];
			var face_ = struct_get_names(global.faces_dict[$ cur_]); face_ = get_face(cur_) == -1 ? face_[irandom(array_length(face_) - 1)] : cur_;
			array_push(options_, 
				new LuiRow().setFlexGrow(1).centerContent().setData("name", cur_).addContent([
					new LuiText({ value: isnew_ != undefined && isnew_ ? $"{string_upper_first(cur_)} (NEW!)" : string_upper_first(cur_), id_: cur_, font: fnt_speech, text_halign: fa_center, auto_height: false, height: 70, text_valign: fa_middle, color: ( get_face(cur_) != -1 ? c_cyan : c_white ), }).setPadding(5).setData("chara", cur_).setTooltip(get_face(cur_) != -1 ? $"[{cur_},0,0.15] [rainbow]Unique and recent!" : "", true, , true)
						.setData("inputsoup_", inputsoup_).setData("inputglobal_", inputglobal_).setData("imagesoup_", imagesoup_).setData("imageglobal_", imageglobal_).setData("clear_", clear_)
						.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
						.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = get_face(element_.params.id_) != -1 ? c_cyan : c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
						.addEvent(LUI_EV_CLICK, function(element_) { //Once clicked on, create new scroll panel and populate it with face sprites
							var get_ = soup_checkout("scrollmain", false); soup_checkout("scrollsub", false).destroy(); 
							global.faces_dict[$ element_.params.id_][$ "NEW SPRITE"] = false; sfx_play(snd_select);
							//Exit early if the sprite already exists(for external sprites added through drag & drop)
							var early_ = get_face(element_.params.id_); if ( sprite_exists(early_) ) { sfx_play(snd_updated); if ( element_.getData("clear_") ) { FACE_CURRENT = early_; FACE_ORIGINAL = FACE_CURRENT; } soup_checkout(element_.getData("inputsoup_"), false, element_.getData("inputglobal_")).set(element_.params.id_); soup_checkout(element_.getData("imagesoup_"), false, element_.getData("imageglobal_")).set(early_); soup_checkout("datafunc", false)(); exit; }
					
							var spr_ = [], cur_ = element_.getData("chara"), spr_exp = struct_get_names(global.faces_dict[$ cur_]), spr_len = array_length(spr_exp), spr_i = 0; //Folders filled with sprites will have their sprites shown here
							repeat ( spr_len ) {
								var exp_ = spr_exp[spr_i], finalname = $"spr_{cur_}_{exp_}", myspr = get_face(finalname);
								if ( exp_ != "NEW SPRITE" ) {
									array_push(spr_, new LuiImageButton({ value: myspr, draw_normal: true, }).setSize(sprite_get_width(myspr), sprite_get_height(myspr)).setData("face", myspr).setData("facename", finalname).setFlexAlignSelf(flexpanel_align.center).setTooltip($"{finalname}\n[face,{finalname}]", true)
									.setData("inputsoup_", element_.getData("inputsoup_")).setData("inputglobal_", element_.getData("inputglobal_")).setData("imagesoup_", element_.getData("imagesoup_")).setData("imageglobal_", element_.getData("imageglobal_")).setData("clear_", element_.getData("clear_"))
									.addEvent(LUI_EV_CLICK, function(element_) { sfx_play(snd_updated); if ( element_.getData("clear_") ) { FACE_CURRENT = element_.getData("face"); FACE_ORIGINAL = FACE_CURRENT; FACE_INTERNAL = element_.getData("facename"); } soup_checkout(element_.getData("inputsoup_"), false, element_.getData("inputglobal_")).set(element_.getData("facename")); soup_checkout(element_.getData("imagesoup_"), false, element_.getData("imageglobal_")).set(element_.getData("face")); soup_checkout("datafunc", false)(); })
									.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { if ( sprite_get_number(element_.get()) > 1 ) { element_.imgspd = 0.15; } }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.imgspd = 0; element_.subimg = 0; })
									);
								}
							spr_i++; }
					
							#region Sort Names Alphabetically
								array_sort(spr_, function(arrcur_, arrnext_) {
									if ( string_lower(arrcur_.value) < string_lower(arrnext_.value) ) { return -1; }
									else if ( string_lower(arrcur_.value) > string_lower(arrnext_.value) ) { return 1; }
									else { return 0; }
								});
							#endregion
							get_.addContent(new LuiScrollPanel({ height: 400, scroll_pin_edge_offset:10, sprite_panel: false, sound_right: snd_throw, }).addContent(spr_).addEvent(LUI_EV_CREATE, function(element_) { soup_store("scrollsub", element_); })); //Add new panel and stash it so we can destroy it later
						}), new LuiImage({ value: get_face(cur_, face_), draw_normal: true, width: 70, height: 70 }),
				])
			);
		options_i++; }
		
		#region Sort Names Alphabetically
			array_sort(options_, function(arrcur_, arrnext_) {
				if ( string_lower(arrcur_.getData("name")) < string_lower(arrnext_.getData("name")) ) { return -1; }
				else if ( string_lower(arrcur_.getData("name")) > string_lower(arrnext_.getData("name")) ) { return 1; }
				else { return 0; }
			});
		#endregion
		
		#region Add Default Options
			array_push(options_, new LuiText({ value: "Test Face", font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, }).setPadding(5)
				.setData("inputsoup_", inputsoup_).setData("inputglobal_", inputglobal_).setData("imagesoup_", imagesoup_).setData("imageglobal_", imageglobal_).setData("clear_", clear_)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) { sfx_play(snd_updated); if ( element_.getData("clear_") ) { FACE_CURRENT = spr_face_test; FACE_ORIGINAL = FACE_CURRENT; } soup_checkout(element_.getData("inputsoup_"), false, element_.getData("inputglobal_")).set("spr_face_test"); soup_checkout(element_.getData("imagesoup_"), false, element_.getData("imageglobal_")).set(element_.getData("face")); soup_checkout("datafunc", false)();})
			);
			array_push(options_, new LuiText({ value: "Blank Page Face", font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, }).setPadding(5)
				.setData("inputsoup_", inputsoup_).setData("inputglobal_", inputglobal_).setData("imagesoup_", imagesoup_).setData("imageglobal_", imageglobal_).setData("clear_", clear_)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) { sfx_play(snd_updated); if ( element_.getData("clear_") ) { FACE_CURRENT = spr_face_blank; FACE_ORIGINAL = FACE_CURRENT; } soup_checkout(element_.getData("inputsoup_"), false, element_.getData("inputglobal_")).set("spr_face_blank"); soup_checkout(element_.getData("imagesoup_"), false, element_.getData("imageglobal_")).set(element_.getData("face")); soup_checkout("datafunc", false)(); })
			);
			if ( !is_wasm() ) { array_push(options_, new LuiText({ value: "Add From File... [->]", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_yellow, }).setPadding(5).addEvent(LUI_EV_CREATE, function (e_) { if ( is_android() ) { soup_store("element_", e_, , true); } })
				.setData("inputsoup_", inputsoup_).setData("inputglobal_", inputglobal_).setData("imagesoup_", imagesoup_).setData("imageglobal_", imageglobal_).setData("clear_", clear_)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) { 
					if ( !is_android() ) { 
						var result = get_open_filename_ext("Image File (.PNG Only) or Zip|*.png;*.zip", "", directory_get_pictures_path(), "Select a sprite to import.");
						if ( result == -1 || result == "" ) { exit; }
						sfx_play(snd_equip);
						var myname_, myext_ = string_lower(filename_ext(result));
						if ( myext_ == ".zip" ) {
							if ( soupy_zip_begin(result) ) { sfx_play(snd_chest); soup_checkout("datafunc", false)(); }
							exit;
						} else { myname_ = string_exclude(string_replace(string_replace(filename_name(result), "_strip", ""), ".png", ""), "0123456789"); result = external_ensure(myname_, filename_name(result), result, , SYSTEMUI.ui_tab == 0 ? true : false); }
						if ( element_.getData("clear_") ) { FACE_CURRENT = result; FACE_ORIGINAL = FACE_CURRENT; } 
						soup_checkout(element_.getData("inputsoup_"), false, element_.getData("inputglobal_")).set(myname_); 
						soup_checkout(element_.getData("imagesoup_"), false, element_.getData("imageglobal_")).set(result);
						soup_checkout("datafunc", false)();
					}
					else { sfx_play(snd_equip); soup_store("asynctype", "face", , true); TweenScript(SYSTEMUI, 0, 30, function () { MobileUtils_Gallery_Open_PNG(); }); }
				})
			); 
			array_push(options_, new LuiText({ value: "Add From URL... [^]", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_cyan, }).setPadding(5)
				.setData("inputsoup_", inputsoup_).setData("inputglobal_", inputglobal_).setData("imagesoup_", imagesoup_).setData("imageglobal_", imageglobal_).setData("clear_", clear_)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_cyan; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) {
						var arr_ = [
						new LuiText({ value: "Enter the URL. The URL must end in \".png\".", text_halign: fa_center, text_valign: fa_middle, font: fnt_abaddon, color: c_white, xoff: 0, y: 10 }),
						new LuiInput({ height: 40, max_length: undefined, offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).addEvent(LUI_EV_CREATE, function(e_) { soup_store("label", e_, , true); }),
						new LuiButton({ text: "Download Image!", height: 40, }).addEvent(LUI_EV_CLICK, function () { 
							var result = soup_checkout("label", false, true).get();
							if ( string_trim(string_lettersdigits(result)) == "" ) { soupy_message("You cannot have a|blank or invalid URL.", , 270, , , snd_error, , , true); exit; }
				
							http(result, , , { get_file: true }, function (_, result) { //Success!
								var temp_ = soup_checkout("label", false, true).get(); //Get URL
								var fname_ = filename_name(temp_); //Get the filename of the URL (just the .png part)
								buffer_save(result, fname_); //Temp save file
								var myname_ = string_exclude(string_replace(string_replace(fname_, "_strip", ""), ".png", ""), "0123456789"); spr_ = external_ensure(myname_, fname_, fname_, , false); //Add file
								soup_checkout("mainui2", false, true).destroy();
								soup_checkout("datafunc", false)();
								file_delete(fname_);
							}, function () { //Failure!
								soupy_popup("Couldn't download image.", , "OK", , , , snd_error, fnt_abaddon, true);
							});
						}),
					];
		
					var mainui2 = soupy_popup(arr_, , "Cancel", , , , snd_dimbox, fnt_abaddon, true); soup_store("mainui2", mainui2, , true);
				})
			); }
			else {
				array_push(options_, new LuiText({ value: "About Custom Sprites...", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_cyan, }).setPadding(5)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_cyan; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) {
						soupy_message("Due to [c_red]Cross-Origin Resource Sharing(CORS)[/], this feature|[shake]isn't available on the web build.[/]|Consider switching to the [c_y]Windows or Android build[/] instead,|or use Wine to run SoupGen on Mac or Linux.|[wheel]Sorry![/]", "That's so unfair... fuck browsers dude.", , , , snd_error, fnt_abaddon, , true, true);
					})
			); }
			array_push(options_, new LuiText({ value: "Clear Page Face", font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_red, }).setPadding(5)
				.setData("inputsoup_", inputsoup_).setData("inputglobal_", inputglobal_).setData("imagesoup_", imagesoup_).setData("imageglobal_", imageglobal_).setData("clear_", clear_)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_red; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) { sfx_play(snd_hurtpowerful); if ( element_.getData("clear_") ) { FACE_CURRENT = -1; FACE_ORIGINAL = FACE_CURRENT; } soup_checkout(element_.getData("inputsoup_"), false, element_.getData("inputglobal_")).set(-1); soup_checkout(element_.getData("imagesoup_"), false, element_.getData("imageglobal_")).set(""); soup_checkout("datafunc", false)(); })
			);
		#endregion

		var dataarr = [
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiScrollPanel({ height: 400, scroll_pin_edge_offset:10, sprite_panel: false, sound_right: snd_throw, }).addContent(options_),
				new LuiText({ value: $"Select a character!\n\nFaces will show up once\nselected. Then scroll to\nfind the perfect sprite\nfor your dialogue!\n\nThis only adds a face for\nthe current dialogue page.", auto_width: false, auto_height: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_center, }).addEvent(LUI_EV_CREATE, function(element_) { soup_store("scrollsub", element_); }),
			]).addEvent(LUI_EV_CREATE, function(element_) { soup_store("scrollmain", element_); }), //Stash panel so we can add another panel to this row
		];

		soup_store("datafunc", method({ clear_, }, function() { soup_checkout("choosemain", false).destroy(); FACE_INDEX = clamp(FACE_INDEX, 0, sprite_get_number(FACE_CURRENT) - 1); if ( clear_ ) { soup_store_clear(); SYSTEMUI.ui_paused = false; } }));
		var maincan = soupy_popup(dataarr, method({ clear_ }, function() { if ( clear_ ) { soup_store_clear(); FACE_INDEX = clamp(FACE_INDEX, 0, sprite_get_number(FACE_CURRENT) - 1); SYSTEMUI.ui_paused = false; } }), "Nevermind", , , , , , multiple_, 2); soup_store("choosemain", maincan); 
	}
	
	///@desc Function for choosing an externally added border
	function external_choose_border() {
		#region Add All Borders
			var options_ = [], bords_ = tag_get_assets("borders"), bords_len = array_length(bords_), bords_i = 0;
				repeat ( bords_len ) {
					var cur_ = bords_[bords_i], myspr = get_border(asset_get_index(cur_)), myname = get_border(asset_get_index(cur_), "name");
					array_push(options_,
						new LuiImageButton({ value: myspr, maintain_aspect: false, id_: string_letters(myname) != "" ? myname : sprite_get_name(myname), isnew: false,
							show_frame: true, frame_sprite: spr_border_header, frame_color: SYSTEMUI.ui_surface_high, frame_inset: 5, }).setSize(82, 82).setFlexAlignSelf(flexpanel_align.center)
						.addEvent(LUI_EV_MOUSE_ENTER, function(e_) {
							if ( sprite_get_number(e_.get()) > 1 ) { e_.imgspd = 0.15; }
							var preview_ = soup_checkout("border_choice_preview", false), details_ = soup_checkout("border_choice_details", false);
							if ( !is_undefined(preview_) ) { preview_.setSprite(e_.get()); }
							if ( !is_undefined(details_) ) { details_.setText($"{e_.params.id_}\n\nClick to use this border."); }
						}).addEvent(LUI_EV_MOUSE_LEAVE, function(e_) { e_.imgspd = 0; e_.subimg = 0; })
					.addEvent(LUI_EV_CREATE, function(e_) { 
						var myname = e_.params.id_, result = get_border(myname, "NEW SPRITE"), text_ = $"[border,{myname}]";
						if ( asset_get_index(result) == -1 ) { e_.params.isnew = ( result != undefined && result ) ? true : false; if ( e_.params.isnew ) { text_ = $"[border,{myname}] (NEW!)"; } }
						e_.setTooltip(text_);
					})
					.addEvent(LUI_EV_CLICK, function(e_) { 
						var myname = e_.params.id_, bord_ = global.bords_dict[$ myname];
						if ( !is_undefined(bord_) ) { bord_[$ "NEW SPRITE"] = false; }
						sfx_play(snd_updated); soup_checkout("datainputB", false, true).set(myname); soup_checkout("dataimageB", false, true).set(e_.get()); soup_checkout("datafunc", false)();
						 if ( sprite_get_number(e_.get()) > 1 && SYSTEMUI.bord_spd == 0 ) { SYSTEMUI.bord_spd = 0.15; }
					})
				);
			bords_i++; }
		#endregion
		
		#region Add Default Options
			if ( !is_wasm() ) { array_push(options_, new LuiText({ value: "Add From File... [->]", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_yellow, }).setPadding(5).addEvent(LUI_EV_CREATE, function (e_) { if ( is_android() ) { soup_store("element_", e_, , true); } })
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) { 
					if ( !is_android() ) {
						var result = get_open_filename_ext("Image File (.PNG Only)|*.png", "", directory_get_pictures_path(), "Select a sprite to import."), myname_;
						if ( result == -1 || result == "" ) { exit; }
						sfx_play(snd_equip);
						myname_ = string_exclude(string_replace(string_replace(filename_name(result), "_strip", ""), ".png", ""), "0123456789"); result = external_ensure(myname_, filename_name(result), result, 1, false);
						SYSTEMUI.spr_bord = result; SYSTEMUI.bord_name = myname_; SYSTEMUI.bord_prev = SYSTEMUI.spr_bord;
						sfx_play(snd_updated); soup_checkout("datainputB", false, true).set(myname_); soup_checkout("dataimageB", false, true).set(result); soup_checkout("datafunc", false)();
					}
					else { soup_store("asynctype", "border", , true); TweenScript(SYSTEMUI, 0, 30, function () { MobileUtils_Gallery_Open_PNG(); }); }
				})
			); 
			
			array_push(options_, new LuiText({ value: "Add From URL... [^]", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_cyan, }).setPadding(5)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_cyan; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) {
						var arr_ = [
						new LuiText({ value: "Enter the URL. The URL must end in \".png\".", text_halign: fa_center, text_valign: fa_middle, font: fnt_abaddon, color: c_white, xoff: 0, y: 10 }),
						new LuiInput({ height: 40, max_length: undefined, offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).addEvent(LUI_EV_CREATE, function(e_) { soup_store("label", e_, , true); }),
						new LuiButton({ text: "Download Image!", height: 40, }).addEvent(LUI_EV_CLICK, function () { 
							var result = soup_checkout("label", false, true).get();
							if ( string_trim(string_lettersdigits(result)) == "" ) { soupy_message("You cannot have a|blank or invalid URL.", , 270, , , snd_error, , , true); exit; }
				
							http(result, , , { get_file: true }, function (_, result) { //Success!
								var temp_ = soup_checkout("label", false, true).get(); //Get URL
								var fname_ = filename_name(temp_); //Get the filename of the URL (just the .png part)
								buffer_save(result, fname_); //Temp save file
								var myname_ = string_exclude(string_replace(string_replace(fname_, "_strip", ""), ".png", ""), "0123456789"); spr_ = external_ensure(myname_, fname_, fname_, 1, false); //Add file
								soup_checkout("mainui2", false, true).destroy();
								soup_checkout("datafunc", false)();
								file_delete(fname_);
							}, function () { //Failure!
								soupy_popup("Couldn't download image.", , "OK", , , , snd_error, fnt_abaddon, true);
							});
						}),
					];
		
					var mainui2 = soupy_popup(arr_, , "Cancel", , , , snd_dimbox, fnt_abaddon, true); soup_store("mainui2", mainui2, , true);
				})
			); }
			else {
				array_push(options_, new LuiText({ value: "About Custom Sprites...", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_cyan, }).setPadding(5)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_cyan; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) {
						soupy_message("Due to [c_red]Cross-Origin Resource Sharing(CORS)[/], this feature|[shake]isn't available on the web build.[/]|Consider switching to the [c_y]Windows or Android build[/] instead,|or use Wine to run SoupGen on Mac or Linux.|[wheel]Sorry![/]", "That's so unfair... fuck browsers dude.", , , , snd_error, fnt_abaddon, , true, true);
					})
			); }
		#endregion
		
		var current_border_name_ = sprite_exists(SYSTEMUI.spr_bord) ? sprite_get_name(SYSTEMUI.spr_bord) : "Current border";
		var dataarr = [
			new LuiText({ value: "Choose a dialogue border", height: 28, auto_width: false, auto_height: false, font: fnt_determination, text_halign: fa_center, text_valign: fa_middle, }),
			new LuiRow({ height: 330, }).setFlexGrow(1).setGap(10).addContent([
				new LuiScrollPanel({ width: 260, height: 330, scroll_pin_edge_offset: 8, sprite_panel: true, sound_right: snd_throw, }).addContent(options_),
				new LuiPanel({ width: 280, height: 330, }).setPadding(12).setGap(10).centerContent().addContent([
					new LuiText({ value: "Preview", height: 24, auto_width: false, auto_height: false, font: fnt_determination, color: SYSTEMUI.ui_mutedcolor, text_halign: fa_center, text_valign: fa_middle, }),
					new LuiImage({ value: SYSTEMUI.spr_bord, maintain_aspect: true, }).setSize(220, 150).addEvent(LUI_EV_CREATE, function(e_) { soup_store("border_choice_preview", e_); }),
					new LuiText({ value: $"{current_border_name_}\n\nHover a border to preview it.", width: 220, height: 90, auto_width: false, auto_height: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, }).addEvent(LUI_EV_CREATE, function(e_) { soup_store("border_choice_details", e_); }),
				]),
			]).addEvent(LUI_EV_CREATE, function(element_) { soup_store("scrollmain", element_); }),
		];
		
		soup_store("datafunc", function() { soup_checkout("choosemain", false).destroy(); soup_store_clear(); SYSTEMUI.ui_paused = false; });
		var maincan = soupy_popup(dataarr, function() { soup_store_clear(); SYSTEMUI.ui_paused = false; }, "Close", , , , , , , 2, 32); soup_store("choosemain", maincan);
	}
	
	///@desc Function for choosing an externally added font
	function external_choose_font() {
		#region Add bundled fonts
			var custom_ = is_undefined(soup_checkout("customfonts", false, true));
			var options_ = [], fonts_len = array_length((!custom_ ? global.fonts_dict_list_custom : global.fonts_dict_list)), fonts_i = 0;
			repeat ( fonts_len ) {
				var get_ = (!custom_ ? global.fonts_dict_list_custom : global.fonts_dict_list);
				var cur_ = get_[fonts_i];
				options_[fonts_i] = new LuiText({ value: $"{cur_} (AaBbCc)", id_: cur_, font: cur_, text_halign: fa_center, text_valign: fa_middle, color: c_white, isnew: false, scribbletext: true, }).setData("customs", custom_)
					.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.value = $"[wheel]{element_.value}"; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
					.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = element_.color_o; element_.value = string_replace(element_.value, "[wheel]", ""); element_.main_ui.animate(element_, "xoff", 0, 0.15); })
					.addEvent(LUI_EV_CLICK, function(e_) { 
						var myname = e_.params.id_, fonts_ = global.fonts_dict[$ myname];
						var custom_ = e_.getData("customs");
						if ( !is_undefined(fonts_) ) { fonts_[$ "NEW SPRITE"] = false; } sfx_play(snd_select);
						if ( custom_ ) { soup_checkout(SYSTEMUI.ui_tab != 4 ? "datainputS" : "datainputbox", false, true).set(myname); soup_checkout(SYSTEMUI.ui_tab != 4 ? "datafont" : "datafontbox", false, true).font = myname; }
						else { soup_checkout(soup_checkout("getfont", false, true), false, true).font = myname; }
						soup_checkout("datafunc", false)();
					})
					.addEvent(LUI_EV_CREATE, function(e_) { 
						var result = global.fonts_dict[$ e_.params.id_]; 
						e_.isnew = ( result != undefined && result[$ "NEW SPRITE"] != undefined && result[$ "NEW SPRITE"] ); if ( e_.isnew ) { e_.value = $"{e_.value} (NEW!)"; }
						if ( result != undefined && result[$ "NEW EXTERNALLY"] != undefined ) { e_.color = c_cyan; e_[$ "color_o"] = c_cyan; e_.setTooltip("[rainbow]Unique and recent!", true, , true); } else { e_[$ "color_o"] = c_white; }
					})
			fonts_i++; }
		#endregion
		
		#region Sort Names Alphabetically
			array_sort(options_, function(arrcur_, arrnext_) {
				if ( string_lower(arrcur_.value) < string_lower(arrnext_.value) ) { return -1; }
				else if ( string_lower(arrcur_.value) > string_lower(arrnext_.value) ) { return 1; }
				else { return 0; }
			});
		#endregion
		
		#region Add Default Options
			if ( !is_wasm() ) { array_push(options_, new LuiText({ value: "Add From File... [->]", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_yellow, }).setPadding(5).setData("customs", custom_).addEvent(LUI_EV_CREATE, function (e_) { if ( is_android() ) { soup_store("element_", e_, , true); } })
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) { 
					if ( !is_android() ) { 
						var result = get_open_filename_ext("GameMaker Strip (_strip#.PNG Only)|*.png", "", directory_get_pictures_path(), "Select a spritefont to import."), myname_;
						if ( result == -1 || result == "" ) { exit; }
						sfx_play(snd_equip);
						myname_ = string_exclude(string_replace(string_replace(string_replace(filename_name(result), "spr_", ""), "_strip", ""), ".png", ""), "0123456789"); result = external_ensure(myname_, filename_name(result), result, 2, false);
						if ( result == -1 || result == "" ) { result = "fnt_determination"; myname_ = result; }
						var custom_ = element_.getData("customs");
						if ( custom_ ) { soup_checkout(SYSTEMUI.ui_tab != 4 ? "datainputS" : "datainputbox", false, true).set(myname_); soup_checkout(SYSTEMUI.ui_tab != 4 ? "datafont" : "datafontbox", false, true).font = myname_; sfx_play(snd_updated); }
						else { soup_checkout(soup_checkout("getfont", false, true), false, true).font = myname_; }
						soup_checkout("datafunc", false)();
					}
					else { soup_store("asynctype", "font", , true); TweenScript(SYSTEMUI, 0, 30, function () { MobileUtils_Gallery_Open_PNG(); }); }
				})
			); 
			
			array_push(options_, new LuiText({ value: "Add From URL... [^]", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_cyan, }).setPadding(5)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_cyan; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) {
						var arr_ = [
						new LuiText({ value: "Enter the URL. The URL must end in \".png\".", text_halign: fa_center, text_valign: fa_middle, font: fnt_abaddon, color: c_white, xoff: 0, y: 10 }),
						new LuiInput({ height: 40, max_length: undefined, offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).addEvent(LUI_EV_CREATE, function(e_) { soup_store("label", e_, , true); }),
						new LuiButton({ text: "Download Image!", height: 40, }).addEvent(LUI_EV_CLICK, function () { 
							var result = soup_checkout("label", false, true).get();
							if ( string_trim(string_lettersdigits(result)) == "" ) { soupy_message("You cannot have a|blank or invalid URL.", , 270, , , snd_error, , , true); exit; }
				
							http(result, , , { get_file: true }, function (_, result) { //Success!
								var temp_ = soup_checkout("label", false, true).get(); //Get URL
								var fname_ = filename_name(temp_); //Get the filename of the URL (just the .png part)
								buffer_save(result, fname_); //Temp save file
								var myname_ = string_exclude(string_replace(string_replace(fname_, "_strip", ""), ".png", ""), "0123456789"); spr_ = external_ensure(myname_, fname_, fname_, 2, false); //Add file
								soup_checkout("mainui2", false, true).destroy();
								soup_checkout("datafunc", false)();
								file_delete(fname_);
							}, function () { //Failure!
								soupy_popup("Couldn't download image.", , "OK", , , , snd_error, fnt_abaddon, true);
							});
						}),
					];
		
					var mainui2 = soupy_popup(arr_, , "Cancel", , , , snd_dimbox, fnt_abaddon, true); soup_store("mainui2", mainui2, , true);
				})
			); }
			else {
				array_push(options_, new LuiText({ value: "About Custom Sprites...", truncate: false, font: fnt_speech, text_halign: fa_center, text_valign: fa_middle, color: c_cyan, }).setPadding(5)
				.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_orange; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
				.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_cyan; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
				.addEvent(LUI_EV_CLICK, function(element_) {
						soupy_message("Due to [c_red]Cross-Origin Resource Sharing(CORS)[/], this feature|[shake]isn't available on the web build.[/]|Consider switching to the [c_y]Windows or Android build[/] instead,|or use Wine to run SoupGen on Mac or Linux.|[wheel]Sorry![/]", "That's so unfair... fuck browsers dude.", , , , snd_error, fnt_abaddon, , true, true);
					})
			); }
		#endregion
		
		var dataarr = [
			new LuiColumn().setFlexGrow(1).centerContent().addContent([
				new LuiScrollPanel({ height: 360, sprite_panel: false, sound_right: snd_throw, }).addContent(options_),
				new LuiText({ value: $"Select a dialogue font! This is the style your dialogue text\nwill be rendered with. Find your perfect font to use!", auto_width: false, auto_height: false, y: -10, font: fnt_speech, text_halign: fa_center, text_valign: fa_center, }).addEvent(LUI_EV_CREATE, function(element_) { soup_store("scrollsub", element_); }),
			]).addEvent(LUI_EV_CREATE, function(element_) { soup_store("scrollmain", element_); }), //Stash panel so we can add another panel to this row
		];
		
		soup_store("datafunc", function() { soup_checkout("choosemain", false).destroy(); soup_store_clear(); if ( is_undefined(soup_checkout("customfonts", false, true)) ) { SYSTEMUI.ui_paused = false; } });
		var maincan = soupy_popup(dataarr, function() { soup_store_clear(); if ( is_undefined(soup_checkout("customfonts", false, true)) ) { SYSTEMUI.ui_paused = false; } }, "Nevermind", , , , , , !custom_, 2); soup_store("choosemain", maincan); 
	}
	
	///@desc Function for editing the spacing between fonts
	function external_edit_fonts() {
		var dataarr = [
			new LuiText({ value: $"Tweak the spacing between letters for your custom font.", y: -10, font: fnt_speech, text_halign: fa_center, text_valign: fa_center, }),
			new LuiRow().setFlexGrow(1).centerContent().addContent([ //Choosing a sprite
				new LuiText({ value: "Font:", width: 65, text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Custom fonts only.", true, , true),
				new LuiButton({ text: "Choose...", height: 40, width: 100, }).addEvent(LUI_EV_CLICK, external_choose_font),
				new LuiText({ value: "AaBbCc", width: 100, text_halign: fa_center, text_valign: fa_middle, font: "fnt_speech", scribbletext: true, }).addEvent(LUI_EV_CREATE, function(e_) { soup_store("datafontcustom", e_, , true); })
				.addEvent(LUI_EV_MOUSE_LEFT_PRESSED, function(element_) { element_.main_ui.animate(element_, "yoff", 0, 1, global.Ease.OutElastic, 10); sfx_play(snd_squish); })
			]),
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Separation:", width: 140, text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }),
				new LuiInput({ value: "14", height: 40, placeholder: "123456", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, input_mode: LUI_INPUT_MODE.numbers, max_length: 2, })
				.addEvent(LUI_EV_CREATE, function(e_) { soup_store("sep", e_, , true); }),
			]),
			new LuiButton({ text: "Make changes!", height: 40, }).addEvent(LUI_EV_CLICK, function () { 
				var font_ = soup_checkout("datafontcustom", false, true).font, result = soup_checkout("sep", , true).get(), value = result == "" ? 14 : real(result);
				if ( font_ != "fnt_speech" ) {
					scribble_glyph_set(font_, all, SCRIBBLE_GLYPH.SEPARATION, value);
					scribble_glyph_set($"{font_}_outline", all, SCRIBBLE_GLYPH.SEPARATION, value);
					scribble_refresh_everything();
					soup_checkout("datafunccustomfonts", , true)(); sfx_play(snd_sparkle);
				}
				else { soupy_message("You haven't selected any|custom font for editing.", , 300, , , snd_error, , , true); }
			}),
		];
		soup_store("customfonts", , , true); soup_store("getfont", "datafontcustom", , true);
		soup_store("datafunccustomfonts", function() { soup_checkout("choosemaincustomfonts", false, true).destroy(); soup_store_clear(); soup_checkout("customfonts", , true); soup_checkout("getfont", , true); SYSTEMUI.ui_paused = false; }, , true);
		var maincan = soupy_popup(dataarr, function() { soup_store_clear(); soup_checkout("customfonts", , true); soup_checkout("getfont", , true); SYSTEMUI.ui_paused = false; }, "Nevermind", , , , , , , 2); soup_store("choosemaincustomfonts", maincan, , true); 
	}
		
	function external_choose_mini(face_ = -1, index_ = 0, text_ = "Text", font_ = "fnt_determination", smooth_ = false, x_ = -1, y_ = -1, id_ = -1, name_ = "", speed_ = 0, stick_ = false) {
		soup_store("minisprite", face_ != -1 ? name_ : face_); soup_store("miniindex", index_); soup_store("minispd", speed_); soup_store("minitext", text_); soup_store("minianim", smooth_); soup_store("minifont", font_); soup_store("ministick", stick_);
		var miniarr = [
			new LuiText({ value: ( id_ == -1 ? "Create a mini speech bubble!" : "Edit current mini speech bubble." ), text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Mini speeches are the tiny thought bubbles\nSusie and Ralsei sometimes say."),
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Sprite:", width: 100, text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }),
				new LuiButton({ text: "Choose...", height: 40, width: 100, }).addEvent(LUI_EV_CLICK, function(element_) { external_choose_face(true, , false, , false, false); }),
				new LuiInput({ value: soup_checkout("minisprite", false), height: 40, placeholder: "spr_face_test", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).bindVariable(global.soupstore, "minisprite").addEvent(LUI_EV_CREATE, function(e_) { soup_store("datainput", e_); }).addEvent(LUI_EV_VALUE_UPDATE, function(e_) { 
					var spr_ = soup_checkout("dataimage", false), getface = get_face(e_.get());
					spr_.set(getface == -1 ? spr_gui_icons : getface); spr_.subimg = ( getface == -1 ? 3 : 0 );
				}),
				new LuiImage({ value: spr_gui_icons, subimg: 3, draw_normal: true, }).setSize(70, 70).addEvent(LUI_EV_CREATE, function(e_) { var mini_ = soup_checkout("minisprite", false); soup_store("dataimage", e_); e_.set(mini_ == -1 ? spr_gui_icons : get_face(mini_)); }),
			]),
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Frame:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("The frame this sprite will be on."),
				new LuiInput({ value: soup_checkout("miniindex", false), width: 20, placeholder: "123456", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, input_mode: LUI_INPUT_MODE.numbers, }).setPadding(20).bindVariable(global.soupstore, "miniindex").addEvent(LUI_EV_VALUE_UPDATE, function(e_) { 
					var spr_ = soup_checkout("dataimage", false), value = e_.get(); if ( spr_.value != spr_gui_icons ) { spr_.subimg = real(value == "" ? 0 : value); }
				}),
				
				new LuiText({ value: "Speed:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Animation speed for the sprite."),
				new LuiInput({ placeholder: "123456", offset: 12, width: 60, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20).bindVariable(global.soupstore, "minispd")
				.addEvent(LUI_EV_SHOW, function(e_) { e_.set(soup_checkout("minispd", false)); }).addEvent(LUI_EV_VALUE_UPDATE, function(e_) { 
					var spr_ = soup_checkout("dataimage", false), value = e_.get(); if ( spr_.value != spr_gui_icons ) { var spd_ = real_ext(value); if ( spd_ == "" ) { spd_ = 0; } spr_.imgspd = spd_; }
				}),
				
				new LuiText({ value: "Smooth:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Whether this mini speech should\nsmoothly move to the left."),
				new LuiToggleSwitch({ value: soup_checkout("minianim", false), checkbox_spr: spr_gui_icons, checkbox_spr_index: 6, checkbox_clr: c_white, sound_click: snd_bump, sound_click_pitch: 1.3, ease: global.Ease.OutBack, }).bindVariable(global.soupstore, "minianim").setWidth(50),
				
				new LuiText({ value: "Sticker:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Whether this mini speech should\nfunction like a sticker and\nshow up instantly.\nCancels Smooth."),
				new LuiToggleSwitch({ value: soup_checkout("ministick", false), checkbox_spr: spr_gui_icons, checkbox_spr_index: 6, checkbox_clr: c_white, sound_click: snd_bump, sound_click_pitch: 1.3, ease: global.Ease.OutBack, }).bindVariable(global.soupstore, "ministick").setWidth(50),
			]),
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Text:", width: 50, text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("You can use commands here!"),
				new LuiInput({ value: soup_checkout("minitext", false), placeholder: "Test text 1, 2, 3.", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20).bindVariable(global.soupstore, "minitext"),
			]),
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Font:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }),
				new LuiInput({ value: soup_checkout("minifont", false), placeholder: "fnt_determination", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20).bindVariable(global.soupstore, "minifont").addEvent(LUI_EV_VALUE_UPDATE, function(e_) {
					var prev_ = soup_checkout("minipreview", false), value = e_.get(); prev_.font = scribble_font_exists(value) ? value : "fnt_determination";
				}),
				new LuiText({ value: "AaBbCc", text_halign: fa_center, text_valign: fa_middle, font: soup_checkout("minifont", false), scribbletext: true, }).addEvent(LUI_EV_CREATE, function(e_) { soup_store("minipreview", e_); }),
			]),
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				
			]),
			new LuiText({ value: "Left Click - Move mini | Right Click (Held) - Delete mini | Double Left Click - Edit mini", color: c_gray, text_halign: fa_center, text_valign: fa_middle, font: fnt_determination_nomono, }),
			new LuiText({ value: "Note: Mini speeches only show up on the current highlighted page and\nwithin the dialogue box.", auto_width: false, auto_height: false, color: c_gray, text_halign: fa_center, text_valign: fa_middle, }),
			new LuiText({ value: "You can drag a face sprite on here too, btw! New sprites are\nimmediately added.", auto_width: false, auto_height: false, color: c_gray, text_halign: fa_center, text_valign: fa_middle, }),
			new LuiText({ value: "Add newline literals(\"\\n\") in your text if you need more room.", auto_width: false, auto_height: false, color: c_gray, text_halign: fa_center, text_valign: fa_middle, }),
			new LuiButton({ text: id_ == -1 ? "Add Mini Speech" : "Save Mini Speech", height: 35, }).setData("xx", x_).setData("yy", y_).setData("id_", id_).addEvent(LUI_EV_CLICK, function(element_) {
				var txt_ = soup_checkout("minitext", false), spr_ = get_face(soup_checkout("minisprite", false)), index_ = soup_checkout("miniindex", false), font_ = soup_checkout("minifont", false), spd_ = soup_checkout("minispd", false), stick_ = soup_checkout("ministick", false);
				var myspd_ = real_ext(spd_); if ( myspd_ == "" ) { myspd_ = 0; }
				//if ( string_lettersdigits(txt_) == "" ) { SYSTEMUI.ui_paused = false; soupy_message("You haven't even written any|dialogue yet!!", "Go Back", 300, , , snd_error, , , true); exit; }
				if ( spr_ == -1 ) { SYSTEMUI.ui_paused = false; soupy_message("Make sure your face sprite|is a valid sprite.", "Go Back", 300, , , snd_error, , , true); exit; }
				if ( string_lettersdigits(font_) == "" ) { font_ = "fnt_determination"; }
									
				var struct_ = { name: soup_checkout("datainput", false).get(), text: txt_, face: spr_, index: index_ == "" ? 0 : real(index_), spd: myspd_, alpha: 1, font: font_, smooth: soup_checkout("minianim", false), page: SYSTEMUI.dial_text_page, sticker: stick_ };
				var x_ = element_.getData("xx"), y_ = element_.getData("yy"), id_ = element_.getData("id_");
				if ( id_ != -1 ) { instance_destroy(id_); sfx_play(snd_updated); }
				instance_create_depth(x_ == -1 ? random_range(30, 310) : x_, y_ == -1 ? random_range(310, 470) : y_, -1, obj_mini, struct_);
				var maincan = soup_checkout("datamain", false);
				soup_store_clear(); SYSTEMUI.ui_paused = false; maincan.destroy();
			}),
		];
		var maincan = soupy_popup(miniarr, function() { soup_store_clear(); SYSTEMUI.ui_paused = false; }, "Nevermind", , , , , , , 2);
		soup_store("datamain", maincan);
	}
	
	///@desc Function for editing the Scribble typewriter animation
	function external_edit_typew() {
		var easeExample = function (stop_ = false) {
			var gettween = soup_checkout("dataease_tween"); if ( gettween != undefined ) { TweenStop(gettween); TweenDestroy(gettween); TweenDestroy(SYSTEMUI); show_debug_message("Tween destroyed"); }
			if ( stop_ ) { SYSTEMUI.soupy_lui.animate(soup_checkout("dataease_soul", false), "yoff", 0, 0, , -80); exit; }
			var func_ = function() { SYSTEMUI.soupy_lui.animate(soup_checkout("dataease_soul", false), "yoff", 0, 1, soup_checkout("dataease_tweenease", false), -80); }
			var tween = TweenFire("?", SYSTEMUI, "$90", "#3", "@continue", func_);
			soup_store("dataease_tween", tween); func_();
		}
		soup_store("dataease_tween func", easeExample);
		var dataarr = [
			new LuiText({ value: "Edit how the typewriter makes text appear!", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }),
			new LuiText({ value: "Instead of characters appearing instantly, you can give characters\nan easing animation to truly customize dialogue to your liking!", text_halign: fa_center, text_valign: fa_middle, color: c_gray, font: fnt_determination, }),
			
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Easing Type:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Sets the easing out algorithm\nthe typewriter will use.\nFor more info, visit:\n[c_yellow]https://easings.net/ (right click me)", true, , true).addEvent(LUI_EV_CLICK_R, function() { soupy_url("https://easings.net/", , , 0); }),
				new LuiComboBox({ height: 35, placeholder: "Select easing type...", noborder: true, height_items: 260, }).addItems([
					new LuiComboBoxItem({ text: "NONE" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.NONE); 
						var func_ = e_.getData("easeExample"); func_(true); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "LINEAR" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.LINEAR); 
						var func_ = e_.getData("easeExample"); func_(true); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "QUAD" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.QUAD); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutQuad); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "CUBIC" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.CUBIC); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutCubic); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "QUART" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.QUART); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutQuart); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "QUINT" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.QUINT); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutQuint); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "SINE" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.SINE); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutSine); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "EXPO" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.EXPO); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutExpo); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "CIRC" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.CIRC); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutCirc); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "BACK" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.BACK); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutBack); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "ELASTIC" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.ELASTIC); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutElastic); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
					new LuiComboBoxItem({ text: "BOUNCE" }).setData("easeExample", easeExample).addEvent(LUI_EV_CLICK, function(e_) { 
						soup_store("dataeasetype", SCRIBBLE_EASE.BOUNCE); 
						var func_ = e_.getData("easeExample"); soup_store("dataease_tweenease", global.Ease.OutBounce); func_(); 
					}).addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_yellow; element_.main_ui.animate(element_, "xoff", 5, 0.30, global.Ease.OutBack, 0); }).addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); }),
				]),
				new LuiImage({ value: spr_soul, draw_normal: true }).setSize(20, 20).addEvent(LUI_EV_CREATE, function(e_) { soup_store("dataease_soul", e_); }),
			]),

			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Start X Offset:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Changes where in the x position a\ntypewriter character starts at.", true),
				new LuiInput({ value: SYSTEMUI.typist_ease.x, placeholder: "123456", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20)
				.addEvent(LUI_EV_CREATE, function() { soup_store("dataease_x", SYSTEMUI.typist_ease.x); }).bindVariable(SYSTEMUI.typist_ease, "x")
				.addEvent(LUI_EV_VALUE_UPDATE, function(e_) { var value = real_ext(e_.get()), result = value == "" ? 0 : value; soup_store("dataease_x", result); }),
			]),
			
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Start Y Offset:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Changes where in the y position a\ntypewriter character starts at.", true),
				new LuiInput({ value: SYSTEMUI.typist_ease.y, placeholder: "123456", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20)
				.addEvent(LUI_EV_CREATE, function() { soup_store("dataease_y", SYSTEMUI.typist_ease.y); }).bindVariable(SYSTEMUI.typist_ease, "y")
				.addEvent(LUI_EV_VALUE_UPDATE, function(e_) { var value = real_ext(e_.get()), result = value == "" ? 0 : value; soup_store("dataease_y", result); }),
			]),
			
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Start X Scale:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Changes the starting xscale\nof a typewriter character.", true),
				new LuiInput({ value: SYSTEMUI.typist_ease.xscale, placeholder: "123456", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20)
				.addEvent(LUI_EV_CREATE, function() { soup_store("dataease_xs", SYSTEMUI.typist_ease.xscale); }).bindVariable(SYSTEMUI.typist_ease, "xscale")
				.addEvent(LUI_EV_VALUE_UPDATE, function(e_) { var value = real_ext(e_.get()), result = value == "" ? 0 : value; soup_store("dataease_xs", result); }),
			]),
			
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Start Y Scale:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Changes the starting yscale\nof a typewriter character.", true),
				new LuiInput({ value: SYSTEMUI.typist_ease.yscale, placeholder: "123456", offset: 12, type_sfx: snd_txttype, color_normal: c_white, color_hover: c_gray, }).setPadding(20)
				.addEvent(LUI_EV_CREATE, function() { soup_store("dataease_ys", SYSTEMUI.typist_ease.yscale); }).bindVariable(SYSTEMUI.typist_ease, "yscale")
				.addEvent(LUI_EV_VALUE_UPDATE, function(e_) { var value = real_ext(e_.get()), result = value == "" ? 0 : value; soup_store("dataease_ys", result); }),
			]),
			
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Smooth Alpha:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Changes the starting alpha\nof a typewriter character.\n0 - Characters will show up instantly\n1 - Characters will smoothly show up", true),
				new LuiSlider({ value: SYSTEMUI.typist_ease.alpha, min_value: 0, color_text: c_black, color_text_drag: c_white, max_value: 1, rounding: false, display_value: true, bar_sprite: spr_border_header, bar_sprite_back: spr_border_header, })
				.addEvent(LUI_EV_CREATE, function() { soup_store("dataease_alpha", SYSTEMUI.typist_ease.alpha); }).bindVariable(SYSTEMUI.typist_ease, "alpha")
				.addEvent(LUI_EV_VALUE_UPDATE, function(e_) { soup_store("dataease_alpha", real(e_.get())); }),
			]),
			
			new LuiRow().setFlexGrow(1).centerContent().addContent([
				new LuiText({ value: "Start Angle:", text_halign: fa_center, text_valign: fa_middle, font: fnt_speech, }).setTooltip("Changes the starting rotation\nof a typewriter character.", true),
				new LuiSlider({ value: SYSTEMUI.typist_ease.angle, min_value: 0, color_text: c_black, color_text_drag: c_white, max_value: 360, rounding: true, display_value: true, bar_sprite: spr_border_header, bar_sprite_back: spr_border_header, })
				.addEvent(LUI_EV_CREATE, function() { soup_store("dataease_angle", SYSTEMUI.typist_ease.angle); }).bindVariable(SYSTEMUI.typist_ease, "angle")
				.addEvent(LUI_EV_VALUE_UPDATE, function(e_) { soup_store("dataease_angle", real(e_.get())); soup_checkout("dataease_soul", false).angle = real(e_.get()); }),
			]),
			
			new LuiButton({ text: "Apply Typewriter Easing", height: 35, }).setData("tween", easeExample).addEvent(LUI_EV_CLICK, function(e_) {
				if ( soup_checkout("dataeasetype", false) == -1 ) { soupy_message("You must select an|easing type.", , 200, , , snd_error, , , true); exit; }
				
				var tween = e_.getData("tween"); tween(true);
				SYSTEMUI.typist_ease = { type: soup_checkout("dataeasetype"), x: soup_checkout("dataease_x"), y: soup_checkout("dataease_y"), xscale: soup_checkout("dataease_xs"), yscale: soup_checkout("dataease_ys"), angle: soup_checkout("dataease_angle"), alpha: soup_checkout("dataease_alpha"), };
				with ( SYSTEMUI ) { if ( typist_smooth == 0 ) { typist_smooth = 15; typist.in(typist_spd, typist_smooth); } typist.ease(typist_ease.type, typist_ease.x, typist_ease.y, typist_ease.xscale, typist_ease.yscale, typist_ease.angle, typist_ease.alpha); }
				sfx_play(snd_chest); soup_checkout("datatypewriteredit_func")();
			}),
		];
		
		//typist_ease = { type: SCRIBBLE_EASE.LINEAR, x: 0, y: 0, xscale: 1, yscale: 1, angle: 0, alpha: 1, };
		//typist.ease(typist_ease.type, typist_ease.x, typist_ease.y, typist_ease.xscale, typist_ease.yscale, typist_ease.angle, typist_ease.alpha);
		
		soup_store("dataeasetype", -1); 
		soup_store("datatypewriteredit_func", function() { soup_checkout("datatypewriteredit").destroy(); soup_store_clear(); SYSTEMUI.ui_paused = false; });
		var maincan = soupy_popup(dataarr, function() { soup_checkout("dataease_tween func")(true); soup_store_clear(); SYSTEMUI.ui_paused = false; }, "Nevermind", , , , , , , 2); soup_store("datatypewriteredit", maincan); 
	}
	
	///@desc Show error message for sprites that couldn't be loaded
	function external_error() {
		if ( global.outputLogSkipped == "" ) { exit; }
		var result = string_split(global.outputLogSkipped, "|"), result_len = array_length(result), result_i = 0, arr_ = [];
		repeat ( result_len ) {
			var cur_ = result[result_i];
			array_push(arr_,  new LuiText({ value: cur_, text_halign: fa_center, text_valign: fa_middle, font: fnt_abaddon, color: c_white, xoff: 0, y: 10 }));
		result_i++; }
	
		array_push(arr_,  new LuiText({ value: "These sprites were not loaded due to\neither incorrect filenames or file structure.", text_halign: fa_center, text_valign: fa_middle, font: fnt_abaddon, color: c_white, xoff: 0, y: 10 }));
		array_push(arr_,  new LuiText({ value: "If you need help, please refer to the SoupGen guide. (Click me!)", text_halign: fa_center, text_valign: fa_middle, font: fnt_abaddon, color: c_white, xoff: 0, y: 10 })
			.addEvent(LUI_EV_CLICK, function(element_) { sfx_play(snd_select); soupy_url("https://rentry.co/utdrsoupguides", , , 0); })
			.addEvent(LUI_EV_MOUSE_ENTER, function(element_) { element_.color = c_gold; sfx_play(snd_sel_switch); element_.main_ui.animate(element_, "xoff", 10, 0.30, global.Ease.OutBack, 0); })
			.addEvent(LUI_EV_MOUSE_LEAVE, function(element_) { element_.color = c_white; element_.main_ui.animate(element_, "xoff", 0, 0.15); })
		);
	
		var maincan = new LuiScrollPanel({ sprite_panel: false, scroll_slider_width: 10, height: 390, }).addContent(arr_);
		soupy_popup([ maincan, ], , "Oh no!", , 460, , snd_error, fnt_abaddon, SYSTEMUI.ui_paused, 0, 40);
		global.outputLogSkipped = "";
	}
#endregion


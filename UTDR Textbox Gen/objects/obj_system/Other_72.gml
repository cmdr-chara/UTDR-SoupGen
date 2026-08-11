///@desc Transactional Bulk Load Faces
//if ( live_call() ) { return live_result; }
var get_ = async_load;
if ( !ds_map_exists(get_, "id") ) { exit; }

// Peek first. Other Save/Load events must not consume an in-flight ZIP request.
var info_ = soup_checkout("bulkload", false, true);
if ( is_undefined(info_) || get_[? "id"] != info_.id ) { exit; }
soup_checkout("bulkload", true, true);

var success_ = false, error_message_ = "ZIP import failed.", pending_log_ = "";
var loaded_sprites_ = [], part_paths_ = [], committed_paths_ = [], created_dirs_ = [];
var registered_aliases_ = [], installed_entries_ = [], created_characters_ = [];

try {
	if ( get_[? "status"] != 0 ) { throw "GameMaker could not extract the archive. It may be corrupt or password-protected."; }
	if ( !soupy_zip_stage_path(info_.stage) || !directory_exists(info_.stage) ) { throw "The ZIP staging folder is missing or outside the temporary area."; }
	var stage_root_canonical_ = soupy_zip_canonical(info_.stage);
	if ( !directory_exists(info_.extract) || !soupy_zip_path_within(stage_root_canonical_, info_.extract) ) { throw "The ZIP extraction folder is missing or outside staging."; }

	var plan_ = info_.plan, expected_ = {}, actual_ = {};
	for ( var plan_i_ = 0; plan_i_ < array_length(plan_); plan_i_++; ) {
		var planned_ = plan_[plan_i_], planned_key_ = string_lower(string_replace_all(planned_.path, "\\", "/"));
		if ( variable_struct_exists(expected_, planned_key_) ) { throw $"Duplicate planned path: {planned_.path}"; }
		expected_[$ planned_key_] = planned_;
	}

	var stage_path_ = string_replace_all(info_.extract, "\\", "/");
	if ( !soupy_zip_ends_with(stage_path_, "/") ) { stage_path_ += "/"; }
	var stage_compare_ = os_type == os_windows ? string_lower(stage_path_) : stage_path_;
	var stage_canonical_ = soupy_zip_canonical(info_.extract);
	var extracted_files_ = soupy_zip_collect_files(info_.extract);
	if ( array_length(extracted_files_) != array_length(plan_) ) { throw "The extracted file set does not match the inspected ZIP directory."; }

	for ( var file_i_ = 0; file_i_ < array_length(extracted_files_); file_i_++; ) {
		var source_path_ = extracted_files_[file_i_];
		if ( symlink_exists(source_path_) ) { throw "The extracted archive contains a symbolic link."; }
		if ( !soupy_zip_path_within(stage_canonical_, source_path_) ) { throw "An extracted file escaped the staging directory."; }

		var source_slash_ = string_replace_all(source_path_, "\\", "/");
		var source_compare_ = os_type == os_windows ? string_lower(source_slash_) : source_slash_;
		if ( !soupy_zip_starts_with(source_compare_, stage_compare_) ) { throw "An extracted path cannot be made relative to staging."; }
		var relative_ = string_copy(source_slash_, string_length(stage_path_) + 1, string_length(source_slash_) - string_length(stage_path_));
		var relative_key_ = string_lower(relative_);
		if ( !variable_struct_exists(expected_, relative_key_) || variable_struct_exists(actual_, relative_key_) ) { throw $"Unexpected or duplicate extracted file: {relative_}"; }

		var planned_file_ = expected_[$ relative_key_];
		if ( file_size(source_path_) != planned_file_.uncompressed_size ) { throw $"Extracted size differs from the inspected ZIP entry: {relative_}"; }
		planned_file_[$ "source"] = source_path_;
		actual_[$ relative_key_] = true;
	}

	for ( var expected_i_ = 0; expected_i_ < array_length(plan_); expected_i_++; ) {
		if ( !variable_struct_exists(plan_[expected_i_], "source") ) { throw $"Expected file was not extracted: {plan_[expected_i_].path}"; }
	}

	var faces_root_ = is_android() ? $"faces{PATHSEP}" : $"{executable_get_directory()}faces{PATHSEP}";
	if ( !directory_exists(faces_root_) ) {
		directory_create(faces_root_);
		if ( !directory_exists(faces_root_) ) { throw "The persistent faces folder could not be created."; }
		array_push(created_dirs_, faces_root_);
	}
	if ( symlink_exists(soupy_zip_trim_directory_path(faces_root_)) ) { throw "The persistent faces root cannot be a symbolic link or junction."; }
	var faces_root_canonical_ = soupy_zip_canonical(faces_root_), character_map_ = {}, planned_aliases_ = {};
	var total_pixels_ = int64(0), pixel_limit_ = is_android() ? int64(16 * 1024 * 1024) : int64(SOUPY_ZIP_MAX_TOTAL_PIXELS);
	for ( var validate_i_ = 0; validate_i_ < array_length(plan_); validate_i_++; ) {
		var item_ = plan_[validate_i_];
		var character_lower_ = string_lower(item_.character);
		var character_key_ = variable_struct_exists(character_map_, character_lower_)
			? character_map_[$ character_lower_]
			: soupy_zip_character_key(item_.character);
		character_map_[$ character_lower_] = character_key_;
		if ( soupy_zip_face_exists(character_key_, item_.expression) ) { throw $"Face already exists: {character_key_}/{item_.expression}"; }

		var scribble_alias_ = $"{character_key_}_{item_.expression}";
		var alt_alias_ = $"spr_{scribble_alias_}";
		var scribble_alias_key_ = string_lower(scribble_alias_), alt_alias_key_ = string_lower(alt_alias_);
		if ( variable_struct_exists(planned_aliases_, scribble_alias_key_) || variable_struct_exists(planned_aliases_, alt_alias_key_) ) {
			throw $"Face aliases collide after normalization: {scribble_alias_}";
		}
		planned_aliases_[$ scribble_alias_key_] = true;
		planned_aliases_[$ alt_alias_key_] = true;
		if ( scribble_external_sprite_exists(scribble_alias_) || scribble_external_sprite_exists(alt_alias_) || soupy_zip_struct_key_exists_ci(global.faces_dict_alt, alt_alias_) ) {
			throw $"Face alias already exists: {alt_alias_}";
		}

		var png_info_ = soupy_zip_png_info(item_.source, item_.crc);
		if ( png_info_.width > SOUPY_ZIP_MAX_TEXTURE_SIDE || png_info_.height > SOUPY_ZIP_MAX_SPRITE_SIDE
			|| png_info_.pixels > SOUPY_ZIP_MAX_IMAGE_PIXELS || png_info_.width mod item_.frames != 0
			|| png_info_.width div item_.frames > SOUPY_ZIP_MAX_SPRITE_SIDE ) {
			throw $"PNG dimensions or strip layout exceed the safe texture budget: {item_.path}";
		}
		total_pixels_ += int64(png_info_.pixels);
		if ( total_pixels_ > pixel_limit_ ) { throw "The face pack exceeds the decoded pixel budget for this platform."; }

		var strip_suffix_ = item_.frames > 1 ? $"_strip{item_.frames}" : "";
		var persistent_filename_ = $"spr_{character_key_}_{item_.expression}{strip_suffix_}.png";
		var character_dir_ = $"{faces_root_}{character_key_}{PATHSEP}";
		var final_path_ = $"{character_dir_}{persistent_filename_}";
		var part_path_ = $"{final_path_}.soupy-part-{info_.token}";
		if ( directory_exists(character_dir_) && (symlink_exists(soupy_zip_trim_directory_path(character_dir_)) || !soupy_zip_path_within(faces_root_canonical_, character_dir_)) ) {
			throw $"Character folder is outside the persistent faces root: {character_key_}";
		}
		if ( file_exists(final_path_) || file_exists(part_path_) || symlink_exists(final_path_) || symlink_exists(part_path_) ) { throw $"Destination already exists: {character_key_}/{persistent_filename_}"; }

		var sprite_ = sprite_add(item_.source, item_.frames, false, false, 0, 0);
		if ( !sprite_exists(sprite_) ) { throw $"PNG could not be decoded: {item_.path}"; }
		array_push(loaded_sprites_, sprite_);
		if ( sprite_get_number(sprite_) != item_.frames || sprite_get_width(sprite_) < 1 || sprite_get_height(sprite_) < 1
			|| sprite_get_width(sprite_) > SOUPY_ZIP_MAX_SPRITE_SIDE || sprite_get_height(sprite_) > SOUPY_ZIP_MAX_SPRITE_SIDE ) {
			throw $"PNG dimensions or frame layout are invalid: {item_.path}";
		}

		item_[$ "install_character"] = character_key_;
		item_[$ "install_filename"] = persistent_filename_;
		item_[$ "character_dir"] = character_dir_;
		item_[$ "final_path"] = final_path_;
		item_[$ "part_path"] = part_path_;
		item_[$ "sprite"] = sprite_;
		item_[$ "scribble_alias"] = scribble_alias_;
		item_[$ "alt_alias"] = alt_alias_;
	}

	// Stage every persistent copy first. Nothing is registered in memory yet.
	var prepared_dirs_ = {};
	for ( var copy_i_ = 0; copy_i_ < array_length(plan_); copy_i_++; ) {
		var copy_item_ = plan_[copy_i_], dir_key_ = string_lower(copy_item_.character_dir);
		if ( !variable_struct_exists(prepared_dirs_, dir_key_) ) {
			if ( !directory_exists(copy_item_.character_dir) ) {
				directory_create(copy_item_.character_dir);
				if ( !directory_exists(copy_item_.character_dir) ) { throw $"Character folder could not be created: {copy_item_.install_character}"; }
				array_push(created_dirs_, copy_item_.character_dir);
			}
			if ( symlink_exists(soupy_zip_trim_directory_path(copy_item_.character_dir)) || !soupy_zip_path_within(faces_root_canonical_, copy_item_.character_dir) ) { throw "A character folder escaped the persistent faces root."; }
			prepared_dirs_[$ dir_key_] = true;
		}

		array_push(part_paths_, copy_item_.part_path);
		file_copy(copy_item_.source, copy_item_.part_path);
		if ( !file_exists(copy_item_.part_path) || file_size(copy_item_.part_path) != file_size(copy_item_.source) ) {
			throw $"Persistent staging copy failed: {copy_item_.install_character}/{copy_item_.filename}";
		}
		soupy_zip_png_info(copy_item_.part_path, copy_item_.crc); //CRC-check the persistent copy before commit.
	}

	// The final names were checked absent above, so successful renames can be rolled back safely.
	for ( var commit_i_ = 0; commit_i_ < array_length(plan_); commit_i_++; ) {
		var commit_item_ = plan_[commit_i_];
		if ( symlink_exists(soupy_zip_trim_directory_path(commit_item_.character_dir)) || !soupy_zip_path_within(faces_root_canonical_, commit_item_.character_dir)
			|| symlink_exists(commit_item_.final_path) || symlink_exists(commit_item_.part_path) || file_exists(commit_item_.final_path) ) {
			throw $"Destination changed before commit: {commit_item_.install_character}/{commit_item_.install_filename}";
		}
		if ( !file_rename(commit_item_.part_path, commit_item_.final_path) ) { throw $"Could not commit face file: {commit_item_.install_character}/{commit_item_.filename}"; }
		array_push(committed_paths_, commit_item_.final_path);
	}

	// Register only after every file reached its final path.
	for ( var install_i_ = 0; install_i_ < array_length(plan_); install_i_++; ) {
		var install_item_ = plan_[install_i_], character_ = install_item_.install_character;
		if ( !variable_struct_exists(global.faces_dict, character_) ) {
			global.faces_dict[$ character_] = {};
			array_push(created_characters_, character_);
		}

		var entry_ = {
			sprite: install_item_.sprite,
			expression: install_item_.expression,
			name: install_item_.final_path,
			count: install_item_.frames,
		};
		with ( entry_ ) {
			self[$ "destroy"] = function () { sprite_delete(sprite); delete sprite; sprite = -1; show_debug_message($"External face \"{name}\" was destroyed and freed from memory successfully!"); }
			self[$ "size"] = { sprite: sprite, width: sprite_get_width(sprite), height: sprite_get_height(sprite), };
			sprite_set_offset(sprite, size.width / 2, size.height / 2);
		}
		global.faces_dict[$ character_][$ install_item_.expression] = entry_;
		array_push(installed_entries_, { character: character_, expression: install_item_.expression, alt: install_item_.alt_alias, });

		scribble_external_sprite_add(install_item_.sprite, install_item_.scribble_alias);
		array_push(registered_aliases_, install_item_.scribble_alias);
		scribble_external_sprite_add(install_item_.sprite, install_item_.alt_alias);
		array_push(registered_aliases_, install_item_.alt_alias);
		global.faces_dict_alt[$ install_item_.alt_alias] = {
			sprite: install_item_.sprite,
			name: install_item_.alt_alias,
			destroy: entry_.destroy,
			size: entry_.size,
		};

		var output_ = $"Added \"{install_item_.expression}\" from {install_item_.final_path}! | Image number: {install_item_.frames} | Scribble name: {install_item_.scribble_alias} | Scribble alt name: {install_item_.alt_alias}";
		show_debug_message(output_);
		pending_log_ += $"{output_}\n";
	}

	success_ = true;
}
catch ( error_ ) {
	error_message_ = soupy_zip_error_string(error_);
}
finally {
	if ( !success_ ) {
		for ( var alias_i_ = 0; alias_i_ < array_length(registered_aliases_); alias_i_++; ) { scribble_external_sprite_remove(registered_aliases_[alias_i_]); }
		for ( var installed_i_ = 0; installed_i_ < array_length(installed_entries_); installed_i_++; ) {
			var installed_ = installed_entries_[installed_i_];
			if ( variable_struct_exists(global.faces_dict, installed_.character) ) { struct_remove(global.faces_dict[$ installed_.character], installed_.expression); }
			if ( variable_struct_exists(global.faces_dict_alt, installed_.alt) ) { struct_remove(global.faces_dict_alt, installed_.alt); }
		}
		for ( var char_i_ = 0; char_i_ < array_length(created_characters_); char_i_++; ) {
			var created_character_ = created_characters_[char_i_];
			if ( variable_struct_exists(global.faces_dict, created_character_) && array_length(struct_get_names(global.faces_dict[$ created_character_])) == 0 ) {
				struct_remove(global.faces_dict, created_character_);
			}
		}
		for ( var sprite_i_ = 0; sprite_i_ < array_length(loaded_sprites_); sprite_i_++; ) {
			if ( sprite_exists(loaded_sprites_[sprite_i_]) ) { sprite_delete(loaded_sprites_[sprite_i_]); }
		}
		for ( var committed_i_ = 0; committed_i_ < array_length(committed_paths_); committed_i_++; ) {
			var committed_path_ = committed_paths_[committed_i_], committed_parent_ = filename_dir(committed_path_);
			if ( file_exists(committed_path_) && !symlink_exists(committed_path_) && !symlink_exists(soupy_zip_trim_directory_path(committed_parent_))
				&& soupy_zip_path_within(faces_root_canonical_, committed_path_) ) { file_delete(committed_path_); }
		}
		for ( var part_i_ = 0; part_i_ < array_length(part_paths_); part_i_++; ) {
			var part_path_ = part_paths_[part_i_], part_parent_ = filename_dir(part_path_);
			if ( file_exists(part_path_) && !symlink_exists(part_path_) && !symlink_exists(soupy_zip_trim_directory_path(part_parent_))
				&& soupy_zip_path_within(faces_root_canonical_, part_path_) ) { file_delete(part_path_); }
		}
		for ( var dir_i_ = array_length(created_dirs_) - 1; dir_i_ >= 0; dir_i_--; ) {
			var created_dir_ = created_dirs_[dir_i_], created_dir_trimmed_ = soupy_zip_trim_directory_path(created_dir_);
			var created_dir_canonical_ = soupy_zip_canonical(created_dir_);
			if ( directory_exists(created_dir_) && !symlink_exists(created_dir_trimmed_)
				&& (created_dir_canonical_ == faces_root_canonical_ || soupy_zip_path_within(faces_root_canonical_, created_dir_)) ) { directory_destroy(created_dir_); }
		}
	}
	soupy_zip_cleanup(info_.stage);
}

if ( success_ ) {
	global.outputLog += pending_log_;
	sfx_play(snd_dimbox);
	sfx_play(snd_updated);
	var plural_ = array_length(info_.plan) == 1 ? "" : "s";
	soupy_message($"Imported {array_length(info_.plan)} face sprite{plural_} successfully.", "Nice!", 400, , , snd_chest, fnt_abaddon, , SYSTEMUI.ui_paused, true);
}
else { soupy_zip_report_error(error_message_); }

///@desc 
if ( !global.pref.soupyicon ) { exit; }
if ( !surface_exists(surf) ) { surf = surface_create(w, h); exit; }
if ( !surface_exists(surf2) ) { surf2 = surface_create(w2, h2); exit; }
image_blend = instance_exists(obj_system) ? obj_system.ui_accentcolor : global.pref.themeclr;

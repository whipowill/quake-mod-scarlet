void() S_Precache =
{
    // sounds
    precache_sound ("walk/generic1.wav");
    precache_sound ("walk/generic2.wav");
    precache_sound ("walk/generic3.wav");
    precache_sound ("walk/generic4.wav");
    precache_sound ("walk/generic5.wav");
    precache_sound ("walk/metal1.wav");
    precache_sound ("walk/metal2.wav");
    precache_sound ("walk/metal3.wav");
    precache_sound ("walk/metal4.wav");
    precache_sound("items/r_item1.wav");
    precache_sound("items/r_item2.wav");
    precache_sound("items/protect.wav");
    // rewards and drops can hand out any powerup on any map, so their sounds can't wait for the item to be on the map
    precache_sound("items/protect2.wav");
    precache_sound("items/protect3.wav");
    precache_sound("items/damage2.wav");
    precache_sound("items/damage3.wav");
    precache_sound("items/suit.wav");
    precache_sound("items/suit2.wav");
    precache_sound("items/inv1.wav");
    precache_sound("items/inv2.wav");
    precache_sound("items/inv3.wav");
    precache_sound("items/health1.wav");
    precache_sound("items/damage.wav");
    precache_sound("halo3/weapons/frag_throw.wav");
    precache_sound("halo3/weapons/frag_bnc_stone1.wav");

    // models
    precache_model("progs/zom_gib.mdl");
    precache_model("progs/invulner.mdl");
    precache_model("progs/quaddama.mdl");

    // every weapon, on every map: dropped weapons (scarlet_visible_weapons) and weapons that appear later can
    // be any of them, whether or not the mapper placed one.  the view models (v_*) are already in worldspawn
    precache_model("progs/g_shot.mdl");
    precache_model("progs/g_nail.mdl");
    precache_model("progs/g_nail2.mdl");
    precache_model("progs/g_rock.mdl");
    precache_model("progs/g_rock2.mdl");
    precache_model("progs/g_light.mdl");

    // the models that aren't part of Quake are only loaded when the feature that shows them is on
    if (cv_scarlet_rewards || cv_scarlet_singleplayer_monsters_drop_chance > 0 || cv_scarlet_respawn_invul > 0)
        precache_model("progs/items/quoth/cross.mdl"); // the Megahealth reward, and the respawn blessing icon
    if (cv_scarlet_grenades)
        precache_model("progs/items/hipnotic/proxbomb_edited.mdl"); // the hand grenade
}
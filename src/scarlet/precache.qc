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
    precache_sound("items/damage.wav");
    precache_sound("halo3/weapons/frag_throw.wav");
    precache_sound("halo3/weapons/frag_bnc_stone1.wav");

    // models
    precache_model("progs/zom_gib.mdl");
    precache_model("progs/invulner.mdl");
    precache_model("progs/quaddama.mdl");

    // the models that aren't part of Quake are only loaded when the feature that shows them is on
    if (cv_scarlet_rewards || cv_scarlet_singleplayer_monsters_drop_chance > 0)
        precache_model("progs/items/quoth/cross.mdl"); // the Megahealth reward
    if (cv_scarlet_grenades)
        precache_model("progs/items/hipnotic/proxbomb_edited.mdl"); // the hand grenade
}
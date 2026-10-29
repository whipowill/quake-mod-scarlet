// -------------------------------------------------
// Shuffle the CD track.
// by whipowill
//-------------------------------------------------

float music_track; // the track picked for this map

// pick a random track from the configured range, avoiding a repeat
// returns 0 if the range is invalid
float() MusicPick =
{
	local float lo = cv_scarlet_music_min;
	local float hi = cv_scarlet_music_max;
	local float t;

	if (lo < 1 || hi < lo) return 0;

	t = lo + floor(random() * (hi - lo + 1));
	if (t == music_track && hi > lo)
		t = lo + mod(t - lo + 1 + floor(random() * (hi - lo)), hi - lo + 1);

	return t;
};

// switch every client to a new random track right now
void() MusicSwap =
{
	local float t = MusicPick();
	if (!t) return;

	music_track = t;

	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, t);
	WriteByte (MSG_ALL, t);

	bprint ("Now playing track ");
	bprint (ftos(t));
	bprint (".\n");
};

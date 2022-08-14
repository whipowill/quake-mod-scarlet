# Docs | Nametags

In ``client.qc``:

```
void() PlayerPreThink =
{
    if (BotPreFrame()) return; // SCARLET - bots integration.

    NameTag(); // SCARLET - nametags integration.
```
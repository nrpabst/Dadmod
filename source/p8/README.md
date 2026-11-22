# Project 8 map converter

These are the tools that turn the Project 8 (original Xbox) levels into the THP8 maps that dadmod ships: Training, Suburbs, Downtown, Car Factory and Crete Park. We wrote all of this code ourselves. No game data is included; you need your own P8 disc image.

- `build_p8.py [Level ...]` builds `p8/build/data/pre/P8<Level>*.prx`, plus the level sounds in `p8/build/tmp/<Level>/sounds/<Level>/`, from `p8/disc/data` and the sound banks in `p8/disc_sounds` / `p8/disc_streams`. It uses `tools/qb.py` and `tools/prx_pack.py` from this repo.
- `p8conv.py` is the converter itself (scene, collision, nodes, scripts, ambience). `p8sound.py` handles P8 sound banks and streams. `p8qb.py` and `p8script.py` read P8 QB files and scripts. `coincident.py` and `colparse.py` are helpers, and `validate_p8.py` checks a build.
- Level sounds are written as THUG Pro `.snd` files, which use the game's own 4-bit ADPCM. The encoder is `thpg/tools/thugsnd.py`. A plain PCM WAV plays as about 1 second of noise in game. P8 sounds flagged `looping` get a loop chunk and play from a hidden Ghost object at their emitter.

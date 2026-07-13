# Audio resource optimization

`optimize_ogg.py` detects two common resource regressions:

- files named `.ogg` that actually contain MP3 or uncompressed PCM and are at
  least 256 KiB;
- files of at least 1 MiB with a bitrate of 256 kbit/s or more.

The default command only audits files:

```sh
python3 tools/audio/optimize_ogg.py
```

To replace selected files with metadata-preserving Ogg Vorbis quality 4:

```sh
python3 tools/audio/optimize_ogg.py --apply
```

Every output is checked for its codec, duration and size before the original is
atomically replaced. Invalid or already compact files are left untouched.

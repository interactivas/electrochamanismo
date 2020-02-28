# sound-source-supercollider

Directory `sound-source-supercollider/`:

We use SuperCollider to:

- Process sound
- Generate patterns and changing parameters (e.g. tempo, beats, etc.)

Processed sound and patterns are publised in OSC format.

## OSC Tags

| OSC tag | Parameter description | Type | Example | Refresh rate |
|---|---|---|---|---|---|
| /didge-mfcc | MFCC coefficients for instrument didgeridoo | array of 13 numbers? |  | 24 fps |
| /didge-volume | Volume for instrument didge | number ? | | 24 fps |
| /didge-pitch | Pitch for instrument didge | number ? | |  24 fps |

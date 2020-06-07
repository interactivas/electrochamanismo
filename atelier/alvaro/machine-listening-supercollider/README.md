# sound-source-supercollider

Directory `sound-source-supercollider/`:

We use SuperCollider to:

- Process sound
- Generate patterns and changing parameters (e.g. tempo, beats, etc.)

Processed sound and patterns are publised in OSC format.

## OSC Tags

| OSC tag | Parameter description | Type | Example | Refresh rate |
| --- | --- | --- | --- | --- |
| `/volume-in`  | Volume for audio input | number ? | | 24 fps |
| `/pitch-in | Pitch for audio input | number ? | |  24 fps |
| `/mfcc-in` | MFCC coefficients for audio input | array of 13 numbers? |  | 24 fps |


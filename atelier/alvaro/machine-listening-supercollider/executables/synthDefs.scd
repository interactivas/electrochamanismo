////////////////////////////////////////////////////////////////////////////////
// synthDef factories exported to event referred by global var 'i'
////////////////////////////////////////////////////////////////////////////////

if (i == nil) {
	i = ()
};

i.makeSynthDef_Volume = {
	|self, synthName = \volume|
	"Making SynthDef for -> ".post; synthName.postln;

	SynthDef(synthName, {
		|outControlBus=0, outAudioBus = 0, inAudioBus = 0|

		var in, amp, freq, hasFreq, sound;
		in = SoundIn.ar(inAudioBus);
		amp = Amplitude.kr(in, 0.05, 0.05);
		Out.kr(outControlBus, amp);
	});
};

i.makeSynthDef_Pitch = {
	|self, synthName = \pitch|
	"Making SynthDef for -> ".post; synthName.postln;

	SynthDef(synthName, {
		|outControlBus=0, outAudioBus = 0, inAudioBus = 0|

		var in, amp, freq, hasFreq, sound;
		in = SoundIn.ar(inAudioBus);
		amp = Amplitude.kr(in, 0.05, 0.05);
		//# freq, hasFreq = Pitch.kr(in, ampThreshold: 0.02, median: 7);
		# freq, hasFreq = Pitch.kr(in);
		//sound = SinOsc.ar(freq, mul: amp * EnvGen.kr(Env.perc, Impulse.kr(1)));
		//Out.ar(outAudioBus,sound);
		Out.kr(outControlBus, freq);
	});
};

i.makeSynthDef_MFCC = {
	|self, synthName = \mfcc|
	"Making SynthDef for -> ".post; synthName.postln;

	SynthDef(synthName, {
		|outControlBus=0, outAudioBus = 0, inAudioBus = 0, fftSize = 1024|

		var in, fft, array;
		in = SoundIn.ar(inAudioBus);
		fft = FFT(LocalBuf(fftSize), in);
		array = MFCC.kr(fft);
		//array.size.postln;
		Out.kr(outControlBus, array);
		//Out.ar(outAudioBus,Pan2.ar(in));
	});
};

i.makeSynthDef_Loudness = {
	|self, synthName = \loudness|
	"Making SynthDef for -> ".post; synthName.postln;

	SynthDef(synthName, {
		|outControlBus=0, outAudioBus = 0, inAudioBus = 0, fftSize = 1024|

		var in, fft, loudness;
		in = SoundIn.ar(inAudioBus);
		fft = FFT(LocalBuf(fftSize), in);
		loudness = Loudness.kr(fft);

		Out.kr(outControlBus, loudness);
	});
};

i.makeSynthDef_SpecCentroid = {
	|self, synthName = \speccentroid|
	"Making SynthDef for -> ".post; synthName.postln;

	SynthDef(synthName, {
		|outControlBus=0, outAudioBus = 0, inAudioBus = 0, fftSize = 1024|

		var in, fft, spec_centroid;
		in = SoundIn.ar(inAudioBus);
		fft = FFT(LocalBuf(fftSize), in);
		spec_centroid = SpecCentroid.kr(fft);

		Out.kr(outControlBus, spec_centroid);
	});
};

i.makeSynthDef_Onsets = {
	|self, synthName = \onsets|
	"Making SynthDef for -> ".post; synthName.postln;

	SynthDef(synthName, {
		|outControlBus=0, outAudioBus = 0, inAudioBus = 0, fftSize = 1024, threshold=0.5|

		var in, fft, onsets;
		in = SoundIn.ar(inAudioBus);
		fft = FFT(LocalBuf(fftSize), in);
		onsets = Onsets.kr(fft, MouseX.kr(0,1), \rcomplex);

		Out.kr(outControlBus, onsets);
	});
};




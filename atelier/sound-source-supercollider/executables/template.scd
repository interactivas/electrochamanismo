////////////////////////////////////////////////////////////////////////////////
//
// aluarosi - 2020-02
//
////////////////////////////////////////////////////////////////////////////////

// TODO: Centralise in a table (list of dicts)
// TODO: Rename from "routines" to "tasks" to be more consistent

( // Double-click on this opening parenthesis and hit shift-enter to run

////////////////////////////////////////////////////////////////////////////////
// Global CONFIG - Change this if needed
////////////////////////////////////////////////////////////////////////////////
// Remote OSC listener
~osc_host = "127.0.0.1";
~osc_port = 7777;

////////////////////////////////////////////////////////////////////////////////
// Global variables
////////////////////////////////////////////////////////////////////////////////
~out = 0;
~path_samples = PathName(thisProcess.nowExecutingPath).parentPath ++ "../samples/";

~buffers = Dictionary.new();
~busses = Dictionary.new();
~synths = Dictionary.new();

~routines = Dictionary.new();
~patterns = Dictionary.new();

~oscTags = Dictionary.new();

////////////////////////////////////////////////////////////////////////////////
// Server config
////////////////////////////////////////////////////////////////////////////////
s = Server.local;
s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
// Memory allocation for buffers and dynamically alloc for delays, etc
s.options.memSize_(2.pow(20)); // Roughly 1GB, probably extremely generous!

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

//
// Generic poller routine
//
~makeRoutinePoller = {
	arg bus, oscTag, fps=1;
	"Making poller routine for bus :".post; bus.postln;
	p = NetAddr.new(~osc_host, ~osc_port);
	Task.new({
		"Routine started for OSC tag ".post; oscTag.post; " with ".post; fps.post; " fps".postln;
		inf.do {
			bus.getn(bus.numChannels, {
				arg val;
				oscTag.post; " : ".post; val.postln;
				// TODO: spread value if it is an array. Spread operator in SC?
				p.sendMsg(oscTag, *val);
			});
			(1/fps).wait;
		}
	});
};

////////////////////////////////////////////////////////////////////////////////
// SynthDefs
// TODO: SynthDefs could be imported from common file
////////////////////////////////////////////////////////////////////////////////
~makeSynthDefMFCC = {
	arg synthName = \mfcc;
	SynthDef(synthName, {
		arg outControlBus=0, outAudioBus = 0, inAudioBus = 0, fftSize = 1024;
		var in, fft, array;
		in = SoundIn.ar(inAudioBus);
		fft = FFT(LocalBuf(fftSize), in);
		array = MFCC.kr(fft);
		//array.size.postln;
		Out.kr(outControlBus, array);
		//Out.ar(outAudioBus,Pan2.ar(in));
	});
};

~makeSynthDefPitch = {
	arg synthName = \pitch;
	SynthDef(synthName, {
		arg outControlBus=0, outAudioBus = 0, inAudioBus = 0;
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

~makeSynthDefVolume= {
	arg synthName = \volume;
	SynthDef(synthName, {
		arg outControlBus=0, outAudioBus = 0, inAudioBus = 0;
		var in, amp, freq, hasFreq, sound;
		in = SoundIn.ar(inAudioBus);
		amp = Amplitude.kr(in, 0.05, 0.05);
		Out.kr(outControlBus, amp);
	});
};

////////////////////////////////////////////////////////////////////////////////
// INTERPRETER Setup functions
////////////////////////////////////////////////////////////////////////////////

~clearRoutines = {
	"--- clearRoutines".postln;
	~routines.keysValuesDo { |k,v| v.stop; };
	~routines.postln;
};

~makeRoutines = {
	"--- makeRoutines".postln;
	~clearRoutines.value;
	~routines.add(
		\volume -> ~makeRoutinePoller.value(~busses[\volume], "/volume", fps: 1));
	~routines.add(
		\pitch -> ~makeRoutinePoller.value(~busses[\pitch], "/pitch", fps: 1));
	~routines.add(
		\mfcc -> ~makeRoutinePoller.value(~busses[\mfcc], "/mfcc", fps: 1));
};

~playEvents = {
	"--- playEvents".postln;
	~routines[\volume].play;
	~routines[\pitch].play;
	~routines[\mfcc].play;
};

////////////////////////////////////////////////////////////////////////////////
// SERVER Setup functions
////////////////////////////////////////////////////////////////////////////////
~makeBuffers = {
	"--- makeBuffers".postln;
};

~makeBusses = {
	"--- makeBusses".postln;
	~busses.add(\volume -> Bus.control(s, 1));
	~busses.add(\pitch -> Bus.control(s, 1));
	~busses.add(\mfcc -> Bus.control(s, 13));
	~busses.postln;
};

~makeSynthDefs = {
	"--- makeSynthDefs".postln;
	~makeSynthDefVolume.value(\volume).add;
	~makeSynthDefPitch.value(\pitch).add;
	~makeSynthDefMFCC.value(\mfcc).add;
};

~makeNodes = {
	"--- makeNodes".postln;
	Synth.new(\volume, [outControlBus: ~busses[\volume] ]);
	Synth.new(\pitch, [outControlBus: ~busses[\pitch] ]);
	Synth.new(\mfcc, [outControlBus: ~busses[\mfcc] ]);
};

////////////////////////////////////////////////////////////////////////////////
// CLEANUP
////////////////////////////////////////////////////////////////////////////////

~cleanup = {
	"--- cleanup".postln;
	~clearRoutines.value;
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

////////////////////////////////////////////////////////////////////////////////
// Start-up hooks
////////////////////////////////////////////////////////////////////////////////
// Cleanup first to be extra-safe.
~cleanup.value;
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);

////////////////////////////////////////////////////////////////////////////////
// Boot server
////////////////////////////////////////////////////////////////////////////////
s.waitForBoot({

	s.sync; // Forces wait for the server to be done (e.g., loading buffers...)

	~makeSynthDefs.value;

	s.sync;

	ServerTree.add(~makeNodes);
	ServerTree.add(~makeRoutines);
	ServerTree.add(~playEvents);
	// Forces server to re-evaluate the 2 previous functions
	s.freeAll;

	s.sync;

	"Server booted OK.".postln;

});

nil;
)

////////////////////////////////////////////////////////////////////////////////
// Checks
////////////////////////////////////////////////////////////////////////////////



r.play;
r.stop;
s.quit;

~busses
~playEvents.value;

~routines[\mfcc].stop;
~routines[\pitch].stop;
~routines[\pitch].start;
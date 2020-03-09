////////////////////////////////////////////////////////////////////////////////
//
// aluarosi - 2020-02
// aluarosi - 2020-03
//
////////////////////////////////////////////////////////////////////////////////

( // Double-click on this opening parenthesis and hit shift-enter to run

// TODO:
// - Register OSC observers
// - GUI controls
// - Add more machine listening modules
// - Consider value normalisation along a time interval
// - ...

////////////////////////////////////////////////////////////////////////////////
// NAMESPACING
////////////////////////////////////////////////////////////////////////////////
//
// We use global variables to organise our code in namespaces.
// Each global variable below points to an Event, which works as a namespace.
//
// d -> Definitions / Constants. Not meant to be changed.
// i -> Imported objects/functions
// c -> Configuration. Meant to be changed by the user.
// t -> State. The user may interact with some pieces of it in real-time.
//             (See real-time section at the end of this file).
// s -> Reference to local server.
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// DEFINITIONS - This should rarely be changed
////////////////////////////////////////////////////////////////////////////////
d = (
	out: 0,
	pathSamples: PathName(thisProcess.nowExecutingPath).parentPath ++ "../samples/";
);

////////////////////////////////////////////////////////////////////////////////
// IMPORTS - These objects/functions should better be imported!
////////////////////////////////////////////////////////////////////////////////
i = ();
("synthDefs.scd").loadRelative;

////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION  - Change this to fit your needs
////////////////////////////////////////////////////////////////////////////////
c = ();
c.osc = (
	host: "127.0.0.1",
	port: 7777
);
c.sources = (
	volume_in: (
		oscTag: "/volume-in",
		synthDefFactory: i[\makeSynthDef_Volume],
		channels: 1,
		fps: 1,
		verbose: true
	),
	pitch_in: (
		oscTag: "/pitch-in",
		synthDefFactory: i[\makeSynthDef_Pitch],
		channels: 1,
		fps: 1,
		verbose: true
	),
	mfcc_in: (
		oscTag: "/mfcc-in",
		synthDefFactory: i[\makeSynthDef_MFCC],
		channels: 13,
		fps: 1,
		verbose: true
	)
);

////////////////////////////////////////////////////////////////////////////////
// STATE - You may tinker with this in real-time (see bottom of this file)
////////////////////////////////////////////////////////////////////////////////
t = ();
t.sources = (
	busses: (),
	synths: (),
	tasks: (),
	fps: (),
	verbose: ()
);

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS
////////////////////////////////////////////////////////////////////////////////
f = ();

f.makeRoutinePoller = {
	|self, sourceName, bus, oscTag, fps=1, verbose=false|

	"Making poller routine for bus :".post; bus.postln;
	p = NetAddr.new(c.osc.host, c.osc.port);
	Task.new({
		"Task started for OSC tag ".post; oscTag.post; " with ".post; fps.post; " fps".postln;
		t.sources.fps[sourceName] = fps;
		t.sources.verbose[sourceName] = verbose;
		loop {
			bus.getn(bus.numChannels, {
				|val|
				if (t.sources.verbose[sourceName] == true) {
					oscTag.post; " : ".post; val.postln;
				};
				p.sendMsg(oscTag, *val);
			});
			(1/t.sources.fps[sourceName]).wait;
		}
	});
};

////////////////////////////////////////////////////////////////////////////////
// SERVER Setup functions
////////////////////////////////////////////////////////////////////////////////
f.makeBusses = {
	"--- makeBusses".postln;
	c.sources.keysValuesDo {
		|sourceName, sourceConfig|
		t.sources.busses[sourceName] = Bus.control(
			s, numChannels: sourceConfig.channels
		);
	};
	t.sources.busses.postln;
};

f.clearBusses = {
	"--- clearBusses".postln;
	t.sources.busses = ();
	t.sources.busses.postln;
};

f.makeSynthDefs = {
	"--- makeSynthDefs".postln;
	c.sources.keysValuesDo {
		|sourceName, sourceConfig|
		sourceConfig.synthDefFactory(
			sourceName
		).add;
	};
};

f.makeSynths = {
	"--- makeSynhts".postln;
	c.sources.keysValuesDo {
		|sourceName, sourceConfig|
		t.sources.synths[sourceName] = Synth.new(
			sourceName,
			[outControlBus: t.sources.busses[sourceName]]
		);
	};
	t.sources.synths.postln;
};

f.clearSynths = {
	"--- clearSynhts".postln;
	t.sources.synths = ();
	t.sources.synths.postln;
};

////////////////////////////////////////////////////////////////////////////////
// INTERPRETER Setup functions
////////////////////////////////////////////////////////////////////////////////

f.stopTasks = {
	"--- stopTasks".postln;
	t.sources.tasks.keysValuesDo {
		|taskName,task|
		task.stop;
	};
	t.sources.tasks.postln;
};

f.clearTasks = {
	"--- clearTasks".postln;
	f.stopTasks;
	t.sources.tasks = ();
	t.sources.tasks.postln;
};

f.makeTasks = {
	"--- makeTasks".postln;
	f.clearTasks.value;
	c.sources.keysValuesDo {
		|sourceName, sourceConfig|
		t.sources.tasks[sourceName] = f.makeRoutinePoller(
			sourceName,
			t.sources.busses[sourceName],
			c.sources[sourceName].oscTag,
			c.sources[sourceName].fps,
			c.sources[sourceName].verbose
		);
	};
	t.sources.tasks.postln;
};

f.playTasks = {
	"--- playTasks".postln;
	t.sources.tasks.keysValuesDo {
		|taskName, task|
		task.play;
	};
};

////////////////////////////////////////////////////////////////////////////////
// CLEANUP
////////////////////////////////////////////////////////////////////////////////

f.clearFps = {
	"--- clearFps".postln;
	t.sources.fps = ();
};

f.cleanup = {
	"--- cleanup".postln;
	f.clearTasks;
	f.clearSynths;
	f.clearFps;
	f.clearBusses;
	s.newBusAllocators;
	ServerBoot.removeAll;
	ServerTree.removeAll;
	ServerQuit.removeAll;
};

////////////////////////////////////////////////////////////////////////////////
// Server config
////////////////////////////////////////////////////////////////////////////////
s = Server.local;
s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
// Memory allocation for buffers and dynamically alloc for delays, etc
s.options.memSize_(2.pow(20)); // Roughly 1GB, probably extremely generous!

////////////////////////////////////////////////////////////////////////////////
// Start-up hooks
////////////////////////////////////////////////////////////////////////////////
// Cleanup first to be extra-safe.
f.cleanup;
ServerBoot.add(f[\makeBusses]);
ServerQuit.add(f[\cleanup]);

////////////////////////////////////////////////////////////////////////////////
// Boot server
////////////////////////////////////////////////////////////////////////////////
s.waitForBoot({

	s.sync; // Forces wait for the server to be done (e.g., loading buffers...)

	f.makeSynthDefs;

	s.sync;

	ServerTree.add(f[\makeSynths]);
	ServerTree.add(f[\makeTasks]);
	ServerTree.add(f[\playTasks]);
	// Forces server to re-evaluate the 2 previous functions
	s.freeAll;

	s.sync;

	"Server booted OK.".postln;

});

nil;
)

////////////////////////////////////////////////////////////////////////////////
// REAL-TIME INTERACTION
////////////////////////////////////////////////////////////////////////////////

//
// Stop/start tasks
//
t.sources.tasks.volume_in.stop;
t.sources.tasks.pitch_in.stop;
t.sources.tasks.mfcc_in.stop;
f.playTasks;
f.stopTasks;
t.sources.tasks.volume_in.start;

//
// Change FPS (frames per second) for a source
//
t.sources.fps.volume_in = 25;
t.sources.fps.volume_in = 1;

//
// Change verbose behavior for a source
//
t.sources.verbose.volume_in = false;
t.sources.verbose.pitch_in = false;
t.sources.verbose.mfcc_in = false;
t.sources.verbose.volume_in = true;

//
// Quit server
//
s.quit;
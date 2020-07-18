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
	pathSamples: PathName(thisProcess.nowExecutingPath).parentPath ++ "../samples/",
	defaults: (
		fps: 25
	)
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
		fps: d.defaults.fps,
		verbose: true
	),
	pitch_in: (
		oscTag: "/pitch-in",
		synthDefFactory: i[\makeSynthDef_Pitch],
		channels: 1,
		fps: d.defaults.fps,
		verbose: true
	),
	mfcc_in: (
		oscTag: "/mfcc-in",
		synthDefFactory: i[\makeSynthDef_MFCC],
		channels: 13,
		fps: d.defaults.fps,
		verbose: true
	),
	loudness_in: (
		oscTag: "/loudness-in",
		synthDefFactory: i[\makeSynthDef_Loudness],
		channels: 1,
		fps: d.defaults.fps,
		verbose: true
	),
	speccentroid_in: (
		oscTag: "/speccentroid-in",
		synthDefFactory: i[\makeSynthDef_SpecCentroid],
		channels: 1,
		fps: d.defaults.fps,
		verbose: true
	),
	onsets_in: (
		oscTag: "/onsets-in",
		synthDefFactory: i[\makeSynthDef_Onsets],
		channels: 1,
		fps: d.defaults.fps,
		verbose: false
	)
);

////////////////////////////////////////////////////////////////////////////////
// STATE - You may tinker with this in real-time (see bottom of this file)
////////////////////////////////////////////////////////////////////////////////
t = ();
t.ui = (
	window: nil,
);
t.sources = (
	busses: (),
	synths: (),
	tasks: (),
	uipollers: (),
	fps: (),
	verbose: (),
	uiViewsMultiSlider: ()
);

////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS
////////////////////////////////////////////////////////////////////////////////
f = ();

f.makeUI = {

	var counter=0, w=50, offset=10, totalWidth, h = 280;

	totalWidth = 2*offset;
	c.sources.keysValuesDo {
		|sourceName, sourceConfig|
		totalWidth = sourceConfig.channels * w + totalWidth;
	};

	t.ui.window = Window.new(
		"Machine Listening",
		Rect(200, 400, totalWidth, 280 + offset + offset)
	);

	c.sources.keysValuesDo {
		|sourceName, sourceConfig|

		var label;

		t.sources.uiViewsMultiSlider[sourceName] =  MultiSliderView.new(
			t.ui.window, Rect(counter * w + offset, offset, w * sourceConfig.channels, h)
		);
		t.sources.uiViewsMultiSlider.postln;
		t.sources.uiViewsMultiSlider[sourceName].valueThumbSize = 3;
		t.sources.uiViewsMultiSlider[sourceName].indexThumbSize = w;
		t.sources.uiViewsMultiSlider[sourceName].gap = 0;

		label = StaticText(
			t.ui.window,
			Rect(counter * w + offset, offset + h, w, offset);
		);
		label.string = sourceName;

		counter = counter + sourceConfig.channels;

	};

	t.ui.window.front;
};

f.makeTaskPoller = {
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

f.makeUIPoller = {
	|self, sourceName, bus, fps=1|

	"Making UI poller for bus :".post; bus.postln;

	Task.new({
		"Task started for UI poller: ".post; sourceName.postln;
		t.sources.fps[sourceName] = fps;
		loop {
			bus.getn(bus.numChannels, {
				|val|
				{
					t.sources.uiViewsMultiSlider[sourceName].value_(val * 0.9);
				}.defer; // Delay the evaluation of this Function by delta in seconds on AppClock.
			});
			(1/t.sources.fps[sourceName]).wait;
		};
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
		t.sources.tasks[sourceName] = f.makeTaskPoller(
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

f.stopUIPollers = {
	"--- stopUIPollers".postln;
	t.sources.uipollers.keysValuesDo {
		|sourceName,poller|
		poller.stop;
	};
	t.sources.uipollers.postln;
};


f.clearUIPollers = {
	"--- clearUIPollers".postln;
	f.stopUIPollers;
	t.sources.uipollers = ();
	t.sources.uipollers.postln;
};

f.makeUIPollers = {
	"--- makeUIPollers".postln;
	c.sources.keysValuesDo {
		|sourceName, sourceConfig|
		t.sources.uipollers[sourceName] = f.makeUIPoller(
			sourceName,
			t.sources.busses[sourceName],
			c.sources[sourceName].fps
		);
	};
};

f.playUIPollers = {
	"--- playUIPollers".postln;
	t.sources.uipollers.keysValuesDo {
		|sourceName, poller|
		poller.play;
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
	f.clearUIPollers;
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
ServerBoot.add(f[\makeUI]);
ServerQuit.add(f[\cleanup]);

////////////////////////////////////////////////////////////////////////////////
// Boot server
////////////////////////////////////////////////////////////////////////////////
s.waitForBoot({

	s.sync; // Forces wait for the server to be done (e.g., loading buffers...)

	f.makeSynthDefs;

	s.sync;

	ServerTree.add(f[\makeSynths]);
	ServerTree.add(f[\makeUIPollers]);
	ServerTree.add(f[\makeTasks]);

	ServerTree.add(f[\playUIPollers]);
	//ServerTree.add(f[\playTasks]);

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
t.sources.tasks.volume_in.start;
t.sources.tasks.pitch_in.start;
t.sources.tasks.mfcc_in.start;
t.sources.tasks.volume_in.stop;
t.sources.tasks.pitch_in.stop;
t.sources.tasks.mfcc_in.stop;
f.playTasks;
f.stopTasks;
f.playUIPollers;
t.sources.tasks.volume_in.start;
t.sources.tasks.loudness_in.start;
t.sources.tasks.onsets_in.start;
t.sources.tasks.onsets_in.stop;
t.sources.tasks.pitch_in.start;

//
// Change FPS (frames per second) for a source
//
t.sources.fps.volume_in = 25;
t.sources.fps.volume_in = 1;
t.sources.fps.mfcc_in = 25;

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


t.sources.fps
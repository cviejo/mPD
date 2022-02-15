#pragma once

#include "mpd.h"
#include "ofxLua.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif

extern "C" {
	void canvas_map(t_canvas *x, t_floatarg f);
	void canvas_mouse(t_canvas *x, t_floatarg xpos,  t_floatarg ypos,  t_floatarg which, t_floatarg mod);
	void canvas_motion(t_canvas *x, t_floatarg xpos,  t_floatarg ypos,  t_floatarg fmod);
	void canvas_mouseup(t_canvas *x, t_floatarg fxpos, t_floatarg fypos, t_floatarg fwhich);
	void canvas_editmode(t_canvas *x, t_floatarg state);
	int luaopen_mpd(lua_State* L);
}

// mutex.lock fixes luajit crashes when accessed from different threads (like scale events on android)
pd::PdBase base;
ofxLua lua;
ofMutex mtx;
ofSoundStream soundStream;
ofSoundStreamSettings audioSettings;

float* inputBuffer = NULL;
int ticks = 8;
bool computing = true;

//--------------------------------------------------------------------
void gui_hook(char* buffer){
	auto message = ofMessage(buffer);
	mtx.lock();
	lua.scriptGotMessage(message);
	mtx.unlock();
}

//--------------------------------------------------------------------
bool initAudio(){
	auto app = ofGetAppPtr();

	// by name
	// auto devices = soundStream.getMatchingDevices("ffff");
	// if (!devices.empty()) {
	// 	ofLogVerbose() << "setting out device";
	// 	audioSettings.setOutDevice(devices[1]);
	// }

	audioSettings.numInputChannels = 1;
	audioSettings.numOutputChannels = 2;
	audioSettings.sampleRate = 44100;
	audioSettings.bufferSize = base.blockSize() * ticks;
	audioSettings.setInListener(app);
	audioSettings.setOutListener(app);

	// auto devices = soundStream.getDeviceList();
	// audioSettings.setInDevice(devices[2]);
	// audioSettings.setOutDevice(devices[1]);
	// audioSettings.sampleRate = 48000;
	

	inputBuffer = new float[audioSettings.numInputChannels * audioSettings.bufferSize];

	soundStream.setup(audioSettings);

	return base.init(
		audioSettings.numInputChannels,
		audioSettings.numOutputChannels,
		audioSettings.sampleRate,
		false
	);
}

//--------------------------------------------------------------------
 bool mpd::init() {
	if (!initAudio()){
		clear();
		return false;
	}

	base.computeAudio(true);

	lua.setErrorCallback([](string& message) {
		ofLogWarning() << "Lua script error: " << message;
	});

	reload();

	return true;
}

//--------------------------------------------------------------------
Patch mpd::openPatch(const string& file, const string& folder) {
	Patch patch = base.openPatch(file, folder);

	if(!patch.isValid()) {
		ofLogError("Pd") << "opening patch \"" + file + "\" failed";
	}
	else {
		// ofLogVerbose("Pd") << "opened patch: "+ file + " path: " + folder;
		canvas_map((t_canvas*)patch.handle(), 1);
	}

	return patch;
}

//--------------------------------------------------------------------
void mpd::touch(ofTouchEventArgs &touch) {
	mtx.lock();
	// We use touchMoved for all touch events, less clutter since is passed anyway
	lua.scriptTouchMoved(touch); 
	mtx.unlock();
}

//--------------------------------------------------------------------
void mpd::key(ofKeyEventArgs &args) {
	mtx.lock();
	lua.scriptKeyPressed(args.key);
	mtx.unlock();
}

//--------------------------------------------------------------------
void mpd::closePatch(Patch& patch) {
	base.closePatch(patch);
}

//--------------------------------------------------------------------
void mpd::clear() {
	if(inputBuffer != NULL) {
		delete[] inputBuffer;
		inputBuffer = NULL;
	}
	base.clear();
}

//--------------------------------------------------------------------
void mpd::reload() {
	lua.scriptExit();
	lua.init(true);
	luaopen_mpd(lua);
	lua.doScript("main.lua", true);
	lua.scriptSetup();
}

//--------------------------------------------------------------------
void mpd::draw() {
	mtx.lock();
	lua.scriptDraw();
	mtx.unlock();
}

//--------------------------------------------------------------------
void updateSettings(int size, int inChannels, int outChannels){
	auto changed = 
		size != audioSettings.bufferSize ||
		inChannels != audioSettings.numInputChannels ||
		outChannels != audioSettings.numOutputChannels;
	if(changed) {
		ticks = size / base.blockSize();
		audioSettings.bufferSize = size;
		audioSettings.numInputChannels = inChannels;
		audioSettings.numOutputChannels = outChannels;
		// @TODO
		// init(audioSettings);
		base.computeAudio(computing);
	}
}

//--------------------------------------------------------------------
void mpd::mute(bool state) {
	// computing = !state;
}

//--------------------------------------------------------------------
void mpd::audioIn(float *input, int size, int channelCount) {
	if(!computing || inputBuffer == NULL) {
		return;
	}
	try {
		updateSettings(size, channelCount, audioSettings.numOutputChannels);
		memcpy(inputBuffer, input, size * channelCount * sizeof(float));
	}
	catch (...) {
		ofLogError("Pd") << "could not copy input buffer";
	}
}

//--------------------------------------------------------------------
void mpd::audioOut(float *output, int size, int channelCount) {
	if(!computing || inputBuffer == NULL) {
		return;
	}
	updateSettings(size, audioSettings.numInputChannels, channelCount);
	if (!base.processFloat(ticks, inputBuffer, output)){
		ofLogError("Pd") << "could not process output buffer";
	}
}

//--------------------------------------------------------------------
bool mpd::scale(const string& type, float value, int x, int y) {
	mtx.lock();
	float scale = (float)lua.getNumber("Scale", 1);
	if (type == "scroll") {
		scale +=  value * 0.1f;
	} else if (type == "scale") {
		scale *=  value;
	}
	// handle scalingEnd / begin
	lua.setNumber("Scale", scale);
	lua.setBool("UpdateNeeded", true);
	mtx.unlock();
	return true;
}


// //--------------------------------------------------------------------
//  void mpd::keyPressed(ofKeyEventArgs &args) {
// 	//  ofLogVerbose() << args.key;
// 	// if (args.key == 114){
// 	// 	reload();
// 	// }
// 	lua.scriptKeyPressed(args.key);
// }


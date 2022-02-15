#pragma once

#include "mpd.h"
#include "ofxLua.h"
#include <queue>
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif

using std::queue;

extern "C" {
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
queue<ofMessage> pdMessages;

//--------------------------------------------------------------------
void gui_hook(char* buffer){
	auto message = ofMessage(buffer);
	pdMessages.push(message);
}

//--------------------------------------------------------------
void mpd::pdsend(const string& cmd){
	t_binbuf* buffer = binbuf_new();

	binbuf_text(buffer, (char*)cmd.c_str(), cmd.length());
	binbuf_eval(buffer, 0, 0, 0);
	binbuf_free(buffer);
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
	// audioSettings.setInDevice(devices[3]);
	// audioSettings.setOutDevice(devices[4]);
	// // audioSettings.sampleRate = 48000;
	

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
void mpd::touch(ofTouchEventArgs &touch) {
	mtx.lock();
	// touchMoved for all events, less clutter since type is passed anyway
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
void mpd::update() {
	mtx.lock();
	while (!pdMessages.empty()) {
		lua.scriptGotMessage(pdMessages.front());
		pdMessages.pop();
	}
	mtx.unlock();
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


//--------------------------------------------------------------------
// Patch mpd::openPatch(const string& file, const string& folder) {
// 	Patch patch = base.openPatch(file, folder);
	// if(!patch.isValid()) {
	// 	ofLogError("Pd") << "opening patch \"" + file + "\" failed";
	// }
	// else {
	// 	canvas_map((t_canvas*)patch.handle(), 1);
	// }
// 	return patch;
// }
// //--------------------------------------------------------------------
// void mpd::closePatch(Patch& patch) {
// 	base.closePatch(patch);
// }


#pragma once

#include "ofMain.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif
#include "./libs/pd/cpp/PdBase.hpp"
#include "./libs/pd/pure-data/src/m_pd.h"

using namespace pd;
using std::string;

namespace mpd {
	void clear();
	void reload();
	void init();
	bool initAudio(int inIndex, int outIndex, float sampleRate);
	void draw();
	void update();

	void key(ofKeyEventArgs &args);
	void touch(ofTouchEventArgs &touch);

	void mute(bool state);
	void audioIn(float *input, int size, int channelCount);
	void audioOut(float *output, int size, int channelCount);

	bool scale(const string& type, float value, int x, int y);

#if defined(TARGET_ANDROID)
	void swipe(ofxAndroidSwipeEventArgs& args);
#endif

	void pdsend(const string& cmd);
}
	// Patch openPatch(const string& file, const string& folder);
	// void closePatch(Patch& patch);

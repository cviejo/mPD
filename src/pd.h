#pragma once

#include "ofMain.h"
#include "PdBase.hpp"

namespace pd {

	extern PdBase base;
	extern ofSoundStreamSettings settings;
	extern float* buffer;
	extern int ticks;

	extern bool init(ofSoundStreamSettings &settings);
	extern void audioIn(float *input, int bufferSize, int nChannels);
	extern void audioOut(float *output, int bufferSize, int nChannels);
	extern Patch openPatch(const std::string &patch);
}

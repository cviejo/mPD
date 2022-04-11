#pragma once

#include <string>

using std::string;

namespace audio {
	bool init(const string& input, const string& output, float sampleRate);
	bool init(int inputChannels, int outputChannels, float sampleRate);
	void mute(bool state);
	void clear();

	void in(float* input, int size, int channelCount);
	void out(float* output, int size, int channelCount);
}  // namespace audio

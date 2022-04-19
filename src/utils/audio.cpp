#include "audio.h"
#include "PdBase.hpp"
#include "ofMain.h"

auto base = pd::PdBase();
auto soundStream = ofSoundStream();
auto soundStreamSettings = ofSoundStreamSettings();
auto computing = true;
auto ticks = 8;
auto inputBuffer = (float*)NULL;

//--------------------------------------------------------------------
bool audio::init(int inputChannels, int outputChannels, float sampleRate) {
	soundStreamSettings.numInputChannels = inputChannels;
	soundStreamSettings.numOutputChannels = outputChannels;
	soundStreamSettings.sampleRate = sampleRate;
	soundStreamSettings.bufferSize = base.blockSize() * ticks;
	soundStreamSettings.setInListener(ofGetAppPtr());
	soundStreamSettings.setOutListener(ofGetAppPtr());

	inputBuffer = new float[inputChannels * soundStreamSettings.bufferSize];

	soundStream.setup(soundStreamSettings);

	bool result = base.init(inputChannels, outputChannels, sampleRate, true);

	if (result) {
		base.computeAudio(true);
	}

	return result;
}

//--------------------------------------------------------------------
bool audio::init(const string& input, const string& output, float sampleRate) {
	auto inDevice = soundStream.getMatchingDevices(input)[0];
	auto outDevice = soundStream.getMatchingDevices(output)[0];

	soundStreamSettings.setInDevice(inDevice);
	soundStreamSettings.setOutDevice(outDevice);

	return init(inDevice.inputChannels, outDevice.outputChannels, sampleRate);
}

//--------------------------------------------------------------------
void audio::mute(bool state) {
	// computing = !state;
}

//--------------------------------------------------------------------
void audio::clear() {
	if (inputBuffer != NULL) {
		delete[] inputBuffer;
		inputBuffer = NULL;
	}
	base.clear();
}

//--------------------------------------------------------------------
void updateSettings(int size, int inChannels, int outChannels) {
	auto changed = size != soundStreamSettings.bufferSize ||
	               inChannels != soundStreamSettings.numInputChannels ||
	               outChannels != soundStreamSettings.numOutputChannels;
	if (changed) {
		ticks = size / base.blockSize();
		soundStreamSettings.bufferSize = size;
		soundStreamSettings.numInputChannels = inChannels;
		soundStreamSettings.numOutputChannels = outChannels;
		// TODO
		// init(settings);
		base.computeAudio(computing);
	}
}

//--------------------------------------------------------------------
void audio::in(float* input, int size, int channelCount) {
	if (!computing || inputBuffer == NULL) {
		return;
	}
	try {
		updateSettings(size, channelCount, soundStreamSettings.numOutputChannels);
		memcpy(inputBuffer, input, size * channelCount * sizeof(float));
	} catch (...) {
		ofLogError("Pd") << "could not copy input buffer";
	}
}

//--------------------------------------------------------------------
void audio::out(float* output, int size, int channelCount) {
	if (!computing || inputBuffer == NULL) {
		return;
	}
	updateSettings(size, soundStreamSettings.numInputChannels, channelCount);
	if (!base.processFloat(ticks, inputBuffer, output)) {
		ofLogError("Pd") << "could not process output buffer";
	}
}

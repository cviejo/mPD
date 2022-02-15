#include "pd.h"
#include "m_pd.h"

extern "C" {
	void canvas_map(t_canvas *x, t_floatarg f);
}

void gui_hook(char* msg){
	ofLogVerbose("gui_hook") << msg;
}

namespace pd {

	PdBase base;
	ofSoundStreamSettings settings;
	float* buffer = NULL;
	int ticks;

	//--------------------------------------------------------------------
	bool init(ofSoundStreamSettings &settings) {
		if (!base.init(settings.numInputChannels, settings.numOutputChannels, settings.sampleRate, false)){
			ofLogError("Pd") << "could not init";
			// clear();
			return false;
		}

		pd::settings = settings;
		
		ticks = settings.bufferSize / base.blockSize();

		// allocate buffers
		buffer = new float[settings.numInputChannels * settings.bufferSize];

		return true;
	}

	//--------------------------------------------------------------------
	Patch openPatch(const std::string &patch) {
		string fullpath = ofFilePath::getAbsolutePath(ofToDataPath(patch));
		string file = ofFilePath::getFileName(fullpath);
		string folder = ofFilePath::getEnclosingDirectory(fullpath);

		// trim the trailing slash Poco::Path always adds ... blarg
		if(folder.size() > 0 && folder.at(folder.size() - 1) == '/') {
			folder.erase(folder.end() - 1);
		}

		ofLogVerbose("Pd") << "opening patch: "+ file + " path: " + folder;

		// [; pd open file folder(
		Patch p = base.openPatch(file.c_str(), folder.c_str());
		if(!p.isValid()) {
			ofLogError("Pd") << "opening patch \"" + file + "\" failed";
		}

		// set canvas visible to 1
		canvas_map((t_canvas*)p.handle(), 1);
		
		return p;
	}

	//--------------------------------------------------------------------
	void updateSettings(int bufferSize, int inChannels, int outChannels){
		if(bufferSize != settings.bufferSize || inChannels != settings.numInputChannels || outChannels != settings.numOutputChannels) {
			ticks = bufferSize / base.blockSize();
			settings.bufferSize = bufferSize;
			settings.numInputChannels = inChannels;
			settings.numOutputChannels = outChannels;
			ofLogVerbose("Pd") << "buffer size or num channels updated";
			init(settings);
			// TODO
			// PdBase::computeAudio(computing);
		}
	}

	//--------------------------------------------------------------------
	void audioIn(float *input, int bufferSize, int nChannels) {
		try {
			if(buffer != NULL) {
				updateSettings(bufferSize, nChannels, settings.numOutputChannels);

				memcpy(buffer, input, bufferSize * nChannels * sizeof(float));
			}
		}
		catch (...) {
			ofLogError("Pd") << "could not copy input buffer";
		}
	}

	//--------------------------------------------------------------------
	void audioOut(float *output, int bufferSize, int nChannels) {
		if(buffer != NULL) {
			updateSettings(bufferSize, settings.numInputChannels, nChannels);

			if (!base.processFloat(ticks, buffer, output)){
				ofLogError("Pd") << "could not process output buffer";
			}
		}
	}

}

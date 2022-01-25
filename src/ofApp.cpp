#include "ofApp.h"

void ofApp::setup() {
#if defined(TARGET_ANDROID)
	ofAddListener(ofxAndroidEvents().scaleBegin, this, &ofApp::onScaleBegin);
	ofAddListener(ofxAndroidEvents().scale, this, &ofApp::onScale);
	ofAddListener(ofxAndroidEvents().scaleEnd, this, &ofApp::onScaleEnd);
#elif !defined(TARGET_OF_IOS)
	ofAddListener(ofEvents().mouseScrolled, this, &ofApp::mouseScrolled);
#endif

	lua.addListener(this);

	#ifdef TARGET_LINUX_ARM
		// longer latency for Raspberry PI
		int ticksPerBuffer = 32; // 32 * 64 = buffer len of 2048
		int numInputs = 0; // no built in mic
	#else
		int ticksPerBuffer = 8; // 8 * 64 = buffer len of 512
		int numInputs = 1;
	#endif

	ofSoundStreamSettings settings;

	settings.numInputChannels = 1;
	settings.numOutputChannels = 2;
	settings.sampleRate = 44100;
	settings.bufferSize = pd::base.blockSize() * ticksPerBuffer;
	settings.setInListener(this);
	settings.setOutListener(this);

	ofSoundStreamSetup(settings);

	if(!pd::init(settings)) {
		OF_EXIT_APP(1);
	}

	pd::base.computeAudio(true);
	Patch patch = pd::openPatch("test.pd");

	this->reset();
}

void ofApp::draw() {
	lua.setNumber("Scale", scale);
	if(updateNeeded){
		lua.setBool("UpdateNeeded", updateNeeded);
		updateNeeded = false;
	}
	lua.scriptDraw();
}

void ofApp::reset() {
	lua.scriptExit();
	lua.init(true);
	lua.doScript("main.lua", true);
	lua.scriptSetup();
}

void ofApp::keyPressed(int key) {
	if (key == 114){
		this->reset();
	}
}

void ofApp::touchDown(ofTouchEventArgs &touch) {}

void ofApp::touchUp(ofTouchEventArgs &touch) {}

void ofApp::touchMoved(ofTouchEventArgs &touch) {
	lua.scriptTouchMoved(touch);
}

void ofApp::touchDoubleTap(ofTouchEventArgs &touch) {
	this->reset();
}


void ofApp::audioReceived(float * input, int bufferSize, int nChannels) {
	pd::audioIn(input, bufferSize, nChannels);
	// if (!_computing){ return; }
   //
	// // TODO: if computing
	// PdGui::instance().audioIn(input, bufferSize, nChannels);
}


void ofApp::audioRequested(float * output, int bufferSize, int nChannels) {
	pd::audioOut(output, bufferSize, nChannels);
	// if (!_computing){ return; }
   //
	// // TODO: if computing
	// PdGui::instance().audioOut(output, bufferSize, nChannels);
}



void ofApp::errorReceived(std::string& msg) {
	ofDrawBitmapString(msg, 200, 200);
	ofLogVerbose() << "lua error: " << msg;
}

void ofApp::exit() {
	ofSoundStreamStop();
}


#if defined(TARGET_ANDROID)
bool ofApp::onScaleBegin(ofxAndroidScaleEventArgs& aArgs) {
	// lua.setBool("Scaling", true);
	//
	// _scaling = true;
	// AppEvent event(AppEvent::TYPE_SCALE_BEGIN);
	// ofNotifyEvent(AppEvent::events, event);

	return true;
}


//--------------------------------------------------------------
bool ofApp::onScale(ofxAndroidScaleEventArgs& aArgs) {
	scale *= aArgs.getScaleFactor();

	//
	// AppEvent event(AppEvent::TYPE_SCALE, "", aArgs.getFocusX(), aArgs.getFocusY());
	// event.value = aArgs.getScaleFactor();
	// ofNotifyEvent(AppEvent::events, event);
	return true;
}


//--------------------------------------------------------------
bool ofApp::onScaleEnd(ofxAndroidScaleEventArgs& aArgs) {
	// lua.setBool("Scaling", false);

	// _scaling = false;
   //
	// AppEvent event(AppEvent::TYPE_SCALE_END);
   //
	// ofNotifyEvent(AppEvent::events, event);
   //
	return true;
}
#endif

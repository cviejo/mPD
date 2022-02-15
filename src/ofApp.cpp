#include "ofApp.h"
#include "mpd.h"
#include "utils/events.h"

void ofApp::setup() {
	watcher.addPath(ofToDataPath("main.lua", true));
	watcher.addPath(ofToDataPath("canvas.lua", true));
	watcher.start();

	mpd::init();
}

void ofApp::update() {
	while(watcher.waitingEvents()) {
		watcher.stop();
		watcher.nextEvent();
		mpd::reload();
		watcher.start();
	}
}

void ofApp::draw() {
	mpd::draw();
}

void ofApp::keyPressed(ofKeyEventArgs &args) {
	mpd::key(args);
}

void ofApp::mousePressed(int x, int y, int button) {
	mpd::touch(*new ofTouchEventArgs(ofTouchEventArgs::down, x, y, button));
}

void ofApp::mouseReleased(int x, int y, int button) {
	mpd::touch(*new ofTouchEventArgs(ofTouchEventArgs::up, x, y, button));
}

void ofApp::mouseDragged(int x, int y, int button) {
	mpd::touch(*new ofTouchEventArgs(ofTouchEventArgs::move, x, y, button));
}

void ofApp::mouseScrolled(ofMouseEventArgs& args) {
	// scale += mouse.scrollY * 0.1f;
	ofLogVerbose() << args.scrollY;
}

void ofApp::audioReceived(float * buffer, int size, int channelCount) {
	mpd::audioIn(buffer, size, channelCount);
}

void ofApp::audioRequested(float * buffer, int size, int channelCount) {
	mpd::audioOut(buffer, size, channelCount);
}


void ofApp::touchDown(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchMoved(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchUp(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchDoubleTap(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchCancelled(ofTouchEventArgs& args) { mpd::touch(args); }

#if defined(TARGET_ANDROID)
bool ofApp::scaleBegin(ofxAndroidScaleEventArgs& aArgs) { return true; }

bool ofApp::scale(ofxAndroidScaleEventArgs& aArgs) { return true; }

bool ofApp::scaleEnd(ofxAndroidScaleEventArgs& aArgs) { return true; }

void ofApp::swipe(ofxAndroidSwipeDir swipeDir, int id) {}
#endif

void ofApp::exit() {
	ofSoundStreamStop();
}

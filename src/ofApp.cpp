#include "ofApp.h"
#include "mpd.h"

void ofApp::setup() {
	watcher.addPath(ofToDataPath("main.lua", true));
	watcher.addPath(ofToDataPath("canvas.lua", true));
	watcher.addPath(ofToDataPath("parse.lua", true));
	watcher.addPath(ofToDataPath("events.lua", true));
	watcher.start();

#if defined(TARGET_ANDROID)
	ofAddListener(ofxAndroidEvents().scaleBegin, this, &ofApp::scaleBegin);
	ofAddListener(ofxAndroidEvents().scale, this, &ofApp::scale);
	ofAddListener(ofxAndroidEvents().scaleEnd, this, &ofApp::scaleEnd);
#endif

	mpd::init();
}

void ofApp::update() {
	while(watcher.waitingEvents()) {
		watcher.stop();
		watcher.nextEvent();
		mpd::reload();
		watcher.start();
	}
	mpd::update();
}

void ofApp::draw() {
	mpd::draw();
}

void ofApp::keyPressed(ofKeyEventArgs &args) {
	mpd::key(args);
}

void ofApp::audioReceived(float * buffer, int size, int channelCount) {
	mpd::audioIn(buffer, size, channelCount);
}

void ofApp::audioRequested(float * buffer, int size, int channelCount) {
	mpd::audioOut(buffer, size, channelCount);
}

#if defined(TARGET_ANDROID)
bool ofApp::scaleBegin(ofxAndroidScaleEventArgs& x) {
	return mpd::scale("scaleBegin", x.getScaleFactor(), x.getFocusX(), x.getFocusY());
}

bool ofApp::scale(ofxAndroidScaleEventArgs& x) {
	return mpd::scale("scale", x.getScaleFactor(), x.getFocusX(), x.getFocusY());
}

bool ofApp::scaleEnd(ofxAndroidScaleEventArgs& x) {
	return mpd::scale("scaleEnd", x.getScaleFactor(), x.getFocusX(), x.getFocusY());
}

void ofApp::swipe(ofxAndroidSwipeDir swipeDir, int id) { }

void ofApp::touchDown(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchMoved(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchUp(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchDoubleTap(ofTouchEventArgs& args) { mpd::touch(args); }

void ofApp::touchCancelled(ofTouchEventArgs& args) { mpd::touch(args); }
#else 
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
	mpd::scale("scroll", args.scrollY, mouseX, mouseY);
}
#endif


void ofApp::exit() {
	ofSoundStreamStop();
}

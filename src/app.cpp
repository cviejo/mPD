#include "app.h"
#include "mpd.h"
#include "utils/audio.h"

void ofApp::setup() {
#if defined(TARGET_ANDROID)
	ofAddListener(ofxAndroidEvents().scaleBegin, this, &ofApp::scaleBegin);
	ofAddListener(ofxAndroidEvents().scale, this, &ofApp::scale);
	ofAddListener(ofxAndroidEvents().scaleEnd, this, &ofApp::scaleEnd);
	ofAddListener(ofxAndroidEvents().deviceOrientationChanged, this, &ofApp::orientationChanged);
#endif
	mpd::setup();
}

void ofApp::update() {
	mpd::update();
}

void ofApp::draw() {
	mpd::draw();
}

void ofApp::keyPressed(ofKeyEventArgs& args) {
	mpd::key(args);
}

void ofApp::gotMessage(ofMessage msg) {
	mpd::push(msg.message);
}

void ofApp::audioReceived(float* buffer, int size, int channelCount) {
	audio::in(buffer, size, channelCount);
}

void ofApp::audioRequested(float* buffer, int size, int channelCount) {
	audio::out(buffer, size, channelCount);
}

bool scaleEvent(const string& type, float x, float y, float scale) {
	auto message = type + " " + ofToString(x) + " " + ofToString(y) + " " + ofToString(scale);
	mpd::push(message);
	return true;
}

#if defined(TARGET_ANDROID)
bool ofApp::scaleBegin(ofxAndroidScaleEventArgs& x) {
	return scaleEvent("scaleBegin", x.getFocusX(), x.getFocusY(), x.getScaleFactor());
}

bool ofApp::scale(ofxAndroidScaleEventArgs& x) {
	return scaleEvent("scale", x.getFocusX(), x.getFocusY(), x.getScaleFactor());
}

bool ofApp::scaleEnd(ofxAndroidScaleEventArgs& x) {
	return scaleEvent("scaleEnd", x.getFocusX(), x.getFocusY(), x.getScaleFactor());
}

void ofApp::orientationChanged(ofOrientation& x) {
	auto message = "orientation " + ofToString((int)x);
	mpd::push(message);
}

void ofApp::swipe(ofxAndroidSwipeDir swipeDir, int id) {}

void ofApp::touchDown(ofTouchEventArgs& args) {
	mpd::touch(args);
}

void ofApp::touchMoved(ofTouchEventArgs& args) {
	mpd::touch(args);
}

void ofApp::touchUp(ofTouchEventArgs& args) {
	mpd::touch(args);
}

void ofApp::touchDoubleTap(ofTouchEventArgs& args) {
	mpd::touch(args);
}

void ofApp::touchCancelled(ofTouchEventArgs& args) {
	mpd::touch(args);
}
#else
void ofApp::mousePressed(int x, int y, int button) {
	auto touch = ofTouchEventArgs(ofTouchEventArgs::down, x, y, button);
	mpd::touch(touch);
}

void ofApp::mouseReleased(int x, int y, int button) {
	auto touch = ofTouchEventArgs(ofTouchEventArgs::up, x, y, button);
	mpd::touch(touch);
}

void ofApp::mouseDragged(int x, int y, int button) {
	auto touch = ofTouchEventArgs(ofTouchEventArgs::move, x, y, button);
	mpd::touch(touch);
}

void ofApp::mouseScrolled(ofMouseEventArgs& args) {
	scaleEvent("scroll", mouseX, mouseY, args.scrollY);
}
#endif

void ofApp::exit() {
	ofSoundStreamStop();
}

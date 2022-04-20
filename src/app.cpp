#include "app.h"
#include "mpd.h"
#include "utils/audio.h"

void ofApp::setup() {
#if defined(TARGET_ANDROID)
	ofAddListener(ofxAndroidEvents().scaleBegin, this, &ofApp::scaleBegin);
	ofAddListener(ofxAndroidEvents().scale, this, &ofApp::scale);
	ofAddListener(ofxAndroidEvents().scaleEnd, this, &ofApp::scaleEnd);
#else
	auto xs = vector<string>{"main.lua",      "ui/cords.lua", "ui/button.lua",   "ui/frame2.lua",
	                         "ui/canvas.lua", "parse.lua",    "ui/draw-item.lua"};
	for (auto x : xs) {
		watcher.addPath(ofToDataPath("app/" + x, true));
	}
	watcher.start();
#endif
	mpd::setup();
}

void ofApp::update() {
	while (watcher.waitingEvents()) {
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

void ofApp::keyPressed(ofKeyEventArgs& args) {
	mpd::key(args);
}

void ofApp::audioReceived(float* buffer, int size, int channelCount) {
	audio::in(buffer, size, channelCount);
}

void ofApp::audioRequested(float* buffer, int size, int channelCount) {
	audio::out(buffer, size, channelCount);
}

#if defined(TARGET_ANDROID)
bool ofApp::scaleBegin(ofxAndroidScaleEventArgs& x) {
	mpd::scale("scaleBegin", x.getScaleFactor(), x.getFocusX(), x.getFocusY());
	return true;
}

bool ofApp::scale(ofxAndroidScaleEventArgs& x) {
	mpd::scale("scale", x.getScaleFactor(), x.getFocusX(), x.getFocusY());
	return true;
}

bool ofApp::scaleEnd(ofxAndroidScaleEventArgs& x) {
	mpd::scale("scaleEnd", x.getScaleFactor(), x.getFocusX(), x.getFocusY());
	return true;
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
	mpd::scale("scroll", args.scrollY, mouseX, mouseY);
}
#endif

void ofApp::exit() {
	ofSoundStreamStop();
}

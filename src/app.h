#pragma once

#include "ofMain.h"
#include "ofxLua.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif

#if defined(TARGET_ANDROID)
class ofApp : public ofxAndroidApp, ofxLuaListener {
#else
class ofApp : public ofBaseApp, ofxLuaListener {
#endif

public:
	void setup();
	void update();
	void draw();
	void exit();
	void audioReceived(float* buffer, int size, int channelCount);
	void audioRequested(float* buffer, int size, int channelCount);

	void gotMessage(ofMessage msg) {}
	void errorReceived(std::string& msg) {}

	void keyPressed(ofKeyEventArgs& args);
#if defined(TARGET_ANDROID)
	void touchDown(ofTouchEventArgs& args);
	void touchMoved(ofTouchEventArgs& args);
	void touchUp(ofTouchEventArgs& args);
	void touchDoubleTap(ofTouchEventArgs& args);
	void touchCancelled(ofTouchEventArgs& args);
	bool scaleBegin(ofxAndroidScaleEventArgs& aArgs);
	bool scale(ofxAndroidScaleEventArgs& aArgs);
	bool scaleEnd(ofxAndroidScaleEventArgs& aArgs);
	void swipe(ofxAndroidSwipeDir swipeDir, int id);
	void orientationChanged(ofOrientation& x);
#else
	void mousePressed(int x, int y, int button);
	void mouseReleased(int x, int y, int button);
	void mouseDragged(int x, int y, int button);
	void mouseScrolled(ofMouseEventArgs& mouse);
#endif
};

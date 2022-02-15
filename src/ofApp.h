#pragma once

#include "ofMain.h"
#include "ofxLua.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif
#include "./utils/PathWatcher.h"

#if defined(TARGET_ANDROID)
class ofApp : public ofxAndroidApp, ofxLuaListener {
#else
class ofApp : public ofBaseApp, ofxLuaListener {
#endif

	public:
		PathWatcher watcher;

		void setup();
		void update();
		void draw();
		void exit();
		void audioReceived(float * buffer, int size, int channelCount);
		void audioRequested(float * buffer, int size, int channelCount);

		void gotMessage(ofMessage msg) {}
		void errorReceived(std::string &msg) {}

		void keyPressed(ofKeyEventArgs &args);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseDragged(int x, int y, int button);
		void mouseScrolled(ofMouseEventArgs & mouse);
		void touchDown(ofTouchEventArgs& args);
		void touchMoved(ofTouchEventArgs& args);
		void touchUp(ofTouchEventArgs& args);
		void touchDoubleTap(ofTouchEventArgs& args);
		void touchCancelled(ofTouchEventArgs& args);
#if defined(TARGET_ANDROID)
		bool scaleBegin(ofxAndroidScaleEventArgs& aArgs);
		bool scale(ofxAndroidScaleEventArgs& aArgs);
		bool scaleEnd(ofxAndroidScaleEventArgs& aArgs);
		void swipe(ofxAndroidSwipeDir swipeDir, int id);
#endif
};

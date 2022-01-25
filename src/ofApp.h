#pragma once

#include "ofMain.h"
#include "pd.h"
#include "ofxLua.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#elif defined(TARGET_OF_IOS)
#include "ofxiOS.h"
#include "ofPinchGestureRecognizer.h"
#endif

using namespace pd;

#if defined(TARGET_ANDROID)
class ofApp : public ofxAndroidApp, ofxLuaListener {
#elif defined(TARGET_OF_IOS)
class ofApp : public ofxiOSApp, ofxLuaListener {
#else
class ofApp : public ofBaseApp, ofxLuaListener {
#endif

	public:
		float scale = 1.0f;
		bool updateNeeded = false;
		bool lock = false;
		ofxLua lua;
		// ofxPd pd;

		void setup();
		void draw();

		void audioReceived(float * input,  int bufferSize, int channelCount);
		void audioRequested(float * output, int bufferSize, int channelCount);

		void keyPressed(int key);
		
		void touchDown(ofTouchEventArgs &touch);
		void touchMoved(ofTouchEventArgs &touch);
		void touchUp(ofTouchEventArgs &touch);
		void touchDoubleTap(ofTouchEventArgs &touch);
		// void touchCancelled(ofTouchEventArgs &touch);

		void reset();
		void exit();

		void errorReceived(std::string &msg);

#if defined(TARGET_ANDROID)
		bool onScaleBegin(ofxAndroidScaleEventArgs& aArgs);
		bool onScale(ofxAndroidScaleEventArgs& aArgs);
		bool onScaleEnd(ofxAndroidScaleEventArgs& aArgs);
		// void swipe(ofxAndroidSwipeDir swipeDir, int id);
#elif defined(TARGET_OF_IOS)
		ofPinchGestureRecognizer* _pinch;
#else
		void mouseScrolled(ofMouseEventArgs & mouse) {
			updateNeeded = true;
			scale += mouse.scrollY * 0.1f;
		}
		void mouseDragged(int x, int y, int id) {
			auto args = new ofTouchEventArgs(ofTouchEventArgs::move, x, y, id);
			touchMoved(*args);
		}
		void mousePressed(int x, int y, int id) {
			auto args = new ofTouchEventArgs(ofTouchEventArgs::down, x, y, id);
			touchDown(*args);
		}
		void mouseReleased(int x, int y, int id) {
			auto args = new ofTouchEventArgs(ofTouchEventArgs::up, x, y, id);
			touchUp(*args);
		}
		// void mouseScrolled(ofMouseEventArgs & mouse);
#endif
};

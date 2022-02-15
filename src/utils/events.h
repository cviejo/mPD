#include "ofMain.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif

namespace events {

	static std::function<void(ofTouchEventArgs& message)> touchListener = nullptr;

	static void touchEvent(ofTouchEventArgs &touch) {
		touchListener(touch);
	}

	static void mouseEvent(ofMouseEventArgs & args) {
		if (args.type == ofMouseEventArgs::Type::Pressed) {
			touchEvent(*new ofTouchEventArgs(ofTouchEventArgs::down, args.x, args.y, args.button));
		}
		else if (args.type == ofMouseEventArgs::Type::Dragged) {
			touchEvent(*new ofTouchEventArgs(ofTouchEventArgs::move, args.x, args.y, args.button));
		}
		else if (args.type == ofMouseEventArgs::Type::Released) {
			touchEvent(*new ofTouchEventArgs(ofTouchEventArgs::up, args.x, args.y, args.button));
		}
	}

	static void onTouch(std::function<void(ofTouchEventArgs& args)> const &listener) {
		touchListener = listener;

		ofAddListener(ofEvents().touchDown, &touchEvent);
		ofAddListener(ofEvents().touchUp, &touchEvent);
		ofAddListener(ofEvents().touchMoved, &touchEvent);
		ofAddListener(ofEvents().touchDoubleTap, &touchEvent);
		ofAddListener(ofEvents().mouseDragged, &mouseEvent);
		ofAddListener(ofEvents().mousePressed, &mouseEvent);
		ofAddListener(ofEvents().mouseReleased, &mouseEvent);
	}

	#if defined(TARGET_ANDROID)
	static std::function<void(ofxAndroidScaleEventArgs& args)> scaleListener = nullptr;

	static bool scaleBegin(ofxAndroidScaleEventArgs& args) {
		// lua.setBool("Scaling", true);
		return true;
	}

	static bool scale(ofxAndroidScaleEventArgs& args) {
		// scale *= args.getScaleFactor();
		// // AppEvent event(AppEvent::TYPE_SCALE, "", args.getFocusX(), args.getFocusY());
		return true;
	}

	static bool scaleEnd(ofxAndroidScaleEventArgs& args) {
		// lua.setBool("Scaling", false);
		return true;
	}
	// static void swipe(ofxAndroidSwipeEventArgs& args) {}
	
	static void onScale(std::function<void(ofxAndroidScaleEventArgs& args)> const &listener) {
		scaleListener = listener;

		ofAddListener(ofxAndroidEvents().scaleBegin, &scaleBegin);
		ofAddListener(ofxAndroidEvents().scale, &scale);
		ofAddListener(ofxAndroidEvents().scaleEnd, &scaleEnd);
	// ofAddListener(ofxAndroidEvents().swipe, &swipe);
	}
	#endif
}

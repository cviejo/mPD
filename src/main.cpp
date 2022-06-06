#include "app.h"
#include "ofMain.h"

int main() {
	ofSetLogLevel(OF_LOG_NOTICE);

#ifdef TARGET_ANDROID
	// needed so textures don't get cleared when app is paused
	ofxAndroidWindowSettings settings;
	ofCreateWindow(settings);
#else
	ofSetupOpenGL(400, 768, OF_WINDOW);
#endif

	return ofRunApp(new ofApp());
}

#ifdef TARGET_ANDROID
void ofAndroidActivityInit() {
	main();
}

void ofAndroidApplicationInit() {}
#endif

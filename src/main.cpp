#include "app.h"
#include "ofMain.h"
#ifdef TARGET_ANDROID
#include <jni.h>
#endif

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

void Java_org_mpd_OFActivity_javaMessage(JNIEnv* env, jobject obj, jstring event, jstring data) {
	jboolean iscopy;

	const char* message = env->GetStringUTFChars(data, &iscopy);

	((ofApp*)ofGetAppPtr())->hostMessage(message);
}
#endif

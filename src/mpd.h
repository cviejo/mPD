#pragma once

#include <string>
#include <vector>
#include "ofMain.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif
#include "m_pd.h"
#include "mpd.h"

using std::find;
using std::map;
using std::string;

class PdNode {
public:
	int x;
	int y;
	int width;
	int height;
	int outletCount;

	t_gobj* ref;
};

class PdMessage {
public:
	string canvasId;
	string cmd;
	string message;
	string value;
	vector<string> tags;
	vector<ofPoint> points;
	map<string, string> params;

	void addPoint(string x, string y) {
		auto point = ofPoint(ofToInt(x), ofToInt(y));
		points.push_back(point);
	}
	bool hasTag(const string& tag) { return find(tags.begin(), tags.end(), tag) != tags.end(); }
};

namespace mpd {
	void setup();
	void draw();
	void update();

	void key(ofKeyEventArgs& args);
	void touch(ofTouchEventArgs& touch);

	void exit();
	void reload();
	float getDPI();

	void push(const string& push);
	void cmd(const string& cmd);

	PdNode* getNode(int x, int y);
	t_gobj* findBox(int x, int y);
	int outletCount(t_gobj* x);
	bool selectionActive();

	void pdsend(const string& cmd);

#if defined(TARGET_ANDROID)
	void swipe(ofxAndroidSwipeEventArgs& args);
#endif
}  // namespace mpd

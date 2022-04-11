#include "graphics.h"
#include "ofMain.h"

void gfx::drawRectangle(int x1, int y1, int x2, int y2, const string& color, const string& fill) {
	auto p1 = ofPoint(x1, y1);

	auto rect = ofRectangle(p1, x2, y2);
	if (!fill.empty()) {
		ofFill();
		ofSetHexColor(ofHexToInt(fill));
		ofDrawRectangle(rect);
	}
	if (!color.empty()) {
		ofNoFill();
		ofSetHexColor(ofHexToInt(color));
		ofDrawRectangle(rect);
	}
}

void gfx::drawEllipse(int x1, int y1, int x2, int y2, const string& color, const string& fill) {
	auto p1 = ofPoint(x1, y1);
	auto p2 = ofPoint(x2, y2);
	auto rect = ofRectangle(p1, p2);

	if (!fill.empty()) {
		ofFill();
		ofSetHexColor(ofHexToInt(fill));
		ofDrawEllipse(rect.getCenter(), rect.width, rect.height);
	}
	if (!color.empty()) {
		ofNoFill();
		ofSetHexColor(ofHexToInt(color));
		ofDrawEllipse(rect.getCenter(), rect.width, rect.height);
	}
}

void gfx::drawLine(int x1, int y1, int x2, int y2, const string& color, float width) {
	ofSetHexColor(ofHexToInt(color));
	ofSetLineWidth(width);
	ofDrawLine(x1, y1, x2, y2);
}

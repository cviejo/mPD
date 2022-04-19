#pragma once

#include "mpd.h"
#include <queue>
#include "ofxLua.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif
#include "audio.h"
#include "g_canvas.h"
#include "graphics.h"

extern "C" {
	t_object* pd_checkobject(t_pd* x);
	t_canvas* canvas_getcurrent(void);
	t_gobj*
	canvas_findhitbox(t_canvas* x, int xpos, int ypos, int* x1p, int* y1p, int* x2p, int* y2p);
	int obj_noutlets(const t_object* x);
	int luaopen_mpd(lua_State* L);
	int luaopen_audio(lua_State* L);
	void sys_lock(void);
	void sys_unlock(void);
}

using namespace mpd;

void pushGlobals();

ofMutex mtx;

auto lua = ofxLua();
auto msgs = queue<string>();
auto partial = string("");
auto scaling = false;
auto touchable = true;  // limits touch rate to draw rate

//--------------------------------------------------------------------
void luaMessage(const string& x) {
	auto message = ofMessage(x);
	lua.scriptGotMessage(message);
}

//--------------------------------------------------------------------
bool includes(const string& needle, char* hay) {
	return ofIsStringInString(hay, needle);
}

//--------------------------------------------------------------------
void gui_hook(char* msg) {
	if (includes("pdtk_canvas_getscroll", msg) || includes("raise cord", msg)) {
		return;
	}
	string str = msg;

	if (str.back() == '\n') {
		str.pop_back();
	}
	if (str.back() != '\\') {  // ignore multiline for now
		mtx.lock();
		if (!partial.empty()) {
			partial += str;
			msgs.push(partial);
			partial = "";
		} else {
			msgs.push(str);
		}
		mtx.unlock();
	} else {
		str.pop_back();
		// not super sure about the space at the end, so far it only fixes this:
		// https://github.com/cviejo/mPD/blob/main/src/libs/pd/pure-data/src/g_template.c#L1969
		partial += str + " ";
	}
}

//--------------------------------------------------------------------
float mpd::getDPI() {
#if defined(TARGET_ANDROID)
	auto activity = ofGetOFActivityObject();
	return ofxJavaCallFloatMethod(activity, "cc/openframeworks/mPD/OFActivity", "getDensity", "()F");
#else
	return 1.0f;
#endif
}

//--------------------------------------------------------------------
void mpd::setup() {
	lua.setErrorCallback([](string& message) { ofLogWarning() << "Lua script error: " << message; });
	reload();
}

//--------------------------------------------------------------------
void mpd::reload() {
	lua.scriptExit();
	lua.init(true);
	luaopen_mpd(lua);
	luaopen_audio(lua);
	lua.doScript("app/main.lua", true);
	pushGlobals();
	lua.scriptSetup();
}

//--------------------------------------------------------------------
void mpd::update() {
	mtx.lock();
	while (!msgs.empty()) {
		luaMessage(msgs.front());
		msgs.pop();
	}
	mtx.unlock();
}

//--------------------------------------------------------------------
void mpd::draw() {
	lua.scriptDraw();
	touchable = true;
}

//--------------------------------------------------------------------
void mpd::exit() {
	audio::clear();
	lua.scriptExit();
	ofExit(0);
}

//--------------------------------------------------------------------
void mpd::key(ofKeyEventArgs& args) {
	lua.scriptKeyPressed(args.key);
}

//--------------------------------------------------------------------
void mpd::touch(ofTouchEventArgs& touch) {
	if (touch.id != 0 || scaling) {
		return;
	}
	if (touch.type != ofTouchEventArgs::move || touchable) {
		touchable = false;
		lua.scriptTouchMoved(touch);  // same fn for all events
	}
}

//--------------------------------------------------------------------
void mpd::scale(const string& type, float value, int x, int y) {
	auto message =
	   "scale " + type + " " + ofToString(value) + " " + ofToString(x) + " " + ofToString(y);
	mtx.lock();
	msgs.push(message);
	mtx.unlock();
}

//--------------------------------------------------------------------
int mpd::outletCount(t_gobj* x) {
	auto object = pd_checkobject(&x->g_pd);
	if (!object) {
		return 0;
	}
	return obj_noutlets(object);
}

//--------------------------------------------------------------------
bool mpd::selectionActive() {
	return !!pd_getcanvaslist()->gl_editor->e_selection;
}

//--------------------------------------------------------------------
void mpd::pdsend(const string& cmd) {
	sys_lock();
	t_binbuf* buffer = binbuf_new();
	binbuf_text(buffer, (char*)cmd.c_str(), cmd.length());
	binbuf_eval(buffer, 0, 0, 0);
	binbuf_free(buffer);
	sys_unlock();
}

//--------------------------------------------------------------------
t_gobj* mpd::findBox(int x, int y) {
	int a, b, c, d;
	auto canvas = pd_getcanvaslist();

	auto selection = canvas->gl_editor->e_onmotion == MA_MOVE;

	return canvas_findhitbox(canvas, x, y, &a, &b, &c, &d);
}

//--------------------------------------------------------------------
PdNode* mpd::getNode(int x, int y) {
	int x1, y1, x2, y2;
	auto canvas = pd_getcanvaslist();
	auto hit = canvas_findhitbox(canvas, x, y, &x1, &y1, &x2, &y2);

	if (!hit) {
		return NULL;
	}

	// auto selection = canvas->gl_editor->e_onmotion == MA_MOVE;

	auto result = new PdNode();
	result->ref = hit;
	result->x = x1;
	result->y = y1;
	result->width = x2 - x1;
	result->height = y2 - y1;
	result->outletCount = mpd::outletCount(hit);

	return result;
}

//--------------------------------------------------------------------
void pushGlobals() {
#if defined(TARGET_ANDROID)
	lua.setString("Target", "android");
#endif
	// 	auto devices = soundStream.getDeviceList();
	// 	lua.newTable("devices");
	// 	lua.pushTable("devices");
	// 	for (size_t i = 0; i < devices.size(); i++) {
	// 		auto device = devices[i];
	// 		lua.newTable(i + 1);
	// 		lua.pushTable(i + 1);
	// 		lua.setString("name", device.name);
	// 		lua.setNumber("id", device.deviceID);
	// 		lua.setNumber("inputChannels", device.inputChannels);
	// 		lua.setNumber("outputChannels", device.outputChannels);
	// 		lua.setBool("isDefaultInput", device.isDefaultInput);
	// 		lua.setBool("isDefaultOutput", device.isDefaultOutput);
	// 		lua.newTable("sampleRates");
	// 		lua.pushTable("sampleRates");
	// 		for (size_t j = 0; j < device.sampleRates.size(); j++) {
	// 			lua.setNumber(j + 1, device.sampleRates[j]);
	// 		}
	// 		lua.popTable();
	// 		lua.popTable();
	// 	}
	// 	lua.popTable();
}

// update
//  mtx.lock();
//  auto length = queue.size();
//  auto copy = msgs;
//  msgs.clear();
//  mtx.unlock();
//  auto size = copy.size();
//  if (size > 1) {
//  	ofLogVerbose("buffer size") << copy.size();
//  }
//  for (auto msg : copy) {
//  	luaMessage(msg);
//  }

// //--------------------------------------------------------------------
// void mpd::drawRectangle(int x, int y, int w, int h, const string& color, const string& fill) {
// 	drawRectangle(x, y, w, h, color, fill);
// }

// if (type == "scaleBegin") {
// 	scaling = true;
// }
// if (type == "scaleEnd") {
// 	scaling = false;
// }
// mtx.lock();
// if (type == "scale" || type == "scroll") {
// 	float scale = (float)lua.getNumber("Scale", 1);
// 	if (type == "scroll") {
// 		scale +=  value * 0.1f;
// 	} else if (type == "scale") {
// 		scale *=  value;
// 	}
// 	lua.setNumber("Scale", scale);
// 	lua.setBool("UpdateNeeded", true);
// }
// else if (type == "scaleBegin") {
// 	lastTouch.type = ofTouchEventArgs::up;
// 	lua.scriptTouchMoved(lastTouch); // finalize touch
// }
// mtx.unlock();
//--------------------------------------------------------------------
// Patch mpd::openPatch(const string& file, const string& folder) {
// 	Patch patch = base.openPatch(file, folder);
// if(!patch.isValid()) {
// 	ofLogError("Pd") << "opening patch \"" + file + "\" failed";
// }
// else {
// 	canvas_map((t_canvas*)patch.handle(), 1);
// }
// 	return patch;
// }
// //--------------------------------------------------------------------
// void mpd::closePatch(Patch& patch) {
// 	base.closePatch(patch);
// }

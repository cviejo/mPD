#pragma once

#include "mpd.h"
#include <vector>
#include "ofxLua.h"
#if defined(TARGET_ANDROID)
#include "ofxAndroid.h"
#endif
#include "audio.h"
#include "g_canvas.h"
#include "graphics.h"

using namespace mpd;

extern "C" {
	t_object* pd_checkobject(t_pd* x);
	t_canvas* canvas_getcurrent(void);
	t_gobj*
	canvas_findhitbox(t_canvas* x, int xpos, int ypos, int* x1p, int* y1p, int* x2p, int* y2p);
	int luaopen_mpd(lua_State* L);
	int luaopen_audio(lua_State* L);
	int obj_noutlets(const t_object* x);
	void sys_lock(void);
	void sys_unlock(void);
}

ofMutex mtx;

auto lua = ofxLua();
auto msgs = vector<string>();
auto classes = vector<string>();
auto partial = string("");
auto scaling = false;
auto touchable = true;  // limits touch rate to draw rate

//--------------------------------------------------------------------
vector<string> pull() {
	mtx.lock();
	auto pulled = msgs;
	msgs.clear();
	mtx.unlock();
	return pulled;
}

//--------------------------------------------------------------------
void message(const string& x) {
	auto message = ofMessage(x);
	lua.scriptGotMessage(message);
}

//--------------------------------------------------------------------
bool includes(const string& needle, char* hay) {
	return ofIsStringInString(hay, needle);
}

//--------------------------------------------------------------------
void gui_hook(char* msg) {
	if (includes("pd-class", msg)) {
		auto parts = ofSplitString(msg, " ");
		classes.push_back(parts[1]);
		return;
	} else if (includes("pdtk_canvas_getscroll", msg) || includes("raise cord", msg)) {
		return;
	}
	string str = msg;

	if (str.back() == '\n') {
		str.pop_back();
	}
	if (str.back() != '\\') {  // ignore multiline for now
		if (!partial.empty()) {
			partial += str;
			push(partial);
			partial = "";
		} else {
			push(str);
		}
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
#if defined(TARGET_ANDROID)
	lua.setString("target", "android");
#endif
	lua.scriptSetup();
}

//--------------------------------------------------------------------
void mpd::update() {
	auto pulled = pull();
	if (pulled.size() > 0) {
		message("update-start");
		for (auto x : pulled) {
			message(x);
		}
		message("update-end");
	}
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
#if !defined(TARGET_ANDROID)
	lua.scriptKeyPressed(args.key);
#endif
}

//--------------------------------------------------------------------
void mpd::touch(ofTouchEventArgs& touch) {
	if (touch.id != 0 || scaling) {
		return;
	}
	if (touch.type != ofTouchEventArgs::move || touchable) {
		touchable = false;
		auto message = "touch " + ofToString(touch.type) + " " + " " + ofToString(touch.x) + " " +
		               ofToString(touch.y);
		push(message);
	}
}

//--------------------------------------------------------------------
void mpd::push(const string& x) {
	mtx.lock();
	msgs.push_back(x);
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
void mpd::cmd(const string& cmd) {
#if defined(TARGET_ANDROID)
	auto activity = ofGetOFActivityObject();
	ofxJavaCallVoidMethod(activity, "cc/openframeworks/mPD/OFActivity", "showSomething", "()V");
#endif
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

	auto result = new PdNode();
	result->ref = hit;
	result->x = x1;
	result->y = y1;
	result->width = x2 - x1;
	result->height = y2 - y1;
	result->outletCount = mpd::outletCount(hit);

	return result;
}

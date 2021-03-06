#include "Button.h"
// #include "../Globals.h"


//--------------------------------------------------------------
Button::Button(string aId, ButtonType aType, bool* aTogglePointer) : GuiElement("button"){

	this->type          = aType;
	this->togglePointer = aTogglePointer;

	this->id = aId + "-button";

	_image.loadImage("img/" + aId + ".png");
}


//--------------------------------------------------------------
void Button::draw(){

	if (this->togglePointer != NULL) {
		this->on = *this->togglePointer;
	}

	if(this->pressed || this->on){
		ofSetColor(54, 55, 58);
	}
	else {
		ofSetColor(0, 0);
	}

	ofDrawRectangle(*this);

	ofSetColor(this->enabled ? 255 : 100);

	_image.draw(*this);

	// if (this->type == TYPE_DRAG && this->pressed){

		// AppEvent event(AppEvent::TYPE_OBJECT_DRAGGED, this->id, _draggedLoc.x, _draggedLoc.y);
		// ofNotifyEvent(AppEvent::events, event);
	// }
}


//--------------------------------------------------------------
void Button::onAppEvent(AppEvent& aAppEvent){

	if (aAppEvent.type == AppEvent::TYPE_TAB_STATE_CHANGED && ofIsStringInString(this->id, aAppEvent.message)){
		this->on = aAppEvent.value;
	}
}


//--------------------------------------------------------------
void Button::onPressed  (int aX, int aY, int aId){

	if (!this->enabled){ return; }

	if (this->type == TYPE_TOGGLE) {

		if (this->togglePointer != NULL) {
			this->on = *this->togglePointer = !*this->togglePointer;
		}
		else {
			this->on = !this->on;
		}
	}
	else if (this->type == TYPE_DRAG){

		this->on = true;
		_draggedLoc.set(aX, aY);
	}

	AppEvent event(AppEvent::TYPE_BUTTON_PRESSED, this->id, this->on);
	ofNotifyEvent(AppEvent::events, event);
}


//--------------------------------------------------------------
void Button::onDragged  (int aX, int aY, int aId){
	
	if (this->type == TYPE_DRAG){
		_draggedLoc.set(aX, aY);
	}
}


//--------------------------------------------------------------
void Button::onReleased  (int aX, int aY, int aId){

	if (!this->enabled){ return; }

	if (this->type != TYPE_TOGGLE) {
		this->on = false;
	}
	// else if (this->type == TYPE_DRAG){
		// AppEvent event(AppEvent::TYPE_OBJECT_DRAGGED, this->id, this->on);
		// ofNotifyEvent(AppEvent::events, event);
	// }
}

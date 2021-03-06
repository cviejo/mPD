#include "Canvas.h"


int gridStepSize = 20; // Globals::Theme.grid.cell.width 


//--------------------------------------------------------------
Canvas::Canvas(int aWidth, int aHeight){

	this->id     = "canvas";
	this->width  = aWidth;
	this->height = aHeight;


	_current = new PdCanvas("untitled");

	_font.load("fonts/DejaVuSansMono.ttf", 70, true, true);

	_font.setLineHeight(100.0f);

	this->initGrid();
}


//--------------------------------------------------------------
void Canvas::initGrid(){

	int gridWidth  = this->width  + gridStepSize;// * 3;
	int gridHeight = this->height + gridStepSize;// * 3;

	_grid.allocate(gridWidth, gridHeight, GL_RGBA);
	_grid.begin();

	ofClear(255, 0);
	ofSetColor(255);
	ofDrawRectangle(0, 0, gridWidth, gridHeight);

	ofSetColor(200);
	for(int i = 0; i < gridWidth; i += gridStepSize){
		for(int j = 0; j < gridHeight; j += gridStepSize){
			ofDrawCircle(i, j, 1);
		}
	}

	_grid.end();

	// Globals::Pd.setCanvasGridMode(true);
	// Globals::Pd.setCanvasGridSize(Globals::Theme.grid.cell.width, 
	//                               Globals::Theme.grid.cell.height);
}


//--------------------------------------------------------------
void Canvas::set(PdCanvas* aCanvas){

	_current = aCanvas;
}


//---------------------------VIRTUAL--------------------------//
//--------------------------------------------------------------
bool Canvas::updateNeeded(){

	auto updated = PdGui::instance().updateNeeded || _updateNeeded || _current->moveMode == PdCanvas::MODE_CONNECT;

	PdGui::instance().updateNeeded = _updateNeeded = false;

	return updated;
}


//--------------------------------------------------------------
void Canvas::draw(){

	if (!_current){ return; }

	ofSetColor(255);
	ofDrawRectangle(*this);

	ofPushMatrix();

	ofTranslate(this->x, this->y);
	ofScale(_current->scale, _current->scale);

	this->drawGrid();

	ofTranslate(_current->viewPort.getPosition() * -1);

	this->drawConnecting();
	this->drawNodes();
	this->drawConnections();
	this->drawRegion();

	ofPopMatrix();
}


//--------------------------------------------------------------
void Canvas::drawGrid(){

	if (_current->gridMode && _current->scale >= 1){

		ofSetColor(255);

		_grid.draw((int)(-_current->viewPort.x) % gridStepSize,
		           (int)(-_current->viewPort.y) % gridStepSize);
	}
}


//--------------------------------------------------------------
void Canvas::drawNodes(){

	for (auto node : _current->nodes){

		if (_current->viewPort.intersects(*node)){

			this->drawNodeBackground(node);
			this->drawNodeText(node);

			if (node->type == "scalar"){

				PdScalar* scalar = (PdScalar*)node;

				ofPushMatrix();
				ofTranslate(scalar->getPosition().x + 1, scalar->getPosition().y);
				ofScale(scalar->scale.x, scalar->scale.y);

				for (auto& path : scalar->paths){
					path->svg.draw();
				}

				ofPopMatrix();
			}
			else if (node->type == "iemgui"){

				PdIemGui* guiNode = (PdIemGui*)node;

				if (guiNode->canvas){
					ofFill();
					ofSetHexColor(guiNode->backColor);
					ofDrawRectangle(*(guiNode->canvas));
				}
				if (guiNode->label){
					this->drawNodeText(guiNode->label);
				}

				if (guiNode->iemType == "slider"){

					ofDrawRectangle(guiNode->slider);
				}
				else if (guiNode->iemType == "radio"){

					ofSetLineWidth(_current->scale);
					ofNoFill();
					ofSetColor(0);
					for (auto& radio : guiNode->radios){
						ofDrawRectangle(radio);
					}

					ofFill();
					ofSetHexColor(guiNode->frontColor);
					ofDrawRectangle(guiNode->radioButtons[guiNode->value]);
				}
				else if (guiNode->iemType == "bng"){

					ofSetHexColor(guiNode->frontColor);
					ofFill();
					ofDrawCircle(guiNode->getCenter(), (guiNode->width - 2) / 2);

					ofSetColor(0); // TODO: borderColor
					ofSetLineWidth(_current->scale);
					ofNoFill();
					ofDrawCircle(guiNode->getCenter(), (guiNode->width - 2) / 2);
				}
				else if (guiNode->iemType == "toggle" && guiNode->value){

					ofSetHexColor(guiNode->frontColor);
					ofSetLineWidth(_current->scale);

					auto pad    = 2;
					auto top    = guiNode->y + pad;
					auto left   = guiNode->x + pad;
					auto bottom = guiNode->getBottom() - pad;
					auto right  = guiNode->getRight()  - pad;

					ofDrawLine(left, top,    right, bottom);
					ofDrawLine(left, bottom, right, top);
				}
			}

			for (auto inlet : node->inlets){
				this->drawNodeIo(inlet);
			}

			for (auto outlet : node->outlets){
				this->drawNodeIo(outlet);
			}
		}
	}
}


//--------------------------------------------------------------
void Canvas::drawConnections(){

	for (auto conn : _current->connections){

		if (_current->viewPort.inside(conn->getPosition()) || _current->viewPort.inside(conn->x2, conn->y2)){
			ofSetColor(119);
			ofSetLineWidth(_current->scale);
			ofDrawLine(conn->x, conn->y, conn->x2, conn->y2);
		}
	}
}


//--------------------------------------------------------------
void Canvas::drawRegion(){

	if (_current->moveMode == PdCanvas::MODE_REGION){

		ofSetColor(100);
		ofNoFill();
		ofDrawRectangle(_current->region);

		ofSetColor(100, 100);
		ofFill();
		ofDrawRectangle(_current->region);
	}
}


//--------------------------------------------------------------
void Canvas::drawConnecting(){

	if (_current->moveMode == PdCanvas::MODE_CONNECT){

		ofPoint loc = this->transformToPdCoordinates(ofGetMouseX(), ofGetMouseY());

		if (auto node = this->getNodeAtPosition(loc.x, loc.y)){

			if (node->inlets.size()){
				loc = this->getClosestIo(node->inlets, loc)->getCenter();
			}
		}

		ofSetColor(119);
		ofSetLineWidth(_current->scale);
		ofDrawLine(_connectionStart->getCenter(), loc);
	}
}


//--------------------------------------------------------------
void Canvas::drawNodeBackground(PdNode* aNode){

	ofFill();

	int top    = aNode->getTop();
	int left   = aNode->getLeft();
	int right  = aNode->getRight();
	int bottom = aNode->getBottom();

	if (aNode->selected){
		ofSetColor(140);
		ofDrawRectangle(aNode->x - 2, aNode->y - 2, aNode->width + 4, aNode->height + 4);
	}

	if (aNode->type == "msg"){
		// ofSetColor(Globals::Theme.node.color.border);
		ofSetColor(204);
		ofBeginShape();
			ofVertex(left,      top);
			ofVertex(right + 4, top);
			ofVertex(right,     top + 4);
			ofVertex(right,     bottom - 4);
			ofVertex(right + 4, bottom);
			ofVertex(left,      bottom);
		ofEndShape();

		// ofSetColor(255);
		ofSetColor(248, 248, 246);
		ofBeginShape();
			ofVertex(left  + 1, top + 1);
			ofVertex(right + 2, top + 1);
			ofVertex(right - 1, top + 4);
			ofVertex(right - 1, bottom - 4);
			ofVertex(right + 2, bottom - 1);
			ofVertex(left  + 1, bottom - 1);
		ofEndShape();
	}
	else if (aNode->type == "atom" || aNode->type == "numbox"){

		ofSetColor(aNode->borderColor);
		ofBeginShape();
			ofVertex(left,      top);
			ofVertex(right - 4, top);
			ofVertex(right,     top + 4);
			ofVertex(right,     bottom);
			ofVertex(left,      bottom);
		ofEndShape();

		if (aNode->type == "atom"){
			ofSetColor(248, 248, 246);
		}
		else {
			ofSetColor(aNode->backColor);
		}

		ofBeginShape();
			ofVertex(left  + 1, top + 1);
			ofVertex(right - 4, top + 1);
			ofVertex(right - 1, top + 4);
			ofVertex(right - 1, bottom - 1);
			ofVertex(left  + 1, bottom - 1);
		ofEndShape();

		if (aNode->type == "numbox") {

			ofSetColor(aNode->borderColor);
			ofDrawTriangle(left + 0, top + 0,
			               left + 0, bottom - 0,
			               left + 7, top + aNode->height / 2);

			ofSetColor(240);
			ofDrawTriangle(left + 1, top + 2,
			               left + 1, bottom - 2,
			               left + 6, top + aNode->height / 2);
		}
	}
	else {

		ofSetColor(aNode->borderColor);
		ofDrawRectangle(*aNode);

		ofSetHexColor(aNode->backColor);
		ofDrawRectangle(aNode->x + 1, aNode->y + 1, aNode->width - 2, aNode->height - 2);
	}
}


//--------------------------------------------------------------
void Canvas::drawNodeText(PdNode* aNode){

	ofSetColor(0);

	ofScale(0.10f, 0.10f);
	_font.drawString(aNode->text, (aNode->x + aNode->textPosition.x) * 10.0f, (aNode->y + aNode->textPosition.y) * 10.0f);
	ofScale(10.0f, 10.0f);
}


//--------------------------------------------------------------
void Canvas::drawNodeIo(PdIo* aIo){

	ofFill();

	if (aIo->height == 2){
		// == 2 bad way of detecting this, put it in the PdGui and node color

		ofSetColor(0);
		ofDrawRectangle(*aIo);
	}
	else {

		ofSetColor(119);
		ofDrawRectangle(*aIo);

		if (!aIo->signal){
			ofSetColor(255);
			ofDrawRectangle(aIo->x + 1, aIo->y + 1, aIo->width - 2, aIo->height - 2);
		}
	}
}


//--------------------------------------------------------------
void Canvas::onPressed(int aX, int aY, int aId){

	_previousMouse.set(aX, aY);

	ofPoint loc  = this->transformToPdCoordinates(aX, aY);
	PdNode* node = this->getNodeAtPosition(loc.x, loc.y);

	if (!_current->editMode && !node){

		_current->moveMode = PdCanvas::MODE_DRAG;
	}
	else if (_current->editMode && node && !node->selected && node->outlets.size()){

		_current->moveMode = PdCanvas::MODE_CONNECT;
		_connectionStart = this->getClosestIo(node->outlets, loc);
	}
	else {

		this->sendMouseEvent("mouse", loc);
	}
}


//--------------------------------------------------------------
void Canvas::onDragged(int aX, int aY, int aId){

	if (_current->moveMode == PdCanvas::MODE_DRAG){ // TODO: only if mode_drag

		ofPoint p(aX - _previousMouse.x, aY - _previousMouse.y);

		_current->viewPort.setPosition(_current->viewPort.getPosition() - p / _current->scale);

		_previousMouse.set(aX, aY);

		if (_current->viewPort.x < 0){
			_current->viewPort.x = 0;
		}
		if (_current->viewPort.y < 0){
			_current->viewPort.y = 0;
		}

		_updateNeeded = true;
	}
	else if (_current->moveMode != PdCanvas::MODE_CONNECT){

		this->sendMouseEvent("motion", this->transformToPdCoordinates(aX, aY));
	}
}


//--------------------------------------------------------------
void Canvas::onReleased(int aX, int aY, int aId){

	ofPoint loc = this->transformToPdCoordinates(aX, aY);

	if (_current->moveMode == PdCanvas::MODE_CONNECT){

		if (auto node = this->getNodeAtPosition(loc.x, loc.y)){

			if ( !node->inlets.size() ){ return; }

			this->sendMouseEvent("mouse",   _connectionStart->getCenter());
			this->sendMouseEvent("mouseup", this->getClosestIo(node->inlets, loc)->getCenter());
		}
	}
	else {

		this->sendMouseEvent("mouseup", loc);
	}

	_current->moveMode = PdCanvas::MODE_NONE;
}


//--------------------------------------------------------------
void Canvas::onDoubleClick(int aX, int aY){

	ofPoint p = this->transformToPdCoordinates(aX, aY);

	for (auto node : _current->nodes){
		if (node->inside(p)){
			return;
		}
	}

	string  cmd = _current->id + " editmode " + (_current->editMode ? "0" : "1");

	PdGui::instance().pdsend(cmd);
}


//--------------------------------------------------------------
void Canvas::onPressCancel(){ }


//--------------------------------------------------------------
void Canvas::onAppEvent(AppEvent& aAppEvent){

	switch(aAppEvent.type){

		case AppEvent::TYPE_CREATE_OBJECT:
			{
				ofPoint mousePos = this->transformToPdCoordinates(aAppEvent.x, aAppEvent.y) + ofPoint(7, 7);
				string cmd;
				cmd = _current->id + " dirty 1";
				PdGui::instance().pdsend(cmd);
				cmd = _current->id + " obj 0";
				this->sendMouseEvent("motion", mousePos);
				PdGui::instance().pdsend(cmd);
				cmd = _current->id + " obj_addtobuf " + aAppEvent.message;
				PdGui::instance().pdsend(cmd);
				cmd = _current->id + " obj_buftotext";
				PdGui::instance().pdsend(cmd);
				this->sendMouseEvent("mouse", ofPoint(-1, -1));
				this->sendMouseEvent("mouseup", ofPoint(-1, -1));
			}
			break;

		case AppEvent::TYPE_SCALE_BEGIN:
			break;

		case AppEvent::TYPE_SCALE:
			_updateNeeded = true;
#ifdef TARGET_ANDROID
			_current->scale *= aAppEvent.value;
#elif  defined(TARGET_OF_IOS)
			_current->scale = aAppEvent.value;
#else 
			_current->scale += aAppEvent.value;
#endif
			_current->viewPort.setSize(this->width / _current->scale, this->height / _current->scale);
			break;

		// debugging
		case AppEvent::TYPE_KEY_PRESSED:

			if (_current){

				string cmd = "";
				int    key = (int)aAppEvent.value;

				if      (key == 'a'){ cmd = _current->id + " selectall"; }
				else if (key == 'c'){ cmd = _current->id + " copy"; }
				else if (key == 'e'){ cmd = _current->id + " editmode " + (_current->editMode ? "0" : "1"); }
				else if (key == 'o'){ PdGui::instance().openPatch(ofToDataPath("main.pd")); }
				else if (key == 'p'){ cmd = _current->id + " paste"; }
				else if (key == 'u'){ cmd = _current->id + " undo"; }
				else if (key == 'g'){ cmd = _current->id + " gridactive 1"; }
				else if (key == 't'){ cmd = _current->id + " gridactive 0"; }
				else if (key == 's'){ cmd = _current->id + " gridsize 20"; }
				else if (key == 'q'){ ofExit(); }
				else if (key == '1'){ this->set(PdGui::instance().getCanvases()[0]); }
				else if (key == '2'){ this->set(PdGui::instance().getCanvases()[1]); }

				PdGui::instance().pdsend(cmd);
			}
			break;

		case AppEvent::TYPE_BUTTON_PRESSED:
			if (_current){

				string cmd = "";

				if (aAppEvent.message == "edit-button"){
					cmd = _current->id + " editmode " + (_current->editMode ? "0" : "1");
				}
				else if (aAppEvent.message == "grid-button"){ // TODO gridsize setting
					cmd = string(_current->id + " gridsize 20");
					PdGui::instance().pdsend(cmd);
					cmd = _current->id + " gridactive " + (_current->gridMode ? "0" : "1");
				}
				else if (aAppEvent.message == "copy-button"){
					cmd = _current->id + " copy";
				}
				else if (aAppEvent.message == "paste-button"){
					cmd = _current->id + " paste";
				}
				else if (aAppEvent.message == "trash-button"){
					cmd = _current->id + " key 1 8 0 1 0";
					PdGui::instance().pdsend(cmd);
					cmd = _current->id + " key 0 8 0 1 0";
				}
				else if (aAppEvent.message == "undo-button"){
					cmd = _current->id + " undo";
				}
				else if (aAppEvent.message == "zoom-in-button"){
					_current->scale += 0.5;
				}
				else if (aAppEvent.message == "zoom-out-button"){
					_current->scale -= 0.5;
				}
				else if (aAppEvent.message == "settings-button"){


				//ofLogVerbose(ofxiOSKeyboard::getText());

					// char key = 'f';

					// AppEvent event(AppEvent::TYPE_KEY_PRESSED, (float)key);

					// ofNotifyEvent(AppEvent::events, event);
				}

				PdGui::instance().pdsend(cmd);
			}
			break;

		default:
			break;
	}

	// else if(aAppEvent.type == AppEvent::TYPE_CREATE_OBJECT){

		// PdNode node;

		// ofPoint loc = this->transformLoc(aAppEvent.x, aAppEvent.y, TRANSFORM_MPD_TO_PD);

		// node.className = aAppEvent.message;
		// node.x         = loc.x;
		// node.y         = loc.y;

		// Globals::Pd.canvasCreateObject(node);
	// }
}


//--------------------------------------------------------------
PdNode* Canvas::getNodeAtPosition(int aX, int aY){

	if (_current){

		for (auto node : _current->nodes){
			if (node->inside(aX, aY)){
				return node;
			}
		}
	}

	return NULL;
}



//--------------------------------------------------------------
PdIo* Canvas::getClosestIo(vector<PdIo*> aIoArray, ofPoint aLoc){

	PdIo* result = aIoArray[0];

	for (auto io : aIoArray){
		if (io->getCenter().squareDistance(aLoc) < result->getCenter().squareDistance(aLoc)){
			result = io;
		}
	}

	return result;
}


//--------------------------------------------------------------
void Canvas::sendMouseEvent(string aEventType, ofPoint aLoc){

	string cmd = _current->id + " " + aEventType + " " + ofToString(aLoc.x) + " " + ofToString(aLoc.y) + " 0 0 0";

	PdGui::instance().pdsend(cmd);
}


//--------------------------------------------------------------
ofPoint Canvas::transformToPdCoordinates(float aX, float aY){

	ofPoint result;

	// has to be rounded otherwise pd behaves weirdly when dragging up or left
	result.x = (int)((aX - this->x) / _current->scale + _current->viewPort.x); // Globals::Settings.scale;
	result.y = (int)((aY - this->y) / _current->scale + _current->viewPort.y); // Globals::Settings.scale;
	// result.x = (int)((aX ) / _current->scale + _current->viewPort.x); // Globals::Settings.scale;
	// result.y = (int)((aY ) / _current->scale + _current->viewPort.y); // Globals::Settings.scale;

	return result;
}


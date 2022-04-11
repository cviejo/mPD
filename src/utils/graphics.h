#pragma once

#include <string>

using std::string;

namespace gfx {

	void drawRectangle(int x1, int y1, int x2, int y2, const string& color, const string& fill);

	void drawEllipse(int x1, int y1, int x2, int y2, const string& color, const string& fill);

	void drawLine(int x1, int y1, int x2, int y2, const string& color, float width);
};  // namespace gfx

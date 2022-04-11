%module mpd
%{
   #include "mpd.h"
   #include "utils/graphics.h"
   using namespace mpd;
   using namespace gfx;
%}

%include <stl.i>
%include <typemaps.i>
%include <std_string.i>
%include <std_vector.i>
%include <std_map.i>

typedef std::string string;

%include "ofMain.h"
%include "mpd.h"
%include "utils/graphics.h"

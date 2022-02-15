%module mpd
%{
   #include "mpd.h"
   using namespace mpd;
%}

%include <stl.i>
%include <std_string.i>
%include <std_vector.i>
%include <std_map.i>

%include "libs/pd/cpp/PdTypes.hpp"
%include "ofMain.h"
%include "mpd.h"

%module audio
%{
   #include "audio.h"
   using namespace audio;
%}

%include <stl.i>
%include <typemaps.i>
%include <std_string.i>

typedef std::string string;

%ignore audio::in;
%ignore audio::out;
%include "audio.h"

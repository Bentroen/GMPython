#define _python_prepare_buffer
/// (size:int)->buffer~
var _size = argument0;
gml_pragma("global", "global.__python_buffer = undefined");
var _buf = global.__python_buffer;
if (_buf == undefined) {
	_buf = buffer_create(_size, buffer_grow, 1);
	global.__python_buffer = _buf;
} else if (buffer_get_size(_buf) < _size) {
	buffer_resize(_buf, _size);
}
buffer_seek(_buf, buffer_seek_start, 0);
return _buf;

#define python_run_file
/// python_run_file() : Call a Python function from a module.
/// (module:string, object:string, args:string)~
var module = argument0;
var obj = argument1;
var args = argument2;
var _buf = _python_prepare_buffer(800);
var ret = _python_run_file(buffer_get_address(_buf), module, obj, args);
switch (ret) {
	case -1: // Python exception
		var exc = buffer_read(_buf, buffer_string);
		throw exc;
	case 0: // Couldn't run function
		show_message("Module " + module + " couldn't be loaded!");
		return;
	case 1: // None
		return noone;
	case 2: // bool
		return buffer_read(_buf, buffer_bool);
	case 3: // int
		return buffer_read(_buf, buffer_s32);
	case 4: // float
		return buffer_read(_buf, buffer_f64); // f64 = double (python float), f32 = float
	case 100: // str
		return buffer_read(_buf, buffer_string);
	default: // anything else
		return buffer_read(_buf, buffer_string);
}


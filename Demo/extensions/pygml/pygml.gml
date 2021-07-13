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
var kwargs = argument3;

// Serialize arguments to JSON string
var args_str = "", kwargs_str = "";
if (args != undefined) {
	if (is_array(args)) {
		args_str = json_stringify(args);
	} else {
		args_str = "[" + string(args) + "]";
	}
}
if (kwargs != undefined) {
	if (is_struct(kwargs)) {
		kwargs_str = json_stringify(kwargs);
	} else {
		kwargs_str = "{" + string(kwargs) + "}";
	}
} 

// Prepare buffer and write arguments to pass
var _buf = _python_prepare_buffer(4096);
buffer_write(_buf, buffer_string, module);
buffer_write(_buf, buffer_string, obj);
buffer_write(_buf, buffer_string, args_str);
buffer_write(_buf, buffer_string, kwargs_str);

// Run Python module
var ret = _python_run_file(buffer_get_address(_buf));
switch (ret) {
	case -1: // Python exception
		var exc = buffer_read(_buf, buffer_string);
		throw exc;
	case 0: // Couldn't run function
		show_message("Module " + module + " couldn't be loaded!");
		return;
	case 1: // Success; parse JSON string back into object
		var result = buffer_read(_buf, buffer_string);
		if (result == "null") {
			return pointer_null;
		} else {
			return json_parse(result);
		}
}


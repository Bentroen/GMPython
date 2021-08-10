#include <pybind11/embed.h>
namespace py = pybind11;

#include <string>
#include <iostream>

#define GMEXPORT extern "C" __declspec (dllexport)

struct buffer {
    char* pos;
public:
    buffer(char* origin) : pos(origin) {}
    template<class T> T read() {
        T r = *(T*)pos;
        pos += sizeof(T);
        return r;
    }
    template<class T> void write(T val) {
        *(T*)pos = val;
        pos += sizeof(T);
    }
    //
    char* read_string() {
        char* r = pos;
        while (*pos != 0) pos++;
        pos++;
        return r;
    }
    void write_string(const char* s) {
        for (int i = 0; s[i] != 0; i++) write<char>(s[i]);
        write<char>(0);
    }
};

GMEXPORT double _python_call_function(char* cbuf) {
    // Set up buffer for writing result
    buffer b(cbuf);

    // Read arguments from buffer
    char* module = b.read_string();
    char* callable = b.read_string();
    char* args = b.read_string();
    char* kwargs = b.read_string();

    // Initialize Python interpreter
    py::scoped_interpreter guard{};
    
    try {
        // Load JSON module for serializing and parsing args/result
        py::module_ json = py::module_::import("json");
        py::object json_dumps = json.attr("dumps");
        py::object json_loads = json.attr("loads");

        // Implement default conversion to 'str' for unsupported types
        //
        // TODO
        //
 
        // Import module and parse arguments for call
        py::module_ pModule = py::module_::import(module);
        py::object pFunc = pModule.attr(callable);
        py::object pArgs = json_loads(args);
        py::object pKwargs = json_loads(kwargs);

        // Wrap single argument into a list
        py::list pArgsList;
        if (!py::isinstance<py::list>(pArgs)) {
            pArgsList.append(pArgs);
        }
        else {
            pArgsList = pArgs;
        }

        // Call function and return result as JSON string
        py::object result = pFunc(*pArgsList, **pKwargs);
        std::string sResult = json_dumps(result).cast<std::string>();
        const char* cstr = sResult.c_str();
        b.write_string(cstr);
        return 1;
    }
    catch (py::error_already_set& e) {
        // Return exception and traceback as a string
        const char* exc = e.what();
        std::cout << exc;
        b.write_string(exc);
        return -1;
    }
}

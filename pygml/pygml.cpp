#include <pybind11/embed.h>
namespace py = pybind11;

#include <string>
#include <iostream>

#define GMEXPORT extern "C" __declspec (dllexport)


GMEXPORT char* python_call(char* module, char* callable, char* args) {

    // Initialize Python interpreter
    py::scoped_interpreter guard{};

    // Build expression to be called
    std::string sModule, sCallable, sArgs, call;
    sModule = std::string(module);
    sCallable = std::string(callable);
    sArgs = std::string(args);
    call = sCallable + "(" + sArgs + ")";

    try {
        // Load Python module
        py::exec("from " + sModule + " import " + sCallable);

        // Call line and return result as a string
        py::object result = py::eval(call);
        std::string resultString = result.attr("__str__")().cast<std::string>();
        char* cstr = new char[resultString.length() + 1];
        strcpy_s(cstr, resultString.size() + 1, resultString.c_str());
        return cstr;

    }
    catch (py::error_already_set& e) {
        // Return exception and traceback as a string
        std::string exc = e.what();
        char* cstr = new char[exc.length() + 1];
        strcpy_s(cstr, exc.size() + 1, exc.c_str());
        return cstr;
    }

    py::finalize_interpreter();
}

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

GMEXPORT double _python_run_file(char* cbuf, char* module, char* callable, char* args) {
    // Set up buffer for writing result
    buffer b(cbuf);

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

        // Buffer contains the result of the call
        // Return code defines how the buffer value must be treated
        if (result.is_none()) {
            return 1;
        }
        else if (py::isinstance<py::bool_>(result)) {
            int value = py::int_(result).cast<int>();
            b.write<int>(value);
            return 2;
        }
        else if (py::isinstance<py::int_>(result)) {
            int value = result.cast<int>();
            b.write<int>(value);
            return 3;
        }
        else if (py::isinstance<py::float_>(result)) {
            double value = result.cast<double>();
            b.write<double>(value);
            return 4;
        }
        else {
            std::string value = py::str(result).cast<std::string>();
            const char* cstr = value.c_str();
            b.write_string(cstr);
            return 100;
        }
    }
    catch (py::error_already_set& e) {
        // Return exception and traceback as a string
        std::string exc = e.what();
        const char* cstr = exc.c_str();
        std::cout << exc;
        b.write(cstr);
        return -1;
    }

    py::finalize_interpreter();
}

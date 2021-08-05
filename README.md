# pygml
A GameMaker Studio 2 extension for calling Python scripts from GML.


## Overview

pygml aims to provide access to a Python interpreter as a simple GameMaker function. It allows:

- Importing modules and calling top-level functions from them
- Passing multiple positional and keyword arguments
- Receiving return values, including nested lists and dicts
- Getting Python exceptions across so that they can be handled in GML
- No Python installation required for users of your game

To achieve this sort of integration in a way that keeps things simple under the hood, pygml uses the awesome [pybind11](https://github.com/pybind/pybind11) library, which provides seamless operability between Python and C++.

In order to support both passing and returning complex data structures from GML to Python and vice-versa, values are converted to JSON on the way through. While this does come with its own set of limitations, this simple approach allows support for nested data structures out of the box, while keeping conversion code to a minimum, thus reducing errors that could arise from other serialization techniques.

Here are all the types supported by pygml and their resulting Python ⟷ GML conversions:

Python        | GML
--------------|-----------------------
`int`         | `real`
`float`       | `real`
`bool`        | `real` (`true`/`false`)
`str`         | `string`
`list`        | `array`
`dict`        | `struct`
`None`        | `pointer_null`
_(exception)_ | `undefined`

Nested arrays/structs in the arguments are supported and will be correctly transmitted to Python as nested lists/dicts. In the same fashion, returning those structures from the called function will also convert it to arrays and structs on the way back to GML.


## Setup

Download the extension [here](). Drag and drop the file into your GameMaker project.

> Due to its extensive use of structs, **pygml requires GameMaker 2.3+** (2.3.2 or later is recommended due to a [bug](https://forum.yoyogames.com/index.php?threads/issues-saving-undefined-struct-variables-to-json-solved.85143/) in JSON conversion in prior versions).
>
> Currently, downloads are only provided for Windows, although there are no Windows-specific dependencies preventing it from working on Mac/Linux.

By default, the extension is configured so Python modules can be loaded either from the root folder of your game, or from a subdirectory named `python` (so your scripts must be placed either in `datafiles/` or `datafiles/python/` in the GameMaker project).

If your project uses a different structure and you need to change where modules are loaded from, open `python39._pth` and change the `python/` line to the appropriate path (or add a new line).

As pygml uses an embedded Python interpreter, installing third-party packages with `pip` is not supported. To include those, install them as normal in your system Python installation, then head to `<python_path>/Lib/site-packages/` and copy the relevant files to `datafiles/python/site-packages/` (or whatever folder you defined above).

That's all! You're now ready to run Python scripts from GameMaker! :D


## Usage

The whole usage consists of one simple GML function with the following syntax:

```
python_call_function(module_name, function_name[, args[, kwargs]]) 
```

To call a simple Python function from a module, getting its return value, do:

```gml
var result = python_call_function("random", "randint");
```

A single `real` or `string` may be passed to the function as a positional argument:

```gml
var result = python_call_function("math", "sqrt", 36);
show_debug_message(result) // 6.0
```

> **Tip:** In Python syntax, the above is essentially the same thing as
>
> ```python
> import math
> result = math.random(36)
> print(result)
> ```

Multiple positional arguments may be passed as a GameMaker array.

```gml
var result = python_call_function("builtins", "min", [18, 42, 35, 11, 24]);
show_debug_message(result); // 11.0
```

When Python returns a list/tuple or a dict, they will be conveniently converted to GML arrays and structs:

```gml
var result = python_call_function("builtins", "sorted", [[4, 3, 2, 5, 1]]);
show_debug_message(result); // [1.0, 2.0, 3.0, 4.0, 5.0]
```

> Note that we use two square brackets `[[ ]]` above. The outermost pair denotes the array of arguments, while the innermost pair wraps the numbers into another array, which will be passed as a single argument to Python.

Keyword arguments may be passed as a struct:

```gml
var result = python_call_function("builtins", "sorted", [[4, 2, 3, 1, 5]], {reversed: true});
show_debug_message(result); // [5.0, 4.0, 3.0, 2.0, 1.0]
```

Any exception that occurs in the Python side will throw a GameMaker error containing the exception message and traceback, which may be caught by wrapping the call in a `try`/`catch` block:

```gml
try {
    var result = python_call_function("builtins", "divmod", [10, 0]);
}
catch (e) {
    // Show exception on the screen
    show_message("Python exception raised: " + e);
}
```

This way, scripts may be run safely without crashing your game, and you may log the error message however you wish. Make sure, however, to handle errors appropriately if you decide to ignore them. The function will return `undefined` if an exception is raised, and your game may not work properly if it relies on the returned value.

All the examples above showcase basic features of the module by calling built-in functions. However, pygml's true power lies on its capability of importing third-party modules.

You can add as many modules as you wish to your game by placing them in `datafiles/` or `datafiles/python/` in your GameMaker project. If you want to keep your scripts in a different folder, check [Setup](#Setup) above.


## Building

_(NOTE: The tutorial below will use file names from Python 3.9 for simplicity. If you're using a different version, just consider the version number to be different.)_

If you need to use a version of Python that is not provided with the releases, be it a different major/minor version or architecture, you will have to build the project yourself. Here's how to do it:

1. Install the correct version of Python. Make sure the version matches the bitness you want the DLL to have, i.e. you must install **32-bit Python** if you want to create a 32-bit DLL — the same goes for 64-bit.

2. Install pybind11 for your version of Python:
   ```
   $ pip install pybind11
   ```

3. Open the Visual Studio project. The default include and library paths point to `C:/Program Files (x86)/Python/Python39-32` for 32-bit Python, and `C:/Program Files/Python/Python39` for 64-bit Python (default locations for the system-wide Python installation). If you installed Python to a different location, adjust the Include Directories and Library Directories as necessary. Alternatively, just copy `pybind11.h`, `python.h` and `python39.lib` into your project folder, and add them as included headers and libraries, respectively.

4. Build the DLL.

5. Download the [Windows embeddable package](https://www.python.org/ftp/python/3.9.6/python-3.9.6-embed-win32.zip) for your version of Python. This contains a minimal Python installation that can be shipped with your game so that users do not need Python installed on their machine. You can read more about it [here](https://docs.python.org/3/using/windows.html#the-embeddable-package).

6. Extract `python39.dll`, `python39.zip` and `python39._pth` from the embeddable package.

   > **Tip:** While the files included in the package aim to mimic a default, system-wide Python installation, most of the files aren't necessary for the Python distribution to work correctly. So, to shrink the size of your game's executable, you may want to remove packages from the standard library that you're not likely to use.
   > 
   > Keep in mind, however, that some modules are used during the Python initialization, and some are required by the `json` module. **Removing any of those will cause the extension to fail or even crash your game.** Make sure to use the `python39_minimal.zip` file included in the release as a base on what files to include, then add any other modules you need.

7. If you want to have your Python files somewhere other than your game's root folder, open `python39._pth` and add the path to look for packages at.

8. In GameMaker, replace each file in the extension as appropriate.


## Limitations

#### Memory cleanup
- There's a number of problems involved with reinitializing a Python interpreter. Due to the way the garbage collector works, not all memory may be freed once the interpreter is finalized. Since pygml starts a new interpreter every time a function is called, leftover memory will pile up as Python functions are called. This problem may be resolved in a future version by keeping one instance of the interpreter alive for the whole session, and reusing it on each function call. You can read more about this on the [pybind11](https://pybind11.readthedocs.io/en/stable/advanced/embedding.html#interpreter-lifetime) and [CPython](https://docs.python.org/3/c-api/init.html#c.Py_FinalizeEx) documentations.

#### Type conversion

- As pygml relies on GameMaker's `json_stringify` and `json_parse` functions, which are somewhat limited, it is wise to take those limitations into account when passing and returning values. Read this GameMaker [manual page](https://manual.yoyogames.com/GameMaker_Language/GML_Reference/File_Handling/Encoding_And_Hashing/json_stringify.htm) for details.

- Not all Python types support JSON serialization. Currently, returning a non-supported type will raise a `JSONDecodeError`. If you need to return a complex object, write a wrapper function that converts it into a simpler `dict` or `list` and then call that function from GML. A default conversion for unsupported types will be worked on in the future. Additionally, support for third-party JSON libraries such as [orjson](https://github.com/ijl/orjson) will be added for compatiblity with more built-in data types. Read the `json` module [documentation](https://docs.python.org/3/library/json.html) for more details.

- As GML doesn't know the concept of booleans, they are not correctly transmitted to Python as `True` or `False`, but as `1.0` and `0.0`. For most purposes, this isn't a big problem, as they'll be correctly interpreted as true and false when used in this context.

- Similarly, as both integers and floating-point numbers are treated as `real`s by GameMaker, an integer passed to a function will always be received as a `float` on Python's end. This can be particularly problematic if you're passing a value that must be used as an `int`, e.g. as a list index. In that case, you may need to write an intermediary Python function to convert it back to the appropriate type.


## To-do

- Add extra functions to run a simple Python string, file, or call object methods

- Add default conversion for Python types with unsupported JSON serialization

- Add support for other JSON parsing libraries for compatibility with more types

- Add individual error checking for each Python operation (module import, function call etc.)

- Allow more control over the interpreter lifetime with dedicated functions for initializing and finalizing it

- Add more interaction between Python and GameMaker besides simply running code snippets


## Thanks

- The [pybind11](https://github.com/pybind/pybind11) team for making Python/C++ integration such a delightful task.
- [YellowAfterlife](https://yal.cc/) for creating [GmlCppExtFuncs](https://github.com/YAL-GameMaker-Tools/GmlCppExtFuncs) (which was immensely helpful in understanding how data can be passed to GameMaker extensions via buffers), and for being really helpful in general.


---

License - [MIT](https://github.com/Bentroen/pygml/blob/master/LICENSE)
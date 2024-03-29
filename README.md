# GMPython
A GameMaker Studio 2 extension for calling Python scripts from GML.

1. [Overview](#Overview)
2. [Setup](#Setup)
3. [Usage](#Usage)
4. [Building](#Building)
5. [Limitations](#Limitations)
6. [To-do](#To-do)
7. [Thanks](#Thanks)

## Overview

GMPython aims to provide access to a Python interpreter as a simple GameMaker function. It allows:

- Importing modules and calling top-level functions from them
- Passing multiple positional and keyword arguments
- Receiving return values, including nested lists and dicts
- Getting Python exceptions across so that they can be handled in GML
- No Python installation required for users of your game

To achieve this sort of integration in a way that keeps things simple under the hood, GMPython uses the awesome [pybind11](https://github.com/pybind/pybind11) library, which provides seamless operability between Python and C++.

In order to support both passing and returning complex data structures from GML to Python and vice-versa, values are converted to JSON on the way through. While this does come with its own set of limitations, this simple approach allows support for nested data structures out of the box, while keeping conversion code to a minimum, thus reducing errors that could arise from other serialization techniques.

Here are all the types supported by GMPython and their corresponding Python ⟷ GML conversions:

Python        | GML
--------------|-----------------------
`int`         | `real`
`float`       | `real`
`bool`        | `bool`*
`str`         | `string`
`list`        | `array`
`dict`        | `struct`
`None`        | `pointer_null`
_(exception)_ | `undefined`

Nested arrays/structs in the arguments are supported and will be correctly transmitted to Python as nested lists/dicts. In the same fashion, returning those structures from the called function will also convert it to arrays and structs on the way back to GML.


## Setup

Download the extension [here](https://github.com/Bentroen/GMPython/releases/latest). Drag and drop the file into your GameMaker project.

> Due to its extensive use of structs, **GMPython requires GameMaker 2.3+** (2.3.2 or later is recommended due to a [bug](https://forum.yoyogames.com/index.php?threads/issues-saving-undefined-struct-variables-to-json-solved.85143/) in JSON conversion in prior versions).
>
> Currently, downloads are only provided for Windows, although there are no Windows-specific dependencies preventing it from working on Mac/Linux.
>
> The Python version provided with the builds will always be the latest stable release. If you need to use a different Python version, check [Building](#Building).

By default, the extension is configured so Python modules can be loaded either from the root folder of your game, or from a subdirectory named `python` (so your scripts must be placed either in `datafiles/` or `datafiles/python/` in the GameMaker project).

If your project uses a different structure and you need to change where modules are loaded from, open `python39._pth` and change the `python/` line to the appropriate path (or add a new line).

The Python standard library is included with the extension as two files: `python39_minimal.zip` and `python39.zip`. The first file contains the absolutely necessary packages for GMPython to run correctly, while the second contains everything in the standard library. These are **not complementary**, i.e. you can either pick one of them, or create your own custom combination. This leaves you with three options:

1. Delete `python39_minimal.zip` to use the full standard library;
2. Rename `python39_minimal.zip` to `python39.zip` to use the minimal library. Python will be lacking basic functionality, but you'll get a much smaller executable;
3. Add only the packages you need from the standard library to `python39_minimal.zip`, and rename it as above.

As GMPython uses an embedded Python interpreter, installing third-party packages with `pip` is not supported. To include those, install them as normal in your system Python installation, then head to `<python_path>/Lib/site-packages/` and copy the relevant files to `datafiles/python/site-packages/` (or whatever folder you defined above). You may also use external packaging tools, such as [`poetry`](https://python-poetry.org/), to handle your game's dependencies.

That's all! You're now ready to run Python scripts from GameMaker! :D


## Usage

The whole usage consists of one simple GML function with the following syntax:

```
python_call_function(module_name, function_name[, args[, kwargs]]) 
```

To call a simple Python function from a module, getting its return value, do:

```gml
var result = python_call_function("random", "random");
// result will contain a random value from 0 to 1
```

A single `real` or `string` may be passed to the function as a positional argument:

```gml
var result = python_call_function("math", "factorial", 5);
show_debug_message(result) // 120
```

> **Tip:** In Python syntax, the above is essentially the same thing as
>
> ```python
> import math
> result = math.factorial(5)
> print(result)
> ```

Multiple positional arguments may be passed as a GameMaker array.

```gml
var result = python_call_function("builtins", "min", [18, 42, 35, 11, 24]);
show_debug_message(result); // 11
```

> Keep in mind that the outermost `list` received by Python will be unpacked into `*args` when being passed to the function, so wrap that into another array if you want to pass a single `list` rather than separate arguments.

When Python returns a list/tuple or a dict, they will be converted to GML arrays or structs:

```gml
var result = python_call_function("builtins", "sorted", [[4, 3, 2, 5, 1]]);
show_debug_message(result); // [ 1,2,3,4,5 ]
```

> Note that this time we use two square brackets `[[ ]]`, as mentioned above. The outermost pair denotes the array of arguments, while the innermost pair wraps the numbers into another array, which will be passed as a single argument to Python.

Keyword arguments may be passed as a struct:

```gml
var result = python_call_function("builtins", "sorted", [[4, 2, 3, 1, 5]], {reverse: bool(true)});
show_debug_message(result); // [ 5,4,3,2,1 ]
```

> In GameMaker versions prior to 2.3.7, it's recommended to call `bool()` on any boolean that you want to pass as an argument. Due to the way those versions handle booleans, Python will receive a `float` instead of a `bool` if you don't do this, which is not desirable in many cases. Starting in GameMaker 2.3.7, this is no longer necessary. Read more about that in [Limitations](#GameMaker-data-types).

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

All the examples above showcase basic features of the extension by calling functions from the standard library. However, its true power lies on its capability of importing third-party modules.

You can add as many modules as you wish to your game by placing them in `datafiles/` or `datafiles/python/` in your GameMaker project. If you want to keep your scripts in a different folder, check [Setup](#Setup) above.

#### Buffer usage

In order to pass arguments and receive return results back, GMPython uses a single shared buffer. By default, this buffer is allocated 4,096 bytes (4 KiB), which should be enough for common usage. However, in case you're passing around or receiving really large structures, you should increase the internal buffer's size prior to calling the function:

```gml
python_set_buffer_size(65536); // will resize the buffer to 64 KiB
```

Keep in mind that the size in bytes taken by each variable is not actually its raw size, but the length of its data encoded to JSON — so the number 1000000 takes 7 bytes, 1000000000 takes 10 bytes and so on.

Currently, writing data beyond the buffer size results in undefined behavior — as such, it is wise to be generous when allocating the buffer size, as the resulting data may end up being larger than expected. A more sophisticated way of detecting buffer overflows may be added in the future.


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

5. Download the [Windows embeddable package](https://www.python.org/downloads/windows/) for your version of Python. This contains a minimal Python installation that can be shipped with your game so that users do not need Python installed on their machine. You can read more about it [here](https://docs.python.org/3/using/windows.html#the-embeddable-package).

6. Extract `python39.dll`, `python39.zip` and `python39._pth` from the embeddable package.

   > **Tip:** While the files included in the package aim to mimic a default, system-wide Python installation, most of the files aren't necessary for the Python distribution to work correctly. So, to shrink the size of your game's executable, you may want to remove packages from the standard library that you're not likely to use.
   > 
   > Keep in mind, however, that some modules are used during the Python initialization, and some are required by the `json` module. **Removing any of those will cause the extension to fail or even crash your game.** Make sure to use the `python39_minimal.zip` file included in the release as a base on what files to include, then add any other modules you need.

7. If you want to have your Python files somewhere other than your game's root folder, open `python39._pth` and add the path to look for packages at.

8. In GameMaker, replace each file in the extension as appropriate.


## Limitations

#### JSON conversion

- As GMPython relies on GameMaker's `json_stringify()` and `json_parse()` functions, which are somewhat limited, it is wise to take those limitations into account when passing and returning values. Read this GameMaker [manual page](https://manual.yoyogames.com/GameMaker_Language/GML_Reference/File_Handling/Encoding_And_Hashing/json_stringify.htm) for details.

- Not all Python types support JSON serialization. Currently, calling a function that returns a non-supported type will raise a `JSONDecodeError`. If you need to return a complex object, write a wrapper function that converts it into a simpler `dict` or `list` and then call that function from GML. A default conversion for unsupported types will be worked on in the future. Additionally, support for third-party JSON libraries such as [orjson](https://github.com/ijl/orjson) will be added for compatiblity with more built-in data types. Read the `json` module [documentation](https://docs.python.org/3/library/json.html) for more details.

#### GameMaker data types

- As both integers and floating-point numbers are treated as `real`s by GameMaker, an integer passed to a function will always be received as a `float` on Python's end. This can be particularly problematic if you're passing a value that must be used as an `int`, e.g. as a list index. In that case, you may need to write an intermediary Python function to convert it back to the appropriate type.

- Prior to GameMaker 2.3.7, boolean values were internally stored as 0 and 1. As such, if `true` and `false` were passed normally as arguments to a function, they would, for the reason above, become `float`s in Python (0.0 and 1.0). This can be a huge burden, since those values can't be interpreted as booleans in many cases. The only way to correctly receive the values as `True` and `False` is to call `bool()` on every boolean value you pass as an argument. This behavior was patched in GameMaker 2.3.7, so you can use `true` and `false` directly if you're using a newer version.


## To-do

- Add extra functions to run a simple Python string, file, or call object methods

- Add default conversion for Python types with unsupported JSON serialization

- Add support for other JSON parsing libraries for compatibility with more types

- Add individual error checking for each Python operation (module import, function call etc.)

- Add more interaction between Python and GameMaker besides simply running code snippets

- Add support for Mac/Linux and (possibly) older GameMaker versions


## Thanks

- The [pybind11](https://github.com/pybind/pybind11) team for making Python/C++ integration such a delightful task.
- [YellowAfterlife](https://yal.cc/) for creating [GmlCppExtFuncs](https://github.com/YAL-GameMaker-Tools/GmlCppExtFuncs) (which was immensely helpful in understanding how data can be passed to GameMaker extensions via buffers), and for being really helpful in general.
- [DragoniteSpam](https://www.youtube.com/c/DragoniteSpam) for making the [video](https://youtu.be/yz4q9hcstdw) that brought GameMaker's boolean patch to my attention. :)


---

License - [MIT](https://github.com/Bentroen/GMPython/blob/master/LICENSE)

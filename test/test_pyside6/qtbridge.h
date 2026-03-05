// Thin C bridge exposing Qt QML functionality to Python.
// Built as a Python C extension module.

#pragma push_macro("slots")
#undef slots
#include <Python.h>
#pragma pop_macro("slots")

PyMODINIT_FUNC PyInit_qtbridge(void);

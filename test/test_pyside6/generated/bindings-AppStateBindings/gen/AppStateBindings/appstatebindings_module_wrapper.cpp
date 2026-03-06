
#include <sbkpython.h>
#include <shiboken.h>
#include <algorithm>
#include <signature.h>
#include <sbkcontainer.h>
#include <sbkstaticstrings.h>

#define PYSIDE6_COMOPT_FULLNAME 1
#define PYSIDE6_COMOPT_COMPRESS 1
// TODO: #define PYSIDE6_COMOPT_FOLDING 1

#ifndef QT_NO_VERSION_TAGGING
#  define QT_NO_VERSION_TAGGING
#endif
#include <QtCore/QDebug>
#include <pysidecleanup.h>
#include <pysideqenum.h>
#include <feature_select.h>
#include <pysidestaticstrings.h>
#include "appstatebindings_python.h"

#include <QList>
#include <QMap>
#include <QString>
#include <qbytearray.h>
#include <qobject.h>


// Current module's type array.
Shiboken::Module::TypeInitStruct *SbkAppStateBindingsTypeStructs = nullptr;
// Backwards compatible structure with identical indexing.
PyTypeObject **SbkAppStateBindingsTypes = nullptr;
// Current module's PyObject pointer.
PyObject *SbkAppStateBindingsModuleObject = nullptr;
// Current module's converter array.
SbkConverter **SbkAppStateBindingsTypeConverters = nullptr;

void cleanTypesAttributes() {
    static PyObject *attrName = Shiboken::PyName::qtStaticMetaObject();
    const int imax = SBK_AppStateBindings_IDX_COUNT;
    for (int i = 0; i < imax && SbkAppStateBindingsTypeStructs[i].fullName != nullptr; ++i) {
        auto *pyType = reinterpret_cast<PyObject *>(SbkAppStateBindingsTypeStructs[i].type);
        if (pyType != nullptr && PyObject_HasAttr(pyType, attrName))
            PyObject_SetAttr(pyType, attrName, Py_None);
    }
}

// Global functions ------------------------------------------------------------

static PyMethodDef AppStateBindings_methods[] = {
    {nullptr, nullptr, 0, nullptr} // Sentinel
};

// Classes initialization functions ------------------------------------------------------------
PyTypeObject *init_AppState(PyObject *enclosing);

// Required modules' type and converter arrays.
Shiboken::Module::TypeInitStruct *SbkPySide6_QtCoreTypeStructs;
SbkConverter **SbkPySide6_QtCoreTypeConverters;

// Module initialization ------------------------------------------------------------
// Container Type converters.

// C++ to Python conversion for container type 'QList<int>'.
static PyObject *_QList_int__CppToPython_PyList(const void *cppIn)
{
    const auto &cppInRef = *reinterpret_cast<const ::QList<int> *>(cppIn);
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - START
    PyObject *pyOut = PyList_New(Py_ssize_t(cppInRef.size()));
    Py_ssize_t idx = 0;
    for (auto it = std::cbegin(cppInRef), end = std::cend(cppInRef); it != end; ++it, ++idx) {
        const auto &cppItem = *it;
        PyList_SET_ITEM(pyOut, idx, Shiboken::Conversions::copyToPython(Shiboken::Conversions::PrimitiveTypeConverter<int>(), &cppItem));
    }
    return pyOut;
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - END

}
static void PySequence_PythonToCpp__QList_int_(PyObject *pyIn, void *cppOut)
{
    auto &cppOutRef = *reinterpret_cast<::QList<int> *>(cppOut);
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - START
    (cppOutRef).clear();
    if (PyList_Check(pyIn)) {
        const Py_ssize_t size = PySequence_Size(pyIn);
        if (size > 10)
            (cppOutRef).reserve(size);
    }

    Shiboken::AutoDecRef it(PyObject_GetIter(pyIn));
    while (true) {
        Shiboken::AutoDecRef pyItem(PyIter_Next(it.object()));
        if (pyItem.isNull()) {
            if (PyErr_Occurred() && PyErr_ExceptionMatches(PyExc_StopIteration))
                PyErr_Clear();
            break;
        }
        int cppItem;
    Shiboken::Conversions::pythonToCppCopy(Shiboken::Conversions::PrimitiveTypeConverter<int>(), pyItem, &(cppItem));
        (cppOutRef).push_back(cppItem);
    }
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - END

}
static PythonToCppFunc is_PySequence_PythonToCpp__QList_int__Convertible(PyObject *pyIn)
{
    if (Shiboken::Conversions::convertibleSequenceTypes(Shiboken::Conversions::PrimitiveTypeConverter<int>(), pyIn))
        return PySequence_PythonToCpp__QList_int_;
    return {};
}


// Binding for QList<int>

template <>
struct ShibokenContainerValueConverter<int>
{
    static bool checkValue(PyObject *pyArg)
    {
        return PyLong_Check(pyArg);
    }

    static PyObject *convertValueToPython(int cppArg)
    {
        return Shiboken::Conversions::copyToPython(Shiboken::Conversions::PrimitiveTypeConverter<int>(), &cppArg);
    }

    static std::optional<int> convertValueToCpp(PyObject *pyArg)
    {
        Shiboken::Conversions::PythonToCppConversion pythonToCpp;
        if (!(PyLong_Check(pyArg) && (pythonToCpp = Shiboken::Conversions::pythonToCppConversion(Shiboken::Conversions::PrimitiveTypeConverter<int>(), (pyArg))))) {
            Shiboken::Errors::setWrongContainerType();
            return {};
        }
        int cppArg;
        pythonToCpp(pyArg, &cppArg);
        return cppArg;
    }
};

static PyMethodDef QIntList_methods[] = {
    {"push_back", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::push_back), METH_O, "push_back"},
    {"append", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::push_back), METH_O, "append"},
    {"clear", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::clear), METH_NOARGS, "clear"},
    {"pop_back", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::pop_back), METH_NOARGS, "pop_back"},
    {"removeLast", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::pop_back), METH_NOARGS, "removeLast"},
    {"push_front", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::push_front), METH_O, "push_front"},
    {"prepend", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::push_front), METH_O, "prepend"},
    {"pop_front", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::pop_front), METH_NOARGS, "pop_front"},
    {"removeFirst", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::pop_front), METH_O, "removeFirst"},
    {"reserve", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::reserve), METH_O, "reserve"},
    {"capacity", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::capacity), METH_NOARGS, "capacity"},
    {"data", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::data), METH_NOARGS, "data"},
    {"constData", reinterpret_cast<PyCFunction>(ShibokenSequenceContainerPrivate<QList<int>>::constData), METH_NOARGS, "constData"},
    {nullptr, nullptr, 0, nullptr} // Sentinel
};

static PyType_Slot QIntList_slots[] = {
    {Py_tp_init, reinterpret_cast<void *>(ShibokenSequenceContainerPrivate<QList<int>>::tpInit)},
    {Py_tp_new, reinterpret_cast<void *>(ShibokenSequenceContainerPrivate<QList<int>>::tpNew)},
    {Py_tp_free, reinterpret_cast<void *>(ShibokenSequenceContainerPrivate<QList<int>>::tpFree)},
    {Py_tp_dealloc, reinterpret_cast<void *>(Sbk_object_dealloc)},
    {Py_tp_methods, reinterpret_cast<void *>(QIntList_methods)},
    {Py_sq_ass_item, reinterpret_cast<void *>(ShibokenSequenceContainerPrivate<QList<int>>::sqSetItem)},
    {Py_sq_length, reinterpret_cast<void *>(ShibokenSequenceContainerPrivate<QList<int>>::sqLen)},
    {Py_sq_item, reinterpret_cast<void *>(ShibokenSequenceContainerPrivate<QList<int>>::sqGetItem)},
    {0, nullptr}
};

static PyType_Spec QIntList_spec = {
    "1:AppStateBindings.QIntList",
    sizeof(ShibokenContainer),
    0,
    Py_TPFLAGS_DEFAULT,
    QIntList_slots
};

static inline PyTypeObject *createQIntListType()
{
    auto *result = SbkType_FromSpec(&QIntList_spec);
    Py_INCREF(Py_True);
    Shiboken::AutoDecRef tpDict(PepType_GetDict(result));
    PyDict_SetItem(tpDict.object(), Shiboken::PyMagicName::opaque_container(), Py_True);
    return result;
}

static PyTypeObject *QIntList_TypeF()
{
    static PyTypeObject *type = createQIntListType();
    return type;
}

extern "C" PyObject *createQIntList(QList<int>* ct)
{
    auto *container = PyObject_New(ShibokenContainer, QIntList_TypeF());
    auto *d = new ShibokenSequenceContainerPrivate<QList<int>>();
    d->m_list = ct;
    container->d = d;
    return reinterpret_cast<PyObject *>(container);
}

extern "C" PyObject *createConstQIntList(const QList<int>* ct)
{
    auto *container = PyObject_New(ShibokenContainer, QIntList_TypeF());
    auto *d = new ShibokenSequenceContainerPrivate<QList<int>>();
    d->m_list = const_cast<QList<int> *>(ct);
    d->m_const = true;
    container->d = d;
    return reinterpret_cast<PyObject *>(container);
}

extern "C" int QIntList_Check(PyObject *pyArg)
{
    return pyArg != nullptr && pyArg != Py_None && pyArg->ob_type == QIntList_TypeF();
}

extern "C" void PythonToCppQIntList(PyObject *pyArg, void *cppOut)
{
    auto *d = ShibokenSequenceContainerPrivate<QList<int>>::get(pyArg);
    *reinterpret_cast<QList<int>**>(cppOut) = d->m_list;
}

extern "C" PythonToCppFunc isQIntListPythonToCppConvertible(PyObject *pyArg)
{
    if (QIntList_Check(pyArg))
        return PythonToCppQIntList;
    return {};
}

extern "C" void PythonToQVariantQIntList(PyObject *pyArg, void *cppOut)
{
    auto *d = ShibokenSequenceContainerPrivate<QList<int>>::get(pyArg);
    *reinterpret_cast<QVariant *>(cppOut) = QVariant::fromValue(*d->m_list);
}

extern "C" PythonToCppFunc isQIntListPythonToQVariantConvertible(PyObject *pyArg)
{
    if (QIntList_Check(pyArg))
        return PythonToQVariantQIntList;
    return {};
}

// C++ to Python conversion for container type 'QList<QObject*>'.
static PyObject *_QList_QObjectPTR__CppToPython_PyList(const void *cppIn)
{
    const auto &cppInRef = *reinterpret_cast<const ::QList<QObject*> *>(cppIn);
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - START
    PyObject *pyOut = PyList_New(Py_ssize_t(cppInRef.size()));
    Py_ssize_t idx = 0;
    for (auto it = std::cbegin(cppInRef), end = std::cend(cppInRef); it != end; ++it, ++idx) {
        const auto &cppItem = *it;
        PyList_SET_ITEM(pyOut, idx, Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), cppItem));
    }
    return pyOut;
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - END

}
static void PySequence_PythonToCpp__QList_QObjectPTR_(PyObject *pyIn, void *cppOut)
{
    auto &cppOutRef = *reinterpret_cast<::QList<QObject*> *>(cppOut);
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - START
    (cppOutRef).clear();
    if (PyList_Check(pyIn)) {
        const Py_ssize_t size = PySequence_Size(pyIn);
        if (size > 10)
            (cppOutRef).reserve(size);
    }

    Shiboken::AutoDecRef it(PyObject_GetIter(pyIn));
    while (true) {
        Shiboken::AutoDecRef pyItem(PyIter_Next(it.object()));
        if (pyItem.isNull()) {
            if (PyErr_Occurred() && PyErr_ExceptionMatches(PyExc_StopIteration))
                PyErr_Clear();
            break;
        }
        ::QObject* cppItem{nullptr};
    Shiboken::Conversions::pythonToCppPointer(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), pyItem, &(cppItem));
        (cppOutRef).push_back(cppItem);
    }
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - END

}
static PythonToCppFunc is_PySequence_PythonToCpp__QList_QObjectPTR__Convertible(PyObject *pyIn)
{
    if (Shiboken::Conversions::checkSequenceTypes(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), pyIn))
        return PySequence_PythonToCpp__QList_QObjectPTR_;
    return {};
}

// C++ to Python conversion for container type 'QList<QByteArray>'.
static PyObject *_QList_QByteArray__CppToPython_PyList(const void *cppIn)
{
    const auto &cppInRef = *reinterpret_cast<const ::QList<QByteArray> *>(cppIn);
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - START
    PyObject *pyOut = PyList_New(Py_ssize_t(cppInRef.size()));
    Py_ssize_t idx = 0;
    for (auto it = std::cbegin(cppInRef), end = std::cend(cppInRef); it != end; ++it, ++idx) {
        const auto &cppItem = *it;
        PyList_SET_ITEM(pyOut, idx, Shiboken::Conversions::copyToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QByteArray_IDX]), &cppItem));
    }
    return pyOut;
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - END

}
static void PySequence_PythonToCpp__QList_QByteArray_(PyObject *pyIn, void *cppOut)
{
    auto &cppOutRef = *reinterpret_cast<::QList<QByteArray> *>(cppOut);
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - START
    (cppOutRef).clear();
    if (PyList_Check(pyIn)) {
        const Py_ssize_t size = PySequence_Size(pyIn);
        if (size > 10)
            (cppOutRef).reserve(size);
    }

    Shiboken::AutoDecRef it(PyObject_GetIter(pyIn));
    while (true) {
        Shiboken::AutoDecRef pyItem(PyIter_Next(it.object()));
        if (pyItem.isNull()) {
            if (PyErr_Occurred() && PyErr_ExceptionMatches(PyExc_StopIteration))
                PyErr_Clear();
            break;
        }
        ::QByteArray cppItem;
    Shiboken::Conversions::pythonToCppCopy(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QByteArray_IDX]), pyItem, &(cppItem));
        (cppOutRef).push_back(cppItem);
    }
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - END

}
static PythonToCppFunc is_PySequence_PythonToCpp__QList_QByteArray__Convertible(PyObject *pyIn)
{
    if (Shiboken::Conversions::convertibleSequenceTypes(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QByteArray_IDX]), pyIn))
        return PySequence_PythonToCpp__QList_QByteArray_;
    return {};
}

// C++ to Python conversion for container type 'QList<QVariant>'.
static PyObject *_QList_QVariant__CppToPython_PyList(const void *cppIn)
{
    const auto &cppInRef = *reinterpret_cast<const ::QList<QVariant> *>(cppIn);
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - START
    PyObject *pyOut = PyList_New(Py_ssize_t(cppInRef.size()));
    Py_ssize_t idx = 0;
    for (auto it = std::cbegin(cppInRef), end = std::cend(cppInRef); it != end; ++it, ++idx) {
        const auto &cppItem = *it;
        PyList_SET_ITEM(pyOut, idx, Shiboken::Conversions::copyToPython(SbkPySide6_QtCoreTypeConverters[SBK_QVariant_IDX], &cppItem));
    }
    return pyOut;
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - END

}
static void PySequence_PythonToCpp__QList_QVariant_(PyObject *pyIn, void *cppOut)
{
    auto &cppOutRef = *reinterpret_cast<::QList<QVariant> *>(cppOut);
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - START
    (cppOutRef).clear();
    if (PyList_Check(pyIn)) {
        const Py_ssize_t size = PySequence_Size(pyIn);
        if (size > 10)
            (cppOutRef).reserve(size);
    }

    Shiboken::AutoDecRef it(PyObject_GetIter(pyIn));
    while (true) {
        Shiboken::AutoDecRef pyItem(PyIter_Next(it.object()));
        if (pyItem.isNull()) {
            if (PyErr_Occurred() && PyErr_ExceptionMatches(PyExc_StopIteration))
                PyErr_Clear();
            break;
        }
        ::QVariant cppItem;
    Shiboken::Conversions::pythonToCppCopy(SbkPySide6_QtCoreTypeConverters[SBK_QVariant_IDX], pyItem, &(cppItem));
        (cppOutRef).push_back(cppItem);
    }
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - END

}
static PythonToCppFunc is_PySequence_PythonToCpp__QList_QVariant__Convertible(PyObject *pyIn)
{
    if (Shiboken::Conversions::convertibleSequenceTypes(SbkPySide6_QtCoreTypeConverters[SBK_QVariant_IDX], pyIn))
        return PySequence_PythonToCpp__QList_QVariant_;
    return {};
}

// C++ to Python conversion for container type 'QList<QString>'.
static PyObject *_QList_QString__CppToPython_PyList(const void *cppIn)
{
    const auto &cppInRef = *reinterpret_cast<const ::QList<QString> *>(cppIn);
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - START
    PyObject *pyOut = PyList_New(Py_ssize_t(cppInRef.size()));
    Py_ssize_t idx = 0;
    for (auto it = std::cbegin(cppInRef), end = std::cend(cppInRef); it != end; ++it, ++idx) {
        const auto &cppItem = *it;
        PyList_SET_ITEM(pyOut, idx, Shiboken::Conversions::copyToPython(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], &cppItem));
    }
    return pyOut;
    // TEMPLATE - shiboken_conversion_cppsequence_to_pylist - END

}
static void PySequence_PythonToCpp__QList_QString_(PyObject *pyIn, void *cppOut)
{
    auto &cppOutRef = *reinterpret_cast<::QList<QString> *>(cppOut);
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - START
    (cppOutRef).clear();
    if (PyList_Check(pyIn)) {
        const Py_ssize_t size = PySequence_Size(pyIn);
        if (size > 10)
            (cppOutRef).reserve(size);
    }

    Shiboken::AutoDecRef it(PyObject_GetIter(pyIn));
    while (true) {
        Shiboken::AutoDecRef pyItem(PyIter_Next(it.object()));
        if (pyItem.isNull()) {
            if (PyErr_Occurred() && PyErr_ExceptionMatches(PyExc_StopIteration))
                PyErr_Clear();
            break;
        }
        ::QString cppItem;
    Shiboken::Conversions::pythonToCppCopy(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], pyItem, &(cppItem));
        (cppOutRef).push_back(cppItem);
    }
    // TEMPLATE - shiboken_conversion_pyiterable_to_cppsequentialcontainer_reserve - END

}
static PythonToCppFunc is_PySequence_PythonToCpp__QList_QString__Convertible(PyObject *pyIn)
{
    if (Shiboken::Conversions::convertibleSequenceTypes(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], pyIn))
        return PySequence_PythonToCpp__QList_QString_;
    return {};
}

// C++ to Python conversion for container type 'QMap<QString,QVariant>'.
static PyObject *_QMap_QString_QVariant__CppToPython_PyDict(const void *cppIn)
{
    const auto &cppInRef = *reinterpret_cast<const ::QMap<QString,QVariant> *>(cppIn);
    // TEMPLATE - shiboken_conversion_qmap_to_pydict - START
    PyObject *pyOut = PyDict_New();
    for (auto it = std::cbegin(cppInRef), end = std::cend(cppInRef); it != end; ++it) {
        const auto &key = it.key();
        const auto &value = it.value();
        PyObject *pyKey = Shiboken::Conversions::copyToPython(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], &key);
        PyObject *pyValue = Shiboken::Conversions::copyToPython(SbkPySide6_QtCoreTypeConverters[SBK_QVariant_IDX], &value);
        PyDict_SetItem(pyOut, pyKey, pyValue);
        Py_DECREF(pyKey);
        Py_DECREF(pyValue);
    }
    return pyOut;
    // TEMPLATE - shiboken_conversion_qmap_to_pydict - END

}
static void PyDict_PythonToCpp__QMap_QString_QVariant_(PyObject *pyIn, void *cppOut)
{
    auto &cppOutRef = *reinterpret_cast<::QMap<QString,QVariant> *>(cppOut);
    // TEMPLATE - shiboken_conversion_pydict_to_qmap - START
    PyObject *key{};
    PyObject *value{};
    cppOutRef.clear();
    Py_ssize_t pos = 0;
    while (PyDict_Next(pyIn, &pos, &key, &value)) {
        ::QString cppKey;
    Shiboken::Conversions::pythonToCppCopy(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], key, &(cppKey));
        ::QVariant cppValue;
    Shiboken::Conversions::pythonToCppCopy(SbkPySide6_QtCoreTypeConverters[SBK_QVariant_IDX], value, &(cppValue));
        cppOutRef.insert(cppKey, cppValue);
    }
    // TEMPLATE - shiboken_conversion_pydict_to_qmap - END

}
static PythonToCppFunc is_PyDict_PythonToCpp__QMap_QString_QVariant__Convertible(PyObject *pyIn)
{
    if (Shiboken::Conversions::convertibleDictTypes(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], false, SbkPySide6_QtCoreTypeConverters[SBK_QVariant_IDX], false, pyIn))
        return PyDict_PythonToCpp__QMap_QString_QVariant_;
    return {};
}


static struct PyModuleDef moduledef = {
    /* m_base     */ PyModuleDef_HEAD_INIT,
    /* m_name     */ "AppStateBindings",
    /* m_doc      */ nullptr,
    /* m_size     */ -1,
    /* m_methods  */ AppStateBindings_methods,
    /* m_reload   */ nullptr,
    /* m_traverse */ nullptr,
    /* m_clear    */ nullptr,
    /* m_free     */ nullptr
};

// The signatures string for the global functions.
// Multiple signatures have their index "n:" in front.
#if PYSIDE6_COMOPT_COMPRESS == 0
static const char *AppStateBindings_SignatureStrings[] = {
    nullptr}; // Sentinel
#else
static constexpr size_t AppStateBindings_SignatureByteSize = 0;
static constexpr uint8_t AppStateBindings_SignatureBytes[1] = {
    0x00
};
#endif

static void initInheritance()
{
    auto &bm = Shiboken::BindingManager::instance();
    SBK_UNUSED(bm)
    bm.addClassInheritance(&SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX],
                           &SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);
}

extern "C" LIBSHIBOKEN_EXPORT PyObject *PyInit_AppStateBindings()
{
    if (SbkAppStateBindingsModuleObject != nullptr)
        return SbkAppStateBindingsModuleObject;
    {
        Shiboken::AutoDecRef requiredModule(Shiboken::Module::import("PySide6.QtCore"));
        if (requiredModule.isNull())
            return nullptr;
        SbkPySide6_QtCoreTypeStructs = Shiboken::Module::getTypes(requiredModule);
        SbkPySide6_QtCoreTypeConverters = Shiboken::Module::getTypeConverters(requiredModule);
    }

    // Create an array of wrapper types/names for the current module.
    static Shiboken::Module::TypeInitStruct cppApi[] = {
        {nullptr, "AppStateBindings.AppState"},
        {nullptr, nullptr}
    };
    // The new global structure consisting of (type, name) pairs.
    SbkAppStateBindingsTypeStructs = cppApi;
    QT_WARNING_PUSH
    QT_WARNING_DISABLE_DEPRECATED
    // The backward compatible alias with upper case indexes.
    SbkAppStateBindingsTypes = reinterpret_cast<PyTypeObject **>(cppApi);
    QT_WARNING_POP

    // Create an array of primitive type converters for the current module.
    static SbkConverter *sbkConverters[SBK_AppStateBindings_CONVERTERS_IDX_COUNT];
    SbkAppStateBindingsTypeConverters = sbkConverters;

    PyObject *module = Shiboken::Module::create("AppStateBindings", &moduledef);

    // Make module available from global scope
    SbkAppStateBindingsModuleObject = module;

    // Initialize classes in the type system
    Shiboken::Module::AddTypeCreationFunction(module, "AppState", init_AppState);

    // Register converter for type 'QList<int>'.
    SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_int_IDX] = Shiboken::Conversions::createConverter(&PyList_Type, _QList_int__CppToPython_PyList);
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_int_IDX], "QList<int>");
    Shiboken::Conversions::addPythonToCppValueConversion(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_int_IDX],
        PySequence_PythonToCpp__QList_int_,
        is_PySequence_PythonToCpp__QList_int__Convertible);
    Shiboken::Conversions::setPythonToCppPointerFunctions(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_int_IDX],
        PythonToCppQIntList,
        isQIntListPythonToCppConvertible);

    // Register converter for type 'QList<QObject*>'.
    SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QObjectPTR_IDX] = Shiboken::Conversions::createConverter(&PyList_Type, _QList_QObjectPTR__CppToPython_PyList);
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QObjectPTR_IDX], "QList<QObject*>");
    Shiboken::Conversions::addPythonToCppValueConversion(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QObjectPTR_IDX],
        PySequence_PythonToCpp__QList_QObjectPTR_,
        is_PySequence_PythonToCpp__QList_QObjectPTR__Convertible);
    // Register converters for type aliases of QList<QObject*>'.
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QObjectPTR_IDX], "QObjectList");

    // Register converter for type 'QList<QByteArray>'.
    SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QByteArray_IDX] = Shiboken::Conversions::createConverter(&PyList_Type, _QList_QByteArray__CppToPython_PyList);
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QByteArray_IDX], "QList<QByteArray>");
    Shiboken::Conversions::addPythonToCppValueConversion(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QByteArray_IDX],
        PySequence_PythonToCpp__QList_QByteArray_,
        is_PySequence_PythonToCpp__QList_QByteArray__Convertible);
    // Register converters for type aliases of QList<QByteArray>'.
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QByteArray_IDX], "QByteArrayList");

    // Register converter for type 'QList<QVariant>'.
    SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QVariant_IDX] = Shiboken::Conversions::createConverter(&PyList_Type, _QList_QVariant__CppToPython_PyList);
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QVariant_IDX], "QList<QVariant>");
    Shiboken::Conversions::addPythonToCppValueConversion(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QVariant_IDX],
        PySequence_PythonToCpp__QList_QVariant_,
        is_PySequence_PythonToCpp__QList_QVariant__Convertible);
    // Register converters for type aliases of QList<QVariant>'.
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QVariant_IDX], "QVariantList");

    // Register converter for type 'QList<QString>'.
    SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QString_IDX] = Shiboken::Conversions::createConverter(&PyList_Type, _QList_QString__CppToPython_PyList);
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QString_IDX], "QList<QString>");
    Shiboken::Conversions::addPythonToCppValueConversion(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QList_QString_IDX],
        PySequence_PythonToCpp__QList_QString_,
        is_PySequence_PythonToCpp__QList_QString__Convertible);
    // Register converters for type aliases of QList<QString>'.

    // Register converter for type 'QMap<QString,QVariant>'.
    SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QMap_QString_QVariant_IDX] = Shiboken::Conversions::createConverter(&PyDict_Type, _QMap_QString_QVariant__CppToPython_PyDict);
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QMap_QString_QVariant_IDX], "QMap<QString,QVariant>");
    Shiboken::Conversions::addPythonToCppValueConversion(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QMap_QString_QVariant_IDX],
        PyDict_PythonToCpp__QMap_QString_QVariant_,
        is_PyDict_PythonToCpp__QMap_QString_QVariant__Convertible);
    // Register converters for type aliases of QMap<QString,QVariant>'.
    Shiboken::Conversions::registerConverterName(SbkAppStateBindingsTypeConverters[SBK_AppStateBindings_QMap_QString_QVariant_IDX], "QVariantMap");


    // Opaque container type registration
    PyObject *ob_type{};
    auto *qVariantConverter = Shiboken::Conversions::getConverter("QVariant");
    Q_ASSERT(qVariantConverter != nullptr);
    ob_type = reinterpret_cast<PyObject *>(QIntList_TypeF());
    Py_XINCREF(ob_type);
    PyModule_AddObject(module, "QIntList", ob_type);
    if constexpr (QMetaTypeId2<int>::Defined) {
        Shiboken::Conversions::prependPythonToCppValueConversion(qVariantConverter,
            PythonToQVariantQIntList, isQIntListPythonToQVariantConvertible);
    }

    // Register primitive types converters.
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "__darwin_fsblkcnt_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "__darwin_fsfilcnt_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<char>(), "__darwin_uuid_string_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned char>(), "__darwin_uuid_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<char>(), "caddr_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<int>(), "errno_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "fsblkcnt_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "fsfilcnt_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<short>(), "int_fast16_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<int>(), "int_fast32_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<long long>(), "int_fast64_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<signed char>(), "int_fast8_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<short>(), "int_least16_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<int>(), "int_least32_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<long long>(), "int_least64_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<signed char>(), "int_least8_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<long>(), "intmax_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<bool>(), "qInternalCallback");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned char>(), "u_char");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "u_int");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned short>(), "u_short");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned short>(), "uint_fast16_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "uint_fast32_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned long long>(), "uint_fast64_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned char>(), "uint_fast8_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned short>(), "uint_least16_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned int>(), "uint_least32_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned long long>(), "uint_least64_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned char>(), "uint_least8_t");
    Shiboken::Conversions::registerConverterAlias(Shiboken::Conversions::PrimitiveTypeConverter<unsigned long>(), "uintmax_t");

    Shiboken::Module::registerTypes(module, SbkAppStateBindingsTypeStructs);
    Shiboken::Module::registerTypeConverters(module, SbkAppStateBindingsTypeConverters);

    initInheritance();

    if (Shiboken::Errors::occurred() != nullptr) {
        PyErr_Print();
        Py_FatalError("can't initialize module AppStateBindings");
    }
    PySide::registerCleanupFunction(cleanTypesAttributes);

#if PYSIDE6_COMOPT_COMPRESS == 0
    FinishSignatureInitialization(module, AppStateBindings_SignatureStrings);
#else
    if (FinishSignatureInitBytes(module, AppStateBindings_SignatureBytes, AppStateBindings_SignatureByteSize) < 0)
        return {};
#endif

    return module;
}

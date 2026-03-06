
// Workaround to access protected functions
#ifndef protected
#  define protected public
#endif

// default includes
#include <shiboken.h>

#define PYSIDE6_COMOPT_FULLNAME 1
#define PYSIDE6_COMOPT_COMPRESS 1
// TODO: #define PYSIDE6_COMOPT_FOLDING 1

#ifndef QT_NO_VERSION_TAGGING
#  define QT_NO_VERSION_TAGGING
#endif
#include <QtCore/QDebug>
#include <pysideqobject.h>
#include <pysidesignal.h>
#include <pysideproperty.h>
#include <signalmanager.h>
#include <pysidemetafunction.h>
#include <pysideqenum.h>
#include <pysideqmetatype.h>
#include <pysideutils.h>
#include <feature_select.h>
QT_WARNING_DISABLE_DEPRECATED


// module include
#include "appstatebindings_python.h"

// main header
#include "appstate_wrapper.h"

// Argument includes
#include <QAnyStringView>
#include <QList>
#include <QString>
#include <qbytearray.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qobjectdefs.h>

#include <cctype>
#include <cstring>
#include <iterator>
#include <type_traits>
#include <typeinfo>

// Native ---------------------------------------------------------

void AppStateWrapper::resetPyMethodCache()
{
    std::fill_n(m_PyMethodCache, sizeof(m_PyMethodCache) / sizeof(m_PyMethodCache[0]), false);
}

AppStateWrapper::AppStateWrapper(::QObject * parent) : AppState(parent)
{
}

void AppStateWrapper::childEvent(::QChildEvent * event)
{
    static const char *funcName = "childEvent";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[0], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::childEvent(event);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[1] = {
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QChildEvent_IDX]), event)
    };

    const bool invalidateArg1 = Py_REFCNT(pyArgArray[0]) == 1;
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(N)",
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QChildEvent_IDX]), event)
    ));
    bool invalidateArg1 = Py_REFCNT(PyTuple_GetItem(pyArgs, 0)) == 1;
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 1, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(pyArgArray[0]);
    Py_DECREF(pyArgArray[0]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(PyTuple_GetItem(pyArgs, 0));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return;
    }
}

void AppStateWrapper::connectNotify(const ::QMetaMethod & signal)
{
    static const char *funcName = "connectNotify";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[1], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::connectNotify(signal);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[1] = {
        Shiboken::Conversions::copyToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QMetaMethod_IDX]), &signal)
    };
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(N)",
        Shiboken::Conversions::copyToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QMetaMethod_IDX]), &signal)
    ));
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 1, nullptr));
    Py_DECREF(pyArgArray[0]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return;
    }
}

void AppStateWrapper::customEvent(::QEvent * event)
{
    static const char *funcName = "customEvent";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[2], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::customEvent(event);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[1] = {
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QEvent_IDX]), event)
    };

    const bool invalidateArg1 = Py_REFCNT(pyArgArray[0]) == 1;
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(N)",
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QEvent_IDX]), event)
    ));
    bool invalidateArg1 = Py_REFCNT(PyTuple_GetItem(pyArgs, 0)) == 1;
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 1, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(pyArgArray[0]);
    Py_DECREF(pyArgArray[0]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(PyTuple_GetItem(pyArgs, 0));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return;
    }
}

void AppStateWrapper::disconnectNotify(const ::QMetaMethod & signal)
{
    static const char *funcName = "disconnectNotify";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[3], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::disconnectNotify(signal);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[1] = {
        Shiboken::Conversions::copyToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QMetaMethod_IDX]), &signal)
    };
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(N)",
        Shiboken::Conversions::copyToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QMetaMethod_IDX]), &signal)
    ));
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 1, nullptr));
    Py_DECREF(pyArgArray[0]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return;
    }
}

::QString AppStateWrapper::displayName() const
{
    // This method belongs to a property.
    static const char *funcName = "1:displayName";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[4], nameCache));
    if (pyOverride.isNull()) {
        return this->::AppState::displayName();
    }
#if defined(PYPY_VERSION) || (defined(Py_LIMITED_API) && Py_LIMITED_API < 0x030A0000)
    Shiboken::AutoDecRef pyArgs(PyTuple_New(0));
#endif

#if !defined(PYPY_VERSION) && ((defined(Py_LIMITED_API) && Py_LIMITED_API >= 0x030A0000) || !defined(Py_LIMITED_API))
    Shiboken::AutoDecRef pyResult(PyObject_CallNoArgs(pyOverride));
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return ::QString();
    }
    // Check return type
    Shiboken::Conversions::PythonToCppConversion pythonToCpp =
        Shiboken::Conversions::pythonToCppConversion(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], pyResult);
    if (!pythonToCpp) {
        Shiboken::Warnings::warnInvalidReturnValue("AppState", funcName, "QString", Py_TYPE(pyResult)->tp_name);
        return ::QString();
    }
    ::QString cppResult;
    pythonToCpp(pyResult, &cppResult);
    return cppResult;
}

bool AppStateWrapper::event(::QEvent * event)
{
    static const char *funcName = "event";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[5], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::event(event);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[1] = {
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QEvent_IDX]), event)
    };

    const bool invalidateArg1 = Py_REFCNT(pyArgArray[0]) == 1;
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(N)",
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QEvent_IDX]), event)
    ));
    bool invalidateArg1 = Py_REFCNT(PyTuple_GetItem(pyArgs, 0)) == 1;
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 1, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(pyArgArray[0]);
    Py_DECREF(pyArgArray[0]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(PyTuple_GetItem(pyArgs, 0));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return false;
    }
    // Check return type
    Shiboken::Conversions::PythonToCppConversion pythonToCpp =
        Shiboken::Conversions::pythonToCppConversion(Shiboken::Conversions::PrimitiveTypeConverter<bool>(), pyResult);
    if (!pythonToCpp) {
        Shiboken::Warnings::warnInvalidReturnValue("AppState", funcName, "bool", Py_TYPE(pyResult)->tp_name);
        return false;
    }
    bool cppResult;
    pythonToCpp(pyResult, &cppResult);
    return cppResult;
}

bool AppStateWrapper::eventFilter(::QObject * watched, ::QEvent * event)
{
    static const char *funcName = "eventFilter";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[6], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::eventFilter(watched, event);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[2] = {
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), watched),
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QEvent_IDX]), event)
    };

    const bool invalidateArg2 = Py_REFCNT(pyArgArray[1]) == 1;
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(NN)",
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), watched),
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QEvent_IDX]), event)
    ));
    bool invalidateArg2 = Py_REFCNT(PyTuple_GetItem(pyArgs, 1)) == 1;
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 2, nullptr));
    if (invalidateArg2)
        Shiboken::Object::invalidate(pyArgArray[1]);
    Py_DECREF(pyArgArray[0]);
    Py_DECREF(pyArgArray[1]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
    if (invalidateArg2)
        Shiboken::Object::invalidate(PyTuple_GetItem(pyArgs, 1));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return false;
    }
    // Check return type
    Shiboken::Conversions::PythonToCppConversion pythonToCpp =
        Shiboken::Conversions::pythonToCppConversion(Shiboken::Conversions::PrimitiveTypeConverter<bool>(), pyResult);
    if (!pythonToCpp) {
        Shiboken::Warnings::warnInvalidReturnValue("AppState", funcName, "bool", Py_TYPE(pyResult)->tp_name);
        return false;
    }
    bool cppResult;
    pythonToCpp(pyResult, &cppResult);
    return cppResult;
}

void AppStateWrapper::timerEvent(::QTimerEvent * event)
{
    static const char *funcName = "timerEvent";
    static PyObject *nameCache[2] = {};
    Shiboken::GilState gil(false);
    Shiboken::AutoDecRef pyOverride(Sbk_GetPyOverride(this, gil, funcName, &m_PyMethodCache[7], nameCache));
    if (pyOverride.isNull()) {
        return this->::QObject::timerEvent(event);
    }
#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    PyObject *pyArgArray[1] = {
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QTimerEvent_IDX]), event)
    };

    const bool invalidateArg1 = Py_REFCNT(pyArgArray[0]) == 1;
#else
    Shiboken::AutoDecRef pyArgs(Py_BuildValue("(N)",
        Shiboken::Conversions::pointerToPython(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QTimerEvent_IDX]), event)
    ));
    bool invalidateArg1 = Py_REFCNT(PyTuple_GetItem(pyArgs, 0)) == 1;
#endif

#if !defined(PYPY_VERSION) && !defined(Py_LIMITED_API)
    Shiboken::AutoDecRef pyResult(PyObject_Vectorcall(pyOverride, pyArgArray, 1, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(pyArgArray[0]);
    Py_DECREF(pyArgArray[0]);
#else
    Shiboken::AutoDecRef pyResult(PyObject_Call(pyOverride, pyArgs, nullptr));
    if (invalidateArg1)
        Shiboken::Object::invalidate(PyTuple_GetItem(pyArgs, 0));
#endif
    if (pyResult.isNull()) {
        // An error happened in python code!
        Shiboken::Errors::storePythonOverrideErrorOrPrint("AppState", funcName);
        return;
    }
}

const QMetaObject *AppStateWrapper::metaObject() const
{
    if (QObject::d_ptr->metaObject != nullptr)
        return QObject::d_ptr->dynamicMetaObject();
    SbkObject *pySelf = Shiboken::BindingManager::instance().retrieveWrapper(this);
    if (pySelf == nullptr)
        return AppState::metaObject();
    return PySide::SignalManager::retrieveMetaObject(reinterpret_cast<PyObject *>(pySelf));
}

int AppStateWrapper::qt_metacall(QMetaObject::Call call, int id, void **args)
{
    int result = AppState::qt_metacall(call, id, args);
    return result < 0 ? result : PySide::SignalManager::qt_metacall(this, call, id, args);
}

void *AppStateWrapper::qt_metacast(const char *_clname)
{
    if (_clname == nullptr)
        return {};
    SbkObject *pySelf = Shiboken::BindingManager::instance().retrieveWrapper(this);
    if (pySelf != nullptr && PySide::inherits(Py_TYPE(pySelf), _clname))
        return static_cast<void *>(const_cast< AppStateWrapper *>(this));
    return AppState::qt_metacast(_clname);
}

AppStateWrapper::~AppStateWrapper()
{
    SbkObject *wrapper = Shiboken::BindingManager::instance().retrieveWrapper(this);
    Shiboken::Object::destroy(wrapper, this);
}

// Target ---------------------------------------------------------

extern "C" {
static int
Sbk_AppState_Init(PyObject *self, PyObject *args, PyObject *kwds)
{
    SBK_UNUSED(kwds)
    auto *sbkSelf = reinterpret_cast<SbkObject *>(self);
    PySide::Feature::Select(self);
    if (Shiboken::Object::isUserType(self) && !Shiboken::ObjectType::canCallConstructor(self->ob_type, Shiboken::SbkType< ::AppState >()))
        return -1;

    AppStateWrapper *cptr{};
    Shiboken::AutoDecRef errInfo{};
    Shiboken::PythonContextMarker pcm;
    int overloadId = -1;
    Shiboken::Conversions::PythonToCppConversion pythonToCpp[1];
    SBK_UNUSED(pythonToCpp)
    const Py_ssize_t numArgs = PyTuple_Size(args);
    SBK_UNUSED(numArgs)
    PyObject *pyArgs[] = {nullptr};

    // invalid argument lengths

    if (PyArg_ParseTuple(args, "|O:AppState", &(pyArgs[0])) == 0)
        return -1;


    // Overloaded function decisor
    // 0: AppState::AppState(QObject*=)
    if (numArgs == 0) {
        overloadId = 0; // AppState(QObject*)
    } else if (numArgs >= 1
        && (pythonToCpp[0] = Shiboken::Conversions::pythonToCppPointerConversion(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), (pyArgs[0])))) {
        overloadId = 0; // AppState(QObject*)
    }

    // Function signature not found.
    if (overloadId == -1)
        return Shiboken::returnWrongArguments_MinusOne(args, "__init__", errInfo, SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);


    // PyMI support
    bool usesPyMI = Shiboken::callInheritedInit(self, args, kwds, SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);
    if (Shiboken::Errors::occurred() != nullptr)
        return -1;

    // Call function/method
    {
        if (kwds && PyDict_Size(kwds) > 0) {
            PyObject *value{};
            Shiboken::AutoDecRef kwds_dup(PyDict_Copy(kwds));
            static PyObject *const key_parent = Shiboken::String::createStaticString("parent");
            if (PyDict_Contains(kwds, key_parent) != 0) {
                value = PyDict_GetItem(kwds, key_parent);
                if (value != nullptr && pyArgs[0] != nullptr ) {
                    errInfo.reset(key_parent);
                    Py_INCREF(errInfo.object());
                    return Shiboken::returnWrongArguments_MinusOne(args, "__init__", errInfo, SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);
                }
                if (value != nullptr) {
                    pyArgs[0] = value;
                    if (!(pythonToCpp[0] = Shiboken::Conversions::pythonToCppPointerConversion(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]), (pyArgs[0]))))
                        return Shiboken::returnWrongArguments_MinusOne(args, "__init__", errInfo, SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);
                }
                PyDict_DelItem(kwds_dup, key_parent);
            }
            if (PyDict_Size(kwds_dup) > 0) {
                errInfo.reset(kwds_dup.release());
                // fall through to handle extra keyword signals and properties
            }
        }
        if (!Shiboken::Object::isValid(pyArgs[0]))
            return -1;
        ::QObject *cppArg0 = nullptr;
        if (pythonToCpp[0])
            pythonToCpp[0](pyArgs[0], &cppArg0);

        if (Shiboken::Errors::occurred() == nullptr) {
            // AppState(QObject*)
            void *addr = PySide::nextQObjectMemoryAddr();
            if (addr != nullptr) {
                cptr = new (addr) AppStateWrapper(cppArg0);
                PySide::setNextQObjectMemoryAddr(nullptr);
            } else {
                cptr = new AppStateWrapper(cppArg0);
            }

        }
    }

    if (Shiboken::Errors::occurred() != nullptr || !Shiboken::Object::setCppPointer(sbkSelf, Shiboken::SbkType< AppState >(), cptr)) {
        delete cptr;
        return -1;
    }
    if (cptr == nullptr)
        return Shiboken::returnWrongArguments_MinusOne(args, "__init__", errInfo, SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);

    Shiboken::Object::setValidCpp(sbkSelf, true);
    Shiboken::Object::setHasCppWrapper(sbkSelf, true);
    if (Shiboken::BindingManager::instance().hasWrapper(cptr)) {
        Shiboken::BindingManager::instance().releaseWrapper(Shiboken::BindingManager::instance().retrieveWrapper(cptr));
    }
    Shiboken::BindingManager::instance().registerWrapper(sbkSelf, cptr);

    // QObject setup
    PySide::Signal::updateSourceObject(self);
    const auto *metaObject = cptr->metaObject(); // <- init python qt properties
    if (!errInfo.isNull() && PyDict_Check(errInfo.object())) {
        if (!PySide::fillQtProperties(self, metaObject, errInfo, usesPyMI))
            return Shiboken::returnWrongArguments_MinusOne(args, "__init__", errInfo, SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]);
    };


    return 1;
}

static PyObject *Sbk_AppStateFunc_deviceModel(PyObject *self)
{
    if (!Shiboken::Object::isValid(self))
        return {};
    auto *cppSelf = reinterpret_cast< ::AppState *>(Shiboken::Conversions::cppPointer(Shiboken::Module::get(SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]), reinterpret_cast<SbkObject *>(self)));
    SBK_UNUSED(cppSelf)
    PyObject *pyResult{};
    Shiboken::PythonContextMarker pcm;

    // Call function/method
    {

        // deviceModel()const
        QString cppResult = const_cast<const ::AppState *>(cppSelf)->deviceModel();
        pyResult = Shiboken::Conversions::copyToPython(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], &cppResult);
    }

    return Sbk_ReturnFromPython_Result(pyResult);
}

static PyObject *Sbk_AppStateFunc_displayName(PyObject *self)
{
    if (!Shiboken::Object::isValid(self))
        return {};
    auto *cppSelf = reinterpret_cast< ::AppState *>(Shiboken::Conversions::cppPointer(Shiboken::Module::get(SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]), reinterpret_cast<SbkObject *>(self)));
    SBK_UNUSED(cppSelf)
    PyObject *pyResult{};
    Shiboken::PythonContextMarker pcm;

    // Call function/method
    {

        // displayName()const
        QString cppResult = Shiboken::Object::hasCppWrapper(reinterpret_cast<SbkObject *>(self))
            ? const_cast<const ::AppState *>(cppSelf)->::AppState::displayName()
            : const_cast<const ::AppState *>(cppSelf)->displayName();
        pyResult = Shiboken::Conversions::copyToPython(SbkPySide6_QtCoreTypeConverters[SBK_QString_IDX], &cppResult);
    }

    return Sbk_ReturnFromPython_Result(pyResult);
}


static const char *Sbk_AppState_PropertyStrings[] = {
    "deviceModel:",
    "displayName:",
    nullptr // Sentinel
};

static PyMethodDef Sbk_AppState_methods[] = {
    {"deviceModel", reinterpret_cast<PyCFunction>(Sbk_AppStateFunc_deviceModel), METH_NOARGS, nullptr},
    {"displayName", reinterpret_cast<PyCFunction>(Sbk_AppStateFunc_displayName), METH_NOARGS, nullptr},
    {nullptr, nullptr, 0, nullptr} // Sentinel
};

static int Sbk_AppState_setattro(PyObject *self, PyObject *name, PyObject *value)
{
    PySide::Feature::Select(self);
    if (value != nullptr && PyCallable_Check(value) != 0) {
        auto plain_inst = reinterpret_cast< ::AppState *>(Shiboken::Conversions::cppPointer(Shiboken::Module::get(SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]), reinterpret_cast<SbkObject *>(self)));
        auto *inst = dynamic_cast<AppStateWrapper *>(plain_inst);
        if (inst != nullptr)
            inst->resetPyMethodCache();
    }
    Shiboken::AutoDecRef pp(reinterpret_cast<PyObject *>(PySide::Property::getObject(self, name)));
    if (!pp.isNull())
        return PySide::Property::setValue(reinterpret_cast<PySideProperty *>(pp.object()), self, value);
    return PyObject_GenericSetAttr(self, name, value);
}

} // extern "C"

static int Sbk_AppState_traverse(PyObject *self, visitproc visit, void *arg)
{
    auto traverseProc = reinterpret_cast<traverseproc>(PepType_GetSlot(SbkObject_TypeF(), Py_tp_traverse));
    ;
    return traverseProc(self, visit, arg);
}
static int Sbk_AppState_clear(PyObject *self)
{
    auto clearProc = reinterpret_cast<inquiry>(PepType_GetSlot(SbkObject_TypeF(), Py_tp_clear));
    ;
    return clearProc(self);
}
// Class Definition -----------------------------------------------
extern "C" {
static PyTypeObject *_Sbk_AppState_Type = nullptr;
static PyTypeObject *Sbk_AppState_TypeF(void)
{
    return _Sbk_AppState_Type;
}

static PyType_Slot Sbk_AppState_slots[] = {
    {Py_tp_base,        nullptr}, // inserted by introduceWrapperType
    {Py_tp_dealloc,     reinterpret_cast<void *>(&SbkDeallocWrapper)},
    {Py_tp_setattro,    reinterpret_cast<void *>(Sbk_AppState_setattro)},
    {Py_tp_traverse,    reinterpret_cast<void *>(Sbk_AppState_traverse)},
    {Py_tp_clear,       reinterpret_cast<void *>(Sbk_AppState_clear)},
    {Py_tp_methods,     reinterpret_cast<void *>(Sbk_AppState_methods)},
    {Py_tp_init,        reinterpret_cast<void *>(Sbk_AppState_Init)},
    {Py_tp_new,         reinterpret_cast<void *>(SbkObject_tp_new)},
    {0, nullptr}
};
static PyType_Spec Sbk_AppState_spec = {
    "1:AppStateBindings.AppState",
    sizeof(SbkObject),
    0,
    Py_TPFLAGS_DEFAULT|Py_TPFLAGS_BASETYPE|Py_TPFLAGS_HAVE_GC,
    Sbk_AppState_slots
};

} //extern "C"

static void *Sbk_AppState_typeDiscovery(void *cptr, PyTypeObject *instanceType)
{
    SBK_UNUSED(cptr)
    SBK_UNUSED(instanceType)
    if (instanceType == Shiboken::SbkType< ::QObject >())
        return dynamic_cast< ::AppState *>(reinterpret_cast< ::QObject *>(cptr));
    return {};
}


// Type conversion functions.

// Python to C++ pointer conversion - returns the C++ object of the Python wrapper (keeps object identity).
static void AppState_PythonToCpp_AppState_PTR(PyObject *pyIn, void *cppOut)
{
    Shiboken::Conversions::pythonToCppPointer(Sbk_AppState_TypeF(), pyIn, cppOut);
}
static PythonToCppFunc is_AppState_PythonToCpp_AppState_PTR_Convertible(PyObject *pyIn)
{
    if (pyIn == Py_None)
        return Shiboken::Conversions::nonePythonToCppNullPtr;
    if (PyObject_TypeCheck(pyIn, Sbk_AppState_TypeF()))
        return AppState_PythonToCpp_AppState_PTR;
    return {};
}

// C++ to Python pointer conversion - tries to find the Python wrapper for the C++ object (keeps object identity).
static PyObject *AppState_PTR_CppToPython_AppState(const void *cppIn)
{
    return PySide::getWrapperForQObject(reinterpret_cast<::AppState *>(const_cast<void *>(cppIn)), Sbk_AppState_TypeF());

}

// The signatures string for the functions.
// Multiple signatures have their index "n:" in front.
#if PYSIDE6_COMOPT_COMPRESS == 0
static const char *AppState_SignatureStrings[] = {
    "AppStateBindings.AppState(self,parent:PySide6.QtCore.QObject=nullptr,*:KeywordOnly=None,deviceModel:QString=None,displayName:QString=None)",
    "AppStateBindings.AppState.deviceModel(self)->QString",
    "AppStateBindings.AppState.displayName(self)->QString",
    nullptr}; // Sentinel
#else
static constexpr size_t AppState_SignatureByteSize = 142;
static constexpr uint8_t AppState_SignatureBytes[142] = {
    0x78, 0xda, 0x7d, 0x8e, 0x4b, 0x0a, 0x02, 0x31, 0x10, 0x44, 0xf7, 0x9e, 0xc4, 0x91, 0x98, 0xa5,
    0x8b, 0xc0, 0x08, 0xa3, 0x4b, 0x71, 0xc6, 0x90, 0x13, 0xc4, 0x49, 0x2b, 0x91, 0xb6, 0x13, 0x92,
    0x56, 0xc9, 0xed, 0x15, 0x09, 0xf8, 0x01, 0xdd, 0x56, 0xf1, 0x5e, 0x55, 0x17, 0xa3, 0x61, 0xcb,
    0xb0, 0xf2, 0xe4, 0x3c, 0x1d, 0xb3, 0xec, 0x6a, 0x30, 0xcd, 0x80, 0x07, 0x11, 0x6d, 0x02, 0x62,
    0xb5, 0x2b, 0xc6, 0x3b, 0x58, 0x48, 0xcd, 0xeb, 0x90, 0x40, 0xea, 0x61, 0x7f, 0x82, 0x91, 0x5b,
    0xba, 0x20, 0x46, 0x4e, 0x62, 0xa6, 0x36, 0x50, 0x6e, 0x21, 0xb9, 0x81, 0xb0, 0xb4, 0x7d, 0x20,
    0x10, 0x0e, 0xae, 0x7e, 0x84, 0x6d, 0x70, 0x80, 0x4a, 0x1b, 0x4e, 0x0f, 0x77, 0x2d, 0x7c, 0x8e,
    0x68, 0x4b, 0x6f, 0xcf, 0xf0, 0x51, 0x34, 0x93, 0xee, 0xd7, 0x15, 0xf9, 0x26, 0x7b, 0xde, 0x6a,
    0xe6, 0xcb, 0x8a, 0xfe, 0x83, 0x5e, 0x43, 0xdf, 0xd0, 0x1d, 0xb6, 0xfb, 0x5a, 0x50
};
#endif

PyTypeObject *init_AppState(PyObject *module)
{
    if (SbkAppStateBindingsTypeStructs[SBK_AppState_IDX].type != nullptr)
        return SbkAppStateBindingsTypeStructs[SBK_AppState_IDX].type;

    Shiboken::AutoDecRef Sbk_AppState_Type_bases(PyTuple_Pack(1,
        reinterpret_cast<PyObject *>(Shiboken::Module::get(SbkPySide6_QtCoreTypeStructs[SBK_QObject_IDX]))));

    _Sbk_AppState_Type = Shiboken::ObjectType::introduceWrapperType(
        module,
        "AppState",
        "AppState*",
        &Sbk_AppState_spec,
        &Shiboken::callCppDestructor< AppState >,
        Sbk_AppState_Type_bases.object(),
        0);
    auto *pyType = Sbk_AppState_TypeF(); // references _Sbk_AppState_Type
#if PYSIDE6_COMOPT_COMPRESS == 0
    InitSignatureStrings(pyType, AppState_SignatureStrings);
#else
    InitSignatureBytes(pyType, AppState_SignatureBytes, AppState_SignatureByteSize);
#endif
    SbkObjectType_SetPropertyStrings(pyType, Sbk_AppState_PropertyStrings);
    SbkAppStateBindingsTypeStructs[SBK_AppState_IDX].type = pyType;

    // Register Converter
    SbkConverter *converter = Shiboken::Conversions::createConverter(pyType,
        AppState_PythonToCpp_AppState_PTR,
        is_AppState_PythonToCpp_AppState_PTR_Convertible,
        AppState_PTR_CppToPython_AppState);

    Shiboken::Conversions::registerConverterName(converter, "AppState");
    Shiboken::Conversions::registerConverterName(converter, "AppState*");
    Shiboken::Conversions::registerConverterName(converter, "AppState&");
    Shiboken::Conversions::registerConverterName(converter, typeid(::AppState).name());
    Shiboken::Conversions::registerConverterName(converter, typeid(AppStateWrapper).name());

    Shiboken::ObjectType::setTypeDiscoveryFunctionV2(
        Sbk_AppState_TypeF(), &Sbk_AppState_typeDiscovery);

    Shiboken::ObjectType::setSubTypeInitHook(pyType, &PySide::initQObjectSubType);
    PySide::initDynamicMetaObject(pyType, &::AppState::staticMetaObject, sizeof(AppStateWrapper));

    return pyType;
}

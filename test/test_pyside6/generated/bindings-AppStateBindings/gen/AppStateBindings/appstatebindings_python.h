

#ifndef SBK_APPSTATEBINDINGS_PYTHON_H
#define SBK_APPSTATEBINDINGS_PYTHON_H

//workaround to access protected functions
#define protected public

#include <sbkpython.h>
#include <sbkmodule.h>
#include <sbkconverter.h>
// Module Includes
#include <pyside6_qtcore_python.h>

// Bound library includes
#include <appstate.h>
// Conversion Includes - Primitive Types
#include <QAnyStringView>
#include <qbytearrayview.h>
#include <qchar.h>
#include <QtCore/qlatin1stringview.h>
#include <QString>
#include <QStringList>
#include <QStringView>

// Conversion Includes - Container Types
#include <QHash>
#include <QList>
#include <QMap>
#include <QMultiHash>
#include <QMultiMap>
#include <QPair>
#include <QQueue>
#include <QSet>
#include <QStack>
#include <array>
#include <list>
#include <map>
#include <utility>
#include <unordered_map>
#include <vector>


// Type indices
enum [[deprecated]] : int {
    SBK_APPSTATE_IDX                                         = 0,
    SBK_APPSTATEBINDINGS_IDX_COUNT                           = 2,
};

// Type indices
enum : int {
    SBK_AppState_IDX                                         = 0,
    SBK_AppStateBindings_IDX_COUNT                           = 1,
};

// This variable stores all Python types exported by this module.
extern Shiboken::Module::TypeInitStruct *SbkAppStateBindingsTypeStructs;

// This variable stores all Python types exported by this module in a backwards compatible way with identical indexing.
[[deprecated]] extern PyTypeObject **SbkAppStateBindingsTypes;

// This variable stores the Python module object exported by this module.
extern PyObject *SbkAppStateBindingsModuleObject;

// This variable stores all type converters exported by this module.
extern SbkConverter **SbkAppStateBindingsTypeConverters;

// Converter indices
enum [[deprecated]] : int {
    SBK_APPSTATEBINDINGS_QLIST_INT_IDX                       = 0, // QList<int>
    SBK_APPSTATEBINDINGS_QLIST_QOBJECTPTR_IDX                = 2, // QList<QObject*>
    SBK_APPSTATEBINDINGS_QLIST_QBYTEARRAY_IDX                = 4, // QList<QByteArray>
    SBK_APPSTATEBINDINGS_QLIST_QVARIANT_IDX                  = 6, // QList<QVariant>
    SBK_APPSTATEBINDINGS_QLIST_QSTRING_IDX                   = 8, // QList<QString>
    SBK_APPSTATEBINDINGS_QMAP_QSTRING_QVARIANT_IDX           = 10, // QMap<QString,QVariant>
    SBK_APPSTATEBINDINGS_CONVERTERS_IDX_COUNT                = 12,
};

// Converter indices
enum : int {
    SBK_AppStateBindings_QList_int_IDX                       = 0, // QList<int>
    SBK_AppStateBindings_QList_QObjectPTR_IDX                = 1, // QList<QObject*>
    SBK_AppStateBindings_QList_QByteArray_IDX                = 2, // QList<QByteArray>
    SBK_AppStateBindings_QList_QVariant_IDX                  = 3, // QList<QVariant>
    SBK_AppStateBindings_QList_QString_IDX                   = 4, // QList<QString>
    SBK_AppStateBindings_QMap_QString_QVariant_IDX           = 5, // QMap<QString,QVariant>
    SBK_AppStateBindings_CONVERTERS_IDX_COUNT                = 6,
};
// Macros for type check

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
namespace Shiboken
{

// PyType functions, to get the PyObjectType for a type T
template<> inline PyTypeObject *SbkType< ::AppState >() { return Shiboken::Module::get(SbkAppStateBindingsTypeStructs[SBK_AppState_IDX]); }

} // namespace Shiboken

QT_WARNING_POP
#endif // SBK_APPSTATEBINDINGS_PYTHON_H


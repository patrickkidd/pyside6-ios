// Minimal Python C extension bridging Qt QML to Python.
// Provides: qtbridge.init(), qtbridge.loadQml(path), qtbridge.setProperty(name, value)

#pragma push_macro("slots")
#undef slots
#include <Python.h>
#pragma pop_macro("slots")

#import <UIKit/UIKit.h>
#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlEngine>
#include <QtQml/QQmlContext>
#include <QtCore/QDebug>
#include <QtCore/QUrl>
#include <QtCore/QMap>

static QGuiApplication *g_app = nullptr;
static QQuickView *g_view = nullptr;
static QMap<QString, QString> g_pendingProperties;

static PyObject *qtbridge_setProperty(PyObject *self, PyObject *args) {
    const char *name;
    const char *value;
    if (!PyArg_ParseTuple(args, "ss", &name, &value))
        return NULL;

    if (g_view) {
        g_view->rootContext()->setContextProperty(
            QString::fromUtf8(name), QString::fromUtf8(value));
    } else {
        g_pendingProperties[QString::fromUtf8(name)] = QString::fromUtf8(value);
    }
    Py_RETURN_NONE;
}

static PyObject *qtbridge_loadQml(PyObject *self, PyObject *args) {
    const char *path;
    if (!PyArg_ParseTuple(args, "s", &path))
        return NULL;

    if (!g_app) {
        PyErr_SetString(PyExc_RuntimeError, "Qt not initialized");
        return NULL;
    }

    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    QString qmlImportPath = QString::fromNSString(bundlePath) + "/qml";

    g_view = new QQuickView();
    g_view->engine()->addImportPath(qmlImportPath);
    g_view->setResizeMode(QQuickView::SizeRootObjectToView);

    // Apply any properties set before view creation
    for (auto it = g_pendingProperties.constBegin();
         it != g_pendingProperties.constEnd(); ++it) {
        g_view->rootContext()->setContextProperty(it.key(), it.value());
    }
    g_pendingProperties.clear();

    g_view->setSource(QUrl::fromLocalFile(QString::fromUtf8(path)));

    if (g_view->status() != QQuickView::Ready) {
        qCritical() << "QML load failed:" << g_view->errors();
        PyErr_SetString(PyExc_RuntimeError, "QML load failed");
        return NULL;
    }

    g_view->showFullScreen();
    qDebug() << "Python loaded QML:" << path;
    Py_RETURN_NONE;
}

static PyObject *qtbridge_reparentView(PyObject *self, PyObject *args) {
    // Reparent Qt's Metal view into the active UIWindowScene window.
    // Must be called from the main thread after loadQml.
    if (!g_view) {
        PyErr_SetString(PyExc_RuntimeError, "No QML view to reparent");
        return NULL;
    }

    WId nativeId = g_view->winId();
    UIView *qtView = (__bridge UIView *)(void *)nativeId;
    if (!qtView) {
        PyErr_SetString(PyExc_RuntimeError, "No native view");
        return NULL;
    }

    // Find the active window scene
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) {
                    qtView.frame = w.bounds;
                    qtView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                              UIViewAutoresizingFlexibleHeight;
                    [w.rootViewController.view addSubview:qtView];
                    qDebug() << "Reparented Qt view from Python";
                    Py_RETURN_NONE;
                }
            }
        }
    }

    PyErr_SetString(PyExc_RuntimeError, "No active UIWindowScene found");
    return NULL;
}

static PyMethodDef qtbridge_methods[] = {
    {"loadQml", qtbridge_loadQml, METH_VARARGS, NULL},
    {"setProperty", qtbridge_setProperty, METH_VARARGS, NULL},
    {"reparentView", qtbridge_reparentView, METH_NOARGS, NULL},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef qtbridge_module = {
    PyModuleDef_HEAD_INIT,
    "qtbridge",
    NULL,
    -1,
    qtbridge_methods
};

PyMODINIT_FUNC PyInit_qtbridge(void) {
    return PyModule_Create(&qtbridge_module);
}

// Called from ObjC to set globals from the host
void qtbridge_setApp(QGuiApplication *app) {
    g_app = app;
}

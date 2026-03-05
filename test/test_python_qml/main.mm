// M4b test: Python drives QML on iOS via qtbridge C extension.
// Host app owns UIApplicationMain lifecycle, creates QGuiApplication,
// then hands control to a Python script that loads QML.

#pragma push_macro("slots")
#undef slots
#include <Python.h>
#pragma pop_macro("slots")

#import <UIKit/UIKit.h>

#include <QtGui/QGuiApplication>
#include <QtCore/QDebug>
#include <QtCore/QtPlugin>

#include "qtbridge.h"

Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)

// Defined in qtbridge.mm
extern void qtbridge_setApp(QGuiApplication *app);

static QGuiApplication *qtApp = nullptr;

static void initPython() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *stdlibPath = [bundlePath stringByAppendingPathComponent:@"lib/python3.13"];
    NSString *dynloadPath = [stdlibPath stringByAppendingPathComponent:@"lib-dynload"];
    NSString *appScriptsPath = [bundlePath stringByAppendingPathComponent:@"scripts"];

    // Register the qtbridge module before Py_Initialize
    PyImport_AppendInittab("qtbridge", PyInit_qtbridge);

    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);
    config.write_bytecode = 0;
    config.home = Py_DecodeLocale([bundlePath UTF8String], NULL);

    config.module_search_paths_set = 1;
    PyWideStringList_Append(&config.module_search_paths,
        Py_DecodeLocale([stdlibPath UTF8String], NULL));
    PyWideStringList_Append(&config.module_search_paths,
        Py_DecodeLocale([dynloadPath UTF8String], NULL));
    PyWideStringList_Append(&config.module_search_paths,
        Py_DecodeLocale([appScriptsPath UTF8String], NULL));

    PyStatus status = Py_InitializeFromConfig(&config);
    if (PyStatus_Exception(status)) {
        NSLog(@"Python init failed: %s", status.err_msg);
        return;
    }
    NSLog(@"Python %s initialized", Py_GetVersion());
}

static void runPythonApp() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *scriptPath = [bundlePath stringByAppendingPathComponent:@"scripts/app.py"];

    FILE *fp = fopen([scriptPath UTF8String], "r");
    if (!fp) {
        NSLog(@"Failed to open %@", scriptPath);
        return;
    }
    int result = PyRun_SimpleFile(fp, [scriptPath UTF8String]);
    fclose(fp);
    if (result != 0) {
        NSLog(@"Python script failed with code %d", result);
        PyErr_Print();
    }
}

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions {

    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    // Init Python
    initPython();

    // Init Qt
    static int argc = 1;
    static const char *argv[] = {"test_python_qml", nullptr};
    qtApp = new QGuiApplication(argc, const_cast<char **>(argv));
    qtbridge_setApp(qtApp);
    qDebug() << "Qt" << qVersion() << "platform:" << qtApp->platformName();

    // Run the Python app script — it calls qtbridge.loadQml()
    runPythonApp();

    // Reparent Qt view into our scene-aware window (deferred to next runloop)
    dispatch_async(dispatch_get_main_queue(), ^{
        PyGILState_STATE gstate = PyGILState_Ensure();
        PyObject *mod = PyImport_ImportModule("qtbridge");
        if (mod) {
            PyObject *result = PyObject_CallMethod(mod, "reparentView", NULL);
            if (!result) PyErr_Print();
            Py_XDECREF(result);
            Py_DECREF(mod);
        } else {
            PyErr_Print();
        }
        PyGILState_Release(gstate);
    });
}
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
    options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *config =
        [[UISceneConfiguration alloc] initWithName:@"Default"
                                       sessionRole:connectingSceneSession.role];
    config.delegateClass = [SceneDelegate class];
    return config;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([AppDelegate class]));
    }
}

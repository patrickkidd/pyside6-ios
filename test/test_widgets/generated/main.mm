// PySide6 iOS QtWidgets demo - custom main.mm
// Exercises: PySide6 QtWidgets, custom C++ sources, MOC, shiboken6 bindings

#pragma push_macro("slots")
#undef slots
#include <Python.h>
#pragma pop_macro("slots")

#import <UIKit/UIKit.h>

#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtGui/QWindow>
#include <QtCore/QDebug>
#include <QtCore/QtPlugin>

#include "appstate.h"
#include "deviceinfo.h"

Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)

// PySide6 built-in modules
extern "C" PyObject *PyInit_QtCore();
extern "C" PyObject *PyInit_QtGui();
extern "C" PyObject *PyInit_QtWidgets();
extern "C" PyObject *PyInit_Shiboken();

// Custom shiboken6 binding module
extern "C" PyObject *PyInit_AppStateBindings();

static QApplication *qtApp = nullptr;

static void initPython() {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *stdlibPath = [bundlePath stringByAppendingPathComponent:@"lib/python3.13"];
    NSString *dynloadPath = [stdlibPath stringByAppendingPathComponent:@"lib-dynload"];
    NSString *appScriptsPath = [bundlePath stringByAppendingPathComponent:@"scripts"];
    NSString *appPackagesPath = [bundlePath stringByAppendingPathComponent:@"packages"];

    PyImport_AppendInittab("PySide6.QtCore", PyInit_QtCore);
    PyImport_AppendInittab("PySide6.QtGui", PyInit_QtGui);
    PyImport_AppendInittab("PySide6.QtWidgets", PyInit_QtWidgets);
    PyImport_AppendInittab("shiboken6.Shiboken", PyInit_Shiboken);
    PyImport_AppendInittab("AppStateBindings", PyInit_AppStateBindings);

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
    PyWideStringList_Append(&config.module_search_paths,
        Py_DecodeLocale([appPackagesPath UTF8String], NULL));

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
    NSLog(@"Running Python script...");
    int result = PyRun_SimpleFile(fp, [scriptPath UTF8String]);
    fclose(fp);
    if (result != 0) {
        NSLog(@"Python script failed with code %d", result);
        if (PyErr_Occurred()) PyErr_Print();
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

    initPython();

    static int argc = 1;
    static const char *argv[] = {"TestWidgets", nullptr};
    qtApp = new QApplication(argc, const_cast<char **>(argv));
    qDebug() << "Qt" << qVersion() << "platform:" << qtApp->platformName();

    // Exercises native C++ source compilation + MOC (Q_OBJECT)
    AppState *appState = new AppState(qtApp);
    qDebug() << "Device model (native C++):" << appState->deviceModel();

    runPythonApp();

    dispatch_async(dispatch_get_main_queue(), ^{
        QWindowList windows = QGuiApplication::topLevelWindows();
        if (!windows.isEmpty()) {
            QWindow *qtWindow = windows.first();
            WId nativeId = qtWindow->winId();
            UIView *qtView = (__bridge UIView *)(void *)nativeId;
            if (qtView) {
                CGRect bounds = self.window.bounds;
                qtView.frame = bounds;
                qtView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight;
                [self.window.rootViewController.view addSubview:qtView];
                // Resize top-level QWidgets to match iOS window bounds
                QWidgetList topWidgets = QApplication::topLevelWidgets();
                for (QWidget *w : topWidgets) {
                    w->resize((int)bounds.size.width, (int)bounds.size.height);
                }
                qDebug() << "Reparented Qt view into iOS window"
                         << bounds.size.width << "x" << bounds.size.height
                         << "widgets:" << topWidgets.size();
            }
        }
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

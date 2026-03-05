// Use UIScene-based lifecycle (iOS 13+) to ensure Qt's UIWindow
// gets properly associated with the UIWindowScene.

#import <UIKit/UIKit.h>

#include <QtGui/QGuiApplication>
#include <QtQuick/QQuickView>
#include <QtQml/QQmlEngine>
#include <QtCore/QDebug>
#include <QtCore/QUrl>
#include <QtCore/QtPlugin>

Q_IMPORT_PLUGIN(QIOSIntegrationPlugin)

static QGuiApplication *qtApp = nullptr;
static QQuickView *view = nullptr;

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions {

    NSLog(@"SceneDelegate: scene willConnectToSession");
    UIWindowScene *windowScene = (UIWindowScene *)scene;

    // Create a placeholder UIWindow so the app has something visible
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.backgroundColor = [UIColor blueColor];
    self.window.rootViewController = [[UIViewController alloc] init];
    [self.window makeKeyAndVisible];

    // Now init Qt — UIApplicationMain is already running
    static int argc = 1;
    static const char *argv[] = {"test_qml", nullptr};
    qtApp = new QGuiApplication(argc, const_cast<char **>(argv));
    qDebug() << "Qt" << qVersion() << "platform:" << qtApp->platformName();

    NSString *appDir = [[NSBundle mainBundle] bundlePath];
    QString qmlImportPath = QString::fromNSString(appDir) + "/qml";
    QString qmlPath = QString::fromNSString(appDir) + "/main.qml";

    view = new QQuickView();
    view->engine()->addImportPath(qmlImportPath);
    view->setResizeMode(QQuickView::SizeRootObjectToView);
    view->setSource(QUrl::fromLocalFile(qmlPath));

    if (view->status() != QQuickView::Ready) {
        qCritical() << "QML load failed:" << view->errors();
        return;
    }

    view->showFullScreen();
    qDebug() << "QQuickView geometry:" << view->geometry();

    // Qt's UIWindow has no scene association and is invisible on iOS 13+.
    // Extract the native UIView from QQuickView and reparent it into our window.
    dispatch_async(dispatch_get_main_queue(), ^{
        WId nativeId = view->winId();
        UIView *qtView = (__bridge UIView *)(void *)nativeId;
        NSLog(@"Qt native view: %@ superview: %@ window: %@",
              qtView, qtView.superview, qtView.window);

        if (qtView) {
            // Reparent Qt's rendering view into our scene-aware window
            qtView.frame = self.window.bounds;
            qtView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                      UIViewAutoresizingFlexibleHeight;
            [self.window.rootViewController.view addSubview:qtView];
            NSLog(@"Reparented Qt view into scene window");
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

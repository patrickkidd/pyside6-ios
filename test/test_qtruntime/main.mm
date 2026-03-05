// Minimal iOS app that loads QtRuntime.framework and creates a QApplication.
// This validates that the merged dynamic framework works correctly.

#import <UIKit/UIKit.h>
#include <dlfcn.h>

// Forward-declare Qt types — we link against QtRuntime at build time
#include <QtCore/QCoreApplication>
#include <QtCore/QDebug>
#include <QtCore/QSysInfo>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Create a QCoreApplication (not QApplication — no GUI needed for this test)
    static int argc = 1;
    static const char *argv[] = {"test_qtruntime", nullptr};
    QCoreApplication app(argc, const_cast<char **>(argv));

    qDebug() << "QtRuntime.framework loaded successfully";
    qDebug() << "Qt version:" << qVersion();
    qDebug() << "Platform:" << QSysInfo::prettyProductName();
    qDebug() << "Architecture:" << QSysInfo::currentCpuArchitecture();

    // Show a native UIKit window to prove the app runs
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *vc = [[UIViewController alloc] init];
    UILabel *label = [[UILabel alloc] initWithFrame:self.window.bounds];
    label.text = [NSString stringWithFormat:@"QtRuntime OK\nQt %s\n%@",
                  qVersion(),
                  @(QSysInfo::currentCpuArchitecture().toUtf8().constData())];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:24];
    [vc.view addSubview:label];
    vc.view.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];

    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([AppDelegate class]));
    }
}

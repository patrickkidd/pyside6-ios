#include "deviceinfo.h"
#import <UIKit/UIKit.h>
#include <sys/utsname.h>

QString deviceModelName() {
    struct utsname info;
    uname(&info);
    return QString::fromUtf8(info.machine);
}

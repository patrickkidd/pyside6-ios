#include "appstate.h"
#include "deviceinfo.h"

AppState::AppState(QObject *parent) : QObject(parent) {}

AppState::~AppState() = default;

QString AppState::deviceModel() const {
    return deviceModelName();
}

QString AppState::displayName() const {
    return QStringLiteral("TestPySide6");
}

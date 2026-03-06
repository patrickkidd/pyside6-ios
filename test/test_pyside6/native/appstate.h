#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>

// Exercises MOC auto-detection (Q_OBJECT macro)
class AppState : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString deviceModel READ deviceModel CONSTANT)
    Q_PROPERTY(QString displayName READ displayName CONSTANT)

public:
    explicit AppState(QObject *parent = nullptr);
    ~AppState() override;
    QString deviceModel() const;
    virtual QString displayName() const;
};

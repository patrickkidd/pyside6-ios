#ifndef SBK_APPSTATEWRAPPER_H
#define SBK_APPSTATEWRAPPER_H

// Workaround to access protected functions
#ifndef protected
#  define protected public
#endif

#include <appstate.h>

namespace PySide { class DynamicQMetaObject; }

class AppStateWrapper : public AppState
{
public:
    AppStateWrapper(const AppStateWrapper &) = delete;
    AppStateWrapper& operator=(const AppStateWrapper &) = delete;
    AppStateWrapper(AppStateWrapper &&) = delete;
    AppStateWrapper& operator=(AppStateWrapper &&) = delete;

    AppStateWrapper(::QObject * parent = nullptr);
    void childEvent(::QChildEvent * event) override;
    void connectNotify(const ::QMetaMethod & signal) override;
    void customEvent(::QEvent * event) override;
    void disconnectNotify(const ::QMetaMethod & signal) override;
    ::QString displayName() const override;
    bool event(::QEvent * event) override;
    bool eventFilter(::QObject * watched, ::QEvent * event) override;
    void timerEvent(::QTimerEvent * event) override;
    ~AppStateWrapper() override;

    const ::QMetaObject * metaObject() const override;
    int qt_metacall(QMetaObject::Call call, int id, void **args) override;
    void *qt_metacast(const char *_clname) override;
    static void pysideInitQtMetaTypes();
    void resetPyMethodCache();
private:
    mutable bool m_PyMethodCache[8] = {false, false, false, false, false, false, false, false};
};

#endif // SBK_APPSTATEWRAPPER_H

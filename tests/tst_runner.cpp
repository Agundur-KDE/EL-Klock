#include <QtQuickTest>
#include <QQmlEngine>
#include <QQmlContext>
#include <KLocalizedQmlContext>

class Setup : public QObject {
    Q_OBJECT
public Q_SLOTS:
    void qmlEngineAvailable(QQmlEngine *engine) {
        auto *context = new KLocalizedQmlContext(engine);
        context->setTranslationDomain(QStringLiteral("plasma_applet_de.agundur.elklock"));
        engine->rootContext()->setContextObject(context);
    }
};

QUICK_TEST_MAIN_WITH_SETUP(plasmoid, Setup)
#include "tst_runner.moc"

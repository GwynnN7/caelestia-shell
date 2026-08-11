#pragma once

#include "configobject.hpp"

#include <qmap.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class SessionIcons : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, shutdown, u"power_settings_new"_s)
    CONFIG_PROPERTY(QString, logout, u"logout"_s)
    CONFIG_PROPERTY(QString, suspend, u"bedtime"_s)
    CONFIG_PROPERTY(QString, reboot, u"cached"_s)
    CONFIG_PROPERTY(QString, steam, u"stadia_controller"_s)
    CONFIG_PROPERTY(QString, windows, u"window"_s)

public:
    explicit SessionIcons(QObject* parent = nullptr);

    void loadFromJson(const QJsonValue& json) override;
    [[nodiscard]] QJsonValue toJson() const override;
    void clearLoadedKeys() override;
    [[nodiscard]] QStringList unknownKeys() const override;
    void resyncFromGlobal() override;

    [[nodiscard]] const QMap<QString, QString>& customIcons() const { return m_customIcons; }
    [[nodiscard]] const QStringList& customIconKeys() const { return m_customIconKeys; }

protected:
    void syncValuesFromGlobal() override;
    void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) override;

private:
    QMap<QString, QString> m_customIcons;
    QStringList m_customIconKeys;
};

class SessionCommands : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QStringList, shutdown, { u"poweroff"_s })
    CONFIG_PROPERTY(QStringList, logout, { u"logout"_s })
    CONFIG_PROPERTY(QStringList, suspend, { u"suspend"_s })
    CONFIG_PROPERTY(QStringList, reboot, { u"reboot"_s })
    CONFIG_PROPERTY(QStringList, steam, { u"bios"_s })
    CONFIG_PROPERTY(QStringList, windows, { u"bios"_s })
    CONFIG_PROPERTY(QStringList, lamp, { u"caelestia"_s, u"shell"_s, u"lock"_s, u"lock"_s })
    CONFIG_PROPERTY(QStringList, generic, { u"caelestia"_s, u"shell"_s, u"lock"_s, u"lock"_s })
    CONFIG_PROPERTY(QStringList, automode, { u"caelestia"_s, u"shell"_s, u"lock"_s, u"lock"_s })

public:
    explicit SessionCommands(QObject* parent = nullptr);

    void loadFromJson(const QJsonValue& json) override;
    [[nodiscard]] QJsonValue toJson() const override;
    void clearLoadedKeys() override;
    [[nodiscard]] QStringList unknownKeys() const override;
    void resyncFromGlobal() override;

    [[nodiscard]] const QMap<QString, QStringList>& customCommands() const { return m_customCommands; }
    [[nodiscard]] const QStringList& customCommandKeys() const { return m_customCommandKeys; }

protected:
    void syncValuesFromGlobal() override;
    void onGlobalPropertiesChanged(const QMap<QString, QVariant>& changed) override;

private:
    QMap<QString, QStringList> m_customCommands;
    QStringList m_customCommandKeys;
};

class SessionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, dragThreshold, 30)
    CONFIG_PROPERTY(bool, vimKeybinds, false)
    CONFIG_SUBOBJECT(SessionIcons, icons)
    CONFIG_SUBOBJECT(SessionCommands, commands)

    Q_PROPERTY(QVariantList buttons READ buttons NOTIFY buttonsChanged)
    Q_PROPERTY(QVariantList customButtons READ customButtons NOTIFY customButtonsChanged)

public:
    explicit SessionConfig(QObject* parent = nullptr);

    void loadFromJson(const QJsonValue& json) override;
    [[nodiscard]] QJsonValue toJson() const override;
    void clearLoadedKeys() override;
    [[nodiscard]] QList<ConfigNode*> childNodes() const override;
    void resyncFromGlobal() override;

    [[nodiscard]] QVariantList buttons() const;
    [[nodiscard]] QVariantList customButtons() const;

signals:
    void buttonsChanged();
    void customButtonsChanged();

protected:
    void syncValuesFromGlobal() override;
};

} // namespace caelestia::config

#pragma once

#include "configobject.hpp"

#include <qstring.h>
#include <qstringlist.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class SessionIcons : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, shutdown, u"power_settings_new"_s)
    CONFIG_PROPERTY(QString, logout, u"logout"_s)
    CONFIG_PROPERTY(QString, suspend, u"bedtime"_s)
    CONFIG_PROPERTY(QString, reboot, u"cached"_s)
    CONFIG_PROPERTY(QString, windows, u"window"_s)
    CONFIG_PROPERTY(QString, bios, u"memory"_s)
    

public:
    explicit SessionIcons(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionCommands : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QStringList, shutdown, { u"systemctl"_s, u"poweroff"_s })
    CONFIG_PROPERTY(QStringList, logout, { u"loginctl"_s, u"terminate-user"_s, u""_s })
    CONFIG_PROPERTY(QStringList, suspend, { u"systemctl"_s, u"suspend"_s })
    CONFIG_PROPERTY(QStringList, reboot, { u"systemctl"_s, u"reboot"_s })
    CONFIG_PROPERTY(QStringList, windows, { u"systemctl"_s, u"reboot"_s })
    CONFIG_PROPERTY(QStringList, lamp, { u"cortana"_s, u"api"_s, u"-act"_s, u"toggle"_s, u"devices/lamp"_s })
    CONFIG_PROPERTY(QStringList, generic, { u"cortana"_s, u"api"_s, u"-act"_s, u"toggle"_s, u"devices/generic"_s })
    CONFIG_PROPERTY(QStringList, automode, { u"cortana"_s, u"api"_s, u"-val"_s, u"0"_s, u"devices/automaticmode"_s })
    CONFIG_PROPERTY(QStringList, bios, { u"systemctl"_s, u"reboot"_s, u"--firmware-setup"_s })

public:
    explicit SessionCommands(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class SessionConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, dragThreshold, 30)
    CONFIG_PROPERTY(bool, vimKeybinds, false)
    CONFIG_SUBOBJECT(SessionIcons, icons)
    CONFIG_SUBOBJECT(SessionCommands, commands)

public:
    explicit SessionConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_icons(new SessionIcons(this))
        , m_commands(new SessionCommands(this)) {}
};

} // namespace caelestia::config

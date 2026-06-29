#pragma once

#include "configobject.hpp"
#include <qstring.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class AiConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(QString, systemPrompt, u"You are a helpful AI assistant called Cortana, integrated into the user's OS. You can use tools to assist the user (gwynn7)."_s)
    CONFIG_PROPERTY(QString, activeModel, u"qwen3.5:9b"_s)
    CONFIG_PROPERTY(int, contextWindow, 8192)

    CONFIG_PROPERTY(bool, agentDateTime, true)
    CONFIG_PROPERTY(bool, agentLocation, false)
    CONFIG_PROPERTY(bool, agentWebSearch, true)
    CONFIG_PROPERTY(bool, agentReadWebpage, true)
    CONFIG_PROPERTY(bool, agentTakeScreenshot, true)
    CONFIG_PROPERTY(bool, agentOpenApp, true)
    CONFIG_PROPERTY(bool, agentSetTimer, true)
    CONFIG_PROPERTY(bool, agentGetWeather, true)
    CONFIG_PROPERTY(bool, agentCaelestiaCommand, true)
    CONFIG_PROPERTY(bool, agentCortanaApi, true)
    CONFIG_PROPERTY(bool, agentRunCommand, false)
    CONFIG_PROPERTY(bool, agentFileOps, false)

public:
    explicit AiConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config

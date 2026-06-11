pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Sidebar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enabled")
            checked: Config.sidebar.enabled
            onToggled: GlobalConfig.sidebar.enabled = checked
        }

        StepperRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the sidebar opens")
            value: Config.sidebar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.sidebar.dragThreshold = v
        }

        // AI Assistant
        SectionHeader {
            text: qsTr("AI Assistant")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Celestial AI Mode (Orion)")
            subtext: qsTr("Enable advanced autonomous features using qwen2.5vl")
            checked: GlobalConfig.ai.enableCelestialMode
            onToggled: GlobalConfig.ai.enableCelestialMode = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Save chat history")
            subtext: qsTr("Persist conversations across shell restarts")
            checked: GlobalConfig.ai.saveChatHistory
            onToggled: GlobalConfig.ai.saveChatHistory = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Enable Gemini")
            subtext: qsTr("Show Gemini in the provider selection tab")
            checked: GlobalConfig.ai.enableGemini
            onToggled: GlobalConfig.ai.enableGemini = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Enable ChatGPT")
            subtext: qsTr("Show ChatGPT in the provider selection tab")
            checked: GlobalConfig.ai.enableChatgpt
            onToggled: GlobalConfig.ai.enableChatgpt = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Enable Ollama")
            subtext: qsTr("Show Ollama in the provider selection tab")
            checked: GlobalConfig.ai.enableOllama
            onToggled: GlobalConfig.ai.enableOllama = checked
        }

        SelectRow {
            id: defaultProviderRow
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            label: qsTr("Default Provider")
            subtext: qsTr("AI Provider loaded on startup")
            fallbackIcon: "smart_toy"
            fallbackText: qsTr("Select Provider")
            enabled: !GlobalConfig.ai.enableCelestialMode
            opacity: enabled ? 1 : 0.5
            
            active: menuItems.find(m => m.providerId === GlobalConfig.ai.defaultProvider) ?? menuItems[0] ?? null
            onSelected: item => {
                GlobalConfig.ai.defaultProvider = item.providerId;
            }
            menuItems: providerVariants.instances

            Variants {
                id: providerVariants
                model: [
                    { id: "gemini", label: "Gemini" },
                    { id: "chatgpt", label: "ChatGPT" },
                    { id: "ollama", label: "Ollama" }
                ]
                delegate: MenuItem {
                    required property var modelData
                    readonly property string providerId: modelData.id
                    text: modelData.label
                }
            }
        }

        SelectRow {
            id: defaultModelRow
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            last: true
            label: qsTr("Default Model")
            subtext: qsTr("Model loaded on startup for default provider")
            fallbackIcon: "smart_toy"
            fallbackText: qsTr("Select Model")
            menuOnTop: true
            enabled: !GlobalConfig.ai.enableCelestialMode
            opacity: enabled ? 1 : 0.5
            
            active: menuItems.find(m => m.modelData === (
                GlobalConfig.ai.defaultProvider === "gemini" ? GlobalConfig.ai.defaultGeminiModel :
                GlobalConfig.ai.defaultProvider === "chatgpt" ? GlobalConfig.ai.defaultChatgptModel :
                GlobalConfig.ai.defaultOllamaModel
            )) ?? menuItems[0] ?? null

            onSelected: item => {
                if (GlobalConfig.ai.defaultProvider === "gemini") {
                    GlobalConfig.ai.defaultGeminiModel = item.modelData;
                } else if (GlobalConfig.ai.defaultProvider === "chatgpt") {
                    GlobalConfig.ai.defaultChatgptModel = item.modelData;
                } else if (GlobalConfig.ai.defaultProvider === "ollama") {
                    GlobalConfig.ai.defaultOllamaModel = item.modelData;
                }
            }
            menuItems: modelVariants.instances

            Variants {
                id: modelVariants
                model: {
                    if (GlobalConfig.ai.defaultProvider === "gemini") {
                        return ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro"];
                    } else if (GlobalConfig.ai.defaultProvider === "chatgpt") {
                        return ["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"];
                    } else if (GlobalConfig.ai.defaultProvider === "ollama") {
                        return ["llama3", "mistral", "phi3", "gemma"];
                    }
                    return [];
                }
                delegate: MenuItem {
                    required property string modelData
                    text: modelData
                }
            }
        }
    }
}

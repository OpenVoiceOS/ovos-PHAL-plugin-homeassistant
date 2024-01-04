import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "../code/helper.js" as HelperJS

Control {
    id: mediaplayerTemplateDashboardCard
    property var device: modelData
    Layout.fillWidth: true
    Layout.fillHeight: true
    property bool isOnline: device.state !== "off" && device.state !== "unknown" && device.state !== "unavailable" ? 1 : 0


    background: Rectangle {
        radius: 10
        color: isOnline ? Kirigami.Theme.highlightColor : (HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.darker(Kirigami.Theme.backgroundColor, 1.5) : Qt.lighter(Kirigami.Theme.backgroundColor, 1.5))

        Image {
            id: mediaArt
            anchors.fill: parent
            source: device.attributes.entity_picture ? device.attributes.entity_picture : ""
            visible: device.attributes.entity_picture && device.state == "playing" || device.state == "paused" ? 1 : 0
            enabled: device.attributes.entity_picture && device.state == "playing" || device.state == "paused" ? 1 : 0
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
            visible: device.state == "playing" || device.state == "paused" ? 1 : 0
            enabled: device.state == "playing" || device.state == "paused" ? 1 : 0
        }
    }

    contentItem: Item {
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Mycroft.Units.gridUnit / 2

            Rectangle {
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Mycroft.Units.gridUnit * 2
                Layout.maximumHeight: Mycroft.Units.gridUnit * 5
                color: Kirigami.Theme.backgroundColor
                radius: 8

                Label {
                    id: appName
                    text: isOnline ? device.attributes.app_name : qsTr("Status: Device Offline")
                    anchors.fill: parent
                    anchors.margins: Mycroft.Units.gridUnit / 2
                    elide: Text.ElideRight
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    font.pixelSize: Mycroft.Units.gridUnit
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                    visible: device.state == "playing" || device.state == "paused" ? 0 : 1
                    enabled: device.state == "playing" || device.state == "paused" ? 0 : 1
                }

                Label {
                    id: mediaTitle
                    text: device.attributes.media_title ? device.attributes.media_title : qsTr("Title: Not Available")
                    anchors.fill: parent
                    anchors.margins: Mycroft.Units.gridUnit / 2
                    elide: Text.ElideRight
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 10
                    font.pixelSize: Mycroft.Units.gridUnit
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                    visible: device.state == "playing" || device.state == "paused" ? 1 : 0
                    enabled: device.state == "playing" || device.state == "paused" ? 1 : 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Mycroft.Units.gridUnit * 2


                Button {
                    id: powerButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: 8
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            width: parent.width > parent.height ? parent.height / 2 : parent.width / 3
                            height: width
                            anchors.centerIn: parent
                            source: "system-shutdown-symbolic"

                            ColorOverlay {
                                id: powerButtonOverlayColor
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    onClicked: {
                        console.log(device.state)
                        if(device.state == "off") {
                            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.device.turn_on", { "device_id": device.id }, {"session": {"session_id": "default"}})
                        }
                        else {
                            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.device.turn_off", { "device_id": device.id }, {"session": {"session_id": "default"}})
                        }
                    }

                    onPressed: {
                        powerButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                    }
                    onReleased: {
                        powerButtonOverlayColor.color = Kirigami.Theme.textColor
                    }
                }

                Button {
                    id: previousButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: device.state == "playing" || device.state == "paused"
                    enabled: device.state == "playing" || device.state == "paused"

                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: 8
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            width: parent.width > parent.height ? parent.height / 2 : parent.width / 3
                            height: width
                            anchors.centerIn: parent
                            source: "media-skip-backward-symbolic"

                            ColorOverlay {
                                id: previousButtonOverlayColor
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    onClicked: {
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                            "device_id": device.id,
                            "function_name": "media_previous_track",
                            "function_args": {}
                        }, {"session": {"session_id": "default"}})
                    }
                    onPressed: {
                        previousButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                    }
                    onReleased: {
                        previousButtonOverlayColor.color = Kirigami.Theme.textColor
                    }
                }

                Button {
                    id: playButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: device.state == "playing" || device.state == "paused"
                    enabled: device.state == "playing" || device.state == "paused"

                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: 8
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            width: parent.width > parent.height ? parent.height / 2 : parent.width / 3
                            height: width
                            anchors.centerIn: parent
                            source: device.state == "playing" ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"

                            ColorOverlay {
                                id: playButtonOverlayColor
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    onClicked: {
                        if(device.state == "paused") {
                            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                                "device_id": device.id,
                                "function_name": "play_media",
                                "function_args": {}
                            }, {"session": {"session_id": "default"}})
                        } else if(device.state == "playing") {
                            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                                "device_id": device.id,
                                "function_name": "media_pause",
                                "function_args": {}
                            }, {"session": {"session_id": "default"}})
                        }
                    }
                    onPressed: {
                        playButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                    }
                    onReleased: {
                        playButtonOverlayColor.color = Kirigami.Theme.textColor
                    }
                }

                Button {
                    id: nextButton
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: device.state == "playing" || device.state == "paused"
                    enabled: device.state == "playing" || device.state == "paused"

                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: 8
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            width: parent.width > parent.height ? parent.height / 2 : parent.width / 3
                            height: width
                            anchors.centerIn: parent
                            source: "media-skip-forward-symbolic"

                            ColorOverlay {
                                id: nextButtonOverlayColor
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    onClicked: {
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                            "device_id": device.id,
                            "function": "media_next_track"
                        }, {"session": {"session_id": "default"}})
                    }
                    onPressed: {
                        nextButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                    }
                    onReleased: {
                        nextButtonOverlayColor.color = Kirigami.Theme.textColor
                    }
                }
            }

            Item {
                id: volumeSliderRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Mycroft.Units.gridUnit * 2
                Layout.maximumHeight: Mycroft.Units.gridUnit * 5

                Button {
                    id: selectMediaButton
                    anchors.left: parent.left
                    width: parent.width - Mycroft.Units.gridUnit * 7
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    background: Rectangle {
                        id: selectMediaButtonBackground
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: Kirigami.Units.gridUnit
                    }

                    SequentialAnimation {
                        id: selectMediaButtonAnimation

                        PropertyAnimation {
                            target: selectMediaButtonBackground
                            property: "color"
                            from: Kirigami.Theme.backgroundColor
                            to: Kirigami.Theme.highlightColor
                            duration: 100
                        }

                        PropertyAnimation {
                            target: selectMediaButtonBackground
                            property: "color"
                            from: Kirigami.Theme.highlightColor
                            to: Kirigami.Theme.backgroundColor
                            duration: 100
                        }
                    }

                    contentItem: Item {
                        RowLayout {
                            id: selectMediaButtonLayout
                            anchors.fill: parent
                            anchors.margins: Mycroft.Units.gridUnit / 2
                            spacing: Mycroft.Units.gridUnit / 3

                            Kirigami.Icon {
                                source: "media-optical-symbolic"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.large
                                Layout.fillHeight: true

                                ColorOverlay {
                                    id: selectMediaButtonOverlayColor
                                    anchors.fill: parent
                                    source: parent
                                    color: Kirigami.Theme.textColor
                                }
                            }

                            Label {
                                text: qsTr("Select Media")
                                color: Kirigami.Theme.textColor
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 10
                                font.pixelSize: Mycroft.Units.gridUnit
                                elide: Text.ElideRight
                            }
                        }
                    }

                    onClicked: {
                        deviceControlsLoader.openSheet(device)
                    }

                    onPressed: {
                        selectMediaButtonAnimation.running = true
                    }
                }

                Button {
                    id: lowerVolumeButton
                    anchors.left: selectMediaButton.right
                    anchors.leftMargin: Mycroft.Units.gridUnit * 0.5
                    width: Mycroft.Units.gridUnit * 3
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    enabled: device.state == "playing" || device.state == "paused" ? 1 : 0

                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: 8
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: Mycroft.Units.gridUnit / 2
                            source: "audio-volume-low"

                            ColorOverlay {
                                id: lowerVolumeButtonOverlayColor
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    onClicked: {
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                            "device_id": device.id,
                            "function_name": "volume_down",
                            "function_args": {}
                        }, {"session": {"session_id": "default"}})
                    }
                    onPressed: {
                        lowerVolumeButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                    }
                    onReleased: {
                        lowerVolumeButtonOverlayColor.color = Kirigami.Theme.textColor
                    }
                }

                Button {
                    id: higherVolumeButton
                    anchors.left: lowerVolumeButton.right
                    anchors.leftMargin: Mycroft.Units.gridUnit * 0.5
                    width: Mycroft.Units.gridUnit * 3
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    enabled: device.state == "playing" || device.state == "paused" ? 1 : 0

                    background: Rectangle {
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor
                        radius: 8
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            anchors.fill: parent
                            anchors.margins: Mycroft.Units.gridUnit / 2
                            source: "audio-volume-high"

                            ColorOverlay {
                                id: higherVolumeButtonOverlayColor
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }
                    }

                    onClicked: {
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                            "device_id": device.id,
                            "function_name": "volume_up",
                            "function_args": {}
                        }, {"session": {"session_id": "default"}})
                    }
                    onPressed: {
                        higherVolumeButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                    }
                    onReleased: {
                        higherVolumeButtonOverlayColor.color = Kirigami.Theme.textColor
                    }
                }
            }
        }
    }
}

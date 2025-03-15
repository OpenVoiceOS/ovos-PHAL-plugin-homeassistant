import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "../code/helper.js" as HelperJS

Rectangle {
    id: brightnessSliderItem
    property int deviceBrightness: deviceControlsLoader.device.attributes.brightness / 255 * Math.max(deviceControlsLoader.device.attributes.rgb_color[0], deviceControlsLoader.device.attributes.rgb_color[1], deviceControlsLoader.device.attributes.rgb_color[2]) / 255 * 100
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.5) : Qt.darker(Kirigami.Theme.backgroundColor, 1.5)
    border.color: Kirigami.Theme.textColor
    border.width: 1
    radius: 10

    Item {
        anchors.fill: parent
        anchors.margins: Mycroft.Units.gridUnit * 0.5

        Label {
            id: brightnessSliderItemHeader
            text: qsTr("Brightness Control")
            font.bold: true
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Mycroft.Units.gridUnit * 2
            color: Kirigami.Theme.textColor   
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter      
        }

        Kirigami.Separator {
            id: brightnessSliderItemSeparator
            anchors.top: brightnessSliderItemHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
        }

        Item {
            anchors.top: brightnessSliderItemSeparator.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Mycroft.Units.gridUnit * 3

                Label {
                    id: brightnessSliderItemControlSliderLabelLeft
                    text: qsTr("0")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }

                Slider {
                    id: brightnessSliderItemControlSlider
                    from: 0
                    to: 100
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    value: Math.round(brightnessSliderItem.deviceBrightness)
                    stepSize: 1

                    handle: Rectangle {
                        x: brightnessSliderItemControlSlider.leftPadding + brightnessSliderItemControlSlider.visualPosition * (brightnessSliderItemControlSlider.availableWidth - width)
                        y: brightnessSliderItemControlSlider.topPadding + brightnessSliderItemControlSlider.availableHeight / 2 - height / 2
                        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.9)
                        border.color: Kirigami.Theme.highlightColor
                        border.width: 1
                        width: Mycroft.Units.gridUnit * 4
                        height: Mycroft.Units.gridUnit * 2
                        radius: 10

                        Label {
                            anchors.centerIn: parent
                            text: brightnessSliderItemControlSlider.value
                            color: Kirigami.Theme.textColor
                            font.bold: true
                        }
                    }

                    onValueChanged: {
                        brightnessSliderItem.deviceBrightness = value
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                            "device_id": deviceControlsLoader.device.id,
                            "function_name": "turn_on",
                            "function_args": {"brightness": Math.round(value / 100 * 255)}
                        }, {"session": {"session_id": "default"}})
                    }
                }

                Label {
                    id: brightnessSliderItemControlSliderLabelRight
                    text: qsTr("100")
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }
            }
        }
    }
}
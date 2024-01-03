import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "../code/helper.js" as HelperJS

Rectangle {
    id: colorPickerItem
    property color deviceColorValue: HelperJS.convertRGBtoHEX(deviceControlsLoader.device.attributes.rgb_color[0], deviceControlsLoader.device.attributes.rgb_color[1], deviceControlsLoader.device.attributes.rgb_color[2])
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.5) : Qt.darker(Kirigami.Theme.backgroundColor, 1.5)
    border.color: Kirigami.Theme.textColor
    border.width: 1
    radius: 10

    Item {
        anchors.fill: parent
        anchors.margins: Mycroft.Units.gridUnit * 0.5

        RowLayout {
            id: colorPickerItemHeader
            anchors.top: parent.top
            width: parent.width
            height: Mycroft.Units.gridUnit * 2

            Label {
                text: qsTr("Color Control")
                font.bold: true
                Layout.alignment: Qt.AlignLeft
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Kirigami.Theme.textColor   
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter      
            }

            Rectangle {
                id: currentColorRectangle
                Layout.preferredWidth: Mycroft.Units.gridUnit * 1.5
                Layout.preferredHeight: Mycroft.Units.gridUnit * 1.5
                Layout.alignment: Qt.AlignRight
                radius: 100
                color: deviceColorValue
            }
        }
        
        Kirigami.Separator {
            id: colorPickerItemSeparator
            anchors.top: colorPickerItemHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
        }

        ColumnLayout {
            anchors.top: colorPickerItemSeparator.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                Item {
                    width: Math.max((deviceControlsLoader.horizontalMode ? parent.height * 0.8 : parent.width * 0.4), Mycroft.Units.gridUnit * 8)
                    height: Math.max((deviceControlsLoader.horizontalMode ? parent.height * 0.8 : parent.width * 0.4), Mycroft.Units.gridUnit * 8)
                    anchors.centerIn: parent

                    ColorPickerControl {
                        id: colorPickerControl
                    }
                }
            }

            Button {
                id: setDeviceColorButton
                Layout.fillWidth: true
                Layout.preferredHeight: Mycroft.Units.gridUnit * 2

                background: Rectangle {
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.backgroundColor
                    radius: 10
                }

                contentItem: Label {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("Set Color")
                    color: Kirigami.Theme.textColor
                }

                onClicked: {
                    var rgbColor = HelperJS.convertHEXtoRGB(colorPickerControl.color)
                    Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
                        "device_id": deviceControlsLoader.device.id,
                        "function_name": "turn_on",
                        "function_args": {"brightness": deviceControlsLoader.device.attributes.brightness, "rgb_color": rgbColor}
                    }, {"session": {"session_id": "default"}})
                }
                onPressed: {
                    setDeviceColorButton.opacity = 0.5
                }
                onReleased: {
                    setDeviceColorButton.opacity = 1
                }
            }
        }
    }
}
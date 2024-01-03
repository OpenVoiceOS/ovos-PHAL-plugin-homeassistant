import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "../code/helper.js" as HelperJS

Button {
    id: deviceStateButtonControl
    property var isDeviceActive: deviceControlsLoader.device.state == "on" ? 1 : 0
    Layout.preferredWidth: Mycroft.Units.gridUnit * 2.5
    Layout.preferredHeight: Mycroft.Units.gridUnit * 2.5
    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

    background: Rectangle {
        id: deviceStateButtonControlBackground
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        color: Kirigami.Theme.backgroundColor
        radius: 4
        border.color: deviceStateButtonControl.isDeviceActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
        border.width: 1
    }

    SequentialAnimation {
        id: deviceStateButtonControlAnimation

        PropertyAnimation {
            target: deviceStateButtonControlBackground
            property: "color"
            to: Qt.darker(Kirigami.Theme.highlightColor, 1.5)
            duration: 200
        }

        PropertyAnimation {
            target: deviceStateButtonControlBackground
            property: "color"
            to: Kirigami.Theme.backgroundColor
            duration: 200
        }
    }

    contentItem: Item {
        Kirigami.Icon {
            id: deviceStateIcon
            anchors.centerIn: parent
            width: Mycroft.Units.gridUnit * 1.75
            height: width
            source: deviceStateButtonControl.isDeviceActive ? Qt.resolvedUrl("../icons/bulb-on.svg") : Qt.resolvedUrl("../icons/bulb-off.svg")
            color: deviceStateButtonControl.isDeviceActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor

            ColorOverlay {
                anchors.fill: parent
                source: deviceStateIcon
                color: deviceStateButtonControl.isDeviceActive ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
            }
        }
    }

    onClicked: {
        deviceStateButtonControlAnimation.start()

        if(deviceControlsLoader.device.state == "on") {
            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.device.turn_off", { "device_id": device.id }, {"session": {"session_id": "default"}})
            deviceControlsLoader.createdControlsEnabled = false
        } else {
            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.device.turn_on", { "device_id": device.id }, {"session": {"session_id": "default"}})
            deviceControlsLoader.createdControlsEnabled = true
        }
    }
}
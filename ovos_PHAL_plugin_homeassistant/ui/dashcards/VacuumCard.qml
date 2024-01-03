import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "../code/helper.js" as HelperJS

Item {
    id: vacuumTemplateDashboardCard
    property var device: modelData
    Layout.fillWidth: true
    Layout.fillHeight: true
    property bool isOn: device.state == "on" ? 1 : 0

    Button {
        id: vacuumTemplateDashboardCardTriggerButton
        anchors.fill: parent
        
        background: Rectangle {
            id: vacuumTemplateDashboardCardTriggerBackground
            color: isOn ? Kirigami.Theme.backgroundColor : (HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.darker(Kirigami.Theme.backgroundColor, 1.5) : Qt.lighter(Kirigami.Theme.backgroundColor, 1.5))
            border.color: isOn ? Kirigami.Theme.highlightColor : (HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.lighter(Kirigami.Theme.backgroundColor, 3) : Qt.darker(Kirigami.Theme.backgroundColor, 3))
            border.width: 1
            radius: 10
        }

        SequentialAnimation {
            id: vacuumTemplateDashboardCardTriggerButtonAnimation

            PropertyAnimation {
                target: vacuumTemplateDashboardCardTriggerBackground
                property: "color"
                to: Qt.darker(Kirigami.Theme.highlightColor, 1.5)
                duration: 100
            }

            PropertyAnimation {
                target: vacuumTemplateDashboardCardTriggerBackground
                property: "color"
                to: Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                duration: 100
            }

            PropertyAnimation {
                target: vacuumTemplateDashboardCardTriggerBackground
                property: "color"
                to: isOn ? Kirigami.Theme.backgroundColor : (HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.darker(Kirigami.Theme.backgroundColor, 1.5) : Qt.lighter(Kirigami.Theme.backgroundColor, 1.5))
                duration: 200
            }
        }

        contentItem: Item {
            Label {
                id: vacuumTemplateDashboardCardTriggerButtonLabel
                text: device.state.toUpperCase()
                color: isOn ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                font.bold: true
                width: parent.width
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        onClicked: {
            if(device.state == "off") {
                Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.device.turn_on", { "device_id": device.id }, {"session": {"session_id": "default"}})
            } else {
                Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.device.turn_off", { "device_id": device.id }, {"session": {"session_id": "default"}})
            }
        }
    }
}
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0

ItemDelegate {
    id: dashboardDelegate
    property var deviceType: modelData.type
    implicitWidth: dashboardGridView.cellWidth
    implicitHeight: dashboardGridView.cellHeight

    leftPadding: Kirigami.Units.largeSpacing * 2
    topPadding: Kirigami.Units.largeSpacing * 2
    rightPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2

    leftInset: Kirigami.Units.largeSpacing
    topInset: Kirigami.Units.largeSpacing
    rightInset: Kirigami.Units.largeSpacing
    bottomInset: Kirigami.Units.largeSpacing

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
        radius: 10
        border.width: dashboardDelegate.activeFocus ? 2 : 0
        border.color: dashboardDelegate.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
    }

    contentItem: Item {

        ColumnLayout {
            anchors.fill: parent

            RowLayout {
                id: delegateTopArea                        
                Layout.fillWidth: true
                Layout.preferredHeight: Mycroft.Units.gridUnit * 3

                Kirigami.Icon {
                    id: delegateIcon
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.preferredWidth: Mycroft.Units.gridUnit * 2
                    Layout.preferredHeight: Mycroft.Units.gridUnit * 2
                    source: Qt.resolvedUrl("../icons/" + modelData.icon + ".svg")
                    color: Kirigami.Theme.textColor
                }

                Label {
                    id: delegateLabel
                    Layout.fillWidth: true
                    Layout.preferredHeight: Mycroft.Units.gridUnit * 2
                    text: modelData.name + "s"
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    id: delegateNumberBackground
                    color: Kirigami.Theme.highlightColor
                    radius: 100
                    Layout.preferredWidth: Mycroft.Units.gridUnit * 2
                    Layout.preferredHeight: Mycroft.Units.gridUnit * 2
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                    Label {
                        id: delegateNumber
                        width: parent.width
                        height: parent.height
                        text: modelData.devices.length
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Keys.onReturnPressed: {
        clicked()
    }

    onClicked: {
        if(dashboardRoot.useGroupDisplay) {
            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.show.area.dashboard", {"area": deviceType}, {"session": {"session_id": "default"}})
        } else {
            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.show.device.dashboard", {"device_type": deviceType}, {"session": {"session_id": "default"}})
        }
        change_tab_to_type(deviceType)
    }
}
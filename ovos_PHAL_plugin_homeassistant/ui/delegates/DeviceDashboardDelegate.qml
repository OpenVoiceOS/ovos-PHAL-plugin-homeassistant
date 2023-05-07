import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0

ItemDelegate {
    property var deviceType: modelData.type
    Layout.preferredWidth: deviceDashboardLayout.cellWidth
    Layout.preferredHeight: deviceDashboardLayout.cellHeight

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
                    text: modelData.attributes.friendly_name ? modelData.attributes.friendly_name : modelData.name
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Loader {
                id: delegateLoader
                Layout.fillWidth: true
                Layout.fillHeight: true

                source: switch (deviceType) {
                    case "media_player": return "../dashcards/MediaPlayerCard.qml"
                    case "binary_sensor": return "../dashcards/BinarySensorCard.qml"
                    case "sensor": return "../dashcards/SensorCard.qml"
                    case "light": return "../dashcards/LightCard.qml"
                    case "vacuum": return "../dashcards/VacuumCard.qml"
                    case "camera": return "../dashcards/CameraCard.qml"
                    case "switch": return "../dashcards/SwitchCard.qml"
                    case "scene": return "../dashcards/SceneCard.qml"
                    case "automation": return "../dashcards/AutomationCard.qml"
                }
            }
        }
    }

    // onClicked: {
    //     console.log("device attr: " + JSON.stringify(modelData.attributes))                
    // }
}

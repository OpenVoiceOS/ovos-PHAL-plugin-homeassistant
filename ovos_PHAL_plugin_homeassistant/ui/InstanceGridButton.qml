import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "code/helper.js" as HelperJS

Rectangle {
    id: gridItem
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: gridItem.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
    border.color: gridItem.activeFocus ? Kirigami.Theme.textColor : Kirigami.Theme.highlightColor
    border.width: gridItem.activeFocus ? 2 : 1
    radius: 5
    property int index
    property alias icon: onDisplayIconType.source
    property alias text: onDisplayIconLabel.text
    property bool hasAction: false
    property var action
    property var actionData

    Keys.onReturnPressed: {
        loginChoiceStackLayout.currentIndex = index
        if (gridItem.hasAction) {
            Mycroft.MycroftController.sendRequest(action, actionData, {"session": {"session_id": "default"}})
        }
    }

    MouseArea {
        anchors.fill: parent

        onClicked: {
            loginChoiceStackLayout.currentIndex = index
            
            if (gridItem.hasAction) {
                Mycroft.MycroftController.sendRequest(action, actionData, {"session": {"session_id": "default"}})
            }
        }

        onPressed: {
            gridItem.color = Qt.rgba(1, 1, 1, 0.2)
            onDisplayIconLabelBackground.color = Qt.darker(Kirigami.Theme.backgroundColor, 2)
        }
        onReleased: {
            gridItem.color = "transparent"
            onDisplayIconLabelBackground.color = Kirigami.Theme.highlightColor
        }
    }

    ColumnLayout {
        anchors.fill: parent

        Kirigami.Icon {
            id: onDisplayIconType
            Layout.preferredWidth: root.horizontalMode ? (parent.width / 2) : (parent.height / 2)
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            ColorOverlay {
                anchors.fill: parent
                source: parent
                color: Kirigami.Theme.textColor
            }
        }

        Rectangle {
            id: onDisplayIconLabelBackground
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.40
            Layout.alignment: Qt.AlignTop
            color: Kirigami.Theme.highlightColor
            radius: 5

            Label {
                id: onDisplayIconLabel
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                font.pixelSize: 32
                color: Kirigami.Theme.textColor
            }
        }
    }
}

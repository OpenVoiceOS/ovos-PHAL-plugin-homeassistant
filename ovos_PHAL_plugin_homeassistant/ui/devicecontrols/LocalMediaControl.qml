import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "../code/helper.js" as HelperJS

Rectangle {
    id: localMediaContentControl
    Layout.fillWidth: true
    Layout.fillHeight: true
    color: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.5) : Qt.darker(Kirigami.Theme.backgroundColor, 1.5)
    border.color: Kirigami.Theme.textColor
    border.width: 1
    radius: 10
    property var mediaModel: deviceControlsLoader.mediaModel
    property bool busyIndicatorVisible: false

    onMediaModelChanged: {
        busyIndicatorVisible = false
    }

    ColumnLayout {
        id: localMediaContentLayout
        anchors.fill: parent
        anchors.margins: Mycroft.Units.gridUnit / 2


        Item {
            id: localMediaControlHeaderArea
            Layout.fillWidth: true
            Layout.minimumHeight: Mycroft.Units.gridUnit * 2
            Layout.maximumHeight: Mycroft.Units.gridUnit * 3

            Label {
                id: localMediaControlHeaderLabel
                text: qsTr("Browse Media")
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
                id: localMediaControlHeaderSeparator
                anchors.top: localMediaControlHeaderLabel.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
            }
        }

        RowLayout {
            id: localMediaContentRowLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: Mycroft.Units.gridUnit * 4
            Layout.minimumHeight: Mycroft.Units.gridUnit * 3

            Rectangle {
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Mycroft.Units.gridUnit * 2
                Layout.maximumHeight: Mycroft.Units.gridUnit * 5
                color: Kirigami.Theme.backgroundColor
                radius: 8

                TextField {
                    id: localMediaSearchField
                    anchors.fill: parent
                    anchors.margins: Mycroft.Units.gridUnit / 2
                    focus: false
                    placeholderText: qsTr("Search with title, artist, or album")
                    color: Kirigami.Theme.textColor

                    background: Rectangle {
                        color: "transparent"
                    }

                    onAccepted: {
                        deviceControlsLoader.forceActiveFocus()
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.integration.query_media", {
                            "phrase": localMediaSearchField.text
                        }, {"session": {"session_id": "default"}})
                        busyIndicatorVisible = true
                    }
                }
            }

            Button {
                id: mediaSearchButton
                Layout.preferredWidth: Mycroft.Units.gridUnit * 4
                Layout.fillHeight: true

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
                        source: "system-search"

                        ColorOverlay {
                            id: mediaSearchButtonOverlayColor
                            anchors.fill: parent
                            source: parent
                            color: Kirigami.Theme.textColor
                        }
                    }
                }

                onClicked: {
                    deviceControlsLoader.forceActiveFocus()
                    Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.integration.query_media", {
                        "phrase": localMediaSearchField.text
                    }, {"session": {"session_id": "default"}})
                    busyIndicatorVisible = true
                }
                onPressed: {
                    mediaSearchButtonOverlayColor.color = Qt.lighter(Kirigami.Theme.highlightColor, 1.5)
                }
                onReleased: {
                    mediaSearchButtonOverlayColor.color = Kirigami.Theme.textColor
                }
            }
        }

        GridView {
            id: testModelView
            model: mediaModel
            Layout.fillWidth: true
            Layout.fillHeight: true
            cellWidth: parent.width / 3
            cellHeight: cellWidth
            cacheBuffer: width
            highlightMoveDuration: Kirigami.Units.longDuration
            clip: true
            delegate: LocalMediaDelegate{}
        }
    }

    Rectangle {
        id: busyIndicatorOverlay
        anchors.fill: parent
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.8)
        visible: busyIndicatorVisible
        enabled: busyIndicatorVisible
        z: 4

        BusyIndicator {
            anchors.centerIn: parent
            running: busyIndicatorOverlay.visible && busyIndicatorOverlay.enabled
        }
    }
}
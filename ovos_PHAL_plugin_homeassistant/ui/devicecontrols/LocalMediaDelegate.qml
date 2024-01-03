import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

ItemDelegate {
    id: delegate
    property int borderSize: Kirigami.Units.smallSpacing
    property int baseRadius: 3

    readonly property Flickable gridView: {
        var candidate = parent;
        while (candidate) {
            if (candidate instanceof Flickable) {
                return candidate;
            }
            candidate = candidate.parent;
        }
        return null;
    }

    leftPadding: Kirigami.Units.largeSpacing * 2
    topPadding: Kirigami.Units.largeSpacing * 2
    rightPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2

    leftInset: Kirigami.Units.largeSpacing
    topInset: Kirigami.Units.largeSpacing
    rightInset: Kirigami.Units.largeSpacing
    bottomInset: Kirigami.Units.largeSpacing

    implicitWidth: gridView.cellWidth
    height: gridView.cellHeight

    background: Rectangle {
        id: delegateBackground
        color: Kirigami.Theme.backgroundColor
        radius: delegate.baseRadius
    }

    SequentialAnimation {
        id: delegateClickAnimation

        PropertyAnimation {
            target: delegateBackground
            property: "color"
            from: Kirigami.Theme.backgroundColor
            to: Kirigami.Theme.highlightColor
            duration: 100
        }

        PropertyAnimation {
            target: delegateBackground
            property: "color"
            from: Kirigami.Theme.highlightColor
            to: Kirigami.Theme.backgroundColor
            duration: 100
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Item {
            id: imgRoot
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: -delegate.topPadding + delegate.topInset + extraBorder
            Layout.leftMargin: -delegate.leftPadding + delegate.leftInset + extraBorder
            Layout.rightMargin: -delegate.rightPadding + delegate.rightInset + extraBorder
            Layout.preferredHeight: width * 0.5625 + delegate.baseRadius
            property real extraBorder: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                cached: true
                maskSource: Rectangle {
                    x: imgRoot.x;
                    y: imgRoot.y
                    width: imgRoot.width
                    height: imgRoot.height
                    radius: delegate.baseRadius
                }
            }

            Image {
                id: img
                source: modelData.thumbnails[0]
                anchors {
                    fill: parent
                    bottomMargin: delegate.baseRadius
                }
                opacity: 1
            }
        }

        Kirigami.Heading {
            id: videoLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignTop
            maximumLineCount: 2
            wrapMode: Text.Wrap
            level: 3
            elide: Text.ElideRight
            color: Kirigami.Theme.textColor
            text: modelData.title
        }
    }

    onClicked: {
        delegateClickAnimation.running = true
        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.call.supported.function", {
            "device_id": deviceControlsLoader.device.id,
            "function_name": "play_media",
            "function_args": {
                "media_content_id": modelData.stream_url, 
                "media_content_type": "video/mp4",
                "extra": {
                    "title": modelData.title,
                    "thumb": modelData.thumbnails[0]
                }
            }
        }, {"session": {"session_id": "default"}})
        deviceControlsLoader.closeSheet()
    }
}

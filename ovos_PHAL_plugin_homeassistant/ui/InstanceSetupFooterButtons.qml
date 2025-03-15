import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "delegates" as Delegates
import "code/helper.js" as HelperJS

RowLayout {
    id: instanceSetupPopupButtonsTokenLogin
    property bool isTokenLogin: false

    Button {
        id: instanceSetupPopupStackBackButton
        Layout.fillWidth: true
        Layout.fillHeight: true

        background: Rectangle {
            id: instanceSetupPopupStackBackButtonBackground
            color: Kirigami.Theme.highlightColor
            radius: Mycroft.Units.gridUnit * 0.5
        }

        contentItem: Item{
            RowLayout {
                id: instanceSetupPopupStackBackButtonLayout
                anchors.centerIn: parent

                Kirigami.Icon {
                    id: instanceSetupPopupStackBackButtonIcon
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    Layout.alignment: Qt.AlignVCenter
                    source: "go-previous-symbolic"

                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: Kirigami.Theme.textColor
                    }
                }

                Kirigami.Heading {
                    id: instanceSetupPopupStackBackButtonText
                    level: 2
                    Layout.fillHeight: true
                    wrapMode: Text.WordWrap
                    font.bold: true
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                    text: qsTr("Back")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        onClicked: {
            loginChoiceStackLayout.currentIndex = 0
        }

        onPressed: {
            instanceSetupPopupStackBackButtonBackground.color = Qt.darker(Kirigami.Theme.highlightColor, 2)
        }

        onReleased: {
            instanceSetupPopupStackBackButtonBackground.color = Kirigami.Theme.highlightColor
        }
    }
    
    Button {
        id: instanceSetupPopupConfirmButton
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: instanceSetupPopupButtonsTokenLogin.isTokenLogin ? 1 : 0
        enabled: instanceSetupPopupButtonsTokenLogin.isTokenLogin ? 1 : 0

        background: Rectangle {
            id: instanceSetupPopupConfirmButtonBackground
            color: Kirigami.Theme.highlightColor
            radius: Mycroft.Units.gridUnit * 0.5
        }

        contentItem: Item {
            RowLayout {
                id: instanceSetupPopupConfirmButtonLayout
                anchors.centerIn: parent

                Kirigami.Icon {
                    id: instanceSetupPopupConfirmButtonIcon
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    Layout.alignment: Qt.AlignVCenter
                    source: "answer-correct"

                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: Kirigami.Theme.textColor
                    }
                }

                Kirigami.Heading {
                    id: instanceSetupPopupConfirmButtonText
                    level: 2
                    Layout.fillHeight: true
                    wrapMode: Text.WordWrap
                    font.bold: true
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                    text: qsTr("Confirm")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        onClicked: {
            Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.setup.instance", {"url": instanceSetupPopupUrl.text, "api_key": instanceSetupPopupApiKey.text}, {"session": {"session_id": "default"}})
            instaceSetupPopupBox.close()
        }

        onPressed: {
            instanceSetupPopupConfirmButtonBackground.color = Qt.darker(Kirigami.Theme.highlightColor, 2)
        }
        onReleased: {
            instanceSetupPopupConfirmButtonBackground.color = Kirigami.Theme.highlightColor
        }
    }

    Button {
        id: instanceSetupPopupCancelButton
        Layout.fillWidth: true
        Layout.fillHeight: true

        background: Rectangle {
            id: instanceSetupPopupCancelButtonBackground
            color: Kirigami.Theme.highlightColor
            radius: Mycroft.Units.gridUnit * 0.5
        }

        contentItem: Item {
            RowLayout {
                id: instanceSetupPopupCancelButtonLayout
                anchors.centerIn: parent

                Kirigami.Icon {
                    id: instanceSetupPopupCancelButtonIcon
                    Layout.fillHeight: true
                    Layout.preferredWidth: height
                    Layout.alignment: Qt.AlignVCenter
                    source: "window-close-symbolic"

                    ColorOverlay {
                        anchors.fill: parent
                        source: parent
                        color: Kirigami.Theme.textColor
                    }
                }

                Kirigami.Heading {
                    id: instanceSetupPopupCancelButtonText
                    level: 2
                    Layout.fillHeight: true
                    wrapMode: Text.WordWrap
                    font.bold: true
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                    text: qsTr("Cancel")
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        onClicked: {
            instaceSetupPopupBox.close()
        }

        onPressed: {
            instanceSetupPopupCancelButtonBackground.color = Qt.darker(Kirigami.Theme.highlightColor, 2)
        }
        onReleased: {
            instanceSetupPopupCancelButtonBackground.color = Kirigami.Theme.highlightColor
        }
    }
}

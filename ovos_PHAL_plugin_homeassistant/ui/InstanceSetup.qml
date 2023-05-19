import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "delegates" as Delegates
import "code/helper.js" as HelperJS

Popup {
    id: instaceSetupPopupBox
    property bool horizontalMode: width > height ? 1 : 0
    
    background: Rectangle {
        color: Qt.darker(Kirigami.Theme.backgroundColor, 1)
        radius: Mycroft.Units.gridUnit * 0.5
    }
    
    contentItem: Item {
        Item {
            anchors.fill: parent
            anchors.margins: Mycroft.Units.gridUnit

            Kirigami.Heading {
                id: instanceSetupPopupTitle
                level: 2
                text: qsTr("Setup Home Assistant Instance")
                font.bold: true
                color: Kirigami.Theme.textColor
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Mycroft.Units.gridUnit * 2
            }

            Kirigami.Separator {
                anchors.top: instanceSetupPopupTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                color: Kirigami.Theme.highlightColor
            }

            StackLayout {
                id: loginChoiceStackLayout
                anchors.top: instanceSetupPopupTitle.bottom
                anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                currentIndex: 0
                
                Item {
                    id: selectLoginMethodItem

                    Label {
                        id: instanceSetupPopupUrlLabel
                        text: qsTr("Home Assistant Instance URL")
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 10
                        elide: Text.ElideRight
                        font.pixelSize: Mycroft.Units.gridUnit * 1.5
                        color: Kirigami.Theme.textColor
                        anchors.top: instanceSetupPopupTitle.bottom
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Mycroft.Units.gridUnit * 2
                    }

                    Label {
                        id: subTextInstanceSetupPopupUrlLabel
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 8
                        elide: Text.ElideRight
                        font.pixelSize: 12
                        color: Kirigami.Theme.highlightColor
                        anchors.top: instanceSetupPopupUrlLabel.bottom
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Mycroft.Units.gridUnit * 2
                        text: qsTr("HTTP: http://homeassistant.local:8123") + "|" + qsTr("Websocket: ws://homeassistant.local:8123")
                    }

                    TextField {
                        id: instanceSetupPopupUrl
                        placeholderText: qsTr("http://homeassistant.local:8123 or ws://homeassistant.local:8123")
                        font.pixelSize: Mycroft.Units.gridUnit * 1.5
                        color: Kirigami.Theme.textColor
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: subTextInstanceSetupPopupUrlLabel.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                        height: Mycroft.Units.gridUnit * 3
                    }

                    GridLayout {
                        anchors.top: instanceSetupPopupUrl.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        columns: instaceSetupPopupBox.horizontalMode ? 2 : 1

                        InstanceGridButton {
                            id: qrCodeLoginButton
                            index: 1
                            icon: Qt.resolvedUrl("icons/qr-mobile.svg")
                            text: qsTr("Use QR Code")
                            hasAction: true
                            action: "ovos.phal.plugin.homeassistant.start.oauth.flow"
                            actionData: {"instance": instanceSetupPopupUrl.text}
                            enabled: instanceSetupPopupUrl.length > 4 ? 1 : 0
                        }

                        InstanceGridButton {
                            id: tokenLoginButton
                            index: 2
                            icon: Qt.resolvedUrl("icons/token-device.svg")
                            text: qsTr("Use Access Token")
                            hasAction: false
                            enabled: instanceSetupPopupUrl.length > 4 ? 1 : 0
                        }
                    }

                    Item {
                        anchors.top: instanceSetupPopupUrl.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        visible: instanceSetupPopupUrl.length < 5 ? 1 : 0
                        enabled: instanceSetupPopupUrl.length < 5 ? 1 : 0

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.8
                            height: Mycroft.Units.gridUnit * 4
                            color: "#000000"
                            radius: 6

                            Label {
                                anchors.fill: parent
                                anchors.margins: Mycroft.Units.gridUnit / 2
                                text: qsTr("Fill Instance Address To Continue Setup")
                                color: "white"
                                font.bold: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Item {
                    id: useQrCodeLoginItem

                    Rectangle{
                        id: instanceSetupPopupQrCodeLabel
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Mycroft.Units.gridUnit * 3
                        color: Kirigami.Theme.highlightColor

                        Label {
                            text: qsTr("Scan the QR code below to continue")
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 10
                            elide: Text.ElideRight
                            font.pixelSize: Mycroft.Units.gridUnit * 1.5
                            color: Kirigami.Theme.textColor
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            anchors.margins: Mycroft.Units.gridUnit * 0.5
                        }
                    }

                    Image {
                        id: qrCodeImage
                        anchors.top: instanceSetupPopupQrCodeLabel.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: instanceSetupFooterButtonsQrCodeArea.top
                        anchors.bottomMargin: Mycroft.Units.gridUnit * 0.5
                        fillMode: Image.PreserveAspectFit
                        source: dashboardRoot.qrImagePath
                    }

                    InstanceSetupFooterButtons {
                        id: instanceSetupFooterButtonsQrCodeArea
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Mycroft.Units.gridUnit * 0.5
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Mycroft.Units.gridUnit * 3
                        isTokenLogin: false
                    }
                }

                Item {
                    id: useTokenLoginItem
                    
                    Label {
                        id: instanceSetupPopupApiKeyLabel
                        text: qsTr("Home Assistant Instance API Key")
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 10
                        elide: Text.ElideRight
                        font.pixelSize: Mycroft.Units.gridUnit * 1.5
                        color: Kirigami.Theme.textColor
                        anchors.top: instanceSetupPopupUrl.bottom
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Mycroft.Units.gridUnit * 2
                    }

                    TextField {
                        id: instanceSetupPopupApiKey
                        placeholderText: qsTr("API Key")
                        font.pixelSize: Mycroft.Units.gridUnit * 1.5
                        color: Kirigami.Theme.textColor
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: instanceSetupPopupApiKeyLabel.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                        height: Mycroft.Units.gridUnit * 3
                    }

                    InstanceSetupFooterButtons {
                        id: instanceSetupFooterButtonsTokenArea
                        anchors.top: instanceSetupPopupApiKey.bottom
                        anchors.topMargin: Mycroft.Units.gridUnit * 0.5
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Mycroft.Units.gridUnit * 3
                        isTokenLogin: true
                    }
                }
            }
        }
    }
}

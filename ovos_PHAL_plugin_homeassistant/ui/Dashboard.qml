import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft
import QtGraphicalEffects 1.0
import "delegates" as Delegates
import "code/helper.js" as HelperJS

Mycroft.Delegate {
    id: dashboardRoot
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    property var dashboardModel: sessionData.dashboardModel
    property var deviceDashboardModel: sessionData.deviceDashboardModel
    property var areaDashboardModel: sessionData.areaDashboardModel
    property bool instanceAvailable: sessionData.instanceAvailable
    property bool useGroupDisplay: sessionData.use_group_display
    property bool useWebsocket: sessionData.use_websocket
    property var tabBarModel
    property bool horizontalMode: width >= height ? true : false
    property var qrImagePath

    function get_page_name() {
        if (dashboardSwipeView.currentIndex == 0) {
            return "Dashboard"
        } else {
            return tabBarModel[bar.currentIndex].name
        }
    }

    function change_tab_to_type(type) {
        var index_of_type_in_tabBarModel = tabBarModel.findIndex(function(item) {
            return item.type == type
        })
        bar.currentIndex = index_of_type_in_tabBarModel
    }

    Timer {
        id: pollTimer
        interval: 3000
        repeat: true
        running: dashboardSwipeView.currentIndex > 0 ? 1 : 0
        onTriggered: {
            if(!dashboardRoot.useWebsocket){
                var dev_type = tabBarModel[bar.currentIndex].type
                if(dev_type != "main") {
                    if (dashboardRoot.useGroupDisplay) {
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.update.area.dashboard", {"area_type": dev_type}, {"session": {"session_id": "default"}})
                    } else {
                        Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.update.device.dashboard", {"device_type": dev_type}, {"session": {"session_id": "default"}})
                    }
                }
            }
        }
    }

    Timer {
        id: delayTimer
    }

    function delay(delayTime, cb) {
        delayTimer.interval = delayTime;
        delayTimer.repeat = false;
        delayTimer.triggered.connect(cb);
        delayTimer.start();
    }

    onGuiEvent: {
        switch (eventName) {
        case "ovos.phal.plugin.homeassistant.change.dashboard":
            var requested_page = data.dash_type
            if (requested_page === "main") {
                dashboardSwipeView.currentIndex = 0
            } else if (requested_page === "device") {
                dashboardSwipeView.currentIndex = 1
            } else if (requested_page === "area") {
                dashboardSwipeView.currentIndex = 1
            }
            break
        case "ovos.phal.plugin.homeassistant.integration.query_media.result":
            deviceControlsLoader.mediaModel = data.results
            break
        case "ovos.phal.plugin.homeassistant.oauth.qr.update":
            dashboardRoot.qrImagePath = Qt.resolvedUrl(data.qr)
            break
        case "ovos.phal.plugin.homeassistant.oauth.success":
            instaceSetupPopupBox.close()
            break
        case "ovos.phal.plugin.homeassistant.device.updated":
            var dev_type = tabBarModel[bar.currentIndex].type
            if(dev_type != "main") {
                if (dashboardRoot.useGroupDisplay) {
                    Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.update.area.dashboard", {"area_type": dev_type}, {"session": {"session_id": "default"}})
                } else {
                    Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.update.device.dashboard", {"device_type": dev_type}, {"session": {"session_id": "default"}})
                }
            }
            break
        }
    }

    onDashboardModelChanged: {
        if (dashboardModel) {
            dashboardGridView.model = dashboardModel.items
            dashboardGridView.forceLayout();

            // Build the tab bar model
            var tabModel = [{"name": "Home", "type": "main"}]
            for (var i = 0; i < dashboardModel.items.length; i++) {
                var item = dashboardModel.items[i]
                if(dashboardRoot.useGroupDisplay) {
                    tabModel.push({"name": item.name, "type": item.type})
                } else {
                    tabModel.push({"name": item.name + "s", "type": item.type})
                }
            }
            tabBarModel = tabModel
        }
    }

    onDeviceDashboardModelChanged: {
        if (deviceDashboardModel) {
            devicesGridView.model = deviceDashboardModel.items

            if(dashboardSwipeView.currentIndex > 0) {
                if(!dashboardRoot.useWebsocket){
                    pollTimer.restart()
                }
            }
        }
    }

    onAreaDashboardModelChanged: {
        if (areaDashboardModel) {
            devicesGridView.model = areaDashboardModel.items

            if(dashboardSwipeView.currentIndex > 0) {
                if(!dashboardRoot.useWebsocket){
                    pollTimer.restart()
                }
            }
        }
    }

    background: Rectangle {
        color: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.darker(Kirigami.Theme.backgroundColor, 1.5) : Qt.lighter(Kirigami.Theme.backgroundColor, 1.5)
    }

    Item {
        anchors.fill: parent

        Item {
            id: topBarArea
            height: dashboardRoot.horizontalMode ? Mycroft.Units.gridUnit * 3 : Mycroft.Units.gridUnit * 6
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            GridLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: topBarSeparator.top
                columns: dashboardRoot.horizontalMode ? 2 : 1

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        id: pageTitleIconArea
                        width: Mycroft.Units.gridUnit * 3
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        color: Kirigami.Theme.highlightColor

                        Kirigami.Icon {
                            id: pageTitleIcon
                            anchors.centerIn: parent
                            width: Mycroft.Units.gridUnit * 1.8
                            height: Mycroft.Units.gridUnit * 1.8
                            source: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.resolvedUrl("icons/ha_icon_dark.svg") : Qt.resolvedUrl("icons/ha_icon_light.svg")
                        }
                    }

                    Rectangle {
                        id: pageTitleRect
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: pageTitleIconArea.right
                        anchors.leftMargin: Mycroft.Units.gridUnit * 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: Kirigami.Theme.highlightColor
                        width: pageTitle.implicitWidth + Mycroft.Units.gridUnit * 2

                        Label {
                            id: pageTitle
                            text: qsTr("Home Assistant") + " - " + get_page_name()
                            font.pixelSize: Mycroft.Units.gridUnit * 1.5
                            color: Kirigami.Theme.textColor
                            anchors.fill: parent
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        id: topBarExperimentArea
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: topBarExperimentLabel.implicitWidth + Mycroft.Units.gridUnit * 6
                        color: Kirigami.Theme.highlightColor
                        anchors.right: dashboardRoot.horizontalMode ? topBarAreaCloseDashboardButton.left : undefined
                        anchors.rightMargin: dashboardRoot.horizontalMode ? Mycroft.Units.gridUnit / 2 : 0
                        anchors.left: dashboardRoot.horizontalMode ? undefined : parent.left
                        visible: dashboardRoot.instanceAvailable && dashboardRoot.useWebsocket ? 1 : 0
                        enabled: dashboardRoot.instanceAvailable && dashboardRoot.useWebsocket ? 1 : 0

                        Label {
                            id: topBarExperimentLabel
                            anchors.left: parent.left
                            anchors.leftMargin: Mycroft.Units.gridUnit / 2
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            width: implicitWidth
                            text: qsTr("Display Grouped")
                            color: Kirigami.Theme.textColor
                        }

                        Switch {
                            id: useGroupDisplaySwitch
                            anchors.left: topBarExperimentLabel.right
                            anchors.right: parent.right
                            anchors.rightMargin: Mycroft.Units.gridUnit / 2
                            anchors.verticalCenter: parent.verticalCenter
                            checked: dashboardRoot.useGroupDisplay
                            palette.mid: Kirigami.Theme.textColor

                            onCheckedChanged:{
                                if(checked) {
                                    Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.set.group.display.settings", {"use_group_display": true}, {"session": {"session_id": "default"}})
                                } else {
                                    Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.set.group.display.settings", {"use_group_display": false}, {"session": {"session_id": "default"}})
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: topBarAreaCloseDashboardButton
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Mycroft.Units.gridUnit * 4
                        color: Kirigami.Theme.highlightColor

                        Kirigami.Icon {
                            id: closeIcon
                            anchors.centerIn: parent
                            width: Mycroft.Units.gridUnit * 1.8
                            height: Mycroft.Units.gridUnit * 1.8
                            source: "window-close-symbolic"

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Mycroft.MycroftController.sendRequest("ovos-PHAL-plugin-homeassistant.close", {}, {"session": {"session_id": "default"}})
                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                id: topBarSeparator
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                color: Kirigami.Theme.highlightColor
            }
        }

        Item {
            id: instanceSetupArea
            visible: !instanceAvailable
            enabled: !instanceAvailable
            anchors.top: topBarArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Kirigami.Icon {
                id: instanceSetupIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -Mycroft.Units.gridUnit * 5
                anchors.horizontalCenter: parent.horizontalCenter
                width: Mycroft.Units.gridUnit * 5
                height: Mycroft.Units.gridUnit * 5
                source: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.resolvedUrl("icons/ha_icon_dark.svg") : Qt.resolvedUrl("icons/ha_icon_light.svg")
            }

            Label {
                id: instanceSetupLabel
                text: qsTr("Home Assistant Instance Not Available")
                fontSizeMode: Text.Fit
                minimumPixelSize: 10
                elide: Text.ElideRight
                font.pixelSize: Mycroft.Units.gridUnit * 1.5
                color: Kirigami.Theme.textColor
                anchors.top: instanceSetupIcon.bottom
                anchors.topMargin: Mycroft.Units.gridUnit * 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                id: instanceSetupButton
                font.pixelSize: Mycroft.Units.gridUnit * 1.5
                anchors.top: instanceSetupLabel.bottom
                anchors.topMargin: Mycroft.Units.gridUnit * 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: instanceSetupButtonLayout.implicitWidth + Mycroft.Units.gridUnit * 2
                height: Mycroft.Units.gridUnit * 4

                background: Rectangle {
                    color: Kirigami.Theme.highlightColor
                    radius: Mycroft.Units.gridUnit * 0.5
                }

                contentItem: Item {
                    RowLayout {
                        id: instanceSetupButtonLayout
                        anchors.centerIn: parent

                        Kirigami.Icon {
                            id: instanceSetupButtonIcon
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.alignment: Qt.AlignVCenter
                            source: "network-connect"
                        }

                        Kirigami.Heading {
                            id: instanceSetupButtonText
                            level: 2
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                            font.bold: true
                            elide: Text.ElideRight
                            color: Kirigami.Theme.textColor
                            text: qsTr("Connect Instance")
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }

                onClicked: {
                    instaceSetupPopupBox.open()
                }
            }
        }

        SwipeView {
            id: dashboardSwipeView
            currentIndex: 0
            anchors.top: topBarArea.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bottomBarArea.top
            visible: instanceAvailable
            enabled: instanceAvailable
            interactive: false
            clip: false

            Item {
                id: mainDashboard

                Kirigami.CardsGridView {
                    id: dashboardGridView
                    anchors.fill: parent
                    maximumColumns: horizontalMode ? 3 : 2
                    cellHeight: Mycroft.Units.gridUnits * 5
                    delegate: Delegates.DashboardDelegate {}
                    clip: true
                    ScrollBar.vertical: ScrollBar{
                        width: Mycroft.Units.gridUnit * 1.5
                        policy: dashboardGridView.count >= 6 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }
                }
            }

            Item {
                id: deviceDashboard

                Flickable {
                    id: devicesDashboard
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: deviceDashboardLayout.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar{
                        width: Mycroft.Units.gridUnit * 1.5
                        policy: devicesGridView.count >= 6 ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    GridLayout {
                        id: deviceDashboardLayout
                        anchors.fill: parent
                        columns: horizontalMode ? (width > 800 ? 3 : 2) : (width > 600 ? 2 : 1)
                        property int cellWidth: horizontalMode ? (width / columns - Kirigami.Units.largeSpacing * 2) : (width / columns - Kirigami.Units.largeSpacing * 2)
                        property int cellHeight: cellWidth - Kirigami.Units.largeSpacing * 3
                        columnSpacing: Kirigami.Units.largeSpacing
                        rowSpacing: Kirigami.Units.largeSpacing

                        Repeater {
                            id: devicesGridView
                            delegate: Delegates.DeviceDashboardDelegate {}
                        }
                    }
                }
            }
        }

        Item {
            id: bottomBarArea
            height: Mycroft.Units.gridUnit * 3
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            Kirigami.Separator {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                color: Kirigami.Theme.highlightColor
            }
            Item {
                id: bottomBarAreaTabsContainer
                width: parent.width
                height: parent.height
                anchors.bottom: parent.bottom
                visible: dashboardRoot.horizontalMode ? 1 : 0
                property bool leftButtonActive: tabBarFlickableObject.contentX > 0 ? 1 : 0
                property bool rightButtonActive: tabBarFlickableObject.contentX < tabBarFlickableObject.contentWidth - tabBarFlickableObject.width ? 1 : 0

                Button {
                    id: arrowLeftTabBarFlicker
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: Mycroft.Units.gridUnit * 3
                    height: Mycroft.Units.gridUnit * 3
                    enabled: bottomBarAreaTabsContainer.leftButtonActive ? 1 : 0
                    opacity: enabled ? 1 : 0.5

                    background: Rectangle {
                        id: arrowLeftTabBarFlickerBackground
                        color: "transparent"
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            id: arrowLeftTabBarFlickerIcon
                            width: parent.width * 0.8
                            height: parent.height * 0.8
                            anchors.centerIn: parent
                            source: "go-previous-symbolic"
                        }
                    }

                    onClicked:  {
                        if (tabBarFlickableObject.contentX > 0) {
                            tabBarFlickableObject.contentX -= Mycroft.Units.gridUnit * 12
                        }
                    }

                    onPressAndHold: {
                        tabBarFlickableObject.contentX = 0
                        arrowLeftTabBarFlickerBackground.color = "transparent"
                    }

                    onPressed: {
                        arrowLeftTabBarFlickerBackground.color = Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
                    }
                    onReleased: {
                        arrowLeftTabBarFlickerBackground.color = "transparent"
                    }
                }

                Flickable {
                    id: tabBarFlickableObject
                    anchors.left: arrowLeftTabBarFlicker.right
                    anchors.leftMargin: Mycroft.Units.gridUnit * 0.5
                    anchors.rightMargin: Mycroft.Units.gridUnit * 0.5
                    anchors.right: arrowRightTabBarFlicker.left
                    height: parent.height
                    anchors.bottom: parent.bottom
                    flickableDirection: Flickable.HorizontalFlick
                    contentWidth: tabBarModelRepeater.count * Mycroft.Units.gridUnit * 12
                    contentHeight: height
                    clip: true

                    TabBar {
                        id: bar
                        width: (Mycroft.Units.gridUnit * 12) * tabBarModel.count
                        height: parent.height - Kirigami.Units.smallSpacing
                        anchors.bottom: parent.bottom

                        Repeater {
                            id: tabBarModelRepeater
                            model: tabBarModel
                            delegate: TabButton {
                                text: modelData.name
                                width: Mycroft.Units.gridUnit * 12
                                height: parent.height

                                onClicked: {
                                    if(dashboardRoot.horizontalMode) {
                                        if(modelData.type === "main") {
                                            dashboardSwipeView.currentIndex = 0
                                        } else {
                                            if(dashboardRoot.useGroupDisplay) {
                                                Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.show.area.dashboard", {"area": modelData.type}, {"session": {"session_id": "default"}})
                                            } else {
                                                Mycroft.MycroftController.sendRequest("ovos.phal.plugin.homeassistant.show.device.dashboard", {"device_type": modelData.type}, {"session": {"session_id": "default"}})
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    id: arrowRightTabBarFlicker
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: Mycroft.Units.gridUnit * 3
                    height: Mycroft.Units.gridUnit * 3
                    enabled: bottomBarAreaTabsContainer.rightButtonActive && tabBarModelRepeater.count > 2 ? 1 : 0
                    opacity: enabled ? 1 : 0.5

                    background: Rectangle {
                        id: arrowRightTabBarFlickerBackground
                        color: "transparent"
                    }

                    contentItem: Item {
                        Kirigami.Icon {
                            id: arrowRightTabBarFlickerIcon
                            width: parent.width * 0.8
                            height: parent.height * 0.8
                            anchors.centerIn: parent
                            source: "go-next-symbolic"
                        }
                    }

                    onClicked: {
                        if(tabBarFlickableObject.contentX < tabBarFlickableObject.contentWidth - tabBarFlickableObject.width) {
                            tabBarFlickableObject.contentX += Mycroft.Units.gridUnit * 12
                        }
                    }

                    onPressAndHold: {
                        tabBarFlickableObject.contentX = tabBarFlickableObject.contentWidth - tabBarFlickableObject.width
                        arrowRightTabBarFlickerBackground.color = "transparent"
                    }

                    onPressed: {
                        arrowRightTabBarFlickerBackground.color = Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.5)
                    }
                    onReleased: {
                        arrowRightTabBarFlickerBackground.color = "transparent"
                    }
                }
            }

            Button {
                id: returnToMainDashboardButtonVerticalMode
                width: parent.width
                height: parent.height - 1
                anchors.bottom: parent.bottom
                visible: !dashboardRoot.horizontalMode ? 1 : 0
                enabled: !dashboardRoot.horizontalMode ? 1 : 0

                background: Rectangle {
                    color: HelperJS.isLight(Kirigami.Theme.backgroundColor) ? Qt.lighter(Kirigami.Theme.backgroundColor, 1.2) : Qt.darker(Kirigami.Theme.backgroundColor, 1.1)
                }

                contentItem: Item {
                    RowLayout {
                        id: returnToMainDashboardButtonVerticalModeLayout
                        anchors.centerIn: parent

                        Kirigami.Icon {
                            id: returnToMainDashboardButtonVerticalModeIcon
                            Layout.fillHeight: true
                            Layout.preferredWidth: height
                            Layout.alignment: Qt.AlignVCenter
                            source: "dashboard-show"

                            ColorOverlay {
                                anchors.fill: parent
                                source: parent
                                color: Kirigami.Theme.textColor
                            }
                        }

                        Kirigami.Heading {
                            id: returnToMainDashboardButtonVerticalModeText
                            level: 2
                            Layout.fillHeight: true
                            wrapMode: Text.WordWrap
                            font.bold: true
                            elide: Text.ElideRight
                            color: Kirigami.Theme.textColor
                            text: qsTr("Dashboard Overview")
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                        }
                    }
                }

                onClicked: {
                    dashboardSwipeView.currentIndex = 0
                }

                onPressed: {
                    returnToMainDashboardButtonVerticalMode.opacity = 0.5
                }
                onReleased: {
                    returnToMainDashboardButtonVerticalMode.opacity = 1
                }
            }
        }

        InstanceSetup {
            id: instaceSetupPopupBox
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: parent.width * 0.95
            height: parent.height * 0.95
        }

        ItemDelegate {
            anchors.fill: parent
            visible: deviceControlsLoader.opened
            enabled: deviceControlsLoader.opened

            background: Rectangle {
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.9)
            }

            DeviceControlsLoader {
                id: deviceControlsLoader
                horizontalMode: dashboardRoot.horizontalMode
            }

            onClicked: {
                if(deviceControlsLoader.opened) {
                    deviceControlsLoader.closeSheet()
                }
            }
        }
    }
}

/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: devicesPage

    allowedOrientations: Orientation.All
    //anchors.bottom: navPanel.top
    //clip: navPanel.expanded

    SilicaListView {
        id: listView
        model: app.controller.devices
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Reload Devices")
                onClicked: app.controller.reloadDevices()
            }
        }

        header: PageHeader {
            id: pHeader
            width: parent.width
            title: qsTr("Devices")
        }

        delegate: ListItem {
            id: delegate
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium

            Column {
                id: column
                width: parent.width
                Label {
                    id: nameLabel
                    color: is_active ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    //width: parent.width - countLabel.width
                    text: {
                        var str = name ? name : qsTr("Unknown Name")
                        if (type)
                            str += ", " + type
                        /*if(sp && avahi)
                            str += " [Spotify, Avahi]"
                        else if(avahi)
                            str += " [Avahi]"
                        else
                            str += " [Spotify]"*/
                        return str
                    }
                }
                Label {
                    id: meta1Label
                    width: parent.width
                    color: is_active ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                    text: {
                        var str = volume_percent + "%"
                        str += ", "
                        str += is_active
                               ? qsTr("active") : qsTr("inactive")
                        str += ", "
                        str += is_restricted
                               ? qsTr("restricted") : qsTr("unrestricted")
                        return str
                    }
                }
            }

            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        //enabled: type === 2
                        text: qsTr("Set as Current")
                        onClicked: {
                            if(spotify)
                                app.setDevice(model.id, model.name)
                        }
                    }
                }
            }

        }

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing Devices found")
            hintText: qsTr("Pull down to reload")
        }

        VerticalScrollDecorator {}
    }

    // signal foundDevicesChanged()
    // onFoundDevicesChanged: refreshDevices()

    Connections {
        target: app
        onHasValidTokenChanged: app.controller.reloadDevices()
    }

    Component.onCompleted: app.controller.reloadDevices()
}


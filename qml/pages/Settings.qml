/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

Page {
    id: settingsPage

    allowedOrientations: Orientation.All


    onStatusChanged: {
        if (status === PageStatus.Activating) {
            searchLimit.text = app.searchLimit.value
            auth_using_browser.checked = app.auth_using_browser.value
            start_stop_librespot.checked = app.start_stop_librespot.value
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        ListModel { id: items }

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Settings") }

            TextField {
                id: searchLimit
                label: qsTr("Number of results per request (limit)")
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: app.searchLimit.value = Math.floor(text)
                validator: IntValidator {bottom: 1; top: 50;}
            }
            TextSwitch {
                id: auth_using_browser
                text: qsTr("Authorize using Browser")
                description: qsTr("Use external Browser to login at Spotify")
                checked: app.auth_using_browser.value
                onCheckedChanged: {
                    app.auth_using_browser.value = checked;
                    app.auth_using_browser.sync();
                }
            }

            /*TextSwitch {
                id: start_stop_librespot
                text: qsTr("Start/Stop Librespot")
                description: qsTr("Start Librespot when launched and stop it on exit")
                checked: app.start_stop_librespot.value
                onCheckedChanged: {
                    app.start_stop_librespot.value = checked;
                    app.start_stop_librespot.sync();
                }
            }*/

            TextSwitch {
                id: launchLibrespot
                text: qsTr("Librespot")
                description: {
                    if(!librespot.serviceEnabled)
                        return qsTr("Unavailable")
                    else
                        return librespot.serviceRunning
                                ? qsTr("Running")
                                : qsTr("Not Running")
                }
                enabled: librespot.serviceEnabled
                checked: librespot.serviceRunning
                onCheckedChanged: {
                    if(checked) {
                        if(!librespot.serviceRunning)
                            librespot.start()
                    } else
                        librespot.stop()
                }
            }
        }
    }

    Librespot {
        id: librespot
    }
}


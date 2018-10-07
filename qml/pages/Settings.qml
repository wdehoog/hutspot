/**
 * Hutspot. Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify

Page {
    id: settingsPage

    allowedOrientations: Orientation.All


    onStatusChanged: {
        if (status === PageStatus.Activating) {
            searchLimit.text = app.searchLimit.value
            searchHistoryLimit.text = app.search_history_max_size.value
            navigation_menu_type.currentIndex = app.navigation_menu_type.value
            hutspotQueueName.text = app.hutspot_queue_playlist_name.value
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PushUpMenu {
            MenuItem {
                text: qsTr("Login")
                onClicked: spotify.doO2Auth(Spotify._scope, app.auth_using_browser.value)
            }
            MenuItem {
                text: qsTr("Refresh Token")
                onClicked: spotify.refreshToken()
            }
        }

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

            TextField {
                id: searchHistoryLimit
                label: qsTr("Maximum size of Search History")
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: app.search_history_max_size.value = Math.floor(text)
                validator: IntValidator {bottom: 1; top: 50;}
            }

            TextSwitch {
                id: start_stop_librespot
                text: qsTr("Control Librespot")
                description: qsTr("Start Librespot when launched and stop it on exit")
                checked: app.start_stop_librespot.value
                onCheckedChanged: {
                    app.start_stop_librespot.value = checked
                    app.start_stop_librespot.sync()
                }
            }

            TextSwitch {
                id: launchLibrespot
                text: {
                    if(!librespot.serviceEnabled)
                        return qsTr("Cannot start Librespot")
                    else
                        return librespot.serviceRunning
                                ? qsTr("Stop Librespot")
                                : qsTr("Start Librespot")
                }
                description: {
                    if(!librespot.serviceEnabled)
                        return qsTr("Librespot is not available")
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

            TextField {
                id: hutspotQueueName
                label: qsTr("Hutspot Queue Playlist name")
                width: parent.width
                onTextChanged: {
                    if(text.length > 0) // ToDo: can we cancel an edit?
                        app.hutspot_queue_playlist_name.value = text
                }
            }

            TextSwitch {
                id: queryForMarket
                text: qsTr("Query for Market")
                description: qsTr("Show only content playable in the country associated with the user account")
                checked: app.query_for_market.value
                onCheckedChanged: {
                    app.query_for_market.value = checked
                    app.query_for_market.sync()
                }
            }

            TextSwitch {
                id: confirm_un_follow_save
                text: qsTr("Confirm Un-Save/Follow")
                description: qsTr("Ask for confirmation for un-save and un-follow")
                checked: app.confirm_un_follow_save.value
                onCheckedChanged: {
                    app.confirm_un_follow_save.value = checked
                    app.confirm_un_follow_save.sync()
                }
            }

            ComboBox {
                id: navigation_menu_type
                label: qsTr("Navigation Menu Type")

                menu: ContextMenu {
                    MenuItem { text: qsTr("Page with List of Menu Items") }
                    MenuItem { text: qsTr("Menu Page attached to Playing Page") }
                    MenuItem { text: qsTr("Docked Panel with all Icons") }
                    MenuItem { text: qsTr("Docked Panel with Player Controls and Hamburger button") }
                }

                onCurrentIndexChanged: {
                    app.navigation_menu_type.value = currentIndex
                    app.navigation_menu_type.sync()
                }
            }

            TextSwitch {
                id: playing_as_attached_page
                text: qsTr("Playing as Attached Page")
                description: qsTr("Have the Playing page as an Attached Page (available on the Right)")
                checked: app.playing_as_attached_page.value
                onCheckedChanged: {
                    app.playing_as_attached_page.value = checked
                    app.playing_as_attached_page.sync()
                }
            }

            TextSwitch {
                id: auth_using_browser
                text: qsTr("Authorize using Browser")
                description: qsTr("Use external Browser to login at Spotify")
                checked: app.auth_using_browser.value
                onCheckedChanged: {
                    app.auth_using_browser.value = checked
                    app.auth_using_browser.sync()
                }
            }


        }

    }

    Librespot {
        id: librespot
    }
}


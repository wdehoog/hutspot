/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: genreMoodPlaylistPage
    objectName: "GenreMoodPlaylistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property int currentIndex: -1

    property var category

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel

        width: parent.width
        anchors.top: parent.top
        anchors.bottom: panelLoader.itemTop
        clip: panelLoader.itemExpanded

        LoadPullMenus {}
        LoadPushMenus {}

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingMedium

            PageHeader {
                id: pHeader
                width: parent.width
                title: category.name
                MenuButton {}
            }
        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeLarge

            Image {
                id: categoryIcon
                width: Theme.iconSizeLarge
                height: width
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: category.icons[0].url
            }

            SearchResultListItem {
                dataModel: model
            }

            onClicked: app.pushPage(Util.HutspotPage.Playlist, {playlist: playlist})
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("No Playlists found")
            hintText: qsTr("Pull down to reload")
        }
    }

    PanelLoader {
        id: panelLoader
        flickable: listView
    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()

        Spotify.getCategoryPlaylists(category.id, {offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                try {
                    console.log("number of Playlists: " + data.playlists.items.length)
                    cursorHelper.offset = data.playlists.offset
                    cursorHelper.total = data.playlists.total
                    for(i=0;i<data.playlists.items.length;i++) {
                        searchModel.append({type: 2,
                                            name: data.playlists.items[i].name,
                                            playlist: data.playlists.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getCategoryPlaylists")
            }
        })

    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: refresh()
        onLoadPrevious: refresh()
    }

    Connections {
        target: app
        onLoggedInChanged: {
            if(app.loggedIn)
                refresh()
        }
        onHasValidTokenChanged: refresh()
    }

    Component.onCompleted: {
        if(app.hasValidToken)
            refresh()
    }
}

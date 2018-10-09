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
    id: newRelease
    objectName: "NewReleasePage"

    property bool showBusy: false

    property int currentIndex: -1

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

        header: Column {
            id: lvColumn

            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                width: parent.width
                title: qsTr("New Releases")
                MenuButton {}
            }

            LoadPullMenus {}
            LoadPushMenus {}

        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            //height: searchResultListItem.height
            contentHeight: Theme.itemSizeLarge

            SearchResultListItem {
                id: searchResultListItem
                dataModel: model
            }

            menu: SearchResultContextMenu {}

            onClicked: app.pushPage(Util.HutspotPage.Album, {album: album})
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("Nothing found")
            hintText: qsTr("Pull down to reload")
        }

    }

    PanelLoader {
        id: panelLoader
        flickable: listView
    }

    function refresh() {
        var i;
        showBusy = true
        searchModel.clear()

        Spotify.getNewReleases({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
            if(data) {
                cursorHelper.offset = data.albums.offset
                cursorHelper.total = data.albums.total
                try {
                    // albums
                    for(i=0;i<data.albums.items.length;i++) {
                        searchModel.append({type: 0,
                                            name: data.albums.items[i].name,
                                            album: data.albums.items[i]})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("getNewReleases returned no results.")
            }
            showBusy = false
        })

        /* why is this here?
        for(var i=0;i<app.history.length;i++) {
            var parsed = Util.parseSpotifyUri(app.history[i])
            if(parsed.type !== undefined)
                console.log("history: type=" + parsed.type +", id=" + parsed.id)
        }*/
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

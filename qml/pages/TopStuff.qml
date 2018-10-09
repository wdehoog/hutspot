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
    id: topStuffPage
    objectName: "TopStuffPage"


    property int searchInType: 0
    property bool showBusy: false
    property int currentIndex: -1


    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    Column {

        anchors.fill: parent

        SilicaListView {
            id: listView
            model: searchModel

            width: parent.width
            height: parent.height - panelLoader.height
            clip: panelLoader.height > 0

            LoadPullMenus {}
            LoadPushMenus {}

            header: Column {
                id: lvColumn

                width: parent.width - 2*Theme.paddingMedium
                x: Theme.paddingMedium
                anchors.bottomMargin: Theme.paddingLarge
                spacing: Theme.paddingLarge

                PageHeader {
                    id: pHeader
                    width: parent.width
                    title: {
                        switch(_itemClass) {
                        case 0: return Util.createPageHeaderLabel(qsTr("Top "), qsTr("Tracks"), Theme)
                        case 1: return Util.createPageHeaderLabel(qsTr("Top "), qsTr("Artists"), Theme)
                        }
                    }
                    MenuButton { z: 1} // set z so you can still click the button
                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onClicked: nextItemClass()
                    }
                }

            }

            delegate: ListItem {
                id: listItem
                width: parent.width - 2*Theme.paddingMedium
                x: Theme.paddingMedium
                contentHeight: Theme.itemSizeLarge

                SearchResultListItem {
                    id: searchResultListItem
                    dataModel: model
                }

                menu: SearchResultContextMenu {}

                onClicked: {
                    switch(type) {
                    case 1:
                        app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                        break;
                    case 3:
                        app.pushPage(Util.HutspotPage.Album, {album: track.album})
                        break;
                    }
                }
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
    }

    property var topTracks
    property var topArtists
    property int _itemClass: 0

    function nextItemClass() {
        var i = _itemClass
        i++
        if(i > 1)
            i = 0
        _itemClass = i
        refresh()
    }

    function loadData() {
        var i

        // I don't understand why I have to make the objects being appended
        // have the same properties. Before I did that the artist property
        // would be missing in the delegate of the ListView. That did never happen
        // when both tracks as well as artists were added in this function.

        if(topTracks)
            for(i=0;i<topTracks.items.length;i++)
                searchModel.append({type: 3,
                                    name: topTracks.items[i].name,
                                    following: false,
                                    track: topTracks.items[i],
                                    artist: {}})
        if(topArtists) {
            var artistIds = []
            for(i=0;i<topArtists.items.length;i++) {
                searchModel.append({type: 1,
                                    name: topArtists.items[i].name,
                                    following: false,
                                    track: {},
                                    artist: topArtists.items[i]})
                artistIds.push(topArtists.items[i].id)
            }
            // request additional Info
            Spotify.isFollowingArtists(artistIds, function(error, data) {
                if(data)
                    Util.setFollowedInfo(Util.SpotifyItemType.Artist, artistIds, data, searchModel)
            })
        }
    }

    function refresh() {
        var i;

        searchModel.clear()
        topTracks = undefined
        topArtists = undefined

        switch(_itemClass) {
        case 0:
            Spotify.getMyTopTracks({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of TopTracks: " + data.items.length)
                    topTracks = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMyTopTracks")
                loadData()
            })
            break
        case 1:
            Spotify.getMyTopArtists({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of MyTopArtists: " + data.items.length)
                    topArtists = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMyTopArtists")
                loadData()
            })
            break
        }
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

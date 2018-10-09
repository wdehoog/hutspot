/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0

import "../components"
import "../Spotify.js" as Spotify
import "../Util.js" as Util

Page {
    id: artistPage
    objectName: "ArtistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property var currentArtist
    property bool isFollowed: false

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
                title: {
                    switch(_itemClass) {
                    case 0: return Util.createPageHeaderLabel(qsTr("Artist "), qsTr("Albums"), Theme)
                    case 1: return Util.createPageHeaderLabel(qsTr("Artist "), qsTr("Related Artists"), Theme)
                    }
                }
                MenuButton { z: 1} // set z so you can still click the button
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: nextItemClass()
                }
            }

            Image {
                id: imageItem
                source: (currentArtist && currentArtist.images)
                        ? currentArtist.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                       anchors.fill: parent
                       onClicked: app.controller.playContext(currentArtist)
                }
            }

            MetaInfoPanel {
                firstLabelText: currentArtist ? currentArtist.name : qsTr("No Name")
                secondLabelText: {
                    var s = ""
                    if(currentArtist.genres && currentArtist.genres.length > 0)
                        s += Util.createItemsString(currentArtist.genres, "")
                    return s
                }
                thirdLabelText: currentArtist.followers && currentArtist.followers.total > 0
                                ? Util.abbreviateNumber(currentArtist.followers.total) + " " + qsTr("followers")
                                : ""

                isFavorite: isFollowed
                onToggleFavorite: app.toggleFollowArtist(currentArtist, isFollowed, function(followed) {
                    isFollowed = followed
                })
            }

            /*Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }*/
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
                case 0:
                    app.pushPage(Util.HutspotPage.Album, {album: album})
                    break;
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                    break;
                }
            }
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("No Artists found")
            hintText: qsTr("Pull down to reload")
        }

    }

    PanelLoader {
        id: panelLoader
        flickable: listView
    }

    onCurrentArtistChanged: refresh()

    property var artistAlbums
    property var relatedArtists
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
        var i;

        if(artistAlbums) {
            for(i=0;i<artistAlbums.items.length;i++) {
                searchModel.append({type: 0,
                                    name: artistAlbums.items[i].name,
                                    album: artistAlbums.items[i],
                                    following: false,
                                    artist: {}})
            }
            // request additional Info
            Spotify.isFollowingArtists([currentArtist.id], function(error, data) {
                if(data)
                    isFollowed = data[0]
            })
        }

        if(relatedArtists) {
            var artistIds = [currentArtist.id]
            for(i=0;i<relatedArtists.artists.length;i++) {
                searchModel.append({type: 1,
                                    name: relatedArtists.artists[i].name,
                                    album: {},
                                    following: false,
                                    artist: relatedArtists.artists[i]})
                artistIds.push(relatedArtists.artists[i].id)
            }
            // request additional Info
            Spotify.isFollowingArtists(artistIds, function(error, data) {
                if(data) {
                    // first one is the currentArtist
                    isFollowed = data[0]
                    data.shift()
                    Util.setFollowedInfo(Util.SpotifyItemType.Artist, artistIds, data, searchModel)
                }
            })
        }

    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: refresh()
        onLoadPrevious: refresh()
    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        
        artistAlbums = undefined
        relatedArtists = undefined

        switch(_itemClass) {
        case 0:
            Spotify.getArtistAlbums(currentArtist.id,
                                    {offset: cursorHelper.offset, limit: cursorHelper.limit},
                                    function(error, data) {
                if(data) {
                    console.log("number of ArtistAlbums: " + data.items.length)
                    artistAlbums = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else {
                    console.log("No Data for getArtistAlbums")
                }
                loadData()
            })
            break
        case 1:
            Spotify.getArtistRelatedArtists(currentArtist.id,
                                            {offset: cursorHelper.offset, limit: cursorHelper.limit},
                                            function(error, data) {
                if(data) {
                    console.log("number of ArtistRelatedArtists: " + data.artists.length)
                    relatedArtists = data
                    cursorHelper.offset = 0 // no cursor, always 20
                    cursorHelper.total = data.artists.length
                } else {
                    console.log("No Data for getArtistRelatedArtists")
                }
                loadData()
            })
            break
        }
        app.notifyHistoryUri(currentArtist.uri)
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Artist:
                if(currentArtist.id === event.id) {
                    isFollowed = event.isFavorite
                }
                break
            }
        }
    }
}

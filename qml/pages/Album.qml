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
    id: albumPage
    objectName: "AlbumPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false
    property var album
    property var albumArtists
    property bool isAlbumSaved: false

    property int currentIndex: -1

    property string currentTrackId: ""

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
                title: qsTr("Album")
                MenuButton {}
            }

            LoadPullMenus {}
            LoadPushMenus {}

            Image {
                id: imageItem
                source:  (album && album.images)
                         ? album.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                     anchors.fill: parent
                     onClicked: app.controller.playContext(album)
                }
            }

            MetaInfoPanel {
                id: metaLabels
                width: parent.width
                firstLabelText: album.name
                secondLabelText: Util.createItemsString(album.artists, qsTr("no artist known"))
                thirdLabelText: {
                    var s = ""
                    var n = searchModel.count
                    if(album.tracks)
                        n = album.tracks.total
                    else if(album.total_tracks)
                        n = album.total_tracks
                    if(n > 1)
                        s += n + " " + qsTr("tracks")
                    else if(n === 1)
                        s += 1 + " " + qsTr("track")
                    if(album.release_date && album.release_date.length > 0)
                        s += ", " + Util.getYearFromReleaseDate(album.release_date)
                    if(album.genres && album.genres.length > 0)
                        s += ", " + Util.createItemsString(album.genres, "")
                    return s
                }
                onFirstLabelClicked: secondLabelClicked()
                onSecondLabelClicked: app.loadArtist(album.artists)
                onThirdLabelClicked: secondLabelClicked()
                isFavorite: isAlbumSaved
                onToggleFavorite: app.toggleSavedAlbum(album, isAlbumSaved, function(saved) {
                    isAlbumSaved = saved
                })
            }

            Separator {
                width: parent.width
                color: Theme.primaryColor
            }

        }

        delegate: ListItem {
            id: listItem
            width: parent.width - 2*Theme.paddingMedium
            x: Theme.paddingMedium
            contentHeight: Theme.itemSizeExtraSmall

            AlbumTrackListItem {
                id: albumTrackListItem
                dataModel: model
                isFavorite: saved
                onToggleFavorite: app.toggleSavedTrack(model)
            }

            menu: AlbumTrackContextMenu {
                context: album
            }

            onClicked: app.controller.playTrackInContext(track, album)
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count == 0
            text: qsTr("No Albums found")
            hintText: qsTr("Pull down to reload")
        }

    }

    PanelLoader {
        id: panelLoader
        flickable: listView
    }

    onAlbumChanged: refresh()

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: refresh()
        onLoadPrevious: refresh()
    }

    function refresh() {
        //showBusy = true
        searchModel.clear()        

        var options = {offset: cursorHelper.offset, limit: cursorHelper.limit}
        if(app.query_for_market.value)
            options.market = "from_token"
        Spotify.getAlbumTracks(album.id, options, function(error, data) {
            if(data) {
                try {
                    console.log("number of AlbumTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    var trackIds = []
                    for(var i=0;i<data.items.length;i++) {
                        searchModel.append({type: Spotify.ItemType.Track,
                                            name: data.items[i].name,
                                            saved: false,
                                            track: data.items[i]})
                        trackIds.push(data.items[i].id)
                    }
                    // get info about saved tracks
                    Spotify.containsMySavedTracks(trackIds, function(error, data) {
                        if(data) {
                            Util.setSavedInfo(Spotify.ItemType.Track, trackIds, data, searchModel)
                        }
                    })

                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getAlbumTracks")
            }
        })

        var artists = []
        for(var i=0;i<album.artists.length;i++)
            artists.push(album.artists[i].id)
        Spotify.getArtists(artists, {}, function(error, data) {
            if(data)
                albumArtists = data.artists
        })

        Spotify.containsMySavedAlbums([album.id], {}, function(error, data) {
            if(data)
                isAlbumSaved = data[0]
        })

        app.notifyHistoryUri(album.uri)
    }

    Connections {
        target: app
        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Album:
                if(album.id === event.id) {
                    isAlbumSaved = event.isFavorite
                }
                break
            case Util.SpotifyItemType.Track:
                // no way to check if this track is for this album
                // so just try to update
                Util.setSavedInfo(Spotify.ItemType.Track, [event.id], [event.isFavorite], searchModel)
                break
            }
        }
    }
}

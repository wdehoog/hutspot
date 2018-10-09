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
    id: playlistPage
    objectName: "PlaylistPage"

    property string defaultImageSource : "image://theme/icon-l-music"
    property bool showBusy: false

    property var playlist
    property bool isFollowed: false

    property int currentIndex: -1

    // binding to playlist properties does not seem to work
    // (not updated when modified)
    property string playListName: ""
    property string playlistDescription: ""
    property string playlistMetaText: ""

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
                title: qsTr("Playlist")
                MenuButton {}
            }

            Image {
                id: imageItem
                source: (playlist && playlist.images)
                        ? playlist.images[0].url : defaultImageSource
                width: parent.width * 0.75
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
                MouseArea {
                     anchors.fill: parent
                     onClicked: app.controller.playContext(playlist)
                }
            }

            MetaInfoPanel {
                id: metaInfoPanel

                isFavorite: isFollowed

                // unfortunately binding to playlist properties (playlist.name)
                // does not work: the text is not updated when the property changes value
                firstLabelText: playListName
                secondLabelText: playlistDescription
                thirdLabelText: playlistMetaText

                onFirstLabelClicked: secondLabelClicked()
                onSecondLabelClicked: app.editPlaylistDetails(playlist)
                onThirdLabelClicked: secondLabelClicked()

                onToggleFavorite: app.toggleFollowPlaylist(playlist, isFollowed, function(followed) {
                    isFollowed = followed
                })
            }

            Separator {
                width: parent.width
                color: Theme.primaryColor
            }

            Rectangle {
                width: parent.width
                height:Theme.paddingMedium
                opacity: 0
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

            menu: SearchResultContextMenu {
                contextType: Spotify.ItemType.Playlist

                MenuItem {
                    text: qsTr("Remove from Playlist")
                    onClicked: {
                        var idx = index
                        var model = searchModel
                        app.removeFromPlaylist(playlist, track, index+cursorHelper.offset, function(error, data) {
                            if(!error)
                                model.remove(idx, 1)
                        })
                    }
                }

                MenuItem {
                    text: qsTr("Add to another Playlist")
                    onClicked: app.addToPlaylist(track)
                }
            }

            onClicked: app.pushPage(Util.HutspotPage.Album, {album: track.album})
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listView.count === 0
            text: qsTr("No tracks found")
            hintText: qsTr("Pull down to reload")
        }

    }

    PanelLoader {
        id: panelLoader
        flickable: listView
    }

    // when the page is on the stack but not on top a refresh can wait
    property bool _needsRefresh: false

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            if(_needsRefresh) {
                _needsRefresh = false
                refresh()
            }
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

        onPlaylistEvent: {
            if(playlist.id !== event.playlistId)
                return
            switch(event.type) {
            case Util.PlaylistEventType.AddedTrack:
                // in theory it has been added at the end of the list
                // so we could load the info and add it to the model but
                // we schedule a refresh
                if(playlistPage.status === PageStatus.Active)
                    refresh()
                else
                    _needsRefresh = true
                break
            case Util.PlaylistEventType.RemovedTrack:
                Util.removeFromListModel(searchModel, Spotify.ItemType.Track, event.trackId)
                break
            case Util.PlaylistEventType.ChangedDetails:
                refreshDetails()
                break
            }
        }

        onFavoriteEvent: {
            switch(event.type) {
            case Util.SpotifyItemType.Playlist:
                if(playlist.id === event.id) {
                    isFollowed = event.isFavorite
                }
                break
            }
        }
    }

    onPlaylistChanged: refresh()

    // binding firstLabelText to playlist.name will not work since changing
    // playlist.name value does not seem to trigger an update
    function updatePlaylistTexts() {
        playListName = playlist.name
        playlistDescription = playlist.description ? playlist.description : ""
        var s = playlist.tracks.total + " " + qsTr("tracks")
        s += ", " + qsTr("by") + " " + playlist.owner.display_name
        if(playlist.followers && playlist.followers.total > 0)
            s += ", " + Util.abbreviateNumber(playlist.followers.total) + " " + qsTr("followers")
        if(playlist["public"])
            s += ", " +  qsTr("public")
        if(playlist.collaborative)
            s += ", " +  qsTr("collaborative")
        playlistMetaText = s
    }

    function refresh() {
        var i;
        //showBusy = true
        searchModel.clear()        

        app.getPlaylistTracks(playlist.id,
                                  {offset: cursorHelper.offset, limit: cursorHelper.limit},
                                  function(error, data) {
            if(data) {
                //console.log(JSON.stringify(data))
                try {
                    console.log("number of PlaylistTracks: " + data.items.length)
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                    for(i=0;i<data.items.length;i++) {
                        searchModel.append({type: 3,
                                            name: data.items[i].track.name,
                                            track: data.items[i].track})
                    }
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getPlaylistTracks")
            }
        })

        app.isFollowingPlaylist(playlist.id, function(error, data) {
            if(data)
                isFollowed = data[0]
        })

        app.notifyHistoryUri(playlist.uri)

        // description is not send with getUserPlaylists so get it using getPlaylist
        refreshDetails()

        updatePlaylistTexts()
    }

    function refreshDetails() {
        app.getPlaylist(playlist.id, function(error, data) {
            if(data) {
                // update details
                playlist.name = data.name
                playlist.description = data.description
                playlist['public'] = data['public']
                playlist.collaborative = data.collaborative
                updatePlaylistTexts()
            }
        })
    }
}

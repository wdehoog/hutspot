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
    id: myStuffPage
    objectName: "MyStuffPage"

    property int searchInType: 0
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
        anchors.bottom: navPanel.top
        clip: navPanel.expanded

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
                    case 0: return qsTr("My [ Saved Albums ]")
                    case 1: return qsTr("My [ Playlists ]")
                    case 2: return qsTr("My [ Recently Played ]")
                    case 3: return qsTr("My [ Saved Tracks ]")
                    case 4: return qsTr("My [ Followed Artists ]")
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

            menu: SearchResultContextMenu {
                MenuItem {
                    enabled: type === 1 || type === 2
                    visible: enabled
                    text: qsTr("Unfollow")
                    onClicked: {
                        var idx = index
                        var model = searchModel
                        if(type === 1)
                            app.unfollowArtist(artist, function(error,data) {
                               if(!error)
                                   model.remove(idx, 1)
                            })
                        else
                            app.unfollowPlaylist(playlist, function(error,data) {
                               if(!error)
                                   model.remove(idx, 1)
                            })
                    }
                }
            }

            onClicked: {
                switch(type) {
                case 0:
                    app.pushPage(Util.HutspotPage.Album, {album: album})
                    break;
                case 1:
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: artist})
                    break;
                case 2:
                    app.pushPage(Util.HutspotPage.Playlist, {playlist: playlist})
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

    NavigationPanel {
        id: navPanel
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

    Connections {
        target: app

        onDetailsChangedOfPlaylist: {
            // check if the playist is in the current list if so trigger a refresh
            var i = Util.doesListModelContain(searchModel, Spotify.ItemType.Playlist, playlistId)
            if(i >= 0) {
                if(myStuffPage.status === PageStatus.Active)
                    refresh()
                else
                    _needsRefresh = true
            }
        }
        onCreatedPlaylist: {
            if(myStuffPage.status === PageStatus.Active)
                refresh()
            else
                _needsRefresh = true
        }
    }

    property var savedAlbums
    property var userPlaylists
    property var recentlyPlayedTracks
    property var savedTracks
    property var followedArtists
    property int _itemClass: 0

    function nextItemClass() {
        _itemClass++;
        if(_itemClass > 4)
            _itemClass = 0
        refresh()
    }

    function loadData() {
        var i
        if(savedAlbums)
            for(i=0;i<savedAlbums.items.length;i++)
                searchModel.append({type: 0,
                                    stype: 0,
                                    name: savedAlbums.items[i].album.name,
                                    album: savedAlbums.items[i].album,
                                    playlist: {},
                                    track: {},
                                    artist: {}})
        if(userPlaylists)
            for(i=0;i<userPlaylists.items.length;i++) {
                searchModel.append({type: 2,
                                    stype: 2,
                                    name: userPlaylists.items[i].name,
                                    album: {},
                                    playlist: userPlaylists.items[i],
                                    track: {},
                                    artist: {}})
            }
        if(recentlyPlayedTracks)
            for(i=0;i<recentlyPlayedTracks.items.length;i++) {
                searchModel.append({type: 3,
                                    stype: 3,
                                    name: recentlyPlayedTracks.items[i].track.name,
                                    album: {},
                                    playlist: {},
                                    track: recentlyPlayedTracks.items[i].track,
                                    artist: {}})
            }
        if(savedTracks)
            for(i=0;i<savedTracks.items.length;i++) {
                searchModel.append({type: 3,
                                    stype: 4,
                                    name: savedTracks.items[i].track.name,
                                    album: {},
                                    playlist: {},
                                    track: savedTracks.items[i].track,
                                    artist: {}})
            }
        if(followedArtists)
            for(i=0;i<followedArtists.artists.items.length;i++) {
                searchModel.append({type: 1,
                                    stype: 1,
                                    name: followedArtists.artists.items[i].name,
                                    following: true,
                                    album: {},
                                    playlist: {},
                                    track: {},
                                    artist: followedArtists.artists.items[i]})
            }
    }

    property int nextPrevious: 0


    function refresh() {
        var i, options;

        searchModel.clear()
        savedAlbums = undefined
        userPlaylists = undefined
        savedTracks = undefined
        recentlyPlayedTracks = undefined
        followedArtists = undefined

        switch(_itemClass) {
        case 0:
            Spotify.getMySavedAlbums({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedAlbums: " + data.items.length)
                    savedAlbums = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedAlbums")
                loadData()
            })
            break
        case 1:
            Spotify.getUserPlaylists({offset: cursorHelper.offset, limit: cursorHelper.limit},function(error, data) {
                if(data) {
                    console.log("number of playlists: " + data.items.length)
                    userPlaylists = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getUserPlaylists")
                loadData()
            })
            break
        case 2:
            options = {limit: cursorHelper.limit}
            // nextPrevious is reversed here
            //if(nextPrevious < 0 && cursorHelper.after)
            //   options.after = cursorHelper.after
            //else if(nextPrevious > 0 && cursorHelper.before)
            //    options.before = cursorHelper.before
            Spotify.getMyRecentlyPlayedTracks(options, function(error, data) {
                if(data) {
                    console.log("number of RecentlyPlayedTracks: " + data.items.length)
                    recentlyPlayedTracks = data
                    cursorHelper.update([Util.loadCursor(data, Util.CursorType.RecentlyPlayed)])
                } else
                    console.log("No Data for getMyRecentlyPlayedTracks")
                loadData()
            })
            break
        case 3:
            Spotify.getMySavedTracks({offset: cursorHelper.offset, limit: cursorHelper.limit}, function(error, data) {
                if(data) {
                    console.log("number of SavedTracks: " + data.items.length)
                    savedTracks = data
                    cursorHelper.offset = data.offset
                    cursorHelper.total = data.total
                } else
                    console.log("No Data for getMySavedTracks")
                loadData()
            })
            break
        case 4:
            options = {limit: cursorHelper.limit}
            var perform = true
            //if(nextPrevious > 0 && cursorHelper.after)
            //   options.after = cursorHelper.after
            //else if(nextPrevious < 0 && cursorHelper.before)
            //    options.before = cursorHelper.before
            //if(nextPrevious > 0 && cursorHelper.after === null)
            //    perform = false // no more followed artists
            //if(perform) {
                Spotify.getFollowedArtists(options, function(error, data) {
                    if(data) {
                        console.log("number of FollowedArtists: " + data.artists.items.length)
                        followedArtists = data
                        cursorHelper.update([Util.loadCursor(data.artists, Util.CursorType.FollowedArtists)])
                    } else
                        console.log("No Data for getFollowedArtists")
                    loadData()
                })
            //}
            break
        }
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        useHas: true
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

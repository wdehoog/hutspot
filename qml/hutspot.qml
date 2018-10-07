/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 * Copyright (C) 2018 Maciej Janiszewski
 *
 * License: MIT
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.configuration 1.0
import org.hildon.components 1.0

import "Spotify.js" as Spotify
import "Util.js" as Util
import "cover"
import "pages"
import "components"

ApplicationWindow {
    id: app

    property alias controller: spotifyController
    SpotifyController {
        id: spotifyController
    }

    property string connectionText: qsTr("connecting")
    property alias searchLimit: searchLimit

    property alias selected_search_targets: selected_search_targets
    property alias auth_using_browser: auth_using_browser
    property alias start_stop_librespot: start_stop_librespot
    property alias confirm_un_follow_save: confirm_un_follow_save
    property alias navigation_menu_type: navigation_menu_type
    property alias playing_as_attached_page: playing_as_attached_page
    property alias history_store: history_store
    property alias genre_seeds: genre_seeds
    property alias search_history: search_history
    property alias search_history_max_size: search_history_max_size
    property alias query_for_market: query_for_market
    property alias hutspot_queue_playlist_name: hutspot_queue_playlist_name
    property alias deviceId: deviceId
    property alias deviceName: deviceName

    property alias queue: queue
    property alias playingPage: playingPage

    allowedOrientations: defaultAllowedOrientations

    cover: CoverPage {
        id: cover
    }

    Messagebox {
        id: msgBox
    }

    Playing {
        id: playingPage
    }

    /*NavigationMenu {
        id: navigationMenuPage
    }*/

    property int _attachedPage: 0 // 0 for playingPage, 1 for navigationMenuPage

    function showPage(pageName) {
        var page
        switch(pageName) {
        case 'PlayingPage':
            // when not having the Playing page as attached page
            // pop all pages above playing page or add it
            var pPage = pageStack.find(function(page) {
                return page.objectName === "PlayingPage"
            })
            if(pPage !== null)
                pageStack.pop(pPage)
            else
                pageStack.push(playingPage)
            break;
        case 'NewReleasePage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/NewRelease.qml"))
            break;
        case 'MyStuffPage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/MyStuff.qml"))
            break;
        case 'TopStuffPage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/TopStuff.qml"))
            break;
        case 'SearchPage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/Search.qml"))
            break;
        case 'GenreMoodPage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/GenreMood.qml"))
            break;
        case 'HistoryPage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/History.qml"))
            break;
        case 'RecommendedPage':
            pageStack.clear()
            page = pageStack.push(Qt.resolvedUrl("pages/Recommended.qml"))
            break;
        default:
            return
        }
        if(playing_as_attached_page.value)
            pageStack.pushAttached(playingPage)
        firstPage.value = pageName
    }

    function loadFirstPage() {
        var pageUrl = undefined
        switch(firstPage.value) {
        default:
        case "PlayingPage":
            // when not having the Playing page as attached page
            if(!playing_as_attached_page.value)
                pageUrl = Qt.resolvedUrl("pages/Playing.qml")
            else
                pageUrl = Qt.resolvedUrl("pages/MyStuff.qml")
            break;
        case "NewReleasePage":
            pageUrl = Qt.resolvedUrl("pages/NewRelease.qml")
            break;
        case "MyStuffPage":
            pageUrl = Qt.resolvedUrl("pages/MyStuff.qml")
            break;
        case "TopStuffPage":
            pageUrl = Qt.resolvedUrl("pages/TopStuff.qml")
            break;
        case "SearchPage":
            pageUrl = Qt.resolvedUrl("pages/Search.qml")
            break;
        case 'GenreMoodPage':
            pageUrl = Qt.resolvedUrl("pages/GenreMood.qml")
            break;
        case 'HistoryPage':
            pageUrl = Qt.resolvedUrl("pages/History.qml")
            break;
        case 'RecommendedPage':
            pageUrl = Qt.resolvedUrl("pages/Recommended.qml")
            break;
        }
        if(pageUrl !== undefined ) {
            pageStack.replace(Qt.resolvedUrl(pageUrl), {}, PageStackAction.Immediate)
            if(playing_as_attached_page.value)
                pageStack.pushAttached(playingPage)
        }
    }

    // when using menu dialog
    function doSelectedMenuItem(selectedIndex) {
        switch(selectedIndex) {
        case Util.HutspotMenuItem.ShowPlayingPage:
            app.showPage('PlayingPage')
            break
        case Util.HutspotMenuItem.ShowNewReleasePage:
            app.showPage('NewReleasePage')
            break
        case Util.HutspotMenuItem.ShowMyStuffPage:
            app.showPage('MyStuffPage')
            break
        case Util.HutspotMenuItem.ShowTopStuffPage:
            app.showPage('TopStuffPage')
            break
        case Util.HutspotMenuItem.ShowGenreMoodPage:
            app.showPage('GenreMoodPage')
            break
        case Util.HutspotMenuItem.ShowHistoryPage:
            app.showPage('HistoryPage')
            break
        case Util.HutspotMenuItem.ShowRecommendedPage:
            app.showPage('RecommendedPage')
            break
        case Util.HutspotMenuItem.ShowSearchPage:
            app.showPage('SearchPage')
            break
        case Util.HutspotMenuItem.ShowDevicesPage:
            pageStack.push(Qt.resolvedUrl("pages/Devices.qml"))
            break
        case Util.HutspotMenuItem.ShowSettingsPage:
            pageStack.push(Qt.resolvedUrl("pages/Settings.qml"))
            break
        case Util.HutspotMenuItem.ShowAboutPage:
            pageStack.push(Qt.resolvedUrl("pages/About.qml"))
            break;
        }
    }

    //
    // 0: Album, 1: Artist, 2: Playlist
    function pushPage(type, options, fromPlaying) {
        var pageUrl = undefined
        switch(type) {
        case Util.HutspotPage.Album:
            pageUrl = "pages/Album.qml"
            break
        case Util.HutspotPage.Artist:
            pageUrl = "pages/Artist.qml"
            break
        case Util.HutspotPage.Playlist:
            pageUrl = "pages/Playlist.qml"
            break
        case Util.HutspotPage.GenreMoodPlaylist:
            pageUrl = "pages/GenreMoodPlaylist.qml"
            break
        }

        // if the pushPage is called from the Playing page and the Playing page
        // is an attached page we need to go to the parent first
        if(fromPlaying) {
            if(playing_as_attached_page.value)
                pageStack.navigateBack(PageStackAction.Immediate)
        }

        if(pageUrl !== undefined ) {
            pageStack.push(Qt.resolvedUrl(pageUrl), options, PageStackAction.Immediate)
            if(playing_as_attached_page.value)
                pageStack.pushAttached(playingPage)
        }
    }

    function setPlayingAsAttachedPage() {
        pageStack.pushAttached(playingPage)
        _attachedPage = 0
    }

    function setMenuAsAttachedPage() {
        //navigationMenuPage.selectedMenuItem = -1
        //navigationMenuPage._currentIndex = -1
        //pageStack.pushAttached(navigationMenuPage)
        pageStack.pushAttached(Qt.resolvedUrl("pages/NavigationMenu.qml"))
        _attachedPage = 1
    }

    function showErrorMessage(error, text) {
        var msg
        if(error) {
            if(error.hasOwnProperty('status') && error.hasOwnProperty('message'))
                msg = text + ":" + error.status + ":" + error.message
            else
                msg = text + ": " + error
        } else
            msg = text
        msgBox.showMessage(msg, 3000)
    }

    function setDevice(id, name) {

        deviceId.value = id
        deviceName.value = name

        Spotify.transferMyPlayback([id],{}, function(error, data) {
            if(!error) {
                controller.refreshPlaybackState()
            } else
                showErrorMessage(error, qsTr("Transfer Failed"))
        })
    }

    property bool loggedIn: spotify.isLinked()
    onLoggedInChanged: {
        // do we need this? isLinked does not mean we have a valid token
        if(loggedIn) {
            controller.refreshPlaybackState();
        }
    }

    Component.onCompleted: {
        if (!spotify.isLinked()) {
            spotify.doO2Auth(Spotify._scope, auth_using_browser.value)
        } else {
            /*Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            tokenExpireTime = spotify.getExpires()
            var date = new Date(tokenExpireTime*1000)
            console.log("expires on: " + date.toDateString() + " " + date.toTimeString())
            app.connectionText = qsTr("Connected")
            loadUser()
            loggedIn = true*/

            var now = new Date ()
            console.log("Currently it is " + now.toDateString() + " " + now.toTimeString())
            var tokenExpireTime = spotify.getExpires()
            var tokenExpireDate = new Date(tokenExpireTime*1000)
            console.log("Current token expires on: " + tokenExpireDate.toDateString() + " " + tokenExpireDate.toTimeString())
            // do not set the 'global' hasValidToken since we will refresh anyway
            // and that will interfere
            var hasValidToken = tokenExpireDate > now
            console.log("Token is " + hasValidToken ? "still valid" : "expired")

            // with Spotify's stupid short living tokens, we can totally assume
            // it's already expired
            spotify.refreshToken();

            loadFirstPage()
        }

        history = history_store.value
        //serviceBrowser.browse("_spotify-connect._tcp")
    }

    // Librespot must be started after we are logged in (have a valid token)
    // otherwise it is not shown in the devices list
    /*Connections {
        target: librespot
        onServiceEnabledChanged: {
            if(start_stop_librespot.value) {
                if(librespot.serviceEnabled)
                    librespot.start()
            }
        }
    }*/
    onHasValidTokenChanged: {
        if(start_stop_librespot.value) {
            if(librespot.serviceEnabled) {
                if(hasValidToken)
                    librespot.start()
                // ToDo: stop Librespot if the token becomes invalid?
            }
        }
    }

    // thanks to harbour-storeman.qml
    Connections {
        target: __quickWindow
        onClosing: {
            if(start_stop_librespot.value) {
                librespot.stop()
            }
        }
    }

    property int tokenExpireTime: 0 // seconds from epoch
    Timer  {
        // refresh token 10 minutes before expiring
        id: refreshTokenTimer
        interval: 60*1000
        running: tokenExpireTime > 0
        repeat: true
        onTriggered: {
            var diff = tokenExpireTime - (Date.now() / 1000)
            if(diff < (10*60))
                spotify.refreshToken()
        }
    }

    property bool hasValidToken: false

    Connections {
        target: spotify

        onExtraTokensReady: { // (const QVariantMap &extraTokens);
            // extraTokens
            //   scope: ""
            //   token_type: "Bearer"
        }

        onLinkingFailed: {
            console.log("Connections.onLinkingFailed")
            app.connectionText = qsTr("Disconnected")
        }

        onLinkingSucceeded: {
            console.log("Connections.onLinkingSucceeded")
            //console.log("username: " + spotify.getUserName())
            //console.log("token   : " + spotify.getToken())
            Spotify._accessToken = spotify.getToken()
            Spotify._username = spotify.getUserName()
            tokenExpireTime = spotify.getExpires()
            var date = new Date(tokenExpireTime*1000)
            console.log("expires on: " + date.toDateString() + " " + date.toTimeString())
            app.connectionText = qsTr("Connected")
            loadUser()
            loggedIn = true
        }

        onLinkedChanged: {
            console.log("Connections.onLinkingChanged")
        }

        onRefreshFinished: {
            console.log("Connections.onRefreshFinished error code: " + errorCode +", msg: " + errorString)
            if(errorCode !== 0) {
                showErrorMessage(errorString, qsTr("Failed to Refresh Authorization Token"))
            } else {
                console.log("expires: " + tokenExpireTime)
                tokenExpireTime = spotify.getExpires()
                var expDate = new Date(tokenExpireTime*1000)
                console.log("expires on: " + expDate.toDateString() + " " + expDate.toTimeString())
                var now = new Date()
                hasValidToken = expDate > now
            }
        }

        onOpenBrowser: {
            if(auth_using_browser.value)
                Qt.openUrlExternally(url)
            else
                pageStack.push(Qt.resolvedUrl("components/WebAuth.qml"),
                               {url: url, scale: Screen.widthRatio})
        }

        onCloseBrowser: {
            loadFirstPage()
        }
    }

    /*property var foundDevices: []
    signal devicesChanged()
    onDevicesChanged: {
        firstPage.foundDevicesChanged()
    }*/

    /* Service Browser has been disabled since it is unknown how to
       register the discovered device at spotify.
    Connections {
        target: serviceBrowser

        onServiceEntryAdded: {
            var serviceJSON = serviceBrowser.getJSON(service)
            console.log("onServiceEntryAdded: " + serviceJSON)
            try {
              var data = JSON.parse(serviceJSON)
              if(data.protocol === "IPv4") {
                  Util.deviceInfoRequest(data, function(error, data) {
                      if(data) {
                          //console.log(JSON.stringify(data,null,2))
                          // replace or add
                          var replaced = 0
                          for(var i=0;i<foundDevices.length;i++) {
                            if(foundDevices[i].remoteName === data.remoteName) {
                              foundDevices[i] = data
                                replaced = 1
                            }
                          }
                          if(!replaced)
                              foundDevices.push(data)
                          devicesChanged()
                      }
                  })
              }
            } catch (e) {
              console.error(e)
            }
        }

        onServiceEntryRemoved: {
            console.log("onServiceEntryRemoved: " + service)
            // todo remove from foundDevices
            for(var i=0;i<foundDevices.length;i++) {
              if(foundDevices[i].remoteName === data.remoteName) {
                  foundDevices.splice(i, 1)
                  devicesChanged()
                  break
              }
            }
        }
    }*/

    property string id: ""
    property string uri: ""
    property string display_name: ""
    property string product: ""
    property string followers: ""

    function loadUser() {
        Spotify.getMe({}, function(error, data) {
            if(data) {
                try {
                    id = data.id
                    uri = data.uri
                    display_name = data.display_name
                    product = data.product
                    followers = data.followers.total
                } catch (err) {
                    console.log(err)
                }
            } else {
                console.log("No Data for getMe")
            }
        })
        controller.refreshPlaybackState();
    }

    function getPlaylist(playlistId, callback) {
        Spotify.getPlaylist(playlistId, {}, function(error, data) {
            if(callback)
                callback(error, data)
        })
    }

    signal playlistEvent(var event)

    function editPlaylistDetails(playlist, callback) {
        var ms = pageStack.push(Qt.resolvedUrl("components/CreatePlaylist.qml"),
                                {titleText: qsTr("Edit Playlist Details"),
                                 name: playlist.name, description: playlist.description,
                                 publicPL: playlist['public'], collaborative: playlist.collaborative} );
        ms.accepted.connect(function() {
            if(ms.name && ms.name.length > 0) {
                var options = {name: ms.name,
                               'public': ms.publicPL,
                               collaborative: ms.collaborativePL}
                if(ms.description && ms.description.length > 0)
                    options.description = ms.description
                Spotify.changePlaylistDetails(playlist.id, options, function(error, data) {
                    if(callback)
                        callback(error, data)
                    if(!error) {
                        var ev = new Util.PlayListEvent(Util.PlaylistEventType.ChangedDetails,
                                                        playlist.id, playlist.snapshot_id)
                        ev.newDetails = options
                        playlistEvent(ev)
                    }
                })
            }
        })
    }

    function addToPlaylist(track) {

        var ms = pageStack.push(Qt.resolvedUrl("components/PlaylistPicker.qml"),
                                { label: qsTr("Select a Playlist") } );
        ms.accepted.connect(function() {
            if(ms.selectedItem && ms.selectedItem.playlist) {
                Spotify.addTracksToPlaylist(ms.selectedItem.playlist.id,
                                            [track.uri], {}, function(error, data) {
                    if(data) {
                        var ev = new Util.PlayListEvent(Util.PlaylistEventType.AddedTrack,
                                                        ms.selectedItem.playlist.id, data.snapshot_id)
                        ev.trackId = track.id
                        ev.trackUri = track.uri
                        playlistEvent(ev)
                        console.log("addToPlaylist: added \"")
                    } else
                        console.log("addToPlaylist: failed to add \"")
                    console.log(track.name + "\" to \"" + ms.selectedItem.playlist.name + "\"")
                })
            }
        })
    }

    function removeFromPlaylist(playlist, track, position, callback) {
        app.showConfirmDialog(qsTr("Please confirm to remove:<br><br><b>" + track.name + "</b>"),
                              function() {
            // does not work due to Qt. cannot have DELETE request with a body
            /*Spotify.removeTracksFromPlaylist(playlist.id, [track.uri], function(error, data) {
                callback(error, data)
                var ev = new Util.PlayListEvent(Util.PlaylistEventType.RemovedTrack,
                                                playlist.id, data.snapshot_id)
                ev.trackId = track.id
                playlistEvent(ev)
            })*/

            // if the track is 'linked' we must remove the linked_from one
            var uri = track.uri
            if(track.hasOwnProperty('linked_from'))
                uri = track.linked_from.uri
            removeTracksFromPlaylistUsingCurl(playlist.id, playlist.snapshot_id, [uri], [position], function(error, data) {
                if(callback)
                    callback(error, data)
                var ev = new Util.PlayListEvent(Util.PlaylistEventType.RemovedTrack,
                                                playlist.id, data.snapshot_id)
                ev.trackId = track.id
                playlistEvent(ev)
            })
        })
    }

    function createPlaylist(callback) {
        var ms = pageStack.push(Qt.resolvedUrl("components/CreatePlaylist.qml"),
                                {} );
        ms.accepted.connect(function() {
            if(ms.name && ms.name.length > 0) {
                var options = {name: ms.name,
                               'public': ms.publicPL,
                               collaborative: ms.collaborativePL}
                if(ms.description && ms.description.length > 0)
                    options.description = ms.description
                Spotify.createPlaylist(options, function(error, data) {
                    callback(error, data)
                    if(data) {
                        var ev = new Util.PlayListEvent(Util.PlaylistEventType.CreatedPlaylist,
                                                        data.id, data.snapshot_id)
                        ev.playlist = data
                        playlistEvent(ev)
                    }
                })
            }
        })
    }

    function getPlaylistTracks(playlistId, options, callback) {
        if(query_for_market.value) {
            if(!options)
                options = {}
            options.market = "from_token"
        }
        Spotify.getPlaylistTracks(playlistId, options, callback)
    }

    function replaceTracksInPlaylist(playlistId, tracks, callback) {
        Spotify.replaceTracksInPlaylist(playlistId, tracks, function(error, data) {
            if(callback)
                callback(error, data)
            if(data && data.snapshot_id) {
                var ev = new Util.PlayListEvent(Util.PlaylistEventType.ReplacedAllTracks,
                                                playlistId, data.snapshot_id)
                playlistEvent(ev)
                console.log("replaceTracksInPlaylist: snapshot: " + data.snapshot_id)
            } else
                console.log("No Data while replacing tracks in Playlist " + playlistId)
        })
    }

    signal favoriteEvent(var event)

    function isFollowingPlaylist(pid, callback) {
        Spotify.areFollowingPlaylist(pid, [id], function(error, data) {
            callback(error, data)
        })
    }

    function followPlaylist(playlist, callback) {
        Spotify.followPlaylist(playlist.id, function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Playlist, playlist.id, true)
            favoriteEvent(event)
        })
    }

    function _unfollowPlaylist(playlist, callback) {
        Spotify.unfollowPlaylist(playlist.id, function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Playlist, playlist.id, false)
            favoriteEvent(event)
        })
    }

    function unfollowPlaylist(playlist, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to unfollow playlist:<br><br><b>" + playlist.name + "</b>"),
                                  function() {
                _unfollowPlaylist(playlist, callback)
            })
        else
            _unfollowPlaylist(playlist, callback)
    }

    function followArtist(artist, callback) {
        Spotify.followArtists([artist.id], function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Artist, artist.id, true)
            favoriteEvent(event)
        })
    }

    function _unfollowArtist(artist, callback) {
        Spotify.unfollowArtists([artist.id], function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Artist, artist.id, false)
            favoriteEvent(event)
        })
    }

    function unfollowArtist(artist, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to unfollow artist:<br><br><b>" + artist.name + "</b>"),
                                  function() {
                _unfollowArtist(artist, callback)
            })
        else
            _unfollowArtist(artist, callback)
    }

    function saveAlbum(album, callback) {
        var id
        if(album.hasOwnProperty("id"))
            id = album.id
        else
            id = Util.parseSpotifyUri(album.uri).id
        Spotify.addToMySavedAlbums([id], function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Album, album.id, true)
            favoriteEvent(event)
        })
    }

    function _unSaveAlbum(album, callback) {
        Spotify.removeFromMySavedAlbums([album.id], function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Album, album.id, false)
            favoriteEvent(event)
        })
    }

    function unSaveAlbum(album, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to un-save album:<br><br><b>" + album.name + "</b>"),
                                  function() {
                _unSaveAlbum(album, callback)
            })
        else
            _unSaveAlbum(album, callback)
    }

    function saveTrack(track, callback) {
        Spotify.addToMySavedTracks([track.id], function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Track, track.id, true)
            favoriteEvent(event)
        })
    }

    function _unSaveTrack(track, callback) {
        Spotify.removeFromMySavedTracks([track.id], function(error, data) {
            callback(error, data)
            var event = new Util.FavoriteEvent(Util.SpotifyItemType.Track, track.id, false)
            favoriteEvent(event)
        })
    }

    function unSaveTrack(track, callback) {
        if(confirm_un_follow_save.value)
            app.showConfirmDialog(qsTr("Please confirm to un-save track:<br><br><b>" + track.name + "</b>"),
                                  function() {
                _unSaveTrack(track, callback)
            })
        else
            _unSaveTrack(track, callback)
    }

    function toggleSavedTrack(model) {
        if(model.saved)
            unSaveTrack(model.track, function(error,data) {
                if(!error)
                    model.saved = false
            })
        else
            saveTrack(model.track, function(error,data) {
                if(!error)
                    model.saved = true
            })
    }

    function toggleSavedAlbum(album, isAlbumSaved, callback) {
        if(isAlbumSaved)
            unSaveAlbum(album, function(error,data) {
                if(!error)
                    callback(false)
            })
        else
            saveAlbum(album, function(error,data) {
                if(!error)
                    callback(true)
            })
    }

    function toggleFollowArtist(artist, isFollowed, callback) {
        if(isFollowed)
            unfollowArtist(artist, function(error,data) {
                if(!error)
                    callback(false)
            })
        else
            followArtist(artist, function(error,data) {
                if(!error)
                    callback(true)
            })
    }

    function toggleFollowPlaylist(playlist, isFollowed, callback) {
        if(isFollowed)
             unfollowPlaylist(playlist, function(error, data) {
                 if(!error)
                     callback(false)
             })
         else
             followPlaylist(playlist, function(error, data) {
                 if(!error)
                     callback(true)
             })
    }

    function loadArtist(artists, fromPlaying) {
        if(artists.length > 1) {
            // choose
            var ms = pageStack.push(Qt.resolvedUrl("components/ArtistPicker.qml"),
                                    { label: qsTr("View an Artist"), artists: artists } );
            ms.done.connect(function() {
                if(ms.selectedItem) {
                    app.pushPage(Util.HutspotPage.Artist, {currentArtist: ms.selectedItem.artist}, fromPlaying)
                }
            })
        } else if(artists.length === 1) {
            app.pushPage(Util.HutspotPage.Artist, {currentArtist:artists[0]}, fromPlaying)
        }
    }

    QueueController {
        id: queue
    }

    Librespot {
        id: librespot
    }

    function getAppIconSource() {
        return getAppIconSource2(Theme.iconSizeExtraLarge)
    }

    function getAppIconSource2(iconSize) {
        if (iconSize < 108)
            iconSize = 86
        else if (iconSize < 128)
            iconSize = 108
        else if (iconSize < 256)
            iconSize = 128
        else
            iconSize = 256
        return "/usr/share/icons/hicolor/" + iconSize + "x" + iconSize + "/apps/hutspot.png"
    }

    /**
     * can have a 4th param: rejectCallback
     */
    function showConfirmDialog(text, acceptCallback) {
        var dialog = pageStack.push (Qt.resolvedUrl("components/ConfirmDialog.qml"),
                                                   {confirmMessageText: text})
        if(acceptCallback !== null)
            dialog.accepted.connect(acceptCallback)
        if(arguments.length >= 4 && arguments[3] !== null)
            dialog.rejected.connect(arguments[3])
    }

    /**
     * List of last visited albums/artists/playlists
     */
    readonly property int historySize: 50
    property var history: []
    signal historyModified(int added, int removed)
    function notifyHistoryUri(uri) {
        var removedIndex = -1
        if(history.length === 0) {
            history.unshift(uri)
        } else if(history[0] !== uri) {
            // add to the top
            history.unshift(uri)
            // remove if already present
            for(var i=1;i<history.length;i++)
                if(history[i] === uri) {
                    history.splice(i, 1)
                    removedIndex = i - 1 // -1 since the model does not have the new one yet
                    break
                }
        }
        history_store.value = history
        historyModified(0, removedIndex)
        if(history.length > historySize) { // make configurable
            history.pop()
            historyModified(-1, historySize-1)
        }
    }

    function clearHistory() {
        history = []
        history_store.value = history
        historyModified(-1, -1)
    }

    ConfigurationValue {
            id: deviceId
            key: "/hutspot/device_id"
            defaultValue: ""
    }

    ConfigurationValue {
            id: deviceName
            key: "/hutspot/device_name"
            defaultValue: ""
    }

    ConfigurationValue {
        id: searchLimit
        key: "/hutspot/search_limit"
        defaultValue: 20
    }

    ConfigurationValue {
            id: selected_search_targets
            key: "/hutspot/selected_search_targets"
            defaultValue: 0xFFF
    }

    ConfigurationValue {
            id: auth_using_browser
            key: "/hutspot/auth_using_browser"
            defaultValue: false
    }

    ConfigurationValue {
            id: firstPage
            key: "/hutspot/first_page"
            defaultValue: ""
    }

    ConfigurationValue {
            id: start_stop_librespot
            key: "/hutspot/start_stop_librespot"
            defaultValue: true
    }

    ConfigurationValue {
            id: confirm_un_follow_save
            key: "/hutspot/confirm_un_follow_save"
            defaultValue: true
    }

    // 0 for NavigationMenuDialog
    // 1 for NavigationMenu as attacted page
    // 2 for NavigationPanel
    // 3 for panel with controls and hamburger
    ConfigurationValue {
            id: navigation_menu_type
            key: "/hutspot/navigation_menu_type"
            defaultValue: 0
    }

    ConfigurationValue {
            id: playing_as_attached_page
            key: "/hutspot/playing_as_attached_page"
            defaultValue: true
    }

    ConfigurationValue {
            id: history_store
            key: "/hutspot/history"
            defaultValue: []
    }

    ConfigurationValue {
            id: genre_seeds
            key: "/hutspot/genre_seeds"
            defaultValue: []
    }

    ConfigurationValue {
            id: hutspot_queue_playlist_name
            key: "/hutspot/hutspot_queue_playlist_name"
            defaultValue: "Hutspot Queue"
    }

    ConfigurationValue {
        id: search_history
        key: "/hutspot/search_history"
        defaultValue: []
    }

    ConfigurationValue {
        id: search_history_max_size
        key: "/hutspot/search_history_max_size"
        defaultValue: 50
    }

    ConfigurationValue {
            id: query_for_market
            key: "/hutspot/query_for_market"
            defaultValue: true
    }


    /*function updateConfigurationData() {
        if(configuration_data_version.value === currentConfigurationDataVersion)
            return

        if(configuration_data_version.value === 0) {
            // menu type from 0..1 to 0..2
            if(navigation_menu_type.value === 1)
                navigation_menu_type.value = 2
        }

        configuration_data_version.value = currentConfigurationDataVersion
    }

    readonly property int currentConfigurationDataVersion: 2
    ConfigurationValue {
            id: configuration_data_version
            key: "/hutspot/configuration_data_version"
            defaultValue: 0
    }*/

    // QML seems unable to send a http DELETE request with a body.
    // Therefore this is done using curl
    //
    // curl -X DELETE -i -H "Authorization: Bearer {your access token}"
    //      -H "Content-Type: application/json" "https://api.spotify.com/v1/playlists/71m0QB5fUFrnqfnxVerUup/tracks"
    //      --data "{\"tracks\":[{\"uri\": \"spotify:track:4iV5W9uYEdYUVa79Axb7Rh\", \"positions\": [2] },{\"uri\":\"spotify:track:1301WleyT98MSxVHPZCA6M\", \"positions\": [7] }] }"

    // assumes the uris and positions arrays are equal length and 1 uri has 1 position
    function removeTracksFromPlaylistUsingCurl(playlistId, snapshotId, uris, positions, callback) {
        var command = "/usr/bin/curl"
        var args = []
        args.push("-X")
        args.push("DELETE")
        //args.push("-i") // include headers in the output
        args.push("-H")
        args.push("Authorization: Bearer " + Spotify.getAccessToken())
        args.push("-H")
        args.push("Content-Type: application/json")
        args.push(Spotify._baseUri + "/playlists/" + playlistId + "/tracks")
        args.push("--data")

        var data = "{\"tracks\":["
        for(var i=0;i<uris.length;i++) {
            if(i>0)
                data += ","
            data += "{\"uri\":\"" + uris[i] + "\",\"positions\":[" +positions[i]+ "]}"
        }
        //data += "],\"snapshot_id\":\"" + snapshotId + "\"}"
        data += "]}"
        args.push(data)

        process.callback = callback
        process.start(command, args)
    }

    Process {
        id: process

        property var callback: undefined

        workingDirectory: "/home/nemo"

        onError: {
            if(callback !== undefined)
                callback(process.error, undefined)
            console.log("Process.Error: " + process.error)
            callback = undefined
        }

        onFinished: {
            var output = process.readAllStandardOutput()
            console.log("Process.Finished: " + process.exitStatus + ", code: " + process.exitCode)
            console.log(output)
            if(callback !== undefined)
                callback(null, JSON.parse(output))
            callback = undefined
        }
    }
}


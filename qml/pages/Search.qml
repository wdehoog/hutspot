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
    id: searchPage
    objectName: "SearchPage"

    property int searchInType: 0
    property bool showBusy: false
    property string searchString: ""

    property int currentIndex: -1

    property var searchTargets: [qsTr("Albums"), qsTr("Artists"), qsTr("Playlists"), qsTr("Tracks")]
    property int selectedSearchTargetsMask: app.selected_search_targets.value
    property var scMap: []

    allowedOrientations: Orientation.All

    ListModel {
        id: searchModel
    }

    ListModel {
        id: searchHistoryModel
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
            //spacing: Theme.paddingSmall

            PageHeader {
                id: pHeader
                width: parent.width
                title: {
                    switch(_itemClass) {
                    case 0: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Albums"), Theme)
                    case 1: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Artists"), Theme)
                    case 2: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Playlists"), Theme)
                    case 3: return Util.createPageHeaderLabel(qsTr("Search "), qsTr("Tracks"), Theme)
                    default: qsTr("Search")
                    }
                }
                MenuButton { z: 1} // set z so you can still click the button
                MouseArea {
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onClicked: {
                        nextItemClass()
                        refresh()
                    }
                }
            }

            LoadPullMenus {}
            LoadPushMenus {}

            /* What to search for */
            ValueButton {
                id: searchTypes
                property var indexes: []
                width: parent.width

                label: qsTr("Search For")

                ListModel {
                    id: items
                }

                Component.onCompleted: {
                    var c = 0;
                    value = qsTr("None")
                    indexes = []

                    // load possible choices
                    for(var u=0;u<searchTargets.length;u++) {
                        items.append( {id: c, name: searchTargets[u]});
                        scMap[c] = u;
                        c++;
                    }

                    // read the selected
                    value = "";
                    for(var i=0;i<scMap.length;i++) {
                        if(selectedSearchTargetsMask & (0x01 << scMap[i])) {
                            var first = value.length == 0;
                            value = value + (first ? "" : ", ") + items.get(i).name;
                            indexes.push(i);
                        }
                    }
                }

                onClicked: {
                    var ms = pageStack.push(Qt.resolvedUrl("../components/MultiItemPicker.qml"),
                                            { items: items, label: label, indexes: indexes } );
                    ms.accepted.connect(function() {
                        indexes = ms.indexes.sort(function (a, b) { return a - b });
                        selectedSearchTargetsMask = 0;
                        if (indexes.length == 0) {
                            value = qsTr("None");
                        } else {
                            value = "";
                            for(var i=0;i<indexes.length;i++) {
                                value += ((i>0) ? ", " : "") + items.get(indexes[i]).name;
                                selectedSearchTargetsMask |= (0x01 << scMap[indexes[i]]);
                            }
                        }
                        app.selected_search_targets.value = selectedSearchTargetsMask;
                        app.selected_search_targets.sync();
                    })
                }

            }

            SearchFieldWithMenu {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Search text")
                Binding {
                    target: searchPage
                    property: "searchString"
                    value: searchField.text.toLowerCase().trim()
                }
                EnterKey.enabled: text.length > 0
                EnterKey.onClicked: {
                    refresh()
                    Util.updateSearchHistory(searchField.text.trim(),
                                             app.search_history,
                                             app.search_history_max_size.value)
                }
                EnterKey.iconSource: "image://theme/icon-m-search"
                Component.onCompleted: searchField.forceActiveFocus()

                menu: ContextMenu {
                    onActiveChanged: {
                        if(!active) {
                            // somehow the menu is opened by scrolling up. very annoying.
                            // and also causing the button to become too close to the 'next page' bulb
                            // so if the menu closes scroll back to the top
                            listView.positionViewAtBeginning()
                        }
                    }

                    MenuItem {
                        text: qsTr("Clear")
                        onClicked: {
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                    }
                    MenuItem {
                        text: qsTr("Select Recently used")
                        onClicked: {
                            searchHistoryModel.clear()
                            var sh = app.search_history.value
                            for(var i=0;i<sh.length;i++)
                                searchHistoryModel.append({id: i, name: sh[i]})
                            var ms = pageStack.push(Qt.resolvedUrl("../components/ItemPicker.qml"),
                                                    {items: searchHistoryModel, label: qsTr("Search History")} );
                            ms.accepted.connect(function() {
                                if(ms.selectedIndex === -1)
                                    return
                                searchField.text = ms.items.get(ms.selectedIndex).name
                                searchField.forceActiveFocus()
                                refresh()
                                Util.updateSearchHistory(searchField.text.trim(),
                                                         app.search_history,
                                                         app.search_history_max_size.value)                            })
                                listView.positionViewAtBeginning() // see above
                        }
                    }
                    MenuItem {
                        text: qsTr("Clear Recently used")
                        onClicked: {
                            app.showConfirmDialog(qsTr("Please confirm Clearing the Search History"), function() {
                                app.search_history.value = []
                            })
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingMedium
                opacity: 0
            }
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
        }
    }

    PanelLoader {
        id: panelLoader
        flickable: listView
    }

    property alias cursorHelper: cursorHelper

    CursorHelper {
        id: cursorHelper

        onLoadNext: refresh()
        onLoadPrevious: refresh()
    }

    property int _itemClass: -1

    function nextItemClass() {
        if(selectedSearchTargetsMask === 0) {
            _itemClass = -1
            return
        }
        var i = _itemClass // use i to not trigger stuff while iterating
        do {
            i++
            if(i > 3)
                i = 0
        } while((selectedSearchTargetsMask & (0x01 << i)) === 0)
        _itemClass = i
    }

    function refresh() {
        var i;
        if(searchString === "")
            return
        if(selectedSearchTargetsMask === 0)
            return
        if(_itemClass === -1)
            nextItemClass()
        showBusy = true
        searchModel.clear()
        var types = []
        if(_itemClass === 0)
            types.push('album')
        else if(_itemClass === 1)
            types.push('artist')
        else if(_itemClass === 2)
            types.push('playlist')
        else if(_itemClass === 3)
            types.push('track')

        var options = {offset: cursorHelper.offset, limit: cursorHelper.limit}
        if(app.query_for_market.value)
            options.market = "from_token"
        Spotify.search(Util.processSearchString(searchString), types, options, function(error, data) {
            if(data) {
                var artistIds = []
                try {
                    // albums
                    if(data.hasOwnProperty('albums')) {
                        for(i=0;i<data.albums.items.length;i++) {
                            searchModel.append({type: 0,
                                                name: data.albums.items[i].name,
                                                album: data.albums.items[i],
                                                following: false,
                                                artist: {},
                                                playlist: {},
                                                track: {}})
                        }
                        cursorHelper.offset = data.albums.offset
                        cursorHelper.total = data.albums.total
                    }

                    // artists
                    if(data.hasOwnProperty('artists')) {
                        for(i=0;i<data.artists.items.length;i++) {
                            searchModel.append({type: 1,
                                                name: data.artists.items[i].name,
                                                following: false,
                                                album: {},
                                                artist: data.artists.items[i],
                                                playlist: {},
                                                track: {}})
                            artistIds.push(data.artists.items[i].id)
                        }
                        cursorHelper.offset = data.artists.offset
                        cursorHelper.total = data.artists.total

                        // request additional Info
                        Spotify.isFollowingArtists(artistIds, function(error, data) {
                            if(data) {
                                Util.setFollowedInfo(Util.SpotifyItemType.Artist, artistIds, data, searchModel)
                            }
                        })
                    }

                    // playlists
                    if(data.hasOwnProperty('playlists')) {
                        for(i=0;i<data.playlists.items.length;i++) {
                            searchModel.append({type: 2,
                                                name: data.playlists.items[i].name,
                                                album: {},
                                                following: false,
                                                artist: {},
                                                playlist: data.playlists.items[i],
                                                track: {}})
                        }
                        cursorHelper.offset = data.playlists.offset
                        cursorHelper.total = data.playlists.total
                    }

                    // tracks
                    if(data.hasOwnProperty('tracks')) {
                        for(i=0;i<data.tracks.items.length;i++) {
                            searchModel.append({type: 3,
                                                name: data.tracks.items[i].name,
                                                album: {},
                                                following: false,
                                                artist: {},
                                                playlist: {},
                                                track: data.tracks.items[i]})
                        }
                        cursorHelper.offset = data.tracks.offset
                        cursorHelper.total = data.tracks.total
                    }

                } catch (err) {
                    console.log("Search.refresh error: " + err)
                }
            } else {
                console.log("Search for: " + searchString + " returned no results.")
            }
            // unfortunately Spotify does not return an error when it has an invalid query
            if(error)
                app.showErrorMessage(error, qsTr("Search Failed"))
            showBusy = false
        })
    }

}

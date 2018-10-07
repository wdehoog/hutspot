/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Loader {

    property var listView
    property var itemTop: _hasItem ? item.top : listView.parent.bottom
    property bool itemExpanded: _hasItem ? item.expanded : false

    property bool _hasItem: false

    width: parent.width

    source: {
        switch(app.navigation_menu_type.value) {
        case 2: return "NavigationPanel.qml"
        case 3: return "ControlPanel.qml"
        default: return ""
        }
    }

    onStatusChanged: {
        if(status === Loader.Null || status === Loader.Error)
            _hasItem = false
    }

    onLoaded: {
        if(app.navigation_menu_type.value === 3) {
            panelLoader.item.parent = listView.parent
            panelLoader.item.flickable = listView
        }
        _hasItem = app.navigation_menu_type.value === 2
                   || app.navigation_menu_type.value === 3
    }

}

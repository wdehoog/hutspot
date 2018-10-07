/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Loader {

    property var listView

    width: parent.width

    source: {
        switch(app.navigation_menu_type.value) {
        case 2: return "NavigationPanel.qml"
        case 3: return "ControlPanel.qml"
        default: return ""
        }
    }

    onLoaded: {
        if(app.navigation_menu_type.value === 3) {
            panelLoader.item.parent = parent
            panelLoader.item.flickable = listView
            listView.anchors.bottom = panelLoader.item.top
        }
    }

}

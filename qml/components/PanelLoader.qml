/**
 * Copyright (C) 2018 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: panel

    property SilicaListView flickable: undefined

    property real itemHeight: 0

    property bool open: true

    width: parent.width
    height: itemHeight

    Item {
        width: parent.width
        height: itemHeight
        y: 0
        Loader {
            id: loader
            width: parent.width
            height: parent.height

            source: {
                switch(app.navigation_menu_type.value) {
                case 2: return "NavigationPanel.qml"
                case 3: return "ControlPanel.qml"
                default: return ""
                }
            }
            onLoaded: {
                itemHeight = item.implicitHeight
            }
        }
    }

    // copied from VerticalScrollDecorator
    property bool _inBounds: flickable
                             && (!flickable.pullDownMenu || !flickable.pullDownMenu.active)
                             && (!flickable.pushUpMenu || !flickable.pushUpMenu.active)

    property bool _ignoreYChange: false

    Connections {
        target: flickable
        onContentYChanged: {
            if(_ignoreYChange)
                return
            open = false
            noScrollDetect.restart()
            var lastPart = flickable.contentHeight - flickable.contentY + flickable.originY
            console.log("overshoot lastPart: " + lastPart + ", atYEnd: " + flickable.atYEnd + ", originY: " + flickable.originY + ", contentY: " + flickable.contentY + ", contentHeight: " + flickable.contentHeight)
        }
    }

    Timer {
        id: noScrollDetect
        interval: 300
        repeat: false
        onTriggered: {
            if(_inBounds)
                open = true
            else
                restart()
        }
    }

    states: [
        State {
            name: "shown"
            when: open
            PropertyChanges { target: panel; height: itemHeight }
            //PropertyChanges { target: flickable; height: flickable.parent.height - itemHeight }
        },
        State {
            name: "hidden"
            when: !open
            PropertyChanges { target: panel; height: 0 }
            //PropertyChanges { target: flickable; height: parent.height }
        }
    ]

    onEndOpenDetectedChanged: {
        // the last item can be hidden under the panel and becomes unreachable
        // if it is the move the list up
        if(endOpenDetected && flickable) {
            if(flickable.contentY <= 0) // otherwise we can never show the top
                return
            var lastPart = flickable.contentHeight - flickable.contentY + flickable.originY
            console.log("lastPart: " + lastPart + ", atYEnd: " + flickable.atYEnd + ", originY: " + flickable.originY + ", contentY: " + flickable.contentY + ", contentHeight: " + flickable.contentHeight)
            if(lastPart <= flickable.parent.height) {
                _ignoreYChange = true
                flickable.contentY += height
                _ignoreYChange = false
            }
        }
    }

    property bool endOpenDetected: false

    transitions: [
        Transition {
            from: "shown"; to: "hidden"
            SequentialAnimation {
                NumberAnimation { property: "height"; duration: 500; easing.type: Easing.InOutQuad }
                PropertyAction { target: panel; property: "endOpenDetected"; value: false} // to detect end of animations
            }
        },
        Transition {
            from: "hidden"; to: "shown"
            SequentialAnimation {
                NumberAnimation { property: "height"; duration: 500; easing.type: Easing.InOutQuad }
                PropertyAction { target: panel; property: "endOpenDetected"; value: true} // to detect end of animations
            }
        }
    ]

    /*Transition {
        id: ft
        NumberAnimation { property: "height"; duration: 500; easing.type: Easing.InOutQuad }
    }
    onFlickableChanged: {
        if(!flickable)
            return
        flickable.transitions = [ft]
    }*/

    /*Behavior on height {
        //id: verticalBehavior
        //enabled: !mouseArea.drag.active && !panel._immediate
        NumberAnimation {
            //id: verticalAnimation
            duration: 500
            //easing.type: Easing.OutQuad
        }
    }*/

    PanelBackground {
        z: -1
        anchors.centerIn: parent
        transformOrigin: Item.Center
        width: isPortrait ? parent.width : parent.height
        height: isPortrait ? parent.height : parent.width
    }
}

//DockedPanel {

//    property SilicaListView flickable: undefined

//    width: parent.width
//    height: Theme.itemSizeLarge
//    dock: Dock.Bottom
//    open: false
//    modal: false
//    //opacity: 1.0

//    Loader {
//        id: loader
//        width: parent.width
//        height: parent.height

//        source: {
//            switch(app.navigation_menu_type.value) {
//            case 2: return "NavigationPanel.qml"
//            case 3: return "ControlPanel.qml"
//            default: return ""
//            }
//        }

//        /*onLoaded: {
//            if(app.navigation_menu_type.value === 3) {
//                //item.flickable = flickable
//            }
//        }*/
//    }

//    /*property real _prevY: 0
//    onYChanged: {
//        if(flickable && moving) {
//            console.log("onYChanged from: " + _prevY +" to " + y + ", visibleSize: " + visibleSize)
//            console.log("  flickable.contentY: " + flickable.contentY + ", flickable.contentHeight: " + flickable.contentHeight + ", flickable.y: " + flickable.y + ", flickable.bottomMargin: " + flickable.bottomMargin)
//            //flickable.contentY -= (y - _prevY)
//        }
//        _prevY = y
//    }*/

//    Connections {
//        target: flickable
//        onContentXChanged: {
//            // hide(true)
//            open = false

//            //flickable.anchors.bottomMargin = 0

//            //flickable.anchors.bottom = flickable.parent.bottom
//            //z = flickable.z - 1
//            //opacity = 0

//            noScrollDetect.restart()
//        }
//        onContentYChanged: {
//            // hide(true)
//            open = false

//            //flickable.anchors.bottomMargin = 0

//            //flickable.anchors.bottom = flickable.parent.bottom
//            //opacity = 0
//            //z = flickable.z - 1

//            noScrollDetect.restart()
//        }
//    }

//    Timer {
//        id: noScrollDetect
//        interval: 300
//        repeat: false

//        onTriggered: {
//            //show(true)
//            /*if(flickable) {
//                flickable.anchors.bottomMargin = Theme.itemSizeLarge //panelLoader.height
//                flickable.clip = true
//            }*/
//            //    flickable.anchors.bottomMargin = panelLoader.visibleSize
//            open = true
//            //flickable.anchors.bottomMargin = height

//            //z = flickable.z + 1
//            //opacity = 1.0
//            //flickable.anchors.bottom = top
//        }
//     }

//    onOpenChanged: {
//        if(!open) {
//            //flickable.anchors.bottomMargin = 0
//            //flickable.clip = false
//            //modal = false
//            hide(true)
//        }
//    }

//}

//Item {
//    id: item

//    property var listView

//    property var itemTop: {
//        switch(app.navigation_menu_type.value) {
//        case 2: return navigationPanel.top
//        case 3: return controlPanel.top
//        default: return parent.bottom
//        }
//    }

//    property bool itemExpanded: {
//        switch(app.navigation_menu_type.value) {
//        case 2: return navigationPanel.expanded
//        case 3: return controlPanel.expanded
//        default: return false
//        }
//    }

//    NavigationPanel {
//        id: navigationPanel
//        parent: item.parent
//        enabled: app.navigation_menu_type.value === 2
//        visible: enabled
//    }

//    ControlPanel {
//        id: controlPanel
//        parent: item.parent
//        enabled: app.navigation_menu_type.value === 3
//        visible: enabled
//        flickable: item.listView
//    }
//}

//Loader {
//    id: loader

//    property var listView
//    property var itemTop: top
//    property bool itemExpanded: _hasItem ? item.expanded : false
//    property bool _hasItem: false

//    /*on_HasItemChanged: {
//        console.log("on_HasItemChanged new value: " + _hasItem
//                                   + ", item.top: " + item.top)
//    }*/

//    width: parent.width

//    source: {
//        switch(app.navigation_menu_type.value) {
//        case 2: return "NavigationPanel.qml"
//        case 3: return "ControlPanel.qml"
//        default: return ""
//        }
//    }

//    onStatusChanged: {
//        if(status === Loader.Null || status === Loader.Error)
//            _hasItem = false
//    }

//    onLoaded: {
//        if(app.navigation_menu_type.value === 3) {
//            item.parent = listView.parent
//            item.flickable = listView
//        }
//        loader.anchors.top = item.top
//        loader.height = item.height
//        _hasItem = true
//    }

//    /*Connections {
//        target: loader.item
//        onYChanged: listView.anchors.bottom = loader.itemTop
//        onExpandedChanged: listView.clip = loader.item.expanded
//    }*/
//}

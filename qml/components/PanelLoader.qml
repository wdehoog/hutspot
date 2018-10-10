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
            // programmatically scrolling
            if(_ignoreYChange)
                return
            // if last item is just above panel
            if(!_inBounds || flickable.atYEnd)
                return
            open = false
            noScrollDetect.restart()
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
        },
        State {
            name: "hidden"
            when: !open
            PropertyChanges { target: panel; height: 0 }
        }
    ]

    onEndOpenDetectedChanged: {
        // the last item can be hidden under the panel and becomes unreachable
        // if it is the move the list up
        if(endOpenDetected && flickable) {
            if(flickable.contentY <= 0) // otherwise we can never show the top
                return
            var lastPart = flickable.contentHeight - flickable.contentY + flickable.originY
            //console.log("lastPart: " + lastPart + ", atYEnd: " + flickable.atYEnd + ", originY: " + flickable.originY + ", contentY: " + flickable.contentY + ", contentHeight: " + flickable.contentHeight)
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

    PanelBackground {
        z: -1
        anchors.centerIn: parent
        transformOrigin: Item.Center
        width: isPortrait ? parent.width : parent.height
        height: isPortrait ? parent.height : parent.width
    }
}

import QtQuick 2.0
import Sailfish.Silica 1.0

DockedPanel {

    property SilicaListView flickable: undefined
    property string defaultImageSource : "image://theme/icon-l-music"

    width: parent.width
    height: Theme.itemSizeLarge
    dock: Dock.Bottom
    open: false
    modal: false
    opacity: 1.0

    Row {
        id: row
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        property real itemWidth : width / 5

        // album art
        Image {
            id: imageItem
            anchors.verticalCenter: parent.verticalCenter
            source: app.controller.getCoverArt(defaultImageSource, true)
            width: row.itemWidth
            height: width
            fillMode: Image.PreserveAspectFit
            //onPaintedHeightChanged: height = Math.min(parent.width, paintedHeight)
        }

        Row {
            id: playerButtons
            width: row.itemWidth * 3
            anchors.verticalCenter: parent.verticalCenter
            // player controls
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                //width: buttonRow.itemWidth
                // enabled: app.mprisPlayer.canGoPrevious
                icon.source: "image://theme/icon-m-previous"
                onClicked: app.controller.previous()
            }
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                //width: buttonRow.itemWidth
                icon.source: app.controller.playbackState.is_playing
                             ? "image://theme/icon-l-pause"
                             : "image://theme/icon-l-play"
                onClicked: app.controller.playPause()
            }
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                //width: buttonRow.itemWidth
                // enabled: app.mprisPlayer.canGoNext
                icon.source: "image://theme/icon-m-next"
                onClicked: app.controller.next()
            }
        }

        // menu
        IconButton {
            width: row.itemWidth
            anchors.verticalCenter: parent.verticalCenter
            //anchors.right: parent.right
            icon.source: "image://theme/icon-m-menu"
            onClicked: {
                var dialog = pageStack.push(Qt.resolvedUrl("NavigationMenuDialog.qml")) //, {}, PageStackAction.Immediate)
                dialog.done.connect(function() {
                    if(dialog.selectedMenuItem > -1)
                        app.doSelectedMenuItem(dialog.selectedMenuItem)
                })
            }
        }

    }

    Connections {
        target: flickable
        onContentXChanged: {
            open = false
            noScrollDetect.restart()
        }
        onContentYChanged: {
            open = false
            noScrollDetect.restart()
        }
    }


    Timer {
        id: noScrollDetect
        interval: 300
        repeat: false

        onTriggered: {
            open = true
        }
     }

    onOpenChanged: {
        if(!open) {
            modal = false
        }
    }

}


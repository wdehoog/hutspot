import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem
{
    id: messagebox
    z: 20
    visible: messageboxVisibility.running
    height: Theme.itemSizeSmall + Theme.paddingSmall
    anchors.centerIn: parent
    onClicked: messageboxVisibility.stop()

    Rectangle
    {
        height: Theme.paddingSmall
        width: parent.width
        color: Theme.highlightBackgroundColor
    }

    Rectangle
    {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    function showMessage(message, delay)
    {
        messageboxText.text = message
        messageboxVisibility.interval = (delay>0) ? delay : 3000
        messageboxVisibility.restart()
    }

    TextArea {
        id: messageboxText
        color: Theme.primaryColor
        text: ""
        readOnly: true
        wrapMode: Text.Wrap
        anchors.centerIn: parent
    }

    Timer
    {
        id: messageboxVisibility
        interval: 3000
    }
}

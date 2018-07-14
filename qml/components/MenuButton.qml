import QtQuick 2.2
import Sailfish.Silica 1.0

IconButton {
    id: menuIcon
    width: icon.width
    height: icon.height

    x: Theme.paddingMedium
    y: Theme.paddingLarge*1.5
    icon.height: Theme.iconSizeSmall
    icon.fillMode: Image.PreserveAspectFit
    icon.source: "image://hutspot-icons/icon-m-toolbar"

               /*"image://theme/icon-m-menu" navPanel.expanded
                 ? "image://theme/icon-m-down"
                 : "image://theme/icon-m-up"*/
    onClicked: {
        if(!navPanel.modal) {
            navPanel.open = true
            navPanel.modal = true
        }
    }
}

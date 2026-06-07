import QtQuick

Rectangle {
    width: 400
    height: 400
    
    Item {
        id: container
        x: 100
        y: 100
        width: 100
        height: 100
        
        Rectangle {
            id: item
            width: 100
            height: 100
            color: "red"
            
            states: State {
                name: "reparented"
                ParentChange {
                    target: item
                    parent: parent.parent // the root
                    x: item.mapToItem(parent.parent, 0, 0).x
                    y: item.mapToItem(parent.parent, 0, 0).y
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: item.state = "reparented"
            }
        }
    }
}

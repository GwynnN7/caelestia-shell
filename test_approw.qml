import QtQuick
import QtQuick.Layouts

Item {
    width: 400; height: 400
    property var vars: {"terminal": "hello"}
    property var defaults: {"terminal": "world"}
    
    component MyText: Text {
        property string varKey
        text: root.vars[varKey] !== undefined ? String(root.vars[varKey]) : (root.defaults[varKey] !== undefined ? String(root.defaults[varKey]) : "")
    }

    MyText {
        id: root
        varKey: "terminal"
    }
}

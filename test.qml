import QtQuick

Item {
    ListModel {
        id: model
    }
    Component.onCompleted: {
        var obj1 = Qt.createQmlObject('import QtQuick; QtObject {}', model);
        model.append({
            "id": "test",
            "toplevels": [obj1]
        });
        console.log(model.get(0).toplevels.get(0));
        Qt.quit();
    }
}

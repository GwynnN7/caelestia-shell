let apps = [{id: "A"}, {id: "B"}, {id: "D"}];
let dockModel = [{appId: "A"}, {appId: "B"}, {appId: "C"}, {appId: "D"}];

// mock dockModel interface
let m = {
    get count() { return dockModel.length; },
    get: i => dockModel[i],
    remove: i => dockModel.splice(i, 1),
    append: obj => dockModel.push(obj),
    move: (from, to) => {
        let item = dockModel.splice(from, 1)[0];
        dockModel.splice(to, 0, item);
    }
};

let orderChanged = false;
if (apps.length !== m.count) {
    orderChanged = true;
} else {
    for (let i = 0; i < apps.length; i++) {
        if (apps[i].id !== m.get(i).appId) {
            orderChanged = true; break;
        }
    }
}

if (orderChanged) {
    for (let i = m.count - 1; i >= 0; i--) {
        let found = false;
        for (let j = 0; j < apps.length; j++) {
            if (apps[j].id === m.get(i).appId) { found = true; break; }
        }
        if (!found) m.remove(i);
    }
    
    for (let i = 0; i < apps.length; i++) {
        let found = false;
        for (let j = 0; j < m.count; j++) {
            if (m.get(j).appId === apps[i].id) { found = true; break; }
        }
        if (!found) m.append({ appId: apps[i].id });
    }
    
    for (let i = 0; i < apps.length; i++) {
        let currentId = apps[i].id;
        if (m.get(i).appId !== currentId) {
            let foundIdx = -1;
            for (let j = i + 1; j < m.count; j++) {
                if (m.get(j).appId === currentId) { foundIdx = j; break; }
            }
            if (foundIdx !== -1) m.move(foundIdx, i);
        }
    }
}

console.log(dockModel.map(x => x.appId).join(", "));

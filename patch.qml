    component BoolRow : ToggleRow {
        property string varKey
        checked: root.vars[varKey] === true
        onToggled: root.saveVar(varKey, checked)
    }

(function () {
const MenuTplDefault =
    '<div id="menu_{{_namespace}}_{{_name}}" class="menu{{#align}} align-{{align}}{{/align}}">' +
    '<div class="head"><span>{{{title}}}</span></div>' +
    '<div class="menu-items">' +
    "{{#elements}}" +
    '<div class="menu-item {{#selected}}selected{{/selected}}">' +
    "{{{label}}}{{#isSlider}} : &lt;{{{sliderLabel}}}&gt;{{/isSlider}}" +
    "</div>" +
    "{{/elements}}" +
    "</div>" +
    "</div>";


    const MenuTplDialog =
        '<div id="menu_{{_namespace}}_{{_name}}" class="dialog {{#isBig}}big{{/isBig}}">' +
        '<div class="head"><span>{{title}}</span></div>' +
        '{{#isDefault}}<input type="text" name="value" class="inputText"/>{{/isDefault}}' +
        '{{#isBig}}<textarea name="value"/>{{/isBig}}' +
        '<button type="button" name="submit">Submit</button>' +
        '<button type="button" name="cancel">Cancel</button>' +
        "</div>";

    window.STANDALONE_UI = {
        ResourceName: "smx-core",
        opened: {},
        focus: [],
        pos: {},
        refreshSelection: function (namespace, name) {
            const menu = this.opened[namespace][name];
            const pos = this.pos[namespace][name];
    
            menu.elements.forEach((el, i) => {
                el.selected = i === pos;
            });
    
            this.change(namespace, name, menu.elements[pos]);
            this.render();
        },    
        open: function (namespace, name, data) {
            if (!data) return;

            if (!this.opened[namespace]) this.opened[namespace] = {};
            if (this.opened[namespace][name]) this.close(namespace, name);
            if (!this.pos[namespace]) this.pos[namespace] = {};

            data._index = this.focus.length;
            data._namespace = namespace;
            data._name = name;

            this.opened[namespace][name] = data;
            this.pos[namespace][name] = 0;

            if (data.elements && Array.isArray(data.elements)) {
                for (let i = 0; i < data.elements.length; i++) {
                    data.elements[i]._namespace = namespace;
                    data.elements[i]._name = name;
                    data.elements[i].selected = !!data.elements[i].selected;
                    if (data.elements[i].selected) {
                        this.pos[namespace][name] = i;
                    }
                }
            }

            this.focus.push({ namespace, name });

            $(document).off("keyup").on("keyup", (e) => {
                const focused = this.getFocused();
                if (!focused) return;
                const menu = this.opened[focused.namespace][focused.name];
                if (!menu) return;
                if (e.which === 13) this.submit(focused.namespace, focused.name, menu);
                if (e.which === 27) this.cancel(focused.namespace, focused.name, menu);
            });

            this.render();
        },

        close: function (namespace, name) {
            delete this.opened[namespace][name];
            this.focus = this.focus.filter(f => f.namespace !== namespace || f.name !== name);
            this.render();
        },

        render: function () {
            const container = $("#menus")[0];
            container.innerHTML = "";
            $(container).hide();

            for (let namespace in this.opened) {
                for (let name in this.opened[namespace]) {
                    const menuData = this.opened[namespace][name];
                    if (!menuData) continue;

                    let view = JSON.parse(JSON.stringify(menuData));
                    let tpl = "";

                    if (menuData.elements && Array.isArray(menuData.elements)) {
                        // default menu
                        tpl = MenuTplDefault;
                        view.elements.forEach((el, i) => {
                            if (el.type === "slider") {
                                el.isSlider = true;
                                el.sliderLabel = (typeof el.options !== "undefined") ? el.options[el.value] : el.value;
                            }
                            if (i === this.pos[namespace][name]) el.selected = true;
                        });
                    } else {
                        // dialog menu
                        tpl = MenuTplDialog;
                        view.isDefault = view.type === "default";
                        view.isBig = view.type === "big";
                    }

                    let menu = $(Mustache.render(tpl, view))[0];
                    $(menu).css("z-index", 1000 + view._index);

                    if (menuData.elements) {
                        // default-type
                        $(menu).hide();
                        container.appendChild(menu);
                        let focused = this.getFocused();
                        if (focused) {
                            $("#menu_" + focused.namespace + "_" + focused.name).show();
                        }
                    } else {
                        // dialog-type
                        $(menu).find('button[name="submit"]').click(() => this.submit(namespace, name, menuData));
                        $(menu).find('button[name="cancel"]').click(() => this.cancel(namespace, name, menuData));
                        $(menu).find('[name="value"]').on("input propertychange", () => {
                            menuData.value = $(menu).find('[name="value"]').val();
                            this.change(namespace, name, menuData);
                        });
                        if (typeof menuData.value !== "undefined") {
                            $(menu).find('[name="value"]').val(menuData.value);
                        }
                        container.appendChild(menu);
                        setTimeout(() => $(menu).find('[name="value"]').focus(), 100);
                    }
                }
            }

            $(container).show();
        },

        submit: function (namespace, name, data) {
            this.post("menu_submit", {
                _namespace: namespace,
                _name: name,
                current: data,
                elements: (this.opened[namespace][name] || {}).elements,
                value: data.value,
            });
        },

        cancel: function (namespace, name, data) {
            this.post("menu_cancel", {
                _namespace: namespace,
                _name: name,
            });
        },

        change: function (namespace, name, data) {
            this.post("menu_change", {
                _namespace: namespace,
                _name: name,
                current: data,
                elements: (this.opened[namespace][name] || {}).elements,
            });
        },

        post: function (action, data) {
            fetch(`https://${this.ResourceName}/${action}`, {
                method: "POST",
                headers: { "Content-Type": "application/json; charset=UTF-8" },
                body: JSON.stringify(data)
            }).catch(err => console.error(`[UI] POST error: ${err}`));
        },

        getFocused: function () {
            return this.focus[this.focus.length - 1];
        },
    };
function showNotify(data) {
    const notify = document.createElement("div");
    const type = data.type || "default";
    const position = data.position || "top-right"; // <-- Standard-Position
    
    notify.classList.add("notification", type);

    notify.innerHTML = `
      <div class="icon-box"></div>
      <div class="text-box">
        <strong>${data.title || "Benachrichtigung"}</strong>
        <div>${data.text || ""}</div>
      </div>
      <div class="progress-bar"></div>
    `;

    const container = document.getElementById("notifications");
    container.className = position; // <-- setzt die Klasse dynamisch
    container.appendChild(notify);

    const duration = data.time || 5000;
    const bar = notify.querySelector(".progress-bar");

    bar.style.animation = `shrink ${duration}ms linear forwards`;

    setTimeout(() => {
        notify.classList.add("fadeout");
        setTimeout(() => {
            notify.remove();
        }, 500);
    }, duration);
}

      
function showHelpUI(data) {
    const help = document.createElement("div");
    help.classList.add("help-hint");
    help.innerHTML = `<div class="key">${data.key}</div><div class="label">${data.text}</div>`;

    document.body.appendChild(help);

    setTimeout(() => {
        help.classList.add("fadeout");
        setTimeout(() => help.remove(), 500);
    }, data.time || 5000);
}

    
    
    // Shrink Animation für Fortschrittsbalken
    const style = document.createElement("style");
    style.innerHTML = `
    @keyframes shrink {
        from { width: 100%; }
        to { width: 0%; }
    }`;
    document.head.appendChild(style);
    
      
      
    
    window.onData = function (data) {
        switch (data.action) {
            case "showAdvancedProgressbar":
                showAdvancedProgressbar(data.duration, data.label);
                break;
            
            case "showHelp":
    showHelpUI(data);
    break;

            case "showNotify":
    showNotify(data);
    break;

            case "openMenu":
                STANDALONE_UI.open(data.namespace, data.name, data.data);
                break;
            case "closeMenu":
                STANDALONE_UI.close(data.namespace, data.name);
                break;
                        case "updateElements":
            if (
                STANDALONE_UI.opened[data.namespace] &&
                STANDALONE_UI.opened[data.namespace][data.name]
            ) {
                STANDALONE_UI.opened[data.namespace][data.name].elements = data.elements;

                // Reset Auswahl auf 0
                STANDALONE_UI.pos[data.namespace][data.name] = 0;

                STANDALONE_UI.render();
            }
            break;

                case "controlPressed": {
                    const focused = STANDALONE_UI.getFocused();
                    if (!focused) return;
                    const menu = STANDALONE_UI.opened[focused.namespace][focused.name];
                    const pos = STANDALONE_UI.pos[focused.namespace][focused.name];
                
                    switch (data.control) {
                        case "ENTER":
                            if (menu?.elements?.length > 0) {
                                const elem = menu.elements[pos];
                                STANDALONE_UI.submit(focused.namespace, focused.name, elem);
                            }
                            break;
                
                        case "BACKSPACE":
                            STANDALONE_UI.cancel(focused.namespace, focused.name, menu);
                            break;
                
                        case "TOP":
                            if (pos > 0) {
                                STANDALONE_UI.pos[focused.namespace][focused.name]--;
                            } else {
                                STANDALONE_UI.pos[focused.namespace][focused.name] = menu.elements.length - 1;
                            }
                            STANDALONE_UI.refreshSelection(focused.namespace, focused.name);
                            break;
                
                        case "DOWN":
                            if (pos < menu.elements.length - 1) {
                                STANDALONE_UI.pos[focused.namespace][focused.name]++;
                            } else {
                                STANDALONE_UI.pos[focused.namespace][focused.name] = 0;
                            }
                            STANDALONE_UI.refreshSelection(focused.namespace, focused.name);
                            break;
                
                        case "LEFT":
                        case "RIGHT":
                            const elem = menu.elements[pos];
                            if (elem.type === "slider") {
                                const direction = data.control === "LEFT" ? -1 : 1;
                                const newVal = (elem.value || 0) + direction;
                                const max = elem.max ?? (elem.options?.length - 1 ?? 0);
                                const min = elem.min ?? 0;
                                elem.value = Math.max(min, Math.min(newVal, max));
                                STANDALONE_UI.change(focused.namespace, focused.name, elem);
                                STANDALONE_UI.render();
                            }
                            break;
                    }
                    break;
                }
                
        }
    };

    window.onload = () => {
        window.addEventListener("message", (event) => {
            onData(event.data);
        });
    };
})();
function showAdvancedProgressbar(duration, labelText, cb) {
    const barContainer = document.getElementById("advanced-progressbar");
    const bar = barContainer.querySelector(".bar");
    const text = barContainer.querySelector(".text");

    bar.style.width = "0%";
    text.innerText = labelText || "Lade...";

    barContainer.style.display = "block";

    let start = Date.now();

    const interval = setInterval(() => {
        let elapsed = Date.now() - start;
        let percent = Math.min((elapsed / duration) * 100, 100);
        bar.style.width = `${percent}%`;
        text.innerText = `${labelText || "Lade..."} ${Math.round(percent)}%`;

        if (percent >= 100) {
            clearInterval(interval);
            setTimeout(() => {
                barContainer.style.display = "none";
                if (cb) cb();
            }, 300);
        }
    }, 50);
}

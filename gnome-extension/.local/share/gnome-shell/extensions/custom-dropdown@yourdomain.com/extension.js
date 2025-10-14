import St from 'gi://St';
import GObject from 'gi://GObject';
import Clutter from 'gi://Clutter';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const CustomDropdownIndicator = GObject.registerClass(
class CustomDropdownIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Custom Dropdown');

        // Create the button with an icon/text
        this._icon = new St.Icon({
            icon_name: 'applications-utilities-symbolic',
            style_class: 'system-status-icon',
        });

        // Create a box to hold icon and optional text
        this._box = new St.BoxLayout({
            style_class: 'panel-status-menu-box'
        });

        this._box.add_child(this._icon);

        // Optional: Add text label
        this._label = new St.Label({
            // text: 'Custom',
            y_expand: true,
            y_align: Clutter.ActorAlign.CENTER,
        });
        this._box.add_child(this._label);

        this.add_child(this._box);

        // Create the dropdown menu
        this._createMenu();
    }

    _createMenu() {
        // Example menu items - customize these as needed

        // Simple menu item
        this.menu.addMenuItem(new PopupMenu.PopupMenuItem('Option 1'));

        // Menu item with callback
        let item2 = new PopupMenu.PopupMenuItem('Option 2');
        item2.connect('activate', () => {
            Main.notify('Custom Dropdown', 'Option 2 selected!');
        });
        this.menu.addMenuItem(item2);

        // Separator
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Submenu
        let submenu = new PopupMenu.PopupSubMenuMenuItem('Submenu');
        submenu.menu.addMenuItem(new PopupMenu.PopupMenuItem('Sub-option 1'));
        submenu.menu.addMenuItem(new PopupMenu.PopupMenuItem('Sub-option 2'));
        this.menu.addMenuItem(submenu);

        // Another separator
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Menu item that opens a terminal command (example)
        let terminalItem = new PopupMenu.PopupMenuItem('Open Terminal');
        terminalItem.connect('activate', () => {
            Main.Util.spawn(['gnome-terminal']);
        });
        this.menu.addMenuItem(terminalItem);

        // Menu item that opens a specific application
        let editorItem = new PopupMenu.PopupMenuItem('Open Text Editor');
        editorItem.connect('activate', () => {
            Main.Util.spawn(['gedit']);
        });
        this.menu.addMenuItem(editorItem);

        // Toggle switch example
        let toggleItem = new PopupMenu.PopupSwitchMenuItem('Toggle Option', false);
        toggleItem.connect('toggled', (item, state) => {
            Main.notify('Custom Dropdown', `Toggle is now ${state ? 'ON' : 'OFF'}`);
        });
        this.menu.addMenuItem(toggleItem);
    }
});

export default class CustomDropdownExtension extends Extension {
    enable() {
        this._indicator = new CustomDropdownIndicator();
        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}

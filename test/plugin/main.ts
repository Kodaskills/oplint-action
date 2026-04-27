import { App, Plugin, PluginSettingTab, Setting } from 'obsidian';

export default class TestPlugin extends Plugin {
  settings = {
    mySetting: 'default',
  };

  async onload() {
    await this.loadSettings();

    this.addSettingTab(new TestSettingTab(this.app, this));

    this.addCommand({
      id: 'test-command',
      name: 'Test Command',
      callback: () => {
        console.log('Test command executed');
      },
    });

    this.registerEvent(
      this.app.on('change', () => {
        console.log('App changed');
      })
    );
  }

  onunload() {
    console.log('Unloading plugin');
  }

  async loadSettings() {
    this.settings = Object.assign({}, this.settings, await this.loadData());
  }

  async saveSettings() {
    await this.saveData(this.settings);
  }
}

class TestSettingTab extends PluginSettingTab {
  plugin: TestPlugin;

  constructor(app: App, plugin: TestPlugin) {
    super(app, plugin);
    this.plugin = plugin;
  }

  display(): void {
    const { containerEl } = this;
    containerEl.empty();

    new Setting(containerEl).setName('My Setting').addText((text) =>
      text.setValue(this.plugin.settings.mySetting).onChange(async (value) => {
        this.plugin.settings.mySetting = value;
        await this.plugin.saveSettings();
      })
    );
  }
}
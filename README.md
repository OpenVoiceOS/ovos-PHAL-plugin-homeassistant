# OVOS PHAL Home Assistant Plugin

The PHAL Plugin provides GUI interfaces and API for Home Assistant Instants.

NOTE: this plugin is roadmapped for merging with https://github.com/OpenVoiceOS/ovos-PHAL-plugin-commonIOT for ovos-core release 0.0.9, the UI will become IOT framework agnostic

# Demo GIF
![HomeAssistant PHAL Demo](demo/demo.gif)

### Installation

Plugin Support Two Installation Methods:
1. Install from Github URL

Note: PIP install from URL will not install the .desktop file and icon if installing to a venv or virtual environment, so you need to manually install them to the system or user directory.

Note: PIP install will attempt to install the .desktop file and icon to the system directory, or user directory if the system directory is not writable. If this is not a virtual environemnt.

```bash
pip install git+https://github.com/OpenVoiceOS/ovos-PHAL-plugin-homeassistant
```

2. Manual Install from Git Clone
```bash
git clone https://github.com/OpenVoiceOS/ovos-PHAL-plugin-homeassistant
cd ovos-PHAL-plugin-homeassistant
cp -r res/desktop/ovos-phal-homeassistant.desktop ~/.local/share/applications/
cp -r res/icon/ovos-phal-homeassistant.png ~/.local/share/icons/
pip install .
```

### Configuration (Instance Setup)

Plugin Supports Two Configuration Methods:
1. Using the GUI
   - Install the plugin
   - Open the application from the homescreen menu
   - Click the "Connect Instance" button
   - Enter the URL of the Home Assistant Instance
   - Enter the Long-Lived Access Token (API KEY)
   - Press the "Confirm" button 

2. Manually Editing the Config File
   - Add the following to the config file:
   ```json
        "PHAL": {
            "ovos-PHAL-plugin-homeassistant": {
                "host": "https://someurl.toinstance",
                "api_key": "api key from the instance"
            }
        }
   ```

### Usage

The plugin provides a GUI interface for Home Assistant Instances. It also provides an API for other plugins or skills to user.

The plugin is in early development, so there are some features that are not yet implemented. It currently supports the following entities:
- Media Player
- Light
- Vacuum
- Binary Sensor
- Sensor

---------------------------------------  
#### BUS API (For Other Plugins / GUIs) - WIP / TODO Documentation
#### EXPANDING DEVICE / ENTITY SUPPORT - WIP / TODO Documentation
---------------------------------------

## Technical Documentation

### Python Controller Class Specification:
Depending on how the controller communicates with the host instance, the minimum required connector initialization properties are:

- **host** (type: string): Address to host instance
- **api_key** (type: string): Access key for host instance authentication

### Python Device Class Specification:
All devices are required to support the below minimal properties for device initialization.

- **controller** (type: string): An instance of the controller class that handles all communications with the API the device talks to for example HomeAssistantConnector, All devices will use the controller class for any kind of communication.
- **device_id** (type: string): A device id to associate all communications with this device with, for HomeAssistant device_id = entity_id, all device_id start with device_type.device_name.
- **device_icon** (type: string): A device icon to associate the device display icon with including type, for example: "mdi:light" for device type light, "mdi:sensor" for device type sensor, "mdi:media_player" for device type media_player
- **device_name** (type: string): A human readable device name that can be used for spoken and visual material
- **device_state** (type: string): A device can have multiple states depending on which type of device it is, for example a light can have an "on", "off" and "unavailable" states, a media_player can have "playing", "paused", "off", "on" and "unavailable" states. Refer to HomeAssistant entities list for complete list of entity states
- **device_attributes** (type: dict): Device attributes provide information of the device such as supported properties and values, they can consist of information such as: "brightness", "rgb_color", "supported_color_mode" in case of lights for example. Refer to HomeAssistant entities list for complete list of entity attributes

### QML GUI Device Display Model Specification:

- **id** (type: string): Device ID as per the device class specification.
- **name** (type: string): Device display name as per the device class specification
- **icon** (type: string): Device icon name as per the device class specification
- **state** (type: string): Device state as updated or provided by device in the device class specification
- **type** (type: string): Device type assigned to the device when the device is registerd, this is not an initialization property and is extracted from the device_id where device_id = "device_type.device_name" generally in HomeAssistant API
- **attributes** (type: dict): Device attributes as provided by the device during various state changes and initial state at time of registeration

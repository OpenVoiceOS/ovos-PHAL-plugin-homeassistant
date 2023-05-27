import uuid
import asyncio
from copy import deepcopy
from os.path import dirname, join
from typing import Optional

from pfzy import fuzzy_match
from ovos_utils.log import LOG
from ovos_bus_client import Message
from ovos_plugin_manager.phal import PHALPlugin
from ovos_utils.gui import GUIInterface
from ovos_PHAL_plugin_homeassistant.logic.connector import HomeAssistantRESTConnector, HomeAssistantWSConnector
from ovos_PHAL_plugin_homeassistant.logic.device import (HomeAssistantSensor,
                                                         HomeAssistantBinarySensor,
                                                         HomeAssistantLight, HomeAssistantAutomation,
                                                         HomeAssistantMediaPlayer, HomeAssistantScene,
                                                         HomeAssistantVacuum, HomeAssistantSwitch,
                                                         HomeAssistantClimate, HomeAssistantCamera)
from ovos_PHAL_plugin_homeassistant.logic.integration import Integrator
from ovos_PHAL_plugin_homeassistant.logic.utils import (map_entity_to_device_type,
                                                        check_if_device_type_is_group,
                                                        get_percentage_brightness_from_ha_value)
from ovos_config.config import update_mycroft_config

SUPPORTED_DEVICES = {
            "sensor": HomeAssistantSensor,
            "binary_sensor": HomeAssistantBinarySensor,
            "light": HomeAssistantLight,
            "media_player": HomeAssistantMediaPlayer,
            "vacuum": HomeAssistantVacuum,
            "switch": HomeAssistantSwitch,
            "climate": HomeAssistantClimate,
            "camera": HomeAssistantCamera,
            "scene": HomeAssistantScene,
            "automation": HomeAssistantAutomation,
        }

class HomeAssistantPlugin(PHALPlugin):
    def __init__(self, bus=None, config=None):
        """ Initialize the plugin

            Args:
                bus (MycroftBusClient): The Mycroft bus client
                config (dict): The plugin configuration
        """
        super().__init__(bus=bus, name="ovos-PHAL-plugin-homeassistant", config=config)
        self.oauth_client_id = None
        self.munged_id = "ovos-PHAL-plugin-homeassistant_homeassistant-phal-plugin"
        self.temporary_instance = None
        self.connector = None
        self.registered_devices = []  # Device objects
        self.registered_device_names = []  # Device friendly/entity names
        self.bus = bus
        self.gui = GUIInterface(bus=self.bus, skill_id=self.name)
        self.integrator = Integrator(self.bus, self.gui)
        self.instance_available = False
        self.use_ws = False
        self.device_types = SUPPORTED_DEVICES

        # BUS API FOR HOME ASSISTANT
        self.bus.on("ovos.phal.plugin.homeassistant.get.devices",
                    self.handle_get_devices)
        self.bus.on("ovos.phal.plugin.homeassistant.get.device",
                    self.handle_get_device)
        self.bus.on("ovos.phal.plugin.homeassistant.device.turn_on",
                    self.handle_turn_on)
        self.bus.on("ovos.phal.plugin.homeassistant.device.turn_off",
                    self.handle_turn_off)
        self.bus.on("ovos.phal.plugin.homeassistant.get.device.display.model",
                    self.handle_get_device_display_model)
        self.bus.on("ovos.phal.plugin.homeassistant.get.device.display.list.model",
                    self.handle_get_device_display_list_model)
        self.bus.on("ovos.phal.plugin.homeassistant.call.supported.function",
                    self.handle_call_supported_function)
        self.bus.on("ovos.phal.plugin.homeassistant.start.oauth.flow", self.handle_start_oauth_flow)
        self.bus.on("ovos.phal.plugin.homeassistant.assist.intent", self.handle_assist_message)
        self.bus.on("ovos.phal.plugin.homeassistant.get.light.brightness", self.handle_get_light_brightness)
        self.bus.on("ovos.phal.plugin.homeassistant.set.light.brightness", self.handle_set_light_brightness)
        self.bus.on("ovos.phal.plugin.homeassistant.increase.light.brightness", self.handle_increase_light_brightness)
        self.bus.on("ovos.phal.plugin.homeassistant.decrease.light.brightness", self.handle_decrease_light_brightness)
        self.bus.on("ovos.phal.plugin.homeassistant.get.light.color", self.handle_get_light_color)
        self.bus.on("ovos.phal.plugin.homeassistant.set.light.color", self.handle_set_light_color)

        # GUI EVENTS
        self.bus.on("ovos-PHAL-plugin-homeassistant.home",
                    self.handle_show_dashboard)
        self.bus.on("ovos-PHAL-plugin-homeassistant.close",
                    self.handle_close_dashboard)
        self.bus.on("ovos.phal.plugin.homeassistant.show.device.dashboard",
                    self.handle_show_device_dashboard)
        self.bus.on("ovos.phal.plugin.homeassistant.show.area.dashboard",
                    self.handle_show_area_dashboard)
        self.bus.on("ovos.phal.plugin.homeassistant.update.device.dashboard",
                    self.handle_update_device_dashboard)
        self.bus.on("ovos.phal.plugin.homeassistant.update.area.dashboard",
                    self.handle_update_area_dashboard)
        self.bus.on("ovos.phal.plugin.homeassistant.set.group.display.settings",
                    self.handle_set_group_display_settings)

        # LISTEN CONFIG CHANGES
        self.bus.on("ovos.phal.plugin.homeassistant.setup.instance",
                    self.setup_configuration)
        self.bus.on("configuration.updated", self.init_configuration)
        self.bus.on("configuration.patch", self.init_configuration)

        # LISTEN FOR OAUTH RESPONSE
        self.bus.on("oauth.app.host.info.response", self.handle_oauth_host_info)
        self.bus.on("oauth.generate.qr.response", self.handle_qr_oauth_response)
        self.bus.on(f"oauth.token.response.{self.munged_id}", self.handle_token_oauth_response)

        self.init_configuration()

# SETUP INSTANCE SUPPORT
    def validate_instance_connection(self, host, api_key):
        """ Validate the connection to the Home Assistant instance

            Args:
                host (str): The Home Assistant instance URL
                api_key (str): The Home Assistant API key

            Returns:
                bool: True if the connection is valid, False otherwise
        """
        try:
            if self.use_ws:
                validator = HomeAssistantWSConnector(host, api_key)
            else:
                validator = HomeAssistantRESTConnector(host, api_key)

            validator.get_all_devices()

            if self.use_ws:
                if validator.client:
                    validator.disconnect()

            return True

        except Exception as e:
            LOG.error(e)
            return False

    def setup_configuration(self, message):
        """ Handle the setup instance message

            Args:
                message (Message): The message object
        """
        host = message.data.get("url", "")
        key = message.data.get("api_key", "")

        if host and key:
            if host.startswith("ws") or host.startswith("wss"):
                self.use_ws = True

            if self.validate_instance_connection(host, key):
                self.config["host"] = host
                self.config["api_key"] = key
                self.instance_available = True
                config_patch = {
                    "PHAL": {
                        "ovos-PHAL-plugin-homeassistant": {
                            "host": host,
                            "api_key": key
                        }
                    }
                }
                update_mycroft_config(config=config_patch, bus=self.bus)
                self.init_configuration()
                self.bus.emit(Message("ovos-PHAL-plugin-homeassistant.home"))

# INSTANCE INIT OPERATIONS
    def init_configuration(self, message=None):
        """ Initialize instance configuration """
        configuration_host = self.config.get("host", "")
        configuration_api_key = self.config.get("api_key", "")
        if configuration_host.startswith("ws") or configuration_host.startswith("wss"):
            self.use_ws = True

        if not self.config.get("use_group_display"):
            self.config["use_group_display"] = False

        if configuration_host != "" and configuration_api_key != "":
            self.instance_available = True
            if self.use_ws:
                self.connector = HomeAssistantWSConnector(configuration_host, configuration_api_key)
            else:
                self.connector = HomeAssistantRESTConnector(configuration_host, configuration_api_key)
            self.devices = self.connector.get_all_devices()
            self.registered_devices = []
            self.build_devices()
            self.gui["use_websocket"] = self.use_ws
            self.gui["instanceAvailable"] = True
            self.bus.emit(Message("ovos.phal.plugin.homeassistant.ready"))
        else:
            self.instance_available = False
            self.bus.emit(
                Message("ovos.phal.plugin.homeassistant.requires.configuration"))

    def build_devices(self):
        """ Build the devices from the Home Assistant API """
        for device in self.devices:
            device_type = map_entity_to_device_type(device["entity_id"])
            device_type_is_group = check_if_device_type_is_group(
                device.get("attributes", {}))
            if device_type is not None:
                if not device_type_is_group:
                    device_id = device["entity_id"]
                    device_name = device.get("attributes", {}).get(
                        "friendly_name", device_id)
                    device_icon = f"mdi:{device_type}"
                    device_state = device.get("state", None)
                    device_area = device.get("area_id", None)
                    LOG.debug(f"Device added: {device_name} - {device_type} - {device_area}")

                    device_attributes = device.get("attributes", {})
                    if device_type in self.device_types:
                        self.registered_devices.append(self.device_types[device_type](
                            self.connector, device_id, device_icon, device_name,
                            device_state, device_attributes, device_area, self.device_updated))
                        self.registered_device_names.append(device_name)
                    else:
                        LOG.warning(f"Device type {device_type} not supported; please file an issue on GitHub")
                else:
                    LOG.warning(
                        f"Device type {device_type} is a group, not supported currently")

    def build_display_dashboard_device_model(self):
        """ Build the dashboard model """
        device_type_model = []
        for device in self.registered_devices:
            device_type = device.device_type
            if device_type not in device_type_model:
                device_type_model.append(device_type)

        display_list_model = []
        for device_type in device_type_model:
            device_type_list_model = []
            for device in self.registered_devices:
                if device.device_type == device_type:
                    device_type_list_model.append(
                        device.get_device_display_model())
            device_human_readable_type = device_type.replace("_", " ").title()
            display_list_model.append({
                "type": device_type,
                "icon": f"mdi:{device_type}",
                "name": device_human_readable_type,
                "devices": device_type_list_model
            })
        return display_list_model

    def build_display_dashboard_area_model(self):
        """ Build the display model by area """
        unknown_area_devices = []
        area_model = []
        display_list_model = []
        for device in self.registered_devices:
            if device.device_area is not None:
                if device.device_area not in area_model:
                    area_model.append(device.device_area)
            else:
                unknown_area_devices.append(device)

        display_list_model.append({
            "type": "unknown",
            "icon": "mdi:ungrouped",
            "name": "Unknown Location",
            "devices": [device.get_device_display_model() for device in unknown_area_devices]
        })

        for area in area_model:
            area_list_model = []
            for device in self.registered_devices:
                if device.device_area == area:
                    area_list_model.append(device.get_device_display_model())

            display_list_model.append({
                "type": area,
                "icon": "mdi:grouped",
                "name": area.replace("_", " ").title(),
                "devices": area_list_model
            })

        return display_list_model

    def build_display_device_type_devices_model(self, device_type):
        """ Build the devices model based on the device type

        Args:
            device_type (String): The device type to build the model for

        Returns:
            dict: The device model
        """
        device_type_list_model = []
        for device in self.registered_devices:
            if device.device_type == device_type:
                device_type_list_model.append(
                    device.get_device_display_model())
        return device_type_list_model

    def build_display_area_devices_model(self, area):
        """ Build the devices model based on the area

        Args:
            area (String): The area to build the model for

        Returns:
            dict: The device model
        """
        area_list_model = []
        for device in self.registered_devices:
            if device.device_area == area:
                area_list_model.append(device.get_device_display_model())
            if device.device_area is None and area == "unknown":
                area_list_model.append(device.get_device_display_model())

        return area_list_model

# BUS API HANDLERS
    def handle_get_devices(self, message):
        """ Handle the get devices message

            Args:
                message (Message): The message object
        """
        # build a plain list of devices
        device_list = []
        for device in self.registered_devices:
            device_list.append(device.get_device_display_model())

        self.bus.emit(message.response(data={"devices": device_list}))

    def handle_get_device(self, message: Message):
        """Handle the message to get a single device

        Args:
            message (Message): The message object
        """
        # Device ID provided, usually GUI
        device_id = message.data.get("device_id", None)
        if device_id is not None:
            LOG.debug(f"Device ID provided in bus message: {device_id}")
            return self._return_device_response(message, device_id)

        # Device ID not provided, usually VUI
        device = message.data.get("device")
        device_result = self.fuzzy_match_name(
                            self.registered_devices,
                            device,
                            self.registered_device_names
                        )
        LOG.debug(f"No device ID, found device result: {device_result or 'None'}")
        if device_result:
            return self._return_device_response(message, device_result)

        # No device found
        LOG.debug(f"No Home Assistant device exists for {device}")
        self.bus.emit(message.response(data=None))

    def _return_device_response(self, message, device_id) -> None:
        """Return the device representation to the bus

        Args:
            message (Message): The message object to respond to
            device_id (str): The device ID to lookup and return
        """
        for device in self.registered_devices:
            if device.device_id == device_id:
                return self.bus.emit(message.response(data=device.get_device_display_model()))
        LOG.debug(f"No device found with device ID {device_id}")
        self.bus.emit(message.response(data=None))

    def handle_turn_on(self, message):
        """ Handle the turn on message

            Args:
                message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        if device_id is not None:
            for device in self.registered_devices:
                if device.device_id == device_id:
                    device.turn_on()
                    return self.bus.emit(message.response(data={"device": spoken_device}))
        # No device found
        LOG.debug(f"No Home Assistant device exists for {device_id}")
        self.bus.emit(message.response(data=None))

    def handle_turn_off(self, message):
        """ Handle the turn off message

            Args:
                message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        if device_id is not None:
            for device in self.registered_devices:
                if device.device_id == device_id:
                    device.turn_off()
                    return self.bus.emit(message.response(data={"device": spoken_device}))
        # No device found
        LOG.debug(f"No Home Assistant device exists for {device_id}")
        self.bus.emit(message.response(data=None))

    def _gather_device_id(self, message):
        """Given a bus message, return the device ID and spoken device name for reference

        Args:
            message (Message): Bus message from GUI or VUI, or other source

        Returns:
            Tuple[Optional[str], str]: original device ID or device search result or None, spoken device name (str)
        """
        device_id = message.data.get("device_id", None)
        device = message.data.get("device", None)
        spoken_device = deepcopy(device) or device_id
        if device_id is None and device is not None:
            device_id = self.fuzzy_match_name(
                            self.registered_devices,
                            device,
                            self.registered_device_names
                        )
            LOG.debug(f"No device ID, found device result: {device_id or 'None'}")
        return device_id, spoken_device

    def handle_call_supported_function(self, message):
        """ Handle the call supported function message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        function_name = message.data.get("function_name", None)
        function_args = message.data.get("function_args", None)
        if device_id is not None and function_name is not None:
            for device in self.registered_devices:
                if device.device_id == device_id:
                    if function_args is not None:
                        response = device.call_function(
                            function_name, function_args)
                    else:
                        response = device.call_function(function_name)
                    return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))
        else:
            response = "Device id or function name not provided"
            LOG.error(response)
            return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_get_light_brightness(self, message):
        """ Handle the get light brightness message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        if device_id is not None:
            for device in self.registered_devices:
                if device.device_id == device_id:
                    return self.bus.emit(message.response(
                        data={
                            "device": spoken_device,
                            "brightness": get_percentage_brightness_from_ha_value(device.get_brightness())
                            }))
        else:
            response = "Device id not provided"
            LOG.error(response)
            return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_get_light_color(self, message):
        """ Handle the get light color VUI message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        if device_id is not None:
            for device in self.registered_devices:
                if device.device_id == device_id:
                    color = device.get_spoken_color()
                    return self.bus.emit(message.response(
                        data={
                            "device": spoken_device,
                            "color": color
                            }))
        else:
            response = "Device id not provided"
            LOG.error(response)
            return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_set_light_color(self, message):
        """ Handle the set light color message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        color = message.data.get("color")
        for device in self.registered_devices:
            if device.device_id == device_id:
                device.set_color(color)
                return self.bus.emit(message.response(data={
                    "device": spoken_device,
                    "color": color
                    }))
        response = "Device id not provided"
        LOG.error(response)
        return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_set_light_brightness(self, message):
        """ Handle the set light brightness message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        brightness = message.data.get("brightness")
        for device in self.registered_devices:
            if device.device_id == device_id:
                device.set_brightness(brightness)
                return self.bus.emit(message.response(data={
                    "device": spoken_device,
                    "brightness": get_percentage_brightness_from_ha_value(brightness)
                    }))
        response = "Device id not provided"
        LOG.error(response)
        return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_increase_light_brightness(self, message):
        """ Handle the increase light brightness message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        for device in self.registered_devices:
            if device.device_id == device_id:
                brightness = device.increase_brightness()
                return self.bus.emit(message.response(data={
                    "device": spoken_device,
                    "brightness": get_percentage_brightness_from_ha_value(brightness)
                    }))
        response = "Device id not provided"
        LOG.error(response)
        return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_decrease_light_brightness(self, message):
        """ Handle the decrease light brightness message

        Args:
            message (Message): The message object
        """
        device_id, spoken_device = self._gather_device_id(message)
        for device in self.registered_devices:
            if device.device_id == device_id:
                brightness = device.decrease_brightness()
                return self.bus.emit(message.response(data={
                    "device": spoken_device,
                    "brightness": get_percentage_brightness_from_ha_value(brightness)
                    }))
        response = "Device id not provided"
        LOG.error(response)
        return self.bus.emit(message.response(data={"device": spoken_device, "response": response}))

    def handle_get_device_display_model(self, message):
        """ Handle the get device display model message

            Args:
                message (Message): The message object
        """
        device_id = message.data.get("device_id", None)
        if device_id is not None:
            for device in self.registered_devices:
                if device.device_id == device_id:
                    self.bus.emit(message.response(
                        data=device.get_device_display_model()))
                    return
        self.bus.emit(message.response(data=None))

    def handle_get_device_display_list_model(self, message):
        """ Handle the get device display list model message

            Args:
                message (Message): The message object
        """
        display_list_model = []
        for device in self.registered_devices:
            display_list_model.append(device.get_device_display_model())
        self.bus.emit(message.response(data=display_list_model))

    def handle_assist_message(self, message):
        """Handle a passthrough message to Home Assistant's Assist API.

        Args:
            message (Message): The message object
        """
        command: str = message.data.get("command")
        LOG.debug(f"Received Assist command: {command}")
        if self.connector and type(self.connector) in (HomeAssistantWSConnector, HomeAssistantRESTConnector):
            self.bus.emit(message.response(data=self.connector.send_assist_command(command)))
        else:
            self.bus.emit(message.response(data=None))

# GUI INTERFACE HANDLERS
    def handle_show_dashboard(self, message=None):
        """ Handle the show dashboard message

            Args:
                message (Message): The message object
        """
        if self.instance_available:
            self.gui["use_websocket"] = self.use_ws
            if not self.config.get("use_group_display"):
                display_list_model = {
                    "items": self.build_display_dashboard_device_model()}
            else:
                display_list_model = {
                    "items": self.build_display_dashboard_area_model()}

            self.gui["dashboardModel"] = display_list_model
            self.gui["instanceAvailable"] = True
            self.gui.send_event("ovos.phal.plugin.homeassistant.change.dashboard", {
                                "dash_type": "main"})
            page = join(dirname(__file__), "ui", "Dashboard.qml")
            self.gui["use_group_display"] = self.config.get("use_group_display", False)
            self.gui.show_page(page, override_idle=True)
        else:
            self.gui["dashboardModel"] = {"items": []}
            self.gui["instanceAvailable"] = False
            self.gui.send_event("ovos.phal.plugin.homeassistant.change.dashboard", {
                                "dash_type": "main"})
            page = join(dirname(__file__), "ui", "Dashboard.qml")
            self.gui["use_group_display"] = self.config.get("use_group_display", False)
            self.gui.show_page(page, override_idle=True)

        LOG.debug("Using group display")
        LOG.debug(self.config["use_group_display"])

    def handle_close_dashboard(self, message):
        """ Handle the close dashboard message

            Args:
                message (Message): The message object
        """
        self.gui.release()

    def handle_show_device_dashboard(self, message):
        """ Handle the show device dashboard message

            Args:
                message (Message): The message object
        """
        device_type = message.data.get("device_type", None)
        if device_type is not None:
            self.gui["deviceDashboardModel"] = {
                "items": self.build_display_device_type_devices_model(device_type)}
            self.gui.send_event("ovos.phal.plugin.homeassistant.change.dashboard", {
                                "dash_type": "device"})

    def handle_show_area_dashboard(self, message):
        """ Handle the show area dashboard message

            Args:
                message (Message): The message object
        """
        area = message.data.get("area", None)
        if area is not None:
            self.gui["areaDashboardModel"] = {
                "items": self.build_display_area_devices_model(area)}
            self.gui.send_event("ovos.phal.plugin.homeassistant.change.dashboard", {
                                "dash_type": "area"})

    def handle_update_device_dashboard(self, message):
        """ Handle the update device dashboard message

            Args:
                message (Message): The message object
        """
        device_type = message.data.get("device_type", None)
        if device_type is not None:
            self.gui["deviceDashboardModel"] = {
                "items": self.build_display_device_type_devices_model(device_type)}

    def handle_update_area_dashboard(self, message):
        """ Handle the update area dashboard message

            Args:
                message (Message): The message object
        """
        area = message.data.get("area_type", None)
        if area is not None:
            self.gui["areaDashboardModel"] = {
                "items": self.build_display_area_devices_model(area)}

    def handle_set_group_display_settings(self, message):
        """ Handle the set group display settings message

            Args:
                message (Message): The message object
        """
        group_settings = message.data.get("use_group_display", None)
        if group_settings is not None:
            if group_settings == True:
                use_group_display = True
                self.config["use_group_display"] = use_group_display
            else:
                use_group_display = False
                self.config["use_group_display"] = use_group_display

            config_patch = {
                "PHAL": {
                    "ovos-PHAL-plugin-homeassistant": {
                        "host": self.config.get("host"),
                        "api_key": self.config.get("api_key"),
                        "use_group_display": use_group_display
                    }
                }
            }
            update_mycroft_config(config=config_patch, bus=self.bus)
            self.gui["use_group_display"] = self.config.get("use_group_display")
            self.handle_show_dashboard()

# OAuth QR Code Flow Handlers
    def request_host_info_from_oauth(self):
        self.bus.emit(Message("oauth.get.app.host.info"))

    def handle_oauth_host_info(self, message):
        host = message.data.get("host", None)
        port = message.data.get("port", None)
        self.oauth_client_id = f"http://{host}:{port}"

        if self.temporary_instance:
            self.oauth_register()
            self.start_oauth_flow()

    def handle_start_oauth_flow(self, message):
        """ Handle the start oauth flow message

            Args:
                message (Message): The message object
        """
        instance = message.data.get("instance", None)
        if instance:
            self.temporary_instance = instance
            self.request_host_info_from_oauth()

    def oauth_register(self):
        """ Register the phal plugin with the oauth service """
        host = self.temporary_instance.replace("ws://", "http://").replace("wss://", "https://")
        auth_endpoint = f"{host}/auth/authorize"
        token_endpoint = f"{host}/auth/token"
        self.bus.emit(Message("oauth.register", {
            "client_id": self.oauth_client_id,
            "skill_id": "ovos-PHAL-plugin-homeassistant",
            "app_id": "homeassistant-phal-plugin",
            "auth_endpoint": auth_endpoint,
            "token_endpoint": token_endpoint,
            "shell_integration": False,
            "refresh_endpoint": "",
        }))

    def start_oauth_flow(self):
        host = self.temporary_instance.replace("ws://", "http://").replace("wss://", "https://")
        app_id = "homeassistant-phal-plugin"
        skill_id = "ovos-PHAL-plugin-homeassistant"
        self.bus.emit(Message("oauth.generate.qr.request", {
            "app_id": app_id,
            "skill_id": skill_id
        }))

    def handle_qr_oauth_response(self, message):
        qr_code_url = message.data.get("qr", None)
        self.gui.send_event("ovos.phal.plugin.homeassistant.oauth.qr.update", {
            "qr": qr_code_url
        })

    def handle_token_oauth_response(self, message):
        response = message.data
        access_token = response.get("access_token", None)
        if access_token:
            self.get_long_term_token(access_token)

    def get_long_term_token(self, short_term_token):
        instance = self.temporary_instance.replace("http://", "ws://").replace("https://", "wss://")
        token = short_term_token
        wsClient = HomeAssistantWSConnector(instance, token)
        client_name = "ovos-PHAL-plugin-homeassistant-" + str(uuid.uuid4().hex)[:4]
        token_response = wsClient.call_command("auth/long_lived_access_token", {"client_name": client_name, "lifespan": 1825})

        if wsClient.client:
            wsClient.disconnect()

        if token_response:
            if token_response["success"]:
                long_term_token = token_response["result"]
                self.gui.send_event("ovos.phal.plugin.homeassistant.oauth.success", {})
                self.setup_configuration(Message("ovos.phal.plugin.homeassistant.setup", {"url": instance, "api_key": long_term_token}))

# EVENT SIGNAL ON DEVICE UPDATE
    def device_updated(self, device_id):
        """Send a device updated signal to the GUI.
        It can request a new display model once it receives this signal.

        Args:
            device (dict): The device that was updated.
        """
        # GUI only event as we don't want to flood the GUI bus
        self.gui.send_event("ovos.phal.plugin.homeassistant.device.updated", {"device_id": device_id})
        self.bus.emit(Message("ovos.phal.plugin.homeassistant.device.state.updated"))

# UTILS
    def fuzzy_match_name(self, devices_list, spoken_name, device_names) -> Optional[str]:
        """Given a list of device names, fuzzy match the spoken name to the most likely one.
        Returns the device id of the most likely match or None if no match is found.
        """
        # https://github.com/kazhala/pfzy/issues/1 fuzzy_match mutates its haystack
        device_names_haystack = deepcopy(device_names)
        try:
            result = asyncio.run(fuzzy_match(spoken_name, device_names_haystack))
            if result:
                return devices_list[device_names.index(result[0].get("value"))].device_id
            else:
                return None
        except TypeError:
            LOG.error(f"Failed to fuzzy match device name {spoken_name}", exc_info=True)
            return None

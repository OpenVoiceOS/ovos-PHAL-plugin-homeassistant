# pylint: disable=missing-function-docstring,missing-class-docstring,missing-module-docstring
import unittest
from unittest.mock import patch

from ovos_utils.messagebus import FakeBus, FakeMessage
from ovos_PHAL_plugin_homeassistant import HomeAssistantPlugin, SUPPORTED_DEVICES


class FakeConnector:
    def __init__(self):
        self.callbacks = []

    def register_callback(self, callback, *args):
        self.callbacks.append(callback)


class TestHomeAssistantPlugin(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plugin = HomeAssistantPlugin(bus=FakeBus(None))
        fake_devices = [
            cls.plugin.device_types["media_player"](
                FakeConnector(),
                "test_media_player",
                "mdi:media_player",
                "test_media_player",
                "off",
                {"friendly_name": "Test Media Player"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["light"](
                FakeConnector(),
                "test_light",
                "mdi:light",
                "test_light",
                "on",
                {"friendly_name": "Test Light"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["switch"](
                FakeConnector(),
                "test_switch",
                "mdi:switch",
                "test_switch",
                "on",
                {"friendly_name": "Test Switch"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["sensor"](
                FakeConnector(),
                "test_sensor",
                "mdi:sensor",
                "test_sensor",
                "on",
                {"friendly_name": "Test Sensor"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["binary_sensor"](
                FakeConnector(),
                "test_binary_sensor",
                "mdi:binary_sensor",
                "test_binary_sensor",
                "on",
                {"friendly_name": "Test Binary Sensor"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["climate"](
                FakeConnector(),
                "test_climate",
                "mdi:climate",
                "test_climate",
                "on",
                {"friendly_name": "Test Climate"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["vacuum"](
                FakeConnector(),
                "test_vacuum",
                "mdi:vacuum",
                "test_vacuum",
                "on",
                {"friendly_name": "Test Vacuum"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["camera"](
                FakeConnector(),
                "test_camera",
                "mdi:camera",
                "test_camera",
                "on",
                {"friendly_name": "Test Camera"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["scene"](
                FakeConnector(),
                "test_scene",
                "mdi:scene",
                "test_scene",
                "on",
                {"friendly_name": "Test Scene"},
                "Living Room",
                True,
            ),
            cls.plugin.device_types["automation"](
                FakeConnector(),
                "test_automation",
                "mdi:automation",
                "test_automation",
                "on",
                {"friendly_name": "Test Automation"},
                "Living Room",
                True,
            ),
        ]
        for device in fake_devices:
            cls.plugin.registered_devices.append(device)
            cls.plugin.registered_device_names.append(device.device_attributes.get("friendly_name"))
        cls.testable_devices = {dtype.device_id.replace("test_", "") for dtype in cls.plugin.registered_devices}

    def test_plugin_loads_with_fake_bus(self):
        self.assertIsNotNone(self.plugin)
        self.assertIsInstance(self.plugin, HomeAssistantPlugin)

    def test_all_supported_device_types_available(self):
        # We want to make sure to at least instantiate one of every type in our tests
        self.assertSetEqual(set(SUPPORTED_DEVICES.keys()), self.testable_devices)

    def test_fuzzy_match_name(self):
        print(f"Pre-fuzzy_match: {self.plugin.registered_device_names[0]}")
        device_id = self.plugin.fuzzy_match_name(
            self.plugin.registered_devices,
            "test media layer",
            self.plugin.registered_device_names,
        )
        self.assertEqual(device_id, "test_media_player")
        # pfzy has mutated this before, we want to make sure it doesn't
        print(f"Post-fuzzy_match: {self.plugin.registered_device_names[0]}")
        self.assertIsInstance(self.plugin.registered_device_names[0], str)

    # Get device
    def test_return_device_response_when_passed_explicitly(self):
        # Device passed explicitly
        fake_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.on", {"device_id": "test_switch"}, None)
        with patch.object(self.plugin, "_return_device_response") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                self.plugin.handle_get_device(fake_message)
                self.assertTrue(mock_call.called)
                self.assertFalse(mock_fuzzy_search.called)

    def test_return_device_response_when_fuzzy_searching(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage("ovos.phal.plugin.homeassistant.get.device", {"device": "test switch"}, None)
        with patch.object(self.plugin, "_return_device_response") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                self.plugin.handle_get_device(fake_message)
                self.assertTrue(mock_call.called)
                self.assertTrue(mock_fuzzy_search.called)

    def test_return_device_response_when_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage("ovos.phal.plugin.homeassistant.get.device", {"device": "NOT REAL"}, None)
        with patch.object(self.plugin, "_return_device_response") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_device(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Turn on device
    def test_handle_turn_on_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.on", {"device_id": "test_switch"}, None)
        with patch.object(self.plugin.device_types["switch"], "turn_on") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_turn_on(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_turn_on_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.on", {"device": "test switch"}, None)
        with patch.object(self.plugin.device_types["switch"], "turn_on") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_switch") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_turn_on(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_turn_on_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.on", {"device": "NOT REAL"}, None)
        with patch.object(self.plugin.device_types["switch"], "turn_on") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_turn_on(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Turn off device
    def test_handle_turn_off_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.off", {"device_id": "test_switch"}, None)
        with patch.object(self.plugin.device_types["switch"], "turn_off") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_turn_off(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_turn_off_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.off", {"device": "test switch"}, None)
        with patch.object(self.plugin.device_types["switch"], "turn_off") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_switch") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_turn_off(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_turn_off_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage("ovos.phal.plugin.homeassistant.turn.off", {"device": "NOT REAL"}, None)
        with patch.object(self.plugin.device_types["switch"], "turn_off") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_turn_off(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Call supported function
    def test_handle_called_supported_function_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.call.supported.function",
            {"device_id": "test_switch", "function_name": "order_66", "function_args": "execute"},
            None,
        )
        with patch.object(self.plugin.device_types["switch"], "call_function") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_call_supported_function(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_called_supported_function_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.call.supported.function",
            {"device": "test switch", "function_name": "order_66", "function_args": "execute"},
            None,
        )
        with patch.object(self.plugin.device_types["switch"], "call_function") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_switch") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_call_supported_function(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_called_supported_function_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.call.supported.function",
            {"device": "NOT REAL", "function_name": "order_66", "function_args": "execute"},
            None,
        )
        with patch.object(self.plugin.device_types["switch"], "call_function") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_call_supported_function(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Get light brightness
    def test_handle_get_light_brightness_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.get.light.brightness",
            {"device_id": "test_light"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "get_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_light_brightness(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_get_light_brightness_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.get.light.brightness",
            {"device": "test_switch"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "get_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_light") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_light_brightness(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_get_light_brightness_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.get.light.brightness",
            {"device": "NOT REAL"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "get_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_light_brightness(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Set light brightness
    def test_handle_set_light_brightness_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.set.light.brightness",
            {"device_id": "test_light", "brightness": 200},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "set_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_set_light_brightness(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_set_light_brightness_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.set.light.brightness",
            {"device": "test_switch", "brightness": 200},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "set_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_light") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_set_light_brightness(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_set_light_brightness_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.set.light.brightness",
            {"device": "NOT REAL", "brightness": 200},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "set_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_set_light_brightness(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Increase light brightness
    def test_handle_increase_light_brightness_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.increase.light.brightness",
            {"device_id": "test_light"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "increase_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_increase_light_brightness(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_increase_light_brightness_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.increase.light.brightness",
            {"device": "test_switch"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "increase_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_light") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_increase_light_brightness(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_increase_light_brightness_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.increase.light.brightness",
            {"device": "NOT REAL"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "increase_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_increase_light_brightness(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Decrease light brightness
    def test_handle_decrease_light_brightness_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.decrease.light.brightness",
            {"device_id": "test_light"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "decrease_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_decrease_light_brightness(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_decrease_light_brightness_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.decrease.light.brightness",
            {"device": "test_switch"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "decrease_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_light") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_decrease_light_brightness(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_decrease_light_brightness_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.decrease.light.brightness",
            {"device": "NOT REAL"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "decrease_brightness") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_decrease_light_brightness(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Get light color
    def test_handle_get_light_color_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.get.light.color",
            {"device_id": "test_light"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "get_spoken_color", return_value="black") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_light_color(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_get_light_color_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.get.light.color",
            {"device": "test_light"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "get_spoken_color", return_value="black") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_light") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_light_color(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_get_light_color_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.get.light.color",
            {"device": "NOT REAL"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "get_spoken_color", return_value="black") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_get_light_color(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

    # Set light color
    def test_handle_set_light_color_with_device_id(self):
        # Device passed explicitly
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.set.light.color",
            {"device_id": "test_light", "color": "red"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "set_color") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_set_light_color(fake_message)
                    self.assertTrue(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertFalse(mock_fuzzy_search.called)

    def test_handle_set_light_color_fuzzy_search(self):
        # Device exists but STT is fuzzy
        fake_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.set.light.color",
            {"device": "test_light", "color": "red"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "set_color") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value="test_light") as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_set_light_color(fake_message)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)
                    self.assertTrue(mock_call.called)

    def test_handle_set_light_color_device_does_not_exist(self):
        # Device does not exist
        bad_message = FakeMessage(
            "ovos.phal.plugin.homeassistant.set.light.color",
            {"device": "NOT REAL", "color": "red"},
            None,
        )
        with patch.object(self.plugin.device_types["light"], "set_color") as mock_call:
            with patch.object(self.plugin, "fuzzy_match_name", return_value=None) as mock_fuzzy_search:
                with patch.object(self.plugin.bus, "emit") as mock_bus:
                    self.plugin.handle_set_light_color(bad_message)
                    self.assertFalse(mock_call.called)
                    self.assertTrue(mock_bus.called)
                    self.assertTrue(mock_fuzzy_search.called)

# pylint: disable=missing-function-docstring,missing-class-docstring,missing-module-docstring
# Utils for the plugin


def map_entity_to_device_type(entity):
    """Map an entity to a device type.

    Args:
        entity (str): The entity to map.
    """
    if entity.startswith("sensor."):
        return "sensor"
    elif entity.startswith("binary_sensor."):
        return "binary_sensor"
    elif entity.startswith("cover."):
        return "cover"
    elif entity.startswith("light."):
        return "light"
    elif entity.startswith("switch."):
        return "switch"
    elif entity.startswith("media_player."):
        return "media_player"
    elif entity.startswith("climate."):
        return "climate"
    elif entity.startswith("vacuum."):
        return "vacuum"
    elif entity.startswith("camera."):
        return "camera"
    elif entity.startswith("scene."):
        return "scene"
    elif entity.startswith("automation."):
        return "automation"
    else:
        return None


def check_if_device_type_is_group(device_attributes):
    """Check if a device is a group.

    Args:
        device_attributes (dict): The attributes of the device.
    """
    # Check if icon name in attributes has "-group" in it
    if "icon" in device_attributes:
        if "-group" in device_attributes["icon"]:
            return True
        else:
            return False
    else:
        return False


def get_device_info(devices_list, device_id):
    return [x for x in devices_list if x["id"] == device_id][0]


def get_percentage_brightness_from_ha_value(brightness):
    return round(int(brightness) / 255 * 100)


def get_ha_value_from_percentage_brightness(brightness):
    return round(int(brightness)) / 100 * 255


def search_for_device_by_id(devices_list, device_id):
    """Returns index of device or None if not found."""
    for i, dic in enumerate(devices_list):
        if dic["id"] == device_id:
            return i
    return None

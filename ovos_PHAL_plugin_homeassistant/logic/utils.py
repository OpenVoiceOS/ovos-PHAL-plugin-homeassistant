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
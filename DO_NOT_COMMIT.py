from ovos_utils.messagebus import FakeBus

from ovos_PHAL_plugin_homeassistant import HomeAssistantPlugin
# from ovos_PHAL_plugin_homeassistant.logic.connector import HomeAssistantWSConnector

token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJjNGQyODc4OGFlNmM0MWJiYTA2NGI1ZTRiODViOTg2NCIsImlhdCI6MTY4NDgwOTIzNCwiZXhwIjoyMDAwMTY5MjM0fQ.JST8RtlA0cKb_rC9Q5est0oJgIhHlD59J4o4gSpb3HU"
url = "ws://192.168.86.49:8123"
ha = HomeAssistantPlugin(bus=FakeBus(), config={"host": url, "api_key": token, "assist_only": True})


print("BREAK")

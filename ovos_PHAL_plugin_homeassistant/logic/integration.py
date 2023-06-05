from ovos_bus_client.message import Message
from youtube_search import YoutubeSearch
from pytube import YouTube


class Integrator:
    # Class handles the integration of the plugin with the rest of the system
    
    def __init__(self, bus, gui):
        """ Constructor 
        Args:
            bus (MessageBus): The PHAL interface bus.
            gui (GUIInterface): GUI interface
        """
        self.bus = bus
        self.gui = gui
        self.register_bus_listeners()
        
    def register_bus_listeners(self):
        self.bus.on('ovos.phal.plugin.homeassistant.integration.query_media',
                    self.handle_query_media)
        
    def handle_query_media(self, message: Message):
        """ Handle a query to the media. 
        Args:
            message (Message): The message from the bus.
        """
        collected_results = []
        phrase = message.data.get("phrase")
        results = YoutubeSearch(phrase)
        results = results.to_dict()
        for result in results:
            collected_results.append(result)
        if len(collected_results) > 3:
            collected_results = collected_results[:3]
        tube_prefix = "https://www.youtube.com/watch?v="
        for result in collected_results:
            yt = YouTube(tube_prefix +
                         result["id"]).streams.filter(progressive=True,
                                                      file_extension='mp4')
            stream = yt.first()
            result["stream_url"] = stream.url

        self.gui.send_event(
            "ovos.phal.plugin.homeassistant.integration.query_media.result",
            {"results": collected_results})
         

        


import asyncio
import json
import threading
# from typing import TypedDict, Union

import requests
import websockets
from ovos_utils.log import LOG


class HomeAssistantClient:
    def __init__(self, url, token):
        self.url = url
        self.token = token
        self.websocket = None
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.response_queue = asyncio.Queue()
        self.event_queue = asyncio.Queue()
        self.id_list = []
        self.thread = threading.Thread(target=self.run)
        self.last_id = None
        self.event_listener = None
        self.authenticated = False

        self._device_registry = {}
        self._entity_registry = {}
        self._area_registry = {}

    async def authenticate(self):
        await self.websocket.send(f'{{"type": "auth", "access_token": "{self.token}"}}')
        message = await self.websocket.recv()
        LOG.debug(message)
        if isinstance(message, list):
            LOG.warning(f"expected json string, got: {message}")
        message = json.loads(message)
        if message.get("type") == "auth_ok":
            self.authenticated = True
            await self.listen()
        else:
            self.authenticated = False
            LOG.error("WS HA Connection Failed to authenticate")
            return

    async def _connect(self):
        try:
            uri = f"{self.url}/api/websocket"
            self.websocket = await websockets.connect(uri)

            # Wait for the auth_required message
            message = await self.websocket.recv()
            LOG.debug(message)
            if isinstance(message, list):
                LOG.warning(f"expected json string, got: {message}")
                return
            message = json.loads(message)
            if message.get("type") == "auth_required":
                await self.authenticate()
                if not self.authenticated:
                    return
            else:
                raise Exception("Expected auth_required message")
        except Exception as e:
            LOG.exception(e)
            await self._disconnect()
            return

    async def _disconnect(self):
        if self.websocket is not None:
            await self.websocket.close()
            self.websocket = None

    async def listen(self):
        while self.websocket is not None:
            message = await self.websocket.recv()
            if isinstance(message, list):
                LOG.warning(f"expected json string, got: {message}")
                continue
            message = json.loads(message)
            # Below log will print a state update for each device periodically
            # LOG.debug(f"Received message with keys: {message.keys()}")
            if message.get("type") == "event":
                if self.event_listener is not None:
                    self.event_listener(message)
                else:
                    await self.event_queue.put(message)
            else:
                await self.response_queue.put(message)

    async def send_command(self, command):
        id = self.counter
        self.last_id = id
        message = {
            "id": id,
            "type": command
        }
        await self.websocket.send(json.dumps(message))

    async def send_raw_command(self, command, args):
        id = self.counter
        self.last_id = id
        message = {
            "id": id,
            "type": command
        }

        if not args is None:
            for key, value in args.items():
                message[key] = value

        await self.websocket.send(json.dumps(message))
        response = await self.response_queue.get()
        self.response_queue.task_done()
        return response

    async def call_service(self, domain, service, service_data):
        id = self.counter
        self.last_id = id
        message = {
            "id": id,
            "type": "call_service",
            "domain": domain,
            "service": service,
            "service_data": service_data
        }
        await self.websocket.send(json.dumps(message))
        response = await self.response_queue.get()
        self.response_queue.task_done()
        return response

    async def get_states(self):
        await self.send_command("get_states")
        message = await self.response_queue.get()
        self.response_queue.task_done()
        if message.get("result") is None:
            LOG.info("No states found")
            return []
        else:
            return message["result"]

    async def subscribe_events(self):
        await self.send_command("subscribe_events")
        message = await self.response_queue.get()
        self.response_queue.task_done()
        return message

    async def get_instance(self):
        while self.websocket is None:
            await asyncio.sleep(0.1)
        return self

    async def build_registries(self):
        # First clean  the registries
        self._device_registry = {}
        self._entity_registry = {}
        self._area_registry = {}

        # device registry
        await self.send_command("config/device_registry/list")
        message = await self.response_queue.get()
        self.response_queue.task_done()
        for item in message["result"]:
            item_id = item["id"]
            self._device_registry[item_id] = item

        # entity registry
        await self.send_command("config/entity_registry/list")
        message = await self.response_queue.get()
        self.response_queue.task_done()
        for item in message["result"]:
            item_id = item["entity_id"]
            self._entity_registry[item_id] = item

        # area registry
        await self.send_command("config/area_registry/list")
        message = await self.response_queue.get()
        self.response_queue.task_done()
        for item in message["result"]:
            item_id = item["area_id"]
            self._area_registry[item_id] = item

        return True

    @property
    def device_registry(self) -> dict:
        """Return device registry."""
        if not self._device_registry:
            asyncio.run_coroutine_threadsafe(
                self.build_registries(), self.loop)
            LOG.debug("Registry is empty, building registry first.")
        return self._device_registry

    @property
    def entity_registry(self) -> dict:
        """Return device registry."""
        if not self._entity_registry:
            asyncio.run_coroutine_threadsafe(
                self.build_registries(), self.loop)
            LOG.debug("Registry is empty, building registry first.")
        return self._entity_registry

    @property
    def area_registry(self) -> dict:
        """Return device registry."""
        if not self._area_registry:
            asyncio.run_coroutine_threadsafe(
                self.build_registries(), self.loop)
            LOG.debug("Registry is empty, building registry first.")
        return self._area_registry

    @property
    def counter(self):
        if len(self.id_list) == 0:
            self.id_list.append(1)
            return 1
        else:
            new_id = max(self.id_list) + 1
            self.id_list.append(new_id)
            return new_id

    def set_state(self, entity_id, state, attributes):
        id = self.counter
        self.last_id = id
        data = {
            "id": id,
            "type": "get_state",
            "entity_id": entity_id,
            "state": state,
            "attributes": attributes
        }
        response = self._post_request(f"states/{entity_id}", data)
        return response

    def _post_request(self, endpoint, data):
        url = self.url.replace("wss", "https").replace("ws", "http")
        full_url = f"{url}{endpoint}"
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }
        response = requests.post(full_url, headers=headers, json=data)
        return response.json()

    def run(self):
        self.loop.run_until_complete(self._connect())
        LOG.info(f"self.loop.is_running={self.loop.is_running()}")

    def connect(self):
        self.thread.start()

    def disconnect(self):
        asyncio.run_coroutine_threadsafe(self._disconnect(), self.loop)
        self.thread.join()

    def get_states_sync(self):
        task = asyncio.run_coroutine_threadsafe(self.get_states(), self.loop)
        return task.result()

    def subscribe_events_sync(self):
        task = asyncio.run_coroutine_threadsafe(
            self.subscribe_events(), self.loop)
        return task.result()

    def get_instance_sync(self):
        task = asyncio.run_coroutine_threadsafe(self.get_instance(), self.loop)
        return task.result()

    def get_event_sync(self):
        task = asyncio.run_coroutine_threadsafe(
            self.event_queue.get(), self.loop)
        return task.result()

    def build_registries_sync(self):
        task = asyncio.run_coroutine_threadsafe(
            self.build_registries(), self.loop)
        return task.result()

    def register_event_listener(self, listener):
        self.event_listener = listener

    def unregister_event_listener(self):
        self.event_listener = None

    def send_command_sync(self, command, args=None):
        task = asyncio.run_coroutine_threadsafe(
            self.send_raw_command(command, args), self.loop)
        return task.result()

    def call_service_sync(self, domain, service, service_data):
        task = asyncio.run_coroutine_threadsafe(
            self.call_service(domain, service, service_data), self.loop)
        return task.result()


# class AssistRestMessage(TypedDict):
#     """Expected JSON structure for Assist API.

#     text (str): Input sentence.

#     language (str): Optional. Language of the input sentence (defaults to configured language in Home Assistant).

#     conversation_id (str): Optional. Unique id to track conversation. Generated by Home Assistant.

#     https://developers.home-assistant.io/docs/intent_conversation_api
#     """
#     text: str
#     language: Union[str, None]
#     conversation_id: Union[str, None]


# class AssistWebsocketMessage(AssistRestMessage):
#     """Expected JSON structure for Assist Websocket API.

#     text (str): Input sentence.

#     type (str): API to send message. In this case, it should be "conversation/process"

#     language (str): Optional. Language of the input sentence (defaults to configured language in Home Assistant).

#     conversation_id (str): Optional. Unique id to track conversation. Generated by Home Assistant.

#     https://developers.home-assistant.io/docs/intent_conversation_api
#     """
#     type: str  # "conversation/process"

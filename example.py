import sys
import time
import os
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
from threading import Thread
from playsound import playsound
from typing import Any

# audio_playing = False


class MyHandler(PatternMatchingEventHandler):
    audio_playing: bool = False
    cached_file: str = ""
    cached_timestamp: Any = 0

    def _dispatch_audio_sample(self):
        sample = self.cached_file.split(" ")[0]
        print(sample)
        if sample == "ichigeki":
            playsound("ichigeki.wav")
        else:
            playsound("ha-ha.wav")

    def _check_cached_file(self, event):
        path = event.src_path
        mod_time_path = os.path.getmtime(path)
        if self.cached_timestamp == mod_time_path:
            return False
        with open(path, "r") as file:
            # breakpoint()
            data = file.read()
            if self.cached_file == data:
                return False
            else:
                self.cached_timestamp = mod_time_path
                self.cached_file = data
                return True

    def _play_audio_file(self):
        if not self.audio_playing:
            try:
                self.audio_playing = True
                self._dispatch_audio_sample()
            except Exception as e:
                self.audio_playing = False
                print(e)
            self.audio_playing = False

    def process(self, event):
        pass
        # print("I am being processed")

    def on_modified(self, event):
        # breakpoint()
        # print("file modified " + event.src_path)
        if self._check_cached_file(event):
            self._play_audio_file()
        self.process(event)


if __name__ == "__main__":
    args = sys.argv[1:]
    observer = Observer()
    observer.schedule(MyHandler(), path=args[0] if args else ".")
    print("Start")
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()

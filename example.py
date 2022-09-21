import sys
import time
import os
from watchdog.observers import Observer
from watchdog.events import PatternMatchingEventHandler
import pyaudio
import wave

from typing import Any


p = pyaudio.PyAudio()


def play_sample(sample_file_name):
    # you audio here
    wf = wave.open(sample_file_name, "rb")
    # define callback
    def callback(in_data, frame_count, time_info, status):
        data = wf.readframes(frame_count)
        return (data, pyaudio.paContinue)

    # open stream using callback
    return p.open(
        format=p.get_format_from_width(wf.getsampwidth()),
        channels=wf.getnchannels(),
        rate=wf.getframerate(),
        output=True,
        stream_callback=callback,
    )


class MyHandler(PatternMatchingEventHandler):
    audio_playing: bool = False
    stream: Any = None
    cached_file: str = ""
    cached_timestamp: Any = 0

    def _dispatch_audio_sample(self):
        # check if already exists?
        if self.stream:
            self.stream.stop_stream()
            self.stream.close()
        sample = self.cached_file.split(" ")[0]
        print(sample)
        if sample == "ichigeki":
            self.stream = play_sample("ichigeki.wav")
        else:
            self.stream = play_sample("ha-ha.wav")
        self.stream.start_stream()

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

    def on_modified(self, event):
        if self._check_cached_file(event):
            self._play_audio_file()
        self.process(event)


if __name__ == "__main__":
    args = sys.argv[1:]
    observer = Observer()
    observer.schedule(MyHandler(), path=args[0] if args else ".")
    print("Observer Working")
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()

    observer.join()

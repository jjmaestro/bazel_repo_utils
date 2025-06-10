"""defs"""

load(":repository.bzl", _archives = "archives")

visibility("public")

download_archives = _archives

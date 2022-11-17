all: help

help:
	@echo '✦ pub-get'
	@echo '✦ analyze'
	@echo '✦ publish-dry-run'
	@echo '✦ publish'

pub-get:
	@fvm flutter pub get

analyze:
	@fvm flutter analyze

publish-dry-run:
	@fvm flutter pub publish --dry-run

publish:
	@fvm flutter pub publish

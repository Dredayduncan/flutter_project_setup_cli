Flutter Project Setup CLI Changelog

## 0.0.2 - 03-09-2024

### Fixed
- Resolved an issue where CLI would fail to generate required files when outside the project directory
- Resolved an issue where firebase project creation failed

### Added
- Added tests for the create command
- Added tests for mason brick generations
- Added a delay after firebase project creation to allow for project provisioning before integrating it

## 0.0.1

- Implemented flutter_project_setup_cli create command template with specified args
- Implemented dynamic links, and JWT authentication setups
- Implemented State Management setup with Riverpod
- Implemented Notification setup with Firebase Cloud Messaging
- Implemented Firebase project integration
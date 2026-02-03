## 4.0.3

feat: Bump version to 4.0.3 and improve Firebase generation command robustness by handling empty configurations.

## 4.0.2

fix: update morpheme_lite to use morpheme 4.0.2

## 4.0.1

fix: generate class state bloc now using sealed class for json2dart command
fix: update generate config if firebase options are not provided

## 4.0.0

feat!: Major release with significant architectural refactoring and new features

- **Core Architecture**: Refactored entire codebase for improved modularity, introducing a new streamlined API, and updating all commands.
- **Platform Support**: Added support for Flutter 3.5+, Dart 3.0+, and multi-platform project generation (web, desktop).
- **JSON to Dart Generation**:
  - Implemented a new modular `Json2DartCommand` architecture with dedicated processors for CLI, generation orchestration, features, configuration, and file operations.
  - Added support for generating extra response models with 'Extra' suffixes, including advanced type inference for complex JSON structures and enhanced deserialization.
  - Refactored endpoint service to handle HTTP URLs and Uri methods more robustly.
- **Build System**: Consolidated build commands (`Apk`, `Appbundle`, `Ios`, `Ipa`, `Web`) under a `BuildCommandBase` for unified argument parsing and logic, simplifying the build process.
- **Extensibility**: Introduced a new plugin system.
- **Developer Experience**:
  - Enhanced error handling and reporting, including verbose flag for debug output.
  - Improved CLI with an interactive mode.
  - Added new testing framework integration, unit test generation, advanced debugging capabilities, and improved documentation generation.
  - Implemented new caching and dependency management systems.
- **Code Quality**: Performed extensive code formatting and styling adjustments across multiple files for better readability, consistency, and maintainability.
- **Security & Localization**: Enhanced security with new encryption features and added support for internationalization and advanced localization.
- **Bug Fixes**: Resolved all known critical issues, improving stability, reliability, and compatibility with the latest Flutter versions.
- **Chores**: Updated all dependencies to their latest versions and removed deprecated APIs and methods.
- **Configuration**: Introduced `Json2DartConfigManager` for configuration management and improved `pubspec.yaml` modification logic.

## 3.7.0

feat(json2dart): add cubit generation support for api implementation

- Add 'cubit' flag to command line arguments for JSON to Dart command
- Introduce isCubit boolean to control cubit generation
- Update argument parsing to handle cubit flag properly
- Integrate cubit update logic within json2dart generation workflow
- Implement updatePresentationCubit method to modify cubit files
- Add imports for bloc dependencies in cubit file if missing
- Update cubit constructor to include required bloc fields dynamically
- Insert bloc variables into cubit class if not already present
- Modify blocProviders method to include new bloc providers
- Modify blocListeners method to add listeners for new blocs
- Add listeners methods for blocs if missing with default handling
- Enhance dispose method to close all managed bloc instances
- Ensure cubit file is saved back after modifications

## 3.6.1

chore: bump version to 3.6.1 and update color2dart command handling

- update version in pubspec.yaml to 3.6.1
- modify morpheme.dart to reflect the new version
- fix lerp method in MorphemeColor class for better type handling
- add color2dart configuration options in init_command.dart

## 3.6.0

chore: bump version to 3.6.0 and add support for extra data model generation in json2dart command

- update version in pubspec.yaml to 3.6.0
- modify morpheme.dart to reflect the new version
- enhance json2dart command to include optional extra data model generation based on configuration

## 3.5.2

fix: correct formatting issues in generated code and improve consistency in json2dart command

- add trailing commas in emit statements for better readability
- update ignore_for_file comments to include prefer_single_quotes and prefer_double_quotes for code style consistency

## 3.5.1

- fix: improve null safety in copyWith method of json2dart command by conditionally adding nullable types

## 3.5.0

chore: update dependencies and versioning in pubspec files, enhance command handling, and improve code formatting

- bump version to 3.5.0 in pubspec.yaml
- update dependencies: args, yaml_writer, archive, intl, and lints
- fix trailing commas in generated code
- streamline command argument handling in page_command.dart
- adjust localization command for output consistency

## 3.4.1

- fix: correct formatting in cache strategy string representation and json2dart command parameter handling

## 3.4.0

- feat: add support for SSE methods and cache strategy handling in ApiCommand, improving API method flexibility and response management
- feat: add 'command-only' flag to RunCommand for previewing commands without execution

## 3.3.4

fix: update shorebird_helper to correctly retrieve flutter_version from the shorebird map

## 3.3.3

feat: implement completer for asynchronous handling in ${apiClassName}Bloc, ensuring proper event completion and stream management

## 3.3.2

refactor: streamline cancellation handling in ${apiClassName}Bloc by simplifying emitted state and enhancing event processing

## 3.3.1

refactor: simplify state classes in ApiCommand by removing body and headers, and enhance event handling for cancellation, pause, and resume actions

## 3.3.0

feat: enhance ApiCommand to support additional response types and state management, including cancellation and streaming capabilities

## 3.2.0

feat: add support for SSE and download methods in ApiCommand, enhancing response handling and stream management

## 3.1.0

feat: enhance json2dart command to support rawBody parameter and update props handling

## 3.0.0

feat!: update ${apiClassName}Bloc to extend MorphemeBloc instead of Bloc
fix: streamline asset command output handling library file

## 2.7.3

fix: update coverage command to use merge_lcov.info for coverage reporting

## 2.7.2

fix: prevent log clearing in CI/CD environments

## 2.7.1

fix: correct file reporter argument check in ModularHelper class

## 2.7.0

feat: add reporter and output file reporter options to TestCommand and CoverageCommand for customizable test result reporting

## 2.6.5

feat: add logging functionality to Loading class by appending messages to a log file
fix: add registerSetUp and registerTearDown in template test command

## 2.6.4

fix: streamline feature and page validation in template test command and improve bloc listener checks

## 2.6.3

fix add Flutter material import and update template test command for page integration

## 2.6.2

- feat enhance template test command with mock page class and improved bloc provider tests

## 2.6.0

- feat add RemoveTestCommand for deleting specific test helpers 
- enhance TestCommand with app, feature, and page options
- enhance CoverageCommand with app, feature, and page options

## 2.5.1

- enhance template test command with additional mock bloc tests and imports

## 2.5.0

- feat add TemplateTestCommand for generating template test code from json2dart.yaml

## 2.4.3

- fix enhance cache strategy handling for multipart requests in json2dart_command.dart

## 2.4.2

- fix json to dart conversion logic in json2dart_command.dart

## 2.4.1

- prevent fetching from closed Bloc

## 2.4.0

- add argument method in api for head method
- add argument return-data in api and json2dart
- add json2dart generate for return data with allowed (model (default), header, body_bytes, body_string, status_code, raw)
- fix unit test for generate with json2dart
- add argument format in json2dart
- add concurrent running for json2dart

## 2.3.2

- fix firebase command using service account json using firebase_command.sh

## 2.3.1

- fix firebase command using service account json using firebase_command.sh

## 2.3.0

- support firebase command using service account json

## 2.2.0

- support shorebird command
- add shorebird command for release and patch

## 2.1.0

- add parameter output in firebase command

## 2.0.3

- adjust print message logs in modular helper

## 2.0.2

- adjust print message logs not show when modular called

## 2.0.1

- adjust print message in loading helper and modular helper

## 2.0.0

- remove unused repository command
- add loading bar console for all command
- support flutter 3.27 / dart 3.6 monorepo with pub workspaces
- adjust print in modular helper

## 1.14.6

- fix json2dart generate response fromMap for data List number

## 1.14.5

- add copyWith in entity and constructor response and entity make to non required

## 1.14.4

- fix api command generate data model multipart without cache strategy
- fix json2dart generate data model mutlipart to Map<String, List<File>>

## 1.14.3

- change generate path dir endpoint endpoint to `core/lib/src/data/remote`

## 1.14.2

- change generate path dir endpoint endpoint to `core/src/data/remote`

## 1.14.1

- fix generate asset when generate for current module

## 1.14.0

- support generate color2dart for all flavor in the same time

## 1.13.1

- add command lcov --ignore-errors unused

## 1.13.0

- add command prebuild for android

## 1.12.15

- same datetime format response

## 1.12.10

- fix double comma in generate json2dart unit-test

## 1.12.8

- add argument generate only unit test in json2dart

## 1.12.3

- fix json2dart when generate list value null

## 1.12.2

- comment call repository in get command

## 1.12.1

- order git clone repo then generate l10n in get command

## 1.12.0

- add color2dart config from morpheme.yaml for color2dart_dir and output_dir

## 1.11.4

- git fetch first before pull in repository command

## 1.11.3

- add flow json2dart format, fix, then last format
- git fetch first before pull in repository command

## 1.11.2

- fix repository command to pull from remote

## 1.11.1

- fix repository command to pull from remote

## 1.11.0

- add new repository command to clone or pull from remote
- call repository command from get command when repository key in morpheme.yaml is exists

## 1.10.4

- fix morpheme cucumber command

## 1.10.3

- fix color2dart linter and generate library for color and theme

## 1.10.2

- fix support muliflavor for assets

## 1.10.1

- fix support muliflavor for assets

## 1.10.0

- add support muliflavor for assets, color2dart
- add support format command to spesific apps, feature or page
- add support fix command to spesific apps, feature or page
- add trailing coma in endpoint, api & json2dart command
- add argument device-id in run command and cucumber command
- change upgrade to upgrade-dependency command for upgrade dependency
- add upgrade command to upgrade version morpheme_cli

## 1.9.8

- add end comas , in locator api command
- order constructor first fromMap and toJson

## 1.9.7

- add end comas , in locator api command

## 1.9.6

- fix end of semicolon for generate locator

## 1.9.5

- fix end of semicolon for generate locator

## 1.9.4

- This reverts commit 4b0b02901c00c384ae21ecd2f87592efabcca9f9

## 1.9.3

- reset to 15d81f4aad964d4b8293e6e4039b6e75f9f49076

## 1.9.2

- fix cascade_invocations for locator api command
- make paralel generat json2dart

## 1.9.1

- make cascade_invocations for locator api command
- after generate json2dart do dart fix

## 1.9.0

- add fix command
- generate custom analysis_option.yaml when create core, feature and apps

## 1.8.4

- fixing path to for ios ic_launcher command

## 1.8.3

- fixing flavor order ic_launcher command

## 1.8.2

- add argument flavor for ic_launcher command

## 1.8.2

- add argument flavor for ic_launcher command

## 1.8.1

- fix copy directory ic-launcher command

## 1.8.0

- add ic-launcher command for copy ic_launcher spesific platform
- generate apps, core and feature with customize dev dependency

## 1.7.0

- support generate json2dart method patchMultipart

## 1.6.0

- add download command

## 1.5.0

- add boolean get state isInitial, isLoading, isFailed & isSuccess in generate api
- fix show print error when error loadYaml

## 1.4.4

- fix generate locator if setup locator is future
- add after command endpoint & asset with morpheme format

## 1.4.3

- fix generate l10n when template file is not exist

## 1.4.2

- fix async command wait until done
- throw error if exit code > 0

## 1.4.1

- hotfix generate domain repository json2dart

## 1.4.0

- add generate headers in json2dart

## 1.3.3

- hotfix generate endpoint with json2dart

## 1.3.2

- hotfix async function and format specific generated json2dart

## 1.3.1

- hotfix generate mapper in json2dart

## 1.3.0

- add command rename file to standar snakecase with prefix or suffix
- fixing generate assets in subfolder

## 1.2.0

- add command to build web

## 1.1.1

- default init firebase is disable in morpheme.yaml

## 1.1.0

- remove dependency dcli
- add flag generate l10n in get, run, build, and cucumber command default to true
- change all method use dependency dcli to pure dart
- make better async method

## 1.0.0

- Initial version.

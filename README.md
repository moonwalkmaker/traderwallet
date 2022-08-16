# TraderWallet

TraderWallet is building a non-custodial crypto wallet with advanced features including a built-in contract scanner, sniper bot, buy locks, and more.

In the spirit of transparency for our community, we are making our GitHub public so you can monitor our progress and development. 

Follow the instructions below to launch the TraderWallet application and view progress of the project towards the first milestone of the lite wallet. 

We have partnered with MoonWalk Financial to build, develop and design this ground-breaking piece of technology. Please email rob@moonwalk.financial or charlie@moonwalk.financial with any questions.

# Flutter project

*Open the `app` folder using Android Studio IDE

# Installing Flutter

1. [Download Flutter source](https://docs.flutter.dev/get-started/install/macos)
1. Unzip file
1. Create a folder called Developer at User directory (same as "~"): /Users/username and create Developer folder and move flutter unzipped folder to that
1. Add: ``` export PATH="$PATH:/Users/username/Developer/flutter/bin ``` to:
    1. nano ~/.bash_profile
    1. nano ~/.zshrc
    1. nano ~/.bashrc
    1. nano ~/.profile

# Run Flutter Commands

1. Version: ``` $ flutter --version ```
1. Missing Packages: ``` $ flutter doctor ```
1. Auto generate contract integration (update contract.abi.json on app/lib folder): ``` $ cd app && flutter pub run build_runner build ```

# Installing Missing Items

## Android

1. Install & Open Android Studio
1. Open Android Studio Preferences > Plugins > Browse Repository > Flutter Plugin : INSTALL IT
1. Now Android Studio shows up the Flutter option for projects

## Android bug fix

1. Android Studio Gradle warning: https://github.com/flutter/flutter/issues/29608#issuecomment-548649907
1. IF SHADER BUG: on emulator screen click on "..." icon > go to settings > tab advanced > change OpenGL ES API to "Compatibility"

## Visual Code

1. Install Flutter PlugIns
1. --> the emulators are displayed at the bottom on a blue lane


# Create flutter project

1. Create: ``` $ flutter create app_name ```
1. Run: ``` $ cd app_name && flutter run ```

# Running Mobile - Android

1. Emulators (show): ``` $ flutter emulators ```
1. Emulators (run): ``` $ flutter emulators --launch Pixel_4_API_30 (emulator_id) ```
1. Emulators (availables): ``` $ flutter devices ```
1. Running on openned emulator: ``` $ flutter run ```
1. Running on specific emulator: ``` $ flutter run -d emulator-5554 (emulator id) ```
1. Running on chrome: ``` $ flutter run -d chrome ```

# Running Mobile - iOS

1. Run command (if ios simuator not showing): ``` sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer ```
1. On  
1. Spotlight: type "simulator"
1. (second option) terminal type: open -a simulator

# Dart & Flutter

1. StatelessWidget: hard cache (doesn't change)
1. MaterialApp: configs do app (locale, theme, routes...)
1. On Dart the {} on parameter means optional param
1. "final" means an attr that must be initialized
1. "_" before class means private
1. To update the screen (drawign) must call the: setState(() {}) --> used to refresh the entire screen at once time
  1. --> receive a lambda (unnamed function)
1. What changes goes on Stateless
1. What is unchangable goes on State/Stateful
1. To enable the app to use the Device options like store an image need to create a request with a permission:
```
  final statuses = [
    Permission.storage
  ].request();
```
1. --> To add it request to the project:
  1. open pubspec.yaml (flutter permission handler on google > click on installing):
    ```yaml
      dependencies:
        permission_handler: ^8.3.0
    ```
  1. Click on "Pub get" to install the dependencies
  1. To add ANDROID PERMISSION:
    1. android > app > src > AndroidManifest.xml
    1. <uses-permission android:name="android.permission.WRITE_EXTERNAL...">
1. Adding Assets to Flutter:
  1. create an asset folder on root of the app
  1. uncomment "asset:" at "pubspec.yaml"
  ```yaml
    assets:
      - assets/
  ```
1. Flutter Wallet: https://medium.com/geekculture/crypto-wallet-app-using-flutter-and-solidity-9f67b0d0819f

# Smart Contract Interaction

Smart Contract Interaction Flutter
https://itnext.io/writing-dapps-with-flutter-solidity-27d0621fd01

Smart Contract Interaction Firebase
https://miro.medium.com/max/700/1*BXhP_Vt_XzBu3YnDQOXGLw.png

ERC20 Solidity
https://solidity-by-example.org/app/erc20/

# If Device Manager from Android Studio not openning

IntelliJ (Android Studio) wants to know what kind of project you have to show the right menus.

click left in file tree on the root node (project name)
MENU -> FILE -> PROJECT STRUCTURE
select left MODULES
hit + button to add ANDROID
hit OK Button
top of the root node (project name) select PROJECT... to see your old view

# Crypto Providers

As client we use the same Rainbow GraphQL client framework (at ReactNative it is known as Apollo at Flutter it is known as graphql-flutter) and same provider: TheGraph.

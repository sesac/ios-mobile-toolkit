# Rumblefish iOS Toolkit (RIT)

v. 1.0 BETA - May 24th, 2012

Copyright 2012, Rumblefish, Inc.

## License

This software is provided for free and is distributed under the Apache 2.0 license. See the license file for more details. The latest version of the Rumblefish iOS Toolkit can be downloaded at https://github.com/rumblefish/ios-mobile-toolkit.

## Terms of Use

Use of Rumblefish API is governed by the [Rumblefish API agreement](https://sandbox.rumblefish.com/agreement) and [Rumblefish Branding Requirements](https://sandbox.rumblefish.com/branding).

## What is the Rumblefish iOS Toolkit (RIT)?

The RIT demonstrates how to interact with Rumblefish’s API to search for and play music from Rumblefish’s music catalog. The RIT contains examples of how to browse by mood, playlist, and occasion as well as play tracks. For more info on Rumblefish’s API, checkout https://sandbox.rumblefish.com for documentation and examples.

## What Can I Do With the RIT?

Build music licensing into your iOS apps! The RIT is configured to use Rumblefish’s sandbox API environment which contains a limited number of Rumblefish tracks and can not issue commercial licenses or delivery high quality tracks for download. Contact us at developers@rumblefish.com when you are ready to set up a production portal to enable these features.

## Hacking on the code

This repository uses git submodules to pull in its dependencies. **Make sure to perform a recursive submodule initialization after cloning.**

    git clone git@github.com:rumblefish/ios-mobile-toolkit.git
    git submodule update --init --recursive
    

The `RumblefishMobileSDKDemo/` directory contains a demo project that uses the SDK. The `RumblefishMobileSDK/` directory contains the SDK project itself. Assuming the submodules in your clone are up-to-date, you should be able to simply build and hack on either project in Xcode in the usual manner.

## Using the SDK in your project

The Rumblefish iOS SDK is distributed as a static library with a companion resource bundle. This technique is described [here](http://www.galloway.me.uk/tutorials/ios-library-with-resources/).

- **Clone this repository onto your local machine as described above.** You may also add this repository as a submodule to your own project if you wish.
- **Add the SDK project to your workspace.** Drag `RumblefishMobileSDK/RumblefishMobileSDK.xcodeproj` in the Finder onto the Project Navigator of your project. The `RumblefishMobileSDK` project can be a subproject of your project, or a sibling in an `xcworkspace`; it's your call.
- **Add the SDK as a dependency of your app target.**
Select your project in the **Project Navigator**, then select your project's app target in the left sidebar of the project editor. Open the **Build Phases** tab, expand the **Target Dependencies** box, hit **+**, and select the `RumblefishMobileSDK` static library (listed under the project). Now the when you build your app, Xcode will build the Rumblefish SDK first.
- **Statically link your project against the SDK.** In the project editor, expand the **Link Binary With Libraries** box, hit **+**, and select `libRumblefishMobileSDK.a`.
- **Include the Rumblefish SDK resource bundle in your app's bundle.** Expand the **RumblefishMobileSDK.xcodeproj** project in the project navigator, then expand the **Products** group beneath it. Drag `RumblefishMobileSDKResources.bundle` onto the **Copy Bundle Resources** box. Don't worry if `RumblefishMobileSDKResources.bundle` is red.
- **Include the Rumblefish SDK header where you want to use it in your project.** Simply `#import "RumblefishMobileSDK/RumblefishMobileSDK.h"` and you're ready to start using the SDK. Take a look at `TestVC.m` in the demo project for an example of how to use the SDK.

## Where Do I Send Complaints, Praise, etc.?

To report a bug, please file an issue on GitHub, https://github.com/rumblefish/ios-mobile-toolkit/issues
For business questions and to set up a production portal, email us developers@rumblefish.com.



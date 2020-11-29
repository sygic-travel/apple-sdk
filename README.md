# Sygic Travel Apple SDK


**Sygic Travel Apple SDK** (stylised for Apple platforms as _TravelKit_) is a framework suitable for embedding a rich set of _Sygic Travel_ data within your application. It gives you access to millions of Places covering the entire world.

We build it as a generic platform project available on all Apple platforms.

For further details see [Full SDK documentation](http://docs.sygictravelapi.com/apple-sdk/latest/).

## Getting the SDK

### Installing via CocoaPods

Simply add a `TravelKit` pod to your `Podfile`. Then run `pod update` to fetch the SDK automatically.

### Getting the framework from GitHub

You can grab a released compiled SDK package or its source code on [GitHub](https://github.com/sygic-travel/apple-sdk). Check out the repository or grab it from the _Releases_ section.

## Development Requirements

All development requirements are actually recommendations as it reflects the environment we use to develop and distribute the code.

- Xcode 8.0+ (recommended)
- macOS 10.12+ SDK (recommended)
- iOS 10.0+ SDK (recommended)
- tvOS 10.0+ SDK (recommended)
- _Objective-C_ or _Swift_ project
- _API key_ for your business or project

## Production Deployment

Deployment requirements determine the minimal environments compatible with the SDK when you distribute it with your project.

- OS X/macOS 10.10+ target (_macOS framework_)
- iOS 8.2+ target (_iOS framework_)
- tvOS 9.0+ target (_tvOS framework_)

## Installation

- get the framework package
- unpack and add to your project
- link it as a dynamic framework (embedded binary) in your project settings

## Configuration

Actually the only step needed is obtaining an _API key_ you use to set up the framework before you start using it. [Contact us](https://travel.sygic.com/b2b) to get one.

## Quick Usage Introduction

This quick example shows how to use the SDK to fetch a representative set of data.

Let's define a set of Places we want:

- placed in _London_
- marked as _Points of interest_
- included in the _Sightseeing_ category
- only the _Top 10_ of them

```objc
// Hold an instance
TravelKit *kit = [TravelKit sharedKit];
	
// Set your API key
kit.APIKey = @"<YOUR_API_KEY_GOES_HERE>";
	
// Create query to get Top 10 Sightseeing Places in London
TKPlacesQuery *query = [TKPlacesQuery new];
query.parentIDs = @[ @"city:1" ];
query.levels = TKPlaceLevelPOI;
query.categories = TKPlaceCategorySightseeing;
query.limit = 10;
	
// Perform query and print a message containing the first item
[kit placesForQuery:query completion:^(NSArray< TKPlace *> *places, NSError *error){
	if (places.firstObject) NSLog(@"Let's visit %@!", places.firstObject.name);
	else NSLog(@"Something went wrong :/");
}];
```

```swift
// Set your API key
TravelKit.shared.apiKey = "<YOUR_API_KEY_GOES_HERE>"
	
// Create query to get Top 10 Sightseeing Places in London
let query = TKPlacesQuery()
query.parentIDs = ["city:1"]
query.levels = .POI
query.categories = [.sightseeing]
query.limit = 10
	
// Perform query and print a message containing the first item
TravelKit.shared.places.places(for: query) { (places, error) in
	if let place = places?.first { print("Let's visit \(place.name)!") }
	else { print("Something went wrong :/") }
}
```

The *API key* must be provided, otherwise using any methods listed below will result in an error being returned by the completion block.

*TravelKit* is very easily testable using _Swift Playgrounds_ – a sample playground is provided together with the workspace attached.

## Basic Classes

Class               | Description
:-------------------|:---------------------
**`TravelKit`**       | Singleton instance for fetching data
**`TKPlace`**         | Basic `Place` entity
**`TKPlacesQuery`**   | Entity used when querying for `Places`
**`TKTrip`**          | Primary `Trip` entity with detailed properties 
**`TKTour`**          | Basic `Tour` entity
**`TKToursViatorQuery`**    | Entity used when querying for `Tours` from _Viator_
**`TKToursGYGQuery`**    | Entity used when querying for `Tours` from _GetYourGuide_
**`TKMedium`**        | Basic `Medium` entity
**`TKReference`**     | External `Reference` link

## Documentation

Available on [Docs portal](http://docs.sygictravelapi.com/apple-sdk/latest/).

## License

This project is licensed under the terms of the MIT license. See the **LICENSE** file for details.

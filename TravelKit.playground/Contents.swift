//: Playground - noun: a place where people can play

/*:
# Hello playground!

A *simple* demo with _markup_ examples.
*/

//: Another **variable** of type __String__


//: This is also a Level 1 Heading

//: ------

//: ## This is a Level 2 Heading

//: ### This is a Level 3 Heading

/*:
## Countries
> 1. Brazil
> 2. Vietnam
> 3. Colombia

(the > symbol denotes a new section)
*/

/*:
## Points to Remember
* Empty lines end the single line comment delimiter block
* Comment content ends at a newline
* Commands that work in a comment block work in single line
* This **includes** text formatting commands
*/

/*:
This text is above the horizontal rule

---
And this is below
*/

/*: Setup and use a link reference.
[The Swift Programming Language]: http://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/ "Some hover text"

For more information, see [The Swift Programming Language].
*/

//: show Swift keywords such as `for` and `let` as monspaced font.

/*:
\* This is not a bullet item
* but this is a bullet item
*/

import Foundation
import TravelKit
import PlaygroundSupport

let travelKit = TravelKit.shared()
let printLock = NSLock()

travelKit.apiKey = "<YOUR_API_KEY_GOES_HERE>"

let destinationsQuery = TKPlacesQuery()
destinationsQuery.level = [ .city, .town ]
destinationsQuery.limit = 5

travelKit.places(for: destinationsQuery) { (places, error) in
	printLock.lock()
	print("\nTop Destinations:\n")
	places?.forEach({ (place) in
		print("\(place)")
	})
	printLock.unlock()
}

let sightsQuery = TKPlacesQuery()
sightsQuery.parentID = "city:1"
sightsQuery.level = .POI
sightsQuery.categories = ["sightseeing"]
sightsQuery.limit = 10

travelKit.places(for: sightsQuery) { (places, error) in
	printLock.lock()
	print("\nTop Sights in London:\n")
	places?.forEach({ (place) in
		print("\(place)")
	})
	printLock.unlock()
}

PlaygroundPage.current.needsIndefiniteExecution = true

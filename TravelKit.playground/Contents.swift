
/*:
# TravelKit playground

A *simple* 😎 demo playground with basic examples on how to use the **TravelKit SDK**.

Let's begin with some Playground necessities first:
*/

// Couple of imports
import Foundation
import TravelKit
import PlaygroundSupport

// Define indefinite execution so the Playground
// won't stop before the requests finish
PlaygroundPage.current.needsIndefiniteExecution = true

// Assign a shared instance to work with
let travelKit = TravelKit.shared

// Create a lock used for results printing sync
let printLock = NSLock()

/*:
## Setting up

Bringing the SDK to life is no big deal – all you need to provide is an API key.
*/

travelKit.apiKey = "<YOUR_API_KEY_GOES_HERE>"

/*:
## Fetching Destinations

For most of your future requests you'll often need some Destinations to work with. Here's an example call for some of them:
*/

let destinationsQuery = TKPlacesQuery()
destinationsQuery.levels = [ .city, .town ]
destinationsQuery.limit = 5

travelKit.places.places(for: destinationsQuery) { (places, error) in
	printLock.lock()
	print("\nTop Destinations:\n")
	places?.forEach({ (place) in
		print("\(place)")
	})
	printLock.unlock()
}

/*:
## Fetching Places with attributes

Making some more advanced queries is very simple as well. For example, here's a quick code fetching the best 10 POI Places in Sightseeing category in London:
*/

let sightsQuery = TKPlacesQuery()
sightsQuery.parentIDs = ["city:1"]
sightsQuery.levels = .POI
sightsQuery.categories = [.sightseeing]
sightsQuery.limit = 10

travelKit.places.places(for: sightsQuery) { (places, error) in
	printLock.lock()
	print("\nTop Sights in London:\n")
	places?.forEach({ (place) in
		print("\(place)")
	})
	printLock.unlock()
}

/*:
## Fetching Tours

Querying for some Tours users would like to attend is very easy as well:
*/

let toursQuery = TKToursViatorQuery()
toursQuery.parentID = "city:1"
toursQuery.sortingType = .price
toursQuery.descendingSortingOrder = true

travelKit.tours.tours(for: toursQuery) { (tours, error) in
	printLock.lock()
	print("\nMost Expensive Tours in London:\n")
	tours?.forEach({ (tour) in
		print("$\(tour.price ?? 0): \(tour.title)")
	})
	printLock.unlock()
}

/*:
[The Apple SDK Documentation]: http://docs.sygictravelapi.com/apple-sdk/latest/ "Apple SDK Documentation"

For more detailed digging in, see [The Apple SDK Documentation].
*/

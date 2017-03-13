//: Playground - noun: a place where people can play

import Foundation
import TravelKit
import PlaygroundSupport

let travelKit = TravelKit.shared()!
let printLock = NSLock()

travelKit.apiKey = "**REDACTED**"

let destinationsQuery = TKPlacesQuery()
destinationsQuery.level = .city
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

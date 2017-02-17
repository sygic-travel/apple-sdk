//: Playground - noun: a place where people can play

import Foundation
import TravelKit
import PlaygroundSupport

let printLock = NSLock()

let destinationsQuery = TKPlacesQuery()
destinationsQuery.type = .city
destinationsQuery.limit = 5

TravelKit.places(for: destinationsQuery) { (places, error) in
	printLock.lock()
	print("Top Destinations:")
	places?.forEach({ (place) in
		print("\(place)")
	})
	printLock.unlock()
}

let sightsQuery = TKPlacesQuery()
sightsQuery.parentID = "city:1"
sightsQuery.type = .POI
sightsQuery.categories = ["sightseeing"]
sightsQuery.limit = 10

TravelKit.places(for: sightsQuery) { (places, error) in
	printLock.lock()
	print("Top Sights in London:")
	places?.forEach({ (place) in
		print("\(place)")
	})
	printLock.unlock()
}

PlaygroundPage.current.needsIndefiniteExecution = true

//
//  TKDirectionDefinitions.h
//  TravelKit
//
//  Created by Michal Zelinka on 10/01/2018.
//  Copyright © 2018 Tripomatic. All rights reserved.
//

#ifndef TKDirectionDefinitions_h
#define TKDirectionDefinitions_h

#import <Foundation/Foundation.h>

/**
 The mode of transport used to indicate the mean of transportation between places.
 */
typedef NS_OPTIONS(NSUInteger, TKDirectionTransportMode) {
	TKDirectionTransportModeUnknown    = (0), /// Unknown mode.
	TKDirectionTransportModePedestrian = (1 << 0), /// Pedestrian mode.
	TKDirectionTransportModeCar        = (1 << 1), /// Car mode.
	TKDirectionTransportModePlane      = (1 << 2), /// Plane mode.
//	TKDirectionTransportModeBike       = (1 << 3), /// Bike mode.
//	TKDirectionTransportModeBus        = (1 << 4), /// Bus mode.
//	TKDirectionTransportModeTrain      = (1 << 5), /// Train mode.
//	TKDirectionTransportModeBoat       = (1 << 6), /// Boat mode.
}; // ABI-EXPORTED

/**
 An enum indicating options to fine-tune transport options. Only useful with Car mode.
 */
typedef NS_OPTIONS(NSUInteger, TKTransportAvoidOption) {
	TKTransportAvoidOptionNone        = (0), /// No Avoid options. Default.
	TKTransportAvoidOptionTolls       = (1 << 0), /// A bit indicating an option to avoid Tolls.
	TKTransportAvoidOptionHighways    = (1 << 1), /// A bit indicating an option to avoid Highways.
	TKTransportAvoidOptionFerries     = (1 << 2), /// A bit indicating an option to avoid Ferries.
	TKTransportAvoidOptionUnpaved     = (1 << 3), /// A bit indicating an option to avoid Unpaved paths.
}; // ABI-EXPORTED


// Basic values which might come handy to work with
#define kTKDistanceIdealWalkLimit     5000.0  //     5 kilometers
#define kTKDistanceMaxWalkLimit      50000.0  //    50 kilometers
#define kTKDistanceIdealCarLimit   1000000.0  //  1000 kilometers
#define kTKDistanceMaxCarLimit     2000000.0  //  2000 kilometers
#define kTKDistanceMinFlightLimit    50000.0  //    50 kilometers

#endif /* TKDirectionDefinitions_h */

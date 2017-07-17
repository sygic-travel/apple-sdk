# Caching

## General

All the cached stuff is held _session-only_ – that means it's not persistent and not available the next time the application initializes the kit.

## Places

`-placesForQuery:completion:` – cached using a `TKPlacesQuery` hash, keeping approx. last 256 unique queries

`-placesWithIDs:completion:` – cached using every single `placeID` keeping approx. last 200 objects

`-detailedPlaceWithID:completion:` – cached using the `placeID` given, keeping approx. last 200 objects

## Media

`-mediaForPlaceWithID:completion:` – cached using the `placeID` given, keeping approx. last 50 results

## Tours

`-toursForQuery:completion:` – cached using a `TKToursQuery` hash, keeping approx. last 32 unique queries

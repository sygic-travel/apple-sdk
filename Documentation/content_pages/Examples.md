# Examples

## Places module

### Get place detail

```objc
// Get and print the name and description of Eiffel Tower (poi:530)
TKPlacesManager *manager = [[TravelKit sharedKit] places];

[manager detailedPlaceWithID: @"poi:530" completion:^(TKDetailedPlace * _Nullable place, NSError * _Nullable error) {
    if (place) {
        NSString *description = place.detail.fullDescription.text;
        if (description) NSLog(@"Description of %@ is: %@", place.name, description);
        else NSLog(@"Something went wrong :/");
    }
}];
```

```swift
// Get and print the name and description of Eiffel Tower (poi:530)
TravelKit.shared.places.detailedPlace(withID: "poi:530", completion:{ (detailedPlace, err) in
    if let description = detailedPlace?.detail?.fullDescription?.text {
        print("Description of \(detailedPlace.name) is: \(description)")
    }
    else {
        print("Something went wrong :/")
    }
})
```

### Get place media

```objc
// Besides main media, we can get all media available for a certain place
TKPlacesManager *manager = [[TravelKit sharedKit] places];

[manager mediaForPlaceWithID:@"poi:530" completion:^(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error) {
    for (TKMedium *m in media) {
        NSString *title = m.title;
        // Print medium title if it has one
        if (title) NSLog(@"Title: %@", title);
        else NSLog(@"no title");
    }
    // To get the actual image from URL with certain size, we use method in TKMedium
    TKMedium *first = media.firstObject;
    [first displayableImageURLForSize:CGSizeMake(first.width, first.height)];
}];
```

```swift
// Besides main media, we can get all media available for a certain place
TravelKit.shared.places.mediaForPlace(withID: "poi:530", completion: { (media, err) in
    if let media = media, let first = media.first {
        // Print medium title if it has one
        for m in media {
            print("Title: \(m.title ?? "no title")")
        }
        // To get the actual image from URL with certain size, we use method in TKMedium
        first.displayableImageURL(for: CGSize(width: first.width, height: first.height))
    }
})
```

## Tours module

### Get tours

```objc
// Create query to to get 12 tours in London that take longer than 1 hour
TKToursGYGQuery *query = [TKToursGYGQuery new];
query.parentID = @"city:1";
query.minimalDuration = [NSNumber numberWithInt: 3600];
query.count = [NSNumber numberWithInt: 12];

TKToursManager *manager = [[TravelKit sharedKit] _tours];

// Perform query and print a message containing tour's title
[manager toursForGYGQuery:query completion:^(NSArray<TKTour *> * _Nullable tours, NSError * _Nullable error) {
    for (TKTour *t in tours) {
        NSString * title = t.title;
        if (title) NSLog(@"%@", title);
        else NSLog(@"no title");
    }
}];
```

```swift
// Create query to to get 12 tours in London that take longer than 1 hour
let query = TKToursGYGQuery()
query.parentID = "city:1"
query.minimalDuration = 3600
query.count = 12

// Perform query and print a message containing tour's title
TravelKit.shared._tours.tours(for: query) { (tours, err) in
    if let tours = tours {
        for tour in tours {
            print("\(tour.title)")
        }
    }
}
```

## Favorites module

### Favorite & unfavorite places

```objc
TKFavoritesManager *manager = [[TravelKit sharedKit] favorites];
// Add Eiffel Tower to favorites
[manager updateFavoritePlaceID:@"poi:530" setFavorite:TRUE];
// Get your favorites and print their IDs
NSLog(@"%@", [manager favoritePlaceIDs]);
// Remove Eiffel Tower from favorites
[manager updateFavoritePlaceID:@"poi:530" setFavorite:FALSE];
```

```swift
// Add Eiffel Tower to favorites
TravelKit.shared.favorites.updateFavoritePlaceID("poi:530", setFavorite: true)
// Get your favorites and print their IDs
print(TravelKit.shared.favorites.favoritePlaceIDs())
// Remove Eiffel Tower from favorites
TravelKit.shared.favorites.updateFavoritePlaceID("poi:530", setFavorite: false)
```

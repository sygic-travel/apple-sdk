# Examples

## Places
### Get place detail
```objc
// Get and print the name and description of Eiffel Tower (poi:530)
TKPlacesManager *manager = [TKPlacesManager sharedManager];

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
TKPlacesManager.shared.detailedPlace(withID: "poi:530", completion:{ (detailedPlace, err) in
    if let detailedPlace = detailedPlace, let description = detailedPlace.detail?.fullDescription?.text {
        print("Description of \(detailedPlace.name) is: \(description)")
    }
    else {
        print("Something went wrong :/")
    }
})
```
### Get place media
```objc
// Besides mainMedia, we can get all medias available for certain place
[manager mediaForPlaceWithID:@"poi:530" completion:^(NSArray<TKMedium *> * _Nullable media, NSError * _Nullable error) {
    if (media) {
        for (int i = 0; i < [media count]; i++) {
            NSString * title = [media objectAtIndex:i].title;
            // Print medium title if it has one
            if (title) NSLog(@"Title: %@", title);
            else NSLog(@"no title");
        }
        // To get the actual image from URL with certain size, we use method in TKMedium
        TKMedium *first = media.firstObject;
        [first displayableImageURLForSize:CGSizeMake(first.width, first.height)];
    }
}];
```

```swift
// Besides mainMedia, we can get all medias available for certain place
TKPlacesManager.shared.mediaForPlace(withID: "poi:530", completion: { (media, err) in
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

## TKToursManager
### Get tours

```objc
// Create query to to get 12 tours in London that take longer than 1 hour
TKToursGYGQuery *query = [TKToursGYGQuery new];
query.parentID = @"city:1";
query.minimalDuration = [NSNumber numberWithInt: 3600];
query.count = [NSNumber numberWithInt: 12];

TKToursManager *manager = [TKToursManager sharedManager];

// Perform query and print a message containing tour's title
[manager toursForGYGQuery:query completion:^(NSArray<TKTour *> * _Nullable places, NSError * _Nullable error) {
    if (places) {
        for (int i = 0; i < [places count]; i++) {
            NSString * title = [places objectAtIndex:i].title;
            if (title) NSLog(@"%@", title);
            else NSLog(@"no title");
        }
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
TKToursManager.shared.tours(for: query) { (tours, err) in
    if let tours = tours {
        for tour in tours {
            print("\(tour.title)")
        }
    }
}
```

## TKFavoritesManager
### Favorite & unfavorite places

```objc
TKFavoritesManager *manager = [TKFavoritesManager sharedManager];
// Add Eiffel Tower to favorites
[manager updateFavoritePlaceID:@"poi:530" setFavorite:TRUE];
// Get your favorites and print their IDs
NSLog(@"%@", [manager favoritePlaceIDs]);
// Remove Eiffel Tower from favorites
[manager updateFavoritePlaceID:@"poi:530" setFavorite:FALSE];
```

```swift
// Add Eiffel Tower to favorites
TKFavoritesManager.shared.updateFavoritePlaceID("poi:530", setFavorite: true)
// Get your favorites and print their IDs
print(TKFavoritesManager.shared.favoritePlaceIDs())
// Remove Eiffel Tower from favorites
TKFavoritesManager.shared.updateFavoritePlaceID("poi:530", setFavorite: false)
```

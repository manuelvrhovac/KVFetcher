#  Description

Subclass KVFetcher to create specific fetchers for things that take time to load. Some examples: images from Photos library, images from internet, JSON objects, audio files, reading files from disk. It could also be used to carry out closure operation synchronously.

### Key and Value

**Key**: Like in dictionary you use keys to fetch (download, calculate, retrieve) a value.
**Value**: Result of fetch operation

## KVFetcher
Subclass this and define the fetching operation so you can fetch values for keys. A good example would be a fetcher that would fetch the image for PHAsset object in user's photos library.

## KVFetcher.Caching
A version of KVFetcher with 'cacher' property used for automatic caching of fetched values.

### Cacher
Cacher stores fetched values into a dictionary. It keeps track of when a value (for a key) has been added and its storage can be limited by item count or by special memory-calculating formula. A maximum age can be set. Cacher will automatically remove older entries to make room for newer ones.

### Limes
Defines the limit of cacher's storage. It could be by limiting the number of items or by examining used memory. In latter, a transformation block has to be supplied which calculates Value's memory footprint. 

> Example: an UIImage object doesn't have size property but it's memory footprint can be approximated by dimensions of image. Or if there's many images and their size is about the same, it could be limited by their count instead.

## KVFetcher.Caching.Active
Fetches and caches values for supplied keys in advance and according to specified options. 

> Example: it could be used in a web photo gallery - as the user swipes photos more photos can be pre-cached in the background. Pre-caching should be done for photos around currently viewed photo (with certain range and direction).

### ActiveFetchingOptions
Defines how background fetching will be executed - range, offset, direction, priority etc.

> Example: Caching images in advance is done around the current index etc. for the upcoming (direction) 10 (range) images starting from the previous (offset) image.

# Example

### Flag fetcher
Flag fetcher will be a subclass of cached KVFetcher. It will fetch an image for specific country iso string. For example, using "de" for key will fetch german flag image (value) and automatically cache it into the cacher's [Key:Value] dictionary. Next time "de" is used to fetch, closure will return immediately with the cached value.





```swift
/// Fetches flag image for iso code.
class FlagFetcher: KVFetcher<String, UIImage>.Caching {

override func _executeFetchValue(for key: String, completion: ((UIImage?) -> Void)!) {
let url = URL(string: "https://www.countryflags.io/\(key)/shiny/64.png")!
guard let data = try? Data(contentsOf: url) else {
print("Couldn't fetch data from internet")
return completion(nil)
}
guard let image = UIImage(data: data) else {
print("Fetched data is not image")
return completion(nil)
}
completion(image)
}
}

func testFlagFetcher() {
let flagFetcher = FlagFetcher(cacher: .init(limes: .count(max: 100)))

flagFetcher.fetchValue(for: "de") { flagImage in
guard let flagImage = flagImage else {
return print("Couldn't fetch flag image for Germany!")
}
print("Got flag image: \(flagImage)!")
}
}
```


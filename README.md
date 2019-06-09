
#  Description
Create a subclass of `KVFetcher<Key, Value>` to easily fetch and cache things that take time to load. Some examples: images from Photos library, images from the internet, JSON objects, reading files from disk... It can be used both asynchronously and synchronously!

**Key**: Identifier used to fetch (query, download, calculate, retrieve etc) a value
**Value**: Result of the fetch execution.

## KVFetcher<Key, Value>.Caching
Subclass of KVFetcher with a 'cacher' property included. Automatically caches values after fetching them.

> Example: Image (Value) fetched from internet for specific URLs (Key), can be cached so next time you try to fetch them, their cached versions will be returned instead.

### Cacher
Cacher is a subclass of KVCacher. It stores fetched values into a dictionary, keeping track of when a value (for a key) has been added. Its storage can be limited by item count or by memory footprint (and a formula that approximates it). Cacher will automatically remove older entries to make room for new ones. A maximum age can also be set.


### Cacher.Limit
Defines the limit of cacher's storage. It could be simply by counting or by examining used memory. In latter, a transformation block has to be supplied which calculates memory footprint for a given value (or key). 

> Example: an UIImage object's memory footprint can be approximated by its pixel dimensions. Or if there will be many images to cache and their size is about the same, cacher's storage could be simply limited by their count instead.


# Simple example: _FlagFetcher_
FlagFetcher fetches a flag image of some country using its ISO string. For example, using "de" as key will fetch german flag image as value and automatically cache it for future use. 

FlagFetcher is a subclass of `KVFetcher.Cached` class with String as Key and UIImage? as Value. Only the   `_executeFetchValue(for:completion:)` method had to be overridden:

```swift
class FlagFetcher: KVFetcher<String, UIImage?>.Caching {

override func _executeFetchValue(for key: String, completion: ((UIImage?) -> Void)!) {
let url = URL(string: "https://www.countryflags.io/" + key + "/shiny/64.png")!
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
```

> Note: Value is an `UIImage?`  (optional) because we can't be 100% sure that the network image fetch will be successful every time.

## Creating a FlagFetcher instance
Let's create an instance of FlagFetcher class that can hold 100 values (flag images) inside its cacher storage. Only one property needs to be initialized - cacher (and its storage limit).

```swift
let flagFetcher = FlagFetcher(cacher: .init(limit: .count(max: 100)))
```
## Using FlagFetcher's asynchronous fetch
Let's fetch the flag image for Germany by passing `"de"` as key to the `fetchValue(for:completion:)` method.
```swift
flagFetcher.fetchValue(for: "de", completion: { flagImage in
guard let flagImage = flagImage else {
return print("Couldn't fetch flag image for Germany!")
}
print("Got flag image: \(flagImage)!")
})
```

# Useful things:
### Retrieving values from cache and caching them manually

`.cacher.cachedValue(for: Key) -> Value?` 
Retrieves optional value from cache (nil if value was never fetched/cached).

`.cacher.has(cachedValueFor: Key)` 
Checks if there's a value cached for key.

`.cacher.cache(Value, removingAllowed: Bool, for: Key) -> Bool` 
Saves value to cache. When there's not enough space, cacher will remove older entries until it can cache it. Set `removingAllowed` to `false` to forbid this. Returned Bool (discardable) indicates if caching was successful.


### Fetching synchronously
There's also a method to fetch values synchronously. It's usable when the operations inside the execution method are synchronous themselves, or if you are already on a background thread.
```swift
let flagImage = flagFetcher.fetchSynchronously("de")!
print("Got flag image with size: \(flagImage.size)")
```

### Fetching synchronously using subscript [ ] 

Same as above you can also fetch synchronously by using square brackets:

```swift
let germanFlag = flagFetcher["de"]!
print("Got flag image with size: \(germanFlag.size)")
```


### Retrieving values from cache manually
If you fetched a value before, next time you fetch it a cached version will be returned. If you want to check if a value is already cached, use `.has(cachedValueFor:)`  method on the `.cacher` property.  Use  `.cachedValue(for:) -> Value?`  method to retrieve it (returns nil if it doesn't exist).




### Saving values to cache manually
Normally, when you fetch a value with KVFetcher.Cached subclass it will be cached automatically. If you want to cache some value manually, use  `.cache(_:for:)` method on the `.cacher` property.
```swift
let germanFlag = UIImage(named: "germany.png")!
flagFetcher.cacher.cache(germanFlag, for: "de")
```

### Fetch multiple values
Use `.fetchMultiple(keys:completion:)` method to fetch more than one value. Completion closure (handler) is called after all values have been fetched.


#  Description
Create a subclass of `KVFetcher<Key, Value>.Caching` to easily fetch and cache things that take time to load. Some examples: images from Photos library, images from the internet, JSON objects, reading files from disk... It can be used both asynchronously and synchronously!

`Key`: Identifier used to fetch (query, download, calculate, retrieve etc) a value
`Value`: Result of the fetch execution.
`ValueCompletion!` = `((Value)->Void)!` completion handler closure

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
    
    override func _executeFetchValue(for key: String, completion: ValueCompletion!) {
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

## Creating an instance
Let's create an instance of FlagFetcher class that can hold 100 flag images. Only one property needs to be initialized - cacher.

```swift
let flagFetcher = FlagFetcher(cacher: .init(limit: .count(max: 100)))
```
## Fetching a value 
Fetching (and auto-caching) is done with the `fetchValue(for: Key, completion: ValueCompletion!)` method. Let's fetch the German flag image by passing `"de"` for key:
```swift
flagFetcher.fetchValue(for: "de", completion: { flagImage in
    guard let flagImage = flagImage else {
        return print("Couldn't fetch flag image for Germany!")
    }
    print("Got flag image: \(flagImage)!")
})
```

> Note: `fetchValue(for:completion:)` method is asynchronous and the value is returned in the completion closure. Once fetched, the resulting value is cached and next time you try to fetch value for "de" the closure will execute synchronously.


# Useful things:

### Fetching synchronously
There's also a method to fetch values synchronously. It's nice to use when the operations inside the execution method are synchronous themselves, or if you are already on a background thread.
```swift
let flagImage = flagFetcher.fetchSynchronously("de")!
print("Got flag image with size: \(flagImage.size)")
```

### Fetching synchronously using subscript [ ] 
Same as above you can also fetch synchronously by using square brackets:

```swift
let germanFlag = flagFetcher["de"]!
print("Got flag image with size: \(germanFlag.size)")

### Fetch multiple values
Use `.fetchMultiple(keys:completion:)` method to fetch more than one value. Completion closure (handler) is called after all values have been fetched.
```
### Retrieving values from cache and caching them manually

`.cacher.cachedValue(for: Key) -> Value?` 
Retrieves optional value from cache (nil if value was never fetched/cached).

`.cacher.has(cachedValueFor: Key)` 
Checks if there's a value cached for key.

`.cacher.cache(Value, removingAllowed: Bool, for: Key) -> Bool` 
Saves value to cache. When there's not enough space, cacher will remove older entries until it can cache it. Set `removingAllowed` to `false` to forbid this. Returned Bool (discardable) indicates if caching was successful.



### Retrieving values from cache manually
If you fetched a value before, next time you fetch it a cached version will be returned. If you want to check if a value is already cached, use `.has(cachedValueFor:)`  method on the `.cacher` property.  Use  `.cachedValue(for:) -> Value?`  method to retrieve it (returns nil if it doesn't exist).




### Saving values to cache manually
Normally, when you fetch a value with KVFetcher.Cached subclass it will be cached automatically. If you want to cache some value manually, use  `.cache(_:for:)` method on the `.cacher` property.
```swift
let germanFlag = UIImage(named: "germany.png")!
flagFetcher.cacher.cache(germanFlag, for: "de")
```

# Bonus: Prefetching 

### `KVFetcher<Key, Value>.Caching.Active`

Subclass it to create a fetcher that has the possibility of pre-fetching values in background so they will be ready when requested later.
`
## Active (prefetching) FlagFetcher
Imagine the user viewing a web gallery of european flags - we could pre-fetch the upcoming 5 flags relative to the one currently displayed on the screen.

No need to subclass anything, we can just use the  .Active subclass on our existing `FlagFetcher` class! We just need to initialize it inside viewDidLoad():
- `keys:` list of all flag codes
- `currentIndex:` initial currently viewed flag index
- `options:` (range, offset and direction of pre-fetch)
- `cacher instance:` .unlimited in this case


```swift
class FlagViewer: UIViewController {
    
    var activeFlagFetcher: FlagFetcher.Active!
    var flagList = ["AT", "BE", "BG", "CY", "CZ", "DK", "EE", "FI", "FR", "DE"]
    
    override func viewDidLoad() {
        activeFlagFetcher = .init(keys: flagList,
                                  currentIndex: 0,
                                  options: .init(range: 5,
                                                 offset: 0,
                                                 direction: .upcoming),
                                  cacher: .unlimited)
        activeFlagFetcher.startPrefetching()
    }
    
    @IBAction func userSwiped() {
        activeFlagFetcher.currentIndex += 1
        //...
    }
    
    //...
}
```
The `startPrefetching()` method has to be called to start pre-fetching flags. 
The `currentIndex` property needs to be updated every time user swipes a flag, so our active fetcher knows which flags to pre-cache.

To stop pre-fetching, simply call the `stopPrefetching()` method.


![logo](https://github.com/manuelvrhovac/resources/blob/master/kvfetcher_logo.jpg?raw=true)
#  Description
Use `KVFetcher` and its subclasses to easily fetch, cache and even pre-fetch things that take time to load. Some examples: images from Photos library, images from the internet, JSON objects, reading files from disk... 

### Features:
- 🅿️ Protocol-oriented in its core
- ✳️ Simple KVFetcher class that's easy to subclass and use
- 📥 Automatically caches already fetched values
- 📤 Removes older cached values to make space for new
- ⏳ Active version that fetches values in advance (pre-fetching)

There's three classes you can use:
- `KVFetcher<Key, Value>` - base class, used to define and execute fetch
- `KVFetcher<Key, Value>.Caching` - has automatic caching features
- `KVFetcher<Key, Value>.Caching.Active` - can pre-fetch values in advance

`Key`: Identifier used to fetch (query, download, calculate, retrieve etc) a value
`Value`: Result of the fetch execution.
`ValueCompletion!` = `((Value)->Void)!` completion handler closure


## Cacher
Cacher is a subclass of KVCacher. It puts fetched values into a dictionary, keeping track of when a value (for a key) has been added. Its storage can be limited so Cacher may automatically remove older entries to make room for new ones. A maximum age of a cached value can also be set.


### Limit
Defines the limit of cacher's storage. It could be simply by counting or by examining used memory. In latter, a transformation block has to be supplied which calculates memory footprint for a given value (or key). 

> Example: an UIImage object's memory footprint can be approximated by its pixel dimensions. Or if there will be many images to cache and their size is about the same, cacher's storage could be simply limited by their count instead.


# Example: Fun with flags!
FlagFetcher fetches an image of some country's flag by its ISO string. It uses the  countryflags.io API. For example, using "de" as a key would fetch german flag image:

![](https://github.com/manuelvrhovac/resources/blob/master/Screenshot%202019-06-10%20at%2002.03.10.png?raw=true)

FlagFetcher is a simple subclass of `KVFetcher.Cached` class with String and UIImage as Key / Value. It automatically caches every fetched value. Only    `_executeFetchValue(for:completion:)` method had to be overridden:

```swift
class FlagFetcher: KVFetcher<String, UIImage?>.Caching {
    
    override func _executeFetchValue(for key: String, completion: ValueCompletion!) {
        let url = URL(string: "https://www.countryflags.io/\(key)/shiny/64.png")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data else {
                    print("Couldn't fetch data from internet")
                    return completion(nil)
                }
                guard let image = UIImage(data: data) else {
                    print("Fetched data is not image")
                    return completion(nil)
                }
                completion(image)
            }
        }.resume()
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
Fetching (and auto-caching) is done with the `fetchValue(for:,completion:)` method. Let's fetch the German flag image by passing `"de"` for key:
```swift
flagFetcher.fetchValue(for: "de", completion: { flagImage in
    guard let flagImage = flagImage else {
        return print("Couldn't fetch flag image for Germany!")
    }
    print("Got flag image: \(flagImage)!")
})
```

> Note: `fetchValue(for:completion:)` method is asynchronous and the value is returned in the completion closure. Once fetched, the resulting value is cached and next time you try to fetch value for "de" the closure will execute synchronously.


# Prefetching 

### `KVFetcher<Key, Value>.Caching.Active`

Subclass it to create a fetcher that has the possibility of pre-fetching values in background so they will be ready when requested later.


`
## Active (prefetching) FlagFetcher


<p align="center">
    <img src="https://github.com/manuelvrhovac/resources/blob/master/ezgif-4-27f160df5cca.gif?raw=true" width="890" alt="TinyConstraints"/>
</p>

Imagine the user viewing a web gallery of world flags. We could, for example, pre-fetch a range of flags starting from a flag before, up until 5 flags total. So for example while flag 31 is viewed; flags 30, 32, 33, and 34 would be prefetched.


![alt](https://github.com/manuelvrhovac/resources/blob/master/Screenshot%202019-06-10%20at%2001.44.22.png?raw=true)



How to implement this? Just add .Active to FlagFetcher's superclass!

```swift
													  +⇣
class FlagFetcher: KVFetcher<String, UIImage?>.Caching.Active {
```

 We can initialize it inside viewDidLoad() with the following parameters:
- `keys:` list of all flag codes
- `currentIndex:` initial currently viewed flag index
- `options:` (range, offset and direction of pre-fetch)
- `cacher:` instance of KVCacher, .unlimited in this case

> Note: Current and next key are prioritized. To avoid this, set .prioritizeCurrentAndNext to false in the options parameter.
```swift
class FlagViewer: UIViewController {
    
    var activeFlagFetcher: FlagFetcher!
    var flagList = [..., "FI", "AT", "BE", "HR", "FR", "DE", "GR", "EE", "FR"...]
    
    override func viewDidLoad() {
        activeFlagFetcher = .init(keys: flagList,
                                  currentIndex: 0,
                                  options: .init(range: 5, offset: 0, direction: .upcoming),
                                  cacher: .unlimited)
        activeFlagFetcher.startPrefetching()
    }
    
    @IBAction func userMovedOntoNextFlag() {
        activeFlagFetcher.currentIndex += 1
        displayNextFlag()
        //...
    }
    
    //...
}
```
The `startPrefetching()` method has to be called to start pre-fetching flags. 
The `currentIndex` property needs to be updated every time user swipes a flag, so our active fetcher knows which flags to pre-cache.

To stop pre-fetching, simply call the `stopPrefetching()` method.

## More practical examples:
- PHAsset -> UIImage fetcher (Photos)
- CLLocation -> CLPlacemark fetcher (CoreLocation)

# Other useful things:

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
```
### Fetch multiple values
Use `.fetchMultiple(keys:completion:)` method to fetch more than one value. Completion closure (handler) is called after all values have been fetched.



### Retrieving values from cache manually
If you fetched a value before, next time you fetch it a cached version will be returned. If you want to check if a value is already cached, use `.has(cachedValueFor:)`  method on the `.cacher` property.  Use  `.cachedValue(for:) -> Value?`  method to retrieve it (returns nil if it doesn't exist).




### Saving values to cache manually
Normally, when you fetch a value with KVFetcher.Cached subclass it will be cached automatically. If you want to cache some value manually, use  `.cache(_:for:)` method on the `.cacher` property.
```swift
let germanFlag = UIImage(named: "germany.png")!
flagFetcher.cacher.cache(germanFlag, for: "de")
```

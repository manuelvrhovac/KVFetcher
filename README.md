
![logo](https://github.com/manuelvrhovac/resources/blob/master/kvfetcher_logo.jpg?raw=true)

Use `KVFetcher` to easily fetch, automatically cache and even pre-fetch things that take time to load like fetching images from Photos library or the internet, reading files from disk, or executing some heavy calculations.

## Contents

- [Requirements](#requirements)
- [Description](#description)
- [Classes](#classes)
- - [KVFetcher](#kvfetcher-class)
- - [KVCacher](#kvcacher-class)
- [Protocols](#protocols)
- [Usage Examples](#caching)
- - [Caching Fetcher](#caching)
- - [Active Caching Fetcher](#active)
- [Installation](#installation)
- - [CocoaPods](#cocoapods)
- - [Carthage](#carthage)
- [License](#license)

## Requirements

- iOS 10.0+
- Xcode 10.0+
- Swift 4.2+

## Features:
- 🅿️ Protocol-oriented in its core
- ✳️ KVFetcher class that's easy to subclass and use
- 📥 Caching version that automatically caches fetched values
- 📤 Removes older cached values to make space for new
- ⏳ Active version that fetches values in advance (pre-fetching)

## Classes

<a id="classes"></a>
### KVFetcher Class
There's three versions you can use:
- **Fetcher** : `KVFetcher<Key, Value>`  base class
- **Caching Fetcher**: `KVFetcher<Key, Value>.Caching`  automatic caching features
- **Active Fetcher**: `KVFetcher<Key, Value>.Caching.Active`  can pre-fetch/pre-cache values in advance

`Key`: Identifier used to fetch a value
`Value`: Result of the fetch execution.
`ValueCompletion!` = `((Value)->Void)!` completion handler closure

> Note: You are **supposed to subclass** these and override the fetch execution method in order to create your own custom fetcher. 

### KVCacher Class
It puts fetched values into a dictionary, keeping track of when a value (for a key) has been added. Its storage can be limited so it may automatically remove older entries to make room for new ones. A maximum age of a cached value can also be set.

> Note: If you want to use a custom cacher in your cached/active fetcher, use `.CustomCached<Cacher: KVCacher>` instead of `.Cached`. This is a generic where you can define cacher's type.


#### Limit
Defines the limit of cacher's storage. It could be simply by counting or by examining used memory. In latter, a transformation block has to be supplied which calculates memory footprint for a given value (or key). 

> Example: an UIImage object's memory footprint can be approximated by its pixel dimensions. Or if there will be many images to cache and their size is about the same, cacher's storage could be simply limited by their count instead.

## Protocols 
If you're not a fan of subclassing or need to create more customized fetchers, you can implement these protocols inside your custom fetcher:
- `KVFetcher_Protocol`
- `KVFetcher_Caching_Protocol`
- `KVFetcher_Caching_Active_Protocol`

Same goes for your custom cacher:
- `KVCacher_Protocol`

## Usage Example: Caching Fetcher
<a id="caching"></a>
**FlagFetcher** is a cached fetcher that fetches an image of some country's flag by its ISO string. It uses the countryflags.io API. For example, "de" would fetch and cache the german flag:

![](https://github.com/manuelvrhovac/resources/blob/master/Screenshot%202019-06-10%20at%2002.03.10.png?raw=true)

FlagFetcher is a simple subclass of `KVFetcher.Cached` class with String and UIImage as Key / Value. It automatically caches every fetched value. Only    `_executeFetchValue(for:completion:)` method had to be overridden:

> Note: Value is `UIImage?`  (optional) because we can't be 100% sure that the network image fetch will be successful.
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

### Creating an instance
Let's create an instance of FlagFetcher class that can hold 100 flag images. It only has one property: cacher (instance of KVCacher<Key,Value>).

```swift
let flagFetcher = FlagFetcher(cacher: .init(limit: .count(max: 100)))
```
### Fetching a value 
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



## Usage Example: Active Caching Fetcher

<a id="active"></a>
<p align="center">
    <img src="https://github.com/manuelvrhovac/resources/blob/master/ezgif-4-27f160df5cca.gif?raw=true" width="890" alt="TinyConstraints"/>
</p>

Imagine the user viewing a web gallery of world flags. We could, for example, pre-fetch a range of flags starting from a flag before, up until 5 flags total. So for example while flag 31 is viewed; flags 30, 32, 33, and 34 would be prefetched.


![alt](https://github.com/manuelvrhovac/resources/blob/master/Screenshot%202019-06-10%20at%2001.44.22.png?raw=true)

How to implement this? Just change FlagFetcher's superclass to its .Active version! Now it has become an active caching fetcher.

```swift
													  +⇣
class FlagFetcher: KVFetcher<String, UIImage?>.Caching.Active {
```

Now aside just the cacher, FlagFetcher has three more properties:
- `keys:` list of all flag codes 
- `currentIndex:` initial currently viewed flag index
- `options:` (range, offset and direction of pre-fetch)


```swift
class FlagViewer: UIViewController {
    
    var activeFlagFetcher: FlagFetcher!
    var flagList = ["FI", "AT", "BE", "HR", "FR", "DE", "GR", "EE", "FR"]
    
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
`startPrefetching()`  has to be called to start pre-fetching flags.  The `currentIndex` property needs to be updated every time user swipes a flag, so our active fetcher knows which flags to pre-cache. To stop pre-fetching, simply call the `stopPrefetching()` method.

## More practical examples:
- PHAsset -> UIImage fetcher (Photos)
- CLLocation -> CLPlacemark fetcher (CoreLocation)

# Some nice-to-have's:


### Fetching synchronously

Use `.fetchSynchronously(_:)` to fetch values synchronously (blocking the main thread until value is returned). It's nice to use when the operations inside the execution method are synchronous themselves, or if you are already on a background thread.

```swift

let flagImage = flagFetcher.fetchSynchronously("de") // returns UIImage?

print("Got flag image with size: \(flagImage!.size)")

```



#### Using subscript [ ]

Shorter way to fetch synchronously - using square brackets. Careful, as it force-unwraps the value!



```swift

let germanFlag = flagFetcher["de"] // returns UIImage

print("Got flag image with size: \(germanFlag.size)")

```

### Fetch multiple values

Use `.fetchMultiple(keys:completion:)` method to fetch more than one value. Completion closure (handler) is called after all values have been fetched.

#### Synchronously

Similar to above, use `.fetchMultipleSynchronously(keys:)` to fetch multiple values synchronously (blocking the main thread until value is returned). 

#### Using subcript []

To avoid having an array inside subscript (looks messy), only a range can be used as subscript to fetch multiple values. To make things simple, Key has to be Int. Example is a fetcher that feches assets from `PHFetchResult<PHAsset>` object:

```swift
let myAssets: [PHAsset] = assetFetcher[0..<100] // returns array of PHAsset ready to use
```

### Retrieving values from cache manually
Use `.cachedValue(for:)` on `cacher` property of a caching fetcher to retrieve a value from the cache (given it has been fetched/cached before). In case it doesn't exists nil is returned. Use `.has(cachedValueFor:)` to check for existance.
```swift
if let germanFlag = flagFetcher.cacher.cachedValue(for: "de"){
	print("🇩🇪 exists in the cache! \(germanFlag.size)")
}
```



### Saving values to cache manually
Use  `.cache(_:for:)` method on the `.cacher` property to save a value to cache. No need to use this after fetching because when you fetch a value with KVFetcher.Cached subclass it will be cached automatically.
```swift
let germanFlag = UIImage(named: "germany.png")!
flagFetcher.cacher.cache(germanFlag, for: "de")
```

  
## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. To integrate KVFetcher into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'KVFetcher', '~> 0.9.0'
end
```

Then run `pod install` command inside Terminal.



### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate KVFetcher into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "manuelvrhovac/KVFetcher" ~> 0.8.0
```

Run `carthage update` to build the framework and drag the built `KVFetcher.framework` into your Xcode project.

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate KVFetcher into your project manually.


## License

KVFetcher is released under the MIT license. See LICENSE for details.


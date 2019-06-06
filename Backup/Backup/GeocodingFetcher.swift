//
//  GeocodingFetcher.swift
//  KVFetcherFramework
//
//  Created by Manuel Vrhovac on 28/04/2019.
//  Copyright © 2019 Manuel Vrhovac. All rights reserved.
//

import Foundation
import MapKit

public enum GeocodeResult {
    case success(_ placemarks: [CLPlacemark])
    case error(_ error: Error)
}

public class GeocodeFetcher: KVFetcher<CLLocationCoordinate2D, GeocodeResult>.Caching.Active {
    
    var geocoder = CLGeocoder()
    
    init(maxCached: Int) {
        super.init(keys: { return [] }, currentIndex: { return 0 }, options: .none, cacher: .init(maxCount: 10))
        cacher.limes = .Count(max: 0)
        timeout = 3.0
    }
    
    public override func _executeFetchValue(for key: Key, completion: ValueCompletion?) {
        let location = CLLocation(latitude: key.latitude, longitude: key.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            completion?( error == nil ? .success(placemarks ?? []) : .error(error!) )
        }
    }
}

public class GeocodeManager {
    
    func go() {
        
        let fetcher = GeocodeFetcher(maxCached: 1000)
        let coordinates = (0...30).map { _ in CLLocationCoordinate2D.randomCentralEurope }
        for coordinate in coordinates {
            fetcher.fetchValue(for: coordinate, priority: .next) { value in
                print("Fetched value: \(value!)")
            }
        }
        fetcher.fetchMultiple(coordinates, cachingOptions: [], completion: nil)
        
    }
}

private class Geocoding {
    
    struct Options {
        
    }
    
    static let geocoder = CLGeocoder()
    
    static func geocode(coordinate: CLLocationCoordinate2D, completion: @escaping ([CLPlacemark]?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (placemarks, _) in
            mainThread {
                completion(placemarks)
            }
        }
    }
    
    static func titleAndSubtitle(
        for coordinate: CLLocationCoordinate2D,
        options: Options,
        completion: @escaping ((title: String?, subtitle: String?)) -> Void
        ) {
    }
}

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    static var randomCentralEurope: CLLocationCoordinate2D {
        return .init(latitude: .random(in: 2.0 ... 20.0), longitude: .random(in: 25.0 ... 40.0))
    }
}

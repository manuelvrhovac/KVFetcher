//

import Foundation

let backtick = "   `   " // `

func delayIf(_ condition: Bool, backgroundIf: Bool = false, _ seconds: Double, _ completion: @escaping () -> Void) {
    delay(if: condition, backgroundIf: backgroundIf, seconds, completion)
}

func delayBackground(if condition: Bool = true, _ seconds: Double, _ completion: @escaping ()-> Void) {
    delay(if: condition, backgroundIf: true, seconds, completion)
}

func delay(if condition: Bool = true, backgroundIf: Bool = false, _ seconds: Double, _ completion: @escaping () -> Void) {
    guard condition else { return }
    guard seconds > 0 else { return completion() }
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        if backgroundIf {
            backgroundThread {
                completion()
            }
        } else {
            mainThread {
                completion()
            }
        }
        
    }
}

func mainThread(if condition: Bool = true, closure: @escaping () -> Void) {
    guard condition else { return }
    DispatchQueue.main.async {
        closure()
    }
}

func backgroundThread(if condition: Bool = true, closure:@escaping () -> Void) {
    guard condition else { return }
    DispatchQueue.global(qos: .background).async {
        closure()
    }
}

extension Bool {
    
    static var random: Bool {
        return arc4random() % 2 == 0
    }
}

extension Double {
    
    /// Returns a random double between two specified numbers (irregardless > or <)
    static func randomBetween(_ d1: Double, until d2: Double) -> Double {
        return d2 > d1
            ? d1 + (d2 - d1) * random1
            : d2 + (d1 - d2) * random1
    }
    
    /// Returns a random doubel between self and d1 (irregardless > or <)
    func randomBetween(_ d1: Double) -> Double {
        return Double.randomBetween(d1, until: self)
    }
    
    /// Returns a random number between 0.0 and 1.0
    static var random1: Double {
        return Double(arc4random()) / Double(UINT32_MAX)
    }
}

extension Int {
    
    static var random: Int {
        return Int(arc4random() % UInt32.max)
    }
    
    /// Limits the number by some array count
    func overflow(byArray array: [Any]) -> Int? {
        return fixOverflow(count: array.count)
    }
    
    /// If count is 30 it will return: 5 for 5, 0 for 30, 1 for 31, 29 for -1, 0 16 for -14 etc...
    func fixOverflow(count: Int) -> Int {
        return self >= 0 ? (self < count ? self : self % count) : count-abs(self) % count
    }
    
    /// Returns yes if negative or equal/bigger than count.
    func isOverflown(count: Int) -> Bool {
        return self < 0 || self >= count
    }
    
}

extension Array where Element == String {
    // MARK: String
    var joinedWithNewline: String {
        return self.joined(separator: "\n")
    }
}

extension Array {
    
    mutating func shuffle() {
        for _ in 0 ..< ((!isEmpty) ? (count-1) : 0) {
            sort { (_, _) in arc4random() < arc4random() }
        }
    }
    
    var shuffled: Array {
        var a = self
        a.shuffle()
        return a
    }
    
    var nextToLast: Element? {
        if self.count < 2 { return nil }
        return self[self.count - 2]
    }
    
    var random: Element? {
        if isEmpty { return nil }
        return self[Int.random % count]
    }
    
    subscript (overflow index: Int) -> Element? {
        let i = index.fixOverflow(count: self.count)
        return self[safe: i]
    }
    
    @discardableResult
    mutating func removeFirstIfExists() -> Element? {
        guard !isEmpty else { return nil }
        return removeFirst()
    }
    
    @discardableResult
    mutating func removeLastIfExists() -> Element? {
        guard !isEmpty else { return nil }
        return removeLast()
    }
    
    func removingFirst() -> [Element] {
        var array = self
        array.removeFirstIfExists()
        return array
    }
    
    func removingLast() -> [Element] {
        var array = self
        array.removeLastIfExists()
        return array
    }
    
    /// Enumerates array and returns a dictionary with indexes as keys. Like: [0: array[0], 1: array[1]...]
    var enumeratedDic: [Int: Element] {
        return self.enumerated().map { $0 }.mapDic { ($0, $1) }
    }
    
    /// Returns array with elements successfully typecasted to specified type
    func compactMapAs<T: AnyObject>(_ type: T.Type) -> [T] {
        return compactMap { $0 as? T }
    }

    /// Converts array to dictionary using transform closure which should take each array element and return a (key,value) tuple. Value can be nil (optional).
    func mapDic<Key: Hashable, Value>(transform: (Element) -> (Key, Value)) -> [Key: Value] {
        var dic: [Key: Value] = [:]
        for element in self {
            let (key, value) = transform(element)
            dic[key] = value
        }
        return dic
    }
    
    /// Converts array to dictionary using transform closure which should take each array element and return a value. Array element are used as the key. Value can be nil (optional).
    func selfMapDic<U>( transform: (Element) -> (U?)) -> [Element: U] {
        return mapDic { ($0, transform($0)) } as! [Element: U]
    }
}

extension Array where Element: Equatable {
    
    func removingDuplicates() -> [Element] {
        var newArray = [Element]()
        for value in self {
            if newArray.contains(value) == false {
                newArray.append(value)
            }
        }
        return newArray
    }
}

extension Dictionary {
    
    var valuesArray: [Value] {
        return map { $0.value }
    }
    
    func valuesAs<T>(_ type: T.Type) -> [T] {
        return valuesArray.compactMap { $0 as? T }
    }
    
    /// Returns a new dictionary by converting it with transform closure that gives a (key,value) tuple and expects a new (key,value) tuple.
     func mapDic<T: Hashable, U>( transform: (Key, Value) -> (T, U)) -> [T: U] {
        var result: [T: U] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }
    
    
    /// Returns a new filtered dictionary using 'test' closure that gives a (key,value) tuple and expects a Bool.
     func filterDic( test: (Key, Value) -> (Bool)) -> [Key: Value] {
        var result: [Key: Value] = [:]
        for (key, value) in self where test(key, value) == true {
            result[key] = value
        }
        return result
    }
    
    subscript(optional optKey: Key?) -> Value? {
        return optKey.flatMap { self[$0] }
    }
    
    
     func mapDicThrow<T: Hashable, U>( transform: (Key, Value) throws -> (T, U)) rethrows -> [T: U] {
        var result: [T: U] = [:]
        for (key, value) in self {
            let (transformedKey, transformedValue) = try transform(key, value)
            result[transformedKey] = transformedValue
        }
        return result
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}

 extension Character {
    
    var isUpperCase: Bool {
        return String(self) == String(self).uppercased()
    }
    
    var isNumber: Bool {
        return self >= "0" && self <= "9"
    }
    
    var isLetter: Bool {
        return self >= "A" && self <= "z"
    }
    
    var isAlphaNumeric: Bool {
        return isNumber || isLetter
    }
    
}

extension NSString {
    
    var s: String { return self as String }
}

extension Optional where Wrapped == String {
    
    var isNilOrEmpty: Bool { return self == nil ? true : self!.isEmpty ? true : false }
}

extension CaseIterable {
    
    static var random: Self? {
        return Array(allCases).random
    }
}

extension Date {
    
    var getHour: Int {
        return Calendar.current.component(.hour, from: self)
    }
    
    var getMinute: Int {
        return Calendar.current.component(.minute, from: self)
    }
    
    var getSecond: Int {
        return Calendar.current.component(.second, from: self)
    }
    
    /// Returns day of month, for example 2019/05/27 returns 27.
    var getDay: Int {
        return Calendar.current.ordinality(of: .day, in: .month, for: self)!
    }
    
    /// Returns day of month, for example 2019/05/27 returns 27.
    var getDayOfMonth: Int {
        return Calendar.current.ordinality(of: .day, in: .month, for: self)!
    }
    
    /// Returns weekday index (Mon=1, Tue=2...).
    var getDayOfWeek: Int {
        let wd = Calendar.current.component(.weekday, from: self)
        return wd == 1 ? 7 : wd - 1
    }
    
    var getDayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self)!
    }
    
    var getWeekOfYear: Int {
        return Calendar.current.component(.weekOfYear, from: self)
    }
    
    /// Jan=1, Feb=2...
    var getMonth: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    var getYear: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// Removes hours/minutes/seconds from a date leaving it at exactly midnight (00:00:00)
    var getPureDate: Date {
        return Date.from(year: self.getYear, month: self.getMonth, day: self.getDayOfMonth)
    }
    
    var getSecondsInDay: Int {
        return self.getHour * 60 * 60 + self.getMinute * 60 + self.getSecond
    }
    
    func msSince(_ date: Date) -> Int {
        return Int(self.timeIntervalSince(date) * 1000)
    }
    
    
    static func from(year: Int, month: Int, day: Int) -> Date {
        return Date(year: year, month: month, day: day)
    }
    
    init(year: Int, month: Int, day: Int) {
        self = Date(Y: year, M: month, D: day, h: 0, m: 0, s: 0)
    }
    
    init(Y: Int, M: Int, D: Int, h: Int, m: Int, s: Int) {
        var dateComponents = DateComponents()
        dateComponents.year = Y
        dateComponents.month = M
        dateComponents.day = D
        dateComponents.hour = h
        dateComponents.minute = m
        dateComponents.second = s
        self = NSCalendar(calendarIdentifier: .gregorian)!.date(from: dateComponents)!
    }
    
    /// Adds x * 60 seconds
    func addingMinutes(_ m: Double) -> Date {
        return self.addingTimeInterval(m * 60)
    }
    
    /// Adds x * 60 seconds
    func addingMinutes(_ m: Int) -> Date {
        return addingMinutes(Double(m))
    }
    
    /// Adds x * 60 seconds
    func addingMinutes(_ m: Float) -> Date {
        return addingMinutes(Double(m))
    }
    
    /// Adds x * 86400 seconds
    func addingDays(_ d: Double) -> Date {
        return self.addingTimeInterval(d*86400.0)
    }
    
    /// Adds x * 86400 seconds
    func addingDays(_ d: Float) -> Date {
        return addingDays(Double(d))
    }
    
    /// Adds x * 86400 seconds
    func addingDays(_ d: Int) -> Date {
        return addingDays(Double(d))
    }
    
    /// Changes the day value in calendar, taking leap seconds into account.
    func addingCalendarDays(_ d: Int) -> Date {
        let cal = Calendar(identifier: .gregorian)
        return cal.date(byAdding: .day, value: d, to: self, wrappingComponents: true)!
    }
    
    /// Adds 86400 seconds
    var addingOneDay: Date {
        return self.addingTimeInterval(60.0 * 60.0 * 24.0)
    }
    
    
    /// Sets the miliseconds (if any) to 0.
    var strippingMilis: Date {
        let ti = self.timeIntervalSince1970
        return Date(timeIntervalSince1970: ti - ti.truncatingRemainder(dividingBy: 1.0))
    }
    
    /// Returns string in format "YYYY-MM-dd HH:mm:ss"
    var YYYYMMDDHHMMSS: String {
        return DateFormatter.yyyymmdd_hhmmss.string(from: self)
    }
    
    /// Returns string in format "YYYY-MM-dd"
    var YYYYMMDD: String {
        return DateFormatter.yyyymmdd.string(from: self)
    }
    
}

extension DateFormatter {
    
    convenience init(df: String) {
        self.init()
        dateFormat = df
    }
    
    /// "YYYY-MM-dd"
    static let yyyymmdd: DateFormatter = .init(df: "YYYY-MM-dd")
    
    /// "YYYY-MM-dd HH:mm:ss"
    static let yyyymmdd_hhmmss: DateFormatter = .init(df: "YYYY-MM-dd HH:mm:ss")
}

final class ControlAction: NSObject {
    
    private let _action: () -> Void
    init(action: @escaping () -> Void) {
        _action = action
        super.init()
    }
    @objc
    func action() {
        _action()
    }
}

/*
extension NumberFormatter {
 
    static func ordinal() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }
}

extension Int {
 
    var ordinal: String {
        return NumberFormatter.ordinal().string(from: NSNumber(value: self)) ?? String(self)
    }
}
*/

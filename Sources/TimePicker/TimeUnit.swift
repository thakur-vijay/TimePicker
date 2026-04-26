//
//  TimeUnit.swift
//  TimePicker
//
//  Created by Ventan Yu on 2026/2/9.
//

import Foundation

/// Represents time units used for duration measurement and localization.
enum TimeUnit: Hashable {
    case hours
    case minutes
    case seconds
    
    /// Returns the `UnitDuration` equivalent for Foundation's measurement system.
    /// This enables compatibility with `MeasurementFormatter` and unit conversions.
    var unit: UnitDuration {
        switch self {
        case .hours: .hours
        case .minutes: .minutes
        case .seconds: .seconds
        }
    }
    
    /// Defines the formatting style for unit display.
    /// Referenced the unit style of the system application "Clock - Timers".
    var unitStyle: Formatter.UnitStyle {
        switch self {
        case .hours: .long
        default: .medium
        }
    }
    
    /// Returns the localized unit symbol for a given numeric value.
    /// This ensures proper pluralization and locale-aware formatting.
    /// - Parameter value: The numeric value to determine proper pluralization.
    /// - Returns: Localized unit symbol without the numeric value.
    func localizedSymbol(_ value: Int) -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current // Respects user's locale for formatting
        formatter.unitStyle = unitStyle
        formatter.unitOptions = .providedUnit // Prevents automatic unit conversion
        
        // Create a measurement to leverage Foundation's localization
        let measurement = Measurement(value: Double(value), unit: unit)
        var formatted = formatter.string(from: measurement)
        
        // Extract only the unit symbol by removing the numeric part
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current // Match the number format with locale
        let numberString = numberFormatter.string(from: value as NSNumber)
        ?? "\(value)" // Fallback to plain string if formatting fails
        
        // Remove the numeric portion to isolate the unit symbol
        if let range = formatted.range(of: numberString) {
            formatted.removeSubrange(range)
        }
        
        // Some languages' localization includes spaces, remove them.
        return formatted.trimmingCharacters(in: .whitespaces)
    }
    
    /// Defines the valid input range for each time unit.
    var range: ClosedRange<Int> {
        0...upperBound
    }
    
    /// The maximum allowed value for each unit following standard time conventions.
    var upperBound: Int {
        switch self {
        case .hours: 23      // 24-hour format maximum
        case .minutes: 59    // Standard minute ceiling
        case .seconds: 59    // Standard second ceiling
        }
    }
}

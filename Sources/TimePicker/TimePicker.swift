// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A customizable SwiftUI view that displays a time picker with hours, minutes, and seconds.
///
/// `TimePicker` provides a minimal, wheel-style time selection interface.
/// You can customize its background style and bind to hour, minute, and second values.
///
/// Example:
/// ```swift
/// @State private var hours = 0
/// @State private var minutes = 0
/// @State private var seconds = 0
///
/// TimePicker(hours: $hours, minutes: $minutes, seconds: $seconds)
/// ```
///
/// - Note: Requires iOS 17.0 or later.
@available(iOS 17.0, *)
public struct TimePicker: View {
    
    /// The binding representing the selected hour value.
    @Binding var hours: Int
    
    /// The binding representing the selected minute value.
    @Binding var minutes: Int
    
    /// The binding representing the selected second value.
    @Binding var seconds: Int
    
    /// Creates a new instance of `TimePicker`.
    ///
    /// - Parameters:
    ///   - hours: A binding to the selected hour value.
    ///   - minutes: A binding to the selected minute value.
    ///   - seconds: A binding to the selected second value.
    public init(
        hours: Binding<Int>,
        minutes: Binding<Int>,
        seconds: Binding<Int>
    ) {
        self._hours = hours
        self._minutes = minutes
        self._seconds = seconds
    }
    
    /// Dynamically selects indicator configuration based on iOS version.
    /// Uses `.liquid` style on iOS 26+ for modern appearance,
    /// falls back to `.flatten` for compatibility.
    private var configuration: IndicatorConfiguration = {
        if #available(iOS 26, *) {
            return .liquid
        } else {
            return .flatten
        }
    }()
    
    /// The content and layout of the time picker.
    public var body: some View {
        HStack(spacing: 0) {
            Column(.hours, selection: $hours)
            Column(.minutes, selection: $minutes)
            Column(.seconds, selection: $seconds)
        }
        .offset(x: -22)
        .background {
            configuration.shape
                .fill(configuration.style)
                .frame(height: 35)
        }
        .padding(.horizontal, 15)
    }
}

@available(iOS 17.0, *)
private extension TimePicker {
    
    /// A single column component representing one time unit (hours, minutes, or seconds).
    /// Combines a number picker with an overlay showing the localized unit symbol.
    struct Column: View {
        let timeUnit: TimeUnit
        @Binding var selection: Int
        
        init(
            _ timeUnit: TimeUnit,
            selection: Binding<Int>,
        ) {
            self.timeUnit = timeUnit
            self._selection = selection
        }
        
        var body: some View {
            PickerWithoutIndicator(selection: $selection) {
                ForEach(timeUnit.range, id: \.self) { value in
                    Text(value.formatted())
                        .frame(width: 35, alignment: .trailing)
                        .tag(value)
                }
            }
            .overlay {
                let symbol = timeUnit.localizedSymbol(selection)
                Text(symbol)
                    // Referenced the font style of the system application "Clock - Timers"
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .frame(width: 50, alignment: .leading)
                    .lineLimit(1)
                    .offset(x: 46)
                    .animation(.smooth, value: symbol)
            }
        }
    }
}

@available(iOS 17.0, *)
public extension TimePicker {
    
    @MainActor
    struct IndicatorConfiguration {
        public var shape: AnyShape
        public var style: AnyShapeStyle
        
        public init<S: Shape, SS: ShapeStyle>(shape: S, style: SS) {
            self.shape = .init(shape)
            self.style = .init(style)
        }
        
        /// The style before iOS 26.
        public static let flatten: Self = .init(
            shape: .rect(cornerRadius: 10),
            style: .bar,
        )
        
        /// The style of iOS 26.
        public static let liquid: Self = .init(shape: .capsule, style: .bar)
    }
    
    /// Applies a custom indicator style configuration.
    func indicatorStyle(_ configuration: IndicatorConfiguration) -> Self {
        var content = self
        content.configuration = configuration
        return content
    }
    
    /// Applies a custom indicator style.
    func indicatorStyle<S: Shape, SS: ShapeStyle>(
        _ style: SS = .bar,
        in shape: S = .rect(cornerRadius: 10),
    ) -> Self {
        indicatorStyle(.init(shape: shape, style: style))
    }
}

// MARK: - View Extension for Sheet Presentation

@available(iOS 17.0, *)
public extension View {
    
    /// Presents a `TimePicker` as a sheet over the current view.
    ///
    /// - Parameters:
    ///   - confirmText: Localized string resource of confirm button title.
    ///   - isPresented: A binding that controls the visibility of the sheet.
    ///   - shape: The visual shape for the picker indicator background.
    ///   - style: The visual style for the picker indicator background. Defaults to `.bar`.
    ///   - hours: A binding to the selected hour value.
    ///   - minutes: A binding to the selected minute value.
    ///   - seconds: A binding to the selected second value.
    ///
    /// Example:
    /// ```swift
    /// @State private var showPicker = false
    /// @State private var hours = 0
    /// @State private var minutes = 0
    /// @State private var seconds = 0
    ///
    /// Button("Select Time") {
    ///     showPicker = true
    /// }
    /// .timePicker(
    ///     isPresented: $showPicker,
    ///     hours: $hours,
    ///     minutes: $minutes,
    ///     seconds: $seconds
    /// )
    /// ```
    @ViewBuilder
    func timePicker<S: Shape, SS: ShapeStyle>(
        _ confirmText: LocalizedStringResource = "Done",
        isPresented: Binding<Bool>,
        shape: S = .rect(cornerRadius: 10),
        style: SS = .bar,
        hours: Binding<Int>,
        minutes: Binding<Int>,
        seconds: Binding<Int>
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            VStack {
                Button(confirmText) {
                    isPresented.wrappedValue = false
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 16)
                .padding(.trailing, 25)
                
                TimePicker(
                    hours: hours,
                    minutes: minutes,
                    seconds: seconds
                )
                .indicatorStyle(style, in: shape)
            }
            .presentationDetents([.height(250)])
        }
    }
}

// MARK: - PickerWithoutIndicator

@available(iOS 17.0, *)
fileprivate struct PickerWithoutIndicator<Content: View, Selection: Hashable>: View {
    
    /// The currently selected value.
    @Binding var selection: Selection
    
    /// The content of the picker.
    @ViewBuilder var content: Content
    
    /// Tracks whether the default picker indicator lines have been hidden.
    @State private var isHidden: Bool = false
    
    /// The content and behavior of the custom picker.
    var body: some View {
        Picker("", selection: $selection) {
            if !isHidden {
                RemovePickerIndicator {
                    isHidden = true
                }
            } else {
                content
            }
        }
        .pickerStyle(.wheel)
    }
}

// MARK: - RemovePickerIndicator

/// A UIKit-based helper that removes the default indicator lines from `UIPickerView`.
fileprivate struct RemovePickerIndicator: UIViewRepresentable {
    
    /// Called after the picker indicators are successfully removed.
    var result: () -> ()
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Remove picker separator lines asynchronously to ensure view hierarchy is ready.
        DispatchQueue.main.async {
            if let pickerView = view.pickerView {
                if pickerView.subviews.count >= 2 {
                    pickerView.subviews[1].backgroundColor = .clear
                }
                result()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}

// MARK: - UIView Extension

fileprivate extension UIView {
    /// Recursively searches for the parent `UIPickerView` in the view hierarchy.
    var pickerView: UIPickerView? {
        if let view = superview as? UIPickerView {
            return view
        }
        return superview?.pickerView
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var hours = 0
    @Previewable @State var minutes = 0
    @Previewable @State var seconds = 0
    
    TimePicker(hours: $hours, minutes: $minutes, seconds: $seconds)
}

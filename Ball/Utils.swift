import Foundation
import SwiftUI

func remap(x: CGFloat, domainStart: CGFloat, domainEnd: CGFloat, rangeStart: CGFloat, rangeEnd: CGFloat, clamp: Bool = true) -> CGFloat {
    let domain = domainEnd - domainStart
    let range = rangeEnd - rangeStart
    let value = (x - domainStart) / domain
    let result = rangeStart + value * range
    if clamp {
        if rangeStart < rangeEnd {
            return min(max(result, rangeStart), rangeEnd)
        } else {
            return min(max(result, rangeEnd), rangeStart)
        }
    } else {
        return result
    }
}

extension Color {
    init(hex: UInt64, alpha: CGFloat = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8) / 255.0
        let b = Double((hex & 0x0000FF) >> 0) / 255.0
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }
}

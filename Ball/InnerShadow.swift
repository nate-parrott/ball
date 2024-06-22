import SwiftUI

struct InnerShadow<S: Shape>: View {
    var shape: S
    var color: Color
    var radius: CGFloat
    var offset: CGSize

    var body: some View {
        let padding: CGFloat = radius * 2
        color
            .padding(-padding)
            .reverseMask {
                shape
                    .padding(padding)
            }
            .shadow(color: color, radius: radius, x: offset.width, y: offset.height)
            .padding(-padding)
            .clipShape(shape)
            .drawingGroup() // force offscreen pass (otherwise doesn't render properly)
            .allowsHitTesting(false)
    }
}

// From https://www.fivestars.blog/articles/reverse-masks-how-to/

extension View {
  @ViewBuilder public func reverseMask<Mask: View>(
    alignment: Alignment = .center,
    cornerRadius: CGFloat = 0,
    @ViewBuilder _ mask: () -> Mask
  ) -> some View {
      self.mask {
          Group {
              if cornerRadius == 0 {
                  Rectangle()
              } else {
                  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
              }
          }
          .overlay(alignment: alignment) {
            mask()
              .blendMode(.destinationOut)
          }
      }

  }
}

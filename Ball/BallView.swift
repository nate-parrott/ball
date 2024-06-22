import SwiftUI

struct BallView<S: InsettableShape>: View {
    var shape: S
    var radius: CGFloat
    var color: Color

    var body: some View {
        ZStack {
            color

            RadialGradient(colors: [
                Color(hex: 0xACACAC),
                Color(hex: 0x585858),
            ], center: .init(x: 0.5, y: 0.3), startRadius: 0, endRadius: radius / (1 - 0.3))
            .blendMode(.luminosity)
            .frame(width: radius * 2, height: radius * 2)

            Image("Noise")
                .opacity(0.05)
                .blendMode(.multiply)

            shape.strokeBorder(Color.white.opacity(0.05), lineWidth: 4)
                .frame(width: radius * 2, height: radius * 2)

            Image("InnerShadow")
                .resizable()
                .frame(width: radius * 2, height: radius * 2)

            Image("Shine-Overlay")
                .resizable()
                .blendMode(.overlay)
                .frame(width: radius * 2, height: radius * 2)
        }
        .frame(width: radius * 2, height: radius * 2)
        .clipShape(shape)
        .drawingGroup()
//        .background(alignment: .bottom) {
//            Image("ContactShadow")
//                .resizable()
//                .frame(width: radius * 2.871, height: radius * 1.621)
//                .frame(width: 1, height: 1)
//                .offset(x: 0, y: radius * -0.164)
//                .opacity(shadowOpacity)
//        }
    }
}

struct BallView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            BallView(shape: Circle(), radius: 256, color: Color(hex: 0xF84E35))
                .padding(20)

            BallView(shape: Circle(), radius: 256, color: Color.red)
                .padding(20)

            BallView(shape: Circle(), radius: 256, color: Color.yellow)
                .padding(20)

            BallView(shape: Circle(), radius: 128, color: Color.yellow)
                .padding(20)

        }
            .background(.white)
    }
}

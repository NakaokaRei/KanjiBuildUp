#if os(iOS)
import SwiftUI
import PencilKit

/// A fixed coordinate space keeps strokes intact when rotating or resizing an iPad window.
private let writingSize = CGSize(width: 600, height: 280)

struct HandwritingView: View {
    @Binding var drawing: PKDrawing
    @State private var erasing = false
    @State private var confirmClear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("手書きの答え", systemImage: "pencil.tip").font(.subheadline.bold())
                Spacer()
                Button { drawing = PKDrawing(strokes: Array(drawing.strokes.dropLast())) } label: {
                    Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 44)
                }.accessibilityLabel("一画戻す").disabled(drawing.strokes.isEmpty)
                Button { confirmClear = true } label: {
                    Image(systemName: "trash").frame(width: 44, height: 44)
                }.accessibilityLabel("すべて消す").disabled(drawing.strokes.isEmpty)
            }
            Picker("筆記具", selection: $erasing) {
                Label("ペン", systemImage: "pencil.tip").tag(false)
                Label("消しゴム", systemImage: "eraser").tag(true)
            }.pickerStyle(.segmented)
            ZStack {
                Color.white
                if drawing.strokes.isEmpty {
                    Text("ここに書いてみましょう")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                        .allowsHitTesting(false)
                }
                WritingCanvas(drawing: $drawing, erasing: erasing)
            }
            .aspectRatio(writingSize.width / writingSize.height, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.green.opacity(0.3)))
            Text("ペンや指で入力できます。書かずに答えを見ることもできます。")
                .font(.caption).foregroundStyle(Palette.secondary)
        }
        .tint(Palette.green)
        .confirmationDialog("手書きの答えをすべて消しますか？", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("手書きを消去", role: .destructive) { drawing = PKDrawing() }
        }
    }
}

struct HandwritingPreview: View {
    let drawing: PKDrawing
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var body: some View {
        VStack(spacing: 8) {
            Text("あなたの答え").font(.caption).foregroundStyle(Palette.secondary)
            Image(uiImage: drawing.image(from: CGRect(origin: .zero, size: writingSize), scale: 2))
                .resizable().scaledToFit()
                .frame(maxHeight: verticalSizeClass == .compact ? 60 : 120)
                .accessibilityLabel("手書きで書いた答え")
                .accessibilityIdentifier("handwritingPreview")
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.green.opacity(0.2)))
    }
}

private struct WritingCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let erasing: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> CanvasContainer {
        let view = CanvasContainer()
        view.canvas.delegate = context.coordinator
        view.canvas.drawingPolicy = .anyInput
        view.canvas.isScrollEnabled = false
        view.canvas.backgroundColor = .clear
        view.canvas.isOpaque = false
        view.canvas.overrideUserInterfaceStyle = .light
        view.canvas.accessibilityIdentifier = "handwritingCanvas"
        view.canvas.accessibilityLabel = "手書きの解答欄"
        view.canvas.drawing = drawing
        return view
    }
    func updateUIView(_ view: CanvasContainer, context: Context) {
        context.coordinator.parent = self
        if view.canvas.drawing != drawing { view.canvas.drawing = drawing }
        view.canvas.tool = erasing ? PKEraserTool(.vector) : PKInkingTool(.pen, color: UIColor(Palette.ink), width: 5)
    }
    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: WritingCanvas
        init(_ parent: WritingCanvas) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            if parent.drawing != canvasView.drawing { parent.drawing = canvasView.drawing }
        }
    }
    final class CanvasContainer: UIView {
        let canvas = PKCanvasView()
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(canvas)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func layoutSubviews() {
            super.layoutSubviews()
            canvas.bounds = CGRect(origin: .zero, size: writingSize)
            let scale = bounds.width / writingSize.width
            canvas.transform = CGAffineTransform(scaleX: scale, y: scale)
            canvas.center = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }
}
#endif

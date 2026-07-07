//
//  CameraPreviewView.swift
//  AAC
//
//  Created by Arjunan on 18/04/26.
//


// CameraPreviewView.swift
import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

struct CamerasPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

class PreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

#elseif os(macOS)
import AppKit

struct CamerasPreviewView: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {}
}

class PreviewNSView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        previewLayer.frame = bounds
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func layout() {
        super.layout()
        previewLayer.frame = bounds
    }
}
#endif

struct DiagonalRotateView: View {
    @State private var rotated = false

    var body: some View {
        VStack {
            Text("3D")
                .font(.largeTitle)
                .bold()
                .frame(width: 150, height: 150)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .rotation3DEffect(
                    .degrees(rotated ? 180 : 0),
                    axis: (x: 1, y: 1, z: 0),
                    perspective: 0.6
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        rotated.toggle()
                    }
                }

            Text("Tap to rotate diagonally")
                .font(.caption)
        }
    }
}

#Preview {
    PageCurlViewNative()
}
struct PageView: View {
    var body: some View {
        PageCurlView(controllers: [
            UIHostingController(rootView: page("Page 1", .red)),
            UIHostingController(rootView: page("Page 2", .blue)),
            UIHostingController(rootView: page("Page 3", .green))
        ])
        .ignoresSafeArea()
    }

    func page(_ text: String, _ color: Color) -> some View {
        ZStack {
            color
                .ignoresSafeArea()
            Text(text)
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

import SwiftUI
import UIKit

struct PageCurlView: UIViewControllerRepresentable {

    var controllers: [UIViewController]

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .vertical,
            options: nil
        )

        pvc.dataSource = context.coordinator
        pvc.setViewControllers([controllers.first!], direction: .forward, animated: false)
        return pvc
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource {
        var parent: PageCurlView

        init(_ parent: PageCurlView) {
            self.parent = parent
        }

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let index = parent.controllers.firstIndex(of: vc), index > 0 else { return nil }
            return parent.controllers[index - 1]
        }

        func pageViewController(_ pvc: UIPageViewController,
                                viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let index = parent.controllers.firstIndex(of: vc),
                  index < parent.controllers.count - 1 else { return nil }
            return parent.controllers[index + 1]
        }
    }
}



struct CurlPageView<Content: View>: View {
    let pages: [Content]

    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(at: index, size: geo.size)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let threshold = geo.size.height * 0.25

                        if value.translation.height < -threshold && currentIndex < pages.count - 1 {
                            currentIndex += 1
                        } else if value.translation.height > threshold && currentIndex > 0 {
                            currentIndex -= 1
                        }

                        withAnimation(.easeOut) {
                            dragOffset = 0
                        }
                    }
            )
        }
    }

    private func pageView(at index: Int, size: CGSize) -> some View {
        let isCurrent = index == currentIndex
        let progress = dragOffset / size.height

        return pages[index]
            .frame(width: size.width, height: size.height)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            
            // 🔥 ONLY current page moves
            .offset(y: isCurrent ? dragOffset : 0)
            
            // 🔥 Optional curl-like rotation only for current page
            .rotation3DEffect(
                .degrees(isCurrent ? Double(progress * 90) : 0),
                axis: (x: 1, y: 0, z: 0),
                anchor: progress < 0 ? .bottom : .top,
                perspective: 0.6
            )
            
            // 🔥 Stack order: current on top
            .zIndex(isCurrent ? 1 : Double(-index))
    }
}

struct PageCurlViewNative: View {
    var body: some View {
        CurlPageView(pages: [
            Color.red.overlay(Text("Page 1").font(.largeTitle)),
            Color.blue.overlay(Text("Page 2").font(.largeTitle)),
            Color.green.overlay(Text("Page 3").font(.largeTitle))
        ])
        .ignoresSafeArea()
    }
}

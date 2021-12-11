//
//  STPopup+SwiftUI.swift
//  STPopup
//
//  Created by Kevin Lin on 07/12/2021.
//  Copyright © 2021 Sth4Me. All rights reserved.
//

#if canImport(SwiftUI)

import SwiftUI

public typealias PopupStyle = STPopupStyle

@available (iOS 13.0, *)
public extension View {
  func popup<ContentView>(
    isPresented: Binding<Bool>,
    style: PopupStyle = .formSheet,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder contentView: @escaping () -> ContentView
  ) -> some View where ContentView: View {
    overlay(
      // We don't need a binding for now. It's exposed as `Binding` so that we can change internal implementation
      // without affecting public API.
      PopupView(isPresented: isPresented.wrappedValue, style: style, onDismiss: onDismiss, contentView: contentView())
        .frame(
          width: isPresented.wrappedValue ? Self.windowSize.width : 0,
          height: isPresented.wrappedValue ? Self.windowSize.height : 0
        )
    )
  }
  
  // Window size is needed to properly layout content view when `sizeThatFits` is called.
  private static var windowSize: CGSize {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = scene.windows.first {
      return window.frame.size
    } else {
      return .zero
    }
  }
}

@available (iOS 13.0, *)
fileprivate struct PopupView<ContentView>: UIViewControllerRepresentable where ContentView: View {
  let isPresented: Bool
  let style: PopupStyle
  let onDismiss: (() -> Void)?
  let contentView: ContentView
  
  func makeUIViewController(context: Context) -> PopupViewController {
    return PopupViewController()
  }
  
  func updateUIViewController(_ popupViewController: PopupViewController, context: Context) {
    popupViewController.contentView = contentView
    popupViewController.isPresented = isPresented
    popupViewController.style = style
    popupViewController.onDismiss = onDismiss
    popupViewController.didUpdate()
  }
  
  class PopupViewController: UIViewController {
    var contentView: ContentView?
    var isPresented: Bool = false
    var style: PopupStyle = .formSheet
    var onDismiss: (() -> Void)?
    
    private var hostingController: UIHostingController<ContentView>?
    private var didAppear = false
    
    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      if let hostingController = hostingController, isPresented {
        hostingController.contentSizeInPopup = hostingController.sizeThatFits(in: view.bounds.size)
      }
    }
    
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      if !didAppear {
        didAppear = true
        didUpdate()
      }
    }
    
    func didUpdate() {
      guard isPresented else {
        if hostingController != nil {
          dismiss(animated: true) {
            if let onDismiss = self.onDismiss {
              onDismiss()
            }
          }
          hostingController = nil
        }
        return
      }
      guard let contentView = contentView, didAppear else {
        return
      }
      if let hostingController = hostingController {
        hostingController.popupController?.style = style
        hostingController.rootView = contentView
        hostingController.contentSizeInPopup = hostingController.sizeThatFits(in: view.bounds.size)
      } else {
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.contentSizeInPopup = hostingController.sizeThatFits(in: view.bounds.size)
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController
        
        let popupController = STPopupController(rootViewController: hostingController)
        popupController.style = style
        popupController.navigationBarHidden = true
        popupController.containerView.backgroundColor = .clear
        popupController.present(in: self)
      }
    }
  }
}

#endif

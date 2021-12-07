//
//  STPopup+SwiftUI.swift
//  STPopup
//
//  Created by Kevin Lin on 07/12/2021.
//  Copyright © 2021 Sth4Me. All rights reserved.
//

#if canImport(SwiftUI)

import SwiftUI

@available (iOS 14.0, *)
fileprivate struct PopupModifier<ContentView>: ViewModifier where ContentView: View {
  @Binding var isPresented: Bool
  let onDismiss: (() -> Void)?
  @ViewBuilder let contentView: () -> ContentView

  func body(content: Content) -> some View {
    content
      .fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
        PopupViewControllerRepresentable(isPresented: $isPresented, contentView: contentView())
      }
  }
}

@available (iOS 14.0, *)
public extension View {
  func popup<ContentView>(
    isPresented: Binding<Bool>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder contentView: @escaping () -> ContentView
  ) -> some View where ContentView: View {
    modifier(PopupModifier(isPresented: isPresented, onDismiss: onDismiss, contentView: contentView))
  }
}

@available (iOS 14.0, *)
fileprivate struct PopupViewControllerRepresentable<ContentView>: UIViewControllerRepresentable where ContentView: View {
  @Binding private var isPresented: Bool
  private let contentView: ContentView

  init(isPresented: Binding<Bool>, contentView: ContentView) {
    self._isPresented = isPresented
    self.contentView = contentView
    // Disable animation to avoid default full screen cover transition
    UIView.setAnimationsEnabled(false)
  }

  func makeUIViewController(context: Context) -> PopupViewController {
    // Re-enable animation for popup transition
    UIView.setAnimationsEnabled(true)
    return PopupViewController()
  }

  func updateUIViewController(_ popupViewController: PopupViewController, context: Context) {
    // Re-enable animation for popup transition
    UIView.setAnimationsEnabled(true)
    popupViewController.isPresented = $isPresented
    popupViewController.contentView = contentView
  }

  fileprivate class PopupViewController: UIViewController {
    var isPresented: Binding<Bool>!
    var contentView: ContentView! {
      didSet {
        guard let hostingController = hostingController else {
          return
        }
        hostingController.rootView = contentView
        hostingController.contentSizeInPopup = hostingController.sizeThatFits(in: view.bounds.size)
      }
    }

    private var hostingController: UIHostingController<ContentView>?
    private var didAppear = false

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      UIView.setAnimationsEnabled(true)
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      if !didAppear {
        didAppear = true
        removeBackgroundColor(in: view)

        let hostingController = UIHostingController(rootView: contentView!)
        hostingController.contentSizeInPopup = hostingController.sizeThatFits(in: view.bounds.size)
        self.hostingController = hostingController

        let popupController = STPopupController(rootViewController: hostingController)
        popupController.navigationBarHidden = true
        popupController.present(in: self)
      } else {
        if isPresented.wrappedValue {
          UIView.setAnimationsEnabled(false)
          isPresented.wrappedValue = false
        } else {
          dismiss(animated: false)
        }
      }
    }

    private func removeBackgroundColor(in view: UIView?) {
      guard let view = view, !(view is UIWindow) else {
        return
      }
      view.backgroundColor = .clear
      removeBackgroundColor(in: view.superview)
    }
  }
}

#endif

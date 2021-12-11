//
//  ContentView.swift
//  STPopupSwiftUIExample
//
//  Created by Kevin Lin on 26/11/2021.
//

import SwiftUI
import STPopup

struct ContentView: View {
  @State private var isPresentingFormSheetPopup = false
  @State private var isPresentingBottomSheetPopup = false
  @State private var showsAdditionalMessage = false
  
  var body: some View {
    NavigationView {
      List {
        Button("Show Popup(style = .formSheet)") {
          isPresentingFormSheetPopup = true
        }
        Button("Show Popup(style = .bottomSheet)") {
          isPresentingBottomSheetPopup = true
        }
      }
      .listStyle(.plain)
      .popup(isPresented: $isPresentingFormSheetPopup) {
        popupContent {
          isPresentingFormSheetPopup = false
        }
        .padding(.leading)
        .padding(.trailing)
        .background(Color.white)
        .cornerRadius(10)
      }
      .popup(isPresented: $isPresentingBottomSheetPopup, style: .bottomSheet) {
        VStack {
          HStack {
            Spacer()
          }
          popupContent {
            isPresentingBottomSheetPopup = false
          }
        }
        .background(
          VStack {
            HStack {
              Spacer()
            }
            Spacer()
          }
          .background(Color.white)
          .cornerRadius(10)
          .padding(.leading)
          .padding(.trailing)
        )
      }
      .navigationTitle("STPopup+SwiftUI")
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
          showsAdditionalMessage = true
        }
      }
    }
  }

  private func popupContent(action: @escaping () -> Void) -> some View {
    VStack(spacing: 10) {
      Image(systemName: "location")
        .font(.system(.largeTitle))
      Text("Location Service")
      if showsAdditionalMessage {
        Text("Tap to dismiss")
      }
      Button("Enable") {
        action()
      }
    }
    .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

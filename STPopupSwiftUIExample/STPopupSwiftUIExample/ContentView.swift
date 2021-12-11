//
//  ContentView.swift
//  STPopupSwiftUIExample
//
//  Created by Kevin Lin on 26/11/2021.
//

import SwiftUI
import STPopup

struct ContentView: View {
  @State private var isPresentingPopup = false
  @State private var showsAdditionalMessage = false
  
  var body: some View {
    Button("Show Popup") {
      isPresentingPopup = true
    }
    .padding()
    .popup(isPresented: $isPresentingPopup) {
      VStack(spacing: 10) {
        Image(systemName: "location")
          .font(.system(.largeTitle))
        Text("Location Service")
        if showsAdditionalMessage {
          Text("Tap to dismiss")
        }
        Button("Enable") {
          isPresentingPopup = false
        }
      }
      .padding()
      .padding(.leading)
      .padding(.trailing)
      .background(Color(.white))
      .cornerRadius(10)
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        showsAdditionalMessage = true
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

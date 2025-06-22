//
//  ParseView.swift
//  ParseGTARadio
//
//  Created by Alexey Vorobyov on 06.06.2025.
//

import SwiftUI

struct ParseView: View {
    @State var viewModel = ParseViewModel()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    ParseView()
}

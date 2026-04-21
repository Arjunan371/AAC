//
//  LaunchScreen.swift
//  AAC
//
//  Created by Arjunan on 15/04/26.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()
            Image(systemName: "gear")
                .font(.system(size: 50))
                .foregroundStyle(Color.blue)
        }
    }
}

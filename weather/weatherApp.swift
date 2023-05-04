//
//  weatherApp.swift
//  weather
//
//  Created by Noam on 5/2/23.
//

import SwiftUI
import ComposableArchitecture

@main
struct weatherApp: App {
    var body: some Scene {
        WindowGroup {
            LoadingForecastView(
                store: Store(
                    initialState: LoadingForecast.State(),
                    reducer: LoadingForecast()
                )
            )
        }
    }
}

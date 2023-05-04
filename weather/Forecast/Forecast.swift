import Foundation
import ComposableArchitecture
import SwiftUI

public struct Forecast: ReducerProtocol {
    //IMPROVEMENT: this is very bare-bone with no actions or logic just to demonstrate how this
    // can also be extended with behavior...
    @Dependency(\.searchClient) var searchClient

    public struct State: Equatable {
        let weatherResponse: WeatherResponse
    }
    
    public enum Action: Equatable {
    }
    
    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    }
    
}

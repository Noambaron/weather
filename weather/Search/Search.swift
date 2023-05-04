import ComposableArchitecture
import SwiftUI

public struct Search: ReducerProtocol {
    @Dependency(\.searchClient) var searchClient
    public struct State: Equatable {
        var textInput: String
        var searchResults: [Place]
        var error: String?
        
        init(textInput: String, searchResults: [Place]) {
            self.textInput = textInput
            self.searchResults = searchResults
        }
    }
    
    public enum Action: Equatable {
        case didChangeTextInput(String)
        case searchPlaces
        case newResults(TaskResult<[Place]>)
        case dismissError
        case exit(String)
    }
    
    
    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .didChangeTextInput(let input):
            state.textInput = input
            if input.isEmpty {
                state.searchResults = []
            }
            return .none
            
        case .searchPlaces:
            let input = state.textInput
            return .task(
                priority: .background) {
                    await .newResults(
                        TaskResult {
                            try await searchClient.search(input: input)
                        }
                    )
                }
            
        case .newResults(let result):
            switch result {
            case .failure(let error):
                state.error = error.localizedDescription
                state.searchResults = []
            case .success(let places):
                state.searchResults = places
            }
            return .none
            
        case .dismissError:
            state.error = nil
            return .none
            
        case .exit:
            //handled by parent
            return .none
        }
    }
}


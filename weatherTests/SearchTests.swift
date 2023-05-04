import XCTest
import ComposableArchitecture
@testable import weather

@MainActor
final class SearchTests: XCTestCase {
    // THESE ARE JUST EXAMPLE TEST. all actions can be tested.
    
    func test_didChangeTextInput() async {
        let store = TestStore(
            initialState: Search.State(textInput: "", searchResults: []),
            reducer: Search()
        )
        let newInput = "newInput"
        
        _ = await store.send(.didChangeTextInput(newInput)) {
            $0.textInput = newInput
        }
    }

    func test_didChangeTextInput_empty_results() async {
        let store = TestStore(
            initialState: Search.State(textInput: "", searchResults: Mock.place(count: 4)),
            reducer: Search()
        )
        let newInput = ""
        
        _ = await store.send(.didChangeTextInput(newInput)) {
            $0.textInput = newInput
            $0.searchResults = []
        }
    }

    func test_searchPlace() async {
        let store = TestStore(
            initialState: Search.State(textInput: "", searchResults: []),
            reducer: Search()
        )
        
        _ = await store.send(.searchPlaces)
        await store.receive(.newResults(.success([])))
    }

    func test_newResults_value() async {
        let store = TestStore(
            initialState: Search.State(textInput: "", searchResults: []),
            reducer: Search()
        )
        let results = Mock.place(count: 3)
        
        _ = await store.send(.newResults(.success(results))){
            $0.searchResults = results
        }
    }

    func test_newResults_error() async {
        let store = TestStore(
            initialState: Search.State(textInput: "", searchResults: Mock.place(count: 3)),
            reducer: Search()
        )
        
        let error = RandomError.some
        _ = await store.send(.newResults(.failure(error))){
            $0.searchResults = []
            $0.error = error.localizedDescription
        }
    }

    enum RandomError: Error {
        case some
    }
}

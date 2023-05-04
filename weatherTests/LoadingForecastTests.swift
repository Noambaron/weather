import XCTest
import ComposableArchitecture
@testable import weather

@MainActor
final class LoadingForecastTests: XCTestCase {
    // THESE ARE JUST EXAMPLE TEST. all actions can be tested.
    
    func test_searchRequested() async {
        let store = TestStore(
            initialState: LoadingForecast.State(),
            reducer: LoadingForecast()
        )
        
        _ = await store.send(.searchRequested) {
            $0.searchState = Search.State(textInput: "", searchResults: [])
        }
    }

    func test_didAppear_with_saved_response() async {
        let searchClient = MockClient()
        let expected = Mock.weatherResponse()
        searchClient.weatherResponse = {
            expected
        }
        
        let store = TestStore(
            initialState: LoadingForecast.State(),
            reducer: LoadingForecast()
                .dependency(\.searchClient, searchClient)
        )
        
        _ = await store.send(.didAppear) {
            $0.weatherResponse = .value(Forecast.State(weatherResponse: expected))
        }
    }

    func test_didAppear_with_no_response() async {
        let searchClient = MockClient()
        let locationClient = MockLocationClient()
        
        let expectedStatus = locationClient.authStatus
        
        searchClient.weatherResponse = {
            nil
        }
        
        let store = TestStore(
            initialState: LoadingForecast.State(),
            reducer: LoadingForecast()
                .dependency(\.searchClient, searchClient)
                .dependency(\.locationClient, locationClient)
        )
        
        _ = await store.send(.didAppear)
        await store.receive(.locationAuthChanged(expectedStatus))
    }
}

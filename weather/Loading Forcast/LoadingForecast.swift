import Foundation
import ComposableArchitecture
import CoreLocation

public struct LoadingForecast: ReducerProtocol {
    @Dependency(\.searchClient) var searchClient
    @Dependency(\.locationClient) var locationClient

    public struct State: Equatable {
        var weatherResponse: Loadable<Forecast.State> = .loading
        var searchState: Search.State? = nil
        var forecast: Forecast.State? {
            get {
                guard case .value(let state) = weatherResponse else {
                    return nil
                }
                return state
            }
            set {
                guard let newValue else { return }
                weatherResponse = .value(newValue)
            }
        }
        
        public init(weatherResponse: Loadable<Forecast.State> = .idle, searchState: Search.State? = nil) {
            self.weatherResponse = weatherResponse
            self.searchState = searchState
        }
    }
    
    public enum Action: Equatable {
        case searchAction(Search.Action)
        case forecastAction(Forecast.Action)
        case searchRequested
        case didAppear
        case dismissSearch
        case newWeatherResponse(TaskResult<WeatherResponse>)
        case requestLocationAuthorisation
        case locationAuthChanged(CLAuthorizationStatus)
        
    }
    
    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
            .ifLet(\.searchState, action: /LoadingForecast.Action.searchAction) {
                Search()
            }
            .ifLet(\.forecast, action: /LoadingForecast.Action.forecastAction) {
                Forecast()
            }
    }
    
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .searchAction(let searchActions):
            return self.reduceOnSearch(state: &state, action: searchActions)
            
        case .searchRequested:
            state.searchState = Search.State(textInput: "", searchResults: [])
            return .none
        case .didAppear:
            if let existing = searchClient.loadLastWeatherResponse() {
                state.weatherResponse = .value(Forecast.State(weatherResponse: existing))
                return .none
            } else {
                return .init(value: .locationAuthChanged(locationClient.authStatus))
            }
            
        case .requestLocationAuthorisation:
            return .init(
                locationClient.requestWhenInUseAuthorization()
                    .map(Action.locationAuthChanged)
            )
            
        case .locationAuthChanged(let status):
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                if
                    state.weatherResponse == .idle,
                    let lat = locationClient.location?.coordinate.latitude,
                    let lon = locationClient.location?.coordinate.longitude
                {
                    state.weatherResponse = .loading
                    return Self.fetchWeatherEffect(lat: lat, lon: lon, searchClient: searchClient)
                }
            case .notDetermined:
                return .init(value: .requestLocationAuthorisation)
            case .restricted, .denied:
                state.searchState = Search.State(textInput: "", searchResults: [])
                return .none
            @unknown default:
                return .none
            }

            return .none
            
        case .dismissSearch:
            state.searchState = nil
            return .none
        case .newWeatherResponse(let result):
            switch result {
            case .failure(let error):
                state.weatherResponse = .error(error.localizedDescription)
            case .success(let weatherResponse):
                searchClient.saveWeatherResponse(response: weatherResponse)
                state.weatherResponse = .value(Forecast.State(weatherResponse: weatherResponse))
            }
            return .none
        }
    }
    
    func reduceOnSearch(state: inout LoadingForecast.State, action: Search.Action) -> EffectTask<Action> {
        switch action {
        case .exit(let selectedCity):
            state.searchState = nil
            state.weatherResponse = .loading
            return .task(
                priority: .background) {
                    await .newWeatherResponse(
                        TaskResult {
                            try await searchClient.fetchWeatherResponse(city: selectedCity)
                        }
                    )
                }
            
        default:
            return .none
        }
    }

    private static func fetchWeatherEffect(lat: Double, lon: Double, searchClient: ClientProtocol) -> EffectTask<Action> {
        .task(priority: .background) {
            await .newWeatherResponse(
                TaskResult {
                    try await searchClient.fetchWeatherResponse(lat: lat, lon: lon)
                }
            )
        }
    }
}

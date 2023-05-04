import ComposableArchitecture
import SwiftUI
import Foundation

struct LoadingForecastView: View {
    let store: StoreOf<LoadingForecast>
    @ObservedObject var viewStore: ViewStore<ViewState, LoadingForecast.Action>

    struct ViewState: Equatable {
        var state: LoadingForecast.State
        
        var isLoadingWeather: Bool {
            state.weatherResponse == .loading
        }
        
        var isShowingSearch: Bool {
            state.searchState != nil
        }
        
        var errorMessage: String? {
            guard case .error(let message) = state.weatherResponse else {
                return nil
            }
            return message
        }
        
        var title: String {
            state.forecast?.weatherResponse.name ?? "Weather"
        }
    }
    
    public init(store: StoreOf<LoadingForecast>) {
        self.store = store
        self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                if viewStore.isLoadingWeather {
                    ProgressView()
                } else if viewStore.errorMessage != nil {
                    Text(viewStore.errorMessage ?? "Something went wrong")
                } else {
                    IfLetStore(
                        store.scope(
                            state: \.forecast,
                            action: LoadingForecast.Action.forecastAction
                        ),
                        then: { store in
                            // This can be switched to the SwiftUI version of the view: ForecastView
                            ForecastViewUIKitWrapper(store: store)
                        }
                    )
                }
            }
            .navigationTitle(viewStore.title)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: {
                        viewStore.send(.searchRequested)
                    }) {
                        Text("Search")
                    }
                }
            }
        }
        .sheet(
            isPresented: viewStore.binding(
                get: \.isShowingSearch,
                send: LoadingForecast.Action.dismissSearch
            ),
            content: {
                IfLetStore(
                    self.store.scope(
                        state: \.searchState,
                        action: LoadingForecast.Action.searchAction
                    ),
                    then: { store in SearchView(store:store) }
                )
            }
        )
        .onAppear {
            viewStore.send(.didAppear)
        }
            
    }
}

struct ForcastView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingForecastView(
            store: Store(
                initialState: LoadingForecast.State(
                    weatherResponse: .value(
                        Forecast.State(
                            weatherResponse: Mock.weatherResponse()
                        )
                    )
                ),
                reducer: LoadingForecast()
            )
        )
    }
}


import ComposableArchitecture
import SwiftUI
import Foundation
import Kingfisher

struct ForecastView: View {
    //IMPROVEMENT: UI is extremely basic here, I tried to focus on other stuff so this was
    // a bit neglegted.
    let store: StoreOf<Forecast>
    @ObservedObject var viewStore: ViewStore<ViewState, Forecast.Action>

    struct ViewState: Equatable {
        var state: Forecast.State
        
        var weatherResponse: WeatherResponse {
            state.weatherResponse
        }
    }
    
    public init(store: StoreOf<Forecast>) {
        self.store = store
        self.viewStore = ViewStore(self.store.scope(state: ViewState.init(state:)))
    }
    
    @ViewBuilder
    func iconImageView(item: Weather) -> some View {
        //IMPROVEMENT: KingFisher was chosen here for the sake of brevity.
        // There could be more elaborate ways to handle loading and caching of images.
        KFImage(item.iconURL)
            .placeholder {
                Image("defaultImage")
                    .resizable()
            }
            .resizable()
            .frame(width: 120, height: 120)
            .scaledToFit()
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(viewStore.weatherResponse.weather) { item in
                    VStack {
                        self.iconImageView(item: item)
                        Text(item.main)
                        Text(viewStore.weatherResponse.main.temp.description)
                    }
                }
            }
            Text(viewStore.weatherResponse.main.temp.description)
        }
    }
}

struct WeatherResponseView_Previews: PreviewProvider {
    static var previews: some View {
        ForecastView(
            store: Store(
                initialState: Forecast.State(weatherResponse: Mock.weatherResponse()),
                reducer: Forecast()
            )
        )
    }
}



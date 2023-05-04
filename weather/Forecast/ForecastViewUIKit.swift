import SwiftUI
import UIKit
import ComposableArchitecture
import Foundation
import Combine
import Kingfisher

class ForecastViewUIKit: UIViewController {
    let store: StoreOf<Forecast>
    let viewStore: ViewStore<ViewState, Forecast.Action>
    private var cancellables: Set<AnyCancellable> = []
    
    struct ViewState: Equatable {
        let state: Forecast.State
        
        var weatherResponse: WeatherResponse {
            state.weatherResponse
        }

        var weather: Weather? {
            weatherResponse.weather.first
        }

        var description: String? {
            weather?.description
        }

        var temp: String {
            String(weatherResponse.main.temp)
        }

        var maxTemp: String {
            String(weatherResponse.main.temp_max)
        }

        var minTemp: String {
            String(weatherResponse.main.temp_min)
        }

        var humidity: String {
            String(weatherResponse.main.humidity)
        }

        var pressure: String {
            String(weatherResponse.main.pressure)
        }

        var iconURL: URL? {
            weather?.iconURL
        }

        
        init(state: Forecast.State) {
            self.state = state
        }
    }

    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let tempLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 50)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var maxTempLabel: UILabel = {
        makeStandardLabel()
    }()

    var minTempLabel: UILabel = {
        makeStandardLabel()
    }()

    var humidityLabel: UILabel = {
        makeStandardLabel()
    }()

    var pressureLabel: UILabel = {
        makeStandardLabel()
    }()

    public init(store: StoreOf<Forecast>) {
      self.store = store
      self.viewStore = ViewStore(store.scope(state: ViewState.init))
      super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        bind()
    }
    
    private func configureView() {
        let vStack = UIStackView(arrangedSubviews: [minTempLabel, maxTempLabel, humidityLabel, pressureLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        let hStack = UIStackView(arrangedSubviews: [vStack])
        hStack.axis = .horizontal
        hStack.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(imageView)
        self.view.addSubview(tempLabel)
        self.view.addSubview(hStack)
        
        NSLayoutConstraint.activate([
            tempLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tempLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            tempLabel.leadingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor),
            tempLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor),

            imageView.topAnchor.constraint(equalTo: tempLabel.bottomAnchor, constant: 8),
            imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            imageView.leadingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            hStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            hStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            hStack.leadingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor),
            hStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])

        imageView.kf.setImage(with: viewStore.iconURL, placeholder: UIImage(named: "defaultImage"))
    }
    
    private func bind() {
        self.viewStore.publisher.temp.sink(
            receiveValue: { [weak self] in
                self?.tempLabel.text = $0
            }
        )
        .store(in: &self.cancellables)
        
        let localizedMaxTemp = NSLocalizedString("Max temp", comment: "")
        self.viewStore.publisher.maxTemp.sink(
            receiveValue: { [weak self] in
                self?.maxTempLabel.text = localizedMaxTemp + ": \($0)"
            }
        )
        .store(in: &self.cancellables)
        
        let localizedMinTemp = NSLocalizedString("Min temp", comment: "")
        self.viewStore.publisher.minTemp.sink(
            receiveValue: { [weak self] in
                self?.minTempLabel.text = localizedMinTemp + ": \($0)"
            }
        )
        .store(in: &self.cancellables)
        
        let localizedHumidity = NSLocalizedString("Humidity", comment: "")
        self.viewStore.publisher.humidity.sink(
            receiveValue: { [weak self] in
                self?.humidityLabel.text = localizedHumidity + ": \($0)%"
            }
        )
        .store(in: &self.cancellables)
        
        let localizedPressure = NSLocalizedString("Pressure", comment: "")
        self.viewStore.publisher.pressure.sink(
            receiveValue: { [weak self] in
                self?.pressureLabel.text = localizedPressure + ": \($0) hPa"
            }
        )
        .store(in: &self.cancellables)
        
    }
    
    static func makeStandardLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}


struct ForecastViewUIKitWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = ForecastViewUIKit

    let store: StoreOf<Forecast>
    
    func makeUIViewController(context: Context) -> ForecastViewUIKit {
        let myViewController = ForecastViewUIKit(store: store)
        return myViewController
    }

    func updateUIViewController(_ uiViewController: ForecastViewUIKit, context: Context) {
        // You can update your view controller here
    }
}

import Foundation
import ComposableArchitecture
import CoreLocation
import Combine

protocol LocationClientProtocol {
    var authStatus: CLAuthorizationStatus  { get }
    var location: CLLocation? { get }
    func requestWhenInUseAuthorization() -> AnyPublisher<CLAuthorizationStatus, Never>
}


class LocationClient: NSObject, LocationClientProtocol, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    private let authorizationStatusSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    
    public var authorizationStatus: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationStatusSubject.eraseToAnyPublisher()
    }
    
    public var authStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    var location: CLLocation? {
        locationManager.location
    }
    
    public func requestWhenInUseAuthorization() -> AnyPublisher<CLAuthorizationStatus, Never> {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        return authorizationStatusSubject.eraseToAnyPublisher()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatusSubject.send(locationManager.authorizationStatus)
    }
}

class MockLocationClient: LocationClientProtocol {
    public var authStatus: CLAuthorizationStatus = .authorizedAlways
    var location: CLLocation? = nil
    public func requestWhenInUseAuthorization() -> AnyPublisher<CLAuthorizationStatus, Never> {
        Empty().eraseToAnyPublisher()
    }
}


extension LocationClient {
    public static var live: LocationClientProtocol = LocationClient()
    public static var mock: LocationClientProtocol = MockLocationClient()
}

private enum LocationClientKey: DependencyKey {
    static let liveValue = LocationClient.live
    static let previewValue = LocationClient.mock
    static let testValue = LocationClient.mock
}

extension DependencyValues {
  var locationClient: LocationClientProtocol {
      get { self[LocationClientKey.self] }
      set { self[LocationClientKey.self] = newValue }
  }
}

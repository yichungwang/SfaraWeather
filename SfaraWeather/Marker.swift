//
//  Place.swift
//  SfaraWeather
//
//  Created by Daydreamer on 4/30/17.
//  Copyright © 2017 Daydreamer. All rights reserved.
//

import Foundation
import MapKit
import SwiftyJSON

protocol MarkerDelegate: class {
    func shouldUpdateCell(name: String)
}

class Marker: NSObject, MKAnnotation {
    
    weak var delegate: MarkerDelegate?
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var name: String
    var temperature: Float?
    var humidity: Int?
    var weather: String?
    
    init(name: String, location: CLLocationCoordinate2D) {
        self.title = name
        self.coordinate = location
        self.name = name
        super.init()
        updateMarker()
    }
    
    func updateMarker() {
        WebManager.sharedInstance.queryWeather(coordinate.latitude, lng: coordinate.longitude, completionHandler: { result, error in
            if let dic = result?.dictionary, let main = dic["main"]?.dictionary {
                if let humidity = main["humidity"]?.int, let temperature = main["temp"]?.float {
                    self.humidity = humidity
                    self.temperature = temperature
                    self.subtitle = "temp: \(humidity), hum: \(temperature)"
                }
            }
            if let dic = result?.dictionary, let weather = dic["weather"]?.array, let weatherdic = weather.first {
                if let main = weatherdic["main"].string {
                    self.weather = main
                }
            }
            self.delegate?.shouldUpdateCell(name: self.name)
        })
    }
    
}

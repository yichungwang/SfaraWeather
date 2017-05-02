//
//  NetworkManager.swift
//  SfaraWeather
//
//  Created by Daydreamer on 4/30/17.
//  Copyright © 2017 Daydreamer. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class WebManager {
    
    static let sharedInstance = WebManager()
    
    fileprivate let baseURL = "http://api.openweathermap.org/data/2.5/"
    fileprivate let key = "e58f0c587b614364b55532925d8754ea"
    fileprivate var alamofireManager: Alamofire.SessionManager!
    
    fileprivate init() {
        let configuration = URLSessionConfiguration.default
        alamofireManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    func queryWeather(_ lat: Double, lng: Double, completionHandler:@escaping (_ result: JSON?, _ error: String?) -> Void) {
        
        alamofireManager.request(baseURL + "weather", method: .get, parameters: ["APPID": key, "lat": lat, "lon": lng], encoding: URLEncoding.default).responseJSON( completionHandler: { response in
            
            switch response.result {
            case .success(let result):
                let resultJSON = JSON.init(result)
                completionHandler(resultJSON, nil)
            case .failure(let error):
                completionHandler(nil, error.localizedDescription)
            }
            
        })
    }
    
}

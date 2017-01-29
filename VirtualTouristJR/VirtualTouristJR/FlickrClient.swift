//
//  FlickrClient.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 22/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    
    var session = URLSession.shared
    
    override init() {
        super.init()
    }
    
    func getPhotos(_ lat: AnyObject, lon: AnyObject, _ completionHandlerForGetPhotos: @escaping (_ success: Bool?, _ error: NSError?) -> Void) {
        
        let parameters = [
            Constants.ParametersKey.Method: Constants.Methods.PhotoSearch as AnyObject,
            Constants.ParametersKey.FlickrAPIKey : Constants.APIInfo.APIKey as AnyObject,
            Constants.ParametersKey.Format: Constants.ParametersValues.JSON as AnyObject,
            Constants.ParametersKey.NoJSONCallback: Constants.ParametersValues.DisableJSONCallback as AnyObject,
            Constants.ParametersKey.Page: Constants.ParametersValues.OnePage as AnyObject,
            Constants.ParametersKey.PerPage: Constants.ParametersValues.Fifteen as AnyObject]
        
        var parametersWithCoord = parameters
        parametersWithCoord[Constants.ParametersKey.lat] = lat
        parametersWithCoord[Constants.ParametersKey.lon] = lon
        
        let url = flickrURLFromParameters(parametersWithCoord)
        let request = NSMutableURLRequest(url: url)
        print(url)
        let task = session.dataTask(with: request as URLRequest) { (data, respnse, error) in
            if let error = error {
                completionHandlerForGetPhotos(false, error as NSError?)
            } else {
                let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print(dataString)
                
                self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: { (results, error) in
                    if let error = error {
                        completionHandlerForGetPhotos(false, error as NSError?)
                    } else {
                        print(results)
                        completionHandlerForGetPhotos(true, nil)
                    }
                })
            }
        }
        
        task.resume()
    }
    
    func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ results: AnyObject?, _ error: NSError?) -> Void) {
        var parsedResult: AnyObject! = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
            return
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }

    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.APIInfo.APIScheme
        components.host = Constants.APIInfo.APIHost
        components.path = Constants.APIInfo.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}

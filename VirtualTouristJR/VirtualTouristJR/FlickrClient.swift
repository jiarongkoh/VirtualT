//
//  FlickrClient.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 22/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    
    var session = URLSession.shared
    
    override init() {
        super.init()
    }
    
    func getPhotosURLFromFlickr(_ lat: AnyObject, lon: AnyObject, _ completionHandlerForGetPhotosURL: @escaping (_ imageURL: [String]?, _ error: NSError?) -> Void) {
        
        taskForGetPagesFromFlickr(lat, lon: lon) { (parameters, error) in
            if let error = error {
                completionHandlerForGetPhotosURL(nil, error as NSError)
            } else {
                
                if let parameters = parameters {
                    print(parameters)
                    self.taskForGetPhotos(parameters, { (imageURLArray, error) in
                        if let error = error {
                            completionHandlerForGetPhotosURL(nil, error as NSError)
                        } else {
                            if let imageURLArray = imageURLArray {
                                completionHandlerForGetPhotosURL(imageURLArray, nil)
                            }
                        }
                    })
                }
            }
        }
    }

    
    func downloadPhotos(_ imagePath: String, completionHandlerForDownloadPhotos: @escaping (_ imageData: Data?, _ error: NSError?) -> Void) {
        let imageURL = URL(string: imagePath)
        let request = URLRequest(url: imageURL!)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                completionHandlerForDownloadPhotos(nil, error as NSError)
            } else {
                
                guard let imageData = data else {
                    print("No Data from downloadPhotos")
                    return
                }
            
                completionHandlerForDownloadPhotos(imageData, nil)
            }
        }
        
        task.resume()
    }
    
    func taskForGetPagesFromFlickr(_ lat: AnyObject, lon: AnyObject, _ completionHandlerForGetPhotosURL: @escaping (_ parameters: [String: AnyObject]?, _ error: NSError?) -> Void) {
        
        let parameters = [
            Constants.ParametersKey.Method: Constants.Methods.PhotoSearch as AnyObject,
            Constants.ParametersKey.FlickrAPIKey : Constants.APIInfo.APIKey as AnyObject,
            Constants.ParametersKey.Format: Constants.ParametersValues.JSON as AnyObject,
            Constants.ParametersKey.NoJSONCallback: Constants.ParametersValues.DisableJSONCallback as AnyObject,
            Constants.ParametersKey.PerPage: Constants.ParametersValues.Fifteen as AnyObject,
            Constants.ParametersKey.Extras: Constants.ParametersValues.MediumURL as AnyObject]
        
        var parametersWithCoord = parameters
        parametersWithCoord[Constants.ParametersKey.lat] = lat
        parametersWithCoord[Constants.ParametersKey.lon] = lon
        
        let url = flickrURLFromParameters(parametersWithCoord)
        let request = NSMutableURLRequest(url: url)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                completionHandlerForGetPhotosURL(nil, error as NSError)
            } else {
                self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: { (results, error) in
                    if let error = error {
                        completionHandlerForGetPhotosURL(nil, error as NSError)
                    } else {
//                        print(results)
                        guard let photosDict = results?["photos"] as? [String: AnyObject] else {
                            let userInfo = [NSLocalizedDescriptionKey : "NoPhotosFound"]
                            completionHandlerForGetPhotosURL(nil, NSError(domain: "NoPhotosFound", code: 1, userInfo: userInfo))
                            return
                        }

                        guard let pages = photosDict[Constants.ParametersKey.Pages] as? Int else {
                            let userInfo = [NSLocalizedDescriptionKey : "NoPagesFound"]
                            completionHandlerForGetPhotosURL(nil, NSError(domain: "NoPagesFound", code: 1, userInfo: userInfo))
                            return
                        }
                        
                        let randomPageIndex = Int(arc4random_uniform(UInt32(pages)))
                        var searchParameters = parametersWithCoord
                        searchParameters[Constants.ParametersKey.Page] = randomPageIndex as AnyObject?
                        print("Number of pages: \(pages)")
                        print("Random page index: \(randomPageIndex)")
                        completionHandlerForGetPhotosURL(searchParameters, nil)
                    }
                })
            }
        }
        
        task.resume()
    }
    
    func taskForGetPhotos(_ parameters: [String: AnyObject], _ completionHandlerForGetPhotosURL: @escaping (_ imageURL: [String]?, _ error: NSError?) -> Void) {
        
        let url = flickrURLFromParameters(parameters)
        let request = NSMutableURLRequest(url: url)
//        print(url)
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                completionHandlerForGetPhotosURL(nil, error as NSError)
            } else {
                self.convertDataWithCompletionHandler(data!, completionHandlerForConvertData: { (results, error) in
                    if let error = error {
                        completionHandlerForGetPhotosURL(nil, error as NSError)
                    } else {
//                        print(results)
                        guard let photosDict = results?["photos"] as? [String: AnyObject] else {
                            let userInfo = [NSLocalizedDescriptionKey : "NoPhotosFound"]
                            completionHandlerForGetPhotosURL(nil, NSError(domain: "NoPhotosFound", code: 1, userInfo: userInfo))
                            return
                        }
                        
                        guard let photosArray = photosDict["photo"] as? [[String: AnyObject]] else {
                            let userInfo = [NSLocalizedDescriptionKey : "NoPhotosArrayFound"]
                            completionHandlerForGetPhotosURL(nil, NSError(domain: "NoPhotosArray", code: 1, userInfo: userInfo))
                            return
                        }
                        
                        var imageURLArray: [String] = []
                        
                        if photosArray.count != 0 {
                            for pics in photosArray {
                                guard let imageURLString = pics[Constants.ParametersValues.MediumURL] as? String else {
                                    print("NoImageURLString Found")
                                    return
                                }
                                
                                imageURLArray.append(imageURLString)
                            }
                        }
//                        print("ImageURLArray : \(imageURLArray)")
                        completionHandlerForGetPhotosURL(imageURLArray, nil)
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

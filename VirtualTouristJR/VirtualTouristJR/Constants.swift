//
//  Constants.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 22/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import Foundation

struct Constants {
    
    struct APIInfo {
        static let APIKey = "88291f02df4d577b293bfd653b76de86"
        
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"

    }
    
    struct Methods {
        static let PhotoSearch = "flickr.photos.search"
    }
    
    struct ParametersKey {
        static let FlickrAPIKey = "api_key"
        static let Method = "method"
        static let bbox = "bbox"
        static let lat = "lat"
        static let lon = "lon"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    struct ParametersValues {
        static let JSON = "json"
        static let DisableJSONCallback = "1"
        static let OnePage = "1"
        static let Fifteen = "15"
    }
    
    
    
}

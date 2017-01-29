//
//  Pin+CoreDataClass.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 22/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import Foundation
import CoreData
import MapKit

public class Pin: NSManagedObject, MKAnnotation {

    convenience init(lat: Double, long: Double, context: NSManagedObjectContext) {

        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.lat = lat
            self.long = long
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    public var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: lat as Double, longitude: long as Double)
        }
        
        set {
            lat = newValue.latitude
            long = newValue.longitude
        }
    }
}

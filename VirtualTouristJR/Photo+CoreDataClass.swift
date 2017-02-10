//
//  Photo+CoreDataClass.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 22/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {

    convenience init(pin: Pin, /*imageData: NSData,*/ imageURL: String, context: NSManagedObjectContext) {
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.pins = pin
//            self.imageData = imageData
            self.imageURL = imageURL
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}

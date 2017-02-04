//
//  MapViewController.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 2/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var addedPin: Pin!
    var pins: [Pin]!
    var deleteToggleBool: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        deleteToggleBool = false
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation))
        longPress.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(longPress)
        
        pins = fetchAllPins()
        
        for pin in pins {
            mapView.addAnnotation(pin)
        }
        
    }
    
    @IBAction func deleteButtonDidTap(_ sender: Any) {
        let deleteView = UIView()
        let screenSize = UIScreen.main.bounds
        deleteView.frame = CGRect(x: 0, y: screenSize.height - 50, width: screenSize.width, height: 100)
        deleteView.backgroundColor = UIColor.red
        
        if deleteToggleBool == false {
            deleteToggleBool = true
//            view.addSubview(deleteView)
            
        } else {
            deleteToggleBool = false
        
        }
    }
    
    @IBAction func retreive(_ sender: Any) {

    }
    
    func fetchAllPins() -> [Pin] {
        let stack = delegate.stack
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            let results = try stack?.context.fetch(fr)
            pins = results as! [Pin]
            print("Number of pins: \(pins.count)")
            return pins
        } catch let e as NSError {
            print(e)
            return []
        }

    }
    
    func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            let stack = delegate.stack
            addedPin = Pin(lat: touchCoordinate.latitude, long: touchCoordinate.longitude, context: (stack?.context)! )
            do {
                try stack?.saveContext()
                mapView.addAnnotation(addedPin)
            } catch {
                print("Error while saving.")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

        pinView.animatesDrop = true
        pinView.isSelected = true
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let pin = view.annotation as? Pin {
            mapView.deselectAnnotation(pin, animated: false)
            viewPin(pin)
        } else {
            print("not pin \(view.annotation?.coordinate)")
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if let _ = view.annotation as? Pin {
            view.isSelected = true
        } else {
            print("deselect not pin \(view.annotation?.coordinate)")
        }
    }
    
    
    func deletePin(_ pin: Pin) {
        let stack = delegate.stack
        stack?.context.delete(pin)
        
        do {
            try stack?.saveContext()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(pin.lat, pin.long)
            mapView.removeAnnotation(annotation)

        } catch {
            print("Error while saving.")
        }

    }
    
    func viewPin(_ pin: Pin) {
        let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbum") as! PhotoAlbumViewController
        controller.pin = pin
        navigationController?.pushViewController(controller, animated: true)
    }

}

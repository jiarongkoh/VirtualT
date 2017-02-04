//
//  PhotoAlbumViewController.swift
//  VirtualTouristJR
//
//  Created by Koh Jia Rong on 29/1/17.
//  Copyright © 2017 Koh Jia Rong. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate {

    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!

    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    var pin: Pin!
    var photos: [Photo]!
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!

    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.stack!.context
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchedRequest.sortDescriptors = []
        fetchedRequest.predicate = NSPredicate(format: "pins == %@", self.pin!)
        return NSFetchedResultsController(fetchRequest: fetchedRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        fetchedResultsController.delegate = self
        
        setUpMapView(coordinate: pin.coordinate)
        setUpCollectionViewLayout()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        do {
            try fetchedResultsController.performFetch()
          
        } catch let error as NSError {
            print("Unable to perform fetch: \(error.localizedDescription)")
        }
        
        let fetchedObjects = fetchedResultsController.fetchedObjects
        if fetchedObjects?.count != 0 {
            print("Image present in CoreData")
            print("Count of fetchedObjects \(fetchedObjects?.count)")
            print(fetchedObjects!)
        } else if fetchedObjects?.count == 0 {
            print("No image in CoreData, fetching...")
            print("Count of fetchedObjects \(fetchedObjects?.count)")
            loadPhotos()
        }
    }
    
    func loadPhotos() {
        newCollectionButton.isUserInteractionEnabled = false
        
        FlickrClient.sharedInstance.getPhotos(pin.coordinate.latitude as AnyObject, lon: pin.coordinate.longitude as AnyObject, { (results, error) in
            if let error = error {
                print(error)
            } else {
                if results != nil {
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.newCollectionButton.isUserInteractionEnabled = true
                    }
                    
                    for result in results! {
                        let picture = Photo(pin: self.pin, imageData: result as NSData, context: self.context)
                        print(picture)
                    }
                    
                    do {
                        try self.delegate.stack?.saveContext()
                    } catch let error as NSError {
                        print("Error saving context in loadPhotos(): \(error.localizedDescription)")
                    }
                }
            }
        })

    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = fetchedResultsController.sections?.count
        print("Number of sections \(sections)")

        return sections!
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = fetchedResultsController.fetchedObjects?.count
        print("Number of items \(count)")
        return count!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageViewCell

        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        cell.imageView?.image = UIImage(data: photo.imageData as! Data)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: "Delete Photo", style: .destructive) { (action) in
            self.context.delete(self.fetchedResultsController.object(at: indexPath) as! Photo)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
        alertVC.addAction(deleteAction)
        alertVC.addAction(cancelAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    func setUpCollectionViewLayout() {
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    }
    
    func setUpMapView(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: false)
    
        mapView.isUserInteractionEnabled = false
    }
    
    @IBAction func newCollectionButtonDidTap(_ sender: Any) {
        for items in fetchedResultsController.fetchedObjects! {
            context.delete(items as! NSManagedObject)
        }
        print(fetchedResultsController.fetchedObjects?.count)
        loadPhotos()
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        insertedIndexPaths = []
//        deletedIndexPaths = []
        print("ControllerWillChangeContent!!")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("Inserting at \(newIndexPath)")
            collectionView.insertItems(at: [newIndexPath!])
        case .delete:
            print("Deleting at \(indexPath)")
            collectionView.deleteItems(at: [indexPath!])
        default: ()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("ControllerDidChangeContent!!!!")
//        collectionView.performBatchUpdates({
//            for indexPath in self.insertedIndexPaths {
//                self.collectionView.insertItems(at: [indexPath as IndexPath])
//            }
//            
//            for indexPath in self.deletedIndexPaths {
//                self.collectionView.deleteItems(at: [indexPath as IndexPath])
//            }
//        }, completion: nil)
    }
}

        

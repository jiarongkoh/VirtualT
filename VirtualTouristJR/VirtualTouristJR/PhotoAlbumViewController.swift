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

    @IBOutlet weak var newColActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!

    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    var pin: Pin!
    var photos = [Photo]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!

    lazy var context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.stack!.context
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchedRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchedRequest.sortDescriptors = []
        fetchedRequest.predicate = NSPredicate(format: "pins == %@", argumentArray: [self.pin])
        return NSFetchedResultsController(fetchRequest: fetchedRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newColActivityIndicator.isHidden = true
        mapView.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
//        fetchedResultsController.delegate = self
        
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
            print("IMAGE PRESENT IN COREDATA")
            print("Count of fetchedObjects \(fetchedObjects?.count)")
            
            for objects in fetchedObjects! {
                let fetchedPic = objects as! Photo
                self.photos.append(fetchedPic)
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        } else if fetchedObjects?.count == 0 {
            print("NO IMAGE IN COREDATA, FETCHING...")
            getPhotosURL()
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }
        
    }

    
    func getPhotosURL() {
        newColActivityIndicator.startAnimating()
        newColActivityIndicator.isHidden = false
        newCollectionButton.isUserInteractionEnabled = false
        newCollectionButton.alpha = 0.4

        FlickrClient.sharedInstance.getPhotosURL(pin.coordinate.latitude as AnyObject, lon: pin.coordinate.longitude as AnyObject) { (results, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let _ = results {
                    for result in results! {
                        let picture = Photo(pin: self.pin, imageURL: result, context: self.context)
                        self.photos.append(picture)
                    }

                    do {
                        try self.delegate.stack?.saveContext()
                    } catch let error as NSError {
                        print("Error saving context in loadPhotos(): \(error.localizedDescription)")
                    }

                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.newColActivityIndicator.stopAnimating()
                        self.newColActivityIndicator.isHidden = true
                        self.newCollectionButton.isUserInteractionEnabled = true
                        self.newCollectionButton.alpha = 1.0
                        print("Reload Data loadPhotos")

                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of items \(photos.count)")
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageViewCell

        cell.activityIndicator.startAnimating()
        cell.activityIndicator.isHidden = false
        
        let photo = photos[indexPath.row]
        
        if let photoImage = photo.imageData {
            print("PhotoImage present")
            DispatchQueue.main.async {
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.isHidden = true
                cell.imageView?.image = UIImage(data: photoImage as Data)
            }

        } else {
            print("PhotoImage Not Present")
            if let photoImageURLString = photo.imageURL {
                let photoImageURL = URL(string: photoImageURLString)
                if let imageData = try? Data(contentsOf: photoImageURL!) {
                    photo.imageData = imageData as NSData
                    
                    do {
                        try self.delegate.stack?.saveContext()
                    } catch let error as NSError {
                        print("Error saving context in loadPhotos(): \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                        cell.imageView?.image = UIImage(data: imageData as Data)
                    }
                }
            }
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: "Delete Photo", style: .destructive) { (action) in
            self.context.delete(self.fetchedResultsController.object(at: indexPath) as! Photo)
            self.photos.remove(at: indexPath.row)
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
        print("FETCHING NEW COLLECTION...")
        DispatchQueue.main.async {
            self.photos.removeAll()
            print(self.photos)
            self.collectionView.reloadData()
            print("Reload Data newColVC")
        }
        for items in fetchedResultsController.fetchedObjects! {
            context.delete(items as! NSManagedObject)
        }
        
        getPhotosURL()
    }
    
    
}


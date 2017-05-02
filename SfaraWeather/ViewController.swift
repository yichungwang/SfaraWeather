//
//  ViewController.swift
//  SfaraWeather
//
//  Created by Daydreamer on 4/30/17.
//  Copyright © 2017 Daydreamer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, MarkerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    fileprivate var locationManager: CLLocationManager?
    fileprivate var didUpdateCurrentLocation: Bool = false
    fileprivate var markers = [String:Marker]() // Use to store current pins on the map
    fileprivate var keys = [String]() // Use to keep the table view cell order

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial Navigation Bar Setup
        title = "SfaraWeather"
        let locationBarButton = MKUserTrackingBarButtonItem.init(mapView: mapView)
        let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addLocation))
        navigationItem.rightBarButtonItems = [locationBarButton, addBarButton]
        
        // Initial MapView Setup
        mapView.showsUserLocation = true
        
        // Initial LocationManager Setup
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.startUpdatingLocation()
        }
        
        // Fetch CoreData
        fetchData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchData() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Place")
        do { // fetch saved location, add to map and tableview
            let places = try managedContext.fetch(fetchRequest)
            for place in places {
                if let name = place.value(forKey: "name") as? String, let lat = place.value(forKey: "latitude") as? Double, let lng = place.value(forKey: "longitude") as? Double {
                    let marker = Marker.init(name: name, location: CLLocationCoordinate2DMake(lat, lng))
                    marker.delegate = self
                    addMarker(marker: marker)
                }
                tableView.reloadData()
            }
        } catch let error as NSError {
            print("\(error), \(error.userInfo)")
        }
        
    }
    
    func addLocation() {
        let alertController = UIAlertController.init(title: "Add Location", message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = CGRect.init(x: UIScreen.main.bounds.width - 100, y: 100, width: 10, height: 10)
        }
        let updateAction = UIAlertAction.init(title: "Update Current Location", style: .default, handler: { action in
            self.removeMarker(name: "CurrentLocation")
            self.didUpdateCurrentLocation = false
            self.locationManager?.startUpdatingLocation()
        })
        let addAction = UIAlertAction.init(title: "Add A Location", style: .default, handler: { action in
            
            let alert = UIAlertController(title: "New Location", message: "Add a name", preferredStyle: .alert)
            let saveAction = UIAlertAction(title: "Save", style: .default) { action in
                guard let textField = alert.textFields?.first, let name = textField.text, name != "CurrentLocation", name != "" else { // CurrentLocation reserved
                    let alert = UIAlertController(title: "Bad Name", message: "Please try another name.", preferredStyle: .alert)
                    let cancel = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(cancel)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                guard self.keys.filter({return $0 == name}).count <= 0 else { // Do not allow duplicate name
                    let alert = UIAlertController(title: "Name Exists", message: "Please try another name.", preferredStyle: .alert)
                    let cancel = UIAlertAction.init(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(cancel)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
                // Save Location to CoreData and add a pin
                let managedContext = appDelegate.persistentContainer.viewContext
                if let entity = NSEntityDescription.entity(forEntityName: "Place", in: managedContext) {
                    let place = NSManagedObject(entity: entity, insertInto: managedContext)
                    place.setValue(name, forKeyPath: "name")
                    place.setValue(self.mapView.centerCoordinate.latitude, forKeyPath: "latitude")
                    place.setValue(self.mapView.centerCoordinate.longitude, forKeyPath: "longitude")
                    do {
                        try managedContext.save()
                        let marker = Marker.init(name: name, location: CLLocationCoordinate2DMake(self.mapView.centerCoordinate.latitude, self.mapView.centerCoordinate.longitude))
                        marker.delegate = self
                        self.addMarker(marker: marker)
                        self.tableView.reloadData()
                    } catch let error as NSError {
                        print("\(error), \(error.userInfo)")
                    }
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .default)
            alert.addTextField()
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
            
        })
        let cancel = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(updateAction)
        alertController.addAction(addAction)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func removeMarker(name: String) {
        if let marker = markers[name] {
            mapView.removeAnnotation(marker)
            markers.removeValue(forKey: name)
            if let index = keys.index(of: name) {
                keys.remove(at: index)
            }
        }
    }
    
    func addMarker(marker: Marker) {
        mapView.addAnnotation(marker)
        markers[marker.name] = marker
        keys.append(marker.name)
    }
    
    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // only use for update current user location's weather
        if let location = locations.last, !didUpdateCurrentLocation {
            didUpdateCurrentLocation = true
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
            
            let marker = Marker.init(name: "CurrentLocation", location: center)
            marker.delegate = self
            mapView.addAnnotation(marker)
            markers[marker.name] = marker
            keys.insert(marker.name, at: 0)
            tableView.reloadData()
            locationManager?.stopUpdatingLocation()
        }
    }
    
    // UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? WeatherCell {
            cell.nameLabel.text = markers[keys[indexPath.row]]?.name
            if let weather = markers[keys[indexPath.row]]?.weather, let name = markers[keys[indexPath.row]]?.name {
                cell.nameLabel.text = name + " (\(weather))"
            }
            if let hum = markers[keys[indexPath.row]]?.humidity {
                cell.humidityLabel.text = "humidity: \(hum)"
            }
            if let temp = markers[keys[indexPath.row]]?.temperature {
                cell.temperatureLabel.text = "temperature: \(temp)"
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 92
    }
    
    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let marker = markers[keys[indexPath.row]] {
            let region = MKCoordinateRegion.init(center: marker.coordinate, span: MKCoordinateSpanMake(0.01, 0.01))
            mapView.setRegion(region, animated: true)
            mapView.selectAnnotation(marker, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0, let marker = markers[keys[indexPath.row]], marker.name == "CurrentLocation" {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let alertController = UIAlertController.init(title: "SfaraWeather", message: "Are you sure you want to remove this location?", preferredStyle: .alert)
            let confirm = UIAlertAction.init(title: "YES", style: .destructive, handler: { action in
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let marker = self.markers[self.keys[indexPath.row]] else {
                    return
                }
                let managedContext = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Place")
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "name == %@", marker.name)
                do { // try fetch the location the user wants to delete
                    let places = try managedContext.fetch(fetchRequest)
                    if let place = places.first {
                        managedContext.delete(place)
                        try managedContext.save()
                        self.removeMarker(name: marker.name)
                        self.tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
                    }
                } catch let error as NSError {
                    print("\(error), \(error.userInfo)")
                }
            })
            let cancel = UIAlertAction.init(title: "NO", style: .cancel, handler: nil)
            alertController.addAction(confirm)
            alertController.addAction(cancel)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MarkerDelegate (Use to update tableview cell after weather api call)
    func shouldUpdateCell(name: String) {
        if let index = keys.index(of: name) {
            tableView.reloadRows(at: [IndexPath.init(row: index, section: 0)], with: .none)
        }
    }

}


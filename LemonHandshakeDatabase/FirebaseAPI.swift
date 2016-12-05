//
//  FirebaseAPI.swift
//  LemonHandshakeDatabase
//
//  Created by Christopher Boynton on 11/16/16.
//  Copyright © 2016 Flatiron School. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import GeoFire

class FirebaseAPI {
    
    static let shared = FirebaseAPI()
    private init() {
    
    }
    
    let ref = FIRDatabase.database().reference()
}

//MARK: - Auth {
extension FirebaseAPI {
    func authorize() {
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("\(user?.displayName) signed in!")
            }
        })
    }
}

//MARK: - Landmark
extension FirebaseAPI {
    
    func serializeAndStoreDataOnFirebase() {
        let landmarksRef = ref.child("landmarks")
        let data = createData(with: DataStore.sharedInstance.landmarks)
        storeOnFirebase(data: data, in: landmarksRef)
    }
    
    func createData(with landmarks: [Landmark]) -> [String:Any] {
        var data = [String:Any]()
        
        for landmark in landmarks {
            let key = ref.childByAutoId().key
            data[key] = landmark.serialized
            geoFireStore(key: key, landmark: landmark)
            print("\(landmark.name) serialized")
        }
        return data
    }
    
    func storeOnFirebase(data: [String:Any], in reference: FIRDatabaseReference) {
        
        reference.updateChildValues(data) { (error, ref) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Successful storage at \(reference)")
            }
        }
        
    }
    
    func pullAllLocations() {
        ref.child("landmarks").observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else { return }
            
        })
        
        
    }
    
    func clearFirebaseLandmarks(){
        ref.child("landmarks").removeValue()
    }
}

//MARK: - GeoFire
extension FirebaseAPI {

    func geoFireStore(key: String, landmark: Landmark){
        
        let geoFireRef = FIRDatabase.database().reference().child("geofire").child("landmarks")
        guard let geoFire = GeoFire(firebaseRef: geoFireRef) else { print("GeoFire failure"); return }
        
        let latitude = landmark.latitude
        let longitude = landmark.longitude
        
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        geoFire.setLocation(location, forKey: key) { (error) in
            if let  error = error {
                print("FAILURE: \(landmark.name) has GeoFire storage error: \(error.localizedDescription)")
            } else {
                print("SUCCESS: \(landmark.name) stored via GeoFire")
            }
        }
        
    }
    
    func clearGeoFireLandmarks() {
        ref.child("geofire").child("landmarks").removeValue()
    }
    
}

//MARK: - Database Clear
extension FirebaseAPI {
    
    func clearDatabase() {
        clearGeoFireLandmarks()
        clearFirebaseLandmarks()
    }
    
    func deleteLandmark(landmarkKey: String) {
        ref.child("geofire").child("landmarks").child(landmarkKey).removeValue()
        ref.child("landmarks").child(landmarkKey)
    }
    
}

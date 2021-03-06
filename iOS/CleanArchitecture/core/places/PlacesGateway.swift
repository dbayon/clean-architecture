//
//  PlacesGateway.swift
//  CleanArchitecture
//
//  Created by Penas Amor, Alberto on 18/4/18.
//  Copyright © 2018 Alberto. All rights reserved.
//

import Foundation

class PlacesGateway:NSObject, Work {
    
    func run(params:Any?, resolve: @escaping (Any) -> Void, reject: @escaping Reject) throws {
        let location:Location = params as! Location
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?key=AIzaSyAt1VaTyKui6zmYs5kGrEUjbe79erbKNjw&radius=150&types=restaurant&location=\(location.latitude),\(location.longitude)"
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
                reject(error!)
            }else{
                do{
                    let json = try JSONSerialization.jsonObject(with: data!, options:[]) as! NSDictionary
                    let results = json["results"] as! [NSDictionary]
                    if results.count > 0 {
                        let places = results.map({ (item) -> Place in
                            let id = item["id"] as! String
                            let placeId = item["place_id"] as! String
                            let name = item["name"] as! String
                            let icon = item["icon"] as! String
                            var openNow = false
                            if let opening = item["opening_hours"] as? NSDictionary {
                                openNow = opening["open_now"] as! Bool
                            }
                            let rating = item["rating"] as! Double
                            let geometry = item["geometry"] as! NSDictionary
                            let location = geometry["location"] as! NSDictionary
                            let latitude = location["lat"] as! Double
                            let longitude = location["lng"] as! Double
                            return Place(id: id, placeId: placeId, name: name, icon: icon, openNow: openNow, rating: rating, location: Location(latitude: latitude, longitude: longitude))
                        })
                        resolve(places)
                    }else{
                        reject(PlacesError.noPlaces)
                    }
                }catch {
                    reject(error)
                }
            }
            }.resume()
    }
    
}

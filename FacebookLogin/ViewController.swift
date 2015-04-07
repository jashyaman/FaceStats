//
//  ViewController.swift
//  FacebookLogin
//
//  Created by Murugesan, Prem Kumar on 4/3/15.
//  Copyright (c) 2015 Murugesan, Prem Kumar. All rights reserved.
//

import UIKit
import Alamofire
import Foundation
//import SwiftyJSON --> No need to import this file



class ViewController: UIViewController, FBLoginViewDelegate {

    @IBOutlet var fbLoginView : FBLoginView!
    @IBOutlet var profilePictureView : FBProfilePictureView!
    
    var firstName : String!
    var lastName : String!
    var email : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fbLoginView.delegate = self
        self.fbLoginView.readPermissions = ["public_profile", "email", "user_friends"]
        
    }

    //Facebook Delegate methods
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        println("User Logged In")
        println("This is where you perform a segue.")
        
        
        
        //Get the access token of the current session
        
        var accessToken = FBSession.activeSession().accessTokenData.accessToken
        println(accessToken)
        
        
        
        //Request to get the events JSON
        
        Alamofire.request(Alamofire.Method.GET, "https://graph.facebook.com/v2.3/me/events?access_token="+accessToken+"&debug=all&format=json&method=get&pretty=0&suppress_http_code=1").responseJSON() {
            (_, _, jsonData, _) in
            //println(jsonData)
            
            // TODO: Unwrap the optional instead of forced unwrapping! -> Prem
            let data = JSON(jsonData!)
            
            println(data)
            var eventName :String?
            if let ev : String = data["data"][0]["name"].string {
                println("Event Name: \(ev)")
                eventName = ev
                
            }
            if var eventDate : String = data["data"][0]["start_time"].string{
                
                eventDate = eventDate.stringByReplacingOccurrencesOfString("T", withString: " ", options: NSStringCompareOptions.LiteralSearch, range: nil)
                println("Data and Time: \(eventDate)")
                
                
                
                
                var timeZone = NSRegularExpression(pattern:"-(\\d{4})");
                var date = NSRegularExpression(pattern: "(\\d{4}-\\d{2}-\\d{2})")
                var time = NSRegularExpression(pattern: "(\\d{2}:\\d{2}:\\d{2})")
                let retrivedTimeZone = timeZone.firstMatch(eventDate)
                let retrivedDate = date.firstMatch(eventDate)
                let retrivedTime = time.firstMatch(eventDate)
                println(retrivedDate+" "+retrivedTime+" "+retrivedTimeZone)
                
                
                
                
                //Extract Date
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
                var extractedDate = dateFormatter.dateFromString(retrivedDate+" "+retrivedTime+" "+retrivedTimeZone)
                println("Extracted Date : \(extractedDate)")
                var localDate = extractedDate?.toLocalTime()
                println("Local Date : \(localDate)")
                
                //Get the number of seconds for the event
                var timeLeftForTheEvent = NSDate().timeIntervalSinceDate(extractedDate!)
                timeLeftForTheEvent *= -1
                var noOfDays: Int = Int(timeLeftForTheEvent/86400)
                var noOfHours:Int = Int((timeLeftForTheEvent%86400)/3600)
                var noOfMinutes: Int = Int(((timeLeftForTheEvent%86400)%3600)/60)
                println("\(noOfDays) days, \(noOfHours) hours and \(noOfMinutes) minutes left for the event \(eventName!)")
            }
            else{
                println("else: ")
            }
            
        }
        
        
        
        
    }
    
    
    //Fetched Data after Login
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser){
        
        self.firstName = user.first_name
        self.lastName = user.last_name
        profilePictureView.profileID = user.objectID
        
        
        //To get the email id - Use the following method coz, there is no available property for the
        // user - FBGraphUser object to get email id
        
        FBRequestConnection.startForMeWithCompletionHandler { (connection, user, error) -> Void in
            if (error == nil){
                self.email = user.objectForKey("email") as String
                //self.performSegueWithIdentifier("showBasicInfoView", sender: self)
            }
        }

    }
    
    //Passing the date for the segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showBasicInfoView"){
            var vc: BasicInfoViewController = segue.destinationViewController as BasicInfoViewController
            vc.firstName = self.firstName
            vc.lastName = self.lastName
            vc.email = self.email
        }
    }
    
    
    //After user Logout
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!) {
        
        profilePictureView.profileID = nil
        println("User Logged Out")
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        println("Error: \(handleError.localizedDescription)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


//An Extenstion of NSDate class to convert Local --> UTC/GMT and UTC/GMT --> Local

extension NSDate {
    // Convert UTC (or GMT) to local time
    func toLocalTime() -> NSDate {
        let timezone: NSTimeZone = NSTimeZone.localTimeZone()
        let seconds: NSTimeInterval = NSTimeInterval(timezone.secondsFromGMTForDate(self))
        return NSDate(timeInterval: seconds, sinceDate: self)
    }
    
    // Convert local time to UTC (or GMT)
    func toGlobalTime() -> NSDate {
        let timezone: NSTimeZone = NSTimeZone.localTimeZone()
        let seconds: NSTimeInterval = -NSTimeInterval(timezone.secondsFromGMTForDate(self))
        return NSDate(timeInterval: seconds, sinceDate: self)
    }
}

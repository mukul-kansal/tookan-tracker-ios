//
//  Constants.swift
//  Tracker
//
//  Created by cl-macmini-45 on 27/09/16.
//  Copyright © 2016 clicklabs. All rights reserved.
//

import UIKit

class Constants: NSObject {
}

let SERVER_PORT = 1  // 1 dev, 2 test, 3 Live

let APIKeyForGoogleMaps = "AIzaSyDqZn_rsqd_ZMQUITSKB5FGerbn6DwtdLg"//"AIzaSyDX32ar9JhpTYR1W3vGAAjzQTGeOx7MWm4"//"AIzaSyBFXsZ_biHbFbNkY05VRZ59YnhS6FWSYyg"
var globalAPIKey = ""
var globalUserId = ""
let frameworkBundle = Bundle(identifier: "com.click-labs.TookanTracker")

let getCurrentLocation  = UIImage(named: "currentLocation", in: frameworkBundle, compatibleWith: nil)
let destinationMarker  = UIImage(named: "marker", in: frameworkBundle, compatibleWith: nil)
let close  = UIImage(named: "closeButton", in: frameworkBundle, compatibleWith: nil)

struct SERVER {
    static let dev = "http://tracking.tookan.io:3008/"//"https://dev.tracking.tookan.io:3008/"//"http://dev.tracking.tookan.io:3005/"
    static let test = "https://tracking.tookan.io:3012/"//"https://api2.tookanapp.com:5555/"
    static let live = "https://tracking.tookan.io:3000/" //"http://52.23.253.217:8888/" //
}

//let APIKeyForGoogleMaps = "AIzaSyDqZn_rsqd_ZMQUITSKB5FGerbn6DwtdLg"//"AIzaSyDX32ar9JhpTYR1W3vGAAjzQTGeOx7MWm4"//"AIzaSyBFXsZ_biHbFbNkY05VRZ59YnhS6FWSYyg"

struct USER_JOB_STATUS {
    static let free = 0
    static let sharingLocation = 1
    static let trackingLocation = 2
}

struct USER_DEFAULT {
    static let locationArray = "LocationArray"
    static let applicationMode = "ApplicationMode"
    static let isHitInProgress = "isHitInProgress"
    static let isLocationTrackingRunning = "isLocationTrackingRunning"
    static let deviceToken = "DeviceToken"
    static let sessionId = "sessionID"
    static let updatingLocationPathArray = "updatingPathLocationArray"
    static let subscribeLocation = "subscribeLocation"
    static let requestID = "requestID"
    static let sessionURL = "sessionUrl"
    static let apiKey = "apiKey"
    static let userId = "userId"
}

struct OBSERVER {
    static let updatePath = "updatePath"
    static let requestIdURL = "requestIDUrl"
    static let sessionIdURL = "sessionIDUrl"
    static let sessionIdPush = "sessionIdPush"
    static let stopTracking = "stopTracking"
}

struct STATUS_CODES{
    static let INVALID_ACCESS_TOKEN = 101
    static let BAD_REQUEST = 400
    static let UNAUTHORIZED_ACCESS = 401
    static let PICKUP_TASK = 410
    static let ERROR_IN_EXECUTION = 500
    static let SHOW_ERROR_MESSAGE = 304
    static let NOT_FOUND_MESSAGE = 404
    static let SHOW_MESSAGE = 201
    static let SHOW_DATA = 200
    static let NO_INTERNET_CONNECTION = "Unable to connect with the server. Check your internet connection and try again."
    static let SERVER_NOT_RESPONDING = "Something went wrong while connecting to server!"
    static let SYNC_FAILED_MESSAGE = "Server Sync interrupted!! please re-connect to internet to resume. Note: Only pending data will be visible in the App now"
    static let SLOW_INTERNET_CONNECTION = 999
    static let DELETED_TASK = 501
}

struct SHARE_MESSAGE {
    static let REQUEST_MESSAGE = "Hey, I am using Tookan Tracker app for location sharing. Can you share yours with me ? Just click on link -  "
    static let SHARE_LOCATION_MESSAGE = "Hey, I am using Tookan Tracker app for location sharing. You can track me via this link - "
}

struct ALERT_MESSAGE {
    static let SHARE_LOCATION = "Your friend has requested you to share your location. Would you like to start sharing?"
    static let TRACKING_PUSH_ALERT = "Your friend accepted your location sharing request, would you like to start tracking?"
    static let ALREADY_SHARING_LOCATION = "You are already sharing your location. Please turn that off, in order to track somebody else."
    static let ALREADY_TRACKING_LOCATION = "You are already tracking somebody. Please turn that off, in order to share your location."
    static let ALREADY_TRACKING_FOR_TRACKING = "You are already tracking somebody. Please turn that off, in order to track somebody else."
    static let OWN_REQUEST_LINK = "This request link was created by you. Do you want to start tracking the requested friend?"
    static let STOP_SHARING = "Stop Sharing Location"
    static let STOP_TRACKING = "Stop Tracking Location"
}

//MARK: STORYBOARD
enum StoryBoard: String {
    //    case afterLogin = "AfterLogin"
    case main = "Main"
    //    case taxi = "TaxiAfterLogIn"
    //    case nLevel = "NLevel"
    //    case favLocation = "FavouriteLocation"
}


struct STORYBOARD_NAME {
    //    static let afterLogin = StoryBoard.afterLogin.rawValue //Appointment,Deliveries
    static let main = StoryBoard.main.rawValue //Common(Appointment,Deliveries,Taxi)
    //    static let taxiStoryBoardId = StoryBoard.taxi.rawValue //Taxi
}

struct STORYBOARD_ID {
    static let home = "HomeController"
    //    static let listVC = "ListTableViewController"
    //    static let addLocation = "addLocation"
    //    static let addCardWeb = "addCardWeb"
    //    static let payment = "payment"
    //    static let orderDetail = "OrderDetail"
    //    static let orderHistoryVC = "OrderHistoryVC"
    
}

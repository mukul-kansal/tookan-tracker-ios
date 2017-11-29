//
//  SignupModel.swift
//  Tookan
//
//  Created by cl-macmini-45 on 02/06/17.
//  Copyright © 2017 Click Labs. All rights reserved.
//

import UIKit

class SignupModel: NSObject {

//    var sections = [DETAIL_SECTION]()
    
    func setSectionsAndRows() {
//        for customField in Singleton.sharedInstance.fleetDetails.signup_template_data! {
//            switch customField.dataType {
//            case CUSTOM_FIELD_DATA_TYPE.barcode:
//                sections.append(.customBarcode)
//            case CUSTOM_FIELD_DATA_TYPE.checkbox:
//                sections.append(.checkbox)
//            case CUSTOM_FIELD_DATA_TYPE.checklist:
//                sections.append(.checklist)
//            case CUSTOM_FIELD_DATA_TYPE.date:
//                sections.append(.date)
//            case CUSTOM_FIELD_DATA_TYPE.dateFuture:
//                sections.append(.dateFuture)
//            case CUSTOM_FIELD_DATA_TYPE.datePast:
//                sections.append(.datePast)
//            case CUSTOM_FIELD_DATA_TYPE.dateTime:
//                sections.append(.dateTime)
//            case CUSTOM_FIELD_DATA_TYPE.dateTimeFuture:
//                sections.append(.dateTimeFuture)
//            case CUSTOM_FIELD_DATA_TYPE.dateTimePast:
//                sections.append(.dateTimePast)
//            case CUSTOM_FIELD_DATA_TYPE.dropDown:
//                sections.append(.dropdown)
//            case CUSTOM_FIELD_DATA_TYPE.email:
//                sections.append(.email)
//            case CUSTOM_FIELD_DATA_TYPE.number:
//                sections.append(.number)
//            case CUSTOM_FIELD_DATA_TYPE.image:
//                sections.append(.customImage)
//            case CUSTOM_FIELD_DATA_TYPE.table:
//                sections.append(.table)
//            case CUSTOM_FIELD_DATA_TYPE.telephone:
//                sections.append(.telephone)
//            case CUSTOM_FIELD_DATA_TYPE.text:
//                sections.append(.text)
//            case CUSTOM_FIELD_DATA_TYPE.url:
//                sections.append(.url)
//            default:
//                break
//            }
//        }
//        if Singleton.sharedInstance.checkForTeamEnabled() == true {
//            sections.append(.teams)
//        }
//        if Singleton.sharedInstance.checkForTagsEnabled() == true {
//            sections.append(.searchTags)
//            sections.append(.tags)
//        }
    }
//    
//    func showMandatoryCheck() -> Bool {
////        var alertFieldString = ""
////        let customAlertString = self.getCustomFieldMandatoryMessage()
////        if customAlertString == "Uploading" {
////            return false
////        } else {
////            alertFieldString = "\(alertFieldString)\(customAlertString)"
////        }
////
////        if alertFieldString.isEmpty {
////            return true
////        }else {
////            UIAlertView(title: TEXT.MANDATORY_FIELD, message: alertFieldString, delegate: self, cancelButtonTitle: TEXT.OK).show()
////            return false
////        }
//    }
    
    
    func getCustomFieldMandatoryMessage() -> String {
        var alertFieldString = ""
        var count = 0
//        for i in (0..<Singleton.sharedInstance.fleetDetails.signup_template_data!.count) {
//            let customField = Singleton.sharedInstance.fleetDetails.signup_template_data![i]
//            switch(customField.dataType) {
//            case CUSTOM_FIELD_DATA_TYPE.dropDown:
//                if customField.fleetData == "" {
//                    if customField.required == true {
//                        if(count == 0) {
//                            alertFieldString = "\(alertFieldString)\n\(TEXT.CUSTOM_FIELDS)\n"//  + String(format: "\n* %@\n", TEXT.CUSTOM_FIELDS)//"\n* Custom Fields\n"
//                        }
//                        count += 1
//                        alertFieldString = "\(alertFieldString)- \(customField.displayLabelName)\n"
//                    }
//                }
//                break
//
//            case CUSTOM_FIELD_DATA_TYPE.image:
//                if(customField.fleetData == "Uploading"){
//                    Singleton.sharedInstance.showErrorMessage(error: ERROR_MESSAGE.IMAGE_UPLOADING, isError: .error)
//                    return "Uploading"
//                } else if customField.imageArray.count == 0 {
//                    if customField.required == true {
//                        if customField.appSide == "1" {
//                            if(count == 0) {
//                                alertFieldString = "\(alertFieldString)\n\(TEXT.CUSTOM_FIELDS)\n"
//                            }
//                            count += 1
//                            alertFieldString = "\(alertFieldString)- \(customField.displayLabelName)\n"
//                        }
//                    }
//                }
//                break
//
//            case CUSTOM_FIELD_DATA_TYPE.checkbox:
//                if(customField.data == "false" || customField.data == "0"){
//                    if (customField.fleetData == "false" || customField.fleetData == "") {
//                        if customField.required == true {
//                            if customField.appSide == "1" {
//                                if(count == 0) {
//                                    alertFieldString = "\(alertFieldString)\n\(TEXT.CUSTOM_FIELDS)\n"
//                                }
//                                count += 1
//                                alertFieldString = "\(alertFieldString)- \(customField.displayLabelName)\n"
//                            }
//                        }
//                    }
//                }
//                break
//
//            case CUSTOM_FIELD_DATA_TYPE.date,
//                 CUSTOM_FIELD_DATA_TYPE.dateFuture,
//                 CUSTOM_FIELD_DATA_TYPE.datePast,
//                 CUSTOM_FIELD_DATA_TYPE.dateTime,
//                 CUSTOM_FIELD_DATA_TYPE.dateTimeFuture,
//                 CUSTOM_FIELD_DATA_TYPE.dateTimePast,
//                 CUSTOM_FIELD_DATA_TYPE.email,
//                 CUSTOM_FIELD_DATA_TYPE.number,
//                 CUSTOM_FIELD_DATA_TYPE.telephone,
//                 CUSTOM_FIELD_DATA_TYPE.text,
//                 CUSTOM_FIELD_DATA_TYPE.url,
//                 CUSTOM_FIELD_DATA_TYPE.barcode:
//
//                if customField.data == "" {
//                    if customField.fleetData == "" {
//                        if customField.required == true {
//                            if customField.appSide == "1" {
//                                if(count == 0) {
//                                    alertFieldString = "\(alertFieldString)\n\(TEXT.CUSTOM_FIELDS)\n"
//                                }
//                                count += 1
//                                alertFieldString = "\(alertFieldString)- \(customField.displayLabelName)\n"
//                            }
//                        }
//                    }
//                }
//                break
//            case CUSTOM_FIELD_DATA_TYPE.checklist:
//                let checkValue = self.getChecklistCheckValue(section: i)
//                if customField.required == true {
//                    if customField.appSide == "1" {
//                        if(customField.fleetData == "" || checkValue == false) {
//                            if(count == 0) {
//                                alertFieldString = "\(alertFieldString)\n\(TEXT.CUSTOM_FIELDS)\n"
//                            }
//                            count += 1
//                            alertFieldString = "\(alertFieldString)- \(customField.displayLabelName)\n"
//                        }
//                    }
//                }
//            default:
//                break
//            }
//        }
        return alertFieldString
    }

    func getChecklistCheckValue(section:Int) -> Bool {
//        for checklistValues in Singleton.sharedInstance.fleetDetails.signup_template_data![section].checklistArray {
//            if checklistValues.check == true {
//                return true
//            }
//        }
        return false
    }
}

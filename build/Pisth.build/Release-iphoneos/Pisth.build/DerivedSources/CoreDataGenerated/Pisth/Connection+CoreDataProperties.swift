//
//  Connection+CoreDataProperties.swift
//  
//
//  Created by Adrian on 21.01.18.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Connection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Connection> {
        return NSFetchRequest<Connection>(entityName: "Connection")
    }

    @NSManaged public var host: String?
    @NSManaged public var name: String?
    @NSManaged public var password: String?
    @NSManaged public var path: String?
    @NSManaged public var port: Int64
    @NSManaged public var username: String?

}

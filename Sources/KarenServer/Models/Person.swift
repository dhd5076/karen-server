//
//  Person.swift
//  KarenServer
//
//  Created by Dylan Dunn on 3/25/26.
//

import Fluent
import Vapor


final class Person: Model, @unchecked Sendable {
    
    static let schema = "people"
    
    
    //TODO: Figure out a better way to format names
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "firstname")
    var firstname: String
    
    @Field(key: "middlename")
    var middlename: String
    
    @Field(key: "lastname")
    var lastname: String
    
    //TODO: DOB is probably a better field than age, add later
    
    init () { }
    
    init(
        id: UUID? = nil,
        firstname: String,
        middlename: String,
        lastname: String
    ) {
        self.id = id
        self.firstname = firstname
        self.middlename = middlename
        self.lastname = lastname
    }
    
}

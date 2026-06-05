//
//  PantryProduct.swift
//  KarenServer
//
//  Created by Dylan Dunn on 6/4/26.
//

import Fluent
import Vapor

final class PantryProduct: Model, @unchecked Sendable {
    
    static let schema = "pantryProduct"
    
    enum FieldKeys {
        static let name: FieldKey = "name"
        static let unit: FieldKey = "unit"
        static let proteinPerUnit: FieldKey = "protein"
        static let carbsPerUnit: FieldKey = "carbs"
        static let fatPerUnit: FieldKey = "fat"
        static let shelfLife: FieldKey = "shelfLife"
    }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: FieldKeys.name)
    var name: String
    
    @Field(key: FieldKeys.unit)
    var unit: String
    
    @Field(key: FieldKeys.proteinPerUnit)
    var proteinPerUnit: Double

    @Field(key: FieldKeys.carbsPerUnit)
    var carbsPerUnit: Double
    
    @Field(key: FieldKeys.fatPerUnit)
    var fatPerUnit: Double
    
    @Field(key: FieldKeys.shelfLife)
    var shelfLife: Int
    
    init () { }
    
    init(
        id: UUID? = nil,
        name: String,
        unit: String,
        proteinPerUnit: Double,
        carbsPerUnit: Double,
        fatPerUnit: Double,
        shelfLife: Int
    ) {
        self.id = id
        self.name = name
        self.unit = unit
        self.proteinPerUnit = proteinPerUnit
        self.carbsPerUnit = carbsPerUnit
        self.fatPerUnit = fatPerUnit
        self.shelfLife = shelfLife
    }
}

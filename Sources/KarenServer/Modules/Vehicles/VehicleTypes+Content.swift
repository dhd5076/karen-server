//
//  VehicleTypes+Content.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import KarenKit
import Vapor

extension VehicleNameRequest: @retroactive Content {}
extension VehicleRequest: @retroactive Content {}
extension VehicleMake: @retroactive Content {}
extension VehicleModel: @retroactive Content {}
extension Vehicle: @retroactive Content {}
extension LicensePlateRequest: @retroactive Content {}
extension LicensePlateRelationshipRequest: @retroactive Content {}
extension LicensePlate: @retroactive Content {}
extension VehicleLicensePlateAssignment: @retroactive Content {}

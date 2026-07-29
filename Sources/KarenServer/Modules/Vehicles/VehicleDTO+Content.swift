//
//  VehicleDTO.swift
//  KarenServer
//
//  Created by Dylan Dunn on 7/24/26.
//

import KarenKit
import Vapor

extension VehicleNameRequest: @retroactive Content {}
extension VehicleRequest: @retroactive Content {}
extension VehicleMakeResponse: @retroactive Content {}
extension VehicleModelResponse: @retroactive Content {}
extension VehicleResponse: @retroactive Content {}
extension LicensePlateRequest: @retroactive Content {}
extension LicensePlateRelationshipRequest: @retroactive Content {}
extension LicensePlateResponse: @retroactive Content {}
extension VehicleLicensePlateResponse: @retroactive Content {}

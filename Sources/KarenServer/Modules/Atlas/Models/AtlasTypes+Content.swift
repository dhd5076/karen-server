//
//  AtlasTypes+Content.swift
//  KarenServer
//
//  Created by Codex on 8/1/26.
//

import KarenKit
import Vapor

extension AtlasEntity: @retroactive Content {}
extension AtlasAttribute: @retroactive Content {}
extension AtlasRelationship: @retroactive Content {}
extension CreateAtlasEntityRequest: @retroactive Content {}
extension UpdateAtlasEntityRequest: @retroactive Content {}
extension SetAtlasAttributeRequest: @retroactive Content {}
extension CreateAtlasRelationshipRequest: @retroactive Content {}
extension EndAtlasRelationshipRequest: @retroactive Content {}

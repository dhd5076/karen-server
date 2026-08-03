//
//  PersonTypes+Content.swift
//  KarenServer
//

import KarenKit
import Vapor

extension PersonRequest: @retroactive Content {}
extension Person: @retroactive Content {}

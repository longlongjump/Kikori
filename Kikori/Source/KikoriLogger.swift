//
//  KikoriLogger.swift
//  Kikori
//
//  Created by eugene on 14/4/16.
//  Copyright © 2016 Eugene Ovchynnykov. All rights reserved.
//

import Foundation

public protocol KikoriLoggerProtocol {
    func log(string: String)
}


public class KikoriLogger: KikoriLoggerProtocol {
    public func log(string: String) {
        print(string)
    }
}

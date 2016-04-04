//
//  ProgressBar.swift
//  KookieKiosk-Swift
//
//  Created by Barbara Reichart on 16/07/14.
//  Copyright (c) 2014 Barbara Reichart. All rights reserved.
//

import SpriteKit

protocol ProgressBar {
    
    var node : SKNode {get}
    func setProgress(percentage percentage: Float)
    
}